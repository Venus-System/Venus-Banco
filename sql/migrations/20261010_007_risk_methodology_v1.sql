-- Venus — metodologia versionada para risco de ingredientes — 2026-10-10
--
-- A metodologia define como evidências aprovadas podem virar scores 0–10.
-- Ela não cria avaliações automaticamente nem trata ausência de evidência como
-- risco zero.

BEGIN;

SET LOCAL lock_timeout = '10s';
SET LOCAL statement_timeout = '120s';
SET LOCAL search_path TO venus, public;

CREATE TABLE IF NOT EXISTS venus.ingredient_risk_methodologies (
    methodology_version TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('draft', 'active', 'retired')),
    score_semantics TEXT NOT NULL,
    unknown_policy TEXT NOT NULL,
    source_hierarchy JSONB NOT NULL,
    effective_from DATE NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS venus.ingredient_risk_methodology_dimensions (
    methodology_version TEXT NOT NULL
        REFERENCES venus.ingredient_risk_methodologies(methodology_version)
        ON DELETE RESTRICT,
    dimension TEXT NOT NULL CHECK (dimension IN (
        'irritation_risk_level',
        'comedogenicity_score',
        'biodegradability_level',
        'environmental_risk_level'
    )),
    score_direction TEXT NOT NULL,
    definition TEXT NOT NULL,
    required_evidence JSONB NOT NULL,
    anchors JSONB NOT NULL,
    PRIMARY KEY (methodology_version, dimension)
);

INSERT INTO venus.ingredient_risk_methodologies (
    methodology_version,
    name,
    status,
    score_semantics,
    unknown_policy,
    source_hierarchy,
    effective_from
)
VALUES (
    'v1',
    'Baseline de risco de ingrediente — Venus',
    'active',
    'Todos os quatro eixos representam carga de risco: 0 é menor risco e 10 é maior risco. O score é intrínseco ao ingrediente e não substitui avaliação de fórmula/concentração.',
    'Ausência de evidência não recebe score. Fica pending e bloqueia a prontidão.',
    jsonb_build_array(
        jsonb_build_object('rank', 1, 'source', 'SCCS/EU Commission', 'url', 'https://health.ec.europa.eu/scientific-committees/scientific-committee-consumer-safety-sccs_en'),
        jsonb_build_object('rank', 2, 'source', 'EU Cosmetics Regulation and Annexes', 'url', 'https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX:02009R1223-20230801'),
        jsonb_build_object('rank', 3, 'source', 'ECHA CHEM / REACH / CLP', 'url', 'https://echa.europa.eu/information-on-chemicals'),
        jsonb_build_object('rank', 4, 'source', 'Peer-reviewed or authoritative assessment', 'url', 'https://health.ec.europa.eu/publications/checklists-applicants-submitting-dossiers-cosmetic-ingredients-be-evaluated-sccs_en'),
        jsonb_build_object('rank', 5, 'source', 'CosIng nomenclature/function data', 'url', 'https://single-market-economy.ec.europa.eu/sectors/cosmetics/cosmetic-ingredient-database_en')
    ),
    DATE '2026-10-10'
)
ON CONFLICT (methodology_version) DO UPDATE SET
    name = EXCLUDED.name,
    status = EXCLUDED.status,
    score_semantics = EXCLUDED.score_semantics,
    unknown_policy = EXCLUDED.unknown_policy,
    source_hierarchy = EXCLUDED.source_hierarchy,
    effective_from = EXCLUDED.effective_from,
    updated_at = NOW();

