BEGIN;
SET LOCAL search_path TO venus, public;

DO $$
DECLARE
    v_conflict TEXT;
BEGIN
    SELECT string_agg(name || ' (' || slug || ')', ', ' ORDER BY name)
      INTO v_conflict
      FROM venus.profile_tags
     WHERE (name IN ('Sem Óleo', 'Hipoalergênico', 'Não Comedogênico')
            OR slug IN ('sem-oleo', 'hipoalergenico', 'nao-comedogenico'))
       AND (name, slug) NOT IN (
           ('Sem Óleo', 'sem-oleo'),
           ('Hipoalergênico', 'hipoalergenico'),
           ('Não Comedogênico', 'nao-comedogenico')
       );
    IF v_conflict IS NOT NULL THEN
        RAISE EXCEPTION 'Conflitos de nome/slug em profile_tags: %', v_conflict;
    END IF;
END $$;

INSERT INTO venus.profile_tags (name, description, slug, category) VALUES
    ('Sem Óleo', 'Preferência por produtos sem óleo (oil-free)', 'sem-oleo', 'values'),
    ('Hipoalergênico', 'Preferência por produtos hipoalergênicos', 'hipoalergenico', 'values'),
    ('Não Comedogênico', 'Preferência por produtos que não obstruem os poros', 'nao-comedogenico', 'values')
ON CONFLICT (slug) DO UPDATE
SET name = EXCLUDED.name,
    description = EXCLUDED.description,
    category = EXCLUDED.category,
    updated_at = NOW();

DO $$
DECLARE
    v_faltando TEXT;
BEGIN
    SELECT string_agg(s.slug, ', ' ORDER BY s.slug)
      INTO v_faltando
      FROM unnest(ARRAY[
          'controle-de-oleosidade','muito-seca','reativa','pele-acneica','rosacea',
          'eczema','hiperpigmentacao','melasma','couro-cabeludo-seco',
          'couro-cabeludo-oleoso','caspa','couro-cabeludo-sensivel','gravidez',
          'amamentacao','vegano','cruelty-free','sem-parabenos','sem-sulfato',
          'sem-silicone','sem-alcool','sem-oleo','ingredientes-naturais','organico',
          'hipoalergenico','nao-comedogenico','testado-dermatologicamente',
          'recyclable-packaging'
      ]) AS s(slug)
     WHERE NOT EXISTS (SELECT 1 FROM venus.profile_tags pt WHERE pt.slug = s.slug);
    IF v_faltando IS NOT NULL THEN
        RAISE EXCEPTION 'Etiquetas ausentes: %', v_faltando;
    END IF;
END $$;

COMMIT;

SELECT profile_tag_id, name, slug, category
FROM venus.profile_tags
WHERE slug IN ('sem-oleo', 'hipoalergenico', 'nao-comedogenico')
ORDER BY slug;
