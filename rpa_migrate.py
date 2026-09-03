from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import unicodedata
import uuid
from typing import Any, Iterable, Mapping

import psycopg
from dotenv import load_dotenv
from psycopg.types.json import Jsonb

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
load_dotenv(os.path.join(BASE_DIR, ".env"))

DEFAULT_PRODUCTS_QUERY = (
    "SELECT legacy_product_id, product_name, brand_name, category_name, "
    "ingredients_text FROM legacy_products"
)
DEFAULT_USERS_QUERY = (
    "SELECT legacy_user_id, full_name, email, status_text FROM legacy_users"
)

STATUS_MAP = {
    "ativo": "active",
    "active": "active",
    "inativo": "inactive",
    "inactive": "inactive",
    "bloqueado": "blocked",
    "blocked": "blocked",
    "pendente": "pending",
    "pending": "pending",
}

REQUIRED_PRODUCT_COLUMNS = {
    "legacy_product_id",
    "product_name",
    "brand_name",
    "category_name",
    "ingredients_text",
}
REQUIRED_USER_COLUMNS = {
    "legacy_user_id",
    "full_name",
    "email",
    "status_text",
}

EMAIL_RE = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")


def norm(value: Any) -> str:
    """Converte valor para texto, normalizando espaços."""
    return re.sub(r"\s+", " ", str(value or "").strip())


def normalize_text(value: Any) -> str:
    """Normalização forte para comparação de nomes (acentos/pontuação)."""
    text = norm(value)
    text = unicodedata.normalize("NFKD", text)
    text = "".join(ch for ch in text if not unicodedata.combining(ch))
    text = text.casefold()
    return re.sub(r"[^a-z0-9]+", "", text)


def slugify(value: Any) -> str:
    text = unicodedata.normalize("NFKD", norm(value)).encode("ascii", "ignore").decode()
    text = text.lower()
    return re.sub(r"[^a-z0-9]+", "-", text).strip("-") or "produto"


def qhash(value: str) -> str:
    return hashlib.sha256(value.encode("utf-8")).hexdigest()


def _cols(cur: psycopg.Cursor) -> list[str]:
    return [d.name for d in cur.description]


def _json_payload(value: Mapping[str, Any] | Any) -> Jsonb:
    """Converte linhas do legado em JSON seguro mesmo com tipos não-JSON."""
    if isinstance(value, Mapping):
        serializable = json.loads(json.dumps(dict(value), default=str))
    else:
        serializable = json.loads(json.dumps(value, default=str))
    return Jsonb(serializable)


def _require_columns(columns: Iterable[str], required: set[str], label: str) -> None:
    actual = {str(c) for c in columns}
    missing = sorted(required - actual)
    if missing:
        raise ValueError(
            f"{label}: a query não retornou as colunas obrigatórias: {', '.join(missing)}"
        )


def _split_ingredients(value: Any) -> list[str]:
    """Converte ingredients_text em tokens, aceitando vírgula e ponto-e-vírgula."""
    if value is None:
        return []

    if isinstance(value, (list, tuple, set)):
        return [norm(x) for x in value if norm(x)]

    text = norm(value)
    if not text:
        return []
    if text.startswith("[") and text.endswith("]"):
        try:
            parsed = json.loads(text)
            if isinstance(parsed, list):
                return [norm(x) for x in parsed if norm(x)]
        except json.JSONDecodeError:
            pass
    parts = re.split(r"\s*[;,]\s*", text)
    return [p for p in (norm(x) for x in parts) if p]


def _add_map_entry(mapping: dict[str, int], ambiguous: set[str], key: str, ingredient_id: int) -> None:
    if not key:
        return
    current = mapping.get(key)
    if current is None:
        mapping[key] = ingredient_id
        return
    if current != ingredient_id:
        ambiguous.add(key)
        mapping.pop(key, None)


