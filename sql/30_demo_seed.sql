SET search_path TO venus, public;

INSERT INTO brands
    (name, country, website, has_cruelty_free_claim, has_vegan_claim, is_brazilian)
VALUES
    ('CeraVe','Estados Unidos','https://www.cerave.com.br/',FALSE,FALSE,FALSE),
    ('La Roche-Posay','França','https://www.laroche-posay.com.br/',FALSE,FALSE,FALSE),
    ('Eucerin','Alemanha','https://www.eucerin.com.br/',FALSE,FALSE,FALSE)
ON CONFLICT (name,country) DO NOTHING;


INSERT INTO users (firebase_uid, name, status, last_login) VALUES
('venus-seed-user-001','Ana Silva','active',NOW()),
('venus-seed-user-002','Bruno Costa','active',NOW()),
('venus-seed-user-003','Carla Oliveira','active',NOW()),
('venus-seed-user-004','Diego Santos','active',NOW()),
('venus-seed-user-005','Elisa Souza','active',NOW()),
('venus-seed-user-006','Felipe Lima','active',NOW()),
('venus-seed-user-007','Gabriela Rocha','active',NOW()),
('venus-seed-user-008','Henrique Martins','active',NOW()),
('venus-seed-user-009','Isabela Alves','active',NOW()),
('venus-seed-user-010','João Mendes','active',NOW()),
('venus-seed-user-011','Karina Ribeiro','active',NOW()),
('venus-seed-user-012','Lucas Ferreira','active',NOW()),
('venus-seed-user-013','Marina Gomes','active',NOW()),
('venus-seed-user-014','Nicolas Barros','active',NOW()),
('venus-seed-user-015','Olivia Cardoso','active',NOW()),
('venus-seed-user-016','Pedro Teixeira','active',NOW()),
('venus-seed-user-017','Rafaela Moura','active',NOW()),
('venus-seed-user-018','Samuel Nunes','active',NOW()),
('venus-seed-user-019','Talita Freitas','active',NOW()),
('venus-seed-user-020','Victor Araujo','active',NOW()),
('venus-seed-user-021','Amanda Castro','active',NOW()),
('venus-seed-user-022','Breno Duarte','active',NOW()),
('venus-seed-user-023','Camila Vieira','active',NOW()),
('venus-seed-user-024','Daniel Farias','active',NOW()),
('venus-seed-user-025','Eduarda Campos','active',NOW()),
('venus-seed-user-026','Fernando Moura','active',NOW()),
('venus-seed-user-027','Giovana Batista','active',NOW()),
('venus-seed-user-028','Hugo Moreira','active',NOW()),
('venus-seed-user-029','Larissa Reis','active',NOW()),
('venus-seed-user-030','Marcelo Pinto','active',NOW()),
('venus-seed-user-031','Natalia Correia','active',NOW()),
('venus-seed-user-032','Otavio Melo','active',NOW()),
('venus-seed-user-033','Priscila Neves','active',NOW()),
('venus-seed-user-034','Rafael Monteiro','active',NOW()),
('venus-seed-user-035','Sabrina Paes','active',NOW()),
('venus-seed-user-036','Thiago Borges','active',NOW()),
('venus-seed-user-037','Vanessa Tavares','active',NOW()),
('venus-seed-user-038','William Lopes','active',NOW()),
('venus-seed-user-039','Yasmin Andrade','active',NOW()),
('venus-seed-user-040','Caio Rezende','active',NOW())
ON CONFLICT (firebase_uid) DO NOTHING;

INSERT INTO admin_users (name,email,role,is_active) VALUES
('VENUS Seed Admin 01','venus-seed-admin-01@example.invalid','admin',TRUE),
('VENUS Seed Moderator 01','venus-seed-mod-01@example.invalid','moderator',TRUE),
('VENUS Seed Analyst 01','venus-seed-analyst-01@example.invalid','analyst',TRUE)
ON CONFLICT (email) DO NOTHING;

INSERT INTO allergies (allergy_name, allergy_type) VALUES
('Fragrância','ingredient'),
('Limonene','ingredient'),
('Linalool','ingredient'),
('Salicylic Acid','ingredient'),
('Parfum','ingredient'),
('Alcohol','ingredient'),
('Phenoxyethanol','ingredient'),
('Benzyl Salicylate','ingredient'),
('Látex','material'),
('Metais','material')
ON CONFLICT (allergy_name) DO NOTHING;


INSERT INTO user_profiles
(fk_user_id, skin_type, skin_phototype, has_hyperpigmentation,
 has_melasma, has_rosacea, has_eczema, hair_type, scalp_type,
 skin_sensitivity, acne_prone, age_range, gender, is_pregnant)
SELECT u.user_id, p.skin_type::venus.skin_type_enum, p.phototype::venus.skin_phototype_enum,
       p.hyperpigmentation, p.melasma, p.rosacea, p.eczema,
       p.hair_type::venus.hair_type_enum, p.scalp_type::venus.scalp_type_enum,
       p.sensitivity::venus.sensitivity_level_enum, p.acne_prone,
       p.age_range::venus.age_range_enum, p.gender::venus.gender_enum, p.pregnant
FROM users u
JOIN (
VALUES
('venus-seed-user-001','oily','iii',TRUE,FALSE,FALSE,FALSE,'straight','oily','medium',TRUE,'age_25_34','female',FALSE),
('venus-seed-user-002','dry','iv',FALSE,TRUE,FALSE,FALSE,'wavy','normal','high',FALSE,'age_35_44','male',FALSE),
('venus-seed-user-003','combination','iii',TRUE,FALSE,FALSE,FALSE,'curly','normal','medium',TRUE,'age_18_24','female',FALSE),
('venus-seed-user-004','normal','ii',FALSE,FALSE,FALSE,FALSE,'straight','normal','low',FALSE,'age_45_54','male',FALSE),
('venus-seed-user-005','sensitive','iii',FALSE,FALSE,TRUE,FALSE,'wavy','sensitive','very_high',FALSE,'age_25_34','female',FALSE),
('venus-seed-user-006','acneic','iv',TRUE,FALSE,FALSE,FALSE,'straight','oily','high',TRUE,'age_18_24','male',FALSE),
('venus-seed-user-007','dry','ii',TRUE,FALSE,FALSE,TRUE,'curly','dry','high',FALSE,'age_35_44','female',FALSE),
('venus-seed-user-008','oily','v',FALSE,FALSE,FALSE,FALSE,'coily','oily','medium',TRUE,'age_25_34','male',FALSE),
('venus-seed-user-009','combination','iii',TRUE,FALSE,FALSE,FALSE,'straight','normal','medium',TRUE,'age_25_34','female',FALSE),
('venus-seed-user-010','normal','iv',FALSE,FALSE,FALSE,FALSE,'wavy','normal','low',FALSE,'age_45_54','male',FALSE),
('venus-seed-user-011','sensitive','ii',FALSE,FALSE,TRUE,FALSE,'straight','sensitive','very_high',FALSE,'age_35_44','female',FALSE),
('venus-seed-user-012','oily','iii',TRUE,FALSE,FALSE,FALSE,'curly','oily','high',TRUE,'age_18_24','male',FALSE),
('venus-seed-user-013','dry','iv',TRUE,TRUE,FALSE,FALSE,'wavy','dry','high',FALSE,'age_45_54','female',FALSE),
('venus-seed-user-014','combination','v',FALSE,FALSE,FALSE,FALSE,'coily','normal','medium',TRUE,'age_25_34','male',FALSE),
('venus-seed-user-015','normal','iii',TRUE,FALSE,FALSE,FALSE,'straight','normal','low',FALSE,'age_55_plus','female',FALSE),
('venus-seed-user-016','acneic','iv',TRUE,FALSE,FALSE,FALSE,'curly','oily','high',TRUE,'age_18_24','male',FALSE),
('venus-seed-user-017','dry','iii',FALSE,FALSE,FALSE,TRUE,'straight','dry','very_high',FALSE,'age_35_44','female',FALSE),
('venus-seed-user-018','oily','vi',TRUE,FALSE,FALSE,FALSE,'coily','oily','medium',TRUE,'age_25_34','male',FALSE),
('venus-seed-user-019','sensitive','ii',FALSE,FALSE,TRUE,FALSE,'wavy','sensitive','very_high',FALSE,'age_45_54','female',FALSE),
('venus-seed-user-020','combination','iv',TRUE,FALSE,FALSE,FALSE,'straight','normal','medium',TRUE,'age_35_44','male',FALSE),
('venus-seed-user-021','normal','iii',FALSE,FALSE,FALSE,FALSE,'curly','normal','low',FALSE,'age_18_24','female',FALSE),
('venus-seed-user-022','oily','iv',TRUE,FALSE,FALSE,FALSE,'straight','oily','high',TRUE,'age_25_34','male',FALSE),
('venus-seed-user-023','dry','ii',TRUE,TRUE,FALSE,FALSE,'wavy','dry','high',FALSE,'age_35_44','female',FALSE),
('venus-seed-user-024','combination','iii',FALSE,FALSE,FALSE,FALSE,'curly','normal','medium',TRUE,'age_45_54','male',FALSE),
('venus-seed-user-025','sensitive','iv',FALSE,FALSE,TRUE,FALSE,'straight','sensitive','very_high',FALSE,'age_25_34','female',FALSE),
('venus-seed-user-026','acneic','v',TRUE,FALSE,FALSE,FALSE,'coily','oily','high',TRUE,'age_18_24','male',FALSE),
('venus-seed-user-027','dry','iii',FALSE,FALSE,FALSE,TRUE,'wavy','dry','very_high',FALSE,'age_45_54','female',FALSE),
('venus-seed-user-028','oily','iv',TRUE,FALSE,FALSE,FALSE,'curly','oily','medium',TRUE,'age_25_34','male',FALSE),
('venus-seed-user-029','normal','ii',TRUE,FALSE,FALSE,FALSE,'straight','normal','low',FALSE,'age_55_plus','female',FALSE),
('venus-seed-user-030','combination','iv',FALSE,FALSE,FALSE,FALSE,'wavy','normal','medium',TRUE,'age_35_44','male',FALSE),
('venus-seed-user-031','sensitive','iii',FALSE,FALSE,TRUE,FALSE,'straight','sensitive','very_high',FALSE,'age_18_24','female',FALSE),
('venus-seed-user-032','dry','v',TRUE,FALSE,FALSE,FALSE,'coily','dry','high',FALSE,'age_25_34','male',FALSE),
('venus-seed-user-033','oily','iii',TRUE,FALSE,FALSE,FALSE,'curly','oily','medium',TRUE,'age_35_44','female',FALSE),
('venus-seed-user-034','normal','iv',FALSE,FALSE,FALSE,FALSE,'straight','normal','low',FALSE,'age_45_54','male',FALSE),
('venus-seed-user-035','combination','iii',TRUE,FALSE,FALSE,FALSE,'wavy','normal','medium',TRUE,'age_25_34','female',FALSE),
('venus-seed-user-036','acneic','iv',TRUE,FALSE,FALSE,FALSE,'curly','oily','high',TRUE,'age_18_24','male',FALSE),
('venus-seed-user-037','dry','ii',TRUE,TRUE,FALSE,FALSE,'straight','dry','high',FALSE,'age_35_44','female',FALSE),
('venus-seed-user-038','sensitive','v',FALSE,FALSE,TRUE,FALSE,'coily','sensitive','very_high',FALSE,'age_45_54','male',FALSE),
('venus-seed-user-039','oily','iv',TRUE,FALSE,FALSE,FALSE,'wavy','oily','medium',TRUE,'age_25_34','female',FALSE),
('venus-seed-user-040','normal','iii',FALSE,FALSE,FALSE,FALSE,'straight','normal','low',FALSE,'age_55_plus','male',FALSE)
) AS p(firebase_uid,skin_type,phototype,hyperpigmentation,melasma,rosacea,eczema,hair_type,scalp_type,sensitivity,acne_prone,age_range,gender,pregnant)
ON p.firebase_uid=u.firebase_uid
ON CONFLICT (fk_user_id) DO NOTHING;


INSERT INTO user_preferences
(fk_user_id, prefer_cruelty_free, prefer_vegan, prefer_sustainable,
 prefer_fragrance_free, prefer_paraben_free, prefer_sulfate_free,
 prefer_silicone_free)
SELECT u.user_id,
       p.cruelty_free,p.vegan,p.sustainable,p.fragrance_free,
       p.paraben_free,p.sulfate_free,p.silicone_free
FROM users u
JOIN (
VALUES
('venus-seed-user-001',TRUE,FALSE,TRUE,TRUE,TRUE,TRUE,FALSE),
('venus-seed-user-002',TRUE,TRUE,TRUE,TRUE,TRUE,FALSE,TRUE),
('venus-seed-user-003',TRUE,TRUE,FALSE,TRUE,TRUE,TRUE,FALSE),
('venus-seed-user-004',FALSE,FALSE,TRUE,FALSE,FALSE,FALSE,FALSE),
('venus-seed-user-005',TRUE,FALSE,TRUE,TRUE,TRUE,TRUE,FALSE),
('venus-seed-user-006',TRUE,TRUE,FALSE,TRUE,TRUE,TRUE,FALSE),
('venus-seed-user-007',TRUE,FALSE,TRUE,TRUE,TRUE,FALSE,TRUE),
('venus-seed-user-008',TRUE,TRUE,TRUE,TRUE,TRUE,TRUE,FALSE),
('venus-seed-user-009',TRUE,FALSE,FALSE,TRUE,TRUE,TRUE,FALSE),
('venus-seed-user-010',FALSE,FALSE,TRUE,FALSE,TRUE,FALSE,FALSE),
('venus-seed-user-011',TRUE,FALSE,TRUE,TRUE,TRUE,TRUE,FALSE),
('venus-seed-user-012',TRUE,TRUE,TRUE,TRUE,TRUE,TRUE,FALSE),
('venus-seed-user-013',TRUE,FALSE,TRUE,TRUE,TRUE,FALSE,TRUE),
('venus-seed-user-014',TRUE,TRUE,TRUE,TRUE,TRUE,TRUE,FALSE),
('venus-seed-user-015',FALSE,FALSE,TRUE,FALSE,TRUE,FALSE,FALSE),
('venus-seed-user-016',TRUE,TRUE,FALSE,TRUE,TRUE,TRUE,FALSE),
('venus-seed-user-017',TRUE,FALSE,TRUE,TRUE,TRUE,FALSE,TRUE),
('venus-seed-user-018',TRUE,TRUE,TRUE,TRUE,TRUE,TRUE,FALSE),
('venus-seed-user-019',TRUE,FALSE,TRUE,TRUE,TRUE,TRUE,FALSE),
('venus-seed-user-020',TRUE,TRUE,FALSE,TRUE,TRUE,TRUE,FALSE),
('venus-seed-user-021',FALSE,FALSE,TRUE,FALSE,FALSE,FALSE,FALSE),
('venus-seed-user-022',TRUE,TRUE,TRUE,TRUE,TRUE,TRUE,FALSE),
('venus-seed-user-023',TRUE,FALSE,TRUE,TRUE,TRUE,FALSE,TRUE),
('venus-seed-user-024',FALSE,FALSE,TRUE,FALSE,FALSE,FALSE,FALSE),
('venus-seed-user-025',TRUE,FALSE,TRUE,TRUE,TRUE,TRUE,FALSE),
('venus-seed-user-026',TRUE,TRUE,TRUE,TRUE,TRUE,TRUE,FALSE),
('venus-seed-user-027',TRUE,FALSE,TRUE,TRUE,TRUE,FALSE,TRUE),
('venus-seed-user-028',TRUE,TRUE,FALSE,TRUE,TRUE,TRUE,FALSE),
('venus-seed-user-029',FALSE,FALSE,TRUE,FALSE,TRUE,FALSE,FALSE),
('venus-seed-user-030',TRUE,TRUE,TRUE,TRUE,TRUE,FALSE,FALSE),
('venus-seed-user-031',TRUE,FALSE,TRUE,TRUE,TRUE,TRUE,FALSE),
('venus-seed-user-032',TRUE,TRUE,TRUE,TRUE,TRUE,FALSE,TRUE),
('venus-seed-user-033',TRUE,FALSE,FALSE,TRUE,TRUE,TRUE,FALSE),
('venus-seed-user-034',FALSE,FALSE,TRUE,FALSE,FALSE,FALSE,FALSE),
('venus-seed-user-035',TRUE,TRUE,TRUE,TRUE,TRUE,TRUE,FALSE),
('venus-seed-user-036',TRUE,TRUE,FALSE,TRUE,TRUE,TRUE,FALSE),
('venus-seed-user-037',TRUE,FALSE,TRUE,TRUE,TRUE,FALSE,TRUE),
('venus-seed-user-038',TRUE,TRUE,TRUE,TRUE,TRUE,TRUE,FALSE),
('venus-seed-user-039',TRUE,FALSE,FALSE,TRUE,TRUE,TRUE,FALSE),
('venus-seed-user-040',FALSE,FALSE,TRUE,FALSE,TRUE,FALSE,FALSE)
) AS p(firebase_uid,cruelty_free,vegan,sustainable,fragrance_free,paraben_free,sulfate_free,silicone_free)
ON p.firebase_uid=u.firebase_uid
ON CONFLICT (fk_user_id) DO NOTHING;

