# 03 — CosIng / União Europeia

## Papel desta fonte

A camada europeia foi usada para responder uma pergunta diferente da ANVISA: **há evidência de uso cosmético/função cosmética ou de regulação europeia para este ingrediente?**

No modelo Venus, essa evidência aparece principalmente como propriedades e vínculos que alimentam a decisão de permanência.

## Evidência preservada

O SQL bruto contém referências EUR-Lex e, no conjunto limpo, a propriedade:

`historical_cosmetic_function`

foi usada como uma das evidências de uso cosmético.

Na análise histórica:

- 7.396 ingredientes tinham `historical_cosmetic_function`;
- 5.933 tinham categoria funcional diferente de `Não classificado`;
- 4.401 tinham efeitos classificados no domínio Venus;
- os conjuntos eram combinados por união, e não por interseção.

## Por que a UE não era apenas "mais uma tradução"

A lista ANVISA podia conter substâncias sem evidência de uso cosmético no contexto do catálogo da aplicação. O cruzamento com função/regulação europeia permitiu separar **existência química/regulatória** de **relevância cosmética para o produto Venus**.

## Regra de rastreabilidade

Toda evidência europeia deve ficar acompanhada de `source_reference` apontando para o documento correspondente. O loader não deve converter uma afirmação regulatória em dado "sem fonte".

## Ver também

- `06_limpeza/README.md` — como `historical_cosmetic_function` entra na política `standard` de retenção.
- `08_qa_evidencias/README.md` — contagens reais de ingredientes com evidência europeia.
- `04_pubchem/README.md` — a outra camada de enriquecimento, focada em identidade química.
