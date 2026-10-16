"""Exporta e carrega avaliações oficiais de risco dos ingredientes.

O banco não possui uma tabela oficial que entregue, sozinha, os quatro
scores Venus de 0 a 10. Este utilitário, portanto, separa três passos:

1. exportar as pendências atuais;
2. validar uma planilha/CSV de evidências específicas por eixo;
3. aplicar somente registros com fonte, localizador e justificativa.

O comando ``apply`` é deliberadamente conservador: sem quatro linhas válidas
por ingrediente, nada daquele ingrediente é gravado. Ausência de evidência
não vira score 0, nem é inferida a partir de função, origem natural,
aprovação regulatória ou marketing.

Uso:

    python ops/load_official_ingredient_risk_v2.py export
    python ops/load_official_ingredient_risk_v2.py validate --input arquivo.csv
    python ops/load_official_ingredient_risk_v2.py apply --input arquivo.csv

O ``apply`` exige Venus-qa por padrão. Para outro banco, informe
``--database-name`` e ``--allow-database`` explicitamente.
"""

from __future__ import annotations

import argparse
import csv
import os
import sys
from collections import defaultdict
from dataclasses import dataclass
from pathlib import Path
from urllib.parse import urlparse

import psycopg
from dotenv import load_dotenv


ROOT = Path(__file__).resolve().parents[1]
load_dotenv(ROOT / ".env")

METHODOLOGY_VERSION = "v2"
ASSESSMENT_SCOPE = "ingredient_baseline_official_v2"
DIMENSIONS = (
    "irritation_risk_level",
    "comedogenicity_score",
    "biodegradability_level",
    "environmental_risk_level",
)

CSV_FIELDS = (
    "ingredient_id",
    "inci_name",
    "dimension",
    "score",
    "evidence_basis",
    "source_type",
    "source_url",
    "evidence_locator",
    "evidence_level",
    "evidence_excerpt",
    "rationale",
    "zero_basis",
    "assessment_scope",
    "methodology_version",
    "retrieved_at",
)

# Fontes de identidade/nomenclatura não são aceitas como prova de risco por
# si só. Elas aparecem no template para orientar a resolução do INCI.
OFFICIAL_SOURCE_HINTS = {
    "identity": (
        "https://www.gov.br/anvisa/pt-br/assuntos/cosmeticos/traducao",
        "https://single-market-economy.ec.europa.eu/sectors/cosmetics/cosmetic-ingredient-database_en",
    ),
    "irritation_risk_level": (
        "https://health.ec.europa.eu/scientific-committees/scientific-committee-consumer-safety-sccs/sccs-opinions_en",
        "https://single-market-economy.ec.europa.eu/sectors/cosmetics/cosmetic-products-specific-topics/cmr-substances_en",
        "https://www.gov.br/anvisa/pt-br/acessoainformacao/perguntasfrequentes/cosmeticos/rdc-no-646-2022",
    ),
    "comedogenicity_score": (
        "https://pubmed.ncbi.nlm.nih.gov/",
        "https://doi.org/",
    ),
    "biodegradability_level": (
        "https://echa.europa.eu/information-on-chemicals",
        "https://echa.europa.eu/documents/10162/17234/factsheet_databases_en.pdf",
    ),
    "environmental_risk_level": (
        "https://echa.europa.eu/information-on-chemicals",
        "https://single-market-economy.ec.europa.eu/sectors/cosmetics/cosmetic-products-specific-topics/cmr-substances_en",
    ),
}

ALLOWED_HOST_SUFFIXES = (
    "gov.br",
    "anvisa.gov.br",
    "ec.europa.eu",
    "europa.eu",
    "echa.europa.eu",
    "pubmed.ncbi.nlm.nih.gov",
    "doi.org",
)

