-- Venus — localização aproximada do usuário — 2026-10-28
--
-- O aplicativo envia latitude/longitude arredondadas a duas casas, além de
-- city/state. A posição é um retrato atual: cada atualização substitui a
-- anterior na própria linha de venus.users.

BEGIN;

SET LOCAL lock_timeout = '10s';
SET LOCAL statement_timeout = '60s';

ALTER TABLE venus.users
    ADD COLUMN IF NOT EXISTS latitude NUMERIC(5,2),
    ADD COLUMN IF NOT EXISTS longitude NUMERIC(5,2),
    ADD COLUMN IF NOT EXISTS city TEXT,
    ADD COLUMN IF NOT EXISTS state TEXT;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conrelid = 'venus.users'::regclass
          AND conname = 'ck_users_latitude_range'
    ) THEN
        ALTER TABLE venus.users
            ADD CONSTRAINT ck_users_latitude_range
            CHECK (latitude BETWEEN -90 AND 90);
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conrelid = 'venus.users'::regclass
          AND conname = 'ck_users_longitude_range'
    ) THEN
        ALTER TABLE venus.users
            ADD CONSTRAINT ck_users_longitude_range
            CHECK (longitude BETWEEN -180 AND 180);
    END IF;
END;
$$;

COMMENT ON COLUMN venus.users.latitude IS
    'Latitude aproximada, arredondada a duas casas para análise regional.';
COMMENT ON COLUMN venus.users.longitude IS
    'Longitude aproximada, arredondada a duas casas para análise regional.';
COMMENT ON COLUMN venus.users.city IS
    'Cidade retornada pelo geocoder do dispositivo.';
COMMENT ON COLUMN venus.users.state IS
    'Estado retornado pelo geocoder do dispositivo; geralmente nome por extenso.';

-- As bases atuais usam privilégios por tabela. Estes grants tornam o contrato
-- explícito também em ambientes onde a tabela users foi criada com ACL menor.
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'api') THEN
        GRANT USAGE ON SCHEMA venus TO api;
        GRANT SELECT, INSERT, UPDATE ON TABLE venus.users TO api;
    END IF;

    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'api_ia') THEN
        GRANT USAGE ON SCHEMA venus TO api_ia;
        GRANT SELECT, INSERT, UPDATE ON TABLE venus.users TO api_ia;
    END IF;
END;
$$;

-- Mantém o catálogo de privacidade sincronizado quando ele existir.
DO $$
BEGIN
    IF to_regclass('venus.data_catalog_rules') IS NOT NULL THEN
        INSERT INTO venus.data_catalog_rules (
            object_type, table_name, column_name, column_description,
            business_rule, access_level, access_rule, data_classification,
            sensitivity_reason, retention_policy, notes
        ) VALUES
        (
            'COLUMN', 'users', 'latitude',
            'Latitude aproximada arredondada a duas casas.',
            'Guarda somente a última posição regional enviada pelo aplicativo.',
            'OWNER', 'Somente o próprio usuário e a API autorizada.', 'CONFIDENTIAL',
            'Dado de localização aproximada vinculado ao usuário.', NULL,
            'Não usar para reconstruir localização exata ou histórico de deslocamento.'
        ),
        (
            'COLUMN', 'users', 'longitude',
            'Longitude aproximada arredondada a duas casas.',
            'Guarda somente a última posição regional enviada pelo aplicativo.',
            'OWNER', 'Somente o próprio usuário e a API autorizada.', 'CONFIDENTIAL',
            'Dado de localização aproximada vinculado ao usuário.', NULL,
            'Não usar para reconstruir localização exata ou histórico de deslocamento.'
        ),
        (
            'COLUMN', 'users', 'city',
            'Cidade retornada pelo geocoder do dispositivo.',
            'Guarda a cidade associada à última posição enviada.',
            'OWNER', 'Somente o próprio usuário e a API autorizada.', 'CONFIDENTIAL',
            'Dado de localização aproximada vinculado ao usuário.', NULL,
            'O valor é fornecido pelo geocoder e pode variar em formato.'
        ),
        (
            'COLUMN', 'users', 'state',
            'Estado retornado pelo geocoder do dispositivo.',
            'Guarda o estado associado à última posição enviada.',
            'OWNER', 'Somente o próprio usuário e a API autorizada.', 'CONFIDENTIAL',
            'Dado de localização aproximada vinculado ao usuário.', NULL,
            'Em geral o geocoder retorna o nome por extenso, não a UF.'
        )
        ON CONFLICT (object_type, table_name, column_name) DO UPDATE SET
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
    END IF;
END;
$$;

-- trg_audit_users já cobre INSERT/UPDATE/DELETE da linha inteira; portanto os
-- novos campos entram automaticamente em old_data/new_data.

COMMIT;
