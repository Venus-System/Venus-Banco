# 08 — QA e evidências

Esta pasta preserva os relatórios reais gerados durante a fase mais delicada da preparação dos ingredientes.

## `cleanup_analyze_20260813.json`

Resumo do diagnóstico antes da poda:

- total: 26.045;
- `categorized`: 5.933;
- `historical_function`: 7.396;
- `has_effects`: 4.401;
- `has_regulations`: 0;
- `standard`: 7.923 mantidos / 18.122 removidos.

## `repair_names_summary_20260813.json`

Resultado real do reparo de `common_name`:

- 26.045 examinados;
- 16.879 por tradução ANVISA;
- 45 por reconstrução INCI;
- 9.120 inalterados;
- 1 sem solução.

## `cleanup_validate_20260813.json`

A validação reportou zero órfãos nas quatro tabelas filhas de ingredientes, zero `common_name` vazio, zero espaçamento quebrado e zero caso de nome em inglês com tradução disponível.

## Evidência técnica adicional

A implementação histórica identificou dependências FK em:

- `ingredient_aliases`
- `ingredient_properties`
- `ingredient_effects`
- `ingredient_regulations`
- `product_ingredients`
- `rule_evaluations`

Isso explica por que a poda precisa respeitar a ordem das tabelas e validar bloqueios antes de excluir um ingrediente.

## Índice dos artefatos desta pasta

| Arquivo | Conteúdo |
|---|---|
| `cleanup_analyze_20260813.json` | diagnóstico das evidências antes da poda |
| `repair_names_summary_20260813.json` | resultado do reparo de `common_name` |
| `cleanup_validate_20260813.json` | validação pós-limpeza (órfãos, nomes vazios) |
| `etl_manifest.json` | manifesto da execução do ETL |
| `qa_ingest_report.json` | evidência de QA da ingestão bruta |
| `SQL_INVENTARIO.txt` | inventário de INSERTs por tabela no SQL bruto |

## Ver também

- `06_limpeza/README.md` — interpretação dos números resumidos aqui.
- `09_reproducao/README.md` — Fase D e F, que descrevem como reproduzir este QA.
