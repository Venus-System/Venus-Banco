-- Venus — guardrails de qualidade para o cálculo de classificação — 2026-10-10
--
-- Esta migration não calcula nem insere scores. Ela torna explícita a
-- preparação dos dados que a Venus-Classificacao consome e bloqueia a gravação
-- de scores quando a entrada ainda é incompleta.
--
-- Decisões importantes:
--   * os quatro campos de risco de ingredients continuam NOT NULL/0 para não
--     quebrar o contrato atual da API; 0 sozinho NÃO é mais considerado uma
--     avaliação. A avaliação aprovada fica registrada abaixo.
--   * não são inventados valores científicos. O estado atual será marcado como
--     needs_review até que fontes reais sejam aprovadas.
--   * product_scores antigos de versões que não estão prontas são preservados
--     em histórico e removidos da tabela operacional para não aparecerem no app.
--   * a composição bruta passa a ser um recibo obrigatório. O RPA existente é
--     integrado automaticamente; novas cargas devem usar a função de registro.

CREATE TABLE IF NOT EXISTS venus.ingredient_risk_assessments (
    ingredient_risk_assessment_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fk_ingredient_id BIGINT NOT NULL
        REFERENCES venus.ingredients(ingredient_id) ON DELETE CASCADE,
    dimension TEXT NOT NULL
        CHECK (dimension IN (
            'irritation_risk_level',
            'comedogenicity_score',
            'biodegradability_level',
            'environmental_risk_level'
        )),
    score SMALLINT NOT NULL CHECK (score BETWEEN 0 AND 10),
    assessment_status TEXT NOT NULL DEFAULT 'pending'
        CHECK (assessment_status IN ('pending', 'approved', 'rejected')),
    source_type TEXT NOT NULL DEFAULT 'manual',
    source_reference TEXT NOT NULL DEFAULT '',
    assessment_version TEXT NOT NULL DEFAULT 'v1',
    assessed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT ck_ingredient_risk_assessment_source
        CHECK (assessment_status <> 'approved' OR BTRIM(source_reference) <> ''),
    UNIQUE (fk_ingredient_id, dimension, assessment_version)
);

CREATE INDEX IF NOT EXISTS idx_ingredient_risk_assessments_ingredient
    ON venus.ingredient_risk_assessments (fk_ingredient_id, assessment_status);

