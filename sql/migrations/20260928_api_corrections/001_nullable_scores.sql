BEGIN;
SET LOCAL search_path TO venus, public;

ALTER TABLE venus.analysis_results
    ALTER COLUMN health_score DROP NOT NULL,
    ALTER COLUMN health_score DROP DEFAULT,
    ALTER COLUMN environmental_score DROP NOT NULL,
    ALTER COLUMN environmental_score DROP DEFAULT,
    ALTER COLUMN transparency_score DROP NOT NULL,
    ALTER COLUMN transparency_score DROP DEFAULT,
    ALTER COLUMN confidence_score DROP NOT NULL,
    ALTER COLUMN confidence_score DROP DEFAULT;

ALTER TABLE venus.product_scores
    ALTER COLUMN health_score DROP NOT NULL,
    ALTER COLUMN health_score DROP DEFAULT,
    ALTER COLUMN environmental_score DROP NOT NULL,
    ALTER COLUMN environmental_score DROP DEFAULT,
    ALTER COLUMN transparency_score DROP NOT NULL,
    ALTER COLUMN transparency_score DROP DEFAULT,
    ALTER COLUMN confidence_score DROP NOT NULL,
    ALTER COLUMN confidence_score DROP DEFAULT;

ALTER TABLE venus.personalized_scores
    ALTER COLUMN compatibility_percentage DROP NOT NULL,
    ALTER COLUMN compatibility_percentage DROP DEFAULT;

COMMIT;

SELECT table_name, column_name, is_nullable, column_default
FROM information_schema.columns
WHERE table_schema = 'venus'
  AND (table_name, column_name) IN (
      ('analysis_results', 'health_score'),
      ('analysis_results', 'environmental_score'),
      ('analysis_results', 'transparency_score'),
      ('analysis_results', 'confidence_score'),
      ('product_scores', 'health_score'),
      ('product_scores', 'environmental_score'),
      ('product_scores', 'transparency_score'),
      ('product_scores', 'confidence_score'),
      ('personalized_scores', 'compatibility_percentage')
  )
ORDER BY table_name, column_name;
