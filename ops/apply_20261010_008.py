import os
from pathlib import Path

import psycopg
from dotenv import load_dotenv


ROOT = Path(__file__).resolve().parents[1]
load_dotenv(ROOT / ".env")


def main() -> None:
    sql_path = ROOT / "sql" / "migrations" / "20261010_008_official_formula_backfill.sql"
    with psycopg.connect(os.environ["DATABASE_URL"], application_name="venus-migration-20261010-008") as conn:
        conn.execute(sql_path.read_text(encoding="utf-8"))
        conn.commit()
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT COUNT(*) FILTER (WHERE pl.source_type = 'official_site') AS official_labels,
                       COUNT(*) FILTER (WHERE cr.validation_status = 'VALID') AS valid_receipts,
                       COUNT(*) FILTER (WHERE cr.validation_status = 'WARNING') AS warning_receipts,
                       COUNT(*) FILTER (WHERE pv.status = 'needs_review') AS needs_review,
                       COUNT(*) FILTER (WHERE pv.status = 'verified') AS verified
                  FROM venus.product_versions pv
                  LEFT JOIN venus.product_labels pl
                    ON pl.fk_product_version_id = pv.product_version_id
                  LEFT JOIN venus.product_composition_receipts cr
                    ON cr.fk_product_version_id = pv.product_version_id
                   AND cr.is_current
                 WHERE pv.is_current
                """
            )
            print("official_formula_backfill_committed", flush=True)
            print(cur.fetchone())


if __name__ == "__main__":
    main()