CREATE TABLE IF NOT EXISTS venus.product_composition_receipts (
    product_composition_receipt_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fk_product_version_id BIGINT NOT NULL
        REFERENCES venus.product_versions(product_version_id) ON DELETE CASCADE,
    source_type TEXT NOT NULL,
    source_reference TEXT NOT NULL DEFAULT '',
    raw_ingredients_text TEXT NOT NULL DEFAULT '',
    formula_hash TEXT,
    validation_status TEXT NOT NULL
        CHECK (validation_status IN ('VALID', 'WARNING', 'INVALID', 'LEGACY_UNVERIFIED')),
    expected_count INTEGER NOT NULL DEFAULT 0 CHECK (expected_count >= 0),
    resolved_count INTEGER NOT NULL DEFAULT 0 CHECK (resolved_count >= 0),
    unresolved_count INTEGER NOT NULL DEFAULT 0 CHECK (unresolved_count >= 0),
    is_current BOOLEAN NOT NULL DEFAULT TRUE,
    validated_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT ck_composition_receipt_counts
        CHECK (resolved_count + unresolved_count <= expected_count
            OR validation_status <> 'VALID'),
    CONSTRAINT ck_composition_receipt_valid
        CHECK (validation_status <> 'VALID'
            OR (BTRIM(source_reference) <> ''
                AND BTRIM(raw_ingredients_text) <> ''
                AND expected_count > 0
                AND expected_count = resolved_count
                AND unresolved_count = 0)),
    UNIQUE (fk_product_version_id, product_composition_receipt_id)
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_product_composition_receipts_current
    ON venus.product_composition_receipts (fk_product_version_id)
    WHERE is_current;

CREATE INDEX IF NOT EXISTS idx_product_composition_receipts_status
    ON venus.product_composition_receipts (validation_status, is_current);

CREATE TABLE IF NOT EXISTS venus.product_dimension_assessments (
    product_dimension_assessment_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fk_product_version_id BIGINT NOT NULL
        REFERENCES venus.product_versions(product_version_id) ON DELETE CASCADE,
    dimension TEXT NOT NULL CHECK (dimension IN ('performance', 'ethical')),
    assessment_status TEXT NOT NULL DEFAULT 'pending'
        CHECK (assessment_status IN ('pending', 'approved', 'rejected')),
    source_type TEXT NOT NULL DEFAULT 'manual',
    source_reference TEXT NOT NULL DEFAULT '',
    assessment_version TEXT NOT NULL DEFAULT 'v1',
    assessed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT ck_product_dimension_assessment_source
        CHECK (assessment_status <> 'approved' OR BTRIM(source_reference) <> ''),
    UNIQUE (fk_product_version_id, dimension, assessment_version)
);

CREATE INDEX IF NOT EXISTS idx_product_dimension_assessments_version
    ON venus.product_dimension_assessments (fk_product_version_id, assessment_status);

CREATE TABLE IF NOT EXISTS venus.product_score_history (
    product_score_history_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    source_product_score_id BIGINT,
    fk_product_version_id BIGINT NOT NULL,
    fk_scoring_model_id BIGINT NOT NULL,
    overall_score INTEGER NOT NULL,
    health_score INTEGER,
    environmental_score INTEGER,
    ethical_score INTEGER,
    performance_score INTEGER,
    transparency_score INTEGER,
    confidence_score SMALLINT,
    calculated_at TIMESTAMPTZ,
    invalidated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    invalidation_reason TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_product_score_history_version
    ON venus.product_score_history (fk_product_version_id, invalidated_at DESC);

CREATE OR REPLACE FUNCTION venus.fn_product_version_data_ready(p_product_version_id BIGINT)
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM venus.product_versions pv
        WHERE pv.product_version_id = p_product_version_id
          AND pv.is_current = TRUE
          AND EXISTS (
              SELECT 1
              FROM venus.product_ingredients pi
              WHERE pi.fk_product_version_id = pv.product_version_id
          )
          AND EXISTS (
              SELECT 1
              FROM venus.product_composition_receipts cr
              WHERE cr.fk_product_version_id = pv.product_version_id
                AND cr.is_current = TRUE
                AND cr.validation_status = 'VALID'
                AND cr.expected_count = cr.resolved_count
                AND cr.unresolved_count = 0
          )
          AND NOT EXISTS (
              SELECT 1
              FROM venus.product_ingredients pi
              WHERE NOT EXISTS (
                  SELECT 1
                  FROM venus.ingredient_risk_assessments ira
                  WHERE ira.fk_ingredient_id = pi.fk_ingredient_id
                    AND ira.assessment_status = 'approved'
                  GROUP BY ira.fk_ingredient_id
                  HAVING COUNT(DISTINCT ira.dimension) = 4
              )
          )
          AND EXISTS (
              SELECT 1
              FROM venus.packaging pg
              WHERE pg.fk_product_version_id = pv.product_version_id
                AND pg.confidence_score > 0
          )
          AND NOT EXISTS (
              SELECT 1
              FROM (VALUES ('performance'), ('ethical')) AS required(dimension)
              WHERE NOT EXISTS (
                  SELECT 1
                  FROM venus.product_dimension_assessments pda
                  WHERE pda.fk_product_version_id = pv.product_version_id
                    AND pda.dimension = required.dimension
                    AND pda.assessment_status = 'approved'
              )
          )
    );
$$;

CREATE OR REPLACE FUNCTION venus.fn_product_version_score_ready(p_product_version_id BIGINT)
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM venus.product_versions pv
        WHERE pv.product_version_id = p_product_version_id
          AND pv.status = 'verified'
          AND venus.fn_product_version_data_ready(pv.product_version_id)
    );
$$;

