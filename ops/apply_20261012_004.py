from __future__ import annotations

import os
from pathlib import Path

import psycopg
from dotenv import load_dotenv


ROOT = Path(__file__).resolve().parents[1]
MIGRATION = ROOT / "sql" / "migrations" / "20261012_004_deactivate_non_real_users.sql"


def main() -> None:
    load_dotenv(ROOT / ".env")
    with psycopg.connect(
        os.environ["DATABASE_URL"],
        connect_timeout=15,
        application_name="venus-migration-20261012-004",
    ) as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT COUNT(*)
                  FROM venus.users
                 WHERE status = 'active'
                   AND (
                       firebase_uid LIKE 'venus-seed-user-%'
                       OR firebase_uid LIKE 'legacy-%'
                       OR LOWER(COALESCE(name, '')) LIKE '%teste%'
                       OR LOWER(COALESCE(email, '')) LIKE '%@exemplo.%'
                   )
                """
            )
            candidate_count = cur.fetchone()[0]

        conn.execute(MIGRATION.read_text(encoding="utf-8"))
        conn.commit()

        with conn.cursor() as cur:
            cur.execute("SELECT status, COUNT(*) FROM venus.users GROUP BY status ORDER BY status")
            print("user_status_counts", cur.fetchall(), flush=True)

            cur.execute(
                """
                SELECT COUNT(*)
                  FROM venus.users
                 WHERE status = 'active'
                   AND (
                       firebase_uid LIKE 'venus-seed-user-%'
                       OR firebase_uid LIKE 'legacy-%'
                       OR LOWER(COALESCE(name, '')) LIKE '%teste%'
                       OR LOWER(COALESCE(email, '')) LIKE '%@exemplo.%'
                   )
                """
            )
            remaining_artificial = cur.fetchone()[0]
            print("candidates_before", candidate_count, flush=True)
            print("artificial_active_remaining", remaining_artificial, flush=True)

            cur.execute(
                """
                SELECT user_id, name, email, firebase_uid
                  FROM venus.users
                 WHERE status = 'active'
                 ORDER BY user_id
                """
            )
            print("preserved_active_users", cur.fetchall(), flush=True)


if __name__ == "__main__":
    main()
