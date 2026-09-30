# Venus — correções da API de classificação — 2026-09-14

## Correções incluídas

### 1. Allergy -> Ingredient
Cria `venus.allergy_ingredients` com FK para `allergies` e `ingredients`.

A migration popula apenas correspondências exatas entre `allergy_name` e `ingredients.inci_name`. Isso evita inventar associações para alergias genéricas como `Fragrância`; essas ficam identificadas pela query de QA para curadoria posterior.

### 2. HairType / HairPattern
Mantém `hair_type` como classificação macro:

- `straight`
- `wavy`
- `curly`
- `coily`
- `other`

Adiciona `hair_pattern` com:

- `1A`, `1B`, `1C`
- `2A`, `2B`, `2C`
- `3A`, `3B`, `3C`
- `4A`, `4B`, `4C`
- `other`

Há uma constraint para impedir combinações incoerentes entre as duas classificações.

### 3. Apenas maiores de 18
`age_range_enum` passa a conter somente:

- `age_18_24`
- `age_25_34`
- `age_35_44`
- `age_45_54`
- `age_55_plus`

Em bancos existentes, qualquer registro legado em `under_13` ou `age_13_17` é normalizado para `age_18_24` antes da troca do enum.

## Banco já existente

Execute na ordem:

1. `20260914_001_allergy_ingredient_mapping.sql`
2. `20260914_002_hair_pattern.sql`
3. `20260914_003_adult_only.sql`

Ou use `20260914_all_classification_fixes.sql`, que contém as três correções em sequência.

## Banco novo

Os scripts-base também foram corrigidos:

- `sql/00_schema.sql`
- `sql/10_reference_seed.sql`
- `sql/30_demo_seed.sql`
- `sql/40_data_catalog.sql`
- `sql/50_bi.sql`
- `sql/99_validation.sql`

## Observação sobre dados antigos

Não é seguro inferir `1A/2A/3A/4A` para usuários antigos apenas a partir de `hair_type`. Por isso `hair_pattern` fica `NULL` nos perfis legados até a API/questionário fornecer a resposta específica. O seed demo recebe valores sintéticos coerentes para testes.

## Reconciliação de produção — 2026-09-27

`20260927_001_reconcile_production_schema.sql` registra o estado já aplicado
em produção e as alterações pendentes de nulidade. Ele torna opcionais os
campos de perfil que podem não ser informados, preservando `NULL` como
"desconhecido" (sem substituir por `false`, `other` ou uma faixa etária).

Também registra os campos de score que podem ainda não ter sido calculados,
as regras de bloqueio, as proteções de auditoria/DAU e a faixa `age_13_17`.
Assim, a regra histórica de "apenas maiores de 18" deixa de representar o
estado atual do produto.

Em bancos já conciliados manualmente, mantenha o arquivo como registro de
versionamento e não o execute novamente. Em ambientes existentes que ainda
estejam no estado anterior, execute-o uma vez após revisar o impacto da
reintrodução da faixa etária de 13–17 anos.

## API IA e Google Calendar — 2026-09-30

`20260930_001_api_ia_audit_and_google_calendar.sql` deve ser executada por
um administrador após confirmar que o papel da API se chama `api_ia`. Ela dá
à API somente a permissão necessária para inserir auditoria e cria
`venus.google_oauth_tokens`, com token de refresh já cifrado pela aplicação.

A tabela de tokens deliberadamente não recebe trigger de auditoria: duplicar
credenciais, ainda que cifradas, em `venus_audit.audit_logs` amplia a superfície
de exposição. A migration também impede que uma execução futura de
`sp_sync_standard_triggers()` recrie esse trigger.