CREATE OR REPLACE FUNCTION venus.fn_register_product_composition(
    p_product_version_id BIGINT,
    p_source_type TEXT,
    p_source_reference TEXT,
    p_raw_ingredients_text TEXT,
    p_expected_count INTEGER,
    p_resolved_count INTEGER,
    p_unresolved_count INTEGER,
    p_validation_status TEXT,
    p_formula_hash TEXT DEFAULT NULL
)
RETURNS VOID
LANGUAGE PLPGSQL
AS $$
BEGIN
    IF p_validation_status NOT IN ('VALID', 'WARNING', 'INVALID', 'LEGACY_UNVERIFIED') THEN
        RAISE EXCEPTION 'validation_status inválido: %', p_validation_status;
    END IF;

    -- Uma carga não pode declarar VALID sem texto de composição e pelo menos
    -- um ingrediente resolvido. Isso também normaliza registros históricos do
    -- RPA que foram marcados VALID apesar de não terem fórmula carregada.
    IF p_validation_status = 'VALID'
       AND (BTRIM(COALESCE(p_raw_ingredients_text, '')) = ''
            OR COALESCE(p_expected_count, 0) <= 0
            OR COALESCE(p_resolved_count, 0) <= 0
            OR COALESCE(p_unresolved_count, 0) <> 0) THEN
        p_validation_status := 'WARNING';
        p_unresolved_count := GREATEST(COALESCE(p_unresolved_count, 0), 1);
        p_expected_count := GREATEST(COALESCE(p_expected_count, 0), COALESCE(p_resolved_count, 0) + p_unresolved_count);
    END IF;

    UPDATE venus.product_composition_receipts
       SET is_current = FALSE,
           updated_at = NOW()
     WHERE fk_product_version_id = p_product_version_id
       AND is_current = TRUE;

    INSERT INTO venus.product_composition_receipts (
        fk_product_version_id,
        source_type,
        source_reference,
        raw_ingredients_text,
        formula_hash,
        validation_status,
        expected_count,
        resolved_count,
        unresolved_count,
        is_current,
        validated_at
    ) VALUES (
        p_product_version_id,
        COALESCE(NULLIF(BTRIM(p_source_type), ''), 'manual'),
        COALESCE(p_source_reference, ''),
        COALESCE(p_raw_ingredients_text, ''),
        p_formula_hash,
        p_validation_status,
        GREATEST(COALESCE(p_expected_count, 0), 0),
        GREATEST(COALESCE(p_resolved_count, 0), 0),
        GREATEST(COALESCE(p_unresolved_count, 0), 0),
        TRUE,
        CASE WHEN p_validation_status = 'VALID' THEN NOW() ELSE NULL END
    );
END;
$$;
CREATE OR REPLACE PROCEDURE venus.sp_register_product_composition(
    p_product_version_id BIGINT,
    p_source_type TEXT,
    p_source_reference TEXT,
    p_raw_ingredients_text TEXT,
    p_expected_count INTEGER,
    p_resolved_count INTEGER,
    p_unresolved_count INTEGER,
    p_validation_status TEXT,
    p_formula_hash TEXT DEFAULT NULL
)
LANGUAGE PLPGSQL
AS $$
BEGIN
    PERFORM venus.fn_register_product_composition(
        p_product_version_id,
        p_source_type,
        p_source_reference,
        p_raw_ingredients_text,
        p_expected_count,
        p_resolved_count,
        p_unresolved_count,
        p_validation_status,
        p_formula_hash
    );
END;
$$;

CREATE OR REPLACE PROCEDURE venus.sp_approve_ingredient_risk_assessment(
    p_ingredient_id BIGINT,
    p_irritation_risk_level SMALLINT,
    p_comedogenicity_score SMALLINT,
    p_biodegradability_level SMALLINT,
    p_environmental_risk_level SMALLINT,
    p_source_type TEXT,
    p_source_reference TEXT,
    p_assessment_version TEXT DEFAULT 'v1'
)
LANGUAGE PLPGSQL
AS $$
DECLARE
BEGIN
    IF NULLIF(BTRIM(p_source_reference), '') IS NULL THEN
        RAISE EXCEPTION 'source_reference é obrigatório para uma avaliação aprovada';
    END IF;

    IF p_irritation_risk_level IS NULL OR p_irritation_risk_level NOT BETWEEN 0 AND 10
       OR p_comedogenicity_score IS NULL OR p_comedogenicity_score NOT BETWEEN 0 AND 10
       OR p_biodegradability_level IS NULL OR p_biodegradability_level NOT BETWEEN 0 AND 10
       OR p_environmental_risk_level IS NULL OR p_environmental_risk_level NOT BETWEEN 0 AND 10 THEN
        RAISE EXCEPTION 'todos os quatro scores devem estar entre 0 e 10';
    END IF;

    INSERT INTO venus.ingredient_risk_assessments
        (fk_ingredient_id, dimension, score, assessment_status, source_type,
         source_reference, assessment_version, assessed_at, updated_at)
    VALUES
        (p_ingredient_id, 'irritation_risk_level', p_irritation_risk_level,
         'approved', COALESCE(NULLIF(BTRIM(p_source_type), ''), 'manual'),
         BTRIM(p_source_reference), COALESCE(NULLIF(BTRIM(p_assessment_version), ''), 'v1'), NOW(), NOW()),
        (p_ingredient_id, 'comedogenicity_score', p_comedogenicity_score,
         'approved', COALESCE(NULLIF(BTRIM(p_source_type), ''), 'manual'),
         BTRIM(p_source_reference), COALESCE(NULLIF(BTRIM(p_assessment_version), ''), 'v1'), NOW(), NOW()),
        (p_ingredient_id, 'biodegradability_level', p_biodegradability_level,
         'approved', COALESCE(NULLIF(BTRIM(p_source_type), ''), 'manual'),
         BTRIM(p_source_reference), COALESCE(NULLIF(BTRIM(p_assessment_version), ''), 'v1'), NOW(), NOW()),
        (p_ingredient_id, 'environmental_risk_level', p_environmental_risk_level,
         'approved', COALESCE(NULLIF(BTRIM(p_source_type), ''), 'manual'),
         BTRIM(p_source_reference), COALESCE(NULLIF(BTRIM(p_assessment_version), ''), 'v1'), NOW(), NOW())
    ON CONFLICT (fk_ingredient_id, dimension, assessment_version)
    DO UPDATE SET
        score = EXCLUDED.score,
        assessment_status = 'approved',
        source_type = EXCLUDED.source_type,
        source_reference = EXCLUDED.source_reference,
        assessed_at = NOW(),
        updated_at = NOW();

    PERFORM set_config('venus.allow_risk_sync', 'on', TRUE);
    UPDATE venus.ingredients
       SET irritation_risk_level = p_irritation_risk_level,
           comedogenicity_score = p_comedogenicity_score,
           biodegradability_level = p_biodegradability_level,
           environmental_risk_level = p_environmental_risk_level,
           updated_at = NOW()
     WHERE ingredient_id = p_ingredient_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'ingredient_id inexistente: %', p_ingredient_id;
    END IF;
