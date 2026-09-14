





CREATE SCHEMA IF NOT EXISTS venus;

SET search_path TO venus, pg_catalog;



CREATE TABLE IF NOT EXISTS venus.data_catalog_rules
(
    rule_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    object_type TEXT NOT NULL
        CHECK (object_type IN ('TABLE', 'COLUMN')),

    table_name TEXT NOT NULL,

    column_name TEXT NOT NULL DEFAULT '',

    table_description TEXT,

    column_description TEXT,

    business_rule TEXT,

    access_level TEXT NOT NULL DEFAULT 'AUTHENTICATED'
        CHECK (
            access_level IN (
                'PUBLIC',
                'AUTHENTICATED',
                'OWNER',
                'ADMIN',
                'SYSTEM',
                'RESTRICTED'
            )
        ),

    access_rule TEXT,

    data_classification TEXT NOT NULL DEFAULT 'INTERNAL'
        CHECK (
            data_classification IN (
                'PUBLIC',
                'INTERNAL',
                'CONFIDENTIAL',
                'RESTRICTED'
            )
        ),

    sensitivity_reason TEXT,

    retention_policy TEXT,

    notes TEXT,

    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    UNIQUE (object_type, table_name, column_name)
);



CREATE TABLE IF NOT EXISTS venus.data_catalog
(
    catalog_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    object_type TEXT NOT NULL
        CHECK (object_type IN ('TABLE', 'COLUMN')),

    table_name TEXT NOT NULL,

    column_name TEXT NOT NULL DEFAULT '',

    ordinal_position INTEGER,

    data_type TEXT,

    udt_name TEXT,

    is_nullable BOOLEAN,

    default_value TEXT,

    is_primary_key BOOLEAN NOT NULL DEFAULT FALSE,

    is_foreign_key BOOLEAN NOT NULL DEFAULT FALSE,

    referenced_table_name TEXT,

    referenced_column_name TEXT NOT NULL DEFAULT '',

    table_description TEXT,

    column_description TEXT,

    business_rule TEXT,

    access_level TEXT NOT NULL DEFAULT 'AUTHENTICATED'
        CHECK (
            access_level IN (
                'PUBLIC',
                'AUTHENTICATED',
                'OWNER',
                'ADMIN',
                'SYSTEM',
                'RESTRICTED'
            )
        ),

    access_rule TEXT,

    data_classification TEXT NOT NULL DEFAULT 'INTERNAL'
        CHECK (
            data_classification IN (
                'PUBLIC',
                'INTERNAL',
                'CONFIDENTIAL',
                'RESTRICTED'
            )
        ),

    sensitivity_reason TEXT,

    retention_policy TEXT,

    source_of_definition TEXT NOT NULL DEFAULT 'VENUS_SCHEMA',

    reviewed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    UNIQUE (object_type, table_name, column_name)
);



UPDATE venus.data_catalog
SET access_level = 'AUTHENTICATED'
WHERE access_level IS NULL
   OR access_level NOT IN
      (
          'PUBLIC',
          'AUTHENTICATED',
          'OWNER',
          'ADMIN',
          'SYSTEM',
          'RESTRICTED'
      );


UPDATE venus.data_catalog
SET data_classification = 'INTERNAL'
WHERE data_classification IS NULL
   OR data_classification NOT IN
      (
          'PUBLIC',
          'INTERNAL',
          'CONFIDENTIAL',
          'RESTRICTED'
      );


UPDATE venus.data_catalog
SET source_of_definition = 'VENUS_SCHEMA'
WHERE source_of_definition IS NULL;


UPDATE venus.data_catalog
SET is_active = TRUE
WHERE is_active IS NULL;


UPDATE venus.data_catalog
SET is_primary_key = FALSE
WHERE is_primary_key IS NULL;


UPDATE venus.data_catalog
SET is_foreign_key = FALSE
WHERE is_foreign_key IS NULL;


UPDATE venus.data_catalog
SET created_at = NOW()
WHERE created_at IS NULL;


UPDATE venus.data_catalog
SET updated_at = NOW()
WHERE updated_at IS NULL;


UPDATE venus.data_catalog
SET reviewed_at = NOW()
WHERE reviewed_at IS NULL;


UPDATE venus.data_catalog_rules
SET access_level = 'AUTHENTICATED'
WHERE access_level IS NULL
   OR access_level NOT IN
      (
          'PUBLIC',
          'AUTHENTICATED',
          'OWNER',
          'ADMIN',
          'SYSTEM',
          'RESTRICTED'
      );


UPDATE venus.data_catalog_rules
SET data_classification = 'INTERNAL'
WHERE data_classification IS NULL
   OR data_classification NOT IN
      (
          'PUBLIC',
          'INTERNAL',
          'CONFIDENTIAL',
          'RESTRICTED'
      );


