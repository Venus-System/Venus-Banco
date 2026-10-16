-- Venus — classificação de fragrâncias e matérias-primas aromáticas — 2026-10-10
--
-- Estratégia conservadora:
--   1. promove para "Agente Perfumante" somente a allowlist primária;
--   2. preserva categorias atuais e registra relações secundárias para óleos
--      essenciais/matérias-primas aromáticas;
--   3. não reclassifica extratos, águas, flores ou pós de forma automática.

BEGIN;

SET LOCAL lock_timeout = '10s';
SET LOCAL statement_timeout = '120s';
SET LOCAL search_path TO venus, public;

DO $$
BEGIN
    IF to_regclass('venus.ingredients') IS NULL
       OR to_regclass('venus.ingredient_categories') IS NULL THEN
        RAISE EXCEPTION 'Schema Venus não está pronto para a migration de fragrâncias';
    END IF;
END;
$$;

INSERT INTO venus.ingredient_categories (name, description)
VALUES
    ('Fragrância', 'Categoria raiz para ingredientes e matérias-primas aromáticas.'),
    ('Agente Perfumante', 'Ingredientes utilizados principalmente para conferir ou compor fragrância.')
ON CONFLICT (name) DO NOTHING;

UPDATE venus.ingredient_categories AS child
   SET parent_ingredient_category_id = parent.ingredient_category_id
  FROM venus.ingredient_categories AS parent
 WHERE child.name = 'Agente Perfumante'
   AND parent.name = 'Fragrância'
   AND child.parent_ingredient_category_id IS DISTINCT FROM parent.ingredient_category_id;

CREATE TABLE IF NOT EXISTS venus.ingredient_category_assignments (
    ingredient_category_assignment_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fk_ingredient_id BIGINT NOT NULL
        REFERENCES venus.ingredients(ingredient_id) ON DELETE CASCADE,
    fk_ingredient_category_id BIGINT NOT NULL
        REFERENCES venus.ingredient_categories(ingredient_category_id) ON DELETE RESTRICT,
    assignment_role TEXT NOT NULL DEFAULT 'secondary'
        CHECK (assignment_role = 'secondary'),
    source_type source_type_enum NOT NULL DEFAULT 'admin',
    source_reference TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (fk_ingredient_id, fk_ingredient_category_id)
);

CREATE INDEX IF NOT EXISTS idx_ingredient_category_assignments_ingredient
    ON venus.ingredient_category_assignments (fk_ingredient_id);

CREATE INDEX IF NOT EXISTS idx_ingredient_category_assignments_category
    ON venus.ingredient_category_assignments (fk_ingredient_category_id);

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
          FROM pg_trigger
         WHERE tgrelid = 'venus.ingredient_category_assignments'::regclass
           AND tgname = 'trg_set_updated_at_ingredient_category_assignments'
    ) THEN
        CREATE TRIGGER trg_set_updated_at_ingredient_category_assignments
        BEFORE UPDATE ON venus.ingredient_category_assignments
        FOR EACH ROW
        EXECUTE FUNCTION venus.fn_touch_updated_at();
    END IF;

    IF NOT EXISTS (
        SELECT 1
          FROM pg_trigger
         WHERE tgrelid = 'venus.ingredient_category_assignments'::regclass
           AND tgname = 'trg_audit_ingredient_category_assignments'
    ) THEN
        CREATE TRIGGER trg_audit_ingredient_category_assignments
        AFTER INSERT OR UPDATE OR DELETE ON venus.ingredient_category_assignments
        FOR EACH ROW
        EXECUTE FUNCTION venus.fn_audit_row();
    END IF;
END;
$$;

CREATE TEMP TABLE _fragrance_primary_allowlist (
    inci_name TEXT PRIMARY KEY
) ON COMMIT DROP;

INSERT INTO _fragrance_primary_allowlist (inci_name)
VALUES
    ('ALPHA-ISOMETHYL IONONE'),
    ('AMYL CINNAMAL'),
    ('AMYLCINNAMYL ALCOHOL'),
    ('ANISE ALCOHOL'),
    ('BENZYL CINNAMATE'),
    ('BUTYLPHENYL METHYLPROPIONAL'),
    ('CINNAMAL'),
    ('CINNAMYL ALCOHOL'),
    ('CITRAL'),
    ('CITRONELLOL'),
    ('COUMARIN'),
    ('EUGENOL'),
    ('FARNESOL'),
    ('GERANIOL'),
    ('HEXYL CINNAMAL'),
    ('HYDROXYCITRONELLAL'),
    ('ISOEUGENOL'),
    ('METHYL 2-OCTYNOATE'),
    ('LAVANDULA HYBRIDA HERB OIL');