INSERT INTO user_allergies (fk_user_id,fk_allergy_id,severity)
SELECT u.user_id,a.allergy_id,v.severity::venus.risk_level_enum
FROM (
VALUES
('venus-seed-user-002','Fragrância','high'),
('venus-seed-user-005','Fragrância','critical'),
('venus-seed-user-005','Linalool','high'),
('venus-seed-user-006','Salicylic Acid','medium'),
('venus-seed-user-007','Fragrância','high'),
('venus-seed-user-011','Fragrância','critical'),
('venus-seed-user-013','Parfum','high'),
('venus-seed-user-017','Fragrância','high'),
('venus-seed-user-019','Limonene','high'),
('venus-seed-user-023','Fragrância','high'),
('venus-seed-user-025','Fragrância','critical'),
('venus-seed-user-027','Phenoxyethanol','medium'),
('venus-seed-user-031','Fragrância','critical'),
('venus-seed-user-032','Limonene','medium'),
('venus-seed-user-037','Parfum','high'),
('venus-seed-user-038','Fragrância','critical')
) AS v(firebase_uid,allergy_name,severity)
JOIN users u ON u.firebase_uid=v.firebase_uid
JOIN allergies a ON a.allergy_name=v.allergy_name
ON CONFLICT (fk_user_id,fk_allergy_id) DO NOTHING;

INSERT INTO user_profile_tags (fk_user_id,fk_profile_tag_id)
SELECT u.user_id,pt.profile_tag_id
FROM users u
JOIN user_profiles up ON up.fk_user_id=u.user_id
JOIN profile_tags pt ON
       (pt.slug='pele-oleosa' AND up.skin_type='oily')
    OR (pt.slug='pele-seca' AND up.skin_type='dry')
    OR (pt.slug='pele-mista' AND up.skin_type='combination')
    OR (pt.slug='pele-sensivel' AND up.skin_type='sensitive')
    OR (pt.slug='pele-acneica' AND up.acne_prone=TRUE)
    OR (pt.slug='hiperpigmentacao' AND up.has_hyperpigmentation=TRUE)
    OR (pt.slug='sem-fragrancia' AND EXISTS (
           SELECT 1 FROM user_preferences pref
           WHERE pref.fk_user_id=u.user_id
             AND pref.prefer_fragrance_free=TRUE
       ))
    OR (pt.slug='sem-parabenos' AND EXISTS (
           SELECT 1 FROM user_preferences pref
           WHERE pref.fk_user_id=u.user_id
             AND pref.prefer_paraben_free=TRUE
       ))    OR (pt.slug='vegano' AND EXISTS (
           SELECT 1 FROM user_preferences pref
           WHERE pref.fk_user_id=u.user_id AND pref.prefer_vegan=TRUE
       ))
    OR (pt.slug='cruelty-free' AND EXISTS (
           SELECT 1 FROM user_preferences pref
           WHERE pref.fk_user_id=u.user_id AND pref.prefer_cruelty_free=TRUE
       ))
    OR (pt.slug='cuidado-masculino' AND up.gender='male')
    OR (pt.slug='pele-madura' AND up.age_range='age_55_plus')
    OR (pt.slug='muito-seca' AND up.skin_type='dry' AND up.skin_sensitivity IN ('high','very_high'))
    OR (pt.slug='reativa' AND up.skin_sensitivity='very_high')
    OR (pt.slug='manchas-escuras' AND up.has_hyperpigmentation=TRUE)
    OR (pt.slug='melasma' AND up.has_melasma=TRUE)
    OR (pt.slug='rosacea' AND up.has_rosacea=TRUE)
    OR (pt.slug='eczema' AND up.has_eczema=TRUE)
    OR (pt.slug='controle-de-acne' AND up.acne_prone=TRUE)
    OR (pt.slug='controle-de-oleosidade' AND up.skin_type='oily')
    OR (pt.slug='hidratacao' AND up.skin_type IN ('dry','sensitive'))
    OR (pt.slug='reparo-da-barreira' AND up.skin_type IN ('dry','sensitive'))
    OR (pt.slug='propenso-a-cravos' AND up.acne_prone=TRUE)
    OR (pt.slug='definicao-de-cachos' AND up.hair_type IN ('curly','coily'))
    OR (pt.slug='cuidados-com-o-couro-cabeludo' AND up.scalp_type IN ('oily','dry','sensitive'))
    OR (pt.slug='couro-cabeludo-oleoso' AND up.scalp_type='oily')
    OR (pt.slug='couro-cabeludo-seco' AND up.scalp_type='dry')
    OR (pt.slug='couro-cabeludo-sensivel' AND up.scalp_type='sensitive')
    OR (pt.slug='pele-adolescente' AND up.age_range IN ('under_13','age_13_17'))
ON CONFLICT (fk_user_id,fk_profile_tag_id) DO NOTHING;


INSERT INTO products (fk_brand_id, fk_product_category_id, name, description, slug, is_active)
SELECT b.brand_id, pc.product_category_id, v.name, v.description, v.slug, TRUE
FROM (VALUES
('CeraVe','Estados Unidos','cerave-gel-de-limpeza','CeraVe Gel de Limpeza','Produto de catálogo oficial da CeraVe. Fonte principal: https://www.cerave.com.br/todos-os-produtos/gel-de-limpeza','Limpeza facial','https://www.cerave.com.br/todos-os-produtos/gel-de-limpeza'),
('CeraVe','Estados Unidos','cerave-sa-gel-de-limpeza-renovador','CeraVe SA Gel de Limpeza Renovador','Produto de catálogo oficial da CeraVe. Fonte principal: https://www.cerave.com.br/todos-os-produtos/sa-gel-de-limpeza-renovador','Limpeza facial','https://www.cerave.com.br/todos-os-produtos/sa-gel-de-limpeza-renovador'),
('CeraVe','Estados Unidos','cerave-acne-control-gel-de-limpeza','CeraVe Gel de Limpeza Acne Control','Produto de catálogo oficial da CeraVe. Fonte principal: https://www.cerave.com.br/todos-os-produtos/gel-de-limpeza-acne-control','Limpeza facial','https://www.cerave.com.br/todos-os-produtos/gel-de-limpeza-acne-control'),
('CeraVe','Estados Unidos','cerave-acne-control-cuidado-diario','CeraVe Acne Control Cuidado Diário','Produto de catálogo oficial da CeraVe. Fonte principal: https://www.cerave.com.br/todos-os-produtos/acne-control-cuidado-diario','Tratamento facial','https://www.cerave.com.br/todos-os-produtos/acne-control-cuidado-diario'),
('CeraVe','Estados Unidos','cerave-creme-hidratante','CeraVe Creme Hidratante','Produto de catálogo oficial da CeraVe. Fonte principal: https://www.cerave.com.br/todos-os-produtos/creme-hidratante','Hidratação','https://www.cerave.com.br/todos-os-produtos/creme-hidratante'),
('CeraVe','Estados Unidos','cerave-locao-hidratante','CeraVe Loção Hidratante','Produto de catálogo oficial da CeraVe. Fonte principal: https://www.cerave.com.br/todos-os-produtos/locao-hidratante','Hidratação','https://www.cerave.com.br/todos-os-produtos/locao-hidratante'),
('CeraVe','Estados Unidos','cerave-locao-facial-hidratante','CeraVe Loção Facial Hidratante','Produto de catálogo oficial da CeraVe. Fonte principal: https://www.cerave.com.br/todos-os-produtos/locao-facial-hidratante','Hidratação facial','https://www.cerave.com.br/todos-os-produtos/locao-facial-hidratante'),
('CeraVe','Estados Unidos','cerave-locao-facial-oil-control','CeraVe Loção Facial Oil Control','Produto de catálogo oficial da CeraVe. Fonte principal: https://www.cerave.com.br/todos-os-produtos/locao-facial-oil-control','Hidratação facial','https://www.cerave.com.br/todos-os-produtos/locao-facial-oil-control'),
('CeraVe','Estados Unidos','cerave-locao-facial-hidratante-fps50','CeraVe Loção Facial Hidratante FPS50','Produto de catálogo oficial da CeraVe. Fonte principal: https://www.cerave.com.br/todos-os-produtos/locao-facial-hidratante-fps50','Proteção solar','https://www.cerave.com.br/todos-os-produtos/locao-facial-hidratante-fps50'),
('CeraVe','Estados Unidos','cerave-locao-de-limpeza-hidratante','CeraVe Loção de Limpeza Hidratante','Produto de catálogo oficial da CeraVe. Fonte principal: https://www.cerave.com.br/todos-os-produtos/locao-de-limpeza-hidratante','Limpeza facial','https://www.cerave.com.br/todos-os-produtos/locao-de-limpeza-hidratante'),
('CeraVe','Estados Unidos','cerave-oleo-de-limpeza-hidratante','CeraVe Óleo de Limpeza Hidratante','Produto de catálogo oficial da CeraVe. Fonte principal: https://www.cerave.com.br/todos-os-produtos/oleo-de-limpeza-hidratante','Limpeza facial','https://www.cerave.com.br/todos-os-produtos/oleo-de-limpeza-hidratante'),
('CeraVe','Estados Unidos','cerave-creme-reparador-para-maos','CeraVe Creme Reparador para as Mãos','Produto de catálogo oficial da CeraVe. Fonte principal: https://www.cerave.com.br/todos-os-produtos/creme-reparador-para-maos','Hidratação','https://www.cerave.com.br/todos-os-produtos/creme-reparador-para-maos'),
('CeraVe','Estados Unidos','cerave-sa-creme-renovador-pes','CeraVe SA Creme Renovador para os Pés','Produto de catálogo oficial da CeraVe. Fonte principal: https://www.cerave.com.br/todos-os-produtos/sa-creme-renovador-para-os-pes','Cuidados dos pés','https://www.cerave.com.br/todos-os-produtos/sa-creme-renovador-para-os-pes'),
('CeraVe','Estados Unidos','cerave-espuma-cremosa-limpeza-hidratante','CeraVe Espuma Cremosa de Limpeza Hidratante','Produto de catálogo oficial da CeraVe. Fonte principal: https://www.cerave.com.br/todos-os-produtos/espuma-cremosa-de-limpeza-hidratante','Limpeza facial','https://www.cerave.com.br/todos-os-produtos/espuma-cremosa-de-limpeza-hidratante'),
('CeraVe','Estados Unidos','cerave-creme-reparador-olhos','CeraVe Creme Reparador para os Olhos','Produto de catálogo oficial da CeraVe. Fonte principal: https://www.cerave.com.br/todos-os-produtos/creme-reparador-para-olhos','Área dos olhos','https://www.cerave.com.br/todos-os-produtos/creme-reparador-para-olhos'),
('CeraVe','Estados Unidos','cerave-serum-hidratante-acido-hialuronico','CeraVe Sérum Hidratante com Ácido Hialurônico','Produto de catálogo oficial da CeraVe. Fonte principal: https://www.cerave.com.br/','Sérum facial','https://www.cerave.com.br/'),
('CeraVe','Estados Unidos','cerave-serum-retinol-refinador','CeraVe Sérum Retinol Refinador','Produto de catálogo oficial da CeraVe. Fonte principal: https://www.cerave.com.br/','Sérum facial','https://www.cerave.com.br/'),
('CeraVe','Estados Unidos','cerave-serum-renovador','CeraVe Sérum Renovador','Produto de catálogo oficial da CeraVe. Fonte principal: https://www.cerave.com.br/','Sérum facial','https://www.cerave.com.br/'),
('CeraVe','Estados Unidos','cerave-creme-espuma-hidratante','CeraVe Creme-espuma de Limpeza Hidratante','Produto de catálogo oficial da CeraVe. Fonte principal: https://www.cerave.com.br/todos-os-produtos/espuma-cremosa-de-limpeza-hidratante','Limpeza facial','https://www.cerave.com.br/todos-os-produtos/espuma-cremosa-de-limpeza-hidratante'),
('CeraVe','Estados Unidos','cerave-hidratante-facial-fps30','CeraVe Hidratante Facial FPS30','Produto de catálogo oficial da CeraVe. Fonte principal: https://www.cerave.com.br/','Proteção solar','https://www.cerave.com.br/'),
('La Roche-Posay','França','lrp-effaclar-gel-concentrado','La Roche-Posay Effaclar Gel Concentrado','Produto de catálogo oficial da La Roche-Posay. Fonte principal: https://www.laroche-posay.com.br/effaclar/gel-concentrado','Limpeza facial','https://www.laroche-posay.com.br/effaclar/gel-concentrado'),
('La Roche-Posay','França','lrp-effaclar-gel-alta-tolerancia','La Roche-Posay Effaclar Gel Alta Tolerância','Produto de catálogo oficial da La Roche-Posay. Fonte principal: https://www.laroche-posay.com.br/effaclar/gel-alta-tolerancia','Limpeza facial','https://www.laroche-posay.com.br/effaclar/gel-alta-tolerancia'),
('La Roche-Posay','França','lrp-effaclar-sabonete-concentrado','La Roche-Posay Effaclar Sabonete Concentrado','Produto de catálogo oficial da La Roche-Posay. Fonte principal: https://www.laroche-posay.com.br/effaclar/sabonete-concentrado','Limpeza facial','https://www.laroche-posay.com.br/effaclar/sabonete-concentrado'),
('La Roche-Posay','França','lrp-effaclar-solucao-micelar-ultra','La Roche-Posay Effaclar Solução Micelar Ultra','Produto de catálogo oficial da La Roche-Posay. Fonte principal: https://www.laroche-posay.com.br/effaclar/solucao-micelar-ultra','Limpeza facial','https://www.laroche-posay.com.br/effaclar/solucao-micelar-ultra'),
('La Roche-Posay','França','lrp-effaclar-serum-antiacne','La Roche-Posay Effaclar Sérum Antiacne Ultra Concentrado','Produto de catálogo oficial da La Roche-Posay. Fonte principal: https://www.laroche-posay.com.br/effaclar/serum-antiacne-ultra-concentrado','Sérum facial','https://www.laroche-posay.com.br/effaclar/serum-antiacne-ultra-concentrado'),
('La Roche-Posay','França','lrp-effaclar-mat','La Roche-Posay Effaclar Mat','Produto de catálogo oficial da La Roche-Posay. Fonte principal: https://www.laroche-posay.com.br/effaclar/mat','Hidratação facial','https://www.laroche-posay.com.br/effaclar/mat'),
('La Roche-Posay','França','lrp-effaclar-duo-fps30','La Roche-Posay Effaclar Duo+ FPS30','Produto de catálogo oficial da La Roche-Posay. Fonte principal: https://www.laroche-posay.com.br/effaclar/duo-fps30','Tratamento facial','https://www.laroche-posay.com.br/effaclar/duo-fps30'),
('La Roche-Posay','França','lrp-lipikar-locao','La Roche-Posay Lipikar Loção','Produto de catálogo oficial da La Roche-Posay. Fonte principal: https://www.laroche-posay.com.br/lipikar/locao','Hidratação corporal','https://www.laroche-posay.com.br/lipikar/locao'),
('La Roche-Posay','França','lrp-lipikar-baume-apm','La Roche-Posay Lipikar Baume AP+M','Produto de catálogo oficial da La Roche-Posay. Fonte principal: https://www.laroche-posay.com.br/lipikar','Hidratação corporal','https://www.laroche-posay.com.br/lipikar'),
('La Roche-Posay','França','lrp-cicaplast-baume-b5','La Roche-Posay Cicaplast Baume B5+','Produto de catálogo oficial da La Roche-Posay. Fonte principal: https://www.laroche-posay.com.br/cicaplast','Reparação da pele','https://www.laroche-posay.com.br/cicaplast'),
('La Roche-Posay','França','lrp-toleriane-sensitive','La Roche-Posay Toleriane Sensitive','Produto de catálogo oficial da La Roche-Posay. Fonte principal: https://www.laroche-posay.com.br/toleriane','Hidratação facial','https://www.laroche-posay.com.br/toleriane'),
('La Roche-Posay','França','lrp-toleriane-dermallergo-fluido','La Roche-Posay Toleriane Dermallergo Fluide','Produto de catálogo oficial da La Roche-Posay. Fonte principal: https://www.laroche-posay.com.br/toleriane','Hidratação facial','https://www.laroche-posay.com.br/toleriane'),
('La Roche-Posay','França','lrp-toleriane-agua-micelar','La Roche-Posay Toleriane Água Micelar','Produto de catálogo oficial da La Roche-Posay. Fonte principal: https://www.laroche-posay.com.br/toleriane','Limpeza facial','https://www.laroche-posay.com.br/toleriane'),
('La Roche-Posay','França','lrp-anthelios-airlicium-fps70','La Roche-Posay Anthelios Airlicium FPS70','Produto de catálogo oficial da La Roche-Posay. Fonte principal: https://www.laroche-posay.com.br/anthelios','Proteção solar','https://www.laroche-posay.com.br/anthelios'),
('La Roche-Posay','França','lrp-anthelios-xl-protect-fps60','La Roche-Posay Anthelios XL Protect FPS60','Produto de catálogo oficial da La Roche-Posay. Fonte principal: https://www.laroche-posay.com.br/anthelios','Proteção solar','https://www.laroche-posay.com.br/anthelios'),
('La Roche-Posay','França','lrp-hyalu-b5-serum','La Roche-Posay Hyalu B5 Sérum','Produto de catálogo oficial da La Roche-Posay. Fonte principal: https://www.laroche-posay.com.br/hyalu-b5','Sérum facial','https://www.laroche-posay.com.br/hyalu-b5'),
('La Roche-Posay','França','lrp-vitamina-c10','La Roche-Posay Pure Vitamin C10','Produto de catálogo oficial da La Roche-Posay. Fonte principal: https://www.laroche-posay.com.br/vitamina-c','Sérum facial','https://www.laroche-posay.com.br/vitamina-c'),
('La Roche-Posay','França','lrp-mela-b3-serum','La Roche-Posay Mela B3 Sérum','Produto de catálogo oficial da La Roche-Posay. Fonte principal: https://www.laroche-posay.com.br/mela-b3','Sérum facial','https://www.laroche-posay.com.br/mela-b3'),
('La Roche-Posay','França','lrp-retinol-b3-serum','La Roche-Posay Retinol B3 Sérum','Produto de catálogo oficial da La Roche-Posay. Fonte principal: https://www.laroche-posay.com.br/retinol','Sérum facial','https://www.laroche-posay.com.br/retinol'),
('La Roche-Posay','França','lrp-kerium-ds-creme','La Roche-Posay Kerium DS Creme','Produto de catálogo oficial da La Roche-Posay. Fonte principal: https://www.laroche-posay.com.br/kerium','Cuidados do couro cabeludo','https://www.laroche-posay.com.br/kerium'),
('La Roche-Posay','França','lrp-agua-termal','La Roche-Posay Água Termal','Produto de catálogo oficial da La Roche-Posay. Fonte principal: https://www.laroche-posay.com.br/','Água termal','https://www.laroche-posay.com.br/'),
('Eucerin','Alemanha','eucerin-dermopure-gel-gentil-200','Eucerin DERMOPURE CLINICAL Gel de Limpeza Facial Gentil 200ml','Produto de catálogo oficial da Eucerin. Fonte principal: https://www.eucerin.com.br/produtos','Limpeza facial','https://www.eucerin.com.br/produtos'),
('Eucerin','Alemanha','eucerin-dermopure-gel-concentrado-150','Eucerin DERMOPURE CLINICAL Gel de Limpeza Facial Concentrado 150ml','Produto de catálogo oficial da Eucerin. Fonte principal: https://www.eucerin.com.br/produtos','Limpeza facial','https://www.eucerin.com.br/produtos'),
('Eucerin','Alemanha','eucerin-dermopure-gel-concentrado-400','Eucerin DERMOPURE CLINICAL Gel de Limpeza Facial Concentrado 400ml','Produto de catálogo oficial da Eucerin. Fonte principal: https://www.eucerin.com.br/produtos','Limpeza facial','https://www.eucerin.com.br/produtos'),
('Eucerin','Alemanha','eucerin-dermopure-gel-creme','Eucerin Dermo Pure Oil Control Gel Creme Facial Ação Renovadora Intensa 40ml','Produto de catálogo oficial da Eucerin. Fonte principal: https://www.eucerin.com.br/produtos','Tratamento facial','https://www.eucerin.com.br/produtos'),
('Eucerin','Alemanha','eucerin-dermopure-serum-triplo','Eucerin Dermo Pure Oil Control Sérum Efeito Triplo Dia e Noite 40ml','Produto de catálogo oficial da Eucerin. Fonte principal: https://www.eucerin.com.br/produtos','Sérum facial','https://www.eucerin.com.br/produtos'),
('Eucerin','Alemanha','eucerin-dermopure-corporal-triplo','Eucerin DERMOPURE CLINICAL Creme Corporal Efeito Triplo 200ml','Produto de catálogo oficial da Eucerin. Fonte principal: https://www.eucerin.com.br/produtos/dermopure-clinical/correcting-body-care','Hidratação corporal','https://www.eucerin.com.br/produtos/dermopure-clinical/correcting-body-care'),
('Eucerin','Alemanha','eucerin-antipigment-dia-fps30','Eucerin Anti-Pigment Creme Facial Dia FPS30 50ml','Produto de catálogo oficial da Eucerin. Fonte principal: https://www.eucerin.com.br/produtos','Hidratação facial','https://www.eucerin.com.br/produtos'),
('Eucerin','Alemanha','eucerin-antipigment-dual-serum','Eucerin Anti-Pigment Dual Sérum Facial 30ml','Produto de catálogo oficial da Eucerin. Fonte principal: https://www.eucerin.com.br/produtos','Sérum facial','https://www.eucerin.com.br/produtos'),
('Eucerin','Alemanha','eucerin-antipigment-gel-esfoliante','Eucerin Anti-Pigment Gel de Limpeza Esfoliante 200ml','Produto de catálogo oficial da Eucerin. Fonte principal: https://www.eucerin.com.br/produtos','Limpeza facial','https://www.eucerin.com.br/produtos'),
('Eucerin','Alemanha','eucerin-aquaphor-pomada','Eucerin Aquaphor Pomada Reparadora Dia e Noite 49g','Produto de catálogo oficial da Eucerin. Fonte principal: https://www.eucerin.com.br/produtos','Reparação da pele','https://www.eucerin.com.br/produtos'),
('Eucerin','Alemanha','eucerin-aquaphor-labial','Eucerin Aquaphor Reparador Labial 10ml','Produto de catálogo oficial da Eucerin. Fonte principal: https://www.eucerin.com.br/produtos','Cuidados labiais','https://www.eucerin.com.br/produtos'),
('Eucerin','Alemanha','eucerin-ph5-gel-oleo-banho','Eucerin pH5 Gel e Óleo de Banho 400ml','Produto de catálogo oficial da Eucerin. Fonte principal: https://www.eucerin.com.br/produtos/body','Limpeza corporal','https://www.eucerin.com.br/produtos/body'),
('Eucerin','Alemanha','eucerin-ph5-gel-creme','Eucerin pH5 Gel Creme 350ml','Produto de catálogo oficial da Eucerin. Fonte principal: https://www.eucerin.com.br/produtos/body','Hidratação corporal','https://www.eucerin.com.br/produtos/body'),
('Eucerin','Alemanha','eucerin-hyaluron-booster','Eucerin Hyaluron-Filler Daily Booster Gel Facial Antirrugas 30ml','Produto de catálogo oficial da Eucerin. Fonte principal: https://www.eucerin.com.br/produtos/cuidados-faciais','Hidratação facial','https://www.eucerin.com.br/produtos/cuidados-faciais'),
('Eucerin','Alemanha','eucerin-hyaluron-pore-serum','Eucerin Hyaluron-Filler Pore Minimizer Sérum Facial Antirrugas 30ml','Produto de catálogo oficial da Eucerin. Fonte principal: https://www.eucerin.com.br/produtos/cuidados-faciais','Sérum facial','https://www.eucerin.com.br/produtos/cuidados-faciais'),
('CeraVe','Estados Unidos','cerave-locao-facial-hidratante-noite','CeraVe Loção Facial Hidratante Noite','Produto de catálogo oficial da CeraVe. Fonte principal: https://www.cerave.com.br/','Hidratação facial','https://www.cerave.com.br/'),
('Eucerin','Alemanha','eucerin-hyaluron-filler-dia-fps30','Eucerin Hyaluron-Filler Dia Creme Facial Antirrugas FPS30 50ml','Produto de catálogo oficial da Eucerin. Fonte principal: https://www.eucerin.com.br/produtos/cuidados-faciais','Hidratação facial','https://www.eucerin.com.br/produtos/cuidados-faciais')
) AS v(brand,country,slug,name,description,category,source_url)
JOIN brands b ON b.name=v.brand AND b.country=v.country
JOIN product_categories pc
  ON pc.name = CASE v.category
       WHEN 'Limpeza facial' THEN 'Gel de Limpeza'
       WHEN 'Tratamento facial' THEN 'Tratamento Local'
       WHEN 'Hidratação' THEN 'Hidratante'
       WHEN 'Hidratação facial' THEN 'Hidratante'
       WHEN 'Proteção solar' THEN 'Protetor Solar'
       WHEN 'Cuidados dos pés' THEN 'Creme para Pés'
       WHEN 'Área dos olhos' THEN 'Creme para Olhos'
       WHEN 'Sérum facial' THEN 'Sérum Facial'
       WHEN 'Hidratação corporal' THEN 'Loção Corporal'
       WHEN 'Reparação da pele' THEN 'Hidratante'
       WHEN 'Cuidados do couro cabeludo' THEN 'Tratamento para Couro Cabeludo'
       WHEN 'Água termal' THEN 'Bruma Facial'
       WHEN 'Cuidados labiais' THEN 'Bálsamo Labial'
       WHEN 'Limpeza corporal' THEN 'Sabonete Corporal'
       ELSE v.category
     END
