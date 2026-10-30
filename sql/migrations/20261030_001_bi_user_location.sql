BEGIN;

SET LOCAL lock_timeout = '10s';
SET LOCAL statement_timeout = '60s';

-- PostgreSQL permite acrescentar colunas ao fim com CREATE OR REPLACE VIEW.
-- A ordem abaixo preserva a dim_user já publicada nos bancos existentes.
CREATE OR REPLACE VIEW venus_bi.dim_user AS
SELECT
    u.user_id AS user_key,
    u.firebase_uid,
    u.name AS user_name,
    u.status::text AS user_status,
    u.last_login::date AS last_login_date,

    up.user_profile_id,
    up.skin_type::text AS skin_type,
    up.skin_phototype::text AS skin_phototype,
    up.has_hyperpigmentation,
    up.has_melasma,
    up.has_rosacea,
    up.has_eczema,
    up.hair_pattern::text AS hair_pattern,
    up.scalp_type::text AS scalp_type,
    up.skin_sensitivity::text AS skin_sensitivity,
    up.acne_prone,
    up.age_range::text AS age_range,
    up.gender::text AS gender,
    up.is_pregnant,

    pref.user_preference_id,
    pref.prefer_cruelty_free,
    pref.prefer_vegan,
    pref.prefer_sustainable,
    pref.prefer_fragrance_free,
    pref.prefer_paraben_free,
    pref.prefer_sulfate_free,
    pref.prefer_silicone_free,

    u.created_at::date AS created_date,
    u.updated_at::date AS updated_date,
    u.state AS state,
    u.city AS city,
    ROUND(u.latitude, 1) AS latitude,
    ROUND(u.longitude, 1) AS longitude
FROM venus.users u
LEFT JOIN venus.user_profiles up
  ON up.fk_user_id = u.user_id
LEFT JOIN venus.user_preferences pref
  ON pref.fk_user_id = u.user_id;

COMMIT;
