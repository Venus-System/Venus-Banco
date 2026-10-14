-- Venus — completa a cobertura de avaliações indiretas v2 — 2026-10-13
--
-- A classificação continua fora desta migração. Ela apenas materializa, para
-- os ingredientes que ainda não possuem as quatro dimensões aprovadas, a
-- avaliação indireta v2 já definida no banco e recalcula o confidence derivado.
-- Isso mantém o contrato usado pelo Venus-qa também no Venus-2ano.

SET default_transaction_read_only = off;

BEGIN;

SET LOCAL lock_timeout = '10s';
SET LOCAL statement_timeout = '900s';
SET LOCAL search_path TO venus, public;
SET LOCAL session_replication_role = 'replica';

DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN
        SELECT i.ingredient_id
          FROM venus.ingredients i
         WHERE NOT EXISTS (
                   SELECT 1
                     FROM venus.ingredient_risk_assessments ira
                    WHERE ira.fk_ingredient_id = i.ingredient_id
                      AND ira.assessment_status = 'approved'
                      AND ira.assessment_version = 'v2'
                    GROUP BY ira.fk_ingredient_id
                   HAVING COUNT(DISTINCT ira.dimension) = 4
               )
         ORDER BY i.ingredient_id
    LOOP
        PERFORM venus.fn_refresh_ingredient_risk_assessment_v2(r.ingredient_id);
    END LOOP;
END;
$$;

-- O gatilho de sincronização fica temporariamente suspenso acima para evitar
-- tocar milhares de versões durante o backfill. Reaplicamos a mesma regra
-- derivada usada pelo gatilho, sem transformar ausência de assessment em valor
-- positivo.
UPDATE venus.ingredients i
   SET scientific_confidence = CASE
           WHEN venus.fn_has_complete_ingredient_assessment(i.ingredient_id)
               THEN venus.fn_calculate_ingredient_confidence(i.ingredient_id)
           ELSE 0
       END,
       scientific_confidence_state = CASE
           WHEN venus.fn_has_complete_ingredient_assessment(i.ingredient_id)
               THEN 'derived'
           ELSE 'default'
       END,
       updated_at = NOW();

COMMIT;

