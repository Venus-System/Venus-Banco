"""Generate the Venus logical database model from PostgreSQL metadata.

The generator is intentionally read-only against the database. It reads
DATABASE_URL from .env and writes a reproducible documentation bundle:

* database-logical-model.md  - complete table/column/constraint catalog
* database-logical-model.sql - logical DDL snapshot
* database-logical-model.mmd - Mermaid ER diagram source
* database-logical-model.svg - zoomable ER diagram image

The physical tables are the source of the ER diagram. BI views are inventoried
in the Markdown file because they are derived objects rather than relational
tables with independent storage.
"""

from __future__ import annotations

import argparse
import html
import os
import re
from collections import defaultdict
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Any, Iterable

import psycopg
from dotenv import load_dotenv


SCHEMAS = ("venus", "venus_audit", "venus_rpa", "venus_optimization")
VIEW_SCHEMAS = SCHEMAS + ("venus_bi",)


@dataclass
class Column:
    name: str
    position: int
    data_type: str
    nullable: bool
    default: str | None
    generation: str | None
    comment: str | None
    is_pk: bool = False
    unique_constraints: list[str] = field(default_factory=list)
    foreign_keys: list[str] = field(default_factory=list)


@dataclass
class Table:
    schema: str
    name: str
    oid: int
    comment: str | None
    columns: list[Column] = field(default_factory=list)
    constraints: list[dict[str, Any]] = field(default_factory=list)
    unique_indexes: list[dict[str, Any]] = field(default_factory=list)
    x: int = 0
    y: int = 0
    width: int = 0
    height: int = 0
    field_y: dict[str, int] = field(default_factory=dict)

    @property
    def key(self) -> str:
        return f"{self.schema}.{self.name}"

    @property
    def pk(self) -> list[str]:
        for constraint in self.constraints:
            if constraint["type"] == "p":
                return constraint["source_columns"]
        return []

    @property
    def fks(self) -> list[dict[str, Any]]:
        return [c for c in self.constraints if c["type"] == "f"]


def qident(value: str) -> str:
    return '"' + value.replace('"', '""') + '"'


def inline(value: Any) -> str:
    return "" if value is None else str(value).replace("\n", " ").strip()


def code_name(schema: str, table: str) -> str:
    value = re.sub(r"[^a-zA-Z0-9_]", "_", f"{schema}__{table}")
    if value[:1].isdigit():
        value = "t_" + value
    return value


def type_label(data_type: str) -> str:
    return data_type.replace(" without time zone", "").replace(" with time zone", "")


def constraint_type_label(value: str) -> str:
    return {"p": "PK", "u": "UQ", "f": "FK", "c": "CHECK", "x": "EXCLUDE"}.get(value, value)


def action_label(value: str) -> str:
    return {"a": "NO ACTION", "r": "RESTRICT", "c": "CASCADE", "n": "SET NULL", "d": "SET DEFAULT"}.get(value, value)


