# OCR e projeção de catálogo

## Fluxo documentado

1. Web/mobile envia a imagem para o fluxo de upload assinado.
2. OCR extrai texto de frente/verso e registra qualidade, texto bruto e
   ingredientes candidatos.
3. O documento fica em MongoDB como `scan_sessions`.
4. O resolvedor tenta encontrar produto, marca, categoria, claims e ingredientes
   por nome, INCI e aliases.
5. Casos ambíguos entram em revisão administrativa.
6. Uma projeção aprovada prepara o payload relacional e uma chave idempotente.
7. PostgreSQL valida composição, FKs, status e regras de prontidão antes de
   promover a versão do produto.
8. As tabelas operacionais alimentam scoring, recomendações e `venus_bi`.

## Evidência no repositório

- O contrato de documento e os estados estão em
  [`mongodb/README.md`](../mongodb/README.md) e `mongodb/validation.js`.
- A resolução relacional está representada por migrations como
  `sql/migrations/20261010_002_ocr_auto_resolution_and_relaxed_gate.sql`.
- A análise de pendências e melhorias está em
  [`../../decisoes/OCR_MELHORIAS_E_CORRECOES.md`](../../decisoes/OCR_MELHORIAS_E_CORRECOES.md).
- O banco mantém `product_labels`, `product_ingredients`,
  `product_ingredient_resolution_issues` e `product_composition_receipts` para
  rastreabilidade do caminho OCR → catálogo.

Não há neste repositório o worker de OCR nem um conector MongoDB → PostgreSQL.
Essas partes devem ser consideradas interfaces documentadas, não código
executável deste pacote.
