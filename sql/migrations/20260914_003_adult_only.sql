BEGIN;

SET search_path TO venus, public;

-- 1) Desmonta as views BI que dependem direta ou indiretamente de user_profiles.age_range.
DROP VIEW IF EXISTS venus_bi.vw_user_recommendation_ranking;
DROP VIEW IF EXISTS venus_bi.dim_user;

-- 2) Normaliza dados legados antes da troca do ENUM.
UPDATE venus.user_profiles
SET age_range = 'age_18_24'
WHERE age_range::text IN ('under_13', 'age_13_17');

-- 3) Remove o default temporariamente.
ALTER TABLE venus.user_profiles
    ALTER COLUMN age_range DROP DEFAULT;

-- 4) Cria o novo ENUM apenas com faixas adultas.
DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM pg_type t
        JOIN pg_namespace n ON n.oid = t.typnamespace
        WHERE n.nspname = 'venus'
          AND t.typname = 'age_range_enum_new'
    ) THEN
        DROP TYPE venus.age_range_enum_new;
    END IF;

    CREATE TYPE venus.age_range_enum_new AS ENUM (
        'age_18_24',
        'age_25_34',
        'age_35_44',
        'age_45_54',
        'age_55_plus'
    );
END $$;

-- 5) Converte a coluna para o novo ENUM.
ALTER TABLE venus.user_profiles
    ALTER COLUMN age_range TYPE venus.age_range_enum_new
    USING age_range::text::venus.age_range_enum_new;

-- 6) Substitui o tipo antigo pelo novo.
DROP TYPE venus.age_range_enum;
ALTER TYPE venus.age_range_enum_new RENAME TO age_range_enum;

-- 7) Restaura default e regra explícita de domínio adulto.
ALTER TABLE venus.user_profiles
    ALTER COLUMN age_range SET DEFAULT 'age_18_24'::venus.age_range_enum;

ALTER TABLE venus.user_profiles
    DROP CONSTRAINT IF EXISTS ck_user_profiles_adult_age_range;

ALTER TABLE venus.user_profiles
    ADD CONSTRAINT ck_user_profiles_adult_age_range
    CHECK (age_range IN (
        'age_18_24',
        'age_25_34',
        'age_35_44',
        'age_45_54',
        'age_55_plus'
    ));

-- 8) Recria as views BI exatamente no formato do projeto atual.
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
    up.hair_type::text AS hair_type,
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
    u.updated_at::date AS updated_date
FROM venus.users u
LEFT JOIN venus.user_profiles up
  ON up.fk_user_id = u.user_id
LEFT JOIN venus.user_preferences pref
  ON pref.fk_user_id = u.user_id;

CREATE OR REPLACE VIEW venus_bi.vw_user_recommendation_ranking AS
WITH recommendation_base AS (
    SELECT
        fr.user_key,
        du.user_name,
        fr.product_key,
        dp.product_name,
        fr.brand_key,
        fr.brand_name,
        fr.product_category_key,
        fr.product_category_name,
        fr.profile_tag_key,
        fr.recommendation_type,
        fr.confidence_score,
        fr.ranking_position,
        fr.date_key,
        fr.reason
    FROM venus_bi.fact_recommendation fr
    LEFT JOIN venus_bi.dim_user du
        ON du.user_key = fr.user_key
    LEFT JOIN venus_bi.dim_product dp
        ON dp.product_key = fr.product_key
),
ranked AS (
    SELECT
        rb.*,
        ROW_NUMBER() OVER (
            PARTITION BY rb.user_key
            ORDER BY
                CASE
                    WHEN rb.recommendation_type = 'ideal' THEN 1
                    WHEN rb.recommendation_type = 'recommended' THEN 2
                    WHEN rb.recommendation_type = 'acceptable' THEN 3
                    WHEN rb.recommendation_type = 'alternative' THEN 4
                    ELSE 5
                END,
                rb.confidence_score DESC,
                NULLIF(rb.ranking_position, 0),
                rb.product_name
        ) AS calculated_user_rank,
        COUNT(*) OVER (
            PARTITION BY rb.user_key
        ) AS user_recommendation_count,
        AVG(rb.confidence_score) OVER (
            PARTITION BY rb.user_key
        )::NUMERIC(10,2) AS user_avg_confidence
    FROM recommendation_base rb
)
SELECT
    r.*,
    ROUND(
        r.confidence_score - r.user_avg_confidence,
        2
    ) AS confidence_delta_vs_user_avg
FROM ranked r;

COMMIT;

-- QA
SELECT age_range::text AS age_range, COUNT(*) AS total
FROM venus.user_profiles
GROUP BY age_range
ORDER BY age_range;

SELECT COUNT(*) AS forbidden_minor_rows
FROM venus.user_profiles
WHERE age_range::text IN ('under_13', 'age_13_17');
