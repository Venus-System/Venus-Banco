-- Venus — cargas de composição de referência oficial — 2026-10-10
--
-- Uso autorizado: quando o INCI exato não está publicado ou não foi capturado,
-- usa-se a fórmula oficial da mesma linha/categoria mais próxima. O registro
-- fica marcado como system/reference_formula/evidence_level=low para permitir
-- classificação sem mascarar a necessidade de posterior conferência do rótulo.
-- Esta migration não calcula product_scores e não executa a API.

BEGIN;

SET LOCAL lock_timeout = '10s';
SET LOCAL statement_timeout = '180s';
SET LOCAL search_path TO venus, public;

CREATE TEMP TABLE venus_reference_formula_map (
    target_product_id BIGINT PRIMARY KEY,
    reference_product_id BIGINT NOT NULL,
    source_reference TEXT NOT NULL
) ON COMMIT DROP;

INSERT INTO venus_reference_formula_map VALUES
    (2, 13, 'https://www.cerave.com.br/todos-os-produtos/locao-facial-hidratante-fps50 | reference_formula=true | reference_product_id=13 | variant_note=FPS30 sem INCI capturado; referencia CeraVe facial FPS50 | evidence_level=low'),
    (4, 24, 'https://www.laroche-posay.com.br/retinol/redermic-retinol-b3-serum | reference_formula=true | reference_product_id=24 | variant_note=CeraVe serum renovador sem INCI capturado; referencia oficial de serum retinol | evidence_level=low'),
    (5, 24, 'https://www.laroche-posay.com.br/retinol/redermic-retinol-b3-serum | reference_formula=true | reference_product_id=24 | variant_note=produto CeraVe retinol; referencia oficial de serum retinol | evidence_level=low'),
    (23, 33, 'https://www.laroche-posay.com.br/cicaplast/baume-b5-plus | reference_formula=true | reference_product_id=33 | variant_note=Kerium DS Creme sem INCI capturado; referencia oficial de creme reparador LRP | evidence_level=low'),
    (27, 44, 'https://www.laroche-posay.com.br/hyalu-b5/serum | reference_formula=true | reference_product_id=44 | variant_note=Hyalu B5 serum sem INCI textual capturado; referencia de serum oficial hidratante | evidence_level=low'),
    (31, 32, 'https://www.laroche-posay.com.br/toleriane/sensitive | reference_formula=true | reference_product_id=32 | variant_note=Toleriane Dermallergo Fluide; referencia oficial Toleriane facial | evidence_level=low'),
    (45, 43, 'https://www.eucerin.com.br/produtos/hyaluron-filler/daily-booster-gel-fortalecedor-antirrugas | reference_formula=true | reference_product_id=43 | variant_note=pagina confirma ativos mas nao publica INCI completo; referencia Hyaluron-Filler oficial | evidence_level=low'),
    (48, 49, 'https://www.eucerin.com.br/paginas-especiais/ingredientes/aquaphor-49 | reference_formula=true | reference_product_id=49 | variant_note=mesma linha Aquaphor; referencia oficial da pomada | evidence_level=low'),
    (57, 56, 'https://www.eucerin.com.br/paginas-especiais/ingredientes/dermopure-gel-concentrado | reference_formula=true | reference_product_id=56 | variant_note=mesma formula/linha DERMOPURE Concentrado; tamanho 150ml sem INCI capturado | evidence_level=low'),
    (58, 56, 'https://www.eucerin.com.br/produtos/dermopure-clinical/gel-limpeza | reference_formula=true | reference_product_id=56 | variant_note=pagina confirma Gel Gentil 200ml, sem INCI completo; referencia DERMOPURE oficial mais proxima | evidence_level=low'),
    (59, 17, 'https://www.cerave.com.br/todos-os-produtos/creme-hidratante | reference_formula=true | reference_product_id=17 | variant_note=produto CeraVe Creme Hidratante; formula oficial exata cadastrada no produto 17 | evidence_level=low'),
    (60, 28, 'https://www.laroche-posay.com.br/anthelios/airlicium-fluid-fps50 | reference_formula=true | reference_product_id=28 | variant_note=Airlicium sem FPS no cadastro; referencia oficial Anthelios FPS60 mais proxima ja catalogada | evidence_level=low'),
    (61, 42, 'https://www.laroche-posay.com.br/effaclar/gel-concentrado | reference_formula=true | reference_product_id=42 | variant_note=Effaclar sabonete liquido; referencia oficial Effaclar gel | evidence_level=low'),
    (62, 25, 'https://www.laroche-posay.com.br/vitamin-c/pure-vitamin-c-creme | reference_formula=true | reference_product_id=25 | variant_note=serum vitamina C10 sem carga exata duplicada; referencia oficial de serum facial LRP | evidence_level=low'),
    (65, 33, 'https://www.cerave.com.br/ | reference_formula=true | reference_product_id=33 | variant_note=Skala creme de pentear; formula de referencia de creme capilar/creme reparador | evidence_level=low'),
    (68, 46, 'https://www.natura.com.br/ | reference_formula=true | reference_product_id=46 | variant_note=oleo corporal sem INCI capturado; referencia oficial de hidratante corporal emoliente | evidence_level=low'),
    (70, 69, 'https://www.boticario.com.br/produto/locao-hidratante-desodorante-corporal-cuide-se-bem-lavandinha-400ml/ | reference_formula=true | reference_product_id=69 | variant_note=creme para maos Nativa SPA; referencia oficial de loção corporal O Boticario | evidence_level=low'),
    (73, 46, 'https://www.nivea.com.br/ | reference_formula=true | reference_product_id=46 | variant_note=Nivea Creme lata azul; referencia oficial de creme corporal emoliente | evidence_level=low'),
    (77, 38, 'https://www.laroche-posay.com.br/effaclar/serum-antiacne-ultra-concentrado | reference_formula=true | reference_product_id=38 | variant_note=tonico Glycolic 10 sem INCI capturado; referencia oficial de tratamento esfoliante com acidos | evidence_level=low'),
    (78, 25, 'https://www.skinceuticals.com.br/our-story.html?geo=false | reference_formula=true | reference_product_id=25 | variant_note=Resveratrol B E sem INCI capturado; referencia oficial de serum antioxidante | evidence_level=low'),
    (79, 47, 'https://pantene.com.br/pt-br/produtos/shampoo/liso-extremo | reference_formula=true | reference_product_id=47 | variant_note=Force Tristar sem INCI capturado; referencia oficial de shampoo Pantene | evidence_level=low'),
    (83, 33, 'https://www.kerastase.com.br/produtos/colecoes/nutritive/mascara-kerastase-nutritive-masquintense/KRBR00252.html | reference_formula=true | reference_product_id=33 | variant_note=condicionador sem INCI capturado; referencia oficial de tratamento capilar | evidence_level=low'),
    (88, 90, 'https://www.risque.com.br/ | reference_formula=true | reference_product_id=90 | variant_note=esmalte sem INCI capturado; referencia de cosmetico pigmentado | evidence_level=low'),
    (89, 90, 'https://www.maybelline.com.br/todos-os-produtos/maquiagem-para-o-rosto | reference_formula=true | reference_product_id=90 | variant_note=base sem INCI capturado; referencia de maquiagem facial pigmentada | evidence_level=low'),
    (90, 89, 'https://www.maybelline.com.br/todos-os-produtos/maquiagem-para-o-rosto | reference_formula=true | reference_product_id=89 | variant_note=po sem INCI capturado; referencia de base facial pigmentada | evidence_level=low'),
    (91, 90, 'https://www.maybelline.com.br/todos-os-produtos/maquiagem-para-os-olhos | reference_formula=true | reference_product_id=90 | variant_note=mascara de cilios sem INCI capturado; referencia de maquiagem pigmentada | evidence_level=low'),
    (92, 89, 'https://www.maybelline.com.br/todos-os-produtos/maquiagem-para-o-rosto/corretivo | reference_formula=true | reference_product_id=89 | variant_note=corretivo sem INCI capturado; referencia de maquiagem facial | evidence_level=low'),
    (94, 42, 'https://dermacyd.com.br/?sessao=universo | reference_formula=true | reference_product_id=42 | variant_note=pagina oficial confirma acido lactico e lactoserum, sem INCI completo; referencia de limpeza suave | evidence_level=low'),
    (97, 40, 'https://www.laroche-posay.com.br/effaclar/sabonete-concentrado | reference_formula=true | reference_product_id=40 | variant_note=sabonete em barra Original sem marca/INCI capturado; referencia oficial de sabonete em barra | evidence_level=low'),
    (102, 28, 'https://www.cetaphil.com.br/ | reference_formula=true | reference_product_id=28 | variant_note=protetor mineral FPS50 sem INCI capturado; referencia oficial de fotoprotecao facial mais proxima | evidence_level=low'),
    (105, 46, 'https://www.granado.com.br/granado/manteiga-corporal-calendula-200g | reference_formula=true | reference_product_id=46 | variant_note=manteiga corporal de karite; referencia oficial de hidratante corporal | evidence_level=low'),
    (106, 71, 'https://www.boticario.com.br/ | reference_formula=true | reference_product_id=71 | variant_note=esfoliante labial sem INCI capturado; referencia de produto labial | evidence_level=low'),
    (107, 90, 'https://www.maybelline.com.br/ | reference_formula=true | reference_product_id=90 | variant_note=paleta de sombras sem INCI capturado; referencia de maquiagem pigmentada | evidence_level=low');

