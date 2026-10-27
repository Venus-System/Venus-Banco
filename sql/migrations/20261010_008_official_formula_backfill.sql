-- Venus — backfill de fórmulas oficiais verificáveis — 2026-10-10
--
-- Registra somente fórmulas publicadas nas páginas oficiais das marcas.
-- A ausência de SKU/FIL na página foi aceita pelo operador; a URL, a data da
-- captura e a observação de variante ficam preservadas em source_reference.
-- Esta migration não cria scores de risco nem executa a classificação.

BEGIN;

SET LOCAL lock_timeout = '10s';
SET LOCAL statement_timeout = '180s';
SET LOCAL search_path TO venus, public;

WITH formulas(product_id, formula_text, source_reference) AS (
    VALUES
    (1,
     $formula$ÁGUA; GLICEROL; TRIGLICERÍDEO CAPRÍLICO/CÁPRICO; NICOTINAMIDA; ÁLCOOL CETOESTEARÍLICO; FOSFATO DE POTÁSSIO MONOBÁSICO; CERAMIDA NP; CERAMIDA AP; CERAMIDA EOP; CARBÔMER; DIMETICONA; CETOMACROGOL 1000; METOSSULFATO DE BEENTRIMÔNIO; LAUROIL LACTILATO DE SÓDIO; HIALURONATO DE SÓDIO; COLESTEROL; FENOXIETANOL; EDETATO DISSÓDICO; FOSFATO DE POTÁSSIO DIBÁSICO; CAPRILILGLICOL; FITOESFINGOSINA; GOMA XANTANA; DI-ISOESTEARATO DE POLIGLICERILA-3; ETILEXILGLICERINA$formula$,
     'https://www.cerave.com.br/todos-os-produtos/locao-facial-hidratante | official_page_capture=2026-10-10 | formula_version=page_current | accepted_without_sku_fil=true'),
    (7,
     $formula$ÁGUA; NICOTINAMIDA; ÁLCOOL CETÍLICO; TRIGLICERÍDEO CAPRÍLICO/CÁPRICO; GLICEROL; PROPANODIOL; ISONONANOATO DE ISONONILA; ÉSTERES DA JOJOBA; SESQUIESTEARATO DE POLIETILENOGLICOL-20 METIL GLICOSE; ÁLCOOL CETOESTEARÍLICO; DIMETICONA; SESQUIESTEARATO DE METIL GLICOSE; FENOXIETANOL; SORBITOL; METOSSULFATO DE BEENTRIMÔNIO; CARBÔMER; LAUROMACROGOL 400; TROLAMINA; TOCOFEROL; BUTILENOGLICOL; ÓLEO DE AMÊNDOAS; ÓLEO VEGETAL HIDROGENADO; ETILEXILGLICERINA; EDETATO DE SÓDIO; LAUROIL LACTILATO DE SÓDIO; HIDRÓXIDO DE SÓDIO; CITRATO DE ZINCO; EXTRATO DE ASPARAGOPSIS ARMATA; EXTRATO DE EQUISETUM ARVENSE; MALTODEXTRINA; EXTRATO DA FOLHA DE ALOE BARBADENSIS; EXTRATO DE ASCOPHYLLUM NODOSUM; EXTRATO DE CHRYSANTHELLUM INDICUM; CERAMIDA NP; CERAMIDA AP; FITOESFINGOSINA; COLESTEROL; GOMA XANTANA; SORBATO DE POTÁSSIO; HIALURONATO DE SÓDIO; CERAMIDA EOP$formula$,
     'https://www.cerave.com.br/todos-os-produtos/creme-reparador-para-olhos | official_page_capture=2026-10-10 | formula_version=page_current | accepted_without_sku_fil=true'),
    (22,
     $formula$AQUA / WATER$formula$,
     'https://www.laroche-posay.com.br/thermal-spring-water/agua-termal | official_page_capture=2026-10-10 | formula_version=page_current'),
    (24,
     $formula$AQUA / WATER; GLYCERIN; CYCLOHEXASILOXANE; ALCOHOL DENAT; PENTYLENE GLYCOL; NIACINAMIDE; DIMETHICONE; GLYCINE SOJA OIL / SOYBEAN OIL; PPG-6-DECYLTETRADECETH-30; SODIUM HYALURONATE; RETINOL; ADENOSINE; AMMONIUM POLYACRYLOYLDIMETHYL TAURATE; CAPRYLYL GLYCOL; CITRIC ACID; TRISODIUM ETHYLENEDIAMINE DISUCCINATE; XANTHAN GUM; POLYSILICONE-11; RETINYL PALMITATE; TOCOPHEROL; PHENOXYETHANOL; PARFUM / FRAGRANCE$formula$,
     'https://www.laroche-posay.com.br/retinol/redermic-retinol-b3-serum | official_page_capture=2026-10-10 | formula_version=page_current'),
    (25,
     $formula$AQUA / WATER / EAU; DIMETHICONE; NIACINAMIDE; GLYCERIN; PROPYLENE GLYCOL; POLYSILICONE-11; SILICA; BIS-PEG/PPG-16/16 PEG/PPG-16/16 DIMETHICONE; CYSTOSEIRA TAMARISCIFOLIA EXTRACT; 2-MERCAPTONICOTINOYL GLYCINE; PEG-20 METHYL GLUCOSE SESQUISTEARATE; SODIUM HYALURONATE; SODIUM HYDROXIDE; SODIUM THIOSULFATE; CARNOSINE; POLOXAMER 338; AMMONIUM POLYACRYLOYLDIMETHYL TAURATE; DIPOTASSIUM GLYCYRRHIZATE; CAPRYLIC/CAPRIC TRIGLYCERIDE; CAPRYLOYL SALICYLIC ACID; CAPRYLYL GLYCOL; CITRIC ACID; TRISODIUM ETHYLENEDIAMINE DISUCCINATE; XANTHAN GUM; PENTYLENE GLYCOL; OCTYLDODECANOL; RETINYL PALMITATE; TOCOPHEROL; PENTAERYTHRITYL TETRA-DI-T-BUTYL HYDROXYHYDROCINNAMATE; PHENOXYETHANOL; CI 17200 / RED 33; PARFUM / FRAGRANCE$formula$,
     'https://www.laroche-posay.com.br/mela-b3/serum-antimanchas | official_page_capture=2026-10-10 | formula_version=page_current'),
    (28,
     $formula$AQUA / WATER; SILICA; HOMOSALATE; ISONONYL ISONONANOATE; ETHYLHEXYL TRIAZONE; BUTYL METHOXYDIBENZOYLMETHANE; BIS-ETHYLHEXYLOXYPHENOL METHOXYPHENYL TRIAZINE; DIISOPROPYL SEBACATE; GLYCERIN; OCTOCRYLENE; CAPRYLYL METHICONE; PENTYLENE GLYCOL; PHENYLBENZIMIDAZOLE SULFONIC ACID; ALUMINUM STARCH OCTENYLSUCCINATE; TRIETHANOLAMINE; TITANIUM DIOXIDE; POTASSIUM CETYL PHOSPHATE; PROPYLENE GLYCOL; STEARIC ACID; PHENOXYETHANOL; PALMITIC ACID; PEG-100 STEARATE; GLYCERYL STEARATE; AMMONIUM ACRYLOYLDIMETHYLTAURATE/VP COPOLYMER; SODIUM METHYL STEAROYL TAURATE; STEARYL ALCOHOL; CAPRYLYL GLYCOL; TEREPHTHALYLIDENE DICAMPHOR SULFONIC ACID; TOCOPHEROL; POLOXAMER 338; ACRYLATES/C10-30 ALKYL ACRYLATE CROSSPOLYMER; ALUMINUM HYDROXIDE; DISODIUM EDTA; SILICA SILYLATE; METHYLENE BIS-BENZOTRIAZOLYL TETRAMETHYLBUTYLPHENOL; MYRISTIC ACID; T-BUTYL ALCOHOL; POLYGLYCERYL-10 LAURATE; BUTYLENE GLYCOL; BHT$formula$,
     'https://www.laroche-posay.com.br/anthelios/xl-protect-face-fps60 | official_page_capture=2026-10-10 | formula_version=page_current | exact_product_variant=true'),
    (30,
     $formula$AQUA / WATER; PEG-7 CAPRYLIC/CAPRIC GLYCERIDES; POLOXAMER 124; POLOXAMER 184; PEG-6 CAPRYLIC/CAPRIC GLYCERIDES; GLYCERIN; POLYSORBATE 80; DISODIUM EDTA; BHT; MYRTRIMONIUM BROMIDE; PARFUM / FRAGRANCE$formula$,
     'https://www.laroche-posay.com.br/micellaire/solucao-micelar-ultra-peles-sensiveis | official_page_capture=2026-10-10 | formula_version=page_current'),
    (32,
     $formula$AQUA / WATER; GLYCERIN; SQUALANE; DIMETHICONE; ZEA MAYS STARCH / CORN STARCH; NIACINAMIDE; AMMONIUM POLYACRYLOYLDIMETHYL TAURATE; MYRISTYL MYRISTATE; STEARIC ACID; CERAMIDE NP; POTASSIUM CETYL PHOSPHATE; GLYCERYL STEARATE SE; SODIUM HYDROXIDE; MYRISTIC ACID; PALMITIC ACID; CAPRYLOYL GLYCINE; CAPRYLYL GLYCOL; XANTHAN GUM$formula$,
     'https://www.laroche-posay.com.br/toleriane/sensitive | official_page_capture=2026-10-10 | formula_version=page_current'),
    (33,
     $formula$ÁGUA; POLI-ISOBUTENO HIDROGENADO; DIMETICONA; GLICEROL; MANTEIGA DE BUTYROSPERMUM PARKII; PANTENOL; AMIDO; PROPANODIOL; BUTILENOGLICOL; CETIL POLIETILENOGLICOL/POLIPROPILENOGLICOL-10/1 DIMETICONA; TRI-HIDROXIESTEARINA; EXTRATO DE FOLHA DE CENTELLA ASIATICA; SUCO DA RAIZ DE POLYMNIA SONCHIFOLIA; GLICONATO DE ZINCO; MADECASSOSIDE; GLICONATO DE MANGANÊS; ALFA-GLUCANO OLIGOSSACARÍDEO; DIÓXIDO DE SILÍCIO; HIDRÓXIDO DE ALUMÍNIO; SULFATO DE MAGNÉSIO; DEXTROMANOSE; CAPRILOIL GLICINA; CAPRILILGLICOL; FERMENTO DE VITREOSCILLA; ÁCIDO CÍTRICO; DISSUCCINATO DE ETILENODIAMINA TRISSÓDICO; LACTOBACILLUS; ESTEARATO DE ETILENOGLICOL ACETILADO; MALTODEXTRINA; PENTILENOGLICOL; ISOESTEARATO DE POLIGLICERILA-4; TOCOFEROL; TETRA-DI-T-BUTIL HIDRÓXI-HIDROCINAMATO DE PENTAERITRITILA; DIÓXIDO DE TITÂNIO$formula$,
     'https://www.laroche-posay.com.br/cicaplast/baume-b5-plus | official_page_capture=2026-10-10 | formula_version=page_current'),
    (34,
     $formula$AQUA / WATER; BUTYROSPERMUM PARKII BUTTER / SHEA BUTTER; GLYCERIN; DIMETHICONE; NIACINAMIDE; CETEARYL ALCOHOL; BRASSICA CAMPESTRIS SEED OIL / RAPESEED SEED OIL; GLYCERYL STEARATE; AMMONIUM POLYACRYLOYLDIMETHYL TAURATE; PEG-100 STEARATE; PROPANEDIOL; OPHIOPOGON JAPONICUS ROOT EXTRACT; PEG-20 METHYL GLUCOSE SESQUISTEARATE; SORBITAN TRISTEARATE; DIMETHICONOL; SODIUM CHLORIDE; MANNOSE; COCO-BETAINE; DISODIUM EDTA; CAPRYLOYL GLYCINE; CAPRYLYL GLYCOL; VITREOSCILLA FERMENT; CITRIC ACID; MALTODEXTRIN; XANTHAN GUM; TOCOPHEROL; PENTAERYTHRITYL TETRA-DI-T-BUTYL HYDROXYHYDROCINNAMATE$formula$,
     'https://www.laroche-posay.com.br/lipikar/baume-ap-m | official_page_capture=2026-10-10 | formula_version=page_current'),
    (35,
     $formula$AQUA / WATER; GLYCERIN; NIACINAMIDE; DIMETHICONE; PARAFFINUM LIQUIDUM / MINERAL OIL; CAPRYLIC/CAPRIC TRIGLYCERIDE; AMMONIUM ACRYLOYLDIMETHYHLTAURATE / STEARETH 25 METACRYLATE CROSSPOLYMER; PROPYLENE GLYCOL; BRASSICA CAMPESTRIS OLEIFERA OIL / RAPESEED SEED OIL; DIMETHICONOL; ISOHEXADECANE; DISODIUM EDTA; CAPRYLYL GLYCOL; XANTHAN GUM; POLYSORBATE 80; ACRYLAMIDE/SODIUM; ACRYLOYLDIMETHYHLTAURATE COPOLYMER; BUTYROSPERMUM PARKII BUTTER / SHEA BUTTER; PHENOXYETHANOL$formula$,
     'https://www.laroche-posay.com.br/lipikar/locao | official_page_capture=2026-10-10 | formula_version=page_current'),
    (43,
     $formula$Aqua; Glycerin; Alcohol Denat.; C12-15 Alkyl Benzoate; Butyl Methoxydibenzoylmethane; Butylene Glycol Dicaprylate/Dicaprate; Ethylhexyl Salicylate; Bis-Ethylhexyloxyphenol Methoxyphenyl Triazine; Cetearyl Alcohol; Dibutyl Adipate; Ethylhexyl Triazone; Phenylbenzimidazole Sulfonic Acid; Tapioca Starch; Behenyl Alcohol; Sodium Hyaluronate; Glycine Soja Germ Extract; Glycyrrhetinic Acid; Glyceryl Stearate; Sodium Stearoyl Glutamate; Xanthan Gum; Sodium Hydroxide; Sodium Chloride; Carbomer; Acrylates/C10-30 Alkyl Acrylate Crosspolymer; Dimethicone; Trisodium EDTA; Ethylhexylglycerin; Phenoxyethanol; Pentaerythrityl Tetra-di-t-butyl Hydroxyhydrocinnamate; Parfum$formula$,
     'https://www.eucerin.com.br/paginas-especiais/ingredientes/hyaluron-filler-dia | official_page_capture=2026-10-10 | formula_version=page_current'),
    (44,
     $formula$Aqua; Alcohol Denat.; Glycerin; Lactic Acid; Glycolic Acid; Sodium Hydroxide; Sodium Hyaluronate; Glucosylrutin; Isoquercitrin; Sodium Ascorbyl Phosphate; Citric Acid; PEG-40 Hydrogenated Castor Oil; Trisodium EDTA; Parfum$formula$,
     'https://www.eucerin.com.br/paginas-especiais/ingredientes/hyaluron-filler-pore-minimizer | official_page_capture=2026-10-10 | formula_version=page_current'),
    (46,
     $formula$Aqua; Glycerin; Isopropyl Palmitate; Cetyl Alcohol; Glyceryl Stearate; Glyceryl Stearate Citrate; Alcohol Denat.; Coco-Caprylate/Caprate; Butyrospermum Parkii Butter; Helianthus Annuus Seed Oil; Panthenol; Pantolactone; Caprylyl Glycol; Hydroxypropyl Starch Phosphate; Xanthan Gum; Hydroxyacetophenone; Ethylhexylglycerin; Phenoxyethanol; Sodium Citrate; Citric Acid; Parfum$formula$,
     'https://www.eucerin.com.br/paginas-especiais/ingredientes/ph5-gel-creme-hidratante-mini | official_page_capture=2026-10-10 | formula_version=page_current | accepted_without_sku_fil=true'),
    (47,
     $formula$Aqua; Glycerin; Sodium Coco-Sulfate; Cocamidopropyl Betaine; Coco-Glucoside; Caprylyl/Capryl Glucoside; Citric Acid; Ricinus Communis Seed Oil; Olea Europaea Fruit Oil; Glycine Soja Oil; Niacinamide; Panthenol; Pantolactone; Sodium Citrate; Sodium Chloride; Propyl Gallate; Sodium Benzoate; Parfum$formula$,
     'https://www.eucerin.com.br/produtos/pele-sensivel/eucerin-ph5-gel---%C3%B3leo-de-banho-400ml | official_page_capture=2026-10-10 | formula_version=page_current'),
    (49,
     $formula$Paraffinum Liquidum; Cera Microcristallina; Ceresin; Lanolin Alcohol; Panthenol; Glycerin; Bisabolol$formula$,
     'https://www.eucerin.com.br/paginas-especiais/ingredientes/aquaphor-49 | official_page_capture=2026-10-10 | formula_version=page_current'),
    (50,
     $formula$Aqua; Alcohol Denat.; Sodium Cocoamphoacetate; Glycerin; Coco-Betaine; Lactic Acid; Sodium Chloride; Dehydroxanthan Gum; Glycolic Acid; Glyceryl Glucoside; Sodium Hydroxide; Sodium Benzoate$formula$,
     'https://www.eucerin.com.br/paginas-especiais/ingredientes/anti-pigment-gel-de-limpeza-esfoliante-sachet | official_page_capture=2026-10-10 | formula_version=page_current | official_page_variant=sachet_3g_same_product_label | accepted_without_sku_fil=true'),
    (51,
     $formula$Aqua; Alcohol Denat.; Butylene Glycol; Glycerin; Isopropyl Palmitate; Cetearyl Isononanoate; Diisopropyl Adipate; Propylheptyl Caprylate; Cetearyl Alcohol; Distarch Phosphate; Isobutylamido Thiazolyl Resorcinol; Sodium Ascorbyl Phosphate; Sodium Hyaluronate; Glycyrrhiza Inflata Root Extract; Tocopherol; Glucosylrutin; Sodium Stearoyl Glutamate; Glyceryl Stearate; Hydroxypropyl Starch Phosphate; Dehydroxanthan Gum; Xanthan Gum; Gellan Gum; Dimethicone; Isoquercitrin; Citric Acid; Sodium Chloride; Ethylhexylglycerin; Trisodium EDTA; Phenoxyethanol; Parfum$formula$,
     'https://www.eucerin.com.br/paginas-especiais/ingredientes/anti-pigment-dual-serum | official_page_capture=2026-10-10 | formula_version=page_current'),
    (52,
     $formula$Aqua; Homosalate; Alcohol Denat.; Butyl Methoxydibenzoylmethane; Ethylhexyl Salicylate; Ethylhexyl Triazone; Bis-Ethylhexyloxyphenol Methoxyphenyl Triazine; Butylene Glycol Dicaprylate/Dicaprate; Tapioca Starch; Distarch Phosphate; C12-15 Alkyl Benzoate; Phenylbenzimidazole Sulfonic Acid; Isobutylamido Thiazolyl Resorcinol; Glycyrrhiza Inflata Root Extract; Tocopherol; Glucosylrutin; Isoquercitrin; Glycerin; Cetyl Alcohol; Stearyl Alcohol; Sodium Chloride; Xanthan Gum; Carbomer; Sodium Hydroxide; Glyceryl Stearate; Sodium Stearoyl Glutamate; Dimethicone; Phenoxyethanol; Trisodium EDTA; Parfum$formula$,
     'https://www.eucerin.com.br/paginas-especiais/ingredientes/anti-pigment-dia | official_page_capture=2026-10-10 | formula_version=page_current'),
    (53,
     $formula$Aqua; Glycerin; Alcohol Denat.; Cetearyl Alcohol; Cocoglycerides; Butyrospermum Parkii Butter; Cetearyl Isononanoate; Glyceryl Stearate Citrate; Tapioca Starch; Hydrogenated Coco-Glycerides; Squalane; Salicylic Acid; Decylene Glycol; Isobutylamido Thiazolyl Resorcinol; Glycyrrhiza Inflata Root Extract; Xanthan Gum; Hydroxypropyl Starch Phosphate; Carrageenan; Phenoxyethanol; Trisodium Ethylenediamine Disuccinate; Sodium Hydroxide; Parfum$formula$,
     'https://www.eucerin.com.br/paginas-especiais/ingredientes/dermopure-clinical-creme-corporal | official_page_capture=2026-10-10 | formula_version=page_current'),
    (54,
     $formula$Aqua; Alcohol Denat.; Glycerin; Tapioca Starch; Carbomer; Salicylic Acid; Isobutylamido Thiazolyl Resorcinol; Decylene Glycol; Glycyrrhiza Inflata Root Extract; Panthenol; Glucosylrutin; Isoquercitrin; Ammonium Acryloyldimethyltaurate/VP Copolymer; Pantolactone; Sodium Hydroxide; Trisodium EDTA; Citric Acid; Parfum$formula$,
     'https://www.eucerin.com.br/paginas-especiais/ingredientes/dermopure | official_page_capture=2026-10-10 | formula_version=page_current'),
    (55,
     $formula$Aqua; Glycolic Acid; Dimethicone; Glycerin; Tapioca Starch; Cetearyl Alcohol; Glyceryl Stearate; Sodium Hydroxide; Gluconolactone; PEG-40 Stearate; PEG-150 Distearate; Salicylic Acid; Glycyrrhiza Inflata Root Extract; Panthenol; Xanthan Gum; Trisodium EDTA; Phenoxyethanol; Parfum$formula$,
     'https://www.eucerin.com.br/paginas-especiais/ingredientes/dermopure-acao-renovadora | official_page_capture=2026-10-10 | formula_version=page_current'),
    (56,
     $formula$Aqua; Coco-Glucoside; Salicylic Acid; Glycerin; Xanthan Gum; Sodium Laureth Sulfate; PEG-8; Alcohol Denat.; Glycolic Acid; Gluconolactone; Phenoxyethanol; Trisodium Ethylenediamine Disuccinate; Citric Acid; Sodium Hydroxide; Parfum$formula$,
     'https://www.eucerin.com.br/paginas-especiais/ingredientes/dermopure-gel-concentrado | official_page_capture=2026-10-10 | formula_version=page_current')
)
INSERT INTO venus.product_labels (
    fk_product_version_id,
    normalized_text,
    language,
    source_type,
    source_reference
)
SELECT pv.product_version_id,
       f.formula_text,
       'pt-BR',
       'official_site',
       f.source_reference
  FROM formulas f
  JOIN venus.product_versions pv
    ON pv.fk_product_id = f.product_id
   AND pv.is_current = TRUE
