import os
from pathlib import Path

import psycopg
from dotenv import load_dotenv


ROOT = Path(__file__).resolve().parents[1]
load_dotenv(ROOT / ".env")


def main() -> None:
    sql_path = ROOT / "sql" / "migrations" / "20261010_006_clear_stale_placeholder_issues.sql"
    with psycopg.connect(os.environ["DATABASE_URL"], application_name="venus-migration-20261010-006") as conn:
        conn.execute(sql_path.read_text(encoding="utf-8"))
        conn.commit()
        print("ddl_committed", flush=True)
        conn.execute("CALL venus.sp_resolve_all_current_product_labels()")
        conn.commit()
        print("ocr_resolution_committed", flush=True)


if __name__ == "__main__":
    main()
