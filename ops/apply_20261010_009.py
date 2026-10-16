import os
from pathlib import Path

import psycopg
from dotenv import load_dotenv


ROOT = Path(__file__).resolve().parents[1]
load_dotenv(ROOT / ".env")


def main() -> None:
    sql_path = ROOT / "sql" / "migrations" / "20261010_009_indirect_risk_assessments_v1.sql"
    with psycopg.connect(os.environ["DATABASE_URL"], application_name="venus-migration-20261010-009") as conn:
        conn.execute(sql_path.read_text(encoding="utf-8"))
        conn.commit()
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT COUNT(*) AS used_ingredients,
                       COUNT(*) FILTER (WHERE has_four_approved_dimensions) AS four_approved,
                       COUNT(*) FILTER (WHERE lowest_evidence_level = 'low') AS indirect_low
                  FROM venus.v_ingredient_risk_coverage
                """
            )
            coverage = cur.fetchone()
            cur.execute(
                """
                SELECT COUNT(*) FILTER (WHERE pv.status = 'verified') AS verified,
                       COUNT(*) FILTER (WHERE pv.status = 'needs_review') AS needs_review,
                       COUNT(*) FILTER (WHERE venus.fn_product_version_data_ready(pv.product_version_id)) AS data_ready
                  FROM venus.product_versions pv
                 WHERE pv.is_current
                """
            )
            versions = cur.fetchone()
            cur.execute(
                """
                SELECT assessment_version, evidence_level::text, assessment_status,
                       COUNT(*)
                  FROM venus.ingredient_risk_assessments
                 GROUP BY assessment_version, evidence_level, assessment_status
                 ORDER BY assessment_version, evidence_level, assessment_status
                """
            )
            print("indirect_risk_v1_committed", flush=True)
            print("coverage", coverage)
            print("versions", versions)
            print("assessments", cur.fetchall())


if __name__ == "__main__":
    main()
