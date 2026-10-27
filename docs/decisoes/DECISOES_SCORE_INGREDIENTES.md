# Decisões de score dos ingredientes

## Objetivo deste documento

Este documento registra, em linguagem operacional e técnica, como os quatro
scores armazenados em `venus.ingredients` são definidos, como uma avaliação é
considerada válida, por que o valor `0` não pode ser interpretado
automaticamente como “sem risco” e qual é a diferença entre uma avaliação
direta e uma avaliação indireta.

O objetivo principal é evitar que o banco produza números visualmente
completos, mas cientificamente mal interpretados. Ter quatro números em cada
linha não significa, por si só, que o ingrediente foi estudado nos quatro
eixos. Por isso o catálogo possui uma tabela de assessments, uma metodologia
versionada e um nível de evidência separado do valor numérico.

## Os quatro eixos

### 1. `irritation_risk_level`

Representa o risco relativo de irritação ou sensibilização associado ao
ingrediente, considerando a evidência disponível para o ingrediente isolado.

Nesta escala:

| Valor | Interpretação operacional |
| --- | --- |
| `0` | risco mínimo ou ausência de preocupação relevante em evidência adequada; nunca significa “não pesquisado” |
| `1–2` | preocupação baixa |
| `3–4` | preocupação baixa a moderada |
| `5–6` | preocupação moderada |
| `7–8` | preocupação alta, restrição relevante ou sinal consistente |
| `9–10` | preocupação muito alta, conclusão regulatória severa ou evidência autoritativa crítica |

Quanto maior o número, maior a carga de risco. O score não representa a
probabilidade de uma reação para qualquer pessoa, porque isso depende de
concentração, veículo, área de aplicação, frequência, tempo de contato e
características individuais.

### 2. `comedogenicity_score`

Representa a evidência de potencial de obstrução folicular ou comedogenicidade.

Este é o eixo mais difícil de preencher com fontes regulatórias. Anvisa,
CosIng e ECHA podem ajudar a identificar o ingrediente, a substância e outros
perigos, mas não substituem um estudo direto de comedogenicidade. Por isso,
uma função “emoliente”, um óleo, um éster, uma manteiga, a origem natural ou a
textura percebida não são provas suficientes.

| Valor | Interpretação operacional |
| --- | --- |
| `0` | evidência adequada de ausência de preocupação relevante ou resultado negativo; não pesquisado não é `0` |
| `1–2` | evidência baixa de obstrução |
| `3–4` | sinal leve ou resultado dependente do modelo |
| `5–6` | sinal moderado |
| `7–8` | evidência direta consistente |
| `9–10` | evidência direta forte de obstrução relevante |

O número é uma classificação de evidência de ingrediente, não uma previsão de
acne para o produto inteiro.

### 3. `biodegradability_level`

Representa a facilidade de biodegradação ou de desaparecimento ambiental do
ingrediente.

Este eixo possui uma direção diferente dos outros três. Aqui, quanto maior o
valor, melhor é a propriedade ambiental:

| Valor | Interpretação operacional |
| --- | --- |
| `0` | baixa biodegradabilidade ou persistência alta, quando sustentado por dado; não pesquisado não é `0` |
| `1–2` | persistência alta ou biodegradação muito incerta |
| `3–4` | biodegradação incompleta ou dependente do contexto |
| `5–6` | biodegradação razoável, mas com incerteza |
| `7–8` | biodegradação boa |
| `9–10` | biodegradação rápida ou conclusão autoritativa favorável |

Essa direção foi corrigida na metodologia `v2`. A regra antiga tratava o campo
como uma carga de persistência, o que podia inverter a interpretação no score
final. A migration `20261012_001_score_readiness_policies.sql` converteu os
valores legados e registrou explicitamente `higher_is_better` para este eixo.

Não se deve inferir biodegradabilidade somente porque o ingrediente é vegetal,
natural, mineral ou sintético. Também não se deve inferir persistência apenas
pelo nome químico.

### 4. `environmental_risk_level`

Representa a carga de risco ambiental do ingrediente, com atenção a toxicidade
aquática, persistência, bioacumulação, classificação ambiental e propriedades
PBT/vPvB.

| Valor | Interpretação operacional |
| --- | --- |
| `0` | ausência de perigo ambiental relevante em dados adequados; não pesquisado não é `0` |
| `1–2` | preocupação ambiental baixa |
| `3–4` | preocupação baixa a moderada |
| `5–6` | preocupação moderada |
| `7–8` | preocupação alta ou evidência ambiental relevante |
| `9–10` | toxicidade ambiental muito alta, PBT/vPvB ou conclusão equivalente |

Biodegradabilidade e risco ambiental são relacionados, mas não são o mesmo
eixo. Um ingrediente pode degradar rapidamente e ainda apresentar toxicidade
aquática; também pode ter baixa toxicidade aguda, mas persistir e
bioacumular. Por isso um eixo não pode ser preenchido copiando o outro.