UPDATE venus.data_catalog_rules
SET is_active = TRUE
WHERE is_active IS NULL;


UPDATE venus.data_catalog_rules
SET created_at = NOW()
WHERE created_at IS NULL;


UPDATE venus.data_catalog_rules
SET updated_at = NOW()
WHERE updated_at IS NULL;



CREATE INDEX IF NOT EXISTS idx_data_catalog_table
    ON venus.data_catalog (table_name);


CREATE INDEX IF NOT EXISTS idx_data_catalog_column
    ON venus.data_catalog (table_name, column_name);


CREATE INDEX IF NOT EXISTS idx_data_catalog_access
    ON venus.data_catalog (access_level);


CREATE INDEX IF NOT EXISTS idx_data_catalog_classification
    ON venus.data_catalog (data_classification);


CREATE INDEX IF NOT EXISTS idx_data_catalog_rules_table
    ON venus.data_catalog_rules (table_name);


CREATE INDEX IF NOT EXISTS idx_data_catalog_rules_column
    ON venus.data_catalog_rules (table_name, column_name);



INSERT INTO venus.data_catalog_rules
(
    object_type,
    table_name,
    column_name,
    table_description,
    business_rule,
    access_level,
    access_rule,
    data_classification,
    sensitivity_reason,
    retention_policy,
    notes
)
VALUES


(
    'TABLE',
    'users',
    '',
    'Cadastro principal dos usuários.',
    'Representa a identidade e o estado cadastral do usuário.',
    'OWNER',
    'Usuário acessa apenas seus próprios dados.',
    'CONFIDENTIAL',
    'Contém dados pessoais e identificadores de autenticação.',
    NULL,
    NULL
),

(
    'TABLE',
    'allergy_ingredients',
    '',
    'Relação entre alergias e ingredientes INCI.',
    'Permite ao motor de compatibilidade identificar quais ingredientes acionam uma alergia declarada.',
    'SYSTEM',
    'Uso controlado pelo backend e motor de compatibilidade.',
    'INTERNAL',
    NULL,
    NULL,
    NULL
),

(
    'TABLE',
    'user_profiles',
    '',
    'Perfil de características declaradas pelo usuário.',
    'Informações representam dados declarados e não diagnósticos.',
    'OWNER',
    'Usuário acessa somente o próprio perfil.',
    'CONFIDENTIAL',
    'Pode conter informações relacionadas à saúde e características pessoais.',
    NULL,
    NULL
),

(
    'TABLE',
    'user_preferences',
    '',
    'Preferências declaradas do usuário.',
    'Utilizadas para personalização de produtos.',
    'OWNER',
    'Usuário acessa somente as próprias preferências.',
    'CONFIDENTIAL',
    'Pode revelar hábitos e preferências pessoais.',
    NULL,
    NULL
),

(
    'TABLE',
    'user_allergies',
    '',
    'Alergias declaradas pelos usuários.',
    'Alergias devem influenciar as regras de compatibilidade.',
    'OWNER',
    'Usuário acessa somente os próprios registros.',
    'RESTRICTED',
    'Informação relacionada à saúde.',
    NULL,
    NULL
),

(
    'TABLE',
    'user_profile_tags',
    '',
    'Tags associadas aos perfis de usuários.',
    'Devem representar atributos declarados ou explicitamente atribuídos.',
    'OWNER',
    'Usuário acessa somente suas tags.',
    'CONFIDENTIAL',
    'Pode representar características pessoais ou condições.',
    NULL,
    NULL
),


(
    'TABLE',
    'analysis_results',
    '',
    'Resultados das análises realizadas.',
    'Resultado personalizado e não diagnóstico médico.',
    'OWNER',
    'Usuário acessa apenas os próprios resultados.',
    'CONFIDENTIAL',
    'Resultado derivado do perfil.',
    NULL,
    NULL
),

(
    'TABLE',
    'rule_evaluations',
    '',
    'Avaliações das regras durante uma análise.',
    'Registra como regras influenciaram um resultado.',
    'OWNER',
    'Usuário acessa somente seus próprios resultados.',
    'CONFIDENTIAL',
    'Pode revelar critérios personalizados.',
    NULL,
    NULL
),

(
    'TABLE',
    'personalized_scores',
    '',
    'Scores personalizados de compatibilidade.',
    'Resultado calculado e não diagnóstico.',
    'OWNER',
    'Usuário acessa apenas seus próprios scores.',
    'CONFIDENTIAL',
    'Resultado derivado do perfil.',
    NULL,
    NULL
),

