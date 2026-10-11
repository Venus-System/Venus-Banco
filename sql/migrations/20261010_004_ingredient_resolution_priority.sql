-- Venus — prioridade determinística para resolução de ingredientes — 2026-10-10
--
-- A resolução deve preferir INCI exato, depois alias e só então nome comum.
-- Isso reduz falsos AMBIGUOUS sem adivinhar ingredientes.

BEGIN;

SET LOCAL lock_timeout = '10s';
SET LOCAL statement_timeout = '120s';
SET LOCAL search_path TO venus, public;

ALTER TABLE venus.ingredient_resolution_keys
    ADD COLUMN IF NOT EXISTS resolution_priority SMALLINT;

UPDATE venus.ingredient_resolution_keys k
   SET resolution_priority = CASE
       WHEN venus.fn_normalize_ingredient_token(i.inci_name) = k.normalized_key THEN 1
       WHEN EXISTS (
           SELECT 1
             FROM venus.ingredient_aliases ia
            WHERE ia.fk_ingredient_id = i.ingredient_id
              AND venus.fn_normalize_ingredient_token(ia.alias_name) = k.normalized_key
       ) THEN 2
       WHEN venus.fn_normalize_ingredient_token(i.common_name) = k.normalized_key THEN 3
       ELSE 99
   END
  FROM venus.ingredients i
 WHERE i.ingredient_id = k.fk_ingredient_id;

ALTER TABLE venus.ingredient_resolution_keys
    ALTER COLUMN resolution_priority SET DEFAULT 99;
ALTER TABLE venus.ingredient_resolution_keys
    ALTER COLUMN resolution_priority SET NOT NULL;

CREATE OR REPLACE FUNCTION venus.fn_rebuild_ingredient_resolution_keys(
    p_ingredient_id BIGINT
)
RETURNS VOID
LANGUAGE PLPGSQL
AS $$
BEGIN
    DELETE FROM venus.ingredient_resolution_keys
     WHERE fk_ingredient_id = p_ingredient_id;

    INSERT INTO venus.ingredient_resolution_keys (
        normalized_key,
        fk_ingredient_id,
        resolution_priority
    )
    SELECT normalized_key,
           p_ingredient_id,
           MIN(resolution_priority)::SMALLINT
      FROM (
          SELECT venus.fn_normalize_ingredient_token(i.inci_name) AS normalized_key,
                 1::SMALLINT AS resolution_priority
            FROM venus.ingredients i
           WHERE i.ingredient_id = p_ingredient_id
          UNION ALL
          SELECT venus.fn_normalize_ingredient_token(ia.alias_name),
                 2::SMALLINT
            FROM venus.ingredient_aliases ia
           WHERE ia.fk_ingredient_id = p_ingredient_id
          UNION ALL
          SELECT venus.fn_normalize_ingredient_token(i.common_name),
                 3::SMALLINT
            FROM venus.ingredients i
           WHERE i.ingredient_id = p_ingredient_id
      ) candidates
     WHERE normalized_key <> ''
     GROUP BY normalized_key
    ON CONFLICT (normalized_key, fk_ingredient_id)
    DO UPDATE SET resolution_priority = EXCLUDED.resolution_priority;
END;
$$;

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

    PERFORM venus.fn_rebuild_ingredient_resolution_keys(NEW.ingredient_id);
    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION venus.fn_sync_ingredient_alias_resolution_key()
RETURNS TRIGGER
LANGUAGE PLPGSQL
AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        PERFORM venus.fn_rebuild_ingredient_resolution_keys(OLD.fk_ingredient_id);
        RETURN OLD;
    END IF;

    IF TG_OP = 'UPDATE' AND OLD.fk_ingredient_id IS DISTINCT FROM NEW.fk_ingredient_id THEN
        PERFORM venus.fn_rebuild_ingredient_resolution_keys(OLD.fk_ingredient_id);
    END IF;

    PERFORM venus.fn_rebuild_ingredient_resolution_keys(NEW.fk_ingredient_id);
    RETURN NEW;
END;
$$;

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
    SELECT t.token_position,
           BTRIM(t.raw_token),
           best.ingredient_id,
           COALESCE(best.candidate_count, 0)::INTEGER
      FROM (
          SELECT ordinality::INTEGER AS token_position,
                 raw_token
            FROM REGEXP_SPLIT_TO_TABLE(v_raw_text, '\s*[;,]\s*')
                 WITH ORDINALITY AS split_tokens(raw_token, ordinality)
           WHERE BTRIM(raw_token) <> ''
      ) t
      LEFT JOIN LATERAL (
          SELECT MIN(r.fk_ingredient_id) FILTER (
                     WHERE r.resolution_priority = r.best_priority
                 ) AS ingredient_id,
                 COUNT(*) FILTER (
                     WHERE r.resolution_priority = r.best_priority
                 ) AS candidate_count
            FROM (
                SELECT k.fk_ingredient_id,
                       k.resolution_priority,
                       MIN(k.resolution_priority) OVER () AS best_priority
                  FROM venus.ingredient_resolution_keys k
                 WHERE k.normalized_key = venus.fn_normalize_ingredient_token(t.raw_token)
            ) r
      ) best ON TRUE
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
    SELECT p_product_version_id,
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

    IF v_total > 0 AND v_unresolved = 0 THEN
        DELETE FROM venus.product_ingredients
         WHERE fk_product_version_id = p_product_version_id;

        INSERT INTO venus.product_ingredients (
            fk_product_version_id,
            fk_ingredient_id,
            position
        )
        SELECT p_product_version_id,
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

COMMENT ON COLUMN venus.ingredient_resolution_keys.resolution_priority IS
    '1=INCI, 2=alias, 3=nome comum; a menor prioridade vence a resolução.';

COMMIT;
