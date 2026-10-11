/*
  Remove apenas artefatos criados pelo seed técnico anterior.

  Esta migration não calcula nem insere scores. Scores reais continuam sendo
  responsabilidade exclusiva da Venus-Classificacao. Ela é idempotente e
  remove apenas:
    1. product_scores zerados de versões que a API não pode calcular;
    2. análises/personalized_scores marcados explicitamente pelo seed.

  Scores zerados de versões verificadas com ingredientes não são removidos:
  a próxima execução da API deve sobrescrevê-los com o resultado calculado.
*/
BEGIN;
SET LOCAL search_path TO venus, public;

-- Esses registros nunca poderiam ter sido produzidos pelo base-score API:
-- versão em análise ou versão sem composição.
DELETE FROM product_scores ps
USING product_versions pv
WHERE ps.fk_product_version_id = pv.product_version_id
  AND ps.overall_score = 0
  AND COALESCE(ps.health_score, 0) = 0
  AND COALESCE(ps.environmental_score, 0) = 0
  AND COALESCE(ps.ethical_score, 0) = 0
  AND COALESCE(ps.performance_score, 0) = 0
  AND COALESCE(ps.transparency_score, 0) = 0
  AND (
      pv.status = 'needs_review'
      OR NOT EXISTS (
          SELECT 1
          FROM product_ingredients pi
          WHERE pi.fk_product_version_id = pv.product_version_id
      )
  );

-- O seed antigo criava análises falsas identificadas pelo próprio summary.
-- Remover dependências primeiro deixa a migration independente das regras de
-- cascade configuradas no banco existente.
DELETE FROM recommendations r
USING analysis_results ar
WHERE r.fk_analysis_result_id = ar.analysis_result_id
  AND ar.summary LIKE 'SEED TÉCNICO:%';

DELETE FROM rule_evaluations re
USING analysis_results ar
WHERE re.fk_analysis_result_id = ar.analysis_result_id
  AND ar.summary LIKE 'SEED TÉCNICO:%';

DELETE FROM personalized_scores ps
USING analysis_results ar
WHERE ps.fk_analysis_result_id = ar.analysis_result_id
  AND ar.summary LIKE 'SEED TÉCNICO:%';

DELETE FROM analysis_results
WHERE summary LIKE 'SEED TÉCNICO:%';

COMMIT;

-- Evidência pós-migration: estas duas consultas devem retornar zero.
SELECT 'placeholder_product_scores_in_blocked_versions' AS check_name,
       COUNT(*) AS total
FROM venus.product_scores ps
JOIN venus.product_versions pv
  ON pv.product_version_id = ps.fk_product_version_id
WHERE ps.overall_score = 0
  AND COALESCE(ps.health_score, 0) = 0
  AND COALESCE(ps.environmental_score, 0) = 0
  AND COALESCE(ps.ethical_score, 0) = 0
  AND COALESCE(ps.performance_score, 0) = 0
  AND COALESCE(ps.transparency_score, 0) = 0
  AND (
      pv.status = 'needs_review'
      OR NOT EXISTS (
          SELECT 1
          FROM venus.product_ingredients pi
          WHERE pi.fk_product_version_id = pv.product_version_id
      )
  );

SELECT 'seed_analysis_results_remaining' AS check_name,
       COUNT(*) AS total
FROM venus.analysis_results
WHERE summary LIKE 'SEED TÉCNICO:%';