def fetch_model(conn: psycopg.Connection[Any]) -> tuple[dict[str, Table], list[dict[str, Any]], list[dict[str, Any]], list[dict[str, Any]]]:
    table_rows = conn.execute(
        """
        SELECT n.nspname, c.relname, c.oid,
               obj_description(c.oid, 'pg_class')
        FROM pg_class c
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE n.nspname = ANY(%s)
          AND c.relkind IN ('r', 'p')
        ORDER BY array_position(%s::text[], n.nspname), c.relname
        """,
        (list(SCHEMAS), list(SCHEMAS)),
    ).fetchall()
    tables = {
        f"{schema}.{name}": Table(schema, name, oid, comment)
        for schema, name, oid, comment in table_rows
    }

    column_rows = conn.execute(
        """
        SELECT n.nspname, c.relname, a.attnum, a.attname,
               format_type(a.atttypid, a.atttypmod),
               NOT a.attnotnull,
               pg_get_expr(ad.adbin, ad.adrelid),
               CASE a.attgenerated
                 WHEN 's' THEN 'GENERATED STORED'
                 WHEN 'v' THEN 'GENERATED VIRTUAL'
                 ELSE NULL
               END,
               col_description(c.oid, a.attnum)
        FROM pg_attribute a
        JOIN pg_class c ON c.oid = a.attrelid
        JOIN pg_namespace n ON n.oid = c.relnamespace
        LEFT JOIN pg_attrdef ad
               ON ad.adrelid = a.attrelid AND ad.adnum = a.attnum
        WHERE n.nspname = ANY(%s)
          AND c.relkind IN ('r', 'p')
          AND a.attnum > 0
          AND NOT a.attisdropped
        ORDER BY array_position(%s::text[], n.nspname), c.relname, a.attnum
        """,
        (list(SCHEMAS), list(SCHEMAS)),
    ).fetchall()
    for row in column_rows:
        schema, name, position, column_name, data_type, nullable, default, generation, comment = row
        tables[f"{schema}.{name}"].columns.append(
            Column(column_name, position, data_type, nullable, default, generation, comment)
        )

    constraint_rows = conn.execute(
        """
        SELECT ns.nspname,
               rel.relname,
               con.conname,
               con.contype,
               pg_get_constraintdef(con.oid, true),
               ARRAY(
                   SELECT a.attname
                   FROM unnest(con.conkey) WITH ORDINALITY AS k(attnum, ord)
                   JOIN pg_attribute a
                     ON a.attrelid = con.conrelid AND a.attnum = k.attnum
                   ORDER BY k.ord
               ),
               ref_ns.nspname,
               ref_rel.relname,
               ARRAY(
                   SELECT a.attname
                   FROM unnest(con.confkey) WITH ORDINALITY AS k(attnum, ord)
                   JOIN pg_attribute a
                     ON a.attrelid = con.confrelid AND a.attnum = k.attnum
                   ORDER BY k.ord
               ),
               con.confdeltype::text,
               con.confupdtype::text,
               con.condeferrable,
               con.condeferred
        FROM pg_constraint con
        JOIN pg_class rel ON rel.oid = con.conrelid
        JOIN pg_namespace ns ON ns.oid = rel.relnamespace
        LEFT JOIN pg_class ref_rel ON ref_rel.oid = con.confrelid
        LEFT JOIN pg_namespace ref_ns ON ref_ns.oid = ref_rel.relnamespace
        WHERE ns.nspname = ANY(%s)
          AND rel.relkind IN ('r', 'p')
        ORDER BY array_position(%s::text[], ns.nspname), rel.relname, con.contype, con.conname
        """,
        (list(SCHEMAS), list(SCHEMAS)),
    ).fetchall()
    for row in constraint_rows:
        (
            schema,
            name,
            conname,
            contype,
            definition,
            source_columns,
            ref_schema,
            ref_name,
            target_columns,
            delete_action,
            update_action,
            deferrable,
            deferred,
        ) = row
        constraint = {
            "name": conname,
            "type": contype,
            "definition": definition,
            "source_columns": list(source_columns or []),
            "ref_schema": ref_schema,
            "ref_name": ref_name,
            "target_columns": list(target_columns or []),
            "delete_action": delete_action,
            "update_action": update_action,
            "deferrable": deferrable,
            "deferred": deferred,
        }
        table = tables[f"{schema}.{name}"]
        table.constraints.append(constraint)
        if contype == "p":
            for column in table.columns:
                column.is_pk = column.name in constraint["source_columns"]
        elif contype == "u":
            for column in table.columns:
                if column.name in constraint["source_columns"]:
                    column.unique_constraints.append(conname)
        elif contype == "f":
            for column in table.columns:
                if column.name in constraint["source_columns"]:
                    column.foreign_keys.append(conname)

    unique_index_rows = conn.execute(
        """
        SELECT ns.nspname,
               rel.relname,
               idx.relname,
               pg_get_indexdef(i.indexrelid),
               i.indisunique,
               i.indisprimary
        FROM pg_index i
        JOIN pg_class rel ON rel.oid = i.indrelid
        JOIN pg_class idx ON idx.oid = i.indexrelid
        JOIN pg_namespace ns ON ns.oid = rel.relnamespace
        WHERE ns.nspname = ANY(%s)
          AND rel.relkind IN ('r', 'p')
          AND i.indisunique
          AND NOT i.indisprimary
        ORDER BY array_position(%s::text[], ns.nspname), rel.relname, idx.relname
        """,
        (list(SCHEMAS), list(SCHEMAS)),
    ).fetchall()
    for schema, name, index_name, definition, is_unique, is_primary in unique_index_rows:
        tables[f"{schema}.{name}"].unique_indexes.append(
            {"name": index_name, "definition": definition}
        )

    enum_rows = conn.execute(
        """
        SELECT n.nspname, t.typname,
               array_agg(e.enumlabel ORDER BY e.enumsortorder)
        FROM pg_type t
        JOIN pg_namespace n ON n.oid = t.typnamespace
        JOIN pg_enum e ON e.enumtypid = t.oid
        WHERE n.nspname = ANY(%s)
        GROUP BY n.nspname, t.typname
        ORDER BY n.nspname, t.typname
        """,
        (list(SCHEMAS),),
    ).fetchall()
    enums = [
        {"schema": schema, "name": name, "values": list(values)}
        for schema, name, values in enum_rows
    ]

    views_rows = conn.execute(
        """
        SELECT n.nspname, c.relname,
               CASE c.relkind WHEN 'v' THEN 'view' WHEN 'm' THEN 'materialized view' END,
               obj_description(c.oid, 'pg_class')
        FROM pg_class c
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE n.nspname = ANY(%s)
          AND c.relkind IN ('v', 'm')
        ORDER BY array_position(%s::text[], n.nspname), c.relname
        """,
        (list(VIEW_SCHEMAS), list(VIEW_SCHEMAS)),
    ).fetchall()
    views = [
        {"schema": schema, "name": name, "kind": kind, "comment": comment}
        for schema, name, kind, comment in views_rows
    ]
    return tables, enums, views, []


