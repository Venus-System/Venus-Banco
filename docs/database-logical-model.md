# Venus — Snapshot físico do banco

> Snapshot gerado a partir dos metadados do PostgreSQL implantado. A fonte desta versão é o catálogo do banco, não uma inferência a partir dos nomes dos campos. O desenho visual editável está em [`docs/modelos lógicos/`](<modelos lógicos/>); este arquivo é a conferência técnica do modelo implantado.

- Banco: `Venus-qa`
- Gerado em: `2026-10-26 22:03:17 -0300`
- Schemas de tabelas: `venus, venus_audit, venus_rpa, venus_optimization`
- Tabelas físicas: **65**
- Relacionamentos FK: **79**
- Tipos enum: **31**
- Views/materialized views inventariadas: **51**

## Artefatos

- [Índice da documentação](README.md)
- [Arquitetura dos schemas e guia de leitura](ARQUITETURA.md)
- [Arquitetura de dados por tecnologia](arquitetura-dados/README.md)
- [Operação e validação](OPERACAO.md)
- [Mapa arquitetural resumido](architecture-overview.mmd)
- [Modelos visuais editáveis do brModelo](<modelos lógicos/README.md>)
- [Diagrama visual completo — SVG](database-logical-model.svg)
- [Fonte do diagrama — Mermaid](database-logical-model.mmd)
- [Snapshot lógico SQL](database-logical-model.sql)

## Escopo e leitura

O diagrama mostra cada tabela física, seus campos, tipos, nulabilidade, PKs, UQs e FKs. As setas representam constraints FK reais; a cardinalidade é calculada pela nulabilidade da FK e pela existência de PK/UQ no conjunto de colunas de origem.

As views `venus_bi` são derivadas e não possuem armazenamento relacional independente. Elas aparecem no inventário ao final deste documento, mas não são desenhadas como tabelas para evitar que uma camada analítica seja confundida com o modelo operacional.

## Inventário por schema

| Schema | Tabela | Campos | PK | FKs | Descrição |
|---|---|---:|---:|---:|---|
| `venus` | `admin_users` | 8 | 1 | 0 | — |
| `venus` | `allergies` | 6 | 1 | 0 | — |
| `venus` | `allergy_ingredients` | 7 | 1 | 2 | Relação explícita entre alergias e ingredientes INCI para compatibilidade de usuários com fórmulas. |
| `venus` | `analysis_results` | 16 | 1 | 3 | — |
| `venus` | `brand_claim_evidence` | 10 | 1 | 1 | — |
| `venus` | `brands` | 9 | 1 | 0 | — |
| `venus` | `claims` | 6 | 1 | 0 | — |
| `venus` | `compatibility_rules` | 17 | 1 | 2 | — |
| `venus` | `data_catalog` | 26 | 1 | 0 | — |
| `venus` | `data_catalog_rules` | 16 | 1 | 0 | — |
| `venus` | `favorites` | 4 | 1 | 2 | — |
| `venus` | `google_oauth_tokens` | 6 | 1 | 1 | — |
| `venus` | `ingredient_aliases` | 8 | 1 | 1 | — |
| `venus` | `ingredient_categories` | 6 | 1 | 1 | — |
| `venus` | `ingredient_category_assignments` | 8 | 1 | 2 | — |
| `venus` | `ingredient_effect_validation_audit` | 12 | 1 | 1 | — |
| `venus` | `ingredient_effects` | 13 | 1 | 2 | — |
| `venus` | `ingredient_evidence_queue` | 9 | 1 | 1 | Fila de curadoria para substituir assessments indiretos v1/low e confidence default por evidência específica. |
| `venus` | `ingredient_properties` | 9 | 1 | 1 | — |
| `venus` | `ingredient_regulations` | 11 | 1 | 2 | — |
| `venus` | `ingredient_resolution_keys` | 3 | 2 | 1 | — |
| `venus` | `ingredient_risk_assessments` | 14 | 1 | 1 | Avaliações aprovadas dos quatro eixos de risco; zero só é evidência quando existir registro aprovado. |
| `venus` | `ingredient_risk_methodologies` | 9 | 1 | 0 | Versões auditáveis das regras que convertem evidência em scores 0–10. |
| `venus` | `ingredient_risk_methodology_dimensions` | 6 | 2 | 1 | Definição, evidência mínima e âncoras por eixo da metodologia ativa. |
| `venus` | `ingredients` | 17 | 1 | 1 | — |
| `venus` | `media_assets` | 23 | 1 | 3 | Canonical registry of Cloudinary media assets. Binary content is stored outside PostgreSQL. |
| `venus` | `packaging` | 15 | 1 | 1 | — |
| `venus` | `packaging_evaluation_policies` | 8 | 1 | 0 | — |
| `venus` | `personalized_scores` | 12 | 1 | 4 | — |
| `venus` | `product_categories` | 5 | 1 | 0 | — |
| `venus` | `product_claims` | 10 | 1 | 2 | — |
| `venus` | `product_composition_receipts` | 14 | 1 | 1 | Recibo da composição bruta, resolução e validação usados para liberar um produto para score. |
| `venus` | `product_dimension_assessments` | 10 | 1 | 1 | Aprovação explícita das dimensões de performance e ética antes do score geral. |
| `venus` | `product_ingredient_resolution_issues` | 7 | 1 | 1 | Tokens OCR não encontrados ou ambíguos; só os casos sem resolução permanecem em needs_review. |
| `venus` | `product_ingredients` | 6 | 1 | 2 | — |
| `venus` | `product_labels` | 8 | 1 | 1 | — |
| `venus` | `product_score_history` | 14 | 1 | 0 | Histórico de scores removidos porque a entrada deixou de atender aos critérios de prontidão. |
| `venus` | `product_scores` | 13 | 1 | 2 | — |
| `venus` | `product_versions` | 12 | 1 | 1 | — |
| `venus` | `products` | 9 | 1 | 2 | — |
| `venus` | `profile_tags` | 7 | 1 | 0 | — |
| `venus` | `recommendations` | 11 | 1 | 4 | — |
| `venus` | `regulations` | 10 | 1 | 0 | — |
| `venus` | `reports` | 10 | 1 | 2 | — |
| `venus` | `review_votes` | 5 | 1 | 2 | — |
| `venus` | `reviews` | 9 | 1 | 2 | — |
| `venus` | `rule_evaluations` | 10 | 1 | 4 | — |
| `venus` | `score_categories` | 6 | 1 | 0 | — |
| `venus` | `scoring_model_categories` | 6 | 1 | 2 | — |
| `venus` | `scoring_models` | 7 | 1 | 0 | — |
| `venus` | `user_access_events` | 8 | 1 | 1 | — |
| `venus` | `user_allergies` | 6 | 1 | 2 | — |
| `venus` | `user_list_items` | 5 | 1 | 2 | — |
| `venus` | `user_lists` | 8 | 1 | 1 | — |
| `venus` | `user_preferences` | 11 | 1 | 1 | — |
| `venus` | `user_profile_tags` | 6 | 1 | 2 | — |
| `venus` | `user_profiles` | 19 | 1 | 1 | — |
| `venus` | `user_tracking_events` | 14 | 1 | 1 | — |
| `venus` | `users` | 9 | 1 | 0 | — |
| `venus_audit` | `audit_logs` | 9 | 1 | 0 | — |
| `venus_rpa` | `rpa_error` | 8 | 1 | 1 | — |
| `venus_rpa` | `rpa_run` | 12 | 1 | 0 | — |
| `venus_rpa` | `rpa_stage_product` | 12 | 2 | 2 | — |
| `venus_rpa` | `rpa_stage_user` | 11 | 2 | 2 | — |
| `venus_optimization` | `readme` | 2 | 1 | 0 | — |

## Detalhe de campos e constraints

### `venus.admin_users`

| # | Campo | Tipo | Aceita NULL? | Default | Papel | Descrição |
|---:|---|---|:---:|---|---|---|
| 1 | `admin_user_id` | `bigint` | não | `—` | PK | — |
| 2 | `name` | `text` | não | `—` | — | — |
| 3 | `email` | `text` | não | `—` | UQ | — |
| 4 | `role` | `venus.admin_role_enum` | não | `'admin'::venus.admin_role_enum` | — | — |
| 5 | `is_active` | `boolean` | não | `true` | — | — |
| 6 | `created_at` | `timestamp with time zone` | não | `now()` | — | — |
| 7 | `updated_at` | `timestamp with time zone` | não | `now()` | — | — |
| 8 | `password_hash` | `text` | sim | `—` | — | — |

**Constraints**

| Nome | Tipo | Definição |
|---|---|---|
| `admin_users_pkey` | `PK` | `PRIMARY KEY (admin_user_id)` |
| `admin_users_email_key` | `UQ` | `UNIQUE (email)` |

**Índices únicos**

| Nome | Definição |
|---|---|
| `admin_users_email_key` | `CREATE UNIQUE INDEX admin_users_email_key ON venus.admin_users USING btree (email)` |

### `venus.allergies`

| # | Campo | Tipo | Aceita NULL? | Default | Papel | Descrição |
|---:|---|---|:---:|---|---|---|
| 1 | `allergy_id` | `bigint` | não | `—` | PK | — |
| 2 | `allergy_name` | `text` | não | `—` | UQ | — |
| 3 | `allergy_type` | `venus.allergy_type_enum` | não | `'ingredient'::venus.allergy_type_enum` | — | — |
| 4 | `created_at` | `timestamp with time zone` | não | `now()` | — | — |
| 5 | `updated_at` | `timestamp with time zone` | não | `now()` | — | — |
| 6 | `is_catalog_visible` | `boolean` | não | `false` | — | — |

**Constraints**

| Nome | Tipo | Definição |
|---|---|---|
| `allergies_pkey` | `PK` | `PRIMARY KEY (allergy_id)` |
| `allergies_allergy_name_key` | `UQ` | `UNIQUE (allergy_name)` |

**Índices únicos**

| Nome | Definição |
|---|---|
| `allergies_allergy_name_key` | `CREATE UNIQUE INDEX allergies_allergy_name_key ON venus.allergies USING btree (allergy_name)` |

### `venus.allergy_ingredients`

Relação explícita entre alergias e ingredientes INCI para compatibilidade de usuários com fórmulas.

| # | Campo | Tipo | Aceita NULL? | Default | Papel | Descrição |
|---:|---|---|:---:|---|---|---|
| 1 | `allergy_ingredient_id` | `bigint` | não | `—` | PK | — |
| 2 | `fk_allergy_id` | `bigint` | não | `—` | UQ, FK | FK para a alergia declarada/cadastrada. |
| 3 | `fk_ingredient_id` | `bigint` | não | `—` | UQ, FK | FK para o ingrediente INCI efetivamente relacionado à alergia. |
| 4 | `source_type` | `venus.source_type_enum` | não | `'admin'::venus.source_type_enum` | — | — |
| 5 | `source_reference` | `text` | sim | `—` | — | — |
| 6 | `created_at` | `timestamp with time zone` | não | `now()` | — | — |
| 7 | `updated_at` | `timestamp with time zone` | não | `now()` | — | — |

**Constraints**

| Nome | Tipo | Definição |
|---|---|---|
| `allergy_ingredients_fk_allergy_id_fkey` | `FK` | `FOREIGN KEY (fk_allergy_id) REFERENCES venus.allergies(allergy_id) ON DELETE CASCADE` |
| `allergy_ingredients_fk_ingredient_id_fkey` | `FK` | `FOREIGN KEY (fk_ingredient_id) REFERENCES venus.ingredients(ingredient_id) ON DELETE CASCADE` |
| `allergy_ingredients_pkey` | `PK` | `PRIMARY KEY (allergy_ingredient_id)` |
| `allergy_ingredients_fk_allergy_id_fk_ingredient_id_key` | `UQ` | `UNIQUE (fk_allergy_id, fk_ingredient_id)` |

**Índices únicos**

| Nome | Definição |
|---|---|
| `allergy_ingredients_fk_allergy_id_fk_ingredient_id_key` | `CREATE UNIQUE INDEX allergy_ingredients_fk_allergy_id_fk_ingredient_id_key ON venus.allergy_ingredients USING btree (fk_allergy_id, fk_ingredient_id)` |

### `venus.analysis_results`

| # | Campo | Tipo | Aceita NULL? | Default | Papel | Descrição |
|---:|---|---|:---:|---|---|---|
| 1 | `analysis_result_id` | `bigint` | não | `—` | PK | — |
| 2 | `fk_user_id` | `bigint` | não | `—` | FK | — |
| 3 | `fk_product_version_id` | `bigint` | não | `—` | FK | — |
| 4 | `fk_scoring_model_id` | `bigint` | não | `—` | FK | — |
| 5 | `overall_score` | `integer` | não | `0` | — | — |
| 6 | `health_score` | `integer` | sim | `—` | — | — |
| 7 | `environmental_score` | `integer` | sim | `—` | — | — |
| 8 | `ethical_score` | `integer` | não | `0` | — | — |
| 9 | `performance_score` | `integer` | sim | `—` | — | — |
| 10 | `transparency_score` | `integer` | sim | `—` | — | — |
| 11 | `confidence_score` | `smallint` | não | `1` | — | — |
| 12 | `processing_time_ms` | `integer` | não | `0` | — | — |
| 13 | `status` | `venus.analysis_status_enum` | não | `'processing'::venus.analysis_status_enum` | — | — |
| 14 | `summary` | `text` | não | `''::text` | — | — |
| 15 | `created_at` | `timestamp with time zone` | não | `now()` | — | — |
| 16 | `updated_at` | `timestamp with time zone` | não | `now()` | — | — |

**Constraints**

| Nome | Tipo | Definição |
|---|---|---|
| `ck_analysis_results_confidence_score_range` | `CHECK` | `CHECK (confidence_score >= 1 AND confidence_score <= 100)` |
| `analysis_results_fk_product_version_id_fkey` | `FK` | `FOREIGN KEY (fk_product_version_id) REFERENCES venus.product_versions(product_version_id) ON DELETE CASCADE` |
| `analysis_results_fk_scoring_model_id_fkey` | `FK` | `FOREIGN KEY (fk_scoring_model_id) REFERENCES venus.scoring_models(scoring_model_id) ON DELETE RESTRICT` |
| `analysis_results_fk_user_id_fkey` | `FK` | `FOREIGN KEY (fk_user_id) REFERENCES venus.users(user_id) ON DELETE CASCADE` |
| `analysis_results_pkey` | `PK` | `PRIMARY KEY (analysis_result_id)` |

### `venus.brand_claim_evidence`

| # | Campo | Tipo | Aceita NULL? | Default | Papel | Descrição |
|---:|---|---|:---:|---|---|---|
| 1 | `brand_claim_evidence_id` | `bigint` | não | `nextval('venus.brand_claim_evidence_brand_claim_evidence_id_seq'::regclass)` | PK | — |
| 2 | `fk_brand_id` | `bigint` | não | `—` | UQ, FK | — |
| 3 | `claim_type` | `text` | não | `—` | UQ | — |
| 4 | `claim_value` | `boolean` | não | `true` | — | — |
| 5 | `source_url` | `text` | não | `—` | UQ | — |
| 6 | `source_title` | `text` | não | `—` | — | — |
| 7 | `evidence_note` | `text` | não | `—` | — | — |
| 8 | `evidence_level` | `text` | não | `—` | — | — |
| 9 | `verified_at` | `timestamp with time zone` | não | `now()` | — | — |
| 10 | `methodology_version` | `text` | não | `'v1'::text` | — | — |

**Constraints**

| Nome | Tipo | Definição |
|---|---|---|
| `brand_claim_evidence_claim_type_check` | `CHECK` | `CHECK (claim_type = ANY (ARRAY['vegan'::text, 'cruelty_free'::text, 'brazilian'::text]))` |
| `brand_claim_evidence_evidence_level_check` | `CHECK` | `CHECK (evidence_level = ANY (ARRAY['high'::text, 'medium'::text, 'low'::text]))` |
| `brand_claim_evidence_note_nonblank` | `CHECK` | `CHECK (btrim(evidence_note) <> ''::text)` |
| `brand_claim_evidence_source_title_nonblank` | `CHECK` | `CHECK (btrim(source_title) <> ''::text)` |
| `brand_claim_evidence_source_url_nonblank` | `CHECK` | `CHECK (btrim(source_url) <> ''::text)` |
| `brand_claim_evidence_fk_brand_id_fkey` | `FK` | `FOREIGN KEY (fk_brand_id) REFERENCES venus.brands(brand_id) ON DELETE CASCADE` |
| `brand_claim_evidence_pkey` | `PK` | `PRIMARY KEY (brand_claim_evidence_id)` |
| `brand_claim_evidence_fk_brand_id_claim_type_source_url_key` | `UQ` | `UNIQUE (fk_brand_id, claim_type, source_url)` |

**Índices únicos**

| Nome | Definição |
|---|---|
| `brand_claim_evidence_fk_brand_id_claim_type_source_url_key` | `CREATE UNIQUE INDEX brand_claim_evidence_fk_brand_id_claim_type_source_url_key ON venus.brand_claim_evidence USING btree (fk_brand_id, claim_type, source_url)` |

### `venus.brands`

| # | Campo | Tipo | Aceita NULL? | Default | Papel | Descrição |
|---:|---|---|:---:|---|---|---|
| 1 | `brand_id` | `bigint` | não | `—` | PK | — |
| 2 | `name` | `text` | não | `—` | UQ | — |
| 3 | `country` | `text` | sim | `—` | UQ | — |
| 4 | `website` | `text` | sim | `—` | — | — |
| 5 | `has_cruelty_free_claim` | `boolean` | sim | `—` | — | TRUE/FALSE somente quando houver evidência elegível; NULL significa desconhecido. |
| 6 | `has_vegan_claim` | `boolean` | sim | `—` | — | TRUE/FALSE somente quando houver evidência elegível; NULL significa desconhecido. |
| 7 | `is_brazilian` | `boolean` | não | `false` | — | — |
| 8 | `created_at` | `timestamp with time zone` | não | `now()` | — | — |
| 9 | `updated_at` | `timestamp with time zone` | não | `now()` | — | — |

**Constraints**

| Nome | Tipo | Definição |
|---|---|---|
| `brands_pkey` | `PK` | `PRIMARY KEY (brand_id)` |
| `brands_name_country_key` | `UQ` | `UNIQUE (name, country)` |

**Índices únicos**

| Nome | Definição |
|---|---|
| `brands_name_country_key` | `CREATE UNIQUE INDEX brands_name_country_key ON venus.brands USING btree (name, country)` |
| `uq_brands_name_normalized` | `CREATE UNIQUE INDEX uq_brands_name_normalized ON venus.brands USING btree (lower(btrim(name)))` |

### `venus.claims`

| # | Campo | Tipo | Aceita NULL? | Default | Papel | Descrição |
|---:|---|---|:---:|---|---|---|
| 1 | `claim_id` | `bigint` | não | `—` | PK | — |
| 2 | `name` | `text` | não | `—` | UQ | — |
| 3 | `description` | `text` | não | `''::text` | — | — |
| 4 | `claim_type` | `venus.claim_type_enum` | não | `'marketing'::venus.claim_type_enum` | — | — |
| 5 | `created_at` | `timestamp with time zone` | não | `now()` | — | — |
| 6 | `updated_at` | `timestamp with time zone` | não | `now()` | — | — |

**Constraints**

| Nome | Tipo | Definição |
|---|---|---|
| `claims_pkey` | `PK` | `PRIMARY KEY (claim_id)` |
| `claims_name_key` | `UQ` | `UNIQUE (name)` |

**Índices únicos**

| Nome | Definição |
|---|---|
| `claims_name_key` | `CREATE UNIQUE INDEX claims_name_key ON venus.claims USING btree (name)` |

### `venus.compatibility_rules`

