UNWIND $produtos AS a
MATCH (pa:Produto {id: a.id})-[:CONTEM]->(:Ingrediente)-[:E_DO_TIPO]->(t:TipoAtivo)
      -[r:PRECISA_DE]->(falta:TipoAtivo)
WITH DISTINCT a, pa, t, r, falta
WHERE NOT EXISTS {
  MATCH (pb:Produto)-[:CONTEM]->(:Ingrediente)-[:E_DO_TIPO]->(falta)
  WHERE pb.id IN CASE r.periodo WHEN 'manha' THEN $ids_manha WHEN 'noite' THEN $ids_noite ELSE $ids_todos END
}
RETURN DISTINCT a.periodo AS periodo, pa.nome AS nome, t.nome AS tipo,
       falta.nome AS precisa_de, r.periodo AS periodo_exigido, r.motivo AS motivo, r.fonte AS fonte;