END;
$$;

CREATE OR REPLACE PROCEDURE venus.sp_approve_product_dimension(
    p_product_version_id BIGINT,
    p_dimension TEXT,
    p_source_type TEXT,
    p_source_reference TEXT,
    p_assessment_version TEXT DEFAULT 'v1'
)
LANGUAGE PLPGSQL
AS $$
BEGIN
    IF p_dimension NOT IN ('performance', 'ethical') THEN
        RAISE EXCEPTION 'dimension inválida: %', p_dimension;
    END IF;
    IF NULLIF(BTRIM(p_source_reference), '') IS NULL THEN
        RAISE EXCEPTION 'source_reference é obrigatório para uma avaliação aprovada';
    END IF;

    INSERT INTO venus.product_dimension_assessments (
        fk_product_version_id,
        dimension,
        assessment_status,
        source_type,
        source_reference,
        assessment_version,
        assessed_at,
        updated_at
    ) VALUES (
        p_product_version_id,
        p_dimension,
        'approved',
        COALESCE(NULLIF(BTRIM(p_source_type), ''), 'manual'),
        BTRIM(p_source_reference),
        COALESCE(NULLIF(BTRIM(p_assessment_version), ''), 'v1'),
        NOW(),
        NOW()
    )
    ON CONFLICT (fk_product_version_id, dimension, assessment_version)
    DO UPDATE SET
        assessment_status = 'approved',
        source_type = EXCLUDED.source_type,
        source_reference = EXCLUDED.source_reference,
        assessed_at = NOW(),
        updated_at = NOW();
END;
$$;

CREATE OR REPLACE FUNCTION venus.fn_block_unassessed_ingredient_risk_update()
RETURNS TRIGGER
LANGUAGE PLPGSQL
AS $$
BEGIN
    IF COALESCE(current_setting('venus.allow_risk_sync', TRUE), '') <> 'on'
       AND (NEW.irritation_risk_level IS DISTINCT FROM OLD.irritation_risk_level
         OR NEW.comedogenicity_score IS DISTINCT FROM OLD.comedogenicity_score
         OR NEW.biodegradability_level IS DISTINCT FROM OLD.biodegradability_level
         OR NEW.environmental_risk_level IS DISTINCT FROM OLD.environmental_risk_level) THEN
        RAISE EXCEPTION
            'Use venus.sp_approve_ingredient_risk_assessment para atualizar as notas de risco; o valor 0 sem avaliação não é evidência';
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_block_unassessed_ingredient_risk_update
    ON venus.ingredients;
CREATE TRIGGER trg_block_unassessed_ingredient_risk_update
BEFORE UPDATE OF irritation_risk_level, comedogenicity_score,
    biodegradability_level, environmental_risk_level
ON venus.ingredients
FOR EACH ROW
EXECUTE FUNCTION venus.fn_block_unassessed_ingredient_risk_update();

CREATE OR REPLACE FUNCTION venus.fn_touch_versions_for_ingredient_risk()
RETURNS TRIGGER
LANGUAGE PLPGSQL
AS $$
BEGIN
    UPDATE venus.product_versions pv
       SET updated_at = pv.updated_at
     WHERE pv.is_current = TRUE
       AND EXISTS (
           SELECT 1
           FROM venus.product_ingredients pi
           WHERE pi.fk_product_version_id = pv.product_version_id
             AND pi.fk_ingredient_id = COALESCE(NEW.fk_ingredient_id, OLD.fk_ingredient_id)
       );
    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    END IF;
    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION venus.fn_touch_version_from_dependency()