| # | Campo | Tipo | Aceita NULL? | Default | Papel | Descrição |
|---:|---|---|:---:|---|---|---|
| 1 | `compatibility_rule_id` | `bigint` | não | `—` | PK | — |
| 2 | `fk_ingredient_effect_id` | `bigint` | não | `—` | UQ, FK | — |
| 3 | `fk_scoring_model_id` | `bigint` | não | `—` | UQ, FK | — |
| 4 | `effect_type` | `venus.effect_type_enum` | não | `—` | — | — |
| 5 | `score_delta` | `integer` | não | `0` | — | — |
| 6 | `weight` | `numeric(6,2)` | não | `1.00` | — | — |
| 7 | `priority` | `integer` | não | `0` | — | — |
| 8 | `has_concentration_factor` | `boolean` | não | `false` | — | — |
| 9 | `is_enabled` | `boolean` | não | `true` | — | — |
| 10 | `evidence_level` | `venus.evidence_level_enum` | não | `'medium'::venus.evidence_level_enum` | — | — |
| 11 | `reason` | `text` | não | `''::text` | — | — |
| 12 | `source_type` | `venus.source_type_enum` | não | `'system'::venus.source_type_enum` | — | — |
| 13 | `source_reference` | `text` | sim | `—` | — | — |
| 14 | `created_at` | `timestamp with time zone` | não | `now()` | — | — |
| 15 | `updated_at` | `timestamp with time zone` | não | `now()` | — | — |
| 16 | `is_block` | `boolean` | sim | `(effect_type = 'block'::venus.effect_type_enum)` | — | — |
| 17 | `is_alert` | `boolean` | sim | `(effect_type = 'alert'::venus.effect_type_enum)` | — | — |

**Constraints**

| Nome | Tipo | Definição |
|---|---|---|
| `compatibility_rules_fk_ingredient_effect_id_fkey` | `FK` | `FOREIGN KEY (fk_ingredient_effect_id) REFERENCES venus.ingredient_effects(ingredient_effect_id) ON DELETE CASCADE` |
| `compatibility_rules_fk_scoring_model_id_fkey` | `FK` | `FOREIGN KEY (fk_scoring_model_id) REFERENCES venus.scoring_models(scoring_model_id) ON DELETE RESTRICT` |
| `compatibility_rules_pkey` | `PK` | `PRIMARY KEY (compatibility_rule_id)` |
| `compatibility_rules_fk_ingredient_effect_id_fk_scoring_mode_key` | `UQ` | `UNIQUE (fk_ingredient_effect_id, fk_scoring_model_id)` |

**Índices únicos**

| Nome | Definição |
|---|---|
| `compatibility_rules_fk_ingredient_effect_id_fk_scoring_mode_key` | `CREATE UNIQUE INDEX compatibility_rules_fk_ingredient_effect_id_fk_scoring_mode_key ON venus.compatibility_rules USING btree (fk_ingredient_effect_id, fk_scoring_model_id)` |

### `venus.data_catalog`

| # | Campo | Tipo | Aceita NULL? | Default | Papel | Descrição |
|---:|---|---|:---:|---|---|---|
| 1 | `catalog_id` | `bigint` | não | `—` | PK | — |
| 2 | `object_type` | `text` | não | `—` | UQ | — |
| 3 | `table_name` | `text` | não | `—` | UQ | — |
| 4 | `column_name` | `text` | não | `''::text` | UQ | — |
| 5 | `ordinal_position` | `integer` | sim | `—` | — | — |
| 6 | `data_type` | `text` | sim | `—` | — | — |
| 7 | `udt_name` | `text` | sim | `—` | — | — |
| 8 | `is_nullable` | `boolean` | sim | `—` | — | — |
| 9 | `default_value` | `text` | sim | `—` | — | — |
| 10 | `is_primary_key` | `boolean` | não | `false` | — | — |
| 11 | `is_foreign_key` | `boolean` | não | `false` | — | — |
| 12 | `referenced_table_name` | `text` | sim | `—` | — | — |
| 13 | `referenced_column_name` | `text` | não | `''::text` | — | — |
| 14 | `table_description` | `text` | sim | `—` | — | — |
| 15 | `column_description` | `text` | sim | `—` | — | — |
| 16 | `business_rule` | `text` | sim | `—` | — | — |
| 17 | `access_level` | `text` | não | `'AUTHENTICATED'::text` | — | — |
| 18 | `access_rule` | `text` | sim | `—` | — | — |
| 19 | `data_classification` | `text` | não | `'INTERNAL'::text` | — | — |
| 20 | `sensitivity_reason` | `text` | sim | `—` | — | — |
| 21 | `retention_policy` | `text` | sim | `—` | — | — |
| 22 | `source_of_definition` | `text` | não | `'VENUS_SCHEMA'::text` | — | — |
| 23 | `reviewed_at` | `timestamp with time zone` | não | `now()` | — | — |
| 24 | `is_active` | `boolean` | não | `true` | — | — |
| 25 | `created_at` | `timestamp with time zone` | não | `now()` | — | — |
| 26 | `updated_at` | `timestamp with time zone` | não | `now()` | — | — |

**Constraints**

| Nome | Tipo | Definição |
|---|---|---|
| `data_catalog_access_level_check` | `CHECK` | `CHECK (access_level = ANY (ARRAY['PUBLIC'::text, 'AUTHENTICATED'::text, 'OWNER'::text, 'ADMIN'::text, 'SYSTEM'::text, 'RESTRICTED'::text]))` |
| `data_catalog_data_classification_check` | `CHECK` | `CHECK (data_classification = ANY (ARRAY['PUBLIC'::text, 'INTERNAL'::text, 'CONFIDENTIAL'::text, 'RESTRICTED'::text]))` |
| `data_catalog_object_type_check` | `CHECK` | `CHECK (object_type = ANY (ARRAY['TABLE'::text, 'COLUMN'::text]))` |
| `data_catalog_pkey` | `PK` | `PRIMARY KEY (catalog_id)` |
| `data_catalog_object_type_table_name_column_name_key` | `UQ` | `UNIQUE (object_type, table_name, column_name)` |

**Índices únicos**

| Nome | Definição |
|---|---|
| `data_catalog_object_type_table_name_column_name_key` | `CREATE UNIQUE INDEX data_catalog_object_type_table_name_column_name_key ON venus.data_catalog USING btree (object_type, table_name, column_name)` |

### `venus.data_catalog_rules`

| # | Campo | Tipo | Aceita NULL? | Default | Papel | Descrição |
|---:|---|---|:---:|---|---|---|
| 1 | `rule_id` | `bigint` | não | `—` | PK | — |
| 2 | `object_type` | `text` | não | `—` | UQ | — |
| 3 | `table_name` | `text` | não | `—` | UQ | — |
| 4 | `column_name` | `text` | não | `''::text` | UQ | — |
| 5 | `table_description` | `text` | sim | `—` | — | — |
| 6 | `column_description` | `text` | sim | `—` | — | — |
| 7 | `business_rule` | `text` | sim | `—` | — | — |
| 8 | `access_level` | `text` | não | `'AUTHENTICATED'::text` | — | — |
| 9 | `access_rule` | `text` | sim | `—` | — | — |
| 10 | `data_classification` | `text` | não | `'INTERNAL'::text` | — | — |
| 11 | `sensitivity_reason` | `text` | sim | `—` | — | — |
| 12 | `retention_policy` | `text` | sim | `—` | — | — |
| 13 | `notes` | `text` | sim | `—` | — | — |
| 14 | `is_active` | `boolean` | não | `true` | — | — |
| 15 | `created_at` | `timestamp with time zone` | não | `now()` | — | — |
| 16 | `updated_at` | `timestamp with time zone` | não | `now()` | — | — |

**Constraints**

| Nome | Tipo | Definição |
|---|---|---|
| `data_catalog_rules_access_level_check` | `CHECK` | `CHECK (access_level = ANY (ARRAY['PUBLIC'::text, 'AUTHENTICATED'::text, 'OWNER'::text, 'ADMIN'::text, 'SYSTEM'::text, 'RESTRICTED'::text]))` |
| `data_catalog_rules_data_classification_check` | `CHECK` | `CHECK (data_classification = ANY (ARRAY['PUBLIC'::text, 'INTERNAL'::text, 'CONFIDENTIAL'::text, 'RESTRICTED'::text]))` |
| `data_catalog_rules_object_type_check` | `CHECK` | `CHECK (object_type = ANY (ARRAY['TABLE'::text, 'COLUMN'::text]))` |
| `data_catalog_rules_pkey` | `PK` | `PRIMARY KEY (rule_id)` |
| `data_catalog_rules_object_type_table_name_column_name_key` | `UQ` | `UNIQUE (object_type, table_name, column_name)` |

**Índices únicos**

| Nome | Definição |
|---|---|
| `data_catalog_rules_object_type_table_name_column_name_key` | `CREATE UNIQUE INDEX data_catalog_rules_object_type_table_name_column_name_key ON venus.data_catalog_rules USING btree (object_type, table_name, column_name)` |

### `venus.favorites`

| # | Campo | Tipo | Aceita NULL? | Default | Papel | Descrição |
|---:|---|---|:---:|---|---|---|
| 1 | `favorite_id` | `bigint` | não | `—` | PK | — |
| 2 | `fk_user_id` | `bigint` | não | `—` | UQ, FK | — |
| 3 | `fk_product_id` | `bigint` | não | `—` | UQ, FK | — |
| 4 | `created_at` | `timestamp with time zone` | não | `now()` | — | — |

**Constraints**

| Nome | Tipo | Definição |
|---|---|---|
| `favorites_fk_product_id_fkey` | `FK` | `FOREIGN KEY (fk_product_id) REFERENCES venus.products(product_id) ON DELETE CASCADE` |
| `favorites_fk_user_id_fkey` | `FK` | `FOREIGN KEY (fk_user_id) REFERENCES venus.users(user_id) ON DELETE CASCADE` |
| `favorites_pkey` | `PK` | `PRIMARY KEY (favorite_id)` |
| `favorites_fk_user_id_fk_product_id_key` | `UQ` | `UNIQUE (fk_user_id, fk_product_id)` |

**Índices únicos**

| Nome | Definição |
|---|---|
| `favorites_fk_user_id_fk_product_id_key` | `CREATE UNIQUE INDEX favorites_fk_user_id_fk_product_id_key ON venus.favorites USING btree (fk_user_id, fk_product_id)` |

### `venus.google_oauth_tokens`

| # | Campo | Tipo | Aceita NULL? | Default | Papel | Descrição |
|---:|---|---|:---:|---|---|---|
| 1 | `google_oauth_token_id` | `bigint` | não | `—` | PK | — |
| 2 | `fk_user_id` | `bigint` | não | `—` | UQ, FK | — |
| 3 | `encrypted_refresh_token` | `bytea` | não | `—` | — | — |
| 4 | `scope` | `text` | não | `—` | — | — |
| 5 | `created_at` | `timestamp with time zone` | não | `now()` | — | — |
| 6 | `updated_at` | `timestamp with time zone` | não | `now()` | — | — |

**Constraints**

| Nome | Tipo | Definição |
|---|---|---|
| `google_oauth_tokens_fk_user_id_fkey` | `FK` | `FOREIGN KEY (fk_user_id) REFERENCES venus.users(user_id) ON DELETE CASCADE` |
| `google_oauth_tokens_pkey` | `PK` | `PRIMARY KEY (google_oauth_token_id)` |
| `google_oauth_tokens_fk_user_id_key` | `UQ` | `UNIQUE (fk_user_id)` |

**Índices únicos**

| Nome | Definição |
|---|---|
| `google_oauth_tokens_fk_user_id_key` | `CREATE UNIQUE INDEX google_oauth_tokens_fk_user_id_key ON venus.google_oauth_tokens USING btree (fk_user_id)` |

### `venus.ingredient_aliases`

| # | Campo | Tipo | Aceita NULL? | Default | Papel | Descrição |
|---:|---|---|:---:|---|---|---|
| 1 | `ingredient_alias_id` | `bigint` | não | `—` | PK | — |
| 2 | `fk_ingredient_id` | `bigint` | não | `—` | UQ, FK | — |
| 3 | `alias_name` | `text` | não | `—` | UQ | — |
| 4 | `alias_language` | `text` | não | `'en'::text` | UQ | — |
| 5 | `source_type` | `venus.source_type_enum` | não | `'admin'::venus.source_type_enum` | — | — |
| 6 | `source_reference` | `text` | sim | `—` | — | — |
| 7 | `created_at` | `timestamp with time zone` | não | `now()` | — | — |
| 8 | `updated_at` | `timestamp with time zone` | não | `now()` | — | — |

**Constraints**

| Nome | Tipo | Definição |
|---|---|---|
| `ingredient_aliases_fk_ingredient_id_fkey` | `FK` | `FOREIGN KEY (fk_ingredient_id) REFERENCES venus.ingredients(ingredient_id) ON DELETE CASCADE` |
| `ingredient_aliases_pkey` | `PK` | `PRIMARY KEY (ingredient_alias_id)` |
| `ingredient_aliases_fk_ingredient_id_alias_name_alias_langua_key` | `UQ` | `UNIQUE (fk_ingredient_id, alias_name, alias_language)` |

**Índices únicos**

| Nome | Definição |
|---|---|
| `ingredient_aliases_fk_ingredient_id_alias_name_alias_langua_key` | `CREATE UNIQUE INDEX ingredient_aliases_fk_ingredient_id_alias_name_alias_langua_key ON venus.ingredient_aliases USING btree (fk_ingredient_id, alias_name, alias_language)` |

### `venus.ingredient_categories`

| # | Campo | Tipo | Aceita NULL? | Default | Papel | Descrição |
|---:|---|---|:---:|---|---|---|
| 1 | `ingredient_category_id` | `bigint` | não | `—` | PK | — |
| 2 | `parent_ingredient_category_id` | `bigint` | sim | `—` | FK | — |
| 3 | `name` | `text` | não | `—` | UQ | — |
| 4 | `description` | `text` | não | `''::text` | — | — |
| 5 | `created_at` | `timestamp with time zone` | não | `now()` | — | — |
| 6 | `updated_at` | `timestamp with time zone` | não | `now()` | — | — |

**Constraints**

| Nome | Tipo | Definição |
|---|---|---|
| `ingredient_categories_parent_ingredient_category_id_fkey` | `FK` | `FOREIGN KEY (parent_ingredient_category_id) REFERENCES venus.ingredient_categories(ingredient_category_id) ON DELETE SET NULL` |
| `ingredient_categories_pkey` | `PK` | `PRIMARY KEY (ingredient_category_id)` |
| `ingredient_categories_name_key` | `UQ` | `UNIQUE (name)` |

**Índices únicos**

| Nome | Definição |
|---|---|
| `ingredient_categories_name_key` | `CREATE UNIQUE INDEX ingredient_categories_name_key ON venus.ingredient_categories USING btree (name)` |

### `venus.ingredient_category_assignments`

| # | Campo | Tipo | Aceita NULL? | Default | Papel | Descrição |
|---:|---|---|:---:|---|---|---|
| 1 | `ingredient_category_assignment_id` | `bigint` | não | `—` | PK | — |
| 2 | `fk_ingredient_id` | `bigint` | não | `—` | UQ, FK | — |
| 3 | `fk_ingredient_category_id` | `bigint` | não | `—` | UQ, FK | — |
| 4 | `assignment_role` | `text` | não | `'secondary'::text` | — | — |
| 5 | `source_type` | `venus.source_type_enum` | não | `'admin'::venus.source_type_enum` | — | — |
| 6 | `source_reference` | `text` | sim | `—` | — | — |
| 7 | `created_at` | `timestamp with time zone` | não | `now()` | — | — |
| 8 | `updated_at` | `timestamp with time zone` | não | `now()` | — | — |

**Constraints**

| Nome | Tipo | Definição |
|---|---|---|
| `ingredient_category_assignments_assignment_role_check` | `CHECK` | `CHECK (assignment_role = 'secondary'::text)` |
| `ingredient_category_assignments_fk_ingredient_category_id_fkey` | `FK` | `FOREIGN KEY (fk_ingredient_category_id) REFERENCES venus.ingredient_categories(ingredient_category_id) ON DELETE RESTRICT` |
| `ingredient_category_assignments_fk_ingredient_id_fkey` | `FK` | `FOREIGN KEY (fk_ingredient_id) REFERENCES venus.ingredients(ingredient_id) ON DELETE CASCADE` |
| `ingredient_category_assignments_pkey` | `PK` | `PRIMARY KEY (ingredient_category_assignment_id)` |
| `ingredient_category_assignmen_fk_ingredient_id_fk_ingredien_key` | `UQ` | `UNIQUE (fk_ingredient_id, fk_ingredient_category_id)` |

**Índices únicos**

| Nome | Definição |
|---|---|
| `ingredient_category_assignmen_fk_ingredient_id_fk_ingredien_key` | `CREATE UNIQUE INDEX ingredient_category_assignmen_fk_ingredient_id_fk_ingredien_key ON venus.ingredient_category_assignments USING btree (fk_ingredient_id, fk_ingredient_category_id)` |

### `venus.ingredient_effect_validation_audit`

| # | Campo | Tipo | Aceita NULL? | Default | Papel | Descrição |
|---:|---|---|:---:|---|---|---|
| 1 | `audit_id` | `bigint` | não | `nextval('venus.ingredient_effect_validation_audit_audit_id_seq'::regclass)` | PK | — |
| 2 | `ingredient_effect_id` | `bigint` | não | `—` | — | — |
| 3 | `fk_ingredient_id` | `bigint` | não | `—` | FK | — |
| 4 | `from_effect_category` | `text` | não | `—` | — | — |
| 5 | `to_effect_category` | `text` | não | `—` | — | — |
| 6 | `from_review_status` | `text` | não | `—` | — | — |
| 7 | `to_review_status` | `text` | não | `—` | — | — |
| 8 | `evidence_level` | `text` | não | `—` | — | — |
| 9 | `source_reference` | `text` | sim | `—` | — | — |
| 10 | `decision` | `text` | não | `—` | — | — |
| 11 | `methodology_version` | `text` | não | `'v1'::text` | — | — |
| 12 | `applied_at` | `timestamp with time zone` | não | `now()` | — | — |

**Constraints**

| Nome | Tipo | Definição |
|---|---|---|
| `ingredient_effect_validation_audit_fk_ingredient_id_fkey` | `FK` | `FOREIGN KEY (fk_ingredient_id) REFERENCES venus.ingredients(ingredient_id) ON DELETE CASCADE` |
| `ingredient_effect_validation_audit_pkey` | `PK` | `PRIMARY KEY (audit_id)` |

### `venus.ingredient_effects`

| # | Campo | Tipo | Aceita NULL? | Default | Papel | Descrição |
|---:|---|---|:---:|---|---|---|
| 1 | `ingredient_effect_id` | `bigint` | não | `—` | PK | — |
| 2 | `fk_ingredient_id` | `bigint` | não | `—` | UQ, FK | — |
| 3 | `fk_profile_tag_id` | `bigint` | não | `—` | UQ, FK | — |
| 4 | `effect_category` | `venus.effect_category_enum` | não | `—` | UQ | — |
| 5 | `effect_name` | `text` | não | `—` | UQ | — |
| 6 | `effect_description` | `text` | não | `''::text` | — | — |
| 7 | `effect_strength` | `venus.effect_strength_enum` | não | `'moderate'::venus.effect_strength_enum` | — | — |
| 8 | `evidence_level` | `venus.evidence_level_enum` | não | `'medium'::venus.evidence_level_enum` | — | — |
| 9 | `review_status` | `venus.review_status_enum` | não | `'pending'::venus.review_status_enum` | — | — |
| 10 | `source_type` | `venus.source_type_enum` | não | `'admin'::venus.source_type_enum` | — | — |
| 11 | `source_reference` | `text` | sim | `—` | — | — |
| 12 | `created_at` | `timestamp with time zone` | não | `now()` | — | — |
| 13 | `updated_at` | `timestamp with time zone` | não | `now()` | — | — |

**Constraints**

