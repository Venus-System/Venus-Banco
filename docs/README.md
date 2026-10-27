# Documentação do Venus-Banco

Este diretório reúne a documentação transversal do repositório. Cada tecnologia
também possui uma pasta de primeiro nível com seus scripts e seu contrato:
`sql/`, `mongodb/`, `neo4j/`, `redis/`, `databricks/`, `ocr/` e `cloudinary/`.

## Comece por aqui

1. [`ARQUITETURA.md`](ARQUITETURA.md) — fluxo ponta a ponta e limites de cada
   sistema.
2. [`arquitetura-dados/README.md`](arquitetura-dados/README.md) — mapa visual
   da arquitetura e das integrações.
3. [`OPERACAO.md`](OPERACAO.md) — instalação, execução segura e validações.
4. [`database-logical-model.md`](database-logical-model.md) — snapshot completo
   do PostgreSQL real, gerado por metadados.
5. [`modelos lógicos/README.md`](<modelos lógicos/README.md>) — fontes editáveis
   do brModelo e prévias dos diagramas.

## Índice por tecnologia

| Tecnologia | Pasta principal |
|---|---|
| PostgreSQL / SQL | [`../sql/README.md`](../sql/README.md) |
| MongoDB / scans OCR | [`../mongodb/README.md`](../mongodb/README.md) |
| Neo4j / grafo | [`../neo4j/README.md`](../neo4j/README.md) |
| Redis | [`../redis/README.md`](../redis/README.md) |
| Databricks / consumo BI | [`../databricks/README.md`](../databricks/README.md) |
| OCR | [`../ocr/README.md`](../ocr/README.md) |
| Cloudinary / mídia | [`../cloudinary/README.md`](../cloudinary/README.md) |

## Índice por assunto

| Assunto | Documento principal |
|---|---|
| Decisões de scoring e evidência | [`decisoes/`](decisoes/) |
| Runbooks operacionais | [`runbooks/`](runbooks/) |
| Contexto histórico | [`historico/`](historico/) |
| Modelos lógicos e cardinalidades | [`modelos lógicos/`](<modelos lógicos/>) |
| Backup e recuperação | [`BACKUP_RECOVERY.md`](BACKUP_RECOVERY.md) |
| Auditoria de escopo e evidências | [`AUDIT_DECISIONS.md`](AUDIT_DECISIONS.md) |
| ETL de ingredientes | [`../data/ETL_INGREDIENTES/README.md`](../data/ETL_INGREDIENTES/README.md) |

## Regra de evidência

- **Validado:** o PostgreSQL é consultado em transação `READ ONLY`; os números
  publicados nesta documentação vêm do banco `Venus-qa`.
- **Fonte do repositório:** scripts e SQL presentes no Git ou no pacote
  `Banco_de_dados.zip` fornecido para esta documentação.
- **Não evidenciado:** uma tecnologia sem código, configuração ou conexão
  disponível não deve ser descrita como se estivesse em produção.

As páginas específicas identificam explicitamente essas três situações.
