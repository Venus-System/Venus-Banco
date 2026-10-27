/*
  Confidence score — regra positiva e derivação centralizada.

  Política:
  - 1 é o piso técnico e significa evidência insuficiente, mas conhecida;
  - 100 é o teto;
  - 0 deixa de ser um valor válido para ingredientes e resultados de
    classificação;
  - a confiança de produto/análise é derivada da confiança dos ingredientes
    vinculados à versão do produto.
*/
BEGIN;
SET LOCAL search_path TO venus, public;

CREATE OR REPLACE FUNCTION venus.fn_calculate_ingredient_confidence(
    p_ingredient_id BIGINT
)
RETURNS SMALLINT
LANGUAGE sql
STABLE
AS $function$
WITH evidence AS (
    SELECT
        i.source_type::TEXT AS source_type,
        LOWER(COALESCE(i.source_reference, '')) AS source_reference,
        COALESCE(MAX(CASE e.evidence_level::TEXT
            WHEN 'very_high' THEN 15
            WHEN 'high' THEN 10
            WHEN 'medium' THEN 5
            WHEN 'low' THEN 2
            ELSE 0
        END), 0) AS evidence_points,
        COALESCE(MAX(CASE e.review_status::TEXT
            WHEN 'validated' THEN 10
            WHEN 'under_review' THEN 5
            WHEN 'deprecated' THEN -20
            ELSE 0
        END), 0) AS review_points
    FROM venus.ingredients i
    LEFT JOIN venus.ingredient_effects e
      ON e.fk_ingredient_id = i.ingredient_id
    WHERE i.ingredient_id = p_ingredient_id
    GROUP BY i.source_type, i.source_reference
)
SELECT LEAST(100, GREATEST(1,
    CASE
        WHEN source_type = 'import' AND source_reference <> '' THEN 45
        WHEN source_type = 'import' THEN 10
        WHEN source_type = 'official_site' THEN 60
        WHEN source_type = 'admin' THEN 40
        WHEN source_type = 'ocr' THEN 25
        WHEN source_type = 'system' THEN 20
        WHEN source_type = 'user_submission' THEN 10
        ELSE 1
    END
    + CASE WHEN source_reference LIKE '%pubchem%' THEN 15 ELSE 0 END
    + CASE WHEN source_reference LIKE '%anvisa%' THEN 10 ELSE 0 END
    + CASE WHEN source_reference LIKE '%eur-lex%' THEN 10 ELSE 0 END
    + evidence_points
    + review_points
))::SMALLINT
FROM evidence;
$function$;

CREATE OR REPLACE FUNCTION venus.fn_calculate_product_confidence(
    p_product_version_id BIGINT
)
RETURNS SMALLINT
LANGUAGE sql
STABLE
AS $function$
SELECT GREATEST(1, LEAST(100,
    COALESCE(ROUND(AVG(i.scientific_confidence))::INTEGER, 1)
))::SMALLINT
FROM venus.product_ingredients pi
JOIN venus.ingredients i
  ON i.ingredient_id = pi.fk_ingredient_id
WHERE pi.fk_product_version_id = p_product_version_id;
$function$;

CREATE OR REPLACE FUNCTION venus.fn_set_derived_confidence_score()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $function$
BEGIN
    NEW.confidence_score := venus.fn_calculate_product_confidence(
        NEW.fk_product_version_id
    );
    RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION venus.fn_set_recommendation_confidence_score()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $function$
BEGIN
    NEW.confidence_score := COALESCE(
        (SELECT ar.confidence_score
           FROM venus.analysis_results ar
          WHERE ar.analysis_result_id = NEW.fk_analysis_result_id),
        venus.fn_calculate_product_confidence(NEW.fk_product_version_id),
        1
    );
    RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION venus.fn_refresh_confidence_after_ingredient_update()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $function$
BEGIN
    UPDATE venus.product_scores ps
       SET confidence_score = venus.fn_calculate_product_confidence(pi.fk_product_version_id),
           updated_at = NOW()
      FROM venus.product_ingredients pi
     WHERE pi.fk_ingredient_id = NEW.ingredient_id
       AND ps.fk_product_version_id = pi.fk_product_version_id;

    UPDATE venus.analysis_results ar
       SET confidence_score = venus.fn_calculate_product_confidence(pi.fk_product_version_id),
           updated_at = NOW()
      FROM venus.product_ingredients pi
     WHERE pi.fk_ingredient_id = NEW.ingredient_id
       AND ar.fk_product_version_id = pi.fk_product_version_id;

    RETURN NEW;
END;
$function$;

UPDATE venus.ingredients i
SET scientific_confidence = venus.fn_calculate_ingredient_confidence(i.ingredient_id),
    updated_at = NOW()