| Nome | Tipo | Definição |
|---|---|---|
| `ingredient_effects_fk_ingredient_id_fkey` | `FK` | `FOREIGN KEY (fk_ingredient_id) REFERENCES venus.ingredients(ingredient_id) ON DELETE CASCADE` |
| `ingredient_effects_fk_profile_tag_id_fkey` | `FK` | `FOREIGN KEY (fk_profile_tag_id) REFERENCES venus.profile_tags(profile_tag_id) ON DELETE CASCADE` |
| `ingredient_effects_pkey` | `PK` | `PRIMARY KEY (ingredient_effect_id)` |
| `ingredient_effects_fk_ingredient_id_fk_profile_tag_id_effec_key` | `UQ` | `UNIQUE (fk_ingredient_id, fk_profile_tag_id, effect_category, effect_name)` |

**Índices únicos**

| Nome | Definição |
|---|---|
| `ingredient_effects_fk_ingredient_id_fk_profile_tag_id_effec_key` | `CREATE UNIQUE INDEX ingredient_effects_fk_ingredient_id_fk_profile_tag_id_effec_key ON venus.ingredient_effects USING btree (fk_ingredient_id, fk_profile_tag_id, effect_category, effect_name)` |

### `venus.ingredient_evidence_queue`

Fila de curadoria para substituir assessments indiretos v1/low e confidence default por evidência específica.

| # | Campo | Tipo | Aceita NULL? | Default | Papel | Descrição |
|---:|---|---|:---:|---|---|---|
| 1 | `ingredient_evidence_queue_id` | `bigint` | não | `—` | PK | — |
| 2 | `fk_ingredient_id` | `bigint` | não | `—` | UQ, FK | — |
| 3 | `priority` | `smallint` | não | `—` | — | — |
| 4 | `is_currently_used` | `boolean` | não | `false` | — | — |
| 5 | `queue_status` | `text` | não | `'queued'::text` | — | — |
| 6 | `target_evidence_level` | `venus.evidence_level_enum` | não | `'medium'::venus.evidence_level_enum` | — | — |
| 7 | `reason` | `text` | não | `—` | — | — |
| 8 | `created_at` | `timestamp with time zone` | não | `now()` | — | — |
| 9 | `updated_at` | `timestamp with time zone` | não | `now()` | — | — |

**Constraints**

| Nome | Tipo | Definição |
|---|---|---|
| `ingredient_evidence_queue_priority_check` | `CHECK` | `CHECK (priority >= 1 AND priority <= 100)` |
| `ingredient_evidence_queue_queue_status_check` | `CHECK` | `CHECK (queue_status = ANY (ARRAY['queued'::text, 'in_progress'::text, 'completed'::text, 'blocked'::text]))` |
| `ingredient_evidence_queue_fk_ingredient_id_fkey` | `FK` | `FOREIGN KEY (fk_ingredient_id) REFERENCES venus.ingredients(ingredient_id) ON DELETE CASCADE` |
| `ingredient_evidence_queue_pkey` | `PK` | `PRIMARY KEY (ingredient_evidence_queue_id)` |
| `ingredient_evidence_queue_fk_ingredient_id_key` | `UQ` | `UNIQUE (fk_ingredient_id)` |

**Índices únicos**

| Nome | Definição |
|---|---|
| `ingredient_evidence_queue_fk_ingredient_id_key` | `CREATE UNIQUE INDEX ingredient_evidence_queue_fk_ingredient_id_key ON venus.ingredient_evidence_queue USING btree (fk_ingredient_id)` |

### `venus.ingredient_properties`

| # | Campo | Tipo | Aceita NULL? | Default | Papel | Descrição |
|---:|---|---|:---:|---|---|---|
| 1 | `ingredient_property_id` | `bigint` | não | `—` | PK | — |
| 2 | `fk_ingredient_id` | `bigint` | não | `—` | UQ, FK | — |
| 3 | `property_name` | `text` | não | `—` | UQ | — |
| 4 | `property_value` | `text` | não | `—` | — | — |
| 5 | `unit` | `text` | não | `''::text` | UQ | — |
| 6 | `source_type` | `venus.source_type_enum` | não | `'admin'::venus.source_type_enum` | — | — |
| 7 | `source_reference` | `text` | sim | `—` | — | — |
| 8 | `created_at` | `timestamp with time zone` | não | `now()` | — | — |
| 9 | `updated_at` | `timestamp with time zone` | não | `now()` | — | — |

**Constraints**

| Nome | Tipo | Definição |
|---|---|---|
| `ingredient_properties_fk_ingredient_id_fkey` | `FK` | `FOREIGN KEY (fk_ingredient_id) REFERENCES venus.ingredients(ingredient_id) ON DELETE CASCADE` |
| `ingredient_properties_pkey` | `PK` | `PRIMARY KEY (ingredient_property_id)` |
| `ingredient_properties_fk_ingredient_id_property_name_unit_key` | `UQ` | `UNIQUE (fk_ingredient_id, property_name, unit)` |

**Índices únicos**

| Nome | Definição |
|---|---|
| `ingredient_properties_fk_ingredient_id_property_name_unit_key` | `CREATE UNIQUE INDEX ingredient_properties_fk_ingredient_id_property_name_unit_key ON venus.ingredient_properties USING btree (fk_ingredient_id, property_name, unit)` |

### `venus.ingredient_regulations`

| # | Campo | Tipo | Aceita NULL? | Default | Papel | Descrição |
|---:|---|---|:---:|---|---|---|
| 1 | `ingredient_regulation_id` | `bigint` | não | `—` | PK | — |
| 2 | `fk_ingredient_id` | `bigint` | não | `—` | UQ, FK | — |
| 3 | `fk_regulation_id` | `bigint` | não | `—` | UQ, FK | — |
| 4 | `restriction_type` | `venus.restriction_type_enum` | não | `'warning'::venus.restriction_type_enum` | — | — |
| 5 | `max_concentration_value` | `numeric(10,4)` | sim | `—` | — | — |
| 6 | `unit` | `text` | não | `''::text` | — | — |
| 7 | `notes` | `text` | não | `''::text` | — | — |
| 8 | `source_type` | `venus.source_type_enum` | não | `'admin'::venus.source_type_enum` | — | — |
| 9 | `source_reference` | `text` | sim | `—` | — | — |
| 10 | `created_at` | `timestamp with time zone` | não | `now()` | — | — |
| 11 | `updated_at` | `timestamp with time zone` | não | `now()` | — | — |

**Constraints**

| Nome | Tipo | Definição |
|---|---|---|
| `ingredient_regulations_fk_ingredient_id_fkey` | `FK` | `FOREIGN KEY (fk_ingredient_id) REFERENCES venus.ingredients(ingredient_id) ON DELETE CASCADE` |
| `ingredient_regulations_fk_regulation_id_fkey` | `FK` | `FOREIGN KEY (fk_regulation_id) REFERENCES venus.regulations(regulation_id) ON DELETE CASCADE` |
| `ingredient_regulations_pkey` | `PK` | `PRIMARY KEY (ingredient_regulation_id)` |
| `ingredient_regulations_fk_ingredient_id_fk_regulation_id_key` | `UQ` | `UNIQUE (fk_ingredient_id, fk_regulation_id)` |

**Índices únicos**

| Nome | Definição |
|---|---|
| `ingredient_regulations_fk_ingredient_id_fk_regulation_id_key` | `CREATE UNIQUE INDEX ingredient_regulations_fk_ingredient_id_fk_regulation_id_key ON venus.ingredient_regulations USING btree (fk_ingredient_id, fk_regulation_id)` |

### `venus.ingredient_resolution_keys`

| # | Campo | Tipo | Aceita NULL? | Default | Papel | Descrição |
|---:|---|---|:---:|---|---|---|
| 1 | `normalized_key` | `text` | não | `—` | PK | — |
| 2 | `fk_ingredient_id` | `bigint` | não | `—` | PK, FK | — |
| 3 | `resolution_priority` | `smallint` | não | `99` | — | 1=INCI, 2=alias, 3=nome comum; a menor prioridade vence a resolução. |

**Constraints**

| Nome | Tipo | Definição |
|---|---|---|
| `ingredient_resolution_keys_fk_ingredient_id_fkey` | `FK` | `FOREIGN KEY (fk_ingredient_id) REFERENCES venus.ingredients(ingredient_id) ON DELETE CASCADE` |
| `ingredient_resolution_keys_pkey` | `PK` | `PRIMARY KEY (normalized_key, fk_ingredient_id)` |

### `venus.ingredient_risk_assessments`

Avaliações aprovadas dos quatro eixos de risco; zero só é evidência quando existir registro aprovado.

| # | Campo | Tipo | Aceita NULL? | Default | Papel | Descrição |
|---:|---|---|:---:|---|---|---|
| 1 | `ingredient_risk_assessment_id` | `bigint` | não | `—` | PK | — |
| 2 | `fk_ingredient_id` | `bigint` | não | `—` | UQ, FK | — |
| 3 | `dimension` | `text` | não | `—` | UQ | — |
| 4 | `score` | `smallint` | não | `—` | — | — |
| 5 | `assessment_status` | `text` | não | `'pending'::text` | — | — |
| 6 | `source_type` | `text` | não | `'manual'::text` | — | — |
| 7 | `source_reference` | `text` | não | `''::text` | — | — |
| 8 | `assessment_version` | `text` | não | `'v1'::text` | UQ | — |
| 9 | `assessed_at` | `timestamp with time zone` | não | `now()` | — | — |
| 10 | `created_at` | `timestamp with time zone` | não | `now()` | — | — |
| 11 | `updated_at` | `timestamp with time zone` | não | `now()` | — | — |
| 12 | `evidence_level` | `venus.evidence_level_enum` | não | `'low'::venus.evidence_level_enum` | — | Força da evidência que sustenta o assessment; não é o confidence_score do produto. |
| 13 | `rationale` | `text` | não | `''::text` | — | Justificativa auditável por dimensão; avaliações indiretas devem declarar os sinais usados e a ausência de concentração/dose. |
| 14 | `assessment_scope` | `text` | não | `'ingredient_baseline'::text` | — | — |

**Constraints**

| Nome | Tipo | Definição |
|---|---|---|
| `ck_ingredient_risk_assessment_source` | `CHECK` | `CHECK (assessment_status <> 'approved'::text OR btrim(source_reference) <> ''::text)` |
| `ingredient_risk_assessments_assessment_status_check` | `CHECK` | `CHECK (assessment_status = ANY (ARRAY['pending'::text, 'approved'::text, 'rejected'::text]))` |
| `ingredient_risk_assessments_dimension_check` | `CHECK` | `CHECK (dimension = ANY (ARRAY['irritation_risk_level'::text, 'comedogenicity_score'::text, 'biodegradability_level'::text, 'environmental_risk_level'::text]))` |
| `ingredient_risk_assessments_score_check` | `CHECK` | `CHECK (score >= 0 AND score <= 10)` |
| `ingredient_risk_assessments_fk_ingredient_id_fkey` | `FK` | `FOREIGN KEY (fk_ingredient_id) REFERENCES venus.ingredients(ingredient_id) ON DELETE CASCADE` |
| `ingredient_risk_assessments_pkey` | `PK` | `PRIMARY KEY (ingredient_risk_assessment_id)` |
| `ingredient_risk_assessments_fk_ingredient_id_dimension_asse_key` | `UQ` | `UNIQUE (fk_ingredient_id, dimension, assessment_version)` |

**Índices únicos**

| Nome | Definição |
|---|---|
| `ingredient_risk_assessments_fk_ingredient_id_dimension_asse_key` | `CREATE UNIQUE INDEX ingredient_risk_assessments_fk_ingredient_id_dimension_asse_key ON venus.ingredient_risk_assessments USING btree (fk_ingredient_id, dimension, assessment_version)` |

### `venus.ingredient_risk_methodologies`

Versões auditáveis das regras que convertem evidência em scores 0–10.

| # | Campo | Tipo | Aceita NULL? | Default | Papel | Descrição |
|---:|---|---|:---:|---|---|---|
| 1 | `methodology_version` | `text` | não | `—` | PK | — |
| 2 | `name` | `text` | não | `—` | — | — |
| 3 | `status` | `text` | não | `—` | — | — |
| 4 | `score_semantics` | `text` | não | `—` | — | — |
| 5 | `unknown_policy` | `text` | não | `—` | — | — |
| 6 | `source_hierarchy` | `jsonb` | não | `—` | — | — |
| 7 | `effective_from` | `date` | não | `—` | — | — |
| 8 | `created_at` | `timestamp with time zone` | não | `now()` | — | — |
| 9 | `updated_at` | `timestamp with time zone` | não | `now()` | — | — |

**Constraints**

| Nome | Tipo | Definição |
|---|---|---|
| `ingredient_risk_methodologies_status_check` | `CHECK` | `CHECK (status = ANY (ARRAY['draft'::text, 'active'::text, 'retired'::text]))` |
| `ingredient_risk_methodologies_pkey` | `PK` | `PRIMARY KEY (methodology_version)` |

### `venus.ingredient_risk_methodology_dimensions`

Definição, evidência mínima e âncoras por eixo da metodologia ativa.

| # | Campo | Tipo | Aceita NULL? | Default | Papel | Descrição |
|---:|---|---|:---:|---|---|---|
| 1 | `methodology_version` | `text` | não | `—` | PK, FK | — |
| 2 | `dimension` | `text` | não | `—` | PK | — |
| 3 | `score_direction` | `text` | não | `—` | — | — |
| 4 | `definition` | `text` | não | `—` | — | — |
| 5 | `required_evidence` | `jsonb` | não | `—` | — | — |
| 6 | `anchors` | `jsonb` | não | `—` | — | — |

**Constraints**

| Nome | Tipo | Definição |
|---|---|---|
| `ingredient_risk_methodology_dimensions_dimension_check` | `CHECK` | `CHECK (dimension = ANY (ARRAY['irritation_risk_level'::text, 'comedogenicity_score'::text, 'biodegradability_level'::text, 'environmental_risk_level'::text]))` |
| `ingredient_risk_methodology_dimensions_methodology_version_fkey` | `FK` | `FOREIGN KEY (methodology_version) REFERENCES venus.ingredient_risk_methodologies(methodology_version) ON DELETE RESTRICT` |
| `ingredient_risk_methodology_dimensions_pkey` | `PK` | `PRIMARY KEY (methodology_version, dimension)` |

### `venus.ingredients`

| # | Campo | Tipo | Aceita NULL? | Default | Papel | Descrição |
|---:|---|---|:---:|---|---|---|
| 1 | `ingredient_id` | `bigint` | não | `—` | PK | — |
| 2 | `fk_ingredient_category_id` | `bigint` | não | `—` | FK | — |
| 3 | `inci_name` | `text` | não | `—` | UQ | — |
| 4 | `common_name` | `text` | não | `''::text` | — | — |
| 5 | `function_summary` | `text` | não | `''::text` | — | — |
| 6 | `description` | `text` | não | `''::text` | — | — |
| 7 | `biodegradability_level` | `smallint` | não | `0` | — | — |
| 8 | `irritation_risk_level` | `smallint` | não | `0` | — | — |
| 9 | `comedogenicity_score` | `smallint` | não | `0` | — | — |
| 10 | `environmental_risk_level` | `smallint` | não | `0` | — | — |
| 11 | `safety_summary` | `text` | não | `''::text` | — | — |
| 12 | `scientific_confidence` | `smallint` | não | `0` | — | — |
| 13 | `source_type` | `venus.source_type_enum` | não | `'import'::venus.source_type_enum` | — | — |
| 14 | `source_reference` | `text` | sim | `—` | — | — |
| 15 | `created_at` | `timestamp with time zone` | não | `now()` | — | — |
| 16 | `updated_at` | `timestamp with time zone` | não | `now()` | — | — |
| 17 | `scientific_confidence_state` | `text` | não | `'default'::text` | — | default = fallback 1 sem avaliação específica; derived = valor calculado por regra; curated = evidência específica revisada. |

**Constraints**

| Nome | Tipo | Definição |
|---|---|---|
| `ck_ingredients_scientific_confidence_range` | `CHECK` | `CHECK (scientific_confidence >= 0 AND scientific_confidence <= 100)` |
| `ck_ingredients_scientific_confidence_state` | `CHECK` | `CHECK (scientific_confidence_state = ANY (ARRAY['default'::text, 'derived'::text, 'curated'::text]))` |
| `ingredients_fk_ingredient_category_id_fkey` | `FK` | `FOREIGN KEY (fk_ingredient_category_id) REFERENCES venus.ingredient_categories(ingredient_category_id) ON DELETE RESTRICT` |
| `ingredients_pkey` | `PK` | `PRIMARY KEY (ingredient_id)` |
| `ingredients_inci_name_key` | `UQ` | `UNIQUE (inci_name)` |

**Índices únicos**

| Nome | Definição |
|---|---|
| `ingredients_inci_name_key` | `CREATE UNIQUE INDEX ingredients_inci_name_key ON venus.ingredients USING btree (inci_name)` |

### `venus.media_assets`

Canonical registry of Cloudinary media assets. Binary content is stored outside PostgreSQL.

| # | Campo | Tipo | Aceita NULL? | Default | Papel | Descrição |
|---:|---|---|:---:|---|---|---|
| 1 | `media_asset_id` | `bigint` | não | `—` | PK | — |
| 2 | `fk_user_id` | `bigint` | sim | `—` | FK | — |
| 3 | `fk_product_version_id` | `bigint` | sim | `—` | FK | — |
| 4 | `purpose` | `text` | não | `—` | — | — |
| 5 | `provider` | `text` | não | `'cloudinary'::text` | UQ | — |
| 6 | `resource_type` | `text` | não | `'image'::text` | — | — |
| 7 | `delivery_type` | `text` | não | `'upload'::text` | — | Cloudinary delivery type: upload for public delivery or authenticated for private delivery. |
| 8 | `public_id` | `text` | não | `—` | UQ | Cloudinary public_id. Canonical identifier controlled by the backend for replace/delete/delivery. |
| 9 | `asset_id` | `text` | sim | `—` | — | Cloudinary immutable asset_id when returned by the Upload API. |
| 10 | `version` | `bigint` | sim | `—` | — | — |
| 11 | `secure_url` | `text` | sim | `—` | — | HTTPS delivery URL returned by Cloudinary. Cached metadata; public_id remains canonical. |
| 12 | `format` | `text` | sim | `—` | — | — |
| 13 | `width` | `integer` | sim | `—` | — | — |
| 14 | `height` | `integer` | sim | `—` | — | — |
| 15 | `bytes` | `bigint` | sim | `—` | — | — |
| 16 | `folder` | `text` | sim | `—` | — | — |
| 17 | `original_filename` | `text` | sim | `—` | — | — |
| 18 | `alt_text` | `text` | sim | `—` | — | — |
| 19 | `sort_order` | `integer` | não | `0` | — | — |
| 20 | `status` | `text` | não | `'active'::text` | — | Application lifecycle: pending, active, deleted or failed. |
| 21 | `created_at` | `timestamp with time zone` | não | `now()` | — | — |
| 22 | `updated_at` | `timestamp with time zone` | não | `now()` | — | — |
| 23 | `fk_user_list_id` | `bigint` | sim | `—` | FK | — |

**Constraints**

