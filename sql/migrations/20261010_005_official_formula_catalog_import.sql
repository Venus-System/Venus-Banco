-- Venus — catálogo automático a partir de fórmulas oficiais — 2026-10-10
--
-- Só cadastra tokens presentes em rótulos de origem official_site. Não cria
-- avaliações de risco: os novos ingredientes continuam bloqueados até haver
-- evidência aprovada para os quatro eixos.

BEGIN;

SET LOCAL lock_timeout = '10s';
SET LOCAL statement_timeout = '120s';
SET LOCAL search_path TO venus, public;

CREATE OR REPLACE FUNCTION venus.fn_split_product_label_tokens(p_text TEXT)
RETURNS TABLE (
    token_position INTEGER,
    raw_token TEXT
)
LANGUAGE SQL
IMMUTABLE
AS $$
    SELECT ordinality::INTEGER,
           BTRIM(REPLACE(raw_token, CHR(31), ','))
      FROM REGEXP_SPLIT_TO_TABLE(
               REGEXP_REPLACE(
                   COALESCE(p_text, ''),
                   '([0-9]),([0-9])',
                   E'\\1' || CHR(31) || E'\\2',
                   'g'
               ),
               '\s*[,;]\s*'
           ) WITH ORDINALITY AS split_tokens(raw_token, ordinality)
     WHERE BTRIM(REPLACE(raw_token, CHR(31), ',')) <> '';
$$;

-- A mensagem de catálogo é um marcador de ausência de composição, não uma
-- lista de ingredientes. Ela fica pendente sem gerar falsos NOT_FOUND.
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

    IF venus.fn_normalize_ingredient_token(v_raw_text) LIKE 'catalogooficial%' THEN
        PERFORM venus.fn_register_product_composition(
            p_product_version_id,
            COALESCE(NULLIF(v_source_type, ''), 'official_site'),
            COALESCE(v_source_reference, FORMAT('product_label:%s', p_product_version_id)),
            v_raw_text,
            0,
            0,
            1,
            'WARNING',
            MD5(v_raw_text)
        );
        RETURN QUERY SELECT 0, 0, 1, 'LEGACY_UNVERIFIED'::TEXT;
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
           t.raw_token,
           best.ingredient_id,
           COALESCE(best.candidate_count, 0)::INTEGER
      FROM venus.fn_split_product_label_tokens(v_raw_text) t
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

-- Ingredientes ausentes, mas explicitamente declarados em uma fonte oficial,
-- entram no catálogo com risco ainda não avaliado. O valor default 0 continua
-- significando "não avaliado" e o gate impede que seja usado como risco zero.
INSERT INTO venus.ingredients (
    fk_ingredient_category_id,
    inci_name,
    source_type,
    source_reference
)
SELECT cat.ingredient_category_id,
       UPPER(BTRIM(t.raw_token)),
       'official_site',
       MIN(pl.source_reference)
  FROM venus.product_versions pv
  JOIN venus.product_labels pl
    ON pl.fk_product_version_id = pv.product_version_id
  CROSS JOIN LATERAL venus.fn_split_product_label_tokens(pl.normalized_text) t
  JOIN venus.ingredient_categories cat
    ON cat.name = 'Não classificado'
 WHERE pv.is_current
   AND pl.source_type = 'official_site'
   AND venus.fn_normalize_ingredient_token(pl.normalized_text) NOT LIKE 'catalogooficial%'
   AND BTRIM(t.raw_token) <> ''
   AND LENGTH(BTRIM(t.raw_token)) BETWEEN 2 AND 300
   AND t.raw_token ~ '[[:alpha:]]'
   AND NOT EXISTS (
       SELECT 1
         FROM venus.ingredients i
        WHERE venus.fn_normalize_ingredient_token(i.inci_name) =
              venus.fn_normalize_ingredient_token(t.raw_token)
   )
 GROUP BY cat.ingredient_category_id,
          venus.fn_normalize_ingredient_token(t.raw_token),
          UPPER(BTRIM(t.raw_token));

COMMIT;