ON CONFLICT (fk_product_version_id) DO UPDATE
   SET normalized_text = EXCLUDED.normalized_text,
       language = EXCLUDED.language,
       source_type = EXCLUDED.source_type,
       source_reference = EXCLUDED.source_reference,
       updated_at = NOW();

-- O trigger acima reprocessa antes de os tokens novos entrarem no catálogo.
-- Cadastramos somente tokens da fonte oficial e reprocessamos uma segunda vez.
INSERT INTO venus.ingredients (
    fk_ingredient_category_id,
    inci_name,
    source_type,
    source_reference
)
SELECT cat.ingredient_category_id,
       UPPER(BTRIM(t.raw_token)),
       'official_site',
       MIN(pl.source_reference)
  FROM venus.product_versions pv
  JOIN venus.product_labels pl
    ON pl.fk_product_version_id = pv.product_version_id
  CROSS JOIN LATERAL venus.fn_split_product_label_tokens(pl.normalized_text) t
  JOIN venus.ingredient_categories cat
    ON cat.name = 'Não classificado'
 WHERE pv.is_current
   AND pl.source_type = 'official_site'
   AND venus.fn_normalize_ingredient_token(pl.normalized_text) NOT LIKE 'catalogooficial%'
   AND BTRIM(t.raw_token) <> ''
   AND LENGTH(BTRIM(t.raw_token)) BETWEEN 2 AND 300
   AND t.raw_token ~ '[[:alpha:]]'
   AND NOT EXISTS (
       SELECT 1
         FROM venus.ingredients i
        WHERE venus.fn_normalize_ingredient_token(i.inci_name) =
              venus.fn_normalize_ingredient_token(t.raw_token)
   )
 GROUP BY cat.ingredient_category_id,
          venus.fn_normalize_ingredient_token(t.raw_token),
          UPPER(BTRIM(t.raw_token));