VALID_EVIDENCE_LEVELS = {"medium", "high", "very_high"}
EVIDENCE_RANK = {"low": 1, "medium": 2, "high": 3, "very_high": 4}
VALID_BASES = {
    "irritation_risk_level": {
        "sccs_conclusion",
        "clinical_or_patch_test",
        "sensitisation_data",
        "regulatory_safety_conclusion",
    },
    "comedogenicity_score": {
        "direct_comedogenicity_study",
        "follicular_occlusion_study",
        "peer_reviewed_direct_evidence",
    },
    "biodegradability_level": {
        "oecd_biodegradation",
        "echa_reach_fate",
        "persistence_data",
        "authoritative_environmental_conclusion",
    },
    "environmental_risk_level": {
        "echa_aquatic_toxicity",
        "echa_pbt_vpvb",
        "clp_environmental_hazard",
        "authoritative_ecotoxicity",
    },
}


@dataclass(frozen=True)
class EvidenceRow:
    ingredient_id: int
    inci_name: str
    dimension: str
    score: int
    evidence_basis: str
    source_type: str
    source_url: str
    evidence_locator: str
    evidence_level: str
    evidence_excerpt: str
    rationale: str
    zero_basis: str
    assessment_scope: str
    methodology_version: str
    retrieved_at: str

    @property
    def source_reference(self) -> str:
        parts = [self.source_url]
        if self.evidence_locator:
            parts.append(f"locator={self.evidence_locator}")
        if self.retrieved_at:
            parts.append(f"retrieved_at={self.retrieved_at}")
        return " | ".join(parts)


def _clean(value: str | None) -> str:
    return " ".join((value or "").strip().split())


def _official_host(url: str) -> bool:
    host = (urlparse(url).hostname or "").lower().rstrip(".")
    return any(host == suffix or host.endswith("." + suffix) for suffix in ALLOWED_HOST_SUFFIXES)


def _parse_row(raw: dict[str, str], line_number: int) -> EvidenceRow:
    missing = [field for field in CSV_FIELDS if field not in raw]
    if missing:
        raise ValueError(f"linha {line_number}: colunas ausentes: {', '.join(missing)}")

    try:
        ingredient_id = int(_clean(raw["ingredient_id"]))
        score = int(_clean(raw["score"]))
    except ValueError as exc:
        raise ValueError(f"linha {line_number}: ingredient_id/score devem ser inteiros") from exc

    row = EvidenceRow(
        ingredient_id=ingredient_id,
        inci_name=_clean(raw["inci_name"]),
        dimension=_clean(raw["dimension"]),
        score=score,
        evidence_basis=_clean(raw["evidence_basis"]),
        source_type=_clean(raw["source_type"]),
        source_url=_clean(raw["source_url"]),
        evidence_locator=_clean(raw["evidence_locator"]),
        evidence_level=_clean(raw["evidence_level"]).lower(),
        evidence_excerpt=_clean(raw["evidence_excerpt"]),
        rationale=_clean(raw["rationale"]),
        zero_basis=_clean(raw["zero_basis"]),
        assessment_scope=_clean(raw["assessment_scope"]),
        methodology_version=_clean(raw["methodology_version"]),
        retrieved_at=_clean(raw["retrieved_at"]),
    )
    validate_row(row, line_number)
    return row


def validate_row(row: EvidenceRow, line_number: int = 0) -> None:
    prefix = f"linha {line_number}: " if line_number else ""
    if row.ingredient_id <= 0:
        raise ValueError(f"{prefix}ingredient_id inválido")
    if not row.inci_name:
        raise ValueError(f"{prefix}inci_name vazio")
    if row.dimension not in DIMENSIONS:
        raise ValueError(f"{prefix}dimension inválida: {row.dimension}")
    if not 0 <= row.score <= 10:
        raise ValueError(f"{prefix}score fora de 0..10")
    if row.evidence_basis not in VALID_BASES[row.dimension]:
        allowed = ", ".join(sorted(VALID_BASES[row.dimension]))
        raise ValueError(f"{prefix}evidence_basis inválido para {row.dimension}; use: {allowed}")
    if not row.source_type:
        raise ValueError(f"{prefix}source_type vazio")
    parsed = urlparse(row.source_url)
    if parsed.scheme != "https" or not parsed.netloc or not _official_host(row.source_url):
        raise ValueError(
            f"{prefix}source_url deve ser HTTPS de fonte oficial/ECHA/SCCS/ANVISA "
            f"ou evidência indexada em PubMed/DOI"
        )
    if not row.evidence_locator:
        raise ValueError(f"{prefix}evidence_locator é obrigatório; home page não basta")
    if row.evidence_level not in VALID_EVIDENCE_LEVELS:
        raise ValueError(f"{prefix}evidence_level deve ser medium, high ou very_high")
    if len(row.evidence_excerpt) < 20:
        raise ValueError(f"{prefix}evidence_excerpt deve registrar a conclusão relevante")
    if len(row.rationale) < 40:
        raise ValueError(f"{prefix}rationale deve explicar o mapeamento para 0..10")
    if row.score == 0 and not row.zero_basis:
        raise ValueError(f"{prefix}zero_basis é obrigatório quando score=0")
    if row.assessment_scope != ASSESSMENT_SCOPE:
        raise ValueError(f"{prefix}assessment_scope deve ser {ASSESSMENT_SCOPE}")
    if row.methodology_version != METHODOLOGY_VERSION:
        raise ValueError(f"{prefix}methodology_version deve ser {METHODOLOGY_VERSION}")


