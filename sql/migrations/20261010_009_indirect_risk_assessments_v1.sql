-- Venus — avaliações indiretas auditáveis dos ingredientes — 2026-10-10
--
-- O operador autorizou inferência conservadora para os eixos sem dado direto.
-- Esta migration não chama a API de classificação. Ela apenas registra no
-- banco quatro avaliações v1 por ingrediente, com evidence_level=low,
-- justificativa, sinais usados e fontes metodológicas oficiais.

BEGIN;

SET LOCAL lock_timeout = '10s';
SET LOCAL statement_timeout = '240s';
SET LOCAL search_path TO venus, public;

UPDATE venus.ingredient_risk_methodologies
   SET unknown_policy =
       'Quando não houver evidência direta para um eixo, é permitida uma inferência conservadora, reproduzível e explicitamente marcada como evidence_level=low. A inferência não equivale a uma conclusão toxicológica direta; nova evidência direta deve substituir a avaliação v1.',
       updated_at = NOW()
 WHERE methodology_version = 'v1';

UPDATE venus.ingredient_risk_methodology_dimensions
   SET required_evidence = jsonb_build_object(
       'direct', required_evidence,
       'indirect_allowed', TRUE,
       'indirect_minimum', 'regra determinística documentada, sinais de catálogo preservados em rationale e evidence_level=low'
   )
 WHERE methodology_version = 'v1';

COMMENT ON COLUMN venus.ingredient_risk_assessments.rationale IS
    'Justificativa auditável por dimensão; avaliações indiretas devem declarar os sinais usados e a ausência de concentração/dose.';