| Nome | Tipo | Definição |
|---|---|---|
| `ck_media_assets_dono` | `CHECK` | `CHECK (fk_user_id IS NOT NULL AND fk_product_version_id IS NULL AND fk_user_list_id IS NULL AND purpose = 'avatar'::text OR fk_user_id IS NULL AND fk_product_version_id IS NOT NULL AND fk_user_list_id IS NULL AND purpose = 'product_photo'::text OR fk_user_id IS NULL AND fk_product_version_id IS NULL AND fk_user_list_id IS NOT NULL AND purpose = 'list_cover'::text)` |
| `media_assets_bytes_check` | `CHECK` | `CHECK (bytes IS NULL OR bytes >= 0)` |
| `media_assets_delivery_type_check` | `CHECK` | `CHECK (delivery_type = ANY (ARRAY['upload'::text, 'authenticated'::text]))` |
| `media_assets_height_check` | `CHECK` | `CHECK (height IS NULL OR height > 0)` |
| `media_assets_provider_check` | `CHECK` | `CHECK (provider = 'cloudinary'::text)` |
| `media_assets_purpose_check` | `CHECK` | `CHECK (purpose = ANY (ARRAY['avatar'::text, 'product_photo'::text, 'list_cover'::text]))` |
| `media_assets_resource_type_check` | `CHECK` | `CHECK (resource_type = 'image'::text)` |
| `media_assets_sort_order_check` | `CHECK` | `CHECK (sort_order >= 0)` |
| `media_assets_status_check` | `CHECK` | `CHECK (status = ANY (ARRAY['pending'::text, 'active'::text, 'deleted'::text, 'failed'::text]))` |
| `media_assets_width_check` | `CHECK` | `CHECK (width IS NULL OR width > 0)` |
| `media_assets_fk_product_version_id_fkey` | `FK` | `FOREIGN KEY (fk_product_version_id) REFERENCES venus.product_versions(product_version_id) ON DELETE CASCADE` |
| `media_assets_fk_user_id_fkey` | `FK` | `FOREIGN KEY (fk_user_id) REFERENCES venus.users(user_id) ON DELETE CASCADE` |
| `media_assets_fk_user_list_id_fkey` | `FK` | `FOREIGN KEY (fk_user_list_id) REFERENCES venus.user_lists(user_list_id) ON DELETE CASCADE` |
| `media_assets_pkey` | `PK` | `PRIMARY KEY (media_asset_id)` |
| `uq_media_assets_provider_public_id` | `UQ` | `UNIQUE (provider, public_id)` |

**Índices únicos**

| Nome | Definição |
|---|---|
| `uq_media_assets_provider_public_id` | `CREATE UNIQUE INDEX uq_media_assets_provider_public_id ON venus.media_assets USING btree (provider, public_id)` |
| `ux_media_user_avatar` | `CREATE UNIQUE INDEX ux_media_user_avatar ON venus.media_assets USING btree (fk_user_id) WHERE ((purpose = 'avatar'::text) AND (status = ANY (ARRAY['pending'::text, 'active'::text])))` |
| `ux_media_user_list_cover` | `CREATE UNIQUE INDEX ux_media_user_list_cover ON venus.media_assets USING btree (fk_user_list_id) WHERE ((purpose = 'list_cover'::text) AND (status = ANY (ARRAY['pending'::text, 'active'::text])))` |

### `venus.packaging`

| # | Campo | Tipo | Aceita NULL? | Default | Papel | Descrição |
|---:|---|---|:---:|---|---|---|
| 1 | `packaging_id` | `bigint` | não | `—` | PK | — |
| 2 | `fk_product_version_id` | `bigint` | não | `—` | UQ, FK | — |
| 3 | `material` | `venus.packaging_material_enum` | não | `'other'::venus.packaging_material_enum` | — | — |
| 4 | `material_detail` | `text` | não | `''::text` | — | — |
| 5 | `packaging_format` | `venus.packaging_format_enum` | não | `'other'::venus.packaging_format_enum` | — | — |
| 6 | `is_recyclable` | `boolean` | não | `false` | — | — |
| 7 | `is_refillable` | `boolean` | não | `false` | — | — |
| 8 | `is_biodegradable` | `boolean` | não | `false` | — | — |
| 9 | `recycled_content_percentage` | `numeric(5,2)` | sim | `—` | — | — |
| 10 | `confidence_score` | `smallint` | não | `0` | — | — |
| 11 | `source_type` | `venus.source_type_enum` | não | `'admin'::venus.source_type_enum` | — | — |
| 12 | `source_reference` | `text` | sim | `—` | — | — |
| 13 | `was_manual_verified` | `boolean` | não | `false` | — | — |
| 14 | `created_at` | `timestamp with time zone` | não | `now()` | — | — |
| 15 | `updated_at` | `timestamp with time zone` | não | `now()` | — | — |

**Constraints**

| Nome | Tipo | Definição |
|---|---|---|
| `packaging_fk_product_version_id_fkey` | `FK` | `FOREIGN KEY (fk_product_version_id) REFERENCES venus.product_versions(product_version_id) ON DELETE CASCADE` |
| `packaging_pkey` | `PK` | `PRIMARY KEY (packaging_id)` |
| `packaging_fk_product_version_id_key` | `UQ` | `UNIQUE (fk_product_version_id)` |

**Índices únicos**

| Nome | Definição |
|---|---|
| `packaging_fk_product_version_id_key` | `CREATE UNIQUE INDEX packaging_fk_product_version_id_key ON venus.packaging USING btree (fk_product_version_id)` |

### `venus.packaging_evaluation_policies`

| # | Campo | Tipo | Aceita NULL? | Default | Papel | Descrição |
|---:|---|---|:---:|---|---|---|
| 1 | `policy_version` | `text` | não | `—` | PK | — |
| 2 | `status` | `text` | não | `—` | — | — |
| 3 | `missing_packaging_policy` | `text` | não | `—` | — | — |
| 4 | `unverified_packaging_policy` | `text` | não | `—` | — | — |
| 5 | `source_hierarchy` | `jsonb` | não | `—` | — | — |
| 6 | `effective_from` | `date` | não | `—` | — | — |
| 7 | `created_at` | `timestamp with time zone` | não | `now()` | — | — |
| 8 | `updated_at` | `timestamp with time zone` | não | `now()` | — | — |

**Constraints**

| Nome | Tipo | Definição |
|---|---|---|
| `packaging_evaluation_policies_status_check` | `CHECK` | `CHECK (status = ANY (ARRAY['active'::text, 'retired'::text]))` |
| `packaging_evaluation_policies_pkey` | `PK` | `PRIMARY KEY (policy_version)` |

### `venus.personalized_scores`

| # | Campo | Tipo | Aceita NULL? | Default | Papel | Descrição |
|---:|---|---|:---:|---|---|---|
| 1 | `personalized_score_id` | `bigint` | não | `—` | PK | — |
| 2 | `fk_user_id` | `bigint` | não | `—` | UQ, FK | — |
| 3 | `fk_product_version_id` | `bigint` | não | `—` | UQ, FK | — |
| 4 | `fk_analysis_result_id` | `bigint` | não | `—` | FK | — |
| 5 | `fk_scoring_model_id` | `bigint` | não | `—` | UQ, FK | — |
| 6 | `final_score` | `integer` | não | `0` | — | — |
| 7 | `compatibility_percentage` | `numeric(5,2)` | sim | `—` | — | — |
| 8 | `risk_level` | `venus.risk_level_enum` | não | `'low'::venus.risk_level_enum` | — | — |
| 9 | `recommendation_level` | `venus.recommendation_level_enum` | não | `'acceptable'::venus.recommendation_level_enum` | — | — |
| 10 | `summary` | `text` | não | `''::text` | — | — |
| 11 | `created_at` | `timestamp with time zone` | não | `now()` | — | — |
| 12 | `updated_at` | `timestamp with time zone` | não | `now()` | — | — |

**Constraints**

| Nome | Tipo | Definição |
|---|---|---|
| `personalized_scores_fk_analysis_result_id_fkey` | `FK` | `FOREIGN KEY (fk_analysis_result_id) REFERENCES venus.analysis_results(analysis_result_id) ON DELETE CASCADE` |
| `personalized_scores_fk_product_version_id_fkey` | `FK` | `FOREIGN KEY (fk_product_version_id) REFERENCES venus.product_versions(product_version_id) ON DELETE CASCADE` |
| `personalized_scores_fk_scoring_model_id_fkey` | `FK` | `FOREIGN KEY (fk_scoring_model_id) REFERENCES venus.scoring_models(scoring_model_id) ON DELETE RESTRICT` |
| `personalized_scores_fk_user_id_fkey` | `FK` | `FOREIGN KEY (fk_user_id) REFERENCES venus.users(user_id) ON DELETE CASCADE` |
| `personalized_scores_pkey` | `PK` | `PRIMARY KEY (personalized_score_id)` |
| `personalized_scores_fk_user_id_fk_product_version_id_fk_sco_key` | `UQ` | `UNIQUE (fk_user_id, fk_product_version_id, fk_scoring_model_id)` |

**Índices únicos**

| Nome | Definição |
|---|---|
| `personalized_scores_fk_user_id_fk_product_version_id_fk_sco_key` | `CREATE UNIQUE INDEX personalized_scores_fk_user_id_fk_product_version_id_fk_sco_key ON venus.personalized_scores USING btree (fk_user_id, fk_product_version_id, fk_scoring_model_id)` |

### `venus.product_categories`

| # | Campo | Tipo | Aceita NULL? | Default | Papel | Descrição |
|---:|---|---|:---:|---|---|---|
| 1 | `product_category_id` | `bigint` | não | `—` | PK | — |
| 2 | `name` | `text` | não | `—` | UQ | — |
| 3 | `description` | `text` | não | `''::text` | — | — |
| 4 | `created_at` | `timestamp with time zone` | não | `now()` | — | — |
| 5 | `updated_at` | `timestamp with time zone` | não | `now()` | — | — |

**Constraints**

| Nome | Tipo | Definição |
|---|---|---|
| `product_categories_pkey` | `PK` | `PRIMARY KEY (product_category_id)` |
| `product_categories_name_key` | `UQ` | `UNIQUE (name)` |

**Índices únicos**

| Nome | Definição |
|---|---|
| `product_categories_name_key` | `CREATE UNIQUE INDEX product_categories_name_key ON venus.product_categories USING btree (name)` |

### `venus.product_claims`

| # | Campo | Tipo | Aceita NULL? | Default | Papel | Descrição |
|---:|---|---|:---:|---|---|---|
| 1 | `product_claim_id` | `bigint` | não | `—` | PK | — |
| 2 | `fk_product_version_id` | `bigint` | não | `—` | UQ, FK | — |
| 3 | `fk_claim_id` | `bigint` | não | `—` | UQ, FK | — |
| 4 | `was_verified` | `boolean` | não | `false` | — | — |
| 5 | `verified_by` | `text` | sim | `—` | — | — |
| 6 | `verified_at` | `timestamp with time zone` | sim | `—` | — | — |
| 7 | `source_type` | `venus.source_type_enum` | não | `'admin'::venus.source_type_enum` | — | — |
| 8 | `source_reference` | `text` | sim | `—` | — | — |
| 9 | `created_at` | `timestamp with time zone` | não | `now()` | — | — |
| 10 | `updated_at` | `timestamp with time zone` | não | `now()` | — | — |

**Constraints**

| Nome | Tipo | Definição |
|---|---|---|
| `product_claims_fk_claim_id_fkey` | `FK` | `FOREIGN KEY (fk_claim_id) REFERENCES venus.claims(claim_id) ON DELETE RESTRICT` |
| `product_claims_fk_product_version_id_fkey` | `FK` | `FOREIGN KEY (fk_product_version_id) REFERENCES venus.product_versions(product_version_id) ON DELETE CASCADE` |
| `product_claims_pkey` | `PK` | `PRIMARY KEY (product_claim_id)` |
| `product_claims_fk_product_version_id_fk_claim_id_key` | `UQ` | `UNIQUE (fk_product_version_id, fk_claim_id)` |

**Índices únicos**

| Nome | Definição |
|---|---|
| `product_claims_fk_product_version_id_fk_claim_id_key` | `CREATE UNIQUE INDEX product_claims_fk_product_version_id_fk_claim_id_key ON venus.product_claims USING btree (fk_product_version_id, fk_claim_id)` |

### `venus.product_composition_receipts`

Recibo da composição bruta, resolução e validação usados para liberar um produto para score.

| # | Campo | Tipo | Aceita NULL? | Default | Papel | Descrição |
|---:|---|---|:---:|---|---|---|
| 1 | `product_composition_receipt_id` | `bigint` | não | `—` | PK, UQ | — |
| 2 | `fk_product_version_id` | `bigint` | não | `—` | UQ, FK | — |
| 3 | `source_type` | `text` | não | `—` | — | — |
| 4 | `source_reference` | `text` | não | `''::text` | — | — |
| 5 | `raw_ingredients_text` | `text` | não | `''::text` | — | — |
| 6 | `formula_hash` | `text` | sim | `—` | — | — |
| 7 | `validation_status` | `text` | não | `—` | — | — |
| 8 | `expected_count` | `integer` | não | `0` | — | — |
| 9 | `resolved_count` | `integer` | não | `0` | — | — |
| 10 | `unresolved_count` | `integer` | não | `0` | — | — |
| 11 | `is_current` | `boolean` | não | `true` | — | — |
| 12 | `validated_at` | `timestamp with time zone` | sim | `—` | — | — |
| 13 | `created_at` | `timestamp with time zone` | não | `now()` | — | — |
| 14 | `updated_at` | `timestamp with time zone` | não | `now()` | — | — |

**Constraints**

| Nome | Tipo | Definição |
|---|---|---|
| `ck_composition_receipt_counts` | `CHECK` | `CHECK ((resolved_count + unresolved_count) <= expected_count OR validation_status <> 'VALID'::text)` |
| `ck_composition_receipt_valid` | `CHECK` | `CHECK (validation_status <> 'VALID'::text OR btrim(source_reference) <> ''::text AND btrim(raw_ingredients_text) <> ''::text AND expected_count > 0 AND expected_count = resolved_count AND unresolved_count = 0)` |
| `product_composition_receipts_expected_count_check` | `CHECK` | `CHECK (expected_count >= 0)` |
| `product_composition_receipts_resolved_count_check` | `CHECK` | `CHECK (resolved_count >= 0)` |
| `product_composition_receipts_unresolved_count_check` | `CHECK` | `CHECK (unresolved_count >= 0)` |
| `product_composition_receipts_validation_status_check` | `CHECK` | `CHECK (validation_status = ANY (ARRAY['VALID'::text, 'WARNING'::text, 'INVALID'::text, 'LEGACY_UNVERIFIED'::text]))` |
| `product_composition_receipts_fk_product_version_id_fkey` | `FK` | `FOREIGN KEY (fk_product_version_id) REFERENCES venus.product_versions(product_version_id) ON DELETE CASCADE` |
| `product_composition_receipts_pkey` | `PK` | `PRIMARY KEY (product_composition_receipt_id)` |
| `product_composition_receipts_fk_product_version_id_product__key` | `UQ` | `UNIQUE (fk_product_version_id, product_composition_receipt_id)` |

**Índices únicos**

| Nome | Definição |
|---|---|
| `product_composition_receipts_fk_product_version_id_product__key` | `CREATE UNIQUE INDEX product_composition_receipts_fk_product_version_id_product__key ON venus.product_composition_receipts USING btree (fk_product_version_id, product_composition_receipt_id)` |
| `ux_product_composition_receipts_current` | `CREATE UNIQUE INDEX ux_product_composition_receipts_current ON venus.product_composition_receipts USING btree (fk_product_version_id) WHERE is_current` |

### `venus.product_dimension_assessments`

Aprovação explícita das dimensões de performance e ética antes do score geral.

| # | Campo | Tipo | Aceita NULL? | Default | Papel | Descrição |
|---:|---|---|:---:|---|---|---|
| 1 | `product_dimension_assessment_id` | `bigint` | não | `—` | PK | — |
| 2 | `fk_product_version_id` | `bigint` | não | `—` | UQ, FK | — |
| 3 | `dimension` | `text` | não | `—` | UQ | — |
| 4 | `assessment_status` | `text` | não | `'pending'::text` | — | — |
| 5 | `source_type` | `text` | não | `'manual'::text` | — | — |
| 6 | `source_reference` | `text` | não | `''::text` | — | — |
| 7 | `assessment_version` | `text` | não | `'v1'::text` | UQ | — |
| 8 | `assessed_at` | `timestamp with time zone` | não | `now()` | — | — |
| 9 | `created_at` | `timestamp with time zone` | não | `now()` | — | — |
| 10 | `updated_at` | `timestamp with time zone` | não | `now()` | — | — |

**Constraints**

| Nome | Tipo | Definição |
|---|---|---|
| `ck_product_dimension_assessment_source` | `CHECK` | `CHECK (assessment_status <> 'approved'::text OR btrim(source_reference) <> ''::text)` |
| `product_dimension_assessments_assessment_status_check` | `CHECK` | `CHECK (assessment_status = ANY (ARRAY['pending'::text, 'approved'::text, 'rejected'::text]))` |
| `product_dimension_assessments_dimension_check` | `CHECK` | `CHECK (dimension = ANY (ARRAY['performance'::text, 'ethical'::text]))` |
| `product_dimension_assessments_fk_product_version_id_fkey` | `FK` | `FOREIGN KEY (fk_product_version_id) REFERENCES venus.product_versions(product_version_id) ON DELETE CASCADE` |
| `product_dimension_assessments_pkey` | `PK` | `PRIMARY KEY (product_dimension_assessment_id)` |
| `product_dimension_assessments_fk_product_version_id_dimensi_key` | `UQ` | `UNIQUE (fk_product_version_id, dimension, assessment_version)` |

**Índices únicos**

| Nome | Definição |
|---|---|
| `product_dimension_assessments_fk_product_version_id_dimensi_key` | `CREATE UNIQUE INDEX product_dimension_assessments_fk_product_version_id_dimensi_key ON venus.product_dimension_assessments USING btree (fk_product_version_id, dimension, assessment_version)` |

### `venus.product_ingredient_resolution_issues`

Tokens OCR não encontrados ou ambíguos; só os casos sem resolução permanecem em needs_review.

| # | Campo | Tipo | Aceita NULL? | Default | Papel | Descrição |
|---:|---|---|:---:|---|---|---|
| 1 | `product_ingredient_resolution_issue_id` | `bigint` | não | `—` | PK | — |
| 2 | `fk_product_version_id` | `bigint` | não | `—` | UQ, FK | — |
| 3 | `token_position` | `integer` | não | `—` | UQ | — |
| 4 | `raw_token` | `text` | não | `—` | — | — |
| 5 | `issue_type` | `text` | não | `—` | — | — |
| 6 | `source_reference` | `text` | sim | `—` | — | — |
| 7 | `created_at` | `timestamp with time zone` | não | `now()` | — | — |

**Constraints**

| Nome | Tipo | Definição |
|---|---|---|
| `product_ingredient_resolution_issues_issue_type_check` | `CHECK` | `CHECK (issue_type = ANY (ARRAY['NOT_FOUND'::text, 'AMBIGUOUS'::text]))` |
| `product_ingredient_resolution_issues_fk_product_version_id_fkey` | `FK` | `FOREIGN KEY (fk_product_version_id) REFERENCES venus.product_versions(product_version_id) ON DELETE CASCADE` |
| `product_ingredient_resolution_issues_pkey` | `PK` | `PRIMARY KEY (product_ingredient_resolution_issue_id)` |
| `product_ingredient_resolution_fk_product_version_id_token_p_key` | `UQ` | `UNIQUE (fk_product_version_id, token_position)` |

**Índices únicos**

| Nome | Definição |
|---|---|
| `product_ingredient_resolution_fk_product_version_id_token_p_key` | `CREATE UNIQUE INDEX product_ingredient_resolution_fk_product_version_id_token_p_key ON venus.product_ingredient_resolution_issues USING btree (fk_product_version_id, token_position)` |

### `venus.product_ingredients`

| # | Campo | Tipo | Aceita NULL? | Default | Papel | Descrição |
|---:|---|---|:---:|---|---|---|
| 1 | `product_ingredient_id` | `bigint` | não | `—` | PK | — |
| 2 | `fk_product_version_id` | `bigint` | não | `—` | UQ, FK | — |
| 3 | `fk_ingredient_id` | `bigint` | não | `—` | UQ, FK | — |
| 4 | `position` | `integer` | não | `—` | UQ | — |
| 5 | `created_at` | `timestamp with time zone` | não | `now()` | — | — |
| 6 | `updated_at` | `timestamp with time zone` | não | `now()` | — | — |

**Constraints**

