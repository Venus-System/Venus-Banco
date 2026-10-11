from __future__ import annotations

import os
from pathlib import Path

import psycopg
from dotenv import load_dotenv


ROOT = Path(__file__).resolve().parents[1]
load_dotenv(ROOT / ".env")


def main() -> None:
    sql_path = ROOT / "sql" / "migrations" / "20261010_010_reference_formula_backfill.sql"
    with psycopg.connect(
        os.environ["DATABASE_URL"],
        connect_timeout=15,
        application_name="venus-migration-20261010-010",
    ) as conn:
        conn.execute(sql_path.read_text(encoding="utf-8"))
        conn.commit()
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT current_database(), current_user,
                       COUNT(*) FILTER (WHERE pv.status = 'verified') AS verified,
                       COUNT(*) FILTER (WHERE pv.status = 'needs_review') AS needs_review,
                       COUNT(*) FILTER (WHERE venus.fn_product_version_data_ready(pv.product_version_id)) AS data_ready
                  FROM venus.product_versions pv
                 WHERE pv.is_current
                """
            )
            print("reference_formula_backfill_committed", flush=True)
            print(cur.fetchone(), flush=True)

            cur.execute(
                """
                SELECT COUNT(*) AS current_versions,
                       COUNT(*) FILTER (WHERE pl.source_type = 'system') AS reference_labels,
                       COUNT(*) FILTER (WHERE cr.validation_status = 'VALID') AS valid_receipts,
                       COUNT(*) FILTER (WHERE venus.fn_product_version_data_ready(pv.product_version_id)) AS ready
                  FROM venus.product_versions pv
                  LEFT JOIN venus.product_labels pl
                    ON pl.fk_product_version_id = pv.product_version_id
                  LEFT JOIN venus.product_composition_receipts cr
                    ON cr.fk_product_version_id = pv.product_version_id
                   AND cr.is_current
                 WHERE pv.is_current
                """
            )
            print("readiness", cur.fetchone(), flush=True)

            cur.execute(
                """
                SELECT pri.issue_type, COUNT(*)
                  FROM venus.product_ingredient_resolution_issues pri
                  JOIN venus.product_versions pv
                    ON pv.product_version_id = pri.fk_product_version_id
                 WHERE pv.is_current
                 GROUP BY pri.issue_type
                 ORDER BY pri.issue_type
                """
            )
            print("issues", cur.fetchall(), flush=True)

            cur.execute(
                """
                SELECT COUNT(DISTINCT pi.fk_ingredient_id) AS used_ingredients,
                       COUNT(DISTINCT pi.fk_ingredient_id) FILTER (
                           WHERE EXISTS (
                               SELECT 1
                                 FROM venus.ingredient_risk_assessments ira
                                WHERE ira.fk_ingredient_id = pi.fk_ingredient_id
                                  AND ira.assessment_status = 'approved'
                                GROUP BY ira.fk_ingredient_id
                               HAVING COUNT(DISTINCT ira.dimension) = 4
                           )
                       ) AS four_assessed
                  FROM venus.product_versions pv
                  JOIN venus.product_ingredients pi
                    ON pi.fk_product_version_id = pv.product_version_id
                 WHERE pv.is_current
                """
            )
            print("ingredient_coverage", cur.fetchone(), flush=True)


if __name__ == "__main__":
    main()