def load_ingredient_map(target_conn: psycopg.Connection) -> tuple[dict[str, int], set[str], int]:
    """Carrega o catálogo Venus uma única vez para resolução O(1) dos tokens.

    A resolução considera INCI, common_name e aliases. Chaves ambíguas são
    deliberadamente removidas para evitar vincular um produto ao ingrediente errado.
    """
    exact_map: dict[str, int] = {}
    normalized_map: dict[str, int] = {}
    exact_ambiguous: set[str] = set()
    normalized_ambiguous: set[str] = set()

    with target_conn.cursor() as cur:
        cur.execute("SELECT ingredient_id, inci_name, common_name FROM venus.ingredients")
        ingredient_rows = cur.fetchall()
        for ingredient_id, inci_name, common_name in ingredient_rows:
            for candidate in (inci_name, common_name):
                raw_key = norm(candidate).casefold()
                strong_key = normalize_text(candidate)
                _add_map_entry(exact_map, exact_ambiguous, raw_key, int(ingredient_id))
                _add_map_entry(normalized_map, normalized_ambiguous, strong_key, int(ingredient_id))

        cur.execute("SELECT fk_ingredient_id, alias_name FROM venus.ingredient_aliases")
        for ingredient_id, alias_name in cur.fetchall():
            raw_key = norm(alias_name).casefold()
            strong_key = normalize_text(alias_name)
            _add_map_entry(exact_map, exact_ambiguous, raw_key, int(ingredient_id))
            _add_map_entry(normalized_map, normalized_ambiguous, strong_key, int(ingredient_id))

    ambiguous = exact_ambiguous | normalized_ambiguous
    for key in ambiguous:
        exact_map.pop(key, None)
        normalized_map.pop(key, None)
    resolved = dict(normalized_map)
    resolved.update(exact_map)
    return resolved, ambiguous, len(ingredient_rows)


def find_ingredient_id(ingredient_map: dict[str, int], token: str) -> int | None:
    """Resolve um nome legado com match exato/casefold e depois normalizado."""
    raw_key = norm(token).casefold()
    if raw_key in ingredient_map:
        return ingredient_map[raw_key]
    strong_key = normalize_text(token)
    return ingredient_map.get(strong_key)


def _get_source_database(source_conn: psycopg.Connection) -> str:
    with source_conn.cursor() as cur:
        cur.execute("SELECT current_database()")
        return str(cur.fetchone()[0])


def _check_target_ready(target_conn: psycopg.Connection) -> None:
    checks = [
        ("venus.users", "SELECT 1 FROM venus.users LIMIT 1"),
        ("venus.products", "SELECT 1 FROM venus.products LIMIT 1"),
        ("venus.ingredients", "SELECT 1 FROM venus.ingredients LIMIT 1"),
        ("venus_rpa.rpa_run", "SELECT 1 FROM venus_rpa.rpa_run LIMIT 1"),
    ]
    for label, sql in checks:
        try:
            target_conn.execute(sql)
        except Exception as exc:
            raise RuntimeError(
                f"Destino Venus não está pronto: objeto {label} indisponível. "
                "Execute primeiro o pipeline de bootstrap."
            ) from exc


def _get_or_create_brand(target_conn: psycopg.Connection, name: str) -> int:
    with target_conn.cursor() as cur:
        cur.execute(
            "SELECT brand_id FROM venus.brands WHERE name=%s AND country IS NULL "
            "ORDER BY brand_id LIMIT 1",
            (name,),
        )
        row = cur.fetchone()
        if row:
            return int(row[0])

        cur.execute(
            "INSERT INTO venus.brands(name, country) VALUES(%s, NULL) RETURNING brand_id",
            (name,),
        )
        return int(cur.fetchone()[0])


def _get_or_create_category(target_conn: psycopg.Connection, name: str) -> int:
    with target_conn.cursor() as cur:
        cur.execute(
            "SELECT product_category_id FROM venus.product_categories WHERE name=%s",
            (name,),
        )
        row = cur.fetchone()
        if row:
            return int(row[0])

        cur.execute(
            "INSERT INTO venus.product_categories(name, description) "
            "VALUES(%s, %s) RETURNING product_category_id",
            (name, "Categoria importada via RPA."),
        )
        return int(cur.fetchone()[0])