| Nome | Tipo | Definição |
|---|---|---|
| `product_ingredients_fk_ingredient_id_fkey` | `FK` | `FOREIGN KEY (fk_ingredient_id) REFERENCES venus.ingredients(ingredient_id) ON DELETE RESTRICT` |
| `product_ingredients_fk_product_version_id_fkey` | `FK` | `FOREIGN KEY (fk_product_version_id) REFERENCES venus.product_versions(product_version_id) ON DELETE CASCADE` |
| `product_ingredients_pkey` | `PK` | `PRIMARY KEY (product_ingredient_id)` |
| `product_ingredients_fk_product_version_id_fk_ingredient_id_key` | `UQ` | `UNIQUE (fk_product_version_id, fk_ingredient_id)` |
| `product_ingredients_fk_product_version_id_position_key` | `UQ` | `UNIQUE (fk_product_version_id, "position")` |

**Índices únicos**

| Nome | Definição |
|---|---|
| `product_ingredients_fk_product_version_id_fk_ingredient_id_key` | `CREATE UNIQUE INDEX product_ingredients_fk_product_version_id_fk_ingredient_id_key ON venus.product_ingredients USING btree (fk_product_version_id, fk_ingredient_id)` |
| `product_ingredients_fk_product_version_id_position_key` | `CREATE UNIQUE INDEX product_ingredients_fk_product_version_id_position_key ON venus.product_ingredients USING btree (fk_product_version_id, "position")` |

### `venus.product_labels`

| # | Campo | Tipo | Aceita NULL? | Default | Papel | Descrição |
|---:|---|---|:---:|---|---|---|
| 1 | `product_label_id` | `bigint` | não | `—` | PK | — |
| 2 | `fk_product_version_id` | `bigint` | não | `—` | UQ, FK | — |
| 3 | `normalized_text` | `text` | não | `''::text` | — | — |
| 4 | `language` | `text` | não | `'pt-BR'::text` | — | — |
| 5 | `source_type` | `venus.source_type_enum` | não | `'ocr'::venus.source_type_enum` | — | — |
| 6 | `source_reference` | `text` | sim | `—` | — | — |
| 7 | `created_at` | `timestamp with time zone` | não | `now()` | — | — |
| 8 | `updated_at` | `timestamp with time zone` | não | `now()` | — | — |

**Constraints**

| Nome | Tipo | Definição |
|---|---|---|
| `product_labels_fk_product_version_id_fkey` | `FK` | `FOREIGN KEY (fk_product_version_id) REFERENCES venus.product_versions(product_version_id) ON DELETE CASCADE` |
| `product_labels_pkey` | `PK` | `PRIMARY KEY (product_label_id)` |
| `product_labels_fk_product_version_id_key` | `UQ` | `UNIQUE (fk_product_version_id)` |

**Índices únicos**

| Nome | Definição |
|---|---|
| `product_labels_fk_product_version_id_key` | `CREATE UNIQUE INDEX product_labels_fk_product_version_id_key ON venus.product_labels USING btree (fk_product_version_id)` |

### `venus.product_score_history`

Histórico de scores removidos porque a entrada deixou de atender aos critérios de prontidão.

| # | Campo | Tipo | Aceita NULL? | Default | Papel | Descrição |
|---:|---|---|:---:|---|---|---|
| 1 | `product_score_history_id` | `bigint` | não | `—` | PK | — |
| 2 | `source_product_score_id` | `bigint` | sim | `—` | — | — |
| 3 | `fk_product_version_id` | `bigint` | não | `—` | — | — |
| 4 | `fk_scoring_model_id` | `bigint` | não | `—` | — | — |
| 5 | `overall_score` | `integer` | não | `—` | — | — |
| 6 | `health_score` | `integer` | sim | `—` | — | — |
| 7 | `environmental_score` | `integer` | sim | `—` | — | — |
| 8 | `ethical_score` | `integer` | sim | `—` | — | — |
| 9 | `performance_score` | `integer` | sim | `—` | — | — |
| 10 | `transparency_score` | `integer` | sim | `—` | — | — |
| 11 | `confidence_score` | `smallint` | sim | `—` | — | — |
| 12 | `calculated_at` | `timestamp with time zone` | sim | `—` | — | — |
| 13 | `invalidated_at` | `timestamp with time zone` | não | `now()` | — | — |
| 14 | `invalidation_reason` | `text` | não | `—` | — | — |

**Constraints**

| Nome | Tipo | Definição |
|---|---|---|
| `product_score_history_pkey` | `PK` | `PRIMARY KEY (product_score_history_id)` |

### `venus.product_scores`

| # | Campo | Tipo | Aceita NULL? | Default | Papel | Descrição |
|---:|---|---|:---:|---|---|---|
| 1 | `product_score_id` | `bigint` | não | `—` | PK | — |
| 2 | `fk_product_version_id` | `bigint` | não | `—` | UQ, FK | — |
| 3 | `fk_scoring_model_id` | `bigint` | não | `—` | UQ, FK | — |
| 4 | `overall_score` | `integer` | não | `0` | — | — |
| 5 | `health_score` | `integer` | sim | `—` | — | — |
| 6 | `environmental_score` | `integer` | sim | `—` | — | — |
| 7 | `ethical_score` | `integer` | não | `0` | — | — |
| 8 | `performance_score` | `integer` | sim | `—` | — | — |
| 9 | `transparency_score` | `integer` | sim | `—` | — | — |
| 10 | `confidence_score` | `smallint` | não | `1` | — | — |
| 11 | `calculated_at` | `timestamp with time zone` | não | `now()` | — | — |
| 12 | `created_at` | `timestamp with time zone` | não | `now()` | — | — |
| 13 | `updated_at` | `timestamp with time zone` | não | `now()` | — | — |

**Constraints**

| Nome | Tipo | Definição |
|---|---|---|
| `ck_product_scores_confidence_score_range` | `CHECK` | `CHECK (confidence_score >= 1 AND confidence_score <= 100)` |
| `product_scores_fk_product_version_id_fkey` | `FK` | `FOREIGN KEY (fk_product_version_id) REFERENCES venus.product_versions(product_version_id) ON DELETE CASCADE` |
| `product_scores_fk_scoring_model_id_fkey` | `FK` | `FOREIGN KEY (fk_scoring_model_id) REFERENCES venus.scoring_models(scoring_model_id) ON DELETE RESTRICT` |
| `product_scores_pkey` | `PK` | `PRIMARY KEY (product_score_id)` |
| `product_scores_fk_product_version_id_fk_scoring_model_id_key` | `UQ` | `UNIQUE (fk_product_version_id, fk_scoring_model_id)` |

**Índices únicos**

| Nome | Definição |
|---|---|
| `product_scores_fk_product_version_id_fk_scoring_model_id_key` | `CREATE UNIQUE INDEX product_scores_fk_product_version_id_fk_scoring_model_id_key ON venus.product_scores USING btree (fk_product_version_id, fk_scoring_model_id)` |

### `venus.product_versions`

| # | Campo | Tipo | Aceita NULL? | Default | Papel | Descrição |
|---:|---|---|:---:|---|---|---|
| 1 | `product_version_id` | `bigint` | não | `—` | PK | — |
| 2 | `fk_product_id` | `bigint` | não | `—` | UQ, FK | — |
| 3 | `version_name` | `text` | não | `—` | — | — |
| 4 | `display_name` | `text` | não | `—` | — | — |
| 5 | `status` | `venus.version_status_enum` | não | `'pending'::venus.version_status_enum` | — | — |
| 6 | `is_current` | `boolean` | não | `false` | — | — |
| 7 | `formula_signature` | `text` | não | `—` | UQ | — |
| 8 | `detected_by` | `venus.source_type_enum` | não | `'system'::venus.source_type_enum` | — | — |
| 9 | `effective_from` | `date` | não | `CURRENT_DATE` | — | — |
| 10 | `effective_to` | `date` | sim | `—` | — | — |
| 11 | `created_at` | `timestamp with time zone` | não | `now()` | — | — |
| 12 | `updated_at` | `timestamp with time zone` | não | `now()` | — | — |

**Constraints**

| Nome | Tipo | Definição |
|---|---|---|
| `product_versions_fk_product_id_fkey` | `FK` | `FOREIGN KEY (fk_product_id) REFERENCES venus.products(product_id) ON DELETE CASCADE` |
| `product_versions_pkey` | `PK` | `PRIMARY KEY (product_version_id)` |
| `trg_enforce_product_version_score_readiness` | `t` | `TRIGGER DEFERRABLE INITIALLY DEFERRED` |
| `product_versions_fk_product_id_formula_signature_key` | `UQ` | `UNIQUE (fk_product_id, formula_signature)` |

**Índices únicos**

| Nome | Definição |
|---|---|
| `product_versions_fk_product_id_formula_signature_key` | `CREATE UNIQUE INDEX product_versions_fk_product_id_formula_signature_key ON venus.product_versions USING btree (fk_product_id, formula_signature)` |
| `ux_product_versions_current` | `CREATE UNIQUE INDEX ux_product_versions_current ON venus.product_versions USING btree (fk_product_id) WHERE is_current` |

### `venus.products`

| # | Campo | Tipo | Aceita NULL? | Default | Papel | Descrição |
|---:|---|---|:---:|---|---|---|
| 1 | `product_id` | `bigint` | não | `—` | PK | — |
| 2 | `fk_brand_id` | `bigint` | não | `—` | FK | — |
| 3 | `fk_product_category_id` | `bigint` | não | `—` | FK | — |
| 4 | `name` | `text` | não | `—` | — | — |
| 5 | `description` | `text` | não | `''::text` | — | — |
| 6 | `slug` | `text` | não | `—` | UQ | — |
| 7 | `is_active` | `boolean` | não | `true` | — | — |
| 8 | `created_at` | `timestamp with time zone` | não | `now()` | — | — |
| 9 | `updated_at` | `timestamp with time zone` | não | `now()` | — | — |

**Constraints**

| Nome | Tipo | Definição |
|---|---|---|
| `products_fk_brand_id_fkey` | `FK` | `FOREIGN KEY (fk_brand_id) REFERENCES venus.brands(brand_id) ON DELETE RESTRICT` |
| `products_fk_product_category_id_fkey` | `FK` | `FOREIGN KEY (fk_product_category_id) REFERENCES venus.product_categories(product_category_id) ON DELETE RESTRICT` |
| `products_pkey` | `PK` | `PRIMARY KEY (product_id)` |
| `products_slug_key` | `UQ` | `UNIQUE (slug)` |

**Índices únicos**

| Nome | Definição |
|---|---|
| `products_slug_key` | `CREATE UNIQUE INDEX products_slug_key ON venus.products USING btree (slug)` |

### `venus.profile_tags`

| # | Campo | Tipo | Aceita NULL? | Default | Papel | Descrição |
|---:|---|---|:---:|---|---|---|
| 1 | `profile_tag_id` | `bigint` | não | `—` | PK | — |
| 2 | `name` | `text` | não | `—` | UQ | — |
| 3 | `description` | `text` | não | `''::text` | — | — |
| 4 | `slug` | `text` | não | `—` | UQ | — |
| 5 | `category` | `venus.profile_tag_category_enum` | não | `'other'::venus.profile_tag_category_enum` | — | — |
| 6 | `created_at` | `timestamp with time zone` | não | `now()` | — | — |
| 7 | `updated_at` | `timestamp with time zone` | não | `now()` | — | — |

**Constraints**

| Nome | Tipo | Definição |
|---|---|---|
| `profile_tags_pkey` | `PK` | `PRIMARY KEY (profile_tag_id)` |
| `profile_tags_name_key` | `UQ` | `UNIQUE (name)` |
| `profile_tags_slug_key` | `UQ` | `UNIQUE (slug)` |

**Índices únicos**

| Nome | Definição |
|---|---|
| `profile_tags_name_key` | `CREATE UNIQUE INDEX profile_tags_name_key ON venus.profile_tags USING btree (name)` |
| `profile_tags_slug_key` | `CREATE UNIQUE INDEX profile_tags_slug_key ON venus.profile_tags USING btree (slug)` |

### `venus.recommendations`

| # | Campo | Tipo | Aceita NULL? | Default | Papel | Descrição |
|---:|---|---|:---:|---|---|---|
| 1 | `recommendation_id` | `bigint` | não | `—` | PK | — |
| 2 | `fk_user_id` | `bigint` | não | `—` | UQ, FK | — |
| 3 | `fk_profile_tag_id` | `bigint` | não | `—` | UQ, FK | — |
| 4 | `fk_product_version_id` | `bigint` | não | `—` | UQ, FK | — |
| 5 | `fk_analysis_result_id` | `bigint` | não | `—` | UQ, FK | — |
| 6 | `recommendation_type` | `venus.recommendation_type_enum` | não | `'recommended'::venus.recommendation_type_enum` | — | — |
| 7 | `confidence_score` | `smallint` | não | `1` | — | — |
| 8 | `ranking_position` | `integer` | não | `0` | — | — |
| 9 | `reason` | `text` | não | `''::text` | — | — |
| 10 | `created_at` | `timestamp with time zone` | não | `now()` | — | — |
| 11 | `updated_at` | `timestamp with time zone` | não | `now()` | — | — |

**Constraints**

| Nome | Tipo | Definição |
|---|---|---|
| `ck_recommendations_confidence_score_range` | `CHECK` | `CHECK (confidence_score >= 1 AND confidence_score <= 100)` |
| `recommendations_fk_analysis_result_id_fkey` | `FK` | `FOREIGN KEY (fk_analysis_result_id) REFERENCES venus.analysis_results(analysis_result_id) ON DELETE CASCADE` |
| `recommendations_fk_product_version_id_fkey` | `FK` | `FOREIGN KEY (fk_product_version_id) REFERENCES venus.product_versions(product_version_id) ON DELETE CASCADE` |
| `recommendations_fk_profile_tag_id_fkey` | `FK` | `FOREIGN KEY (fk_profile_tag_id) REFERENCES venus.profile_tags(profile_tag_id) ON DELETE CASCADE` |
| `recommendations_fk_user_id_fkey` | `FK` | `FOREIGN KEY (fk_user_id) REFERENCES venus.users(user_id) ON DELETE CASCADE` |
| `recommendations_pkey` | `PK` | `PRIMARY KEY (recommendation_id)` |
| `recommendations_fk_user_id_fk_profile_tag_id_fk_product_ver_key` | `UQ` | `UNIQUE (fk_user_id, fk_profile_tag_id, fk_product_version_id, fk_analysis_result_id)` |

**Índices únicos**

| Nome | Definição |
|---|---|
| `recommendations_fk_user_id_fk_profile_tag_id_fk_product_ver_key` | `CREATE UNIQUE INDEX recommendations_fk_user_id_fk_profile_tag_id_fk_product_ver_key ON venus.recommendations USING btree (fk_user_id, fk_profile_tag_id, fk_product_version_id, fk_analysis_result_id)` |

### `venus.regulations`

| # | Campo | Tipo | Aceita NULL? | Default | Papel | Descrição |
|---:|---|---|:---:|---|---|---|
| 1 | `regulation_id` | `bigint` | não | `—` | PK | — |
| 2 | `title` | `text` | não | `—` | UQ | — |
| 3 | `country` | `text` | não | `—` | UQ | — |
| 4 | `agency` | `text` | não | `—` | UQ | — |
| 5 | `document_url` | `text` | não | `—` | — | — |
| 6 | `status` | `venus.regulation_status_enum` | não | `'draft'::venus.regulation_status_enum` | — | — |
| 7 | `effective_date` | `date` | sim | `—` | — | — |
| 8 | `summary` | `text` | não | `''::text` | — | — |
| 9 | `created_at` | `timestamp with time zone` | não | `now()` | — | — |
| 10 | `updated_at` | `timestamp with time zone` | não | `now()` | — | — |

**Constraints**

| Nome | Tipo | Definição |
|---|---|---|
| `regulations_pkey` | `PK` | `PRIMARY KEY (regulation_id)` |
| `regulations_title_country_agency_key` | `UQ` | `UNIQUE (title, country, agency)` |

**Índices únicos**

| Nome | Definição |
|---|---|
| `regulations_title_country_agency_key` | `CREATE UNIQUE INDEX regulations_title_country_agency_key ON venus.regulations USING btree (title, country, agency)` |

### `venus.reports`

| # | Campo | Tipo | Aceita NULL? | Default | Papel | Descrição |
|---:|---|---|:---:|---|---|---|
| 1 | `report_id` | `bigint` | não | `—` | PK | — |
| 2 | `fk_user_id` | `bigint` | não | `—` | FK | — |
| 3 | `fk_admin_user_id` | `bigint` | sim | `—` | FK | — |
| 4 | `target_type` | `venus.report_target_type_enum` | não | `—` | — | — |
| 5 | `target_id` | `bigint` | não | `—` | — | — |
| 6 | `reason` | `text` | não | `''::text` | — | — |
| 7 | `status` | `venus.report_status_enum` | não | `'open'::venus.report_status_enum` | — | — |
| 8 | `handled_at` | `timestamp with time zone` | sim | `—` | — | — |
| 9 | `created_at` | `timestamp with time zone` | não | `now()` | — | — |
| 10 | `updated_at` | `timestamp with time zone` | não | `now()` | — | — |

**Constraints**

| Nome | Tipo | Definição |
|---|---|---|
| `reports_fk_admin_user_id_fkey` | `FK` | `FOREIGN KEY (fk_admin_user_id) REFERENCES venus.admin_users(admin_user_id) ON DELETE SET NULL` |
| `reports_fk_user_id_fkey` | `FK` | `FOREIGN KEY (fk_user_id) REFERENCES venus.users(user_id) ON DELETE CASCADE` |
| `reports_pkey` | `PK` | `PRIMARY KEY (report_id)` |

### `venus.review_votes`

| # | Campo | Tipo | Aceita NULL? | Default | Papel | Descrição |
|---:|---|---|:---:|---|---|---|
| 1 | `review_vote_id` | `bigint` | não | `—` | PK | — |
| 2 | `fk_review_id` | `bigint` | não | `—` | UQ, FK | — |
| 3 | `fk_user_id` | `bigint` | não | `—` | UQ, FK | — |
| 4 | `vote_type` | `venus.vote_type_enum` | não | `'useful'::venus.vote_type_enum` | — | — |
| 5 | `created_at` | `timestamp with time zone` | não | `now()` | — | — |

**Constraints**

| Nome | Tipo | Definição |
|---|---|---|
| `review_votes_fk_review_id_fkey` | `FK` | `FOREIGN KEY (fk_review_id) REFERENCES venus.reviews(review_id) ON DELETE CASCADE` |
| `review_votes_fk_user_id_fkey` | `FK` | `FOREIGN KEY (fk_user_id) REFERENCES venus.users(user_id) ON DELETE CASCADE` |
| `review_votes_pkey` | `PK` | `PRIMARY KEY (review_vote_id)` |
| `review_votes_fk_review_id_fk_user_id_key` | `UQ` | `UNIQUE (fk_review_id, fk_user_id)` |

**Índices únicos**

| Nome | Definição |
|---|---|
| `review_votes_fk_review_id_fk_user_id_key` | `CREATE UNIQUE INDEX review_votes_fk_review_id_fk_user_id_key ON venus.review_votes USING btree (fk_review_id, fk_user_id)` |

### `venus.reviews`

| # | Campo | Tipo | Aceita NULL? | Default | Papel | Descrição |
|---:|---|---|:---:|---|---|---|
| 1 | `review_id` | `bigint` | não | `—` | PK | — |
| 2 | `fk_user_id` | `bigint` | não | `—` | UQ, FK | — |
| 3 | `fk_product_version_id` | `bigint` | não | `—` | UQ, FK | — |
| 4 | `rating` | `numeric(2,1)` | não | `0.0` | — | — |
| 5 | `title` | `text` | não | `''::text` | — | — |
| 6 | `comment` | `text` | não | `''::text` | — | — |
| 7 | `verified_use` | `boolean` | não | `false` | — | — |
| 8 | `created_at` | `timestamp with time zone` | não | `now()` | — | — |
| 9 | `updated_at` | `timestamp with time zone` | não | `now()` | — | — |

