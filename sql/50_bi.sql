

CREATE SCHEMA IF NOT EXISTS venus_bi;

SET search_path TO venus_bi, venus, public;


CREATE OR REPLACE VIEW venus_bi.dim_date AS
WITH limites AS (
    SELECT
        COALESCE(
            LEAST(
                (SELECT MIN(created_at)::date FROM venus.products),
                (SELECT MIN(created_at)::date FROM venus.product_versions),
                (SELECT MIN(calculated_at)::date FROM venus.product_scores),
                (SELECT MIN(created_at)::date FROM venus.analysis_results),
                (SELECT MIN(created_at)::date FROM venus.personalized_scores),
                (SELECT MIN(created_at)::date FROM venus.recommendations),
                (SELECT MIN(created_at)::date FROM venus.reviews)
            ),
            CURRENT_DATE
        ) AS data_inicio,
        COALESCE(
            GREATEST(
                (SELECT MAX(updated_at)::date FROM venus.products),
                (SELECT MAX(updated_at)::date FROM venus.product_versions),
                (SELECT MAX(calculated_at)::date FROM venus.product_scores),
                (SELECT MAX(updated_at)::date FROM venus.analysis_results),
                (SELECT MAX(created_at)::date FROM venus.personalized_scores),
                (SELECT MAX(created_at)::date FROM venus.recommendations),
                (SELECT MAX(created_at)::date FROM venus.reviews),
                CURRENT_DATE
            ),
            CURRENT_DATE
        ) AS data_fim
)
SELECT
    gs::date AS date_key,
    EXTRACT(YEAR FROM gs)::int AS year_number,
    EXTRACT(QUARTER FROM gs)::int AS quarter_number,
    'Q' || EXTRACT(QUARTER FROM gs)::int AS quarter_label,
    EXTRACT(MONTH FROM gs)::int AS month_number,
    TO_CHAR(gs, 'YYYY-MM') AS year_month,
    TO_CHAR(gs, 'Mon') AS month_short_name,
    TO_CHAR(gs, 'TMMonth') AS month_name,
    EXTRACT(WEEK FROM gs)::int AS week_number,
    EXTRACT(DOY FROM gs)::int AS day_of_year,
    EXTRACT(DAY FROM gs)::int AS day_number,
    EXTRACT(ISODOW FROM gs)::int AS iso_weekday_number,
    TO_CHAR(gs, 'TMDay') AS weekday_name,
    CASE WHEN EXTRACT(ISODOW FROM gs) IN (6, 7) THEN TRUE ELSE FALSE END AS is_weekend
FROM limites
CROSS JOIN LATERAL generate_series(
    limites.data_inicio::timestamp,
    limites.data_fim::timestamp,
    interval '1 day'
) AS g(gs);

CREATE OR REPLACE VIEW venus_bi.dim_brand AS
SELECT
    b.brand_id AS brand_key,
    b.name AS brand_name,
    b.country,
    b.website,
    b.has_cruelty_free_claim,
    b.has_vegan_claim,
    b.is_brazilian,
    b.created_at::date AS created_date,
    b.updated_at::date AS updated_date
FROM venus.brands b;

CREATE OR REPLACE VIEW venus_bi.dim_product_category AS
SELECT
    pc.product_category_id AS product_category_key,
    pc.name AS product_category_name,
    pc.description
FROM venus.product_categories pc;

CREATE OR REPLACE VIEW venus_bi.dim_ingredient_category AS
SELECT
    ic.ingredient_category_id AS ingredient_category_key,
    ic.name AS ingredient_category_name,
    ic.description
FROM venus.ingredient_categories ic;

CREATE OR REPLACE VIEW venus_bi.dim_product AS
SELECT
    p.product_id AS product_key,
    p.name AS product_name,
    p.slug AS product_slug,
    p.description AS product_description,
    p.fk_brand_id AS brand_key,
    b.name AS brand_name,
    b.country AS brand_country,
    p.fk_product_category_id AS product_category_key,
    pc.name AS product_category_name,
    p.is_active,
    p.created_at::date AS created_date,
    p.updated_at::date AS updated_date
FROM venus.products p
JOIN venus.brands b
  ON b.brand_id = p.fk_brand_id
JOIN venus.product_categories pc
  ON pc.product_category_id = p.fk_product_category_id;

