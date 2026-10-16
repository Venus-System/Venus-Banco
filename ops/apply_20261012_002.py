from __future__ import annotations

import os
from pathlib import Path

import psycopg
from dotenv import load_dotenv


ROOT = Path(__file__).resolve().parents[1]
MIGRATION = ROOT / "sql" / "migrations" / "20261012_002_promote_complete_assessments.sql"


def main() -> None:
    load_dotenv(ROOT / ".env")
    with psycopg.connect(
        os.environ["DATABASE_URL"],
        connect_timeout=15,
        application_name="venus-migration-20261012-002",
    ) as conn:
        conn.execute(MIGRATION.read_text(encoding="utf-8"))
        conn.commit()
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT COUNT(*) FILTER (WHERE scientific_confidence > 0),
                       COUNT(*) FILTER (WHERE scientific_confidence = 0),
                       COUNT(*) FILTER (WHERE scientific_confidence = 1)
                  FROM venus.ingredients i
                 WHERE EXISTS (
                     SELECT 1
                       FROM venus.product_ingredients pi
                       JOIN venus.product_versions pv
                         ON pv.product_version_id = pi.fk_product_version_id
                        AND pv.is_current
                      WHERE pi.fk_ingredient_id = i.ingredient_id
                 )
                """
            )
            print("used_ingredients_confidence", cur.fetchone(), flush=True)

            cur.execute("SELECT COUNT(*) FROM venus.product_scores")
            print("scores_remaining", cur.fetchone(), flush=True)


if __name__ == "__main__":
    main()