-- Corrige a ordem de verificação do resolvedor: DELETE de issues não pode
-- sobrescrever o resultado de FOUND produzido pelo SELECT do rótulo.
CREATE OR REPLACE FUNCTION venus.fn_resolve_product_label_ingredients(
    p_product_version_id BIGINT
)
RETURNS TABLE (
    total_tokens INTEGER,
    resolved_tokens INTEGER,
    unresolved_tokens INTEGER,
    validation_status TEXT
)
LANGUAGE PLPGSQL
AS $$
DECLARE
    v_raw_text TEXT;
    v_source_reference TEXT;
    v_source_type TEXT;
    v_total INTEGER := 0;
    v_resolved INTEGER := 0;
    v_unresolved INTEGER := 0;
BEGIN
    SELECT pl.normalized_text,
           pl.source_reference,
           pl.source_type::TEXT
      INTO v_raw_text, v_source_reference, v_source_type
      FROM venus.product_labels pl
     WHERE pl.fk_product_version_id = p_product_version_id;

    IF NOT FOUND OR BTRIM(COALESCE(v_raw_text, '')) = '' THEN
        RETURN QUERY SELECT 0, 0, 0, 'LEGACY_UNVERIFIED'::TEXT;
        RETURN;
    END IF;

    DELETE FROM venus.product_ingredient_resolution_issues
     WHERE fk_product_version_id = p_product_version_id;

    IF venus.fn_normalize_ingredient_token(v_raw_text) LIKE 'catalogooficial%' THEN
        PERFORM venus.fn_register_product_composition(
            p_product_version_id,
            COALESCE(NULLIF(v_source_type, ''), 'official_site'),
            COALESCE(v_source_reference, FORMAT('product_label:%s', p_product_version_id)),
            v_raw_text,
            0,
            0,
            1,
            'WARNING',
            MD5(v_raw_text)
        );
        RETURN QUERY SELECT 0, 0, 1, 'LEGACY_UNVERIFIED'::TEXT;
        RETURN;
    END IF;

    CREATE TEMP TABLE IF NOT EXISTS venus_ocr_resolution_tokens (
        token_position INTEGER NOT NULL,
        raw_token TEXT NOT NULL,
        ingredient_id BIGINT,
        candidate_count INTEGER NOT NULL
    ) ON COMMIT DROP;
    TRUNCATE venus_ocr_resolution_tokens;

    INSERT INTO venus_ocr_resolution_tokens (
        token_position,
        raw_token,
        ingredient_id,
        candidate_count
    )
    SELECT t.token_position,
           t.raw_token,
           best.ingredient_id,
           COALESCE(best.candidate_count, 0)::INTEGER
      FROM venus.fn_split_product_label_tokens(v_raw_text) t
      LEFT JOIN LATERAL (
          SELECT MIN(r.fk_ingredient_id) FILTER (
                     WHERE r.resolution_priority = r.best_priority
                 ) AS ingredient_id,
                 COUNT(*) FILTER (
                     WHERE r.resolution_priority = r.best_priority
                 ) AS candidate_count
            FROM (
                SELECT k.fk_ingredient_id,
                       k.resolution_priority,
                       MIN(k.resolution_priority) OVER () AS best_priority
                  FROM venus.ingredient_resolution_keys k
                 WHERE k.normalized_key = venus.fn_normalize_ingredient_token(t.raw_token)
            ) r
      ) best ON TRUE
     ORDER BY t.token_position;

    INSERT INTO venus.product_ingredient_resolution_issues (
        fk_product_version_id,
        token_position,
        raw_token,
        issue_type,
        source_reference
    )
    SELECT p_product_version_id,
           rt.token_position,
           rt.raw_token,
           CASE WHEN rt.candidate_count = 0 THEN 'NOT_FOUND' ELSE 'AMBIGUOUS' END,
           v_source_reference
      FROM venus_ocr_resolution_tokens rt
     WHERE rt.candidate_count <> 1;

    SELECT COUNT(*)::INTEGER,
           COUNT(*) FILTER (WHERE candidate_count = 1)::INTEGER,
           COUNT(*) FILTER (WHERE candidate_count <> 1)::INTEGER
      INTO v_total, v_resolved, v_unresolved
      FROM venus_ocr_resolution_tokens;

    IF v_total > 0 AND v_unresolved = 0 THEN
        DELETE FROM venus.product_ingredients
         WHERE fk_product_version_id = p_product_version_id;

        INSERT INTO venus.product_ingredients (
            fk_product_version_id,
            fk_ingredient_id,
            position
        )
        SELECT p_product_version_id,
               rt.ingredient_id,
               rt.token_position
          FROM venus_ocr_resolution_tokens rt
         WHERE rt.candidate_count = 1
         ORDER BY rt.token_position
        ON CONFLICT (fk_product_version_id, fk_ingredient_id) DO NOTHING;
    END IF;

    PERFORM venus.fn_register_product_composition(
        p_product_version_id,
        COALESCE(NULLIF(v_source_type, ''), 'ocr'),
        COALESCE(v_source_reference, FORMAT('product_label:%s', p_product_version_id)),
        v_raw_text,
        v_total,
        v_resolved,
        v_unresolved,
        CASE WHEN v_total > 0 AND v_unresolved = 0 THEN 'VALID' ELSE 'WARNING' END,
        MD5(v_raw_text)
    );

    RETURN QUERY
    SELECT v_total,
           v_resolved,
           v_unresolved,
           CASE WHEN v_total > 0 AND v_unresolved = 0 THEN 'VALID' ELSE 'WARNING' END;
END;
$$;

CALL venus.sp_resolve_all_current_product_labels();

COMMIT;