def is_unique_fk(table: Table, constraint: dict[str, Any]) -> bool:
    columns = set(constraint["source_columns"])
    for other in table.constraints:
        if other["type"] in ("p", "u") and set(other["source_columns"]) == columns:
            return True
    return False


def relationship_label(table: Table, constraint: dict[str, Any]) -> str:
    required = all(not c.nullable for c in table.columns if c.name in constraint["source_columns"])
    unique = is_unique_fk(table, constraint)
    child_to_parent = "1..1" if required else "0..1"
    parent_to_child = "0..1" if unique else "0..N"
    return f"child {child_to_parent} -> parent 1..1; parent -> child {parent_to_child}"


def fk_rows(tables: dict[str, Table]) -> list[tuple[Table, dict[str, Any]]]:
    rows: list[tuple[Table, dict[str, Any]]] = []
    for table in tables.values():
        rows.extend((table, c) for c in table.fks)
    return rows


def generate_mermaid(tables: dict[str, Table]) -> str:
    lines = ["%% Generated from PostgreSQL metadata; physical tables only.", "erDiagram"]
    for table in tables.values():
        lines.append(f"    {code_name(table.schema, table.name)} {{")
        for column in table.columns:
            marker = []
            if column.is_pk:
                marker.append("PK")
            if column.unique_constraints:
                marker.append("UK")
            if column.foreign_keys:
                marker.append("FK")
            marker_text = " " + " ".join(marker) if marker else ""
            safe_type = re.sub(r"[^a-zA-Z0-9_]", "_", type_label(column.data_type)).upper()
            lines.append(f"        {safe_type} {column.name}{marker_text}")
        lines.append("    }")
    lines.append("")
    for table, constraint in fk_rows(tables):
        parent = f"{constraint['ref_schema']}.{constraint['ref_name']}"
        if parent not in tables:
            continue
        unique = is_unique_fk(table, constraint)
        required = all(not c.nullable for c in table.columns if c.name in constraint["source_columns"])
        notation = "||--o|" if unique else ("||--|{" if required else "||--o{")
        source = ", ".join(constraint["source_columns"])
        target = ", ".join(constraint["target_columns"])
        label = f"{constraint['name']}: {source} -> {target}"
        lines.append(
            f"    {code_name(constraint['ref_schema'], constraint['ref_name'])} {notation} "
            f"{code_name(table.schema, table.name)} : \"{label}\""
        )
    return "\n".join(lines) + "\n"


