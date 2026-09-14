
CREATE SCHEMA IF NOT EXISTS venus;
CREATE SCHEMA IF NOT EXISTS venus_audit;

SET search_path TO venus, public;

DO $$
BEGIN
    CREATE TYPE user_status_enum AS ENUM ('active', 'inactive', 'blocked', 'pending');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END$$;

DO $$
BEGIN
    CREATE TYPE gender_enum AS ENUM ('female', 'male', 'non_binary', 'other', 'prefer_not_say');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END$$;

DO $$
BEGIN
    CREATE TYPE age_range_enum AS ENUM ('age_18_24', 'age_25_34', 'age_35_44', 'age_45_54', 'age_55_plus');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END$$;

DO $$
BEGIN
    CREATE TYPE skin_type_enum AS ENUM ('normal', 'dry', 'oily', 'combination', 'sensitive', 'acneic', 'other');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END$$;

DO $$
BEGIN
    CREATE TYPE skin_phototype_enum AS ENUM ('i', 'ii', 'iii', 'iv', 'v', 'vi');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END$$;

DO $$
BEGIN
    CREATE TYPE hair_type_enum AS ENUM ('straight', 'wavy', 'curly', 'coily', 'other');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END$$;

DO $$
BEGIN
    CREATE TYPE hair_pattern_enum AS ENUM ('1A','1B','1C','2A','2B','2C','3A','3B','3C','4A','4B','4C','other');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END$$;

DO $$
BEGIN
    CREATE TYPE scalp_type_enum AS ENUM ('normal', 'dry', 'oily', 'sensitive', 'dandruff', 'other');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END$$;

DO $$
BEGIN
    CREATE TYPE sensitivity_level_enum AS ENUM ('low', 'medium', 'high', 'very_high');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END$$;

DO $$
BEGIN
    CREATE TYPE allergy_type_enum AS ENUM ('ingredient', 'material', 'condition', 'other');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END$$;

DO $$
BEGIN
    CREATE TYPE profile_tag_category_enum AS ENUM ('skin', 'hair', 'health', 'values', 'sustainability', 'allergy', 'other');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END$$;

DO $$
BEGIN
    CREATE TYPE source_type_enum AS ENUM ('ocr', 'official_site', 'admin', 'user_submission', 'import', 'system');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END$$;

DO $$
BEGIN
    CREATE TYPE version_status_enum AS ENUM ('pending', 'verified', 'needs_review', 'deprecated');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END$$;

DO $$
BEGIN
    CREATE TYPE effect_category_enum AS ENUM ('benefit', 'risk', 'warning', 'contraindication', 'neutral');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END$$;

DO $$
BEGIN
    CREATE TYPE effect_type_enum AS ENUM ('bonus', 'penalty', 'alert', 'block', 'neutral');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END$$;

DO $$
BEGIN
    CREATE TYPE effect_strength_enum AS ENUM ('light', 'moderate', 'strong', 'very_strong');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END$$;

DO $$
BEGIN
    CREATE TYPE evidence_level_enum AS ENUM ('low', 'medium', 'high', 'very_high');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END$$;

DO $$
BEGIN
    CREATE TYPE review_status_enum AS ENUM ('pending', 'validated', 'under_review', 'deprecated');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END$$;

DO $$
BEGIN
    CREATE TYPE restriction_type_enum AS ENUM ('prohibited', 'restricted', 'limited', 'warning');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END$$;

DO $$
BEGIN
    CREATE TYPE claim_type_enum AS ENUM ('safety', 'ethical', 'sustainability', 'marketing', 'performance', 'other');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END$$;

DO $$
BEGIN
    CREATE TYPE packaging_material_enum AS ENUM ('plastic', 'glass', 'metal', 'paper', 'cardboard', 'mixed', 'other');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END$$;

DO $$
BEGIN
    CREATE TYPE packaging_format_enum AS ENUM ('bottle', 'tube', 'jar', 'pump', 'spray', 'sachet', 'box', 'refill', 'stick', 'other');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END$$;

DO $$
BEGIN
    CREATE TYPE regulation_status_enum AS ENUM ('draft', 'active', 'deprecated');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END$$;

DO $$
BEGIN
    CREATE TYPE recommendation_type_enum AS ENUM ('ideal', 'recommended', 'acceptable', 'not_recommended', 'contraindicated', 'alternative');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END$$;

DO $$
BEGIN
    CREATE TYPE risk_level_enum AS ENUM ('low', 'medium', 'high', 'critical');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END$$;

DO $$
BEGIN
    CREATE TYPE recommendation_level_enum AS ENUM ('ideal', 'recommended', 'acceptable', 'not_recommended', 'contraindicated');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END$$;

DO $$
BEGIN
    CREATE TYPE list_type_enum AS ENUM ('shopping', 'routine', 'favorites', 'custom');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END$$;

DO $$
BEGIN
    CREATE TYPE vote_type_enum AS ENUM ('useful', 'not_useful');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END$$;

DO $$
BEGIN
    CREATE TYPE report_target_type_enum AS ENUM ('product', 'review', 'ingredient', 'user', 'other');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END$$;

DO $$
BEGIN
    CREATE TYPE report_status_enum AS ENUM ('open', 'in_review', 'resolved', 'rejected');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END$$;

DO $$
BEGIN
    CREATE TYPE admin_role_enum AS ENUM ('admin', 'moderator', 'analyst');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END$$;

