/*
  API IA: corrige escrita de auditoria e adiciona tokens OAuth do Google.

  Executar como administrador/dono dos schemas venus e venus_audit.
  O refresh token chega aqui já cifrado pela API; nunca registrar seu valor em
  logs, prints, consultas de validação ou audit_logs.
*/

BEGIN;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'api_ia') THEN
        RAISE EXCEPTION 'O papel api_ia não existe. Ajuste o nome do papel da API antes de executar esta migration.';
    END IF;
END;
$$;

/* O trigger de auditoria precisa gravar usando as permissões do chamador. */
GRANT USAGE ON SCHEMA venus_audit TO api_ia;
GRANT INSERT ON TABLE venus_audit.audit_logs TO api_ia;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA venus_audit TO api_ia;

CREATE TABLE IF NOT EXISTS venus.google_oauth_tokens (
    google_oauth_token_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fk_user_id BIGINT NOT NULL UNIQUE
        REFERENCES venus.users(user_id) ON DELETE CASCADE,
    encrypted_refresh_token BYTEA NOT NULL,
    scope TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

DROP TRIGGER IF EXISTS trg_set_updated_at_google_oauth_tokens
    ON venus.google_oauth_tokens;
CREATE TRIGGER trg_set_updated_at_google_oauth_tokens
    BEFORE UPDATE ON venus.google_oauth_tokens
    FOR EACH ROW EXECUTE FUNCTION venus.fn_touch_updated_at();

/* Não manter cópia do token, mesmo cifrado, no log de auditoria. */
DROP TRIGGER IF EXISTS trg_audit_google_oauth_tokens
    ON venus.google_oauth_tokens;

GRANT SELECT, INSERT, UPDATE, DELETE
    ON TABLE venus.google_oauth_tokens TO api_ia;
GRANT USAGE, SELECT
    ON SEQUENCE venus.google_oauth_tokens_google_oauth_token_id_seq TO api_ia;

/* Impede que uma futura sincronização de triggers volte a auditar tokens. */
CREATE OR REPLACE PROCEDURE venus.sp_sync_standard_triggers()
LANGUAGE plpgsql
AS $proc$
DECLARE r RECORD;
BEGIN
    FOR r IN
        SELECT c.table_schema, c.table_name
          FROM information_schema.columns c
          JOIN information_schema.tables t
            ON t.table_schema = c.table_schema
           AND t.table_name = c.table_name
           AND t.table_type = 'BASE TABLE'
         WHERE c.table_schema = 'venus'
           AND c.column_name = 'updated_at'
           AND c.table_name NOT IN ('data_catalog', 'data_catalog_rules')
         GROUP BY c.table_schema, c.table_name
    LOOP
        EXECUTE format('DROP TRIGGER IF EXISTS trg_set_updated_at_%I ON %I.%I;', r.table_name, r.table_schema, r.table_name);
        EXECUTE format('CREATE TRIGGER trg_set_updated_at_%I BEFORE UPDATE ON %I.%I FOR EACH ROW EXECUTE FUNCTION venus.fn_touch_updated_at();', r.table_name, r.table_schema, r.table_name);
    END LOOP;

    FOR r IN
        SELECT table_schema, table_name
          FROM information_schema.tables
         WHERE table_schema = 'venus'
           AND table_type = 'BASE TABLE'
           AND table_name NOT IN ('data_catalog', 'data_catalog_rules', 'google_oauth_tokens')
         ORDER BY table_name
    LOOP
        EXECUTE format('DROP TRIGGER IF EXISTS trg_audit_%I ON %I.%I;', r.table_name, r.table_schema, r.table_name);
        EXECUTE format('CREATE TRIGGER trg_audit_%I AFTER INSERT OR UPDATE OR DELETE ON %I.%I FOR EACH ROW EXECUTE FUNCTION venus.fn_audit_row();', r.table_name, r.table_schema, r.table_name);
    END LOOP;
END;
$proc$;

INSERT INTO venus.data_catalog_rules (
    object_type, table_name, column_name, table_description, column_description,
    business_rule, access_level, access_rule, data_classification,
    sensitivity_reason, retention_policy, notes
) VALUES
    ('TABLE', 'google_oauth_tokens', '',
     'Tokens OAuth cifrados para consulta de disponibilidade no Google Calendar.',
     NULL,
     'Uma linha por usuário; remoção do usuário remove o token.',
     'SYSTEM', 'Somente API IA autenticada; sem acesso direto por cliente.', 'RESTRICTED',
     'Refresh token é credencial persistente, ainda que cifrada.',
     'Remover em desconexão do Google ou exclusão da conta.',
     'Não possui trigger de auditoria para não replicar credenciais.'),
    ('COLUMN', 'google_oauth_tokens', 'encrypted_refresh_token',
     NULL, 'Refresh token OAuth cifrado com chave mantida fora do banco.',
     'Nunca armazenar token em texto puro nem replicá-lo em logs.',
     'SYSTEM', 'Somente API IA autenticada.', 'RESTRICTED',
     'Credencial de acesso à agenda do usuário.',
     'Remover em desconexão do Google ou exclusão da conta.',
     'Não expor em consultas operacionais ou auditoria.')
ON CONFLICT (object_type, table_name, column_name) DO UPDATE SET
    table_description = EXCLUDED.table_description,
    column_description = EXCLUDED.column_description,
    business_rule = EXCLUDED.business_rule,
    access_level = EXCLUDED.access_level,
    access_rule = EXCLUDED.access_rule,
    data_classification = EXCLUDED.data_classification,
    sensitivity_reason = EXCLUDED.sensitivity_reason,
    retention_policy = EXCLUDED.retention_policy,
    notes = EXCLUDED.notes,
    is_active = TRUE,
    updated_at = NOW();

SELECT venus.sync_data_catalog();

COMMIT;

/* Pós-deploy: todos os valores esperados devem ser true, exceto audit_trigger. */
SELECT
    has_schema_privilege('api_ia', 'venus_audit', 'USAGE') AS audit_schema_usage,
    has_table_privilege('api_ia', 'venus_audit.audit_logs', 'INSERT') AS audit_insert,
    has_table_privilege('api_ia', 'venus.google_oauth_tokens', 'SELECT,INSERT,UPDATE,DELETE') AS token_crud,
    to_regclass('venus.google_oauth_tokens') IS NOT NULL AS token_table_exists,
    NOT EXISTS (
        SELECT 1
        FROM pg_trigger
        WHERE tgrelid = 'venus.google_oauth_tokens'::regclass
          AND tgname = 'trg_audit_google_oauth_tokens'
          AND NOT tgisinternal
    ) AS no_token_audit_trigger;