def generate_sql(tables: dict[str, Table], enums: list[dict[str, Any]]) -> str:
    lines = [
        "-- Venus logical schema snapshot generated from live PostgreSQL metadata.",
        "-- This file documents the deployed model; it is not a migration script.",
        "-- Physical tables are included; BI views are documented separately in Markdown.",
        "",
    ]
    for enum in enums:
        values = ", ".join("'" + v.replace("'", "''") + "'" for v in enum["values"])
        lines.append(
            f"CREATE TYPE {qident(enum['schema'])}.{qident(enum['name'])} AS ENUM ({values});"
        )
    if enums:
        lines.append("")
    for schema in SCHEMAS:
        lines.append(f"CREATE SCHEMA IF NOT EXISTS {qident(schema)};")
    lines.append("")
    for table in tables.values():
        lines.append(f"CREATE TABLE {qident(table.schema)}.{qident(table.name)} (")
        column_lines = []
        for column in table.columns:
            definition = f"    {qident(column.name)} {column.data_type}"
            if column.generation:
                definition += f" {column.generation}"
            elif column.default is not None:
                definition += f" DEFAULT {column.default}"
            if not column.nullable:
                definition += " NOT NULL"
            column_lines.append(definition)
        lines.append(",\n".join(column_lines))
        lines.append(");")
        if table.comment:
            lines.append(
                f"COMMENT ON TABLE {qident(table.schema)}.{qident(table.name)} IS "
                f"'{table.comment.replace(chr(39), chr(39) * 2)}';"
            )
        for column in table.columns:
            if column.comment:
                lines.append(
                    f"COMMENT ON COLUMN {qident(table.schema)}.{qident(table.name)}.{qident(column.name)} IS "
                    f"'{column.comment.replace(chr(39), chr(39) * 2)}';"
                )
        lines.append("")
    for table in tables.values():
        for constraint in table.constraints:
            definition = constraint["definition"]
            if constraint["type"] == "f":
                source = ", ".join(qident(column) for column in constraint["source_columns"])
                target = ", ".join(qident(column) for column in constraint["target_columns"])
                definition = (
                    f"FOREIGN KEY ({source}) REFERENCES "
                    f"{qident(constraint['ref_schema'])}.{qident(constraint['ref_name'])} ({target})"
                )
                if constraint["delete_action"] != "a":
                    definition += f" ON DELETE {action_label(constraint['delete_action'])}"
                if constraint["update_action"] != "a":
                    definition += f" ON UPDATE {action_label(constraint['update_action'])}"
                if constraint["deferrable"]:
                    definition += " DEFERRABLE"
                    if constraint["deferred"]:
                        definition += " INITIALLY DEFERRED"
            lines.append(
                f"ALTER TABLE {qident(table.schema)}.{qident(table.name)} "
                f"ADD CONSTRAINT {qident(constraint['name'])} {definition};"
            )
        lines.extend(index["definition"] + ";" for index in table.unique_indexes)
        if table.constraints or table.unique_indexes:
            lines.append("")
    return "\n".join(lines).rstrip() + "\n"


def table_badges(table: Table) -> str:
    pk = next((c for c in table.constraints if c["type"] == "p"), None)
    fks = len(table.fks)
    return f"PK {len(pk['source_columns']) if pk else 0} · FK {fks} · {len(table.columns)} fields"


