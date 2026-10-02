/*
  Listas: descrição, capa padrão e capa Cloudinary por lista.
  Executar em banco existente como administrador/dono das tabelas.
*/

BEGIN;

ALTER TABLE venus.user_lists
    ADD COLUMN IF NOT EXISTS description TEXT,
    ADD COLUMN IF NOT EXISTS cover_key TEXT;

ALTER TABLE venus.user_lists
    DROP CONSTRAINT IF EXISTS ck_user_lists_description_length,
    DROP CONSTRAINT IF EXISTS ck_user_lists_cover_key,
    ADD CONSTRAINT ck_user_lists_description_length
        CHECK (description IS NULL OR char_length(description) <= 500),
    ADD CONSTRAINT ck_user_lists_cover_key
        CHECK (cover_key IS NULL OR cover_key IN ('favoritos', 'escaneados', 'skincare'));

ALTER TABLE venus.media_assets
    ADD COLUMN IF NOT EXISTS fk_user_list_id BIGINT
        REFERENCES venus.user_lists(user_list_id) ON DELETE CASCADE;

/*
  Bancos antigos podem ter nomes automáticos diferentes para estas duas
  CHECKs. Localizamos pela definição, para não depender de nomes específicos.
*/
DO $$
DECLARE
    v_purpose_constraint TEXT;
    v_owner_constraint TEXT;
BEGIN
    SELECT c.conname
      INTO v_purpose_constraint
      FROM pg_constraint c
     WHERE c.conrelid = 'venus.media_assets'::regclass
       AND c.contype = 'c'
       AND pg_get_constraintdef(c.oid) ILIKE '%purpose%'
       AND pg_get_constraintdef(c.oid) NOT ILIKE '%fk_user_id%'
     ORDER BY c.oid
     LIMIT 1;

    SELECT c.conname
      INTO v_owner_constraint
      FROM pg_constraint c
     WHERE c.conrelid = 'venus.media_assets'::regclass
       AND c.contype = 'c'
       AND pg_get_constraintdef(c.oid) ILIKE '%fk_user_id%'
       AND pg_get_constraintdef(c.oid) ILIKE '%fk_product_version_id%'
     ORDER BY c.oid
     LIMIT 1;

    IF v_purpose_constraint IS NOT NULL THEN
        EXECUTE format(
            'ALTER TABLE venus.media_assets DROP CONSTRAINT %I',
            v_purpose_constraint
        );
    END IF;

    IF v_owner_constraint IS NOT NULL THEN
        EXECUTE format(
            'ALTER TABLE venus.media_assets DROP CONSTRAINT %I',
            v_owner_constraint
        );
    END IF;
END;
$$;

ALTER TABLE venus.media_assets
    DROP CONSTRAINT IF EXISTS media_assets_purpose_check,
    DROP CONSTRAINT IF EXISTS media_assets_check,
    DROP CONSTRAINT IF EXISTS ck_media_assets_dono,
    ADD CONSTRAINT media_assets_purpose_check
        CHECK (purpose IN ('avatar', 'product_photo', 'list_cover')),
    ADD CONSTRAINT ck_media_assets_dono CHECK (
        (fk_user_id IS NOT NULL
         AND fk_product_version_id IS NULL
         AND fk_user_list_id IS NULL
         AND purpose = 'avatar')
        OR
        (fk_user_id IS NULL
         AND fk_product_version_id IS NOT NULL
         AND fk_user_list_id IS NULL
         AND purpose = 'product_photo')
        OR
        (fk_user_id IS NULL
         AND fk_product_version_id IS NULL
         AND fk_user_list_id IS NOT NULL
         AND purpose = 'list_cover')
    );

CREATE UNIQUE INDEX IF NOT EXISTS ux_media_user_list_cover
    ON venus.media_assets (fk_user_list_id)
    WHERE purpose = 'list_cover' AND status IN ('pending', 'active');

CREATE INDEX IF NOT EXISTS idx_media_assets_user_list
    ON venus.media_assets (fk_user_list_id, updated_at)
    WHERE purpose = 'list_cover' AND status IN ('pending', 'active');

CREATE OR REPLACE VIEW venus.v_user_list_covers AS
SELECT
    m.media_asset_id,
    m.fk_user_list_id AS user_list_id,
    m.public_id,
    m.asset_id,
    m.secure_url,
    m.format,
    m.width,
    m.height,
    m.bytes,
    m.alt_text,
    m.updated_at
FROM venus.media_assets m
WHERE m.purpose = 'list_cover'
  AND m.status IN ('pending', 'active');

INSERT INTO venus.data_catalog_rules (
    object_type,
    table_name,
    column_name,
    column_description,
    business_rule,
    access_level,
    access_rule,
    data_classification,
    notes
)
VALUES
(
    'COLUMN', 'user_lists', 'description',
    'Descrição opcional da lista, limitada a 500 caracteres.',
    'Texto livre informado pelo usuário.',
    'OWNER', 'Somente o dono da lista e a API autorizada.',
    'INTERNAL', NULL
),
(
    'COLUMN', 'user_lists', 'cover_key',
    'Chave da capa padrão exibida pelo aplicativo.',
    'Valores aceitos: favoritos, escaneados ou skincare.',
    'OWNER', 'Somente o dono da lista e a API autorizada.',
    'INTERNAL', NULL
),
(
    'COLUMN', 'media_assets', 'fk_user_list_id',
    'Lista proprietária de uma capa Cloudinary.',
    'Obrigatório quando purpose = list_cover.',
    'SYSTEM', 'Backend/API.',
    'INTERNAL', 'A capa de lista é uma mídia pertencente à lista.'
)
ON CONFLICT (object_type, table_name, column_name) DO UPDATE SET
    column_description = EXCLUDED.column_description,
    business_rule = EXCLUDED.business_rule,
    access_level = EXCLUDED.access_level,
    access_rule = EXCLUDED.access_rule,
    data_classification = EXCLUDED.data_classification,
    notes = EXCLUDED.notes,
    is_active = TRUE,
    updated_at = NOW();

SELECT venus.sync_data_catalog();

COMMIT;

SELECT
    EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'venus'
          AND table_name = 'user_lists'
          AND column_name = 'description'
    ) AS list_description_exists,
    EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'venus'
          AND table_name = 'media_assets'
          AND column_name = 'fk_user_list_id'
    ) AS list_media_owner_exists,
    to_regclass('venus.ux_media_user_list_cover') IS NOT NULL AS list_cover_index_exists;
