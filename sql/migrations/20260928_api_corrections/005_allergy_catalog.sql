BEGIN;

SET LOCAL search_path TO venus, public;

/*
  Correção 5 — catálogo de alergias só com o que o sistema consegue checar
  ------------------------------------------------------------------------
  A web e o app oferecem a mesma lista de 10 alergias, lida de
  GET /api/allergies. A API de classificação checa alergia por ingrediente
  (user_allergies -> allergy_ingredients -> ingredients), então cada uma das
  10 precisa ter os ingredientes ligados.

  O que o script faz, nesta ordem:

    1. cria 7 ingredientes comuns em rótulo que a limpeza da carga
       (pipeline.py) cortou por serem "Não classificado" sem evidência —
       sem eles, a alergia não pega o produto que traz só esse nome;
    2. renomeia 'Salicylic Acid' -> 'Ácido salicílico' e 'Alcohol' -> 'Álcool'
       (mantém o id, os vínculos e as marcações de quem já escolheu);
    3. cria as 7 alergias que faltam;
    4. liga os ingredientes pelo nome INCI exato (321 vínculos; a lista está
       no próprio arquivo, com a regra de cada alergia);
    5. marca apenas as 10 opções como visíveis e cria a view de catálogo.

  As alergias antigas, user_allergies e allergy_ingredients são preservadas.
  Elas continuam participando da classificação de usuários que já as tinham,
  mas não aparecem para novas seleções em v_available_allergies.

  Para ver antes, sem mudar nada, rode só esta consulta:

    SELECT a.allergy_name, COUNT(ua.user_allergy_id) AS marcacoes
    FROM venus.allergies a
    LEFT JOIN venus.user_allergies ua ON ua.fk_allergy_id = a.allergy_id
    GROUP BY a.allergy_name ORDER BY a.allergy_name;

  A lista de INCI foi conferida contra os 8.028 ingredientes da carga
  (venus_v12_load.sql + limpeza do pipeline.py, repo dd2840d). Se algum nome
  não existir no banco, a conferência desfaz tudo e diz qual.
*/

/* 1. Ingredientes que a limpeza da carga cortou. */
INSERT INTO venus.ingredients (
    fk_ingredient_category_id, inci_name, common_name, source_type, source_reference
)
SELECT c.ingredient_category_id, n.inci_name, n.common_name, 'admin',
       'Migration 20260927_005: rótulo comum de alergia cortado pela limpeza da carga'
FROM (VALUES
    ('PRUNUS AMYGDALUS DULCIS OIL', 'Emoliente', 'ÓLEO DE AMÊNDOAS DOCES'),
    ('HYDROGENATED SWEET ALMOND OIL', 'Emoliente', 'ÓLEO DE AMÊNDOAS DOCES HIDROGENADO'),
    ('LANOLIN OIL', 'Emoliente', 'ÓLEO DE LANOLINA'),
    ('GLYCINE SOJA SEED EXTRACT', 'Não classificado', 'EXTRATO DE SEMENTE DE SOJA'),
    ('GLYCINE SOJA GERM EXTRACT', 'Não classificado', 'EXTRATO DE GÉRMEN DE SOJA'),
    ('GLYCINE SOJA EXTRACT', 'Não classificado', 'EXTRATO DE SOJA'),
    ('METHYLENE GLYCOL', 'Não classificado', 'METILENOGLICOL')
) AS n(inci_name, category_name, common_name)
JOIN venus.ingredient_categories c ON c.name = n.category_name
ON CONFLICT (inci_name) DO NOTHING;

/* 2. Nomes em português, mantendo o id. */
UPDATE venus.allergies SET allergy_name = 'Ácido salicílico' WHERE allergy_name = 'Salicylic Acid';
UPDATE venus.allergies SET allergy_name = 'Álcool' WHERE allergy_name = 'Alcohol';

/* 3. As alergias que faltam. */
INSERT INTO venus.allergies (allergy_name, allergy_type) VALUES
    ('Lanolina', 'ingredient'),
    ('Óleo de amêndoas', 'ingredient'),
    ('Parabenos', 'ingredient'),
    ('Formaldeído', 'ingredient'),
    ('Propilenoglicol', 'ingredient'),
    ('Soja', 'ingredient'),
    ('Sulfatos', 'ingredient')
ON CONFLICT (allergy_name) DO NOTHING;

/* 4. Vínculos alergia -> ingrediente, pelo INCI exato. */
CREATE TEMP TABLE tmp_alergia_inci (
    allergy_name TEXT NOT NULL,
    inci_name    TEXT NOT NULL,
    PRIMARY KEY (allergy_name, inci_name)
) ON COMMIT DROP;