def _upsert_user(target_conn: psycopg.Connection, legacy_id: int, name: str, status: str) -> int:
    with target_conn.cursor() as cur:
        cur.execute(
            """
            INSERT INTO venus.users(firebase_uid, name, status)
            VALUES(%s, %s, %s::venus.user_status_enum)
            ON CONFLICT(firebase_uid)
            DO UPDATE SET
                name = EXCLUDED.name,
                status = EXCLUDED.status,
                updated_at = NOW()
            RETURNING user_id
            """,
            (f"legacy-{legacy_id}", name, status),
        )
        return int(cur.fetchone()[0])


def _upsert_product(
    target_conn: psycopg.Connection,
    legacy_id: int,
    name: str,
    brand: str,
    category: str,
    ingredient_tokens: list[str],
) -> tuple[int, int]:
    brand_id = _get_or_create_brand(target_conn, brand)
    category_id = _get_or_create_category(target_conn, category)
    slug = f"{slugify(name)}-legacy-{legacy_id}"

    with target_conn.cursor() as cur:
        cur.execute(
            """
            INSERT INTO venus.products(
                fk_brand_id, fk_product_category_id, name, description, slug, is_active
            )
            VALUES(%s, %s, %s, %s, %s, TRUE)
            ON CONFLICT(slug)
            DO UPDATE SET
                fk_brand_id = EXCLUDED.fk_brand_id,
                fk_product_category_id = EXCLUDED.fk_product_category_id,
                name = EXCLUDED.name,
                description = EXCLUDED.description,
                is_active = TRUE,
                updated_at = NOW()
            RETURNING product_id
            """,
            (
                brand_id,
                category_id,
                name,
                "Importado do banco legado via RPA.",
                slug,
            ),
        )
        product_id = int(cur.fetchone()[0])

        formula_basis = "|".join(normalize_text(t) for t in ingredient_tokens) or normalize_text(name)
        formula_signature = hashlib.sha256(formula_basis.encode("utf-8")).hexdigest()[:40]

        cur.execute(
            """
            INSERT INTO venus.product_versions(
                fk_product_id,
                version_name,
                display_name,
                status,
                is_current,
                formula_signature,
                detected_by
            )
            VALUES(%s, 'legacy-rpa', %s, 'verified'::venus.version_status_enum, TRUE,
                   %s, 'import'::venus.source_type_enum)
            ON CONFLICT(fk_product_id, formula_signature)
            DO UPDATE SET
                display_name = EXCLUDED.display_name,
                status = EXCLUDED.status,
                is_current = TRUE,
                detected_by = EXCLUDED.detected_by,
                updated_at = NOW()
            RETURNING product_version_id
            """,
            (product_id, name, formula_signature),
        )
        version_id = int(cur.fetchone()[0])

    return product_id, version_id


def _insert_stage_user(
    target_conn: psycopg.Connection,
    batch: uuid.UUID,
    row: Mapping[str, Any],
    normalized_name: str,
    normalized_email: str,
    status_normalized: str,
    validation_status: str,
    validation_message: str | None,
    loaded_user_id: int | None,
) -> None:
    target_conn.execute(
        """
        INSERT INTO venus_rpa.rpa_stage_user(
            batch_id, legacy_user_id, full_name, email, status_text,
            normalized_name, normalized_email, status_normalized,
            validation_status, validation_message, loaded_user_id
        )
        VALUES(%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
        ON CONFLICT(batch_id, legacy_user_id) DO UPDATE SET
            full_name = EXCLUDED.full_name,
            email = EXCLUDED.email,
            status_text = EXCLUDED.status_text,
            normalized_name = EXCLUDED.normalized_name,
            normalized_email = EXCLUDED.normalized_email,
            status_normalized = EXCLUDED.status_normalized,
            validation_status = EXCLUDED.validation_status,
            validation_message = EXCLUDED.validation_message,
            loaded_user_id = EXCLUDED.loaded_user_id
        """,
        (
            batch,
            int(row["legacy_user_id"]),
            row.get("full_name"),
            row.get("email"),
            row.get("status_text"),
            normalized_name,
            normalized_email,
            status_normalized,
            validation_status,
            validation_message,
            loaded_user_id,
        ),
    )