ON CONFLICT (slug) DO NOTHING;

INSERT INTO product_versions
 (fk_product_id, version_name, display_name, status, is_current, formula_signature, detected_by, effective_from)
SELECT p.product_id, COALESCE(v.version_name,'CATALOG-'||p.slug), p.name,
       COALESCE(v.status::venus.version_status_enum,'needs_review'::venus.version_status_enum), TRUE, COALESCE(v.signature,'CATALOG-'||p.slug), 'official_site'::venus.source_type_enum, CURRENT_DATE
FROM products p
LEFT JOIN (VALUES
('cerave-gel-de-limpeza','F.I.L. D250307/1','F.I.L. D250307/1','verified'),
('cerave-sa-gel-de-limpeza-renovador','F.I.L. D235671/1','F.I.L. D235671/1','verified'),
('cerave-acne-control-gel-de-limpeza','F.I.L. C274845/2','F.I.L. C274845/2','verified'),
('cerave-acne-control-cuidado-diario','F.I.L. D271240/1','F.I.L. D271240/1','verified'),
('cerave-creme-hidratante','F.I.L. D213768/2','F.I.L. D213768/2','verified'),
('cerave-locao-hidratante','F.I.L. D213778/1','F.I.L. D213778/1','verified'),
('cerave-locao-facial-hidratante','F.I.L. D213445/2','F.I.L. D213445/2','verified'),
('cerave-locao-facial-oil-control','F.I.L. Z70040235/1','F.I.L. Z70040235/1','verified'),
('cerave-locao-facial-hidratante-fps50','F.I.L. Y292332/1','F.I.L. Y292332/1','verified'),
('cerave-locao-de-limpeza-hidratante','F.I.L. D214629/3','F.I.L. D214629/3','verified'),
('cerave-oleo-de-limpeza-hidratante','F.I.L. Y70024722/1','F.I.L. Y70024722/1','verified'),
('cerave-creme-reparador-para-maos','F.I.L. D215085/2','F.I.L. D215085/2','verified'),
('cerave-sa-creme-renovador-pes','F.I.L. D215076/3','F.I.L. D215076/3','verified'),
('cerave-espuma-cremosa-limpeza-hidratante',NULL,NULL,'needs_review'),
('cerave-creme-reparador-olhos',NULL,NULL,'needs_review'),
('cerave-serum-hidratante-acido-hialuronico',NULL,NULL,'needs_review'),
('cerave-serum-retinol-refinador',NULL,NULL,'needs_review'),
('cerave-serum-renovador',NULL,NULL,'needs_review'),
('cerave-creme-espuma-hidratante',NULL,NULL,'needs_review'),
('cerave-hidratante-facial-fps30',NULL,NULL,'needs_review'),
('lrp-effaclar-gel-concentrado','OFFICIAL-BR-LRP-EFFACLAR-GEL','OFFICIAL-BR-LRP-EFFACLAR-GEL','verified'),
('lrp-effaclar-gel-alta-tolerancia','OFFICIAL-BR-LRP-EFFACLAR-ALTA-TOLERANCIA','OFFICIAL-BR-LRP-EFFACLAR-ALTA-TOLERANCIA','verified'),
('lrp-effaclar-sabonete-concentrado','OFFICIAL-BR-LRP-EFFACLAR-SABONETE','OFFICIAL-BR-LRP-EFFACLAR-SABONETE','verified'),
('lrp-effaclar-solucao-micelar-ultra','OFFICIAL-BR-LRP-EFFACLAR-MICELAR','OFFICIAL-BR-LRP-EFFACLAR-MICELAR','verified'),
('lrp-effaclar-serum-antiacne','OFFICIAL-BR-LRP-EFFACLAR-SERUM','OFFICIAL-BR-LRP-EFFACLAR-SERUM','verified'),
('lrp-effaclar-mat','OFFICIAL-BR-LRP-EFFACLAR-MAT','OFFICIAL-BR-LRP-EFFACLAR-MAT','verified'),
('lrp-effaclar-duo-fps30','OFFICIAL-BR-LRP-EFFACLAR-DUO-FPS30','OFFICIAL-BR-LRP-EFFACLAR-DUO-FPS30','verified'),
('lrp-lipikar-locao','OFFICIAL-BR-LRP-LIPIKAR-LOCAO','OFFICIAL-BR-LRP-LIPIKAR-LOCAO','verified'),
('lrp-lipikar-baume-apm',NULL,NULL,'needs_review'),
('lrp-cicaplast-baume-b5',NULL,NULL,'needs_review'),
('lrp-toleriane-sensitive',NULL,NULL,'needs_review'),
('lrp-toleriane-dermallergo-fluido',NULL,NULL,'needs_review'),
('lrp-toleriane-agua-micelar',NULL,NULL,'needs_review'),
('lrp-anthelios-airlicium-fps70',NULL,NULL,'needs_review'),
('lrp-anthelios-xl-protect-fps60',NULL,NULL,'needs_review'),
('lrp-hyalu-b5-serum',NULL,NULL,'needs_review'),
('lrp-vitamina-c10',NULL,NULL,'needs_review'),
('lrp-mela-b3-serum',NULL,NULL,'needs_review'),
('lrp-retinol-b3-serum',NULL,NULL,'needs_review'),
('lrp-kerium-ds-creme',NULL,NULL,'needs_review'),
('lrp-agua-termal',NULL,NULL,'needs_review'),
('eucerin-dermopure-gel-gentil-200',NULL,NULL,'needs_review'),
('eucerin-dermopure-gel-concentrado-150',NULL,NULL,'needs_review'),
('eucerin-dermopure-gel-concentrado-400',NULL,NULL,'needs_review'),
('eucerin-dermopure-gel-creme',NULL,NULL,'needs_review'),
('eucerin-dermopure-serum-triplo',NULL,NULL,'needs_review'),
('eucerin-dermopure-corporal-triplo',NULL,NULL,'needs_review'),
('eucerin-antipigment-dia-fps30',NULL,NULL,'needs_review'),
('eucerin-antipigment-dual-serum',NULL,NULL,'needs_review'),
('eucerin-antipigment-gel-esfoliante',NULL,NULL,'needs_review'),
('eucerin-aquaphor-pomada',NULL,NULL,'needs_review'),
('eucerin-aquaphor-labial',NULL,NULL,'needs_review'),
('eucerin-ph5-gel-oleo-banho',NULL,NULL,'needs_review'),
('eucerin-ph5-gel-creme',NULL,NULL,'needs_review'),
('eucerin-hyaluron-booster',NULL,NULL,'needs_review'),
('eucerin-hyaluron-pore-serum',NULL,NULL,'needs_review'),
('cerave-locao-facial-hidratante-noite',NULL,NULL,'needs_review'),
('eucerin-hyaluron-filler-dia-fps30',NULL,NULL,'needs_review')
) AS v(slug,version_name,signature,status) ON v.slug=p.slug
ON CONFLICT (fk_product_id, formula_signature) DO NOTHING;

