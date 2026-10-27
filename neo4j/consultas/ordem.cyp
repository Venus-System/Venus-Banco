UNWIND $produtos AS a
UNWIND $produtos AS b
WITH a, b
WHERE a.periodo = b.periodo AND a.ordem > b.ordem
MATCH (pa:Produto {id: a.id})-[:CONTEM]->(:Ingrediente)-[:E_DO_TIPO]->(ta:TipoAtivo)
      -[r:VEM_ANTES_DE]->(tb:TipoAtivo)<-[:E_DO_TIPO]-(:Ingrediente)<-[:CONTEM]-(pb:Produto {id: b.id})
RETURN DISTINCT a.periodo AS periodo, pa.nome AS aplicar_primeiro, ta.nome AS tipo_primeiro,
       pb.nome AS aplicar_depois, tb.nome AS tipo_depois, r.motivo AS motivo, r.fonte AS fonte;