(
    'TABLE',
    'recommendations',
    '',
    'Recomendações personalizadas.',
    'Devem ser baseadas nas regras e dados de compatibilidade.',
    'OWNER',
    'Usuário acessa apenas suas recomendações.',
    'CONFIDENTIAL',
    'Resultado personalizado.',
    NULL,
    NULL
),


(
    'TABLE',
    'favorites',
    '',
    'Produtos favoritos dos usuários.',
    'Representa preferência do usuário.',
    'OWNER',
    'Usuário acessa apenas seus próprios favoritos.',
    'CONFIDENTIAL',
    NULL,
    NULL,
    NULL
),

(
    'TABLE',
    'user_lists',
    '',
    'Listas pessoais de produtos.',
    'Cada lista pertence ao usuário que a criou.',
    'OWNER',
    'Usuário acessa apenas suas próprias listas.',
    'CONFIDENTIAL',
    NULL,
    NULL,
    NULL
),

(
    'TABLE',
    'user_list_items',
    '',
    'Produtos pertencentes às listas pessoais.',
    'Pertence ao usuário proprietário da lista.',
    'OWNER',
    'Usuário acessa apenas seus próprios itens.',
    'CONFIDENTIAL',
    NULL,
    NULL,
    NULL
),

(
    'TABLE',
    'reviews',
    '',
    'Avaliações e comentários publicados.',
    'Conteúdo público/autenticado conforme as regras do produto.',
    'AUTHENTICATED',
    'Usuários autenticados podem consultar avaliações.',
    'CONFIDENTIAL',
    NULL,
    NULL,
    NULL
),

(
    'TABLE',
    'review_votes',
    '',
    'Votos de utilidade das avaliações.',
    'Representa interação do usuário com avaliações.',
    'AUTHENTICATED',
    'Usuários autenticados podem consultar e registrar seus votos.',
    'INTERNAL',
    NULL,
    NULL,
    NULL
),


(
    'TABLE',
    'admin_users',
    '',
    'Contas administrativas.',
    'Acesso administrativo restrito.',
    'ADMIN',
    'Somente administradores autorizados.',
    'RESTRICTED',
    'Conta privilegiada.',
    NULL,
    NULL
),

(
    'TABLE',
    'reports',
    '',
    'Denúncias e registros de moderação.',
    'Tratamento restrito a administração/moderação.',
    'ADMIN',
    'Somente usuários administrativos autorizados.',
    'RESTRICTED',
    'Pode conter dados pessoais e informações de moderação.',
    NULL,
    NULL
),

(
    'TABLE',
    'compatibility_rules',
    '',
    'Regras utilizadas pelo motor de compatibilidade.',
    'Somente regras habilitadas devem ser aplicadas.',
    'SYSTEM',
    'Somente backend/admin autorizado.',
    'RESTRICTED',
    'Contém lógica interna do sistema.',
    NULL,
    NULL
),


(
    'TABLE',
    'brands',
    '',
    'Cadastro das marcas.',
    NULL,
    'PUBLIC',
    'Consulta pública.',
    'PUBLIC',
    NULL,
    NULL,
    NULL
),

(
    'TABLE',
    'product_categories',
    '',
    'Categorias de produtos.',
    NULL,
    'PUBLIC',
    'Consulta pública.',
    'PUBLIC',
    NULL,
    NULL,
    NULL
),

(
    'TABLE',
    'products',
    '',
    'Catálogo de produtos cosméticos.',
    NULL,
    'PUBLIC',
    'Consulta pública.',
    'PUBLIC',
    NULL,
    NULL,
    NULL
),

(
    'TABLE',
    'product_versions',
    '',
    'Versões e formulações dos produtos.',
    NULL,
    'PUBLIC',
    'Consulta de catálogo.',
    'INTERNAL',
    NULL,
    NULL,
    NULL
),

(
    'TABLE',
    'product_labels',
    '',
    'Textos normalizados dos rótulos.',
    NULL,
    'PUBLIC',
    'Consulta como informação de catálogo.',
    'INTERNAL',
    NULL,
    NULL,
    NULL
),

(
    'TABLE',
    'packaging',
    '',
    'Informações de embalagem.',
    NULL,
    'PUBLIC',
    'Consulta como informação de catálogo.',
    'INTERNAL',
    NULL,
    NULL,
    NULL
),

(
    'TABLE',
    'product_claims',
    '',
    'Claims associados aos produtos.',
    NULL,
    'PUBLIC',
    'Consulta como informação de catálogo.',
    'INTERNAL',
    NULL,
    NULL,
    NULL
),


(
    'TABLE',
    'ingredients',
    '',
    'Catálogo mestre de ingredientes.',
    'INCI identifica unicamente o ingrediente.',
    'PUBLIC',
    'Consulta pública.',
    'INTERNAL',
    NULL,
    NULL,
    NULL
),

