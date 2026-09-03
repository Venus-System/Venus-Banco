SET search_path TO venus, public;


SET search_path TO venus, public;


INSERT INTO venus.regulations
(
    title,
    country,
    agency,
    document_url,
    status,
    effective_date,
    summary
)
VALUES
(
    'Regulamento (CE) n.º 1223/2009 do Parlamento Europeu e do Conselho',
    'UE',
    'Parlamento Europeu e Conselho da União Europeia',
    'https://eur-lex.europa.eu/legal-content/PT/TXT/?uri=CELEX:32009R1223',
    'active',
    NULL,
    'Regulamento europeu relativo aos produtos cosméticos, incluindo requisitos de segurança, rotulagem e anexos com substâncias proibidas e restritas.'
)
ON CONFLICT (title, country, agency)
DO UPDATE SET
    document_url = EXCLUDED.document_url,
    status = EXCLUDED.status,
    summary = EXCLUDED.summary,
    updated_at = NOW();



INSERT INTO venus.regulations
(
    title,
    country,
    agency,
    document_url,
    status,
    effective_date,
    summary
)
VALUES
(
    'Decisão de Execução (UE) 2025/1175 da Comissão',
    'UE',
    'Comissão Europeia',
    'https://eur-lex.europa.eu/legal-content/PT/TXT/?uri=CELEX:32025D1175',
    'active',
    NULL,
    'Decisão de Execução que estabelece o glossário consolidado de denominações comuns de ingredientes cosméticos para utilização na rotulagem.'
)
ON CONFLICT (title, country, agency)
DO UPDATE SET
    document_url = EXCLUDED.document_url,
    status = EXCLUDED.status,
    summary = EXCLUDED.summary,
    updated_at = NOW();



INSERT INTO venus.regulations
(
    title,
    country,
    agency,
    document_url,
    status,
    effective_date,
    summary
)
VALUES
(
    'Decisão 96/335/CE da Comissão',
    'UE',
    'Comissão Europeia',
    'https://eur-lex.europa.eu/legal-content/PT/TXT/?uri=CELEX:31996D0335',
    'deprecated',
    NULL,
    'Decisão histórica que estabelece o inventário e a nomenclatura comum de ingredientes utilizados em produtos cosméticos.'
)
ON CONFLICT (title, country, agency)
DO UPDATE SET
    document_url = EXCLUDED.document_url,
    status = EXCLUDED.status,
    summary = EXCLUDED.summary,
    updated_at = NOW();



DO $$
DECLARE
    v_count INTEGER;
BEGIN
    SELECT COUNT(*)
      INTO v_count
      FROM venus.regulations
     WHERE title = 'Regulamento (CE) n.º 1223/2009 do Parlamento Europeu e do Conselho'
       AND country = 'UE';

    IF v_count <> 1 THEN
        RAISE EXCEPTION
            'REPARO FALHOU: Regulamento 1223/2009 não foi cadastrado corretamente.';
    END IF;
END $$;


DO $$
DECLARE
    v_orphans INTEGER;
    v_links INTEGER;
BEGIN
    SELECT COUNT(*)
      INTO v_links
      FROM venus.ingredient_regulations;

    SELECT COUNT(*)
      INTO v_orphans
      FROM venus.ingredient_regulations ir
      LEFT JOIN venus.regulations r
        ON r.regulation_id = ir.fk_regulation_id
     WHERE r.regulation_id IS NULL;

    IF v_orphans > 0 THEN
        RAISE EXCEPTION
            'REPARO FALHOU: % de % ingredient_regulations possuem FK órfã.',
            v_orphans,
            v_links;
    END IF;
END $$;







SELECT
    regulation_id,
    title,
    country,
    agency,
    status,
    document_url
FROM venus.regulations
ORDER BY regulation_id;
