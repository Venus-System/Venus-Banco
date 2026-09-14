/*
  Runner lógico das três correções de modelagem.
  Execute os três arquivos na ordem abaixo, pois psql \i depende do caminho
  do ambiente em que o comando for executado.

  \i sql/migrations/20260914_001_allergy_ingredient_mapping.sql
  \i sql/migrations/20260914_002_hair_pattern.sql
  \i sql/migrations/20260914_003_adult_only.sql
*/
SELECT 'Execute os três arquivos de migration listados no comentário acima, nesta ordem.' AS instruction;