(
    'TABLE',
    'ingredient_aliases',
    '',
    'Nomes alternativos dos ingredientes.',
    NULL,
    'PUBLIC',
    'Consulta pública.',
    'INTERNAL',
    NULL,
    NULL,
    NULL
),

(
    'TABLE',
    'ingredient_effects',
    '',
    'Efeitos documentados dos ingredientes.',
    NULL,
    'AUTHENTICATED',
    'Consulta conforme regras do produto.',
    'INTERNAL',
    NULL,
    NULL,
    NULL
),


(
    'TABLE',
    'profile_tags',
    '',
    'Catálogo de atributos usados na personalização.',
    NULL,
    'PUBLIC',
    'Consulta pública.',
    'PUBLIC',
    NULL,
    NULL,
    NULL
),

(
    'TABLE',
    'claims',
    '',
    'Catálogo de claims.',
    NULL,
    'PUBLIC',
    'Consulta pública.',
    'PUBLIC',
    NULL,
    NULL,
    NULL
),

(
    'TABLE',
    'scoring_models',
    '',
    'Modelos de pontuação.',
    NULL,
    'AUTHENTICATED',
    'Consulta conforme regras do produto.',
    'INTERNAL',
    NULL,
    NULL,
    NULL
),

(
    'TABLE',
    'score_categories',
    '',
    'Categorias dos modelos de score.',
    NULL,
    'AUTHENTICATED',
    'Consulta conforme regras do produto.',
    'INTERNAL',
    NULL,
    NULL,
    NULL
),

(
    'TABLE',
    'product_ingredients',
    '',
    'Relação entre produtos e ingredientes.',
    'Sempre deve referenciar ingrediente existente; position representa a ordem da composição.',
    'PUBLIC',
    'Consulta de catálogo.',
    'INTERNAL',
    NULL,
    NULL,
    NULL
),

(
    'TABLE',
    'product_scores',
    '',
    'Scores calculados dos produtos.',
    NULL,
    'AUTHENTICATED',
    'Consulta conforme regras do produto.',
    'INTERNAL',
    NULL,
    NULL,
    NULL
),

(
    'TABLE',
    'regulations',
    '',
    'Regulamentações utilizadas pelo sistema.',
    NULL,
    'AUTHENTICATED',
    'Consulta conforme regras do produto.',
    'INTERNAL',
    NULL,
    NULL,
    NULL
)

ON CONFLICT (object_type, table_name, column_name)
DO UPDATE SET

    table_description = EXCLUDED.table_description,

    business_rule = EXCLUDED.business_rule,

    access_level = EXCLUDED.access_level,

    access_rule = EXCLUDED.access_rule,

    data_classification = EXCLUDED.data_classification,

    sensitivity_reason = EXCLUDED.sensitivity_reason,

    retention_policy = EXCLUDED.retention_policy,

    notes = EXCLUDED.notes,

    is_active = TRUE,

    updated_at = NOW();


INSERT INTO venus.data_catalog_rules
(
    object_type,
    table_name,
    column_name,
    column_description,
    business_rule,
    access_level,
    access_rule,
    data_classification,
    sensitivity_reason,
    notes
)
VALUES

(
    'COLUMN',
    'user_profiles',
    'hair_pattern',
    'Classificação específica do padrão capilar (1A–4C).',
    'Pode ser nulo em perfis legados; quando preenchido deve ser coerente com hair_type.',
    'OWNER',
    'Somente o próprio usuário.',
    'CONFIDENTIAL',
    'Característica pessoal declarada.',
    NULL
),

(
    'COLUMN',
    'users',
    'firebase_uid',
    'Identificador externo do provedor de autenticação.',
    'Não é senha nem token de sessão.',
    'SYSTEM',
    'Somente backend/autenticação.',
    'RESTRICTED',
    'Identificador vinculado à identidade do usuário.',
    'Não tratar como senha.'
),

(
    'COLUMN',
    'user_profiles',
    'age_range',
    'Faixa etária declarada.',
    'Representa faixa etária e não idade exata.',
    'OWNER',
    'Somente o próprio usuário.',
    'CONFIDENTIAL',
    NULL,
    NULL
),

(
    'COLUMN',
    'user_profiles',
    'gender',
    'Gênero declarado pelo usuário.',
    'Não deve ser inferido pelo sistema.',
    'OWNER',
    'Somente o próprio usuário.',
    'CONFIDENTIAL',
    'Dado pessoal.',
    NULL
),

(
    'COLUMN',
    'user_profiles',
    'skin_type',
    'Tipo de pele declarado.',
    'Não representa diagnóstico médico.',
    'OWNER',
    'Somente o próprio usuário.',
    'CONFIDENTIAL',
    'Informação relacionada à pele.',
    NULL
),

