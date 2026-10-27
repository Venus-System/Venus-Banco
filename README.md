# Venus-Banco

Bootstrap e documentação da arquitetura de dados do Venus. O pacote mantém o
PostgreSQL operacional e seus artefatos de carga, auditoria, RPA e BI. As
integrações externas são documentadas com o nível de evidência disponível.

## Leitura recomendada

1. [`docs/README.md`](docs/README.md) — índice da documentação.
2. [`docs/ARQUITETURA.md`](docs/ARQUITETURA.md) — fluxo ponta a ponta, do OCR
   ao consumo das views no Databricks.
3. [`docs/arquitetura-dados/README.md`](docs/arquitetura-dados/README.md) —
   separação por SQL, MongoDB, Neo4j, Redis, OCR, Cloudinary e Databricks.
4. [`docs/database-logical-model.md`](docs/database-logical-model.md) — estado
   físico real do PostgreSQL, incluindo todas as tabelas e relacionamentos.
5. [`docs/OPERACAO.md`](docs/OPERACAO.md) — instalação, execução e validação.

Os scripts e contratos de cada tecnologia ficam agrupados em pastas de primeiro
nível: [`sql/`](sql/), [`mongodb/`](mongodb/), [`neo4j/`](neo4j/),
[`redis/`](redis/), [`databricks/`](databricks/), [`ocr/`](ocr/) e
[`cloudinary/`](cloudinary/).

## Desenho da arquitetura

```mermaid
flowchart LR
    client["Web / Mobile"] --> ocr["OCR e interpretação"]
    client --> media["Cloudinary - binário das imagens"]
    ocr --> scans[("MongoDB - scan_sessions")]
    scans --> review["Revisão administrativa"]
    review --> projection["Projeção aprovada"]

    legacy["Banco legado externo"] --> rpa["venus_rpa - staging e execução"]

    subgraph postgresql["PostgreSQL - Venus"]
        core[("venus - catálogo operacional")]
        audit[("venus_audit - auditoria")]
        bi[("venus_bi - views analíticas")]
    end

    projection --> core
    rpa --> core
    core --> audit
    core --> graph[("Neo4j - grafo derivado")]
    bi --> databricks["Databricks - consumo analítico"]
    core -. "não evidenciado no repo" .-> redis[("Redis")]
    core --> bi
    media -. "metadados" .-> core
```

O PostgreSQL é a fonte operacional depois da aprovação do scan. O MongoDB
preserva o contexto bruto e o workflow de revisão; o Cloudinary mantém os
binários; o Neo4j representa uma projeção derivada; e as views `venus_bi` são
consumidas pelo Databricks. Redis permanece explicitamente como não evidenciado
neste repositório. Para detalhes, consulte
[`docs/ARQUITETURA.md`](docs/ARQUITETURA.md).

## Início rápido

```bash
python -m pip install -r requirements.txt
cp .env.example .env
python pipeline.py --skip-rpa
```

No PowerShell, use `Copy-Item .env.example .env`. Configure `DATABASE_URL`
antes da execução. Para executar o RPA, configure também `LEGACY_DATABASE_URL`,
`LEGACY_PRODUCTS_QUERY` e `LEGACY_USERS_QUERY`; o banco legado permanece
externo e somente leitura.

## O que o pipeline faz

1. cria os schemas controlados do Venus;
2. aplica `sql/` em ordem e as migrations selecionadas;
3. carrega referências, ingredientes e dados opcionais;
4. configura auditoria, RPA, mídia e views BI;
5. valida o estado do banco.

`--reset` e os modos de reconstrução são destrutivos. Leia
[`docs/OPERACAO.md`](docs/OPERACAO.md) e [`docs/BACKUP_RECOVERY.md`](docs/BACKUP_RECOVERY.md)
antes de usá-los.

## Arquitetura SQL

| Camada | Arquivos principais |
|---|---|
| Modelo operacional | [`sql/`](sql/) e `sql/migrations/` |
| Mídia | [`cloudinary/`](cloudinary/) e `cloudinary_service.py` |
| Dados mestres | `sql/10_reference_seed.sql`, `sql/20_regulation_seed.sql` |
| Catálogo técnico | `sql/40_data_catalog.sql` |
| BI | `sql/50_bi.sql` → schema `venus_bi` |
| RPA | `sql/60_rpa.sql` → schema `venus_rpa` |
| Validação | `sql/99_validation.sql` e `diagnostico_postgres.py` |

## Estado validado em QA

Em 26/10/2026, uma transação `READ ONLY` no banco `Venus-qa` confirmou:

- PostgreSQL `17.11`;
- 65 tabelas físicas;
- 79 relacionamentos por FK;
- 51 views/materialized views;
- tabelas nos schemas `venus`, `venus_audit`, `venus_rpa` e
  `venus_optimization`;
- `venus_bi` sem tabelas físicas, somente views analíticas.

Para regenerar o snapshot do catálogo:

```bash
python ops/generate_database_model.py
```

O gerador é somente leitura no banco e atualiza os artefatos em
`docs/database-logical-model.*`.

## Estrutura do repositório

```text
Venus-Banco/
├── sql/                        # PostgreSQL, BI, RPA e migrations
├── mongodb/                    # contrato e scripts de scan_sessions
├── neo4j/                      # cargas, constraints e consultas do grafo
├── redis/                      # status e contrato Redis
├── databricks/                 # contrato de consumo analítico
├── ocr/                        # fluxo de OCR e projeção
├── cloudinary/                 # API, mídia e metadados
├── pipeline.py                 # bootstrap e orquestração
├── rpa_migrate.py              # legado externo -> venus_rpa/venus
├── cloudinary_service.py       # operações backend-only de mídia
├── data/                       # carga e ETL de ingredientes
├── docs/                       # arquitetura transversal e modelos lógicos
└── ops/                        # backup, restore e geração de documentação
```

## Variáveis essenciais

| Variável | Uso |
|---|---|
| `DATABASE_URL` | PostgreSQL do Venus. |
| `LEGACY_DATABASE_URL` | PostgreSQL legado externo, somente leitura no RPA. |
| `LEGACY_PRODUCTS_QUERY` / `LEGACY_USERS_QUERY` | Queries de extração do legado. |
| `CLOUDINARY_CLOUD_NAME` / `CLOUDINARY_API_KEY` / `CLOUDINARY_API_SECRET` | Upload e gestão de imagens; o segredo fica somente no backend. |

Consulte [`.env.example`](.env.example) para a lista completa.
