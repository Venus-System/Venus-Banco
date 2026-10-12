from __future__ import annotations

import os
from pathlib import Path

import psycopg
from dotenv import load_dotenv


ROOT = Path(__file__).resolve().parents[1]
MIGRATION = ROOT / "sql" / "migrations" / "20261011_002_ingredient_descriptions_and_brand_consolidation.sql"


def main() -> None:
    load_dotenv(ROOT / ".env")
    with psycopg.connect(
        os.environ["DATABASE_URL"],
        connect_timeout=15,
        application_name="venus-migration-20261011-002",
    ) as conn:
        conn.execute(MIGRATION.read_text(encoding="utf-8"))
        conn.commit()
        with conn.cursor() as cur:
            cur.execute(
                """
                WITH used AS (
                    SELECT DISTINCT pi.fk_ingredient_id AS ingredient_id
                      FROM venus.product_ingredients pi
                      JOIN venus.product_versions pv
                        ON pv.product_version_id = pi.fk_product_version_id
                     WHERE COALESCE(pv.is_current, TRUE)
                )
                SELECT COUNT(*) AS used,
                       COUNT(*) FILTER (
                           WHERE NULLIF(BTRIM(i.description), '') IS NOT NULL
                       ) AS descriptions_filled,
                       COUNT(*) FILTER (
                           WHERE NULLIF(BTRIM(i.description), '') IS NULL
                       ) AS descriptions_missing
                  FROM used u
                  JOIN venus.ingredients i
                    ON i.ingredient_id = u.ingredient_id
                """
            )
            descriptions = cur.fetchone()

            cur.execute(
                """
                SELECT b.brand_id, b.name, COUNT(p.product_id) AS product_count
                  FROM venus.brands b
                  LEFT JOIN venus.products p
                    ON p.fk_brand_id = b.brand_id
                 WHERE LOWER(BTRIM(b.name)) IN ('cerave', 'la roche-posay', 'rexona')
                 GROUP BY b.brand_id, b.name
                 ORDER BY b.brand_id
                """
            )
            brands = cur.fetchall()

            print("ingredient_descriptions", descriptions, flush=True)
            print("canonical_brands", brands, flush=True)


if __name__ == "__main__":
    main()
