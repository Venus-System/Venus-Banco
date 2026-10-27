# Venus-Banco — arquitetura e modelos lógicos

Este documento explica como o banco está organizado e qual arquivo deve ser
usado para cada tipo de leitura. Os modelos visuais editáveis em brModelo são
as fontes de apresentação da arquitetura; os snapshots gerados do PostgreSQL
servem para conferir o desenho contra o banco implantado em QA.

## Visão geral

```text
Banco legado externo (somente leitura)
                 │
                 ▼
        rpa_migrate.py / venus_rpa
                 │  staging, execução e erros
                 ▼
             venus
      núcleo operacional do produto
          │                 │
          │                 └── triggers de auditoria ──► venus_audit
          │
          └── views analíticas ──► venus_bi
```

O pacote também mantém `venus_optimization.readme` como ponto de extensão para
objetos de otimização. Ele não possui relacionamento operacional com as demais
tabelas.

## Schemas do banco

### `venus`

É o núcleo transacional. Contém o catálogo de produtos e ingredientes, perfis
de usuários, preferências, avaliações, regras de compatibilidade, scores,
recomendações, listas e reviews.

Principais grupos:

- Identidade e perfil: `users`, `user_profiles`, `user_preferences`,
  `profile_tags`, `user_profile_tags`, `user_allergies`, `allergies`.
- Catálogo de produtos: `brands`, `products`, `product_categories`,
  `product_versions`, `product_labels`, `packaging`, `media_assets`, `claims`.
- Ingredientes e regulação: `ingredients`, `ingredient_aliases`,
  `ingredient_categories`, `ingredient_effects`, `ingredient_properties`,
  `ingredient_regulations`, `regulations`.
- Avaliação e scoring: `scoring_models`, `score_categories`,
  `scoring_model_categories`, `compatibility_rules`, `analysis_results`,
  `product_scores`, `personalized_scores`, `recommendations`.
- Engajamento: `favorites`, `user_lists`, `user_list_items`, `reviews`,
  `review_votes`, `reports`, `user_access_events` e `user_tracking_events`.

### `venus_audit`

Mantém o histórico de alterações em `audit_logs`. O schema é separado do núcleo
para facilitar retenção, backup e governança. A tabela não possui FKs para o
núcleo de propósito: o log deve continuar registrando a alteração mesmo quando
o registro de origem for removido ou alterado.

### `venus_rpa`

É a camada de integração com o legado externo. `rpa_run` representa uma
execução; `rpa_stage_product` e `rpa_stage_user` recebem os dados intermediários;
`rpa_error` registra falhas. Os campos `loaded_product_id` e `loaded_user_id`
ligam o staging ao registro carregado em `venus`, mas aceitam NULL quando a
carga ainda não foi concluída.

### `venus_bi`

Não possui tabelas físicas. É uma camada derivada composta por dimensões,
fatos e views analíticas criadas em `sql/50_bi.sql`. Portanto, não aparece como
cartões de tabelas nos modelos brM3 físicos; deve ser consultada como camada de
leitura e relatórios.

### `venus_optimization`

Possui atualmente apenas a tabela `readme`, usada como espaço reservado para
estruturas futuras de otimização.

## Inventário completo de tabelas

O inventário abaixo representa todas as tabelas físicas encontradas no banco
de QA na geração deste documento. O detalhamento de campos, tipos, PKs, UQs,
FKs, defaults e nulabilidade está em
[`database-logical-model.md`](database-logical-model.md).

### `venus` — 59 tabelas

`admin_users`, `allergies`, `allergy_ingredients`, `analysis_results`,
`brand_claim_evidence`, `brands`, `claims`, `compatibility_rules`,
`data_catalog`, `data_catalog_rules`, `favorites`, `google_oauth_tokens`,
`ingredient_aliases`, `ingredient_categories`,
`ingredient_category_assignments`, `ingredient_effect_validation_audit`,
`ingredient_effects`, `ingredient_evidence_queue`, `ingredient_properties`,
`ingredient_regulations`, `ingredient_resolution_keys`,
`ingredient_risk_assessments`, `ingredient_risk_methodologies`,
`ingredient_risk_methodology_dimensions`, `ingredients`, `media_assets`,
`packaging`, `packaging_evaluation_policies`, `personalized_scores`,
`product_categories`, `product_claims`, `product_composition_receipts`,
`product_dimension_assessments`, `product_ingredient_resolution_issues`,
`product_ingredients`, `product_labels`, `product_score_history`,
`product_scores`, `product_versions`, `products`, `profile_tags`,
`recommendations`, `regulations`, `reports`, `review_votes`, `reviews`,
`rule_evaluations`, `score_categories`, `scoring_model_categories`,
`scoring_models`, `user_access_events`, `user_allergies`,
`user_list_items`, `user_lists`, `user_preferences`, `user_profile_tags`,
`user_profiles`, `user_tracking_events` e `users`.

### `venus_audit` — 1 tabela

`audit_logs`.

### `venus_rpa` — 4 tabelas

`rpa_error`, `rpa_run`, `rpa_stage_product` e `rpa_stage_user`.

### `venus_optimization` — 1 tabela

`readme`.

Total: **65 tabelas físicas**.

## Relacionamentos da arquitetura