CREATE OR REPLACE VIEW venus.v_ingredient_risk_inference_v1 AS
WITH signals AS (
    SELECT i.ingredient_id,
           i.inci_name,
           COALESCE(ic.name, '') AS category_name,
           LOWER(COALESCE(i.inci_name, '')) AS name_lc,
           EXISTS (
               SELECT 1
                 FROM venus.ingredient_effects ie
                WHERE ie.fk_ingredient_id = i.ingredient_id
                  AND ie.effect_category IN ('warning', 'contraindication', 'risk')
                  AND ie.review_status <> 'deprecated'
           ) AS has_warning_effect,
           EXISTS (
               SELECT 1
                 FROM venus.ingredient_regulations ir
                WHERE ir.fk_ingredient_id = i.ingredient_id
                  AND ir.source_type = 'ocr'
                  AND ir.restriction_type IN ('warning', 'restricted', 'limited', 'prohibited')
           ) AS has_ocr_regulation
      FROM venus.ingredients i
      LEFT JOIN venus.ingredient_categories ic
        ON ic.ingredient_category_id = i.fk_ingredient_category_id
), scored AS (
    SELECT s.*,
           GREATEST(1, LEAST(10,
               1
               + CASE WHEN s.category_name ILIKE '%tensoativo%'
                            OR s.category_name ILIKE '%solvente%'
                            OR s.category_name ILIKE '%conservante%'
                            OR s.category_name ILIKE '%filtro uv%'
                            OR s.category_name ILIKE '%perfumante%'
                      THEN 1 ELSE 0 END
               + CASE WHEN s.name_lc ~ '(acid|hydroxide|sulfate|surfact|retinol|alcohol denat|peroxide)'
                      THEN 2 ELSE 0 END
               + CASE WHEN s.name_lc ~ '(parfum|fragrance|cinnamal|limonene|linalool|benzyl|isothiazolinone|phenoxyethanol)'
                      THEN 2 ELSE 0 END
               + CASE WHEN s.has_warning_effect THEN 2 ELSE 0 END
               + CASE WHEN s.has_ocr_regulation THEN 2 ELSE 0 END
           ))::SMALLINT AS irritation_score,
           GREATEST(1, LEAST(10,
               1
               + CASE WHEN s.category_name ILIKE '%emoliente%'
                            OR s.category_name ILIKE '%emulsionante%'
                      THEN 1 ELSE 0 END
               + CASE WHEN s.name_lc ~ '(isopropyl palmitate|myristic acid|palmitic acid|coconut|cocoa|shea|oleate|stearate|palmitate|laurate|glyceryl|lanolin|cetearyl|cetyl alcohol|stearyl alcohol|triglyceride|isononanoate|alkyl benzoate)'
                      THEN 2 ELSE 0 END
               + CASE WHEN s.name_lc ~ '(petrolatum|paraffin|mineral oil|squalane|dimethicone)'
                      THEN 1 ELSE 0 END
           ))::SMALLINT AS comedogenicity_score,
           GREATEST(1, LEAST(10,
               4
               + CASE WHEN s.category_name ILIKE '%formador de filme%'
                            OR s.category_name ILIKE '%antiespumante%'
                      THEN 2 ELSE 0 END
               + CASE WHEN s.category_name ILIKE '%filtro uv%'
                            OR s.category_name ILIKE '%agente quelante%'
                            OR s.category_name ILIKE '%perfumante%'
                            OR s.category_name ILIKE '%estabilizante%'
                      THEN 1 ELSE 0 END
               + CASE WHEN s.name_lc ~ '(siloxane|dimethicone|acrylate|polyacryl|crosspolymer|silicone|peg-|ppg-|poloxamer|parfum|fragrance|edta|bht|titanium dioxide|zinc oxide)'
                      THEN 2 ELSE 0 END
               + CASE WHEN s.name_lc ~ '(aqua|water|glycerin|glycol|sodium chloride|citric acid|lactic acid|amino|starch|extract|oil|butter)'
                      THEN -2 ELSE 0 END
           ))::SMALLINT AS biodegradability_score,
           GREATEST(1, LEAST(10,
               2
               + CASE WHEN s.category_name ILIKE '%tensoativo%'
                            OR s.category_name ILIKE '%conservante%'
                            OR s.category_name ILIKE '%agente quelante%'
                            OR s.category_name ILIKE '%antiespumante%'
                      THEN 1 ELSE 0 END
               + CASE WHEN s.category_name ILIKE '%filtro uv%'
                            OR s.category_name ILIKE '%perfumante%'
                            OR s.category_name ILIKE '%formador de filme%'
                      THEN 2 ELSE 0 END
               + CASE WHEN s.name_lc ~ '(siloxane|dimethicone|acrylate|polyacryl|crosspolymer|peg-|ppg-|poloxamer|parfum|fragrance|benzotriazole|octocrylene|homosalate|ethylhexyl salicylate|edta|bht)'
                      THEN 2 ELSE 0 END
               + CASE WHEN s.has_warning_effect THEN 2 ELSE 0 END
               + CASE WHEN s.has_ocr_regulation THEN 2 ELSE 0 END
               + CASE WHEN s.name_lc ~ '(aqua|water|glycerin|sodium chloride|amino|starch|citric acid|lactic acid)'
                      THEN -1 ELSE 0 END
           ))::SMALLINT AS environmental_score
      FROM signals s
)
SELECT s.ingredient_id,
       s.inci_name,
       s.irritation_score,
       s.comedogenicity_score,
       s.biodegradability_score,
       s.environmental_score,
       FORMAT(
           'https://health.ec.europa.eu/scientific-committees/scientific-committee-consumer-safety-sccs_en | https://echa.europa.eu/information-on-chemicals | https://single-market-economy.ec.europa.eu/sectors/cosmetics/cosmetic-ingredient-database_en | methodology=v1; inference=indirect; evidence_level=low; ingredient_id=%s; category=%s; warning_effect=%s; ocr_regulation=%s',
           s.ingredient_id,
           REPLACE(REPLACE(s.category_name, '|', ' '), ';', ' '),
           s.has_warning_effect,
           s.has_ocr_regulation
       ) AS source_reference,
       FORMAT(
           'v1 indireta; score=%s; sinais categoria=%s, efeito de alerta=%s, regulação OCR=%s; proxy conservadora sem concentração, dose ou conclusão toxicológica direta.',
           s.irritation_score, s.category_name, s.has_warning_effect, s.has_ocr_regulation
       ) AS irritation_rationale,
       FORMAT(
           'v1 indireta; score=%s; sinais categoria=%s e padrões INCI=%s; não há medição específica de comedogenicidade neste catálogo, portanto o valor é um proxy estrutural conservador.',
           s.comedogenicity_score, s.category_name, s.name_lc
       ) AS comedogenicity_rationale,
       FORMAT(
           'v1 indireta; score=%s; sinais categoria=%s e padrões INCI=%s; persistência/biodegradação direta não está disponível para este ingrediente, portanto o valor é um proxy conservador.',
           s.biodegradability_score, s.category_name, s.name_lc
       ) AS biodegradability_rationale,
       FORMAT(
           'v1 indireta; score=%s; sinais categoria=%s, efeito de alerta=%s, regulação OCR=%s e padrões INCI=%s; não substitui avaliação ambiental específica.',
           s.environmental_score, s.category_name, s.has_warning_effect, s.has_ocr_regulation, s.name_lc
       ) AS environmental_rationale
  FROM scored s;

