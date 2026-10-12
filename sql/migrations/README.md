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

## Composição CeraVe — 2026-10-04

`20261004_001_cerave_cleanser_compositions.sql` cadastra a fórmula oficial
F.I.L. D253447/1 e os vínculos ordenados de ingredientes para os produtos
`cerave-espuma-cremosa-limpeza-hidratante` e
`cerave-creme-espuma-hidratante`. Execute-o uma vez em bancos existentes,
depois valide o resultado do `SELECT` final da própria migration.

## API IA e Google Calendar — 2026-09-30

`20260930_001_api_ia_audit_and_google_calendar.sql` deve ser executada por
um administrador após confirmar que o papel da API se chama `api_ia`. Ela dá
à API somente a permissão necessária para inserir auditoria e cria
`venus.google_oauth_tokens`, com token de refresh já cifrado pela aplicação.

A tabela de tokens deliberadamente não recebe trigger de auditoria: duplicar
credenciais, ainda que cifradas, em `venus_audit.audit_logs` amplia a superfície
de exposição. A migration também impede que uma execução futura de
`sp_sync_standard_triggers()` recrie esse trigger.

## Capas de listas — 2026-10-01

`20261001_001_user_list_covers.sql` adiciona `description` e `cover_key` em
`venus.user_lists` e cria a finalidade `list_cover` em `venus.media_assets`.
Cada lista pode ter no máximo uma capa ativa/pending, e a lista passa a ser a
única dona da mídia nessa finalidade. As constraints antigas de
`media_assets` são localizadas pela definição antes de serem substituídas,
para não depender dos nomes automáticos usados pelo PostgreSQL.

## Confidence score positivo — 2026-10-07

`20261007_001_positive_confidence_scores.sql` centraliza o cálculo de confiança
dos ingredientes e dos resultados de classificação. O piso técnico é `1`
(`0` deixa de ser válido); `1` representa evidência insuficiente, enquanto o
valor máximo é `100`.

A migration recalcula ingredientes existentes usando fonte, evidência e status
de revisão, cria constraints de faixa e triggers que derivam a confiança de
produto, análise e recomendação a partir dos ingredientes da versão do produto.
Execute-a uma vez nos bancos existentes, após backup e validação do resultado.

## Scores placeholder — 2026-10-08

`20261008_001_remove_placeholder_scores.sql` remove os scores zerados criados
por seed em versões que a API não pode calcular (`needs_review` ou sem
ingredientes) e remove análises técnicas falsas identificadas pelo summary.
Não calcula nem insere scores. Scores de versões verificadas com ingredientes
ficam preservados para serem sobrescritos pela próxima execução oficial da
Venus-Classificacao.

Depois de aplicar a migration, execute a API de classificação/base scores. A
API deve ser a única responsável por criar ou atualizar `product_scores`,
`analysis_results` e `personalized_scores` com resultados reais.

## Versões verificadas sem composição — 2026-10-08

`20261008_002_normalize_verified_without_ingredients.sql` normaliza versões
atuais marcadas como `verified` que não possuem ingredientes para
`needs_review`. Sem composição, a API não pode calcular score; manter essas
versões como verificadas faz o catálogo transformar a ausência de score em
`0` ou `null`.

## Guardrails de prontidão dos scores — 2026-10-10

`20261010_001_score_data_readiness_guardrails.sql` adiciona as proteções de
qualidade para a entrada da Venus-Classificacao, sem alterar a API nem
calcular scores no banco:

- registra avaliações aprovadas dos quatro eixos de risco dos ingredientes;
- registra a composição bruta, a contagem resolvida e os tokens não resolvidos;
- integra a staging do RPA e rebaixa automaticamente cargas inconsistentes;
- cria a base de prontidão usada pelo gate; a exigência final de dimensões
  secundárias é ajustada pela migration 002 abaixo;
- coloca versões incompletas em `needs_review` e bloqueia `product_scores` fora
  da prontidão;
- move scores invalidados para `venus.product_score_history`, sem deixá-los
  aparecer como resultado operacional no mobile.