CREATE OR REPLACE VIEW venus_bi.dim_product_version AS
SELECT
    pv.product_version_id AS product_version_key,
    pv.fk_product_id AS product_key,
    p.name AS product_name,
    p.slug AS product_slug,
    b.brand_id AS brand_key,
    b.name AS brand_name,
    pc.product_category_id AS product_category_key,
    pc.name AS product_category_name,
    pv.version_name,
    pv.display_name,
    pv.status::text AS version_status,
    pv.is_current,
    pv.formula_signature,
    pv.detected_by::text AS detected_by,
    pv.effective_from,
    pv.effective_to,
    CASE
        WHEN pv.effective_to IS NULL THEN TRUE
        WHEN pv.effective_to >= CURRENT_DATE THEN TRUE
        ELSE FALSE
    END AS is_effective_current,
    pv.created_at::date AS created_date,
    pv.updated_at::date AS updated_date
FROM venus.product_versions pv
JOIN venus.products p
  ON p.product_id = pv.fk_product_id
JOIN venus.brands b
  ON b.brand_id = p.fk_brand_id
JOIN venus.product_categories pc
  ON pc.product_category_id = p.fk_product_category_id;

CREATE OR REPLACE VIEW venus_bi.dim_ingredient AS
SELECT
    i.ingredient_id AS ingredient_key,
    i.inci_name,
    i.common_name,
    i.function_summary,
    i.description,
    i.fk_ingredient_category_id AS ingredient_category_key,
    ic.name AS ingredient_category_name,
    i.biodegradability_level,
    i.irritation_risk_level,
    i.comedogenicity_score,
    i.environmental_risk_level,
    i.scientific_confidence,
    i.safety_summary,
    i.source_type::text AS source_type,
    i.source_reference,
    i.created_at::date AS created_date,
    i.updated_at::date AS updated_date
FROM venus.ingredients i
JOIN venus.ingredient_categories ic
  ON ic.ingredient_category_id = i.fk_ingredient_category_id;

CREATE OR REPLACE VIEW venus_bi.dim_profile_tag AS
SELECT
    pt.profile_tag_id AS profile_tag_key,
    pt.name AS profile_tag_name,
    pt.slug AS profile_tag_slug,
    pt.description,
    pt.category::text AS profile_tag_category,
    pt.created_at::date AS created_date,
    pt.updated_at::date AS updated_date
FROM venus.profile_tags pt;

CREATE OR REPLACE VIEW venus_bi.dim_scoring_model AS
SELECT
    sm.scoring_model_id AS scoring_model_key,
    sm.name AS scoring_model_name,
    sm.version AS scoring_model_version,
    sm.description,
    sm.is_active,
    sm.created_at::date AS created_date,
    sm.updated_at::date AS updated_date
FROM venus.scoring_models sm;

CREATE OR REPLACE VIEW venus_bi.dim_claim AS
SELECT
    c.claim_id AS claim_key,
    c.name AS claim_name,
    c.description,
    c.claim_type::text AS claim_type,
    c.created_at::date AS created_date,
    c.updated_at::date AS updated_date
FROM venus.claims c;

CREATE OR REPLACE VIEW venus_bi.dim_regulation AS
SELECT
    r.regulation_id AS regulation_key,
    r.title AS regulation_title,
    r.country,
    r.agency,
    r.document_url,
    r.status::text AS regulation_status,
    r.effective_date,
    r.summary,
    r.created_at::date AS created_date,
    r.updated_at::date AS updated_date
FROM venus.regulations r;

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
    u.updated_at::date AS updated_date
FROM venus.users u
LEFT JOIN venus.user_profiles up
  ON up.fk_user_id = u.user_id
LEFT JOIN venus.user_preferences pref
  ON pref.fk_user_id = u.user_id;


CREATE OR REPLACE VIEW venus_bi.fact_product_score AS
SELECT
    ps.product_score_id AS product_score_key,
    ps.fk_product_version_id AS product_version_key,
    pv.fk_product_id AS product_key,
    p.fk_brand_id AS brand_key,
    p.fk_product_category_id AS product_category_key,
    ps.fk_scoring_model_id AS scoring_model_key,
    ps.calculated_at::date AS date_key,

    ps.overall_score,
    ps.health_score,
    ps.environmental_score,
    ps.ethical_score,
    ps.performance_score,
    ps.transparency_score,
    ps.confidence_score,

    1::bigint AS score_count
FROM venus.product_scores ps
JOIN venus.product_versions pv
  ON pv.product_version_id = ps.fk_product_version_id
JOIN venus.products p
  ON p.product_id = pv.fk_product_id;

