-- Venus — fragrância canônica, estado de confidence e fila de evidência — 2026-10-11
--
-- Esta migração não executa a classificação nem cria product_scores.
-- Ela normaliza os ingredientes de fragrância, expõe um contrato de aviso para
-- o backend/mobile e separa confidence padrão de confidence derivado/curado.

BEGIN;

SET LOCAL lock_timeout = '10s';
SET LOCAL statement_timeout = '180s';
SET LOCAL search_path TO venus, public;

DO $$
DECLARE
    v_agent_category BIGINT;
BEGIN
    SELECT ingredient_category_id
      INTO v_agent_category
      FROM venus.ingredient_categories
     WHERE name = 'Agente Perfumante';

    IF v_agent_category IS NULL OR v_agent_category <> 25 THEN
        RAISE EXCEPTION 'Categoria Agente Perfumante ausente ou com ID inesperado: %', v_agent_category;
    END IF;

    IF NOT EXISTS (
        SELECT 1
          FROM venus.ingredients
         WHERE ingredient_id = 8104
           AND inci_name = 'PARFUM'
    ) THEN
        RAISE EXCEPTION 'Ingrediente PARFUM (8104) não encontrado';
    END IF;

    IF NOT EXISTS (
        SELECT 1
          FROM venus.ingredients
         WHERE ingredient_id = 8202
           AND inci_name = 'PARFUM / FRAGRANCE'
    ) THEN
        RAISE EXCEPTION 'Ingrediente PARFUM / FRAGRANCE (8202) não encontrado';
    END IF;
END;
$$;

-- Os dois registros permanecem preservados para compatibilidade histórica,
-- mas passam a compartilhar a categoria canônica e os dados exibidos.
UPDATE venus.ingredients
   SET fk_ingredient_category_id = 25,
       common_name = 'Fragrância',
       function_summary = 'Agente perfumante: confere ou compõe o aroma do produto.',
       updated_at = NOW()
 WHERE ingredient_id IN (8104, 8202);

-- PARFUM é o registro canônico para novas resoluções de FRAGRANCE/AROMA.
-- PARFUM / FRAGRANCE continua como INCI histórico para os rótulos que o usam.
INSERT INTO venus.ingredient_aliases (
    fk_ingredient_id,
    alias_name,
    alias_language,
    source_type,
    source_reference
)
VALUES
    (8104, 'FRAGRANCE', 'en', 'admin', 'migration:20261011_001_fragrance_canonical_confidence_evidence'),
    (8104, 'PARFUM / FRAGRANCE', 'en', 'admin', 'migration:20261011_001_fragrance_canonical_confidence_evidence'),
    (8104, 'AROMA', 'en', 'admin', 'migration:20261011_001_fragrance_canonical_confidence_evidence; cosmetic-context-only')
ON CONFLICT (fk_ingredient_id, alias_name, alias_language) DO UPDATE SET
    source_type = EXCLUDED.source_type,
    source_reference = EXCLUDED.source_reference,
    updated_at = NOW();

-- Mantém o valor numérico positivo exigido pelo contrato legado, mas deixa
-- explícito se ele é apenas o fallback 1, um valor derivado ou uma avaliação
-- curada com evidência específica.
ALTER TABLE venus.ingredients
    ADD COLUMN IF NOT EXISTS scientific_confidence_state TEXT NOT NULL DEFAULT 'default';

ALTER TABLE venus.ingredients
    DROP CONSTRAINT IF EXISTS ck_ingredients_scientific_confidence_state;

ALTER TABLE venus.ingredients
    ADD CONSTRAINT ck_ingredients_scientific_confidence_state
    CHECK (scientific_confidence_state IN ('default', 'derived', 'curated'));

UPDATE venus.ingredients
   SET scientific_confidence_state = CASE
       WHEN scientific_confidence = 1 THEN 'default'
       ELSE 'derived'
   END,
       updated_at = NOW()
 WHERE scientific_confidence_state <> 'curated';

CREATE INDEX IF NOT EXISTS idx_ingredients_scientific_confidence_state
    ON venus.ingredients (scientific_confidence_state);

