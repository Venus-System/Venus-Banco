# Operação do Venus-Banco

## Pré-requisitos

- Python compatível com `requirements.txt`.
- PostgreSQL acessível por `DATABASE_URL`.
- `pg_dump` e `pg_restore` apenas para backup, restauração ou reconstrução.
- `LEGACY_DATABASE_URL` e queries de extração somente quando o RPA for usado.

## Instalação e execução

```bash
python -m pip install -r requirements.txt
cp .env.example .env
python pipeline.py --skip-rpa
```

No PowerShell, use `Copy-Item .env.example .env` no lugar de `cp`.

Para executar a extração do legado, configure `LEGACY_DATABASE_URL`,
`LEGACY_PRODUCTS_QUERY` e `LEGACY_USERS_QUERY` e execute `python pipeline.py`.
O banco legado é externo; o pipeline não o cria nem o popula.

## Validações seguras

```bash
python diagnostico_postgres.py
python ops/generate_database_model.py
```

O gerador consulta somente o catálogo PostgreSQL e atualiza os artefatos em
`docs/database-logical-model.*`. Para validação estrutural adicional, execute
`sql/99_validation.sql` em uma sessão controlada.

No ambiente de QA usado para esta documentação, a leitura `READ ONLY` confirmou
65 tabelas físicas, 79 FKs e 51 views/materialized views. A contagem detalhada
fica em [`database-logical-model.md`](database-logical-model.md).

## Operações destrutivas

`--reset`, `--rebuild-preserve-data-except-audit` e restaurações com
`pg_restore --clean` podem remover objetos ou dados. Faça backup antes e siga
[`BACKUP_RECOVERY.md`](BACKUP_RECOVERY.md). Não execute essas operações
contra o banco real sem aprovação explícita e janela de manutenção.

## Manutenção da documentação

1. Altere o SQL ou a migration que define o contrato.
2. Valide a mudança no PostgreSQL de QA.
3. Regenere `docs/database-logical-model.*`.
4. Atualize [`ARQUITETURA.md`](ARQUITETURA.md) apenas quando o fluxo ou a
   responsabilidade de uma camada mudar.
5. Atualize o README da tecnologia afetada em `arquitetura-dados/`.