CREATE OR REPLACE VIEW venus_bi.fact_product_ingredient AS
SELECT
    pi.product_ingredient_id AS product_ingredient_key,
    pi.fk_product_version_id AS product_version_key,
    pv.fk_product_id AS product_key,
    p.fk_brand_id AS brand_key,
    p.fk_product_category_id AS product_category_key,
    pi.fk_ingredient_id AS ingredient_key,
    i.fk_ingredient_category_id AS ingredient_category_key,

    pi.position AS ingredient_position,
    CASE WHEN pi.position = 1 THEN TRUE ELSE FALSE END AS is_first_ingredient,
    pi.created_at::date AS date_key,

    1::bigint AS ingredient_count
FROM venus.product_ingredients pi
JOIN venus.product_versions pv
  ON pv.product_version_id = pi.fk_product_version_id
JOIN venus.products p
  ON p.product_id = pv.fk_product_id
JOIN venus.ingredients i
  ON i.ingredient_id = pi.fk_ingredient_id;

CREATE OR REPLACE VIEW venus_bi.fact_ingredient_effect AS
SELECT
    ie.ingredient_effect_id AS ingredient_effect_key,
    ie.fk_ingredient_id AS ingredient_key,
    ie.fk_profile_tag_id AS profile_tag_key,
    i.fk_ingredient_category_id AS ingredient_category_key,

    ie.effect_category::text AS effect_category,
    ie.effect_name,
    ie.effect_description,
    ie.effect_strength::text AS effect_strength,
    ie.evidence_level::text AS evidence_level,
    ie.review_status::text AS review_status,
    ie.source_type::text AS source_type,
    ie.source_reference,

    ie.created_at::date AS date_key,
    1::bigint AS effect_count
FROM venus.ingredient_effects ie
JOIN venus.ingredients i
  ON i.ingredient_id = ie.fk_ingredient_id;

CREATE OR REPLACE VIEW venus_bi.fact_analysis_result AS
SELECT
    ar.analysis_result_id AS analysis_result_key,
    ar.fk_user_id AS user_key,
    ar.fk_product_version_id AS product_version_key,
    pv.fk_product_id AS product_key,
    p.fk_brand_id AS brand_key,
    p.fk_product_category_id AS product_category_key,
    ar.fk_scoring_model_id AS scoring_model_key,
    ar.created_at::date AS date_key,

    ar.overall_score,
    ar.health_score,
    ar.environmental_score,
    ar.ethical_score,
    ar.performance_score,
    ar.transparency_score,
    ar.confidence_score,
    ar.processing_time_ms,
    ar.status::text AS analysis_status,
    ar.summary,

    1::bigint AS analysis_count,
    CASE WHEN ar.status::text = 'completed' THEN 1 ELSE 0 END::bigint AS completed_analysis_count
FROM venus.analysis_results ar
JOIN venus.product_versions pv
  ON pv.product_version_id = ar.fk_product_version_id
JOIN venus.products p
  ON p.product_id = pv.fk_product_id;

CREATE OR REPLACE VIEW venus_bi.fact_personalized_score AS
SELECT
    psc.personalized_score_id AS personalized_score_key,
    psc.fk_user_id AS user_key,
    psc.fk_product_version_id AS product_version_key,
    pv.fk_product_id AS product_key,
    p.fk_brand_id AS brand_key,
    p.fk_product_category_id AS product_category_key,
    psc.fk_analysis_result_id AS analysis_result_key,
    psc.fk_scoring_model_id AS scoring_model_key,
    psc.created_at::date AS date_key,

    psc.final_score,
    psc.compatibility_percentage,
    psc.risk_level::text AS risk_level,
    psc.recommendation_level::text AS recommendation_level,
    psc.summary,

    1::bigint AS personalized_score_count
FROM venus.personalized_scores psc
JOIN venus.product_versions pv
  ON pv.product_version_id = psc.fk_product_version_id
JOIN venus.products p
  ON p.product_id = pv.fk_product_id;

CREATE OR REPLACE VIEW venus_bi.fact_recommendation AS
SELECT
    r.recommendation_id AS recommendation_key,
    r.fk_user_id AS user_key,
    r.fk_profile_tag_id AS profile_tag_key,
    r.fk_product_version_id AS product_version_key,
    pv.fk_product_id AS product_key,
    p.fk_brand_id AS brand_key,
    b.name AS brand_name,
    p.fk_product_category_id AS product_category_key,
    pc.name AS product_category_name,
    r.fk_analysis_result_id AS analysis_result_key,
    r.created_at::date AS date_key,

    r.recommendation_type::text AS recommendation_type,
    r.confidence_score,
    r.ranking_position,
    r.reason,

    1::bigint AS recommendation_count,
    CASE
        WHEN r.recommendation_type::text IN ('ideal', 'recommended') THEN 1
        ELSE 0
    END::bigint AS positive_recommendation_count
