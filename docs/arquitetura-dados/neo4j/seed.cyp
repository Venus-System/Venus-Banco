WITH 'demo-checkup-v1' AS rodada
FOREACH (l IN [
  {id:900001, nome:'DEMO Sérum A', categoria:'Serum'},
  {id:900002, nome:'DEMO Sérum A similar', categoria:'Serum'},
  {id:900003, nome:'DEMO Loção B', categoria:'Locao'},
  {id:900004, nome:'DEMO Protetor', categoria:'Protetor solar'}
] |
  MERGE (p:Produto {id:l.id})
  SET p.nome=l.nome, p.categoria=l.categoria, p.rodada=rodada
)
FOREACH (l IN [
  {id:900001, inci:'DEMO BASE 1', nome:'Base fictícia 1'},
  {id:900002, inci:'DEMO BASE 2', nome:'Base fictícia 2'},
  {id:900003, inci:'DEMO ACTIVE A', nome:'Ativo fictício A'},
  {id:900004, inci:'DEMO ACTIVE B', nome:'Ativo fictício B'},
  {id:900005, inci:'DEMO UV FILTER', nome:'Filtro fictício'}
] |
  MERGE (i:Ingrediente {id:l.id})
  SET i.inci=l.inci, i.nome=l.nome, i.rodada=rodada
)
FOREACH (nome IN ['DEMO Ativo A', 'DEMO Ativo B', 'Filtro UV'] |
  MERGE (t:TipoAtivo {nome:nome}) SET t.rodada=rodada
)
MERGE (u:Usuario {id:900001}) SET u.rodada=rodada
WITH rodada, u
MATCH (a:Produto {id:900001}), (similar:Produto {id:900002}),
      (b:Produto {id:900003}), (solar:Produto {id:900004}),
      (base1:Ingrediente {id:900001}), (base2:Ingrediente {id:900002}),
      (ia:Ingrediente {id:900003}), (ib:Ingrediente {id:900004}),
      (iuv:Ingrediente {id:900005}),
      (ta:TipoAtivo {nome:'DEMO Ativo A'}),
      (tb:TipoAtivo {nome:'DEMO Ativo B'}), (uv:TipoAtivo {nome:'Filtro UV'})
FOREACH (p IN [a, similar] |
  MERGE (p)-[r1:CONTEM]->(base1) SET r1.posicao=1, r1.rodada=rodada
  MERGE (p)-[r2:CONTEM]->(base2) SET r2.posicao=2, r2.rodada=rodada
  MERGE (p)-[r3:CONTEM]->(ia) SET r3.posicao=3, r3.rodada=rodada
)
MERGE (b)-[cb:CONTEM]->(ib) SET cb.posicao=1, cb.rodada=rodada
MERGE (solar)-[cs:CONTEM]->(iuv) SET cs.posicao=1, cs.rodada=rodada
MERGE (ia)-[ea:E_DO_TIPO]->(ta) SET ea.rodada=rodada
MERGE (ib)-[eb:E_DO_TIPO]->(tb) SET eb.rodada=rodada
MERGE (iuv)-[eu:E_DO_TIPO]->(uv) SET eu.rodada=rodada
FOREACH (p IN [a, b, solar] |
  MERGE (u)-[f:FAVORITOU]->(p) SET f.rodada=rodada
)
MERGE (ta)-[c:CONFLITA_COM]->(tb)
SET c.severidade='demonstracao', c.motivo='DEMO: incompatibilidade fictícia A/B.',
    c.fonte='fixture local; sem validade clínica', c.revisado=false, c.rodada=rodada
MERGE (ta)-[f:PRECISA_DE]->(uv)
SET f.periodo='manha', f.motivo='DEMO: A exige filtro UV na rotina da manhã.',
    f.fonte='fixture local; sem validade clínica', f.revisado=false, f.rodada=rodada
MERGE (ta)-[o:VEM_ANTES_DE]->(tb)
SET o.motivo='DEMO: A deve vir antes de B.',
    o.fonte='fixture local; sem validade clínica', o.revisado=false, o.rodada=rodada
RETURN rodada, 'Carga demonstrativa concluída' AS resultado;
