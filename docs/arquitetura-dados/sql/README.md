# PostgreSQL / SQL

## Papel

O PostgreSQL é a fonte operacional do Venus. O bootstrap cria e mantém os
schemas `venus`, `venus_audit`, `venus_bi`, `venus_rpa` e
`venus_optimization`. As alterações incrementais ficam em `sql/migrations/`.

## Ordem de leitura do código

| Arquivo | Responsabilidade |
|---|---|
| [`sql/00_schema.sql`](../../../sql/00_schema.sql) | Schemas, enums, tabelas principais, FKs, funções e auditoria. |
| [`sql/05_cloudinary_images.sql`](../../../sql/05_cloudinary_images.sql) | Registro de metadados de imagens. |
| [`sql/10_reference_seed.sql`](../../../sql/10_reference_seed.sql) e `20_*` | Dados mestres e regulação. |
| [`sql/30_demo_seed.sql`](../../../sql/30_demo_seed.sql) | Massa demonstrativa opcional. |
| [`sql/40_data_catalog.sql`](../../../sql/40_data_catalog.sql) | Catálogo técnico. |
| [`sql/45_advanced_structures.sql`](../../../sql/45_advanced_structures.sql) e migrations | Estruturas incrementais e regras de prontidão. |
| [`sql/50_bi.sql`](../../../sql/50_bi.sql) | Dimensões, fatos e views analíticas. |
| [`sql/55_optimization.sql`](../../../sql/55_optimization.sql) | Espaço reservado para otimização. |
| [`sql/60_rpa.sql`](../../../sql/60_rpa.sql) | Execução, staging e erros da carga do legado. |
| [`sql/99_validation.sql`](../../../sql/99_validation.sql) | Validações estruturais. |

## Estado real validado

Consulta realizada em 26/10/2026 em transação PostgreSQL `READ ONLY`:

- banco: `Venus-qa`;
- PostgreSQL: `17.11`;
- schemas com tabelas: `venus` (59), `venus_audit` (1), `venus_rpa` (4) e
  `venus_optimization` (1);
- total: **65 tabelas físicas**;
- total: **79 FKs**;
- total: **51 views/materialized views** considerando os schemas documentados;
- `venus_bi` não possui tabelas físicas: é uma camada de views.

O relatório completo de campos, tipos, nulabilidade, constraints e cardinalidade
está em [`database-logical-model.md`](../../database-logical-model.md). A fonte
editável do diagrama está em [`modelos lógicos/`](<../../modelos lógicos/>).

## Regras para alterações

1. Não editar o snapshot gerado manualmente.
2. Alterar o schema inicial ou criar migration idempotente.
3. Aplicar em QA e executar a validação.
4. Regenerar o snapshot com `python ops/generate_database_model.py`.
5. Atualizar o modelo brModelo quando a estrutura lógica mudar.
