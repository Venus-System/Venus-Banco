BEGIN;

SET search_path TO venus, public;

/*
  Correção 2 — granularidade do tipo de cabelo
  --------------------------------------------
  hair_type continua sendo a classificação macro:
      straight / wavy / curly / coily / other

  hair_pattern representa a classificação específica:
      1A ... 1C
      2A ... 2C
      3A ... 3C
      4A ... 4C
      other

  Os registros antigos permanecem válidos com hair_pattern = NULL, pois não
  é seguro inferir 1A/2A/3A/4A somente a partir do hair_type antigo.
*/

DO $$
BEGIN
    CREATE TYPE venus.hair_pattern_enum AS ENUM (
        '1A', '1B', '1C',
        '2A', '2B', '2C',
        '3A', '3B', '3C',
        '4A', '4B', '4C',
        'other'
    );
EXCEPTION
    WHEN duplicate_object THEN NULL;
END$$;

ALTER TABLE venus.user_profiles
    ADD COLUMN IF NOT EXISTS hair_pattern venus.hair_pattern_enum;

ALTER TABLE venus.user_profiles
    DROP CONSTRAINT IF EXISTS ck_user_profiles_hair_pattern_consistency;

ALTER TABLE venus.user_profiles
    ADD CONSTRAINT ck_user_profiles_hair_pattern_consistency
    CHECK (
        hair_pattern IS NULL
        OR hair_pattern = 'other'
        OR (
            hair_pattern IN ('1A','1B','1C')
            AND hair_type = 'straight'
        )
        OR (
            hair_pattern IN ('2A','2B','2C')
            AND hair_type = 'wavy'
        )
        OR (
            hair_pattern IN ('3A','3B','3C')
            AND hair_type = 'curly'
        )
        OR (
            hair_pattern IN ('4A','4B','4C')
            AND hair_type = 'coily'
        )
    );

CREATE INDEX IF NOT EXISTS idx_user_profiles_hair_pattern
    ON venus.user_profiles (hair_pattern);

COMMENT ON COLUMN venus.user_profiles.hair_type IS
'Classificação macro do cabelo: straight, wavy, curly, coily ou other.';

COMMENT ON COLUMN venus.user_profiles.hair_pattern IS
'Classificação específica do padrão capilar: 1A–4C ou other. Nullable para perfis legados ainda sem granularidade.';

COMMIT;

/* QA */
SELECT hair_type::text, hair_pattern::text, COUNT(*) AS total
FROM venus.user_profiles
GROUP BY hair_type, hair_pattern
ORDER BY hair_type, hair_pattern;
