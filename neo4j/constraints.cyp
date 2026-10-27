CREATE CONSTRAINT produto_id IF NOT EXISTS
FOR (p:Produto)
REQUIRE p.id IS UNIQUE

CREATE CONSTRAINT ingrediente_id IF NOT EXISTS
FOR (i:Ingrediente)
REQUIRE i.id IS UNIQUE

CREATE CONSTRAINT usuario_id IF NOT EXISTS
FOR (u:Usuario)
REQUIRE u.id IS UNIQUE

CREATE CONSTRAINT tipo_nome IF NOT EXISTS
FOR (t:TipoAtivo)
REQUIRE p.id IS UNIQUE





CREATE CONSTRAINT produto_id_obrigatorio IF NOT EXISTS
FOR (p:Produto)
REQUIRE p.id IS NOT NULL;

CREATE CONSTRAINT ingrediente_id_obrigatorio IF NOT EXISTS
FOR (i:Ingrediente)
REQUIRE i.id IS NOT NULL;

CREATE CONSTRAINT usuario_id_obrigatorio IF NOT EXISTS
FOR (u:Usuario)
REQUIRE u.id IS NOT NULL;

CREATE CONSTRAINT tipo_nome_obrigatorio IF NOT EXISTS
FOR (t:TipoAtivo)
REQUIRE t.nome IS NOT NULL;




CREATE CONSTRAINT produto_rodada_obrigatoria IF NOT EXISTS
FOR (p:Produto)
REQUIRE p.rodada IS NOT NULL;

CREATE CONSTRAINT ingrediente_rodada_obrigatoria IF NOT EXISTS
FOR (i:Ingrediente)
REQUIRE i.rodada IS NOT NULL;

CREATE CONSTRAINT usuario_rodada_obrigatoria IF NOT EXISTS
FOR (u:Usuario)
REQUIRE u.rodada IS NOT NULL;

CREATE CONSTRAINT tipo_rodada_obrigatoria IF NOT EXISTS
FOR (t:TipoAtivo)
REQUIRE t.rodada IS NOT NULL;




CREATE CONSTRAINT contem_rodada_obrigatoria IF NOT EXISTS
FOR ()-[r:CONTEM]-()
REQUIRE r.rodada IS NOT NULL;

CREATE CONSTRAINT favoritou_rodada_obrigatoria IF NOT EXISTS
FOR ()-[r:FAVORITOU]-()
REQUIRE r.rodada IS NOT NULL;

CREATE CONSTRAINT e_do_tipo_rodada_obrigatoria IF NOT EXISTS
FOR ()-[r:E_DO_TIPO]-()
REQUIRE r.rodada IS NOT NULL;

CREATE CONSTRAINT conflita_com_rodada_obrigatoria IF NOT EXISTS
FOR ()-[r:CONFLITA_COM]-()
REQUIRE r.rodada IS NOT NULL;

CREATE CONSTRAINT precisa_de_rodada_obrigatoria IF NOT EXISTS
FOR ()-[r:PRECISA_DE]-()
REQUIRE r.rodada IS NOT NULL;

CREATE CONSTRAINT vem_antes_de_rodada_obrigatoria IF NOT EXISTS
FOR ()-[r:VEM_ANTES_DE]-()
REQUIRE r.rodada IS NOT NULL;
