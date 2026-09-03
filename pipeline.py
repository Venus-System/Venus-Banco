from __future__ import annotations

import re
from dataclasses import dataclass, field
from pathlib import Path

def split_top_level(s: str) -> list[str]:
    items: list[str] = []
    depth = 0
    in_str = False
    buf: list[str] = []
    i = 0
    n = len(s)
    while i < n:
        c = s[i]
        if in_str:
            if c == "'":
                if i + 1 < n and s[i + 1] == "'":
                    buf.append("''")
                    i += 2
                    continue
                in_str = False
                buf.append(c)
                i += 1
                continue
            buf.append(c)
            i += 1
            continue
        if c == "'":
            in_str = True
            buf.append(c)
            i += 1
            continue
        if c == "(":
            depth += 1
            buf.append(c)
            i += 1
            continue
        if c == ")":
            depth -= 1
            buf.append(c)
            i += 1
            continue
        if c == "," and depth == 0:
            items.append("".join(buf).strip())
            buf = []
            i += 1
            continue
        buf.append(c)
        i += 1
    if buf:
        items.append("".join(buf).strip())
    return items


def unquote(tok: str) -> str | None:
    tok = tok.strip()
    if tok.upper() == "NULL":
        return None
    if len(tok) >= 2 and tok[0] == "'" and tok[-1] == "'":
        return tok[1:-1].replace("''", "'")
    return tok


def split_statements(sql_text: str) -> list[str]:
    stmts: list[str] = []
    in_str = False
    buf: list[str] = []
    i = 0
    n = len(sql_text)
    while i < n:
        c = sql_text[i]
        if in_str:
            buf.append(c)
            if c == "'":
                if i + 1 < n and sql_text[i + 1] == "'":
                    buf.append(sql_text[i + 1])
                    i += 2
                    continue
                in_str = False
            i += 1
            continue
        if c == "'":
            in_str = True
            buf.append(c)
            i += 1
            continue
        if c == ";":
            stmt = "".join(buf).strip()
            if stmt:
                stmts.append(stmt)
            buf = []
            i += 1
            continue
        buf.append(c)
        i += 1
    tail = "".join(buf).strip()
    if tail:
        stmts.append(tail)
    return stmts


_WS = re.compile(r"\s+")


def _normspace(s: str) -> str:
    return _WS.sub(" ", s).strip()

@dataclass
class ParsedIngredient:
    inci_name: str
    common_name_raw: str
    function_summary: str
    description: str
    source_type: str
    source_reference: str
    category_name: str
    properties: list[tuple[str, str, str, str, str]] = field(default_factory=list)
    aliases: list[tuple[str, str, str, str]] = field(default_factory=list)
    effects: list[tuple[str, str, str, str, str, str, str, str, str, str]] = field(default_factory=list)
    regulations: list[tuple[str, str, str, str, str, str, str, str]] = field(default_factory=list)

    def anvisa_translation(self) -> str | None:
        for name, value, *_ in self.properties:
            if name == "anvisa_translation" and value and value.strip():
                return value
        return None

    def has_historical_function(self) -> bool:
        return any(name == "historical_cosmetic_function" for name, *_ in self.properties)


_RE_INCI_WHERE = re.compile(r"WHERE\s+(?:\w+\.)?inci_name\s*=\s*'((?:[^']|'')*)'")
_RE_CATEGORY_IN_VALUE = re.compile(
    r"ingredient_categories\s+WHERE\s+name\s*=\s*'((?:[^']|'')*)'"
)
_RE_PT_JOIN = re.compile(
    r"JOIN\s+profile_tags\s+pt\s+ON\s*\(\s*pt\.name\s*=\s*'((?:[^']|'')*)'\s*OR\s*pt\.slug\s*=\s*'((?:[^']|'')*)'\s*\)"
)
_RE_RG_JOIN = re.compile(
    r"JOIN\s+regulations\s+rg\s+ON\s+rg\.title\s*=\s*'((?:[^']|'')*)'\s+AND\s+rg\.country\s*=\s*'((?:[^']|'')*)'"
)


