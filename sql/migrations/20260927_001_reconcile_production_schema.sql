/*
  Reconcilia o schema versionado com alterações já aplicadas em produção.
  Execute uma única vez em bancos existentes. Não inclui senha temporária nem
  dados pessoais; password_hash permanece nulo até o fluxo de credenciais.
*/

SET search_path TO venus, public;

-- O ADD VALUE fica fora da transação para ser compatível com PostgreSQL 11+.
ALTER TYPE venus.age_range_enum
    ADD VALUE IF NOT EXISTS 'age_13_17' BEFORE 'age_18_24';

BEGIN;

ALTER TABLE venus.admin_users
    ADD COLUMN IF NOT EXISTS password_hash TEXT;

/* Ausência de resposta é NULL; não é convertida silenciosamente em "não". */
ALTER TABLE venus.user_profiles
    ALTER COLUMN skin_type DROP NOT NULL,
    ALTER COLUMN skin_type DROP DEFAULT,
    ALTER COLUMN skin_phototype DROP NOT NULL,
    ALTER COLUMN skin_phototype DROP DEFAULT,
    ALTER COLUMN has_hyperpigmentation DROP NOT NULL,
    ALTER COLUMN has_hyperpigmentation DROP DEFAULT,
    ALTER COLUMN has_melasma DROP NOT NULL,
    ALTER COLUMN has_melasma DROP DEFAULT,
    ALTER COLUMN has_rosacea DROP NOT NULL,
    ALTER COLUMN has_rosacea DROP DEFAULT,
    ALTER COLUMN has_eczema DROP NOT NULL,
    ALTER COLUMN has_eczema DROP DEFAULT,
    ALTER COLUMN scalp_type DROP NOT NULL,
    ALTER COLUMN scalp_type DROP DEFAULT,
    ALTER COLUMN skin_sensitivity DROP NOT NULL,
    ALTER COLUMN skin_sensitivity DROP DEFAULT,
    ALTER COLUMN acne_prone DROP NOT NULL,
    ALTER COLUMN acne_prone DROP DEFAULT,
    ALTER COLUMN age_range DROP NOT NULL,
    ALTER COLUMN age_range DROP DEFAULT,
    ALTER COLUMN gender DROP NOT NULL,
    ALTER COLUMN gender DROP DEFAULT,
    ALTER COLUMN is_pregnant DROP NOT NULL,
    ALTER COLUMN is_pregnant DROP DEFAULT,
    ALTER COLUMN is_breastfeeding DROP NOT NULL,
    ALTER COLUMN is_breastfeeding DROP DEFAULT;

ALTER TABLE venus.user_profiles
    DROP CONSTRAINT IF EXISTS ck_user_profiles_adult_age_range;
ALTER TABLE venus.user_profiles
    ADD CONSTRAINT ck_user_profiles_adult_age_range CHECK (
        age_range::text IN ('age_13_17','age_18_24','age_25_34','age_35_44','age_45_54','age_55_plus')
    );

ALTER TABLE venus.compatibility_rules
    ADD COLUMN IF NOT EXISTS is_block BOOLEAN GENERATED ALWAYS AS (effect_type = 'block') STORED,
    ADD COLUMN IF NOT EXISTS is_alert BOOLEAN GENERATED ALWAYS AS (effect_type = 'alert') STORED;

ALTER TABLE venus.analysis_results
    ALTER COLUMN health_score DROP NOT NULL,
    ALTER COLUMN health_score DROP DEFAULT,
    ALTER COLUMN environmental_score DROP NOT NULL,
    ALTER COLUMN environmental_score DROP DEFAULT,
    ALTER COLUMN transparency_score DROP NOT NULL,
    ALTER COLUMN confidence_score DROP NOT NULL;

ALTER TABLE venus.product_scores
    ALTER COLUMN health_score DROP NOT NULL,
    ALTER COLUMN health_score DROP DEFAULT,
    ALTER COLUMN environmental_score DROP NOT NULL,
    ALTER COLUMN environmental_score DROP DEFAULT,
    ALTER COLUMN transparency_score DROP NOT NULL,
    ALTER COLUMN transparency_score DROP DEFAULT,
    ALTER COLUMN confidence_score DROP NOT NULL,
    ALTER COLUMN confidence_score DROP DEFAULT;

