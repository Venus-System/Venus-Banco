
SELECT
    id AS legacy_product_id,
    nome AS product_name,
    marca AS brand_name,
    categoria AS category_name,
    ingredientes AS ingredients_text
FROM public.produtos;

SELECT
    id AS legacy_user_id,
    nome AS full_name,
    email,
    status AS status_text
FROM public.usuarios;
