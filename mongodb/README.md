# MongoDB — `scan_sessions`

## Papel

O MongoDB armazena o documento de captura antes da projeção relacional. A
coleção documentada é `scan_sessions`; cada documento reúne imagens, OCR,
interpretação, revisão administrativa e o estado de sincronização com
PostgreSQL.

## Contrato resumido

- Identidade: `scan_id` público com prefixo `VS-`.
- Estados: `pending_review`, `in_review`, `approved`, `rejected`,
  `sync_failed`, `synced`.
- Entrada: `source`, `device`, `workflow`, `quality_check`, `images` e `ocr`.
- Interpretação: correspondência de produto, marca, categoria e claims.
- Revisão: decisão, responsável, fila, histórico e motivo de rejeição.
- Projeção: `postgres_projection.ready_to_sync` e erros de validação.
- Sincronização: `postgres_sync.status`, `idempotency_key`, tentativas e erro.

O MongoDB mantém o contexto do scan. O PostgreSQL valida e persiste o catálogo
operacional; uma decisão aprovada não deve ignorar as FKs, checks e regras de
prontidão do SQL.

## Arquivos incorporados

- `validation.js`: validador JSON Schema da coleção.
- `indexes_novo.js`: índices de fila, usuário, sincronização e produto.
- `seed.js`: documentos demonstrativos idempotentes.
- `consultas.js`: consultas operacionais para revisão e sincronização.

Os arquivos foram copiados do `Banco_de_dados.zip` fornecido e preservados como
referência. Eles não foram executados nesta revisão, conforme a regra de validar
diretamente apenas o SQL.

## Observações para execução

`validation.js` usa a variável `nomeDB`; defina-a no contexto do `mongosh` antes
de executar o script, por exemplo `const nomeDB = "venus_scan"`. Valide também
se o nome do banco e a autenticação correspondem ao ambiente escolhido.
