-- Venus — descrições em português e consolidação de marcas — 2026-10-11
--
-- Preenche a descrição exibida pelo produto sem sobrescrever o termo técnico
-- original e consolida duplicidades exatas de marcas após reatribuir produtos.

BEGIN;

SET LOCAL lock_timeout = '10s';
SET LOCAL statement_timeout = '180s';
SET LOCAL search_path TO venus, public;

-- A tabela de efeitos já contém textos em português e referências de fonte.
-- Quando não houver efeito disponível, a descrição é derivada da função
-- registrada; quando nem isso existir, o texto informa honestamente a lacuna.
DO $$
DECLARE
    r RECORD;
    v_description TEXT;
    v_term TEXT;
    v_clause TEXT;
    v_clauses TEXT[];
BEGIN
    FOR r IN
        SELECT i.ingredient_id,
               i.function_summary,
               c.name AS category_name
          FROM venus.ingredients i
          LEFT JOIN venus.ingredient_categories c
            ON c.ingredient_category_id = i.fk_ingredient_category_id
         WHERE EXISTS (
                   SELECT 1
                     FROM venus.product_ingredients pi
                     JOIN venus.product_versions pv
                       ON pv.product_version_id = pi.fk_product_version_id
                    WHERE pi.fk_ingredient_id = i.ingredient_id
                      AND COALESCE(pv.is_current, TRUE)
               )
           AND COALESCE(BTRIM(i.description), '') = ''
         ORDER BY i.ingredient_id
    LOOP
        SELECT e.effect_description
          INTO v_description
          FROM venus.ingredient_effects e
         WHERE e.fk_ingredient_id = r.ingredient_id
           AND NULLIF(BTRIM(e.effect_description), '') IS NOT NULL
         ORDER BY e.ingredient_effect_id
         LIMIT 1;

        IF v_description IS NULL THEN
            v_clauses := ARRAY[]::TEXT[];

            IF COALESCE(BTRIM(r.function_summary), '') = '' THEN
                IF LOWER(COALESCE(r.category_name, '')) = 'agente perfumante' THEN
                    v_description := 'Confere perfume ao produto.';
                ELSIF LOWER(COALESCE(r.category_name, '')) = 'emoliente' THEN
                    v_description := 'Ajuda a suavizar a pele e reduzir a sensação de ressecamento.';
                ELSE
                    v_description := 'Faz parte da fórmula, mas sua função cosmética específica ainda não está classificada no catálogo.';
                END IF;
            ELSE
                IF LOWER(r.function_summary) LIKE 'agente perfumante%' THEN
                    v_clauses := ARRAY_APPEND(v_clauses, 'dar perfume ao produto');
                ELSIF LOWER(r.function_summary) LIKE 'agente de textura/espessante%' THEN
                    v_clauses := ARRAY_APPEND(v_clauses, 'ajustar a textura e a espessura da fórmula');
                ELSIF LOWER(r.function_summary) LIKE 'antioxidante%' THEN
                    v_clauses := ARRAY_APPEND(v_clauses, 'proteger a fórmula contra oxidação');
                ELSIF LOWER(r.function_summary) LIKE '%nicomethanol hydrofluoride%' THEN
                    v_description := 'Está registrado como aditivo no catálogo, mas sua função cosmética específica ainda precisa de revisão.';
                ELSIF LOWER(r.function_summary) LIKE 'corantes capilares%' THEN
                    v_clauses := ARRAY_APPEND(v_clauses, 'dar cor aos cabelos');
                ELSE
                    FOR v_term IN
                        SELECT BTRIM(value)
                          FROM REGEXP_SPLIT_TO_TABLE(r.function_summary, '\s*;\s*') AS value
                    LOOP
                        v_clause := CASE LOWER(v_term)
                            WHEN 'emollient' THEN 'suavizar a pele e reduzir a sensação de ressecamento'
                            WHEN 'emulsifying' THEN 'misturar ingredientes que normalmente não se misturam'
                            WHEN 'stabilising' THEN 'manter a fórmula estável'
                            WHEN 'stabilizing' THEN 'manter a fórmula estável'
                            WHEN 'opacificantes' THEN 'deixar a fórmula menos transparente'
                            WHEN 'opacifying' THEN 'deixar a fórmula menos transparente'
                            WHEN 'preservative' THEN 'proteger a fórmula contra microrganismos'
                            WHEN 'deodorant' THEN 'reduzir ou mascarar odores'
                            WHEN 'aditivos' THEN 'dar suporte à fórmula'
                            WHEN 'additive' THEN 'dar suporte à fórmula'
                            WHEN 'surfactant' THEN 'limpar e ajudar a misturar água e óleo'
                            WHEN 'antistatic' THEN 'reduzir a eletricidade estática e o frizz'
                            WHEN 'solvent' THEN 'dissolver outros ingredientes'
                            WHEN 'humectant' THEN 'atrair e reter água'
                            WHEN 'uv filter' THEN 'absorver ou filtrar parte da radiação UV'
                            WHEN 'buffering' THEN 'manter o pH da fórmula'
                            WHEN 'biological additive' THEN 'atuar como aditivo de origem biológica'
                            WHEN 'botanical origin' THEN 'fornecer um componente de origem botânica'
                            WHEN 'chelating' THEN 'controlar metais que podem desestabilizar a fórmula'
                            WHEN 'film forming' THEN 'formar uma película fina sobre a pele ou o cabelo'
                            WHEN 'antioxidant' THEN 'proteger a fórmula contra oxidação'
                            WHEN 'viscosity controlling' THEN 'ajustar a espessura da fórmula'
                            WHEN 'abrasive' THEN 'remover resíduos por fricção suave'
                            WHEN 'absorbent' THEN 'absorver oleosidade ou umidade'
                            WHEN 'antifoaming' THEN 'reduzir a formação de espuma'
                            WHEN 'colorant' THEN 'dar cor ao produto'
                            WHEN 'hair colorant' THEN 'dar cor aos cabelos'
                            WHEN 'corantes capilares' THEN 'dar cor aos cabelos'
                            WHEN 'desnaturantes' THEN 'alterar a composição do álcool para torná-lo impróprio para consumo'
                            WHEN 'binding' THEN 'unir ou dar coesão aos ingredientes'
                            WHEN 'hair removing' THEN 'ajudar na remoção dos pelos'
                            WHEN 'reducing' THEN 'participar de reações de redução da fórmula'
                            WHEN 'propellant' THEN 'impulsionar o produto para fora da embalagem'
                            WHEN 'oral care' THEN 'dar suporte à higiene bucal'
                            WHEN 'antiperspirant' THEN 'reduzir a transpiração'
                            ELSE NULL
                        END;

                        IF v_clause IS NULL
                           AND (LOWER(v_term) LIKE '%perfum%'
                                OR LOWER(v_term) LIKE '%fragrance%') THEN
                            v_clause := 'dar perfume ao produto';
                        END IF;

                        IF v_clause IS NULL THEN
                            v_clause := 'dar suporte à formulação';
                        END IF;

                        IF NOT (v_clause = ANY(v_clauses)) THEN
                            v_clauses := ARRAY_APPEND(v_clauses, v_clause);
                        END IF;
                    END LOOP;

                    IF COALESCE(ARRAY_LENGTH(v_clauses, 1), 0) = 0 THEN
                        v_description := 'Faz parte da fórmula, mas sua função cosmética específica ainda não está classificada no catálogo.';
                    ELSIF ARRAY_LENGTH(v_clauses, 1) = 1 THEN
                        v_description := 'Ajuda a ' || v_clauses[1] || '.';
                    ELSE
                        v_description := 'Ajuda a ' || ARRAY_TO_STRING(v_clauses, ', ') || '.';
                    END IF;
                END IF;
            END IF;
        END IF;

        UPDATE venus.ingredients
           SET description = v_description,
               updated_at = NOW()
         WHERE ingredient_id = r.ingredient_id
           AND COALESCE(BTRIM(description), '') = '';
    END LOOP;