**Constraints**

| Nome | Tipo | Definição |
|---|---|---|
| `reviews_fk_product_version_id_fkey` | `FK` | `FOREIGN KEY (fk_product_version_id) REFERENCES venus.product_versions(product_version_id) ON DELETE CASCADE` |
| `reviews_fk_user_id_fkey` | `FK` | `FOREIGN KEY (fk_user_id) REFERENCES venus.users(user_id) ON DELETE CASCADE` |
| `reviews_pkey` | `PK` | `PRIMARY KEY (review_id)` |
| `reviews_fk_user_id_fk_product_version_id_key` | `UQ` | `UNIQUE (fk_user_id, fk_product_version_id)` |

**Índices únicos**

| Nome | Definição |
|---|---|
| `reviews_fk_user_id_fk_product_version_id_key` | `CREATE UNIQUE INDEX reviews_fk_user_id_fk_product_version_id_key ON venus.reviews USING btree (fk_user_id, fk_product_version_id)` |

### `venus.rule_evaluations`

| # | Campo | Tipo | Aceita NULL? | Default | Papel | Descrição |
|---:|---|---|:---:|---|---|---|
| 1 | `rule_evaluation_id` | `bigint` | não | `—` | PK | — |
| 2 | `fk_analysis_result_id` | `bigint` | não | `—` | UQ, FK | — |
| 3 | `fk_compatibility_rule_id` | `bigint` | não | `—` | UQ, FK | — |
| 4 | `fk_ingredient_id` | `bigint` | não | `—` | UQ, FK | — |
| 5 | `fk_profile_tag_id` | `bigint` | não | `—` | UQ, FK | — |
| 6 | `was_matched` | `boolean` | não | `false` | — | — |
| 7 | `score_delta` | `numeric(10,2)` | não | `0` | — | — |
| 8 | `final_delta` | `numeric(10,2)` | não | `0` | — | — |
| 9 | `explanation` | `text` | não | `''::text` | — | — |
| 10 | `created_at` | `timestamp with time zone` | não | `now()` | — | — |

**Constraints**

| Nome | Tipo | Definição |
|---|---|---|
| `rule_evaluations_fk_analysis_result_id_fkey` | `FK` | `FOREIGN KEY (fk_analysis_result_id) REFERENCES venus.analysis_results(analysis_result_id) ON DELETE CASCADE` |
| `rule_evaluations_fk_compatibility_rule_id_fkey` | `FK` | `FOREIGN KEY (fk_compatibility_rule_id) REFERENCES venus.compatibility_rules(compatibility_rule_id) ON DELETE CASCADE` |
| `rule_evaluations_fk_ingredient_id_fkey` | `FK` | `FOREIGN KEY (fk_ingredient_id) REFERENCES venus.ingredients(ingredient_id) ON DELETE RESTRICT` |
| `rule_evaluations_fk_profile_tag_id_fkey` | `FK` | `FOREIGN KEY (fk_profile_tag_id) REFERENCES venus.profile_tags(profile_tag_id) ON DELETE CASCADE` |
| `rule_evaluations_pkey` | `PK` | `PRIMARY KEY (rule_evaluation_id)` |
| `rule_evaluations_fk_analysis_result_id_fk_compatibility_rul_key` | `UQ` | `UNIQUE (fk_analysis_result_id, fk_compatibility_rule_id, fk_ingredient_id, fk_profile_tag_id)` |

**Índices únicos**

| Nome | Definição |
|---|---|
| `rule_evaluations_fk_analysis_result_id_fk_compatibility_rul_key` | `CREATE UNIQUE INDEX rule_evaluations_fk_analysis_result_id_fk_compatibility_rul_key ON venus.rule_evaluations USING btree (fk_analysis_result_id, fk_compatibility_rule_id, fk_ingredient_id, fk_profile_tag_id)` |

### `venus.score_categories`

| # | Campo | Tipo | Aceita NULL? | Default | Papel | Descrição |
|---:|---|---|:---:|---|---|---|
| 1 | `score_category_id` | `bigint` | não | `—` | PK | — |
| 2 | `name` | `text` | não | `—` | UQ | — |
| 3 | `description` | `text` | não | `''::text` | — | — |
| 4 | `default_weight` | `numeric(6,2)` | não | `1.00` | — | — |
| 5 | `created_at` | `timestamp with time zone` | não | `now()` | — | — |
| 6 | `updated_at` | `timestamp with time zone` | não | `now()` | — | — |

**Constraints**

| Nome | Tipo | Definição |
|---|---|---|
| `score_categories_pkey` | `PK` | `PRIMARY KEY (score_category_id)` |
| `score_categories_name_key` | `UQ` | `UNIQUE (name)` |

**Índices únicos**

| Nome | Definição |
|---|---|
| `score_categories_name_key` | `CREATE UNIQUE INDEX score_categories_name_key ON venus.score_categories USING btree (name)` |

### `venus.scoring_model_categories`

| # | Campo | Tipo | Aceita NULL? | Default | Papel | Descrição |
|---:|---|---|:---:|---|---|---|
| 1 | `scoring_model_category_id` | `bigint` | não | `—` | PK | — |
| 2 | `fk_scoring_model_id` | `bigint` | não | `—` | UQ, FK | — |
| 3 | `fk_score_category_id` | `bigint` | não | `—` | UQ, FK | — |
| 4 | `weight` | `numeric(6,2)` | não | `—` | — | — |
| 5 | `created_at` | `timestamp with time zone` | não | `now()` | — | — |
| 6 | `updated_at` | `timestamp with time zone` | não | `now()` | — | — |

**Constraints**

| Nome | Tipo | Definição |
|---|---|---|
| `scoring_model_categories_fk_score_category_id_fkey` | `FK` | `FOREIGN KEY (fk_score_category_id) REFERENCES venus.score_categories(score_category_id) ON DELETE RESTRICT` |
| `scoring_model_categories_fk_scoring_model_id_fkey` | `FK` | `FOREIGN KEY (fk_scoring_model_id) REFERENCES venus.scoring_models(scoring_model_id) ON DELETE CASCADE` |
| `scoring_model_categories_pkey` | `PK` | `PRIMARY KEY (scoring_model_category_id)` |
| `scoring_model_categories_fk_scoring_model_id_fk_score_categ_key` | `UQ` | `UNIQUE (fk_scoring_model_id, fk_score_category_id)` |

**Índices únicos**

| Nome | Definição |
|---|---|
| `scoring_model_categories_fk_scoring_model_id_fk_score_categ_key` | `CREATE UNIQUE INDEX scoring_model_categories_fk_scoring_model_id_fk_score_categ_key ON venus.scoring_model_categories USING btree (fk_scoring_model_id, fk_score_category_id)` |

### `venus.scoring_models`

| # | Campo | Tipo | Aceita NULL? | Default | Papel | Descrição |
|---:|---|---|:---:|---|---|---|
| 1 | `scoring_model_id` | `bigint` | não | `—` | PK | — |
| 2 | `name` | `text` | não | `—` | UQ | — |
| 3 | `version` | `text` | não | `—` | UQ | — |
| 4 | `description` | `text` | não | `''::text` | — | — |
| 5 | `is_active` | `boolean` | não | `true` | — | — |
| 6 | `created_at` | `timestamp with time zone` | não | `now()` | — | — |
| 7 | `updated_at` | `timestamp with time zone` | não | `now()` | — | — |

**Constraints**

| Nome | Tipo | Definição |
|---|---|---|
| `scoring_models_pkey` | `PK` | `PRIMARY KEY (scoring_model_id)` |
| `scoring_models_name_version_key` | `UQ` | `UNIQUE (name, version)` |

**Índices únicos**

| Nome | Definição |
|---|---|
| `scoring_models_name_version_key` | `CREATE UNIQUE INDEX scoring_models_name_version_key ON venus.scoring_models USING btree (name, version)` |
| `ux_scoring_models_single_active` | `CREATE UNIQUE INDEX ux_scoring_models_single_active ON venus.scoring_models USING btree (is_active) WHERE is_active` |

### `venus.user_access_events`

| # | Campo | Tipo | Aceita NULL? | Default | Papel | Descrição |
|---:|---|---|:---:|---|---|---|
| 1 | `access_event_id` | `bigint` | não | `—` | PK | — |
| 2 | `fk_user_id` | `bigint` | não | `—` | FK | — |
| 3 | `access_type` | `text` | não | `'APP_ACTIVITY'::text` | — | — |
| 4 | `accessed_at` | `timestamp with time zone` | não | `now()` | — | — |
| 5 | `activity_date` | `date` | sim | `((accessed_at AT TIME ZONE 'UTC'::text))::date` | — | — |
| 6 | `application_name` | `text` | sim | `—` | — | — |
| 7 | `client_ip` | `inet` | sim | `—` | — | — |
| 8 | `metadata` | `jsonb` | não | `'{}'::jsonb` | — | — |

**Constraints**

| Nome | Tipo | Definição |
|---|---|---|
| `user_access_events_fk_user_id_fkey` | `FK` | `FOREIGN KEY (fk_user_id) REFERENCES venus.users(user_id) ON DELETE CASCADE` |
| `user_access_events_pkey` | `PK` | `PRIMARY KEY (access_event_id)` |

### `venus.user_allergies`

| # | Campo | Tipo | Aceita NULL? | Default | Papel | Descrição |
|---:|---|---|:---:|---|---|---|
| 1 | `user_allergy_id` | `bigint` | não | `—` | PK | — |
| 2 | `fk_user_id` | `bigint` | não | `—` | UQ, FK | — |
| 3 | `fk_allergy_id` | `bigint` | não | `—` | UQ, FK | — |
| 4 | `severity` | `venus.risk_level_enum` | não | `'medium'::venus.risk_level_enum` | — | — |
| 5 | `created_at` | `timestamp with time zone` | não | `now()` | — | — |
| 6 | `updated_at` | `timestamp with time zone` | não | `now()` | — | — |

**Constraints**

| Nome | Tipo | Definição |
|---|---|---|
| `user_allergies_fk_allergy_id_fkey` | `FK` | `FOREIGN KEY (fk_allergy_id) REFERENCES venus.allergies(allergy_id) ON DELETE CASCADE` |
| `user_allergies_fk_user_id_fkey` | `FK` | `FOREIGN KEY (fk_user_id) REFERENCES venus.users(user_id) ON DELETE CASCADE` |
| `user_allergies_pkey` | `PK` | `PRIMARY KEY (user_allergy_id)` |
| `user_allergies_fk_user_id_fk_allergy_id_key` | `UQ` | `UNIQUE (fk_user_id, fk_allergy_id)` |

**Índices únicos**

| Nome | Definição |
|---|---|
| `user_allergies_fk_user_id_fk_allergy_id_key` | `CREATE UNIQUE INDEX user_allergies_fk_user_id_fk_allergy_id_key ON venus.user_allergies USING btree (fk_user_id, fk_allergy_id)` |

### `venus.user_list_items`

| # | Campo | Tipo | Aceita NULL? | Default | Papel | Descrição |
|---:|---|---|:---:|---|---|---|
| 1 | `user_list_item_id` | `bigint` | não | `—` | PK | — |
| 2 | `fk_user_list_id` | `bigint` | não | `—` | UQ, FK | — |
| 3 | `fk_product_id` | `bigint` | não | `—` | UQ, FK | — |
| 4 | `position_order` | `integer` | não | `—` | UQ | — |
| 5 | `created_at` | `timestamp with time zone` | não | `now()` | — | — |

**Constraints**

| Nome | Tipo | Definição |
|---|---|---|
| `user_list_items_fk_product_id_fkey` | `FK` | `FOREIGN KEY (fk_product_id) REFERENCES venus.products(product_id) ON DELETE CASCADE` |
| `user_list_items_fk_user_list_id_fkey` | `FK` | `FOREIGN KEY (fk_user_list_id) REFERENCES venus.user_lists(user_list_id) ON DELETE CASCADE` |
| `user_list_items_pkey` | `PK` | `PRIMARY KEY (user_list_item_id)` |
| `user_list_items_fk_user_list_id_fk_product_id_key` | `UQ` | `UNIQUE (fk_user_list_id, fk_product_id)` |
| `user_list_items_fk_user_list_id_position_order_key` | `UQ` | `UNIQUE (fk_user_list_id, position_order)` |

**Índices únicos**

| Nome | Definição |
|---|---|
| `user_list_items_fk_user_list_id_fk_product_id_key` | `CREATE UNIQUE INDEX user_list_items_fk_user_list_id_fk_product_id_key ON venus.user_list_items USING btree (fk_user_list_id, fk_product_id)` |
| `user_list_items_fk_user_list_id_position_order_key` | `CREATE UNIQUE INDEX user_list_items_fk_user_list_id_position_order_key ON venus.user_list_items USING btree (fk_user_list_id, position_order)` |

### `venus.user_lists`

| # | Campo | Tipo | Aceita NULL? | Default | Papel | Descrição |
|---:|---|---|:---:|---|---|---|
| 1 | `user_list_id` | `bigint` | não | `—` | PK | — |
| 2 | `fk_user_id` | `bigint` | não | `—` | UQ, FK | — |
| 3 | `name` | `text` | não | `—` | UQ | — |
| 4 | `list_type` | `venus.list_type_enum` | não | `'custom'::venus.list_type_enum` | — | — |
| 5 | `created_at` | `timestamp with time zone` | não | `now()` | — | — |
| 6 | `updated_at` | `timestamp with time zone` | não | `now()` | — | — |
| 7 | `description` | `text` | sim | `—` | — | — |
| 8 | `cover_key` | `text` | sim | `—` | — | — |

**Constraints**

| Nome | Tipo | Definição |
|---|---|---|
| `ck_user_lists_cover_key` | `CHECK` | `CHECK (cover_key IS NULL OR (cover_key = ANY (ARRAY['favoritos'::text, 'escaneados'::text, 'skincare'::text])))` |
| `ck_user_lists_description_length` | `CHECK` | `CHECK (description IS NULL OR char_length(description) <= 500)` |
| `user_lists_fk_user_id_fkey` | `FK` | `FOREIGN KEY (fk_user_id) REFERENCES venus.users(user_id) ON DELETE CASCADE` |
| `user_lists_pkey` | `PK` | `PRIMARY KEY (user_list_id)` |
| `user_lists_fk_user_id_name_key` | `UQ` | `UNIQUE (fk_user_id, name)` |

**Índices únicos**

| Nome | Definição |
|---|---|
| `user_lists_fk_user_id_name_key` | `CREATE UNIQUE INDEX user_lists_fk_user_id_name_key ON venus.user_lists USING btree (fk_user_id, name)` |

### `venus.user_preferences`

| # | Campo | Tipo | Aceita NULL? | Default | Papel | Descrição |
|---:|---|---|:---:|---|---|---|
| 1 | `user_preference_id` | `bigint` | não | `—` | PK | — |
| 2 | `fk_user_id` | `bigint` | não | `—` | UQ, FK | — |
| 3 | `prefer_cruelty_free` | `boolean` | não | `false` | — | — |
| 4 | `prefer_vegan` | `boolean` | não | `false` | — | — |
| 5 | `prefer_sustainable` | `boolean` | não | `false` | — | — |
| 6 | `prefer_fragrance_free` | `boolean` | não | `false` | — | — |
| 7 | `prefer_paraben_free` | `boolean` | não | `false` | — | — |
| 8 | `prefer_sulfate_free` | `boolean` | não | `false` | — | — |
| 9 | `prefer_silicone_free` | `boolean` | não | `false` | — | — |
| 10 | `created_at` | `timestamp with time zone` | não | `now()` | — | — |
| 11 | `updated_at` | `timestamp with time zone` | não | `now()` | — | — |

**Constraints**

| Nome | Tipo | Definição |
|---|---|---|
| `user_preferences_fk_user_id_fkey` | `FK` | `FOREIGN KEY (fk_user_id) REFERENCES venus.users(user_id) ON DELETE CASCADE` |
| `user_preferences_pkey` | `PK` | `PRIMARY KEY (user_preference_id)` |
| `user_preferences_fk_user_id_key` | `UQ` | `UNIQUE (fk_user_id)` |

**Índices únicos**

| Nome | Definição |
|---|---|
| `user_preferences_fk_user_id_key` | `CREATE UNIQUE INDEX user_preferences_fk_user_id_key ON venus.user_preferences USING btree (fk_user_id)` |

### `venus.user_profile_tags`

| # | Campo | Tipo | Aceita NULL? | Default | Papel | Descrição |
|---:|---|---|:---:|---|---|---|
| 1 | `user_profile_tag_id` | `bigint` | não | `—` | PK | — |
| 2 | `fk_user_id` | `bigint` | não | `—` | UQ, FK | — |
| 3 | `fk_profile_tag_id` | `bigint` | não | `—` | UQ, FK | — |
| 4 | `created_at` | `timestamp with time zone` | não | `now()` | — | — |
| 5 | `updated_at` | `timestamp with time zone` | não | `now()` | — | — |
| 6 | `is_active` | `boolean` | não | `true` | — | — |

**Constraints**

| Nome | Tipo | Definição |
|---|---|---|
| `user_profile_tags_fk_profile_tag_id_fkey` | `FK` | `FOREIGN KEY (fk_profile_tag_id) REFERENCES venus.profile_tags(profile_tag_id) ON DELETE CASCADE` |
| `user_profile_tags_fk_user_id_fkey` | `FK` | `FOREIGN KEY (fk_user_id) REFERENCES venus.users(user_id) ON DELETE CASCADE` |
| `user_profile_tags_pkey` | `PK` | `PRIMARY KEY (user_profile_tag_id)` |
| `user_profile_tags_fk_user_id_fk_profile_tag_id_key` | `UQ` | `UNIQUE (fk_user_id, fk_profile_tag_id)` |

**Índices únicos**

| Nome | Definição |
|---|---|
| `user_profile_tags_fk_user_id_fk_profile_tag_id_key` | `CREATE UNIQUE INDEX user_profile_tags_fk_user_id_fk_profile_tag_id_key ON venus.user_profile_tags USING btree (fk_user_id, fk_profile_tag_id)` |

### `venus.user_profiles`

| # | Campo | Tipo | Aceita NULL? | Default | Papel | Descrição |
|---:|---|---|:---:|---|---|---|
| 1 | `user_profile_id` | `bigint` | não | `—` | PK | — |
| 2 | `fk_user_id` | `bigint` | não | `—` | UQ, FK | — |
| 3 | `skin_type` | `venus.skin_type_enum` | sim | `—` | — | — |
| 4 | `skin_phototype` | `venus.skin_phototype_enum` | sim | `—` | — | — |
| 5 | `has_hyperpigmentation` | `boolean` | sim | `—` | — | — |
| 6 | `has_melasma` | `boolean` | sim | `—` | — | — |
| 7 | `has_rosacea` | `boolean` | sim | `—` | — | — |
| 8 | `has_eczema` | `boolean` | sim | `—` | — | — |
| 9 | `scalp_type` | `venus.scalp_type_enum` | sim | `—` | — | — |
| 10 | `skin_sensitivity` | `venus.sensitivity_level_enum` | sim | `—` | — | — |
| 11 | `acne_prone` | `boolean` | sim | `—` | — | — |
| 12 | `age_range` | `venus.age_range_enum` | sim | `—` | — | — |
| 13 | `gender` | `venus.gender_enum` | sim | `—` | — | — |
| 14 | `is_pregnant` | `boolean` | sim | `—` | — | — |
| 15 | `is_active` | `boolean` | não | `true` | — | — |
| 16 | `created_at` | `timestamp with time zone` | não | `now()` | — | — |
| 17 | `updated_at` | `timestamp with time zone` | não | `now()` | — | — |
| 18 | `hair_pattern` | `venus.hair_pattern_enum` | sim | `—` | — | Classificação específica do padrão capilar: 1A–4C ou other. Nullable para perfis legados ainda sem granularidade. |
| 19 | `is_breastfeeding` | `boolean` | sim | `—` | — | — |

