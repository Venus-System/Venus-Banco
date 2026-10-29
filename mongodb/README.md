# MongoDB

## Documentação

- [`scan_sessions.md`](scan_sessions.md): coleção `scan_sessions` no formato
  gravado pelo Venus-CRUD (captura do rótulo, ingredientes, revisão, retrato
  aprovado e sincronização com o PostgreSQL).
- [`historico.md`](historico.md): coleções do chatbot (`checkpoints`,
  `checkpoint_writes`, `memorias_longo_prazo`, `metricas_requisicoes` e
  `limites_chat`), gravadas pelo Venus-AI-Sdk e pelo Venus-AI-api.

## Papel

O MongoDB armazena o documento de captura antes da projeção relacional e o
estado do chatbot. Na coleção `scan_sessions`, cada documento reúne imagens,
OCR, ingredientes, revisão e o estado de sincronização com PostgreSQL.

## Contrato do validador (`validation.js`)

O resumo abaixo descreve o validador copiado do `Banco_de_dados.zip`. O
Venus-CRUD grava outro formato (`ingredients` na raiz, `review`,
`approved_snapshot` e `sync`), descrito em `scan_sessions.md`; com este
validador ativo na coleção, o insert do CRUD seria recusado.

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
