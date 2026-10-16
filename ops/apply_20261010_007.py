import os
from pathlib import Path

import psycopg
from dotenv import load_dotenv


ROOT = Path(__file__).resolve().parents[1]
load_dotenv(ROOT / ".env")


def main() -> None:
    sql_path = ROOT / "sql" / "migrations" / "20261010_007_risk_methodology_v1.sql"
    with psycopg.connect(os.environ["DATABASE_URL"], application_name="venus-migration-20261010-007") as conn:
        conn.execute(sql_path.read_text(encoding="utf-8"))
        conn.commit()
        print("methodology_v1_committed", flush=True)
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT methodology_version, status,
                       (SELECT COUNT(*) FROM venus.ingredient_risk_methodology_dimensions d
                         WHERE d.methodology_version = m.methodology_version),
                       (SELECT COUNT(*) FROM venus.v_ingredient_risk_coverage)
                  FROM venus.ingredient_risk_methodologies m
                 WHERE methodology_version = 'v1'
                """
            )
            print(cur.fetchone())


if __name__ == "__main__":
    main()
