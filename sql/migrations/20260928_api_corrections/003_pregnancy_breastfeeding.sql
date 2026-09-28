BEGIN;

SET LOCAL search_path TO venus, public;

/*
  Correção 3 — regras de gestação e amamentação
  ---------------------------------------------
  A API de classificação veta um produto (nota 0, contraindicado) quando uma
  regra 'block' bate numa etiqueta do perfil. Ingrediente que só não é
  recomendado vira 'penalty' e tira ponto na própria pergunta. As regras
  ficam no modelo base (id 1), e o 'block' do modelo base vale para todos os
  modelos: nenhum modelo consegue trocá-lo por uma regra própria.

  gravidez    -> 'block':   Retinol, Acetato de retinol, Palmitato de retinol,
                            Propionato de retinila, Hidroquinona e Lilial
                            (Butylphenyl Methylpropional)
  gravidez    -> 'penalty': Ácido salicílico, Capriloil ácido salicílico
  amamentacao -> 'penalty': Hidroquinona

  O Peróxido de benzoíla tem efeito de gestação gravado em 2026-09-24, mas
  fica sem regra (decisão do produto), então não pesa em nada.

  O que já existe no banco real e este script só garante (no banco real não
  muda nada; num banco novo, cria):
    - a etiqueta 'gravidez' (criada em 2026-09-22);
    - os 8 efeitos de gestação gravados em 2026-09-24 (ids 5843 a 5850).

  O que é novo: o efeito do Lilial na gestação, o efeito da Hidroquinona na
  amamentação e as 9 regras.

  Valores das regras:
    - 'penalty' = score_delta -5, weight 1.00, priority 10, iguais às 702
      penalidades que já existem;
    - 'block'   = score_delta 0: o bloqueio não soma ponto, ele zera a nota.

  Segurança (lição de 2026-09-22): nenhum ON CONFLICT DO UPDATE. Se já houver
  uma regra diferente para um destes efeitos no modelo 1, o INSERT não a
  sobrescreve e a conferência do fim desfaz tudo com a mensagem do problema.
*/

CREATE TEMP TABLE tmp_gestacao (
    inci_name          TEXT NOT NULL,
    tag_slug           TEXT NOT NULL,
    effect_category    venus.effect_category_enum NOT NULL,
    effect_name        TEXT NOT NULL,
    effect_description TEXT NOT NULL,
    effect_strength    venus.effect_strength_enum NOT NULL,
    evidence_level     venus.evidence_level_enum NOT NULL,
    rule_type          venus.effect_type_enum,   -- NULL = efeito sem regra
    rule_score_delta   INTEGER,
    rule_reason        TEXT
) ON COMMIT DROP;

INSERT INTO tmp_gestacao VALUES
    -- efeitos de 2026-09-24 (já existem no banco real)
    ('RETINOL', 'gravidez', 'contraindication', 'Contraindicado na gestação',
     'Retinoides e hidroquinona devem ser evitados durante a gravidez.', 'very_strong', 'high',
     'block', 0, 'Retinoide: contraindicado na gestação.'),
    ('RETINYL ACETATE', 'gravidez', 'contraindication', 'Contraindicado na gestação',
     'Retinoides e hidroquinona devem ser evitados durante a gravidez.', 'very_strong', 'high',
     'block', 0, 'Retinoide: contraindicado na gestação.'),
    ('RETINYL PALMITATE', 'gravidez', 'contraindication', 'Contraindicado na gestação',
     'Retinoides e hidroquinona devem ser evitados durante a gravidez.', 'very_strong', 'high',
     'block', 0, 'Retinoide: contraindicado na gestação.'),
    ('RETINYL PROPIONATE', 'gravidez', 'contraindication', 'Contraindicado na gestação',
     'Retinoides e hidroquinona devem ser evitados durante a gravidez.', 'very_strong', 'high',
     'block', 0, 'Retinoide: contraindicado na gestação.'),
    ('HYDROQUINONE', 'gravidez', 'contraindication', 'Contraindicado na gestação',
     'Retinoides e hidroquinona devem ser evitados durante a gravidez.', 'very_strong', 'high',
     'block', 0, 'Hidroquinona: contraindicada na gestação.'),
    ('SALICYLIC ACID', 'gravidez', 'warning', 'Uso com cautela na gestação',
     'Evitar em alta concentração ou peeling durante a gravidez; consultar médico.', 'moderate', 'medium',
     'penalty', -5, 'Ácido salicílico: usar com cautela na gestação.'),
    ('CAPRYLOYL SALICYLIC ACID', 'gravidez', 'warning', 'Uso com cautela na gestação',
     'Evitar em alta concentração ou peeling durante a gravidez; consultar médico.', 'moderate', 'medium',
     'penalty', -5, 'Capriloil ácido salicílico: usar com cautela na gestação.'),
    ('BENZOYL PEROXIDE', 'gravidez', 'warning', 'Uso com cautela na gestação',
     'Evitar em alta concentração ou peeling durante a gravidez; consultar médico.', 'moderate', 'medium',
     NULL, NULL, NULL),
    -- novos
    ('BUTYLPHENYL METHYLPROPIONAL', 'gravidez', 'contraindication', 'Contraindicado na gestação',
     'Lilial: classificado como tóxico para a reprodução e proibido em cosméticos na UE desde 2022.',
     'very_strong', 'high',
     'block', 0, 'Lilial (Butylphenyl Methylpropional): contraindicado na gestação.'),
    ('HYDROQUINONE', 'amamentacao', 'warning', 'Uso com cautela na amamentação',
     'A hidroquinona é bem absorvida pela pele; na amamentação, evitar ou usar só com orientação médica.',
     'moderate', 'medium',
     'penalty', -5, 'Hidroquinona: usar com cautela na amamentação.');