DO $$
BEGIN
    CREATE TYPE analysis_status_enum AS ENUM ('processing', 'completed', 'failed', 'pending_review');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END$$;

CREATE TABLE users (
    user_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    firebase_uid TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    status user_status_enum NOT NULL DEFAULT 'active',
    last_login TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE admin_users (
    admin_user_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    role admin_role_enum NOT NULL DEFAULT 'admin',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE allergies (
    allergy_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    allergy_name TEXT NOT NULL UNIQUE,
    allergy_type allergy_type_enum NOT NULL DEFAULT 'ingredient',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE brands (
    brand_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name TEXT NOT NULL,
    country TEXT,
    website TEXT,
    has_cruelty_free_claim BOOLEAN NOT NULL DEFAULT FALSE,
    has_vegan_claim BOOLEAN NOT NULL DEFAULT FALSE,
    is_brazilian BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (name, country)
);

CREATE TABLE product_categories (
    product_category_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    description TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE ingredient_categories (
    ingredient_category_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    parent_ingredient_category_id BIGINT REFERENCES ingredient_categories(ingredient_category_id) ON DELETE SET NULL,
    name TEXT NOT NULL UNIQUE,
    description TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE claims (
    claim_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    description TEXT NOT NULL DEFAULT '',
    claim_type claim_type_enum NOT NULL DEFAULT 'marketing',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE profile_tags (
    profile_tag_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    description TEXT NOT NULL DEFAULT '',
    slug TEXT NOT NULL UNIQUE,
    category profile_tag_category_enum NOT NULL DEFAULT 'other',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE scoring_models (
    scoring_model_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name TEXT NOT NULL,
    version TEXT NOT NULL,
    description TEXT NOT NULL DEFAULT '',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (name, version)
);

CREATE TABLE score_categories (
    score_category_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    description TEXT NOT NULL DEFAULT '',
    default_weight NUMERIC(6,2) NOT NULL DEFAULT 1.00,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE regulations (
    regulation_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title TEXT NOT NULL,
    country TEXT NOT NULL,
    agency TEXT NOT NULL,
    document_url TEXT NOT NULL,
    status regulation_status_enum NOT NULL DEFAULT 'draft',
    effective_date DATE,
    summary TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (title, country, agency)
);

CREATE TABLE user_profiles (
    user_profile_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fk_user_id BIGINT NOT NULL UNIQUE REFERENCES users(user_id) ON DELETE CASCADE,
    skin_type skin_type_enum NOT NULL DEFAULT 'other',
    skin_phototype skin_phototype_enum NOT NULL DEFAULT 'iii',
    has_hyperpigmentation BOOLEAN NOT NULL DEFAULT FALSE,
    has_melasma BOOLEAN NOT NULL DEFAULT FALSE,
    has_rosacea BOOLEAN NOT NULL DEFAULT FALSE,
    has_eczema BOOLEAN NOT NULL DEFAULT FALSE,
    hair_type hair_type_enum NOT NULL DEFAULT 'other',
    hair_pattern hair_pattern_enum,
    scalp_type scalp_type_enum NOT NULL DEFAULT 'other',
    skin_sensitivity sensitivity_level_enum NOT NULL DEFAULT 'medium',
    acne_prone BOOLEAN NOT NULL DEFAULT FALSE,
    age_range age_range_enum NOT NULL DEFAULT 'age_18_24',
    gender gender_enum NOT NULL DEFAULT 'prefer_not_say',
    is_pregnant BOOLEAN NOT NULL DEFAULT FALSE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT ck_user_profiles_hair_pattern_consistency CHECK (
        hair_pattern IS NULL
        OR hair_pattern = 'other'
        OR (hair_pattern IN ('1A','1B','1C') AND hair_type = 'straight')
        OR (hair_pattern IN ('2A','2B','2C') AND hair_type = 'wavy')
        OR (hair_pattern IN ('3A','3B','3C') AND hair_type = 'curly')
        OR (hair_pattern IN ('4A','4B','4C') AND hair_type = 'coily')
    ),
    CONSTRAINT ck_user_profiles_adult_age_range CHECK (
        age_range IN ('age_18_24','age_25_34','age_35_44','age_45_54','age_55_plus')
    )
);

CREATE TABLE user_preferences (
    user_preference_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fk_user_id BIGINT NOT NULL UNIQUE REFERENCES users(user_id) ON DELETE CASCADE,
    prefer_cruelty_free BOOLEAN NOT NULL DEFAULT FALSE,
    prefer_vegan BOOLEAN NOT NULL DEFAULT FALSE,
    prefer_sustainable BOOLEAN NOT NULL DEFAULT FALSE,
    prefer_fragrance_free BOOLEAN NOT NULL DEFAULT FALSE,
    prefer_paraben_free BOOLEAN NOT NULL DEFAULT FALSE,
    prefer_sulfate_free BOOLEAN NOT NULL DEFAULT FALSE,
    prefer_silicone_free BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE user_allergies (
    user_allergy_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fk_user_id BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    fk_allergy_id BIGINT NOT NULL REFERENCES allergies(allergy_id) ON DELETE CASCADE,
    severity risk_level_enum NOT NULL DEFAULT 'medium',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (fk_user_id, fk_allergy_id)
);

CREATE TABLE user_profile_tags (
    user_profile_tag_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fk_user_id BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    fk_profile_tag_id BIGINT NOT NULL REFERENCES profile_tags(profile_tag_id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    UNIQUE (fk_user_id, fk_profile_tag_id)
);

CREATE TABLE products (
    product_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fk_brand_id BIGINT NOT NULL REFERENCES brands(brand_id) ON DELETE RESTRICT,
    fk_product_category_id BIGINT NOT NULL REFERENCES product_categories(product_category_id) ON DELETE RESTRICT,
    name TEXT NOT NULL,
    description TEXT NOT NULL DEFAULT '',
    slug TEXT NOT NULL UNIQUE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE product_versions (
    product_version_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fk_product_id BIGINT NOT NULL REFERENCES products(product_id) ON DELETE CASCADE,
    version_name TEXT NOT NULL,
    display_name TEXT NOT NULL,
    status version_status_enum NOT NULL DEFAULT 'pending',
    is_current BOOLEAN NOT NULL DEFAULT FALSE,
    formula_signature TEXT NOT NULL,
    detected_by source_type_enum NOT NULL DEFAULT 'system',
    effective_from DATE NOT NULL DEFAULT CURRENT_DATE,
    effective_to DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (fk_product_id, formula_signature)
);

CREATE TABLE product_labels (
    product_label_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fk_product_version_id BIGINT NOT NULL UNIQUE REFERENCES product_versions(product_version_id) ON DELETE CASCADE,
    normalized_text TEXT NOT NULL DEFAULT '',
    language TEXT NOT NULL DEFAULT 'pt-BR',
    source_type source_type_enum NOT NULL DEFAULT 'ocr',
    source_reference TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE packaging (
    packaging_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fk_product_version_id BIGINT NOT NULL UNIQUE REFERENCES product_versions(product_version_id) ON DELETE CASCADE,
    material packaging_material_enum NOT NULL DEFAULT 'other',
    material_detail TEXT NOT NULL DEFAULT '',
    packaging_format packaging_format_enum NOT NULL DEFAULT 'other',
    is_recyclable BOOLEAN NOT NULL DEFAULT FALSE,
    is_refillable BOOLEAN NOT NULL DEFAULT FALSE,
    is_biodegradable BOOLEAN NOT NULL DEFAULT FALSE,
    recycled_content_percentage NUMERIC(5,2),
    confidence_score SMALLINT NOT NULL DEFAULT 0,
    source_type source_type_enum NOT NULL DEFAULT 'admin',
    source_reference TEXT,
    was_manual_verified BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE product_claims (
    product_claim_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fk_product_version_id BIGINT NOT NULL REFERENCES product_versions(product_version_id) ON DELETE CASCADE,
    fk_claim_id BIGINT NOT NULL REFERENCES claims(claim_id) ON DELETE RESTRICT,
    was_verified BOOLEAN NOT NULL DEFAULT FALSE,
    verified_by TEXT,
    verified_at TIMESTAMPTZ,
    source_type source_type_enum NOT NULL DEFAULT 'admin',
    source_reference TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (fk_product_version_id, fk_claim_id)
);

CREATE TABLE ingredients (
    ingredient_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fk_ingredient_category_id BIGINT NOT NULL REFERENCES ingredient_categories(ingredient_category_id) ON DELETE RESTRICT,
    inci_name TEXT NOT NULL UNIQUE,
    common_name TEXT NOT NULL DEFAULT '',
    function_summary TEXT NOT NULL DEFAULT '',
    description TEXT NOT NULL DEFAULT '',
    biodegradability_level SMALLINT NOT NULL DEFAULT 0,
    irritation_risk_level SMALLINT NOT NULL DEFAULT 0,
    comedogenicity_score SMALLINT NOT NULL DEFAULT 0,
    environmental_risk_level SMALLINT NOT NULL DEFAULT 0,
    safety_summary TEXT NOT NULL DEFAULT '',
    scientific_confidence SMALLINT NOT NULL DEFAULT 0,
    source_type source_type_enum NOT NULL DEFAULT 'import',
    source_reference TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE ingredient_aliases (
    ingredient_alias_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fk_ingredient_id BIGINT NOT NULL REFERENCES ingredients(ingredient_id) ON DELETE CASCADE,
    alias_name TEXT NOT NULL,
    alias_language TEXT NOT NULL DEFAULT 'en',
    source_type source_type_enum NOT NULL DEFAULT 'admin',
    source_reference TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (fk_ingredient_id, alias_name, alias_language)
);

CREATE TABLE ingredient_properties (
    ingredient_property_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fk_ingredient_id BIGINT NOT NULL REFERENCES ingredients(ingredient_id) ON DELETE CASCADE,
    property_name TEXT NOT NULL,
    property_value TEXT NOT NULL,
    unit TEXT NOT NULL DEFAULT '',
    source_type source_type_enum NOT NULL DEFAULT 'admin',
    source_reference TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (fk_ingredient_id, property_name, unit)
);

CREATE TABLE ingredient_effects (
    ingredient_effect_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fk_ingredient_id BIGINT NOT NULL REFERENCES ingredients(ingredient_id) ON DELETE CASCADE,
    fk_profile_tag_id BIGINT NOT NULL REFERENCES profile_tags(profile_tag_id) ON DELETE CASCADE,
    effect_category effect_category_enum NOT NULL,
    effect_name TEXT NOT NULL,
    effect_description TEXT NOT NULL DEFAULT '',
    effect_strength effect_strength_enum NOT NULL DEFAULT 'moderate',
    evidence_level evidence_level_enum NOT NULL DEFAULT 'medium',
    review_status review_status_enum NOT NULL DEFAULT 'pending',
    source_type source_type_enum NOT NULL DEFAULT 'admin',
    source_reference TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (fk_ingredient_id, fk_profile_tag_id, effect_category, effect_name)
);

CREATE TABLE ingredient_regulations (
    ingredient_regulation_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fk_ingredient_id BIGINT NOT NULL REFERENCES ingredients(ingredient_id) ON DELETE CASCADE,
    fk_regulation_id BIGINT NOT NULL REFERENCES regulations(regulation_id) ON DELETE CASCADE,
    restriction_type restriction_type_enum NOT NULL DEFAULT 'warning',
    max_concentration_value NUMERIC(10,4),
    unit TEXT NOT NULL DEFAULT '',
    notes TEXT NOT NULL DEFAULT '',
    source_type source_type_enum NOT NULL DEFAULT 'admin',
    source_reference TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (fk_ingredient_id, fk_regulation_id)
);

CREATE TABLE product_ingredients (
    product_ingredient_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fk_product_version_id BIGINT NOT NULL REFERENCES product_versions(product_version_id) ON DELETE CASCADE,
    fk_ingredient_id BIGINT NOT NULL REFERENCES ingredients(ingredient_id) ON DELETE RESTRICT,
    position INTEGER NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (fk_product_version_id, fk_ingredient_id),
    UNIQUE (fk_product_version_id, position)
);

CREATE TABLE allergy_ingredients (
    allergy_ingredient_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fk_allergy_id BIGINT NOT NULL REFERENCES allergies(allergy_id) ON DELETE CASCADE,
    fk_ingredient_id BIGINT NOT NULL REFERENCES ingredients(ingredient_id) ON DELETE CASCADE,
    source_type source_type_enum NOT NULL DEFAULT 'admin',
    source_reference TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (fk_allergy_id, fk_ingredient_id)
);

CREATE TABLE compatibility_rules (
    compatibility_rule_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fk_ingredient_effect_id BIGINT NOT NULL REFERENCES ingredient_effects(ingredient_effect_id) ON DELETE CASCADE,
    fk_scoring_model_id BIGINT NOT NULL REFERENCES scoring_models(scoring_model_id) ON DELETE RESTRICT,
    effect_type effect_type_enum NOT NULL,
    score_delta INTEGER NOT NULL DEFAULT 0,
    weight NUMERIC(6,2) NOT NULL DEFAULT 1.00,
    priority INTEGER NOT NULL DEFAULT 0,
    has_concentration_factor BOOLEAN NOT NULL DEFAULT FALSE,
    is_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    evidence_level evidence_level_enum NOT NULL DEFAULT 'medium',
    reason TEXT NOT NULL DEFAULT '',
    source_type source_type_enum NOT NULL DEFAULT 'system',
    source_reference TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (fk_ingredient_effect_id, fk_scoring_model_id)
);

CREATE TABLE product_scores (
    product_score_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fk_product_version_id BIGINT NOT NULL REFERENCES product_versions(product_version_id) ON DELETE CASCADE,
    fk_scoring_model_id BIGINT NOT NULL REFERENCES scoring_models(scoring_model_id) ON DELETE RESTRICT,
    overall_score INTEGER NOT NULL DEFAULT 0,
    health_score INTEGER NOT NULL DEFAULT 0,
    environmental_score INTEGER NOT NULL DEFAULT 0,
    ethical_score INTEGER NOT NULL DEFAULT 0,
    performance_score INTEGER NOT NULL DEFAULT 0,
    transparency_score INTEGER NOT NULL DEFAULT 0,
    confidence_score SMALLINT NOT NULL DEFAULT 0,
    calculated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (fk_product_version_id, fk_scoring_model_id)
);

CREATE TABLE analysis_results (
    analysis_result_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fk_user_id BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    fk_product_version_id BIGINT NOT NULL REFERENCES product_versions(product_version_id) ON DELETE CASCADE,
    fk_scoring_model_id BIGINT NOT NULL REFERENCES scoring_models(scoring_model_id) ON DELETE RESTRICT,
    overall_score INTEGER NOT NULL DEFAULT 0,
    health_score INTEGER NOT NULL DEFAULT 0,
    environmental_score INTEGER NOT NULL DEFAULT 0,
    ethical_score INTEGER NOT NULL DEFAULT 0,
    performance_score INTEGER NOT NULL DEFAULT 0,
    transparency_score INTEGER NOT NULL DEFAULT 0,
    confidence_score SMALLINT NOT NULL DEFAULT 0,
    processing_time_ms INTEGER NOT NULL DEFAULT 0,
    status analysis_status_enum NOT NULL DEFAULT 'processing',
    summary TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE rule_evaluations (
    rule_evaluation_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fk_analysis_result_id BIGINT NOT NULL REFERENCES analysis_results(analysis_result_id) ON DELETE CASCADE,
    fk_compatibility_rule_id BIGINT NOT NULL REFERENCES compatibility_rules(compatibility_rule_id) ON DELETE CASCADE,
    fk_ingredient_id BIGINT NOT NULL REFERENCES ingredients(ingredient_id) ON DELETE RESTRICT,
    fk_profile_tag_id BIGINT NOT NULL REFERENCES profile_tags(profile_tag_id) ON DELETE CASCADE,
    was_matched BOOLEAN NOT NULL DEFAULT FALSE,
    score_delta NUMERIC(10,2) NOT NULL DEFAULT 0,
    final_delta NUMERIC(10,2) NOT NULL DEFAULT 0,
    explanation TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (fk_analysis_result_id, fk_compatibility_rule_id, fk_ingredient_id, fk_profile_tag_id)
);

CREATE TABLE personalized_scores (
    personalized_score_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fk_user_id BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    fk_product_version_id BIGINT NOT NULL REFERENCES product_versions(product_version_id) ON DELETE CASCADE,
    fk_analysis_result_id BIGINT NOT NULL REFERENCES analysis_results(analysis_result_id) ON DELETE CASCADE,
    fk_scoring_model_id BIGINT NOT NULL REFERENCES scoring_models(scoring_model_id) ON DELETE RESTRICT,
    final_score INTEGER NOT NULL DEFAULT 0,
    compatibility_percentage NUMERIC(5,2) NOT NULL DEFAULT 0.00,
    risk_level risk_level_enum NOT NULL DEFAULT 'low',
    recommendation_level recommendation_level_enum NOT NULL DEFAULT 'acceptable',
    summary TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (fk_user_id, fk_product_version_id, fk_scoring_model_id)
);

CREATE TABLE recommendations (
    recommendation_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fk_user_id BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    fk_profile_tag_id BIGINT NOT NULL REFERENCES profile_tags(profile_tag_id) ON DELETE CASCADE,
    fk_product_version_id BIGINT NOT NULL REFERENCES product_versions(product_version_id) ON DELETE CASCADE,
    fk_analysis_result_id BIGINT NOT NULL REFERENCES analysis_results(analysis_result_id) ON DELETE CASCADE,
    recommendation_type recommendation_type_enum NOT NULL DEFAULT 'recommended',
    confidence_score SMALLINT NOT NULL DEFAULT 0,
    ranking_position INTEGER NOT NULL DEFAULT 0,
    reason TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (fk_user_id, fk_profile_tag_id, fk_product_version_id, fk_analysis_result_id)
);

CREATE TABLE favorites (
    favorite_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fk_user_id BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    fk_product_id BIGINT NOT NULL REFERENCES products(product_id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (fk_user_id, fk_product_id)
);

CREATE TABLE user_lists (
    user_list_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fk_user_id BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    list_type list_type_enum NOT NULL DEFAULT 'custom',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (fk_user_id, name)
);

CREATE TABLE user_list_items (
    user_list_item_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fk_user_list_id BIGINT NOT NULL REFERENCES user_lists(user_list_id) ON DELETE CASCADE,
    fk_product_id BIGINT NOT NULL REFERENCES products(product_id) ON DELETE CASCADE,
    position_order INTEGER NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (fk_user_list_id, fk_product_id),
    UNIQUE (fk_user_list_id, position_order)
);

CREATE TABLE reviews (
    review_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fk_user_id BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    fk_product_version_id BIGINT NOT NULL REFERENCES product_versions(product_version_id) ON DELETE CASCADE,
    rating NUMERIC(2,1) NOT NULL DEFAULT 0.0,
    title TEXT NOT NULL DEFAULT '',
    comment TEXT NOT NULL DEFAULT '',
    verified_use BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (fk_user_id, fk_product_version_id)
);

CREATE TABLE review_votes (
    review_vote_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fk_review_id BIGINT NOT NULL REFERENCES reviews(review_id) ON DELETE CASCADE,
    fk_user_id BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    vote_type vote_type_enum NOT NULL DEFAULT 'useful',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (fk_review_id, fk_user_id)
);

CREATE TABLE reports (
    report_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fk_user_id BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    fk_admin_user_id BIGINT REFERENCES admin_users(admin_user_id) ON DELETE SET NULL,
    target_type report_target_type_enum NOT NULL,
    target_id BIGINT NOT NULL,
    reason TEXT NOT NULL DEFAULT '',
    status report_status_enum NOT NULL DEFAULT 'open',
    handled_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_users_name ON users (name);

CREATE INDEX IF NOT EXISTS idx_users_status ON users (status);

CREATE INDEX IF NOT EXISTS idx_admin_users_role ON admin_users (role);

CREATE INDEX IF NOT EXISTS idx_admin_users_is_active ON admin_users (is_active);

CREATE INDEX IF NOT EXISTS idx_allergies_type ON allergies (allergy_type);

CREATE INDEX IF NOT EXISTS idx_brands_name ON brands (name);

CREATE INDEX IF NOT EXISTS idx_brands_country ON brands (country);

CREATE INDEX IF NOT EXISTS idx_claims_type ON claims (claim_type);

CREATE INDEX IF NOT EXISTS idx_profile_tags_category ON profile_tags (category);

CREATE INDEX IF NOT EXISTS idx_scoring_models_is_active ON scoring_models (is_active);

CREATE INDEX IF NOT EXISTS idx_regulations_status ON regulations (status);

CREATE INDEX IF NOT EXISTS idx_regulations_country ON regulations (country);

CREATE INDEX IF NOT EXISTS idx_user_allergies_allergy ON user_allergies (fk_allergy_id);

CREATE INDEX IF NOT EXISTS idx_user_profile_tags_tag ON user_profile_tags (fk_profile_tag_id);
CREATE INDEX IF NOT EXISTS idx_allergy_ingredients_allergy ON allergy_ingredients (fk_allergy_id);
CREATE INDEX IF NOT EXISTS idx_allergy_ingredients_ingredient ON allergy_ingredients (fk_ingredient_id);
CREATE INDEX IF NOT EXISTS idx_user_profiles_hair_pattern ON user_profiles (hair_pattern);
CREATE INDEX IF NOT EXISTS idx_user_profiles_skin_phototype ON user_profiles (skin_phototype);

CREATE INDEX IF NOT EXISTS idx_products_brand ON products (fk_brand_id);

CREATE INDEX IF NOT EXISTS idx_products_category ON products (fk_product_category_id);

CREATE INDEX IF NOT EXISTS idx_products_name ON products (name);

CREATE INDEX IF NOT EXISTS idx_products_is_active ON products (is_active);

CREATE INDEX IF NOT EXISTS idx_product_versions_detected_by ON product_versions (detected_by);
CREATE UNIQUE INDEX IF NOT EXISTS ux_product_versions_current ON product_versions (fk_product_id) WHERE is_current;


CREATE INDEX IF NOT EXISTS idx_product_claims_claim ON product_claims (fk_claim_id);

CREATE INDEX IF NOT EXISTS idx_ingredients_category ON ingredients (fk_ingredient_category_id);

CREATE INDEX IF NOT EXISTS idx_ingredients_common_name ON ingredients (common_name);

CREATE INDEX IF NOT EXISTS idx_ingredient_aliases_name ON ingredient_aliases (alias_name);

CREATE INDEX IF NOT EXISTS idx_ingredient_effects_profile_tag ON ingredient_effects (fk_profile_tag_id);

CREATE INDEX IF NOT EXISTS idx_ingredient_regulations_regulation ON ingredient_regulations (fk_regulation_id);

CREATE INDEX IF NOT EXISTS idx_product_ingredients_ingredient ON product_ingredients (fk_ingredient_id);

CREATE INDEX IF NOT EXISTS idx_compatibility_rules_model ON compatibility_rules (fk_scoring_model_id);

CREATE INDEX IF NOT EXISTS idx_compatibility_rules_enabled ON compatibility_rules (is_enabled);

CREATE INDEX IF NOT EXISTS idx_product_scores_model ON product_scores (fk_scoring_model_id);





CREATE INDEX IF NOT EXISTS idx_analysis_results_user ON analysis_results (fk_user_id);

CREATE INDEX IF NOT EXISTS idx_analysis_results_product_version ON analysis_results (fk_product_version_id);

CREATE INDEX IF NOT EXISTS idx_analysis_results_status ON analysis_results (status);

CREATE INDEX IF NOT EXISTS idx_rule_evaluations_analysis ON rule_evaluations (fk_analysis_result_id);

CREATE INDEX IF NOT EXISTS idx_rule_evaluations_rule ON rule_evaluations (fk_compatibility_rule_id);

CREATE INDEX IF NOT EXISTS idx_rule_evaluations_ingredient ON rule_evaluations (fk_ingredient_id);

CREATE INDEX IF NOT EXISTS idx_rule_evaluations_profile_tag ON rule_evaluations (fk_profile_tag_id);

CREATE INDEX IF NOT EXISTS idx_personalized_scores_user ON personalized_scores (fk_user_id);
CREATE INDEX IF NOT EXISTS idx_personalized_scores_version ON personalized_scores (fk_product_version_id);

CREATE INDEX IF NOT EXISTS idx_personalized_scores_analysis ON personalized_scores (fk_analysis_result_id);

CREATE INDEX IF NOT EXISTS idx_recommendations_version ON recommendations (fk_product_version_id);
CREATE INDEX IF NOT EXISTS idx_recommendations_user ON recommendations (fk_user_id);

CREATE INDEX IF NOT EXISTS idx_recommendations_analysis ON recommendations (fk_analysis_result_id);

CREATE INDEX IF NOT EXISTS idx_favorites_product ON favorites (fk_product_id);

CREATE INDEX IF NOT EXISTS idx_user_list_items_product ON user_list_items (fk_product_id);


CREATE INDEX IF NOT EXISTS idx_reviews_version ON reviews (fk_product_version_id);

CREATE INDEX IF NOT EXISTS idx_review_votes_user ON review_votes (fk_user_id);

CREATE INDEX IF NOT EXISTS idx_reports_user ON reports (fk_user_id);

CREATE INDEX IF NOT EXISTS idx_reports_admin ON reports (fk_admin_user_id);

CREATE INDEX IF NOT EXISTS idx_reports_status ON reports (status);

CREATE INDEX IF NOT EXISTS idx_reports_target ON reports (target_type, target_id);

CREATE INDEX IF NOT EXISTS idx_user_profiles_is_active ON venus.user_profiles (is_active);
CREATE INDEX IF NOT EXISTS idx_user_profile_tags_is_active ON venus.user_profile_tags (is_active);
CREATE UNIQUE INDEX IF NOT EXISTS ux_scoring_models_single_active ON venus.scoring_models ((is_active)) WHERE is_active;
CREATE UNIQUE INDEX IF NOT EXISTS ux_product_versions_current ON venus.product_versions (fk_product_id) WHERE is_current;

CREATE TABLE IF NOT EXISTS venus.user_access_events (
    access_event_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fk_user_id BIGINT NOT NULL REFERENCES venus.users(user_id) ON DELETE CASCADE,
    access_type TEXT NOT NULL DEFAULT 'APP_ACTIVITY',
    accessed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    activity_date DATE GENERATED ALWAYS AS ((accessed_at AT TIME ZONE 'UTC')::DATE) STORED,
    application_name TEXT,
    client_ip INET,
    metadata JSONB NOT NULL DEFAULT '{}'::JSONB
);

CREATE INDEX IF NOT EXISTS idx_user_access_events_user_date ON venus.user_access_events (fk_user_id, activity_date);
CREATE INDEX IF NOT EXISTS idx_user_access_events_date ON venus.user_access_events (activity_date);

CREATE OR REPLACE FUNCTION venus.fn_register_user_access(
    p_user_id BIGINT,
    p_access_type TEXT DEFAULT 'APP_ACTIVITY',
    p_metadata JSONB DEFAULT '{}'::JSONB
)
RETURNS BIGINT LANGUAGE plpgsql AS $$
DECLARE v_id BIGINT;
BEGIN
    INSERT INTO venus.user_access_events(fk_user_id, access_type, application_name, client_ip, metadata)
    VALUES (p_user_id, COALESCE(NULLIF(p_access_type,''),'APP_ACTIVITY'), current_setting('application_name', true), inet_client_addr(), COALESCE(p_metadata,'{}'::JSONB))
    RETURNING access_event_id INTO v_id;
    RETURN v_id;
END;
$$;

CREATE OR REPLACE VIEW venus.v_dau AS
SELECT activity_date, COUNT(DISTINCT fk_user_id) AS daily_active_users
FROM venus.user_access_events GROUP BY activity_date;

CREATE OR REPLACE VIEW venus.v_dau_rolling_30d AS
SELECT activity_date, daily_active_users,
       AVG(daily_active_users) OVER (ORDER BY activity_date ROWS BETWEEN 29 PRECEDING AND CURRENT ROW) AS dau_30d_avg
FROM venus.v_dau;

CREATE TABLE IF NOT EXISTS venus_audit.audit_logs (
    audit_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    schema_name TEXT NOT NULL,
    table_name TEXT NOT NULL,
    operation_type TEXT NOT NULL,
    old_data JSONB,
    new_data JSONB,
    changed_by TEXT NOT NULL DEFAULT CURRENT_USER,
    changed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    application_name TEXT
);

CREATE INDEX IF NOT EXISTS idx_audit_logs_table ON venus_audit.audit_logs (schema_name, table_name, changed_at);
CREATE INDEX IF NOT EXISTS idx_audit_logs_changed_at ON venus_audit.audit_logs (changed_at);

CREATE OR REPLACE FUNCTION venus.fn_touch_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION venus.fn_ensure_single_current_product_version()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.is_current THEN
        UPDATE venus.product_versions
           SET is_current = FALSE,
               updated_at = NOW()
         WHERE fk_product_id = NEW.fk_product_id
           AND product_version_id <> COALESCE(NEW.product_version_id, -1)
           AND is_current = TRUE;
    END IF;
    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION venus.fn_sync_dependent_active_status()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_should_be_active BOOLEAN := (NEW.status = 'active');
BEGIN
    UPDATE venus.user_profiles
       SET is_active = v_should_be_active
     WHERE fk_user_id = NEW.user_id
       AND is_active IS DISTINCT FROM v_should_be_active;

    UPDATE venus.user_profile_tags
       SET is_active = v_should_be_active
     WHERE fk_user_id = NEW.user_id
       AND is_active IS DISTINCT FROM v_should_be_active;

    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION venus.fn_scoring_models_single_active()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.is_active THEN
        UPDATE venus.scoring_models
           SET is_active = FALSE,
               updated_at = NOW()
         WHERE is_active = TRUE
           AND scoring_model_id <> COALESCE(NEW.scoring_model_id, -1);
    END IF;
    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION venus.fn_validate_analysis_status_transition()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF OLD.status = NEW.status THEN RETURN NEW; END IF;

    IF (OLD.status, NEW.status) IN (
        ('processing', 'completed'),
        ('processing', 'failed'),
        ('processing', 'pending_review'),
        ('pending_review', 'completed'),
        ('pending_review', 'failed')
    ) THEN
        RETURN NEW;
    END IF;

    RAISE EXCEPTION 'analysis_result % cannot change status from % to %',
        OLD.analysis_result_id, OLD.status, NEW.status;
END;
$$;

CREATE OR REPLACE FUNCTION venus.fn_audit_row()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF COALESCE(current_setting('venus.bootstrap', true), 'off') = 'on' THEN
        RETURN CASE WHEN TG_OP = 'DELETE' THEN OLD ELSE NEW END;
    END IF;

    IF TG_OP = 'INSERT' THEN
        INSERT INTO venus_audit.audit_logs
            (schema_name, table_name, operation_type, old_data, new_data, changed_by, application_name)
        VALUES
            (TG_TABLE_SCHEMA, TG_TABLE_NAME, TG_OP, NULL, to_jsonb(NEW), CURRENT_USER, current_setting('application_name', true));
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO venus_audit.audit_logs
            (schema_name, table_name, operation_type, old_data, new_data, changed_by, application_name)
        VALUES
            (TG_TABLE_SCHEMA, TG_TABLE_NAME, TG_OP, to_jsonb(OLD), to_jsonb(NEW), CURRENT_USER, current_setting('application_name', true));
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO venus_audit.audit_logs
            (schema_name, table_name, operation_type, old_data, new_data, changed_by, application_name)
        VALUES
            (TG_TABLE_SCHEMA, TG_TABLE_NAME, TG_OP, to_jsonb(OLD), NULL, CURRENT_USER, current_setting('application_name', true));
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$;

CREATE OR REPLACE PROCEDURE venus.sp_set_user_active(p_user_id BIGINT, p_active BOOLEAN)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE venus.users
       SET status = CASE
           WHEN p_active THEN 'active'::venus.user_status_enum
           ELSE 'inactive'::venus.user_status_enum
       END
     WHERE user_id = p_user_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'usuário % não encontrado', p_user_id;
    END IF;
END;
$$;

CREATE OR REPLACE PROCEDURE venus.sp_purge_audit_logs(p_keep_days INTEGER DEFAULT 90)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_keep_days < 1 THEN
        RAISE EXCEPTION 'p_keep_days deve ser >= 1';
    END IF;
    DELETE FROM venus_audit.audit_logs
     WHERE changed_at < NOW() - make_interval(days => p_keep_days);
END;
$$;

CREATE OR REPLACE FUNCTION venus.fn_log_user_activity()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN PERFORM venus.fn_register_user_access(NEW.user_id, 'LOGIN'); RETURN NEW; END;
$$;

CREATE OR REPLACE FUNCTION venus.fn_log_fk_user_activity()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN PERFORM venus.fn_register_user_access(NEW.fk_user_id, TG_TABLE_NAME); RETURN NEW; END;
$$;

DROP TRIGGER IF EXISTS trg_log_user_login_activity ON venus.users;
CREATE TRIGGER trg_log_user_login_activity AFTER UPDATE OF last_login ON venus.users
FOR EACH ROW WHEN (NEW.last_login IS DISTINCT FROM OLD.last_login AND NEW.last_login IS NOT NULL)
EXECUTE FUNCTION venus.fn_log_user_activity();

DROP TRIGGER IF EXISTS trg_ensure_single_current_product_version ON venus.product_versions;
CREATE TRIGGER trg_ensure_single_current_product_version
BEFORE INSERT OR UPDATE OF is_current, fk_product_id ON venus.product_versions
FOR EACH ROW EXECUTE FUNCTION venus.fn_ensure_single_current_product_version();

DROP TRIGGER IF EXISTS trg_sync_dependent_active_status ON venus.users;
CREATE TRIGGER trg_sync_dependent_active_status
AFTER UPDATE OF status ON venus.users
FOR EACH ROW WHEN (OLD.status IS DISTINCT FROM NEW.status)
EXECUTE FUNCTION venus.fn_sync_dependent_active_status();

DROP TRIGGER IF EXISTS trg_scoring_models_single_active ON venus.scoring_models;
CREATE TRIGGER trg_scoring_models_single_active
BEFORE INSERT OR UPDATE OF is_active ON venus.scoring_models
FOR EACH ROW WHEN (NEW.is_active)
EXECUTE FUNCTION venus.fn_scoring_models_single_active();

DROP TRIGGER IF EXISTS trg_validate_analysis_status_transition ON venus.analysis_results;
CREATE TRIGGER trg_validate_analysis_status_transition
BEFORE UPDATE OF status ON venus.analysis_results
FOR EACH ROW EXECUTE FUNCTION venus.fn_validate_analysis_status_transition();

DO $$
DECLARE r RECORD;
BEGIN
    FOR r IN
        SELECT table_schema, table_name
        FROM information_schema.columns
        WHERE table_schema = 'venus'
          AND column_name = 'updated_at'
          AND table_name NOT IN ('data_catalog', 'data_catalog_rules')
        GROUP BY table_schema, table_name
    LOOP
        EXECUTE format('DROP TRIGGER IF EXISTS trg_set_updated_at_%I ON %I.%I;', r.table_name, r.table_schema, r.table_name);
        EXECUTE format('CREATE TRIGGER trg_set_updated_at_%I BEFORE UPDATE ON %I.%I FOR EACH ROW EXECUTE FUNCTION venus.fn_touch_updated_at();', r.table_name, r.table_schema, r.table_name);
    END LOOP;
END
$$;

DO $$
DECLARE r RECORD;
BEGIN
    FOR r IN
        SELECT table_schema, table_name
        FROM information_schema.tables
        WHERE table_schema = 'venus'
          AND table_type = 'BASE TABLE'
          AND table_name NOT IN ('data_catalog', 'data_catalog_rules')
        ORDER BY table_name
    LOOP
        EXECUTE format('DROP TRIGGER IF EXISTS trg_audit_%I ON %I.%I;', r.table_name, r.table_schema, r.table_name);
        EXECUTE format('CREATE TRIGGER trg_audit_%I AFTER INSERT OR UPDATE OR DELETE ON %I.%I FOR EACH ROW EXECUTE FUNCTION venus.fn_audit_row();', r.table_name, r.table_schema, r.table_name);
    END LOOP;
END
$$;

DO $$
DECLARE r RECORD;
BEGIN
    FOR r IN SELECT table_name FROM information_schema.columns
             WHERE table_schema='venus' AND column_name='fk_user_id'
               AND table_name IN ('analysis_results','favorites','user_lists','reviews','reports','recommendations','personalized_scores')
             GROUP BY table_name LOOP
        EXECUTE format('DROP TRIGGER IF EXISTS trg_activity_%I ON venus.%I;', r.table_name, r.table_name);
        EXECUTE format('CREATE TRIGGER trg_activity_%I AFTER INSERT OR UPDATE ON venus.%I FOR EACH ROW EXECUTE FUNCTION venus.fn_log_fk_user_activity();', r.table_name, r.table_name);
    END LOOP;
END $$;

CREATE INDEX IF NOT EXISTS idx_audit_logs_changed_by ON venus_audit.audit_logs(changed_by, changed_at);