ALTER TABLE venus.personalized_scores
    ALTER COLUMN compatibility_percentage DROP NOT NULL,
    ALTER COLUMN compatibility_percentage DROP DEFAULT;

INSERT INTO venus.profile_tags (name, description, slug, category) VALUES
    ('Gravidez', 'Usuário durante o período de gravidez', 'gravidez', 'health'),
    ('Organic Ingredients', 'Preferência por produtos que contenham ingredientes orgânicos.', 'organic-ingredients', 'sustainability'),
    ('Biodegradable Formula', 'Preferência por produtos com formulação biodegradável.', 'biodegradable-formula', 'sustainability'),
    ('Eco-Friendly Packaging', 'Preferência por produtos com embalagem de menor impacto ambiental.', 'eco-friendly-packaging', 'sustainability'),
    ('Refillable', 'Preferência por produtos com embalagem ou sistema de refil.', 'refillable', 'sustainability'),
    ('Recyclable Packaging', 'Preferência por produtos com embalagem reciclável.', 'recyclable-packaging', 'sustainability')
ON CONFLICT (name) DO NOTHING;

CREATE OR REPLACE FUNCTION venus.fn_is_authorized_bootstrap_session()
RETURNS BOOLEAN LANGUAGE plpgsql STABLE AS $$
DECLARE v_schema_owner NAME;
BEGIN
    IF COALESCE(current_setting('venus.bootstrap', true), 'off') <> 'on' THEN RETURN FALSE; END IF;
    SELECT r.rolname INTO v_schema_owner
      FROM pg_namespace n JOIN pg_roles r ON r.oid = n.nspowner
     WHERE n.nspname = 'venus';
    RETURN v_schema_owner IS NOT NULL
       AND (current_user = v_schema_owner OR pg_has_role(current_user, v_schema_owner, 'member'));
END;
$$;

CREATE OR REPLACE FUNCTION venus.fn_validate_analysis_status_transition()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF OLD.status = NEW.status THEN RETURN NEW; END IF;
    IF (OLD.status, NEW.status) IN (('processing','completed'),('processing','failed'),('processing','pending_review'),('pending_review','completed'),('pending_review','failed')) THEN RETURN NEW; END IF;
    RAISE EXCEPTION 'analysis_result % cannot change status from % to %', OLD.analysis_result_id, OLD.status, NEW.status USING ERRCODE = 'VE001';
END;
$$;

CREATE OR REPLACE FUNCTION venus.fn_validate_report_status_transition()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF OLD.status = NEW.status THEN RETURN NEW; END IF;
    IF (OLD.status, NEW.status) IN (('open','in_review'),('in_review','resolved'),('in_review','rejected')) THEN RETURN NEW; END IF;
    RAISE EXCEPTION 'report % cannot change status from % to %', OLD.report_id, OLD.status, NEW.status USING ERRCODE = 'VE001';
END;
$$;

CREATE OR REPLACE FUNCTION venus.fn_audit_row()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF venus.fn_is_authorized_bootstrap_session() THEN
        RETURN CASE WHEN TG_OP = 'DELETE' THEN OLD ELSE NEW END;
    END IF;
    IF TG_OP = 'INSERT' THEN
        INSERT INTO venus_audit.audit_logs (schema_name,table_name,operation_type,old_data,new_data,changed_by,application_name)
        VALUES (TG_TABLE_SCHEMA,TG_TABLE_NAME,TG_OP,NULL,to_jsonb(NEW),CURRENT_USER,current_setting('application_name',true));
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO venus_audit.audit_logs (schema_name,table_name,operation_type,old_data,new_data,changed_by,application_name)
        VALUES (TG_TABLE_SCHEMA,TG_TABLE_NAME,TG_OP,to_jsonb(OLD),to_jsonb(NEW),CURRENT_USER,current_setting('application_name',true));
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO venus_audit.audit_logs (schema_name,table_name,operation_type,old_data,new_data,changed_by,application_name)
        VALUES (TG_TABLE_SCHEMA,TG_TABLE_NAME,TG_OP,to_jsonb(OLD),NULL,CURRENT_USER,current_setting('application_name',true));
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$;