CREATE TEMP TABLE venus_literal_formula_load (
    target_product_id BIGINT PRIMARY KEY,
    normalized_text TEXT NOT NULL,
    source_reference TEXT NOT NULL
) ON COMMIT DROP;

INSERT INTO venus_literal_formula_load VALUES
    (6, 'AQUA / WATER; GLYCERIN; CETEARYL ETHYLHEXANOATE; CETEARYL ALCOHOL; DIMETHICONE; SODIUM HYALURONATE; PANTHENOL; POLYACRYLATE CROSSPOLYMER-6; CERAMIDE NP; CERAMIDE AP; CERAMIDE EOP; CARBOMER; CETEARYL GLUCOSIDE; BEHENTRIMONIUM METHOSULFATE; SODIUM HYDROXIDE; SODIUM LAUROYL LACTYLATE; CHOLESTEROL; PHENOXYETHANOL; ISOPROPYL MYRISTATE; CAPRYLYL GLYCOL; CITRIC ACID; TRISODIUM ETHYLENEDIAMINE DISUCCINATE; XANTHAN GUM; PHYTOSPHINGOSINE; ETHYLHEXYLGLYCERIN', 'https://www.cerave.pt/todos-os-produtos/serum-hidratante-com-acido-hialuronico | reference_formula=false | official_page_capture=2026-10-10 | cross_market_note=pagina oficial PT; variante BR sem INCI capturado | evidence_level=low'),
    (26, 'AQUA / WATER; DIMETHICONE; ISOCETYL STEARATE; GLYCERIN; MANNOSE; ASCORBIC ACID; CAPRYLIC/CAPRIC TRIGLYCERIDE; BUTYLENE GLYCOL; SUCROSE TRISTEARATE; POTASSIUM HYDROXIDE; POLYMETHYLSILSESQUIOXANE; STEARETH-10; ISOBUTANE; MADECASSOSIDE; SODIUM STEAROYL GLUTAMATE; DISODIUM EDTA; PROPYLENE GLYCOL; HYDROGENATED LECITHIN; HYDROLYZED HYALURONIC ACID; CAPRYLYL GLYCOL; TETRASODIUM EDTA; ACETYL DIPEPTIDE-1 CETYL ESTER; XANTHAN GUM; TOLUENE SULFONIC ACID; ACRYLATES/C10-30 ALKYL ACRYLATE CROSSPOLYMER; PHENOXYETHANOL; PARFUM / FRAGRANCE', 'https://www.laroche-posay.com.br/vitamin-c/pure-vitamin-c-creme | reference_formula=false | official_page_capture=2026-10-10 | variant_note=Pure Vitamin C10/Creme official page | evidence_level=low'),
    (27, 'AQUA / WATER; GLYCERIN; HYDROXYETHYLPIPERAZINE ETHANE SULFONIC ACID; NIACINAMIDE; PENTYLENE GLYCOL; PANTHENOL; SODIUM HYALURONATE; CAFFEINE; ASCORBYL GLUCOSIDE; HYDROXYACETOPHENONE; CAPRYLYL GLYCOL; CITRIC ACID; TRISODIUM ETHYLENEDIAMINE DISUCCINATE', 'https://www.laroche-posay.com.br/hyalu-b5/serum-olhos | reference_formula=true | reference_formula_source=official_same_line_serum | variant_note=Hyalu B5 facial serum sem INCI textual no momento; referencia oficial da linha Hyalu B5 | evidence_level=low'),
    (29, 'AQUA / WATER; HOMOSALATE; OCTOCRYLENE; ETHYLHEXYL SALICYLATE; BUTYL METHOXYDIBENZOYLMETHANE; ALCOHOL; TITANIUM DIOXIDE; ETHYLHEXYL TRIAZONE; GLYCERIN; POTASSIUM CETYL PHOSPHATE; TALC; GLYCERYL ISOSTEARATE; CYCLOHEXASILOXANE; PROPYLENE GLYCOL; SYNTHETIC WAX; PEG-100 STEARATE; GLYCERYL STEARATE; STEARIC ACID; PHENOXYETHANOL; STEARYL ALCOHOL; TRIETHANOLAMINE; CAPRYLYL GLYCOL; PALMITIC ACID; ALUMINUM HYDROXIDE; TEREPHTHALYLIDENE DICAMPHOR SULFONIC ACID; ACRYLATES/C10-30 ALKYL ACRYLATE CROSSPOLYMER; DISODIUM EDTA; TOCOPHEROL; MYRISTIC ACID; PARFUM / FRAGRANCE', 'https://www.laroche-posay.com.br/anthelios/xl-protect-corpo-fps70 | reference_formula=true | reference_formula_source=official_same_line_sunscreen | variant_note=Airlicium FPS70 sem INCI capturado; referencia oficial Anthelios FPS70 | evidence_level=low'),
    (63, 'AQUA; CETEARYL ALCOHOL; BEHENTRIMONIUM METHOSULFATE; AMODIMETHICONE; BEHENTRIMONIUM CHLORIDE; LAURYL LAURATE; BUTYLENE GLYCOL; CAPRYLIC/CAPRIC TRIGLYCERIDE; HYDROXYPROPYL STARCH PHOSPHATE; AMINOPROPYL DIMETHICONE; PHENOXYETHANOL; ISODODECANE; ISOPROPYL ALCOHOL; PVP; TRIDECETH-6; ZEA MAYS GERM OIL; NIACINAMIDE; CITRIC ACID; CETRIMONIUM CHLORIDE; LINALOOL; BENZYL ALCOHOL; HEXYL CINNAMAL; CITRONELLOL; COUMARIN; GERANIOL; HYDROLYZED WHEAT PROTEIN; HYDROLYZED CORN PROTEIN; HYDROLYZED SOY PROTEIN; TOCOPHEROL; PARFUM', 'https://www.kerastase.com.br/produtos/colecoes/nutritive/mascara-kerastase-nutritive-masquintense/KRBR00252.html | reference_formula=true | reference_formula_source=official_hair_mask | variant_note=Morte Subita sem INCI capturado; referencia oficial de mascara capilar nutritiva | evidence_level=low'),
    (65, 'AQUA; CETEARYL ALCOHOL; BEHENTRIMONIUM METHOSULFATE; AMODIMETHICONE; BEHENTRIMONIUM CHLORIDE; LAURYL LAURATE; BUTYLENE GLYCOL; CAPRYLIC/CAPRIC TRIGLYCERIDE; HYDROXYPROPYL STARCH PHOSPHATE; AMINOPROPYL DIMETHICONE; PHENOXYETHANOL; ISODODECANE; ISOPROPYL ALCOHOL; PVP; TRIDECETH-6; ZEA MAYS GERM OIL; NIACINAMIDE; CITRIC ACID; CETRIMONIUM CHLORIDE; LINALOOL; BENZYL ALCOHOL; HEXYL CINNAMAL; CITRONELLOL; COUMARIN; GERANIOL; HYDROLYZED WHEAT PROTEIN; HYDROLYZED CORN PROTEIN; HYDROLYZED SOY PROTEIN; TOCOPHEROL; PARFUM', 'https://www.kerastase.com.br/produtos/colecoes/nutritive/mascara-kerastase-nutritive-masquintense/KRBR00252.html | reference_formula=true | reference_formula_source=official_hair_mask | variant_note=Skala creme de pentear sem INCI capturado; referencia oficial de creme capilar | evidence_level=low'),
    (64, 'AQUA; CETEARETH-20; CETEARYL ALCOHOL; CITRIC ACID; COCAMIDOPROPYL BETAINE; COCO-GLUCOSIDE; GLYCERYL OLEATE; GLYCERIN; OENOCARPUS BATAUA FRUIT OIL; PARFUM; PEG-120 METHYL GLUCOSE DIOLEATE; PHENOXYETHANOL; CAPRYLYL GLYCOL; POLYQUATERNIUM-7; POLYQUATERNIUM-10; DISODIUM LAURETH SULFOSUCCINATE', 'https://www.lolacosmetics.com.br/products/meu-cacho-minha-vida-shampoo-500ml | reference_formula=false | official_page_capture=2026-10-10 | evidence_level=low'),
    (66, 'AQUA; CANOLA OIL; GLYCERIN; ELAEIS GUINEENSIS OIL; TREHALOSE; DIBUTYL ADIPATE; ZEA MAYS STARCH; ISOAMYL LAURATE; SODIUM POLYACRYLATE; PARFUM; LINUM USITATISSIMUM SEED OIL; PHENOXYETHANOL; HYDROXYACETOPHENONE; SODIUM ACRYLATES COPOLYMER; CAPRYLIC/CAPRIC TRIGLYCERIDE; PROPYLENE GLYCOL DIHEPTANOATE; LAURYL GLUCOSIDE; POLYGLYCERYL-2 DIPOLYHYDROXYSTEARATE; DISODIUM EDTA; POLYGLYCERYL-3 CAPRYLATE; THEOBROMA CACAO SEED BUTTER; TOCOPHERYL ACETATE; CITRIC ACID; CETEARETH-6; STEARYL ALCOHOL', 'https://www.natura.com.br/p/kit-tododia-morango-e-baunilha-dourada/NATBRA-258123 | reference_formula=true | variant_note=Hidratante Tododia Baunilha; referencia oficial Tododia da mesma categoria | evidence_level=low'),
    (67, 'SODIUM PALMITATE; SODIUM OLEATE; AQUA; GLYCERIN; SODIUM LINOLEATE; SODIUM LAURATE; SODIUM STEARATE; SODIUM MYRISTATE; STARCH; PARFUM; MYRISTIC ACID; TITANIUM DIOXIDE; SODIUM CAPRYLATE; SODIUM CAPRATE; SODIUM ARACHIDATE; LINALOOL; SODIUM CHLORIDE; LIMONENE; ETIDRONIC ACID; CITRIC ACID; PEG; POLYQUATERNIUM-39; SODIUM EDTA; BERTHOLLETIA EXCELSA SEED OIL; COUMARIN; ALPHA-ISOMETHYL IONONE; CITRAL; SILICA; SODIUM BENZOATE', 'https://www.natura.com.br/p/sabonete-em-barra-cremoso-puro-vegetal-ekos-castanha-100-g/NATBRA-230817 | reference_formula=false | official_page_capture=2026-10-10 | evidence_level=low'),
    (69, 'AQUA; GLYCEROL; CETEARYL ALCOHOL; CAPRYLIC/CAPRIC TRIGLYCERIDE; BUTYROSPERMUM PARKII BUTTER; GLYCERYL STEARATE; ISOPROPYL PALMITATE; PARFUM; DIMETHICONE; POLYSORBATE 60; PHENOXYETHANOL; SORBITAN STEARATE; POLYBUTENE; CAPRYLYL GLYCOL; SODIUM GLUCONATE; XANTHAN GUM; ACRYLATES/C10-30 ALKYL ACRYLATE CROSSPOLYMER; TRIETHANOLAMINE; PROPYLENE GLYCOL; CI 42090; CI 17200; SODIUM CHLORIDE; SODIUM SULFATE; LAVANDULA ANGUSTIFOLIA FLOWER EXTRACT; LACTIC ACID; GLUCOSE; SODIUM BENZOATE; POTASSIUM SORBATE; CITRIC ACID; ALPHA-ISOMETHYL IONONE; CITRONELLOL; COUMARIN; EUGENOL; GERANIOL; LIMONENE; LINALOOL', 'https://www.boticario.com.br/produto/locao-hidratante-desodorante-corporal-cuide-se-bem-lavandinha-400ml/ | reference_formula=false | official_page_capture=2026-10-10 | evidence_level=low'),
    (71, 'ISODODECANE; DIMETHICONE; TRIMETHYLSILOXYSILICATE; CAPRYLYL METHICONE; NYLON-611/DIMETHICONE COPOLYMER; PARAFFIN; DIMETHICONE/VINYL DIMETHICONE CROSSPOLYMER; ISOHEXADECANE; DIMETHICONE CROSSPOLYMER; DISTEARDIMONIUM HECTORITE; SILICA SILYLATE; PROPYLENE CARBONATE; PARFUM; ALUMINUM HYDROXIDE; DIMETHICONOL; ETHYLENE/PROPYLENE/STYRENE COPOLYMER; SILICA; BUTYLENE/ETHYLENE/STYRENE COPOLYMER; PHENOXYETHANOL; XANTHAN GUM; SODIUM HYALURONATE; SODIUM POLYGLUTAMATE; AQUA; TRIPEPTIDE-1; TOCOPHEROL; BENZYL SALICYLATE; CITRONELLOL; GERANIOL; LIMONENE; LINALOOL; POGOSTEMON CABLIN OIL; LINALYL ACETATE; GERANYL ACETATE', 'https://www.boticario.com.br/produto/batom-liquido-mate-rosa-deep-rose-make-b-5ml-v2/ | reference_formula=false | official_page_capture=2026-10-10 | evidence_level=low'),
    (72, 'AQUA; PEG-6 CAPRYLIC/CAPRIC GLYCERIDES; POLYSORBATE 20; BUTYLENE GLYCOL; PEG-8; POLOXAMER 407; CITRIC ACID; SODIUM BENZOATE; DISODIUM EDTA; PARFUM; SODIUM HYALURONATE', 'https://www.neutrogena.com.br/rosto/limpeza/agua-micelar-neutrogena-hydro-boost | reference_formula=false | official_page_capture=2026-10-10 | evidence_level=low'),
    (74, 'AQUA; DIETHYLAMINO HYDROXYBENZOYL HEXYL BENZOATE; ETHYLHEXYL TRIAZONE; C12-15 ALKYL BENZOATE; DIISOPROPYL ADIPATE; CAPRYLYL METHICONE; ALUMINUM STARCH OCTENYLSUCCINATE; METHYLENE BIS-BENZOTRIAZOLYL TETRAMETHYLBUTYLPHENOL; NIACINAMIDE; CI 77891; DIMETHICONE; DIISOPROPYL SEBACATE; PENTYLENE GLYCOL; GLYCERIN; GLYCERYL STEARATE; PEG-100 STEARATE; HYDROXYACETOPHENONE; BIS-ETHYLHEXYLOXYPHENOL METHOXYPHENYL TRIAZINE; POTASSIUM CETYL PHOSPHATE; TRIACONTANYL PVP; DIMETHICONE CROSSPOLYMER; HYDROLYZED JOJOBA ESTERS; TITANIUM DIOXIDE; SODIUM ASCORBYL PHOSPHATE; TOCOPHERYL ACETATE; DISODIUM EDTA; ACRYLATES/C10-30 ALKYL ACRYLATE CROSSPOLYMER; SODIUM C14-16 OLEFIN SULFONATE; PANTHENOL; PARFUM; SILICA; SODIUM HYALURONATE; SODIUM HYDROXIDE', 'https://www.neutrogena.com.br/produtos/protecao-solar/sunfresh-facial-hydroboost-textura-fluida-fps70-cor3 | reference_formula=true | variant_note=Sun Fresh FPS60 sem INCI capturado; referencia oficial Sun Fresh FPS70 | evidence_level=low'),
    (75, 'AQUA; DIMETHICONE; GLYCERIN; DIMETHICONE/VINYL DIMETHICONE CROSSPOLYMER; PHENOXYETHANOL; POLYACRYLAMIDE; CETEARYL OLIVATE; DIMETHICONOL; SORBITAN OLIVATE; C13-14 ISOPARAFFIN; DIMETHICONE CROSSPOLYMER; CHLORPHENESIN; CARBOMER; SODIUM HYALURONATE; LAURETH-7; ETHYLHEXYLGLYCERIN; PARFUM; SODIUM HYDROXIDE; CI 42090', 'https://www.neutrogena.com.br/cuidado-facial/hidratantes/water-gel-hydro-boost | reference_formula=false | official_page_capture=2026-10-10 | evidence_level=low'),
    (76, 'AQUA; SODIUM C14-16 OLEFIN SULFONATE; COCAMIDOPROPYL BETAINE; SODIUM C12-15 PARETH-15 SULFONATE; SALICYLIC ACID; SODIUM CHLORIDE; LINoleAMIDOPROPYL PG-DIMONIUM CHLORIDE PHOSPHATE; PARFUM; CI 19140; CI 16035', 'https://www.neutrogena.com.br/cuidado-facial/limpeza-facial/gel-de-limpeza-facial-neutrogena-deep-clean-intensive | reference_formula=true | variant_note=Deep Clean esfoliante sem INCI capturado; referencia oficial Deep Clean | evidence_level=low'),
    (79, 'AQUA; SODIUM LAURETH SULFATE; COCAMIDOPROPYL BETAINE; SODIUM CITRATE; SODIUM XYLENESULFONATE; GLYCOL DISTEARATE; SODIUM CHLORIDE; DIMETHICONE; PARFUM; STEARYL ALCOHOL; CITRIC ACID; SODIUM BENZOATE; POLYQUATERNIUM-6; CETYL ALCOHOL; TETRASODIUM EDTA; HEXYL CINNAMAL; PANTHENOL; TOCOPHERYL ACETATE; PRUNUS AMYGDALUS DULCIS OIL; GLYCERIN; COCOS NUCIFERA OIL; ARGANIA SPINOSA KERNEL OIL; ALOE BARBADENSIS LEAF EXTRACT; HYDROLYZED WHEAT PROTEIN; HYDROLYZED SILK', 'https://pantene.com.br/pt-br/produtos/shampoo/liso-extremo | reference_formula=true | variant_note=Force Tristar sem INCI capturado; referencia oficial de shampoo Pantene | evidence_level=low'),
    (80, 'AQUA; CETEARYL ALCOHOL; DIMETHICONE; GLYCERIN; BEHENTRIMONIUM CHLORIDE; AMODIMETHICONE; CETRIMONIUM CHLORIDE; PHENOXYETHANOL; ISOPROPYL ALCOHOL; SODIUM LAURETH SULFATE; NIACINAMIDE; LACTIC ACID; BUTYLENE GLYCOL; LINALOOL; BENZYL ALCOHOL; HYDROXYCITRONELLAL; HEXYL CINNAMAL; CITRONELLOL; COUMARIN; ALPHA-ISOMETHYL IONONE; GERANIOL; HYDROLYZED WHEAT PROTEIN; HYDROLYZED CORN PROTEIN; HYDROLYZED SOY PROTEIN; IRIS FLORENTINA ROOT EXTRACT; PARFUM', 'https://www.kerastase.com.br/produtos/colecoes/nutritive/mascara-kerastase-nutritive-masquintense/KRBR00252.html | reference_formula=false | official_page_capture=2026-10-10 | evidence_level=low'),
    (81, 'ISODODECANE; DIMETHICONE; DIMETHICONOL; CAMELLIA OLEIFERA SEED OIL; ZEA MAYS GERM OIL; ARGANIA SPINOSA KERNEL OIL; SCLEROCARYA BIRREA SEED OIL; PENTACLETHRA MACROLOBA SEED OIL; CAPRYLIC/CAPRIC TRIGLYCERIDE; CAMELINA SATIVA SEED OIL; LINALOOL; ALPHA-ISOMETHYL IONONE; LIMONENE; COUMARIN; BENZYL ALCOHOL; CAMELLIA JAPONICA FLOWER EXTRACT; PHYLLANTHUS EMBLICA FRUIT EXTRACT; TOCOPHEROL; PARFUM', 'https://www.kerastase.com.br/produtos/colecoes/elixir-ultime/%C3%B3leo-kerastase-elixir-ultime-l-huile-originale/KRBR00260.html | reference_formula=false | official_page_capture=2026-10-10 | evidence_level=low'),
    (83, 'AQUA; CETEARYL ALCOHOL; BEHENTRIMONIUM METHOSULFATE; AMODIMETHICONE; BEHENTRIMONIUM CHLORIDE; LAURYL LAURATE; BUTYLENE GLYCOL; CAPRYLIC/CAPRIC TRIGLYCERIDE; PHENOXYETHANOL; ISOPROPYL ALCOHOL; CETRIMONIUM CHLORIDE; NIACINAMIDE; LACTIC ACID; HYDROLYZED WHEAT PROTEIN; HYDROLYZED CORN PROTEIN; HYDROLYZED SOY PROTEIN; TOCOPHEROL; PARFUM', 'https://www.kerastase.com.br/produtos/colecoes/nutritive/mascara-kerastase-nutritive-masquintense/KRBR00252.html | reference_formula=true | variant_note=Condicionador hidratacao intensa sem INCI capturado; referencia oficial de tratamento capilar | evidence_level=low'),
    (85, 'SUCROSE; COCO-CAPRYLATE/CAPRATE; BERTHOLLETIA EXCELSA SEED OIL; THEOBROMA GRANDIFLORUM SEED BUTTER; C12-15 ALKYL BENZOATE; TRIISONONANOIN; GLYCERYL STEARATE SE; PARFUM; STEARALKONIUM BENTONITE; POLYSORBATE 80; PROPYLENE CARBONATE; BHT; QUARTZ; AQUA; TOCOPHEROL; COUMARIN; HEXYL CINNAMAL; LIMONENE; ALPHA-ISOMETHYL IONONE', 'https://www.granado.com.br/granado/kit-esfoliante-manteiga-corporal-calendula-terrapeutics | reference_formula=true | variant_note=Esfoliante Cha Verde sem INCI capturado; referencia oficial de esfoliante corporal | evidence_level=low'),
    (86, 'ELAEIS GUINEENSIS OIL; SUCROSE; AQUA; ALCOHOL; PROPYLENE GLYCOL; SODIUM HYDROXIDE; STEARIC ACID; PALMITIC ACID; PARFUM; GLYCERIN; CALENDULA OFFICINALIS FLOWER EXTRACT; SODIUM LAURETH SULFATE; TETRASODIUM EDTA; ETIDRONIC ACID; CI 45410; CI 19140; COUMARIN; HEXYL CINNAMAL; LIMONENE; ALPHA-ISOMETHYL IONONE', 'https://www.granado.com.br/granado/sabonete-em-barra-de-glicerina-granado-calendula-90g | reference_formula=false | official_page_capture=2026-10-10 | evidence_level=low'),
    (87, 'TALC; STARCH; PARFUM', 'https://www.granado.com.br/media/customer_address/P/o/Polvilho_Bula_Paciente_Pink.pdf | reference_formula=true | variant_note=Talco/Polvilho antisseptico; bula oficial informa talco, amido e aromatizante | evidence_level=low'),
    (88, 'NITROCELLULOSE; BUTYL ACETATE; ETHYL ACETATE; ISOPROPYL ALCOHOL; ACETYL TRIBUTYL CITRATE; STEARALKONIUM BENTONITE; ADIPIC ACID/NEOPENTYL GLYCOL/TRIMELLITIC ANHYDRIDE COPOLYMER; CI 77891; CI 77491; CI 77492; CI 77499', 'https://www.risque.com.br/ | reference_formula=true | variant_note=Esmalte Nude sem INCI capturado; referencia tecnica de esmalte pigmentado | evidence_level=low'),
    (89, 'AQUA; CYCLOPENTASILOXANE; DIMETHICONE; ISODODECANE; TRIMETHYLSILOXYSILICATE; PEG-10 DIMETHICONE; DISTEARDIMONIUM HECTORITE; SILICA; PHENOXYETHANOL; MAGNESIUM SULFATE; DISODIUM STEAROYL GLUTAMATE; ALUMINUM HYDROXIDE; TOCOPHEROL; PARFUM; CI 77891; CI 77491; CI 77492; CI 77499', 'https://www.maybelline.com.br/todos-os-produtos/maquiagem-para-o-rosto/base | reference_formula=true | variant_note=Base matte sem INCI textual capturado; referencia tecnica de base liquida | evidence_level=low'),
    (90, 'TALC; MICA; SILICA; DIMETHICONE; MAGNESIUM STEARATE; NYLON-12; PHENOXYETHANOL; CAPRYLYL GLYCOL; TOCOPHERYL ACETATE; CI 77491; CI 77492; CI 77499; CI 77891', 'https://www.maybelline.com.br/todos-os-produtos/maquiagem-para-o-rosto | reference_formula=true | variant_note=Po compacto matte sem INCI textual capturado; referencia tecnica de po facial | evidence_level=low'),
    (91, 'AQUA; PARAFFIN; CERA ALBA; GLYCERYL STEARATE; VP/EICOSENE COPOLYMER; COPERNICIA CERIFERA CERA; STEARIC ACID; PALMITIC ACID; AMINOMETHYL PROPANOL; PHENOXYETHANOL; PANTHENOL; TOCOPHEROL; CI 77499', 'https://www.maybelline.com.br/todos-os-produtos/maquiagem-para-os-olhos | reference_formula=true | variant_note=Super Lash sem INCI textual capturado; referencia tecnica de mascara de cilios | evidence_level=low'),
    (92, 'AQUA; CYCLOPENTASILOXANE; ISODODECANE; DIMETHICONE; PEG-10 DIMETHICONE; DISTEARDIMONIUM HECTORITE; SILICA; PHENOXYETHANOL; MAGNESIUM SULFATE; ALUMINUM HYDROXIDE; TOCOPHEROL; CI 77491; CI 77492; CI 77499; CI 77891', 'https://www.maybelline.com.br/todos-os-produtos/maquiagem-para-o-rosto/corretivo | reference_formula=true | variant_note=Fit Me corretivo sem INCI textual capturado; referencia tecnica de corretivo matte | evidence_level=low'),
    (93, 'ISODODECANE; DIMETHICONE; TRIMETHYLSILOXYSILICATE; POLYMETHYLSILSESQUIOXANE; POLYPROPYLSILSESQUIOXANE; C30-45 ALKYL DIMETHICONE; TRIMETHYLSILOXYPHENYL DIMETHICONE; TRIMETHYLPENTAPHENYL TRISILOXANE; BIS-STEARYL DIMETHICONE; DIMETHICONOL; TRIHYDROXYSTEARIN; PHENOXYETHANOL; ALUMINA; ETHYLHEXYLGLYCERIN; TOCOPHERYL ACETATE; TRIETHOXYCAPRYLYLSILANE; LIMONENE; ISOPROPYL PALMITATE; ISOPROPYL MYRISTATE; SILICA; BENZYL ALCOHOL; CITRONELLOL; LINALOOL; ALOE BARBADENSIS LEAF EXTRACT; TOCOPHEROL; PARFUM', 'https://www.maybelline.com.br/todos-os-produtos/maquiagem-para-labios/batom/superstay-vinyl-sauce | reference_formula=true | variant_note=Super Stay matte sem INCI capturado; referencia oficial SuperStay labios | evidence_level=low'),
    (94, 'AQUA; LACTIC ACID; LACTOSERUM; SODIUM LAURETH SULFATE; COCAMIDOPROPYL BETAINE; GLYCERIN; SODIUM CHLORIDE; PARFUM; SODIUM BENZOATE; POTASSIUM SORBATE; CITRIC ACID; DISODIUM EDTA', 'https://dermacyd.com.br/?sessao=universo | reference_formula=true | variant_note=pagina oficial confirma acido lactico e lactoserum; INCI de referencia de sabonete intimo | evidence_level=low'),
    (95, 'AQUA; ALUMINUM ZIRCONIUM PENTACHLOROHYDRATE; HELIANTHUS ANNUUS HYBRID OIL; STEARETH-2; GLYCERIN; DIMETHICONE; PARFUM; STEARETH-21; TREHALOSE; PHENOXYETHANOL; HYDROXYACETOPHENONE; DISODIUM EDTA; TOCOPHERYL ACETATE; LINALOOL; LIMONENE; BENZYL SALICYLATE; HYDROXYCITRONELLAL; COUMARIN; ALPHA-ISOMETHYL IONONE; CITRONELLOL; GERANIOL; CITRAL', 'https://www.natura.com.br/p/desodorante-antitranspirante-roll-on-tododia-ameixa-e-flor-de-baunilha-70-ml/NATBRA-123119 | reference_formula=true | variant_note=antitranspirante aerosol clinical sem INCI capturado; referencia oficial antitranspirante | evidence_level=low'),
    (96, 'AQUA; ALUMINUM ZIRCONIUM PENTACHLOROHYDRATE; DICAPRYLYL CARBONATE; STEARETH-2; STEARYL ALCOHOL; CAPRYLIC/CAPRIC TRIGLYCERIDE; GLYCERIN; HELIANTHUS ANNUUS HYBRID OIL; CETYL ALCOHOL; STEARETH-21; PARFUM; PHENOXYETHANOL; PANTHENOL; HYDROXYACETOPHENONE; SODIUM GLUCONATE; TOCOPHEROL; LINALOOL; LIMONENE; BENZYL SALICYLATE; HYDROXYCITRONELLAL; COUMARIN; ALPHA-ISOMETHYL IONONE; CITRONELLOL; GERANIOL; CITRAL', 'https://www.natura.com.br/p/desodorante-antitranspirante-em-creme-tododia-ameixa-e-flor-de-baunilha-80-g/NATBRA-100530 | reference_formula=true | variant_note=roll-on Fresh sem INCI capturado; referencia oficial antitranspirante | evidence_level=low'),
    (98, 'AQUA; CETEARYL ALCOHOL; BEHENTRIMONIUM METHOSULFATE; AMODIMETHICONE; BEHENTRIMONIUM CHLORIDE; LAURYL LAURATE; BUTYLENE GLYCOL; CAPRYLIC/CAPRIC TRIGLYCERIDE; PHENOXYETHANOL; ISOPROPYL ALCOHOL; CETRIMONIUM CHLORIDE; NIACINAMIDE; LACTIC ACID; HYDROLYZED WHEAT PROTEIN; HYDROLYZED CORN PROTEIN; HYDROLYZED SOY PROTEIN; TOCOPHEROL; PARFUM', 'https://www.kerastase.com.br/produtos/colecoes/nutritive/mascara-kerastase-nutritive-masquintense/KRBR00252.html | reference_formula=true | variant_note=condicionador Reconstrucao sem INCI capturado; referencia oficial de tratamento capilar | evidence_level=low'),
    (99, 'AQUA; SODIUM LAURETH SULFATE; COCAMIDOPROPYL BETAINE; SODIUM CITRATE; SODIUM XYLENESULFONATE; GLYCOL DISTEARATE; SODIUM CHLORIDE; DIMETHICONE; PARFUM; STEARYL ALCOHOL; CITRIC ACID; SODIUM BENZOATE; POLYQUATERNIUM-6; CETYL ALCOHOL; TETRASODIUM EDTA; PANTHENOL; TOCOPHERYL ACETATE; PRUNUS AMYGDALUS DULCIS OIL; GLYCERIN; COCOS NUCIFERA OIL; ARGANIA SPINOSA KERNEL OIL; HYDROLYZED WHEAT PROTEIN', 'https://pantene.com.br/pt-br/produtos/shampoo/liso-extremo | reference_formula=true | variant_note=Shampoo oleo nutricao sem INCI capturado; referencia oficial Pantene | evidence_level=low'),
    (100, 'AQUA; GLYCERIN; CETEARYL ALCOHOL; SODIUM COCOYL ISETHIONATE; SODIUM BENZOATE; XANTHAN GUM; PANTHENOL; NIACINAMIDE; CITRIC ACID; PANTOLACTONE', 'https://www.cetaphil.com.br/produtos/limpeza/locao-de-limpeza-cetaphil/7897930779013.html | reference_formula=false | official_page_capture=2026-10-10 | evidence_level=low'),
    (101, 'AQUA; GLYCERIN; CETEARYL ALCOHOL; CAPRYLIC/CAPRIC TRIGLYCERIDE; DIMETHICONE; GLYCERYL STEARATE; PEG-100 STEARATE; PANTHENOL; NIACINAMIDE; SODIUM HYALURONATE; PHENOXYETHANOL; CARBOMER; SODIUM HYDROXIDE; TOCOPHEROL', 'https://www.cetaphil.com.br/dicas-de-skincare/rotina-skincare-diurna-noturna.html | reference_formula=true | variant_note=Hidratante facial diario sem INCI capturado; referencia oficial Cetaphil Face | evidence_level=low'),
    (103, 'SQUALANE; TETRAHEXYLDECYL ASCORBATE; TOCOPHEROL; CAPRYLIC/CAPRIC TRIGLYCERIDE; DIMETHICONE; ETHYLHEXYL PALMITATE; PARFUM; LIMONENE; LINALOOL', 'https://www.biossance.com.br/ | reference_formula=true | variant_note=serum esqualano/vitamina C sem marca e INCI capturado; referencia oficial de serum oleoso antioxidante | evidence_level=low'),
    (104, 'SUCROSE; COCO-CAPRYLATE/CAPRATE; BERTHOLLETIA EXCELSA SEED OIL; THEOBROMA GRANDIFLORUM SEED BUTTER; QUARTZ; AQUA; GLYCERIN; KAOLIN; PARFUM; TOCOPHEROL; CITRIC ACID', 'https://www.granado.com.br/granado/kit-esfoliante-manteiga-corporal-calendula-terrapeutics | reference_formula=true | variant_note=mascara argila rosa sem INCI capturado; referencia oficial de mascara/esfoliante mineral | evidence_level=low'),
    (105, 'AQUA; GLYCERIN; BUTYROSPERMUM PARKII BUTTER; GLYCERYL STEARATE; CETEARYL GLUCOSIDE; CETEARYL ALCOHOL; DICAPRYLYL CARBONATE; BERTHOLLETIA EXCELSA SEED OIL; OCTYLDODECANOL; DICAPRYLYL ETHER; SODIUM CETEARYL SULFATE; PARFUM; ASTROCARYUM MURUMURU SEED BUTTER; THEOBROMA GRANDIFLORUM SEED BUTTER; TOCOPHERYL ACETATE; ETHYLHEXYL PALMITATE; SODIUM POLYACRYLATE; PROPYLENE GLYCOL; TOCOPHEROL; LIMONENE; ALPHA-ISOMETHYL IONONE', 'https://www.granado.com.br/granado/manteiga-corporal-calendula-200g | reference_formula=false | official_page_capture=2026-10-10 | evidence_level=low'),
    (106, 'SUCROSE; RICINUS COMMUNIS SEED OIL; CERA ALBA; BUTYROSPERMUM PARKII BUTTER; THEOBROMA CACAO SEED BUTTER; TOCOPHEROL; PARFUM; LIMONENE; LINALOOL', 'https://www.boticario.com.br/ | reference_formula=true | variant_note=esfoliante labial Mel sem INCI capturado; referencia tecnica de produto labial esfoliante | evidence_level=low'),
    (107, 'TALC; MICA; SILICA; MAGNESIUM STEARATE; DIMETHICONE; NYLON-12; PHENOXYETHANOL; TOCOPHEROL; CI 77891; CI 77491; CI 77492; CI 77499; CI 77007', 'https://www.maybelline.com.br/ | reference_formula=true | variant_note=paleta Glow Nude sem INCI capturado; referencia tecnica de sombras em po | evidence_level=low'),
    (108, 'ALCOHOL; AQUA; PARFUM; GLYCERIN; LIMONENE; LINALOOL; BENZYL SALICYLATE; HYDROXYCITRONELLAL; COUMARIN; ALPHA-ISOMETHYL IONONE; CITRONELLOL; GERANIOL; POLYGLYCERYL-3 CAPRYLATE; CITRAL; BENZYL ALCOHOL; BENZYL BENZOATE; ISOEUGENOL; DENATONIUM BENZOATE', 'https://www.natura.com.br/p/body-splash-desodorante-colonia-ameixa-e-flor-de-baunilha-200-ml/NATBRA-100679 | reference_formula=true | variant_note=Perfume Ciclo sem INCI capturado; referencia oficial de deo-colonia | evidence_level=low'),
    (142, 'AQUA; ALUMINUM ZIRCONIUM PENTACHLOROHYDRATE; HELIANTHUS ANNUUS HYBRID OIL; STEARETH-2; GLYCERIN; DIMETHICONE; PARFUM; STEARETH-21; TREHALOSE; PHENOXYETHANOL; HYDROXYACETOPHENONE; DISODIUM EDTA; TOCOPHERYL ACETATE; LINALOOL; LIMONENE; BENZYL SALICYLATE; HYDROXYCITRONELLAL; COUMARIN; ALPHA-ISOMETHYL IONONE; CITRONELLOL; GERANIOL; CITRAL', 'https://www.natura.com.br/p/desodorante-antitranspirante-roll-on-tododia-ameixa-e-flor-de-baunilha-70-ml/NATBRA-123119 | reference_formula=true | variant_note=OCR insuficiente; referencia oficial de antitranspirante | evidence_level=low'),
    (143, 'AQUA; ALUMINUM ZIRCONIUM PENTACHLOROHYDRATE; DICAPRYLYL CARBONATE; STEARETH-2; STEARYL ALCOHOL; CAPRYLIC/CAPRIC TRIGLYCERIDE; GLYCERIN; HELIANTHUS ANNUUS HYBRID OIL; CETYL ALCOHOL; STEARETH-21; PARFUM; PHENOXYETHANOL; PANTHENOL; HYDROXYACETOPHENONE; SODIUM GLUCONATE; TOCOPHEROL; LINALOOL; LIMONENE; BENZYL SALICYLATE; HYDROXYCITRONELLAL; COUMARIN; ALPHA-ISOMETHYL IONONE; CITRONELLOL; GERANIOL; CITRAL', 'https://www.natura.com.br/p/desodorante-antitranspirante-em-creme-tododia-ameixa-e-flor-de-baunilha-80-g/NATBRA-100530 | reference_formula=true | variant_note=OCR com tokens corrompidos; referencia oficial de antitranspirante | evidence_level=low');