INSERT INTO product_labels (fk_product_version_id, normalized_text, language, source_type, source_reference)
SELECT pv.product_version_id,
       COALESCE(f.normalized_text, 'CATÁLOGO OFICIAL — composição integral não capturada nesta carga; consultar a embalagem/página oficial antes da validação.'),
       'pt-BR','official_site', COALESCE(f.source_url, b.website)
FROM product_versions pv
JOIN products p ON p.product_id=pv.fk_product_id
JOIN brands b ON b.brand_id=p.fk_brand_id
LEFT JOIN (VALUES
('F.I.L. D250307/1','Aqua, Cocamidopropyl Hydroxysultaine, Glycerin, Sodium Lauroyl Sarcosinate, Propanediol, PEG-150 Pentaerythrityl Tetrastearate, Niacinamide, PEG-6 Caprylic/Capric Glycerides, Ceramide NP, Ceramide AP, Ceramide EOP, Carbomer, Sodium Methyl Cocoyl Taurate, Sodium Benzoate, Sodium Chloride, Sodium Lauroyl Lactylate, Sodium Hyaluronate, Cholesterol, Phenoxyethanol, Disodium EDTA, Citric Acid, Sodium EDTA, Phytosphingosine, Xanthan Gum, Ethylhexylglycerin','https://www.cerave.com.br/todos-os-produtos/gel-de-limpeza'),
('F.I.L. D235671/1','Aqua, Sodium Lauroyl Sarcosinate, Cocamidopropyl Hydroxysultaine, Glycerin, Niacinamide, Gluconolactone, Sodium Methyl Cocoyl Taurate, PEG-150 Pentaerythrityl Tetrastearate, Ceramide EOP, Ceramide NP, Ceramide AP, Carbomer, Calcium Gluconate, Salicylic Acid, Sodium Benzoate, Sodium Lauroyl Lactylate, Cholesterol, Phenoxyethanol, Disodium EDTA, Sodium EDTA, Hydrolyzed Hyaluronic Acid, Phytosphingosine, Xanthan Gum, Ethylhexylglycerin','https://www.cerave.com.br/todos-os-produtos/sa-gel-de-limpeza-renovador'),
('F.I.L. C274845/2','Aqua, Sodium Lauroyl Sarcosinate, Cocamidopropyl Hydroxysultaine, Glycerin, Niacinamide, Salicylic Acid, Gluconolactone, Sodium Methyl Cocoyl Taurate, PEG-150 Pentaerythrityl Tetrastearate, Ceramide EOP, Ceramide NP, Ceramide AP, Carbomer, Calcium Gluconate, Triethyl Citrate, Sodium Benzoate, Sodium Hydroxide, Sodium Lauroyl Lactylate, Cholesterol, Sodium EDTA, Caprylyl Glycol, Hydrolyzed Hyaluronic Acid, Trisodium Ethylenediamine Disuccinate, Xanthan Gum, Hectorite, Phytosphingosine, Benzoic Acid','https://www.cerave.com.br/todos-os-produtos/gel-de-limpeza-acne-control'),
('F.I.L. D271240/1','Aqua, Glycerin, Sodium Hydroxide, Glycolic Acid, Lactic Acid, Salicylic Acid, Niacinamide, Guar Gum, Xanthan Gum, Chlorphenesin, Sodium Hyaluronate, Disodium EDTA, Sodium Lauroyl Lactylate, Cetearyl Alcohol, Behentrimonium Methosulfate, Ceramide NP, Triethyl Citrate, Caprylyl Glycol, Ceramide AP, Phytosphingosine, Cholesterol, Carbomer, Benzoic Acid, Ceramide EOP','https://www.cerave.com.br/todos-os-produtos/acne-control-cuidado-diario'),
('F.I.L. D213768/2','Aqua, Glycerin, Cetearyl Alcohol, Caprylic/Capric Triglyceride, Cetyl Alcohol, Ceteareth-20, Petrolatum, Potassium Phosphate, Ceramide NP, Ceramide AP, Ceramide EOP, Carbomer, Dimethicone, Behentrimonium Methosulfate, Sodium Lauroyl Lactylate, Sodium Hyaluronate, Cholesterol, Phenoxyethanol, Disodium EDTA, Dipotassium Phosphate, Tocopherol, Phytosphingosine, Xanthan Gum, Ethylhexylglycerin','https://www.cerave.com.br/todos-os-produtos/creme-hidratante'),
('F.I.L. D213778/1','Aqua, Glycerin, Caprylic/Capric Triglyceride, Cetearyl Alcohol, Cetyl Alcohol, Dimethicone, Phenoxyethanol, Polysorbate 20, Ceteareth-20, Behentrimonium Methosulfate, Polyglyceryl-3 Diisostearate, Sodium Lauroyl Lactylate, Ethylhexylglycerin, Potassium Phosphate, Disodium EDTA, Dipotassium Phosphate, Ceramide NP, Ceramide AP, Phytosphingosine, Cholesterol, Xanthan Gum, Carbomer, Sodium Hyaluronate, Tocopherol, Ceramide EOP','https://www.cerave.com.br/todos-os-produtos/locao-hidratante'),
('F.I.L. D213445/2','Aqua, Glycerin, Caprylic/Capric Triglyceride, Niacinamide, Cetearyl Alcohol, Potassium Phosphate, Ceramide NP, Ceramide AP, Ceramide EOP, Carbomer, Dimethicone, Ceteareth-20, Behentrimonium Methosulfate, Sodium Lauroyl Lactylate, Sodium Hyaluronate, Cholesterol, Phenoxyethanol, Disodium EDTA, Dipotassium Phosphate, Caprylyl Glycol, Phytosphingosine, Xanthan Gum, Polyglyceryl-3 Diisostearate, Ethylhexylglycerin','https://www.cerave.com.br/todos-os-produtos/locao-facial-hidratante'),
('F.I.L. Z70040235/1','Aqua, Niacinamide, Glycerin, Cetearyl Isononanoate, C14-22 Alcohols, Isopropyl Myristate, Starch, Ceramide NP, Ceramide AP, Ceramide EOP, Carbomer, Cetearyl Alcohol, Behentrimonium Methosulfate, Triethyl Citrate, Silica, Sodium Hydroxide, Sodium Hyaluronate, Sodium Lauroyl Lactylate, Cholesterol, Phenoxyethanol, Citric Acid, Caprylyl Glycol, Trisodium Ethylenediamine Disuccinate, Xanthan Gum, Phytosphingosine, Polyacrylate-6 Crosspolymer, Benzoic Acid, C12-20 Alkyl Glucoside','https://www.cerave.com.br/todos-os-produtos/locao-facial-oil-control'),
('F.I.L. Y292332/1','Aqua, Glycerin, Isopropyl Palmitate, Bis-Ethylhexyloxyphenol Methoxyphenyl Triazine, Ethylhexyl Salicylate, Niacinamide, Butyl Methoxydibenzoylmethane, Ethylhexyl Triazone, Pentylene Glycol, Propanediol, Starch, Potassium Cetyl Phosphate, Diisopropyl Sebacate, Oryza Sativa Wax, Stearic Acid, Ceramide NP, Ceramide AP, Ceramide EOP, Carbomer, Glyceryl Stearate, Cetearyl Alcohol, Trolamine, Behentrimonium Methosulfate, Triethyl Citrate, Sodium Hyaluronate, Sodium Polyacrylate, Sodium Lauroyl Lactylate, Myristic Acid, Cholesterol, Palmitic Acid, Tocopherol, Caprylyl Glycol, Citric Acid, Trisodium Ethylenediamine Disuccinate, Xanthan Gum, Phytosphingosine, Acrylates/C10-30 Alkyl Acrylate Crosspolymer, Butyrospermum Parkii Butter, Benzoic Acid, Macrogol 100 Stearate','https://www.cerave.com.br/todos-os-produtos/locao-facial-hidratante-fps50'),
('F.I.L. D214629/3','Aqua, Glycerin, Cetearyl Alcohol, Phenoxyethanol, Stearyl Alcohol, Cetyl Alcohol, Macrogol 2000 Stearate, Behentrimonium Methosulfate, Glyceryl Stearate, Polysorbate 20, Ethylhexylglycerin, Potassium Phosphate, Disodium EDTA, Dipotassium Phosphate, Sodium Lauroyl Lactylate, Ceramide NP, Ceramide AP, Phytosphingosine, Cholesterol, Sodium Hyaluronate, Xanthan Gum, Carbomer, Tocopherol, Ceramide EOP','https://www.cerave.com.br/todos-os-produtos/locao-de-limpeza-hidratante'),
('F.I.L. Y70024722/1','Aqua, Glycerin, PEG-200 Hydrogenated Glyceryl Palmate, Coco-Betaine, Disodium Cocoyl Glutamate, PEG-120 Methyl Glucose Dioleate, Polysorbate 20, PEG-7 Glyceryl Cocoate, PEG-150 Pentaerythrityl Tetrastearate, PPG-5-Ceteth-20, PEG-6 Caprylic/Capric Glycerides, Ceramide EOP, Squalane, Ceramide NP, Ceramide AP, Carbomer, Triethyl Citrate, Sodium Chloride, Sodium Hydroxide, Sodium Cocoyl Glutamate, Sodium Benzoate, Sodium Lauroyl Lactylate, Sodium Hyaluronate, Cholesterol, Citric Acid, Capryloyl Glycine, Hydroxyacetophenone, Caprylyl Glycol, Trisodium Ethylenediamine Disuccinate, Phytosphingosine, Xanthan Gum, Benzoic Acid','https://www.cerave.com.br/todos-os-produtos/oleo-de-limpeza-hidratante'),
('F.I.L. D215085/2','Aqua, Glycerin, Cetearyl Alcohol, Caprylic/Capric Triglyceride, Cetyl Alcohol, Ceteareth-20, Petrolatum, Behentrimonium Methosulfate, Carbomer, Ceramide AP, Ceramide EOP, Ceramide NP, Cholesterol, Dimethicone, Dipotassium Phosphate, Disodium EDTA, Ethylhexylglycerin, Phenoxyethanol, Phytosphingosine, Potassium Phosphate, Sodium Hyaluronate, Sodium Lauroyl Lactylate, Tocopherol, Xanthan Gum','https://www.cerave.com.br/todos-os-produtos/creme-reparador-para-maos'),
('F.I.L. D215076/3','Aqua, Glycerin, Mineral Oil, Glyceryl Stearate SE, Cetearyl Alcohol, Niacinamide, Cetyl Alcohol, Ammonium Lactate, Trolamine, Salicylic Acid, Behentrimonium Methosulfate, Macrogol 100 Stearate, Phenoxyethanol, Dimethicone, Sodium Lauroyl Lactylate, Disodium EDTA, Ceramide NP, Ceramide AP, Phytosphingosine, Cholesterol, Xanthan Gum, Carbomer, Ethylhexylglycerin, Sodium Hyaluronate, Ceramide EOP','https://www.cerave.com.br/todos-os-produtos/sa-creme-renovador-para-os-pes'),
('OFFICIAL-BR-LRP-EFFACLAR-GEL','Aqua, Sodium Laureth Sulfate, Decyl Glucoside, Glycerin, Sodium Chloride, Coco-Betaine, Salicylic Acid, PEG-150 Pentaerythrityl Tetrastearate, PEG-6 Caprylic/Capric Glycerides, Zinc Gluconate, Sodium Hydroxide, Capryloyl Salicylic Acid, Tetrasodium EDTA, Citric Acid, Menthol, Polyquaternium-47','https://www.laroche-posay.com.br/effaclar/gel-concentrado'),
('OFFICIAL-BR-LRP-EFFACLAR-ALTA-TOLERANCIA','Aqua, Sodium Laureth Sulfate, PEG-8, Coco-Betaine, Hexylene Glycol, Sodium Chloride, PEG-120 Methyl Glucose Dioleate, Zinc PCA, Sodium Hydroxide, Propylene Glycol, Citric Acid, Sodium Benzoate, Phenoxyethanol, Caprylyl Glycol, Parfum','https://www.laroche-posay.com.br/effaclar/gel-alta-tolerancia'),
('OFFICIAL-BR-LRP-EFFACLAR-SABONETE','Sodium Stearate, Sodium Palmate, Sodium Palm Kernelate, Aqua, Salicylic Acid, Glycerin, Parfum, Perlite, Capryloyl Salicylic Acid, Titanium Dioxide, Etidronic Acid, Phenoxyethanol, Sodium Chloride, Sodium Hydroxide, Tetrasodium EDTA, Zinc PCA','https://www.laroche-posay.com.br/effaclar/sabonete-concentrado'),
('OFFICIAL-BR-LRP-EFFACLAR-MICELAR','Aqua, PEG-7 Caprylic/Capric Glycerides, Poloxamer 124, Poloxamer 184, PEG-6 Caprylic/Capric Glycerides, Glycerin, Polysorbate 80, Zinc PCA, Sodium Hydroxide, Disodium EDTA, BHT, Myrtrimonium Bromide, Parfum','https://www.laroche-posay.com.br/effaclar/solucao-micelar-ultra'),
('OFFICIAL-BR-LRP-EFFACLAR-SERUM','Aqua, Alcohol, Propanediol, Glycolic Acid, Niacinamide, Dimethyl Isosorbide, Pentylene Glycol, Salicylic Acid, Sodium Hydroxide, PPG-26-Buteth-26, Hydroxyethylpiperazine Ethane Sulfonic Acid, Citric Acid, PEG-30 Glyceryl Cocoate, PEG-40 Hydrogenated Castor Oil, Capryloyl Salicylic Acid, Biosaccharide Gum-1, Maltodextrin, Phytic Acid, Polyquaternium-10, Parfum','https://www.laroche-posay.com.br/effaclar/serum-antiacne-ultra-concentrado'),
('OFFICIAL-BR-LRP-EFFACLAR-MAT','Aqua, Glycerin, Dimethicone, Isocetyl Stearate, Alcohol Denat., Silica, Dimethicone/Vinyl Dimethicone Crosspolymer, Acrylamide/Sodium Acryloyldimethyltaurate Copolymer, Methyl Methacrylate Crosspolymer, Butylene Glycol, PEG-100 Stearate, Cocamide MEA, Sarcosine, Glyceryl Stearate, Triethanolamine, Isohexadecane, Perlite, Capryloyl Salicylic Acid, Tetrasodium EDTA, Pentylene Glycol, Polysorbate 80, Acrylates/C10-30 Alkyl Acrylate Crosspolymer, Salicylic Acid, Parfum','https://www.laroche-posay.com.br/effaclar/mat'),
('OFFICIAL-BR-LRP-EFFACLAR-DUO-FPS30','Aqua, Octocrylene, Glycerin, Homosalate, Ethylhexyl Salicylate, Alcohol Denat., Niacinamide, Butyl Methoxydibenzoylmethane, Dimethicone, Sorbitan Stearate, Silica, Isopropyl Lauroyl Sarcosinate, Styrene/Acrylates Copolymer, Propylene Glycol, Potassium Cetyl Phosphate, Diisopropyl Sebacate, PEG-20, PEG-8 Laurate, Zinc PCA, Dimethicone/Vinyl Dimethicone Crosspolymer, Sodium Dodecylbenzenesulfonate, 2-Oleamido-1,3-Octadecanediol, Inulin Lauryl Carbamate, Mannose, Carnosine, Poloxamer 338, Ammonium Polyacryloyldimethyl Taurate, Disodium EDTA, Sucrose Cocoate, Capryloyl Salicylic Acid, Vitreoscilla Ferment, Xanthan Gum, Salicylic Acid, Parfum','https://www.laroche-posay.com.br/effaclar/duo-fps30'),
('OFFICIAL-BR-LRP-LIPIKAR-LOCAO','Aqua, Glycerin, Niacinamide, Dimethicone, Paraffinum Liquidum, Caprylic/Capric Triglyceride, Ammonium Acryloyldimethyltaurate/Steareth-25 Methacrylate Crosspolymer, Propylene Glycol, Brassica Campestris Oleifera Oil, Dimethiconol, Isohexadecane, Disodium EDTA, Caprylyl Glycol, Xanthan Gum, Polysorbate 80, Acrylamide/Sodium Acryloyldimethyltaurate Copolymer, Butyrospermum Parkii Butter, Phenoxyethanol','https://www.laroche-posay.com.br/lipikar/locao')
) AS f(formula_signature,normalized_text,source_url) ON f.formula_signature=pv.formula_signature
ON CONFLICT (fk_product_version_id) DO UPDATE SET
  normalized_text=EXCLUDED.normalized_text, source_type=EXCLUDED.source_type, source_reference=EXCLUDED.source_reference, updated_at=NOW();

