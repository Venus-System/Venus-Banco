-- Venus — estado desconhecido para claims éticos — 2026-10-12
-- Somente banco: não executa a classificação.

BEGIN;

SET LOCAL lock_timeout = '10s';
SET LOCAL statement_timeout = '600s';
SET LOCAL search_path TO venus, public;

-- Ausência de evidência não é uma declaração negativa. Os dois campos passam
-- a usar: TRUE = evidência positiva elegível, FALSE = evidência negativa
-- explícita elegível, NULL = desconhecido/sem evidência suficiente.
ALTER TABLE venus.brands
    ALTER COLUMN has_vegan_claim DROP DEFAULT,
    ALTER COLUMN has_vegan_claim DROP NOT NULL,
    ALTER COLUMN has_cruelty_free_claim DROP DEFAULT,
    ALTER COLUMN has_cruelty_free_claim DROP NOT NULL;

-- Uma evidência precisa ser auditável. A migration 001 já criou a tabela;
-- estes checks também protegem instalações que tenham criado a tabela antes.
ALTER TABLE venus.brand_claim_evidence
    DROP CONSTRAINT IF EXISTS brand_claim_evidence_source_url_nonblank,
    DROP CONSTRAINT IF EXISTS brand_claim_evidence_source_title_nonblank,
    DROP CONSTRAINT IF EXISTS brand_claim_evidence_note_nonblank;

ALTER TABLE venus.brand_claim_evidence
    ADD CONSTRAINT brand_claim_evidence_source_url_nonblank
        CHECK (btrim(source_url) <> ''),
    ADD CONSTRAINT brand_claim_evidence_source_title_nonblank
        CHECK (btrim(source_title) <> ''),
    ADD CONSTRAINT brand_claim_evidence_note_nonblank
        CHECK (btrim(evidence_note) <> '');

-- Somente evidências high/medium são suficientes para alimentar o flag
-- operacional. Evidência low continua registrada, mas não aprova a marca.
CREATE OR REPLACE FUNCTION venus.fn_derived_brand_claim(
    p_brand_id BIGINT,
    p_claim_type TEXT
)
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
AS $$
    SELECT CASE
        WHEN EXISTS (
            SELECT 1
              FROM venus.brand_claim_evidence e
             WHERE e.fk_brand_id = p_brand_id
               AND e.claim_type = p_claim_type
               AND e.claim_value = TRUE
               AND e.evidence_level IN ('high', 'medium')
        )
        AND NOT EXISTS (
            SELECT 1
              FROM venus.brand_claim_evidence e
             WHERE e.fk_brand_id = p_brand_id
               AND e.claim_type = p_claim_type
               AND e.claim_value = FALSE
               AND e.evidence_level IN ('high', 'medium')
        ) THEN TRUE
        WHEN EXISTS (
            SELECT 1
              FROM venus.brand_claim_evidence e
             WHERE e.fk_brand_id = p_brand_id
               AND e.claim_type = p_claim_type
               AND e.claim_value = FALSE
               AND e.evidence_level IN ('high', 'medium')
        )
        AND NOT EXISTS (
            SELECT 1
              FROM venus.brand_claim_evidence e
             WHERE e.fk_brand_id = p_brand_id
               AND e.claim_type = p_claim_type
               AND e.claim_value = TRUE
               AND e.evidence_level IN ('high', 'medium')
        ) THEN FALSE
        ELSE NULL
    END;
$$;

CREATE OR REPLACE FUNCTION venus.sp_sync_brand_claim_flags(p_brand_id BIGINT)
RETURNS VOID
LANGUAGE PLPGSQL
AS $$
BEGIN
    UPDATE venus.brands b
       SET has_vegan_claim = venus.fn_derived_brand_claim(b.brand_id, 'vegan'),
           has_cruelty_free_claim = venus.fn_derived_brand_claim(b.brand_id, 'cruelty_free'),
           updated_at = NOW()
     WHERE b.brand_id = p_brand_id;
END;
$$;

CREATE OR REPLACE FUNCTION venus.fn_sync_brand_claim_flags_from_evidence()
RETURNS TRIGGER
LANGUAGE PLPGSQL
AS $$
BEGIN
    IF TG_OP IN ('DELETE', 'UPDATE') THEN
        PERFORM venus.sp_sync_brand_claim_flags(OLD.fk_brand_id);
    END IF;

    IF TG_OP IN ('INSERT', 'UPDATE') THEN
        PERFORM venus.sp_sync_brand_claim_flags(NEW.fk_brand_id);
    END IF;

    RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS trg_sync_brand_claim_flags_from_evidence
    ON venus.brand_claim_evidence;