CREATE OR REPLACE PROCEDURE venus.sp_approve_ingredient_risk_assessment_v1(
    p_ingredient_id BIGINT,
    p_irritation_risk_level SMALLINT,
    p_comedogenicity_score SMALLINT,
    p_biodegradability_level SMALLINT,
    p_environmental_risk_level SMALLINT,
    p_source_reference TEXT,
    p_irritation_rationale TEXT,
    p_comedogenicity_rationale TEXT,
    p_biodegradability_rationale TEXT,
    p_environmental_rationale TEXT,
    p_evidence_level evidence_level_enum DEFAULT 'low',
    p_assessment_scope TEXT DEFAULT 'ingredient_baseline_indirect_v1',
    p_assessment_version TEXT DEFAULT 'v1'
)
LANGUAGE PLPGSQL
AS $$
BEGIN
    IF NULLIF(BTRIM(p_source_reference), '') IS NULL THEN
        RAISE EXCEPTION 'source_reference é obrigatório para avaliação v1';
    END IF;

    IF p_irritation_risk_level IS NULL OR p_irritation_risk_level NOT BETWEEN 0 AND 10
       OR p_comedogenicity_score IS NULL OR p_comedogenicity_score NOT BETWEEN 0 AND 10
       OR p_biodegradability_level IS NULL OR p_biodegradability_level NOT BETWEEN 0 AND 10
       OR p_environmental_risk_level IS NULL OR p_environmental_risk_level NOT BETWEEN 0 AND 10 THEN
        RAISE EXCEPTION 'todos os quatro scores v1 devem estar entre 0 e 10';
    END IF;

    INSERT INTO venus.ingredient_risk_assessments (
        fk_ingredient_id, dimension, score, assessment_status, source_type,
        source_reference, assessment_version, evidence_level, rationale,
        assessment_scope, assessed_at, updated_at
    ) VALUES
        (p_ingredient_id, 'irritation_risk_level', p_irritation_risk_level,
         'approved', 'system', BTRIM(p_source_reference), p_assessment_version,
         p_evidence_level, COALESCE(p_irritation_rationale, ''), p_assessment_scope, NOW(), NOW()),
        (p_ingredient_id, 'comedogenicity_score', p_comedogenicity_score,
         'approved', 'system', BTRIM(p_source_reference), p_assessment_version,
         p_evidence_level, COALESCE(p_comedogenicity_rationale, ''), p_assessment_scope, NOW(), NOW()),
        (p_ingredient_id, 'biodegradability_level', p_biodegradability_level,
         'approved', 'system', BTRIM(p_source_reference), p_assessment_version,
         p_evidence_level, COALESCE(p_biodegradability_rationale, ''), p_assessment_scope, NOW(), NOW()),
        (p_ingredient_id, 'environmental_risk_level', p_environmental_risk_level,
         'approved', 'system', BTRIM(p_source_reference), p_assessment_version,
         p_evidence_level, COALESCE(p_environmental_rationale, ''), p_assessment_scope, NOW(), NOW())
    ON CONFLICT (fk_ingredient_id, dimension, assessment_version)
    DO UPDATE SET
        score = EXCLUDED.score,
        assessment_status = 'approved',
        source_type = EXCLUDED.source_type,
        source_reference = EXCLUDED.source_reference,
        evidence_level = EXCLUDED.evidence_level,
        rationale = EXCLUDED.rationale,
        assessment_scope = EXCLUDED.assessment_scope,
        assessed_at = NOW(),
        updated_at = NOW();

    PERFORM set_config('venus.allow_risk_sync', 'on', TRUE);
    UPDATE venus.ingredients
       SET irritation_risk_level = p_irritation_risk_level,
           comedogenicity_score = p_comedogenicity_score,
           biodegradability_level = p_biodegradability_level,
           environmental_risk_level = p_environmental_risk_level,
           updated_at = NOW()
     WHERE ingredient_id = p_ingredient_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'ingredient_id inexistente: %', p_ingredient_id;
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION venus.fn_refresh_ingredient_risk_assessment_v1(
    p_ingredient_id BIGINT
)
RETURNS VOID
LANGUAGE PLPGSQL
AS $$
DECLARE
    v RECORD;