WHERE i.scientific_confidence IS NULL
   OR i.scientific_confidence <= 0;

ALTER TABLE venus.ingredients
    ALTER COLUMN scientific_confidence SET DEFAULT 1;

ALTER TABLE venus.ingredients
    DROP CONSTRAINT IF EXISTS ck_ingredients_scientific_confidence_range;

ALTER TABLE venus.ingredients
    ADD CONSTRAINT ck_ingredients_scientific_confidence_range
    CHECK (scientific_confidence BETWEEN 1 AND 100);

DROP TRIGGER IF EXISTS trg_derive_product_scores_confidence ON venus.product_scores;
CREATE TRIGGER trg_derive_product_scores_confidence
BEFORE INSERT OR UPDATE ON venus.product_scores
FOR EACH ROW
EXECUTE FUNCTION venus.fn_set_derived_confidence_score();

DROP TRIGGER IF EXISTS trg_derive_analysis_results_confidence ON venus.analysis_results;
CREATE TRIGGER trg_derive_analysis_results_confidence
BEFORE INSERT OR UPDATE ON venus.analysis_results
FOR EACH ROW
EXECUTE FUNCTION venus.fn_set_derived_confidence_score();

DROP TRIGGER IF EXISTS trg_derive_recommendations_confidence ON venus.recommendations;
CREATE TRIGGER trg_derive_recommendations_confidence
BEFORE INSERT OR UPDATE ON venus.recommendations
FOR EACH ROW
EXECUTE FUNCTION venus.fn_set_recommendation_confidence_score();

DROP TRIGGER IF EXISTS trg_refresh_confidence_after_ingredient_update ON venus.ingredients;
CREATE TRIGGER trg_refresh_confidence_after_ingredient_update
AFTER UPDATE OF scientific_confidence ON venus.ingredients
FOR EACH ROW
WHEN (OLD.scientific_confidence IS DISTINCT FROM NEW.scientific_confidence)
EXECUTE FUNCTION venus.fn_refresh_confidence_after_ingredient_update();

UPDATE venus.product_scores ps
SET confidence_score = venus.fn_calculate_product_confidence(ps.fk_product_version_id),
    updated_at = NOW();

UPDATE venus.analysis_results ar
SET confidence_score = venus.fn_calculate_product_confidence(ar.fk_product_version_id),
    updated_at = NOW();

UPDATE venus.recommendations r
SET confidence_score = COALESCE(
        (SELECT ar.confidence_score
           FROM venus.analysis_results ar
          WHERE ar.analysis_result_id = r.fk_analysis_result_id),
        venus.fn_calculate_product_confidence(r.fk_product_version_id),
        1
    ),
    updated_at = NOW();

ALTER TABLE venus.product_scores
    ALTER COLUMN confidence_score SET DEFAULT 1,
    ALTER COLUMN confidence_score SET NOT NULL;

ALTER TABLE venus.analysis_results
    ALTER COLUMN confidence_score SET DEFAULT 1,
    ALTER COLUMN confidence_score SET NOT NULL;

ALTER TABLE venus.recommendations
    ALTER COLUMN confidence_score SET DEFAULT 1;

ALTER TABLE venus.product_scores
    DROP CONSTRAINT IF EXISTS ck_product_scores_confidence_score_range;
ALTER TABLE venus.product_scores
    ADD CONSTRAINT ck_product_scores_confidence_score_range
    CHECK (confidence_score BETWEEN 1 AND 100);

ALTER TABLE venus.analysis_results
    DROP CONSTRAINT IF EXISTS ck_analysis_results_confidence_score_range;
ALTER TABLE venus.analysis_results
    ADD CONSTRAINT ck_analysis_results_confidence_score_range
    CHECK (confidence_score BETWEEN 1 AND 100);

ALTER TABLE venus.recommendations
    DROP CONSTRAINT IF EXISTS ck_recommendations_confidence_score_range;
ALTER TABLE venus.recommendations
    ADD CONSTRAINT ck_recommendations_confidence_score_range
    CHECK (confidence_score BETWEEN 1 AND 100);

COMMIT;

SELECT 'ingredients_confidence_zero' AS check_name,
       COUNT(*) AS total
FROM venus.ingredients
WHERE scientific_confidence <= 0;

SELECT 'classification_confidence_invalid' AS check_name,
       COUNT(*) AS total
FROM (
    SELECT confidence_score FROM venus.product_scores
    UNION ALL
    SELECT confidence_score FROM venus.analysis_results
    UNION ALL
    SELECT confidence_score FROM venus.recommendations
) scores
WHERE confidence_score IS NULL OR confidence_score NOT BETWEEN 1 AND 100;