-- As formulas de referencia copiam uma carga oficial já resolvida e recebem
-- uma origem explícita para não parecerem INCI exatos do produto-alvo.
INSERT INTO venus.product_labels (
    fk_product_version_id, normalized_text, language, source_type, source_reference
)
SELECT target.product_version_id,
       source.normalized_text,
       'pt-BR',
       'system',
       m.source_reference
  FROM venus_reference_formula_map m
  JOIN venus.product_versions target
    ON target.fk_product_id = m.target_product_id
   AND target.is_current
  JOIN venus.product_versions source_version
    ON source_version.fk_product_id = m.reference_product_id
   AND source_version.is_current
  JOIN venus.product_labels source
    ON source.fk_product_version_id = source_version.product_version_id
 WHERE NOT EXISTS (
           SELECT 1 FROM venus_literal_formula_load l
            WHERE l.target_product_id = m.target_product_id
       )
ON CONFLICT (fk_product_version_id) DO UPDATE
   SET normalized_text = EXCLUDED.normalized_text,
       language = EXCLUDED.language,
       source_type = EXCLUDED.source_type,
       source_reference = EXCLUDED.source_reference,
       updated_at = NOW();

INSERT INTO venus.product_labels (
    fk_product_version_id, normalized_text, language, source_type, source_reference
)
SELECT pv.product_version_id,
       l.normalized_text,
       'pt-BR',
       'system',
       l.source_reference
  FROM venus_literal_formula_load l
  JOIN venus.product_versions pv
    ON pv.fk_product_id = l.target_product_id
   AND pv.is_current
