/*
  Uma versão sem ingredientes não pode ser classificada pela API.
  Portanto, ela não pode permanecer como VERIFIED: isso faz consumidores do
  catálogo esperarem um score que não existe e converterem NULL em 0.

  Esta migration não insere ingredientes nem scores. Apenas corrige o estado
  da versão para NEEDS_REVIEW, até que a composição seja cadastrada e validada.
*/
BEGIN;
SET LOCAL search_path TO venus, public;

UPDATE product_versions pv
SET status = 'needs_review',
    updated_at = NOW()
WHERE pv.is_current = TRUE
  AND pv.status = 'verified'
  AND NOT EXISTS (
      SELECT 1
      FROM product_ingredients pi
      WHERE pi.fk_product_version_id = pv.product_version_id
  );

COMMIT;

SELECT 'current_verified_without_ingredients' AS check_name,
       COUNT(*) AS total
FROM venus.product_versions pv
WHERE pv.is_current = TRUE
  AND pv.status = 'verified'
  AND NOT EXISTS (
      SELECT 1
      FROM venus.product_ingredients pi
      WHERE pi.fk_product_version_id = pv.product_version_id
  );
