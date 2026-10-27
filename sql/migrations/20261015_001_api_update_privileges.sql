-- Venus — privilégios de atualização para o usuário da API — 2026-10-15
--
-- O papel api já possui os demais privilégios operacionais em boa parte do
-- schema. Esta migração completa o UPDATE nas tabelas novas adicionadas pelo
-- fluxo de OCR/classificação, incluindo allergy_ingredients e
-- product_composition_receipts.

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'api') THEN
        GRANT USAGE ON SCHEMA venus TO api;
        GRANT UPDATE ON ALL TABLES IN SCHEMA venus TO api;
    END IF;
END;
$$;

