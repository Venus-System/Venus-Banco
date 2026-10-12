-- Venus — políticas de prontidão para a classificação — 2026-10-12
-- Somente banco: a API de classificação permanece sem alteração.

BEGIN;

SET LOCAL lock_timeout = '10s';
SET LOCAL statement_timeout = '600s';
SET LOCAL search_path TO venus, public;

-- -------------------------------------------------------------------------
-- 1. Biodegradabilidade: metodologia v2 com a direção usada pela API
-- -------------------------------------------------------------------------

INSERT INTO venus.ingredient_risk_methodologies (
    methodology_version, name, status, score_semantics, unknown_policy,
    source_hierarchy, effective_from, created_at, updated_at
)
SELECT
    'v2',
    'Baseline de risco de ingrediente — direção de biodegradabilidade compatível com a classificação',
    'active',
    'Irritação, comedogenicidade e risco ambiental são carga de risco: 0 é menor risco e 10 é maior risco. Biodegradabilidade é desempenho ambiental: 0 é baixa biodegradabilidade/persistência e 10 é biodegradabilidade alta. O score é intrínseco ao ingrediente e não substitui avaliação de fórmula, concentração ou embalagem.',
    unknown_policy,
    source_hierarchy,
    DATE '2026-10-12',
    NOW(),
    NOW()
FROM venus.ingredient_risk_methodologies
WHERE methodology_version = 'v1'
ON CONFLICT (methodology_version) DO UPDATE SET
    name = EXCLUDED.name,
    status = EXCLUDED.status,
    score_semantics = EXCLUDED.score_semantics,
    unknown_policy = EXCLUDED.unknown_policy,
    source_hierarchy = EXCLUDED.source_hierarchy,
    effective_from = EXCLUDED.effective_from,
    updated_at = NOW();

INSERT INTO venus.ingredient_risk_methodology_dimensions (
    methodology_version, dimension, score_direction, definition,
    required_evidence, anchors
)
SELECT
    'v2',
    dimension,
    CASE
        WHEN dimension = 'biodegradability_level' THEN 'higher_is_better'
        ELSE score_direction
    END,
    CASE
        WHEN dimension = 'biodegradability_level'
            THEN 'Facilidade de biodegradação/desaparecimento ambiental. 0 significa baixa biodegradabilidade ou persistência elevada; 10 significa biodegradabilidade alta e menor persistência.'
        ELSE definition
    END,
    required_evidence,
    CASE
        WHEN dimension = 'biodegradability_level' THEN
            '{"0":"very persistent or low biodegradation","2":"slow or uncertain biodegradation","4":"biodegradable but incomplete or context-dependent evidence","6":"good biodegradation with minor uncertainty","8":"high biodegradation","10":"readily biodegradable or authoritative favorable conclusion"}'::jsonb
        ELSE anchors
    END
FROM venus.ingredient_risk_methodology_dimensions
WHERE methodology_version = 'v1'
ON CONFLICT (methodology_version, dimension) DO UPDATE SET
    score_direction = EXCLUDED.score_direction,
    definition = EXCLUDED.definition,
    required_evidence = EXCLUDED.required_evidence,
    anchors = EXCLUDED.anchors;

UPDATE venus.ingredient_risk_methodologies
   SET status = 'retired', updated_at = NOW()
 WHERE methodology_version = 'v1';