DO $$
DECLARE
    v_expected INTEGER;
    v_found INTEGER;
    v_non_pending TEXT;
    v_updated INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_expected FROM _fragrance_primary_allowlist;

    SELECT COUNT(*)
      INTO v_found
      FROM _fragrance_primary_allowlist AS a
      JOIN venus.ingredients AS i ON i.inci_name = a.inci_name;

    IF v_found <> v_expected THEN
        SELECT STRING_AGG(a.inci_name, ', ' ORDER BY a.inci_name)
          INTO v_non_pending
          FROM _fragrance_primary_allowlist AS a
          LEFT JOIN venus.ingredients AS i ON i.inci_name = a.inci_name
         WHERE i.ingredient_id IS NULL;
        RAISE EXCEPTION 'Allowlist primária incompleta; ausentes: %', v_non_pending;
    END IF;

    SELECT STRING_AGG(i.inci_name, ', ' ORDER BY i.inci_name)
      INTO v_non_pending
      FROM venus.ingredients AS i
      JOIN _fragrance_primary_allowlist AS a ON a.inci_name = i.inci_name
      JOIN venus.ingredient_categories AS c
        ON c.ingredient_category_id = i.fk_ingredient_category_id
     WHERE c.name IS DISTINCT FROM 'Não classificado';

    IF v_non_pending IS NOT NULL THEN
        RAISE EXCEPTION 'Allowlist primária contém ingredientes já classificados: %', v_non_pending;
    END IF;

    UPDATE venus.ingredients AS i
       SET fk_ingredient_category_id = c.ingredient_category_id,
           source_type = 'admin',
           source_reference = 'migration:20261010_003_fragrance_category_reclassification'
      FROM venus.ingredient_categories AS c
          CROSS JOIN _fragrance_primary_allowlist AS a
     WHERE c.name = 'Agente Perfumante'
       AND a.inci_name = i.inci_name;

    GET DIAGNOSTICS v_updated = ROW_COUNT;

    IF v_updated <> v_expected THEN
        RAISE EXCEPTION 'Atualização primária incompleta: esperados %, atualizados %', v_expected, v_updated;
    END IF;
END;
$$;

CREATE TEMP TABLE _fragrance_secondary_allowlist (
    inci_name TEXT PRIMARY KEY
) ON COMMIT DROP;

INSERT INTO _fragrance_secondary_allowlist (inci_name)
VALUES
    ('BENZYL ALCOHOL'),
    ('BENZYL BENZOATE'),
    ('BENZYL SALICYLATE'),
    ('LIMONENE'),
    ('LINALOOL'),
    ('LAVANDULA ANGUSTIFOLIA HERB OIL'),
    ('CINNAMOMUM CASSIA OIL'),
    ('CINNAMOMUM ZEYLANICUM BARK OIL'),
    ('CINNAMOMUM ZEYLANICUM LEAF OIL'),
    ('CITRUS AURANTIUM BERGAMIA LEAF OIL'),
    ('CITRUS AURANTIUM BERGAMIA PEEL OIL'),
    ('CITRUS AURANTIUM DULCIS FLOWER OIL'),
    ('CITRUS AURANTIUM DULCIS PEEL OIL EXPRESSED'),
    ('CITRUS AURANTIUM LEAF OIL'),
    ('CITRUS AURANTIUM PEEL OIL EXPRESSED'),
    ('CITRUS BERGAMIA LEAF OIL'),
    ('CITRUS BERGAMIA PEEL OIL EXPRESSED'),
    ('CITRUS NOBILIS LEAF OIL'),
    ('CITRUS NOBILIS PEEL OIL EXPRESSED'),
    ('CITRUS PARADISI M. PEEL OIL EXPRESSED'),
    ('EUCALYPTUS GLOBULUS LEAF/TWIG OIL'),
    ('MENTHA ARVENSIS HERB OIL'),
    ('MENTHA ARVENSIS LEAF/STEM OIL'),
    ('MENTHA SPICATA HERB OIL'),
    ('PINUS PINASTER TWIG LEAF OIL'),
    ('PINUS SYLVESTRIS TWIG LEAF OIL'),
    ('ROSA GALLICA FLOWER OIL'),
    ('ROSMARINUS OFFICINALIS FLOWER OIL'),
    ('ROSMARINUS OFFICINALIS LEAF/STEM OIL'),
    ('ROSMARINUS OFFICINALIS STEM OIL'),
    ('SANTALUM ALBUM WOOD OIL'),
    ('THYMUS SERPILLUM OIL');

INSERT INTO venus.ingredient_category_assignments (
    fk_ingredient_id,
    fk_ingredient_category_id,
    assignment_role,
    source_type,
    source_reference
)
SELECT i.ingredient_id,
       c.ingredient_category_id,
       'secondary',
       'admin',
       'migration:20261010_003_fragrance_category_reclassification'
  FROM venus.ingredients AS i
  JOIN _fragrance_secondary_allowlist AS a ON a.inci_name = i.inci_name
  JOIN venus.ingredient_categories AS c ON c.name = 'Agente Perfumante'
ON CONFLICT (fk_ingredient_id, fk_ingredient_category_id) DO NOTHING;

CREATE OR REPLACE VIEW venus.v_ingredient_category_links AS
SELECT i.ingredient_id,
       i.inci_name,
       i.common_name,
       c.ingredient_category_id,
       c.name AS category_name,
       'primary'::TEXT AS assignment_role
  FROM venus.ingredients AS i
  JOIN venus.ingredient_categories AS c
    ON c.ingredient_category_id = i.fk_ingredient_category_id
UNION ALL
SELECT i.ingredient_id,
       i.inci_name,
       i.common_name,
       c.ingredient_category_id,
       c.name AS category_name,
       a.assignment_role
  FROM venus.ingredient_category_assignments AS a
  JOIN venus.ingredients AS i ON i.ingredient_id = a.fk_ingredient_id
  JOIN venus.ingredient_categories AS c
    ON c.ingredient_category_id = a.fk_ingredient_category_id;

COMMIT;
