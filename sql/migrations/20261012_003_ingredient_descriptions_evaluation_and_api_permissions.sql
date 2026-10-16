-- Venus — descrição de ingredientes, avaliação real e permissão da classificação — 2026-10-12
--
-- Corrige três pontos operacionais:
-- 1) toda descrição vazia recebe uma frase honesta em português, derivada do
--    efeito/função canônica, e novos ingredientes são preenchidos pelo banco;
-- 2) confidence só pode representar ingrediente avaliado quando existem as
--    quatro dimensões v2 aprovadas com fonte específica;
-- 3) a role da API recebe leitura da relação de alergias.

BEGIN;

SET LOCAL lock_timeout = '10s';
SET LOCAL statement_timeout = '180s';
SET LOCAL search_path TO venus, public;

-- -------------------------------------------------------------------------
-- 1. Descrição amigável em português
-- -------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION venus.fn_make_ingredient_description(
    p_function_summary TEXT,
    p_category_name TEXT
)
RETURNS TEXT
LANGUAGE PLPGSQL
IMMUTABLE
AS $$
DECLARE
    v_term TEXT;
    v_clause TEXT;
    v_clauses TEXT[] := ARRAY[]::TEXT[];
BEGIN
    IF COALESCE(BTRIM(p_function_summary), '') = '' THEN
        CASE LOWER(COALESCE(BTRIM(p_category_name), ''))
            WHEN 'agente perfumante' THEN
                RETURN 'Confere perfume ao produto.';
            WHEN 'emoliente' THEN
                RETURN 'Ajuda a suavizar a pele e reduzir a sensação de ressecamento.';
            ELSE
                RETURN 'Este ingrediente faz parte da fórmula, mas sua função cosmética específica ainda não foi documentada no catálogo.';
        END CASE;
    END IF;

    IF LOWER(BTRIM(p_function_summary)) LIKE 'agente perfumante%'
       OR LOWER(BTRIM(p_function_summary)) LIKE '%fragrance%'
       OR LOWER(BTRIM(p_function_summary)) LIKE '%parfum%' THEN
        RETURN 'Ajuda a dar perfume ao produto.';
    END IF;

    FOR v_term IN
        SELECT BTRIM(value)
          FROM REGEXP_SPLIT_TO_TABLE(p_function_summary, '\s*;\s*') AS value
    LOOP
        v_clause := CASE LOWER(v_term)
            WHEN 'emollient' THEN 'suavizar a pele e reduzir a sensação de ressecamento'
            WHEN 'emulsifying' THEN 'misturar ingredientes que normalmente não se misturam'
            WHEN 'stabilising' THEN 'manter a fórmula estável'
            WHEN 'stabilizing' THEN 'manter a fórmula estável'
            WHEN 'opacificantes' THEN 'deixar a fórmula menos transparente'
            WHEN 'opacifying' THEN 'deixar a fórmula menos transparente'
            WHEN 'preservative' THEN 'proteger a fórmula contra microrganismos'
            WHEN 'deodorant' THEN 'reduzir ou mascarar odores'
            WHEN 'aditivos' THEN 'dar suporte à fórmula'
            WHEN 'additive' THEN 'dar suporte à fórmula'
            WHEN 'surfactant' THEN 'limpar e ajudar a misturar água e óleo'
            WHEN 'antistatic' THEN 'reduzir a eletricidade estática e o frizz'
            WHEN 'solvent' THEN 'dissolver outros ingredientes'
            WHEN 'humectant' THEN 'atrair e reter água'
            WHEN 'uv filter' THEN 'absorver ou filtrar parte da radiação UV'
            WHEN 'buffering' THEN 'manter o pH da fórmula'
            WHEN 'biological additive' THEN 'atuar como aditivo de origem biológica'
            WHEN 'botanical origin' THEN 'fornecer um componente de origem botânica'
            WHEN 'chelating' THEN 'controlar metais que podem desestabilizar a fórmula'
            WHEN 'film forming' THEN 'formar uma película fina sobre a pele ou o cabelo'
            WHEN 'antioxidant' THEN 'proteger a fórmula contra oxidação'
            WHEN 'viscosity controlling' THEN 'ajustar a espessura da fórmula'
            WHEN 'abrasive' THEN 'remover resíduos por fricção suave'
            WHEN 'absorbent' THEN 'absorver oleosidade ou umidade'
            WHEN 'antifoaming' THEN 'reduzir a formação de espuma'
            WHEN 'colorant' THEN 'dar cor ao produto'
            WHEN 'hair colorant' THEN 'dar cor aos cabelos'
            WHEN 'corantes capilares' THEN 'dar cor aos cabelos'
            WHEN 'desnaturantes' THEN 'alterar a composição do álcool para torná-lo impróprio para consumo'
            WHEN 'binding' THEN 'unir ou dar coesão aos ingredientes'
            WHEN 'hair removing' THEN 'ajudar na remoção dos pelos'
            WHEN 'reducing' THEN 'participar de reações de redução da fórmula'
            WHEN 'propellant' THEN 'impulsionar o produto para fora da embalagem'
            WHEN 'oral care' THEN 'dar suporte à higiene bucal'
            WHEN 'antiperspirant' THEN 'reduzir a transpiração'
            ELSE NULL
        END;

        IF v_clause IS NULL
           AND (LOWER(v_term) LIKE '%perfum%'
                OR LOWER(v_term) LIKE '%fragrance%') THEN
            v_clause := 'dar perfume ao produto';
        END IF;

        IF v_clause IS NULL THEN
            v_clause := 'dar suporte à formulação';
        END IF;

        IF NOT (v_clause = ANY(v_clauses)) THEN
            v_clauses := ARRAY_APPEND(v_clauses, v_clause);
        END IF;
    END LOOP;

    IF COALESCE(ARRAY_LENGTH(v_clauses, 1), 0) = 0 THEN
        RETURN 'Este ingrediente faz parte da fórmula, mas sua função cosmética específica ainda não foi documentada no catálogo.';
    END IF;

    RETURN 'Ajuda a ' || ARRAY_TO_STRING(v_clauses, ', ') || '.';