END;
$$;

-- IDs canônicos: CeraVe 1, La Roche-Posay 2 e Rexona 28.
DO $$
DECLARE
    v_source_id BIGINT;
    v_target_id BIGINT;
    v_source_name TEXT;
    v_target_name TEXT;
BEGIN
    FOR v_source_id, v_target_id IN
        SELECT source_id, target_id
          FROM (VALUES
                    (4::BIGINT, 1::BIGINT),
                    (5::BIGINT, 2::BIGINT),
                    (21::BIGINT, 28::BIGINT)
               ) AS mapping(source_id, target_id)
    LOOP
        SELECT name INTO v_source_name
          FROM venus.brands
         WHERE brand_id = v_source_id;

        SELECT name INTO v_target_name
          FROM venus.brands
         WHERE brand_id = v_target_id;

        IF v_source_name IS NOT NULL AND v_target_name IS NULL THEN
            RAISE EXCEPTION 'Marca canônica ausente para consolidação: %', v_target_id;
        END IF;

        IF v_source_name IS NOT NULL AND v_source_name <> v_target_name THEN
            RAISE EXCEPTION 'Marca duplicada % não corresponde à canônica %', v_source_name, v_target_name;
        END IF;

        IF v_source_name IS NOT NULL THEN
            UPDATE venus.products
               SET fk_brand_id = v_target_id,
                   updated_at = NOW()
             WHERE fk_brand_id = v_source_id;

            DELETE FROM venus.brands
             WHERE brand_id = v_source_id;
        END IF;
    END LOOP;
END;
$$;

CREATE UNIQUE INDEX IF NOT EXISTS uq_brands_name_normalized
    ON venus.brands (LOWER(BTRIM(name)));

COMMENT ON INDEX venus.uq_brands_name_normalized IS
    'Impede marcas duplicadas por nome normalizado; a ingestão deve resolver para o registro canônico.';

COMMIT;
