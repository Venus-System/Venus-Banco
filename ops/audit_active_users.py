from __future__ import annotations

import os
from pathlib import Path

import psycopg
from dotenv import load_dotenv


ROOT = Path(__file__).resolve().parents[1]


def main() -> None:
    load_dotenv(ROOT / ".env")
    with psycopg.connect(
        os.environ["DATABASE_URL"],
        connect_timeout=15,
        application_name="venus-audit-active-users",
    ) as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT u.user_id,
                       u.name,
                       COALESCE(LEFT(u.email, 24), '') AS email_prefix,
                       LEFT(u.firebase_uid, 18) AS uid_prefix,
                       u.last_login,
                       u.created_at,
                       (SELECT COUNT(*) FROM venus.user_access_events e
                         WHERE e.fk_user_id = u.user_id) AS access_events,
                       (SELECT COUNT(*) FROM venus.user_preferences p
                         WHERE p.fk_user_id = u.user_id) AS preferences,
                       (SELECT COUNT(*) FROM venus.user_profiles p
                         WHERE p.fk_user_id = u.user_id) AS profiles,
                       (SELECT COUNT(*) FROM venus.analysis_results a
                         WHERE a.fk_user_id = u.user_id) AS analyses
                  FROM venus.users u
                 WHERE u.status = 'active'
                 ORDER BY u.user_id
                """
            )
            for row in cur.fetchall():
                print(row)


if __name__ == "__main__":
    main()
