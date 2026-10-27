-- Venus — resolução automática de OCR e liberação sem aprovação manual de
-- dimensões secundárias — 2026-10-10
--
-- Não inventa avaliações de risco. A versão só fica pronta quando existir uma
-- avaliação aprovada real para cada eixo dos ingredientes usados.

CREATE TABLE IF NOT EXISTS venus.product_ingredient_resolution_issues (
    product_ingredient_resolution_issue_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fk_product_version_id BIGINT NOT NULL
        REFERENCES venus.product_versions(product_version_id) ON DELETE CASCADE,
    token_position INTEGER NOT NULL,
    raw_token TEXT NOT NULL,
    issue_type TEXT NOT NULL CHECK (issue_type IN ('NOT_FOUND', 'AMBIGUOUS')),
    source_reference TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (fk_product_version_id, token_position)
);

CREATE INDEX IF NOT EXISTS idx_product_ingredient_resolution_issues_version
    ON venus.product_ingredient_resolution_issues (fk_product_version_id, issue_type);

CREATE OR REPLACE FUNCTION venus.fn_normalize_ingredient_token(p_value TEXT)
RETURNS TEXT
LANGUAGE SQL
IMMUTABLE
AS $$
    SELECT REGEXP_REPLACE(
        TRANSLATE(
            LOWER(BTRIM(COALESCE(p_value, ''))),
            'áàãâäéèêëíìîïóòôõöúùûüç',
            'aaaaaeeeeiiiiooooouuuuc'
        ),
        '[^a-z0-9]',
        '',
        'g'
    );
$$;

CREATE TABLE IF NOT EXISTS venus.ingredient_resolution_keys (
    normalized_key TEXT NOT NULL,
    fk_ingredient_id BIGINT NOT NULL
        REFERENCES venus.ingredients(ingredient_id) ON DELETE CASCADE,
    PRIMARY KEY (normalized_key, fk_ingredient_id)
);

CREATE INDEX IF NOT EXISTS idx_ingredient_resolution_keys_key
    ON venus.ingredient_resolution_keys (normalized_key);

INSERT INTO venus.ingredient_resolution_keys (normalized_key, fk_ingredient_id)
SELECT venus.fn_normalize_ingredient_token(i.inci_name), i.ingredient_id
  FROM venus.ingredients i
 WHERE venus.fn_normalize_ingredient_token(i.inci_name) <> ''
UNION
SELECT venus.fn_normalize_ingredient_token(i.common_name), i.ingredient_id
  FROM venus.ingredients i
 WHERE venus.fn_normalize_ingredient_token(i.common_name) <> ''
UNION
SELECT venus.fn_normalize_ingredient_token(ia.alias_name), ia.fk_ingredient_id
  FROM venus.ingredient_aliases ia
 WHERE venus.fn_normalize_ingredient_token(ia.alias_name) <> ''
ON CONFLICT DO NOTHING;

CREATE OR REPLACE FUNCTION venus.fn_sync_ingredient_resolution_keys()
RETURNS TRIGGER
LANGUAGE PLPGSQL
AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        DELETE FROM venus.ingredient_resolution_keys
         WHERE fk_ingredient_id = OLD.ingredient_id;
        RETURN OLD;
    END IF;

    DELETE FROM venus.ingredient_resolution_keys
     WHERE fk_ingredient_id = NEW.ingredient_id;
    INSERT INTO venus.ingredient_resolution_keys (normalized_key, fk_ingredient_id)
    SELECT DISTINCT key_value, NEW.ingredient_id
    FROM (
        VALUES
            (venus.fn_normalize_ingredient_token(NEW.inci_name)),
            (venus.fn_normalize_ingredient_token(NEW.common_name))
    ) AS keys(key_value)
    WHERE key_value <> ''
    ON CONFLICT DO NOTHING;
    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION venus.fn_sync_ingredient_alias_resolution_key()