Para cargas futuras, use `venus.sp_register_product_composition`,
`venus.sp_approve_ingredient_risk_assessment` e
`venus.sp_approve_product_dimension`. O valor `0` nos quatro campos de
ingrediente só será considerado uma avaliação quando houver os quatro registros
aprovados correspondentes; não se deve preencher valores por fallback.

## Resolução automática do OCR — 2026-10-10

`20261010_002_ocr_auto_resolution_and_relaxed_gate.sql` adiciona a resolução
automática dos textos em `product_labels` por INCI, nome comum e alias, usando
uma chave normalizada indexada. Tokens não encontrados ou ambíguos ficam em
`venus.product_ingredient_resolution_issues`; a lista só substitui os vínculos
existentes quando todos os tokens forem resolvidos.

O gate também deixa de exigir aprovação manual separada de embalagem, ética e
performance. Continua exigindo composição integral e quatro avaliações reais
aprovadas por ingrediente. A procedure `venus.sp_resolve_all_current_product_labels`
é executada pelo trigger sempre que um rótulo chega ou é atualizado, e o trigger
de prontidão promove automaticamente a versão quando os requisitos técnicos
forem atendidos.

Esta migration deliberadamente não cria avaliações científicas. CosIng, PubChem
e ECHA fornecem camadas diferentes de nomenclatura, segurança, regulação e
ambiente; nenhum deles fornece sozinho uma escala Venus 0–10 completa para os
quatro eixos. A carga dessas avaliações precisa vir de uma fonte/curadoria que
declare a metodologia e a referência de cada valor.

## Prioridade da resolução — 2026-10-10

`20261010_004_ingredient_resolution_priority.sql` torna a resolução
determinística: INCI exato vence alias, e alias vence nome comum. A chave é
reconstruída quando ingredientes ou aliases mudam, mantendo o comportamento
automático para produtos futuros.

## Fórmulas oficiais — 2026-10-10

`20261010_005_official_formula_catalog_import.sql` cadastra no catálogo apenas
tokens ausentes que aparecem em fórmulas de rótulos `official_site`, mantendo a
URL da fonte. Também preserva nomes químicos que contêm vírgula e trata o
placeholder de “composição não capturada” como pendência, não como ingrediente.
Esses ingredientes entram sem avaliação de risco e continuam bloqueados pelo
gate até receberem quatro avaliações aprovadas.

## Limpeza de pendências — 2026-10-10

`20261010_006_clear_stale_placeholder_issues.sql` remove pendências antigas
geradas pelos placeholders quando o rótulo é reprocessado. OCR ilegível não é
adivinhado: permanece listado como `NOT_FOUND` para uma nova captura.

## Metodologia de risco v1 — 2026-10-10

`20261010_007_risk_methodology_v1.sql` registra no banco a metodologia ativa
`v1` e suas quatro dimensões. Os quatro eixos usam a mesma direção: `0` é
menor risco e `10` é maior risco; em biodegradabilidade, isso significa que
`10` representa maior persistência ou menor biodegradação.

A metodologia exige evidência específica por eixo e mantém o estado como
`pending` quando a fonte não permite concluir. CosIng é usado para
nomenclatura/função, não como aprovação de segurança; avaliações de risco
priorizam SCCS/Comissão Europeia, Regulamento de Cosméticos, ECHA e fontes
científicas adequadas. A visão `venus.v_ingredient_risk_coverage` mostra os
ingredientes atuais que ainda não possuem quatro avaliações aprovadas.

## Backfill de fórmulas oficiais — 2026-10-10

`20261010_008_official_formula_backfill.sql` atualiza 23 produtos com fórmulas
publicadas nas páginas oficiais de CeraVe, La Roche-Posay e Eucerin. Cada rótulo
preserva a URL, a data de captura e a indicação de variante aceita pelo
operador. A migration é idempotente, cadastra tokens ainda ausentes no
catálogo e reprocessa a resolução automática; não cria avaliações de risco.

Ela também corrige a ordem de leitura do resolvedor: a verificação de rótulo
agora ocorre antes da limpeza das pendências, evitando que um `DELETE` sem
linhas faça uma fórmula existente ser tratada como `LEGACY_UNVERIFIED`.

Os produtos sem página oficial compatível, com variante materialmente
diferente ou com OCR ilegível continuam pendentes e não são preenchidos por
inferência.

