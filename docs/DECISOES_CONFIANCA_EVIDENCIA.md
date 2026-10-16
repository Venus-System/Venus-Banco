# Confidence, evidência e estado de avaliação

## O problema original

O catálogo começou tratando `scientific_confidence` como se qualquer valor
positivo significasse que o ingrediente havia sido avaliado. Como vários
ingredientes recebiam `1` por padrão, o sistema produzia três problemas:

- ingredientes sem estudo apareciam como aprovados;
- scores de saúde pareciam perfeitos quando os quatro campos de risco estavam
  zerados;
- produtos sem ingrediente realmente avaliado podiam ser classificados com
  confidence artificial.

O valor `1` é útil como fallback técnico, mas não é evidência científica. A
correção separou valor, estado, dimensão e evidência.

## Os quatro conceitos que não podem ser confundidos

### `scientific_confidence`

É um valor numérico utilizado no contrato da API. Ele responde à pergunta:

> “Qual confidence numérico está disponível para este ingrediente?”

Não responde sozinho:

> “Existe estudo direto para os quatro eixos?”

### `scientific_confidence_state`

Indica como o confidence foi obtido:

- `default`: fallback ou ausência de avaliação completa;
- `derived`: derivado de assessments ou regras do banco;
- `curated`: revisado/curado explicitamente.

### `evidence_level`

Indica a força da evidência da avaliação:

- `low`: proxy indireta, regra de triagem ou evidência insuficiente para uma
  conclusão direta;
- `medium`: evidência específica razoável;
- `high`: evidência forte e fonte identificável;
- `very_high`: evidência autoritativa ou conclusão regulatória muito robusta.

### `evaluation_state`

É o estado semântico exposto por
`venus.v_ingredient_evaluation_status`:

- `not_evaluated`: não há os quatro assessments `v2` aprovados com fonte;
- `assessed_indirect_v2`: há quatro assessments, mas a evidência é apenas
  indireta/low;
- `assessed`: há pelo menos uma evidência mais forte (`medium` ou superior).

## Regra de completude

Um ingrediente só é completo para a classificação quando possui exatamente
estas quatro dimensões em `v2`, com status `approved` e `source_reference` não
vazio:

```text
irritation_risk_level
comedogenicity_score
biodegradability_level
environmental_risk_level
```

Uma dimensão faltante não pode ser compensada por outra. Um ingredient com
irritação avaliada, mas biodegradabilidade desconhecida, continua incompleto
para o contrato atual.

## Por que a proxy pode gerar confidence positivo

Foi tomada uma decisão operacional explícita: todos os ingredientes precisam
ter dados suficientes para que a classificação rode. Como não era possível
obter evidência direta para todos os 8.237 ingredientes imediatamente, foi
autorizado o uso de proxies `v2/low`.

O confidence positivo significa:

```text
há uma avaliação operacional versionada para os quatro eixos
```

Ele não significa:

```text
há quatro estudos diretos de alta qualidade
```

Por esse motivo, o backend e o mobile devem consultar a view de estado quando
precisarem exibir linguagem como “avaliado”, “aprovado” ou “com evidência”.

## Regras de UI recomendadas

### Para `not_evaluated`

Exibir algo como:

> “Ainda não temos avaliação suficiente deste ingrediente.”

Não exibir “Aprovado”, “seguro” ou “baixo risco”.

### Para `assessed_indirect_v2`

Exibir algo como:

> “Estimativa baseada em dados indiretos; pode ser revisada quando houver
> evidência específica.”

Não esconder o fato de que o score é proxy.

### Para `assessed`

Exibir a avaliação conforme a política de produto, mantendo a fonte disponível
para auditoria.

Mesmo `assessed` não é promessa de segurança absoluta. É apenas o estado de
qualidade de evidência do catálogo.

## Triggers e proteção

O banco possui trigger para evitar confidence positivo sem os quatro
assessments `v2`. Ao inserir ou atualizar um assessment:

1. verifica se as quatro dimensões estão completas;
2. recalcula o confidence derivado;
3. volta para o estado padrão quando uma dimensão é removida ou rejeitada;
4. não permite que uma atualização manual dos campos legados ignore o contrato.

O campo numérico da tabela `ingredients` continua existindo por compatibilidade
com a API, mas o código novo deve preferir a view de evaluation status.

## Política de substituição

Uma avaliação indireta é temporária. Quando uma fonte específica for encontrada:

1. insira ou atualize a dimensão no mesmo `assessment_version = 'v2'`;
2. use `source_type` adequado;
3. salve a URL ou referência específica;
4. registre o localizador do trecho, seção, endpoint, opinião ou estudo;
5. escreva a justificativa do score;
6. eleve `evidence_level` para `medium`, `high` ou `very_high`;
7. preserve a avaliação mais forte contra cargas posteriores de proxy.

O loader oficial impede downgrade de evidência. A proxy não pode apagar uma
avaliação forte apenas porque uma rotina em lote foi executada novamente.

## O que não é permitido

Não usar:

- `scientific_confidence = 1` como sinônimo de avaliação;
- `score = 0` para representar dado ausente;
- ausência de restrição como prova de ausência de risco;
- categoria cosmética como prova toxicológica;
- origem natural como prova de biodegradabilidade;
- função emoliente como prova de comedogenicidade;
- marketing como evidência de performance ou segurança;
- valor de biodegradabilidade invertido sem declarar a metodologia;
- score de produto inserido manualmente para contornar o gate.
