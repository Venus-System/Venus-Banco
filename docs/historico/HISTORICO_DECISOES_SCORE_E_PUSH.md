# Histórico das decisões de score e do push

## Contexto

O trabalho nasceu de uma sequência de problemas observados no mobile e na API:

- confidence positivo em ingredientes sem avaliação real;
- risco zerado interpretado como ausência de risco;
- saúde artificialmente próxima de 100;
- ambiental concentrado em valores repetidos;
- produtos sem score exibidos como `0`, `null` ou “Sem dado”;
- scores antigos permanecendo depois de uma mudança de dados;
- dificuldade de diferenciar fonte oficial, proxy e ausência de evidência;
- busca do CRUD sensível a acentos.

As decisões foram transformadas em migrations, triggers, views e scripts
operacionais para que não dependessem de uma correção manual única.

## Linha do tempo resumida

### 2026-10-10 — Guardrails de prontidão

Foi criada a base de prontidão dos scores:

- `ingredient_risk_assessments`;
- recibos de composição;
- avaliação de dimensões de produto;
- funções de prontidão;
- histórico de score invalidado;
- bloqueio de score quando a entrada está incompleta.

Também foi criada a resolução automática do OCR por INCI, alias e nome comum.

### 2026-10-10 — Metodologia e proxies

Foi registrada a metodologia dos quatro eixos. As proxies receberam
`evidence_level = low`, `source_type = system` e justificativas explícitas.

A regra foi documentada como proxy e não como conclusão toxicológica direta.

### 2026-10-11 — Fragrância e confiança

Foram separados:

- confidence padrão;
- confidence derivado;
- ingrediente realmente avaliado;
- evidência indireta;
- evidência mais forte.

Também foram consolidados aliases de fragrância e criado o contrato canônico
para o aviso do mobile.

### 2026-10-12 — Direção da biodegradabilidade

A metodologia `v2` corrigiu a direção do eixo:

```text
biodegradabilidade maior = melhor resultado ambiental
```

O valor legado foi convertido para a direção atual. A API deve consumir a
direção `v2` sem inverter novamente.

### 2026-10-12 — Cobertura completa por proxy

Foi autorizada a decisão de operação com proxies indiretas. O script
`ops/apply_indirect_risk_proxies_v2.py` completou os 5.008 ingredientes que
estavam sem os quatro assessments.

Resultado verificado:

- pendentes antes: `5.008`;
- pendentes depois: `0`;
- ingredientes totais: `8.237`;
- ingredientes com quatro dimensões: `8.237`;
- estado: `assessed_indirect_v2`;
- evidência: `low`;
- confidence positivo: `8.237`.

### 2026-10-12 — Busca sem acento

A extensão PostgreSQL `unaccent` foi instalada no schema `venus`, porque a API
usa `currentSchema=venus`. O teste encontrou produtos com `locao` mesmo quando
o nome armazenado continha `Loção`.

Essa mudança apenas disponibiliza a função. Os repositories devem chamá-la nos
dois lados da comparação.

## Arquivos principais

### Metodologia

- `sql/migrations/20261010_007_risk_methodology_v1.sql`;
- `sql/migrations/20261012_001_score_readiness_policies.sql`;
- `sql/migrations/README.md`.

### Assessments e proxies

- `sql/migrations/20261010_009_indirect_risk_assessments_v1.sql`;
- `ops/apply_indirect_risk_proxies_v2.py`;
- `ops/load_official_ingredient_risk_v2.py`;
- `docs/decisoes/DECISOES_SCORE_INGREDIENTES.md`.

### Prontidão de produtos

- `sql/migrations/20261010_001_score_data_readiness_guardrails.sql`;
- `sql/migrations/20261010_002_ocr_auto_resolution_and_relaxed_gate.sql`;
- `sql/migrations/20261012_002_promote_complete_assessments.sql`;
- `docs/decisoes/DECISOES_SCORE_PRODUTOS_E_CLASSIFICACAO.md`.

### Busca sem acento

- `sql/migrations/20261012_005_unaccent_search.sql`;
- `ops/apply_20261012_005.py`;
- `sql/00_schema.sql`.

## O que foi deliberadamente evitado

Não foram tomadas estas ações:

- não foi executada a API de classificação durante a carga dos ingredientes;
- não foram inseridos `product_scores` manualmente;
- não foram atribuídos scores diretos com base apenas em CosIng;
- não foram tratados ingredientes naturais como automaticamente seguros;
- não foi usado `0` para esconder ausência de evidência;
- não foram sobrescritas avaliações mais fortes por proxies;
- não foi alterada a lógica da Venus-Classificacao nesta etapa;
- não foi criada uma falsa conclusão de comedogenicidade para todos os óleos;
- não foi inferido risco ambiental apenas pela função cosmética.

## Commit e push

Todas as alterações pendentes do checkout foram incluídas, conforme autorizado,
incluindo documentação de modelo já existente no working tree, scripts de
operação, migration de `unaccent`, documentação de OCR e o template de
evidências.

Commit enviado:

```text
6fc9fdb Add indirect risk backfill and accent-insensitive search
```

Branch remoto:

```text
codex/venus-readiness-reference-formulas
```

Destino:

```text
origin = https://github.com/Venus-System/Venus-Banco.git
```

O push foi concluído com sucesso e o checkout ficou limpo depois do envio.

## Próximo passo operacional

O próximo passo é rodar novamente o endpoint administrativo da classificação e
auditar os resultados. A classificação deve ser executada apenas depois de a
base estar pronta, porque é ela que grava o score final dos produtos.

Depois da execução, a equipe deve registrar:

- data/hora da execução;
- quantidade de produtos processados;
- quantidade com score nulo ou zero;
- quantidade ainda em `needs_review`;
- quantidade de produtos usando ingredientes `assessed_indirect_v2`;
- amostra de produtos para comparação no mobile.

O objetivo da documentação é que a próxima pessoa consiga reproduzir a
decisão, identificar o grau de evidência e saber exatamente qual etapa pertence
ao banco e qual etapa pertence à API.
