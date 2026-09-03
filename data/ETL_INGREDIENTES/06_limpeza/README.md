# 06 — Limpeza e redução para o catálogo Venus

Esta é a etapa mais crítica do projeto.

## Problema 1: `common_name` corrompido

A extração que gerou a carga original quebrou espaços dentro de nomes, por exemplo:

`ABALONE EXTRACT` -> `AB ALONE EXTRA CT`

A correção segura não tenta "adivinhar" português. Ela compara a cadeia sem espaços e usa, quando disponível, a `anvisa_translation` como fonte autoritativa.

Na execução documentada:

- 16.879 correções por tradução ANVISA;
- 45 reconstruções conservadoras pelo INCI;
- 9.120 registros já corretos;
- 1 sem solução automática.

## Problema 2: excesso de ingredientes

Os 26.045 registros não deveriam entrar integralmente no catálogo final. A pergunta correta foi: **há evidência suficiente de que este ingrediente é relevante para uso cosmético no contexto Venus?**

### Evidências consideradas

- categoria funcional diferente de `Não classificado`;
- propriedade `historical_cosmetic_function`;
- efeitos já classificados no domínio Venus;
- vínculos regulatórios.

### Política `standard`

A decisão é uma **união** das evidências:

`categorized OR historical_function OR has_effects OR has_regulations`

Na execução de 13/08/2026:

- manter: **7.923**
- remover: **18.122**

Os 18.122 removidos não foram simplesmente "apagados" de um banco: no pipeline unificado eles podem ser eliminados **antes de qualquer INSERT final**, preservando o banco novo sem resíduos.

## Por que não cruzar tudo por interseção

Exigir que um ingrediente tenha simultaneamente categoria + CosIng + efeito + regulação descartaria dados válidos. A união permite que uma evidência forte, individualmente, seja suficiente para manter o registro.

## Regra de segurança

A heurística de "nome suspeito" nunca deve ser a única justificativa para alterar dados. A alteração automática precisa de uma fonte comprovável, como a tradução ANVISA ou identidade INCI.

## Política alternativa

Existe também `strict`, mais conservadora. Ela reduz o conjunto ainda mais. A política recomendada para o catálogo principal histórico foi `standard`.

## Como acionar no pipeline atual

No pipeline unificado, a política é selecionada pela flag `--policy` (`standard` por padrão, ou `strict`). Ver `../../../README.md`, seção "Referência rápida de flags do `pipeline.py`".

## Ver também

- `05_normalizacao/README.md` — etapa anterior, de normalização e deduplicação.
- `07_geracao_sql/README.md` — como o snapshot limpo se relaciona com o SQL de carga bruto.
- `08_qa_evidencias/README.md` — evidências reais (JSON) por trás dos números citados aqui.
