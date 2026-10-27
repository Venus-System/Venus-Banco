from __future__ import annotations

import os
from pathlib import Path

import psycopg
from dotenv import load_dotenv


ROOT = Path(__file__).resolve().parents[1]
MIGRATION = ROOT / "sql" / "migrations" / "20261012_003_ingredient_descriptions_evaluation_and_api_permissions.sql"


def main() -> None:
    load_dotenv(ROOT / ".env")
    with psycopg.connect(
        os.environ["DATABASE_URL"],
        connect_timeout=15,
        application_name="venus-migration-20261012-003",
    ) as conn:
        conn.execute(MIGRATION.read_text(encoding="utf-8"))
        conn.commit()

        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT COUNT(*) AS total,
                       COUNT(*) FILTER (
                           WHERE NULLIF(BTRIM(description), '') IS NOT NULL
                       ) AS descriptions_filled,
                       COUNT(*) FILTER (
                           WHERE NULLIF(BTRIM(description), '') IS NULL
                       ) AS descriptions_missing
                  FROM venus.ingredients
                """
            )
            print("ingredient_descriptions", cur.fetchone(), flush=True)

            cur.execute(
                """
                SELECT COUNT(*) AS used,
                       COUNT(*) FILTER (WHERE s.is_really_evaluated) AS really_evaluated,
                       COUNT(*) FILTER (WHERE NOT s.is_really_evaluated) AS not_evaluated,
                       COUNT(*) FILTER (WHERE i.scientific_confidence = 1) AS confidence_one,
                       COUNT(*) FILTER (WHERE i.scientific_confidence = 0) AS confidence_zero
                  FROM venus.v_ingredient_evaluation_status s
                  JOIN venus.ingredients i
                    ON i.ingredient_id = s.ingredient_id
                 WHERE EXISTS (
                           SELECT 1
                             FROM venus.product_ingredients pi
                             JOIN venus.product_versions pv
                               ON pv.product_version_id = pi.fk_product_version_id
                              AND pv.is_current
                            WHERE pi.fk_ingredient_id = s.ingredient_id
                       )
                """
            )
            print("used_ingredient_evaluation", cur.fetchone(), flush=True)

            cur.execute(
                """
                SELECT has_table_privilege('api', 'venus.allergy_ingredients', 'SELECT'),
                       has_table_privilege('api', 'venus.allergies', 'SELECT'),
                       has_table_privilege('api', 'venus.ingredients', 'SELECT'),
                       has_table_privilege('api', 'venus.v_ingredient_evaluation_status', 'SELECT')
                """
            )
            print("api_select_privileges", cur.fetchone(), flush=True)

            cur.execute(
                """
                SELECT COUNT(*)
                  FROM venus.v_ingredient_evaluation_status
                 WHERE is_really_evaluated
                   AND scientific_confidence <= 1
                """
            )
            print("evaluated_with_nonpositive_confidence", cur.fetchone()[0], flush=True)


if __name__ == "__main__":
    main()
