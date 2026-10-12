# Carga de evidências oficiais para os quatro eixos de ingredientes

O script `ops/load_official_ingredient_risk_v2.py` foi criado para impedir
que a ausência de informação seja convertida em risco `0`. Ele trabalha com a
metodologia `v2` já registrada no banco:

- irritação e comedogenicidade: `0` é menor risco e `10` é maior risco;
- biodegradabilidade: `0` é baixa biodegradabilidade/persistência e `10` é
  alta biodegradabilidade;
- ambiental: `0` é menor risco identificado e `10` é maior risco.

## Fontes e limites

Use o painel oficial de nomenclatura da [Anvisa](https://www.gov.br/anvisa/pt-br/assuntos/cosmeticos/traducao)
e o [CosIng da Comissão Europeia](https://single-market-economy.ec.europa.eu/sectors/cosmetics/cosmetic-ingredient-database_en)
para resolver o INCI e localizar restrições, funções e referências. Eles não
devem ser tratados, isoladamente, como quatro scores de risco.

Para evidência específica, priorize:

- [opiniões do SCCS](https://health.ec.europa.eu/scientific-committees/scientific-committee-consumer-safety-sccs/sccs-opinions_en)
  ou uma conclusão regulatória específica para irritação/sensibilização;
- estudo direto e identificável, indexado em [PubMed](https://pubmed.ncbi.nlm.nih.gov/)
  ou por [DOI](https://doi.org/), para comedogenicidade;
- [ECHA — informação sobre substâncias](https://echa.europa.eu/information-on-chemicals)
  e dados REACH/OECD para biodegradação, persistência e destino ambiental;
- dados ECHA/CLP, PBT/vPvB ou ecotoxicidade para o eixo ambiental.

Uma restrição, uma função cosmética, o fato de o ingrediente ser natural ou a
ausência de restrição não produzem score automaticamente. A linha precisa
informar a evidência, o localizador (seção, registro, opinião, endpoint ou
DOI), o nível da evidência e a justificativa do mapeamento para `0..10`.

## Fluxo seguro

1. Gere o template:

   ```powershell
   python ops/load_official_ingredient_risk_v2.py export
   ```

2. Preencha as quatro linhas de cada ingrediente usando evidência específica.
   `evidence_excerpt` deve registrar a conclusão relevante, sem substituir a
   fonte original. Para `score=0`, preencha também `zero_basis` para deixar
   claro que o zero é uma conclusão avaliada, não ausência de dado.

3. Valide sem tocar no banco:

   ```powershell
   python ops/load_official_ingredient_risk_v2.py validate `
     --input data/official_risk_evidence_v2.csv
   ```

4. Só depois aplique em `Venus-qa`:

   ```powershell
   python ops/load_official_ingredient_risk_v2.py apply `
     --input data/official_risk_evidence_v2.csv
   ```

O importador exige quatro dimensões por ingrediente, fonte HTTPS permitida,
nível `medium`, `high` ou `very_high`, justificativa e versão `v2`. Ele grava
as avaliações em `venus.ingredient_risk_assessments`, sincroniza os quatro
campos de `venus.ingredients` e deixa os demais ingredientes pendentes. A API
de classificação não é chamada.
