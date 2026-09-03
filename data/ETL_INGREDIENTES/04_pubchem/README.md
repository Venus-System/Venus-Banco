# 04 — PubChem API

## Objetivo

A API do PubChem foi usada como camada de enriquecimento/identificação química, principalmente a partir do **CAS**. O resultado esperado é obter propriedades canônicas que ajudam a confirmar que o registro ANVISA/INCI e o composto químico apontam para a mesma entidade.

No SQL de carga final, as referências PubChem seguem o padrão PUG REST, por exemplo:

`https://pubchem.ncbi.nlm.nih.gov/rest/pug/compound/identifier/{CAS}/property/Title,MolecularFormula,MolecularWeight,CanonicalSMILES,IsomericSMILES,InChI,InChIKey/JSON?identifier_type=CAS`

## Dados enriquecidos

O conjunto de propriedades usado pelo Venus inclui campos como:

- CAS;
- título químico;
- fórmula molecular;
- massa molecular;
- Canonical SMILES;
- Isomeric SMILES;
- InChI;
- InChIKey.

O pipeline não deve depender da API em tempo de carga de produção se os dados já estiverem materializados no artefato ETL. A API serve para **construção/atualização da camada de dados**, não para tornar a carga do banco frágil por depender de uma chamada externa para cada linha.

## Estratégia de uso

1. extrair CAS dos candidatos;
2. consultar PubChem em lote/controlando taxa e retries;
3. persistir a resposta bruta ou um cache versionado;
4. normalizar somente os campos necessários;
5. anexar `source_reference` ao registro Venus;
6. tratar ausência de retorno como `sem enriquecimento`, nunca como prova de ausência do ingrediente.

## Tratamento de falhas

Uma falha de rede, timeout ou resposta vazia do PubChem não deve apagar a evidência ANVISA nem descartar automaticamente o ingrediente. O resultado químico é uma camada de enriquecimento.

## Limitação de reprodutibilidade

O ZIP preserva as referências PubChem e o SQL produzido, mas não contém um snapshot integral de todas as respostas da API. Para reproduzir exatamente a construção a partir das fontes externas, deve-se reexecutar essa etapa e registrar a data de consulta e o retorno utilizado.

## Ver também

- `01_fontes/README.md` — princípio de precedência entre ANVISA, UE e PubChem.
- `05_normalizacao/README.md` — onde as propriedades PubChem são persistidas (`ingredient_properties`).
- `09_reproducao/README.md` — Fase A do procedimento de reprodução completo, que inclui a consulta ao PubChem.
