/*
  CeraVe: restaura a composição oficial das versões atuais dos dois
  cadastros do limpador Creme-espuma/Espuma Cremosa.

  Fonte brasileira consultada em 2026-10-04:
  https://www.cerave.com.br/todos-os-produtos/espuma-cremosa-de-limpeza-hidratante
  A fórmula publicada informa o código F.I.L. D253447/1. A lista INCI abaixo
  usa a nomenclatura INCI correspondente à mesma fórmula oficial; CI 77891 é
  o registro canônico do catálogo para "CI 77891 / Titanium Dioxide".

  A migration resolve os produtos pelos slugs, e não presume que IDs de
  identity sejam iguais entre ambientes. Ela não remove vínculos existentes:
  se encontrar composição diferente, aborta para revisão manual.
*/

BEGIN;

CREATE TEMP TABLE _cerave_formula (
    position INTEGER PRIMARY KEY,
    inci_name TEXT NOT NULL
) ON COMMIT DROP;

INSERT INTO _cerave_formula (position, inci_name)
VALUES
    (1, 'Aqua'),
    (2, 'Glycerin'),
    (3, 'Sodium Methyl Cocoyl Taurate'),
    (4, 'Coco-Betaine'),
    (5, 'Sodium Cocoyl Isethionate'),
    (6, 'Sodium Chloride'),
    (7, 'PCA'),
    (8, 'PPG-5-Ceteth-20'),
    (9, 'PEG-100 Stearate'),
    (10, 'PEG-150 Pentaerythrityl Tetrastearate'),
    (11, 'PEG-6 Caprylic/Capric Glycerides'),
    (12, 'PEG-30 Dipolyhydroxystearate'),
    (13, 'CI 77891'),
    (14, 'Aspartic Acid'),
    (15, 'Ceramide NP'),
    (16, 'Ceramide AP'),
    (17, 'Ceramide EOP'),
    (18, 'Sorbitan Isostearate'),
    (19, 'Carbomer'),
    (20, 'Glycol Distearate'),
    (21, 'Glyceryl Stearate'),
    (22, 'Glyceryl Oleate'),
    (23, 'Glycine'),
    (24, 'Trideceth-6'),
    (25, 'Cetearyl Alcohol'),
    (26, 'Behentrimonium Methosulfate'),
    (27, 'Threonine'),
    (28, 'Sodium Hydroxide'),
    (29, 'Salicylic Acid'),
    (30, 'Sodium PCA'),
    (31, 'Sodium Lactate'),
    (32, 'Arginine'),
    (33, 'Sodium Lauroyl Lactylate'),
    (34, 'Serine'),
    (35, 'Sodium Benzoate'),
    (36, 'Valine'),
    (37, 'Sodium Hyaluronate'),
    (38, 'Proline'),
    (39, 'Isoleucine'),
    (40, 'Cholesterol'),
    (41, 'Phenoxyethanol'),
    (42, 'Alanine'),
    (43, 'Phenylalanine'),
    (44, 'Coconut Acid'),
    (45, 'Coco-Glucoside'),
    (46, 'Chlorphenesin'),
    (47, 'Disodium EDTA'),
    (48, 'Hydroxyethyl Urea'),
    (49, 'Citric Acid'),
    (50, 'Hydroxyethyl Acrylate/Sodium Acryloyldimethyl Taurate Copolymer'),
    (51, 'Caprylyl Glycol'),
    (52, 'Phytosphingosine'),
    (53, 'Xanthan Gum'),
    (54, 'Histidine'),
    (55, 'Acrylates/C10-30 Alkyl Acrylate Crosspolymer'),
    (56, 'Polyquaternium-53'),
    (57, 'Polyquaternium-39'),
    (58, 'Polysorbate 60'),
    (59, 'Ethylhexylglycerin'),
    (60, 'Benzoic Acid');

CREATE TEMP TABLE _cerave_targets (
    slug TEXT PRIMARY KEY,
    product_id BIGINT NOT NULL,
    product_version_id BIGINT NOT NULL
) ON COMMIT DROP;

INSERT INTO _cerave_targets (slug, product_id, product_version_id)
SELECT p.slug, p.product_id, pv.product_version_id
FROM venus.products p
JOIN venus.product_versions pv
  ON pv.fk_product_id = p.product_id
 AND pv.is_current
WHERE p.slug IN (
    'cerave-espuma-cremosa-limpeza-hidratante',
    'cerave-creme-espuma-hidratante'
);

DO $$
DECLARE
    v_target_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_target_count FROM _cerave_targets;
    IF v_target_count <> 2 THEN
        RAISE EXCEPTION
            'Esperadas duas versões current CeraVe pelos slugs; encontradas %.',
            v_target_count;
    END IF;
END;
$$;

/*
  Estes são os ingredientes ausentes no catálogo atual. O cadastro mínimo
  mantém a fonte oficial e não inventa função, risco ou propriedade científica;
  a curadoria científica pode enriquecê-los posteriormente pela API/admin.
*/
INSERT INTO venus.ingredients (
    fk_ingredient_category_id,
    inci_name,
    common_name,
    function_summary,
    description,
    source_type,
    source_reference
)
SELECT
    ic.ingredient_category_id,
    missing.inci_name,
    '',
    '',
    '',
    'official_site'::venus.source_type_enum,
    'https://www.cerave.com.br/todos-os-produtos/espuma-cremosa-de-limpeza-hidratante'