def _insert_stage_product(
    target_conn: psycopg.Connection,
    batch: uuid.UUID,
    row: Mapping[str, Any],
    normalized_name: str,
    normalized_brand: str,
    normalized_category: str,
    validation_status: str,
    validation_message: str | None,
    loaded_product_id: int | None,
) -> None:
    target_conn.execute(
        """
        INSERT INTO venus_rpa.rpa_stage_product(
            batch_id, legacy_product_id, product_name, brand_name, category_name,
            ingredients_text, normalized_product_name, normalized_brand_name,
            normalized_category_name, validation_status, validation_message,
            loaded_product_id
        )
        VALUES(%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
        ON CONFLICT(batch_id, legacy_product_id) DO UPDATE SET
            product_name = EXCLUDED.product_name,
            brand_name = EXCLUDED.brand_name,
            category_name = EXCLUDED.category_name,
            ingredients_text = EXCLUDED.ingredients_text,
            normalized_product_name = EXCLUDED.normalized_product_name,
            normalized_brand_name = EXCLUDED.normalized_brand_name,
            normalized_category_name = EXCLUDED.normalized_category_name,
            validation_status = EXCLUDED.validation_status,
            validation_message = EXCLUDED.validation_message,
            loaded_product_id = EXCLUDED.loaded_product_id
        """,
        (
            batch,
            int(row["legacy_product_id"]),
            row.get("product_name"),
            row.get("brand_name"),
            row.get("category_name"),
            row.get("ingredients_text"),
            normalized_name,
            normalized_brand,
            normalized_category,
            validation_status,
            validation_message,
            loaded_product_id,
        ),
    )


def _insert_rpa_error(
    target_conn: psycopg.Connection,
    batch: uuid.UUID,
    source_table: str,
    legacy_id: int | None,
    error_type: str,
    error_message: str,
    payload: Any,
) -> None:
    target_conn.execute(
        """
        INSERT INTO venus_rpa.rpa_error(
            batch_id, source_table, legacy_id, error_type, error_message, payload
        )
        VALUES(%s,%s,%s,%s,%s,%s)
        """,
        (
            batch,
            source_table,
            legacy_id,
            error_type,
            error_message,
            _json_payload(payload),
        ),
    )


