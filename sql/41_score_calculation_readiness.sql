-- Regras de preparação para o recálculo oficial dos scores.
--
-- Este arquivo não calcula, insere ou corrige scores. A gravação dos valores
-- continua sendo responsabilidade exclusiva da API Venus-Classificacao.
-- Ele apenas documenta a consulta de reconciliação que deve ser usada antes
-- e depois de POST /api/base-scores.

-- Versões atuais elegíveis para cálculo pela API:
-- status VERIFIED + pelo menos um ingrediente vinculado.
SELECT
    pv.product_version_id,
    pv.fk_product_id,
    pv.status,
    COUNT(pi.product_ingredient_id) AS ingredient_count,
    ps.product_score_id,
    ps.overall_score,
    ps.calculated_at
FROM product_versions pv
JOIN product_ingredients pi
    ON pi.fk_product_version_id = pv.product_version_id
JOIN scoring_models sm
    ON sm.is_active = TRUE
LEFT JOIN product_scores ps
    ON ps.fk_product_version_id = pv.product_version_id
   AND ps.fk_scoring_model_id = sm.scoring_model_id
WHERE pv.is_current = TRUE
  AND pv.status = 'verified'
GROUP BY
    pv.product_version_id,
    pv.fk_product_id,
    pv.status,
    ps.product_score_id,
    ps.overall_score,
    ps.calculated_at
ORDER BY pv.product_version_id;

-- Versões que a API deve reportar como ignoradas, sem score numérico:
-- * needs_review: VERSION_UNDER_REVIEW
-- * verified sem ingredientes: NO_INGREDIENTS
SELECT
    pv.product_version_id,
    pv.fk_product_id,
    pv.status,
    COUNT(pi.product_ingredient_id) AS ingredient_count,
    CASE
        WHEN pv.status = 'needs_review' THEN 'VERSION_UNDER_REVIEW'
        WHEN COUNT(pi.product_ingredient_id) = 0 THEN 'NO_INGREDIENTS'
    END AS skip_reason
FROM product_versions pv
LEFT JOIN product_ingredients pi
    ON pi.fk_product_version_id = pv.product_version_id
WHERE pv.is_current = TRUE
  AND (pv.status = 'needs_review' OR pv.status = 'verified')
GROUP BY pv.product_version_id, pv.fk_product_id, pv.status
HAVING pv.status = 'needs_review' OR COUNT(pi.product_ingredient_id) = 0
ORDER BY pv.product_version_id;