-- -------------------------------------------------------------------------
-- 2. Benefícios: somente benefit + validated entra na performance
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS venus.ingredient_effect_validation_audit (
    audit_id BIGSERIAL PRIMARY KEY,
    ingredient_effect_id BIGINT NOT NULL,
    fk_ingredient_id BIGINT NOT NULL REFERENCES venus.ingredients (ingredient_id) ON DELETE CASCADE,
    from_effect_category TEXT NOT NULL,
    to_effect_category TEXT NOT NULL,
    from_review_status TEXT NOT NULL,
    to_review_status TEXT NOT NULL,
    evidence_level TEXT NOT NULL,
    source_reference TEXT,
    decision TEXT NOT NULL,
    methodology_version TEXT NOT NULL DEFAULT 'v1',
    applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ingredient_effect_validation_audit_ingredient
    ON venus.ingredient_effect_validation_audit (fk_ingredient_id, applied_at DESC);

INSERT INTO venus.ingredient_effect_validation_audit (
    ingredient_effect_id, fk_ingredient_id, from_effect_category,
    to_effect_category, from_review_status, to_review_status,
    evidence_level, source_reference, decision, methodology_version
)
SELECT
    ingredient_effect_id, fk_ingredient_id, effect_category::TEXT,
    'benefit', review_status::TEXT, 'validated',
    evidence_level::TEXT, source_reference,
    'validated_from_authoritative_source_chain', 'v1'
FROM venus.ingredient_effects
WHERE effect_category = 'benefit'
  AND review_status = 'pending'
  AND evidence_level = 'high';

UPDATE venus.ingredient_effects
   SET review_status = 'validated', updated_at = NOW()
 WHERE effect_category = 'benefit'
   AND review_status = 'pending'
   AND evidence_level = 'high';

INSERT INTO venus.ingredient_effect_validation_audit (
    ingredient_effect_id, fk_ingredient_id, from_effect_category,
    to_effect_category, from_review_status, to_review_status,
    evidence_level, source_reference, decision, methodology_version
)
SELECT
    ingredient_effect_id, fk_ingredient_id, effect_category::TEXT,
    'neutral', review_status::TEXT, review_status::TEXT,
    evidence_level::TEXT, source_reference,
    'excluded_from_performance_until_specific_validation', 'v1'
FROM venus.ingredient_effects
WHERE effect_category = 'benefit'
  AND review_status = 'pending';

UPDATE venus.ingredient_effects
   SET effect_category = 'neutral', updated_at = NOW()
 WHERE effect_category = 'benefit'
   AND review_status = 'pending';

CREATE OR REPLACE FUNCTION venus.fn_gate_unvalidated_benefit()
RETURNS TRIGGER
LANGUAGE PLPGSQL
AS $$
BEGIN
    IF NEW.effect_category = 'benefit'
       AND NEW.review_status <> 'validated' THEN
        NEW.effect_category := 'neutral';
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_gate_unvalidated_benefit
    ON venus.ingredient_effects;
CREATE TRIGGER trg_gate_unvalidated_benefit
BEFORE INSERT OR UPDATE OF effect_category, review_status
ON venus.ingredient_effects
FOR EACH ROW
EXECUTE FUNCTION venus.fn_gate_unvalidated_benefit();

COMMENT ON FUNCTION venus.fn_gate_unvalidated_benefit() IS
    'Mantém efeitos benefit fora da performance enquanto review_status não for validated.';

-- -------------------------------------------------------------------------
-- 3. Ingrediente avaliado: confidence padrão não é avaliação
-- -------------------------------------------------------------------------

ALTER TABLE venus.ingredients
    DROP CONSTRAINT IF EXISTS ck_ingredients_scientific_confidence_range;

ALTER TABLE venus.ingredients
    ALTER COLUMN scientific_confidence SET DEFAULT 0;

ALTER TABLE venus.ingredients
    ADD CONSTRAINT ck_ingredients_scientific_confidence_range
    CHECK (scientific_confidence >= 0 AND scientific_confidence <= 100);

UPDATE venus.ingredients
   SET scientific_confidence = 0,
       scientific_confidence_state = 'default',
       updated_at = NOW()
 WHERE scientific_confidence <= 1
    OR (
        irritation_risk_level = 0
        AND comedogenicity_score = 0
        AND biodegradability_level = 0
        AND environmental_risk_level = 0
    );

CREATE OR REPLACE FUNCTION venus.fn_normalize_scientific_confidence_state()
RETURNS TRIGGER
LANGUAGE PLPGSQL
AS $$
BEGIN
    IF NEW.scientific_confidence IS NULL
       OR NEW.scientific_confidence <= 1
       OR (
           COALESCE(NEW.irritation_risk_level, 0) = 0
           AND COALESCE(NEW.comedogenicity_score, 0) = 0
           AND COALESCE(NEW.biodegradability_level, 0) = 0
           AND COALESCE(NEW.environmental_risk_level, 0) = 0
       ) THEN
        NEW.scientific_confidence := 0;
        NEW.scientific_confidence_state := 'default';
        RETURN NEW;
    END IF;

    IF NEW.scientific_confidence_state IS NULL
       OR NEW.scientific_confidence_state NOT IN ('default', 'derived', 'curated') THEN
        NEW.scientific_confidence_state := 'default';
    END IF;

    IF NEW.scientific_confidence_state <> 'curated' THEN
        NEW.scientific_confidence_state := 'derived';
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_normalize_scientific_confidence_state
    ON venus.ingredients;
CREATE TRIGGER trg_normalize_scientific_confidence_state
BEFORE INSERT OR UPDATE OF scientific_confidence, scientific_confidence_state,
    irritation_risk_level, comedogenicity_score,
    biodegradability_level, environmental_risk_level
ON venus.ingredients
FOR EACH ROW
EXECUTE FUNCTION venus.fn_normalize_scientific_confidence_state();

COMMENT ON FUNCTION venus.fn_normalize_scientific_confidence_state() IS
    'Confidence 0 é o estado padrão/desconhecido; somente confidence > 1 com notas não zeradas pode ser avaliado pela classificação.';

-- -------------------------------------------------------------------------
-- 4. Embalagem ausente/incompleta: desconhecida, nunca inferida
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS venus.packaging_evaluation_policies (
    policy_version TEXT PRIMARY KEY,
    status TEXT NOT NULL CHECK (status IN ('active', 'retired')),
    missing_packaging_policy TEXT NOT NULL,
    unverified_packaging_policy TEXT NOT NULL,
    source_hierarchy JSONB NOT NULL,
    effective_from DATE NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO venus.packaging_evaluation_policies (
    policy_version, status, missing_packaging_policy,
    unverified_packaging_policy, source_hierarchy, effective_from
)
VALUES (
    'v1',
    'active',
    'Sem linha de packaging: estado unknown; não assumir reciclável, refilável, biodegradável ou não reciclável.',
    'Confidence 0 ou ausência de atributo verificável: estado unknown; não contar a embalagem como evidência positiva ou negativa.',
    '[
        {"rank": 1, "source": "ficha técnica ou fabricante", "required": true},
        {"rank": 2, "source": "rótulo/foto legível", "required": true},
        {"rank": 3, "source": "declaração regulatória ou certificação", "required": true}
    ]'::jsonb,
    DATE '2026-10-12'
)
ON CONFLICT (policy_version) DO UPDATE SET
    status = EXCLUDED.status,
    missing_packaging_policy = EXCLUDED.missing_packaging_policy,
    unverified_packaging_policy = EXCLUDED.unverified_packaging_policy,
    source_hierarchy = EXCLUDED.source_hierarchy,
    effective_from = EXCLUDED.effective_from,
    updated_at = NOW();

UPDATE venus.packaging
   SET confidence_score = 0, updated_at = NOW()
 WHERE COALESCE(confidence_score, 0) > 0
   AND recycled_content_percentage IS NULL
   AND is_recyclable = FALSE
   AND is_refillable = FALSE
   AND is_biodegradable = FALSE;

CREATE OR REPLACE FUNCTION venus.fn_normalize_packaging_confidence()
RETURNS TRIGGER
LANGUAGE PLPGSQL
AS $$
BEGIN
    IF COALESCE(NEW.confidence_score, 0) > 0
       AND NEW.recycled_content_percentage IS NULL
       AND NEW.is_recyclable = FALSE
       AND NEW.is_refillable = FALSE
       AND NEW.is_biodegradable = FALSE THEN
        NEW.confidence_score := 0;
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_normalize_packaging_confidence
    ON venus.packaging;
CREATE TRIGGER trg_normalize_packaging_confidence
BEFORE INSERT OR UPDATE OF confidence_score, is_recyclable, is_refillable,
    is_biodegradable, recycled_content_percentage
ON venus.packaging
FOR EACH ROW
EXECUTE FUNCTION venus.fn_normalize_packaging_confidence();

CREATE OR REPLACE VIEW venus.v_packaging_evaluation_status AS
SELECT
    pv.product_version_id,
    pv.display_name,
    p.packaging_id,
    COALESCE(p.confidence_score, 0) AS confidence_score,
    CASE
        WHEN p.packaging_id IS NULL THEN 'unknown_missing'
        WHEN COALESCE(p.confidence_score, 0) <= 0 THEN 'unknown_unverified'
        ELSE 'evaluated'
    END AS evaluation_status,
    pep.policy_version
FROM venus.product_versions pv
LEFT JOIN venus.packaging p
  ON p.fk_product_version_id = pv.product_version_id
CROSS JOIN LATERAL (
    SELECT policy_version
      FROM venus.packaging_evaluation_policies
     WHERE status = 'active'
     ORDER BY effective_from DESC
     LIMIT 1
) pep;

COMMENT ON VIEW venus.v_packaging_evaluation_status IS
    'Contrato v1: embalagem ausente ou sem evidência fica unknown e não deve ser preenchida por inferência.';

-- -------------------------------------------------------------------------
-- 5. Evidências éticas positivas por marca
-- -------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS venus.brand_claim_evidence (
    brand_claim_evidence_id BIGSERIAL PRIMARY KEY,
    fk_brand_id BIGINT NOT NULL REFERENCES venus.brands (brand_id) ON DELETE CASCADE,
    claim_type TEXT NOT NULL CHECK (claim_type IN ('vegan', 'cruelty_free', 'brazilian')),
    claim_value BOOLEAN NOT NULL DEFAULT TRUE,
    source_url TEXT NOT NULL,
    source_title TEXT NOT NULL,
    evidence_note TEXT NOT NULL,
    evidence_level TEXT NOT NULL CHECK (evidence_level IN ('high', 'medium', 'low')),
    verified_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    methodology_version TEXT NOT NULL DEFAULT 'v1',
    UNIQUE (fk_brand_id, claim_type, source_url)
);

INSERT INTO venus.brand_claim_evidence (
    fk_brand_id, claim_type, claim_value, source_url, source_title,
    evidence_note, evidence_level
)
VALUES
    (7, 'vegan', TRUE, 'https://www.lolacosmetics.com.br/pages/lola-lab', 'Lola Lab — site oficial', 'A marca declara que toda a linha é vegana e cruelty-free.', 'high'),
    (7, 'cruelty_free', TRUE, 'https://www.lolacosmetics.com.br/pages/lola-lab', 'Lola Lab — site oficial', 'A marca declara que nada é testado em animais em nenhuma etapa.', 'high'),
    (8, 'vegan', TRUE, 'https://www.skala.com.br/es/vegano/', 'Skala 100% Vegano — site oficial', 'A marca declara que toda a linha é 100% vegana e sem ingredientes de origem animal.', 'high'),
    (8, 'cruelty_free', TRUE, 'https://www.skala.com.br/es/vegano/', 'Skala 100% Vegano — site oficial', 'A marca declara compromisso cruelty-free e ausência de testes em animais.', 'high'),
    (9, 'cruelty_free', TRUE, 'https://www.natura.com.br/blog/sustentabilidade/contra-testes-em-animais', 'Natura — site oficial', 'A marca declara não realizar nem contratar testes em animais e informa certificação Cruelty Free International.', 'high'),
    (24, 'vegan', TRUE, 'https://www.biossance.com/blog/certifications-and-awards/', 'Biossance Certifications and Awards — site oficial', 'A marca declara ser totalmente vegana.', 'high'),
    (24, 'cruelty_free', TRUE, 'https://www.biossance.com/blog/certifications-and-awards/', 'Biossance Certifications and Awards — site oficial', 'A marca declara compromisso cruelty-free e que seus produtos não são testados em animais.', 'high'),
    (25, 'cruelty_free', TRUE, 'https://www.thebodyshop.com/blogs/body-care/about-our-ingredients', 'The Body Shop — site oficial', 'A marca declara que ser cruelty-free é uma prioridade permanente.', 'medium')
ON CONFLICT (fk_brand_id, claim_type, source_url) DO UPDATE SET
    claim_value = EXCLUDED.claim_value,
    source_title = EXCLUDED.source_title,
    evidence_note = EXCLUDED.evidence_note,
    evidence_level = EXCLUDED.evidence_level,
    verified_at = NOW(),
    methodology_version = EXCLUDED.methodology_version;

UPDATE venus.brands b
   SET has_vegan_claim = TRUE
 WHERE b.brand_id IN (7, 8, 24)
   AND EXISTS (
       SELECT 1 FROM venus.brand_claim_evidence e
        WHERE e.fk_brand_id = b.brand_id
          AND e.claim_type = 'vegan'
          AND e.claim_value
          AND e.evidence_level IN ('high', 'medium')
   );

UPDATE venus.brands b
   SET has_cruelty_free_claim = TRUE
 WHERE b.brand_id IN (7, 8, 9, 24, 25)
   AND EXISTS (
       SELECT 1 FROM venus.brand_claim_evidence e
        WHERE e.fk_brand_id = b.brand_id
          AND e.claim_type = 'cruelty_free'
          AND e.claim_value
          AND e.evidence_level IN ('high', 'medium')
   );

-- -------------------------------------------------------------------------
-- 6. Converter as notas legadas e manter a inferência futura em v2
-- -------------------------------------------------------------------------

UPDATE venus.ingredient_risk_assessments
   SET score = CASE
                   WHEN dimension = 'biodegradability_level' THEN 10 - score
                   ELSE score
               END,
       assessment_version = 'v2',
       source_reference = source_reference || ' | methodology=v2; biodegradability_direction=higher_is_better',
       rationale = CASE
           WHEN dimension = 'biodegradability_level'
               THEN 'v2; score invertido do legado v1 para a direção maior=melhor; ' || rationale
           ELSE 'v2; direção preservada do legado v1; ' || rationale
       END,
       assessment_scope = 'ingredient_baseline_indirect_v2',
       updated_at = NOW()
 WHERE assessment_version = 'v1';

SELECT set_config('venus.allow_risk_sync', 'on', TRUE);

UPDATE venus.ingredients
   SET biodegradability_level = 10 - biodegradability_level,
       updated_at = NOW()
 WHERE biodegradability_level BETWEEN 0 AND 10;

CREATE OR REPLACE VIEW venus.v_ingredient_risk_inference_v2 AS
SELECT
    v.ingredient_id,
    v.inci_name,
    v.irritation_score,
    v.comedogenicity_score,
    (10 - v.biodegradability_score)::SMALLINT AS biodegradability_score,
    v.environmental_score,
    v.source_reference || ' | methodology=v2; biodegradability_direction=higher_is_better' AS source_reference,
    v.irritation_rationale,
    v.comedogenicity_rationale,
    format('v2 indireta; score=%s; direção maior=melhor; score legado de persistência=%s.', (10 - v.biodegradability_score), v.biodegradability_score) AS biodegradability_rationale,
    v.environmental_rationale
FROM venus.v_ingredient_risk_inference_v1 v;

CREATE OR REPLACE FUNCTION venus.fn_refresh_ingredient_risk_assessment_v2(
    p_ingredient_id BIGINT
)
RETURNS VOID
LANGUAGE PLPGSQL
AS $$
DECLARE
    v RECORD;
BEGIN
    SELECT * INTO v
      FROM venus.v_ingredient_risk_inference_v2
     WHERE ingredient_id = p_ingredient_id;

    IF NOT FOUND THEN
        RETURN;
    END IF;

    CALL venus.sp_approve_ingredient_risk_assessment_v1(
        v.ingredient_id,
        v.irritation_score,
        v.comedogenicity_score,
        v.biodegradability_score,
        v.environmental_score,
        v.source_reference,
        v.irritation_rationale,
        v.comedogenicity_rationale,
        v.biodegradability_rationale,
        v.environmental_rationale,
        'low'::venus.evidence_level_enum,
        'ingredient_baseline_indirect_v2',
        'v2'
    );
END;
$$;

CREATE OR REPLACE FUNCTION venus.fn_refresh_ingredient_risk_assessment_v1(
    p_ingredient_id BIGINT
)
RETURNS VOID
LANGUAGE PLPGSQL
AS $$
BEGIN
    PERFORM venus.fn_refresh_ingredient_risk_assessment_v2(p_ingredient_id);
END;
$$;

CREATE OR REPLACE FUNCTION venus.fn_auto_refresh_ingredient_risk_from_ingredient()
RETURNS TRIGGER
LANGUAGE PLPGSQL
AS $$
BEGIN
    PERFORM venus.fn_refresh_ingredient_risk_assessment_v2(NEW.ingredient_id);
    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION venus.fn_auto_refresh_ingredient_risk_from_fk()
RETURNS TRIGGER
LANGUAGE PLPGSQL
AS $$
BEGIN
    PERFORM venus.fn_refresh_ingredient_risk_assessment_v2(
        CASE WHEN TG_OP = 'DELETE' THEN OLD.fk_ingredient_id ELSE NEW.fk_ingredient_id END
    );
    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    END IF;
    RETURN NEW;
END;
$$;

-- -------------------------------------------------------------------------
-- 7. Remover scores antigos e obrigar nova execução do base-scores
-- -------------------------------------------------------------------------

DO $$
DECLARE
    v RECORD;
BEGIN
    FOR v IN
        SELECT product_version_id
          FROM venus.product_versions
         WHERE is_current
         ORDER BY product_version_id
    LOOP
        PERFORM venus.fn_invalidate_product_scores(
            v.product_version_id,
            'score_readiness_policies_20261012; rerun_base_scores_required'
        );
    END LOOP;
END;
$$;

COMMIT;