FROM venus.ingredient_categories ic
 CROSS JOIN (
      VALUES
          ('ASPARTIC ACID'),
          ('CERAMIDE NP'),
          ('CERAMIDE AP'),
          ('CERAMIDE EOP'),
          ('THREONINE'),
          ('PROLINE'),
          ('PHENYLALANINE'),
          ('HYDROXYETHYL UREA'),
          ('PHYTOSPHINGOSINE'),
          ('POLYQUATERNIUM-53'),
          ('HYDROXYETHYL ACRYLATE/SODIUM ACRYLOYLDIMETHYL TAURATE COPOLYMER')
  ) AS missing(inci_name)
WHERE ic.name = 'Não classificado'
  AND NOT EXISTS (
      SELECT 1
      FROM venus.ingredients i
      WHERE UPPER(TRIM(i.inci_name)) = UPPER(TRIM(missing.inci_name))
  )
ON CONFLICT (inci_name) DO NOTHING;

DO $$
DECLARE
    v_missing TEXT;
BEGIN
    SELECT string_agg(f.inci_name, ', ' ORDER BY f.position)
      INTO v_missing
    FROM _cerave_formula f
    LEFT JOIN venus.ingredients i
      ON UPPER(TRIM(i.inci_name)) = UPPER(TRIM(f.inci_name))
    WHERE i.ingredient_id IS NULL;

    IF v_missing IS NOT NULL THEN
        RAISE EXCEPTION 'Ingredientes INCI ausentes no catálogo: %', v_missing;
    END IF;
END;
$$;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM venus.product_versions pv
        JOIN _cerave_targets t
          ON t.product_id = pv.fk_product_id
         AND pv.product_version_id <> t.product_version_id
        WHERE pv.formula_signature = 'F.I.L. D253447/1'
    ) THEN
        RAISE EXCEPTION
            'Já existe outra versão CeraVe com a assinatura F.I.L. D253447/1; revisão manual necessária.';
    END IF;
END;
$$;

UPDATE venus.product_versions pv
SET version_name = 'F.I.L. D253447/1',
    display_name = p.name,
    status = 'verified'::venus.version_status_enum,
    formula_signature = 'F.I.L. D253447/1',
    detected_by = 'official_site'::venus.source_type_enum,
    updated_at = NOW()
FROM _cerave_targets t
JOIN venus.products p ON p.product_id = t.product_id
WHERE pv.product_version_id = t.product_version_id;

INSERT INTO venus.product_labels (
    fk_product_version_id,
    normalized_text,
    language,
    source_type,
    source_reference
)
SELECT
    t.product_version_id,
    string_agg(
        CASE
            WHEN f.position = 13 THEN 'CI 77891 / Titanium Dioxide'
            ELSE f.inci_name
        END,
        ', ' ORDER BY f.position
    ),
    'pt-BR',
    'official_site'::venus.source_type_enum,
    'https://www.cerave.com.br/todos-os-produtos/espuma-cremosa-de-limpeza-hidratante'
FROM _cerave_targets t
CROSS JOIN _cerave_formula f
GROUP BY t.product_version_id
ON CONFLICT (fk_product_version_id) DO UPDATE SET
    normalized_text = EXCLUDED.normalized_text,
    language = EXCLUDED.language,
    source_type = EXCLUDED.source_type,
    source_reference = EXCLUDED.source_reference,
    updated_at = NOW();

/* Nunca sobrescrever uma composição existente que diverge da fórmula oficial. */
DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM venus.product_ingredients pi
        JOIN _cerave_targets t
          ON t.product_version_id = pi.fk_product_version_id
        LEFT JOIN _cerave_formula f ON f.position = pi.position
        LEFT JOIN venus.ingredients i ON i.ingredient_id = pi.fk_ingredient_id
        WHERE f.position IS NULL
           OR UPPER(TRIM(i.inci_name)) <> UPPER(TRIM(f.inci_name))
    ) THEN
        RAISE EXCEPTION
            'As versões CeraVe já possuem vínculos divergentes; backup/revisão manual necessária.';
    END IF;
END;
$$;

INSERT INTO venus.product_ingredients (
    fk_product_version_id,
    fk_ingredient_id,
    position
)
SELECT
    t.product_version_id,
    i.ingredient_id,
    f.position
FROM _cerave_targets t
CROSS JOIN _cerave_formula f
JOIN venus.ingredients i
  ON UPPER(TRIM(i.inci_name)) = UPPER(TRIM(f.inci_name))
ON CONFLICT (fk_product_version_id, fk_ingredient_id) DO NOTHING;

COMMIT;

/* Pós-deploy: ambas as versões devem estar completas e sem o marcador. */
SELECT
    pv.product_version_id,
    p.product_id,
    p.name,
    pv.is_current,
    pv.status,
    COUNT(pi.product_ingredient_id) AS total_ingredientes,
    pl.source_reference,
    pl.normalized_text NOT LIKE 'CATÁLOGO OFICIAL — composição integral não capturada%' AS composition_is_real
FROM venus.product_versions pv
JOIN venus.products p ON p.product_id = pv.fk_product_id
LEFT JOIN venus.product_labels pl ON pl.fk_product_version_id = pv.product_version_id
LEFT JOIN venus.product_ingredients pi ON pi.fk_product_version_id = pv.product_version_id
WHERE p.slug IN (
    'cerave-espuma-cremosa-limpeza-hidratante',
    'cerave-creme-espuma-hidratante'
) AND pv.is_current
GROUP BY pv.product_version_id, p.product_id, p.name, pv.is_current,
         pv.status, pl.source_reference, pl.normalized_text
ORDER BY pv.product_version_id;