FROM venus.recommendations r
JOIN venus.product_versions pv
  ON pv.product_version_id = r.fk_product_version_id
JOIN venus.products p
  ON p.product_id = pv.fk_product_id
JOIN venus.brands b
  ON b.brand_id = p.fk_brand_id
JOIN venus.product_categories pc
  ON pc.product_category_id = p.fk_product_category_id;

CREATE OR REPLACE VIEW venus_bi.fact_review AS
SELECT
    rv.review_id AS review_key,
    rv.fk_user_id AS user_key,
    rv.fk_product_version_id AS product_version_key,
    pv.fk_product_id AS product_key,
    p.fk_brand_id AS brand_key,
    p.fk_product_category_id AS product_category_key,
    rv.created_at::date AS date_key,

    rv.rating,
    rv.verified_use,
    rv.title,
    rv.comment,

    1::bigint AS review_count,
    CASE WHEN rv.verified_use THEN 1 ELSE 0 END::bigint AS verified_review_count
FROM venus.reviews rv
JOIN venus.product_versions pv
  ON pv.product_version_id = rv.fk_product_version_id
JOIN venus.products p
  ON p.product_id = pv.fk_product_id;

CREATE OR REPLACE VIEW venus_bi.fact_packaging AS
SELECT
    pg.packaging_id AS packaging_key,
    pg.fk_product_version_id AS product_version_key,
    pv.fk_product_id AS product_key,
    p.fk_brand_id AS brand_key,
    p.fk_product_category_id AS product_category_key,
    pg.created_at::date AS date_key,

    pg.material::text AS material,
    pg.material_detail,
    pg.packaging_format::text AS packaging_format,
    pg.is_recyclable,
    pg.is_refillable,
    pg.is_biodegradable,
    pg.recycled_content_percentage,
    pg.confidence_score,
    pg.source_type::text AS source_type,
    pg.was_manual_verified,

    1::bigint AS packaging_count
FROM venus.packaging pg
JOIN venus.product_versions pv
  ON pv.product_version_id = pg.fk_product_version_id
JOIN venus.products p
  ON p.product_id = pv.fk_product_id;

CREATE OR REPLACE VIEW venus_bi.fact_product_claim AS
SELECT
    pcl.product_claim_id AS product_claim_key,
    pcl.fk_product_version_id AS product_version_key,
    pv.fk_product_id AS product_key,
    p.fk_brand_id AS brand_key,
    p.fk_product_category_id AS product_category_key,
    pcl.fk_claim_id AS claim_key,
    pcl.created_at::date AS date_key,

    pcl.was_verified,
    pcl.verified_by,
    pcl.verified_at,
    pcl.source_type::text AS source_type,
    pcl.source_reference,

    1::bigint AS claim_count,
    CASE WHEN pcl.was_verified THEN 1 ELSE 0 END::bigint AS verified_claim_count
FROM venus.product_claims pcl
JOIN venus.product_versions pv
  ON pv.product_version_id = pcl.fk_product_version_id
JOIN venus.products p
  ON p.product_id = pv.fk_product_id;