def _cols_of(stmt: str, table_hint: str) -> list[str]:
    m = re.search(re.escape(table_hint) + r"\s*\(([^)]*)\)", stmt)
    if not m:
        raise ValueError(f"Não achei a lista de colunas para {table_hint!r} em: {stmt[:120]}...")
    return [c.strip() for c in m.group(1).split(",")]


def _values_top_level(stmt: str) -> list[str]:
    idx = stmt.index("VALUES(")
    start = idx + len("VALUES(")
    depth = 1
    i = start
    in_str = False
    while i < len(stmt):
        c = stmt[i]
        if in_str:
            if c == "'":
                if i + 1 < len(stmt) and stmt[i + 1] == "'":
                    i += 2
                    continue
                in_str = False
            i += 1
            continue
        if c == "'":
            in_str = True
            i += 1
            continue
        if c == "(":
            depth += 1
        elif c == ")":
            depth -= 1
            if depth == 0:
                break
        i += 1
    inner = stmt[start:i]
    return split_top_level(inner)


def _select_top_level(stmt: str) -> list[str]:
    m = re.search(r"\bSELECT\s+(.*?)\s+FROM\s+ingredients\b", stmt, re.DOTALL)
    if not m:
        raise ValueError(f"Não achei SELECT ... FROM ingredients em: {stmt[:160]}...")
    return split_top_level(m.group(1))