(
    'COLUMN',
    'user_profiles',
    'skin_phototype',
    'Fototipo de pele declarado.',
    'Deve ser tratado como informação declarada.',
    'OWNER',
    'Somente o próprio usuário.',
    'CONFIDENTIAL',
    'Característica pessoal relacionada à pele.',
    NULL
),

(
    'COLUMN',
    'user_profiles',
    'skin_sensitivity',
    'Sensibilidade da pele declarada.',
    'Informação sensível.',
    'OWNER',
    'Somente o próprio usuário.',
    'RESTRICTED',
    'Possível dado relacionado à saúde.',
    NULL
),

(
    'COLUMN',
    'user_profiles',
    'is_pregnant',
    'Indicação declarada de gestação.',
    'Não gera diagnóstico automático.',
    'OWNER',
    'Somente o próprio usuário.',
    'RESTRICTED',
    'Dado sensível relacionado à saúde.',
    NULL
),

(
    'COLUMN',
    'ingredients',
    'inci_name',
    'Nome INCI do ingrediente.',
    'Identidade mestre e única do ingrediente.',
    'PUBLIC',
    'Consulta pública.',
    'INTERNAL',
    NULL,
    'Campo principal de identificação.'
),

(
    'COLUMN',
    'product_ingredients',
    'position',
    'Ordem do ingrediente na composição.',
    'Representa a posição do ingrediente na fórmula.',
    'PUBLIC',
    'Consulta pública.',
    'INTERNAL',
    NULL,
    NULL
),

(
    'COLUMN',
    'compatibility_rules',
    'is_enabled',
    'Indica se uma regra está habilitada.',
    'Somente regras habilitadas devem ser aplicadas.',
    'SYSTEM',
    'Somente backend/admin.',
    'RESTRICTED',
    'Lógica interna do sistema.',
    NULL
),

(
    'COLUMN',
    'compatibility_rules',
    'score_delta',
    'Variação de score causada pela regra.',
    'Utilizada pelo motor de compatibilidade.',
    'SYSTEM',
    'Somente backend/admin.',
    'RESTRICTED',
    'Lógica interna.',
    NULL
),

(
    'COLUMN',
    'compatibility_rules',
    'weight',
    'Peso aplicado pela regra.',
    'Utilizado pelo motor de pontuação.',
    'SYSTEM',
    'Somente backend/admin.',
    'RESTRICTED',
    'Lógica interna.',
    NULL
),

(
    'COLUMN',
    'analysis_results',
    'overall_score',
    'Pontuação geral da análise.',
    'Resultado personalizado e não diagnóstico médico.',
    'OWNER',
    'Somente usuário proprietário.',
    'CONFIDENTIAL',
    NULL,
    NULL
),

(
    'COLUMN',
    'personalized_scores',
    'final_score',
    'Pontuação final personalizada.',
    'Representa compatibilidade e não diagnóstico.',
    'OWNER',
    'Somente usuário proprietário.',
    'CONFIDENTIAL',
    NULL,
    NULL
),

(
    'COLUMN',
    'recommendations',
    'reason',
    'Motivo da recomendação.',
    'Deve refletir os dados e regras que produziram a recomendação.',
    'OWNER',
    'Somente usuário proprietário.',
    'CONFIDENTIAL',
    NULL,
    NULL
)

ON CONFLICT (object_type, table_name, column_name)
DO UPDATE SET
    column_description = EXCLUDED.column_description,
    business_rule = EXCLUDED.business_rule,
    access_level = EXCLUDED.access_level,
    access_rule = EXCLUDED.access_rule,
    data_classification = EXCLUDED.data_classification,
    sensitivity_reason = EXCLUDED.sensitivity_reason,
    notes = EXCLUDED.notes,
    is_active = TRUE,
    updated_at = NOW();



CREATE OR REPLACE FUNCTION venus.sync_data_catalog()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, venus, pg_temp
AS $$

DECLARE

    v_real_tables INTEGER;
    v_catalog_tables INTEGER;

    v_real_columns INTEGER;
    v_catalog_columns INTEGER;