/* 0. Pré-condições: ingredientes da lista e modelo base. */
DO $$
DECLARE
    v_faltando TEXT;
    v_modelo   TEXT;
BEGIN
    SELECT string_agg(DISTINCT t.inci_name, ', ')
      INTO v_faltando
      FROM tmp_gestacao t
     WHERE NOT EXISTS (SELECT 1 FROM venus.ingredients i WHERE i.inci_name = t.inci_name);
    IF v_faltando IS NOT NULL THEN
        RAISE EXCEPTION 'INCI da lista que não existem em venus.ingredients: %', v_faltando;
    END IF;

    SELECT name INTO v_modelo FROM venus.scoring_models WHERE scoring_model_id = 1;
    IF v_modelo IS DISTINCT FROM 'Recomendação Geral' THEN
        RAISE EXCEPTION 'O modelo 1 não é "Recomendação Geral" (achei: %). Nada foi alterado.', v_modelo;
    END IF;
END $$;

/* 1. Etiquetas necessárias. */
INSERT INTO venus.profile_tags (name, description, slug, category)
VALUES
    ('Gravidez', 'Usuária gestante', 'gravidez', 'health'),
    ('Amamentação', 'Usuária em fase de amamentação', 'amamentacao', 'health')
ON CONFLICT (slug) DO UPDATE
SET name = EXCLUDED.name,
    description = EXCLUDED.description,
    category = EXCLUDED.category,
    updated_at = NOW();

/* 2. Efeitos: os 8 de 2026-09-24 (conflito = já existe) e os 2 novos. */
INSERT INTO venus.ingredient_effects (
    fk_ingredient_id, fk_profile_tag_id, effect_category, effect_name,
    effect_description, effect_strength, evidence_level, review_status,
    source_type, source_reference
)
SELECT i.ingredient_id, pt.profile_tag_id, t.effect_category, t.effect_name,
       t.effect_description, t.effect_strength, t.evidence_level, 'pending',
       'admin', 'Migration 20260927_003: gestação e amamentação (API de Classificação §5)'
FROM tmp_gestacao t
JOIN venus.ingredients i ON i.inci_name = t.inci_name
JOIN venus.profile_tags pt ON pt.slug = t.tag_slug
ON CONFLICT (fk_ingredient_id, fk_profile_tag_id, effect_category, effect_name) DO NOTHING;

/* 3. Regras no modelo base (id 1). */
INSERT INTO venus.compatibility_rules (
    fk_ingredient_effect_id, fk_scoring_model_id, effect_type, score_delta,
    weight, priority, has_concentration_factor, is_enabled, evidence_level,
    reason, source_type, source_reference
)
SELECT ie.ingredient_effect_id, 1, t.rule_type, t.rule_score_delta,
       1.00, 10, FALSE, TRUE, ie.evidence_level,
       t.rule_reason, 'admin', 'Migration 20260927_003: gestação e amamentação (API de Classificação §5)'
FROM tmp_gestacao t
JOIN venus.ingredients i ON i.inci_name = t.inci_name
JOIN venus.profile_tags pt ON pt.slug = t.tag_slug
JOIN venus.ingredient_effects ie
  ON ie.fk_ingredient_id = i.ingredient_id
 AND ie.fk_profile_tag_id = pt.profile_tag_id
 AND ie.effect_category = t.effect_category
 AND ie.effect_name = t.effect_name
WHERE t.rule_type IS NOT NULL
ON CONFLICT (fk_ingredient_effect_id, fk_scoring_model_id) DO NOTHING;

/* 4. Conferência: se algo não bater, desfaz a transação inteira. */
DO $$
DECLARE
    v_certas INTEGER;
BEGIN
    SELECT COUNT(*)
      INTO v_certas
      FROM tmp_gestacao t
      JOIN venus.ingredients i ON i.inci_name = t.inci_name
      JOIN venus.profile_tags pt ON pt.slug = t.tag_slug
      JOIN venus.ingredient_effects ie
        ON ie.fk_ingredient_id = i.ingredient_id
       AND ie.fk_profile_tag_id = pt.profile_tag_id
       AND ie.effect_category = t.effect_category
       AND ie.effect_name = t.effect_name
      JOIN venus.compatibility_rules cr
        ON cr.fk_ingredient_effect_id = ie.ingredient_effect_id
       AND cr.fk_scoring_model_id = 1
       AND cr.effect_type = t.rule_type
       AND cr.score_delta = t.rule_score_delta
       AND cr.is_enabled
     WHERE t.rule_type IS NOT NULL;
    IF v_certas <> 9 THEN
        RAISE EXCEPTION 'Esperadas 9 regras no modelo 1 (6 block + 3 penalty); conferidas %. Nada foi gravado.', v_certas;
    END IF;

END $$;

COMMIT;

/* QA: esperado 10 linhas — 9 com regra (6 block, 3 penalty) e o Peróxido de benzoíla sem regra. */
SELECT pt.slug, i.inci_name, ie.effect_category, cr.effect_type, cr.score_delta, cr.reason
FROM venus.ingredient_effects ie
JOIN venus.ingredients i ON i.ingredient_id = ie.fk_ingredient_id
JOIN venus.profile_tags pt ON pt.profile_tag_id = ie.fk_profile_tag_id
LEFT JOIN venus.compatibility_rules cr
       ON cr.fk_ingredient_effect_id = ie.ingredient_effect_id
      AND cr.fk_scoring_model_id = 1
WHERE pt.slug IN ('gravidez', 'amamentacao')
ORDER BY pt.slug, cr.effect_type NULLS LAST, i.inci_name;
