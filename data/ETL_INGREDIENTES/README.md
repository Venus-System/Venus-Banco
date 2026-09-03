# ETL dos ingredientes Venus — da fonte bruta ao catálogo limpo

Esta pasta documenta o trabalho mais importante do banco Venus: como a base bruta de ingredientes foi transformada em um conjunto confiável para o PostgreSQL.

## Objetivo

Preservar a rastreabilidade completa:

`fontes externas -> ingestão -> enriquecimento -> normalização -> deduplicação -> validação -> geração do SQL de carga -> limpeza por evidência -> carga final no schema venus`

O artefato central é `../../data/venus_v12_load.sql`, um arquivo de **246.980 linhas** contendo **246.978 INSERTs**. Ele representa a carga bruta reconstruída que serviu de matéria-prima para a limpeza.

## Resultado histórico validado

Na execução documentada em 13/08/2026:

- 26.045 ingredientes reconstruídos;
- 139.402 propriedades;
- 75.230 aliases;
- 5.842 efeitos;
- 458 vínculos regulatórios;
- 7.923 ingredientes mantidos pela política `standard`;
- 18.122 removidos antes de qualquer INSERT no banco final;
- 16.879 correções de `common_name` usando tradução ANVISA;
- 45 reconstruções conservadoras pelo INCI;
- 1 caso sem solução automática.

Esses números vêm dos artefatos de QA presentes em `08_qa_evidencias/` e dos scripts históricos originais preservados no ZIP entregue pelo projeto.

## Importante sobre reprodutibilidade

A planilha ANVISA está incluída nesta pasta. O arquivo bruto de carga também está incluído no pacote.

Para reconstruir a cadeia **do zero**, é necessário obter novamente as fontes externas usadas na época, em especial os dados regulatórios europeus e as respostas da API PubChem. O pacote não contém um dump completo do CosIng nem um cache integral das respostas PubChem; portanto, esta documentação separa claramente o que é artefato preservado do que precisa ser reobtido.

## Ordem de leitura

1. `01_fontes/README.md`
2. `02_ingestao_anvisa/README.md`
3. `03_cosing_ue/README.md`
4. `04_pubchem/README.md`
5. `05_normalizacao/README.md`
6. `06_limpeza/README.md`
7. `07_geracao_sql/README.md`
8. `08_qa_evidencias/README.md`
9. `09_reproducao/README.md`

Depois, leia `../../README.md` para entender como a carga limpa entra no bootstrap do PostgreSQL.

## Glossário rápido

- **INCI**: nomenclatura internacional padronizada de ingredientes cosméticos; chave de identidade principal usada nesta cadeia.
- **CAS**: número de registro químico (Chemical Abstracts Service); evidência auxiliar de identidade química.
- **ANVISA**: fonte da tradução oficial pt-BR do INCI.
- **CosIng/EUR-Lex**: base regulatória europeia usada como evidência de função/uso cosmético.
- **PubChem**: base de dados química pública, usada para enriquecimento e confirmação de identidade via CAS.
- **Política `standard`**: critério de retenção por união de evidências (categoria, função histórica, efeitos ou regulação).
- **Política `strict`**: variante mais conservadora, que remove também a evidência histórica isolada.
- **Snapshot limpo**: conjunto final de ingredientes aprovados para carga no banco Venus, após aplicar a política de limpeza.

## Onde cada etapa é executada no pipeline atual

A leitura desta pasta é histórica/documental — descreve como o arquivo `../../data/venus_v12_load.sql` foi construído. A execução em tempo real, no pipeline unificado, corresponde principalmente a:

- leitura e parsing do arquivo bruto: `pipeline.py` (funções de parsing do SQL de carga);
- diagnóstico/reparo de nomes e decisão de política: `pipeline.py` (etapa de limpeza, equivalente às etapas 05/06 desta documentação);
- carga transacional do snapshot aprovado: `pipeline.py` (etapa final, dentro da transação única do bootstrap).

Não é necessário reexecutar o ETL completo (fases A–F de `09_reproducao/README.md`) para rodar o bootstrap do banco — isso só é necessário para reconstruir o arquivo de carga bruto a partir das fontes originais.