END;
$$;

CREATE OR REPLACE FUNCTION venus.fn_fill_ingredient_description()
RETURNS TRIGGER
LANGUAGE PLPGSQL
AS $$
DECLARE
    v_category_name TEXT;
BEGIN
    IF COALESCE(BTRIM(NEW.description), '') <> '' THEN
        RETURN NEW;
    END IF;

    SELECT c.name
      INTO v_category_name
      FROM venus.ingredient_categories c
     WHERE c.ingredient_category_id = NEW.fk_ingredient_category_id;

    NEW.description := venus.fn_make_ingredient_description(
        NEW.function_summary,
        v_category_name
    );
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_fill_ingredient_description ON venus.ingredients;
CREATE TRIGGER trg_fill_ingredient_description
BEFORE INSERT OR UPDATE OF description, function_summary, fk_ingredient_category_id
ON venus.ingredients
FOR EACH ROW
EXECUTE FUNCTION venus.fn_fill_ingredient_description();

-- Usa uma descrição de efeito já cadastrada quando existir; caso contrário,
-- traduz a função canônica sem sobrescrever textos já revisados.
UPDATE venus.ingredients i
   SET description = COALESCE(
           (
               SELECT NULLIF(BTRIM(e.effect_description), '')
                 FROM venus.ingredient_effects e
                WHERE e.fk_ingredient_id = i.ingredient_id
                  AND NULLIF(BTRIM(e.effect_description), '') IS NOT NULL
                ORDER BY e.ingredient_effect_id
                LIMIT 1
           ),
           venus.fn_make_ingredient_description(
               i.function_summary,
               c.name
           )
       ),
       updated_at = NOW()
  FROM venus.ingredient_categories c
 WHERE c.ingredient_category_id = i.fk_ingredient_category_id
   AND COALESCE(BTRIM(i.description), '') = '';

-- -------------------------------------------------------------------------
-- 2. Avaliação real: confidence não é aprovação por padrão
-- -------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION venus.fn_has_complete_ingredient_assessment(
    p_ingredient_id BIGINT
)
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
AS $$
WITH required(dimension) AS (
    VALUES
        ('irritation_risk_level'),
        ('comedogenicity_score'),
        ('biodegradability_level'),
        ('environmental_risk_level')
)
SELECT COUNT(*) = 4
  FROM required r
 WHERE EXISTS (
           SELECT 1
             FROM venus.ingredient_risk_assessments ira
            WHERE ira.fk_ingredient_id = p_ingredient_id
              AND ira.dimension = r.dimension
              AND ira.assessment_version = 'v2'
              AND ira.assessment_status = 'approved'
              AND NULLIF(BTRIM(ira.source_reference), '') IS NOT NULL
       );
$$;

CREATE OR REPLACE FUNCTION venus.fn_normalize_scientific_confidence_state()
RETURNS TRIGGER
LANGUAGE PLPGSQL
AS $$
BEGIN
    IF NEW.scientific_confidence IS NULL
       OR NEW.scientific_confidence <= 1
       OR NOT venus.fn_has_complete_ingredient_assessment(NEW.ingredient_id) THEN
        NEW.scientific_confidence := 0;
        NEW.scientific_confidence_state := 'default';
        RETURN NEW;
    END IF;

    IF NEW.scientific_confidence_state IS NULL
       OR NEW.scientific_confidence_state NOT IN ('default', 'derived', 'curated') THEN
        NEW.scientific_confidence_state := 'default';
    END IF;

    IF NEW.scientific_confidence_state <> 'curated' THEN
        NEW.scientific_confidence_state := 'derived';
    END IF;

    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION venus.fn_sync_ingredient_confidence_from_assessment()
RETURNS TRIGGER
LANGUAGE PLPGSQL
AS $$
DECLARE
    v_ingredient_id BIGINT := COALESCE(NEW.fk_ingredient_id, OLD.fk_ingredient_id);
    v_confidence SMALLINT;