CREATE OR REPLACE VIEW venus_bi.vw_product_overview AS
WITH scores AS (
    SELECT
        ps.product_key,
        COUNT(*) AS score_records,
        ROUND(AVG(ps.overall_score), 2) AS avg_overall_score,
        ROUND(AVG(ps.health_score), 2) AS avg_health_score,
        ROUND(AVG(ps.environmental_score), 2) AS avg_environmental_score,
        ROUND(AVG(ps.ethical_score), 2) AS avg_ethical_score,
        ROUND(AVG(ps.performance_score), 2) AS avg_performance_score,
        ROUND(AVG(ps.transparency_score), 2) AS avg_transparency_score,
        ROUND(AVG(ps.confidence_score), 2) AS avg_score_confidence
    FROM venus_bi.fact_product_score ps
    GROUP BY ps.product_key
),
reviews AS (
    SELECT
        fr.product_key,
        COUNT(*) AS review_count,
        ROUND(AVG(fr.rating), 2) AS avg_rating,
        SUM(fr.verified_review_count) AS verified_review_count
    FROM venus_bi.fact_review fr
    GROUP BY fr.product_key
),
ingredients AS (
    SELECT
        fpi.product_key,
        COUNT(*) AS ingredient_records,
        COUNT(DISTINCT fpi.ingredient_key) AS distinct_ingredient_count
    FROM venus_bi.fact_product_ingredient fpi
    GROUP BY fpi.product_key
),
packaging AS (
    SELECT
        fp.product_key,
        MAX(CASE WHEN fp.is_recyclable THEN 1 ELSE 0 END) AS has_recyclable_packaging,
        MAX(CASE WHEN fp.is_refillable THEN 1 ELSE 0 END) AS has_refillable_packaging,
        MAX(CASE WHEN fp.is_biodegradable THEN 1 ELSE 0 END) AS has_biodegradable_packaging,
        ROUND(AVG(fp.recycled_content_percentage), 2) AS avg_recycled_content_percentage
    FROM venus_bi.fact_packaging fp
    GROUP BY fp.product_key
)
SELECT
    p.product_key,
    p.product_name,
    p.brand_key,
    p.brand_name,
    p.brand_country,
    p.product_category_key,
    p.product_category_name,
    p.is_active,

    COALESCE(s.score_records, 0) AS score_records,
    s.avg_overall_score,
    s.avg_health_score,
    s.avg_environmental_score,
    s.avg_ethical_score,
    s.avg_performance_score,
    s.avg_transparency_score,
    s.avg_score_confidence,

    COALESCE(r.review_count, 0) AS review_count,
    r.avg_rating,
    COALESCE(r.verified_review_count, 0) AS verified_review_count,

    COALESCE(i.ingredient_records, 0) AS ingredient_records,
    COALESCE(i.distinct_ingredient_count, 0) AS distinct_ingredient_count,

    COALESCE(pg.has_recyclable_packaging, 0) AS has_recyclable_packaging,
    COALESCE(pg.has_refillable_packaging, 0) AS has_refillable_packaging,
    COALESCE(pg.has_biodegradable_packaging, 0) AS has_biodegradable_packaging,
    pg.avg_recycled_content_percentage
FROM venus_bi.dim_product p
LEFT JOIN scores s
  ON s.product_key = p.product_key
LEFT JOIN reviews r
  ON r.product_key = p.product_key
LEFT JOIN ingredients i
  ON i.product_key = p.product_key
LEFT JOIN packaging pg
  ON pg.product_key = p.product_key;

CREATE OR REPLACE VIEW venus_bi.vw_ingredient_overview AS
WITH uses AS (
    SELECT
        fpi.ingredient_key,
        COUNT(*) AS product_ingredient_records,
        COUNT(DISTINCT fpi.product_key) AS product_count
    FROM venus_bi.fact_product_ingredient fpi
    GROUP BY fpi.ingredient_key
),
effects AS (
    SELECT
        fie.ingredient_key,
        COUNT(*) AS effect_count,
        COUNT(DISTINCT fie.profile_tag_key) AS profile_tag_count,
        SUM(
            CASE
                WHEN fie.effect_category IN ('risk', 'warning', 'contraindication')
                THEN 1 ELSE 0
            END
        ) AS risk_effect_count
    FROM venus_bi.fact_ingredient_effect fie
    GROUP BY fie.ingredient_key
)
SELECT
    i.ingredient_key,
    i.inci_name,
    i.common_name,
    i.ingredient_category_key,
    i.ingredient_category_name,
    i.function_summary,
    i.biodegradability_level,
    i.irritation_risk_level,
    i.comedogenicity_score,
    i.environmental_risk_level,
    i.scientific_confidence,

    COALESCE(u.product_ingredient_records, 0) AS product_ingredient_records,
    COALESCE(u.product_count, 0) AS product_count,

    COALESCE(e.effect_count, 0) AS effect_count,
    COALESCE(e.profile_tag_count, 0) AS profile_tag_count,
    COALESCE(e.risk_effect_count, 0) AS risk_effect_count
FROM venus_bi.dim_ingredient i
LEFT JOIN uses u
  ON u.ingredient_key = i.ingredient_key
LEFT JOIN effects e
  ON e.ingredient_key = i.ingredient_key;