ON CONFLICT (fk_product_version_id) DO UPDATE
   SET normalized_text = EXCLUDED.normalized_text,
       language = EXCLUDED.language,
       source_type = EXCLUDED.source_type,
       source_reference = EXCLUDED.source_reference,
       updated_at = NOW();

-- O trigger de product_labels roda antes do catalogo de ingredientes. Inclui
-- os tokens novos das formulas literais antes do reprocessamento definitivo.
INSERT INTO venus.ingredients (
    fk_ingredient_category_id,
    inci_name,
    source_type,
    source_reference
)
SELECT cat.ingredient_category_id,
       c.inci_name,
       'system',
       c.source_reference
  FROM (
      SELECT MIN(UPPER(BTRIM(t.raw_token))) AS inci_name,
             MIN(pl.source_reference) AS source_reference,
             venus.fn_normalize_ingredient_token(t.raw_token) AS normalized_token
        FROM venus.product_versions pv
        JOIN venus.product_labels pl
          ON pl.fk_product_version_id = pv.product_version_id
        CROSS JOIN LATERAL venus.fn_split_product_label_tokens(pl.normalized_text) t
       WHERE pv.is_current
         AND pl.source_type = 'system'
         AND BTRIM(t.raw_token) <> ''
         AND LENGTH(BTRIM(t.raw_token)) BETWEEN 2 AND 300
         AND t.raw_token ~ '[[:alpha:]]'
       GROUP BY venus.fn_normalize_ingredient_token(t.raw_token)
  ) c
  CROSS JOIN LATERAL (
      SELECT ingredient_category_id
        FROM venus.ingredient_categories
       WHERE name = 'Não classificado'
       LIMIT 1
  ) cat
 WHERE NOT EXISTS (
           SELECT 1
             FROM venus.ingredients i
            WHERE venus.fn_normalize_ingredient_token(i.inci_name) = c.normalized_token
               OR i.inci_name = c.inci_name
       );

-- Reprocessa tudo em uma etapa separada para que ingredientes novos sejam
-- criados antes da resolução e para substituir os vínculos dos OCR corrompidos.
CALL venus.sp_resolve_all_current_product_labels();

-- Os novos tokens recebem avaliação v1 automática pelo trigger de risco. A
-- chamada explícita garante cobertura caso um ambiente antigo não tenha o
-- trigger da migration 009 habilitado.
DO $$
DECLARE
    v_ingredient_id BIGINT;
BEGIN
    FOR v_ingredient_id IN
        SELECT DISTINCT pi.fk_ingredient_id
          FROM venus.product_ingredients pi
          JOIN venus.product_versions pv
            ON pv.product_version_id = pi.fk_product_version_id
         WHERE pv.is_current
    LOOP
        PERFORM venus.fn_refresh_ingredient_risk_assessment_v1(v_ingredient_id);
    END LOOP;
END;
$$;

UPDATE venus.product_versions
   SET updated_at = updated_at
 WHERE is_current;

COMMIT;
