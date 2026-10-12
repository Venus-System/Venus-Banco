-- Venus — promover avaliações completas com confidence derivada — 2026-10-12

BEGIN;

SET LOCAL lock_timeout = '10s';
SET LOCAL statement_timeout = '180s';
SET LOCAL search_path TO venus, public;

-- Confidence 0 continua sendo o padrão/desconhecido. Quando há as quatro
-- dimensões v2 aprovadas, fonte e scores não zerados, a confidence é derivada
-- pela função já existente no banco; ela não é marcada como curated.
UPDATE venus.ingredients i
   SET scientific_confidence = venus.fn_calculate_ingredient_confidence(i.ingredient_id),
       scientific_confidence_state = 'derived',
       updated_at = NOW()
 WHERE i.scientific_confidence = 0
   AND venus.fn_calculate_ingredient_confidence(i.ingredient_id) > 1
   AND EXISTS (
       SELECT 1
         FROM venus.product_ingredients pi
         JOIN venus.product_versions pv
           ON pv.product_version_id = pi.fk_product_version_id
          AND pv.is_current
        WHERE pi.fk_ingredient_id = i.ingredient_id
   )
   AND NOT EXISTS (
       SELECT 1
         FROM (VALUES
                   ('irritation_risk_level'),
                   ('comedogenicity_score'),
                   ('biodegradability_level'),
                   ('environmental_risk_level')
              ) AS required(dimension)
        WHERE NOT EXISTS (
            SELECT 1
              FROM venus.ingredient_risk_assessments ira
             WHERE ira.fk_ingredient_id = i.ingredient_id
               AND ira.dimension = required.dimension
               AND ira.assessment_version = 'v2'
               AND ira.assessment_status = 'approved'
               AND BTRIM(ira.source_reference) <> ''
        )
   );

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
            'complete_assessments_promoted_20261012; rerun_base_scores_required'
        );
    END LOOP;
END;
$$;

COMMIT;
