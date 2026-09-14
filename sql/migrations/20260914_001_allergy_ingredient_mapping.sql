BEGIN;

SET search_path TO venus, public;

/*
  Correção 1 — alergias x ingredientes
  ------------------------------------
  O modelo anterior relacionava apenas:
      users -> user_allergies -> allergies

  Esta tabela cria o vínculo explícito:
      allergies <-> ingredients

  Observação: somente correspondências exatas entre allergy_name e inci_name
  são populadas automaticamente. Alergias genéricas (ex.: "Fragrância")
  permanecem para curadoria específica, evitando associações científicas
  arbitrárias.
*/

CREATE TABLE IF NOT EXISTS venus.allergy_ingredients (
    allergy_ingredient_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fk_allergy_id BIGINT NOT NULL
        REFERENCES venus.allergies(allergy_id) ON DELETE CASCADE,
    fk_ingredient_id BIGINT NOT NULL
        REFERENCES venus.ingredients(ingredient_id) ON DELETE CASCADE,
    source_type venus.source_type_enum NOT NULL DEFAULT 'admin',
    source_reference TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (fk_allergy_id, fk_ingredient_id)
);

CREATE INDEX IF NOT EXISTS idx_allergy_ingredients_allergy
    ON venus.allergy_ingredients (fk_allergy_id);

CREATE INDEX IF NOT EXISTS idx_allergy_ingredients_ingredient
    ON venus.allergy_ingredients (fk_ingredient_id);

/*
  Mapeamento inicial seguro: apenas nome exato da alergia = INCI.
  Isso cobre automaticamente alergias de ingrediente já cadastradas com o
  mesmo nome do ingrediente mestre.
*/

INSERT INTO venus.allergy_ingredients (
    fk_allergy_id,
    fk_ingredient_id,
    source_type,
    source_reference
)
SELECT
    a.allergy_id,
    i.ingredient_id,
    'system'::venus.source_type_enum,
    'Migration 20260914_001: exact allergy_name = ingredients.inci_name'
FROM venus.allergies a
JOIN venus.ingredients i
  ON UPPER(BTRIM(a.allergy_name)) = UPPER(BTRIM(i.inci_name))
WHERE a.allergy_type = 'ingredient'
ON CONFLICT (fk_allergy_id, fk_ingredient_id) DO NOTHING;

COMMENT ON TABLE venus.allergy_ingredients IS
'Relação explícita entre alergias e ingredientes INCI para compatibilidade de usuários com fórmulas.';

COMMENT ON COLUMN venus.allergy_ingredients.fk_allergy_id IS
'FK para a alergia declarada/cadastrada.';

COMMENT ON COLUMN venus.allergy_ingredients.fk_ingredient_id IS
'FK para o ingrediente INCI efetivamente relacionado à alergia.';

COMMIT;

/* QA: alergias de ingrediente ainda sem mapeamento exigem curadoria. */
SELECT
    a.allergy_id,
    a.allergy_name,
    COUNT(ai.allergy_ingredient_id) AS mapped_ingredients
FROM venus.allergies a
LEFT JOIN venus.allergy_ingredients ai
    ON ai.fk_allergy_id = a.allergy_id
WHERE a.allergy_type = 'ingredient'
GROUP BY a.allergy_id, a.allergy_name
HAVING COUNT(ai.allergy_ingredient_id) = 0
ORDER BY a.allergy_name;