INSERT INTO venus.ingredient_risk_methodology_dimensions (
    methodology_version,
    dimension,
    score_direction,
    definition,
    required_evidence,
    anchors
)
VALUES
(
    'v1',
    'irritation_risk_level',
    'higher_is_more_risk',
    'Potencial intrínseco de irritação/sensibilização cutânea em uso cosmético, sem presumir concentração não informada.',
    jsonb_build_object('minimum', 'evidence of irritation, sensitisation, restriction or authoritative safety conclusion', 'forbidden', 'infer score only from ingredient function, pH assumption or absence of a CosIng restriction'),
    jsonb_build_object('0', 'evidence of negligible or no relevant irritation risk', '2', 'low concern', '4', 'limited or weak concern', '6', 'documented moderate concern', '8', 'strong concern or significant restriction', '10', 'critical hazard, prohibition or authoritative conclusion of unacceptable risk')
),
(
    'v1',
    'comedogenicity_score',
    'higher_is_more_risk',
    'Potencial de obstrução folicular baseado em evidência específica de comedogenicidade; função emoliente ou textura não é suficiente.',
    jsonb_build_object('minimum', 'direct comedogenicity or follicular-occlusion evidence', 'forbidden', 'infer score from oiliness, molecular weight, natural origin or marketing claims'),
    jsonb_build_object('0', 'direct evidence of negligible or non-comedogenic potential', '2', 'very low concern', '4', 'low concern', '6', 'moderate concern', '8', 'high concern', '10', 'strong direct evidence of severe comedogenic potential')
),
(
    'v1',
    'biodegradability_level',
    'higher_is_more_persistence_risk',
    'Dificuldade de biodegradação/persistência ambiental. 0 significa facilmente biodegradável; 10 significa baixa biodegradabilidade ou persistência elevada.',
    jsonb_build_object('minimum', 'standard biodegradation, persistence or environmental fate data', 'forbidden', 'infer biodegradability from natural, plant-derived, synthetic or mineral origin alone'),
    jsonb_build_object('0', 'readily biodegradable', '2', 'high biodegradation with minor uncertainty', '4', 'biodegradable but incomplete or context-dependent evidence', '6', 'slow or uncertain biodegradation', '8', 'low biodegradation or persistence concern', '10', 'very persistent or authoritative P/vP conclusion')
),
(
    'v1',
    'environmental_risk_level',
    'higher_is_more_risk',
    'Perigo ambiental intrínseco, priorizando toxicidade aquática, PBT/vPvB e classificações regulatórias ambientais.',
    jsonb_build_object('minimum', 'aquatic toxicity, PBT/vPvB, CLP or authoritative environmental assessment', 'forbidden', 'infer from biodegradability alone or from a product marketing claim'),
    jsonb_build_object('0', 'no relevant environmental hazard identified in adequate data', '2', 'very low concern', '4', 'low concern', '6', 'moderate aquatic or fate concern', '8', 'high concern or regulated hazard', '10', 'very toxic, PBT/vPvB or equivalent critical conclusion')
)
ON CONFLICT (methodology_version, dimension) DO UPDATE SET
    score_direction = EXCLUDED.score_direction,
    definition = EXCLUDED.definition,
    required_evidence = EXCLUDED.required_evidence,
    anchors = EXCLUDED.anchors;

ALTER TABLE venus.ingredient_risk_assessments
    ADD COLUMN IF NOT EXISTS evidence_level evidence_level_enum NOT NULL DEFAULT 'low';

ALTER TABLE venus.ingredient_risk_assessments
    ADD COLUMN IF NOT EXISTS rationale TEXT NOT NULL DEFAULT '';

ALTER TABLE venus.ingredient_risk_assessments
    ADD COLUMN IF NOT EXISTS assessment_scope TEXT NOT NULL DEFAULT 'ingredient_baseline';

COMMENT ON TABLE venus.ingredient_risk_methodologies IS
    'Versões auditáveis das regras que convertem evidência em scores 0–10.';
COMMENT ON TABLE venus.ingredient_risk_methodology_dimensions IS
    'Definição, evidência mínima e âncoras por eixo da metodologia ativa.';
COMMENT ON COLUMN venus.ingredient_risk_assessments.evidence_level IS
    'Força da evidência que sustenta o assessment; não é o confidence_score do produto.';

CREATE OR REPLACE VIEW venus.v_ingredient_risk_coverage AS
WITH used AS (
    SELECT DISTINCT pi.fk_ingredient_id AS ingredient_id
      FROM venus.product_versions pv
      JOIN venus.product_ingredients pi
        ON pi.fk_product_version_id = pv.product_version_id
     WHERE pv.is_current
), approved AS (
    SELECT ira.fk_ingredient_id AS ingredient_id,
           COUNT(DISTINCT ira.dimension) AS approved_dimensions,
           MIN(ira.assessment_version) AS methodology_version,
           MIN(ira.evidence_level::TEXT) AS lowest_evidence_level
      FROM venus.ingredient_risk_assessments ira
     WHERE ira.assessment_status = 'approved'
     GROUP BY ira.fk_ingredient_id
)
SELECT i.ingredient_id,
       i.inci_name,
       i.source_reference,
       COALESCE(a.approved_dimensions, 0) AS approved_dimensions,
       COALESCE(a.approved_dimensions, 0) = 4 AS has_four_approved_dimensions,
       a.methodology_version,
       a.lowest_evidence_level
  FROM used u
  JOIN venus.ingredients i ON i.ingredient_id = u.ingredient_id
  LEFT JOIN approved a ON a.ingredient_id = i.ingredient_id;

COMMIT;