INSERT INTO tmp_alergia_inci (allergy_name, inci_name) VALUES
    -- Lanolina (98): tudo que vem da lanolina: nome INCI com LANOLIN, LANOLATE ou LANETH
    ('Lanolina', 'ACETYLATED HYDROGENATED LANOLIN'),
    ('Lanolina', 'ACETYLATED LANOLIN'),
    ('Lanolina', 'ACETYLATED LANOLIN ALCOHOL'),
    ('Lanolina', 'ACETYLATED LANOLIN RICINOLEATE'),
    ('Lanolina', 'ALUMINUM LANOLATE'),
    ('Lanolina', 'DIMETHICONE PEG-8 LANOLATE'),
    ('Lanolina', 'DIPA-LANOLATE'),
    ('Lanolina', 'DISODIUM LANETH-5 SULFOSUCCINATE'),
    ('Lanolina', 'GLYCERYL LANOLATE'),
    ('Lanolina', 'HYDROGENATED LANETH-20'),
    ('Lanolina', 'HYDROGENATED LANETH-25'),
    ('Lanolina', 'HYDROGENATED LANETH-5'),
    ('Lanolina', 'HYDROGENATED LANOLIN'),
    ('Lanolina', 'HYDROGENATED LANOLIN ALCOHOL'),
    ('Lanolina', 'HYDROXYLATED LANOLIN'),
    ('Lanolina', 'ISOBUTYLATED LANOLIN OIL'),
    ('Lanolina', 'ISOPROPANOLAMINE LANOLATE'),
    ('Lanolina', 'ISOPROPYL LANOLATE'),
    ('Lanolina', 'LANETH-10'),
    ('Lanolina', 'LANETH-10 ACETATE'),
    ('Lanolina', 'LANETH-15'),
    ('Lanolina', 'LANETH-16'),
    ('Lanolina', 'LANETH-20'),
    ('Lanolina', 'LANETH-25'),
    ('Lanolina', 'LANETH-4 PHOSPHATE'),
    ('Lanolina', 'LANETH-40'),
    ('Lanolina', 'LANETH-5'),
    ('Lanolina', 'LANETH-50'),
    ('Lanolina', 'LANETH-60'),
    ('Lanolina', 'LANETH-75'),
    ('Lanolina', 'LANETH-9 ACETATE'),
    ('Lanolina', 'LANOLIN'),
    ('Lanolina', 'LANOLIN ACID'),
    ('Lanolina', 'LANOLIN ALCOHOL'),
    ('Lanolina', 'LANOLIN CERA'),
    ('Lanolina', 'LANOLIN LINOLEATE'),
    ('Lanolina', 'LANOLIN RICINOLEATE'),
    ('Lanolina', 'LANOLIN WAX'),
    ('Lanolina', 'LANOLINAMIDE DEA'),
    ('Lanolina', 'MAGNESIUM LANOLATE'),
    ('Lanolina', 'MIXED ISOPROPANOLAMINES LANOLATE'),
    ('Lanolina', 'OLEYL LANOLATE'),
    ('Lanolina', 'PEG-10 HYDROGENATED LANOLIN'),
    ('Lanolina', 'PEG-10 LANOLATE'),
    ('Lanolina', 'PEG-10 LANOLIN'),
    ('Lanolina', 'PEG-100 LANOLIN'),
    ('Lanolina', 'PEG-12 LANOLATE'),
    ('Lanolina', 'PEG-15 HYDROGENATED LANOLIN'),
    ('Lanolina', 'PEG-15 LANOLATE'),
    ('Lanolina', 'PEG-150 LANOLIN'),
    ('Lanolina', 'PEG-20 HYDROGENATED LANOLIN'),
    ('Lanolina', 'PEG-20 LANOLATE'),
    ('Lanolina', 'PEG-20 LANOLIN'),
    ('Lanolina', 'PEG-24 HYDROGENATED LANOLIN'),
    ('Lanolina', 'PEG-24 LANOLIN'),
    ('Lanolina', 'PEG-27 LANOLIN'),
    ('Lanolina', 'PEG-3 LANOLATE'),
    ('Lanolina', 'PEG-30 HYDROGENATED LANOLIN'),
    ('Lanolina', 'PEG-30 LANOLIN'),
    ('Lanolina', 'PEG-35 LANOLIN'),
    ('Lanolina', 'PEG-4 LANOLATE'),
    ('Lanolina', 'PEG-40 HYDROGENATED LANOLIN'),
    ('Lanolina', 'PEG-40 LANOLIN'),
    ('Lanolina', 'PEG-40 SORBITAN LANOLATE'),
    ('Lanolina', 'PEG-5 HYDROGENATED LANOLIN'),
    ('Lanolina', 'PEG-5 LANOLATE'),
    ('Lanolina', 'PEG-5 LANOLIN'),
    ('Lanolina', 'PEG-5 LANOLINAMIDE'),
    ('Lanolina', 'PEG-50 LANOLIN'),
    ('Lanolina', 'PEG-55 LANOLIN'),
    ('Lanolina', 'PEG-6 LANOLATE'),
    ('Lanolina', 'PEG-60 LANOLIN'),
    ('Lanolina', 'PEG-7 LANOLATE'),
    ('Lanolina', 'PEG-70 HYDROGENATED LANOLIN'),
    ('Lanolina', 'PEG-75 LANOLIN'),
    ('Lanolina', 'PEG-75 LANOLIN OIL'),
    ('Lanolina', 'PEG-75 LANOLIN WAX'),
    ('Lanolina', 'PEG-75 SORBITAN LANOLATE'),
    ('Lanolina', 'PEG-8 LANOLATE'),
    ('Lanolina', 'PEG-85 LANOLIN'),
    ('Lanolina', 'POLYGLYCERYL-2 LANOLIN ALCOHOL ETHER'),
    ('Lanolina', 'PPG-10 LANOLIN ALCOHOL ETHER'),
    ('Lanolina', 'PPG-12-LANETH-50'),
    ('Lanolina', 'PPG-12-PEG-50 LANOLIN'),
    ('Lanolina', 'PPG-12-PEG-65 LANOLIN OIL'),
    ('Lanolina', 'PPG-2 LANOLIN ALCOHOL ETHER'),
    ('Lanolina', 'PPG-20 LANOLIN ALCOHOL ETHER'),
    ('Lanolina', 'PPG-20-PEG-20 HYDROGENATED LANOLIN'),
    ('Lanolina', 'PPG-30 LANOLIN ALCOHOL ETHER'),
    ('Lanolina', 'PPG-40-PEG-60 LANOLIN OIL'),
    ('Lanolina', 'PPG-5 LANOLATE'),
    ('Lanolina', 'PPG-5 LANOLIN ALCOHOL ETHER'),
    ('Lanolina', 'PPG-5 LANOLIN WAX'),
    ('Lanolina', 'PPG-5 LANOLIN WAX GLYCERIDE'),
    ('Lanolina', 'SODIUM LANETH SULFATE'),
    ('Lanolina', 'TEA-LANETH-5 SULFATE'),
    ('Lanolina', 'TRILANETH-4 PHOSPHATE'),
    ('Lanolina', 'LANOLIN OIL'),
    -- Óleo de amêndoas (17): a amêndoa e o que vem dela (óleo em qualquer forma, semente, extrato, proteína); fora casca da árvore, broto, flor, folha, casca dura e os derivados feitos só da gordura (ésteres PEG, glicerídeos, amidas)
    ('Óleo de amêndoas', 'HYDROLYZED SWEET ALMOND PROTEIN'),
    ('Óleo de amêndoas', 'PRUNUS AMYGDALUS AMARA KERNEL COLD PRESSED OIL'),
    ('Óleo de amêndoas', 'PRUNUS AMYGDALUS AMARA SEED EXTRACT'),
    ('Óleo de amêndoas', 'PRUNUS AMYGDALUS DULCIS FRUIT EXTRACT'),
    ('Óleo de amêndoas', 'PRUNUS AMYGDALUS DULCIS FRUIT WATER'),
    ('Óleo de amêndoas', 'PRUNUS AMYGDALUS DULCIS OIL UNSAPONIFIABLES'),
    ('Óleo de amêndoas', 'PRUNUS AMYGDALUS DULCIS OLEOSOMES'),
    ('Óleo de amêndoas', 'PRUNUS AMYGDALUS DULCIS PROTEIN'),
    ('Óleo de amêndoas', 'PRUNUS AMYGDALUS DULCIS SEED EXTRACT'),
    ('Óleo de amêndoas', 'PRUNUS AMYGDALUS DULCIS SEED MEAL'),
    ('Óleo de amêndoas', 'PRUNUS AMYGDALUS DULCIS SEED POWDER'),
    ('Óleo de amêndoas', 'PRUNUS AMYGDALUS DULCIS SEEDCOAT EXTRACT'),
    ('Óleo de amêndoas', 'PRUNUS AMYGDALUS DULCIS SEEDCOAT POWDER'),
    ('Óleo de amêndoas', 'PRUNUS AMYGDALUS SATIVA KERNEL EXTRACT'),
    ('Óleo de amêndoas', 'PRUNUS AMYGDALUS SATIVA KERNEL OIL'),
    ('Óleo de amêndoas', 'PRUNUS AMYGDALUS DULCIS OIL'),
    ('Óleo de amêndoas', 'HYDROGENATED SWEET ALMOND OIL'),
    -- Parabenos (25): todos os parabenos e sais: nome INCI com PARABEN
    ('Parabenos', 'BENZYLPARABEN'),
    ('Parabenos', 'BUTYLPARABEN'),
    ('Parabenos', 'CALCIUM PARABEN'),
    ('Parabenos', 'ETHYLPARABEN'),
    ('Parabenos', 'HEXAMIDINE DIPARABEN'),
    ('Parabenos', 'HEXAMIDINE PARABEN'),
    ('Parabenos', 'ISOBUTYLPARABEN'),
    ('Parabenos', 'ISODECYLPARABEN'),
    ('Parabenos', 'ISOPROPYLPARABEN'),
    ('Parabenos', 'METHYLPARABEN'),
    ('Parabenos', 'PHENOXYETHYLPARABEN'),
    ('Parabenos', 'PHENYLPARABEN'),
    ('Parabenos', 'POTASSIUM BUTYLPARABEN'),
    ('Parabenos', 'POTASSIUM ETHYLPARABEN'),
    ('Parabenos', 'POTASSIUM METHYLPARABEN'),
    ('Parabenos', 'POTASSIUM PARABEN'),
    ('Parabenos', 'POTASSIUM PROPYLPARABEN'),
    ('Parabenos', 'PROPYLPARABEN'),
    ('Parabenos', 'SODIUM BUTYLPARABEN'),
    ('Parabenos', 'SODIUM ETHYLPARABEN'),
    ('Parabenos', 'SODIUM ISOBUTYLPARABEN'),
    ('Parabenos', 'SODIUM METHYLPARABEN'),
    ('Parabenos', 'SODIUM PARABEN'),
    ('Parabenos', 'SODIUM PROPYLPARABEN'),
    ('Parabenos', 'UNDECYLENOYL PEG-5 PARABEN'),
    -- Formaldeído (21): o formaldeído, o metilenoglicol (formaldeído em água, dos alisantes), os conservantes que liberam formaldeído e as resinas feitas de formaldeído
    ('Formaldeído', 'FORMALDEHYDE'),
    ('Formaldeído', 'METHYLENE GLYCOL'),
    ('Formaldeído', '2-BROMO-2-NITROPROPANE-1,3-DIOL'),
    ('Formaldeído', '5-BROMO-5-NITRO-1,3-DIOXANE'),
    ('Formaldeído', '7-ETHYLBICYCLOOXAZOLIDINE'),
    ('Formaldeído', 'BENZYLHEMIFORMAL'),
    ('Formaldeído', 'DIAZOLIDINYL UREA'),
    ('Formaldeído', 'DMDM HYDANTOIN'),
    ('Formaldeído', 'IMIDAZOLIDINYL UREA'),
    ('Formaldeído', 'METHENAMINE'),
    ('Formaldeído', 'QUATERNIUM-15'),
    ('Formaldeído', 'SODIUM HYDROXYMETHYLGLYCINATE'),
    ('Formaldeído', 'TRIS-HYDROXYMETHYLNITROMETHANE'),
    ('Formaldeído', 'MDM HYDANTOIN'),
    ('Formaldeído', 'DEDM HYDANTOIN'),
    ('Formaldeído', 'TOSYLAMIDE/FORMALDEHYDE RESIN'),
    ('Formaldeído', 'ZINC FORMALDEHYDE SULFOXYLATE'),
    ('Formaldeído', 'POLYOXYMETHYLENE UREA'),
    ('Formaldeído', 'BUTYLATED POLYOXYMETHYLENE UREA'),
    ('Formaldeído', 'POLYOXYMETHYLENE MELAMINE'),
    ('Formaldeído', 'POLYOXYMETHYLENE MELAMINE UREA'),
    -- Propilenoglicol (1): só o propilenoglicol; os ésteres (PROPYLENE GLYCOL DICAPRYLATE e parecidos) são outra substância
    ('Propilenoglicol', 'PROPYLENE GLYCOL'),
    -- Ácido salicílico (1): já ligado; renomeada de 'Salicylic Acid'
    ('Ácido salicílico', 'SALICYLIC ACID'),
    -- Látex (1): a borracha natural
    ('Látex', 'RUBBER LATEX'),
    -- Soja (26): a soja e a proteína dela (óleo em qualquer forma, farinha, extrato, proteína, proteína hidrolisada e derivados da proteína); fora os derivados feitos só da gordura (aminas, amidas, betaínas, quaternários, ésteres, glicerídeos, ácido graxo)
    ('Soja', 'AMP-ISOSTEAROYL HYDROLYZED SOY PROTEIN'),
    ('Soja', 'COCODIMONIUM HYDROXYPROPYL HYDROLYZED SOY PROTEIN'),
    ('Soja', 'COCOYL HYDROLYZED SOY PROTEIN'),
    ('Soja', 'EPOXIDIZED SOYBEAN OIL'),
    ('Soja', 'GLYCINE SOJA FLOUR'),
    ('Soja', 'GLYCINE SOJA OIL'),
    ('Soja', 'GLYCINE SOJA OIL UNSAPONIFIABLES'),
    ('Soja', 'GLYCINE SOJA PHYTOPLACENTA EXTRACT'),
    ('Soja', 'GLYCINE SOJA PROTEIN'),
    ('Soja', 'GLYCINE SOJA SEEDCAKE EXTRACT'),
    ('Soja', 'GLYCINE SOJA SPROUT EXTRACT'),
    ('Soja', 'HYDROGENATED SOYBEAN OIL'),
    ('Soja', 'HYDROLYZED SOY PROTEIN'),
    ('Soja', 'HYDROLYZED SOY PROTEIN/DIMETHICONE PEG-7 ACETATE'),
    ('Soja', 'LAURDIMONIUM HYDROXYPROPYL HYDROLYZED SOY PROTEIN'),
    ('Soja', 'MALEATED SOYBEAN OIL'),
    ('Soja', 'POTASSIUM COCOYL HYDROLYZED SOY PROTEIN'),
    ('Soja', 'POTASSIUM LAUROYL HYDROLYZED SOY PROTEIN'),
    ('Soja', 'PROPYLTRIMONIUM HYDROLYZED SOY PROTEIN'),
    ('Soja', 'QUATERNIUM-79 HYDROLYZED SOY PROTEIN'),
    ('Soja', 'SODIUM COCOYL HYDROLYZED SOY PROTEIN'),
    ('Soja', 'SOYBEAN PEROXIDASE'),
    ('Soja', 'TEA-COCOYL HYDROLYZED SOY PROTEIN'),
    ('Soja', 'GLYCINE SOJA SEED EXTRACT'),
    ('Soja', 'GLYCINE SOJA GERM EXTRACT'),
    ('Soja', 'GLYCINE SOJA EXTRACT'),
    -- Sulfatos (129): os sulfatos detergentes (alquil sulfatos e alquil éter sulfatos, como SODIUM LAURYL SULFATE e SODIUM LAURETH SULFATE); fora sal mineral, tintura de cabelo, condroitina e metossulfatos
    ('Sulfatos', 'AMMONIUM C12-13 ALKYL SULFATE'),
    ('Sulfatos', 'AMMONIUM C12-15 ALKYL SULFATE'),
    ('Sulfatos', 'AMMONIUM C12-15 PARETH SULFATE'),
    ('Sulfatos', 'AMMONIUM C12-16 ALKYL SULFATE'),
    ('Sulfatos', 'AMMONIUM CAPRYLETH SULFATE'),
    ('Sulfatos', 'AMMONIUM COCO-SULFATE'),
    ('Sulfatos', 'AMMONIUM COCOMONOGLYCERIDE SULFATE'),
    ('Sulfatos', 'AMMONIUM DIMETHICONE PEG-7 SULFATE'),
    ('Sulfatos', 'AMMONIUM LAURETH SULFATE'),
    ('Sulfatos', 'AMMONIUM LAURETH-12 SULFATE'),
    ('Sulfatos', 'AMMONIUM LAURETH-5 SULFATE'),
    ('Sulfatos', 'AMMONIUM LAURETH-7 SULFATE'),
    ('Sulfatos', 'AMMONIUM LAURETH-9 SULFATE'),
    ('Sulfatos', 'AMMONIUM LAURYL SULFATE'),
    ('Sulfatos', 'AMMONIUM MYRETH SULFATE'),
    ('Sulfatos', 'AMMONIUM MYRISTYL SULFATE'),
    ('Sulfatos', 'AMMONIUM NONOXYNOL-30 SULFATE'),
    ('Sulfatos', 'AMMONIUM NONOXYNOL-4 SULFATE'),
    ('Sulfatos', 'AMMONIUM PALM KERNEL SULFATE'),
    ('Sulfatos', 'ARGININE LAURETH SULFATE'),
    ('Sulfatos', 'ARGININE PEG-4 COCAMIDE SULFATE'),
    ('Sulfatos', 'DEA-C12-13 ALKYL SULFATE'),
    ('Sulfatos', 'DEA-C12-13 PARETH-3 SULFATE'),
    ('Sulfatos', 'DEA-C12-15 ALKYL SULFATE'),
    ('Sulfatos', 'DEA-CETYL SULFATE'),
    ('Sulfatos', 'DEA-LAURETH SULFATE'),
    ('Sulfatos', 'DEA-LAURYL SULFATE'),
    ('Sulfatos', 'DEA-MYRETH SULFATE'),
    ('Sulfatos', 'DEA-MYRISTYL SULFATE'),
    ('Sulfatos', 'DIETHYLAMINE LAURETH SULFATE'),
    ('Sulfatos', 'DIMETHICONE PEG-7 SULFATE'),
    ('Sulfatos', 'HYDROXYETHYLBUTYLAMINE LAURETH SULFATE'),
    ('Sulfatos', 'MAGNESIUM COCETH SULFATE'),
    ('Sulfatos', 'MAGNESIUM COCO-SULFATE'),
    ('Sulfatos', 'MAGNESIUM LAURETH SULFATE'),
    ('Sulfatos', 'MAGNESIUM LAURETH-16 SULFATE'),
    ('Sulfatos', 'MAGNESIUM LAURETH-5 SULFATE'),
    ('Sulfatos', 'MAGNESIUM LAURETH-8 SULFATE'),
    ('Sulfatos', 'MAGNESIUM LAURYL SULFATE'),
    ('Sulfatos', 'MAGNESIUM MYRETH SULFATE'),
    ('Sulfatos', 'MAGNESIUM OLETH SULFATE'),
    ('Sulfatos', 'MAGNESIUM PEG-3 COCAMIDE SULFATE'),
    ('Sulfatos', 'MAGNESIUM/TEA-COCO-SULFATE'),
    ('Sulfatos', 'MEA-LAURETH SULFATE'),
    ('Sulfatos', 'MEA-LAURYL SULFATE'),
    ('Sulfatos', 'MIPA C12-15 PARETH SULFATE'),
    ('Sulfatos', 'MIPA-LAURETH SULFATE'),
    ('Sulfatos', 'MIPA-LAURYL SULFATE'),
    ('Sulfatos', 'MIXED ISOPROPANOLAMINES LAURYL SULFATE'),
    ('Sulfatos', 'POTASSIUM LAURYL SULFATE'),
    ('Sulfatos', 'SODIUM BABASSU SULFATE'),
    ('Sulfatos', 'SODIUM BUTOXYNOL-12 SULFATE'),
    ('Sulfatos', 'SODIUM C10-15 PARETH SULFATE'),
    ('Sulfatos', 'SODIUM C10-16 ALKETH-2 SULFATE'),
    ('Sulfatos', 'SODIUM C10-16 ALKYL SULFATE'),
    ('Sulfatos', 'SODIUM C10-16 PARETH-2 SULFATE'),
    ('Sulfatos', 'SODIUM C11-15 ALKYL SULFATE'),
    ('Sulfatos', 'SODIUM C12-13 ALKETH SULFATE'),
    ('Sulfatos', 'SODIUM C12-13 ALKYL SULFATE'),
    ('Sulfatos', 'SODIUM C12-13 PARETH SULFATE'),
    ('Sulfatos', 'SODIUM C12-14 PARETH-3 SULFATE'),
    ('Sulfatos', 'SODIUM C12-14 SEC-ALKETH-3 SULFATE'),
    ('Sulfatos', 'SODIUM C12-14 SEC-PARETH-3 SULFATE'),
    ('Sulfatos', 'SODIUM C12-15 ALKETH SULFATE'),
    ('Sulfatos', 'SODIUM C12-15 ALKETH-3 SULFATE'),
    ('Sulfatos', 'SODIUM C12-15 ALKYL SULFATE'),
    ('Sulfatos', 'SODIUM C12-15 PARETH SULFATE'),
    ('Sulfatos', 'SODIUM C12-15 PARETH-3 SULFATE'),
    ('Sulfatos', 'SODIUM C12-18 ALKYL SULFATE'),
    ('Sulfatos', 'SODIUM C13-15 PARETH-3 SULFATE'),
    ('Sulfatos', 'SODIUM C16-20 ALKYL SULFATE'),
    ('Sulfatos', 'SODIUM C8-10 ALKYL SULFATE'),
    ('Sulfatos', 'SODIUM C9-15 PARETH-3 SULFATE'),
    ('Sulfatos', 'SODIUM CAPRYLYL SULFATE'),
    ('Sulfatos', 'SODIUM CETEARYL SULFATE'),
    ('Sulfatos', 'SODIUM CETYL SULFATE'),
    ('Sulfatos', 'SODIUM COCETH SULFATE'),
    ('Sulfatos', 'SODIUM COCETH-30 SULFATE'),
    ('Sulfatos', 'SODIUM COCO-SULFATE'),
    ('Sulfatos', 'SODIUM COCO/BABASSU SULFATE'),
    ('Sulfatos', 'SODIUM COCO/BABASSU/ANDIROBA SULFATE'),
    ('Sulfatos', 'SODIUM COCO/HYDROGENATED TALLOW SULFATE'),
    ('Sulfatos', 'SODIUM COCOMONOGLYCERIDE SULFATE'),
    ('Sulfatos', 'SODIUM DECETH SULFATE'),
    ('Sulfatos', 'SODIUM DECYL SULFATE'),
    ('Sulfatos', 'SODIUM DODOXYNOL-40 SULFATE'),
    ('Sulfatos', 'SODIUM ETHYLHEXYL SULFATE'),
    ('Sulfatos', 'SODIUM LANETH SULFATE'),
    ('Sulfatos', 'SODIUM LAURETH SULFATE'),
    ('Sulfatos', 'SODIUM LAURETH-12 SULFATE'),
    ('Sulfatos', 'SODIUM LAURETH-40 SULFATE'),
    ('Sulfatos', 'SODIUM LAURETH-5 SULFATE'),
    ('Sulfatos', 'SODIUM LAURETH-7 SULFATE'),
    ('Sulfatos', 'SODIUM LAURETH-8 SULFATE'),
    ('Sulfatos', 'SODIUM LAURYL HYDROXYACETAMIDE SULFATE'),
    ('Sulfatos', 'SODIUM LAURYL SULFATE'),
    ('Sulfatos', 'SODIUM MYRETH SULFATE'),
    ('Sulfatos', 'SODIUM MYRISTYL SULFATE'),
    ('Sulfatos', 'SODIUM OCTOXYNOL-2 SULFATE'),
    ('Sulfatos', 'SODIUM OCTOXYNOL-6 SULFATE'),
    ('Sulfatos', 'SODIUM OCTOXYNOL-9 SULFATE'),
    ('Sulfatos', 'SODIUM OLETH SULFATE'),
    ('Sulfatos', 'SODIUM OLEYL SULFATE'),
    ('Sulfatos', 'SODIUM PEG-4 COCAMIDE SULFATE'),
    ('Sulfatos', 'SODIUM PEG-4 LAURAMIDE SULFATE'),
    ('Sulfatos', 'SODIUM PPG-16/PEG-2 LAURYL ETHER SULFATE'),
    ('Sulfatos', 'SODIUM STEARIC ACID SULFATE'),
    ('Sulfatos', 'SODIUM STEARYL SULFATE'),
    ('Sulfatos', 'SODIUM TALLOW SULFATE'),
    ('Sulfatos', 'SODIUM TRIDECETH SULFATE'),
    ('Sulfatos', 'SODIUM TRIDECYL SULFATE'),
    ('Sulfatos', 'SODIUM/MEA-PEG-3 COCAMIDE SULFATE'),
    ('Sulfatos', 'SODIUM/TEA C12-13 PARETH-3 SULFATE'),
    ('Sulfatos', 'TEA-C10-15 ALKYL SULFATE'),
    ('Sulfatos', 'TEA-C11-15 ALKYL SULFATE'),
    ('Sulfatos', 'TEA-C11-15 PARETH SULFATE'),
    ('Sulfatos', 'TEA-C12-13 ALKYL SULFATE'),
    ('Sulfatos', 'TEA-C12-13 PARETH-3 SULFATE'),
    ('Sulfatos', 'TEA-C12-14 ALKYL SULFATE'),
    ('Sulfatos', 'TEA-C12-15 ALKYL SULFATE'),
    ('Sulfatos', 'TEA-COCO-SULFATE'),
    ('Sulfatos', 'TEA-LANETH-5 SULFATE'),
    ('Sulfatos', 'TEA-LAURETH SULFATE'),
    ('Sulfatos', 'TEA-LAURYL SULFATE'),
    ('Sulfatos', 'TEA-PEG-3 COCAMIDE SULFATE'),
    ('Sulfatos', 'TIPA-LAURETH SULFATE'),
    ('Sulfatos', 'TIPA-LAURYL SULFATE'),
    ('Sulfatos', 'ZINC COCETH SULFATE'),
    ('Sulfatos', 'ZINC COCO-SULFATE'),
    -- Álcool (2): o álcool etílico, inclusive o desnaturado; renomeada de 'Alcohol'
    ('Álcool', 'ALCOHOL'),
    ('Álcool', 'ALCOHOL DENAT.');