INSERT INTO packaging
 (fk_product_version_id, material, material_detail, packaging_format, is_recyclable, is_refillable, is_biodegradable, confidence_score, source_type, source_reference, was_manual_verified)
SELECT pv.product_version_id, 'other'::venus.packaging_material_enum, 'Material não inferido; validar na embalagem física.',
       CASE
         WHEN p.name ILIKE '%sérum%' THEN 'bottle'::packaging_format_enum
         WHEN p.name ILIKE '%gel%' THEN 'tube'::packaging_format_enum
         WHEN p.name ILIKE '%spray%' OR p.name ILIKE '%água termal%' THEN 'spray'::packaging_format_enum
         WHEN p.name ILIKE '%loção%' THEN 'pump'::packaging_format_enum
         WHEN p.name ILIKE '%creme%' OR p.name ILIKE '%pomada%' THEN 'tube'::packaging_format_enum
         ELSE 'other'::venus.packaging_format_enum END,
       FALSE,FALSE,FALSE,0,'official_site'::venus.source_type_enum,b.website,FALSE
FROM product_versions pv JOIN products p ON p.product_id=pv.fk_product_id JOIN brands b ON b.brand_id=p.fk_brand_id
ON CONFLICT (fk_product_version_id) DO NOTHING;

INSERT INTO product_claims
 (fk_product_version_id,fk_claim_id,was_verified,verified_by,verified_at,source_type,source_reference)
SELECT pv.product_version_id,c.claim_id,TRUE,'VENUS_OFFICIAL_SOURCE',NOW(),'official_site'::venus.source_type_enum,v.source_url
FROM (VALUES
('cerave-gel-de-limpeza','Não Comedogênico','https://www.cerave.com.br/todos-os-produtos/gel-de-limpeza'),
('cerave-gel-de-limpeza','Sem Fragrância','https://www.cerave.com.br/todos-os-produtos/gel-de-limpeza'),
('cerave-sa-gel-de-limpeza-renovador','Não Comedogênico','https://www.cerave.com.br/todos-os-produtos/sa-gel-de-limpeza-renovador'),
('cerave-sa-gel-de-limpeza-renovador','Sem Fragrância','https://www.cerave.com.br/todos-os-produtos/sa-gel-de-limpeza-renovador'),
('cerave-acne-control-gel-de-limpeza','Não Comedogênico','https://www.cerave.com.br/todos-os-produtos/gel-de-limpeza-acne-control'),
('cerave-acne-control-gel-de-limpeza','Sem Fragrância','https://www.cerave.com.br/todos-os-produtos/gel-de-limpeza-acne-control'),
('cerave-acne-control-gel-de-limpeza','Sem Parabenos','https://www.cerave.com.br/todos-os-produtos/gel-de-limpeza-acne-control'),
('cerave-acne-control-cuidado-diario','Não Comedogênico','https://www.cerave.com.br/todos-os-produtos/acne-control-cuidado-diario'),
('cerave-acne-control-cuidado-diario','Sem Fragrância','https://www.cerave.com.br/todos-os-produtos/acne-control-cuidado-diario'),
('cerave-acne-control-cuidado-diario','Sem Parabenos','https://www.cerave.com.br/todos-os-produtos/acne-control-cuidado-diario'),
('cerave-creme-hidratante','Não Comedogênico','https://www.cerave.com.br/todos-os-produtos/creme-hidratante'),
('cerave-creme-hidratante','Sem Fragrância','https://www.cerave.com.br/todos-os-produtos/creme-hidratante'),
('cerave-locao-facial-hidratante','Não Comedogênico','https://www.cerave.com.br/todos-os-produtos/locao-facial-hidratante'),
('cerave-locao-facial-hidratante','Sem Fragrância','https://www.cerave.com.br/todos-os-produtos/locao-facial-hidratante'),
('cerave-locao-de-limpeza-hidratante','Não Comedogênico','https://www.cerave.com.br/todos-os-produtos/locao-de-limpeza-hidratante'),
('cerave-locao-de-limpeza-hidratante','Sem Fragrância','https://www.cerave.com.br/todos-os-produtos/locao-de-limpeza-hidratante'),
('cerave-oleo-de-limpeza-hidratante','Não Comedogênico','https://www.cerave.com.br/todos-os-produtos/oleo-de-limpeza-hidratante'),
('cerave-oleo-de-limpeza-hidratante','Sem Fragrância','https://www.cerave.com.br/todos-os-produtos/oleo-de-limpeza-hidratante'),
('cerave-creme-reparador-para-maos','Sem Fragrância','https://www.cerave.com.br/todos-os-produtos/creme-reparador-para-maos'),
('cerave-sa-creme-renovador-pes','Não Comedogênico','https://www.cerave.com.br/todos-os-produtos/sa-creme-renovador-para-os-pes'),
('lrp-lipikar-locao','Sem Parabenos','https://www.laroche-posay.com.br/lipikar/locao')
) AS v(slug,claim_name,source_url)
JOIN products p ON p.slug=v.slug JOIN product_versions pv ON pv.fk_product_id=p.product_id
JOIN claims c ON c.name=v.claim_name
ON CONFLICT (fk_product_version_id,fk_claim_id) DO UPDATE SET was_verified=TRUE, verified_at=NOW(), source_reference=EXCLUDED.source_reference, updated_at=NOW();


