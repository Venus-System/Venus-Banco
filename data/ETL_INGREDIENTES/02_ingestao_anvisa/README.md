# 02 — Ingestão da ANVISA

## O que foi feito

A planilha ANVISA foi lida e transformada em registros canônicos de ingrediente. O identificador principal para reconciliação é o `INCI NAME`, com o CAS sendo usado como evidência auxiliar quando disponível.

A ingestão precisa:

1. normalizar Unicode e espaços;
2. tratar `null`, strings vazias e valores inválidos;
3. preservar o texto da tradução ANVISA como evidência, sem sobrescrevê-lo com heurísticas;
4. consolidar duplicidades do mesmo INCI;
5. preparar a estrutura para enriquecimento e carga no PostgreSQL.

## Resultado

A reconstrução final resultou em **26.045 ingredientes**.

Esses registros foram materializados no arquivo bruto de carga `data/venus_v12_load.sql` juntamente com suas tabelas filhas.

## Ponto importante

A ANVISA fornece principalmente a camada de nomenclatura/tradução. A presença na planilha não foi usada, sozinha, como prova de que o ingrediente deveria permanecer no catálogo final da aplicação. Essa distinção foi decisiva para chegar ao conjunto limpo de aproximadamente 7,9 mil ingredientes.

## Ver também

- `01_fontes/README.md` — origem e formato da planilha ANVISA.
- `05_normalizacao/README.md` — como os 26.045 registros foram separados em `ingredients` e suas tabelas filhas.
- `06_limpeza/README.md` — critério que reduziu os 26.045 candidatos ao catálogo final.