DO $$
DECLARE
    v_faltando TEXT;
BEGIN
    SELECT string_agg(t.inci_name, ', ' ORDER BY t.inci_name)
      INTO v_faltando
      FROM tmp_alergia_inci t
     WHERE NOT EXISTS (SELECT 1 FROM venus.ingredients i WHERE i.inci_name = t.inci_name);
    IF v_faltando IS NOT NULL THEN
        RAISE EXCEPTION 'INCI da lista que não existem em venus.ingredients: %. Nada foi gravado.', v_faltando;
    END IF;
END $$;

INSERT INTO venus.allergy_ingredients (fk_allergy_id, fk_ingredient_id, source_type, source_reference)
SELECT a.allergy_id, i.ingredient_id, 'admin',
       'Migration 20260927_005: alergias checáveis (API de Classificação §5)'
FROM tmp_alergia_inci t
JOIN venus.allergies a ON a.allergy_name = t.allergy_name
JOIN venus.ingredients i ON i.inci_name = t.inci_name
ON CONFLICT (fk_allergy_id, fk_ingredient_id) DO NOTHING;

/* 5. Catálogo visível. Registros antigos e marcações de usuário são preservados. */
ALTER TABLE venus.allergies
    ADD COLUMN IF NOT EXISTS is_catalog_visible BOOLEAN NOT NULL DEFAULT FALSE;