RETURNS TRIGGER
LANGUAGE PLPGSQL
AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        DELETE FROM venus.ingredient_resolution_keys
         WHERE normalized_key = venus.fn_normalize_ingredient_token(OLD.alias_name)
           AND fk_ingredient_id = OLD.fk_ingredient_id;
        RETURN OLD;
    END IF;

    IF TG_OP = 'UPDATE' THEN
        DELETE FROM venus.ingredient_resolution_keys
         WHERE normalized_key = venus.fn_normalize_ingredient_token(OLD.alias_name)
           AND fk_ingredient_id = OLD.fk_ingredient_id;
    END IF;

    INSERT INTO venus.ingredient_resolution_keys (normalized_key, fk_ingredient_id)
    VALUES (venus.fn_normalize_ingredient_token(NEW.alias_name), NEW.fk_ingredient_id)
    ON CONFLICT DO NOTHING;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_sync_ingredient_resolution_keys
    ON venus.ingredients;
CREATE TRIGGER trg_sync_ingredient_resolution_keys
AFTER INSERT OR UPDATE OF inci_name, common_name OR DELETE
ON venus.ingredients
FOR EACH ROW
EXECUTE FUNCTION venus.fn_sync_ingredient_resolution_keys();

DROP TRIGGER IF EXISTS trg_sync_ingredient_alias_resolution_key
    ON venus.ingredient_aliases;
CREATE TRIGGER trg_sync_ingredient_alias_resolution_key
AFTER INSERT OR UPDATE OF alias_name, fk_ingredient_id OR DELETE
ON venus.ingredient_aliases
FOR EACH ROW
EXECUTE FUNCTION venus.fn_sync_ingredient_alias_resolution_key();

CREATE OR REPLACE FUNCTION venus.fn_resolve_product_label_ingredients(
    p_product_version_id BIGINT
)
RETURNS TABLE (
    total_tokens INTEGER,
    resolved_tokens INTEGER,
    unresolved_tokens INTEGER,
    validation_status TEXT
)
LANGUAGE PLPGSQL
AS $$
DECLARE
    r RECORD;
    v_raw_text TEXT;
    v_source_reference TEXT;
    v_source_type TEXT;
    v_total INTEGER := 0;
    v_resolved INTEGER := 0;
    v_unresolved INTEGER := 0;
BEGIN
    SELECT pl.normalized_text,
           pl.source_reference,
           pl.source_type::TEXT
      INTO v_raw_text, v_source_reference, v_source_type
      FROM venus.product_labels pl
     WHERE pl.fk_product_version_id = p_product_version_id;

    IF NOT FOUND OR BTRIM(COALESCE(v_raw_text, '')) = '' THEN
        RETURN QUERY SELECT 0, 0, 0, 'LEGACY_UNVERIFIED'::TEXT;
        RETURN;
    END IF;

    CREATE TEMP TABLE IF NOT EXISTS venus_ocr_resolution_tokens (
        token_position INTEGER NOT NULL,
        raw_token TEXT NOT NULL,
        ingredient_id BIGINT,
        candidate_count INTEGER NOT NULL
    ) ON COMMIT DROP;
    TRUNCATE venus_ocr_resolution_tokens;

    INSERT INTO venus_ocr_resolution_tokens (
        token_position,
        raw_token,
        ingredient_id,
        candidate_count
    )
    SELECT
        t.token_position,
        BTRIM(t.raw_token),
        MIN(c.fk_ingredient_id),
        COUNT(DISTINCT c.fk_ingredient_id)::INTEGER
    FROM (
        SELECT
            ordinality::INTEGER AS token_position,
            raw_token
        FROM REGEXP_SPLIT_TO_TABLE(v_raw_text, '\s*[;,]\s*')
             WITH ORDINALITY AS split_tokens(raw_token, ordinality)
        WHERE BTRIM(raw_token) <> ''
    ) t
    LEFT JOIN venus.ingredient_resolution_keys c
      ON c.normalized_key = venus.fn_normalize_ingredient_token(t.raw_token)
    GROUP BY t.token_position, t.raw_token
    ORDER BY t.token_position;

    DELETE FROM venus.product_ingredient_resolution_issues
     WHERE fk_product_version_id = p_product_version_id;

    INSERT INTO venus.product_ingredient_resolution_issues (
        fk_product_version_id,
        token_position,
        raw_token,
        issue_type,
        source_reference
    )
    SELECT
        p_product_version_id,
        rt.token_position,
        rt.raw_token,
        CASE WHEN rt.candidate_count = 0 THEN 'NOT_FOUND' ELSE 'AMBIGUOUS' END,
        v_source_reference
    FROM venus_ocr_resolution_tokens rt
    WHERE rt.candidate_count <> 1;

    SELECT COUNT(*)::INTEGER,
           COUNT(*) FILTER (WHERE candidate_count = 1)::INTEGER,
           COUNT(*) FILTER (WHERE candidate_count <> 1)::INTEGER
      INTO v_total, v_resolved, v_unresolved
      FROM venus_ocr_resolution_tokens;

    -- Só substitui os vínculos existentes quando a lista inteira foi resolvida.
    -- Em uma leitura parcial, preserva o que já existe e deixa a versão bloqueada.
    IF v_total > 0 AND v_unresolved = 0 THEN
        DELETE FROM venus.product_ingredients
         WHERE fk_product_version_id = p_product_version_id;

        INSERT INTO venus.product_ingredients (
            fk_product_version_id,
            fk_ingredient_id,
            position
        )
        SELECT
            p_product_version_id,
            rt.ingredient_id,
            rt.token_position
        FROM venus_ocr_resolution_tokens rt
        WHERE rt.candidate_count = 1
        ORDER BY rt.token_position
        ON CONFLICT (fk_product_version_id, fk_ingredient_id) DO NOTHING;
    END IF;

    PERFORM venus.fn_register_product_composition(
        p_product_version_id,
        COALESCE(NULLIF(v_source_type, ''), 'ocr'),
        COALESCE(v_source_reference, FORMAT('product_label:%s', p_product_version_id)),
        v_raw_text,
        v_total,
        v_resolved,
        v_unresolved,
        CASE WHEN v_total > 0 AND v_unresolved = 0 THEN 'VALID' ELSE 'WARNING' END,
        MD5(v_raw_text)
    );

    RETURN QUERY
    SELECT v_total,
           v_resolved,
           v_unresolved,
           CASE WHEN v_total > 0 AND v_unresolved = 0 THEN 'VALID' ELSE 'WARNING' END;
