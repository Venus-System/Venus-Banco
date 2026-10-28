-- Venus logical schema snapshot generated from live PostgreSQL metadata.
-- This file documents the deployed model; it is not a migration script.
-- Physical tables are included; BI views are documented separately in Markdown.

CREATE TYPE "venus"."admin_role_enum" AS ENUM ('admin', 'moderator', 'analyst');
CREATE TYPE "venus"."age_range_enum" AS ENUM ('age_13_17', 'age_18_24', 'age_25_34', 'age_35_44', 'age_45_54', 'age_55_plus');
CREATE TYPE "venus"."allergy_type_enum" AS ENUM ('ingredient', 'material', 'condition', 'other');
CREATE TYPE "venus"."analysis_status_enum" AS ENUM ('processing', 'completed', 'failed', 'pending_review');
CREATE TYPE "venus"."claim_type_enum" AS ENUM ('safety', 'ethical', 'sustainability', 'marketing', 'performance', 'other');
CREATE TYPE "venus"."effect_category_enum" AS ENUM ('benefit', 'risk', 'warning', 'contraindication', 'neutral');
CREATE TYPE "venus"."effect_strength_enum" AS ENUM ('light', 'moderate', 'strong', 'very_strong');
CREATE TYPE "venus"."effect_type_enum" AS ENUM ('bonus', 'penalty', 'alert', 'block', 'neutral');
CREATE TYPE "venus"."evidence_level_enum" AS ENUM ('low', 'medium', 'high', 'very_high');
CREATE TYPE "venus"."gender_enum" AS ENUM ('female', 'male', 'non_binary', 'other', 'prefer_not_say');
CREATE TYPE "venus"."hair_pattern_enum" AS ENUM ('1A', '1B', '1C', '2A', '2B', '2C', '3A', '3B', '3C', '4A', '4B', '4C', 'other');
CREATE TYPE "venus"."list_type_enum" AS ENUM ('shopping', 'routine', 'favorites', 'custom');
CREATE TYPE "venus"."packaging_format_enum" AS ENUM ('bottle', 'tube', 'jar', 'pump', 'spray', 'sachet', 'box', 'refill', 'stick', 'other');
CREATE TYPE "venus"."packaging_material_enum" AS ENUM ('plastic', 'glass', 'metal', 'paper', 'cardboard', 'mixed', 'other');
CREATE TYPE "venus"."profile_tag_category_enum" AS ENUM ('skin', 'hair', 'health', 'values', 'sustainability', 'allergy', 'other');
CREATE TYPE "venus"."recommendation_level_enum" AS ENUM ('ideal', 'recommended', 'acceptable', 'not_recommended', 'contraindicated');
CREATE TYPE "venus"."recommendation_type_enum" AS ENUM ('ideal', 'recommended', 'acceptable', 'not_recommended', 'contraindicated', 'alternative');
CREATE TYPE "venus"."regulation_status_enum" AS ENUM ('draft', 'active', 'deprecated');
CREATE TYPE "venus"."report_status_enum" AS ENUM ('open', 'in_review', 'resolved', 'rejected');
CREATE TYPE "venus"."report_target_type_enum" AS ENUM ('product', 'review', 'ingredient', 'user', 'other');
CREATE TYPE "venus"."restriction_type_enum" AS ENUM ('prohibited', 'restricted', 'limited', 'warning');
CREATE TYPE "venus"."review_status_enum" AS ENUM ('pending', 'validated', 'under_review', 'deprecated');
CREATE TYPE "venus"."risk_level_enum" AS ENUM ('low', 'medium', 'high', 'critical');
CREATE TYPE "venus"."scalp_type_enum" AS ENUM ('normal', 'dry', 'oily', 'sensitive', 'dandruff', 'other');
CREATE TYPE "venus"."sensitivity_level_enum" AS ENUM ('low', 'medium', 'high', 'very_high');
CREATE TYPE "venus"."skin_phototype_enum" AS ENUM ('i', 'ii', 'iii', 'iv', 'v', 'vi');
CREATE TYPE "venus"."skin_type_enum" AS ENUM ('normal', 'dry', 'oily', 'combination', 'sensitive', 'acneic', 'other');
CREATE TYPE "venus"."source_type_enum" AS ENUM ('ocr', 'official_site', 'admin', 'user_submission', 'import', 'system');
CREATE TYPE "venus"."user_status_enum" AS ENUM ('active', 'inactive', 'blocked', 'pending');
CREATE TYPE "venus"."version_status_enum" AS ENUM ('pending', 'verified', 'needs_review', 'deprecated');
CREATE TYPE "venus"."vote_type_enum" AS ENUM ('useful', 'not_useful');

CREATE SCHEMA IF NOT EXISTS "venus";
CREATE SCHEMA IF NOT EXISTS "venus_audit";
CREATE SCHEMA IF NOT EXISTS "venus_rpa";
CREATE SCHEMA IF NOT EXISTS "venus_optimization";

CREATE TABLE "venus"."admin_users" (
    "admin_user_id" bigint NOT NULL,
    "name" text NOT NULL,
    "email" text NOT NULL,
    "role" venus.admin_role_enum DEFAULT 'admin'::venus.admin_role_enum NOT NULL,
    "is_active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
    "password_hash" text
);

CREATE TABLE "venus"."allergies" (
    "allergy_id" bigint NOT NULL,
    "allergy_name" text NOT NULL,
    "allergy_type" venus.allergy_type_enum DEFAULT 'ingredient'::venus.allergy_type_enum NOT NULL,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
    "is_catalog_visible" boolean DEFAULT false NOT NULL
);