UPDATE venus.allergies
SET is_catalog_visible = allergy_name IN (
    'Lanolina', 'Óleo de amêndoas', 'Parabenos', 'Formaldeído',
    'Propilenoglicol', 'Ácido salicílico', 'Látex', 'Soja',
    'Sulfatos', 'Álcool'
);

CREATE OR REPLACE VIEW venus.v_available_allergies AS
SELECT allergy_id, allergy_name, allergy_type
FROM venus.allergies
WHERE is_catalog_visible
ORDER BY allergy_name;

/* 6. Conferência: se algo não bater, desfaz a transação inteira. */
DO $$
DECLARE
    v_falta TEXT;
    v_sem_vinculo TEXT;
    v_total INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_total FROM venus.allergies WHERE is_catalog_visible;
    IF v_total <> 10 THEN
        RAISE EXCEPTION 'Esperadas 10 alergias visíveis; encontradas %. Nada foi gravado.', v_total;
    END IF;

    SELECT string_agg(n, ', ')
      INTO v_falta
      FROM unnest(ARRAY['Lanolina', 'Óleo de amêndoas', 'Parabenos', 'Formaldeído', 'Propilenoglicol', 'Ácido salicílico', 'Látex', 'Soja', 'Sulfatos', 'Álcool']) AS n
     WHERE NOT EXISTS (SELECT 1 FROM venus.allergies a WHERE a.allergy_name = n);
    IF v_falta IS NOT NULL THEN
        RAISE EXCEPTION 'Alergias da lista que não existem: %. Nada foi gravado.', v_falta;
    END IF;

    SELECT string_agg(t.allergy_name || ' -> ' || t.inci_name, ', ')
      INTO v_sem_vinculo
      FROM tmp_alergia_inci t
     WHERE NOT EXISTS (
            SELECT 1
              FROM venus.allergy_ingredients ai
              JOIN venus.allergies a ON a.allergy_id = ai.fk_allergy_id
              JOIN venus.ingredients i ON i.ingredient_id = ai.fk_ingredient_id
             WHERE a.allergy_name = t.allergy_name
               AND i.inci_name = t.inci_name);
    IF v_sem_vinculo IS NOT NULL THEN
        RAISE EXCEPTION 'Vínculos que não foram criados: %. Nada foi gravado.', v_sem_vinculo;
    END IF;
END $$;

COMMIT;

/* QA: esperado 10 linhas, com estes ingredientes ligados (321 no total):
     Lanolina: 98
     Óleo de amêndoas: 17
     Parabenos: 25
     Formaldeído: 21
     Propilenoglicol: 1
     Ácido salicílico: 1
     Látex: 1
     Soja: 26
     Sulfatos: 129
     Álcool: 2
*/
SELECT a.allergy_id, a.allergy_name, a.allergy_type, COUNT(ai.allergy_ingredient_id) AS ingredientes
FROM venus.allergies a
LEFT JOIN venus.allergy_ingredients ai ON ai.fk_allergy_id = a.allergy_id
WHERE a.is_catalog_visible
GROUP BY a.allergy_id, a.allergy_name, a.allergy_type
ORDER BY a.allergy_name;
