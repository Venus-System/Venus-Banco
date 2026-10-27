import os
from pathlib import Path

import psycopg
from dotenv import load_dotenv


ROOT = Path(__file__).resolve().parents[1]
load_dotenv(ROOT / ".env")

sql_path = ROOT / "sql" / "migrations" / "20261010_002_ocr_auto_resolution_and_relaxed_gate.sql"
sql = sql_path.read_text(encoding="utf-8")

conn = psycopg.connect(os.environ["DATABASE_URL"], autocommit=False)
try:
    with conn.cursor() as cur:
        cur.execute(sql)
    conn.commit()
    print("ddl_committed", flush=True)
    with conn.cursor() as cur:
        cur.execute("CALL venus.sp_resolve_all_current_product_labels()")
    conn.commit()
    print("ocr_resolution_committed", flush=True)
    with conn.cursor() as cur:
        cur.execute("SELECT current_database(), (SELECT COUNT(*) FROM venus.product_scores)")
        print(cur.fetchone())
except Exception:
    conn.rollback()
    raise
finally:
    conn.close()