BEGIN


    UPDATE venus.data_catalog
       SET is_active = FALSE,
           updated_at = NOW();



    INSERT INTO venus.data_catalog
    (
        object_type,
        table_name,
        column_name,
        ordinal_position,
        table_description,
        column_description,
        business_rule,
        access_level,
        access_rule,
        data_classification,
        sensitivity_reason,
        retention_policy,
        source_of_definition,
        reviewed_at,
        is_active,
        created_at,
        updated_at
    )

    SELECT

        'TABLE',

        t.table_name,

        '',

        NULL,

        COALESCE
        (
            r.table_description,

            pg_catalog.obj_description
            (
                pg_catalog.format(
                    '%I.%I',
                    t.table_schema,
                    t.table_name
                )::pg_catalog.regclass,

                'pg_class'
            )
        ),

        NULL,

        r.business_rule,

        COALESCE
        (
            r.access_level,
            'AUTHENTICATED'
        ),

        r.access_rule,

        COALESCE
        (
            r.data_classification,
            'INTERNAL'
        ),

        r.sensitivity_reason,

        r.retention_policy,

        'VENUS_SCHEMA',

        NOW(),

        TRUE,

        NOW(),

        NOW()

    FROM information_schema.tables t

    LEFT JOIN venus.data_catalog_rules r
        ON r.object_type = 'TABLE'
       AND r.table_name = t.table_name
       AND r.column_name = ''
       AND r.is_active = TRUE

    WHERE t.table_schema = 'venus'
      AND t.table_type = 'BASE TABLE'


      AND t.table_name NOT IN
      (
          'data_catalog',
          'data_catalog_rules'
      )

    ON CONFLICT
    (
        object_type,
        table_name,
        column_name
    )

    DO UPDATE SET

        ordinal_position =
            EXCLUDED.ordinal_position,

        table_description =
            EXCLUDED.table_description,

        column_description =
            EXCLUDED.column_description,

        business_rule =
            EXCLUDED.business_rule,

        access_level =
            EXCLUDED.access_level,

        access_rule =
            EXCLUDED.access_rule,

        data_classification =
            EXCLUDED.data_classification,

        sensitivity_reason =
            EXCLUDED.sensitivity_reason,

        retention_policy =
            EXCLUDED.retention_policy,

        source_of_definition =
            'VENUS_SCHEMA',

        reviewed_at =
            NOW(),

        is_active =
            TRUE,

        updated_at =
            NOW();



    INSERT INTO venus.data_catalog
    (
        object_type,
        table_name,
        column_name,
        ordinal_position,

        data_type,
        udt_name,

        is_nullable,
        default_value,

        is_primary_key,
        is_foreign_key,

        referenced_table_name,
        referenced_column_name,

        table_description,
        column_description,
        business_rule,

        access_level,
        access_rule,

        data_classification,
        sensitivity_reason,
        retention_policy,

        source_of_definition,
        reviewed_at,
        is_active,

        created_at,
        updated_at
    )

    SELECT

        'COLUMN',

        c.table_name,

        c.column_name,

        c.ordinal_position,

        c.data_type,

        c.udt_name,

        (c.is_nullable = 'YES'),

        c.column_default,


        EXISTS
        (
            SELECT 1

            FROM information_schema.table_constraints tc

            JOIN information_schema.key_column_usage kcu
                ON kcu.constraint_schema = tc.constraint_schema
               AND kcu.constraint_name = tc.constraint_name
               AND kcu.table_schema = tc.table_schema
               AND kcu.table_name = tc.table_name

            WHERE tc.constraint_schema = 'venus'
              AND tc.table_name = c.table_name
              AND tc.constraint_type = 'PRIMARY KEY'
              AND kcu.column_name = c.column_name
        ),


        EXISTS
        (
            SELECT 1

            FROM information_schema.table_constraints tc

            JOIN information_schema.key_column_usage kcu
                ON kcu.constraint_schema = tc.constraint_schema
               AND kcu.constraint_name = tc.constraint_name
               AND kcu.table_schema = tc.table_schema
               AND kcu.table_name = tc.table_name

            WHERE tc.constraint_schema = 'venus'
              AND tc.table_name = c.table_name
              AND tc.constraint_type = 'FOREIGN KEY'
              AND kcu.column_name = c.column_name
        ),

        fk.referenced_table_name,

        COALESCE(fk.referenced_column_name, ''),


        COALESCE
        (
            cr.table_description,

            tr.table_description,

            pg_catalog.obj_description
            (
                pg_catalog.format(
                    '%I.%I',
                    c.table_schema,
                    c.table_name
                )::pg_catalog.regclass,

                'pg_class'
            )
        ),


        COALESCE
        (
            cr.column_description,

            pg_catalog.col_description
            (
                pg_catalog.format(
                    '%I.%I',
                    c.table_schema,
                    c.table_name
                )::pg_catalog.regclass,

                c.ordinal_position
            )
        ),


        COALESCE
        (
            cr.business_rule,

            tr.business_rule
        ),


        COALESCE
        (
            cr.access_level,

            tr.access_level,

            'AUTHENTICATED'
        ),

        COALESCE
        (
            cr.access_rule,

            tr.access_rule
        ),


        COALESCE
        (
            cr.data_classification,

            tr.data_classification,

            'INTERNAL'
        ),

        COALESCE
        (
            cr.sensitivity_reason,

            tr.sensitivity_reason
        ),

        COALESCE
        (
            cr.retention_policy,

            tr.retention_policy
        ),

        'VENUS_SCHEMA',

        NOW(),

        TRUE,

        NOW(),

        NOW()

    FROM information_schema.columns c

    LEFT JOIN venus.data_catalog_rules cr
        ON cr.object_type = 'COLUMN'
       AND cr.table_name = c.table_name
       AND cr.column_name = c.column_name
       AND cr.is_active = TRUE

    LEFT JOIN venus.data_catalog_rules tr
        ON tr.object_type = 'TABLE'
       AND tr.table_name = c.table_name
       AND tr.column_name = ''
       AND tr.is_active = TRUE


    LEFT JOIN LATERAL
    (
        SELECT

            parent.relname
                AS referenced_table_name,

            parent_col.attname
                AS referenced_column_name

        FROM pg_catalog.pg_constraint con

        JOIN pg_catalog.pg_class child
            ON child.oid = con.conrelid

        JOIN pg_catalog.pg_namespace child_ns
            ON child_ns.oid = child.relnamespace

        JOIN pg_catalog.pg_class parent
            ON parent.oid = con.confrelid

        JOIN LATERAL
        (
            SELECT
                ck.attnum,
                ck.ord
            FROM pg_catalog.unnest(con.conkey)
                WITH ORDINALITY AS ck(attnum, ord)
        ) ck
            ON TRUE

        JOIN LATERAL
        (
            SELECT
                fkatt.attnum,
                fkatt.ord
            FROM pg_catalog.unnest(con.confkey)
                WITH ORDINALITY AS fkatt(attnum, ord)
        ) fkatt
            ON fkatt.ord = ck.ord

        JOIN pg_catalog.pg_attribute child_col
            ON child_col.attrelid = child.oid
           AND child_col.attnum = ck.attnum

        JOIN pg_catalog.pg_attribute parent_col
            ON parent_col.attrelid = parent.oid
           AND parent_col.attnum = fkatt.attnum

        WHERE con.contype = 'f'

          AND child_ns.nspname = 'venus'

          AND child.relname = c.table_name

          AND child_col.attname = c.column_name

        LIMIT 1

    ) fk
        ON TRUE

    WHERE c.table_schema = 'venus'

      AND c.table_name NOT IN
      (
          'data_catalog',
          'data_catalog_rules'
      )


    ON CONFLICT
    (
        object_type,
        table_name,
        column_name
    )

    DO UPDATE SET

        ordinal_position =
            EXCLUDED.ordinal_position,

        data_type =
            EXCLUDED.data_type,

        udt_name =
            EXCLUDED.udt_name,

        is_nullable =
            EXCLUDED.is_nullable,

        default_value =
            EXCLUDED.default_value,

        is_primary_key =
            EXCLUDED.is_primary_key,

        is_foreign_key =
            EXCLUDED.is_foreign_key,

        referenced_table_name =
            EXCLUDED.referenced_table_name,

        referenced_column_name =
            EXCLUDED.referenced_column_name,

        table_description =
            EXCLUDED.table_description,

        column_description =
            EXCLUDED.column_description,

        business_rule =
            EXCLUDED.business_rule,

        access_level =
            EXCLUDED.access_level,

        access_rule =
            EXCLUDED.access_rule,

        data_classification =
            EXCLUDED.data_classification,

        sensitivity_reason =
            EXCLUDED.sensitivity_reason,

        retention_policy =
            EXCLUDED.retention_policy,

        source_of_definition =
            'VENUS_SCHEMA',

        reviewed_at =
            NOW(),

        is_active =
            TRUE,

        updated_at =
            NOW();



    SELECT COUNT(*)
      INTO v_real_tables

    FROM information_schema.tables

    WHERE table_schema = 'venus'

      AND table_type = 'BASE TABLE'

      AND table_name NOT IN
      (
          'data_catalog',
          'data_catalog_rules'
      );


    SELECT COUNT(*)
      INTO v_catalog_tables

    FROM venus.data_catalog

    WHERE object_type = 'TABLE'

      AND is_active = TRUE;


    IF v_real_tables <> v_catalog_tables THEN

        RAISE EXCEPTION
            'ERRO NO DATA CATALOG: tabelas reais = %, tabelas catalogadas = %',
            v_real_tables,
            v_catalog_tables;

    END IF;



    SELECT COUNT(*)
      INTO v_real_columns

    FROM information_schema.columns

    WHERE table_schema = 'venus'

      AND table_name NOT IN
      (
          'data_catalog',
          'data_catalog_rules'
      );


    SELECT COUNT(*)
      INTO v_catalog_columns

    FROM venus.data_catalog

    WHERE object_type = 'COLUMN'

      AND is_active = TRUE;


    IF v_real_columns <> v_catalog_columns THEN

        RAISE EXCEPTION
            'ERRO NO DATA CATALOG: colunas reais = %, colunas catalogadas = %',
            v_real_columns,
            v_catalog_columns;

    END IF;


