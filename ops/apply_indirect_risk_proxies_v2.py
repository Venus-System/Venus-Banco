"""Preenche as avaliações faltantes com proxies indiretas v2/low.

Esta é uma carga explicitamente inferior a uma avaliação científica direta.
Ela usa a view determinística ``venus.v_ingredient_risk_inference_v2`` já
versionada no banco, preserva qualquer avaliação medium/high/very_high e marca
as quatro dimensões como ``ingredient_baseline_indirect_v2``.

O script não chama a Venus-Classificacao e só aceita Venus-qa por padrão.
"""

from __future__ import annotations

import argparse
import os
from pathlib import Path

import psycopg
from dotenv import load_dotenv


ROOT = Path(__file__).resolve().parents[1]
load_dotenv(ROOT / ".env")


def connect():
    url = os.environ.get("DATABASE_URL")
    if not url:
        raise RuntimeError("DATABASE_URL não encontrada no .env")
    return psycopg.connect(
        url,
        connect_timeout=15,
        application_name="venus-apply-indirect-risk-proxies-v2",
    )


def assert_database(conn, expected: str, allow_database: bool) -> None:
    with conn.cursor() as cur:
        cur.execute("SELECT current_database(), current_user")
        database, user = cur.fetchone()
    if database != expected and not allow_database:
        raise RuntimeError(
            f"banco conectado é {database!r}, esperado {expected!r}; "
            "use --allow-database somente após conferir o alvo"
        )
    print(f"banco={database} usuário={user}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--database-name", default="Venus-qa")
    parser.add_argument("--allow-database", action="store_true")
    args = parser.parse_args()

    with connect() as conn:
        assert_database(conn, args.database_name, args.allow_database)
        with conn.cursor() as cur:
            cur.execute("SET LOCAL lock_timeout = '10s'")
            cur.execute("SET LOCAL statement_timeout = '600s'")
            cur.execute("SET LOCAL search_path TO venus, public")
            cur.execute("SELECT set_config('venus.allow_risk_sync', 'on', TRUE)")

            cur.execute(
                """
                SELECT COUNT(*)
                  FROM venus.ingredients i
                 WHERE NOT venus.fn_has_complete_ingredient_assessment(i.ingredient_id)
                """
            )
            pending_before = cur.fetchone()[0]

            # A carga por dimensão permite completar um ingrediente que tenha
            # uma evidência forte em um eixo. O ON CONFLICT só substitui uma
            # avaliação já marcada como low/indireta; medium+ jamais é perdido.
            cur.execute(
                """
                WITH pending AS (
                    SELECT v.*
                      FROM venus.v_ingredient_risk_inference_v2 v
                     WHERE NOT venus.fn_has_complete_ingredient_assessment(v.ingredient_id)
                ), rows_to_load AS (
                    SELECT ingredient_id, 'irritation_risk_level'::TEXT AS dimension,
                           irritation_score AS score, source_reference,
                           irritation_rationale AS rationale
                      FROM pending
                    UNION ALL
                    SELECT ingredient_id, 'comedogenicity_score', comedogenicity_score,
                           source_reference, comedogenicity_rationale
                      FROM pending
                    UNION ALL
                    SELECT ingredient_id, 'biodegradability_level', biodegradability_score,
                           source_reference, biodegradability_rationale
                      FROM pending
                    UNION ALL
                    SELECT ingredient_id, 'environmental_risk_level', environmental_score,
                           source_reference, environmental_rationale
                      FROM pending
                )
                INSERT INTO venus.ingredient_risk_assessments (
                    fk_ingredient_id, dimension, score, assessment_status,
                    source_type, source_reference, assessment_version,
                    evidence_level, rationale, assessment_scope,
                    assessed_at, updated_at
                )
                SELECT ingredient_id, dimension, score, 'approved', 'system',
                       source_reference, 'v2', 'low', rationale,
                       'ingredient_baseline_indirect_v2', NOW(), NOW()
                  FROM rows_to_load
                ON CONFLICT (fk_ingredient_id, dimension, assessment_version)
                DO UPDATE SET
                    score = EXCLUDED.score,
                    assessment_status = 'approved',
                    source_type = EXCLUDED.source_type,
                    source_reference = EXCLUDED.source_reference,
                    evidence_level = EXCLUDED.evidence_level,
                    rationale = EXCLUDED.rationale,
                    assessment_scope = EXCLUDED.assessment_scope,
                    assessed_at = NOW(),
                    updated_at = NOW()
                WHERE venus.ingredient_risk_assessments.evidence_level = 'low'
                  AND venus.ingredient_risk_assessments.assessment_scope LIKE
                      'ingredient_baseline_indirect%'
                """
            )

            # Sincroniza os campos legados com o assessment de maior evidência
            # disponível em cada eixo. A tabela de assessments continua sendo a
            # fonte auditável; estes campos são apenas o contrato legado da API.
            cur.execute(
                """
                WITH ranked AS (
                    SELECT DISTINCT ON (fk_ingredient_id, dimension)
                           fk_ingredient_id, dimension, score
                      FROM venus.ingredient_risk_assessments
                     WHERE assessment_version = 'v2'
                       AND assessment_status = 'approved'
                       AND NULLIF(BTRIM(source_reference), '') IS NOT NULL
                     ORDER BY fk_ingredient_id, dimension,
                              CASE evidence_level
                                  WHEN 'very_high' THEN 4
                                  WHEN 'high' THEN 3
                                  WHEN 'medium' THEN 2
                                  ELSE 1
                              END DESC,
                              updated_at DESC
                ), pivot AS (
                    SELECT fk_ingredient_id,
                           MAX(score) FILTER (WHERE dimension = 'irritation_risk_level') AS irritation,
                           MAX(score) FILTER (WHERE dimension = 'comedogenicity_score') AS comedogenicity,
                           MAX(score) FILTER (WHERE dimension = 'biodegradability_level') AS biodegradability,
                           MAX(score) FILTER (WHERE dimension = 'environmental_risk_level') AS environmental
                      FROM ranked
                     GROUP BY fk_ingredient_id
                )
                UPDATE venus.ingredients i
                   SET irritation_risk_level = p.irritation,
                       comedogenicity_score = p.comedogenicity,
                       biodegradability_level = p.biodegradability,
                       environmental_risk_level = p.environmental,
                       updated_at = NOW()
                  FROM pivot p
                 WHERE i.ingredient_id = p.fk_ingredient_id
                   AND p.irritation IS NOT NULL
                   AND p.comedogenicity IS NOT NULL
                   AND p.biodegradability IS NOT NULL
                   AND p.environmental IS NOT NULL
                """
            )

            cur.execute(
                """
                SELECT COUNT(*)
                  FROM venus.ingredients i
                 WHERE NOT venus.fn_has_complete_ingredient_assessment(i.ingredient_id)
                """
            )
            pending_after = cur.fetchone()[0]

            cur.execute(
                """
                SELECT assessment_version, evidence_level::TEXT,
                       assessment_scope, assessment_status, COUNT(*)
                  FROM venus.ingredient_risk_assessments
                 GROUP BY 1, 2, 3, 4
                 ORDER BY 1, 2, 3, 4
                """
            )
            assessment_summary = cur.fetchall()

            cur.execute(
                """
                SELECT COUNT(*) FILTER (
                           WHERE evaluation_state = 'assessed_indirect_v2'
                       ),
                       COUNT(*) FILTER (WHERE is_really_evaluated),
                       COUNT(*)
                  FROM venus.v_ingredient_evaluation_status
                """
            )
            evaluation_summary = cur.fetchone()

        conn.commit()

    print(f"pendentes antes: {pending_before}")
    print(f"pendentes depois: {pending_after}")
    print(f"avaliacao indireta v2: {evaluation_summary[0]}")
    print(f"ingredientes com quatro dimensoes: {evaluation_summary[1]}/{evaluation_summary[2]}")
    print("assessments:")
    for row in assessment_summary:
        print(row)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
