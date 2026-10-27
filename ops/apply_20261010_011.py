from __future__ import annotations

import os
from pathlib import Path

import psycopg
from dotenv import load_dotenv


ROOT = Path(__file__).resolve().parents[1]
load_dotenv(ROOT / ".env")


def main() -> None:
    sql_path = ROOT / "sql" / "migrations" / "20261010_011_finish_reference_formula_gaps.sql"
    with psycopg.connect(
        os.environ["DATABASE_URL"],
        connect_timeout=15,
        application_name="venus-migration-20261010-011",
    ) as conn:
        conn.execute(sql_path.read_text(encoding="utf-8"))
        conn.commit()
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT current_database(),
                       COUNT(*) FILTER (WHERE pv.status = 'verified'),
                       COUNT(*) FILTER (WHERE pv.status = 'needs_review'),
                       COUNT(*) FILTER (WHERE venus.fn_product_version_data_ready(pv.product_version_id))
                  FROM venus.product_versions pv
                 WHERE pv.is_current
                """
            )
            print("reference_formula_gaps_committed", cur.fetchone(), flush=True)


if __name__ == "__main__":
    main()