CREATE OR REPLACE VIEW venus_bi.vw_analysis_kpi AS
SELECT
    far.date_key,
    far.product_key,
    far.product_version_key,
    far.brand_key,
    far.product_category_key,

    COUNT(*) AS analysis_count,
    SUM(far.completed_analysis_count) AS completed_analysis_count,
    ROUND(AVG(far.overall_score), 2) AS avg_overall_score,
    ROUND(AVG(far.health_score), 2) AS avg_health_score,
    ROUND(AVG(far.environmental_score), 2) AS avg_environmental_score,
    ROUND(AVG(far.ethical_score), 2) AS avg_ethical_score,
    ROUND(AVG(far.performance_score), 2) AS avg_performance_score,
    ROUND(AVG(far.transparency_score), 2) AS avg_transparency_score,
    ROUND(AVG(far.confidence_score), 2) AS avg_confidence_score,
    ROUND(AVG(far.processing_time_ms), 2) AS avg_processing_time_ms
FROM venus_bi.fact_analysis_result far
GROUP BY
    far.date_key,
    far.product_key,
    far.product_version_key,
    far.brand_key,
    far.product_category_key;

CREATE OR REPLACE VIEW venus_bi.vw_recommendation_kpi AS
SELECT
    fr.date_key,
    fr.product_key,
    fr.product_version_key,
    fr.brand_key,
    fr.product_category_key,
    fr.recommendation_type,

    COUNT(*) AS recommendation_count,
    SUM(fr.positive_recommendation_count) AS positive_recommendation_count,
    ROUND(AVG(fr.confidence_score), 2) AS avg_confidence_score,
    ROUND(AVG(NULLIF(fr.ranking_position, 0)), 2) AS avg_ranking_position
FROM venus_bi.fact_recommendation fr
GROUP BY
    fr.date_key,
    fr.product_key,
    fr.product_version_key,
    fr.brand_key,
    fr.product_category_key,
    fr.recommendation_type;

CREATE OR REPLACE VIEW venus_bi.vw_product_ingredient_effect AS
SELECT
    fpi.product_version_key,
    fpi.product_key,
    fpi.brand_key,
    fpi.product_category_key,
    fpi.ingredient_key,
    fpi.ingredient_category_key,
    fpi.ingredient_position,
    fie.ingredient_effect_key,
    fie.profile_tag_key,
    fie.effect_category,
    fie.effect_name,
    fie.effect_strength,
    fie.evidence_level,
    fie.review_status,
    CASE
        WHEN fie.effect_category IN ('risk', 'warning', 'contraindication')
        THEN TRUE
        ELSE FALSE
    END AS is_risk_related
FROM venus_bi.fact_product_ingredient fpi
JOIN venus_bi.fact_ingredient_effect fie
  ON fie.ingredient_key = fpi.ingredient_key;




CREATE SCHEMA IF NOT EXISTS venus_bi;
SET search_path TO venus_bi, venus, public;



CREATE OR REPLACE VIEW venus_bi.vw_product_score_ranking AS
WITH base_scores AS (
    SELECT
        p.product_key,
        p.product_name,
        p.brand_key,
        p.brand_name,
        p.product_category_key,
        p.product_category_name,
        COALESCE(AVG(ps.overall_score), 0)::NUMERIC(10,2)
            AS avg_overall_score,
        COALESCE(AVG(ps.health_score), 0)::NUMERIC(10,2)
            AS avg_health_score,
        COALESCE(AVG(ps.environmental_score), 0)::NUMERIC(10,2)
            AS avg_environmental_score,
        COALESCE(AVG(ps.performance_score), 0)::NUMERIC(10,2)
            AS avg_performance_score,
        COALESCE(AVG(ps.transparency_score), 0)::NUMERIC(10,2)
            AS avg_transparency_score,
        COALESCE(AVG(ps.confidence_score), 0)::NUMERIC(10,2)
            AS avg_confidence_score,
        COUNT(ps.product_score_key) AS score_count
    FROM venus_bi.dim_product p
    LEFT JOIN venus_bi.fact_product_score ps
        ON ps.product_key = p.product_key
    GROUP BY
        p.product_key,
        p.product_name,
        p.brand_key,
        p.brand_name,
        p.product_category_key,
        p.product_category_name
),
ranked AS (
    SELECT
        bs.*,
        RANK() OVER (
            PARTITION BY bs.product_category_key
            ORDER BY bs.avg_overall_score DESC, bs.product_name
        ) AS category_rank,
        DENSE_RANK() OVER (
            PARTITION BY bs.product_category_key
            ORDER BY bs.avg_overall_score DESC
        ) AS category_dense_rank,
        AVG(bs.avg_overall_score) OVER (
            PARTITION BY bs.product_category_key
        )::NUMERIC(10,2) AS category_avg_score
    FROM base_scores bs
)
SELECT
    ranked.*,
    ROUND(
        ranked.avg_overall_score - ranked.category_avg_score,
        2
    ) AS delta_vs_category_avg,
    CASE
        WHEN ranked.category_avg_score = 0 THEN NULL
        ELSE ROUND(
            (ranked.avg_overall_score / ranked.category_avg_score) * 100,
            2
        )
    END AS pct_of_category_average
