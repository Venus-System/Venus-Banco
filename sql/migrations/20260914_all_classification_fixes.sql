BEGIN;

SET search_path TO venus, public;

-- ============================================================
-- Correção 3 — somente maiores de 18 anos
-- ============================================================
--
-- O modelo não armazena idade exata.
-- Portanto, registros legados nas faixas de menores são
-- normalizados para a menor faixa adulta disponível.
--
-- Mantemos o ENUM atual para não quebrar views existentes.
-- A regra de negócio passa a ser garantida pela CHECK constraint.
-- ============================================================

UPDATE venus.user_profiles
SET age_range = 'age_18_24'
WHERE age_range::text IN (
    'under_13',
    'age_13_17'
);

-- Garante que novos registros tenham uma faixa adulta por padrão.
ALTER TABLE venus.user_profiles
    ALTER COLUMN age_range
    SET DEFAULT 'age_18_24';

-- Remove eventual constraint anterior para recriá-la de forma
-- idempotente.
ALTER TABLE venus.user_profiles
    DROP CONSTRAINT IF EXISTS ck_user_profiles_adult_age_range;

-- Permite somente faixas adultas.
ALTER TABLE venus.user_profiles
    ADD CONSTRAINT ck_user_profiles_adult_age_range
    CHECK (
        age_range::text IN (
            'age_18_24',
            'age_25_34',
            'age_35_44',
            'age_45_54',
            'age_55_plus'
        )
    );

COMMIT;

-- ============================================================
-- QA
-- ============================================================

SELECT
    age_range::text AS age_range,
    COUNT(*) AS total
FROM venus.user_profiles
GROUP BY age_range
ORDER BY age_range;

SELECT COUNT(*) AS forbidden_minor_rows
FROM venus.user_profiles
WHERE age_range::text IN (
    'under_13',
    'age_13_17'
);