CREATE TRIGGER trg_sync_brand_claim_flags_from_evidence
AFTER INSERT OR UPDATE OR DELETE
ON venus.brand_claim_evidence
FOR EACH ROW
EXECUTE FUNCTION venus.fn_sync_brand_claim_flags_from_evidence();

-- Impede que a aplicação grave FALSE como default ou TRUE sem evidência. A
-- normalização é silenciosa para manter o fluxo de cadastro de marcas:
-- o estado derivado é sempre NULL, TRUE ou FALSE conforme a evidência.
CREATE OR REPLACE FUNCTION venus.fn_normalize_brand_claim_flags()
RETURNS TRIGGER
LANGUAGE PLPGSQL
AS $$
BEGIN
    IF NEW.brand_id IS NULL THEN
        NEW.has_vegan_claim := NULL;
        NEW.has_cruelty_free_claim := NULL;
    ELSE
        NEW.has_vegan_claim := venus.fn_derived_brand_claim(NEW.brand_id, 'vegan');
        NEW.has_cruelty_free_claim := venus.fn_derived_brand_claim(NEW.brand_id, 'cruelty_free');
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_normalize_brand_claim_flags
    ON venus.brands;
CREATE TRIGGER trg_normalize_brand_claim_flags
BEFORE INSERT OR UPDATE OF has_vegan_claim, has_cruelty_free_claim
ON venus.brands
FOR EACH ROW
EXECUTE FUNCTION venus.fn_normalize_brand_claim_flags();

-- Recalcula os flags existentes. Marcas sem evidência deixam de ser tratadas
-- como negativas; as oito evidências positivas existentes são preservadas.
UPDATE venus.brands b
   SET has_vegan_claim = venus.fn_derived_brand_claim(b.brand_id, 'vegan'),
       has_cruelty_free_claim = venus.fn_derived_brand_claim(b.brand_id, 'cruelty_free'),
       updated_at = NOW();

CREATE OR REPLACE VIEW venus.v_brand_claim_status AS
WITH claim_types(claim_type) AS (
    VALUES ('vegan'::TEXT), ('cruelty_free'::TEXT)
), evidence AS (
    SELECT
        e.fk_brand_id,
        e.claim_type,
        bool_or(e.claim_value) FILTER (
            WHERE e.evidence_level IN ('high', 'medium')
        ) AS has_positive_evidence,
        bool_or(NOT e.claim_value) FILTER (
            WHERE e.evidence_level IN ('high', 'medium')
        ) AS has_negative_evidence,
        COUNT(*) FILTER (
            WHERE e.evidence_level IN ('high', 'medium')
        )::INTEGER AS eligible_evidence_count
    FROM venus.brand_claim_evidence e
    WHERE e.claim_type IN ('vegan', 'cruelty_free')
    GROUP BY e.fk_brand_id, e.claim_type
)
SELECT
    b.brand_id,
    b.name,
    c.claim_type,
    CASE
        WHEN COALESCE(e.has_positive_evidence, FALSE)
         AND COALESCE(e.has_negative_evidence, FALSE) THEN 'conflict'
        WHEN e.has_positive_evidence THEN 'verified'
        WHEN e.has_negative_evidence THEN 'explicit_negative'
        ELSE 'unknown'
    END AS claim_status,
    e.eligible_evidence_count,
    CASE c.claim_type
        WHEN 'vegan' THEN b.has_vegan_claim
        WHEN 'cruelty_free' THEN b.has_cruelty_free_claim
    END AS operational_value,
    'v1'::TEXT AS methodology_version
FROM venus.brands b
CROSS JOIN claim_types c
LEFT JOIN evidence e
  ON e.fk_brand_id = b.brand_id
 AND e.claim_type = c.claim_type;

COMMENT ON VIEW venus.v_brand_claim_status IS
    'Status ético por marca: verified, explicit_negative, conflict ou unknown. NULL não deve ser tratado como false sem evidência.';

COMMENT ON COLUMN venus.brands.has_vegan_claim IS
    'TRUE/FALSE somente quando houver evidência elegível; NULL significa desconhecido.';

COMMENT ON COLUMN venus.brands.has_cruelty_free_claim IS
    'TRUE/FALSE somente quando houver evidência elegível; NULL significa desconhecido.';

COMMIT;