**Constraints**

| Nome | Tipo | Definição |
|---|---|---|
| `ck_user_profiles_adult_age_range` | `CHECK` | `CHECK (age_range = ANY (ARRAY['age_13_17'::venus.age_range_enum, 'age_18_24'::venus.age_range_enum, 'age_25_34'::venus.age_range_enum, 'age_35_44'::venus.age_range_enum, 'age_45_54'::venus.age_range_enum, 'age_55_plus'::venus.age_range_enum]))` |
| `user_profiles_fk_user_id_fkey` | `FK` | `FOREIGN KEY (fk_user_id) REFERENCES venus.users(user_id) ON DELETE CASCADE` |
| `user_profiles_pkey` | `PK` | `PRIMARY KEY (user_profile_id)` |
| `user_profiles_fk_user_id_key` | `UQ` | `UNIQUE (fk_user_id)` |

**Índices únicos**

| Nome | Definição |
|---|---|
| `user_profiles_fk_user_id_key` | `CREATE UNIQUE INDEX user_profiles_fk_user_id_key ON venus.user_profiles USING btree (fk_user_id)` |

### `venus.user_tracking_events`

| # | Campo | Tipo | Aceita NULL? | Default | Papel | Descrição |
|---:|---|---|:---:|---|---|---|
| 1 | `tracking_event_id` | `bigint` | não | `—` | PK | — |
| 2 | `fk_user_id` | `bigint` | sim | `—` | FK | — |
| 3 | `user_external_id` | `text` | sim | `—` | — | — |
| 4 | `anonymous_id` | `text` | sim | `—` | — | — |
| 5 | `platform` | `text` | não | `—` | — | — |
| 6 | `event_name` | `text` | não | `—` | — | — |
| 7 | `session_id` | `text` | sim | `—` | — | — |
| 8 | `screen_name` | `text` | sim | `—` | — | — |
| 9 | `app_version` | `text` | sim | `—` | — | — |
| 10 | `device_os` | `text` | sim | `—` | — | — |
| 11 | `device_id_hash` | `text` | sim | `—` | — | — |
| 12 | `occurred_at` | `timestamp with time zone` | não | `now()` | — | — |
| 13 | `metadata` | `jsonb` | não | `'{}'::jsonb` | — | — |
| 14 | `created_at` | `timestamp with time zone` | não | `now()` | — | — |

**Constraints**

| Nome | Tipo | Definição |
|---|---|---|
| `ck_user_tracking_events_name` | `CHECK` | `CHECK (event_name = btrim(event_name) AND length(event_name) >= 1 AND length(event_name) <= 120)` |
| `ck_user_tracking_events_platform` | `CHECK` | `CHECK (platform = ANY (ARRAY['mobile'::text, 'web'::text]))` |
| `user_tracking_events_fk_user_id_fkey` | `FK` | `FOREIGN KEY (fk_user_id) REFERENCES venus.users(user_id) ON DELETE SET NULL` |
| `user_tracking_events_pkey` | `PK` | `PRIMARY KEY (tracking_event_id)` |

### `venus.users`

| # | Campo | Tipo | Aceita NULL? | Default | Papel | Descrição |
|---:|---|---|:---:|---|---|---|
| 1 | `user_id` | `bigint` | não | `—` | PK | — |
| 2 | `firebase_uid` | `text` | não | `—` | UQ | — |
| 3 | `name` | `text` | não | `—` | — | — |
| 4 | `status` | `venus.user_status_enum` | não | `'active'::venus.user_status_enum` | — | — |
| 5 | `last_login` | `timestamp with time zone` | sim | `—` | — | — |
| 6 | `created_at` | `timestamp with time zone` | não | `now()` | — | — |
| 7 | `updated_at` | `timestamp with time zone` | não | `now()` | — | — |
| 8 | `email` | `text` | sim | `—` | — | — |
| 9 | `password_hash` | `text` | sim | `—` | — | — |

**Constraints**

| Nome | Tipo | Definição |
|---|---|---|
| `users_pkey` | `PK` | `PRIMARY KEY (user_id)` |
| `users_firebase_uid_key` | `UQ` | `UNIQUE (firebase_uid)` |

**Índices únicos**

| Nome | Definição |
|---|---|
| `users_firebase_uid_key` | `CREATE UNIQUE INDEX users_firebase_uid_key ON venus.users USING btree (firebase_uid)` |
| `ux_users_email` | `CREATE UNIQUE INDEX ux_users_email ON venus.users USING btree (lower(email)) WHERE (email IS NOT NULL)` |

### `venus_audit.audit_logs`

| # | Campo | Tipo | Aceita NULL? | Default | Papel | Descrição |
|---:|---|---|:---:|---|---|---|
| 1 | `audit_id` | `bigint` | não | `—` | PK | — |
| 2 | `schema_name` | `text` | não | `—` | — | — |
| 3 | `table_name` | `text` | não | `—` | — | — |
| 4 | `operation_type` | `text` | não | `—` | — | — |
| 5 | `old_data` | `jsonb` | sim | `—` | — | — |
| 6 | `new_data` | `jsonb` | sim | `—` | — | — |
| 7 | `changed_by` | `text` | não | `CURRENT_USER` | — | — |
| 8 | `changed_at` | `timestamp with time zone` | não | `now()` | — | — |
| 9 | `application_name` | `text` | sim | `—` | — | — |

**Constraints**

| Nome | Tipo | Definição |
|---|---|---|
| `audit_logs_pkey` | `PK` | `PRIMARY KEY (audit_id)` |

### `venus_rpa.rpa_error`

| # | Campo | Tipo | Aceita NULL? | Default | Papel | Descrição |
|---:|---|---|:---:|---|---|---|
| 1 | `error_id` | `bigint` | não | `—` | PK | — |
| 2 | `batch_id` | `uuid` | não | `—` | FK | — |
| 3 | `source_table` | `text` | não | `—` | — | — |
| 4 | `legacy_id` | `bigint` | sim | `—` | — | — |
| 5 | `error_type` | `text` | não | `—` | — | — |
| 6 | `error_message` | `text` | não | `—` | — | — |
| 7 | `payload` | `jsonb` | sim | `—` | — | — |
| 8 | `created_at` | `timestamp with time zone` | não | `now()` | — | — |

**Constraints**

| Nome | Tipo | Definição |
|---|---|---|
| `rpa_error_batch_id_fkey` | `FK` | `FOREIGN KEY (batch_id) REFERENCES venus_rpa.rpa_run(batch_id) ON DELETE CASCADE` |
| `rpa_error_pkey` | `PK` | `PRIMARY KEY (error_id)` |

### `venus_rpa.rpa_run`

| # | Campo | Tipo | Aceita NULL? | Default | Papel | Descrição |
|---:|---|---|:---:|---|---|---|
| 1 | `batch_id` | `uuid` | não | `—` | PK | — |
| 2 | `started_at` | `timestamp with time zone` | não | `now()` | — | — |
| 3 | `finished_at` | `timestamp with time zone` | sim | `—` | — | — |
| 4 | `status` | `text` | não | `—` | — | — |
| 5 | `source_database` | `text` | sim | `—` | — | — |
| 6 | `source_products_query_hash` | `text` | sim | `—` | — | — |
| 7 | `source_users_query_hash` | `text` | sim | `—` | — | — |
| 8 | `records_read` | `integer` | não | `0` | — | — |
| 9 | `records_transformed` | `integer` | não | `0` | — | — |
| 10 | `records_loaded` | `integer` | não | `0` | — | — |
| 11 | `records_failed` | `integer` | não | `0` | — | — |
| 12 | `error_message` | `text` | sim | `—` | — | — |

**Constraints**

| Nome | Tipo | Definição |
|---|---|---|
| `rpa_run_status_check` | `CHECK` | `CHECK (status = ANY (ARRAY['RUNNING'::text, 'SUCCESS'::text, 'PARTIAL'::text, 'FAILED'::text]))` |
| `rpa_run_pkey` | `PK` | `PRIMARY KEY (batch_id)` |

### `venus_rpa.rpa_stage_product`

| # | Campo | Tipo | Aceita NULL? | Default | Papel | Descrição |
|---:|---|---|:---:|---|---|---|
| 1 | `batch_id` | `uuid` | não | `—` | PK, FK | — |
| 2 | `legacy_product_id` | `bigint` | não | `—` | PK | — |
| 3 | `product_name` | `text` | sim | `—` | — | — |
| 4 | `brand_name` | `text` | sim | `—` | — | — |
| 5 | `category_name` | `text` | sim | `—` | — | — |
| 6 | `ingredients_text` | `text` | sim | `—` | — | — |
| 7 | `normalized_product_name` | `text` | sim | `—` | — | — |
| 8 | `normalized_brand_name` | `text` | sim | `—` | — | — |
| 9 | `normalized_category_name` | `text` | sim | `—` | — | — |
| 10 | `validation_status` | `text` | não | `—` | — | — |
| 11 | `validation_message` | `text` | sim | `—` | — | — |
| 12 | `loaded_product_id` | `bigint` | sim | `—` | FK | — |

**Constraints**

| Nome | Tipo | Definição |
|---|---|---|
| `rpa_stage_product_validation_status_check` | `CHECK` | `CHECK (validation_status = ANY (ARRAY['VALID'::text, 'INVALID'::text, 'WARNING'::text]))` |
| `rpa_stage_product_batch_id_fkey` | `FK` | `FOREIGN KEY (batch_id) REFERENCES venus_rpa.rpa_run(batch_id) ON DELETE CASCADE` |
| `rpa_stage_product_loaded_product_id_fkey` | `FK` | `FOREIGN KEY (loaded_product_id) REFERENCES venus.products(product_id) ON DELETE SET NULL` |
| `rpa_stage_product_pkey` | `PK` | `PRIMARY KEY (batch_id, legacy_product_id)` |

### `venus_rpa.rpa_stage_user`

| # | Campo | Tipo | Aceita NULL? | Default | Papel | Descrição |
|---:|---|---|:---:|---|---|---|
| 1 | `batch_id` | `uuid` | não | `—` | PK, FK | — |
| 2 | `legacy_user_id` | `bigint` | não | `—` | PK | — |
| 3 | `full_name` | `text` | sim | `—` | — | — |
| 4 | `email` | `text` | sim | `—` | — | — |
| 5 | `status_text` | `text` | sim | `—` | — | — |
| 6 | `normalized_name` | `text` | sim | `—` | — | — |
| 7 | `normalized_email` | `text` | sim | `—` | — | — |
| 8 | `status_normalized` | `text` | sim | `—` | — | — |
| 9 | `validation_status` | `text` | não | `—` | — | — |
| 10 | `validation_message` | `text` | sim | `—` | — | — |
| 11 | `loaded_user_id` | `bigint` | sim | `—` | FK | — |

**Constraints**

| Nome | Tipo | Definição |
|---|---|---|
| `rpa_stage_user_validation_status_check` | `CHECK` | `CHECK (validation_status = ANY (ARRAY['VALID'::text, 'INVALID'::text, 'WARNING'::text]))` |
| `rpa_stage_user_batch_id_fkey` | `FK` | `FOREIGN KEY (batch_id) REFERENCES venus_rpa.rpa_run(batch_id) ON DELETE CASCADE` |
| `rpa_stage_user_loaded_user_id_fkey` | `FK` | `FOREIGN KEY (loaded_user_id) REFERENCES venus.users(user_id) ON DELETE SET NULL` |
| `rpa_stage_user_pkey` | `PK` | `PRIMARY KEY (batch_id, legacy_user_id)` |

### `venus_optimization.readme`

| # | Campo | Tipo | Aceita NULL? | Default | Papel | Descrição |
|---:|---|---|:---:|---|---|---|
| 1 | `item` | `text` | não | `—` | PK | — |
| 2 | `description` | `text` | não | `—` | — | — |

**Constraints**

| Nome | Tipo | Definição |
|---|---|---|
| `readme_pkey` | `PK` | `PRIMARY KEY (item)` |

## Relacionamentos físicos

