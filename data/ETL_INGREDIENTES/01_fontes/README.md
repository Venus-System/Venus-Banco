# 01 — Fontes e contrato de dados

## Fonte principal: ANVISA

Arquivo preservado:

`ANVISA_Base_de_Traducao_2025-03-06.xlsx`

A planilha possui a aba `Tradução`, com aproximadamente 30 mil linhas de vocabulário regulatório/INCI. O cabeçalho útil é:

- INÍCIO DE VIGÊNCIA
- FIM DE VIGÊNCIA
- SITUAÇÃO ATUAL
- Nº CAS
- INCI NAME
- TRADUÇÃO ANVISA

A ANVISA é a fonte de referência para a **tradução pt-BR do INCI**. Essa informação foi fundamental para corrigir o `common_name` que havia sido corrompido durante a extração inicial.

## União de fontes

As referências preservadas no SQL final mostram a combinação de:

- `ANVISA:Base de Tradução INCI`
- atos/documentos da União Europeia publicados no EUR-Lex;
- identificadores e propriedades químicas obtidos do PubChem.

## Princípio de precedência

1. Identidade INCI/CAS: chave química e de reconciliação.
2. ANVISA: tradução pt-BR.
3. UE/CosIng: função cosmética/regulação europeia.
4. PubChem: identificação/enriquecimento químico e confirmação de identidade.
5. O banco Venus: normalização e persistência final.

Não se deve tratar uma heurística textual como fonte autoritativa quando existe uma evidência de referência.

## Ver também

- `02_ingestao_anvisa/README.md` — como a planilha ANVISA foi transformada em registros canônicos.
- `03_cosing_ue/README.md` — papel da evidência europeia na decisão de permanência do ingrediente.
- `04_pubchem/README.md` — enriquecimento químico via CAS.
- `../README.md` — visão geral e ordem de leitura completa da cadeia de ETL.