END;
$$;

CREATE OR REPLACE PROCEDURE venus.sp_resolve_all_current_product_labels()
LANGUAGE PLPGSQL
AS $$
DECLARE
    v_product_version_id BIGINT;
BEGIN
    FOR v_product_version_id IN
        SELECT pv.product_version_id
          FROM venus.product_versions pv
          JOIN venus.product_labels pl
            ON pl.fk_product_version_id = pv.product_version_id
         WHERE pv.is_current = TRUE
           AND BTRIM(COALESCE(pl.normalized_text, '')) <> ''
         ORDER BY pv.product_version_id
    LOOP
        PERFORM venus.fn_resolve_product_label_ingredients(v_product_version_id);
    END LOOP;
END;
$$;

CREATE OR REPLACE FUNCTION venus.fn_auto_resolve_product_label()
RETURNS TRIGGER
LANGUAGE PLPGSQL
AS $$
BEGIN
    PERFORM venus.fn_resolve_product_label_ingredients(NEW.fk_product_version_id);
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_auto_resolve_product_label
    ON venus.product_labels;
CREATE TRIGGER trg_auto_resolve_product_label
AFTER INSERT OR UPDATE OF normalized_text, source_reference, source_type
ON venus.product_labels
FOR EACH ROW
EXECUTE FUNCTION venus.fn_auto_resolve_product_label();

-- Para liberar score, a composição e os quatro eixos de risco dos ingredientes
-- continuam obrigatórios. Embalagem, ética e performance deixam de exigir uma
-- aprovação manual separada: a API calcula essas dimensões com os dados
-- disponíveis e o seu resultado fica sujeito à confiança dos ingredientes.
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
    );
$$;

-- A execução do reprocessamento é feita pelo operador depois do commit da DDL,
-- em uma transação separada, para não manter locks de definição enquanto o
-- catálogo de rótulos é resolvido.
UPDATE venus.product_versions
   SET updated_at = updated_at
 WHERE is_current = TRUE;

COMMENT ON TABLE venus.product_ingredient_resolution_issues IS
    'Tokens OCR não encontrados ou ambíguos; só os casos sem resolução permanecem em needs_review.';
