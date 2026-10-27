from __future__ import annotations

import os
from pathlib import Path
from urllib.parse import urlsplit, urlunsplit

import psycopg
from dotenv import load_dotenv


ROOT = Path(__file__).resolve().parents[1]
MIGRATION = ROOT / "sql" / "migrations" / "20261010_003_fragrance_category_reclassification.sql"
PRIMARY = [
    "ALPHA-ISOMETHYL IONONE",
    "AMYL CINNAMAL",
    "AMYLCINNAMYL ALCOHOL",
    "ANISE ALCOHOL",
    "BENZYL CINNAMATE",
    "BUTYLPHENYL METHYLPROPIONAL",
    "CINNAMAL",
    "CINNAMYL ALCOHOL",
    "CITRAL",
    "CITRONELLOL",
    "COUMARIN",
    "EUGENOL",
    "FARNESOL",
    "GERANIOL",
    "HEXYL CINNAMAL",
    "HYDROXYCITRONELLAL",
    "ISOEUGENOL",
    "METHYL 2-OCTYNOATE",
    "LAVANDULA HYBRIDA HERB OIL",
]
SECONDARY = [
    "BENZYL ALCOHOL",
    "BENZYL BENZOATE",
    "BENZYL SALICYLATE",
    "LIMONENE",
    "LINALOOL",
    "LAVANDULA ANGUSTIFOLIA HERB OIL",
    "CINNAMOMUM CASSIA OIL",
    "CINNAMOMUM ZEYLANICUM BARK OIL",
    "CINNAMOMUM ZEYLANICUM LEAF OIL",
    "CITRUS AURANTIUM BERGAMIA LEAF OIL",
    "CITRUS AURANTIUM BERGAMIA PEEL OIL",
    "CITRUS AURANTIUM DULCIS FLOWER OIL",
    "CITRUS AURANTIUM DULCIS PEEL OIL EXPRESSED",
    "CITRUS AURANTIUM LEAF OIL",
    "CITRUS AURANTIUM PEEL OIL EXPRESSED",
    "CITRUS BERGAMIA LEAF OIL",
    "CITRUS BERGAMIA PEEL OIL EXPRESSED",
    "CITRUS NOBILIS LEAF OIL",
    "CITRUS NOBILIS PEEL OIL EXPRESSED",
    "CITRUS PARADISI M. PEEL OIL EXPRESSED",
    "EUCALYPTUS GLOBULUS LEAF/TWIG OIL",
    "MENTHA ARVENSIS HERB OIL",
    "MENTHA ARVENSIS LEAF/STEM OIL",
    "MENTHA SPICATA HERB OIL",
    "PINUS PINASTER TWIG LEAF OIL",
    "PINUS SYLVESTRIS TWIG LEAF OIL",
    "ROSA GALLICA FLOWER OIL",
    "ROSMARINUS OFFICINALIS FLOWER OIL",
    "ROSMARINUS OFFICINALIS LEAF/STEM OIL",
    "ROSMARINUS OFFICINALIS STEM OIL",
    "SANTALUM ALBUM WOOD OIL",
    "THYMUS SERPILLUM OIL",
]


def database_urls() -> list[tuple[str, str]]:
    load_dotenv(ROOT / ".env")
    base = os.environ["DATABASE_URL"]
    parsed = urlsplit(base)
    return [
        ("Venus-qa", base),
        ("Venus-2ano", urlunsplit(parsed._replace(path="/Venus-2ano"))),
    ]


def placeholders(values: list[str]) -> tuple[str, list[str]]:
    return ", ".join(["%s"] * len(values)), values


