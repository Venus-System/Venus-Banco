CREATE SCHEMA IF NOT EXISTS venus_rpa;
SET search_path TO venus_rpa, public;
CREATE TABLE IF NOT EXISTS rpa_run (
 batch_id UUID PRIMARY KEY, started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), finished_at TIMESTAMPTZ,
 status TEXT NOT NULL CHECK(status IN ('RUNNING','SUCCESS','PARTIAL','FAILED')),
 source_database TEXT, source_products_query_hash TEXT, source_users_query_hash TEXT,
 records_read INTEGER NOT NULL DEFAULT 0, records_transformed INTEGER NOT NULL DEFAULT 0,
 records_loaded INTEGER NOT NULL DEFAULT 0, records_failed INTEGER NOT NULL DEFAULT 0, error_message TEXT);
CREATE TABLE IF NOT EXISTS rpa_error(
 error_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY, batch_id UUID NOT NULL REFERENCES rpa_run(batch_id) ON DELETE CASCADE,
 source_table TEXT NOT NULL, legacy_id BIGINT, error_type TEXT NOT NULL, error_message TEXT NOT NULL, payload JSONB, created_at TIMESTAMPTZ NOT NULL DEFAULT NOW());
CREATE TABLE IF NOT EXISTS rpa_stage_product(
 batch_id UUID NOT NULL REFERENCES rpa_run(batch_id) ON DELETE CASCADE, legacy_product_id BIGINT NOT NULL,
 product_name TEXT, brand_name TEXT, category_name TEXT, ingredients_text TEXT,
 normalized_product_name TEXT, normalized_brand_name TEXT, normalized_category_name TEXT,
 validation_status TEXT NOT NULL CHECK(validation_status IN ('VALID','INVALID','WARNING')), validation_message TEXT,
 loaded_product_id BIGINT REFERENCES venus.products(product_id) ON DELETE SET NULL,
 PRIMARY KEY(batch_id,legacy_product_id));
CREATE TABLE IF NOT EXISTS rpa_stage_user(
 batch_id UUID NOT NULL REFERENCES rpa_run(batch_id) ON DELETE CASCADE, legacy_user_id BIGINT NOT NULL,
 full_name TEXT, email TEXT, status_text TEXT, normalized_name TEXT, normalized_email TEXT, status_normalized TEXT,
 validation_status TEXT NOT NULL CHECK(validation_status IN ('VALID','INVALID','WARNING')), validation_message TEXT,
 loaded_user_id BIGINT REFERENCES venus.users(user_id) ON DELETE SET NULL,
 PRIMARY KEY(batch_id,legacy_user_id));
CREATE INDEX IF NOT EXISTS idx_rpa_run_status ON rpa_run(status);
CREATE INDEX IF NOT EXISTS idx_rpa_error_batch ON rpa_error(batch_id);
CREATE INDEX IF NOT EXISTS idx_rpa_stage_product_batch ON rpa_stage_product(batch_id);
CREATE INDEX IF NOT EXISTS idx_rpa_stage_user_batch ON rpa_stage_user(batch_id);
COMMENT ON SCHEMA venus_rpa IS 'Controle da integração RPA com banco legado externo. O legado não é criado por este pacote.';