CREATE OR REPLACE FUNCTION venus.fn_normalize_scientific_confidence_state()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.scientific_confidence_state IS NULL
       OR NEW.scientific_confidence_state NOT IN ('default', 'derived', 'curated') THEN
        NEW.scientific_confidence_state := 'default';
    END IF;

    IF NEW.scientific_confidence_state <> 'curated' THEN
        NEW.scientific_confidence_state := CASE
            WHEN NEW.scientific_confidence = 1 THEN 'default'
            ELSE 'derived'
        END;
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_normalize_scientific_confidence_state
    ON venus.ingredients;
CREATE TRIGGER trg_normalize_scientific_confidence_state
BEFORE INSERT OR UPDATE OF scientific_confidence, scientific_confidence_state
ON venus.ingredients
FOR EACH ROW
EXECUTE FUNCTION venus.fn_normalize_scientific_confidence_state();

-- Fila persistente para substituir gradualmente os proxies v1/low por
-- evidência específica. A fila não altera os assessments atuais e, portanto,
-- não transforma ausência de fonte em score zero nem bloqueia os produtos.
CREATE TABLE IF NOT EXISTS venus.ingredient_evidence_queue (
    ingredient_evidence_queue_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fk_ingredient_id BIGINT NOT NULL
        REFERENCES venus.ingredients(ingredient_id) ON DELETE CASCADE,
    priority SMALLINT NOT NULL CHECK (priority BETWEEN 1 AND 100),
    is_currently_used BOOLEAN NOT NULL DEFAULT FALSE,
    queue_status TEXT NOT NULL DEFAULT 'queued'
        CHECK (queue_status IN ('queued', 'in_progress', 'completed', 'blocked')),
    target_evidence_level evidence_level_enum NOT NULL DEFAULT 'medium',
    reason TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (fk_ingredient_id)
);

CREATE INDEX IF NOT EXISTS idx_ingredient_evidence_queue_priority
    ON venus.ingredient_evidence_queue (queue_status, priority, is_currently_used DESC);

WITH used AS (
    SELECT DISTINCT pi.fk_ingredient_id AS ingredient_id
      FROM venus.product_versions pv
      JOIN venus.product_ingredients pi
        ON pi.fk_product_version_id = pv.product_version_id
     WHERE pv.is_current
), targets AS (
    SELECT i.ingredient_id,
           (u.ingredient_id IS NOT NULL) AS is_currently_used,
           CASE
               WHEN u.ingredient_id IS NOT NULL AND i.scientific_confidence = 1 THEN 1
               WHEN u.ingredient_id IS NOT NULL THEN 2
               ELSE 3
           END::SMALLINT AS priority,
           CASE
               WHEN i.scientific_confidence = 1
                   THEN 'Confidence está no fallback 1; requer fonte específica e avaliação científica.'
               ELSE 'Avaliação atual é proxy indireta v1/low; requer substituição por evidência específica.'
           END AS reason
      FROM venus.ingredients i
      LEFT JOIN used u ON u.ingredient_id = i.ingredient_id
     WHERE i.scientific_confidence = 1
        OR EXISTS (
            SELECT 1
              FROM venus.ingredient_risk_assessments ira
             WHERE ira.fk_ingredient_id = i.ingredient_id
               AND ira.assessment_status = 'approved'
               AND ira.assessment_version = 'v1'
               AND ira.evidence_level = 'low'
        )
)
INSERT INTO venus.ingredient_evidence_queue (
    fk_ingredient_id,
    priority,
    is_currently_used,
    queue_status,
    target_evidence_level,
    reason
)
SELECT ingredient_id,
       priority,
       is_currently_used,
       'queued',
       'medium',
       reason
  FROM targets
ON CONFLICT (fk_ingredient_id) DO UPDATE SET
    priority = LEAST(venus.ingredient_evidence_queue.priority, EXCLUDED.priority),
    is_currently_used = EXCLUDED.is_currently_used,
    reason = EXCLUDED.reason,
    updated_at = NOW()
 WHERE venus.ingredient_evidence_queue.queue_status <> 'completed';