CREATE TEMP TABLE tmp_seed_formula (slug TEXT, position INTEGER, inci_name TEXT) ON COMMIT PRESERVE ROWS;
INSERT INTO tmp_seed_formula VALUES
('cerave-gel-de-limpeza',1,'Aqua'),
('cerave-gel-de-limpeza',2,'Cocamidopropyl Hydroxysultaine'),
('cerave-gel-de-limpeza',3,'Glycerin'),
('cerave-gel-de-limpeza',4,'Sodium Lauroyl Sarcosinate'),
('cerave-gel-de-limpeza',5,'Propanediol'),
('cerave-gel-de-limpeza',6,'PEG-150 Pentaerythrityl Tetrastearate'),
('cerave-gel-de-limpeza',7,'Niacinamide'),
('cerave-gel-de-limpeza',8,'PEG-6 Caprylic/Capric Glycerides'),
('cerave-gel-de-limpeza',9,'Ceramide NP'),
('cerave-gel-de-limpeza',10,'Ceramide AP'),
('cerave-gel-de-limpeza',11,'Ceramide EOP'),
('cerave-gel-de-limpeza',12,'Carbomer'),
('cerave-gel-de-limpeza',13,'Sodium Methyl Cocoyl Taurate'),
('cerave-gel-de-limpeza',14,'Sodium Benzoate'),
('cerave-gel-de-limpeza',15,'Sodium Chloride'),
('cerave-gel-de-limpeza',16,'Sodium Lauroyl Lactylate'),
('cerave-gel-de-limpeza',17,'Sodium Hyaluronate'),
('cerave-gel-de-limpeza',18,'Cholesterol'),
('cerave-gel-de-limpeza',19,'Phenoxyethanol'),
('cerave-gel-de-limpeza',20,'Disodium EDTA'),
('cerave-gel-de-limpeza',21,'Citric Acid'),
('cerave-gel-de-limpeza',22,'Sodium EDTA'),
('cerave-gel-de-limpeza',23,'Phytosphingosine'),
('cerave-gel-de-limpeza',24,'Xanthan Gum'),
('cerave-gel-de-limpeza',25,'Ethylhexylglycerin'),
('cerave-sa-gel-de-limpeza-renovador',1,'Aqua'),
('cerave-sa-gel-de-limpeza-renovador',2,'Sodium Lauroyl Sarcosinate'),
('cerave-sa-gel-de-limpeza-renovador',3,'Cocamidopropyl Hydroxysultaine'),
('cerave-sa-gel-de-limpeza-renovador',4,'Glycerin'),
('cerave-sa-gel-de-limpeza-renovador',5,'Niacinamide'),
('cerave-sa-gel-de-limpeza-renovador',6,'Gluconolactone'),
('cerave-sa-gel-de-limpeza-renovador',7,'Sodium Methyl Cocoyl Taurate'),
('cerave-sa-gel-de-limpeza-renovador',8,'PEG-150 Pentaerythrityl Tetrastearate'),
('cerave-sa-gel-de-limpeza-renovador',9,'Ceramide EOP'),
('cerave-sa-gel-de-limpeza-renovador',10,'Ceramide NP'),
('cerave-sa-gel-de-limpeza-renovador',11,'Ceramide AP'),
('cerave-sa-gel-de-limpeza-renovador',12,'Carbomer'),
('cerave-sa-gel-de-limpeza-renovador',13,'Calcium Gluconate'),
('cerave-sa-gel-de-limpeza-renovador',14,'Salicylic Acid'),
('cerave-sa-gel-de-limpeza-renovador',15,'Sodium Benzoate'),
('cerave-sa-gel-de-limpeza-renovador',16,'Sodium Lauroyl Lactylate'),
('cerave-sa-gel-de-limpeza-renovador',17,'Cholesterol'),
('cerave-sa-gel-de-limpeza-renovador',18,'Phenoxyethanol'),
('cerave-sa-gel-de-limpeza-renovador',19,'Disodium EDTA'),
('cerave-sa-gel-de-limpeza-renovador',20,'Sodium EDTA'),
('cerave-sa-gel-de-limpeza-renovador',21,'Hydrolyzed Hyaluronic Acid'),
('cerave-sa-gel-de-limpeza-renovador',22,'Phytosphingosine'),
('cerave-sa-gel-de-limpeza-renovador',23,'Xanthan Gum'),
('cerave-sa-gel-de-limpeza-renovador',24,'Ethylhexylglycerin'),
('cerave-acne-control-gel-de-limpeza',1,'Aqua'),
('cerave-acne-control-gel-de-limpeza',2,'Sodium Lauroyl Sarcosinate'),
('cerave-acne-control-gel-de-limpeza',3,'Cocamidopropyl Hydroxysultaine'),
('cerave-acne-control-gel-de-limpeza',4,'Glycerin'),
('cerave-acne-control-gel-de-limpeza',5,'Niacinamide'),
('cerave-acne-control-gel-de-limpeza',6,'Salicylic Acid'),
('cerave-acne-control-gel-de-limpeza',7,'Gluconolactone'),
('cerave-acne-control-gel-de-limpeza',8,'Sodium Methyl Cocoyl Taurate'),
('cerave-acne-control-gel-de-limpeza',9,'PEG-150 Pentaerythrityl Tetrastearate'),
('cerave-acne-control-gel-de-limpeza',10,'Ceramide EOP'),
('cerave-acne-control-gel-de-limpeza',11,'Ceramide NP'),
('cerave-acne-control-gel-de-limpeza',12,'Ceramide AP'),
('cerave-acne-control-gel-de-limpeza',13,'Carbomer'),
('cerave-acne-control-gel-de-limpeza',14,'Calcium Gluconate'),
('cerave-acne-control-gel-de-limpeza',15,'Triethyl Citrate'),
('cerave-acne-control-gel-de-limpeza',16,'Sodium Benzoate'),
('cerave-acne-control-gel-de-limpeza',17,'Sodium Hydroxide'),
('cerave-acne-control-gel-de-limpeza',18,'Sodium Lauroyl Lactylate'),
('cerave-acne-control-gel-de-limpeza',19,'Cholesterol'),
('cerave-acne-control-gel-de-limpeza',20,'Sodium EDTA'),
('cerave-acne-control-gel-de-limpeza',21,'Caprylyl Glycol'),
('cerave-acne-control-gel-de-limpeza',22,'Hydrolyzed Hyaluronic Acid'),
('cerave-acne-control-gel-de-limpeza',23,'Trisodium Ethylenediamine Disuccinate'),
('cerave-acne-control-gel-de-limpeza',24,'Xanthan Gum'),
('cerave-acne-control-gel-de-limpeza',25,'Hectorite'),
('cerave-acne-control-gel-de-limpeza',26,'Phytosphingosine'),
('cerave-acne-control-gel-de-limpeza',27,'Benzoic Acid'),
('cerave-acne-control-cuidado-diario',1,'Aqua'),
('cerave-acne-control-cuidado-diario',2,'Glycerin'),
('cerave-acne-control-cuidado-diario',3,'Sodium Hydroxide'),
('cerave-acne-control-cuidado-diario',4,'Glycolic Acid'),
('cerave-acne-control-cuidado-diario',5,'Lactic Acid'),
('cerave-acne-control-cuidado-diario',6,'Salicylic Acid'),
('cerave-acne-control-cuidado-diario',7,'Niacinamide'),
('cerave-acne-control-cuidado-diario',8,'Guar Gum'),
('cerave-acne-control-cuidado-diario',9,'Xanthan Gum'),
('cerave-acne-control-cuidado-diario',10,'Chlorphenesin'),
('cerave-acne-control-cuidado-diario',11,'Sodium Hyaluronate'),
('cerave-acne-control-cuidado-diario',12,'Disodium EDTA'),
('cerave-acne-control-cuidado-diario',13,'Sodium Lauroyl Lactylate'),
('cerave-acne-control-cuidado-diario',14,'Cetearyl Alcohol'),
('cerave-acne-control-cuidado-diario',15,'Behentrimonium Methosulfate'),
('cerave-acne-control-cuidado-diario',16,'Ceramide NP'),
('cerave-acne-control-cuidado-diario',17,'Triethyl Citrate'),
('cerave-acne-control-cuidado-diario',18,'Caprylyl Glycol'),
('cerave-acne-control-cuidado-diario',19,'Ceramide AP'),
('cerave-acne-control-cuidado-diario',20,'Phytosphingosine'),
('cerave-acne-control-cuidado-diario',21,'Cholesterol'),
('cerave-acne-control-cuidado-diario',22,'Carbomer'),
('cerave-acne-control-cuidado-diario',23,'Benzoic Acid'),
('cerave-acne-control-cuidado-diario',24,'Ceramide EOP'),
('cerave-creme-hidratante',1,'Aqua'),
('cerave-creme-hidratante',2,'Glycerin'),
('cerave-creme-hidratante',3,'Cetearyl Alcohol'),
('cerave-creme-hidratante',4,'Caprylic/Capric Triglyceride'),
('cerave-creme-hidratante',5,'Cetyl Alcohol'),
('cerave-creme-hidratante',6,'Ceteareth-20'),
('cerave-creme-hidratante',7,'Petrolatum'),
('cerave-creme-hidratante',8,'Potassium Phosphate'),
('cerave-creme-hidratante',9,'Ceramide NP'),
('cerave-creme-hidratante',10,'Ceramide AP'),
('cerave-creme-hidratante',11,'Ceramide EOP'),
('cerave-creme-hidratante',12,'Carbomer'),
('cerave-creme-hidratante',13,'Dimethicone'),
('cerave-creme-hidratante',14,'Behentrimonium Methosulfate'),
('cerave-creme-hidratante',15,'Sodium Lauroyl Lactylate'),
('cerave-creme-hidratante',16,'Sodium Hyaluronate'),
('cerave-creme-hidratante',17,'Cholesterol'),
('cerave-creme-hidratante',18,'Phenoxyethanol'),
('cerave-creme-hidratante',19,'Disodium EDTA'),
('cerave-creme-hidratante',20,'Dipotassium Phosphate'),
('cerave-creme-hidratante',21,'Tocopherol'),
('cerave-creme-hidratante',22,'Phytosphingosine'),
('cerave-creme-hidratante',23,'Xanthan Gum'),
('cerave-creme-hidratante',24,'Ethylhexylglycerin'),
('cerave-locao-hidratante',1,'Aqua'),
('cerave-locao-hidratante',2,'Glycerin'),
('cerave-locao-hidratante',3,'Caprylic/Capric Triglyceride'),
('cerave-locao-hidratante',4,'Cetearyl Alcohol'),
('cerave-locao-hidratante',5,'Cetyl Alcohol'),
('cerave-locao-hidratante',6,'Dimethicone'),
('cerave-locao-hidratante',7,'Phenoxyethanol'),
('cerave-locao-hidratante',8,'Polysorbate 20'),
('cerave-locao-hidratante',9,'Ceteareth-20'),
('cerave-locao-hidratante',10,'Behentrimonium Methosulfate'),
('cerave-locao-hidratante',11,'Polyglyceryl-3 Diisostearate'),
('cerave-locao-hidratante',12,'Sodium Lauroyl Lactylate'),
('cerave-locao-hidratante',13,'Ethylhexylglycerin'),
('cerave-locao-hidratante',14,'Potassium Phosphate'),
('cerave-locao-hidratante',15,'Disodium EDTA'),
('cerave-locao-hidratante',16,'Dipotassium Phosphate'),
('cerave-locao-hidratante',17,'Ceramide NP'),
('cerave-locao-hidratante',18,'Ceramide AP'),
('cerave-locao-hidratante',19,'Phytosphingosine'),
('cerave-locao-hidratante',20,'Cholesterol'),
('cerave-locao-hidratante',21,'Xanthan Gum'),
('cerave-locao-hidratante',22,'Carbomer'),
('cerave-locao-hidratante',23,'Sodium Hyaluronate'),
('cerave-locao-hidratante',24,'Tocopherol'),
('cerave-locao-hidratante',25,'Ceramide EOP'),
('cerave-locao-facial-hidratante',1,'Aqua'),
('cerave-locao-facial-hidratante',2,'Glycerin'),
('cerave-locao-facial-hidratante',3,'Caprylic/Capric Triglyceride'),
('cerave-locao-facial-hidratante',4,'Niacinamide'),
('cerave-locao-facial-hidratante',5,'Cetearyl Alcohol'),
('cerave-locao-facial-hidratante',6,'Potassium Phosphate'),
('cerave-locao-facial-hidratante',7,'Ceramide NP'),
('cerave-locao-facial-hidratante',8,'Ceramide AP'),
('cerave-locao-facial-hidratante',9,'Ceramide EOP'),
('cerave-locao-facial-hidratante',10,'Carbomer'),
('cerave-locao-facial-hidratante',11,'Dimethicone'),
('cerave-locao-facial-hidratante',12,'Ceteareth-20'),
('cerave-locao-facial-hidratante',13,'Behentrimonium Methosulfate'),
('cerave-locao-facial-hidratante',14,'Sodium Lauroyl Lactylate'),
('cerave-locao-facial-hidratante',15,'Sodium Hyaluronate'),
('cerave-locao-facial-hidratante',16,'Cholesterol'),
('cerave-locao-facial-hidratante',17,'Phenoxyethanol'),
('cerave-locao-facial-hidratante',18,'Disodium EDTA'),
('cerave-locao-facial-hidratante',19,'Dipotassium Phosphate'),
('cerave-locao-facial-hidratante',20,'Caprylyl Glycol'),
('cerave-locao-facial-hidratante',21,'Phytosphingosine'),
('cerave-locao-facial-hidratante',22,'Xanthan Gum'),
('cerave-locao-facial-hidratante',23,'Polyglyceryl-3 Diisostearate'),
('cerave-locao-facial-hidratante',24,'Ethylhexylglycerin'),
('cerave-locao-facial-oil-control',1,'Aqua'),
('cerave-locao-facial-oil-control',2,'Niacinamide'),
('cerave-locao-facial-oil-control',3,'Glycerin'),
('cerave-locao-facial-oil-control',4,'Cetearyl Isononanoate'),
('cerave-locao-facial-oil-control',5,'C14-22 Alcohols'),
('cerave-locao-facial-oil-control',6,'Isopropyl Myristate'),
('cerave-locao-facial-oil-control',7,'Starch'),
('cerave-locao-facial-oil-control',8,'Ceramide NP'),
('cerave-locao-facial-oil-control',9,'Ceramide AP'),
('cerave-locao-facial-oil-control',10,'Ceramide EOP'),
('cerave-locao-facial-oil-control',11,'Carbomer'),
('cerave-locao-facial-oil-control',12,'Cetearyl Alcohol'),
('cerave-locao-facial-oil-control',13,'Behentrimonium Methosulfate'),
('cerave-locao-facial-oil-control',14,'Triethyl Citrate'),
('cerave-locao-facial-oil-control',15,'Silica'),
('cerave-locao-facial-oil-control',16,'Sodium Hydroxide'),
('cerave-locao-facial-oil-control',17,'Sodium Hyaluronate'),
('cerave-locao-facial-oil-control',18,'Sodium Lauroyl Lactylate'),
('cerave-locao-facial-oil-control',19,'Cholesterol'),
('cerave-locao-facial-oil-control',20,'Phenoxyethanol'),
('cerave-locao-facial-oil-control',21,'Citric Acid'),
('cerave-locao-facial-oil-control',22,'Caprylyl Glycol'),
('cerave-locao-facial-oil-control',23,'Trisodium Ethylenediamine Disuccinate'),
('cerave-locao-facial-oil-control',24,'Xanthan Gum'),
('cerave-locao-facial-oil-control',25,'Phytosphingosine'),
('cerave-locao-facial-oil-control',26,'Polyacrylate-6 Crosspolymer'),
('cerave-locao-facial-oil-control',27,'Benzoic Acid'),
('cerave-locao-facial-oil-control',28,'C12-20 Alkyl Glucoside'),
('cerave-locao-facial-hidratante-fps50',1,'Aqua'),
('cerave-locao-facial-hidratante-fps50',2,'Glycerin'),
('cerave-locao-facial-hidratante-fps50',3,'Isopropyl Palmitate'),
('cerave-locao-facial-hidratante-fps50',4,'Bis-Ethylhexyloxyphenol Methoxyphenyl Triazine'),
('cerave-locao-facial-hidratante-fps50',5,'Ethylhexyl Salicylate'),
('cerave-locao-facial-hidratante-fps50',6,'Niacinamide'),
('cerave-locao-facial-hidratante-fps50',7,'Butyl Methoxydibenzoylmethane'),
('cerave-locao-facial-hidratante-fps50',8,'Ethylhexyl Triazone'),
('cerave-locao-facial-hidratante-fps50',9,'Pentylene Glycol'),
('cerave-locao-facial-hidratante-fps50',10,'Propanediol'),
('cerave-locao-facial-hidratante-fps50',11,'Starch'),
('cerave-locao-facial-hidratante-fps50',12,'Potassium Cetyl Phosphate'),
('cerave-locao-facial-hidratante-fps50',13,'Diisopropyl Sebacate'),
('cerave-locao-facial-hidratante-fps50',14,'Oryza Sativa Wax'),
('cerave-locao-facial-hidratante-fps50',15,'Stearic Acid'),
('cerave-locao-facial-hidratante-fps50',16,'Ceramide NP'),
('cerave-locao-facial-hidratante-fps50',17,'Ceramide AP'),
('cerave-locao-facial-hidratante-fps50',18,'Ceramide EOP'),
('cerave-locao-facial-hidratante-fps50',19,'Carbomer'),
('cerave-locao-facial-hidratante-fps50',20,'Glyceryl Stearate'),
('cerave-locao-facial-hidratante-fps50',21,'Cetearyl Alcohol'),
('cerave-locao-facial-hidratante-fps50',22,'Trolamine'),
('cerave-locao-facial-hidratante-fps50',23,'Behentrimonium Methosulfate'),
('cerave-locao-facial-hidratante-fps50',24,'Triethyl Citrate'),
('cerave-locao-facial-hidratante-fps50',25,'Sodium Hyaluronate'),
('cerave-locao-facial-hidratante-fps50',26,'Sodium Polyacrylate'),
('cerave-locao-facial-hidratante-fps50',27,'Sodium Lauroyl Lactylate'),
('cerave-locao-facial-hidratante-fps50',28,'Myristic Acid'),
('cerave-locao-facial-hidratante-fps50',29,'Cholesterol'),
('cerave-locao-facial-hidratante-fps50',30,'Palmitic Acid'),
('cerave-locao-facial-hidratante-fps50',31,'Tocopherol'),
('cerave-locao-facial-hidratante-fps50',32,'Caprylyl Glycol'),
('cerave-locao-facial-hidratante-fps50',33,'Citric Acid'),
('cerave-locao-facial-hidratante-fps50',34,'Trisodium Ethylenediamine Disuccinate'),
('cerave-locao-facial-hidratante-fps50',35,'Xanthan Gum'),
('cerave-locao-facial-hidratante-fps50',36,'Phytosphingosine'),
('cerave-locao-facial-hidratante-fps50',37,'Acrylates/C10-30 Alkyl Acrylate Crosspolymer'),
('cerave-locao-facial-hidratante-fps50',38,'Butyrospermum Parkii Butter'),
('cerave-locao-facial-hidratante-fps50',39,'Benzoic Acid'),
('cerave-locao-facial-hidratante-fps50',40,'Macrogol 100 Stearate'),
('cerave-locao-de-limpeza-hidratante',1,'Aqua'),
('cerave-locao-de-limpeza-hidratante',2,'Glycerin'),
('cerave-locao-de-limpeza-hidratante',3,'Cetearyl Alcohol'),
('cerave-locao-de-limpeza-hidratante',4,'Phenoxyethanol'),
('cerave-locao-de-limpeza-hidratante',5,'Stearyl Alcohol'),
('cerave-locao-de-limpeza-hidratante',6,'Cetyl Alcohol'),
('cerave-locao-de-limpeza-hidratante',7,'Macrogol 2000 Stearate'),
('cerave-locao-de-limpeza-hidratante',8,'Behentrimonium Methosulfate'),
('cerave-locao-de-limpeza-hidratante',9,'Glyceryl Stearate'),
('cerave-locao-de-limpeza-hidratante',10,'Polysorbate 20'),
('cerave-locao-de-limpeza-hidratante',11,'Ethylhexylglycerin'),
('cerave-locao-de-limpeza-hidratante',12,'Potassium Phosphate'),
('cerave-locao-de-limpeza-hidratante',13,'Disodium EDTA'),
('cerave-locao-de-limpeza-hidratante',14,'Dipotassium Phosphate'),
('cerave-locao-de-limpeza-hidratante',15,'Sodium Lauroyl Lactylate'),
('cerave-locao-de-limpeza-hidratante',16,'Ceramide NP'),
('cerave-locao-de-limpeza-hidratante',17,'Ceramide AP'),
('cerave-locao-de-limpeza-hidratante',18,'Phytosphingosine'),
('cerave-locao-de-limpeza-hidratante',19,'Cholesterol'),
('cerave-locao-de-limpeza-hidratante',20,'Sodium Hyaluronate'),
('cerave-locao-de-limpeza-hidratante',21,'Xanthan Gum'),
('cerave-locao-de-limpeza-hidratante',22,'Carbomer'),
('cerave-locao-de-limpeza-hidratante',23,'Tocopherol'),
('cerave-locao-de-limpeza-hidratante',24,'Ceramide EOP'),
('cerave-oleo-de-limpeza-hidratante',1,'Aqua'),
('cerave-oleo-de-limpeza-hidratante',2,'Glycerin'),
('cerave-oleo-de-limpeza-hidratante',3,'PEG-200 Hydrogenated Glyceryl Palmate'),
('cerave-oleo-de-limpeza-hidratante',4,'Coco-Betaine'),
('cerave-oleo-de-limpeza-hidratante',5,'Disodium Cocoyl Glutamate'),
('cerave-oleo-de-limpeza-hidratante',6,'PEG-120 Methyl Glucose Dioleate'),
('cerave-oleo-de-limpeza-hidratante',7,'Polysorbate 20'),
('cerave-oleo-de-limpeza-hidratante',8,'PEG-7 Glyceryl Cocoate'),
('cerave-oleo-de-limpeza-hidratante',9,'PEG-150 Pentaerythrityl Tetrastearate'),
('cerave-oleo-de-limpeza-hidratante',10,'PPG-5-Ceteth-20'),
('cerave-oleo-de-limpeza-hidratante',11,'PEG-6 Caprylic/Capric Glycerides'),
('cerave-oleo-de-limpeza-hidratante',12,'Ceramide EOP'),
('cerave-oleo-de-limpeza-hidratante',13,'Squalane'),
('cerave-oleo-de-limpeza-hidratante',14,'Ceramide NP'),
('cerave-oleo-de-limpeza-hidratante',15,'Ceramide AP'),
('cerave-oleo-de-limpeza-hidratante',16,'Carbomer'),
('cerave-oleo-de-limpeza-hidratante',17,'Triethyl Citrate'),
('cerave-oleo-de-limpeza-hidratante',18,'Sodium Chloride'),
('cerave-oleo-de-limpeza-hidratante',19,'Sodium Hydroxide'),
('cerave-oleo-de-limpeza-hidratante',20,'Sodium Cocoyl Glutamate'),
('cerave-oleo-de-limpeza-hidratante',21,'Sodium Benzoate'),
('cerave-oleo-de-limpeza-hidratante',22,'Sodium Lauroyl Lactylate'),
('cerave-oleo-de-limpeza-hidratante',23,'Sodium Hyaluronate'),
('cerave-oleo-de-limpeza-hidratante',24,'Cholesterol'),
('cerave-oleo-de-limpeza-hidratante',25,'Citric Acid'),
('cerave-oleo-de-limpeza-hidratante',26,'Capryloyl Glycine'),
('cerave-oleo-de-limpeza-hidratante',27,'Hydroxyacetophenone'),
('cerave-oleo-de-limpeza-hidratante',28,'Caprylyl Glycol'),
('cerave-oleo-de-limpeza-hidratante',29,'Trisodium Ethylenediamine Disuccinate'),
('cerave-oleo-de-limpeza-hidratante',30,'Phytosphingosine'),
('cerave-oleo-de-limpeza-hidratante',31,'Xanthan Gum'),
('cerave-oleo-de-limpeza-hidratante',32,'Benzoic Acid'),
('cerave-creme-reparador-para-maos',1,'Aqua'),
('cerave-creme-reparador-para-maos',2,'Glycerin'),
('cerave-creme-reparador-para-maos',3,'Cetearyl Alcohol'),
('cerave-creme-reparador-para-maos',4,'Caprylic/Capric Triglyceride'),
('cerave-creme-reparador-para-maos',5,'Cetyl Alcohol'),
('cerave-creme-reparador-para-maos',6,'Ceteareth-20'),
('cerave-creme-reparador-para-maos',7,'Petrolatum'),
('cerave-creme-reparador-para-maos',8,'Behentrimonium Methosulfate'),
('cerave-creme-reparador-para-maos',9,'Carbomer'),
('cerave-creme-reparador-para-maos',10,'Ceramide AP'),
('cerave-creme-reparador-para-maos',11,'Ceramide EOP'),
('cerave-creme-reparador-para-maos',12,'Ceramide NP'),
('cerave-creme-reparador-para-maos',13,'Cholesterol'),
('cerave-creme-reparador-para-maos',14,'Dimethicone'),
('cerave-creme-reparador-para-maos',15,'Dipotassium Phosphate'),
('cerave-creme-reparador-para-maos',16,'Disodium EDTA'),
('cerave-creme-reparador-para-maos',17,'Ethylhexylglycerin'),
('cerave-creme-reparador-para-maos',18,'Phenoxyethanol'),
('cerave-creme-reparador-para-maos',19,'Phytosphingosine'),
('cerave-creme-reparador-para-maos',20,'Potassium Phosphate'),
('cerave-creme-reparador-para-maos',21,'Sodium Hyaluronate'),
('cerave-creme-reparador-para-maos',22,'Sodium Lauroyl Lactylate'),
('cerave-creme-reparador-para-maos',23,'Tocopherol'),
('cerave-creme-reparador-para-maos',24,'Xanthan Gum'),
('cerave-sa-creme-renovador-pes',1,'Aqua'),
('cerave-sa-creme-renovador-pes',2,'Glycerin'),
('cerave-sa-creme-renovador-pes',3,'Mineral Oil'),
('cerave-sa-creme-renovador-pes',4,'Glyceryl Stearate SE'),
('cerave-sa-creme-renovador-pes',5,'Cetearyl Alcohol'),
('cerave-sa-creme-renovador-pes',6,'Niacinamide'),
('cerave-sa-creme-renovador-pes',7,'Cetyl Alcohol'),
('cerave-sa-creme-renovador-pes',8,'Ammonium Lactate'),
('cerave-sa-creme-renovador-pes',9,'Trolamine'),
('cerave-sa-creme-renovador-pes',10,'Salicylic Acid'),
('cerave-sa-creme-renovador-pes',11,'Behentrimonium Methosulfate'),
('cerave-sa-creme-renovador-pes',12,'Macrogol 100 Stearate'),
('cerave-sa-creme-renovador-pes',13,'Phenoxyethanol'),
('cerave-sa-creme-renovador-pes',14,'Dimethicone'),
('cerave-sa-creme-renovador-pes',15,'Sodium Lauroyl Lactylate'),
('cerave-sa-creme-renovador-pes',16,'Disodium EDTA'),
('cerave-sa-creme-renovador-pes',17,'Ceramide NP'),
('cerave-sa-creme-renovador-pes',18,'Ceramide AP'),
('cerave-sa-creme-renovador-pes',19,'Phytosphingosine'),
('cerave-sa-creme-renovador-pes',20,'Cholesterol'),
('cerave-sa-creme-renovador-pes',21,'Xanthan Gum'),
('cerave-sa-creme-renovador-pes',22,'Carbomer'),
('cerave-sa-creme-renovador-pes',23,'Ethylhexylglycerin'),
('cerave-sa-creme-renovador-pes',24,'Sodium Hyaluronate'),
('cerave-sa-creme-renovador-pes',25,'Ceramide EOP'),
('lrp-effaclar-gel-concentrado',1,'Aqua'),
('lrp-effaclar-gel-concentrado',2,'Sodium Laureth Sulfate'),
('lrp-effaclar-gel-concentrado',3,'Decyl Glucoside'),
('lrp-effaclar-gel-concentrado',4,'Glycerin'),
('lrp-effaclar-gel-concentrado',5,'Sodium Chloride'),
('lrp-effaclar-gel-concentrado',6,'Coco-Betaine'),
('lrp-effaclar-gel-concentrado',7,'Salicylic Acid'),
('lrp-effaclar-gel-concentrado',8,'PEG-150 Pentaerythrityl Tetrastearate'),
('lrp-effaclar-gel-concentrado',9,'PEG-6 Caprylic/Capric Glycerides'),
('lrp-effaclar-gel-concentrado',10,'Zinc Gluconate'),
('lrp-effaclar-gel-concentrado',11,'Sodium Hydroxide'),
('lrp-effaclar-gel-concentrado',12,'Capryloyl Salicylic Acid'),
('lrp-effaclar-gel-concentrado',13,'Tetrasodium EDTA'),
('lrp-effaclar-gel-concentrado',14,'Citric Acid'),
('lrp-effaclar-gel-concentrado',15,'Menthol'),
('lrp-effaclar-gel-concentrado',16,'Polyquaternium-47'),
('lrp-effaclar-gel-alta-tolerancia',1,'Aqua'),
('lrp-effaclar-gel-alta-tolerancia',2,'Sodium Laureth Sulfate'),
('lrp-effaclar-gel-alta-tolerancia',3,'PEG-8'),
('lrp-effaclar-gel-alta-tolerancia',4,'Coco-Betaine'),
('lrp-effaclar-gel-alta-tolerancia',5,'Hexylene Glycol'),
('lrp-effaclar-gel-alta-tolerancia',6,'Sodium Chloride'),
('lrp-effaclar-gel-alta-tolerancia',7,'PEG-120 Methyl Glucose Dioleate'),
('lrp-effaclar-gel-alta-tolerancia',8,'Zinc PCA'),
('lrp-effaclar-gel-alta-tolerancia',9,'Sodium Hydroxide'),
('lrp-effaclar-gel-alta-tolerancia',10,'Propylene Glycol'),
('lrp-effaclar-gel-alta-tolerancia',11,'Citric Acid'),
('lrp-effaclar-gel-alta-tolerancia',12,'Sodium Benzoate'),
('lrp-effaclar-gel-alta-tolerancia',13,'Phenoxyethanol'),
('lrp-effaclar-gel-alta-tolerancia',14,'Caprylyl Glycol'),
('lrp-effaclar-gel-alta-tolerancia',15,'Parfum'),
('lrp-effaclar-sabonete-concentrado',1,'Sodium Stearate'),
('lrp-effaclar-sabonete-concentrado',2,'Sodium Palmate'),
('lrp-effaclar-sabonete-concentrado',3,'Sodium Palm Kernelate'),
('lrp-effaclar-sabonete-concentrado',4,'Aqua'),
('lrp-effaclar-sabonete-concentrado',5,'Salicylic Acid'),
('lrp-effaclar-sabonete-concentrado',6,'Glycerin'),
('lrp-effaclar-sabonete-concentrado',7,'Parfum'),
('lrp-effaclar-sabonete-concentrado',8,'Perlite'),
('lrp-effaclar-sabonete-concentrado',9,'Capryloyl Salicylic Acid'),
('lrp-effaclar-sabonete-concentrado',10,'Titanium Dioxide'),
('lrp-effaclar-sabonete-concentrado',11,'Etidronic Acid'),
('lrp-effaclar-sabonete-concentrado',12,'Phenoxyethanol'),
('lrp-effaclar-sabonete-concentrado',13,'Sodium Chloride'),
('lrp-effaclar-sabonete-concentrado',14,'Sodium Hydroxide'),
('lrp-effaclar-sabonete-concentrado',15,'Tetrasodium EDTA'),
('lrp-effaclar-sabonete-concentrado',16,'Zinc PCA'),
('lrp-effaclar-solucao-micelar-ultra',1,'Aqua'),
('lrp-effaclar-solucao-micelar-ultra',2,'PEG-7 Caprylic/Capric Glycerides'),
('lrp-effaclar-solucao-micelar-ultra',3,'Poloxamer 124'),
('lrp-effaclar-solucao-micelar-ultra',4,'Poloxamer 184'),
('lrp-effaclar-solucao-micelar-ultra',5,'PEG-6 Caprylic/Capric Glycerides'),
('lrp-effaclar-solucao-micelar-ultra',6,'Glycerin'),
('lrp-effaclar-solucao-micelar-ultra',7,'Polysorbate 80'),
('lrp-effaclar-solucao-micelar-ultra',8,'Zinc PCA'),
('lrp-effaclar-solucao-micelar-ultra',9,'Sodium Hydroxide'),
('lrp-effaclar-solucao-micelar-ultra',10,'Disodium EDTA'),
('lrp-effaclar-solucao-micelar-ultra',11,'BHT'),
('lrp-effaclar-solucao-micelar-ultra',12,'Myrtrimonium Bromide'),
('lrp-effaclar-solucao-micelar-ultra',13,'Parfum'),
('lrp-effaclar-serum-antiacne',1,'Aqua'),
('lrp-effaclar-serum-antiacne',2,'Alcohol'),
('lrp-effaclar-serum-antiacne',3,'Propanediol'),
('lrp-effaclar-serum-antiacne',4,'Glycolic Acid'),
('lrp-effaclar-serum-antiacne',5,'Niacinamide'),
('lrp-effaclar-serum-antiacne',6,'Dimethyl Isosorbide'),
('lrp-effaclar-serum-antiacne',7,'Pentylene Glycol'),
('lrp-effaclar-serum-antiacne',8,'Salicylic Acid'),
('lrp-effaclar-serum-antiacne',9,'Sodium Hydroxide'),
('lrp-effaclar-serum-antiacne',10,'PPG-26-Buteth-26'),
('lrp-effaclar-serum-antiacne',11,'Hydroxyethylpiperazine Ethane Sulfonic Acid'),
('lrp-effaclar-serum-antiacne',12,'Citric Acid'),
('lrp-effaclar-serum-antiacne',13,'PEG-30 Glyceryl Cocoate'),
('lrp-effaclar-serum-antiacne',14,'PEG-40 Hydrogenated Castor Oil'),
('lrp-effaclar-serum-antiacne',15,'Capryloyl Salicylic Acid'),
('lrp-effaclar-serum-antiacne',16,'Biosaccharide Gum-1'),
('lrp-effaclar-serum-antiacne',17,'Maltodextrin'),
('lrp-effaclar-serum-antiacne',18,'Phytic Acid'),
('lrp-effaclar-serum-antiacne',19,'Polyquaternium-10'),
('lrp-effaclar-serum-antiacne',20,'Parfum'),
('lrp-effaclar-mat',1,'Aqua'),
('lrp-effaclar-mat',2,'Glycerin'),
('lrp-effaclar-mat',3,'Dimethicone'),
('lrp-effaclar-mat',4,'Isocetyl Stearate'),
('lrp-effaclar-mat',5,'Alcohol Denat.'),
('lrp-effaclar-mat',6,'Silica'),
('lrp-effaclar-mat',7,'Dimethicone/Vinyl Dimethicone Crosspolymer'),
('lrp-effaclar-mat',8,'Acrylamide/Sodium Acryloyldimethyltaurate Copolymer'),
('lrp-effaclar-mat',9,'Methyl Methacrylate Crosspolymer'),
('lrp-effaclar-mat',10,'Butylene Glycol'),
('lrp-effaclar-mat',11,'PEG-100 Stearate'),
('lrp-effaclar-mat',12,'Cocamide MEA'),
('lrp-effaclar-mat',13,'Sarcosine'),
('lrp-effaclar-mat',14,'Glyceryl Stearate'),
('lrp-effaclar-mat',15,'Triethanolamine'),
('lrp-effaclar-mat',16,'Isohexadecane'),
('lrp-effaclar-mat',17,'Perlite'),
('lrp-effaclar-mat',18,'Capryloyl Salicylic Acid'),
('lrp-effaclar-mat',19,'Tetrasodium EDTA'),
('lrp-effaclar-mat',20,'Pentylene Glycol'),
('lrp-effaclar-mat',21,'Polysorbate 80'),
('lrp-effaclar-mat',22,'Acrylates/C10-30 Alkyl Acrylate Crosspolymer'),
('lrp-effaclar-mat',23,'Salicylic Acid'),
('lrp-effaclar-mat',24,'Parfum'),
('lrp-effaclar-duo-fps30',1,'Aqua'),
('lrp-effaclar-duo-fps30',2,'Octocrylene'),
('lrp-effaclar-duo-fps30',3,'Glycerin'),
('lrp-effaclar-duo-fps30',4,'Homosalate'),
('lrp-effaclar-duo-fps30',5,'Ethylhexyl Salicylate'),
('lrp-effaclar-duo-fps30',6,'Alcohol Denat.'),
('lrp-effaclar-duo-fps30',7,'Niacinamide'),
('lrp-effaclar-duo-fps30',8,'Butyl Methoxydibenzoylmethane'),
('lrp-effaclar-duo-fps30',9,'Dimethicone'),
('lrp-effaclar-duo-fps30',10,'Sorbitan Stearate'),
('lrp-effaclar-duo-fps30',11,'Silica'),
('lrp-effaclar-duo-fps30',12,'Isopropyl Lauroyl Sarcosinate'),
('lrp-effaclar-duo-fps30',13,'Styrene/Acrylates Copolymer'),
('lrp-effaclar-duo-fps30',14,'Propylene Glycol'),
('lrp-effaclar-duo-fps30',15,'Potassium Cetyl Phosphate'),
('lrp-effaclar-duo-fps30',16,'Diisopropyl Sebacate'),
('lrp-effaclar-duo-fps30',17,'PEG-20'),
('lrp-effaclar-duo-fps30',18,'PEG-8 Laurate'),
('lrp-effaclar-duo-fps30',19,'Zinc PCA'),
('lrp-effaclar-duo-fps30',20,'Dimethicone/Vinyl Dimethicone Crosspolymer'),
('lrp-effaclar-duo-fps30',21,'Sodium Dodecylbenzenesulfonate'),
('lrp-effaclar-duo-fps30',22,'2-Oleamido-1,3-Octadecanediol'),
('lrp-effaclar-duo-fps30',23,'Inulin Lauryl Carbamate'),
('lrp-effaclar-duo-fps30',24,'Mannose'),
('lrp-effaclar-duo-fps30',25,'Carnosine'),
('lrp-effaclar-duo-fps30',26,'Poloxamer 338'),
('lrp-effaclar-duo-fps30',27,'Ammonium Polyacryloyldimethyl Taurate'),
('lrp-effaclar-duo-fps30',28,'Disodium EDTA'),
('lrp-effaclar-duo-fps30',29,'Sucrose Cocoate'),
('lrp-effaclar-duo-fps30',30,'Capryloyl Salicylic Acid'),
('lrp-effaclar-duo-fps30',31,'Vitreoscilla Ferment'),
('lrp-effaclar-duo-fps30',32,'Xanthan Gum'),
('lrp-effaclar-duo-fps30',33,'Salicylic Acid'),
('lrp-effaclar-duo-fps30',34,'Parfum'),
('lrp-lipikar-locao',1,'Aqua'),
('lrp-lipikar-locao',2,'Glycerin'),
('lrp-lipikar-locao',3,'Niacinamide'),
('lrp-lipikar-locao',4,'Dimethicone'),
('lrp-lipikar-locao',5,'Paraffinum Liquidum'),
('lrp-lipikar-locao',6,'Caprylic/Capric Triglyceride'),
('lrp-lipikar-locao',7,'Ammonium Acryloyldimethyltaurate/Steareth-25 Methacrylate Crosspolymer'),
('lrp-lipikar-locao',8,'Propylene Glycol'),
('lrp-lipikar-locao',9,'Brassica Campestris Oleifera Oil'),
('lrp-lipikar-locao',10,'Dimethiconol'),
('lrp-lipikar-locao',11,'Isohexadecane'),
('lrp-lipikar-locao',12,'Disodium EDTA'),
('lrp-lipikar-locao',13,'Caprylyl Glycol'),
('lrp-lipikar-locao',14,'Xanthan Gum'),
('lrp-lipikar-locao',15,'Polysorbate 80'),
('lrp-lipikar-locao',16,'Acrylamide/Sodium Acryloyldimethyltaurate Copolymer'),
('lrp-lipikar-locao',17,'Butyrospermum Parkii Butter'),
('lrp-lipikar-locao',18,'Phenoxyethanol');