def generate_markdown(
    tables: dict[str, Table],
    enums: list[dict[str, Any]],
    views: list[dict[str, Any]],
    database_name: str,
    generated_at: str,
) -> str:
    fk_count = sum(len(t.fks) for t in tables.values())
    lines = [
        "# Venus — Snapshot físico do banco",
        "",
        "> Snapshot gerado a partir dos metadados do PostgreSQL implantado. A fonte desta versão é o catálogo do banco, não uma inferência a partir dos nomes dos campos. O desenho visual editável está em [`docs/modelos lógicos/`](<modelos lógicos/>); este arquivo é a conferência técnica do modelo implantado.",
        "",
        f"- Banco: `{database_name}`",
        f"- Gerado em: `{generated_at}`",
        f"- Schemas de tabelas: `{', '.join(SCHEMAS)}`",
        f"- Tabelas físicas: **{len(tables)}**",
        f"- Relacionamentos FK: **{fk_count}**",
        f"- Tipos enum: **{len(enums)}**",
        f"- Views/materialized views inventariadas: **{len(views)}**",
        "",
        "## Artefatos",
        "",
        "- [Arquitetura dos schemas e guia de leitura](ARQUITETURA.md)",
        "- [Mapa arquitetural resumido](architecture-overview.mmd)",
        "- [Modelos visuais editáveis do brModelo](<modelos lógicos/README.md>)",
        "- [Diagrama visual completo — SVG](database-logical-model.svg)",
        "- [Fonte do diagrama — Mermaid](database-logical-model.mmd)",
        "- [Snapshot lógico SQL](database-logical-model.sql)",
        "",
        "## Escopo e leitura",
        "",
        "O diagrama mostra cada tabela física, seus campos, tipos, nulabilidade, PKs, UQs e FKs. As setas representam constraints FK reais; a cardinalidade é calculada pela nulabilidade da FK e pela existência de PK/UQ no conjunto de colunas de origem.",
        "",
        "As views `venus_bi` são derivadas e não possuem armazenamento relacional independente. Elas aparecem no inventário ao final deste documento, mas não são desenhadas como tabelas para evitar que uma camada analítica seja confundida com o modelo operacional.",
        "",
        "## Inventário por schema",
        "",
        "| Schema | Tabela | Campos | PK | FKs | Descrição |",
        "|---|---|---:|---:|---:|---|",
    ]
    for table in tables.values():
        pk = next((c for c in table.constraints if c["type"] == "p"), None)
        description = inline(table.comment).replace("|", "\\|") or "—"
        lines.append(
            f"| `{table.schema}` | `{table.name}` | {len(table.columns)} | "
            f"{len(pk['source_columns']) if pk else 0} | {len(table.fks)} | {description} |"
        )
    lines.extend(["", "## Detalhe de campos e constraints", ""])
    for table in tables.values():
        lines.extend([f"### `{table.schema}.{table.name}`", ""])
        if table.comment:
            lines.extend([table.comment, ""])
        lines.extend([
            "| # | Campo | Tipo | Aceita NULL? | Default | Papel | Descrição |",
            "|---:|---|---|:---:|---|---|---|",
        ])
        for column in table.columns:
            roles: list[str] = []
            if column.is_pk:
                roles.append("PK")
            if column.unique_constraints:
                roles.append("UQ")
            if column.foreign_keys:
                roles.append("FK")
            description = inline(column.comment).replace("|", "\\|") or "—"
            default = inline(column.default).replace("|", "\\|") or "—"
            lines.append(
                f"| {column.position} | `{column.name}` | `{column.data_type}` | "
                f"{'sim' if column.nullable else 'não'} | `{default}` | "
                f"{', '.join(roles) or '—'} | {description} |"
            )
        lines.append("")
        if table.constraints:
            lines.extend(["**Constraints**", "", "| Nome | Tipo | Definição |", "|---|---|---|"])
            for constraint in table.constraints:
                definition = inline(constraint["definition"]).replace("|", "\\|")
                lines.append(
                    f"| `{constraint['name']}` | `{constraint_type_label(constraint['type'])}` | `{definition}` |"
                )
            lines.append("")
        if table.unique_indexes:
            lines.extend(["**Índices únicos**", "", "| Nome | Definição |", "|---|---|"])
            for index in table.unique_indexes:
                lines.append(f"| `{index['name']}` | `{inline(index['definition'])}` |")
            lines.append("")
    lines.extend(["## Relacionamentos físicos", "", "| Constraint | Origem | Destino | Cardinalidade derivada | ON DELETE | ON UPDATE |", "|---|---|---|---|---|---|"])
    for table, constraint in fk_rows(tables):
        parent = f"{constraint['ref_schema']}.{constraint['ref_name']}"
        source = ", ".join(f"`{table.schema}.{table.name}.{c}`" for c in constraint["source_columns"])
        target = ", ".join(f"`{parent}.{c}`" for c in constraint["target_columns"])
        lines.append(
            f"| `{constraint['name']}` | {source} | {target} | `{relationship_label(table, constraint)}` | "
            f"`{action_label(constraint['delete_action'])}` | `{action_label(constraint['update_action'])}` |"
        )
    lines.extend(["", "## Tipos enum", "", "| Tipo | Valores |", "|---|---|"])
    for enum in enums:
        values = ", ".join(f"`{v}`" for v in enum["values"])
        lines.append(f"| `{enum['schema']}.{enum['name']}` | {values} |")
    lines.extend(["", "## Views e materialized views", "", "| Schema | Nome | Tipo | Descrição |", "|---|---|---|---|"])
    for view in views:
        lines.append(
            f"| `{view['schema']}` | `{view['name']}` | {view['kind']} | {inline(view['comment']) or '—'} |"
        )
    lines.extend([
        "",
        "## Regra de atualização",
        "",
        "Este documento é gerado por `python ops/generate_database_model.py` após uma alteração de schema ou migração. O gerador consulta somente metadados e não cria, altera ou remove objetos no banco. Os arquivos brM3 em `docs/modelos lógicos/` continuam sendo os desenhos visuais editáveis.",
        "",
    ])
    return "\n".join(lines)


def text_width(text: str, font_size: int) -> int:
    return max(1, len(text)) * max(6, int(font_size * 0.58))


def svg_escape(text: str) -> str:
    return html.escape(inline(text), quote=True)


def field_line(column: Column) -> str:
    markers = []
    if column.is_pk:
        markers.append("PK")
    if column.unique_constraints:
        markers.append("UQ")
    if column.foreign_keys:
        markers.append("FK")
    markers.append("NULL" if column.nullable else "NN")
    return f"{column.name} : {type_label(column.data_type)} [{', '.join(markers)}]"


