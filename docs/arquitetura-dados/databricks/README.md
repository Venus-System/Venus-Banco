# Databricks / camada analítica

## Contrato de dados

O repositório implementa a camada analítica em SQL, no schema `venus_bi`. O
arquivo [`sql/50_bi.sql`](../../../sql/50_bi.sql) cria dimensões, fatos e views
de KPI/ranking. O PostgreSQL de QA confirmou que não há tabelas físicas em
`venus_bi`; as estruturas são views derivadas.

Principais grupos:

- dimensões: `dim_date`, `dim_brand`, `dim_product`, `dim_product_version`,
  `dim_ingredient`, `dim_user`, `dim_claim`, `dim_regulation` e outras;
- fatos: `fact_product_score`, `fact_product_ingredient`,
  `fact_ingredient_effect`, `fact_analysis_result`,
  `fact_personalized_score`, `fact_recommendation`, `fact_review`,
  `fact_packaging` e `fact_product_claim`;
- análises: `vw_product_overview`, `vw_ingredient_overview`, KPIs, rankings,
  janelas temporais e status de requisitos SQL.

## Databricks

Não há notebooks, jobs, Unity Catalog, credenciais ou configuração de conexão
Databricks neste repositório. Portanto, a integração Databricks é uma fronteira
de consumo documentada, não uma implementação comprovada aqui.

O consumidor deve ler as views por uma conexão somente leitura, registrar a
versão/horário do snapshot e evitar escrever de volta em `venus` ou `venus_bi`.
Caso seja criado um pipeline de ingestão no Databricks, ele deve ser
versionado junto com seu catálogo, modo de atualização, watermark e política de
reprocessamento.