## Avaliações indiretas v1 — 2026-10-10

`20261010_009_indirect_risk_assessments_v1.sql` registra quatro avaliações por
ingrediente usado em versões atuais. Quando não existe evidência direta para
um eixo, a regra aplica uma inferência conservadora baseada em categoria,
padrões do INCI e sinais de alerta/regulação OCR. Cada dimensão recebe
`evidence_level=low`, `source_type=system`, `assessment_scope` explícito e
justificativa própria; isso não deve ser lido como conclusão toxicológica
direta nem como avaliação de concentração.

A view `venus.v_ingredient_risk_inference_v1` expõe os valores antes da carga.
Triggers recalculam a avaliação quando um ingrediente, propriedade, efeito ou
regulação muda, permitindo que novos produtos recebam avaliações no banco sem
alteração na API de classificação.

## Fórmulas de referência — 2026-10-10

`20261010_010_reference_formula_backfill.sql` carrega fórmulas oficiais da
mesma linha ou da categoria mais próxima para os produtos sem INCI exato. Cada
registro é marcado como `source_type=system`, com `reference_formula=true`,
URL, produto de referência e `evidence_level=low`; portanto a prontidão para
classificação não confunde uma fórmula de referência com uma foto de rótulo.
As fontes usadas incluem páginas oficiais de CeraVe, La Roche-Posay, Eucerin,
Lola Cosmetics, Natura, O Boticário, Kérastase, Neutrogena, Granado, Pantene,
Maybelline e Cetaphil. A migration resolve os tokens, cadastra os ingredientes
novos e não executa a API nem cria `product_scores`.

`20261010_011_finish_reference_formula_gaps.sql` completa três versões que não
tinham recebido rótulo na primeira carga e reexecuta a resolução automática.

## Reclassificação de fragrâncias — 2026-10-10

`20261010_003_fragrance_category_reclassification.sql` promove uma allowlist
de 19 ingredientes inequívocos para `Agente Perfumante`, incluindo os 18
alérgenos clássicos identificados e `LAVANDULA HYBRIDA HERB OIL`.

Para não apagar funções atuais, a migration cria
`venus.ingredient_category_assignments` e registra 32 associações secundárias
de fragrância, incluindo óleos essenciais e matérias-primas botânicas. Extratos,
águas, flores e pós de lavanda permanecem sem promoção automática.

Use `venus.v_ingredient_category_links` quando a consulta precisar enxergar
categorias primárias e secundárias. O executor validado para os dois ambientes
é `ops/apply_20261010_003.py`.

## Fragrância canônica e fila de evidência — 2026-10-11

`20261011_001_fragrance_canonical_confidence_evidence.sql` move os registros
`PARFUM` (8104) e `PARFUM / FRAGRANCE` (8202) para `Agente Perfumante`, preenche
`common_name`/`function_summary` e registra aliases cosméticos em 8104. Os dois
IDs são preservados para compatibilidade histórica.

A view `venus.v_product_fragrance_flags` expõe `contains_fragrance`,
`warning_text` e os IDs envolvidos para o backend/mobile; o aviso é derivado
da categoria canônica, não de uma lista fixa de IDs. A função
`venus.fn_product_contains_fragrance` fornece o mesmo contrato para consultas
por versão.

A coluna `ingredients.scientific_confidence_state` separa `default` (fallback
1), `derived` e `curated`. A view `venus.v_ingredient_evaluation_status` também
separa avaliações indiretas `v1/low` de avaliações com evidência `medium+`.
Os ingredientes usados com fallback ou proxy entram em
`venus.ingredient_evidence_queue`; a prioridade 1 corresponde aos 185
ingredientes atuais com confidence padrão 1. A fila não altera os assessments
atuais nem executa a API de classificação.

## Busca sem acento no CRUD — 2026-10-12

`20261012_005_unaccent_search.sql` instala a extensão PostgreSQL `unaccent` no
schema `venus`, usado pelo `currentSchema` da API. O `ProductRepository` e o
`IngredientRepository` podem normalizar os dois lados da comparação com
`venus.unaccent(lower(...))`, permitindo que `locao` encontre `Loção`. A
migration não altera os dados nem executa a classificação.
