
WITH $dados AS dados, $rodada AS rodada
CALL {
  WITH dados, rodada
  UNWIND dados.produtos AS l
  MERGE (p:Produto {id: l.id}) SET p.nome = l.nome, p.categoria = l.categoria, p.rodada = rodada
  RETURN count(*) AS produtos_gravados
}
CALL {
  WITH dados, rodada
  UNWIND dados.ingredientes AS l
  MERGE (i:Ingrediente {id: l.id}) SET i.inci = l.inci, i.nome = l.nome, i.rodada = rodada
  RETURN count(*) AS ingredientes_gravados
}
CALL {
  WITH dados, rodada
  UNWIND dados.tipos AS nome MERGE (t:TipoAtivo {nome: nome}) SET t.rodada = rodada
  RETURN count(*) AS tipos_gravados
}
CALL {
  WITH dados, rodada
  UNWIND dados.usuarios AS id MERGE (u:Usuario {id: id}) SET u.rodada = rodada
  RETURN count(*) AS usuarios_gravados
}
CALL {
  WITH dados, rodada
  UNWIND dados.composicao AS l
  MATCH (p:Produto {id: l.produto})
  MATCH (i:Ingrediente {id: l.ingrediente})
  MERGE (p)-[c:CONTEM]->(i) SET c.posicao = l.posicao, c.rodada = rodada
  RETURN count(*) AS composicao_gravados
}
CALL {
  WITH dados, rodada
  UNWIND dados.favoritos AS l
  MATCH (u:Usuario {id: l.usuario})
  MATCH (p:Produto {id: l.produto})
  MERGE (u)-[f:FAVORITOU]->(p) SET f.rodada = rodada
  RETURN count(*) AS favoritos_gravados
}
CALL {
  WITH dados, rodada
  UNWIND dados.tipos_ingredientes AS l
  MATCH (i:Ingrediente {id: l.ingrediente})
  MATCH (t:TipoAtivo {nome: l.tipo})
  MERGE (i)-[e:E_DO_TIPO]->(t) SET e.rodada = rodada
  RETURN count(*) AS tipos_ingredientes_gravados
}
CALL {
  WITH dados, rodada
  UNWIND dados.conflita_com AS l
  MATCH (a:TipoAtivo {nome: l.tipo})
  MATCH (b:TipoAtivo {nome: l.outro_tipo})
  MERGE (a)-[r:CONFLITA_COM]->(b)
  SET r.periodo = l.periodo, r.severidade = l.severidade, r.motivo = l.motivo, r.fonte = l.fonte,
      r.revisado = l.revisado, r.rodada = rodada
  RETURN count(*) AS conflita_com_gravados
}
CALL {
  WITH dados, rodada
  UNWIND dados.precisa_de AS l
  MATCH (a:TipoAtivo {nome: l.tipo})
  MATCH (b:TipoAtivo {nome: l.outro_tipo})
  MERGE (a)-[r:PRECISA_DE]->(b)
  SET r.periodo = l.periodo, r.severidade = l.severidade, r.motivo = l.motivo, r.fonte = l.fonte,
      r.revisado = l.revisado, r.rodada = rodada
  RETURN count(*) AS precisa_de_gravados
}
CALL {
  WITH dados, rodada
  UNWIND dados.vem_antes_de AS l
  MATCH (a:TipoAtivo {nome: l.tipo})
  MATCH (b:TipoAtivo {nome: l.outro_tipo})
  MERGE (a)-[r:VEM_ANTES_DE]->(b)
  SET r.periodo = l.periodo, r.severidade = l.severidade, r.motivo = l.motivo, r.fonte = l.fonte,
      r.revisado = l.revisado, r.rodada = rodada
  RETURN count(*) AS vem_antes_de_gravados
}
RETURN
  produtos_gravados,
  ingredientes_gravados,
  tipos_gravados,
  usuarios_gravados,
  composicao_gravados,
  favoritos_gravados,
  tipos_ingredientes_gravados,
  conflita_com_gravados,
  precisa_de_gravados,
  vem_antes_de_gravados;
