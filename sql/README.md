# PostgreSQL / SQL

## Papel

O PostgreSQL é a fonte operacional do Venus. O bootstrap cria e mantém os
schemas `venus`, `venus_audit`, `venus_bi`, `venus_rpa` e
`venus_optimization`. As alterações incrementais ficam em `migrations/`.

## Ordem de leitura do código

| Arquivo | Responsabilidade |
|---|---|
| [`00_schema.sql`](00_schema.sql) | Schemas, enums, tabelas principais, FKs, funções e auditoria. |
| [`05_cloudinary_images.sql`](05_cloudinary_images.sql) | Registro de metadados de imagens. |
| [`10_reference_seed.sql`](10_reference_seed.sql) e `20_*` | Dados mestres e regulação. |
| [`30_demo_seed.sql`](30_demo_seed.sql) | Massa demonstrativa opcional. |
| [`40_data_catalog.sql`](40_data_catalog.sql) | Catálogo técnico. |
| [`45_advanced_structures.sql`](45_advanced_structures.sql) e `migrations/` | Estruturas incrementais e regras de prontidão. |
| [`50_bi.sql`](50_bi.sql) | Dimensões, fatos e views analíticas. |
| [`55_optimization.sql`](55_optimization.sql) | Espaço reservado para otimização. |
| [`60_rpa.sql`](60_rpa.sql) | Execução, staging e erros da carga do legado. |
| [`99_validation.sql`](99_validation.sql) | Validações estruturais. |
| [`rpa_queries.example.sql`](rpa_queries.example.sql) | Exemplo de consultas somente leitura do legado externo. |

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
está em [`../docs/database-logical-model.md`](../docs/database-logical-model.md).
A fonte editável do diagrama está em
[`../docs/modelos lógicos/`](<../docs/modelos lógicos/>).

## Regras para alterações

1. Não editar o snapshot gerado manualmente.
2. Alterar o schema inicial ou criar migration idempotente.
3. Aplicar em QA e executar a validação.
4. Regenerar o snapshot com `python ops/generate_database_model.py`.
5. Atualizar o modelo brModelo quando a estrutura lógica mudar.