-- Estado consumível pelo backend: 1/default não é tratado como avaliação
-- científica; v1/low é explicitamente indireto; medium+ representa evidência
-- mais forte quando for carregada na tabela de assessments.
CREATE OR REPLACE VIEW venus.v_ingredient_evaluation_status AS
WITH approved AS (
    SELECT ira.fk_ingredient_id,
           COUNT(DISTINCT ira.dimension) AS approved_dimensions,
           BOOL_OR(ira.evidence_level IN ('medium', 'high', 'very_high')) AS has_stronger_evidence,
           MIN(ira.assessment_version) AS assessment_version,
           MIN(ira.evidence_level::TEXT) AS lowest_evidence_level
      FROM venus.ingredient_risk_assessments ira
     WHERE ira.assessment_status = 'approved'
     GROUP BY ira.fk_ingredient_id
)
SELECT i.ingredient_id,
       i.inci_name,
       i.scientific_confidence,
       i.scientific_confidence_state,
       COALESCE(a.approved_dimensions, 0)::INTEGER AS approved_risk_dimensions,
       COALESCE(a.approved_dimensions, 0) = 4 AS has_four_approved_risk_dimensions,
       COALESCE(a.has_stronger_evidence, FALSE) AS has_stronger_evidence,
       COALESCE(a.assessment_version, '') AS assessment_version,
       COALESCE(a.lowest_evidence_level, '') AS lowest_evidence_level,
       CASE
           WHEN i.scientific_confidence_state = 'default' THEN 'default'
           WHEN COALESCE(a.approved_dimensions, 0) = 4
                AND COALESCE(a.has_stronger_evidence, FALSE) THEN 'assessed'
           WHEN COALESCE(a.approved_dimensions, 0) = 4 THEN 'indirect_v1'
           ELSE 'derived_without_complete_risk_assessment'
       END AS evaluation_state
  FROM venus.ingredients i
  LEFT JOIN approved a ON a.fk_ingredient_id = i.ingredient_id;

-- Contrato de dados para o aviso do mobile. O aviso é derivado da categoria
-- canônica, e não de uma lista fixa de IDs ou de um texto específico do OCR.
CREATE OR REPLACE VIEW venus.v_product_fragrance_flags AS
SELECT pv.product_version_id,
       pv.fk_product_id AS product_id,
       pv.is_current,
       COALESCE(BOOL_OR(cl.category_name IN ('Fragrância', 'Agente Perfumante')), FALSE)
           AS contains_fragrance,
       CASE
           WHEN COALESCE(BOOL_OR(cl.category_name IN ('Fragrância', 'Agente Perfumante')), FALSE)
               THEN 'Contém fragrância'
           ELSE NULL
       END AS warning_text,
       ARRAY_REMOVE(
           ARRAY_AGG(DISTINCT i.ingredient_id)
               FILTER (WHERE cl.category_name IN ('Fragrância', 'Agente Perfumante')),
           NULL
       ) AS fragrance_ingredient_ids
  FROM venus.product_versions pv
  LEFT JOIN venus.product_ingredients pi
    ON pi.fk_product_version_id = pv.product_version_id
  LEFT JOIN venus.ingredients i
    ON i.ingredient_id = pi.fk_ingredient_id
  LEFT JOIN venus.v_ingredient_category_links cl
    ON cl.ingredient_id = i.ingredient_id
 GROUP BY pv.product_version_id, pv.fk_product_id, pv.is_current;

CREATE OR REPLACE FUNCTION venus.fn_product_contains_fragrance(
    p_product_version_id BIGINT
)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
AS $$
    SELECT COALESCE(v.contains_fragrance, FALSE)
      FROM venus.v_product_fragrance_flags v
     WHERE v.product_version_id = p_product_version_id;
$$;

COMMENT ON COLUMN venus.ingredients.scientific_confidence_state IS
    'default = fallback 1 sem avaliação específica; derived = valor calculado por regra; curated = evidência específica revisada.';
COMMENT ON TABLE venus.ingredient_evidence_queue IS
    'Fila de curadoria para substituir assessments indiretos v1/low e confidence default por evidência específica.';
COMMENT ON VIEW venus.v_ingredient_evaluation_status IS
    'Contrato de avaliação: diferencia fallback, proxy indireto e avaliação com evidência medium/high/very_high.';
COMMENT ON VIEW venus.v_product_fragrance_flags IS
    'Contrato consumível pelo backend/mobile para o aviso Contém fragrância baseado na categoria canônica.';

-- Recalcula apenas os dois ingredientes normalizados; não executa a API.
SELECT venus.fn_refresh_ingredient_risk_assessment_v1(ingredient_id)
  FROM venus.ingredients
 WHERE ingredient_id IN (8104, 8202);

COMMIT;
