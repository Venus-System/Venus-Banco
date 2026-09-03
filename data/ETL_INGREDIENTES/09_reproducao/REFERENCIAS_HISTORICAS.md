# Referências históricas do processo

Os seguintes artefatos estavam no ZIP original do projeto e foram usados para reconstruir esta documentação:

| Arquivo histórico | Papel |
|---|---|
| `venus_pipeline_banco_unico/.../venus_sql_parser.py` | parser do SQL bruto; reconstrói ingredientes e tabelas filhas sem executar os INSERTs |
| `venus_pipeline_banco_unico/.../venus_pipeline_single_db_clean_load.py` | pipeline de snapshot limpo e carga transacional |
| `venus_pipeline_banco_unico/.../venus_cleanup.py` | análise, reparo de nomes, poda e validação |
| `venus_pipeline_banco_unico/.../qa_loader/repair_common_names.py` | versão anterior do reparo de `common_name`; documentada porque gerou regressões e foi substituída |
| `venus_pipeline_banco_unico/.../load/qa_ingest_report.json` | evidência de QA da ingestão |
| `output/cleanup_analyze.json` | contagens da decisão de limpeza |
| `output/cleanup_validate.json` | evidência da validação pós-limpeza |
| `output/repair_names_20260813T160535Z_summary.json` | contagem real das correções de nomes |

## O que não foi inventado

O ZIP original não contém um script Python separado chamado `pubchem.py` nem um dump completo de CosIng. A evidência do PubChem aparece nas `source_reference` do SQL bruto, enquanto a evidência europeia aparece nas referências EUR-Lex e na propriedade `historical_cosmetic_function`.

Por isso esta pasta documenta a etapa PubChem como parte da cadeia de enriquecimento, mas não apresenta um script histórico que não exista no material fornecido.

## Ver também

- `README.md` (nesta mesma pasta) — procedimento de reprodução que referencia estes artefatos.
- `../08_qa_evidencias/` — versões destes relatórios preservadas no pacote atual.