CREATE TEMP TABLE tmp_seed_match AS
WITH official AS (
    SELECT
        f.slug,
        f.position,
        f.inci_name,
        lower(trim(f.inci_name)) AS inci_lc,
        lower(
            regexp_replace(
                translate(
                    trim(f.inci_name),
                    'áàãâäéèêëíìîïóòôõöúùûüçÁÀÃÂÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ',
                    'aaaaaeeeeiiiiooooouuuucAAAAAEEEEIIIIOOOOOUUUUC'
                ),
                '[^a-z0-9]', '', 'g'
            )
        ) AS inci_norm
    FROM tmp_seed_formula f
),
explicit_equiv(inci_name, candidate_name) AS (
    VALUES
        ('Ceramide NP','Ceramida NP'),
        ('Ceramide AP','Ceramida AP'),
        ('Ceramide EOP','Ceramida EOP'),
        ('Phytosphingosine','Fitoesfingosina'),
        ('Sodium EDTA','EDTA dissódico'),
        ('Hydrolyzed Hyaluronic Acid','Ácido hialurônico hidrolisado'),
        ('Parfum','Perfume'),
        ('Propanediol','Propanodiol'),
        ('Pentylene Glycol','Pentilenoglicol'),
        ('Glycolic Acid','Ácido glicólico'),
        ('Lactic Acid','Ácido láctico'),
        ('Salicylic Acid','Ácido salicílico'),
        ('Citric Acid','Ácido cítrico'),
        ('Benzoic Acid','Ácido benzoico'),
        ('Sodium Hydroxide','Hidróxido de sódio'),
        ('Calcium Gluconate','Gluconato de cálcio'),
        ('Triethyl Citrate','Citrato de trietila'),
        ('Caprylyl Glycol','Caprililglicol'),
        ('Phenoxyethanol','Fenoxietanol'),
        ('Sodium Hyaluronate','Hialuronato de sódio'),
        ('Sodium Benzoate','Benzoato de sódio'),
        ('Sodium Chloride','Cloreto de sódio'),
        ('Sodium Lauroyl Lactylate','Lauroil lactilato de sódio'),
        ('Xanthan Gum','Goma xantana'),
        ('Carbomer','Carbômero'),
        ('Glycerin','Glicerina'),
        ('Aqua','Água'),
        ('Niacinamide','Niacinamida'),
        ('Mineral Oil','Óleo mineral'),
        ('Starch','Amido'),
        ('Oryza Sativa Wax','Cera de Oryza sativa'),
        ('Butyrospermum Parkii Butter','Manteiga de karité'),
        ('Macrogol 100 Stearate','Estearato de macrogol 100'),
        ('Macrogol 2000 Stearate','Estearato de macrogol 2000'),
        ('Polyquaternium-47','Poliquatérnio-47'),
        ('Perlite','Perlita'),
        ('Mannose','Manose'),
        ('Carnosine','Carnosina'),
        ('Vitreoscilla Ferment','Fermento de Vitreoscilla'),
        ('Guar Gum','Goma guar'),
        ('Pentylene Glycol','Glicol pentilênico')
),
candidates AS (
    SELECT o.slug,o.position,o.inci_name,i.ingredient_id,'EXACT_INCI'::text AS match_type,1 AS priority
    FROM official o JOIN ingredients i ON lower(trim(i.inci_name))=o.inci_lc
    UNION ALL
    SELECT o.slug,o.position,o.inci_name,ia.fk_ingredient_id,'EXACT_ALIAS',2
    FROM official o JOIN ingredient_aliases ia ON lower(trim(ia.alias_name))=o.inci_lc
    UNION ALL
    SELECT o.slug,o.position,o.inci_name,i.ingredient_id,'EXACT_COMMON_NAME',3
    FROM official o JOIN ingredients i ON lower(trim(i.common_name))=o.inci_lc
    UNION ALL
    SELECT o.slug,o.position,o.inci_name,i.ingredient_id,'NORMALIZED_INCI',4
    FROM official o JOIN ingredients i ON lower(regexp_replace(translate(trim(i.inci_name),'áàãâäéèêëíìîïóòôõöúùûüçÁÀÃÂÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ','aaaaaeeeeiiiiooooouuuucAAAAAEEEEIIIIOOOOOUUUUC'),'[^a-z0-9]','','g'))=o.inci_norm
    UNION ALL
    SELECT o.slug,o.position,o.inci_name,ia.fk_ingredient_id,'NORMALIZED_ALIAS',5
    FROM official o JOIN ingredient_aliases ia ON lower(regexp_replace(translate(trim(ia.alias_name),'áàãâäéèêëíìîïóòôõöúùûüçÁÀÃÂÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ','aaaaaeeeeiiiiooooouuuucAAAAAEEEEIIIIOOOOOUUUUC'),'[^a-z0-9]','','g'))=o.inci_norm
    UNION ALL
    SELECT o.slug,o.position,o.inci_name,i.ingredient_id,'NORMALIZED_COMMON_NAME',6
    FROM official o JOIN ingredients i ON lower(regexp_replace(translate(trim(i.common_name),'áàãâäéèêëíìîïóòôõöúúûüçÁÀÃÂÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ','aaaaaeeeeiiiiooooouuuucAAAAAEEEEIIIIOOOOOUUUUC'),'[^a-z0-9]','','g'))=o.inci_norm
    UNION ALL
    SELECT o.slug,o.position,o.inci_name,i.ingredient_id,'EXPLICIT_EQUIVALENCE',7
    FROM official o
    JOIN explicit_equiv e ON lower(trim(e.inci_name))=o.inci_lc
    JOIN ingredients i ON lower(trim(i.common_name))=lower(trim(e.candidate_name))
),
dedup AS (
    SELECT
        slug,
        position,
        inci_name,
        ingredient_id,
        MIN(priority) AS priority
    FROM candidates
    GROUP BY slug,position,inci_name,ingredient_id
),
best AS (
    SELECT d.*,
           COUNT(*) OVER (PARTITION BY d.slug,d.position,d.inci_name) AS distinct_candidates,
           ROW_NUMBER() OVER (PARTITION BY d.slug,d.position,d.inci_name ORDER BY d.priority,d.ingredient_id) AS rn
    FROM dedup d
),
resolved AS (
    SELECT
        b.slug,
        b.position,
        b.inci_name,
        CASE WHEN b.distinct_candidates=1 THEN b.ingredient_id END AS ingredient_id,
        CASE
          WHEN b.distinct_candidates=1 AND b.priority=1 THEN 'EXACT_INCI'
          WHEN b.distinct_candidates=1 AND b.priority=2 THEN 'EXACT_ALIAS'
          WHEN b.distinct_candidates=1 AND b.priority=3 THEN 'EXACT_COMMON_NAME'
          WHEN b.distinct_candidates=1 AND b.priority=4 THEN 'NORMALIZED_INCI'
          WHEN b.distinct_candidates=1 AND b.priority=5 THEN 'NORMALIZED_ALIAS'
          WHEN b.distinct_candidates=1 AND b.priority=6 THEN 'NORMALIZED_COMMON_NAME'
          WHEN b.distinct_candidates=1 AND b.priority=7 THEN 'EXPLICIT_EQUIVALENCE'
          WHEN b.distinct_candidates>1 THEN 'AMBIGUOUS'
          ELSE 'MISSING'
        END AS match_type
    FROM best b
    WHERE b.rn=1
)
SELECT * FROM resolved;