BEGIN
    IF venus.fn_has_complete_ingredient_assessment(v_ingredient_id) THEN
        v_confidence := venus.fn_calculate_ingredient_confidence(v_ingredient_id);
        UPDATE venus.ingredients
           SET scientific_confidence = CASE WHEN v_confidence > 1 THEN v_confidence ELSE 0 END,
               scientific_confidence_state = CASE WHEN v_confidence > 1 THEN 'derived' ELSE 'default' END,
               updated_at = NOW()
         WHERE ingredient_id = v_ingredient_id;
    ELSE
        UPDATE venus.ingredients
           SET scientific_confidence = 0,
               scientific_confidence_state = 'default',
               updated_at = NOW()
         WHERE ingredient_id = v_ingredient_id;
    END IF;

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_sync_ingredient_confidence_from_assessment
    ON venus.ingredient_risk_assessments;
CREATE TRIGGER trg_sync_ingredient_confidence_from_assessment
AFTER INSERT OR UPDATE OR DELETE ON venus.ingredient_risk_assessments
FOR EACH ROW
EXECUTE FUNCTION venus.fn_sync_ingredient_confidence_from_assessment();

-- Normaliza qualquer confidence positiva que ainda não tenha as quatro
-- avaliações v2 com fonte. Os ingredientes usados pelos produtos atuais que
-- já foram promovidos permanecem avaliados.
UPDATE venus.ingredients i
   SET scientific_confidence = 0,
       scientific_confidence_state = 'default',
       updated_at = NOW()
 WHERE i.scientific_confidence > 1
   AND NOT venus.fn_has_complete_ingredient_assessment(i.ingredient_id);

-- Contrato consumível pelo backend: o selo só deve considerar avaliado quando
-- as quatro dimensões v2 com fonte específica estiverem aprovadas.
CREATE OR REPLACE VIEW venus.v_ingredient_evaluation_status AS
WITH approved AS (
    SELECT ira.fk_ingredient_id,
           COUNT(*) FILTER (
               WHERE ira.assessment_version = 'v2'
                 AND ira.assessment_status = 'approved'
                 AND NULLIF(BTRIM(ira.source_reference), '') IS NOT NULL
           )::INTEGER AS approved_v2_risk_dimensions,
           BOOL_OR(
               ira.assessment_status = 'approved'
               AND ira.assessment_version = 'v2'
               AND ira.evidence_level IN ('medium', 'high', 'very_high')
           ) AS has_stronger_evidence,
           MIN(ira.assessment_version) FILTER (WHERE ira.assessment_status = 'approved') AS assessment_version,
           MIN(ira.evidence_level::TEXT) FILTER (WHERE ira.assessment_status = 'approved') AS lowest_evidence_level
      FROM venus.ingredient_risk_assessments ira
     GROUP BY ira.fk_ingredient_id
)
SELECT i.ingredient_id,
       i.inci_name,
       i.scientific_confidence,
       i.scientific_confidence_state,
       COALESCE(a.approved_v2_risk_dimensions, 0) AS approved_risk_dimensions,
       COALESCE(a.approved_v2_risk_dimensions, 0) = 4 AS has_four_approved_risk_dimensions,
       COALESCE(a.has_stronger_evidence, FALSE) AS has_stronger_evidence,
       COALESCE(a.assessment_version, '') AS assessment_version,
       COALESCE(a.lowest_evidence_level, '') AS lowest_evidence_level,
       CASE
           WHEN NOT venus.fn_has_complete_ingredient_assessment(i.ingredient_id) THEN 'not_evaluated'
           WHEN COALESCE(a.has_stronger_evidence, FALSE) THEN 'assessed'
           ELSE 'assessed_indirect_v2'
       END AS evaluation_state,
       venus.fn_has_complete_ingredient_assessment(i.ingredient_id) AS is_really_evaluated
  FROM venus.ingredients i
  LEFT JOIN approved a
    ON a.fk_ingredient_id = i.ingredient_id;

COMMENT ON FUNCTION venus.fn_has_complete_ingredient_assessment(BIGINT) IS
    'Verdadeiro somente com as quatro dimensões v2 aprovadas e cada uma com source_reference.';
COMMENT ON VIEW venus.v_ingredient_evaluation_status IS
    'Contrato de avaliação: confidence padrão não é avaliação; is_really_evaluated exige quatro assessments v2 com fonte.';

-- -------------------------------------------------------------------------
-- 3. Permissões da API de classificação
-- -------------------------------------------------------------------------

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'api') THEN
        GRANT USAGE ON SCHEMA venus TO api;
        GRANT SELECT ON TABLE venus.allergy_ingredients TO api;
        GRANT SELECT ON TABLE venus.allergies TO api;
        GRANT SELECT ON TABLE venus.ingredients TO api;
        GRANT SELECT ON TABLE venus.v_ingredient_evaluation_status TO api;
    END IF;
END;
$$;

COMMIT;