def parse_load_sql(path: Path) -> dict[str, ParsedIngredient]:
    """Faz uma única passada pelo arquivo e devolve inci_name -> ParsedIngredient
    com tudo já preenchido (properties, aliases, effects, regulations)."""
    text = path.read_text(encoding="utf-8")
    statements = split_statements(text)

    ingredients: dict[str, ParsedIngredient] = {}

    for stmt in statements:
        head = stmt[:40]
        if stmt.startswith("INSERT INTO ingredients("):
            cols = _cols_of(stmt, "ingredients")
            vals_raw = _values_top_level(stmt)
            row = dict(zip(cols, vals_raw))
            cat_raw = row["fk_ingredient_category_id"]
            cat_m = _RE_CATEGORY_IN_VALUE.search(cat_raw)
            category_name = unquote("'" + cat_m.group(1) + "'") if cat_m else "Não classificado"
            inci = unquote(row["inci_name"]) or ""
            ing = ParsedIngredient(
                inci_name=inci,
                common_name_raw=unquote(row.get("common_name", "''")) or "",
                function_summary=unquote(row.get("function_summary", "''")) or "",
                description=unquote(row.get("description", "''")) or "",
                source_type=unquote(row.get("source_type", "''")) or "",
                source_reference=unquote(row.get("source_reference", "''")) or "",
                category_name=category_name,
            )
            ingredients[inci] = ing
            continue

        if stmt.startswith("INSERT INTO ingredient_properties("):
            cols = _cols_of(stmt, "ingredient_properties")
            sel = _select_top_level(stmt)
            row = dict(zip(cols[1:], sel[1:]))
            m = _RE_INCI_WHERE.search(stmt)
            if not m:
                continue
            inci = unquote("'" + m.group(1) + "'") or ""
            ing = ingredients.get(inci)
            if ing is None:
                continue
            ing.properties.append((
                unquote(row.get("property_name", "''")) or "",
                unquote(row.get("property_value", "''")) or "",
                unquote(row.get("unit", "''")) or "",
                unquote(row.get("source_type", "''")) or "",
                unquote(row.get("source_reference", "''")) or "",
            ))
            continue

        if stmt.startswith("INSERT INTO ingredient_aliases("):
            cols = _cols_of(stmt, "ingredient_aliases")
            sel = _select_top_level(stmt)
            row = dict(zip(cols[1:], sel[1:]))
            m = _RE_INCI_WHERE.search(stmt)
            if not m:
                continue
            inci = unquote("'" + m.group(1) + "'") or ""
            ing = ingredients.get(inci)
            if ing is None:
                continue
            ing.aliases.append((
                unquote(row.get("alias_name", "''")) or "",
                unquote(row.get("alias_language", "''")) or "",
                unquote(row.get("source_type", "''")) or "",
                unquote(row.get("source_reference", "''")) or "",
            ))
            continue

        if stmt.startswith("INSERT INTO ingredient_effects("):
            cols = _cols_of(stmt, "ingredient_effects")
            sel = _select_top_level(stmt)
            row = dict(zip(cols[2:], sel[2:]))
            m_inci = _RE_INCI_WHERE.search(stmt)
            m_pt = _RE_PT_JOIN.search(stmt)
            if not (m_inci and m_pt):
                continue
            inci = unquote("'" + m_inci.group(1) + "'") or ""
            ing = ingredients.get(inci)
            if ing is None:
                continue
            ing.effects.append((
                unquote("'" + m_pt.group(1) + "'") or "",
                unquote("'" + m_pt.group(2) + "'") or "",
                unquote(row.get("effect_category", "''")) or "",
                unquote(row.get("effect_name", "''")) or "",
                unquote(row.get("effect_description", "''")) or "",
                unquote(row.get("effect_strength", "''")) or "",
                unquote(row.get("evidence_level", "''")) or "",
                unquote(row.get("review_status", "''")) or "",
                unquote(row.get("source_type", "''")) or "",
                unquote(row.get("source_reference", "''")) or "",
            ))
            continue

        if stmt.startswith("INSERT INTO ingredient_regulations("):
            cols = _cols_of(stmt, "ingredient_regulations")
            sel = _select_top_level(stmt)
            row = dict(zip(cols[2:], sel[2:]))
            m_inci = _RE_INCI_WHERE.search(stmt)
            m_rg = _RE_RG_JOIN.search(stmt)
            if not (m_inci and m_rg):
                continue
            inci = unquote("'" + m_inci.group(1) + "'") or ""
            ing = ingredients.get(inci)
            if ing is None:
                continue
            ing.regulations.append((
                unquote("'" + m_rg.group(1) + "'") or "",
                unquote("'" + m_rg.group(2) + "'") or "",
                unquote(row.get("restriction_type", "''")) or "",
                unquote(row.get("max_concentration_value", "NULL")),
                unquote(row.get("unit", "''")) or "",
                unquote(row.get("notes", "''")) or "",
                unquote(row.get("source_type", "''")) or "",
                unquote(row.get("source_reference", "''")) or "",
            ))
            continue


    return ingredients



import argparse
import hashlib
from dotenv import load_dotenv
import json
import os
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent
load_dotenv(ROOT / ".env")
SQL_DIR = ROOT / "sql"
SOURCE_SQL = ROOT / "data" / "venus_v12_load.sql"
SCHEMA = "venus"
UNCLASSIFIED_CATEGORY = "Não classificado"

_WS = re.compile(r"\s+")
def normalize_text(value: str | None) -> str:
    if value is None:
        return ""
    import unicodedata
    return _WS.sub(" ", unicodedata.normalize("NFKC", value).strip())

def despace(value: str | None) -> str:
    if value is None:
        return ""
    import unicodedata
    return re.sub(r"\s+", "", unicodedata.normalize("NFKC", value)).upper()

def is_spaced_copy_of(value: str | None, reference: str | None) -> bool:
    v, r = normalize_text(value), normalize_text(reference)
    return bool(v and r and v != r and despace(v) == despace(r))

POLICIES = {
    "standard": ("categorized", "historical_function", "has_effects", "has_regulations"),
    "strict": ("categorized", "has_effects", "has_regulations"),
}


