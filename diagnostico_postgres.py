from pathlib import Path
import os
from dotenv import load_dotenv
import psycopg

ROOT = Path(__file__).resolve().parent
load_dotenv(ROOT / '.env')
url = os.getenv('DATABASE_URL') or os.getenv('QA_DATABASE_URL')
if not url:
    raise SystemExit('DATABASE_URL/QA_DATABASE_URL não encontrada no .env')

conn = psycopg.connect(url, autocommit=True)
try:
    with conn.cursor() as cur:
        cur.execute('''
            SELECT
                current_database(),
                current_user,
                current_schema(),
                inet_server_addr()::text,
                inet_server_port(),
                version()
        ''')
        db, user, schema, host, port, version = cur.fetchone()
        print('=== CONEXÃO REAL USADA PELO PIPELINE ===')
        print(f'database : {db}')
        print(f'user     : {user}')
        print(f'schema   : {schema}')
        print(f'host     : {host}')
        print(f'port     : {port}')
        print(f'version  : {version.splitlines()[0]}')
        print()

        cur.execute("SELECT nspname FROM pg_namespace WHERE nspname LIKE 'venus%' ORDER BY nspname")
        schemas = [r[0] for r in cur.fetchall()]
        print('Schemas Venus encontrados:')
        for s in schemas:
            print('  -', s)
        if not schemas:
            print('  NENHUM schema venus encontrado.')

        for table in ['ingredients', 'products', 'users', 'data_catalog']:
            cur.execute('''
                SELECT EXISTS (
                    SELECT 1 FROM information_schema.tables
                    WHERE table_schema='venus' AND table_name=%s
                )
            ''', (table,))
            exists = cur.fetchone()[0]
            print(f'venus.{table}:', 'EXISTE' if exists else 'NÃO EXISTE')
            if exists:
                cur.execute(f'SELECT COUNT(*) FROM venus.{table}')
                print(f'  linhas: {cur.fetchone()[0]}')
finally:
    conn.close()
