# Auditoria e decisões — Venus PostgreSQL

## Mantido
- Modelo canônico em `sql/00_schema.sql`.
- Carga de ingredientes `data/venus_v12_load.sql` com limpeza e resolução de referências no `pipeline.py`.
- Seeds de referência/regulação e massa de demonstração.
- Data Mart/analytics em `sql/50_bi.sql`.
- Catálogo técnico em `sql/40_data_catalog.sql`.

## Removido do runtime
- `venusbackup.sql`, migrations destrutivas e snapshots históricos.
- `product_images`, `scan_sessions`, `routines`, `routine_items` e estruturas específicas desses fluxos antigos.
- RPA demo que criava tabelas representando um legado dentro do próprio banco.

## Implementações acadêmicas acrescentadas
- RPA real: `rpa_migrate.py` + `sql/60_rpa.sql`; o legado deve existir externamente e é lido por `LEGACY_DATABASE_URL`.
- Auditoria com `OLD`, `NEW`, `TG_OP`, `CURRENT_USER` e `application_name`.
- DAU via `venus.user_access_events`, função de registro, triggers e views `v_dau`/`v_dau_rolling_30d`.
- CTE recursiva para a hierarquia de `ingredient_categories`.
- `EXPLAIN (ANALYZE, BUFFERS)` em `sql/55_optimization.sql` associado aos índices do modelo.
- Backup/recovery documentados em `BACKUP_RECOVERY.md` e scripts PowerShell em `ops/`.
- Cardinalidades explícitas em `MODEL_CARDINALIDADES.md`.

## Regra importante do RPA
O pacote não cria, popula ou simula o banco legado. O usuário fornece a conexão real e as consultas de extração do legado, que retornam os aliases canônicos documentados em `rpa_queries.example.sql`.

## Como ler este documento

Esta auditoria resume decisões de escopo tomadas ao consolidar os scripts históricos do Venus em um único pacote reproduzível. Ela deve ser lida junto com:

- `PACKAGE_CHANGELOG_V7.md`, para o histórico cronológico de mudanças por versão;
- `README.md`, para a arquitetura canônica resultante dessas decisões;
- `data/ETL_INGREDIENTES/README.md`, para o detalhamento da decisão de limpeza aplicada aos ingredientes.

## Critério geral de decisão

Uma estrutura, script ou tabela histórica foi mantida no runtime quando atendia a pelo menos um destes critérios:

1. É necessária para o funcionamento atual da aplicação (schema operacional, seeds de referência, BI, RPA).
2. Está associada a uma correção de dados que ainda precisa ser reaplicada em bancos novos (ex.: `venus_fix_fk_e_is_active.sql`).
3. Documenta uma decisão ou evidência que não pode ser reconstruída de outra forma (ex.: artefatos de QA do ETL de ingredientes).

Um item foi removido do runtime quando era puramente histórico/diagnóstico, dependia de estruturas já descontinuadas (como `product_images` e `scan_sessions`), ou representava uma simulação do banco legado dentro do próprio Venus — o que contradiz a regra de que o legado é sempre externo.