def _connect(application_name: str):
    url = os.environ.get("DATABASE_URL")
    if not url:
        raise RuntimeError("DATABASE_URL não encontrada no .env")
    return psycopg.connect(url, connect_timeout=15, application_name=application_name)


def _assert_database(conn, expected: str, allow_database: bool) -> None:
    with conn.cursor() as cur:
        cur.execute("SELECT current_database(), current_user")
        database, user = cur.fetchone()
    if database != expected and not allow_database:
        raise RuntimeError(
            f"banco conectado é {database!r}, mas o esperado é {expected!r}. "
            "Use --allow-database somente depois de conferir o alvo."
        )
    print(f"banco={database} usuário={user}")


def _pending_query() -> str:
    return """
        WITH required(dimension) AS (
            VALUES
                ('irritation_risk_level'),
                ('comedogenicity_score'),
                ('biodegradability_level'),
                ('environmental_risk_level')
        )
        SELECT i.ingredient_id, i.inci_name
          FROM venus.ingredients i
         WHERE EXISTS (
                   SELECT 1
                     FROM required r
                    WHERE NOT EXISTS (
                              SELECT 1
                                FROM venus.ingredient_risk_assessments ira
                               WHERE ira.fk_ingredient_id = i.ingredient_id
                                 AND ira.dimension = r.dimension
                                 AND ira.assessment_version = 'v2'
                                 AND ira.assessment_status = 'approved'
                                 AND NULLIF(BTRIM(ira.source_reference), '') IS NOT NULL
                          )
               )
         ORDER BY i.ingredient_id
    """


def export_template(path: Path, database_name: str, allow_database: bool) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with _connect("venus-official-risk-export") as conn:
        _assert_database(conn, database_name, allow_database)
        with conn.cursor() as cur:
            cur.execute(_pending_query())
            ingredients = cur.fetchall()

    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=CSV_FIELDS)
        writer.writeheader()
        for ingredient_id, inci_name in ingredients:
            for dimension in DIMENSIONS:
                writer.writerow(
                    {
                        "ingredient_id": ingredient_id,
                        "inci_name": inci_name,
                        "dimension": dimension,
                        "score": "",
                        "evidence_basis": "",
                        "source_type": "",
                        "source_url": "",
                        "evidence_locator": "",
                        "evidence_level": "",
                        "evidence_excerpt": "",
                        "rationale": "",
                        "zero_basis": "",
                        "assessment_scope": ASSESSMENT_SCOPE,
                        "methodology_version": METHODOLOGY_VERSION,
                        "retrieved_at": "",
                    }
                )

    print(f"pendências exportadas: {len(ingredients)} ingredientes / {len(ingredients) * 4} linhas")
    print(f"arquivo: {path}")
    print("fontes de identidade: Anvisa INCI + CosIng")
    print("fontes de risco: SCCS/Comissão Europeia, ECHA/CLP/REACH e estudos diretos para comedogenicidade")