## Por que o zero não é um fallback aceitável

Historicamente, os quatro campos da tabela `ingredients` eram `NOT NULL` e
tinham `DEFAULT 0`. Isso era conveniente para a API, mas criava uma ambiguidade
grave:

```text
0 = risco baixo
0 = ausência de estudo
0 = dado não carregado
0 = score ainda não calculado
```

Esses significados são diferentes. A solução adotada foi manter os campos
legados para compatibilidade com a API, mas usar
`venus.ingredient_risk_assessments` como fonte de auditoria. Um valor só é
tratado como avaliação quando existe uma linha aprovada para a dimensão, com
versão, fonte, nível de evidência e justificativa.

As avaliações indiretas usam o piso `1`, e não `0`, justamente para deixar
claro que “não há risco identificado” não foi concluído. O piso técnico evita
que o produto pareça perfeito por falta de informação.

## Metodologias versionadas

### `v1`

A metodologia `v1` foi a primeira formalização dos quatro eixos. Ela usava a
mesma direção de risco para todos os campos, inclusive biodegradabilidade.
Essa decisão se mostrou inadequada para o consumo do score ambiental, porque
uma biodegradabilidade maior deveria melhorar, e não piorar, o resultado.

A `v1` continua registrada para rastreabilidade histórica, mas está aposentada
como metodologia ativa.

### `v2`

A `v2` é a metodologia ativa. Ela mantém:

- irritação: maior valor, maior risco;
- comedogenicidade: maior valor, maior risco;
- risco ambiental: maior valor, maior risco;
- biodegradabilidade: maior valor, melhor biodegradação.

Todo novo assessment operacional deve usar `assessment_version = 'v2'`.
Avaliações antigas podem continuar no banco para histórico, mas não devem ser
misturadas com a leitura atual sem considerar a direção do eixo.

## Fontes e hierarquia de evidência

### Identidade e nomenclatura

