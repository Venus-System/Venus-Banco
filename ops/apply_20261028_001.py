from __future__ import annotations

import argparse
import os
from pathlib import Path
from urllib.parse import urlsplit, urlunsplit

import psycopg
from dotenv import load_dotenv


ROOT = Path(__file__).resolve().parents[1]
MIGRATION = ROOT / "sql" / "migrations" / "20261028_001_user_location_columns.sql"
LOCATION_COLUMNS = ("latitude", "longitude", "city", "state")


def venus_2ano_url(database_url: str) -> str:
    parsed = urlsplit(database_url)
    return urlunsplit(parsed._replace(path="/Venus-2ano"))


def apply_target(label: str, expected_database: str, url: str) -> None:
    print(f"[{label}] conectando", flush=True)
    with psycopg.connect(
        url,
        connect_timeout=15,
        application_name="venus-migration-20261028-001",
    ) as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT current_database(), current_user")
            database, user = cur.fetchone()
        if database != expected_database:
            raise RuntimeError(
                f"[{label}] banco inesperado: {database!r}; esperado {expected_database!r}"
            )

        conn.execute(MIGRATION.read_text(encoding="utf-8"))
        conn.commit()

        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT column_name, data_type, numeric_precision,
                       numeric_scale, is_nullable
                FROM information_schema.columns
                WHERE table_schema = 'venus'
                  AND table_name = 'users'
                  AND column_name = ANY(%s)
                ORDER BY array_position(%s::text[], column_name)
                """,
                (list(LOCATION_COLUMNS), list(LOCATION_COLUMNS)),
            )
            columns = cur.fetchall()
            expected_columns = [
                ("latitude", "numeric", 5, 2, "YES"),
                ("longitude", "numeric", 5, 2, "YES"),
                ("city", "text", None, None, "YES"),
                ("state", "text", None, None, "YES"),
            ]
            if columns != expected_columns:
                raise RuntimeError(
                    f"[{label}] definição das colunas inesperada: {columns!r}"
                )

            cur.execute(
                """
                SELECT conname, pg_get_constraintdef(oid)
                FROM pg_constraint
                WHERE conrelid = 'venus.users'::regclass
                  AND conname IN (
                      'ck_users_latitude_range',
                      'ck_users_longitude_range'
                  )
                ORDER BY conname
                """
            )
            constraints = cur.fetchall()
            if len(constraints) != 2:
                raise RuntimeError(
                    f"[{label}] constraints de faixa ausentes: {constraints!r}"
                )
            constraint_text = " ".join(definition.lower() for _, definition in constraints)
            for token in ("latitude", "longitude", "-90", "90", "-180", "180"):
                if token not in constraint_text:
                    raise RuntimeError(
                        f"[{label}] constraint sem a faixa esperada: {constraints!r}"
                    )

            cur.execute(
                """
                SELECT rolname
                FROM pg_roles
                WHERE rolname IN ('api', 'api_ia')
                ORDER BY rolname
                """
            )
            roles = [row[0] for row in cur.fetchall()]
            for role in roles:
                cur.execute(
                    "SELECT has_table_privilege(%s, 'venus.users', 'SELECT,INSERT,UPDATE')",
                    (role,),
                )
                if not cur.fetchone()[0]:
                    raise RuntimeError(
                        f"[{label}] {role} não tem SELECT/INSERT/UPDATE em venus.users"
                    )

            cur.execute(
                """
                SELECT EXISTS (
                    SELECT 1
                    FROM pg_trigger
                    WHERE tgrelid = 'venus.users'::regclass
                      AND tgname = 'trg_audit_users'
                      AND NOT tgisinternal
                )
                """
            )
            if not cur.fetchone()[0]:
                raise RuntimeError(f"[{label}] trigger de auditoria de users ausente")

            cur.execute(
                """
                SELECT COUNT(*)
                FROM venus.data_catalog_rules
                WHERE object_type = 'COLUMN'
                  AND table_name = 'users'
                  AND column_name = ANY(%s)
                  AND is_active
                """,
                (list(LOCATION_COLUMNS),),
            )
            catalog_count = cur.fetchone()[0]

        print(
            f"[{label}] database={database}; user={user}; "
            f"columns={len(columns)}; range_constraints={len(constraints)}; "
            f"catalog_rules={catalog_count}; audit_trigger=True",
            flush=True,
        )


def main() -> None:
    load_dotenv(ROOT / ".env")
    parser = argparse.ArgumentParser(
        description="Aplica a localização aproximada nos bancos Venus-qa e Venus-2ano."
    )
    parser.add_argument("--database-url", default=os.getenv("DATABASE_URL"))
    parser.add_argument(
        "--venus-2ano-url",
        default=None,
        help="URL opcional do Venus-2ano; por padrão é derivada de DATABASE_URL.",
    )
    args = parser.parse_args()
    if not args.database_url:
        raise SystemExit("Defina DATABASE_URL no .env ou passe --database-url.")

    apply_target("Venus-qa", "Venus-qa", args.database_url)
    apply_target(
        "Venus-2ano",
        "Venus-2ano",
        args.venus_2ano_url or venus_2ano_url(args.database_url),
    )


if __name__ == "__main__":
    main()
