# Runbook de score e evidência

## 1. Antes de qualquer carga

Confirme o banco e o usuário:

```sql
SELECT current_database(), current_user;
```

Confira se a metodologia ativa é a `v2`:

```sql
SELECT methodology_version, status, score_semantics
  FROM venus.ingredient_risk_methodologies
 WHERE status = 'active';
```

Não execute cargas de score em um banco diferente do ambiente autorizado.

## 2. Auditar ingredientes

Total de ingredientes:

```sql
SELECT COUNT(*) AS total
  FROM venus.ingredients;
```

Ingredientes sem os quatro eixos `v2`:

```sql
SELECT COUNT(*) AS without_four_dimensions
  FROM venus.ingredients i
 WHERE NOT venus.fn_has_complete_ingredient_assessment(i.ingredient_id);
```

Cobertura por eixo:

```sql
SELECT dimension,
       COUNT(*) FILTER (
           WHERE assessment_status = 'approved'
             AND assessment_version = 'v2'
             AND NULLIF(BTRIM(source_reference), '') IS NOT NULL
       ) AS approved_with_source
  FROM venus.ingredient_risk_assessments
 GROUP BY dimension
 ORDER BY dimension;
```

Distribuição da evidência:

```sql
SELECT assessment_version,
       evidence_level,
       assessment_scope,
       assessment_status,
       COUNT(*)
  FROM venus.ingredient_risk_assessments
 GROUP BY 1, 2, 3, 4
 ORDER BY 1, 2, 3, 4;
```

Estado semântico:

```sql
SELECT evaluation_state,
       is_really_evaluated,
       COUNT(*)
  FROM venus.v_ingredient_evaluation_status
 GROUP BY 1, 2
 ORDER BY 1, 2;
```

## 3. Importar evidência direta

O fluxo recomendado para fontes específicas é:

```powershell
python ops/load_official_ingredient_risk_v2.py export
python ops/load_official_ingredient_risk_v2.py validate `
  --input data/official_risk_evidence_v2.csv
python ops/load_official_ingredient_risk_v2.py apply `
  --input data/official_risk_evidence_v2.csv
```

O arquivo precisa ter quatro linhas por ingrediente. Cada linha deve declarar
fonte, localizador, evidência, justificativa, versão e nível de evidência.

O carregador recusa:

- score fora de `0..10`;
- fonte sem HTTPS permitido;
- home page sem localizador;
- justificativa vazia;
- score `0` sem explicar a base do zero;
- menos de quatro dimensões por ingrediente;
- downgrade de uma evidência forte para `low`.

## 4. Aplicar proxies autorizadas

Quando a decisão de produto for aceitar cobertura indireta, execute:

```powershell
python ops/apply_indirect_risk_proxies_v2.py
```

O script:

- exige `Venus-qa` por padrão;
- calcula a lista de ingredientes incompletos;
- usa a view determinística de inferência `v2`;
- grava quatro assessments `approved` por ingrediente;
- usa `evidence_level = 'low'`;
- usa `assessment_scope = 'ingredient_baseline_indirect_v2'`;
- preserva evidências `medium+`;
- sincroniza os campos numéricos legados;
- não chama a API de classificação.

## 5. Auditar produtos

Quantidade de versões prontas:

```sql
SELECT COUNT(*) AS current_versions,
       COUNT(*) FILTER (
           WHERE venus.fn_product_version_data_ready(pv.product_version_id)
       ) AS data_ready
  FROM venus.product_versions pv
 WHERE pv.is_current;
```

Composição inválida ou incompleta:

```sql
SELECT pv.product_version_id,
       p.name,
       cr.validation_status,
       cr.expected_count,
       cr.resolved_count,
       cr.unresolved_count
  FROM venus.product_versions pv
  JOIN venus.products p ON p.product_id = pv.fk_product_id
  LEFT JOIN venus.product_composition_receipts cr
    ON cr.fk_product_version_id = pv.product_version_id
   AND cr.is_current
 WHERE pv.is_current
   AND (
       cr.product_composition_receipt_id IS NULL
       OR cr.validation_status <> 'VALID'
       OR cr.expected_count <> cr.resolved_count
       OR cr.unresolved_count <> 0
   );
```

## 6. Executar a classificação

Somente depois de o banco estar pronto, execute o endpoint administrativo da
Venus-Classificacao:

```text
POST /api/base-scores
```

A API é a responsável por gerar ou atualizar `product_scores`. O banco não
deve preencher esses resultados por SQL.

## 7. Validar depois da API

Verifique:

- quantidade de produtos com score;
- scores nulos;
- scores iguais a zero;
- confidence de produto;
- produtos ainda em `needs_review`;
- divergência entre score armazenado e resposta da API;
- comportamento do mobile para “Sem dado”, `null` e `0`.

O valor `0` no resultado final pode ser legítimo em alguma dimensão, mas não
pode ser usado como substituto silencioso de “API não rodou” ou “ingrediente
sem avaliação”.

## 8. Novos ingredientes

Para um novo ingrediente:

1. cadastre o INCI e o identificador disponível;
2. resolva tradução/alias;
3. carregue evidência direta ou aceite proxy `v2/low` conforme a política;
4. confirme os quatro assessments;
5. confira a view de evaluation status;
6. aguarde a prontidão da versão do produto;
7. execute a classificação na próxima janela.

Não copie scores de outro ingrediente apenas por semelhança de nome.

## 9. Busca sem acento

A extensão `unaccent` foi instalada no schema `venus` para que a API possa
normalizar os dois lados da busca:

```sql
venus.unaccent(lower(product.name))
```

O mesmo deve ser aplicado ao termo digitado e à busca por ingrediente. A
extensão não muda a consulta automaticamente; o repository precisa chamá-la
explicitamente.