RETURNS TRIGGER
LANGUAGE PLPGSQL
AS $$
DECLARE
    v_product_version_id BIGINT;
BEGIN
    v_product_version_id := COALESCE(NEW.fk_product_version_id, OLD.fk_product_version_id);
    UPDATE venus.product_versions pv
       SET updated_at = pv.updated_at
     WHERE pv.product_version_id = v_product_version_id;
    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    END IF;
    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION venus.fn_invalidate_product_scores(
    p_product_version_id BIGINT,
    p_reason TEXT
)
RETURNS VOID
LANGUAGE PLPGSQL
AS $$
BEGIN
    INSERT INTO venus.product_score_history (
        source_product_score_id,
        fk_product_version_id,
        fk_scoring_model_id,
        overall_score,
        health_score,
        environmental_score,
        ethical_score,
        performance_score,
        transparency_score,
        confidence_score,
        calculated_at,
        invalidation_reason
    )
    SELECT
        ps.product_score_id,
        ps.fk_product_version_id,
        ps.fk_scoring_model_id,
        ps.overall_score,
        ps.health_score,
        ps.environmental_score,
        ps.ethical_score,
        ps.performance_score,
        ps.transparency_score,
        ps.confidence_score,
        ps.calculated_at,
        p_reason
    FROM venus.product_scores ps
    WHERE ps.fk_product_version_id = p_product_version_id;

    DELETE FROM venus.product_scores
     WHERE fk_product_version_id = p_product_version_id;
END;
$$;

CREATE OR REPLACE FUNCTION venus.fn_enforce_product_version_score_readiness()
RETURNS TRIGGER
LANGUAGE PLPGSQL
AS $$
BEGIN
    IF NEW.is_current = TRUE
       AND NEW.status <> 'deprecated'
       AND venus.fn_product_version_data_ready(NEW.product_version_id) THEN
        IF NEW.status IN ('pending', 'needs_review') THEN
            UPDATE venus.product_versions
               SET status = 'verified'
             WHERE product_version_id = NEW.product_version_id
               AND status IN ('pending', 'needs_review');
        END IF;
    ELSE
        IF NEW.is_current = TRUE AND NEW.status = 'verified' THEN
            UPDATE venus.product_versions
               SET status = 'needs_review'
             WHERE product_version_id = NEW.product_version_id
               AND status = 'verified';
        END IF;
        PERFORM venus.fn_invalidate_product_scores(
            NEW.product_version_id,
            'Dados de composição ou avaliação incompletos; score removido até nova classificação válida.'
        );
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_enforce_product_version_score_readiness
    ON venus.product_versions;
CREATE CONSTRAINT TRIGGER trg_enforce_product_version_score_readiness
AFTER INSERT OR UPDATE ON venus.product_versions
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION venus.fn_enforce_product_version_score_readiness();

DROP TRIGGER IF EXISTS trg_guard_product_score_readiness
    ON venus.product_scores;
CREATE OR REPLACE FUNCTION venus.fn_guard_product_score_readiness()
RETURNS TRIGGER
LANGUAGE PLPGSQL
AS $$
BEGIN
    IF NOT venus.fn_product_version_score_ready(NEW.fk_product_version_id) THEN
        RAISE EXCEPTION
            'Score bloqueado: product_version_id % ainda não possui composição, avaliações e evidências aprovadas',
            NEW.fk_product_version_id
            USING ERRCODE = 'check_violation';
    END IF;
    RETURN NEW;
END;
$$;
CREATE TRIGGER trg_guard_product_score_readiness
BEFORE INSERT OR UPDATE ON venus.product_scores
FOR EACH ROW
EXECUTE FUNCTION venus.fn_guard_product_score_readiness();

DROP TRIGGER IF EXISTS trg_touch_version_from_product_ingredients
    ON venus.product_ingredients;
CREATE TRIGGER trg_touch_version_from_product_ingredients
AFTER INSERT OR UPDATE OR DELETE ON venus.product_ingredients
FOR EACH ROW
EXECUTE FUNCTION venus.fn_touch_version_from_dependency();

DROP TRIGGER IF EXISTS trg_touch_versions_from_risk_assessments
    ON venus.ingredient_risk_assessments;
CREATE TRIGGER trg_touch_versions_from_risk_assessments
AFTER INSERT OR UPDATE OR DELETE ON venus.ingredient_risk_assessments
FOR EACH ROW
EXECUTE FUNCTION venus.fn_touch_versions_for_ingredient_risk();

