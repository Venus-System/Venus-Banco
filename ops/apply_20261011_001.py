from __future__ import annotations

import os
from pathlib import Path

import psycopg
from dotenv import load_dotenv


ROOT = Path(__file__).resolve().parents[1]
MIGRATION = ROOT / "sql" / "migrations" / "20261011_001_fragrance_canonical_confidence_evidence.sql"


def main() -> None:
    load_dotenv(ROOT / ".env")
    sql = MIGRATION.read_text(encoding="utf-8")
    with psycopg.connect(
        os.environ["DATABASE_URL"],
        connect_timeout=15,
        application_name="venus-migration-20261011-001",
    ) as conn:
        conn.execute(sql)
        conn.commit()
    print(f"OK: applied {MIGRATION.name}")


if __name__ == "__main__":
    main()
