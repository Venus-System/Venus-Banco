BEGIN;
SET LOCAL search_path TO venus, public;

DO $$
DECLARE
    v_model_id BIGINT;
    v_total INTEGER;
BEGIN
    SELECT scoring_model_id INTO STRICT v_model_id
    FROM venus.scoring_models
    WHERE name = 'Transparência de Ingredientes' AND version = '1.0.0';

    SELECT COUNT(*) INTO v_total
    FROM venus.scoring_model_categories smc
    JOIN venus.score_categories sc ON sc.score_category_id = smc.fk_score_category_id
    WHERE smc.fk_scoring_model_id = v_model_id
      AND sc.name IN ('Transparência','Integridade do Claim','Qualidade dos Ingredientes','Evidência Científica');

    IF v_total <> 4 THEN
        RAISE EXCEPTION 'Esperadas 4 categorias; encontradas %', v_total;
    END IF;
END $$;

UPDATE venus.scoring_model_categories smc
SET weight = CASE sc.name
    WHEN 'Qualidade dos Ingredientes' THEN 45.00
    WHEN 'Evidência Científica' THEN 35.00
    WHEN 'Transparência' THEN sc.default_weight
    WHEN 'Integridade do Claim' THEN sc.default_weight
END,
updated_at = NOW()
FROM venus.score_categories sc, venus.scoring_models sm
WHERE sm.scoring_model_id = smc.fk_scoring_model_id
  AND sc.score_category_id = smc.fk_score_category_id
  AND sm.name = 'Transparência de Ingredientes'
  AND sm.version = '1.0.0'
  AND sc.name IN ('Transparência','Integridade do Claim','Qualidade dos Ingredientes','Evidência Científica');

COMMIT;

SELECT sc.name AS categoria, smc.weight, sc.default_weight
FROM venus.scoring_model_categories smc
JOIN venus.score_categories sc ON sc.score_category_id = smc.fk_score_category_id
JOIN venus.scoring_models sm ON sm.scoring_model_id = smc.fk_scoring_model_id
WHERE sm.name = 'Transparência de Ingredientes'
  AND sm.version = '1.0.0'
  AND sc.name IN ('Transparência','Integridade do Claim','Qualidade dos Ingredientes','Evidência Científica')
ORDER BY sc.name;