def run_rpa(
    target_conn: psycopg.Connection,
    legacy_url: str,
    products_query: str | None = None,
    users_query: str | None = None,
) -> dict[str, Any]:
    """Extrai do legado e carrega no Venus com controle de batch e falhas por registro."""
    if not legacy_url:
        raise ValueError("LEGACY_DATABASE_URL é obrigatório para o RPA")

    products_query = products_query or DEFAULT_PRODUCTS_QUERY
    users_query = users_query or DEFAULT_USERS_QUERY
    batch = uuid.uuid4()
    source = psycopg.connect(legacy_url)

    try:
        source.execute("SET application_name='venus_rpa_source'")
        target_conn.execute("SET application_name='venus_rpa_etl'")
        _check_target_ready(target_conn)

        with source.cursor() as cur:
            cur.execute(products_query)
            product_columns = _cols(cur)
            _require_columns(product_columns, REQUIRED_PRODUCT_COLUMNS, "LEGACY_PRODUCTS_QUERY")
            products = [dict(zip(product_columns, row)) for row in cur.fetchall()]

            cur.execute(users_query)
            user_columns = _cols(cur)
            _require_columns(user_columns, REQUIRED_USER_COLUMNS, "LEGACY_USERS_QUERY")
            users = [dict(zip(user_columns, row)) for row in cur.fetchall()]

        source_database = _get_source_database(source)

        target_conn.execute(
            """
            INSERT INTO venus_rpa.rpa_run(
                batch_id, status, source_database,
                source_products_query_hash, source_users_query_hash
            )
            VALUES(%s,'RUNNING',%s,%s,%s)
            """,
            (batch, source_database, qhash(products_query), qhash(users_query)),
        )
        ingredient_map, ambiguous_ingredient_keys, ingredient_count = load_ingredient_map(target_conn)

        read = len(products) + len(users)
        transformed = 0
        loaded = 0
        failed = 0
        warnings = 0
        for row in users:
            legacy_id = int(row["legacy_user_id"])
            normalized_name = norm(row.get("full_name"))
            normalized_email = norm(row.get("email")).lower()
            status_normalized = STATUS_MAP.get(norm(row.get("status_text")).lower(), "pending")
            valid = bool(normalized_name and EMAIL_RE.match(normalized_email))
            message = None if valid else "Nome/email inválido; registro não carregado."
            loaded_user_id = None

            try:
                with target_conn.transaction():
                    if valid:
                        loaded_user_id = _upsert_user(
                            target_conn, legacy_id, normalized_name, status_normalized
                        )
                        loaded += 1

                    _insert_stage_user(
                        target_conn,
                        batch,
                        row,
                        normalized_name,
                        normalized_email,
                        status_normalized,
                        "VALID" if valid else "INVALID",
                        message,
                        loaded_user_id,
                    )

                    if not valid:
                        _insert_rpa_error(
                            target_conn,
                            batch,
                            "legacy_users",
                            legacy_id,
                            "VALIDATION",
                            message or "Registro inválido",
                            row,
                        )
                        failed += 1
                transformed += 1
            except Exception as exc:
                failed += 1
                transformed += 1
                message = f"Falha ao carregar usuário: {exc}"
                _insert_rpa_error(target_conn, batch, "legacy_users", legacy_id, "LOAD_ERROR", message, row)
        for row in products:
            legacy_id = int(row["legacy_product_id"])
            name = norm(row.get("product_name"))
            brand = norm(row.get("brand_name"))
            category = norm(row.get("category_name"))
            ingredient_tokens = _split_ingredients(row.get("ingredients_text"))
            basic_valid = bool(name and brand and category)
            loaded_product_id = None
            ingredient_missing: list[str] = []
            ingredient_inserted = 0

            try:
                with target_conn.transaction():
                    if not basic_valid:
                        validation_message = "Nome, marca ou categoria ausente."
                        validation_status = "INVALID"
                        _insert_stage_product(
                            target_conn,
                            batch,
                            row,
                            name,
                            brand,
                            category,
                            validation_status,
                            validation_message,
                            None,
                        )
                        _insert_rpa_error(
                            target_conn,
                            batch,
                            "legacy_products",
                            legacy_id,
                            "VALIDATION",
                            validation_message,
                            row,
                        )
                        failed += 1
                    else:
                        loaded_product_id, version_id = _upsert_product(
                            target_conn,
                            legacy_id,
                            name,
                            brand,
                            category,
                            ingredient_tokens,
                        )
                        position = 0
                        for token in ingredient_tokens:
                            position += 1
                            ingredient_id = find_ingredient_id(ingredient_map, token)
                            if ingredient_id is None:
                                ingredient_missing.append(token)
                                continue

                            target_conn.execute(
                                """
                                INSERT INTO venus.product_ingredients(
                                    fk_product_version_id, fk_ingredient_id, position
                                )
                                VALUES(%s,%s,%s)
                                ON CONFLICT DO NOTHING
                                """,
                                (version_id, ingredient_id, position),
                            )
                            ingredient_inserted += 1

                        if ingredient_missing:
                            warnings += 1
                            for token in ingredient_missing:
                                err_msg = f"Ingrediente legado não encontrado: {token}"
                                error_type = (
                                    "INGREDIENT_AMBIGUOUS"
                                    if normalize_text(token) in ambiguous_ingredient_keys
                                    else "INGREDIENT_NOT_FOUND"
                                )
                                _insert_rpa_error(
                                    target_conn,
                                    batch,
                                    "legacy_products",
                                    legacy_id,
                                    error_type,
                                    err_msg,
                                    {"ingredient": token},
                                )
                                failed += 1

                        validation_status = "WARNING" if ingredient_missing else "VALID"
                        validation_message = (
                            f"{len(ingredient_missing)} ingrediente(s) não resolvido(s); "
                            f"{ingredient_inserted} vínculo(s) criado(s)."
                            if ingredient_missing
                            else f"{ingredient_inserted} vínculo(s) de ingrediente criado(s)."
                        )
                        _insert_stage_product(
                            target_conn,
                            batch,
                            row,
                            name,
                            brand,
                            category,
                            validation_status,
                            validation_message,
                            loaded_product_id,
                        )
                        loaded += 1

                transformed += 1
            except Exception as exc:
                failed += 1
                transformed += 1
                error_message = f"Falha ao carregar produto: {exc}"
                _insert_rpa_error(
                    target_conn,
                    batch,
                    "legacy_products",
                    legacy_id,
                    "LOAD_ERROR",
                    error_message,
                    row,
                )
                _insert_stage_product(
                    target_conn,
                    batch,
                    row,
                    name,
                    brand,
                    category,
                    "INVALID",
                    error_message,
                    None,
                )

        final_status = "SUCCESS" if failed == 0 else ("PARTIAL" if loaded else "FAILED")
        target_conn.execute(
            """
            UPDATE venus_rpa.rpa_run
            SET finished_at=NOW(),
                status=%s,
                records_read=%s,
                records_transformed=%s,
                records_loaded=%s,
                records_failed=%s,
                error_message=%s
            WHERE batch_id=%s
            """,
            (
                final_status,
                read,
                transformed,
                loaded,
                failed,
                (
                    f"{warnings} produto(s) com ingredientes não resolvidos. "
                    f"Catálogo carregado: {ingredient_count} ingredientes."
                    if warnings
                    else None
                ),
                batch,
            ),
        )

        return {
            "batch_id": str(batch),
            "status": final_status,
            "source_database": source_database,
            "records_read": read,
            "records_transformed": transformed,
            "records_loaded": loaded,
            "records_failed": failed,
            "products_with_warnings": warnings,
            "ingredient_catalog_loaded": ingredient_count,
        }

    except Exception:
        raise
    finally:
        source.close()


def main() -> int:
    parser = argparse.ArgumentParser(
        description="VENUS RPA: banco legado externo -> banco Venus"
    )
    parser.add_argument("--database-url", default=os.getenv("DATABASE_URL"))
    parser.add_argument("--legacy-database-url", default=os.getenv("LEGACY_DATABASE_URL"))
    parser.add_argument("--legacy-products-query", default=os.getenv("LEGACY_PRODUCTS_QUERY"))
    parser.add_argument("--legacy-users-query", default=os.getenv("LEGACY_USERS_QUERY"))
    args = parser.parse_args()

    if not args.database_url:
        raise SystemExit("Defina DATABASE_URL no .env (ou passe --database-url).")
    if not args.legacy_database_url:
        raise SystemExit(
            "Defina LEGACY_DATABASE_URL no .env (ou passe --legacy-database-url)."
        )

    with psycopg.connect(args.database_url) as target_conn:
        with target_conn.transaction():
            result = run_rpa(
                target_conn,
                args.legacy_database_url,
                args.legacy_products_query,
                args.legacy_users_query,
            )
        print(json.dumps(result, ensure_ascii=False, indent=2))

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