def layout_tables(tables: dict[str, Table]) -> tuple[int, int]:
    """Place parent tables to the left of their FK children.

    A schema/file-order grid looks tidy but is a poor ERD layout: FK lines
    repeatedly cross unrelated cards and become visually hidden. Ranking by
    dependency keeps referenced tables upstream and gives every relationship a
    predictable horizontal corridor.
    """
    card_w = 460
    col_gap = 150
    row_gap = 42
    margin = 90
    top = 150
    line_h = 20

    parents: dict[str, list[str]] = {key: [] for key in tables}
    for table in tables.values():
        for constraint in table.fks:
            parent_key = f"{constraint['ref_schema']}.{constraint['ref_name']}"
            if parent_key in tables and parent_key != table.key:
                parents[table.key].append(parent_key)

    rank_memo: dict[str, int] = {}

    def rank(key: str, visiting: set[str] | None = None) -> int:
        if key in rank_memo:
            return rank_memo[key]
        visiting = set() if visiting is None else visiting
        if key in visiting:
            return 0
        visiting.add(key)
        parent_ranks = [rank(parent, visiting) for parent in parents[key]]
        value = min(7, 1 + max(parent_ranks, default=-1))
        visiting.remove(key)
        rank_memo[key] = value
        return value

    for key in tables:
        rank(key)

    def degree(table: Table) -> int:
        inbound = sum(table.key in parent_list for parent_list in parents.values())
        return len(table.fks) + inbound

    layers: dict[int, list[Table]] = defaultdict(list)
    for table in tables.values():
        table.rank = rank_memo[table.key]
        layers[table.rank].append(table)
    for layer in layers.values():
        layer.sort(key=lambda table: (-degree(table), SCHEMAS.index(table.schema), table.name))

    max_y = top
    max_rank = max(layers, default=0)
    for layer_number in range(max_rank + 1):
        y = top
        for table in layers.get(layer_number, []):
            table.width = card_w
            table.height = 54 + max(1, len(table.columns)) * line_h + 12
            table.x = margin + layer_number * (card_w + col_gap)
            table.y = y
            table.field_y.clear()
            field_y = table.y + 54
            for column in table.columns:
                table.field_y[column.name] = field_y + line_h // 2
                field_y += line_h
            y += table.height + row_gap
        max_y = max(max_y, y)
    width = margin * 2 + (max_rank + 1) * (card_w + col_gap) - col_gap
    return width, max_y + margin + 70


def svg_text(x: int, y: int, value: str, size: int = 12, color: str = "#243447", weight: int = 400, family: str = "Inter,Segoe UI,Arial,sans-serif") -> str:
    return f'<text x="{x}" y="{y}" font-family="{family}" font-size="{size}px" font-weight="{weight}" fill="{color}">{svg_escape(value)}</text>'


