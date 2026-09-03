# 07 — Como foi gerado o SQL de ~240 mil linhas

## O arquivo

`data/venus_v12_load.sql`

Métricas reais do artefato:

- **246.980 linhas**;
- **246.978 INSERTs**;
- 26.045 INSERTs em `ingredients`;
- 139.402 em `ingredient_properties`;
- 75.230 em `ingredient_aliases`;
- 5.842 em `ingredient_effects`;
- 458 em `ingredient_regulations`.

## Construção conceitual

A geração ocorreu depois que os dados foram reconciliados em memória. Cada ingrediente foi materializado juntamente com suas relações e evidências.

O parser histórico preservado em:

`../../../../venus_pipeline_banco_unico/venus_load_repair_v12/venus_sql_parser.py`

faz o trabalho inverso: lê o SQL como texto, reconstrói os objetos de dados sem executar os INSERTs e permite que a política de limpeza opere antes da carga final.

## Por que gerar SQL em vez de inserir diretamente

O SQL grande funcionou como um **artefato intermediário auditável**:

- permite inspeção;
- tem hash reprodutível;
- pode ser versionado/comprimido;
- separa construção de dados e carga no PostgreSQL;
- permite validar sem modificar o banco.

## O que não deve acontecer

Não se deve "limpar" o arquivo de 240 mil linhas com substituições cegas de texto. A limpeza precisa entender a estrutura de cada tabela e a dependência por `ingredient_id`/INCI.

## Ver também

- `06_limpeza/README.md` — critério de retenção aplicado sobre este SQL bruto.
- `08_qa_evidencias/README.md` — evidências de QA geradas sobre este arquivo.
- `../../../README.md` — como `pipeline.py` consome `data/venus_v12_load.sql` no bootstrap.
