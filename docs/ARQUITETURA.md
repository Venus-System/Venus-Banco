# Arquitetura de dados do Venus

Este é o documento canônico da arquitetura ponta a ponta. Ele explica como uma
imagem chega ao catálogo, onde cada estado é persistido, como o PostgreSQL
aplica as regras operacionais e como a camada analítica é consumida.

Para navegação por tecnologia, use [`arquitetura-dados/README.md`](arquitetura-dados/README.md).
Para a relação completa de campos, tipos, constraints e FKs, use o
[`snapshot físico do PostgreSQL`](database-logical-model.md).

## Fluxo ponta a ponta

```text
Web / Mobile
    │
    ├── imagem ───────────────────────────────► Cloudinary
    │                                             │ binário
    │                                             ▼
    │                                      venus.media_assets
    │
    └── solicitação OCR ─► OCR / interpretação
                              │
                              ▼
                    MongoDB.scan_sessions
                              │
                              ▼
                    revisão administrativa
                              │ aprovação + idempotency_key
                              ▼
                    projeção para PostgreSQL
                              │
Legado externo ─► venus_rpa ──┴──► venus
                                  │  catálogo, usuários,
                                  │  composição e scoring
                                  ├──► venus_audit
                                  ├──► Neo4j (projeção de grafo)
                                  └──► venus_bi (views)
                                                │
                                                ▼
                                      Databricks / analytics
```

## Responsabilidade por camada

| Camada | Fonte de verdade / responsabilidade | Status no repositório |
|---|---|---|
| Aplicação | Captura imagem, inicia OCR e apresenta resultados. | Interface descrita; código da aplicação não está neste repo. |
| OCR | Extrai texto, qualidade, candidatos e interpretação. | Contrato documentado; worker não está neste repo. |
| Cloudinary | Binário das imagens. | Contrato e SQL de metadados implementados. |
| MongoDB | Documento do scan, revisão e sincronização. | Scripts fornecidos incorporados em `arquitetura-dados/mongodb`. |
| PostgreSQL | Catálogo operacional, integridade, auditoria, RPA e BI. | Implementado e validado em QA. |
| Neo4j | Grafo derivado para compatibilidade e ordem de uso. | Scripts fornecidos; conector não está neste repo. |
| Redis | Cache/fila, se adotado. | Nenhuma implementação evidenciada. |
| Databricks | Consumo analítico das views. | Contrato descrito; notebooks/jobs não estão neste repo. |

## PostgreSQL real validado

A validação foi feita em 26/10/2026 com conexão `READ ONLY` ao banco `Venus-qa`
(PostgreSQL `17.11`). O catálogo confirmou:

| Schema | Tabelas físicas | Papel |
|---|---:|---|
| `venus` | 59 | Núcleo transacional: usuários, produtos, ingredientes, scoring e engajamento. |
| `venus_audit` | 1 | `audit_logs`, histórico de alterações sem FK para o núcleo. |
| `venus_rpa` | 4 | Execuções, staging e erros do legado externo. |
| `venus_optimization` | 1 | `readme`, ponto de extensão para otimização. |
| `venus_bi` | 0 | Views analíticas, sem tabelas físicas. |
| **Total** | **65** | **79 FKs e 51 views/materialized views** |

O inventário completo das 65 tabelas, na ordem do catálogo, está em
[`database-logical-model.md`](database-logical-model.md). O diagrama editável
está em [`modelos lógicos/`](<modelos lógicos/>).

## Ciclo do OCR até o catálogo

1. A imagem é enviada para o armazenamento externo e seus metadados são
   registrados.
2. O OCR grava texto bruto e campos extraídos no documento `scan_sessions`.
3. O resolvedor usa produto, marca, categoria, claims, INCI e aliases para
   gerar candidatos.
4. Casos ambíguos permanecem em revisão; nenhum candidato incerto deve ser
   promovido automaticamente.
5. A projeção aprovada leva composição, status, referências e chave idempotente
   para o PostgreSQL.
6. O PostgreSQL aplica FKs, checks, unicidades e regras de prontidão das
   migrations antes da versão ser considerada utilizável.
7. A composição alimenta efeitos, compatibilidade, análises, scores e
   recomendações.
8. `venus_bi` publica dimensões, fatos, KPIs e rankings para consumo analítico.

Detalhes da fronteira OCR estão em [`arquitetura-dados/ocr/`](<arquitetura-dados/ocr/>).

## RPA do legado

O legado é externo e somente leitura. `rpa_migrate.py` extrai usando as queries
configuradas, grava a execução em `venus_rpa.rpa_run`, mantém staging em
`rpa_stage_product`/`rpa_stage_user`, registra falhas em `rpa_error` e só então
carrega os registros válidos em `venus`.

O pacote não cria nem simula o banco legado. A documentação SQL e as tabelas de
staging estão em [`arquitetura-dados/sql/README.md`](<arquitetura-dados/sql/README.md>).

## BI e Databricks

`sql/50_bi.sql` cria a camada `venus_bi` com dimensões, fatos, visões de
overview, KPIs, rankings e análises temporais. O PostgreSQL é o produtor; o
Databricks é consumidor analítico e não deve escrever de volta na camada
operacional.

Não há notebooks ou jobs Databricks versionados neste repositório. O contrato e
os limites estão em [`arquitetura-dados/databricks/README.md`](<arquitetura-dados/databricks/README.md>).

## Manutenção

- SQL/migrations definem o contrato executável.
- `ops/generate_database_model.py` documenta o catálogo real sem alterá-lo.
- Alterações de tabelas exigem atualizar o brModelo em `modelos lógicos/`.
- Alterações de fluxo exigem atualizar este arquivo e o README da tecnologia.
- Qualquer tecnologia sem código/configuração deve continuar marcada como não
  evidenciada.