def choose_common_name(inci: str, current: str | None, translation: str | None):
    inci_n = normalize_text(inci)
    tr = normalize_text(translation)
    if tr and not is_spaced_copy_of(tr, inci_n):
        return tr, "anvisa_translation"
    if is_spaced_copy_of(current, inci_n):
        return inci_n, "inci_reconstructed"
    return None, "unresolved"


def sha256_file(path: Path, chunk: int = 1024 * 1024) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        while True:
            b = f.read(chunk)
            if not b:
                break
            h.update(b)
    return h.hexdigest()


def db_connect(url: str):
    try:
        import psycopg
    except ImportError as exc:
        raise SystemExit('Instale a dependência: python -m pip install "psycopg[binary]"') from exc
    conn = psycopg.connect(url, autocommit=False)
    conn.execute("SET application_name = 'venus_bootstrap_pipeline'")
    return conn


def require_clean_target(conn, reset: bool) -> None:
    with conn.cursor() as cur:
        cur.execute("""
            SELECT COUNT(*)
            FROM pg_namespace
            WHERE nspname = ANY(%s)
        """, (['venus','venus_audit','venus_bi','venus_rpa','venus_optimization'],))
        schema_count = int(cur.fetchone()[0])
        if not schema_count:
            return
        cur.execute("""
            SELECT COUNT(*)
            FROM information_schema.tables
            WHERE table_schema = ANY(%s)
        """, (['venus','venus_audit','venus_bi','venus_rpa','venus_optimization'],))
        count = int(cur.fetchone()[0])
        if count and not reset:
            raise RuntimeError(
                "O banco já contém objetos Venus. Este pipeline é bootstrap, não migration. "
                "Use um banco novo ou passe --reset para reconstruir somente os schemas gerenciados."
            )


def reset_venus(conn) -> None:
    with conn.cursor() as cur:
        for schema in ("venus_optimization", "venus_rpa", "venus_bi", "venus_audit", "venus"):
            cur.execute(f"DROP SCHEMA IF EXISTS {schema} CASCADE")


def execute_sql_file(conn, path: Path) -> None:
    text = path.read_text(encoding="utf-8")
    if not text.strip():
        return
    conn.execute(text)


def load_reference_tables(conn) -> dict:
    with conn.cursor() as cur:
        cur.execute("SELECT ingredient_category_id, name FROM venus.ingredient_categories")
        categories = {name: cid for cid, name in cur.fetchall()}
        cur.execute("SELECT profile_tag_id, name, slug FROM venus.profile_tags")
        tags_by_name, tags_by_slug = {}, {}
        for tid, name, slug in cur.fetchall():
            if name: tags_by_name[name] = tid
            if slug: tags_by_slug[slug] = tid
        cur.execute("SELECT regulation_id, title, country FROM venus.regulations")
        regs = {(title, country): rid for rid, title, country in cur.fetchall()}
    return {"categories": categories, "tags_by_name": tags_by_name, "tags_by_slug": tags_by_slug, "regulations": regs}


def resolve_profile_tag(refs: dict, name: str, slug: str):
    return refs["tags_by_name"].get(name) or refs["tags_by_slug"].get(slug)


REGULATION_ALIASES = {
    ("Regulation (EC) No 1223/2009 on cosmetic products", "European Union"): (
        "Regulamento (CE) n.º 1223/2009 do Parlamento Europeu e do Conselho", "UE"
    ),
}

def resolve_regulation(refs: dict, title: str, country: str):
    exact = refs["regulations"].get((title, country))
    if exact is not None:
        return exact
    alias = REGULATION_ALIASES.get((title, country))
    return refs["regulations"].get(alias) if alias else None


