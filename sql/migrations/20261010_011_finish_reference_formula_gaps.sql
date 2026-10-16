-- Venus — completa as três cargas que ficaram sem rótulo — 2026-10-10
-- Os produtos 70, 82 e 84 usam fórmulas de referência já persistidas pela
-- migration 010; nenhum score de produto é calculado aqui.

BEGIN;

SET LOCAL lock_timeout = '10s';
SET LOCAL statement_timeout = '180s';
SET LOCAL search_path TO venus, public;

WITH source_map(target_product_id, source_product_id, source_reference) AS (
    VALUES
        (70, 69, 'https://www.boticario.com.br/produto/locao-hidratante-desodorante-corporal-cuide-se-bem-lavandinha-400ml/ | reference_formula=true | reference_product_id=69 | variant_note=Nativa SPA Quinoa sem INCI capturado; referencia oficial de hidratante corporal | evidence_level=low'),
        (82, 79, 'https://pantene.com.br/pt-br/produtos/shampoo/liso-extremo | reference_formula=true | reference_product_id=79 | variant_note=Pantene Reparo Extremo sem INCI capturado; referencia oficial Pantene shampoo | evidence_level=low'),
        (84, 80, 'https://www.kerastase.com.br/produtos/colecoes/nutritive/mascara-kerastase-nutritive-masquintense/KRBR00252.html | reference_formula=true | reference_product_id=80 | variant_note=Pantene 3 Minutos Milagrosos sem INCI capturado; referencia oficial de tratamento capilar | evidence_level=low')
)
INSERT INTO venus.product_labels (
    fk_product_version_id,
    normalized_text,
    language,
    source_type,
    source_reference
)
SELECT target.product_version_id,
       source.normalized_text,
       'pt-BR',
       'system',
       m.source_reference
  FROM source_map m
  JOIN venus.product_versions target
    ON target.fk_product_id = m.target_product_id
   AND target.is_current
  JOIN venus.product_versions source_version
    ON source_version.fk_product_id = m.source_product_id
   AND source_version.is_current
  JOIN venus.product_labels source
    ON source.fk_product_version_id = source_version.product_version_id
ON CONFLICT (fk_product_version_id) DO UPDATE
   SET normalized_text = EXCLUDED.normalized_text,
       language = EXCLUDED.language,
       source_type = EXCLUDED.source_type,
       source_reference = EXCLUDED.source_reference,
       updated_at = NOW();

CALL venus.sp_resolve_all_current_product_labels();

UPDATE venus.product_versions
   SET updated_at = updated_at
 WHERE is_current;

COMMIT;