INSERT INTO product_ingredients
    (fk_product_version_id, fk_ingredient_id, position)
SELECT
    pv.product_version_id,
    m.ingredient_id,
    MIN(m.position)
FROM tmp_seed_match m
JOIN products p ON p.slug=m.slug
JOIN product_versions pv ON pv.fk_product_id=p.product_id
WHERE m.ingredient_id IS NOT NULL
GROUP BY pv.product_version_id,m.ingredient_id
ON CONFLICT (fk_product_version_id,fk_ingredient_id)
DO NOTHING;

SELECT
    match_type,
    COUNT(*) AS total
FROM tmp_seed_match
GROUP BY match_type
ORDER BY match_type;

SELECT
    slug,
    position,
    inci_name,
    match_type
FROM tmp_seed_match
WHERE ingredient_id IS NULL
ORDER BY slug,position;



INSERT INTO product_scores
(
    fk_product_version_id,
    fk_scoring_model_id,
    overall_score,
    health_score,
    environmental_score,
    ethical_score,
    performance_score,
    transparency_score,
    confidence_score
)
SELECT
    pv.product_version_id,
    sm.scoring_model_id,
    0, 0, 0, 0, 0, 0, 0
FROM product_versions pv
CROSS JOIN LATERAL (
    SELECT scoring_model_id
    FROM scoring_models
    WHERE is_active = TRUE
    ORDER BY
        CASE WHEN lower(name) = lower('Recomendação Geral') THEN 0 ELSE 1 END,
        scoring_model_id
    LIMIT 1
) sm
ON CONFLICT (fk_product_version_id, fk_scoring_model_id)
DO NOTHING;


INSERT INTO favorites (fk_user_id, fk_product_id)
SELECT
    u.user_id,
    p.product_id
FROM users u
CROSS JOIN LATERAL (
    SELECT p2.product_id
    FROM products p2
    ORDER BY p2.product_id
    OFFSET ((u.user_id - 1) % 10)
    LIMIT 5
) p
WHERE u.firebase_uid LIKE 'venus-seed-user-%'
ON CONFLICT (fk_user_id, fk_product_id)
DO NOTHING;


INSERT INTO user_lists (fk_user_id, name, list_type)
SELECT
    u.user_id,
    'Produtos para testar',
    'custom'
FROM users u
WHERE u.firebase_uid LIKE 'venus-seed-user-%'
ON CONFLICT (fk_user_id, name)
DO NOTHING;

INSERT INTO user_list_items
(
    fk_user_list_id,
    fk_product_id,
    position_order
)
SELECT
    ul.user_list_id,
    p.product_id,
    ROW_NUMBER() OVER (
        PARTITION BY ul.user_list_id
        ORDER BY p.product_id
    )::INTEGER
FROM user_lists ul
JOIN users u
  ON u.user_id = ul.fk_user_id
CROSS JOIN LATERAL (
    SELECT p2.product_id
    FROM products p2
    ORDER BY p2.product_id
    LIMIT 10
) p
WHERE u.firebase_uid LIKE 'venus-seed-user-%'
  AND ul.name = 'Produtos para testar'
ON CONFLICT (fk_user_list_id, fk_product_id)
DO NOTHING;


INSERT INTO compatibility_rules
(
    fk_ingredient_effect_id,
    fk_scoring_model_id,
    effect_type,
    score_delta,
    weight,
    priority,
    has_concentration_factor,
    is_enabled,
    evidence_level,
    reason,
    source_type,
    source_reference
)
SELECT
    ie.ingredient_effect_id,
    sm.scoring_model_id,
    CASE
        WHEN ie.effect_category IN ('risk','warning','contraindication')
            THEN 'penalty'::effect_type_enum
        ELSE 'bonus'::effect_type_enum
    END,
    CASE
        WHEN ie.effect_category IN ('risk','warning','contraindication')
            THEN -5
        ELSE 5
    END,
    1.00,
    10,
    FALSE,
    TRUE,
    ie.evidence_level,
    'Regra de teste criada a partir de um ingredient_effect já existente.',
    'system',
    'VENUS_TEST_RECOVERY'
FROM ingredient_effects ie
CROSS JOIN LATERAL (
    SELECT scoring_model_id
    FROM scoring_models
    WHERE is_active = TRUE
    ORDER BY
        CASE WHEN lower(name) = lower('Recomendação Geral') THEN 0 ELSE 1 END,
        scoring_model_id
    LIMIT 1
) sm
ON CONFLICT (fk_ingredient_effect_id, fk_scoring_model_id)
DO NOTHING;


INSERT INTO analysis_results
(
    fk_user_id,
    fk_product_version_id,
    fk_scoring_model_id,
    overall_score,
    health_score,
    environmental_score,
    ethical_score,
    performance_score,
    transparency_score,
    confidence_score,
    processing_time_ms,
    status,
    summary
)
SELECT
    u.user_id,
    pv.product_version_id,
    sm.scoring_model_id,
    0, 0, 0, 0, 0, 0, 0, 0,
    'completed'::venus.analysis_status_enum,
    'SEED TÉCNICO: análise criada para validar o relacionamento usuário x produto.'
FROM product_versions pv
JOIN users u
  ON u.firebase_uid = 'venus-seed-user-' ||
     LPAD((((pv.product_version_id - 1) % 40) + 1)::TEXT, 3, '0')
CROSS JOIN LATERAL (
    SELECT scoring_model_id
    FROM scoring_models
    WHERE is_active = TRUE
    ORDER BY
        CASE WHEN lower(name) = lower('Recomendação Geral') THEN 0 ELSE 1 END,
        scoring_model_id
    LIMIT 1
) sm
ON CONFLICT DO NOTHING;


INSERT INTO rule_evaluations
(
    fk_analysis_result_id,
    fk_compatibility_rule_id,
    fk_ingredient_id,
    fk_profile_tag_id,
    was_matched,
    score_delta,
    final_delta,
    explanation
)
SELECT
    ar.analysis_result_id,
    cr.compatibility_rule_id,
    pi.fk_ingredient_id,
    ie.fk_profile_tag_id,
    TRUE,
    cr.score_delta,
    cr.score_delta,
    'SEED TÉCNICO: avaliação para teste do pipeline de compatibilidade.'
FROM analysis_results ar
JOIN product_ingredients pi
  ON pi.fk_product_version_id = ar.fk_product_version_id
JOIN ingredient_effects ie
  ON ie.fk_ingredient_id = pi.fk_ingredient_id
JOIN compatibility_rules cr
  ON cr.fk_ingredient_effect_id = ie.ingredient_effect_id
WHERE cr.is_enabled = TRUE
ON CONFLICT (
    fk_analysis_result_id,
    fk_compatibility_rule_id,
    fk_ingredient_id,
    fk_profile_tag_id
)
DO NOTHING;


INSERT INTO personalized_scores
(
    fk_user_id,
    fk_product_version_id,
    fk_analysis_result_id,
    fk_scoring_model_id,
    final_score,
    compatibility_percentage,
    risk_level,
    recommendation_level,
    summary
)
SELECT
    ar.fk_user_id,
    ar.fk_product_version_id,
    ar.analysis_result_id,
    ar.fk_scoring_model_id,
    0,
    0.00,
    'low'::venus.risk_level_enum,
    'acceptable'::venus.recommendation_level_enum,
    'SEED TÉCNICO: valor inicial para validar o pipeline; não é avaliação real.'
FROM analysis_results ar
ON CONFLICT (
    fk_user_id,
    fk_product_version_id,
    fk_scoring_model_id
)
DO NOTHING;


INSERT INTO recommendations
(
    fk_user_id,
    fk_profile_tag_id,
    fk_product_version_id,
    fk_analysis_result_id,
    recommendation_type,
    confidence_score,
    ranking_position,
    reason
)
SELECT
    ar.fk_user_id,
    pt.profile_tag_id,
    ar.fk_product_version_id,
    ar.analysis_result_id,
    'acceptable'::venus.recommendation_type_enum,
    0,
    ROW_NUMBER() OVER (
        PARTITION BY ar.fk_user_id
        ORDER BY ar.fk_product_version_id
    )::INTEGER,
    'SEED TÉCNICO: recomendação criada para validar a integração.'
FROM analysis_results ar
JOIN user_profile_tags upt
  ON upt.fk_user_id = ar.fk_user_id
JOIN profile_tags pt
  ON pt.profile_tag_id = upt.fk_profile_tag_id
WHERE NOT EXISTS (
    SELECT 1
    FROM recommendations r
    WHERE r.fk_user_id = ar.fk_user_id
      AND r.fk_profile_tag_id = pt.profile_tag_id
      AND r.fk_product_version_id = ar.fk_product_version_id
      AND r.fk_analysis_result_id = ar.analysis_result_id
)
ON CONFLICT DO NOTHING;


INSERT INTO reviews
(
    fk_user_id,
    fk_product_version_id,
    rating,
    title,
    comment,
    verified_use
)
SELECT
    u.user_id,
    pv.product_version_id,
    0.0,
    'SEED TÉCNICO',
    'Registro técnico de integração; não representa opinião real de consumidor.',
    FALSE
FROM product_versions pv
JOIN users u
  ON u.firebase_uid = 'venus-seed-user-' ||
     LPAD((((pv.product_version_id - 1) % 40) + 1)::TEXT, 3, '0')
WHERE NOT EXISTS (
    SELECT 1
    FROM reviews r
    WHERE r.fk_user_id = u.user_id
      AND r.fk_product_version_id = pv.product_version_id
);


INSERT INTO review_votes
(
    fk_review_id,
    fk_user_id,
    vote_type
)
SELECT
    r.review_id,
    voter.user_id,
    'useful'::venus.vote_type_enum
FROM reviews r
CROSS JOIN LATERAL (
    SELECT user_id
    FROM users
    WHERE user_id <> r.fk_user_id
    ORDER BY user_id
    LIMIT 1
) voter
ON CONFLICT (fk_review_id, fk_user_id)
DO NOTHING;


INSERT INTO reports
(
    fk_user_id,
    fk_admin_user_id,
    target_type,
    target_id,
    reason,
    status
)
SELECT
    r.fk_user_id,
    a.admin_user_id,
    'review'::venus.report_target_type_enum,
    r.review_id,
    'SEED TÉCNICO: relatório para testar o fluxo administrativo.',
    'open'::venus.report_status_enum
FROM reviews r
CROSS JOIN LATERAL (
    SELECT admin_user_id
    FROM admin_users
    ORDER BY admin_user_id
    LIMIT 1
) a
WHERE r.title = 'SEED TÉCNICO'
  AND r.review_id % 4 = 0
  AND NOT EXISTS (
      SELECT 1
      FROM reports rp
      WHERE rp.target_type = 'review'::venus.report_target_type_enum
        AND rp.target_id = r.review_id
        AND rp.reason LIKE 'SEED TÉCNICO:%'
  );




DO $$
DECLARE
    n_products INTEGER;
    n_users INTEGER;
    n_profiles INTEGER;
    n_preferences INTEGER;
BEGIN
    SELECT COUNT(*) INTO n_products
    FROM products
    WHERE slug LIKE 'cerave-%' OR slug LIKE 'lrp-%' OR slug LIKE 'eucerin-%';

    SELECT COUNT(*) INTO n_users
    FROM users
    WHERE firebase_uid LIKE 'venus-seed-user-%';

    SELECT COUNT(*) INTO n_profiles
    FROM user_profiles up
    JOIN users u ON u.user_id = up.fk_user_id
    WHERE u.firebase_uid LIKE 'venus-seed-user-%';

    SELECT COUNT(*) INTO n_preferences
    FROM user_preferences up
    JOIN users u ON u.user_id = up.fk_user_id
    WHERE u.firebase_uid LIKE 'venus-seed-user-%';

    IF n_products < 50 THEN
        RAISE EXCEPTION 'Carga não concluída: catálogo de teste possui apenas % produtos.', n_products;
    END IF;

    IF n_users <> 40 OR n_profiles <> 40 OR n_preferences <> 40 THEN
        RAISE EXCEPTION 'Carga de usuários incompleta: users=%, profiles=%, preferences=%.',
            n_users, n_profiles, n_preferences;
    END IF;
END $$;