def build_clean_snapshot(ingredients: dict[str, ParsedIngredient], refs: dict, policy: str):
    keep_evidence = {"categorized": set(), "historical_function": set(), "has_effects": set(), "has_regulations": set()}
    resolved_effects: dict[str, list[tuple]] = {}
    resolved_regs: dict[str, list[tuple]] = {}

    for inci, ing in ingredients.items():
        if ing.category_name != UNCLASSIFIED_CATEGORY:
            keep_evidence["categorized"].add(inci)
        if ing.has_historical_function():
            keep_evidence["historical_function"].add(inci)
        effs = []
        for row in ing.effects:
            tag_id = resolve_profile_tag(refs, row[0], row[1])
            if tag_id is not None:
                effs.append((tag_id, *row[2:]))
        if effs:
            seen = set(); unique = []
            for e in effs:
                key = (e[0], e[1], e[2])
                if key not in seen:
                    seen.add(key); unique.append(e)
            keep_evidence["has_effects"].add(inci)
            resolved_effects[inci] = unique
        regs = []
        for row in ing.regulations:
            reg_id = resolve_regulation(refs, row[0], row[1])
            if reg_id is not None:
                regs.append((reg_id, *row[2:]))
        if regs:
            seen = set(); unique = []
            for r in regs:
                key = (r[0], r[1], r[2], r[3], r[6] if len(r) > 6 else None)
                if key not in seen:
                    seen.add(key); unique.append(r)
            keep_evidence["has_regulations"].add(inci)
            resolved_regs[inci] = unique

    keep_set = set().union(*(keep_evidence[k] for k in POLICIES[policy]))
    now = datetime.now(timezone.utc)
    data = {"ingredients": [], "ingredient_aliases": [], "ingredient_properties": [], "ingredient_effects": [], "ingredient_regulations": []}
    repair = {"unchanged": 0, "anvisa_translation": 0, "inci_reconstructed": 0, "unresolved": 0}
    unresolved = []

    for inci in sorted(keep_set):
        ing = ingredients[inci]
        cat_id = refs["categories"].get(ing.category_name)
        if cat_id is None:
            raise RuntimeError(f"Categoria '{ing.category_name}' do ingrediente '{inci}' não existe em venus.ingredient_categories.")
        target, method = choose_common_name(inci, ing.common_name_raw, ing.anvisa_translation())
        current_n = normalize_text(ing.common_name_raw)
        if target is None:
            repair["unresolved"] += 1
            unresolved.append(inci)
            target = ing.common_name_raw
        elif target == current_n:
            repair["unchanged"] += 1
            target = ing.common_name_raw
        else:
            repair[method] += 1
        data["ingredients"].append((cat_id, ing.inci_name, target, ing.function_summary, ing.description,
                                     ing.source_type, ing.source_reference, now, now))

        for pname, pvalue, unit, psrc, pref in ing.properties:
            data["ingredient_properties"].append((inci, pname, pvalue, unit, psrc, pref, now, now))
        for aname, alang, asrc, aref in ing.aliases:
            data["ingredient_aliases"].append((inci, aname, alang, asrc, aref, now, now))
        for tag_id, ecat, ename, edesc, estr, elev, estatus, esrc, eref in resolved_effects.get(inci, []):
            data["ingredient_effects"].append((inci, tag_id, ecat, ename, edesc, estr, elev, estatus, esrc, eref, now, now))
        for reg_id, rtype, maxc, unit, notes, rsrc, rref in resolved_regs.get(inci, []):
            data["ingredient_regulations"].append((inci, reg_id, rtype, maxc, unit, notes, rsrc, rref, now, now))

    def dedup(rows, keyidx):
        seen=set(); out=[]
        for row in rows:
            key=tuple(row[i] for i in keyidx)
            if key not in seen:
                seen.add(key); out.append(row)
        return out
    data["ingredient_aliases"] = dedup(data["ingredient_aliases"], (0,1,2))
    data["ingredient_properties"] = dedup(data["ingredient_properties"], (0,1,3))
    data["ingredient_effects"] = dedup(data["ingredient_effects"], (0,1,2,3))
    data["ingredient_regulations"] = dedup(data["ingredient_regulations"], (0,1))

    return data, {
        "policy": policy,
        "ingredients_no_arquivo_fonte": len(ingredients),
        "evidencia_de_uso_cosmetico": {k: len(v) for k,v in keep_evidence.items()},
        "mantidos": len(keep_set),
        "removidos_antes_de_qualquer_insert": len(ingredients)-len(keep_set),
        "repair_names": repair,
        "repair_names_unresolved_inci": unresolved,
        "linhas_geradas": {k: len(v) for k,v in data.items()},
    }


