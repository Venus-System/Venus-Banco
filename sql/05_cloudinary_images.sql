
CREATE TABLE IF NOT EXISTS venus.media_assets (
    media_asset_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fk_user_id BIGINT REFERENCES venus.users(user_id) ON DELETE CASCADE,
    fk_product_version_id BIGINT REFERENCES venus.product_versions(product_version_id) ON DELETE CASCADE,
    purpose TEXT NOT NULL CHECK (purpose IN ('avatar', 'product_photo')),
    provider TEXT NOT NULL DEFAULT 'cloudinary' CHECK (provider = 'cloudinary'),
    resource_type TEXT NOT NULL DEFAULT 'image' CHECK (resource_type = 'image'),
    delivery_type TEXT NOT NULL DEFAULT 'upload' CHECK (delivery_type IN ('upload', 'authenticated')),
    public_id TEXT NOT NULL,
    asset_id TEXT,
    version BIGINT,
    secure_url TEXT,
    format TEXT,
    width INTEGER CHECK (width IS NULL OR width > 0),
    height INTEGER CHECK (height IS NULL OR height > 0),
    bytes BIGINT CHECK (bytes IS NULL OR bytes >= 0),
    folder TEXT,
    original_filename TEXT,
    alt_text TEXT,
    sort_order INTEGER NOT NULL DEFAULT 0 CHECK (sort_order >= 0),
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('pending', 'active', 'deleted', 'failed')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CHECK (
        (fk_user_id IS NOT NULL AND fk_product_version_id IS NULL AND purpose = 'avatar')
        OR
        (fk_user_id IS NULL AND fk_product_version_id IS NOT NULL AND purpose = 'product_photo')
    ),
    CONSTRAINT uq_media_assets_provider_public_id UNIQUE (provider, public_id)
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_media_user_avatar
    ON venus.media_assets (fk_user_id)
    WHERE purpose = 'avatar' AND status IN ('pending', 'active');

CREATE INDEX IF NOT EXISTS idx_media_assets_product_version
    ON venus.media_assets (fk_product_version_id, sort_order, media_asset_id)
    WHERE purpose = 'product_photo' AND status IN ('pending', 'active');

CREATE INDEX IF NOT EXISTS idx_media_assets_user
    ON venus.media_assets (fk_user_id)
    WHERE purpose = 'avatar' AND status IN ('pending', 'active');

CREATE INDEX IF NOT EXISTS idx_media_assets_public_id
    ON venus.media_assets (public_id);

CREATE INDEX IF NOT EXISTS idx_media_assets_status
    ON venus.media_assets (status, updated_at);

COMMENT ON TABLE venus.media_assets IS
'Canonical registry of Cloudinary media assets. Binary content is stored outside PostgreSQL.';
COMMENT ON COLUMN venus.media_assets.public_id IS
'Cloudinary public_id. Canonical identifier controlled by the backend for replace/delete/delivery.';
COMMENT ON COLUMN venus.media_assets.asset_id IS
'Cloudinary immutable asset_id when returned by the Upload API.';
COMMENT ON COLUMN venus.media_assets.secure_url IS
'HTTPS delivery URL returned by Cloudinary. Cached metadata; public_id remains canonical.';
COMMENT ON COLUMN venus.media_assets.delivery_type IS
'Cloudinary delivery type: upload for public delivery or authenticated for private delivery.';
COMMENT ON COLUMN venus.media_assets.status IS
'Application lifecycle: pending, active, deleted or failed.';

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='venus' AND table_name='users' AND column_name='avatar_public_id') THEN
        INSERT INTO venus.media_assets (
            fk_user_id, purpose, provider, resource_type, delivery_type,
            public_id, secure_url, status, created_at, updated_at
        )
        SELECT u.user_id, 'avatar', 'cloudinary', 'image', 'upload',
               u.avatar_public_id, u.avatar_secure_url, 'active',
               COALESCE(u.avatar_updated_at, u.updated_at, NOW()),
               COALESCE(u.avatar_updated_at, u.updated_at, NOW())
        FROM venus.users u
        WHERE NULLIF(TRIM(u.avatar_public_id), '') IS NOT NULL
          AND NOT EXISTS (
              SELECT 1 FROM venus.media_assets m
              WHERE m.provider='cloudinary' AND m.public_id=u.avatar_public_id
          );
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='venus' AND table_name='product_versions' AND column_name='photo_public_id') THEN
        INSERT INTO venus.media_assets (
            fk_product_version_id, purpose, provider, resource_type, delivery_type,
            public_id, secure_url, sort_order, status, created_at, updated_at
        )
        SELECT p.product_version_id, 'product_photo', 'cloudinary', 'image', 'upload',
               p.photo_public_id, p.photo_secure_url, 0, 'active',
               COALESCE(p.photo_updated_at, p.updated_at, NOW()),
               COALESCE(p.photo_updated_at, p.updated_at, NOW())
        FROM venus.product_versions p
        WHERE NULLIF(TRIM(p.photo_public_id), '') IS NOT NULL
          AND NOT EXISTS (
              SELECT 1 FROM venus.media_assets m
              WHERE m.provider='cloudinary' AND m.public_id=p.photo_public_id
          );
    END IF;
END
$$;

ALTER TABLE venus.users DROP COLUMN IF EXISTS avatar_public_id;
ALTER TABLE venus.users DROP COLUMN IF EXISTS avatar_secure_url;
ALTER TABLE venus.users DROP COLUMN IF EXISTS avatar_updated_at;
ALTER TABLE venus.product_versions DROP COLUMN IF EXISTS photo_public_id;
ALTER TABLE venus.product_versions DROP COLUMN IF EXISTS photo_secure_url;
ALTER TABLE venus.product_versions DROP COLUMN IF EXISTS photo_updated_at;

CREATE OR REPLACE VIEW venus.v_user_avatars AS
SELECT
    m.media_asset_id,
    m.fk_user_id AS user_id,
    m.public_id,
    m.asset_id,
    m.secure_url,
    m.format,
    m.width,
    m.height,
    m.bytes,
    m.updated_at
FROM venus.media_assets m
WHERE m.purpose = 'avatar'
  AND m.status IN ('pending', 'active');

CREATE OR REPLACE VIEW venus.v_product_photos AS
SELECT
    m.media_asset_id,
    m.fk_product_version_id AS product_version_id,
    m.public_id,
    m.asset_id,
    m.secure_url,
    m.format,
    m.width,
    m.height,
    m.bytes,
    m.alt_text,
    m.sort_order,
    m.updated_at
FROM venus.media_assets m
WHERE m.purpose = 'product_photo'
  AND m.status IN ('pending', 'active');
