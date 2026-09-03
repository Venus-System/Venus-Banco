# 05 — Normalização e deduplicação

## Chave de identidade

O `INCI NAME` foi tratado como identificador lógico principal do ingrediente. O CAS foi usado como evidência química auxiliar.

A transformação normaliza:

- Unicode (`NFKC`);
- espaços repetidos;
- bordas do texto;
- valores nulos/placeholder;
- representações equivalentes do mesmo registro.

## Modelo destino

Cada ingrediente fica separado de seus fatos/atributos multivalorados:

- `ingredients`
- `ingredient_properties`
- `ingredient_aliases`
- `ingredient_effects`
- `ingredient_regulations`

Isso evita repetir o ingrediente para cada propriedade, alias, efeito ou regulação.

## Contagens do artefato bruto

O arquivo de carga contém exatamente:

| Estrutura | Registros |
|---|---:|
| ingredients | 26.045 |
| ingredient_properties | 139.402 |
| ingredient_aliases | 75.230 |
| ingredient_effects | 5.842 |
| ingredient_regulations | 458 |

Total dessas cinco estruturas: **247. - aproximadamente 247 mil INSERTs**, correspondendo ao arquivo de 246.978 INSERTs.

## Regra de deduplicação

A carga utiliza `ON CONFLICT` para atualizar/ignorar valores conforme a natureza da tabela. As tabelas filhas usam chaves compostas apropriadas para evitar duplicações sem transformar eventos diferentes em um único fato.

## Ver também

- `02_ingestao_anvisa/README.md` — etapa anterior, de ingestão bruta da ANVISA.
- `06_limpeza/README.md` — próxima etapa, reparo de nomes e redução do catálogo.
- `07_geracao_sql/README.md` — como este modelo normalizado foi materializado em `data/venus_v12_load.sql`.
