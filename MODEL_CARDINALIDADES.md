# Venus — PK, FK e Cardinalidades

A documentação abaixo cobre as relações do modelo operacional. Tabelas associativas materializam N:N.

- users 1:1 user_profiles; users 1:1 user_preferences.
- users N:N allergies via user_allergies.
- users N:N profile_tags via user_profile_tags.
- brands 1:N products; product_categories 1:N products.
- products 1:N product_versions; product_versions 1:1 product_labels; product_versions 1:1 packaging.
- product_versions N:N claims via product_claims.
- ingredient_categories 1:N ingredients e hierarquia 1:N por parent_ingredient_category_id.
- ingredients 1:N aliases/properties/effects/regulations.
- ingredients N:N regulations via ingredient_regulations.
- product_versions N:N ingredients via product_ingredients.
- scoring_models 1:N compatibility_rules/product_scores/analysis_results/personalized_scores.
- users 1:N analysis_results/personalized_scores/recommendations/favorites/lists/reviews/reports.
- users N:N products via favorites; user_lists N:N products via user_list_items; users N:N reviews via review_votes.
- users 1:N user_access_events.

As PKs e FKs estão definidas no `sql/00_schema.sql`; restrições UNIQUE implementam as relações 1:1.

## Legenda

- **1:1** — uma linha na tabela A corresponde a no máximo uma linha na tabela B, garantido por FK com restrição UNIQUE.
- **1:N** — uma linha na tabela A pode se relacionar a várias linhas na tabela B; a FK fica no lado "N".
- **N:N** — relação implementada por uma tabela associativa, que guarda um par de FKs (uma para cada lado da relação).

## Como usar este documento

Este mapa de cardinalidades serve como referência rápida ao escrever consultas ou ao avaliar o impacto de uma alteração de schema. Para o detalhe de cada coluna, tipo e constraint, consulte diretamente `sql/00_schema.sql` (fonte canônica) ou o catálogo técnico gerado em `sql/40_data_catalog.sql`, que descreve tabelas, colunas e regras de forma consultável via SQL.

## Tabelas associativas citadas

| Tabela associativa | Relação N:N que implementa |
|---|---|
| `user_allergies` | `users` ↔ `allergies` |
| `user_profile_tags` | `users` ↔ `profile_tags` |
| `product_claims` | `product_versions` ↔ `claims` |
| `ingredient_regulations` | `ingredients` ↔ `regulations` |
| `product_ingredients` | `product_versions` ↔ `ingredients` |
| `favorites` | `users` ↔ `products` |
| `user_list_items` | `user_lists` ↔ `products` |
| `review_votes` | `users` ↔ `reviews` |

## Hierarquias

`ingredient_categories` é uma tabela auto-referenciada (`parent_ingredient_category_id`), formando uma hierarquia 1:N recursiva. Consultas que precisem percorrer essa hierarquia (por exemplo, para agregar ingredientes por categoria-mãe) devem usar uma CTE recursiva, como a documentada em `AUDIT_DECISIONS.md`.
