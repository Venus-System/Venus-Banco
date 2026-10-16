from __future__ import annotations

import os
from pathlib import Path

import psycopg
from dotenv import load_dotenv


ROOT = Path(__file__).resolve().parents[1]
load_dotenv(ROOT / ".env")


def main() -> None:
    with psycopg.connect(
        os.environ["DATABASE_URL"],
        connect_timeout=15,
        application_name="venus-readiness-audit",
    ) as conn:
        with conn.cursor() as cur:
            queries = {
                "database": "SELECT current_database(), current_user",
                "versions": """
                    SELECT pv.status, COUNT(*)
                      FROM venus.product_versions pv
                     WHERE pv.is_current
                     GROUP BY pv.status
                     ORDER BY pv.status
                """,
                "receipts": """
                    SELECT cr.validation_status, COUNT(*)
                      FROM venus.product_composition_receipts cr
                      JOIN venus.product_versions pv
                        ON pv.product_version_id = cr.fk_product_version_id
                     WHERE pv.is_current AND cr.is_current
                     GROUP BY cr.validation_status
                     ORDER BY cr.validation_status
                """,
                "sources_with_links": """
                    SELECT COALESCE(pv.detected_by::text, '<null>') AS detected_by,
                           COALESCE(pl.source_type::text, '<no label>') AS label_source,
                           COUNT(DISTINCT pv.product_version_id) AS versions,
                           COUNT(pi.product_ingredient_id) AS links
                      FROM venus.product_versions pv
                      LEFT JOIN venus.product_labels pl
                        ON pl.fk_product_version_id = pv.product_version_id
                      LEFT JOIN venus.product_ingredients pi
                        ON pi.fk_product_version_id = pv.product_version_id
                     WHERE pv.is_current
                     GROUP BY 1, 2
                     ORDER BY 1, 2
                """,
                "issues": """
                    SELECT issue_type, COUNT(*)
                      FROM venus.product_ingredient_resolution_issues
                     GROUP BY issue_type
                     ORDER BY issue_type
                """,
                "not_found_by_source": """
                    SELECT COALESCE(pl.source_type::text, '<no label>') AS source_type,
                           pri.raw_token,
                           COUNT(*)
                      FROM venus.product_ingredient_resolution_issues pri
                      JOIN venus.product_versions pv
                        ON pv.product_version_id = pri.fk_product_version_id
                      LEFT JOIN venus.product_labels pl
                        ON pl.fk_product_version_id = pv.product_version_id
                     WHERE pv.is_current
                       AND pri.issue_type = 'NOT_FOUND'
                     GROUP BY 1, 2
                     ORDER BY 1, 3 DESC, 2
                     LIMIT 200
                """,
                "coverage": """
                    SELECT COUNT(*) AS current_versions,
                           COUNT(*) FILTER (WHERE EXISTS (
                               SELECT 1 FROM venus.product_ingredients pi
                               WHERE pi.fk_product_version_id = pv.product_version_id
                           )) AS with_links,
                           COUNT(*) FILTER (WHERE venus.fn_product_version_data_ready(pv.product_version_id)) AS ready
                      FROM venus.product_versions pv
                     WHERE pv.is_current
                """,
                "ingredients": """
                    SELECT COUNT(DISTINCT pi.fk_ingredient_id) AS used_ingredients,
                           COUNT(DISTINCT ira.fk_ingredient_id) AS assessed_ingredients,
                           COUNT(DISTINCT ira.fk_ingredient_id) FILTER (WHERE ira.assessment_status = 'approved') AS approved_ingredients
                      FROM venus.product_versions pv
                      JOIN venus.product_ingredients pi
                        ON pi.fk_product_version_id = pv.product_version_id
                      LEFT JOIN venus.ingredient_risk_assessments ira
                        ON ira.fk_ingredient_id = pi.fk_ingredient_id
                     WHERE pv.is_current
                """,
                "placeholder_ingredients": """
                    SELECT i.ingredient_id,
                           i.inci_name,
                           COUNT(pi.product_ingredient_id) AS links
                      FROM venus.ingredients i
                      LEFT JOIN venus.product_ingredients pi
                        ON pi.fk_ingredient_id = i.ingredient_id
                     WHERE venus.fn_normalize_ingredient_token(i.inci_name) LIKE 'cat%'
                        OR i.inci_name ILIKE '%consultar%'
                     GROUP BY i.ingredient_id, i.inci_name
                     ORDER BY i.ingredient_id
                """,
                "placeholder_labels": """
                    SELECT pv.product_version_id,
                           LEFT(pl.normalized_text, 40),
                           venus.fn_normalize_ingredient_token(LEFT(pl.normalized_text, 40)),
                           LENGTH(pl.normalized_text)
                      FROM venus.product_versions pv
                      JOIN venus.product_labels pl
                        ON pl.fk_product_version_id = pv.product_version_id
                     WHERE pv.is_current
                       AND pl.source_type = 'official_site'
                       AND UPPER(BTRIM(pl.normalized_text)) LIKE 'CAT%'
                     ORDER BY pv.product_version_id
                """,
                "missing_composition_examples": """
                    SELECT pv.product_version_id,
                           p.name,
                           pv.detected_by,
                           CASE WHEN pl.product_label_id IS NULL THEN 'NO_LABEL' ELSE 'NO_LINKS_OR_WARNING' END,
                           pl.source_reference
                      FROM venus.product_versions pv
                      JOIN venus.products p ON p.product_id = pv.fk_product_id
                      LEFT JOIN venus.product_labels pl
                        ON pl.fk_product_version_id = pv.product_version_id
                      LEFT JOIN venus.product_ingredients pi
                        ON pi.fk_product_version_id = pv.product_version_id
                     WHERE pv.is_current
                     GROUP BY pv.product_version_id, p.name, pv.detected_by,
                              pl.product_label_id, pl.source_reference
                    HAVING COUNT(pi.product_ingredient_id) = 0
                     ORDER BY pv.product_version_id
                     LIMIT 80
                """,
                "automation_guards": """
                    SELECT tg.tgname,
                           c.relname,
                           pg_get_triggerdef(tg.oid)
                      FROM pg_trigger tg
                      JOIN pg_class c ON c.oid = tg.tgrelid
                      JOIN pg_namespace n ON n.oid = c.relnamespace
                     WHERE n.nspname = 'venus'
                       AND NOT tg.tgisinternal
                       AND tg.tgname IN (
                           'trg_auto_resolve_product_label',
                           'trg_product_version_readiness',
                           'trg_product_score_readiness_guard'
                       )
                     ORDER BY tg.tgname
                """,
                "readiness_triggers": """
                    SELECT c.relname,
                           tg.tgname,
                           pg_get_triggerdef(tg.oid)
                      FROM pg_trigger tg
                      JOIN pg_class c ON c.oid = tg.tgrelid
                      JOIN pg_namespace n ON n.oid = c.relnamespace
                     WHERE n.nspname = 'venus'
                       AND NOT tg.tgisinternal
                       AND c.relname IN ('product_versions', 'product_scores', 'product_labels')
                     ORDER BY c.relname, tg.tgname
                """,
                "official_examples": """
                    SELECT pv.product_version_id,
                           p.name,
                           pv.detected_by,
                           pl.source_reference,
                           LENGTH(pl.normalized_text) AS label_length,
                           COALESCE(cr.validation_status::text, '<no receipt>'),
                           COUNT(DISTINCT pi.fk_ingredient_id) AS linked_ingredients,
                           COUNT(DISTINCT pri.product_ingredient_resolution_issue_id) AS issues
                      FROM venus.product_versions pv
                      JOIN venus.products p ON p.product_id = pv.fk_product_id
                      LEFT JOIN venus.product_labels pl
                        ON pl.fk_product_version_id = pv.product_version_id
                      LEFT JOIN venus.product_composition_receipts cr
                        ON cr.fk_product_version_id = pv.product_version_id
                       AND cr.is_current
                      LEFT JOIN venus.product_ingredients pi
                        ON pi.fk_product_version_id = pv.product_version_id
                      LEFT JOIN venus.product_ingredient_resolution_issues pri
                        ON pri.fk_product_version_id = pv.product_version_id
                     WHERE pv.is_current
                       AND pv.detected_by = 'official_site'
                     GROUP BY pv.product_version_id, p.name, pv.detected_by,
                              pl.source_reference, pl.normalized_text,
                              cr.validation_status
                     ORDER BY issues DESC, linked_ingredients DESC, pv.product_version_id
                     LIMIT 20
                """,
            }
            for name, query in queries.items():
                cur.execute(query)
                print(name, cur.fetchall())


if __name__ == "__main__":
    main()
