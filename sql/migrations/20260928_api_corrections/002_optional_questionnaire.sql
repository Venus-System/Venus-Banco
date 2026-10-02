BEGIN;
SET LOCAL search_path TO venus, public;

ALTER TABLE venus.user_profiles
    ALTER COLUMN has_hyperpigmentation DROP NOT NULL,
    ALTER COLUMN has_hyperpigmentation DROP DEFAULT,
    ALTER COLUMN has_melasma DROP NOT NULL,
    ALTER COLUMN has_melasma DROP DEFAULT,
    ALTER COLUMN has_rosacea DROP NOT NULL,
    ALTER COLUMN has_rosacea DROP DEFAULT,
    ALTER COLUMN has_eczema DROP NOT NULL,
    ALTER COLUMN has_eczema DROP DEFAULT,
    ALTER COLUMN acne_prone DROP NOT NULL,
    ALTER COLUMN acne_prone DROP DEFAULT,
    ALTER COLUMN is_pregnant DROP NOT NULL,
    ALTER COLUMN is_pregnant DROP DEFAULT,
    ALTER COLUMN is_breastfeeding DROP NOT NULL,
    ALTER COLUMN is_breastfeeding DROP DEFAULT,
    ALTER COLUMN skin_type DROP NOT NULL,
    ALTER COLUMN skin_type DROP DEFAULT,
    ALTER COLUMN skin_phototype DROP NOT NULL,
    ALTER COLUMN skin_phototype DROP DEFAULT,
    ALTER COLUMN hair_pattern DROP NOT NULL,
    ALTER COLUMN hair_pattern DROP DEFAULT,
    ALTER COLUMN scalp_type DROP NOT NULL,
    ALTER COLUMN scalp_type DROP DEFAULT,
    ALTER COLUMN skin_sensitivity DROP NOT NULL,
    ALTER COLUMN skin_sensitivity DROP DEFAULT,
    ALTER COLUMN age_range DROP NOT NULL,
    ALTER COLUMN age_range DROP DEFAULT,
    ALTER COLUMN gender DROP NOT NULL,
    ALTER COLUMN gender DROP DEFAULT;

COMMIT;

SELECT column_name, is_nullable, column_default
FROM information_schema.columns
WHERE table_schema = 'venus'
  AND table_name = 'user_profiles'
  AND column_name IN (
      'has_hyperpigmentation', 'has_melasma', 'has_rosacea', 'has_eczema',
      'acne_prone', 'is_pregnant', 'is_breastfeeding', 'skin_type',
      'skin_phototype', 'hair_pattern', 'scalp_type', 'skin_sensitivity',
      'age_range', 'gender'
  )
ORDER BY column_name;