| Constraint | Origem | Destino | Cardinalidade derivada | ON DELETE | ON UPDATE |
|---|---|---|---|---|---|
| `allergy_ingredients_fk_allergy_id_fkey` | `venus.allergy_ingredients.fk_allergy_id` | `venus.allergies.allergy_id` | `child 1..1 -> parent 1..1; parent -> child 0..N` | `CASCADE` | `NO ACTION` |
| `allergy_ingredients_fk_ingredient_id_fkey` | `venus.allergy_ingredients.fk_ingredient_id` | `venus.ingredients.ingredient_id` | `child 1..1 -> parent 1..1; parent -> child 0..N` | `CASCADE` | `NO ACTION` |
| `analysis_results_fk_product_version_id_fkey` | `venus.analysis_results.fk_product_version_id` | `venus.product_versions.product_version_id` | `child 1..1 -> parent 1..1; parent -> child 0..N` | `CASCADE` | `NO ACTION` |
| `analysis_results_fk_scoring_model_id_fkey` | `venus.analysis_results.fk_scoring_model_id` | `venus.scoring_models.scoring_model_id` | `child 1..1 -> parent 1..1; parent -> child 0..N` | `RESTRICT` | `NO ACTION` |
| `analysis_results_fk_user_id_fkey` | `venus.analysis_results.fk_user_id` | `venus.users.user_id` | `child 1..1 -> parent 1..1; parent -> child 0..N` | `CASCADE` | `NO ACTION` |
| `brand_claim_evidence_fk_brand_id_fkey` | `venus.brand_claim_evidence.fk_brand_id` | `venus.brands.brand_id` | `child 1..1 -> parent 1..1; parent -> child 0..N` | `CASCADE` | `NO ACTION` |
| `compatibility_rules_fk_ingredient_effect_id_fkey` | `venus.compatibility_rules.fk_ingredient_effect_id` | `venus.ingredient_effects.ingredient_effect_id` | `child 1..1 -> parent 1..1; parent -> child 0..N` | `CASCADE` | `NO ACTION` |
| `compatibility_rules_fk_scoring_model_id_fkey` | `venus.compatibility_rules.fk_scoring_model_id` | `venus.scoring_models.scoring_model_id` | `child 1..1 -> parent 1..1; parent -> child 0..N` | `RESTRICT` | `NO ACTION` |
| `favorites_fk_product_id_fkey` | `venus.favorites.fk_product_id` | `venus.products.product_id` | `child 1..1 -> parent 1..1; parent -> child 0..N` | `CASCADE` | `NO ACTION` |
| `favorites_fk_user_id_fkey` | `venus.favorites.fk_user_id` | `venus.users.user_id` | `child 1..1 -> parent 1..1; parent -> child 0..N` | `CASCADE` | `NO ACTION` |
| `google_oauth_tokens_fk_user_id_fkey` | `venus.google_oauth_tokens.fk_user_id` | `venus.users.user_id` | `child 1..1 -> parent 1..1; parent -> child 0..1` | `CASCADE` | `NO ACTION` |
| `ingredient_aliases_fk_ingredient_id_fkey` | `venus.ingredient_aliases.fk_ingredient_id` | `venus.ingredients.ingredient_id` | `child 1..1 -> parent 1..1; parent -> child 0..N` | `CASCADE` | `NO ACTION` |
| `ingredient_categories_parent_ingredient_category_id_fkey` | `venus.ingredient_categories.parent_ingredient_category_id` | `venus.ingredient_categories.ingredient_category_id` | `child 0..1 -> parent 1..1; parent -> child 0..N` | `SET NULL` | `NO ACTION` |
| `ingredient_category_assignments_fk_ingredient_category_id_fkey` | `venus.ingredient_category_assignments.fk_ingredient_category_id` | `venus.ingredient_categories.ingredient_category_id` | `child 1..1 -> parent 1..1; parent -> child 0..N` | `RESTRICT` | `NO ACTION` |
| `ingredient_category_assignments_fk_ingredient_id_fkey` | `venus.ingredient_category_assignments.fk_ingredient_id` | `venus.ingredients.ingredient_id` | `child 1..1 -> parent 1..1; parent -> child 0..N` | `CASCADE` | `NO ACTION` |
| `ingredient_effect_validation_audit_fk_ingredient_id_fkey` | `venus.ingredient_effect_validation_audit.fk_ingredient_id` | `venus.ingredients.ingredient_id` | `child 1..1 -> parent 1..1; parent -> child 0..N` | `CASCADE` | `NO ACTION` |
| `ingredient_effects_fk_ingredient_id_fkey` | `venus.ingredient_effects.fk_ingredient_id` | `venus.ingredients.ingredient_id` | `child 1..1 -> parent 1..1; parent -> child 0..N` | `CASCADE` | `NO ACTION` |
| `ingredient_effects_fk_profile_tag_id_fkey` | `venus.ingredient_effects.fk_profile_tag_id` | `venus.profile_tags.profile_tag_id` | `child 1..1 -> parent 1..1; parent -> child 0..N` | `CASCADE` | `NO ACTION` |
| `ingredient_evidence_queue_fk_ingredient_id_fkey` | `venus.ingredient_evidence_queue.fk_ingredient_id` | `venus.ingredients.ingredient_id` | `child 1..1 -> parent 1..1; parent -> child 0..1` | `CASCADE` | `NO ACTION` |
| `ingredient_properties_fk_ingredient_id_fkey` | `venus.ingredient_properties.fk_ingredient_id` | `venus.ingredients.ingredient_id` | `child 1..1 -> parent 1..1; parent -> child 0..N` | `CASCADE` | `NO ACTION` |
| `ingredient_regulations_fk_ingredient_id_fkey` | `venus.ingredient_regulations.fk_ingredient_id` | `venus.ingredients.ingredient_id` | `child 1..1 -> parent 1..1; parent -> child 0..N` | `CASCADE` | `NO ACTION` |
| `ingredient_regulations_fk_regulation_id_fkey` | `venus.ingredient_regulations.fk_regulation_id` | `venus.regulations.regulation_id` | `child 1..1 -> parent 1..1; parent -> child 0..N` | `CASCADE` | `NO ACTION` |
| `ingredient_resolution_keys_fk_ingredient_id_fkey` | `venus.ingredient_resolution_keys.fk_ingredient_id` | `venus.ingredients.ingredient_id` | `child 1..1 -> parent 1..1; parent -> child 0..N` | `CASCADE` | `NO ACTION` |
| `ingredient_risk_assessments_fk_ingredient_id_fkey` | `venus.ingredient_risk_assessments.fk_ingredient_id` | `venus.ingredients.ingredient_id` | `child 1..1 -> parent 1..1; parent -> child 0..N` | `CASCADE` | `NO ACTION` |
| `ingredient_risk_methodology_dimensions_methodology_version_fkey` | `venus.ingredient_risk_methodology_dimensions.methodology_version` | `venus.ingredient_risk_methodologies.methodology_version` | `child 1..1 -> parent 1..1; parent -> child 0..N` | `RESTRICT` | `NO ACTION` |
| `ingredients_fk_ingredient_category_id_fkey` | `venus.ingredients.fk_ingredient_category_id` | `venus.ingredient_categories.ingredient_category_id` | `child 1..1 -> parent 1..1; parent -> child 0..N` | `RESTRICT` | `NO ACTION` |
| `media_assets_fk_product_version_id_fkey` | `venus.media_assets.fk_product_version_id` | `venus.product_versions.product_version_id` | `child 0..1 -> parent 1..1; parent -> child 0..N` | `CASCADE` | `NO ACTION` |
| `media_assets_fk_user_id_fkey` | `venus.media_assets.fk_user_id` | `venus.users.user_id` | `child 0..1 -> parent 1..1; parent -> child 0..N` | `CASCADE` | `NO ACTION` |
| `media_assets_fk_user_list_id_fkey` | `venus.media_assets.fk_user_list_id` | `venus.user_lists.user_list_id` | `child 0..1 -> parent 1..1; parent -> child 0..N` | `CASCADE` | `NO ACTION` |
| `packaging_fk_product_version_id_fkey` | `venus.packaging.fk_product_version_id` | `venus.product_versions.product_version_id` | `child 1..1 -> parent 1..1; parent -> child 0..1` | `CASCADE` | `NO ACTION` |
| `personalized_scores_fk_analysis_result_id_fkey` | `venus.personalized_scores.fk_analysis_result_id` | `venus.analysis_results.analysis_result_id` | `child 1..1 -> parent 1..1; parent -> child 0..N` | `CASCADE` | `NO ACTION` |
| `personalized_scores_fk_product_version_id_fkey` | `venus.personalized_scores.fk_product_version_id` | `venus.product_versions.product_version_id` | `child 1..1 -> parent 1..1; parent -> child 0..N` | `CASCADE` | `NO ACTION` |
| `personalized_scores_fk_scoring_model_id_fkey` | `venus.personalized_scores.fk_scoring_model_id` | `venus.scoring_models.scoring_model_id` | `child 1..1 -> parent 1..1; parent -> child 0..N` | `RESTRICT` | `NO ACTION` |
| `personalized_scores_fk_user_id_fkey` | `venus.personalized_scores.fk_user_id` | `venus.users.user_id` | `child 1..1 -> parent 1..1; parent -> child 0..N` | `CASCADE` | `NO ACTION` |
| `product_claims_fk_claim_id_fkey` | `venus.product_claims.fk_claim_id` | `venus.claims.claim_id` | `child 1..1 -> parent 1..1; parent -> child 0..N` | `RESTRICT` | `NO ACTION` |
| `product_claims_fk_product_version_id_fkey` | `venus.product_claims.fk_product_version_id` | `venus.product_versions.product_version_id` | `child 1..1 -> parent 1..1; parent -> child 0..N` | `CASCADE` | `NO ACTION` |
| `product_composition_receipts_fk_product_version_id_fkey` | `venus.product_composition_receipts.fk_product_version_id` | `venus.product_versions.product_version_id` | `child 1..1 -> parent 1..1; parent -> child 0..N` | `CASCADE` | `NO ACTION` |
| `product_dimension_assessments_fk_product_version_id_fkey` | `venus.product_dimension_assessments.fk_product_version_id` | `venus.product_versions.product_version_id` | `child 1..1 -> parent 1..1; parent -> child 0..N` | `CASCADE` | `NO ACTION` |
| `product_ingredient_resolution_issues_fk_product_version_id_fkey` | `venus.product_ingredient_resolution_issues.fk_product_version_id` | `venus.product_versions.product_version_id` | `child 1..1 -> parent 1..1; parent -> child 0..N` | `CASCADE` | `NO ACTION` |
| `product_ingredients_fk_ingredient_id_fkey` | `venus.product_ingredients.fk_ingredient_id` | `venus.ingredients.ingredient_id` | `child 1..1 -> parent 1..1; parent -> child 0..N` | `RESTRICT` | `NO ACTION` |
| `product_ingredients_fk_product_version_id_fkey` | `venus.product_ingredients.fk_product_version_id` | `venus.product_versions.product_version_id` | `child 1..1 -> parent 1..1; parent -> child 0..N` | `CASCADE` | `NO ACTION` |
| `product_labels_fk_product_version_id_fkey` | `venus.product_labels.fk_product_version_id` | `venus.product_versions.product_version_id` | `child 1..1 -> parent 1..1; parent -> child 0..1` | `CASCADE` | `NO ACTION` |
| `product_scores_fk_product_version_id_fkey` | `venus.product_scores.fk_product_version_id` | `venus.product_versions.product_version_id` | `child 1..1 -> parent 1..1; parent -> child 0..N` | `CASCADE` | `NO ACTION` |
| `product_scores_fk_scoring_model_id_fkey` | `venus.product_scores.fk_scoring_model_id` | `venus.scoring_models.scoring_model_id` | `child 1..1 -> parent 1..1; parent -> child 0..N` | `RESTRICT` | `NO ACTION` |
| `product_versions_fk_product_id_fkey` | `venus.product_versions.fk_product_id` | `venus.products.product_id` | `child 1..1 -> parent 1..1; parent -> child 0..N` | `CASCADE` | `NO ACTION` |
| `products_fk_brand_id_fkey` | `venus.products.fk_brand_id` | `venus.brands.brand_id` | `child 1..1 -> parent 1..1; parent -> child 0..N` | `RESTRICT` | `NO ACTION` |
| `products_fk_product_category_id_fkey` | `venus.products.fk_product_category_id` | `venus.product_categories.product_category_id` | `child 1..1 -> parent 1..1; parent -> child 0..N` | `RESTRICT` | `NO ACTION` |
| `recommendations_fk_analysis_result_id_fkey` | `venus.recommendations.fk_analysis_result_id` | `venus.analysis_results.analysis_result_id` | `child 1..1 -> parent 1..1; parent -> child 0..N` | `CASCADE` | `NO ACTION` |
| `recommendations_fk_product_version_id_fkey` | `venus.recommendations.fk_product_version_id` | `venus.product_versions.product_version_id` | `child 1..1 -> parent 1..1; parent -> child 0..N` | `CASCADE` | `NO ACTION` |
| `recommendations_fk_profile_tag_id_fkey` | `venus.recommendations.fk_profile_tag_id` | `venus.profile_tags.profile_tag_id` | `child 1..1 -> parent 1..1; parent -> child 0..N` | `CASCADE` | `NO ACTION` |
| `recommendations_fk_user_id_fkey` | `venus.recommendations.fk_user_id` | `venus.users.user_id` | `child 1..1 -> parent 1..1; parent -> child 0..N` | `CASCADE` | `NO ACTION` |
| `reports_fk_admin_user_id_fkey` | `venus.reports.fk_admin_user_id` | `venus.admin_users.admin_user_id` | `child 0..1 -> parent 1..1; parent -> child 0..N` | `SET NULL` | `NO ACTION` |
| `reports_fk_user_id_fkey` | `venus.reports.fk_user_id` | `venus.users.user_id` | `child 1..1 -> parent 1..1; parent -> child 0..N` | `CASCADE` | `NO ACTION` |
| `review_votes_fk_review_id_fkey` | `venus.review_votes.fk_review_id` | `venus.reviews.review_id` | `child 1..1 -> parent 1..1; parent -> child 0..N` | `CASCADE` | `NO ACTION` |
| `review_votes_fk_user_id_fkey` | `venus.review_votes.fk_user_id` | `venus.users.user_id` | `child 1..1 -> parent 1..1; parent -> child 0..N` | `CASCADE` | `NO ACTION` |
| `reviews_fk_product_version_id_fkey` | `venus.reviews.fk_product_version_id` | `venus.product_versions.product_version_id` | `child 1..1 -> parent 1..1; parent -> child 0..N` | `CASCADE` | `NO ACTION` |
| `reviews_fk_user_id_fkey` | `venus.reviews.fk_user_id` | `venus.users.user_id` | `child 1..1 -> parent 1..1; parent -> child 0..N` | `CASCADE` | `NO ACTION` |
| `rule_evaluations_fk_analysis_result_id_fkey` | `venus.rule_evaluations.fk_analysis_result_id` | `venus.analysis_results.analysis_result_id` | `child 1..1 -> parent 1..1; parent -> child 0..N` | `CASCADE` | `NO ACTION` |
| `rule_evaluations_fk_compatibility_rule_id_fkey` | `venus.rule_evaluations.fk_compatibility_rule_id` | `venus.compatibility_rules.compatibility_rule_id` | `child 1..1 -> parent 1..1; parent -> child 0..N` | `CASCADE` | `NO ACTION` |
| `rule_evaluations_fk_ingredient_id_fkey` | `venus.rule_evaluations.fk_ingredient_id` | `venus.ingredients.ingredient_id` | `child 1..1 -> parent 1..1; parent -> child 0..N` | `RESTRICT` | `NO ACTION` |
| `rule_evaluations_fk_profile_tag_id_fkey` | `venus.rule_evaluations.fk_profile_tag_id` | `venus.profile_tags.profile_tag_id` | `child 1..1 -> parent 1..1; parent -> child 0..N` | `CASCADE` | `NO ACTION` |
| `scoring_model_categories_fk_score_category_id_fkey` | `venus.scoring_model_categories.fk_score_category_id` | `venus.score_categories.score_category_id` | `child 1..1 -> parent 1..1; parent -> child 0..N` | `RESTRICT` | `NO ACTION` |
| `scoring_model_categories_fk_scoring_model_id_fkey` | `venus.scoring_model_categories.fk_scoring_model_id` | `venus.scoring_models.scoring_model_id` | `child 1..1 -> parent 1..1; parent -> child 0..N` | `CASCADE` | `NO ACTION` |
| `user_access_events_fk_user_id_fkey` | `venus.user_access_events.fk_user_id` | `venus.users.user_id` | `child 1..1 -> parent 1..1; parent -> child 0..N` | `CASCADE` | `NO ACTION` |
| `user_allergies_fk_allergy_id_fkey` | `venus.user_allergies.fk_allergy_id` | `venus.allergies.allergy_id` | `child 1..1 -> parent 1..1; parent -> child 0..N` | `CASCADE` | `NO ACTION` |
| `user_allergies_fk_user_id_fkey` | `venus.user_allergies.fk_user_id` | `venus.users.user_id` | `child 1..1 -> parent 1..1; parent -> child 0..N` | `CASCADE` | `NO ACTION` |
| `user_list_items_fk_product_id_fkey` | `venus.user_list_items.fk_product_id` | `venus.products.product_id` | `child 1..1 -> parent 1..1; parent -> child 0..N` | `CASCADE` | `NO ACTION` |
| `user_list_items_fk_user_list_id_fkey` | `venus.user_list_items.fk_user_list_id` | `venus.user_lists.user_list_id` | `child 1..1 -> parent 1..1; parent -> child 0..N` | `CASCADE` | `NO ACTION` |
| `user_lists_fk_user_id_fkey` | `venus.user_lists.fk_user_id` | `venus.users.user_id` | `child 1..1 -> parent 1..1; parent -> child 0..N` | `CASCADE` | `NO ACTION` |
| `user_preferences_fk_user_id_fkey` | `venus.user_preferences.fk_user_id` | `venus.users.user_id` | `child 1..1 -> parent 1..1; parent -> child 0..1` | `CASCADE` | `NO ACTION` |
| `user_profile_tags_fk_profile_tag_id_fkey` | `venus.user_profile_tags.fk_profile_tag_id` | `venus.profile_tags.profile_tag_id` | `child 1..1 -> parent 1..1; parent -> child 0..N` | `CASCADE` | `NO ACTION` |
| `user_profile_tags_fk_user_id_fkey` | `venus.user_profile_tags.fk_user_id` | `venus.users.user_id` | `child 1..1 -> parent 1..1; parent -> child 0..N` | `CASCADE` | `NO ACTION` |
| `user_profiles_fk_user_id_fkey` | `venus.user_profiles.fk_user_id` | `venus.users.user_id` | `child 1..1 -> parent 1..1; parent -> child 0..1` | `CASCADE` | `NO ACTION` |
| `user_tracking_events_fk_user_id_fkey` | `venus.user_tracking_events.fk_user_id` | `venus.users.user_id` | `child 0..1 -> parent 1..1; parent -> child 0..N` | `SET NULL` | `NO ACTION` |
| `rpa_error_batch_id_fkey` | `venus_rpa.rpa_error.batch_id` | `venus_rpa.rpa_run.batch_id` | `child 1..1 -> parent 1..1; parent -> child 0..N` | `CASCADE` | `NO ACTION` |
| `rpa_stage_product_batch_id_fkey` | `venus_rpa.rpa_stage_product.batch_id` | `venus_rpa.rpa_run.batch_id` | `child 1..1 -> parent 1..1; parent -> child 0..N` | `CASCADE` | `NO ACTION` |
| `rpa_stage_product_loaded_product_id_fkey` | `venus_rpa.rpa_stage_product.loaded_product_id` | `venus.products.product_id` | `child 0..1 -> parent 1..1; parent -> child 0..N` | `SET NULL` | `NO ACTION` |
| `rpa_stage_user_batch_id_fkey` | `venus_rpa.rpa_stage_user.batch_id` | `venus_rpa.rpa_run.batch_id` | `child 1..1 -> parent 1..1; parent -> child 0..N` | `CASCADE` | `NO ACTION` |
| `rpa_stage_user_loaded_user_id_fkey` | `venus_rpa.rpa_stage_user.loaded_user_id` | `venus.users.user_id` | `child 0..1 -> parent 1..1; parent -> child 0..N` | `SET NULL` | `NO ACTION` |

## Tipos enum

| Tipo | Valores |
|---|---|
| `venus.admin_role_enum` | `admin`, `moderator`, `analyst` |
| `venus.age_range_enum` | `age_13_17`, `age_18_24`, `age_25_34`, `age_35_44`, `age_45_54`, `age_55_plus` |
| `venus.allergy_type_enum` | `ingredient`, `material`, `condition`, `other` |
| `venus.analysis_status_enum` | `processing`, `completed`, `failed`, `pending_review` |
| `venus.claim_type_enum` | `safety`, `ethical`, `sustainability`, `marketing`, `performance`, `other` |
| `venus.effect_category_enum` | `benefit`, `risk`, `warning`, `contraindication`, `neutral` |
| `venus.effect_strength_enum` | `light`, `moderate`, `strong`, `very_strong` |
| `venus.effect_type_enum` | `bonus`, `penalty`, `alert`, `block`, `neutral` |
| `venus.evidence_level_enum` | `low`, `medium`, `high`, `very_high` |
| `venus.gender_enum` | `female`, `male`, `non_binary`, `other`, `prefer_not_say` |
| `venus.hair_pattern_enum` | `1A`, `1B`, `1C`, `2A`, `2B`, `2C`, `3A`, `3B`, `3C`, `4A`, `4B`, `4C`, `other` |
| `venus.list_type_enum` | `shopping`, `routine`, `favorites`, `custom` |
| `venus.packaging_format_enum` | `bottle`, `tube`, `jar`, `pump`, `spray`, `sachet`, `box`, `refill`, `stick`, `other` |
| `venus.packaging_material_enum` | `plastic`, `glass`, `metal`, `paper`, `cardboard`, `mixed`, `other` |
| `venus.profile_tag_category_enum` | `skin`, `hair`, `health`, `values`, `sustainability`, `allergy`, `other` |
| `venus.recommendation_level_enum` | `ideal`, `recommended`, `acceptable`, `not_recommended`, `contraindicated` |
| `venus.recommendation_type_enum` | `ideal`, `recommended`, `acceptable`, `not_recommended`, `contraindicated`, `alternative` |
| `venus.regulation_status_enum` | `draft`, `active`, `deprecated` |
| `venus.report_status_enum` | `open`, `in_review`, `resolved`, `rejected` |
| `venus.report_target_type_enum` | `product`, `review`, `ingredient`, `user`, `other` |
| `venus.restriction_type_enum` | `prohibited`, `restricted`, `limited`, `warning` |
| `venus.review_status_enum` | `pending`, `validated`, `under_review`, `deprecated` |
| `venus.risk_level_enum` | `low`, `medium`, `high`, `critical` |
| `venus.scalp_type_enum` | `normal`, `dry`, `oily`, `sensitive`, `dandruff`, `other` |
| `venus.sensitivity_level_enum` | `low`, `medium`, `high`, `very_high` |
| `venus.skin_phototype_enum` | `i`, `ii`, `iii`, `iv`, `v`, `vi` |
| `venus.skin_type_enum` | `normal`, `dry`, `oily`, `combination`, `sensitive`, `acneic`, `other` |
| `venus.source_type_enum` | `ocr`, `official_site`, `admin`, `user_submission`, `import`, `system` |
| `venus.user_status_enum` | `active`, `inactive`, `blocked`, `pending` |
| `venus.version_status_enum` | `pending`, `verified`, `needs_review`, `deprecated` |
| `venus.vote_type_enum` | `useful`, `not_useful` |

## Views e materialized views

| Schema | Nome | Tipo | Descrição |
|---|---|---|---|
| `venus` | `v_available_allergies` | view | — |
| `venus` | `v_brand_claim_status` | view | Status ético por marca: verified, explicit_negative, conflict ou unknown. NULL não deve ser tratado como false sem evidência. |
| `venus` | `v_data_catalog_columns` | view | — |
| `venus` | `v_data_catalog_tables` | view | — |
| `venus` | `v_dau` | view | — |
| `venus` | `v_dau_rolling_30d` | view | — |
| `venus` | `v_ingredient_category_links` | view | — |
| `venus` | `v_ingredient_category_tree` | view | — |
| `venus` | `v_ingredient_evaluation_status` | view | Contrato de avaliação: confidence padrão não é avaliação; is_really_evaluated exige quatro assessments v2 com fonte. |
| `venus` | `v_ingredient_risk_coverage` | view | — |
| `venus` | `v_ingredient_risk_inference_v1` | view | Regra determinística v1 para inferência conservadora; os scores aprovados carregam evidence_level=low e não são conclusões toxicológicas diretas. |
| `venus` | `v_ingredient_risk_inference_v2` | view | — |
| `venus` | `v_packaging_evaluation_status` | view | Contrato v1: embalagem ausente ou sem evidência fica unknown e não deve ser preenchida por inferência. |
| `venus` | `v_product_fragrance_flags` | view | Contrato consumível pelo backend/mobile para o aviso Contém fragrância baseado na categoria canônica. |
| `venus` | `v_product_photos` | view | — |
| `venus` | `v_product_score_readiness` | view | — |
| `venus` | `v_user_avatars` | view | — |
| `venus` | `v_user_list_covers` | view | — |
| `venus_bi` | `dim_brand` | view | — |
| `venus_bi` | `dim_claim` | view | — |
| `venus_bi` | `dim_date` | view | — |
| `venus_bi` | `dim_ingredient` | view | — |
| `venus_bi` | `dim_ingredient_category` | view | — |
| `venus_bi` | `dim_product` | view | — |
| `venus_bi` | `dim_product_category` | view | — |
| `venus_bi` | `dim_product_version` | view | — |
| `venus_bi` | `dim_profile_tag` | view | — |
| `venus_bi` | `dim_regulation` | view | — |
| `venus_bi` | `dim_scoring_model` | view | — |
| `venus_bi` | `dim_user` | view | — |
| `venus_bi` | `fact_analysis_result` | view | — |
| `venus_bi` | `fact_ingredient_effect` | view | — |
| `venus_bi` | `fact_packaging` | view | — |
| `venus_bi` | `fact_personalized_score` | view | — |
| `venus_bi` | `fact_product_claim` | view | — |
| `venus_bi` | `fact_product_ingredient` | view | — |
| `venus_bi` | `fact_product_score` | view | — |
| `venus_bi` | `fact_recommendation` | view | — |
| `venus_bi` | `fact_review` | view | — |
| `venus_bi` | `vw_analysis_kpi` | view | — |
| `venus_bi` | `vw_analysis_temporal_windows` | view | — |
| `venus_bi` | `vw_competitive_product_ranking` | view | — |
| `venus_bi` | `vw_ingredient_overview` | view | — |
| `venus_bi` | `vw_ingredient_risk_analysis` | view | — |
| `venus_bi` | `vw_ingredient_usage_ranking` | view | — |
| `venus_bi` | `vw_product_ingredient_effect` | view | — |
| `venus_bi` | `vw_product_overview` | view | — |
| `venus_bi` | `vw_product_score_ranking` | view | — |
| `venus_bi` | `vw_recommendation_kpi` | view | — |
| `venus_bi` | `vw_sql_advanced_requirements_status` | view | — |
| `venus_bi` | `vw_user_recommendation_ranking` | view | — |

## Regra de atualização

Este documento é gerado por `python ops/generate_database_model.py` após uma alteração de schema ou migração. O gerador consulta somente metadados e não cria, altera ou remove objetos no banco. Os arquivos brM3 em `docs/modelos lógicos/` continuam sendo os desenhos visuais editáveis.
