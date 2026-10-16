from __future__ import annotations

import os
from pathlib import Path

import psycopg
from dotenv import load_dotenv


ROOT = Path(__file__).resolve().parents[1]
load_dotenv(ROOT / ".env")


def main() -> None:
    with psycopg.connect(
        os.environ["DATABASE_URL"],
        connect_timeout=15,
        application_name="venus-evidence-audit",
    ) as conn:
        with conn.cursor() as cur:
            queries = {
                "used_ingredients": """
                    SELECT COUNT(DISTINCT pi.fk_ingredient_id)
                      FROM venus.product_versions pv
                      JOIN venus.product_ingredients pi
                        ON pi.fk_product_version_id = pv.product_version_id
                     WHERE pv.is_current
                """,
                "evidence_coverage": """
                    SELECT COUNT(DISTINCT i.ingredient_id) AS used,
                           COUNT(DISTINCT i.ingredient_id) FILTER (WHERE ip.ingredient_id IS NOT NULL) AS with_properties,
                           COUNT(DISTINCT i.ingredient_id) FILTER (WHERE ir.ingredient_id IS NOT NULL) AS with_regulations,
                           COUNT(DISTINCT i.ingredient_id) FILTER (WHERE ie.ingredient_id IS NOT NULL) AS with_effects
                      FROM venus.ingredients i
                      JOIN venus.product_ingredients pi ON pi.fk_ingredient_id = i.ingredient_id
                      JOIN venus.product_versions pv ON pv.product_version_id = pi.fk_product_version_id
                      LEFT JOIN (
                          SELECT DISTINCT fk_ingredient_id AS ingredient_id
                            FROM venus.ingredient_properties
                      ) ip ON ip.ingredient_id = i.ingredient_id
                      LEFT JOIN (
                          SELECT DISTINCT fk_ingredient_id AS ingredient_id
                            FROM venus.ingredient_regulations
                      ) ir ON ir.ingredient_id = i.ingredient_id
                      LEFT JOIN (
                          SELECT DISTINCT fk_ingredient_id AS ingredient_id
                            FROM venus.ingredient_effects
                      ) ie ON ie.ingredient_id = i.ingredient_id
                     WHERE pv.is_current
                """,
                "property_names": """
                    SELECT property_name, COUNT(*)
                      FROM venus.ingredient_properties
                     GROUP BY property_name
                     ORDER BY COUNT(*) DESC, property_name
                """,
                "regulation_sources": """
                    SELECT COALESCE(ir.source_type::text, '<null>'),
                           COALESCE(ir.restriction_type::text, '<null>'),
                           COUNT(*)
                      FROM venus.ingredient_regulations ir
                     GROUP BY 1, 2
                     ORDER BY 1, 2
                """,
                "risk_fields": """
                    SELECT COUNT(*) AS total,
                           COUNT(*) FILTER (WHERE irritation_risk_level <> 0) AS irritation_nonzero,
                           COUNT(*) FILTER (WHERE comedogenicity_score <> 0) AS comedogenic_nonzero,
                           COUNT(*) FILTER (WHERE biodegradability_level <> 0) AS biodeg_nonzero,
                           COUNT(*) FILTER (WHERE environmental_risk_level <> 0) AS environmental_nonzero
                      FROM venus.ingredients
                """,
                "examples": """
                    SELECT i.ingredient_id,
                           i.inci_name,
                           i.source_type,
                           i.source_reference,
                           COUNT(DISTINCT ip.ingredient_property_id) AS properties,
                           COUNT(DISTINCT ir.ingredient_regulation_id) AS regulations,
                           COUNT(DISTINCT ie.ingredient_effect_id) AS effects
                      FROM venus.ingredients i
                      JOIN venus.product_ingredients pi ON pi.fk_ingredient_id = i.ingredient_id
                      JOIN venus.product_versions pv ON pv.product_version_id = pi.fk_product_version_id
                      LEFT JOIN venus.ingredient_properties ip ON ip.fk_ingredient_id = i.ingredient_id
                      LEFT JOIN venus.ingredient_regulations ir ON ir.fk_ingredient_id = i.ingredient_id
                      LEFT JOIN venus.ingredient_effects ie ON ie.fk_ingredient_id = i.ingredient_id
                     WHERE pv.is_current
                     GROUP BY i.ingredient_id, i.inci_name, i.source_type, i.source_reference
                     ORDER BY regulations DESC, properties DESC, i.ingredient_id
                     LIMIT 30
                """,
                "effect_catalog": """
                    SELECT ie.effect_category::text,
                           ie.effect_strength::text,
                           COUNT(*)
                      FROM venus.ingredient_effects ie
                     GROUP BY 1, 2
                     ORDER BY 1, 2
                """,
                "effect_examples": """
                    SELECT i.inci_name,
                           ie.effect_name,
                           ie.effect_category::text,
                           ie.evidence_level::text,
                           ie.source_type::text,
                           ie.source_reference
                      FROM venus.ingredient_effects ie
                      JOIN venus.ingredients i ON i.ingredient_id = ie.fk_ingredient_id
                     ORDER BY ie.evidence_level DESC, i.inci_name
                     LIMIT 50
                """,
                "target_effects": """
                    SELECT i.inci_name,
                           ie.effect_name,
                           ie.effect_category::text,
                           ie.effect_strength::text,
                           ie.evidence_level::text,
                           ie.source_reference
                      FROM venus.ingredient_effects ie
                      JOIN venus.ingredients i ON i.ingredient_id = ie.fk_ingredient_id
                     WHERE ie.effect_name ILIKE '%irrit%'
                        OR ie.effect_name ILIKE '%comed%'
                        OR ie.effect_name ILIKE '%environment%'
                        OR ie.effect_name ILIKE '%biodegrad%'
                        OR ie.effect_name ILIKE '%acne%'
                     ORDER BY i.inci_name
                """,
                "methodology_coverage": """
                    SELECT COUNT(*) AS used_ingredients,
                           COUNT(*) FILTER (WHERE has_four_approved_dimensions) AS ready_ingredients,
                           COUNT(*) FILTER (WHERE approved_dimensions BETWEEN 1 AND 3) AS partial_ingredients
                      FROM venus.v_ingredient_risk_coverage
                """,
            }
            for name, query in queries.items():
                cur.execute(query)
                print(name, cur.fetchall())


if __name__ == "__main__":
    main()