DROP TRIGGER IF EXISTS trg_touch_version_from_composition_receipts
    ON venus.product_composition_receipts;
CREATE TRIGGER trg_touch_version_from_composition_receipts
AFTER INSERT OR UPDATE OR DELETE ON venus.product_composition_receipts
FOR EACH ROW
EXECUTE FUNCTION venus.fn_touch_version_from_dependency();

DROP TRIGGER IF EXISTS trg_touch_version_from_dimension_assessments
    ON venus.product_dimension_assessments;
CREATE TRIGGER trg_touch_version_from_dimension_assessments
AFTER INSERT OR UPDATE OR DELETE ON venus.product_dimension_assessments
FOR EACH ROW
EXECUTE FUNCTION venus.fn_touch_version_from_dependency();

DROP TRIGGER IF EXISTS trg_touch_version_from_packaging
    ON venus.packaging;
CREATE TRIGGER trg_touch_version_from_packaging
AFTER INSERT OR UPDATE OR DELETE ON venus.packaging
FOR EACH ROW
EXECUTE FUNCTION venus.fn_touch_version_from_dependency();

CREATE OR REPLACE FUNCTION venus.fn_sync_rpa_composition_receipt()
RETURNS TRIGGER
LANGUAGE PLPGSQL
AS $$
DECLARE
    v_product_version_id BIGINT;
    v_resolved_count INTEGER;
    v_expected_count INTEGER;
    v_unresolved_count INTEGER;
    v_receipt_status TEXT;
BEGIN
    IF NEW.loaded_product_id IS NULL THEN
        RETURN NEW;
    END IF;

    SELECT pv.product_version_id
      INTO v_product_version_id
      FROM venus.product_versions pv
     WHERE pv.fk_product_id = NEW.loaded_product_id
       AND pv.is_current = TRUE
     ORDER BY pv.updated_at DESC, pv.product_version_id DESC
     LIMIT 1;

    IF v_product_version_id IS NULL THEN
        RETURN NEW;
    END IF;

    SELECT COUNT(*)::INTEGER
      INTO v_resolved_count
      FROM venus.product_ingredients pi
     WHERE pi.fk_product_version_id = v_product_version_id;

    v_receipt_status := CASE NEW.validation_status
        WHEN 'VALID' THEN 'VALID'
        WHEN 'WARNING' THEN 'WARNING'
        ELSE 'INVALID'
    END;
    v_unresolved_count := CASE WHEN NEW.validation_status = 'VALID' THEN 0 ELSE 1 END;
    v_expected_count := v_resolved_count + v_unresolved_count;

    PERFORM venus.fn_register_product_composition(
        v_product_version_id,
        'rpa',
        FORMAT('rpa:%s:%s', NEW.batch_id, NEW.legacy_product_id),
        COALESCE(NEW.ingredients_text, ''),
        v_expected_count,
        v_resolved_count,
        v_unresolved_count,
        v_receipt_status,
        MD5(COALESCE(NEW.ingredients_text, ''))
    );
    RETURN NEW;
END;
$$;

DO $$
BEGIN
    IF to_regclass('venus_rpa.rpa_stage_product') IS NOT NULL THEN
        DROP TRIGGER IF EXISTS trg_sync_rpa_composition_receipt
            ON venus_rpa.rpa_stage_product;
        CREATE TRIGGER trg_sync_rpa_composition_receipt
        AFTER INSERT OR UPDATE OF loaded_product_id, ingredients_text, validation_status
        ON venus_rpa.rpa_stage_product
        FOR EACH ROW
        EXECUTE FUNCTION venus.fn_sync_rpa_composition_receipt();
    END IF;
END;
$$;

-- Reconcilia o RPA já existente sem promover WARNING/INVALID a composição válida.
DO $$
DECLARE
    r RECORD;
    v_resolved_count INTEGER;
    v_unresolved_count INTEGER;
BEGIN
    IF to_regclass('venus_rpa.rpa_stage_product') IS NULL THEN
        RETURN;
    END IF;

    FOR r IN
        SELECT DISTINCT ON (sp.loaded_product_id)
            sp.loaded_product_id,
            sp.batch_id,
            sp.legacy_product_id,
            sp.ingredients_text,
            sp.validation_status,
            pv.product_version_id
        FROM venus_rpa.rpa_stage_product sp
        JOIN venus.product_versions pv
          ON pv.fk_product_id = sp.loaded_product_id
         AND pv.is_current = TRUE
        WHERE sp.loaded_product_id IS NOT NULL
        ORDER BY sp.loaded_product_id, sp.batch_id DESC
    LOOP
        SELECT COUNT(*)::INTEGER
          INTO v_resolved_count
          FROM venus.product_ingredients pi
         WHERE pi.fk_product_version_id = r.product_version_id;

        v_unresolved_count := CASE WHEN r.validation_status = 'VALID' THEN 0 ELSE 1 END;

        PERFORM venus.fn_register_product_composition(
            r.product_version_id,
            'rpa',
            FORMAT('rpa:%s:%s', r.batch_id, r.legacy_product_id),
            COALESCE(r.ingredients_text, ''),
            v_resolved_count + v_unresolved_count,
            v_resolved_count,
            v_unresolved_count,
            CASE r.validation_status
                WHEN 'VALID' THEN 'VALID'
                WHEN 'WARNING' THEN 'WARNING'
                ELSE 'INVALID'
            END,
            MD5(COALESCE(r.ingredients_text, ''))
        );
    END LOOP;
