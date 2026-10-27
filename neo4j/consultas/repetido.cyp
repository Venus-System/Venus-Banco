UNWIND $produtos AS a
UNWIND $produtos AS b
WITH a, b
WHERE a.id < b.id AND a.periodo = b.periodo
MATCH (pa:Produto {id: a.id})
MATCH (pb:Produto {id: b.id})
WHERE pa.categoria = pb.categoria
WITH a, pa, pb,
     [(pa)-[:CONTEM]->(i:Ingrediente) | i.id] AS ia,
     [(pb)-[:CONTEM]->(j:Ingrediente) | j.id] AS ib
WITH a, pa, pb, ia, ib, size([x IN ia WHERE x IN ib]) AS comuns
WITH a, pa, pb, comuns, size(ia) + size(ib) - comuns AS total
WHERE total > 0 AND toFloat(comuns) / total >= $semelhanca_minima
RETURN a.periodo AS periodo, pa.nome AS nome_a, pb.nome AS nome_b, pa.categoria AS categoria,
       round(toFloat(comuns) / total, 2) AS semelhanca;
