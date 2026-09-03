SET search_path TO venus, public;

UPDATE venus.ingredient_categories child
SET parent_ingredient_category_id = parent.ingredient_category_id
FROM venus.ingredient_categories parent
WHERE (child.name, parent.name) IN (
('Condicionante Capilar','Condicionante'),
('Condicionante da Pele','Condicionante'),
('Agente Perfumante','Fragrância'),
('Absorvedor de UV','Filtro UV'),
('Refletor de UV','Filtro UV'),
('Agente de Limpeza','Tensoativo'),
('Agente Espumante','Tensoativo'),
('Solubilizante','Solvente'),
('Controlador de Viscosidade','Espessante'),
('Ajustador de pH','Agente Tampão')
) AND child.parent_ingredient_category_id IS DISTINCT FROM parent.ingredient_category_id;

CREATE OR REPLACE VIEW venus.v_ingredient_category_tree AS
WITH RECURSIVE category_tree AS (
    SELECT c.ingredient_category_id, c.parent_ingredient_category_id, c.name, c.description,
           0 AS depth, c.name::TEXT AS path
    FROM venus.ingredient_categories c
    WHERE c.parent_ingredient_category_id IS NULL
    UNION ALL
    SELECT c.ingredient_category_id, c.parent_ingredient_category_id, c.name, c.description,
           ct.depth + 1, ct.path || ' > ' || c.name
    FROM venus.ingredient_categories c
    JOIN category_tree ct ON c.parent_ingredient_category_id = ct.ingredient_category_id
)
SELECT * FROM category_tree;