FROM ranked;



CREATE OR REPLACE VIEW venus_bi.vw_ingredient_usage_ranking AS
WITH ingredient_usage AS (
    SELECT
        fpi.ingredient_key,
        di.inci_name,
        di.common_name,
        di.ingredient_category_key,
        di.ingredient_category_name,
        COUNT(*)::BIGINT AS product_ingredient_records,
        COUNT(DISTINCT fpi.product_key)::BIGINT AS distinct_products
    FROM venus_bi.fact_product_ingredient fpi
    JOIN venus_bi.dim_ingredient di
        ON di.ingredient_key = fpi.ingredient_key
    GROUP BY
        fpi.ingredient_key,
        di.inci_name,
        di.common_name,
        di.ingredient_category_key,
        di.ingredient_category_name
),
ranked AS (
    SELECT
        iu.*,
        ROW_NUMBER() OVER (
            ORDER BY iu.distinct_products DESC, iu.inci_name
        ) AS global_usage_rank,
        RANK() OVER (
            PARTITION BY iu.ingredient_category_key
            ORDER BY iu.distinct_products DESC, iu.inci_name
        ) AS category_usage_rank,
        SUM(iu.distinct_products) OVER ()::NUMERIC AS total_product_uses,
        SUM(iu.distinct_products) OVER (
            ORDER BY iu.distinct_products DESC, iu.inci_name
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        )::NUMERIC AS cumulative_product_uses
    FROM ingredient_usage iu
)
SELECT
    r.*,
    CASE
        WHEN r.total_product_uses = 0 THEN NULL
        ELSE ROUND(
            (r.distinct_products / r.total_product_uses) * 100,
            2
        )
    END AS product_usage_share_pct,
    CASE
        WHEN r.total_product_uses = 0 THEN NULL
        ELSE ROUND(
            (r.cumulative_product_uses / r.total_product_uses) * 100,
            2
        )
    END AS cumulative_usage_pct
FROM ranked r;



CREATE OR REPLACE VIEW venus_bi.vw_ingredient_risk_analysis AS
WITH base AS (
    SELECT
        di.ingredient_key,
        di.inci_name,
        di.ingredient_category_name,
        di.biodegradability_level,
        di.irritation_risk_level,
        di.comedogenicity_score,
        di.environmental_risk_level,
        di.scientific_confidence,
        COALESCE(iur.distinct_products, 0) AS distinct_products
    FROM venus_bi.dim_ingredient di
    LEFT JOIN venus_bi.vw_ingredient_usage_ranking iur
        ON iur.ingredient_key = di.ingredient_key
),
scored AS (
    SELECT
        b.*,
        (
            COALESCE(b.irritation_risk_level, 0)
            + COALESCE(b.environmental_risk_level, 0)
            + COALESCE(b.comedogenicity_score, 0)
        )::NUMERIC AS composite_risk_index,
        PERCENT_RANK() OVER (
            ORDER BY
                (
                    COALESCE(b.irritation_risk_level, 0)
                    + COALESCE(b.environmental_risk_level, 0)
                    + COALESCE(b.comedogenicity_score, 0)
                )
        ) AS composite_risk_percentile,
        RANK() OVER (
            ORDER BY
                (
                    COALESCE(b.irritation_risk_level, 0)
                    + COALESCE(b.environmental_risk_level, 0)
                    + COALESCE(b.comedogenicity_score, 0)
                ) DESC,
                b.inci_name
        ) AS composite_risk_rank
    FROM base b
)
SELECT
    s.*,
    CASE
        WHEN s.composite_risk_percentile >= 0.90 THEN 'TOP_10_PCT_RISK'
        WHEN s.composite_risk_percentile >= 0.75 THEN 'HIGHER_RISK'
        WHEN s.composite_risk_percentile >= 0.50 THEN 'MEDIUM_RISK'
        ELSE 'LOWER_RISK'
    END AS relative_risk_band
FROM scored s;



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