END;
$$;

-- Se houver uma versão criada antes da linha do RPA, a criação/atualização da
-- versão também tenta aproveitar o recibo já presente na staging.
CREATE OR REPLACE FUNCTION venus.fn_sync_rpa_receipt_from_version()
RETURNS TRIGGER
LANGUAGE PLPGSQL
AS $$
DECLARE
    r RECORD;
    v_resolved_count INTEGER;
    v_unresolved_count INTEGER;
BEGIN
    IF to_regclass('venus_rpa.rpa_stage_product') IS NULL THEN
        RETURN NEW;
    END IF;

    SELECT sp.batch_id, sp.legacy_product_id, sp.ingredients_text, sp.validation_status
      INTO r
      FROM venus_rpa.rpa_stage_product sp
     WHERE sp.loaded_product_id = NEW.fk_product_id
     ORDER BY sp.batch_id DESC
     LIMIT 1;

    IF NOT FOUND THEN
        RETURN NEW;
    END IF;

    SELECT COUNT(*)::INTEGER
      INTO v_resolved_count
      FROM venus.product_ingredients pi
     WHERE pi.fk_product_version_id = NEW.product_version_id;
    v_unresolved_count := CASE WHEN r.validation_status = 'VALID' THEN 0 ELSE 1 END;

    PERFORM venus.fn_register_product_composition(
        NEW.product_version_id,
        'rpa',
        FORMAT('rpa:%s:%s', r.batch_id, r.legacy_product_id),
        COALESCE(r.ingredients_text, ''),
        v_resolved_count + v_unresolved_count,
        v_resolved_count,
        v_unresolved_count,
        CASE r.validation_status
            WHEN 'VALID' THEN 'VALID'
            WHEN 'WARNING' THEN 'WARNING'
            ELSE 'INVALID'
        END,
        MD5(COALESCE(r.ingredients_text, ''))
    );
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_sync_rpa_receipt_from_version
    ON venus.product_versions;
CREATE TRIGGER trg_sync_rpa_receipt_from_version
AFTER INSERT OR UPDATE OF fk_product_id ON venus.product_versions
FOR EACH ROW
EXECUTE FUNCTION venus.fn_sync_rpa_receipt_from_version();

-- A staging do RPA pode ser carregada antes dos product_ingredients. Recalcula
-- o recibo quando os vínculos chegam para não transformar a ordem da carga em
-- um falso WARNING.
CREATE OR REPLACE FUNCTION venus.fn_refresh_rpa_receipt_after_ingredient_link()
RETURNS TRIGGER
LANGUAGE PLPGSQL
AS $$
DECLARE
    v_product_version_id BIGINT;
    v_product_id BIGINT;
    r RECORD;
    v_resolved_count INTEGER;
    v_valid BOOLEAN;
BEGIN
    v_product_version_id := COALESCE(NEW.fk_product_version_id, OLD.fk_product_version_id);

    IF to_regclass('venus_rpa.rpa_stage_product') IS NULL THEN
        IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF;
    END IF;

    SELECT pv.fk_product_id
      INTO v_product_id
      FROM venus.product_versions pv
     WHERE pv.product_version_id = v_product_version_id;

    SELECT sp.batch_id, sp.legacy_product_id, sp.ingredients_text, sp.validation_status
      INTO r
      FROM venus_rpa.rpa_stage_product sp
     WHERE sp.loaded_product_id = v_product_id
     ORDER BY sp.batch_id DESC
     LIMIT 1;

    IF FOUND THEN
        SELECT COUNT(*)::INTEGER
          INTO v_resolved_count
          FROM venus.product_ingredients pi
         WHERE pi.fk_product_version_id = v_product_version_id;

        v_valid := r.validation_status = 'VALID'
                   AND BTRIM(COALESCE(r.ingredients_text, '')) <> ''
                   AND v_resolved_count > 0;

        PERFORM venus.fn_register_product_composition(
            v_product_version_id,
            'rpa',
            FORMAT('rpa:%s:%s', r.batch_id, r.legacy_product_id),
            COALESCE(r.ingredients_text, ''),
            v_resolved_count + CASE WHEN v_valid THEN 0 ELSE 1 END,
            v_resolved_count,
            CASE WHEN v_valid THEN 0 ELSE 1 END,
            CASE WHEN v_valid THEN 'VALID' ELSE 'WARNING' END,
            MD5(COALESCE(r.ingredients_text, ''))
        );
    END IF;

    IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF;
