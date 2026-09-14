
SELECT 'core_tables' AS check_name, COUNT(*) AS total
FROM information_schema.tables
WHERE table_schema = 'venus' AND table_type = 'BASE TABLE';

SELECT 'legacy_tables' AS check_name, COUNT(*) AS total
FROM information_schema.tables
WHERE table_schema = 'venus'
  AND table_name IN ('product_images','scan_sessions','routines','routine_items');

SELECT 'ingredients' AS check_name, COUNT(*) AS total FROM venus.ingredients
UNION ALL SELECT 'ingredient_aliases', COUNT(*) FROM venus.ingredient_aliases
UNION ALL SELECT 'ingredient_properties', COUNT(*) FROM venus.ingredient_properties
UNION ALL SELECT 'ingredient_effects', COUNT(*) FROM venus.ingredient_effects
UNION ALL SELECT 'ingredient_regulations', COUNT(*) FROM venus.ingredient_regulations
UNION ALL SELECT 'products', COUNT(*) FROM venus.products
UNION ALL SELECT 'users', COUNT(*) FROM venus.users
ORDER BY check_name;

SELECT 'active_scoring_models' AS check_name, COUNT(*) AS total
FROM venus.scoring_models
WHERE is_active;

SELECT 'multiple_current_versions' AS check_name, COUNT(*) AS total
FROM (
    SELECT fk_product_id
    FROM venus.product_versions
    WHERE is_current
    GROUP BY fk_product_id
    HAVING COUNT(*) > 1
) q;

SELECT 'catalog_tables' AS check_name, COUNT(*) AS total
FROM venus.data_catalog
WHERE object_type = 'TABLE' AND is_active;

SELECT 'catalog_columns' AS check_name, COUNT(*) AS total
FROM venus.data_catalog
WHERE object_type = 'COLUMN' AND is_active;


SELECT 'audit_actor' AS check_name, COUNT(*) AS total_missing
FROM venus_audit.audit_logs
WHERE changed_by IS NULL OR changed_by = '';

SELECT 'dau_objects' AS check_name,
       (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='venus' AND table_name='user_access_events') AS access_table,
       (SELECT COUNT(*) FROM information_schema.views WHERE table_schema='venus' AND table_name='v_dau') AS dau_view;

SELECT 'recursive_category_view' AS check_name, COUNT(*) AS total
FROM venus.v_ingredient_category_tree;

SELECT 'explain_artifact' AS check_name, COUNT(*) AS total
FROM venus_optimization.readme;


SELECT 'academic_data_volume' AS check_name,
       (SELECT COUNT(*) FROM venus.ingredients) AS ingredients,
       (SELECT COUNT(*) FROM venus.products) AS products,
       (SELECT COUNT(*) FROM venus.users) AS users,
       (SELECT
          (SELECT COUNT(*) FROM venus.ingredients) +
          (SELECT COUNT(*) FROM venus.products) +
          (SELECT COUNT(*) FROM venus.users)) AS total_primary_rows;

SELECT 'academic_functions' AS check_name, COUNT(*) AS total
FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
WHERE n.nspname='venus' AND p.prokind='f';

SELECT 'academic_procedures' AS check_name, COUNT(*) AS total
FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
WHERE n.nspname='venus' AND p.prokind='p';

SELECT 'academic_audit_triggers' AS check_name, COUNT(*) AS total
FROM information_schema.triggers
WHERE trigger_schema='venus_audit' OR (event_object_schema='venus' AND trigger_name LIKE 'trg_audit_%');

SELECT 'cloudinary_media_table' AS check_name,
       CASE WHEN EXISTS (
           SELECT 1 FROM information_schema.tables
           WHERE table_schema='venus' AND table_name='media_assets'
       ) THEN 1 ELSE 0 END AS total;

SELECT 'cloudinary_views' AS check_name,
       (SELECT COUNT(*) FROM information_schema.views WHERE table_schema='venus' AND table_name='v_user_avatars') AS user_avatar_view,
       (SELECT COUNT(*) FROM information_schema.views WHERE table_schema='venus' AND table_name='v_product_photos') AS product_photo_view;

SELECT 'cloudinary_media_invalid_owners' AS check_name, COUNT(*) AS total
FROM venus.media_assets
WHERE NOT (
    (fk_user_id IS NOT NULL AND fk_product_version_id IS NULL AND purpose='avatar')
    OR
    (fk_user_id IS NULL AND fk_product_version_id IS NOT NULL AND purpose='product_photo')
);


SELECT 'cloudinary_duplicate_columns_removed' AS check_name,
       (SELECT COUNT(*) FROM information_schema.columns
        WHERE table_schema='venus' AND ((table_name='users' AND column_name IN ('avatar_public_id','avatar_secure_url','avatar_updated_at'))
          OR (table_name='product_versions' AND column_name IN ('photo_public_id','photo_secure_url','photo_updated_at')))) AS total;

SELECT 'cloudinary_single_source_of_truth' AS check_name,
       CASE WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='venus' AND table_name='media_assets')
         AND NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='venus' AND column_name IN ('avatar_public_id','avatar_secure_url','avatar_updated_at','photo_public_id','photo_secure_url','photo_updated_at'))
       THEN 1 ELSE 0 END AS ok;

SELECT 'cloudinary_media_required_metadata' AS check_name, COUNT(*) AS total_null_public_id
FROM venus.media_assets
WHERE public_id IS NULL OR BTRIM(public_id)='';

SELECT 'adult_only_age_range' AS check_name,
       COUNT(*) AS forbidden_minor_rows
FROM venus.user_profiles
WHERE age_range::text IN ('under_13','age_13_17');

SELECT 'age_range_enum_values' AS check_name,
       string_agg(e.enumlabel, ', ' ORDER BY e.enumsortorder) AS values
FROM pg_enum e
JOIN pg_type t ON t.oid = e.enumtypid
JOIN pg_namespace n ON n.oid = t.typnamespace
WHERE n.nspname='venus' AND t.typname='age_range_enum';

SELECT 'allergy_ingredient_table' AS check_name,
       CASE WHEN EXISTS (
           SELECT 1 FROM information_schema.tables
           WHERE table_schema='venus' AND table_name='allergy_ingredients'
       ) THEN 1 ELSE 0 END AS exists_flag;

SELECT 'unmapped_ingredient_allergies' AS check_name,
       COUNT(*) AS total
FROM venus.allergies a
LEFT JOIN venus.allergy_ingredients ai
  ON ai.fk_allergy_id=a.allergy_id
WHERE a.allergy_type='ingredient'
  AND ai.allergy_ingredient_id IS NULL;

SELECT 'hair_pattern_inconsistent' AS check_name,
       COUNT(*) AS total
FROM venus.user_profiles
WHERE hair_pattern IS NOT NULL
  AND NOT (
      hair_pattern='other'
      OR (hair_pattern IN ('1A','1B','1C') AND hair_type='straight')
      OR (hair_pattern IN ('2A','2B','2C') AND hair_type='wavy')
      OR (hair_pattern IN ('3A','3B','3C') AND hair_type='curly')
      OR (hair_pattern IN ('4A','4B','4C') AND hair_type='coily')
  );