def bulk_insert(conn, sql: str, rows: list[tuple], label: str) -> None:
    if not rows: return
    with conn.cursor() as cur:
        cur.executemany(sql, rows)
    print(f"      {label}: {len(rows):,} linhas")


def insert_clean_data(conn, data: dict) -> None:
    with conn.cursor() as cur:
        cur.executemany(
            """INSERT INTO venus.ingredients
            (fk_ingredient_category_id, inci_name, common_name, function_summary, description, source_type, source_reference, created_at, updated_at)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s)""", data["ingredients"])
        cur.execute("SELECT ingredient_id, inci_name FROM venus.ingredients")
        id_by_inci = {inci: iid for iid, inci in cur.fetchall()}
        if len(id_by_inci) != len(data["ingredients"]):
            raise RuntimeError("Mapa de ingredients inconsistente após o INSERT.")

        alias_rows=[(id_by_inci[inci], aname, alang, asrc, aref, created, updated) for inci,aname,alang,asrc,aref,created,updated in data["ingredient_aliases"]]
        prop_rows=[(id_by_inci[inci], pname, pvalue, unit, psrc, pref, created, updated) for inci,pname,pvalue,unit,psrc,pref,created,updated in data["ingredient_properties"]]
        effect_rows=[(id_by_inci[inci], tag_id, ecat, ename, edesc, estr, elev, estatus, esrc, eref, created, updated) for inci,tag_id,ecat,ename,edesc,estr,elev,estatus,esrc,eref,created,updated in data["ingredient_effects"]]
        reg_rows=[(id_by_inci[inci], reg_id, rtype, maxc, unit, notes, rsrc, rref, created, updated) for inci,reg_id,rtype,maxc,unit,notes,rsrc,rref,created,updated in data["ingredient_regulations"]]
        cur.executemany("""INSERT INTO venus.ingredient_aliases
            (fk_ingredient_id, alias_name, alias_language, source_type, source_reference, created_at, updated_at)
            VALUES (%s,%s,%s,%s,%s,%s,%s) ON CONFLICT (fk_ingredient_id,alias_name,alias_language) DO NOTHING""", alias_rows)
        cur.executemany("""INSERT INTO venus.ingredient_properties
            (fk_ingredient_id, property_name, property_value, unit, source_type, source_reference, created_at, updated_at)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s) ON CONFLICT (fk_ingredient_id,property_name,unit) DO NOTHING""", prop_rows)
        cur.executemany("""INSERT INTO venus.ingredient_effects
            (fk_ingredient_id, fk_profile_tag_id, effect_category, effect_name, effect_description, effect_strength, evidence_level, review_status, source_type, source_reference, created_at, updated_at)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s) ON CONFLICT (fk_ingredient_id,fk_profile_tag_id,effect_category,effect_name) DO NOTHING""", effect_rows)
        cur.executemany("""INSERT INTO venus.ingredient_regulations
            (fk_ingredient_id, fk_regulation_id, restriction_type, max_concentration_value, unit, notes, source_type, source_reference, created_at, updated_at)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s) ON CONFLICT (fk_ingredient_id,fk_regulation_id) DO NOTHING""", reg_rows)
    print(f"      ingredients: {len(data['ingredients']):,}")
    print(f"      ingredient_aliases: {len(alias_rows):,}")
    print(f"      ingredient_properties: {len(prop_rows):,}")
    print(f"      ingredient_effects: {len(effect_rows):,}")
    print(f"      ingredient_regulations: {len(reg_rows):,}")


