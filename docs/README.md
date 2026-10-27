# Documentação do Venus-Banco

Este diretório é a entrada única para entender a arquitetura de dados do
Venus. A documentação separa o que foi validado no PostgreSQL de QA do que foi
fornecido como script de apoio para MongoDB e Neo4j.

## Comece por aqui

1. [`ARQUITETURA.md`](ARQUITETURA.md) — fluxo ponta a ponta, limites de cada
   sistema e responsabilidades.
2. [`arquitetura-dados/README.md`](arquitetura-dados/README.md) — mapa por
   tecnologia: SQL, MongoDB, Neo4j, Redis, OCR, Cloudinary e Databricks.
3. [`OPERACAO.md`](OPERACAO.md) — instalação, execução segura e validações.
4. [`database-logical-model.md`](database-logical-model.md) — snapshot completo
   do PostgreSQL real, gerado somente por metadados.
5. [`modelos lógicos/README.md`](<modelos lógicos/README.md>) — fontes editáveis
   do brModelo e prévias dos diagramas.

## Índice por assunto

| Assunto | Documento principal |
|---|---|
| PostgreSQL, schemas, tabelas e FKs | [`arquitetura-dados/sql/`](<arquitetura-dados/sql/>) e [`database-logical-model.md`](database-logical-model.md) |
| OCR e revisão administrativa | [`arquitetura-dados/ocr/`](<arquitetura-dados/ocr/>) |
| Estado bruto de scans | [`arquitetura-dados/mongodb/`](<arquitetura-dados/mongodb/>) |
| Grafo de compatibilidade | [`arquitetura-dados/neo4j/`](<arquitetura-dados/neo4j/>) |
| Cache/eventos Redis | [`arquitetura-dados/redis/`](<arquitetura-dados/redis/>) |
| Views analíticas e Databricks | [`arquitetura-dados/databricks/`](<arquitetura-dados/databricks/>) |
| Imagens e metadados de mídia | [`arquitetura-dados/cloudinary/`](<arquitetura-dados/cloudinary/>) |
| Decisões de scoring e evidência | [`decisoes/`](decisoes/) |
| Runbooks operacionais | [`runbooks/`](runbooks/) |
| Contexto histórico | [`historico/`](historico/) |
| ETL de ingredientes | [`../data/ETL_INGREDIENTES/README.md`](../data/ETL_INGREDIENTES/README.md) |
| Backup e recuperação | [`../BACKUP_RECOVERY.md`](../BACKUP_RECOVERY.md) |
| Cardinalidades | [`../MODEL_CARDINALIDADES.md`](../MODEL_CARDINALIDADES.md) |

## Regra de evidência

- **Validado:** o PostgreSQL é consultado em transação `READ ONLY`; os números
  publicados nesta documentação vêm do banco `Venus-qa`.
- **Fonte do repositório:** scripts e SQL presentes no Git ou no pacote
  `Banco_de_dados.zip` fornecido para esta documentação.
- **Não evidenciado:** uma tecnologia sem código, configuração ou conexão
  disponível não deve ser descrita como se estivesse em produção.

As páginas específicas identificam explicitamente essas três situações.