def preflight(name: str, url: str) -> dict[str, object]:
    with psycopg.connect(
        url,
        connect_timeout=15,
        options="-c default_transaction_read_only=on",
        application_name="venus-fragrance-preflight",
    ) as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT current_database(), current_user,
                       (SELECT COUNT(*) FROM venus.ingredients),
                       (SELECT COUNT(*) FROM venus.ingredient_categories)
                """
            )
            database, user, ingredient_count, category_count = cur.fetchone()

            marks, params = placeholders(PRIMARY)
            cur.execute(
                f"""
                SELECT COUNT(*) FILTER (WHERE i.ingredient_id IS NOT NULL),
                       COUNT(*) FILTER (WHERE i.ingredient_id IS NOT NULL AND c.name = %s),
                       COALESCE(STRING_AGG(a.inci_name, ', ' ORDER BY a.inci_name)
                                FILTER (WHERE i.ingredient_id IS NULL), '')
                  FROM (VALUES {', '.join(['(%s)'] * len(PRIMARY))}) AS a(inci_name)
                  LEFT JOIN venus.ingredients i ON i.inci_name = a.inci_name
                  LEFT JOIN venus.ingredient_categories c
                    ON c.ingredient_category_id = i.fk_ingredient_category_id
                """,
                ["Não classificado", *PRIMARY],
            )
            primary_found, primary_unclassified, primary_missing = cur.fetchone()

            marks, params = placeholders(SECONDARY)
            cur.execute(
                f"SELECT COUNT(*) FROM venus.ingredients WHERE inci_name IN ({marks})",
                params,
            )
            secondary_found = cur.fetchone()[0]

            return {
                "name": name,
                "database": database,
                "user": user,
                "ingredients": ingredient_count,
                "categories": category_count,
                "primary_found": primary_found,
                "primary_unclassified": primary_unclassified,
                "primary_missing": primary_missing,
                "secondary_found": secondary_found,
            }


def validate(name: str, url: str) -> dict[str, object]:
    with psycopg.connect(
        url,
        connect_timeout=15,
        options="-c default_transaction_read_only=on",
        application_name="venus-fragrance-validation",
    ) as conn:
        with conn.cursor() as cur:
            marks, params = placeholders(PRIMARY)
            cur.execute(
                f"""
                SELECT COUNT(*) FILTER (WHERE c.name = %s),
                       COUNT(*) FILTER (WHERE c.name = %s),
                       COUNT(*) FILTER (WHERE c.name = %s),
                       COUNT(*) FILTER (WHERE i.source_reference = %s)
                  FROM venus.ingredients i
                  JOIN venus.ingredient_categories c
                    ON c.ingredient_category_id = i.fk_ingredient_category_id
                 WHERE i.inci_name IN ({marks})
                """,
                ["Agente Perfumante", "Não classificado", "Fragrância",
                 "migration:20261010_003_fragrance_category_reclassification", *PRIMARY],
            )
            primary_perfuming, primary_unclassified, primary_root, source_marked = cur.fetchone()

            cur.execute(
                """
                SELECT COUNT(*)
                  FROM venus.ingredient_category_assignments a
                  JOIN venus.ingredient_categories c
                    ON c.ingredient_category_id = a.fk_ingredient_category_id
                 WHERE c.name = 'Agente Perfumante'
                   AND a.source_reference = 'migration:20261010_003_fragrance_category_reclassification'
                """
            )
            secondary_links = cur.fetchone()[0]

            cur.execute(
                """
                SELECT COUNT(*)
                  FROM venus.v_ingredient_category_links
                 WHERE category_name IN ('Fragrância', 'Agente Perfumante')
                """
            )
            visible_links = cur.fetchone()[0]

            cur.execute(
                """
                SELECT child.parent_ingredient_category_id = parent.ingredient_category_id
                  FROM venus.ingredient_categories child
                  JOIN venus.ingredient_categories parent ON parent.name = 'Fragrância'
                 WHERE child.name = 'Agente Perfumante'
                """
            )
            parent_ok = cur.fetchone()[0]

            cur.execute(
                """
                SELECT COUNT(*)
                  FROM venus_audit.audit_logs
                 WHERE table_name = 'ingredients'
                   AND operation_type = 'UPDATE'
                   AND new_data ->> 'source_reference' =
                       'migration:20261010_003_fragrance_category_reclassification'
                """
            )
            audit_updates = cur.fetchone()[0]

            return {
                "name": name,
                "primary_perfuming": primary_perfuming,
                "primary_unclassified": primary_unclassified,
                "primary_root": primary_root,
                "primary_source_marked": source_marked,
                "secondary_links": secondary_links,
                "visible_links": visible_links,
                "parent_ok": parent_ok,
                "audit_updates": audit_updates,
            }


def main() -> None:
    urls = database_urls()
    checks = [preflight(name, url) for name, url in urls]
    for check in checks:
        print("PREFLIGHT", check)
        if check["primary_found"] != len(PRIMARY):
            raise RuntimeError(f"{check['name']}: allowlist primária incompleta: {check['primary_missing']}")
        if check["primary_unclassified"] != len(PRIMARY):
            raise RuntimeError(f"{check['name']}: há ingredientes da allowlist já classificados")

    sql = MIGRATION.read_text(encoding="utf-8")
    for name, url in urls:
        print(f"APPLY {name}")
        try:
            with psycopg.connect(
                url,
                connect_timeout=15,
                application_name="venus-fragrance-migration-20261010-003",
            ) as conn:
                conn.execute(sql)
        except Exception:
            print(f"ROLLBACK {name}")
            raise

    results = [validate(name, url) for name, url in urls]
    for result in results:
        print("VALIDATION", result)
        if result["primary_perfuming"] != len(PRIMARY):
            raise RuntimeError(f"{result['name']}: validação primária falhou")
        if result["primary_unclassified"] != 0:
            raise RuntimeError(f"{result['name']}: ainda há allowlist primária não classificada")
        if not result["parent_ok"]:
            raise RuntimeError(f"{result['name']}: hierarquia Fragrância/Agente Perfumante inválida")
        if result["audit_updates"] < len(PRIMARY):
            raise RuntimeError(f"{result['name']}: auditoria de ingredientes incompleta")

    print("OK: migration de fragrâncias aplicada e validada nos dois bancos")


if __name__ == "__main__":
    main()