BEGIN
    SELECT *
      INTO v
      FROM venus.v_ingredient_risk_inference_v1
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
        'ingredient_baseline_indirect_v1',
        'v1'
    );
END;
$$;

CREATE OR REPLACE FUNCTION venus.fn_auto_refresh_ingredient_risk_from_ingredient()
RETURNS TRIGGER
LANGUAGE PLPGSQL
AS $$
BEGIN
    PERFORM venus.fn_refresh_ingredient_risk_assessment_v1(NEW.ingredient_id);
    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION venus.fn_auto_refresh_ingredient_risk_from_fk()
RETURNS TRIGGER
LANGUAGE PLPGSQL
AS $$
BEGIN
    PERFORM venus.fn_refresh_ingredient_risk_assessment_v1(
        CASE WHEN TG_OP = 'DELETE' THEN OLD.fk_ingredient_id ELSE NEW.fk_ingredient_id END
    );
    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_auto_infer_ingredient_risk_v1
    ON venus.ingredients;
CREATE TRIGGER trg_auto_infer_ingredient_risk_v1
AFTER INSERT OR UPDATE OF fk_ingredient_category_id, inci_name, common_name
ON venus.ingredients
FOR EACH ROW
EXECUTE FUNCTION venus.fn_auto_refresh_ingredient_risk_from_ingredient();

DROP TRIGGER IF EXISTS trg_auto_refresh_risk_from_properties_v1
    ON venus.ingredient_properties;
CREATE TRIGGER trg_auto_refresh_risk_from_properties_v1
AFTER INSERT OR UPDATE OR DELETE
ON venus.ingredient_properties
FOR EACH ROW
EXECUTE FUNCTION venus.fn_auto_refresh_ingredient_risk_from_fk();

DROP TRIGGER IF EXISTS trg_auto_refresh_risk_from_regulations_v1
    ON venus.ingredient_regulations;
CREATE TRIGGER trg_auto_refresh_risk_from_regulations_v1
AFTER INSERT OR UPDATE OR DELETE
ON venus.ingredient_regulations
FOR EACH ROW
EXECUTE FUNCTION venus.fn_auto_refresh_ingredient_risk_from_fk();

DROP TRIGGER IF EXISTS trg_auto_refresh_risk_from_effects_v1
    ON venus.ingredient_effects;
CREATE TRIGGER trg_auto_refresh_risk_from_effects_v1
AFTER INSERT OR UPDATE OR DELETE
ON venus.ingredient_effects
FOR EACH ROW
EXECUTE FUNCTION venus.fn_auto_refresh_ingredient_risk_from_fk();

DO $$
DECLARE
    v RECORD;
BEGIN
    FOR v IN
        SELECT vi.ingredient_id
          FROM venus.v_ingredient_risk_inference_v1 vi
         WHERE EXISTS (
             SELECT 1
               FROM venus.product_ingredients pi
               JOIN venus.product_versions pv
                 ON pv.product_version_id = pi.fk_product_version_id
                AND pv.is_current
              WHERE pi.fk_ingredient_id = vi.ingredient_id
         )
         ORDER BY vi.ingredient_id
    LOOP
        PERFORM venus.fn_refresh_ingredient_risk_assessment_v1(v.ingredient_id);
    END LOOP;
END;
$$;

COMMENT ON VIEW venus.v_ingredient_risk_inference_v1 IS
    'Regra determinística v1 para inferência conservadora; os scores aprovados carregam evidence_level=low e não são conclusões toxicológicas diretas.';

COMMIT;