END;
$$;

DROP TRIGGER IF EXISTS trg_refresh_rpa_receipt_after_ingredient_link
    ON venus.product_ingredients;
CREATE TRIGGER trg_refresh_rpa_receipt_after_ingredient_link
AFTER INSERT OR UPDATE OR DELETE ON venus.product_ingredients
FOR EACH ROW
EXECUTE FUNCTION venus.fn_refresh_rpa_receipt_after_ingredient_link();

CREATE OR REPLACE VIEW venus.v_product_score_readiness AS
SELECT
    pv.product_version_id,
    pv.fk_product_id,
    pv.status,
    pv.is_current,
    venus.fn_product_version_data_ready(pv.product_version_id) AS data_ready,
    venus.fn_product_version_score_ready(pv.product_version_id) AS score_ready,
    COUNT(DISTINCT pi.product_ingredient_id) AS ingredient_count,
    COUNT(DISTINCT ira.fk_ingredient_id) FILTER (WHERE ira.assessment_status = 'approved') AS ingredients_with_risk_approval,
    COALESCE(cr.validation_status, 'MISSING') AS composition_status,
    COALESCE(cr.unresolved_count, 0) AS unresolved_count,
    COALESCE(pg.confidence_score, 0) AS packaging_confidence,
    COUNT(DISTINCT pda.dimension) FILTER (WHERE pda.assessment_status = 'approved') AS approved_product_dimensions,
    ps.product_score_id,
    ps.overall_score
FROM venus.product_versions pv
LEFT JOIN venus.product_ingredients pi
       ON pi.fk_product_version_id = pv.product_version_id
LEFT JOIN venus.ingredient_risk_assessments ira
       ON ira.fk_ingredient_id = pi.fk_ingredient_id
LEFT JOIN venus.product_composition_receipts cr
       ON cr.fk_product_version_id = pv.product_version_id
      AND cr.is_current = TRUE
LEFT JOIN venus.packaging pg
       ON pg.fk_product_version_id = pv.product_version_id
LEFT JOIN venus.product_dimension_assessments pda
       ON pda.fk_product_version_id = pv.product_version_id
LEFT JOIN venus.product_scores ps
       ON ps.fk_product_version_id = pv.product_version_id
GROUP BY
    pv.product_version_id,
    pv.fk_product_id,
    pv.status,
    pv.is_current,
    cr.validation_status,
    cr.unresolved_count,
    pg.confidence_score,
    ps.product_score_id,
    ps.overall_score;

COMMENT ON TABLE venus.ingredient_risk_assessments IS
    'Avaliações aprovadas dos quatro eixos de risco; zero só é evidência quando existir registro aprovado.';
COMMENT ON TABLE venus.product_composition_receipts IS
    'Recibo da composição bruta, resolução e validação usados para liberar um produto para score.';
COMMENT ON TABLE venus.product_dimension_assessments IS
    'Aprovação explícita das dimensões de performance e ética antes do score geral.';
COMMENT ON TABLE venus.product_score_history IS
    'Histórico de scores removidos porque a entrada deixou de atender aos critérios de prontidão.';

-- Dispara uma reconciliação deferida de todas as versões atuais. O trigger
-- colocará versões incompletas em needs_review e arquivará scores enganadores.
UPDATE venus.product_versions
   SET updated_at = updated_at
 WHERE is_current = TRUE;

-- Reprocessa vínculos já existentes depois que o trigger de ordem de carga foi
-- criado, mantendo a reconciliação idempotente em bancos já migrados.
DO $$
BEGIN
    IF to_regclass('venus_rpa.rpa_stage_product') IS NOT NULL THEN
        UPDATE venus.product_ingredients pi
           SET updated_at = pi.updated_at
         WHERE EXISTS (
               SELECT 1
               FROM venus_rpa.rpa_stage_product sp
               JOIN venus.product_versions pv
                 ON pv.fk_product_id = sp.loaded_product_id
                AND pv.product_version_id = pi.fk_product_version_id
               WHERE sp.loaded_product_id IS NOT NULL
           );
    END IF;
END;
$$;

