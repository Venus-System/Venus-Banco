from __future__ import annotations

import os
from pathlib import Path

import psycopg
from dotenv import load_dotenv


ROOT = Path(__file__).resolve().parents[1]
MIGRATION = ROOT / "sql" / "migrations" / "20261012_001_score_readiness_policies.sql"


def main() -> None:
    load_dotenv(ROOT / ".env")

    with psycopg.connect(
        os.environ["DATABASE_URL"],
        connect_timeout=15,
        application_name="venus-migration-20261012-001",
    ) as conn:
        conn.execute(MIGRATION.read_text(encoding="utf-8"))
        conn.commit()

        checks = {
            "scores_remaining": """
                SELECT COUNT(*)
                  FROM venus.product_scores
            """,
            "all_ingredients_zero_confidence": """
                SELECT COUNT(*)
                  FROM venus.ingredients
                 WHERE scientific_confidence <= 1
                   AND scientific_confidence_state <> 'default'
            """,
            "zero_dimensions_still_evaluated": """
                SELECT COUNT(*)
                  FROM venus.ingredients
                 WHERE scientific_confidence > 0
                   AND irritation_risk_level = 0
                   AND comedogenicity_score = 0
                   AND biodegradability_level = 0
                   AND environmental_risk_level = 0
            """,
            "used_ingredients_confidence_one": """
                SELECT COUNT(*)
                  FROM venus.ingredients i
                 WHERE i.scientific_confidence <= 1
                   AND EXISTS (
                       SELECT 1
                         FROM venus.product_ingredients pi
                        WHERE pi.fk_ingredient_id = i.ingredient_id
                   )
            """,
            "pending_benefits": """
                SELECT COUNT(*)
                  FROM venus.ingredient_effects
                 WHERE effect_category = 'benefit'
                   AND review_status <> 'validated'
            """,
            "validated_benefits": """
                SELECT COUNT(*)
                  FROM venus.ingredient_effects
                 WHERE effect_category = 'benefit'
                   AND review_status = 'validated'
            """,
            "packaging_evaluated": """
                SELECT COUNT(*)
                  FROM venus.packaging
                 WHERE confidence_score > 0
            """,
            "ethical_evidence": """
                SELECT COUNT(*)
                  FROM venus.brand_claim_evidence
                 WHERE claim_value
            """,
            "ethical_brands": """
                SELECT COUNT(*)
                  FROM venus.brands
                 WHERE has_vegan_claim OR has_cruelty_free_claim
            """,
            "methodology_versions": """
                SELECT methodology_version, status
                  FROM venus.ingredient_risk_methodologies
                 ORDER BY methodology_version
            """,
        }

        for name, query in checks.items():
            with conn.cursor() as cur:
                cur.execute(query)
                print(name, cur.fetchall(), flush=True)


if __name__ == "__main__":
    main()
