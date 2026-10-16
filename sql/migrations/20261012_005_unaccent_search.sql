-- Habilita busca sem acento para o CRUD.
--
-- A extensão fica no schema venus porque a API conecta com
-- currentSchema=venus e não deve depender de funções instaladas em public.
-- Esta migration não altera nomes nem índices; ela disponibiliza
-- venus.unaccent(...) para o ProductRepository e IngredientRepository.

DO $$
DECLARE
    v_schema TEXT;
BEGIN
    SELECT n.nspname
      INTO v_schema
      FROM pg_extension e
      JOIN pg_namespace n ON n.oid = e.extnamespace
     WHERE e.extname = 'unaccent';

    IF v_schema IS NULL THEN
        CREATE EXTENSION unaccent WITH SCHEMA venus;
    ELSIF v_schema <> 'venus' THEN
        RAISE EXCEPTION
            'a extensão unaccent já existe no schema %, mas o contrato do CRUD exige venus',
            v_schema;
    END IF;
END;
$$;

COMMENT ON EXTENSION unaccent IS
    'Normalização de acentos para buscas do CRUD; instalada no schema venus.';

SELECT
    venus.unaccent('Loção') AS normalized_product_name,
    venus.unaccent('locao') AS normalized_query,
    venus.unaccent(lower('Loção')) LIKE '%' || venus.unaccent(lower('locao')) || '%' AS matches_without_accent;