CREATE OR REPLACE FUNCTION venus.fn_log_fk_user_activity()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE v_app_user_id BIGINT;
BEGIN
    IF venus.fn_is_authorized_bootstrap_session() THEN RETURN NEW; END IF;
    BEGIN
        v_app_user_id := NULLIF(current_setting('venus.app_user_id', true), '')::BIGINT;
    EXCEPTION WHEN invalid_text_representation OR numeric_value_out_of_range THEN
        RETURN NEW;
    END;
    IF v_app_user_id IS NULL OR NEW.fk_user_id IS DISTINCT FROM v_app_user_id THEN RETURN NEW; END IF;
    PERFORM venus.fn_register_user_access(v_app_user_id, TG_TABLE_NAME);
    RETURN NEW;
END;
$$;

CREATE OR REPLACE PROCEDURE venus.sp_sync_standard_triggers()
LANGUAGE plpgsql AS $proc$
DECLARE r RECORD;
BEGIN
    FOR r IN
        SELECT c.table_schema, c.table_name
          FROM information_schema.columns c
          JOIN information_schema.tables t ON t.table_schema = c.table_schema AND t.table_name = c.table_name
         WHERE c.table_schema = 'venus' AND t.table_type = 'BASE TABLE'
           AND c.column_name = 'updated_at'
           AND c.table_name NOT IN ('data_catalog', 'data_catalog_rules')
         GROUP BY c.table_schema, c.table_name
    LOOP
        EXECUTE format('DROP TRIGGER IF EXISTS trg_set_updated_at_%I ON %I.%I;', r.table_name, r.table_schema, r.table_name);
        EXECUTE format('CREATE TRIGGER trg_set_updated_at_%I BEFORE UPDATE ON %I.%I FOR EACH ROW EXECUTE FUNCTION venus.fn_touch_updated_at();', r.table_name, r.table_schema, r.table_name);
    END LOOP;
    FOR r IN
        SELECT table_schema, table_name FROM information_schema.tables
         WHERE table_schema = 'venus' AND table_type = 'BASE TABLE'
           AND table_name NOT IN ('data_catalog', 'data_catalog_rules')
    LOOP
        EXECUTE format('DROP TRIGGER IF EXISTS trg_audit_%I ON %I.%I;', r.table_name, r.table_schema, r.table_name);
        EXECUTE format('CREATE TRIGGER trg_audit_%I AFTER INSERT OR UPDATE OR DELETE ON %I.%I FOR EACH ROW EXECUTE FUNCTION venus.fn_audit_row();', r.table_name, r.table_schema, r.table_name);
    END LOOP;
END;
$proc$;

CALL venus.sp_sync_standard_triggers();

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'api') THEN
        GRANT USAGE ON SCHEMA venus_audit TO api;
        GRANT INSERT ON TABLE venus_audit.audit_logs TO api;
        GRANT USAGE, SELECT ON SEQUENCE venus_audit.audit_logs_audit_id_seq TO api;
    END IF;
END;
$$;

CREATE OR REPLACE PROCEDURE venus.sp_set_user_active(p_user_id BIGINT, p_active BOOLEAN)
LANGUAGE plpgsql AS $$
DECLARE v_status venus.user_status_enum;
BEGIN
    SELECT status INTO v_status FROM venus.users WHERE user_id = p_user_id;
    IF NOT FOUND THEN RAISE EXCEPTION 'usuário % não encontrado', p_user_id; END IF;
    IF v_status IN ('blocked'::venus.user_status_enum,'pending'::venus.user_status_enum) THEN
        RAISE EXCEPTION 'usuário % está em status % e não pode ser alterado por sp_set_user_active', p_user_id, v_status USING ERRCODE = 'VE001';
    END IF;
    IF (v_status = 'active'::venus.user_status_enum AND p_active) OR (v_status = 'inactive'::venus.user_status_enum AND NOT p_active) THEN RETURN; END IF;
    UPDATE venus.users SET status = CASE WHEN p_active THEN 'active'::venus.user_status_enum ELSE 'inactive'::venus.user_status_enum END WHERE user_id = p_user_id;
END;
$$;

DROP TRIGGER IF EXISTS trg_validate_report_status_transition ON venus.reports;
CREATE TRIGGER trg_validate_report_status_transition BEFORE UPDATE OF status ON venus.reports
FOR EACH ROW EXECUTE FUNCTION venus.fn_validate_report_status_transition();

DROP TRIGGER IF EXISTS trg_activity_recommendations ON venus.recommendations;
DROP TRIGGER IF EXISTS trg_activity_personalized_scores ON venus.personalized_scores;
COMMIT;