CREATE TABLE "venus"."allergy_ingredients" (
    "allergy_ingredient_id" bigint NOT NULL,
    "fk_allergy_id" bigint NOT NULL,
    "fk_ingredient_id" bigint NOT NULL,
    "source_type" venus.source_type_enum DEFAULT 'admin'::venus.source_type_enum NOT NULL,
    "source_reference" text,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
COMMENT ON TABLE "venus"."allergy_ingredients" IS 'Relação explícita entre alergias e ingredientes INCI para compatibilidade de usuários com fórmulas.';
COMMENT ON COLUMN "venus"."allergy_ingredients"."fk_allergy_id" IS 'FK para a alergia declarada/cadastrada.';
COMMENT ON COLUMN "venus"."allergy_ingredients"."fk_ingredient_id" IS 'FK para o ingrediente INCI efetivamente relacionado à alergia.';

CREATE TABLE "venus"."analysis_results" (
    "analysis_result_id" bigint NOT NULL,
    "fk_user_id" bigint NOT NULL,
    "fk_product_version_id" bigint NOT NULL,
    "fk_scoring_model_id" bigint NOT NULL,
    "overall_score" integer DEFAULT 0 NOT NULL,
    "health_score" integer,
    "environmental_score" integer,
    "ethical_score" integer DEFAULT 0 NOT NULL,
    "performance_score" integer,
    "transparency_score" integer,
    "confidence_score" smallint DEFAULT 1 NOT NULL,
    "processing_time_ms" integer DEFAULT 0 NOT NULL,
    "status" venus.analysis_status_enum DEFAULT 'processing'::venus.analysis_status_enum NOT NULL,
    "summary" text DEFAULT ''::text NOT NULL,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE "venus"."brand_claim_evidence" (
    "brand_claim_evidence_id" bigint DEFAULT nextval('venus.brand_claim_evidence_brand_claim_evidence_id_seq'::regclass) NOT NULL,
    "fk_brand_id" bigint NOT NULL,
    "claim_type" text NOT NULL,
    "claim_value" boolean DEFAULT true NOT NULL,
    "source_url" text NOT NULL,
    "source_title" text NOT NULL,
    "evidence_note" text NOT NULL,
    "evidence_level" text NOT NULL,
    "verified_at" timestamp with time zone DEFAULT now() NOT NULL,
    "methodology_version" text DEFAULT 'v1'::text NOT NULL
);

CREATE TABLE "venus"."brands" (
    "brand_id" bigint NOT NULL,
    "name" text NOT NULL,
    "country" text,
    "website" text,
    "has_cruelty_free_claim" boolean,
    "has_vegan_claim" boolean,
    "is_brazilian" boolean DEFAULT false NOT NULL,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
COMMENT ON COLUMN "venus"."brands"."has_cruelty_free_claim" IS 'TRUE/FALSE somente quando houver evidência elegível; NULL significa desconhecido.';
COMMENT ON COLUMN "venus"."brands"."has_vegan_claim" IS 'TRUE/FALSE somente quando houver evidência elegível; NULL significa desconhecido.';

CREATE TABLE "venus"."claims" (
    "claim_id" bigint NOT NULL,
    "name" text NOT NULL,
    "description" text DEFAULT ''::text NOT NULL,
    "claim_type" venus.claim_type_enum DEFAULT 'marketing'::venus.claim_type_enum NOT NULL,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE "venus"."compatibility_rules" (
    "compatibility_rule_id" bigint NOT NULL,
    "fk_ingredient_effect_id" bigint NOT NULL,
    "fk_scoring_model_id" bigint NOT NULL,
    "effect_type" venus.effect_type_enum NOT NULL,
    "score_delta" integer DEFAULT 0 NOT NULL,
    "weight" numeric(6,2) DEFAULT 1.00 NOT NULL,
    "priority" integer DEFAULT 0 NOT NULL,
    "has_concentration_factor" boolean DEFAULT false NOT NULL,
    "is_enabled" boolean DEFAULT true NOT NULL,
    "evidence_level" venus.evidence_level_enum DEFAULT 'medium'::venus.evidence_level_enum NOT NULL,
    "reason" text DEFAULT ''::text NOT NULL,
    "source_type" venus.source_type_enum DEFAULT 'system'::venus.source_type_enum NOT NULL,
    "source_reference" text,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
    "is_block" boolean GENERATED STORED,
    "is_alert" boolean GENERATED STORED
);

CREATE TABLE "venus"."data_catalog" (
    "catalog_id" bigint NOT NULL,
    "object_type" text NOT NULL,
    "table_name" text NOT NULL,
    "column_name" text DEFAULT ''::text NOT NULL,
    "ordinal_position" integer,
    "data_type" text,
    "udt_name" text,
    "is_nullable" boolean,
    "default_value" text,
    "is_primary_key" boolean DEFAULT false NOT NULL,
    "is_foreign_key" boolean DEFAULT false NOT NULL,
    "referenced_table_name" text,
    "referenced_column_name" text DEFAULT ''::text NOT NULL,
    "table_description" text,
    "column_description" text,
    "business_rule" text,
    "access_level" text DEFAULT 'AUTHENTICATED'::text NOT NULL,
    "access_rule" text,
    "data_classification" text DEFAULT 'INTERNAL'::text NOT NULL,
    "sensitivity_reason" text,
    "retention_policy" text,
    "source_of_definition" text DEFAULT 'VENUS_SCHEMA'::text NOT NULL,
    "reviewed_at" timestamp with time zone DEFAULT now() NOT NULL,
    "is_active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE "venus"."data_catalog_rules" (
    "rule_id" bigint NOT NULL,
    "object_type" text NOT NULL,
    "table_name" text NOT NULL,
    "column_name" text DEFAULT ''::text NOT NULL,
    "table_description" text,
    "column_description" text,
    "business_rule" text,
    "access_level" text DEFAULT 'AUTHENTICATED'::text NOT NULL,
    "access_rule" text,
    "data_classification" text DEFAULT 'INTERNAL'::text NOT NULL,
    "sensitivity_reason" text,
    "retention_policy" text,
    "notes" text,
    "is_active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE "venus"."favorites" (
    "favorite_id" bigint NOT NULL,
    "fk_user_id" bigint NOT NULL,
    "fk_product_id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE "venus"."google_oauth_tokens" (
    "google_oauth_token_id" bigint NOT NULL,
    "fk_user_id" bigint NOT NULL,
    "encrypted_refresh_token" bytea NOT NULL,
    "scope" text NOT NULL,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE "venus"."ingredient_aliases" (
    "ingredient_alias_id" bigint NOT NULL,
    "fk_ingredient_id" bigint NOT NULL,
    "alias_name" text NOT NULL,
    "alias_language" text DEFAULT 'en'::text NOT NULL,
    "source_type" venus.source_type_enum DEFAULT 'admin'::venus.source_type_enum NOT NULL,
    "source_reference" text,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE "venus"."ingredient_categories" (
    "ingredient_category_id" bigint NOT NULL,
    "parent_ingredient_category_id" bigint,
    "name" text NOT NULL,
    "description" text DEFAULT ''::text NOT NULL,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE "venus"."ingredient_category_assignments" (
    "ingredient_category_assignment_id" bigint NOT NULL,
    "fk_ingredient_id" bigint NOT NULL,
    "fk_ingredient_category_id" bigint NOT NULL,
    "assignment_role" text DEFAULT 'secondary'::text NOT NULL,
    "source_type" venus.source_type_enum DEFAULT 'admin'::venus.source_type_enum NOT NULL,
    "source_reference" text,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE "venus"."ingredient_effect_validation_audit" (
    "audit_id" bigint DEFAULT nextval('venus.ingredient_effect_validation_audit_audit_id_seq'::regclass) NOT NULL,
    "ingredient_effect_id" bigint NOT NULL,
    "fk_ingredient_id" bigint NOT NULL,
    "from_effect_category" text NOT NULL,
    "to_effect_category" text NOT NULL,
    "from_review_status" text NOT NULL,
    "to_review_status" text NOT NULL,
    "evidence_level" text NOT NULL,
    "source_reference" text,
    "decision" text NOT NULL,
    "methodology_version" text DEFAULT 'v1'::text NOT NULL,
    "applied_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE "venus"."ingredient_effects" (
    "ingredient_effect_id" bigint NOT NULL,
    "fk_ingredient_id" bigint NOT NULL,
    "fk_profile_tag_id" bigint NOT NULL,
    "effect_category" venus.effect_category_enum NOT NULL,
    "effect_name" text NOT NULL,
    "effect_description" text DEFAULT ''::text NOT NULL,
    "effect_strength" venus.effect_strength_enum DEFAULT 'moderate'::venus.effect_strength_enum NOT NULL,
    "evidence_level" venus.evidence_level_enum DEFAULT 'medium'::venus.evidence_level_enum NOT NULL,
    "review_status" venus.review_status_enum DEFAULT 'pending'::venus.review_status_enum NOT NULL,
    "source_type" venus.source_type_enum DEFAULT 'admin'::venus.source_type_enum NOT NULL,
    "source_reference" text,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE "venus"."ingredient_evidence_queue" (
    "ingredient_evidence_queue_id" bigint NOT NULL,
    "fk_ingredient_id" bigint NOT NULL,
    "priority" smallint NOT NULL,
    "is_currently_used" boolean DEFAULT false NOT NULL,
    "queue_status" text DEFAULT 'queued'::text NOT NULL,
    "target_evidence_level" venus.evidence_level_enum DEFAULT 'medium'::venus.evidence_level_enum NOT NULL,
    "reason" text NOT NULL,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
COMMENT ON TABLE "venus"."ingredient_evidence_queue" IS 'Fila de curadoria para substituir assessments indiretos v1/low e confidence default por evidência específica.';

CREATE TABLE "venus"."ingredient_properties" (
    "ingredient_property_id" bigint NOT NULL,
    "fk_ingredient_id" bigint NOT NULL,
    "property_name" text NOT NULL,
    "property_value" text NOT NULL,
    "unit" text DEFAULT ''::text NOT NULL,
    "source_type" venus.source_type_enum DEFAULT 'admin'::venus.source_type_enum NOT NULL,
    "source_reference" text,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE "venus"."ingredient_regulations" (
    "ingredient_regulation_id" bigint NOT NULL,
    "fk_ingredient_id" bigint NOT NULL,
    "fk_regulation_id" bigint NOT NULL,
    "restriction_type" venus.restriction_type_enum DEFAULT 'warning'::venus.restriction_type_enum NOT NULL,
    "max_concentration_value" numeric(10,4),
    "unit" text DEFAULT ''::text NOT NULL,
    "notes" text DEFAULT ''::text NOT NULL,
    "source_type" venus.source_type_enum DEFAULT 'admin'::venus.source_type_enum NOT NULL,
    "source_reference" text,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE "venus"."ingredient_resolution_keys" (
    "normalized_key" text NOT NULL,
    "fk_ingredient_id" bigint NOT NULL,
    "resolution_priority" smallint DEFAULT 99 NOT NULL
);
COMMENT ON COLUMN "venus"."ingredient_resolution_keys"."resolution_priority" IS '1=INCI, 2=alias, 3=nome comum; a menor prioridade vence a resolução.';

CREATE TABLE "venus"."ingredient_risk_assessments" (
    "ingredient_risk_assessment_id" bigint NOT NULL,
    "fk_ingredient_id" bigint NOT NULL,
    "dimension" text NOT NULL,
    "score" smallint NOT NULL,
    "assessment_status" text DEFAULT 'pending'::text NOT NULL,
    "source_type" text DEFAULT 'manual'::text NOT NULL,
    "source_reference" text DEFAULT ''::text NOT NULL,
    "assessment_version" text DEFAULT 'v1'::text NOT NULL,
    "assessed_at" timestamp with time zone DEFAULT now() NOT NULL,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
    "evidence_level" venus.evidence_level_enum DEFAULT 'low'::venus.evidence_level_enum NOT NULL,
    "rationale" text DEFAULT ''::text NOT NULL,
    "assessment_scope" text DEFAULT 'ingredient_baseline'::text NOT NULL
);
COMMENT ON TABLE "venus"."ingredient_risk_assessments" IS 'Avaliações aprovadas dos quatro eixos de risco; zero só é evidência quando existir registro aprovado.';
COMMENT ON COLUMN "venus"."ingredient_risk_assessments"."evidence_level" IS 'Força da evidência que sustenta o assessment; não é o confidence_score do produto.';
COMMENT ON COLUMN "venus"."ingredient_risk_assessments"."rationale" IS 'Justificativa auditável por dimensão; avaliações indiretas devem declarar os sinais usados e a ausência de concentração/dose.';

CREATE TABLE "venus"."ingredient_risk_methodologies" (
    "methodology_version" text NOT NULL,
    "name" text NOT NULL,
    "status" text NOT NULL,
    "score_semantics" text NOT NULL,
    "unknown_policy" text NOT NULL,
    "source_hierarchy" jsonb NOT NULL,
    "effective_from" date NOT NULL,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
COMMENT ON TABLE "venus"."ingredient_risk_methodologies" IS 'Versões auditáveis das regras que convertem evidência em scores 0–10.';

CREATE TABLE "venus"."ingredient_risk_methodology_dimensions" (
    "methodology_version" text NOT NULL,
    "dimension" text NOT NULL,
    "score_direction" text NOT NULL,
    "definition" text NOT NULL,
    "required_evidence" jsonb NOT NULL,
    "anchors" jsonb NOT NULL
);
COMMENT ON TABLE "venus"."ingredient_risk_methodology_dimensions" IS 'Definição, evidência mínima e âncoras por eixo da metodologia ativa.';

CREATE TABLE "venus"."ingredients" (
    "ingredient_id" bigint NOT NULL,
    "fk_ingredient_category_id" bigint NOT NULL,
    "inci_name" text NOT NULL,
    "common_name" text DEFAULT ''::text NOT NULL,
    "function_summary" text DEFAULT ''::text NOT NULL,
    "description" text DEFAULT ''::text NOT NULL,
    "biodegradability_level" smallint DEFAULT 0 NOT NULL,
    "irritation_risk_level" smallint DEFAULT 0 NOT NULL,
    "comedogenicity_score" smallint DEFAULT 0 NOT NULL,
    "environmental_risk_level" smallint DEFAULT 0 NOT NULL,
    "safety_summary" text DEFAULT ''::text NOT NULL,
    "scientific_confidence" smallint DEFAULT 0 NOT NULL,
    "source_type" venus.source_type_enum DEFAULT 'import'::venus.source_type_enum NOT NULL,
    "source_reference" text,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
    "scientific_confidence_state" text DEFAULT 'default'::text NOT NULL
);
COMMENT ON COLUMN "venus"."ingredients"."scientific_confidence_state" IS 'default = fallback 1 sem avaliação específica; derived = valor calculado por regra; curated = evidência específica revisada.';

CREATE TABLE "venus"."media_assets" (
    "media_asset_id" bigint NOT NULL,
    "fk_user_id" bigint,
    "fk_product_version_id" bigint,
    "purpose" text NOT NULL,
    "provider" text DEFAULT 'cloudinary'::text NOT NULL,
    "resource_type" text DEFAULT 'image'::text NOT NULL,
    "delivery_type" text DEFAULT 'upload'::text NOT NULL,
    "public_id" text NOT NULL,
    "asset_id" text,
    "version" bigint,
    "secure_url" text,
    "format" text,
    "width" integer,
    "height" integer,
    "bytes" bigint,
    "folder" text,
    "original_filename" text,
    "alt_text" text,
    "sort_order" integer DEFAULT 0 NOT NULL,
    "status" text DEFAULT 'active'::text NOT NULL,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
    "fk_user_list_id" bigint
);
COMMENT ON TABLE "venus"."media_assets" IS 'Canonical registry of Cloudinary media assets. Binary content is stored outside PostgreSQL.';
COMMENT ON COLUMN "venus"."media_assets"."delivery_type" IS 'Cloudinary delivery type: upload for public delivery or authenticated for private delivery.';
COMMENT ON COLUMN "venus"."media_assets"."public_id" IS 'Cloudinary public_id. Canonical identifier controlled by the backend for replace/delete/delivery.';
COMMENT ON COLUMN "venus"."media_assets"."asset_id" IS 'Cloudinary immutable asset_id when returned by the Upload API.';
COMMENT ON COLUMN "venus"."media_assets"."secure_url" IS 'HTTPS delivery URL returned by Cloudinary. Cached metadata; public_id remains canonical.';
COMMENT ON COLUMN "venus"."media_assets"."status" IS 'Application lifecycle: pending, active, deleted or failed.';

CREATE TABLE "venus"."packaging" (
    "packaging_id" bigint NOT NULL,
    "fk_product_version_id" bigint NOT NULL,
    "material" venus.packaging_material_enum DEFAULT 'other'::venus.packaging_material_enum NOT NULL,
    "material_detail" text DEFAULT ''::text NOT NULL,
    "packaging_format" venus.packaging_format_enum DEFAULT 'other'::venus.packaging_format_enum NOT NULL,
    "is_recyclable" boolean DEFAULT false NOT NULL,
    "is_refillable" boolean DEFAULT false NOT NULL,
    "is_biodegradable" boolean DEFAULT false NOT NULL,
    "recycled_content_percentage" numeric(5,2),
    "confidence_score" smallint DEFAULT 0 NOT NULL,
    "source_type" venus.source_type_enum DEFAULT 'admin'::venus.source_type_enum NOT NULL,
    "source_reference" text,
    "was_manual_verified" boolean DEFAULT false NOT NULL,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE "venus"."packaging_evaluation_policies" (
    "policy_version" text NOT NULL,
    "status" text NOT NULL,
    "missing_packaging_policy" text NOT NULL,
    "unverified_packaging_policy" text NOT NULL,
    "source_hierarchy" jsonb NOT NULL,
    "effective_from" date NOT NULL,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE "venus"."personalized_scores" (
    "personalized_score_id" bigint NOT NULL,
    "fk_user_id" bigint NOT NULL,
    "fk_product_version_id" bigint NOT NULL,
    "fk_analysis_result_id" bigint NOT NULL,
    "fk_scoring_model_id" bigint NOT NULL,
    "final_score" integer DEFAULT 0 NOT NULL,
    "compatibility_percentage" numeric(5,2),
    "risk_level" venus.risk_level_enum DEFAULT 'low'::venus.risk_level_enum NOT NULL,
    "recommendation_level" venus.recommendation_level_enum DEFAULT 'acceptable'::venus.recommendation_level_enum NOT NULL,
    "summary" text DEFAULT ''::text NOT NULL,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE "venus"."product_categories" (
    "product_category_id" bigint NOT NULL,
    "name" text NOT NULL,
    "description" text DEFAULT ''::text NOT NULL,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE "venus"."product_claims" (
    "product_claim_id" bigint NOT NULL,
    "fk_product_version_id" bigint NOT NULL,
    "fk_claim_id" bigint NOT NULL,
    "was_verified" boolean DEFAULT false NOT NULL,
    "verified_by" text,
    "verified_at" timestamp with time zone,
    "source_type" venus.source_type_enum DEFAULT 'admin'::venus.source_type_enum NOT NULL,
    "source_reference" text,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE "venus"."product_composition_receipts" (
    "product_composition_receipt_id" bigint NOT NULL,
    "fk_product_version_id" bigint NOT NULL,
    "source_type" text NOT NULL,
    "source_reference" text DEFAULT ''::text NOT NULL,
    "raw_ingredients_text" text DEFAULT ''::text NOT NULL,
    "formula_hash" text,
    "validation_status" text NOT NULL,
    "expected_count" integer DEFAULT 0 NOT NULL,
    "resolved_count" integer DEFAULT 0 NOT NULL,
    "unresolved_count" integer DEFAULT 0 NOT NULL,
    "is_current" boolean DEFAULT true NOT NULL,
    "validated_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
COMMENT ON TABLE "venus"."product_composition_receipts" IS 'Recibo da composição bruta, resolução e validação usados para liberar um produto para score.';

CREATE TABLE "venus"."product_dimension_assessments" (
    "product_dimension_assessment_id" bigint NOT NULL,
    "fk_product_version_id" bigint NOT NULL,
    "dimension" text NOT NULL,
    "assessment_status" text DEFAULT 'pending'::text NOT NULL,
    "source_type" text DEFAULT 'manual'::text NOT NULL,
    "source_reference" text DEFAULT ''::text NOT NULL,
    "assessment_version" text DEFAULT 'v1'::text NOT NULL,
    "assessed_at" timestamp with time zone DEFAULT now() NOT NULL,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
COMMENT ON TABLE "venus"."product_dimension_assessments" IS 'Aprovação explícita das dimensões de performance e ética antes do score geral.';

CREATE TABLE "venus"."product_ingredient_resolution_issues" (
    "product_ingredient_resolution_issue_id" bigint NOT NULL,
    "fk_product_version_id" bigint NOT NULL,
    "token_position" integer NOT NULL,
    "raw_token" text NOT NULL,
    "issue_type" text NOT NULL,
    "source_reference" text,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL
);
COMMENT ON TABLE "venus"."product_ingredient_resolution_issues" IS 'Tokens OCR não encontrados ou ambíguos; só os casos sem resolução permanecem em needs_review.';

CREATE TABLE "venus"."product_ingredients" (
    "product_ingredient_id" bigint NOT NULL,
    "fk_product_version_id" bigint NOT NULL,
    "fk_ingredient_id" bigint NOT NULL,
    "position" integer NOT NULL,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE "venus"."product_labels" (
    "product_label_id" bigint NOT NULL,
    "fk_product_version_id" bigint NOT NULL,
    "normalized_text" text DEFAULT ''::text NOT NULL,
    "language" text DEFAULT 'pt-BR'::text NOT NULL,
    "source_type" venus.source_type_enum DEFAULT 'ocr'::venus.source_type_enum NOT NULL,
    "source_reference" text,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE "venus"."product_score_history" (
    "product_score_history_id" bigint NOT NULL,
    "source_product_score_id" bigint,
    "fk_product_version_id" bigint NOT NULL,
    "fk_scoring_model_id" bigint NOT NULL,
    "overall_score" integer NOT NULL,
    "health_score" integer,
    "environmental_score" integer,
    "ethical_score" integer,
    "performance_score" integer,
    "transparency_score" integer,
    "confidence_score" smallint,
    "calculated_at" timestamp with time zone,
    "invalidated_at" timestamp with time zone DEFAULT now() NOT NULL,
    "invalidation_reason" text NOT NULL
);
COMMENT ON TABLE "venus"."product_score_history" IS 'Histórico de scores removidos porque a entrada deixou de atender aos critérios de prontidão.';

CREATE TABLE "venus"."product_scores" (
    "product_score_id" bigint NOT NULL,
    "fk_product_version_id" bigint NOT NULL,
    "fk_scoring_model_id" bigint NOT NULL,
    "overall_score" integer DEFAULT 0 NOT NULL,
    "health_score" integer,
    "environmental_score" integer,
    "ethical_score" integer DEFAULT 0 NOT NULL,
    "performance_score" integer,
    "transparency_score" integer,
    "confidence_score" smallint DEFAULT 1 NOT NULL,
    "calculated_at" timestamp with time zone DEFAULT now() NOT NULL,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE "venus"."product_versions" (
    "product_version_id" bigint NOT NULL,
    "fk_product_id" bigint NOT NULL,
    "version_name" text NOT NULL,
    "display_name" text NOT NULL,
    "status" venus.version_status_enum DEFAULT 'pending'::venus.version_status_enum NOT NULL,
    "is_current" boolean DEFAULT false NOT NULL,
    "formula_signature" text NOT NULL,
    "detected_by" venus.source_type_enum DEFAULT 'system'::venus.source_type_enum NOT NULL,
    "effective_from" date DEFAULT CURRENT_DATE NOT NULL,
    "effective_to" date,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE "venus"."products" (
    "product_id" bigint NOT NULL,
    "fk_brand_id" bigint NOT NULL,
    "fk_product_category_id" bigint NOT NULL,
    "name" text NOT NULL,
    "description" text DEFAULT ''::text NOT NULL,
    "slug" text NOT NULL,
    "is_active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE "venus"."profile_tags" (
    "profile_tag_id" bigint NOT NULL,
    "name" text NOT NULL,
    "description" text DEFAULT ''::text NOT NULL,
    "slug" text NOT NULL,
    "category" venus.profile_tag_category_enum DEFAULT 'other'::venus.profile_tag_category_enum NOT NULL,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE "venus"."recommendations" (
    "recommendation_id" bigint NOT NULL,
    "fk_user_id" bigint NOT NULL,
    "fk_profile_tag_id" bigint NOT NULL,
    "fk_product_version_id" bigint NOT NULL,
    "fk_analysis_result_id" bigint NOT NULL,
    "recommendation_type" venus.recommendation_type_enum DEFAULT 'recommended'::venus.recommendation_type_enum NOT NULL,
    "confidence_score" smallint DEFAULT 1 NOT NULL,
    "ranking_position" integer DEFAULT 0 NOT NULL,
    "reason" text DEFAULT ''::text NOT NULL,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE "venus"."regulations" (
    "regulation_id" bigint NOT NULL,
    "title" text NOT NULL,
    "country" text NOT NULL,
    "agency" text NOT NULL,
    "document_url" text NOT NULL,
    "status" venus.regulation_status_enum DEFAULT 'draft'::venus.regulation_status_enum NOT NULL,
    "effective_date" date,
    "summary" text DEFAULT ''::text NOT NULL,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE "venus"."reports" (
    "report_id" bigint NOT NULL,
    "fk_user_id" bigint NOT NULL,
    "fk_admin_user_id" bigint,
    "target_type" venus.report_target_type_enum NOT NULL,
    "target_id" bigint NOT NULL,
    "reason" text DEFAULT ''::text NOT NULL,
    "status" venus.report_status_enum DEFAULT 'open'::venus.report_status_enum NOT NULL,
    "handled_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE "venus"."review_votes" (
    "review_vote_id" bigint NOT NULL,
    "fk_review_id" bigint NOT NULL,
    "fk_user_id" bigint NOT NULL,
    "vote_type" venus.vote_type_enum DEFAULT 'useful'::venus.vote_type_enum NOT NULL,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE "venus"."reviews" (
    "review_id" bigint NOT NULL,
    "fk_user_id" bigint NOT NULL,
    "fk_product_version_id" bigint NOT NULL,
    "rating" numeric(2,1) DEFAULT 0.0 NOT NULL,
    "title" text DEFAULT ''::text NOT NULL,
    "comment" text DEFAULT ''::text NOT NULL,
    "verified_use" boolean DEFAULT false NOT NULL,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE "venus"."rule_evaluations" (
    "rule_evaluation_id" bigint NOT NULL,
    "fk_analysis_result_id" bigint NOT NULL,
    "fk_compatibility_rule_id" bigint NOT NULL,
    "fk_ingredient_id" bigint NOT NULL,
    "fk_profile_tag_id" bigint NOT NULL,
    "was_matched" boolean DEFAULT false NOT NULL,
    "score_delta" numeric(10,2) DEFAULT 0 NOT NULL,
    "final_delta" numeric(10,2) DEFAULT 0 NOT NULL,
    "explanation" text DEFAULT ''::text NOT NULL,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE "venus"."score_categories" (
    "score_category_id" bigint NOT NULL,
    "name" text NOT NULL,
    "description" text DEFAULT ''::text NOT NULL,
    "default_weight" numeric(6,2) DEFAULT 1.00 NOT NULL,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE "venus"."scoring_model_categories" (
    "scoring_model_category_id" bigint NOT NULL,
    "fk_scoring_model_id" bigint NOT NULL,
    "fk_score_category_id" bigint NOT NULL,
    "weight" numeric(6,2) NOT NULL,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE "venus"."scoring_models" (
    "scoring_model_id" bigint NOT NULL,
    "name" text NOT NULL,
    "version" text NOT NULL,
    "description" text DEFAULT ''::text NOT NULL,
    "is_active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE "venus"."user_access_events" (
    "access_event_id" bigint NOT NULL,
    "fk_user_id" bigint NOT NULL,
    "access_type" text DEFAULT 'APP_ACTIVITY'::text NOT NULL,
    "accessed_at" timestamp with time zone DEFAULT now() NOT NULL,
    "activity_date" date GENERATED STORED,
    "application_name" text,
    "client_ip" inet,
    "metadata" jsonb DEFAULT '{}'::jsonb NOT NULL
);

CREATE TABLE "venus"."user_allergies" (
    "user_allergy_id" bigint NOT NULL,
    "fk_user_id" bigint NOT NULL,
    "fk_allergy_id" bigint NOT NULL,
    "severity" venus.risk_level_enum DEFAULT 'medium'::venus.risk_level_enum NOT NULL,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE "venus"."user_list_items" (
    "user_list_item_id" bigint NOT NULL,
    "fk_user_list_id" bigint NOT NULL,
    "fk_product_id" bigint NOT NULL,
    "position_order" integer NOT NULL,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE "venus"."user_lists" (
    "user_list_id" bigint NOT NULL,
    "fk_user_id" bigint NOT NULL,
    "name" text NOT NULL,
    "list_type" venus.list_type_enum DEFAULT 'custom'::venus.list_type_enum NOT NULL,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
    "description" text,
    "cover_key" text
);

CREATE TABLE "venus"."user_preferences" (
    "user_preference_id" bigint NOT NULL,
    "fk_user_id" bigint NOT NULL,
    "prefer_cruelty_free" boolean DEFAULT false NOT NULL,
    "prefer_vegan" boolean DEFAULT false NOT NULL,
    "prefer_sustainable" boolean DEFAULT false NOT NULL,
    "prefer_fragrance_free" boolean DEFAULT false NOT NULL,
    "prefer_paraben_free" boolean DEFAULT false NOT NULL,
    "prefer_sulfate_free" boolean DEFAULT false NOT NULL,
    "prefer_silicone_free" boolean DEFAULT false NOT NULL,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE "venus"."user_profile_tags" (
    "user_profile_tag_id" bigint NOT NULL,
    "fk_user_id" bigint NOT NULL,
    "fk_profile_tag_id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
    "is_active" boolean DEFAULT true NOT NULL
);

CREATE TABLE "venus"."user_profiles" (
    "user_profile_id" bigint NOT NULL,
    "fk_user_id" bigint NOT NULL,
    "skin_type" venus.skin_type_enum,
    "skin_phototype" venus.skin_phototype_enum,
    "has_hyperpigmentation" boolean,
    "has_melasma" boolean,
    "has_rosacea" boolean,
    "has_eczema" boolean,
    "scalp_type" venus.scalp_type_enum,
    "skin_sensitivity" venus.sensitivity_level_enum,
    "acne_prone" boolean,
    "age_range" venus.age_range_enum,
    "gender" venus.gender_enum,
    "is_pregnant" boolean,
    "is_active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
    "hair_pattern" venus.hair_pattern_enum,
    "is_breastfeeding" boolean
);
COMMENT ON COLUMN "venus"."user_profiles"."hair_pattern" IS 'Classificação específica do padrão capilar: 1A–4C ou other. Nullable para perfis legados ainda sem granularidade.';

CREATE TABLE "venus"."user_tracking_events" (
    "tracking_event_id" bigint NOT NULL,
    "fk_user_id" bigint,
    "user_external_id" text,
    "anonymous_id" text,
    "platform" text NOT NULL,
    "event_name" text NOT NULL,
    "session_id" text,
    "screen_name" text,
    "app_version" text,
    "device_os" text,
    "device_id_hash" text,
    "occurred_at" timestamp with time zone DEFAULT now() NOT NULL,
    "metadata" jsonb DEFAULT '{}'::jsonb NOT NULL,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE "venus"."users" (
    "user_id" bigint NOT NULL,
    "firebase_uid" text NOT NULL,
    "name" text NOT NULL,
    "status" venus.user_status_enum DEFAULT 'active'::venus.user_status_enum NOT NULL,
    "last_login" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
    "email" text,
    "password_hash" text,
    "latitude" numeric(5,2),
    "longitude" numeric(5,2),
    "city" text,
    "state" text
);
COMMENT ON COLUMN "venus"."users"."latitude" IS 'Latitude aproximada, arredondada a duas casas para análise regional.';
COMMENT ON COLUMN "venus"."users"."longitude" IS 'Longitude aproximada, arredondada a duas casas para análise regional.';
COMMENT ON COLUMN "venus"."users"."city" IS 'Cidade retornada pelo geocoder do dispositivo.';
COMMENT ON COLUMN "venus"."users"."state" IS 'Estado retornado pelo geocoder do dispositivo; geralmente nome por extenso.';

CREATE TABLE "venus_audit"."audit_logs" (
    "audit_id" bigint NOT NULL,
    "schema_name" text NOT NULL,
    "table_name" text NOT NULL,
    "operation_type" text NOT NULL,
    "old_data" jsonb,
    "new_data" jsonb,
    "changed_by" text DEFAULT CURRENT_USER NOT NULL,
    "changed_at" timestamp with time zone DEFAULT now() NOT NULL,
    "application_name" text
);

CREATE TABLE "venus_rpa"."rpa_error" (
    "error_id" bigint NOT NULL,
    "batch_id" uuid NOT NULL,
    "source_table" text NOT NULL,
    "legacy_id" bigint,
    "error_type" text NOT NULL,
    "error_message" text NOT NULL,
    "payload" jsonb,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE "venus_rpa"."rpa_run" (
    "batch_id" uuid NOT NULL,
    "started_at" timestamp with time zone DEFAULT now() NOT NULL,
    "finished_at" timestamp with time zone,
    "status" text NOT NULL,
    "source_database" text,
    "source_products_query_hash" text,
    "source_users_query_hash" text,
    "records_read" integer DEFAULT 0 NOT NULL,
    "records_transformed" integer DEFAULT 0 NOT NULL,
    "records_loaded" integer DEFAULT 0 NOT NULL,
    "records_failed" integer DEFAULT 0 NOT NULL,
    "error_message" text
);

CREATE TABLE "venus_rpa"."rpa_stage_product" (
    "batch_id" uuid NOT NULL,
    "legacy_product_id" bigint NOT NULL,
    "product_name" text,
    "brand_name" text,
    "category_name" text,
    "ingredients_text" text,
    "normalized_product_name" text,
    "normalized_brand_name" text,
    "normalized_category_name" text,
    "validation_status" text NOT NULL,
    "validation_message" text,
    "loaded_product_id" bigint
);

CREATE TABLE "venus_rpa"."rpa_stage_user" (
    "batch_id" uuid NOT NULL,
    "legacy_user_id" bigint NOT NULL,
    "full_name" text,
    "email" text,
    "status_text" text,
    "normalized_name" text,
    "normalized_email" text,
    "status_normalized" text,
    "validation_status" text NOT NULL,
    "validation_message" text,
    "loaded_user_id" bigint
);

CREATE TABLE "venus_optimization"."readme" (
    "item" text NOT NULL,
    "description" text NOT NULL
);

ALTER TABLE "venus"."admin_users" ADD CONSTRAINT "admin_users_pkey" PRIMARY KEY (admin_user_id);
ALTER TABLE "venus"."admin_users" ADD CONSTRAINT "admin_users_email_key" UNIQUE (email);
CREATE UNIQUE INDEX admin_users_email_key ON venus.admin_users USING btree (email);

ALTER TABLE "venus"."allergies" ADD CONSTRAINT "allergies_pkey" PRIMARY KEY (allergy_id);
ALTER TABLE "venus"."allergies" ADD CONSTRAINT "allergies_allergy_name_key" UNIQUE (allergy_name);
CREATE UNIQUE INDEX allergies_allergy_name_key ON venus.allergies USING btree (allergy_name);

ALTER TABLE "venus"."allergy_ingredients" ADD CONSTRAINT "allergy_ingredients_fk_allergy_id_fkey" FOREIGN KEY ("fk_allergy_id") REFERENCES "venus"."allergies" ("allergy_id") ON DELETE CASCADE;
ALTER TABLE "venus"."allergy_ingredients" ADD CONSTRAINT "allergy_ingredients_fk_ingredient_id_fkey" FOREIGN KEY ("fk_ingredient_id") REFERENCES "venus"."ingredients" ("ingredient_id") ON DELETE CASCADE;
ALTER TABLE "venus"."allergy_ingredients" ADD CONSTRAINT "allergy_ingredients_pkey" PRIMARY KEY (allergy_ingredient_id);
ALTER TABLE "venus"."allergy_ingredients" ADD CONSTRAINT "allergy_ingredients_fk_allergy_id_fk_ingredient_id_key" UNIQUE (fk_allergy_id, fk_ingredient_id);
CREATE UNIQUE INDEX allergy_ingredients_fk_allergy_id_fk_ingredient_id_key ON venus.allergy_ingredients USING btree (fk_allergy_id, fk_ingredient_id);

ALTER TABLE "venus"."analysis_results" ADD CONSTRAINT "ck_analysis_results_confidence_score_range" CHECK (confidence_score >= 1 AND confidence_score <= 100);
ALTER TABLE "venus"."analysis_results" ADD CONSTRAINT "analysis_results_fk_product_version_id_fkey" FOREIGN KEY ("fk_product_version_id") REFERENCES "venus"."product_versions" ("product_version_id") ON DELETE CASCADE;
ALTER TABLE "venus"."analysis_results" ADD CONSTRAINT "analysis_results_fk_scoring_model_id_fkey" FOREIGN KEY ("fk_scoring_model_id") REFERENCES "venus"."scoring_models" ("scoring_model_id") ON DELETE RESTRICT;
ALTER TABLE "venus"."analysis_results" ADD CONSTRAINT "analysis_results_fk_user_id_fkey" FOREIGN KEY ("fk_user_id") REFERENCES "venus"."users" ("user_id") ON DELETE CASCADE;
ALTER TABLE "venus"."analysis_results" ADD CONSTRAINT "analysis_results_pkey" PRIMARY KEY (analysis_result_id);

ALTER TABLE "venus"."brand_claim_evidence" ADD CONSTRAINT "brand_claim_evidence_claim_type_check" CHECK (claim_type = ANY (ARRAY['vegan'::text, 'cruelty_free'::text, 'brazilian'::text]));
ALTER TABLE "venus"."brand_claim_evidence" ADD CONSTRAINT "brand_claim_evidence_evidence_level_check" CHECK (evidence_level = ANY (ARRAY['high'::text, 'medium'::text, 'low'::text]));
ALTER TABLE "venus"."brand_claim_evidence" ADD CONSTRAINT "brand_claim_evidence_note_nonblank" CHECK (btrim(evidence_note) <> ''::text);
ALTER TABLE "venus"."brand_claim_evidence" ADD CONSTRAINT "brand_claim_evidence_source_title_nonblank" CHECK (btrim(source_title) <> ''::text);
ALTER TABLE "venus"."brand_claim_evidence" ADD CONSTRAINT "brand_claim_evidence_source_url_nonblank" CHECK (btrim(source_url) <> ''::text);
ALTER TABLE "venus"."brand_claim_evidence" ADD CONSTRAINT "brand_claim_evidence_fk_brand_id_fkey" FOREIGN KEY ("fk_brand_id") REFERENCES "venus"."brands" ("brand_id") ON DELETE CASCADE;
ALTER TABLE "venus"."brand_claim_evidence" ADD CONSTRAINT "brand_claim_evidence_pkey" PRIMARY KEY (brand_claim_evidence_id);
ALTER TABLE "venus"."brand_claim_evidence" ADD CONSTRAINT "brand_claim_evidence_fk_brand_id_claim_type_source_url_key" UNIQUE (fk_brand_id, claim_type, source_url);
CREATE UNIQUE INDEX brand_claim_evidence_fk_brand_id_claim_type_source_url_key ON venus.brand_claim_evidence USING btree (fk_brand_id, claim_type, source_url);

ALTER TABLE "venus"."brands" ADD CONSTRAINT "brands_pkey" PRIMARY KEY (brand_id);
ALTER TABLE "venus"."brands" ADD CONSTRAINT "brands_name_country_key" UNIQUE (name, country);
CREATE UNIQUE INDEX brands_name_country_key ON venus.brands USING btree (name, country);
CREATE UNIQUE INDEX uq_brands_name_normalized ON venus.brands USING btree (lower(btrim(name)));

ALTER TABLE "venus"."claims" ADD CONSTRAINT "claims_pkey" PRIMARY KEY (claim_id);
ALTER TABLE "venus"."claims" ADD CONSTRAINT "claims_name_key" UNIQUE (name);
CREATE UNIQUE INDEX claims_name_key ON venus.claims USING btree (name);

ALTER TABLE "venus"."compatibility_rules" ADD CONSTRAINT "compatibility_rules_fk_ingredient_effect_id_fkey" FOREIGN KEY ("fk_ingredient_effect_id") REFERENCES "venus"."ingredient_effects" ("ingredient_effect_id") ON DELETE CASCADE;
ALTER TABLE "venus"."compatibility_rules" ADD CONSTRAINT "compatibility_rules_fk_scoring_model_id_fkey" FOREIGN KEY ("fk_scoring_model_id") REFERENCES "venus"."scoring_models" ("scoring_model_id") ON DELETE RESTRICT;
ALTER TABLE "venus"."compatibility_rules" ADD CONSTRAINT "compatibility_rules_pkey" PRIMARY KEY (compatibility_rule_id);
ALTER TABLE "venus"."compatibility_rules" ADD CONSTRAINT "compatibility_rules_fk_ingredient_effect_id_fk_scoring_mode_key" UNIQUE (fk_ingredient_effect_id, fk_scoring_model_id);
CREATE UNIQUE INDEX compatibility_rules_fk_ingredient_effect_id_fk_scoring_mode_key ON venus.compatibility_rules USING btree (fk_ingredient_effect_id, fk_scoring_model_id);

ALTER TABLE "venus"."data_catalog" ADD CONSTRAINT "data_catalog_access_level_check" CHECK (access_level = ANY (ARRAY['PUBLIC'::text, 'AUTHENTICATED'::text, 'OWNER'::text, 'ADMIN'::text, 'SYSTEM'::text, 'RESTRICTED'::text]));
ALTER TABLE "venus"."data_catalog" ADD CONSTRAINT "data_catalog_data_classification_check" CHECK (data_classification = ANY (ARRAY['PUBLIC'::text, 'INTERNAL'::text, 'CONFIDENTIAL'::text, 'RESTRICTED'::text]));
ALTER TABLE "venus"."data_catalog" ADD CONSTRAINT "data_catalog_object_type_check" CHECK (object_type = ANY (ARRAY['TABLE'::text, 'COLUMN'::text]));
ALTER TABLE "venus"."data_catalog" ADD CONSTRAINT "data_catalog_pkey" PRIMARY KEY (catalog_id);
ALTER TABLE "venus"."data_catalog" ADD CONSTRAINT "data_catalog_object_type_table_name_column_name_key" UNIQUE (object_type, table_name, column_name);
CREATE UNIQUE INDEX data_catalog_object_type_table_name_column_name_key ON venus.data_catalog USING btree (object_type, table_name, column_name);

ALTER TABLE "venus"."data_catalog_rules" ADD CONSTRAINT "data_catalog_rules_access_level_check" CHECK (access_level = ANY (ARRAY['PUBLIC'::text, 'AUTHENTICATED'::text, 'OWNER'::text, 'ADMIN'::text, 'SYSTEM'::text, 'RESTRICTED'::text]));
ALTER TABLE "venus"."data_catalog_rules" ADD CONSTRAINT "data_catalog_rules_data_classification_check" CHECK (data_classification = ANY (ARRAY['PUBLIC'::text, 'INTERNAL'::text, 'CONFIDENTIAL'::text, 'RESTRICTED'::text]));
ALTER TABLE "venus"."data_catalog_rules" ADD CONSTRAINT "data_catalog_rules_object_type_check" CHECK (object_type = ANY (ARRAY['TABLE'::text, 'COLUMN'::text]));
ALTER TABLE "venus"."data_catalog_rules" ADD CONSTRAINT "data_catalog_rules_pkey" PRIMARY KEY (rule_id);
ALTER TABLE "venus"."data_catalog_rules" ADD CONSTRAINT "data_catalog_rules_object_type_table_name_column_name_key" UNIQUE (object_type, table_name, column_name);
CREATE UNIQUE INDEX data_catalog_rules_object_type_table_name_column_name_key ON venus.data_catalog_rules USING btree (object_type, table_name, column_name);

ALTER TABLE "venus"."favorites" ADD CONSTRAINT "favorites_fk_product_id_fkey" FOREIGN KEY ("fk_product_id") REFERENCES "venus"."products" ("product_id") ON DELETE CASCADE;
ALTER TABLE "venus"."favorites" ADD CONSTRAINT "favorites_fk_user_id_fkey" FOREIGN KEY ("fk_user_id") REFERENCES "venus"."users" ("user_id") ON DELETE CASCADE;
ALTER TABLE "venus"."favorites" ADD CONSTRAINT "favorites_pkey" PRIMARY KEY (favorite_id);
ALTER TABLE "venus"."favorites" ADD CONSTRAINT "favorites_fk_user_id_fk_product_id_key" UNIQUE (fk_user_id, fk_product_id);
CREATE UNIQUE INDEX favorites_fk_user_id_fk_product_id_key ON venus.favorites USING btree (fk_user_id, fk_product_id);

ALTER TABLE "venus"."google_oauth_tokens" ADD CONSTRAINT "google_oauth_tokens_fk_user_id_fkey" FOREIGN KEY ("fk_user_id") REFERENCES "venus"."users" ("user_id") ON DELETE CASCADE;
ALTER TABLE "venus"."google_oauth_tokens" ADD CONSTRAINT "google_oauth_tokens_pkey" PRIMARY KEY (google_oauth_token_id);
ALTER TABLE "venus"."google_oauth_tokens" ADD CONSTRAINT "google_oauth_tokens_fk_user_id_key" UNIQUE (fk_user_id);
CREATE UNIQUE INDEX google_oauth_tokens_fk_user_id_key ON venus.google_oauth_tokens USING btree (fk_user_id);

ALTER TABLE "venus"."ingredient_aliases" ADD CONSTRAINT "ingredient_aliases_fk_ingredient_id_fkey" FOREIGN KEY ("fk_ingredient_id") REFERENCES "venus"."ingredients" ("ingredient_id") ON DELETE CASCADE;
ALTER TABLE "venus"."ingredient_aliases" ADD CONSTRAINT "ingredient_aliases_pkey" PRIMARY KEY (ingredient_alias_id);
ALTER TABLE "venus"."ingredient_aliases" ADD CONSTRAINT "ingredient_aliases_fk_ingredient_id_alias_name_alias_langua_key" UNIQUE (fk_ingredient_id, alias_name, alias_language);
CREATE UNIQUE INDEX ingredient_aliases_fk_ingredient_id_alias_name_alias_langua_key ON venus.ingredient_aliases USING btree (fk_ingredient_id, alias_name, alias_language);

ALTER TABLE "venus"."ingredient_categories" ADD CONSTRAINT "ingredient_categories_parent_ingredient_category_id_fkey" FOREIGN KEY ("parent_ingredient_category_id") REFERENCES "venus"."ingredient_categories" ("ingredient_category_id") ON DELETE SET NULL;
ALTER TABLE "venus"."ingredient_categories" ADD CONSTRAINT "ingredient_categories_pkey" PRIMARY KEY (ingredient_category_id);
ALTER TABLE "venus"."ingredient_categories" ADD CONSTRAINT "ingredient_categories_name_key" UNIQUE (name);
CREATE UNIQUE INDEX ingredient_categories_name_key ON venus.ingredient_categories USING btree (name);

ALTER TABLE "venus"."ingredient_category_assignments" ADD CONSTRAINT "ingredient_category_assignments_assignment_role_check" CHECK (assignment_role = 'secondary'::text);
ALTER TABLE "venus"."ingredient_category_assignments" ADD CONSTRAINT "ingredient_category_assignments_fk_ingredient_category_id_fkey" FOREIGN KEY ("fk_ingredient_category_id") REFERENCES "venus"."ingredient_categories" ("ingredient_category_id") ON DELETE RESTRICT;
ALTER TABLE "venus"."ingredient_category_assignments" ADD CONSTRAINT "ingredient_category_assignments_fk_ingredient_id_fkey" FOREIGN KEY ("fk_ingredient_id") REFERENCES "venus"."ingredients" ("ingredient_id") ON DELETE CASCADE;
ALTER TABLE "venus"."ingredient_category_assignments" ADD CONSTRAINT "ingredient_category_assignments_pkey" PRIMARY KEY (ingredient_category_assignment_id);
ALTER TABLE "venus"."ingredient_category_assignments" ADD CONSTRAINT "ingredient_category_assignmen_fk_ingredient_id_fk_ingredien_key" UNIQUE (fk_ingredient_id, fk_ingredient_category_id);
CREATE UNIQUE INDEX ingredient_category_assignmen_fk_ingredient_id_fk_ingredien_key ON venus.ingredient_category_assignments USING btree (fk_ingredient_id, fk_ingredient_category_id);

ALTER TABLE "venus"."ingredient_effect_validation_audit" ADD CONSTRAINT "ingredient_effect_validation_audit_fk_ingredient_id_fkey" FOREIGN KEY ("fk_ingredient_id") REFERENCES "venus"."ingredients" ("ingredient_id") ON DELETE CASCADE;
ALTER TABLE "venus"."ingredient_effect_validation_audit" ADD CONSTRAINT "ingredient_effect_validation_audit_pkey" PRIMARY KEY (audit_id);

ALTER TABLE "venus"."ingredient_effects" ADD CONSTRAINT "ingredient_effects_fk_ingredient_id_fkey" FOREIGN KEY ("fk_ingredient_id") REFERENCES "venus"."ingredients" ("ingredient_id") ON DELETE CASCADE;
ALTER TABLE "venus"."ingredient_effects" ADD CONSTRAINT "ingredient_effects_fk_profile_tag_id_fkey" FOREIGN KEY ("fk_profile_tag_id") REFERENCES "venus"."profile_tags" ("profile_tag_id") ON DELETE CASCADE;
ALTER TABLE "venus"."ingredient_effects" ADD CONSTRAINT "ingredient_effects_pkey" PRIMARY KEY (ingredient_effect_id);
ALTER TABLE "venus"."ingredient_effects" ADD CONSTRAINT "ingredient_effects_fk_ingredient_id_fk_profile_tag_id_effec_key" UNIQUE (fk_ingredient_id, fk_profile_tag_id, effect_category, effect_name);
CREATE UNIQUE INDEX ingredient_effects_fk_ingredient_id_fk_profile_tag_id_effec_key ON venus.ingredient_effects USING btree (fk_ingredient_id, fk_profile_tag_id, effect_category, effect_name);

ALTER TABLE "venus"."ingredient_evidence_queue" ADD CONSTRAINT "ingredient_evidence_queue_priority_check" CHECK (priority >= 1 AND priority <= 100);
ALTER TABLE "venus"."ingredient_evidence_queue" ADD CONSTRAINT "ingredient_evidence_queue_queue_status_check" CHECK (queue_status = ANY (ARRAY['queued'::text, 'in_progress'::text, 'completed'::text, 'blocked'::text]));
ALTER TABLE "venus"."ingredient_evidence_queue" ADD CONSTRAINT "ingredient_evidence_queue_fk_ingredient_id_fkey" FOREIGN KEY ("fk_ingredient_id") REFERENCES "venus"."ingredients" ("ingredient_id") ON DELETE CASCADE;
ALTER TABLE "venus"."ingredient_evidence_queue" ADD CONSTRAINT "ingredient_evidence_queue_pkey" PRIMARY KEY (ingredient_evidence_queue_id);
ALTER TABLE "venus"."ingredient_evidence_queue" ADD CONSTRAINT "ingredient_evidence_queue_fk_ingredient_id_key" UNIQUE (fk_ingredient_id);
CREATE UNIQUE INDEX ingredient_evidence_queue_fk_ingredient_id_key ON venus.ingredient_evidence_queue USING btree (fk_ingredient_id);

ALTER TABLE "venus"."ingredient_properties" ADD CONSTRAINT "ingredient_properties_fk_ingredient_id_fkey" FOREIGN KEY ("fk_ingredient_id") REFERENCES "venus"."ingredients" ("ingredient_id") ON DELETE CASCADE;
ALTER TABLE "venus"."ingredient_properties" ADD CONSTRAINT "ingredient_properties_pkey" PRIMARY KEY (ingredient_property_id);
ALTER TABLE "venus"."ingredient_properties" ADD CONSTRAINT "ingredient_properties_fk_ingredient_id_property_name_unit_key" UNIQUE (fk_ingredient_id, property_name, unit);
CREATE UNIQUE INDEX ingredient_properties_fk_ingredient_id_property_name_unit_key ON venus.ingredient_properties USING btree (fk_ingredient_id, property_name, unit);

ALTER TABLE "venus"."ingredient_regulations" ADD CONSTRAINT "ingredient_regulations_fk_ingredient_id_fkey" FOREIGN KEY ("fk_ingredient_id") REFERENCES "venus"."ingredients" ("ingredient_id") ON DELETE CASCADE;
ALTER TABLE "venus"."ingredient_regulations" ADD CONSTRAINT "ingredient_regulations_fk_regulation_id_fkey" FOREIGN KEY ("fk_regulation_id") REFERENCES "venus"."regulations" ("regulation_id") ON DELETE CASCADE;
ALTER TABLE "venus"."ingredient_regulations" ADD CONSTRAINT "ingredient_regulations_pkey" PRIMARY KEY (ingredient_regulation_id);
ALTER TABLE "venus"."ingredient_regulations" ADD CONSTRAINT "ingredient_regulations_fk_ingredient_id_fk_regulation_id_key" UNIQUE (fk_ingredient_id, fk_regulation_id);
CREATE UNIQUE INDEX ingredient_regulations_fk_ingredient_id_fk_regulation_id_key ON venus.ingredient_regulations USING btree (fk_ingredient_id, fk_regulation_id);

ALTER TABLE "venus"."ingredient_resolution_keys" ADD CONSTRAINT "ingredient_resolution_keys_fk_ingredient_id_fkey" FOREIGN KEY ("fk_ingredient_id") REFERENCES "venus"."ingredients" ("ingredient_id") ON DELETE CASCADE;
ALTER TABLE "venus"."ingredient_resolution_keys" ADD CONSTRAINT "ingredient_resolution_keys_pkey" PRIMARY KEY (normalized_key, fk_ingredient_id);

ALTER TABLE "venus"."ingredient_risk_assessments" ADD CONSTRAINT "ck_ingredient_risk_assessment_source" CHECK (assessment_status <> 'approved'::text OR btrim(source_reference) <> ''::text);
ALTER TABLE "venus"."ingredient_risk_assessments" ADD CONSTRAINT "ingredient_risk_assessments_assessment_status_check" CHECK (assessment_status = ANY (ARRAY['pending'::text, 'approved'::text, 'rejected'::text]));
ALTER TABLE "venus"."ingredient_risk_assessments" ADD CONSTRAINT "ingredient_risk_assessments_dimension_check" CHECK (dimension = ANY (ARRAY['irritation_risk_level'::text, 'comedogenicity_score'::text, 'biodegradability_level'::text, 'environmental_risk_level'::text]));
ALTER TABLE "venus"."ingredient_risk_assessments" ADD CONSTRAINT "ingredient_risk_assessments_score_check" CHECK (score >= 0 AND score <= 10);
ALTER TABLE "venus"."ingredient_risk_assessments" ADD CONSTRAINT "ingredient_risk_assessments_fk_ingredient_id_fkey" FOREIGN KEY ("fk_ingredient_id") REFERENCES "venus"."ingredients" ("ingredient_id") ON DELETE CASCADE;
ALTER TABLE "venus"."ingredient_risk_assessments" ADD CONSTRAINT "ingredient_risk_assessments_pkey" PRIMARY KEY (ingredient_risk_assessment_id);
ALTER TABLE "venus"."ingredient_risk_assessments" ADD CONSTRAINT "ingredient_risk_assessments_fk_ingredient_id_dimension_asse_key" UNIQUE (fk_ingredient_id, dimension, assessment_version);
CREATE UNIQUE INDEX ingredient_risk_assessments_fk_ingredient_id_dimension_asse_key ON venus.ingredient_risk_assessments USING btree (fk_ingredient_id, dimension, assessment_version);

ALTER TABLE "venus"."ingredient_risk_methodologies" ADD CONSTRAINT "ingredient_risk_methodologies_status_check" CHECK (status = ANY (ARRAY['draft'::text, 'active'::text, 'retired'::text]));
ALTER TABLE "venus"."ingredient_risk_methodologies" ADD CONSTRAINT "ingredient_risk_methodologies_pkey" PRIMARY KEY (methodology_version);

ALTER TABLE "venus"."ingredient_risk_methodology_dimensions" ADD CONSTRAINT "ingredient_risk_methodology_dimensions_dimension_check" CHECK (dimension = ANY (ARRAY['irritation_risk_level'::text, 'comedogenicity_score'::text, 'biodegradability_level'::text, 'environmental_risk_level'::text]));
ALTER TABLE "venus"."ingredient_risk_methodology_dimensions" ADD CONSTRAINT "ingredient_risk_methodology_dimensions_methodology_version_fkey" FOREIGN KEY ("methodology_version") REFERENCES "venus"."ingredient_risk_methodologies" ("methodology_version") ON DELETE RESTRICT;
ALTER TABLE "venus"."ingredient_risk_methodology_dimensions" ADD CONSTRAINT "ingredient_risk_methodology_dimensions_pkey" PRIMARY KEY (methodology_version, dimension);

ALTER TABLE "venus"."ingredients" ADD CONSTRAINT "ck_ingredients_scientific_confidence_range" CHECK (scientific_confidence >= 0 AND scientific_confidence <= 100);
ALTER TABLE "venus"."ingredients" ADD CONSTRAINT "ck_ingredients_scientific_confidence_state" CHECK (scientific_confidence_state = ANY (ARRAY['default'::text, 'derived'::text, 'curated'::text]));
ALTER TABLE "venus"."ingredients" ADD CONSTRAINT "ingredients_fk_ingredient_category_id_fkey" FOREIGN KEY ("fk_ingredient_category_id") REFERENCES "venus"."ingredient_categories" ("ingredient_category_id") ON DELETE RESTRICT;
ALTER TABLE "venus"."ingredients" ADD CONSTRAINT "ingredients_pkey" PRIMARY KEY (ingredient_id);
ALTER TABLE "venus"."ingredients" ADD CONSTRAINT "ingredients_inci_name_key" UNIQUE (inci_name);
CREATE UNIQUE INDEX ingredients_inci_name_key ON venus.ingredients USING btree (inci_name);

ALTER TABLE "venus"."media_assets" ADD CONSTRAINT "ck_media_assets_dono" CHECK (fk_user_id IS NOT NULL AND fk_product_version_id IS NULL AND fk_user_list_id IS NULL AND purpose = 'avatar'::text OR fk_user_id IS NULL AND fk_product_version_id IS NOT NULL AND fk_user_list_id IS NULL AND purpose = 'product_photo'::text OR fk_user_id IS NULL AND fk_product_version_id IS NULL AND fk_user_list_id IS NOT NULL AND purpose = 'list_cover'::text);
ALTER TABLE "venus"."media_assets" ADD CONSTRAINT "media_assets_bytes_check" CHECK (bytes IS NULL OR bytes >= 0);
ALTER TABLE "venus"."media_assets" ADD CONSTRAINT "media_assets_delivery_type_check" CHECK (delivery_type = ANY (ARRAY['upload'::text, 'authenticated'::text]));
ALTER TABLE "venus"."media_assets" ADD CONSTRAINT "media_assets_height_check" CHECK (height IS NULL OR height > 0);
ALTER TABLE "venus"."media_assets" ADD CONSTRAINT "media_assets_provider_check" CHECK (provider = 'cloudinary'::text);
ALTER TABLE "venus"."media_assets" ADD CONSTRAINT "media_assets_purpose_check" CHECK (purpose = ANY (ARRAY['avatar'::text, 'product_photo'::text, 'list_cover'::text]));
ALTER TABLE "venus"."media_assets" ADD CONSTRAINT "media_assets_resource_type_check" CHECK (resource_type = 'image'::text);
ALTER TABLE "venus"."media_assets" ADD CONSTRAINT "media_assets_sort_order_check" CHECK (sort_order >= 0);
ALTER TABLE "venus"."media_assets" ADD CONSTRAINT "media_assets_status_check" CHECK (status = ANY (ARRAY['pending'::text, 'active'::text, 'deleted'::text, 'failed'::text]));
ALTER TABLE "venus"."media_assets" ADD CONSTRAINT "media_assets_width_check" CHECK (width IS NULL OR width > 0);
ALTER TABLE "venus"."media_assets" ADD CONSTRAINT "media_assets_fk_product_version_id_fkey" FOREIGN KEY ("fk_product_version_id") REFERENCES "venus"."product_versions" ("product_version_id") ON DELETE CASCADE;
ALTER TABLE "venus"."media_assets" ADD CONSTRAINT "media_assets_fk_user_id_fkey" FOREIGN KEY ("fk_user_id") REFERENCES "venus"."users" ("user_id") ON DELETE CASCADE;
ALTER TABLE "venus"."media_assets" ADD CONSTRAINT "media_assets_fk_user_list_id_fkey" FOREIGN KEY ("fk_user_list_id") REFERENCES "venus"."user_lists" ("user_list_id") ON DELETE CASCADE;
ALTER TABLE "venus"."media_assets" ADD CONSTRAINT "media_assets_pkey" PRIMARY KEY (media_asset_id);
ALTER TABLE "venus"."media_assets" ADD CONSTRAINT "uq_media_assets_provider_public_id" UNIQUE (provider, public_id);
CREATE UNIQUE INDEX uq_media_assets_provider_public_id ON venus.media_assets USING btree (provider, public_id);
CREATE UNIQUE INDEX ux_media_user_avatar ON venus.media_assets USING btree (fk_user_id) WHERE ((purpose = 'avatar'::text) AND (status = ANY (ARRAY['pending'::text, 'active'::text])));
CREATE UNIQUE INDEX ux_media_user_list_cover ON venus.media_assets USING btree (fk_user_list_id) WHERE ((purpose = 'list_cover'::text) AND (status = ANY (ARRAY['pending'::text, 'active'::text])));

ALTER TABLE "venus"."packaging" ADD CONSTRAINT "packaging_fk_product_version_id_fkey" FOREIGN KEY ("fk_product_version_id") REFERENCES "venus"."product_versions" ("product_version_id") ON DELETE CASCADE;
ALTER TABLE "venus"."packaging" ADD CONSTRAINT "packaging_pkey" PRIMARY KEY (packaging_id);
ALTER TABLE "venus"."packaging" ADD CONSTRAINT "packaging_fk_product_version_id_key" UNIQUE (fk_product_version_id);
CREATE UNIQUE INDEX packaging_fk_product_version_id_key ON venus.packaging USING btree (fk_product_version_id);

ALTER TABLE "venus"."packaging_evaluation_policies" ADD CONSTRAINT "packaging_evaluation_policies_status_check" CHECK (status = ANY (ARRAY['active'::text, 'retired'::text]));
ALTER TABLE "venus"."packaging_evaluation_policies" ADD CONSTRAINT "packaging_evaluation_policies_pkey" PRIMARY KEY (policy_version);

ALTER TABLE "venus"."personalized_scores" ADD CONSTRAINT "personalized_scores_fk_analysis_result_id_fkey" FOREIGN KEY ("fk_analysis_result_id") REFERENCES "venus"."analysis_results" ("analysis_result_id") ON DELETE CASCADE;
ALTER TABLE "venus"."personalized_scores" ADD CONSTRAINT "personalized_scores_fk_product_version_id_fkey" FOREIGN KEY ("fk_product_version_id") REFERENCES "venus"."product_versions" ("product_version_id") ON DELETE CASCADE;
ALTER TABLE "venus"."personalized_scores" ADD CONSTRAINT "personalized_scores_fk_scoring_model_id_fkey" FOREIGN KEY ("fk_scoring_model_id") REFERENCES "venus"."scoring_models" ("scoring_model_id") ON DELETE RESTRICT;
ALTER TABLE "venus"."personalized_scores" ADD CONSTRAINT "personalized_scores_fk_user_id_fkey" FOREIGN KEY ("fk_user_id") REFERENCES "venus"."users" ("user_id") ON DELETE CASCADE;
ALTER TABLE "venus"."personalized_scores" ADD CONSTRAINT "personalized_scores_pkey" PRIMARY KEY (personalized_score_id);
ALTER TABLE "venus"."personalized_scores" ADD CONSTRAINT "personalized_scores_fk_user_id_fk_product_version_id_fk_sco_key" UNIQUE (fk_user_id, fk_product_version_id, fk_scoring_model_id);
CREATE UNIQUE INDEX personalized_scores_fk_user_id_fk_product_version_id_fk_sco_key ON venus.personalized_scores USING btree (fk_user_id, fk_product_version_id, fk_scoring_model_id);

ALTER TABLE "venus"."product_categories" ADD CONSTRAINT "product_categories_pkey" PRIMARY KEY (product_category_id);
ALTER TABLE "venus"."product_categories" ADD CONSTRAINT "product_categories_name_key" UNIQUE (name);
CREATE UNIQUE INDEX product_categories_name_key ON venus.product_categories USING btree (name);

ALTER TABLE "venus"."product_claims" ADD CONSTRAINT "product_claims_fk_claim_id_fkey" FOREIGN KEY ("fk_claim_id") REFERENCES "venus"."claims" ("claim_id") ON DELETE RESTRICT;
ALTER TABLE "venus"."product_claims" ADD CONSTRAINT "product_claims_fk_product_version_id_fkey" FOREIGN KEY ("fk_product_version_id") REFERENCES "venus"."product_versions" ("product_version_id") ON DELETE CASCADE;
ALTER TABLE "venus"."product_claims" ADD CONSTRAINT "product_claims_pkey" PRIMARY KEY (product_claim_id);
ALTER TABLE "venus"."product_claims" ADD CONSTRAINT "product_claims_fk_product_version_id_fk_claim_id_key" UNIQUE (fk_product_version_id, fk_claim_id);
CREATE UNIQUE INDEX product_claims_fk_product_version_id_fk_claim_id_key ON venus.product_claims USING btree (fk_product_version_id, fk_claim_id);

ALTER TABLE "venus"."product_composition_receipts" ADD CONSTRAINT "ck_composition_receipt_counts" CHECK ((resolved_count + unresolved_count) <= expected_count OR validation_status <> 'VALID'::text);
ALTER TABLE "venus"."product_composition_receipts" ADD CONSTRAINT "ck_composition_receipt_valid" CHECK (validation_status <> 'VALID'::text OR btrim(source_reference) <> ''::text AND btrim(raw_ingredients_text) <> ''::text AND expected_count > 0 AND expected_count = resolved_count AND unresolved_count = 0);
ALTER TABLE "venus"."product_composition_receipts" ADD CONSTRAINT "product_composition_receipts_expected_count_check" CHECK (expected_count >= 0);
ALTER TABLE "venus"."product_composition_receipts" ADD CONSTRAINT "product_composition_receipts_resolved_count_check" CHECK (resolved_count >= 0);
ALTER TABLE "venus"."product_composition_receipts" ADD CONSTRAINT "product_composition_receipts_unresolved_count_check" CHECK (unresolved_count >= 0);
ALTER TABLE "venus"."product_composition_receipts" ADD CONSTRAINT "product_composition_receipts_validation_status_check" CHECK (validation_status = ANY (ARRAY['VALID'::text, 'WARNING'::text, 'INVALID'::text, 'LEGACY_UNVERIFIED'::text]));
ALTER TABLE "venus"."product_composition_receipts" ADD CONSTRAINT "product_composition_receipts_fk_product_version_id_fkey" FOREIGN KEY ("fk_product_version_id") REFERENCES "venus"."product_versions" ("product_version_id") ON DELETE CASCADE;
ALTER TABLE "venus"."product_composition_receipts" ADD CONSTRAINT "product_composition_receipts_pkey" PRIMARY KEY (product_composition_receipt_id);
ALTER TABLE "venus"."product_composition_receipts" ADD CONSTRAINT "product_composition_receipts_fk_product_version_id_product__key" UNIQUE (fk_product_version_id, product_composition_receipt_id);
CREATE UNIQUE INDEX product_composition_receipts_fk_product_version_id_product__key ON venus.product_composition_receipts USING btree (fk_product_version_id, product_composition_receipt_id);
CREATE UNIQUE INDEX ux_product_composition_receipts_current ON venus.product_composition_receipts USING btree (fk_product_version_id) WHERE is_current;

ALTER TABLE "venus"."product_dimension_assessments" ADD CONSTRAINT "ck_product_dimension_assessment_source" CHECK (assessment_status <> 'approved'::text OR btrim(source_reference) <> ''::text);
ALTER TABLE "venus"."product_dimension_assessments" ADD CONSTRAINT "product_dimension_assessments_assessment_status_check" CHECK (assessment_status = ANY (ARRAY['pending'::text, 'approved'::text, 'rejected'::text]));
ALTER TABLE "venus"."product_dimension_assessments" ADD CONSTRAINT "product_dimension_assessments_dimension_check" CHECK (dimension = ANY (ARRAY['performance'::text, 'ethical'::text]));
ALTER TABLE "venus"."product_dimension_assessments" ADD CONSTRAINT "product_dimension_assessments_fk_product_version_id_fkey" FOREIGN KEY ("fk_product_version_id") REFERENCES "venus"."product_versions" ("product_version_id") ON DELETE CASCADE;
ALTER TABLE "venus"."product_dimension_assessments" ADD CONSTRAINT "product_dimension_assessments_pkey" PRIMARY KEY (product_dimension_assessment_id);
ALTER TABLE "venus"."product_dimension_assessments" ADD CONSTRAINT "product_dimension_assessments_fk_product_version_id_dimensi_key" UNIQUE (fk_product_version_id, dimension, assessment_version);
CREATE UNIQUE INDEX product_dimension_assessments_fk_product_version_id_dimensi_key ON venus.product_dimension_assessments USING btree (fk_product_version_id, dimension, assessment_version);

ALTER TABLE "venus"."product_ingredient_resolution_issues" ADD CONSTRAINT "product_ingredient_resolution_issues_issue_type_check" CHECK (issue_type = ANY (ARRAY['NOT_FOUND'::text, 'AMBIGUOUS'::text]));
ALTER TABLE "venus"."product_ingredient_resolution_issues" ADD CONSTRAINT "product_ingredient_resolution_issues_fk_product_version_id_fkey" FOREIGN KEY ("fk_product_version_id") REFERENCES "venus"."product_versions" ("product_version_id") ON DELETE CASCADE;
ALTER TABLE "venus"."product_ingredient_resolution_issues" ADD CONSTRAINT "product_ingredient_resolution_issues_pkey" PRIMARY KEY (product_ingredient_resolution_issue_id);
ALTER TABLE "venus"."product_ingredient_resolution_issues" ADD CONSTRAINT "product_ingredient_resolution_fk_product_version_id_token_p_key" UNIQUE (fk_product_version_id, token_position);
CREATE UNIQUE INDEX product_ingredient_resolution_fk_product_version_id_token_p_key ON venus.product_ingredient_resolution_issues USING btree (fk_product_version_id, token_position);

ALTER TABLE "venus"."product_ingredients" ADD CONSTRAINT "product_ingredients_fk_ingredient_id_fkey" FOREIGN KEY ("fk_ingredient_id") REFERENCES "venus"."ingredients" ("ingredient_id") ON DELETE RESTRICT;
ALTER TABLE "venus"."product_ingredients" ADD CONSTRAINT "product_ingredients_fk_product_version_id_fkey" FOREIGN KEY ("fk_product_version_id") REFERENCES "venus"."product_versions" ("product_version_id") ON DELETE CASCADE;
ALTER TABLE "venus"."product_ingredients" ADD CONSTRAINT "product_ingredients_pkey" PRIMARY KEY (product_ingredient_id);
ALTER TABLE "venus"."product_ingredients" ADD CONSTRAINT "product_ingredients_fk_product_version_id_fk_ingredient_id_key" UNIQUE (fk_product_version_id, fk_ingredient_id);
ALTER TABLE "venus"."product_ingredients" ADD CONSTRAINT "product_ingredients_fk_product_version_id_position_key" UNIQUE (fk_product_version_id, "position");
CREATE UNIQUE INDEX product_ingredients_fk_product_version_id_fk_ingredient_id_key ON venus.product_ingredients USING btree (fk_product_version_id, fk_ingredient_id);
CREATE UNIQUE INDEX product_ingredients_fk_product_version_id_position_key ON venus.product_ingredients USING btree (fk_product_version_id, "position");

ALTER TABLE "venus"."product_labels" ADD CONSTRAINT "product_labels_fk_product_version_id_fkey" FOREIGN KEY ("fk_product_version_id") REFERENCES "venus"."product_versions" ("product_version_id") ON DELETE CASCADE;
ALTER TABLE "venus"."product_labels" ADD CONSTRAINT "product_labels_pkey" PRIMARY KEY (product_label_id);
ALTER TABLE "venus"."product_labels" ADD CONSTRAINT "product_labels_fk_product_version_id_key" UNIQUE (fk_product_version_id);
CREATE UNIQUE INDEX product_labels_fk_product_version_id_key ON venus.product_labels USING btree (fk_product_version_id);

ALTER TABLE "venus"."product_score_history" ADD CONSTRAINT "product_score_history_pkey" PRIMARY KEY (product_score_history_id);

ALTER TABLE "venus"."product_scores" ADD CONSTRAINT "ck_product_scores_confidence_score_range" CHECK (confidence_score >= 1 AND confidence_score <= 100);
ALTER TABLE "venus"."product_scores" ADD CONSTRAINT "product_scores_fk_product_version_id_fkey" FOREIGN KEY ("fk_product_version_id") REFERENCES "venus"."product_versions" ("product_version_id") ON DELETE CASCADE;
ALTER TABLE "venus"."product_scores" ADD CONSTRAINT "product_scores_fk_scoring_model_id_fkey" FOREIGN KEY ("fk_scoring_model_id") REFERENCES "venus"."scoring_models" ("scoring_model_id") ON DELETE RESTRICT;
ALTER TABLE "venus"."product_scores" ADD CONSTRAINT "product_scores_pkey" PRIMARY KEY (product_score_id);
ALTER TABLE "venus"."product_scores" ADD CONSTRAINT "product_scores_fk_product_version_id_fk_scoring_model_id_key" UNIQUE (fk_product_version_id, fk_scoring_model_id);
CREATE UNIQUE INDEX product_scores_fk_product_version_id_fk_scoring_model_id_key ON venus.product_scores USING btree (fk_product_version_id, fk_scoring_model_id);

ALTER TABLE "venus"."product_versions" ADD CONSTRAINT "product_versions_fk_product_id_fkey" FOREIGN KEY ("fk_product_id") REFERENCES "venus"."products" ("product_id") ON DELETE CASCADE;
ALTER TABLE "venus"."product_versions" ADD CONSTRAINT "product_versions_pkey" PRIMARY KEY (product_version_id);
ALTER TABLE "venus"."product_versions" ADD CONSTRAINT "trg_enforce_product_version_score_readiness" TRIGGER DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE "venus"."product_versions" ADD CONSTRAINT "product_versions_fk_product_id_formula_signature_key" UNIQUE (fk_product_id, formula_signature);
CREATE UNIQUE INDEX product_versions_fk_product_id_formula_signature_key ON venus.product_versions USING btree (fk_product_id, formula_signature);
CREATE UNIQUE INDEX ux_product_versions_current ON venus.product_versions USING btree (fk_product_id) WHERE is_current;

ALTER TABLE "venus"."products" ADD CONSTRAINT "products_fk_brand_id_fkey" FOREIGN KEY ("fk_brand_id") REFERENCES "venus"."brands" ("brand_id") ON DELETE RESTRICT;
ALTER TABLE "venus"."products" ADD CONSTRAINT "products_fk_product_category_id_fkey" FOREIGN KEY ("fk_product_category_id") REFERENCES "venus"."product_categories" ("product_category_id") ON DELETE RESTRICT;
ALTER TABLE "venus"."products" ADD CONSTRAINT "products_pkey" PRIMARY KEY (product_id);
ALTER TABLE "venus"."products" ADD CONSTRAINT "products_slug_key" UNIQUE (slug);
CREATE UNIQUE INDEX products_slug_key ON venus.products USING btree (slug);

ALTER TABLE "venus"."profile_tags" ADD CONSTRAINT "profile_tags_pkey" PRIMARY KEY (profile_tag_id);
ALTER TABLE "venus"."profile_tags" ADD CONSTRAINT "profile_tags_name_key" UNIQUE (name);
ALTER TABLE "venus"."profile_tags" ADD CONSTRAINT "profile_tags_slug_key" UNIQUE (slug);
CREATE UNIQUE INDEX profile_tags_name_key ON venus.profile_tags USING btree (name);
CREATE UNIQUE INDEX profile_tags_slug_key ON venus.profile_tags USING btree (slug);

ALTER TABLE "venus"."recommendations" ADD CONSTRAINT "ck_recommendations_confidence_score_range" CHECK (confidence_score >= 1 AND confidence_score <= 100);
ALTER TABLE "venus"."recommendations" ADD CONSTRAINT "recommendations_fk_analysis_result_id_fkey" FOREIGN KEY ("fk_analysis_result_id") REFERENCES "venus"."analysis_results" ("analysis_result_id") ON DELETE CASCADE;
ALTER TABLE "venus"."recommendations" ADD CONSTRAINT "recommendations_fk_product_version_id_fkey" FOREIGN KEY ("fk_product_version_id") REFERENCES "venus"."product_versions" ("product_version_id") ON DELETE CASCADE;
ALTER TABLE "venus"."recommendations" ADD CONSTRAINT "recommendations_fk_profile_tag_id_fkey" FOREIGN KEY ("fk_profile_tag_id") REFERENCES "venus"."profile_tags" ("profile_tag_id") ON DELETE CASCADE;
ALTER TABLE "venus"."recommendations" ADD CONSTRAINT "recommendations_fk_user_id_fkey" FOREIGN KEY ("fk_user_id") REFERENCES "venus"."users" ("user_id") ON DELETE CASCADE;
ALTER TABLE "venus"."recommendations" ADD CONSTRAINT "recommendations_pkey" PRIMARY KEY (recommendation_id);
ALTER TABLE "venus"."recommendations" ADD CONSTRAINT "recommendations_fk_user_id_fk_profile_tag_id_fk_product_ver_key" UNIQUE (fk_user_id, fk_profile_tag_id, fk_product_version_id, fk_analysis_result_id);
CREATE UNIQUE INDEX recommendations_fk_user_id_fk_profile_tag_id_fk_product_ver_key ON venus.recommendations USING btree (fk_user_id, fk_profile_tag_id, fk_product_version_id, fk_analysis_result_id);

ALTER TABLE "venus"."regulations" ADD CONSTRAINT "regulations_pkey" PRIMARY KEY (regulation_id);
ALTER TABLE "venus"."regulations" ADD CONSTRAINT "regulations_title_country_agency_key" UNIQUE (title, country, agency);
CREATE UNIQUE INDEX regulations_title_country_agency_key ON venus.regulations USING btree (title, country, agency);

ALTER TABLE "venus"."reports" ADD CONSTRAINT "reports_fk_admin_user_id_fkey" FOREIGN KEY ("fk_admin_user_id") REFERENCES "venus"."admin_users" ("admin_user_id") ON DELETE SET NULL;
ALTER TABLE "venus"."reports" ADD CONSTRAINT "reports_fk_user_id_fkey" FOREIGN KEY ("fk_user_id") REFERENCES "venus"."users" ("user_id") ON DELETE CASCADE;
ALTER TABLE "venus"."reports" ADD CONSTRAINT "reports_pkey" PRIMARY KEY (report_id);

ALTER TABLE "venus"."review_votes" ADD CONSTRAINT "review_votes_fk_review_id_fkey" FOREIGN KEY ("fk_review_id") REFERENCES "venus"."reviews" ("review_id") ON DELETE CASCADE;
ALTER TABLE "venus"."review_votes" ADD CONSTRAINT "review_votes_fk_user_id_fkey" FOREIGN KEY ("fk_user_id") REFERENCES "venus"."users" ("user_id") ON DELETE CASCADE;
ALTER TABLE "venus"."review_votes" ADD CONSTRAINT "review_votes_pkey" PRIMARY KEY (review_vote_id);
ALTER TABLE "venus"."review_votes" ADD CONSTRAINT "review_votes_fk_review_id_fk_user_id_key" UNIQUE (fk_review_id, fk_user_id);
CREATE UNIQUE INDEX review_votes_fk_review_id_fk_user_id_key ON venus.review_votes USING btree (fk_review_id, fk_user_id);

ALTER TABLE "venus"."reviews" ADD CONSTRAINT "reviews_fk_product_version_id_fkey" FOREIGN KEY ("fk_product_version_id") REFERENCES "venus"."product_versions" ("product_version_id") ON DELETE CASCADE;
ALTER TABLE "venus"."reviews" ADD CONSTRAINT "reviews_fk_user_id_fkey" FOREIGN KEY ("fk_user_id") REFERENCES "venus"."users" ("user_id") ON DELETE CASCADE;
ALTER TABLE "venus"."reviews" ADD CONSTRAINT "reviews_pkey" PRIMARY KEY (review_id);
ALTER TABLE "venus"."reviews" ADD CONSTRAINT "reviews_fk_user_id_fk_product_version_id_key" UNIQUE (fk_user_id, fk_product_version_id);
CREATE UNIQUE INDEX reviews_fk_user_id_fk_product_version_id_key ON venus.reviews USING btree (fk_user_id, fk_product_version_id);

ALTER TABLE "venus"."rule_evaluations" ADD CONSTRAINT "rule_evaluations_fk_analysis_result_id_fkey" FOREIGN KEY ("fk_analysis_result_id") REFERENCES "venus"."analysis_results" ("analysis_result_id") ON DELETE CASCADE;
ALTER TABLE "venus"."rule_evaluations" ADD CONSTRAINT "rule_evaluations_fk_compatibility_rule_id_fkey" FOREIGN KEY ("fk_compatibility_rule_id") REFERENCES "venus"."compatibility_rules" ("compatibility_rule_id") ON DELETE CASCADE;
ALTER TABLE "venus"."rule_evaluations" ADD CONSTRAINT "rule_evaluations_fk_ingredient_id_fkey" FOREIGN KEY ("fk_ingredient_id") REFERENCES "venus"."ingredients" ("ingredient_id") ON DELETE RESTRICT;
ALTER TABLE "venus"."rule_evaluations" ADD CONSTRAINT "rule_evaluations_fk_profile_tag_id_fkey" FOREIGN KEY ("fk_profile_tag_id") REFERENCES "venus"."profile_tags" ("profile_tag_id") ON DELETE CASCADE;
ALTER TABLE "venus"."rule_evaluations" ADD CONSTRAINT "rule_evaluations_pkey" PRIMARY KEY (rule_evaluation_id);
ALTER TABLE "venus"."rule_evaluations" ADD CONSTRAINT "rule_evaluations_fk_analysis_result_id_fk_compatibility_rul_key" UNIQUE (fk_analysis_result_id, fk_compatibility_rule_id, fk_ingredient_id, fk_profile_tag_id);
CREATE UNIQUE INDEX rule_evaluations_fk_analysis_result_id_fk_compatibility_rul_key ON venus.rule_evaluations USING btree (fk_analysis_result_id, fk_compatibility_rule_id, fk_ingredient_id, fk_profile_tag_id);

ALTER TABLE "venus"."score_categories" ADD CONSTRAINT "score_categories_pkey" PRIMARY KEY (score_category_id);
ALTER TABLE "venus"."score_categories" ADD CONSTRAINT "score_categories_name_key" UNIQUE (name);
CREATE UNIQUE INDEX score_categories_name_key ON venus.score_categories USING btree (name);

ALTER TABLE "venus"."scoring_model_categories" ADD CONSTRAINT "scoring_model_categories_fk_score_category_id_fkey" FOREIGN KEY ("fk_score_category_id") REFERENCES "venus"."score_categories" ("score_category_id") ON DELETE RESTRICT;
ALTER TABLE "venus"."scoring_model_categories" ADD CONSTRAINT "scoring_model_categories_fk_scoring_model_id_fkey" FOREIGN KEY ("fk_scoring_model_id") REFERENCES "venus"."scoring_models" ("scoring_model_id") ON DELETE CASCADE;
ALTER TABLE "venus"."scoring_model_categories" ADD CONSTRAINT "scoring_model_categories_pkey" PRIMARY KEY (scoring_model_category_id);
ALTER TABLE "venus"."scoring_model_categories" ADD CONSTRAINT "scoring_model_categories_fk_scoring_model_id_fk_score_categ_key" UNIQUE (fk_scoring_model_id, fk_score_category_id);
CREATE UNIQUE INDEX scoring_model_categories_fk_scoring_model_id_fk_score_categ_key ON venus.scoring_model_categories USING btree (fk_scoring_model_id, fk_score_category_id);

ALTER TABLE "venus"."scoring_models" ADD CONSTRAINT "scoring_models_pkey" PRIMARY KEY (scoring_model_id);
ALTER TABLE "venus"."scoring_models" ADD CONSTRAINT "scoring_models_name_version_key" UNIQUE (name, version);
CREATE UNIQUE INDEX scoring_models_name_version_key ON venus.scoring_models USING btree (name, version);
CREATE UNIQUE INDEX ux_scoring_models_single_active ON venus.scoring_models USING btree (is_active) WHERE is_active;

ALTER TABLE "venus"."user_access_events" ADD CONSTRAINT "user_access_events_fk_user_id_fkey" FOREIGN KEY ("fk_user_id") REFERENCES "venus"."users" ("user_id") ON DELETE CASCADE;
ALTER TABLE "venus"."user_access_events" ADD CONSTRAINT "user_access_events_pkey" PRIMARY KEY (access_event_id);

ALTER TABLE "venus"."user_allergies" ADD CONSTRAINT "user_allergies_fk_allergy_id_fkey" FOREIGN KEY ("fk_allergy_id") REFERENCES "venus"."allergies" ("allergy_id") ON DELETE CASCADE;
ALTER TABLE "venus"."user_allergies" ADD CONSTRAINT "user_allergies_fk_user_id_fkey" FOREIGN KEY ("fk_user_id") REFERENCES "venus"."users" ("user_id") ON DELETE CASCADE;
ALTER TABLE "venus"."user_allergies" ADD CONSTRAINT "user_allergies_pkey" PRIMARY KEY (user_allergy_id);
ALTER TABLE "venus"."user_allergies" ADD CONSTRAINT "user_allergies_fk_user_id_fk_allergy_id_key" UNIQUE (fk_user_id, fk_allergy_id);
CREATE UNIQUE INDEX user_allergies_fk_user_id_fk_allergy_id_key ON venus.user_allergies USING btree (fk_user_id, fk_allergy_id);

ALTER TABLE "venus"."user_list_items" ADD CONSTRAINT "user_list_items_fk_product_id_fkey" FOREIGN KEY ("fk_product_id") REFERENCES "venus"."products" ("product_id") ON DELETE CASCADE;
ALTER TABLE "venus"."user_list_items" ADD CONSTRAINT "user_list_items_fk_user_list_id_fkey" FOREIGN KEY ("fk_user_list_id") REFERENCES "venus"."user_lists" ("user_list_id") ON DELETE CASCADE;
ALTER TABLE "venus"."user_list_items" ADD CONSTRAINT "user_list_items_pkey" PRIMARY KEY (user_list_item_id);
ALTER TABLE "venus"."user_list_items" ADD CONSTRAINT "user_list_items_fk_user_list_id_fk_product_id_key" UNIQUE (fk_user_list_id, fk_product_id);
ALTER TABLE "venus"."user_list_items" ADD CONSTRAINT "user_list_items_fk_user_list_id_position_order_key" UNIQUE (fk_user_list_id, position_order);
CREATE UNIQUE INDEX user_list_items_fk_user_list_id_fk_product_id_key ON venus.user_list_items USING btree (fk_user_list_id, fk_product_id);
CREATE UNIQUE INDEX user_list_items_fk_user_list_id_position_order_key ON venus.user_list_items USING btree (fk_user_list_id, position_order);

ALTER TABLE "venus"."user_lists" ADD CONSTRAINT "ck_user_lists_cover_key" CHECK (cover_key IS NULL OR (cover_key = ANY (ARRAY['favoritos'::text, 'escaneados'::text, 'skincare'::text])));
ALTER TABLE "venus"."user_lists" ADD CONSTRAINT "ck_user_lists_description_length" CHECK (description IS NULL OR char_length(description) <= 500);
ALTER TABLE "venus"."user_lists" ADD CONSTRAINT "user_lists_fk_user_id_fkey" FOREIGN KEY ("fk_user_id") REFERENCES "venus"."users" ("user_id") ON DELETE CASCADE;
ALTER TABLE "venus"."user_lists" ADD CONSTRAINT "user_lists_pkey" PRIMARY KEY (user_list_id);
ALTER TABLE "venus"."user_lists" ADD CONSTRAINT "user_lists_fk_user_id_name_key" UNIQUE (fk_user_id, name);
CREATE UNIQUE INDEX user_lists_fk_user_id_name_key ON venus.user_lists USING btree (fk_user_id, name);

ALTER TABLE "venus"."user_preferences" ADD CONSTRAINT "user_preferences_fk_user_id_fkey" FOREIGN KEY ("fk_user_id") REFERENCES "venus"."users" ("user_id") ON DELETE CASCADE;
ALTER TABLE "venus"."user_preferences" ADD CONSTRAINT "user_preferences_pkey" PRIMARY KEY (user_preference_id);
ALTER TABLE "venus"."user_preferences" ADD CONSTRAINT "user_preferences_fk_user_id_key" UNIQUE (fk_user_id);
CREATE UNIQUE INDEX user_preferences_fk_user_id_key ON venus.user_preferences USING btree (fk_user_id);

ALTER TABLE "venus"."user_profile_tags" ADD CONSTRAINT "user_profile_tags_fk_profile_tag_id_fkey" FOREIGN KEY ("fk_profile_tag_id") REFERENCES "venus"."profile_tags" ("profile_tag_id") ON DELETE CASCADE;
ALTER TABLE "venus"."user_profile_tags" ADD CONSTRAINT "user_profile_tags_fk_user_id_fkey" FOREIGN KEY ("fk_user_id") REFERENCES "venus"."users" ("user_id") ON DELETE CASCADE;
ALTER TABLE "venus"."user_profile_tags" ADD CONSTRAINT "user_profile_tags_pkey" PRIMARY KEY (user_profile_tag_id);
ALTER TABLE "venus"."user_profile_tags" ADD CONSTRAINT "user_profile_tags_fk_user_id_fk_profile_tag_id_key" UNIQUE (fk_user_id, fk_profile_tag_id);
CREATE UNIQUE INDEX user_profile_tags_fk_user_id_fk_profile_tag_id_key ON venus.user_profile_tags USING btree (fk_user_id, fk_profile_tag_id);

ALTER TABLE "venus"."user_profiles" ADD CONSTRAINT "ck_user_profiles_adult_age_range" CHECK (age_range = ANY (ARRAY['age_13_17'::venus.age_range_enum, 'age_18_24'::venus.age_range_enum, 'age_25_34'::venus.age_range_enum, 'age_35_44'::venus.age_range_enum, 'age_45_54'::venus.age_range_enum, 'age_55_plus'::venus.age_range_enum]));
ALTER TABLE "venus"."user_profiles" ADD CONSTRAINT "user_profiles_fk_user_id_fkey" FOREIGN KEY ("fk_user_id") REFERENCES "venus"."users" ("user_id") ON DELETE CASCADE;
ALTER TABLE "venus"."user_profiles" ADD CONSTRAINT "user_profiles_pkey" PRIMARY KEY (user_profile_id);
ALTER TABLE "venus"."user_profiles" ADD CONSTRAINT "user_profiles_fk_user_id_key" UNIQUE (fk_user_id);
CREATE UNIQUE INDEX user_profiles_fk_user_id_key ON venus.user_profiles USING btree (fk_user_id);

ALTER TABLE "venus"."user_tracking_events" ADD CONSTRAINT "ck_user_tracking_events_name" CHECK (event_name = btrim(event_name) AND length(event_name) >= 1 AND length(event_name) <= 120);
ALTER TABLE "venus"."user_tracking_events" ADD CONSTRAINT "ck_user_tracking_events_platform" CHECK (platform = ANY (ARRAY['mobile'::text, 'web'::text]));
ALTER TABLE "venus"."user_tracking_events" ADD CONSTRAINT "user_tracking_events_fk_user_id_fkey" FOREIGN KEY ("fk_user_id") REFERENCES "venus"."users" ("user_id") ON DELETE SET NULL;
ALTER TABLE "venus"."user_tracking_events" ADD CONSTRAINT "user_tracking_events_pkey" PRIMARY KEY (tracking_event_id);

ALTER TABLE "venus"."users" ADD CONSTRAINT "ck_users_latitude_range" CHECK (latitude >= '-90'::integer::numeric AND latitude <= 90::numeric);
ALTER TABLE "venus"."users" ADD CONSTRAINT "ck_users_longitude_range" CHECK (longitude >= '-180'::integer::numeric AND longitude <= 180::numeric);
ALTER TABLE "venus"."users" ADD CONSTRAINT "users_pkey" PRIMARY KEY (user_id);
ALTER TABLE "venus"."users" ADD CONSTRAINT "users_firebase_uid_key" UNIQUE (firebase_uid);
CREATE UNIQUE INDEX users_firebase_uid_key ON venus.users USING btree (firebase_uid);
CREATE UNIQUE INDEX ux_users_email ON venus.users USING btree (lower(email)) WHERE (email IS NOT NULL);

ALTER TABLE "venus_audit"."audit_logs" ADD CONSTRAINT "audit_logs_pkey" PRIMARY KEY (audit_id);

ALTER TABLE "venus_rpa"."rpa_error" ADD CONSTRAINT "rpa_error_batch_id_fkey" FOREIGN KEY ("batch_id") REFERENCES "venus_rpa"."rpa_run" ("batch_id") ON DELETE CASCADE;
ALTER TABLE "venus_rpa"."rpa_error" ADD CONSTRAINT "rpa_error_pkey" PRIMARY KEY (error_id);

ALTER TABLE "venus_rpa"."rpa_run" ADD CONSTRAINT "rpa_run_status_check" CHECK (status = ANY (ARRAY['RUNNING'::text, 'SUCCESS'::text, 'PARTIAL'::text, 'FAILED'::text]));
ALTER TABLE "venus_rpa"."rpa_run" ADD CONSTRAINT "rpa_run_pkey" PRIMARY KEY (batch_id);

ALTER TABLE "venus_rpa"."rpa_stage_product" ADD CONSTRAINT "rpa_stage_product_validation_status_check" CHECK (validation_status = ANY (ARRAY['VALID'::text, 'INVALID'::text, 'WARNING'::text]));
ALTER TABLE "venus_rpa"."rpa_stage_product" ADD CONSTRAINT "rpa_stage_product_batch_id_fkey" FOREIGN KEY ("batch_id") REFERENCES "venus_rpa"."rpa_run" ("batch_id") ON DELETE CASCADE;
ALTER TABLE "venus_rpa"."rpa_stage_product" ADD CONSTRAINT "rpa_stage_product_loaded_product_id_fkey" FOREIGN KEY ("loaded_product_id") REFERENCES "venus"."products" ("product_id") ON DELETE SET NULL;
ALTER TABLE "venus_rpa"."rpa_stage_product" ADD CONSTRAINT "rpa_stage_product_pkey" PRIMARY KEY (batch_id, legacy_product_id);

ALTER TABLE "venus_rpa"."rpa_stage_user" ADD CONSTRAINT "rpa_stage_user_validation_status_check" CHECK (validation_status = ANY (ARRAY['VALID'::text, 'INVALID'::text, 'WARNING'::text]));
ALTER TABLE "venus_rpa"."rpa_stage_user" ADD CONSTRAINT "rpa_stage_user_batch_id_fkey" FOREIGN KEY ("batch_id") REFERENCES "venus_rpa"."rpa_run" ("batch_id") ON DELETE CASCADE;
ALTER TABLE "venus_rpa"."rpa_stage_user" ADD CONSTRAINT "rpa_stage_user_loaded_user_id_fkey" FOREIGN KEY ("loaded_user_id") REFERENCES "venus"."users" ("user_id") ON DELETE SET NULL;
ALTER TABLE "venus_rpa"."rpa_stage_user" ADD CONSTRAINT "rpa_stage_user_pkey" PRIMARY KEY (batch_id, legacy_user_id);

ALTER TABLE "venus_optimization"."readme" ADD CONSTRAINT "readme_pkey" PRIMARY KEY (item);