O banco possui **79 relacionamentos por FK**. No núcleo `venus`, as relações
seguem principalmente estes eixos:

- `users` centraliza perfil, preferências, autenticação OAuth, favoritos,
  listas, reviews, avaliações, recomendações, relatórios e eventos de acesso/
  rastreamento.
- `products` referencia marcas e categorias e possui versões em
  `product_versions`; a versão concentra composição, rótulos, embalagem,
  mídia, avaliações, scores, recomendações e reviews.
- `ingredients` referencia categorias e se relaciona com aliases, efeitos,
  propriedades, regulamentações, chaves de resolução, avaliações de risco,
  alergias e composição de produtos.
- `scoring_models` se relaciona com categorias de score, scores de produto,
  scores personalizados, resultados de análise e regras de compatibilidade.
- `user_allergies`, `user_profile_tags`, `scoring_model_categories`,
  `product_ingredients`, `product_claims`, `ingredient_regulations` e outras
  tabelas de associação materializam relações N:N.
- `venus_rpa` é uma fronteira de ingestão: `rpa_run` organiza a execução,
  `rpa_stage_product` e `rpa_stage_user` armazenam staging e `rpa_error`
  registra falhas. Os IDs `loaded_product_id` e `loaded_user_id` apontam para
  registros carregados em `venus` quando a carga termina.
- `venus_audit.audit_logs` não possui FK intencionalmente; registra o schema,
  tabela e dados alterados sem depender da permanência do registro de origem.

Para a lista exata de cada FK, origem, destino, nulabilidade e cardinalidade
derivada (`1:1`, `1:N` ou associação `N:N`), consulte a seção
[`Relacionamentos físicos`](database-logical-model.md#relacionamentos-físicos)
do snapshot gerado.

## Fontes dos modelos

### Mapa arquitetural resumido

Para uma visão que renderiza bem sem abrir o ERD completo, use
[`architecture-overview.mmd`](architecture-overview.mmd). Ele mostra o fluxo
entre legado, RPA, núcleo transacional, auditoria e BI sem tentar exibir todas
as colunas de `venus` em uma única imagem.

### Modelos visuais editáveis — brModelo

Os arquivos abaixo substituem o modelo visual antigo e devem ser abertos no
brModelo 3.2:

- [`Schema-Venus-Logico.brM3`](<modelos lógicos/Schema-Venus-Logico.brM3>): modelo completo do núcleo `venus`.
- [`Schema-Venus_Audit-Logico.brM3`](<modelos lógicos/Schema-Venus_Audit-Logico.brM3>): auditoria.
- [`Schema-Venus_RPA-Logico.brM3`](<modelos lógicos/Schema-Venus_RPA-Logico.brM3>): integração RPA e staging.

As capturas em [`modelos lógicos/previews`](<modelos lógicos/previews>) são apenas
pré-visualizações para navegação no repositório. A captura de `venus` é
intencionalmente densa porque representa todas as tabelas do núcleo; para ler
campos e relacionamentos, abra o `.brM3` no brModelo ou use os artefatos
gerados abaixo.

### Snapshot conferido contra o PostgreSQL de QA

- [`database-logical-model.md`](database-logical-model.md): catálogo completo
  de tabelas, campos, tipos, constraints, FKs, enums e views.
- [`database-logical-model.mmd`](database-logical-model.mmd): diagrama Mermaid
  gerado dos metadados físicos.
- [`database-logical-model.svg`](database-logical-model.svg): diagrama SVG
  zoomável de todas as tabelas físicas.
- [`database-logical-model.sql`](database-logical-model.sql): snapshot lógico
  SQL, sem executar alterações no banco.
- [`../MODEL_CARDINALIDADES.md`](../MODEL_CARDINALIDADES.md): resumo das
  cardinalidades e tabelas associativas.

O snapshot é regenerado por `python ops/generate_database_model.py` e não
substitui os arquivos brM3 como desenho editável. Ele existe para detectar
divergências entre o desenho apresentado e o banco implantado.

## Arquivos que implementam a arquitetura

- `sql/00_schema.sql`: schemas, tipos, tabelas, FKs, índices, funções e
  auditoria inicial.
- `sql/05_cloudinary_images.sql`: metadados de mídia e views relacionadas.
- `sql/40_data_catalog.sql`: catálogo técnico de tabelas e colunas.
- `sql/50_bi.sql`: camada de views analíticas em `venus_bi`.
- `sql/60_rpa.sql`: estruturas de execução e staging em `venus_rpa`.
- `sql/migrations/`: alterações incrementais posteriores ao schema inicial.
- `pipeline.py`: bootstrap, aplicação ordenada dos SQLs e validações.
- `rpa_migrate.py`: extração do legado e carga do staging/`venus`.
- `ops/generate_database_model.py`: documentação somente leitura do banco.

## Regras de manutenção

1. Alterações estruturais devem ser feitas no schema SQL ou em uma migration.
2. Depois da migration, atualizar o desenho brM3 correspondente.
3. Regenerar os snapshots com `python ops/generate_database_model.py`.
4. Conferir `MODEL_CARDINALIDADES.md` quando uma FK, UQ ou tabela associativa
   for alterada.
5. Não colocar credenciais, dumps de dados ou binários de mídia no repositório.