def read_rows(path: Path) -> list[EvidenceRow]:
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        reader = csv.DictReader(handle)
        if reader.fieldnames is None:
            raise ValueError("arquivo sem cabeçalho")
        rows = []
        for line_number, raw in enumerate(reader, start=2):
            if not any(_clean(value) for value in raw.values()):
                continue
            rows.append(_parse_row(raw, line_number))
    if not rows:
        raise ValueError("nenhuma linha de evidência encontrada")
    return rows


def validate_file(path: Path) -> list[EvidenceRow]:
    rows = read_rows(path)
    grouped: dict[int, dict[str, EvidenceRow]] = defaultdict(dict)
    for row in rows:
        previous = grouped[row.ingredient_id].get(row.dimension)
        if previous:
            raise ValueError(
                f"ingredient_id={row.ingredient_id} possui mais de uma linha para {row.dimension}"
            )
        grouped[row.ingredient_id][row.dimension] = row

    incomplete = {
        ingredient_id: sorted(set(DIMENSIONS) - set(dimensions))
        for ingredient_id, dimensions in grouped.items()
        if set(dimensions) != set(DIMENSIONS)
    }
    if incomplete:
        examples = "; ".join(
            f"{ingredient_id}: {', '.join(missing)}"
            for ingredient_id, missing in list(incomplete.items())[:5]
        )
        raise ValueError(
            "cada ingrediente precisa de quatro avaliações v2; pendências: " + examples
        )

    print(f"arquivo válido: {len(grouped)} ingredientes / {len(rows)} avaliações")
    return rows


def _lookup_ingredients(conn, ingredient_ids: list[int]) -> dict[int, str]:
    with conn.cursor() as cur:
        cur.execute(
            """
            SELECT ingredient_id, inci_name
              FROM venus.ingredients
             WHERE ingredient_id = ANY(%s)
            """,
            (ingredient_ids,),
        )
        return {ingredient_id: inci_name for ingredient_id, inci_name in cur.fetchall()}


def _assert_no_evidence_downgrade(conn, rows: list[EvidenceRow]) -> None:
    ingredient_ids = sorted({row.ingredient_id for row in rows})
    with conn.cursor() as cur:
        cur.execute(
            """
            SELECT fk_ingredient_id, dimension, evidence_level::text
              FROM venus.ingredient_risk_assessments
             WHERE assessment_version = 'v2'
               AND assessment_status = 'approved'
               AND fk_ingredient_id = ANY(%s)
            """,
            (ingredient_ids,),
        )
        current = {
            (ingredient_id, dimension): evidence_level
            for ingredient_id, dimension, evidence_level in cur.fetchall()
        }

    downgrades = []
    for row in rows:
        existing = current.get((row.ingredient_id, row.dimension))
        if existing and EVIDENCE_RANK[row.evidence_level] < EVIDENCE_RANK[existing]:
            downgrades.append(
                f"{row.ingredient_id}/{row.dimension}: {existing} -> {row.evidence_level}"
            )
    if downgrades:
        raise RuntimeError(
            "o arquivo tentaria substituir evidência mais forte por mais fraca: "
            + "; ".join(downgrades[:10])
        )