def validate_db(conn) -> dict:
    checks = {}
    with conn.cursor() as cur:
        forbidden = ('product_images','scan_sessions','routines','routine_items')
        cur.execute("SELECT table_name FROM information_schema.tables WHERE table_schema='venus' AND table_name = ANY(%s)", (list(forbidden),))
        checks['tabelas_legadas_presentes'] = [r[0] for r in cur.fetchall()]
        if checks['tabelas_legadas_presentes']:
            raise RuntimeError(f"Tabelas legadas ainda presentes: {checks['tabelas_legadas_presentes']}")
        cur.execute("SELECT COUNT(*) FROM venus.scoring_models WHERE is_active")
        checks['scoring_models_ativos'] = int(cur.fetchone()[0])
        if checks['scoring_models_ativos'] != 1:
            raise RuntimeError(f"Esperado exatamente 1 scoring_model ativo; obtido {checks['scoring_models_ativos']}.")
        cur.execute("SELECT COUNT(*) FROM venus.products")
        checks['products'] = int(cur.fetchone()[0])
        cur.execute("SELECT COUNT(*) FROM venus.users")
        checks['users'] = int(cur.fetchone()[0])
        cur.execute("SELECT COUNT(*) FROM venus.ingredients")
        checks['ingredients'] = int(cur.fetchone()[0])
        cur.execute("SELECT COUNT(*) FROM venus.data_catalog")
        checks['data_catalog_rows'] = int(cur.fetchone()[0])
        cur.execute("SELECT COUNT(*) FROM venus.data_catalog_rules")
        checks['data_catalog_rules'] = int(cur.fetchone()[0])
        cur.execute("SELECT COUNT(*) FROM (SELECT fk_product_id FROM venus.product_versions WHERE is_current GROUP BY fk_product_id HAVING COUNT(*)>1) q")
        checks['products_with_multiple_current_versions'] = int(cur.fetchone()[0])
        if checks['products_with_multiple_current_versions']:
            raise RuntimeError('Existe produto com mais de uma versão current.')
    return checks


