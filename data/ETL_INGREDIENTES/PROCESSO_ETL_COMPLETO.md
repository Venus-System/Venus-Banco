# Processo completo — visão executiva para apresentação

O grande desafio do banco Venus não foi criar as tabelas. Foi transformar uma base extensa e heterogênea em um catálogo pequeno, rastreável e útil para a aplicação.

## 1. Começo: a base ANVISA

A planilha oficial de tradução ANVISA forneceu o universo inicial de nomes INCI/CAS e suas traduções para português. Ela tinha cerca de 30 mil linhas úteis e foi usada como ponto de partida para construir os 26.045 ingredientes candidatos.

## 2. Enriquecimento químico: PubChem

Para os ingredientes com CAS, o PubChem serviu para confirmar a identidade química e obter propriedades estruturais. Isso reduziu ambiguidades e possibilitou preservar referências como InChI/InChIKey/SMILES junto ao ingrediente.

## 3. Evidência regulatória/cosmética: UE/CosIng

A camada europeia respondeu à questão que a planilha ANVISA não responde: quais candidatos têm função cosmética ou evidência regulatória relevante para o catálogo? Essa informação virou evidência estruturada no modelo Venus.

## 4. Geração do artefato de carga

Depois da reconciliação, foram produzidos INSERTs para o conjunto de tabelas de ingredientes. O resultado foi um SQL com 246.980 linhas e 246.978 INSERTs.

Esse arquivo não era ainda o catálogo final. Era o **dataset bruto estruturado para QA e limpeza**.

## 5. Descoberta do problema de `common_name`

Uma falha de extração de texto/PDF havia inserido espaços dentro de palavras. Em paralelo, uma tentativa anterior de reparo havia substituído traduções portuguesas válidas por nomes INCI em inglês. A correção final passou a usar a tradução ANVISA como fonte de verdade e só aplicar o fallback INCI quando a identidade fosse segura.

## 6. Descoberta do excesso de registros

Dos 26.045 candidatos, grande parte existia apenas porque aparecia na base de tradução. Isso não significava que fossem necessários para a aplicação cosmética.

Foram então calculadas evidências independentes:

- categoria funcional;
- função cosmética histórica UE;
- efeitos;
- regulações.

A política `standard` preservou a união dessas evidências e chegou a 7.923 ingredientes.

## 7. Limpeza antes da carga final

No desenho definitivo, a poda acontece antes de materializar os registros no banco novo sempre que possível. Assim o PostgreSQL recebe apenas o catálogo aprovado, suas propriedades, aliases, efeitos e vínculos regulatórios.

## 8. Resultado

O resultado é um catálogo significativamente menor, mais limpo e muito mais adequado às consultas da aplicação, sem perder a rastreabilidade das fontes.

## Frase para apresentação

> "Nós não simplesmente importamos uma planilha de ingredientes. Construímos um ETL de reconciliação de identidade química, enriquecemos os registros com fontes regulatórias e PubChem, corrigimos uma corrupção real de nomenclatura, e só então aplicamos uma política de evidência cosmética que reduziu 26.045 candidatos para 7.923 registros justificáveis no catálogo Venus."

## Leitura detalhada

Esta página é a versão executiva da cadeia completa. Para o detalhamento técnico de cada etapa, com números e regras precisas, consulte `README.md` (nesta pasta) e a sequência `01_fontes/` a `09_reproducao/`.