def apply_file(path: Path, database_name: str, allow_database: bool) -> None:
    rows = validate_file(path)
    grouped: dict[int, list[EvidenceRow]] = defaultdict(list)
    for row in rows:
        grouped[row.ingredient_id].append(row)

    with _connect("venus-official-risk-import") as conn:
        _assert_database(conn, database_name, allow_database)
        database_ingredients = _lookup_ingredients(conn, sorted(grouped))
        missing = sorted(set(grouped) - set(database_ingredients))
        if missing:
            raise RuntimeError(f"ingredient_id inexistente no banco: {missing[:20]}")

        mismatches = []
        for ingredient_id, evidence_rows in grouped.items():
            expected = " ".join(database_ingredients[ingredient_id].upper().split())
            received = " ".join(evidence_rows[0].inci_name.upper().split())
            if expected != received:
                mismatches.append(
                    f"{ingredient_id}: banco={database_ingredients[ingredient_id]!r}, "
                    f"arquivo={evidence_rows[0].inci_name!r}"
                )
        if mismatches:
            raise RuntimeError("INCI divergente: " + "; ".join(mismatches[:10]))

        _assert_no_evidence_downgrade(conn, rows)

        with conn.cursor() as cur:
            cur.execute("SET LOCAL lock_timeout = '10s'")
            cur.execute("SET LOCAL statement_timeout = '600s'")
            cur.execute("SET LOCAL search_path TO venus, public")
            cur.execute("SELECT set_config('venus.allow_risk_sync', 'on', TRUE)")

            for ingredient_id, evidence_rows in grouped.items():
                for row in evidence_rows:
                    cur.execute(
                        """
                        INSERT INTO venus.ingredient_risk_assessments (
                            fk_ingredient_id, dimension, score, assessment_status,
                            source_type, source_reference, assessment_version,
                            evidence_level, rationale, assessment_scope,
                            assessed_at, updated_at
                        ) VALUES (
                            %s, %s, %s, 'approved', %s, %s, %s,
                            %s::venus.evidence_level_enum, %s, %s,
                            NOW(), NOW()
                        )
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
                        """,
                        (
                            row.ingredient_id,
                            row.dimension,
                            row.score,
                            row.source_type,
                            row.source_reference,
                            row.methodology_version,
                            row.evidence_level,
                            (
                                f"{row.rationale} Evidence registrada: "
                                f"{row.evidence_excerpt}"
                            ),
                            row.assessment_scope,
                        ),
                    )

                score_by_dimension = {row.dimension: row.score for row in evidence_rows}
                cur.execute(
                    """
                    UPDATE venus.ingredients
                       SET irritation_risk_level = %s,
                           comedogenicity_score = %s,
                           biodegradability_level = %s,
                           environmental_risk_level = %s,
                           updated_at = NOW()
                     WHERE ingredient_id = %s
                    """,
                    (
                        score_by_dimension["irritation_risk_level"],
                        score_by_dimension["comedogenicity_score"],
                        score_by_dimension["biodegradability_level"],
                        score_by_dimension["environmental_risk_level"],
                        ingredient_id,
                    ),
                )

            cur.execute(
                """
                SELECT COUNT(*)
                  FROM venus.ingredients i
                 WHERE EXISTS (
                     SELECT 1
                       FROM (VALUES
                           ('irritation_risk_level'),
                           ('comedogenicity_score'),
                           ('biodegradability_level'),
                           ('environmental_risk_level')
                       ) AS required(dimension)
                      WHERE NOT EXISTS (
                          SELECT 1
                            FROM venus.ingredient_risk_assessments ira
                           WHERE ira.fk_ingredient_id = i.ingredient_id
                             AND ira.dimension = required.dimension
                             AND ira.assessment_version = 'v2'
                             AND ira.assessment_status = 'approved'
                             AND NULLIF(BTRIM(ira.source_reference), '') IS NOT NULL
                      )
                 )
                """
            )
            remaining = cur.fetchone()[0]
        conn.commit()

    print(f"aplicado: {len(grouped)} ingredientes / {len(rows)} avaliações")
    print(f"ingredientes ainda sem os quatro eixos oficiais: {remaining}")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--database-name", default="Venus-qa")
    parser.add_argument("--allow-database", action="store_true")
    subparsers = parser.add_subparsers(dest="command", required=True)

    export = subparsers.add_parser("export", help="exporta as pendências atuais")
    export.add_argument(
        "--output",
        type=Path,
        default=ROOT / "data" / "official_risk_evidence_v2_template.csv",
    )

    for name in ("validate", "apply"):
        command = subparsers.add_parser(name, help=f"{name} um CSV de evidências")
        command.add_argument("--input", type=Path, required=True)
    return parser


def main() -> int:
    args = build_parser().parse_args()
    try:
        if args.command == "export":
            export_template(args.output, args.database_name, args.allow_database)
        elif args.command == "validate":
            validate_file(args.input)
        else:
            apply_file(args.input, args.database_name, args.allow_database)
    except (OSError, ValueError, RuntimeError, psycopg.Error) as exc:
        print(f"ERRO: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