CREATE OR REPLACE VIEW venus_bi.vw_analysis_temporal_windows AS
WITH daily AS (
    SELECT
        far.date_key,
        COUNT(*)::BIGINT AS analysis_count,
        SUM(far.completed_analysis_count)::BIGINT
            AS completed_analysis_count,
        ROUND(AVG(far.overall_score), 2)::NUMERIC(10,2)
            AS avg_overall_score,
        ROUND(AVG(far.confidence_score), 2)::NUMERIC(10,2)
            AS avg_confidence_score,
        ROUND(AVG(far.processing_time_ms), 2)::NUMERIC(12,2)
            AS avg_processing_time_ms
    FROM venus_bi.fact_analysis_result far
    GROUP BY far.date_key
),
with_windows AS (
    SELECT
        d.*,
        SUM(d.analysis_count) OVER (
            ORDER BY d.date_key
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS running_analysis_count,
        SUM(d.completed_analysis_count) OVER (
            ORDER BY d.date_key
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS running_completed_analysis_count,
        AVG(d.avg_overall_score) OVER (
            ORDER BY d.date_key
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        )::NUMERIC(10,2) AS moving_7day_avg_score,
        LAG(d.avg_overall_score) OVER (
            ORDER BY d.date_key
        )::NUMERIC(10,2) AS previous_day_avg_score
    FROM daily d
)
SELECT
    ww.*,
    CASE
        WHEN ww.previous_day_avg_score IS NULL THEN NULL
        ELSE ROUND(
            ww.avg_overall_score - ww.previous_day_avg_score,
            2
        )
    END AS day_over_day_score_delta
FROM with_windows ww;



CREATE OR REPLACE VIEW venus_bi.vw_competitive_product_ranking AS
WITH product_scores AS (
    SELECT
        p.product_key,
        p.product_name,
        p.brand_key,
        p.brand_name,
        p.product_category_key,
        p.product_category_name,
        COALESCE(AVG(fps.overall_score), 0)::NUMERIC(10,2)
            AS avg_overall_score,
        COALESCE(AVG(fps.environmental_score), 0)::NUMERIC(10,2)
            AS avg_environmental_score,
        COALESCE(AVG(fps.performance_score), 0)::NUMERIC(10,2)
            AS avg_performance_score,
        COUNT(fps.product_score_key)::BIGINT AS score_count
    FROM venus_bi.dim_product p
    LEFT JOIN venus_bi.fact_product_score fps
        ON fps.product_key = p.product_key
    GROUP BY
        p.product_key,
        p.product_name,
        p.brand_key,
        p.brand_name,
        p.product_category_key,
        p.product_category_name
),
ranked AS (
    SELECT
        ps.*,
        RANK() OVER (
            PARTITION BY ps.product_category_key
            ORDER BY ps.avg_overall_score DESC, ps.product_name
        ) AS product_rank_in_category,
        RANK() OVER (
            PARTITION BY ps.product_category_key, ps.brand_key
            ORDER BY ps.avg_overall_score DESC, ps.product_name
        ) AS product_rank_in_brand,
        MAX(ps.avg_overall_score) OVER (
            PARTITION BY ps.product_category_key
        ) AS category_best_score
    FROM product_scores ps
)
SELECT
    r.*,
    ROUND(
        r.category_best_score - r.avg_overall_score,
        2
    ) AS gap_to_category_leader
FROM ranked r;



CREATE OR REPLACE VIEW venus_bi.vw_sql_advanced_requirements_status AS
SELECT
    'CTE' AS technique,
    'vw_product_score_ranking' AS object_name,
    'Transformação + agregação por produto/categoria' AS purpose
UNION ALL
SELECT
    'WINDOW FUNCTION',
    'vw_product_score_ranking',
    'RANK, DENSE_RANK e AVG OVER'
UNION ALL
SELECT
    'WINDOW FUNCTION',
    'vw_ingredient_usage_ranking',
    'ROW_NUMBER, RANK e SUM OVER'
UNION ALL
SELECT
    'WINDOW FUNCTION',
    'vw_ingredient_risk_analysis',
    'PERCENT_RANK e RANK'
UNION ALL
SELECT
    'WINDOW FUNCTION',
    'vw_user_recommendation_ranking',
    'ROW_NUMBER, COUNT OVER e AVG OVER'
UNION ALL
SELECT
    'WINDOW FUNCTION',
    'vw_analysis_temporal_windows',
    'SUM OVER, AVG OVER e LAG'
UNION ALL
SELECT
    'CTE + WINDOW FUNCTION',
    'vw_competitive_product_ranking',
    'CTE de consolidação + RANK/MAX OVER';


