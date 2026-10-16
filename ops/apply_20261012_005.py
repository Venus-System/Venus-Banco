from __future__ import annotations

import os
from pathlib import Path

import psycopg
from dotenv import load_dotenv


ROOT = Path(__file__).resolve().parents[1]
load_dotenv(ROOT / ".env")


def main() -> None:
    sql_path = ROOT / "sql" / "migrations" / "20261012_005_unaccent_search.sql"
    with psycopg.connect(
        os.environ["DATABASE_URL"],
        connect_timeout=15,
        application_name="venus-migration-20261012-005",
    ) as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT current_database(), current_user")
            database, user = cur.fetchone()
            if database != "Venus-qa":
                raise RuntimeError(f"banco inesperado: {database!r}")
        conn.execute(sql_path.read_text(encoding="utf-8"))
        conn.commit()

        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT e.extname, n.nspname
                  FROM pg_extension e
                  JOIN pg_namespace n ON n.oid = e.extnamespace
                 WHERE e.extname = 'unaccent'
                """
            )
            extension = cur.fetchone()
            cur.execute(
                """
                SELECT venus.unaccent('Loção') = 'Locao',
                       COUNT(*)
                  FROM venus.products p
                 WHERE venus.unaccent(lower(p.name))
                       LIKE '%' || venus.unaccent(lower('locao')) || '%'
                """
            )
            matches = cur.fetchone()

    print("database", database, "user", user)
    print("extension", extension)
    print("search_test_accent_removed", matches[0])
    print("products_matching_locao", matches[1])


if __name__ == "__main__":
    main()