def main() -> int:
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--database-url', default=os.getenv('DATABASE_URL') or os.getenv('QA_DATABASE_URL'))
    ap.add_argument('--load-sql', default=str(SOURCE_SQL))
    ap.add_argument('--policy', choices=POLICIES, default='standard')
    ap.add_argument('--reset', action='store_true', help='derruba e recria apenas schemas Venus do pacote')
    ap.add_argument('--skip-demo', action='store_true')
    ap.add_argument('--skip-bi', action='store_true')
    ap.add_argument('--skip-rpa', action='store_true', help='não executar o RPA contra o legado externo')
    ap.add_argument('--legacy-database-url', default=os.getenv('LEGACY_DATABASE_URL'))
    ap.add_argument('--legacy-products-query', default=os.getenv('LEGACY_PRODUCTS_QUERY'))
    ap.add_argument('--legacy-users-query', default=os.getenv('LEGACY_USERS_QUERY'))
    args=ap.parse_args()
    if not args.database_url:
        raise SystemExit('Defina DATABASE_URL no arquivo .env (ou passe --database-url).')
    source=Path(args.load_sql)
    if not source.is_file():
        raise SystemExit(f'Arquivo de carga não encontrado: {source}')

    print('=== VENUS / BOOTSTRAP POSTGRESQL ===')
    print(f'Fonte de ingredientes: {source}')
    print(f'Policy: {args.policy}')
    print(f'Reset: {args.reset}')
    print(f'RPA: {"habilitado" if (args.legacy_database_url and not args.skip_rpa) else "preparado/ignorado"}')

    conn=db_connect(args.database_url)
    try:
        require_clean_target(conn, args.reset)
        if args.reset:
            reset_venus(conn)
            conn.commit()

        with conn.transaction():
            print('[1/10] Criando schema, tabelas, FKs, índices, funções e triggers...')
            execute_sql_file(conn, SQL_DIR/'00_schema.sql')
            print('      [1b/10] Configurando catálogo de mídia Cloudinary...')
            execute_sql_file(conn, SQL_DIR/'05_cloudinary_images.sql')
            conn.execute("SET venus.bootstrap = 'on'")

            print('[2/10] Inserindo dados mestres e regulações...')
            execute_sql_file(conn, SQL_DIR/'10_reference_seed.sql')
            execute_sql_file(conn, SQL_DIR/'20_regulation_seed.sql')

            refs=load_reference_tables(conn)
            if UNCLASSIFIED_CATEGORY not in refs['categories']:
                raise RuntimeError(f"Categoria obrigatória '{UNCLASSIFIED_CATEGORY}' não existe após o seed.")
            if len(refs['tags_by_name']) < 10 or len(refs['regulations']) < 1:
                raise RuntimeError('Dados de referência insuficientes para carregar ingredientes.')

            print('[3/10] Lendo e reconstruindo o arquivo v12 em memória...')
            ingredients=parse_load_sql(source)
            print(f'      {len(ingredients):,} ingredientes reconstruídos.')

            print('[4/10] Aplicando limpeza e resolvendo FKs antes de qualquer INSERT de ingrediente...')
            data, stats=build_clean_snapshot(ingredients,refs,args.policy)
            print(f"      mantidos: {stats['mantidos']:,} / {stats['ingredients_no_arquivo_fonte']:,}")
            print(f"      removidos antes de qualquer INSERT: {stats['removidos_antes_de_qualquer_insert']:,}")
            print(f"      repair-names: {stats['repair_names']}")

            print('[5/10] Gravando somente o conjunto limpo de ingredientes e dependências...')
            insert_clean_data(conn,data)

            if not args.skip_demo:
                print('[6/10] Carga técnica/demonstração (58 produtos / 40 usuários)...')
                execute_sql_file(conn,SQL_DIR/'30_demo_seed.sql')
            else:
                print('[6/10] Demo seed ignorado (--skip-demo).')

            print('[7/10] Catálogo técnico...')
            execute_sql_file(conn, SQL_DIR/'40_data_catalog.sql')

            print('[8/10] Estruturas avançadas + BI + EXPLAIN ANALYZE...')
            execute_sql_file(conn, SQL_DIR/'45_advanced_structures.sql')

            if not args.skip_bi:
                execute_sql_file(conn, SQL_DIR/'50_bi.sql')

            execute_sql_file(conn, SQL_DIR/'55_optimization.sql')

            print('[9/10] RPA...')
            execute_sql_file(conn, SQL_DIR/'60_rpa.sql')

            if not args.skip_rpa and args.legacy_database_url:
                from rpa_migrate import run_rpa
                result=run_rpa(
                    conn,
                    args.legacy_database_url,
                    args.legacy_products_query,
                    args.legacy_users_query
                )
                print(json.dumps({'rpa':result},ensure_ascii=False))
            elif args.skip_rpa:
                print('      RPA ignorado (--skip-rpa); controle/staging criado no alvo.')
            else:
                print('      RPA não executado: LEGACY_DATABASE_URL não informado. O legado é externo e não é criado pelo pacote.')

            print('[10/10] Validação final...')

            conn.execute("SET venus.bootstrap = 'off'")
            execute_sql_file(conn, SQL_DIR/'99_validation.sql')
            checks=validate_db(conn)

        conn.commit()

        print('\n=== CONCLUÍDO ===')
        print(json.dumps({'status':'ok','policy':args.policy,'source_sha256':sha256_file(source),'checks':checks},ensure_ascii=False,indent=2))
        return 0
    except Exception:
        try: conn.rollback()
        except Exception: pass
        raise
    finally:
        conn.close()

if __name__=='__main__':
    raise SystemExit(main())
