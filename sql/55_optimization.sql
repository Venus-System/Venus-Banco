CREATE SCHEMA IF NOT EXISTS venus_optimization;
CREATE TABLE IF NOT EXISTS venus_optimization.readme(item TEXT PRIMARY KEY, description TEXT NOT NULL);
INSERT INTO venus_optimization.readme VALUES
('products_by_category','Validação do índice de categoria/status em products.'),
('ingredients_by_category','Validação do índice de categoria em ingredients.'),
('analysis_by_user','Validação do índice por usuário em analysis_results.'),
('product_ingredients_by_version','Validação da associação por versão de produto.')
ON CONFLICT (item) DO UPDATE SET description=EXCLUDED.description;

EXPLAIN (ANALYZE, BUFFERS)
SELECT p.product_id,p.name,pc.name AS category FROM venus.products p
JOIN venus.product_categories pc ON pc.product_category_id=p.fk_product_category_id
WHERE p.is_active=TRUE ORDER BY p.fk_product_category_id,p.name LIMIT 50;

EXPLAIN (ANALYZE, BUFFERS)
SELECT i.ingredient_id,i.inci_name FROM venus.ingredients i
WHERE i.fk_ingredient_category_id=(SELECT MIN(ingredient_category_id) FROM venus.ingredient_categories)
ORDER BY i.inci_name LIMIT 100;

EXPLAIN (ANALYZE, BUFFERS)
SELECT ar.analysis_result_id,ar.status,ar.created_at FROM venus.analysis_results ar
WHERE ar.fk_user_id=(SELECT MIN(user_id) FROM venus.users)
ORDER BY ar.created_at DESC LIMIT 100;

EXPLAIN (ANALYZE, BUFFERS)
SELECT pi.fk_product_version_id,pi.fk_ingredient_id,pi.position FROM venus.product_ingredients pi
WHERE pi.fk_product_version_id=(SELECT MIN(product_version_id) FROM venus.product_versions)
ORDER BY pi.position;
