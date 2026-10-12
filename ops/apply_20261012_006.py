from __future__ import annotations

import os
from pathlib import Path

import psycopg
from dotenv import load_dotenv


ROOT = Path(__file__).resolve().parents[1]
MIGRATION = ROOT / "sql" / "migrations" / "20261012_006_brand_claim_unknown_state.sql"


def main() -> None:
    load_dotenv(ROOT / ".env")

    with psycopg.connect(
        os.environ["DATABASE_URL"],
        connect_timeout=15,
        application_name="venus-migration-20261012-006",
    ) as conn:
        conn.execute(MIGRATION.read_text(encoding="utf-8"))
        conn.commit()

        checks = {
            "session": """
                SELECT current_database(), current_user
            """,
            "brands": """
                SELECT
                    COUNT(*) AS total,
                    COUNT(*) FILTER (WHERE has_vegan_claim IS TRUE) AS vegan_true,
                    COUNT(*) FILTER (WHERE has_vegan_claim IS FALSE) AS vegan_false,
                    COUNT(*) FILTER (WHERE has_vegan_claim IS NULL) AS vegan_unknown,
                    COUNT(*) FILTER (WHERE has_cruelty_free_claim IS TRUE) AS cruelty_free_true,
                    COUNT(*) FILTER (WHERE has_cruelty_free_claim IS FALSE) AS cruelty_free_false,
                    COUNT(*) FILTER (WHERE has_cruelty_free_claim IS NULL) AS cruelty_free_unknown
                FROM venus.brands
            """,
            "evidence": """
                SELECT COUNT(*)
                  FROM venus.brand_claim_evidence
            """,
            "statuses": """
                SELECT claim_type, claim_status, COUNT(*)
                  FROM venus.v_brand_claim_status
                 GROUP BY claim_type, claim_status
                 ORDER BY claim_type, claim_status
            """,
            "flags_without_evidence": """
                SELECT COUNT(*)
                  FROM venus.brands b
                 WHERE (b.has_vegan_claim IS TRUE AND NOT EXISTS (
                           SELECT 1 FROM venus.brand_claim_evidence e
                            WHERE e.fk_brand_id = b.brand_id
                              AND e.claim_type = 'vegan'
                              AND e.claim_value IS TRUE
                              AND e.evidence_level IN ('high', 'medium')
                       ))
                    OR (b.has_cruelty_free_claim IS TRUE AND NOT EXISTS (
                           SELECT 1 FROM venus.brand_claim_evidence e
                            WHERE e.fk_brand_id = b.brand_id
                              AND e.claim_type = 'cruelty_free'
                              AND e.claim_value IS TRUE
                              AND e.evidence_level IN ('high', 'medium')
                       ))
            """,
        }

        for name, query in checks.items():
            with conn.cursor() as cur:
                cur.execute(query)
                print(name, cur.fetchall(), flush=True)


if __name__ == "__main__":
    main()