END;
$$;



REVOKE ALL
ON FUNCTION venus.sync_data_catalog()
FROM PUBLIC;


GRANT EXECUTE
ON FUNCTION venus.sync_data_catalog()
TO CURRENT_USER;



CREATE OR REPLACE VIEW venus.v_data_catalog_tables AS

SELECT

    table_name,

    table_description,

    business_rule,

    access_level,

    access_rule,

    data_classification,

    sensitivity_reason,

    retention_policy

FROM venus.data_catalog

WHERE object_type = 'TABLE'

  AND is_active = TRUE

ORDER BY table_name;


CREATE OR REPLACE VIEW venus.v_data_catalog_columns AS

SELECT

    table_name,

    column_name,

    ordinal_position,

    data_type,

    udt_name,

    is_nullable,

    default_value,

    is_primary_key,

    is_foreign_key,

    referenced_table_name,

    referenced_column_name,

    table_description,

    column_description,

    business_rule,

    access_level,

    access_rule,

    data_classification,

    sensitivity_reason,

    retention_policy

FROM venus.data_catalog

WHERE object_type = 'COLUMN'

  AND is_active = TRUE

ORDER BY

    table_name,

    ordinal_position;



INSERT INTO venus.data_catalog_rules(object_type,table_name,column_name,table_description,business_rule,access_level,data_classification,notes) VALUES ('TABLE','user_access_events','','Eventos de atividade do usuário para DAU.','Cada evento pertence a um usuário.','SYSTEM','INTERNAL','Base do monitoramento DAU.') ON CONFLICT(object_type,table_name,column_name) DO UPDATE SET table_description=EXCLUDED.table_description,business_rule=EXCLUDED.business_rule,access_level=EXCLUDED.access_level,data_classification=EXCLUDED.data_classification,notes=EXCLUDED.notes;

