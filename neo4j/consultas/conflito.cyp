UNWIND $produtos AS a
UNWIND $produtos AS b
WITH a, b
WHERE a.id < b.id AND a.periodo = b.periodo
MATCH (pa:Produto {id: a.id})-[:CONTEM]->(:Ingrediente)-[:E_DO_TIPO]->(ta:TipoAtivo)
MATCH (pb:Produto {id: b.id})-[:CONTEM]->(:Ingrediente)-[:E_DO_TIPO]->(tb:TipoAtivo)
MATCH (ta)-[r:CONFLITA_COM]-(tb)
RETURN DISTINCT a.periodo AS periodo,
       pa.nome AS nome_a, ta.nome AS tipo_a,
       pb.nome AS nome_b, tb.nome AS tipo_b,
       r.severidade AS severidade, r.motivo AS motivo, r.fonte AS fonte;
