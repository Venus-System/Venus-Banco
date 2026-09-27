/* Pesos iniciais dos modelos de score. Não sobrescreve curadoria existente. */
SET search_path TO venus, public;

WITH overrides (model_name, category_name, weight) AS (
    VALUES
    ('Pele Sensível','Pele Sensível',40), ('Pele Sensível','Potencial de Irritação',40), ('Pele Sensível','Risco Alérgico',40), ('Pele Sensível','Risco de Fragrância',35), ('Pele Sensível','Segurança de Curto Prazo',25), ('Pele Sensível','Sistema Conservante',25),
    ('Pele Seca','Efetividade',40), ('Pele Seca','Qualidade dos Ingredientes',25), ('Pele Seca','Estabilidade da Fórmula',20), ('Pele Seca','Experiência Sensorial',15), ('Pele Seca','Risco Comedogênico',10),
    ('Pele Oleosa','Compatibilidade',40), ('Pele Oleosa','Risco Comedogênico',40), ('Pele Oleosa','Equilíbrio da Fórmula',25), ('Pele Oleosa','Experiência Sensorial',15),
    ('Acne','Compatibilidade com Acne',40), ('Acne','Risco Comedogênico',40), ('Acne','Efetividade',40), ('Acne','Potencial de Irritação',30),
    ('Acne Intensiva','Compatibilidade com Acne',45), ('Acne Intensiva','Risco Comedogênico',40), ('Acne Intensiva','Efetividade',40), ('Acne Intensiva','Potencial de Irritação',35), ('Acne Intensiva','Evidência Científica',35),
    ('Rosácea','Pele Sensível',40), ('Rosácea','Potencial de Irritação',40), ('Rosácea','Risco de Fragrância',40), ('Rosácea','Risco Alérgico',35), ('Rosácea','Segurança de Curto Prazo',25),
    ('Pele Madura','Efetividade',40), ('Pele Madura','Evidência Científica',35), ('Pele Madura','Qualidade dos Ingredientes',25), ('Pele Madura','Sinergia de Ingredientes',20),
    ('Olhos Sensíveis','Potencial de Irritação',45), ('Olhos Sensíveis','Risco Alérgico',40), ('Olhos Sensíveis','Risco de Fragrância',35), ('Olhos Sensíveis','Segurança de Curto Prazo',30), ('Olhos Sensíveis','Sistema Conservante',25), ('Olhos Sensíveis','Robustez Microbiológica',25),
    ('Hiperpigmentação','Efetividade',40), ('Hiperpigmentação','Evidência Científica',35), ('Hiperpigmentação','Potencial de Irritação',30), ('Hiperpigmentação','Segurança de Longo Prazo',25), ('Hiperpigmentação','Sinergia de Ingredientes',20),
    ('Melasma','Efetividade',40), ('Melasma','Evidência Científica',35), ('Melasma','Potencial de Irritação',30), ('Melasma','Segurança de Longo Prazo',25), ('Melasma','Sinergia de Ingredientes',20),
    ('Psoríase','Efetividade',40), ('Psoríase','Potencial de Irritação',40), ('Psoríase','Risco Alérgico',35), ('Psoríase','Evidência Científica',35), ('Psoríase','Pele Sensível',30), ('Psoríase','Risco de Fragrância',30),
    ('Seguro na Gravidez','Segurança na Gravidez',45), ('Seguro na Gravidez','Segurança',45), ('Seguro na Gravidez','Evidência Científica',35), ('Seguro na Gravidez','Segurança de Longo Prazo',30),
    ('Infantil','Segurança',50), ('Infantil','Risco Alérgico',40), ('Infantil','Potencial de Irritação',35), ('Infantil','Segurança de Longo Prazo',30), ('Infantil','Pele Sensível',30), ('Infantil','Risco de Fragrância',30), ('Infantil','Segurança de Curto Prazo',25), ('Infantil','Sistema Conservante',25),
    ('Cuidado Infantil','Segurança',50), ('Cuidado Infantil','Risco Alérgico',40), ('Cuidado Infantil','Potencial de Irritação',35), ('Cuidado Infantil','Segurança de Longo Prazo',30), ('Cuidado Infantil','Pele Sensível',30), ('Cuidado Infantil','Risco de Fragrância',30), ('Cuidado Infantil','Segurança de Curto Prazo',25), ('Cuidado Infantil','Sistema Conservante',25),
    ('Cuidados Capilares','Compatibilidade Capilar',40), ('Cuidados Capilares','Efetividade',35), ('Cuidados Capilares','Compatibilidade do Couro Cabeludo',25),
    ('Cabelos Cacheados','Compatibilidade Capilar',40), ('Cabelos Cacheados','Efetividade',40), ('Cabelos Cacheados','Sinergia de Ingredientes',20), ('Cabelos Cacheados','Experiência Sensorial',15),
    ('Cabelos Lisos','Compatibilidade Capilar',40), ('Cabelos Lisos','Equilíbrio da Fórmula',25), ('Cabelos Lisos','Experiência Sensorial',15),
    ('Cabelos Coloridos','Compatibilidade Capilar',40), ('Cabelos Coloridos','Qualidade dos Ingredientes',25), ('Cabelos Coloridos','Segurança de Longo Prazo',25), ('Cabelos Coloridos','Estabilidade da Fórmula',20), ('Cabelos Coloridos','Qualidade do Pigmento',15),
    ('Cuidados com o Couro Cabeludo','Compatibilidade do Couro Cabeludo',40), ('Cuidados com o Couro Cabeludo','Potencial de Irritação',30), ('Cuidados com o Couro Cabeludo','Compatibilidade Capilar',25),
    ('Couro Cabeludo Seco','Compatibilidade do Couro Cabeludo',40), ('Couro Cabeludo Seco','Efetividade',40), ('Couro Cabeludo Seco','Potencial de Irritação',30),
    ('Couro Cabeludo Oleoso','Compatibilidade do Couro Cabeludo',40), ('Couro Cabeludo Oleoso','Efetividade',40), ('Couro Cabeludo Oleoso','Equilíbrio da Fórmula',25),
    ('Cuidados com Barba','Compatibilidade Capilar',30), ('Cuidados com Barba','Potencial de Irritação',30), ('Cuidados com Barba','Pele Sensível',25), ('Cuidados com Barba','Experiência Sensorial',15),
    ('Maquiagem','Risco Comedogênico',25), ('Maquiagem','Qualidade do Pigmento',20), ('Maquiagem','Estabilidade de Prateleira',20), ('Maquiagem','Robustez Microbiológica',20), ('Maquiagem','Experiência Sensorial',15),
    ('Maquiagem Alta Cobertura','Risco Comedogênico',30), ('Maquiagem Alta Cobertura','Compatibilidade com Acne',25), ('Maquiagem Alta Cobertura','Qualidade do Pigmento',25), ('Maquiagem Alta Cobertura','Estabilidade de Prateleira',20), ('Maquiagem Alta Cobertura','Experiência Sensorial',15),
    ('Maquiagem Leve','Potencial de Irritação',30), ('Maquiagem Leve','Equilíbrio da Fórmula',25), ('Maquiagem Leve','Qualidade do Pigmento',15), ('Maquiagem Leve','Experiência Sensorial',15),
    ('Ecológico','Impacto Ambiental',40), ('Ecológico','Sustentabilidade',40), ('Ecológico','Segurança',35), ('Ecológico','Sustentabilidade da Embalagem',25), ('Ecológico','Cruelty Free',20), ('Ecológico','Vegano',15),
    ('Transparência de Ingredientes','Transparência',45), ('Transparência de Ingredientes','Integridade do Claim',35), ('Transparência de Ingredientes','Qualidade dos Ingredientes',25),
    ('Confiança Científica','Evidência Científica',45), ('Confiança Científica','Efetividade',40), ('Confiança Científica','Integridade do Claim',30), ('Confiança Científica','Transparência',25),
    ('Cosméticos Premium','Qualidade dos Ingredientes',30), ('Cosméticos Premium','Estabilidade da Fórmula',20), ('Cosméticos Premium','Experiência Sensorial',20), ('Cosméticos Premium','Sinergia de Ingredientes',20), ('Cosméticos Premium','Preço vs Performance',15)
), params AS (
    SELECT
        ARRAY['Cuidados Capilares','Cabelos Cacheados','Cabelos Lisos','Cabelos Coloridos','Cuidados com o Couro Cabeludo','Couro Cabeludo Seco','Couro Cabeludo Oleoso']::text[] AS hair_models,
        ARRAY['Pele Sensível','Pele Seca','Pele Oleosa','Acne','Acne Intensiva','Rosácea','Pele Madura','Olhos Sensíveis','Hiperpigmentação','Melasma','Psoríase','Maquiagem','Maquiagem Alta Cobertura','Maquiagem Leve']::text[] AS skin_models,
        ARRAY['Maquiagem','Maquiagem Alta Cobertura','Maquiagem Leve','Cabelos Coloridos']::text[] AS color_models,
        ARRAY['Risco Comedogênico','Compatibilidade com Acne']::text[] AS skin_only_categories,
        ARRAY['Compatibilidade Capilar','Compatibilidade do Couro Cabeludo']::text[] AS hair_only_categories
)
INSERT INTO scoring_model_categories (fk_scoring_model_id, fk_score_category_id, weight)
SELECT sm.scoring_model_id, sc.score_category_id,
       COALESCE(o.weight, CASE
           WHEN sm.name = ANY (p.hair_models) AND sc.name = ANY (p.skin_only_categories) THEN 5.00
           WHEN sm.name = ANY (p.skin_models) AND sc.name = ANY (p.hair_only_categories) THEN 5.00
           WHEN sc.name = 'Qualidade do Pigmento' AND sm.name <> ALL (p.color_models) THEN 5.00
           ELSE sc.default_weight
       END)::NUMERIC(6,2)
  FROM scoring_models sm
 CROSS JOIN score_categories sc
 CROSS JOIN params p
  LEFT JOIN overrides o ON o.model_name = sm.name AND o.category_name = sc.name
ON CONFLICT (fk_scoring_model_id, fk_score_category_id) DO NOTHING;