def generate_svg(tables: dict[str, Table], database_name: str, generated_at: str) -> str:
    width, height = layout_tables(tables)
    card_fill = {"venus": "#ffffff", "venus_audit": "#fffaf0", "venus_rpa": "#f5fff7", "venus_optimization": "#fcf6ff"}
    card_stroke = {"venus": "#1f2937", "venus_audit": "#8a5a12", "venus_rpa": "#26734d", "venus_optimization": "#70408f"}
    header_fill = {"venus": "#d9dde2", "venus_audit": "#f1dfb8", "venus_rpa": "#cfe8d7", "venus_optimization": "#e8d7f0"}
    edge_rows: list[dict[str, Any]] = []
    port_groups: dict[tuple[str, str, str], list[int]] = defaultdict(list)
    for table, constraint in fk_rows(tables):
        parent_key = f"{constraint['ref_schema']}.{constraint['ref_name']}"
        if parent_key not in tables or not constraint["source_columns"] or not constraint["target_columns"]:
            continue
        parent = tables[parent_key]
        source_field = constraint["source_columns"][0]
        target_field = constraint["target_columns"][0]
        if parent.x + parent.width + 35 <= table.x:
            parent_side, child_side = "right", "left"
        elif table.x + table.width + 35 <= parent.x:
            parent_side, child_side = "left", "right"
        else:
            parent_side = child_side = "right"
        edge_index = len(edge_rows)
        edge = {
            "index": edge_index,
            "table": table,
            "parent": parent,
            "constraint": constraint,
            "source_field": source_field,
            "target_field": target_field,
            "parent_side": parent_side,
            "child_side": child_side,
        }
        edge_rows.append(edge)
        port_groups[(parent.key, parent_side, target_field)].append(edge_index)
        port_groups[(table.key, child_side, source_field)].append(edge_index)

    edge_lanes: dict[tuple[int, int], int] = defaultdict(int)
    for edge in edge_rows:
        parent = edge["parent"]
        table = edge["table"]
        constraint = edge["constraint"]
        parent_group = port_groups[(parent.key, edge["parent_side"], edge["target_field"])]
        child_group = port_groups[(table.key, edge["child_side"], edge["source_field"])]
        parent_offset = (parent_group.index(edge["index"]) - (len(parent_group) - 1) / 2) * 6
        child_offset = (child_group.index(edge["index"]) - (len(child_group) - 1) / 2) * 6
        parent_x = parent.x if edge["parent_side"] == "left" else parent.x + parent.width
        child_x = table.x if edge["child_side"] == "left" else table.x + table.width
        parent_y = parent.field_y.get(edge["target_field"], parent.y + 54) + parent_offset
        child_y = table.field_y.get(edge["source_field"], table.y + 54) + child_offset
        rank_pair = (min(getattr(parent, "rank", 0), getattr(table, "rank", 0)), max(getattr(parent, "rank", 0), getattr(table, "rank", 0)))
        lane_number = edge_lanes[rank_pair]
        edge_lanes[rank_pair] += 1
        if edge["parent_side"] == "right" and edge["child_side"] == "left":
            midpoint = (parent_x + child_x) // 2 + (lane_number % 11 - 5) * 10
            path = f"M {parent_x} {parent_y} H {midpoint} V {child_y} H {child_x}"
        elif edge["parent_side"] == "left" and edge["child_side"] == "right":
            midpoint = (child_x + parent_x) // 2 + (lane_number % 11 - 5) * 10
            path = f"M {parent_x} {parent_y} H {midpoint} V {child_y} H {child_x}"
        else:
            outside = max(parent.x + parent.width, table.x + table.width) + 90 + lane_number * 14
            path = f"M {parent_x} {parent_y} H {outside} V {child_y} H {child_x}"
        edge["path"] = path
        edge["title"] = (
            f"{constraint['name']}: {table.key}.{edge['source_field']} -> "
            f"{parent.key}.{edge['target_field']}; {relationship_label(table, constraint)}; "
            f"ON DELETE {action_label(constraint['delete_action'])}; "
            f"ON UPDATE {action_label(constraint['update_action'])}"
        )
    parts = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}" role="img" aria-labelledby="title desc">',
        "<title id=\"title\">Venus — modelo lógico do banco</title>",
        f"<desc id=\"desc\">{len(tables)} tabelas físicas e {sum(len(t.fks) for t in tables.values())} relacionamentos de chave estrangeira, extraídos do banco {svg_escape(database_name)}.</desc>",
        "<defs>",
        "<marker id=\"one-bar\" markerWidth=\"12\" markerHeight=\"14\" refX=\"5\" refY=\"7\" orient=\"auto\" markerUnits=\"userSpaceOnUse\"><path d=\"M5 1 V13\" fill=\"none\" stroke=\"#1f2937\" stroke-width=\"2\"/></marker>",
        "<marker id=\"many-foot\" markerWidth=\"14\" markerHeight=\"14\" refX=\"1\" refY=\"7\" orient=\"auto\" markerUnits=\"userSpaceOnUse\"><path d=\"M1 7 L12 1 M1 7 H12 M1 7 L12 13\" fill=\"none\" stroke=\"#1f2937\" stroke-width=\"2\"/></marker>",
        "<marker id=\"one-foot\" markerWidth=\"12\" markerHeight=\"14\" refX=\"1\" refY=\"7\" orient=\"auto\" markerUnits=\"userSpaceOnUse\"><path d=\"M2 1 V13\" fill=\"none\" stroke=\"#1f2937\" stroke-width=\"2\"/></marker>",
        "</defs>",
        "<rect width=\"100%\" height=\"100%\" fill=\"#ffffff\"/>",
        svg_text(90, 48, "Venus — modelo lógico do banco", 26, "#172b4d", 500),
        svg_text(90, 76, f"Fonte: {database_name} · {len(tables)} tabelas · {len(edge_rows)} FKs · gerado em {generated_at}", 13, "#52606d"),
        svg_text(90, 100, "Cada linha sai da coluna FK e chega à coluna PK/UQ correspondente. PK = primária · UQ = única · FK = estrangeira · NN = NOT NULL · NULL = opcional", 12, "#52606d"),
    ]

    for edge in edge_rows:
        table = edge["table"]
        constraint = edge["constraint"]
        child_marker = "url(#one-foot)" if is_unique_fk(table, constraint) else "url(#many-foot)"
        parts.append(
            f'<path d="{edge["path"]}" fill="none" stroke="#1f2937" stroke-width="2" '
            f'stroke-linejoin="round" marker-start="url(#one-bar)" marker-end="{child_marker}">' 
            f'<title>{svg_escape(edge["title"])}</title></path>'
        )

    ordered_tables = sorted(tables.values(), key=lambda table: (getattr(table, "rank", 0), table.y, table.x, table.schema, table.name))
    for table in ordered_tables:
        fill = card_fill.get(table.schema, "#f7f9fb")
        stroke = card_stroke.get(table.schema, "#7b8794")
        header = header_fill.get(table.schema, "#d9dde2")
        parts.append(f'<g id="table-{code_name(table.schema, table.name)}">')
        parts.append(f'<rect x="{table.x}" y="{table.y}" width="{table.width}" height="{table.height}" rx="7" fill="{fill}" stroke="{stroke}" stroke-width="2"/>')
        parts.append(f'<rect x="{table.x + 1}" y="{table.y + 1}" width="{table.width - 2}" height="34" rx="6" fill="{header}"/>')
        parts.append(f'<line x1="{table.x}" y1="{table.y + 35}" x2="{table.x + table.width}" y2="{table.y + 35}" stroke="{stroke}" stroke-width="1.4"/>')
        parts.append(svg_text(table.x + 12, table.y + 23, table.name, 16, "#111827", 500, "ui-monospace,SFMono-Regular,Consolas,monospace"))
        parts.append(svg_text(table.x + table.width - 12 - text_width(table.schema, 10), table.y + 21, table.schema, 10, "#344054", 400))
        parts.append(f'<line x1="{table.x + 70}" y1="{table.y + 35}" x2="{table.x + 70}" y2="{table.y + table.height}" stroke="#c7cdd4" stroke-width="1"/>')
        y = table.y + 50
        for column in table.columns:
            marker = []
            if column.is_pk:
                marker.append("PK")
            if column.unique_constraints:
                marker.append("UQ")
            if column.foreign_keys:
                marker.append("FK")
            role = "/".join(marker) if marker else ""
            detail = f"{column.name} : {type_label(column.data_type)}"
            parts.append(svg_text(table.x + 10, y, role, 10, "#344054", 500, "ui-monospace,SFMono-Regular,Consolas,monospace"))
            parts.append(svg_text(table.x + 82, y, detail, 11, "#243447", 400, "ui-monospace,SFMono-Regular,Consolas,monospace"))
            null_marker = "NULL" if column.nullable else "NN"
            parts.append(svg_text(table.x + table.width - 38 - text_width(null_marker, 9), y, null_marker, 9, "#667085", 400, "ui-monospace,SFMono-Regular,Consolas,monospace"))
            y += 20
        parts.append("</g>")
    parts.append(svg_text(90, height - 28, "Barra = uma ocorrência na tabela referenciada; pé-de-galinha = várias ocorrências na tabela que contém a FK. A definição completa está no Markdown e no snapshot SQL.", 12, "#52606d"))
    parts.append("</svg>")
    return "\n".join(parts) + "\n"


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output-dir", type=Path, default=Path("docs"))
    args = parser.parse_args()
    load_dotenv()
    database_url = os.getenv("DATABASE_URL")
    if not database_url:
        raise SystemExit("DATABASE_URL não está configurada.")
    output_dir = args.output_dir
    if not output_dir.is_absolute():
        output_dir = Path(__file__).resolve().parents[1] / output_dir
    output_dir.mkdir(parents=True, exist_ok=True)
    with psycopg.connect(database_url, connect_timeout=10) as conn:
        tables, enums, views, _ = fetch_model(conn)
        database_name = conn.execute("select current_database()").fetchone()[0]
    generated_at = datetime.now().astimezone().strftime("%Y-%m-%d %H:%M:%S %z")
    (output_dir / "database-logical-model.md").write_text(
        generate_markdown(tables, enums, views, database_name, generated_at), encoding="utf-8"
    )
    (output_dir / "database-logical-model.sql").write_text(generate_sql(tables, enums), encoding="utf-8")
    (output_dir / "database-logical-model.mmd").write_text(generate_mermaid(tables), encoding="utf-8")
    (output_dir / "database-logical-model.svg").write_text(
        generate_svg(tables, database_name, generated_at), encoding="utf-8"
    )
    print(f"Generated {len(tables)} tables, {sum(len(t.fks) for t in tables.values())} FKs and {len(views)} views in {output_dir}")


if __name__ == "__main__":
    main()