O painel [Tradução INCI da Anvisa](https://www.gov.br/anvisa/pt-br/assuntos/cosmeticos/traducao)
é usado para resolver INCI, tradução para português, CAS quando disponível e
vigência da nomenclatura.

O [CosIng da Comissão Europeia](https://single-market-economy.ec.europa.eu/sectors/cosmetics/cosmetic-ingredient-database_en)
é usado para nomenclatura, funções cosméticas, referências e contexto
regulatório.

Essas fontes são importantes para identificar corretamente a substância, mas
não geram automaticamente quatro scores Venus. A própria Comissão Europeia
informa que o CosIng tem caráter informativo e não determina, isoladamente,
que uma substância esteja aprovada ou seja segura.

### Irritação e sensibilização

Prioridade:

1. opinião final do [SCCS](https://health.ec.europa.eu/scientific-committees/scientific-committee-consumer-safety-sccs/sccs-opinions_en);
2. conclusão regulatória específica da Comissão Europeia ou Anvisa;
3. estudo de irritação/sensibilização identificável e aplicável ao ingrediente;
4. evidência indireta explicitamente marcada como `low` quando não houver dado
   direto.

Uma simples presença no CosIng, uma função cosmética ou ausência de restrição
não é uma conclusão de segurança.

### Comedogenicidade

Prioridade:

1. estudo direto de comedogenicidade;
2. estudo de obstrução folicular ou modelo diretamente relacionado;
3. estudo científico identificável com metodologia e substância claras;
4. proxy `low` somente quando a aplicação foi autorizada e o resultado estiver
   marcado como indireto.

Não é permitido converter “emoliente”, “óleo”, “manteiga”, “éster” ou
“natural” diretamente em score alto.

### Biodegradabilidade

Prioridade:

1. teste padronizado de biodegradação, como OECD;
2. dado de destino ambiental ou persistência em REACH/ECHA;
3. conclusão autoritativa de biodegradabilidade;
4. proxy `low` claramente identificado.

### Risco ambiental

Prioridade:

1. toxicidade aquática específica;
2. classificação ambiental CLP;
3. avaliação PBT/vPvB;
4. dados ambientais ECHA/REACH ou conclusão equivalente;
5. proxy `low` explicitamente identificado.

A [lista PBT/vPvB da ECHA](https://echa.europa.eu/pbt) é uma fonte específica
para esse tipo de evidência, mas a ausência de uma substância na lista não
prova ausência de risco ambiental.

## Avaliação direta versus proxy

### Avaliação direta

É registrada com `evidence_level` `medium`, `high` ou `very_high`, fonte
específica, localizador, justificativa e escopo. O loader
`ops/load_official_ingredient_risk_v2.py` exige esses campos e rejeita linhas
sem evidência suficiente.

### Proxy indireto

Foi autorizado como solução operacional para que o banco não fique com valores
zero e os produtos possam passar pelo pipeline de classificação. A proxy:

- usa uma regra determinística;
- é reproduzível;
- recebe `evidence_level = 'low'`;
- recebe `source_type = 'system'`;
- recebe `assessment_scope = 'ingredient_baseline_indirect_v2'`;
- preserva a justificativa dos sinais usados;
- não deve ser apresentada ao usuário como conclusão toxicológica direta.

O script aplicado foi
`ops/apply_indirect_risk_proxies_v2.py`. Ele só completa ingredientes que
ainda não têm os quatro assessments `v2` aprovados e não substitui uma
avaliação `medium`, `high` ou `very_high` por uma proxy fraca.

## Regra determinística da proxy atual

A proxy atual foi criada na migration
`20261010_009_indirect_risk_assessments_v1.sql` e adaptada para a direção `v2`.
Ela é uma regra de cobertura operacional, não uma conclusão científica.

### Irritação

O cálculo parte de uma base baixa e adiciona sinais como:

- categorias associadas a tensoativos, solventes, conservantes, filtros UV e
  perfumantes;
- padrões de nome químico associados a ácidos, hidróxidos, sulfatos,
  surfactantes, retinoides, álcool desnaturado e peróxidos;
- fragrâncias e alérgenos de fragrância;
- efeitos de alerta, risco ou contraindicação;
- restrição regulatória capturada no catálogo.

O resultado é limitado ao intervalo `1..10`.

### Comedogenicidade

O cálculo usa sinais estruturais conservadores, como:

- categorias de emoliente ou emulsificante;
- padrões de ácidos graxos, palmitatos, estearatos, lauratos, lanolina e
  triglicerídeos;
- alguns ingredientes oclusivos ou muito usados em bases emolientes.

O resultado não afirma que o ingrediente é comedogênico em uso real. É somente
uma priorização de risco estrutural até existir estudo direto.

### Biodegradabilidade

O valor legado era calculado como um proxy de persistência. A `v2` converte o
resultado para `10 - valor_legado`, de forma que maior score indique melhor
biodegradabilidade. Sinais de polímeros, silicones, certos formadores de filme,
fragrâncias e agentes quelantes aumentam a preocupação de persistência na
proxy. Água, glicerina, sais simples, aminoácidos e alguns ácidos orgânicos
reduzem a preocupação proxy.

Essa transformação é uma correção de direção, não uma medição de meia-vida ou
resultado OECD.

### Risco ambiental

O cálculo considera sinais de categoria, padrões de nome, filtros UV,
formadores de filme, fragrância, silicones, quelantes, estabilizantes, efeitos
de alerta e restrições registradas. O resultado fica entre `1..10`.

Ele não substitui toxicidade aquática, avaliação PBT/vPvB ou concentração
ambiental prevista.

## Contrato do banco

As quatro linhas de um ingrediente ficam em
`venus.ingredient_risk_assessments`:

| Campo | Finalidade |
| --- | --- |
| `fk_ingredient_id` | ingrediente avaliado |
| `dimension` | um dos quatro eixos |
| `score` | inteiro entre `0` e `10` |
| `assessment_status` | `pending`, `approved` ou `rejected` |
| `source_type` | origem da evidência ou `system` para proxy |
| `source_reference` | URL, referência ou cadeia de fontes |
| `assessment_version` | `v2` para o contrato atual |
| `evidence_level` | força da evidência |
| `rationale` | justificativa auditável |
| `assessment_scope` | escopo, por exemplo `ingredient_baseline_indirect_v2` |

A tabela `venus.ingredients` mantém os quatro campos numéricos como contrato
legado para a API. O assessment é a fonte de verdade para saber se o número é
avaliado, proxy, pendente ou rejeitado.

## Regra de promoção da confiança

`scientific_confidence` não é sinônimo de “estudo direto”. O banco separa:

- `scientific_confidence`: valor consumível pela API;
- `scientific_confidence_state`: `default`, `derived` ou `curated`;
- `evidence_level`: força da evidência do assessment;
- `evaluation_state`: estado operacional exposto pela view de avaliação.

Depois da decisão de aceitar proxies, os 8.237 ingredientes do `Venus-qa`
passaram a ter quatro assessments `v2` aprovados e confiança positiva, mas a
view os classifica como `assessed_indirect_v2`. Isso é intencional: permite que
a classificação rode sem fingir que a evidência é direta.

## Substituição gradual por fontes fortes

Uma proxy `low` pode ser substituída por uma avaliação melhor usando o loader
oficial. A política é:

1. nunca baixar o nível de evidência;
2. nunca substituir `high` ou `very_high` por `low`;
3. manter a fonte e a justificativa da avaliação nova;
4. conservar o histórico no assessment atualizado;
5. revisar scores de produtos somente depois de atualizar os ingredientes;
6. executar novamente a classificação oficial após a carga.

Essa separação permite operar o catálogo hoje e melhorar a qualidade científica
sem alterar a API de classificação.