SELECT venus.sync_data_catalog();



SELECT
    'TABELAS REAIS' AS tipo,
    COUNT(*) AS quantidade
FROM information_schema.tables
WHERE table_schema = 'venus'
  AND table_type = 'BASE TABLE'
  AND table_name NOT IN
  (
      'data_catalog',
      'data_catalog_rules'
  )

UNION ALL

SELECT
    'TABELAS NO CATALOGO',
    COUNT(*)
FROM venus.data_catalog
WHERE object_type = 'TABLE'
  AND is_active = TRUE

UNION ALL

SELECT
    'COLUNAS REAIS',
    COUNT(*)
FROM information_schema.columns
WHERE table_schema = 'venus'
  AND table_name NOT IN
  (
      'data_catalog',
      'data_catalog_rules'
  )

UNION ALL

SELECT
    'COLUNAS NO CATALOGO',
    COUNT(*)
FROM venus.data_catalog
WHERE object_type = 'COLUMN'
  AND is_active = TRUE;












INSERT INTO venus.data_catalog_rules (
    object_type, table_name, column_name, column_description, business_rule,
    access_level, access_rule, data_classification, sensitivity_reason, notes
) VALUES
('COLUMN','media_assets','public_id','Identificador canônico do asset no Cloudinary.','Gerado/controlado pelo backend e usado para delivery, replace e delete.','SYSTEM','Backend/API gerencia; cliente não escolhe livremente.','INTERNAL',NULL,'Fonte canônica de identidade Cloudinary.'),
('COLUMN','media_assets','asset_id','Identificador imutável do asset no Cloudinary quando disponível.','Persistido para rastreabilidade e reconciliação.','SYSTEM','Backend/API.','INTERNAL',NULL,NULL),
('COLUMN','media_assets','secure_url','URL HTTPS retornada pelo Cloudinary.','Metadado de entrega; pode ser regenerado a partir da identidade do asset.','AUTHENTICATED','API decide quando expor.','INTERNAL',NULL,'Não substitui public_id como identidade.'),
('COLUMN','media_assets','status','Estado do ciclo de vida do asset.','pending/active/deleted/failed controlam consistência entre API, banco e Cloudinary.','SYSTEM','Somente backend/API.','INTERNAL',NULL,NULL)
ON CONFLICT (object_type, table_name, column_name) DO UPDATE SET
    column_description=EXCLUDED.column_description, business_rule=EXCLUDED.business_rule, access_level=EXCLUDED.access_level,
    access_rule=EXCLUDED.access_rule, data_classification=EXCLUDED.data_classification, notes=EXCLUDED.notes,
    is_active=TRUE, updated_at=NOW();

SELECT venus.sync_data_catalog();
