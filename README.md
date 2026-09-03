# Venus — PostgreSQL Bootstrap Unificado

Este pacote substitui a sequência histórica de scripts por um bootstrap único e reproduzível.

## Execução

1. Crie um banco PostgreSQL vazio para o Venus. O banco legado **já existente** permanece fora deste pacote.
2. Copie `.env.example` para `.env`.
3. Preencha `DATABASE_URL` com a URL do novo banco Venus.
4. Se for executar a integração com o legado, preencha também `LEGACY_DATABASE_URL`, `LEGACY_PRODUCTS_QUERY` e `LEGACY_USERS_QUERY`.
5. Instale dependências:

```bash
python -m pip install -r requirements.txt
```

6. Execute:

```bash
python pipeline.py
```

O pipeline carrega `.env` automaticamente. Os argumentos `--database-url`, `--legacy-database-url` e as queries continuam disponíveis como override para automação.

O pipeline usa `.env` como configuração padrão. A parte do banco Venus executa em uma transação única; a conexão com o legado é externa e somente de leitura durante a extração, enquanto o destino RPA participa da transação do Venus. Se uma etapa do alvo falhar, ocorre rollback.

### Opções

`--policy standard` mantém ingredientes com evidência cosmética por categoria, função histórica, efeitos ou regulação. `--policy strict` remove a evidência histórica isolada.

`--reset` reconstrói apenas `venus`, `venus_audit`, `venus_bi`, `venus_rpa` e `venus_optimization`. É destrutivo e deve ser usado somente para recriar o ambiente.

`--skip-demo`, `--skip-bi` e `--skip-rpa` tornam partes opcionais. Para a aplicação completa com integração legada, preencha `LEGACY_DATABASE_URL` e as queries no `.env`.

## Arquitetura canônica

- `sql/00_schema.sql`: tipos, tabelas, FKs, índices, funções, triggers e auditoria.
- `sql/05_cloudinary_images.sql`: catálogo canônico de mídia, views e sincronização de metadados Cloudinary; imagens nunca são armazenadas no PostgreSQL.
- `sql/10_reference_seed.sql`: categorias, tags, claims, modelos e demais dados mestres.
- `sql/20_regulation_seed.sql`: regulações.
- `data/venus_v12_load.sql`: fonte grande de ingredientes. O pipeline faz parser, limpeza e resolução de referências em memória.
- `sql/30_demo_seed.sql`: dados técnicos reproduzíveis para desenvolvimento/testes.
- `sql/40_data_catalog.sql`: catálogo técnico de tabelas, colunas e regras.
- `sql/50_bi.sql`: views dimensionais + CTE/window analytics.
- `sql/60_rpa.sql`: controle/staging do RPA no banco novo; não cria o legado.
- `rpa_migrate.py`: extrai do legado externo e carrega `venus.*`.
- `cloudinary_service.py`: geração de assinaturas de upload e operações backend-only do Cloudinary; o `api_secret` nunca é enviado a web/mobile.

## Correções consolidadas

A versão unificada removeu `product_images`, `scan_sessions`, `routines`, `routine_items` e os tipos/funções exclusivos dessas estruturas. `analysis_results` não depende mais de scan session. Credenciais por senha não são adicionadas a `venus.users`; o modelo atual usa `firebase_uid`. A auditoria é mantida separada em `venus_audit`.

Também foram incorporadas as correções de `venus_fix_fk_e_is_active.sql` e `venus_status_fn.sql`: FKs de perfil corrigidas, `is_active`/`updated_at` em `user_profile_tags`, sincronização de status, exatamente um scoring model ativo, uma versão current por produto e transições válidas de `analysis_results.status`.

O catálogo foi ajustado para que `column_name=''` represente linhas de tabela. Isso faz a chave única funcionar de fato no PostgreSQL; `NULL` em uma coluna de chave UNIQUE permitiria duplicatas em sincronizações sucessivas.

## Arquivos históricos descartados do runtime

Foram excluídos do caminho de execução: `1ano_venus_banco.sql`, `venusbackup.sql`, `venus_desligar_tabelas.sql`, `venus_carga_complementar_usuarios_testes.sql`, snapshots JSONL/CSV gerados, manifests de execuções anteriores e o script de benchmark `venus_explain_index_finished.sql`. Eles são históricos/diagnósticos, não são necessários para criar um ambiente novo.

O modelo lógico `.brM3` também ficou fora do pacote executável por conter estruturas antigas que conflitam com o schema canônico.

## Documentação do ETL de ingredientes

A pasta `data/ETL_INGREDIENTES/` documenta a cadeia que produziu o grande SQL de carga e a redução dos 26.045 candidatos ao conjunto histórico de 7.923 ingredientes. Ela contém a planilha ANVISA utilizada, evidências de QA, contagens, decisões de limpeza e o procedimento de reprodução envolvendo ANVISA, UE/CosIng e PubChem.

## Imagens / Cloudinary

A integração usa Cloudinary como armazenamento externo de imagens. O banco guarda apenas metadados em `venus.media_assets`; essa é a única fonte de verdade de mídia e não existem colunas duplicadas de Cloudinary em `users`/`product_versions`. Para web/mobile, o fluxo recomendado é upload direto assinado: a API autentica o usuário, gera `timestamp` + `signature`, o cliente envia a imagem ao Cloudinary e depois a API registra a resposta validada. O segredo `CLOUDINARY_API_SECRET` permanece somente no backend. Veja `CLOUDINARY_API.md` para o contrato da API e regras de segurança.

## Pré-requisitos

- PostgreSQL acessível (local ou remoto) com permissão para criar schemas (`venus`, `venus_audit`, `venus_bi`, `venus_rpa`, `venus_optimization`).
- Python 3.10+ com `pip`.
- Conta Cloudinary (cloud name, API key e API secret) se a etapa de imagens for utilizada.
- Acesso ao banco legado (opcional) somente se a integração RPA for executada; o pacote nunca cria ou simula esse banco.

## Estrutura do projeto

```text
venus_postgres_pipeline_unificado/
├── pipeline.py                 # orquestrador principal do bootstrap
├── rpa_migrate.py               # extração do legado externo -> venus.*
├── cloudinary_service.py        # assinatura de upload e operações Cloudinary backend-only
├── diagnostico_postgres.py      # utilitário de diagnóstico da conexão/estado do banco
├── requirements.txt             # dependências Python
├── .env.example                 # modelo de variáveis de ambiente (copiar para .env)
├── rpa_queries.example.sql      # exemplos de queries de extração do legado
├── data/
│   ├── venus_v12_load.sql       # carga bruta de ingredientes (fonte para o pipeline)
│   └── ETL_INGREDIENTES/        # documentação completa do ETL que originou a carga
├── sql/                         # scripts SQL executados pelo pipeline, em ordem numérica
└── ops/                         # scripts PowerShell de backup/restore
```

## Variáveis de ambiente

| Variável | Obrigatória | Descrição |
|---|---|---|
| `DATABASE_URL` | Sim | URL de conexão do banco Venus (novo, vazio). |
| `LEGACY_DATABASE_URL` | Não | URL do banco legado externo, somente leitura durante a extração RPA. |
| `LEGACY_PRODUCTS_QUERY` | Não | Query que retorna os produtos do legado com os aliases esperados por `rpa_migrate.py`. |
| `LEGACY_USERS_QUERY` | Não | Query que retorna os usuários do legado com os aliases esperados por `rpa_migrate.py`. |
| `CLOUDINARY_CLOUD_NAME` | Não* | Cloud name da conta Cloudinary. |
| `CLOUDINARY_API_KEY` | Não* | API key da conta Cloudinary. |
| `CLOUDINARY_API_SECRET` | Não* | API secret; nunca deve sair do backend. |
| `CLOUDINARY_SIGNATURE_ALGORITHM` | Não | Algoritmo de assinatura (padrão `sha256`). |
| `CLOUDINARY_SIGNED_UPLOAD_PRESET` | Não | Nome do upload preset assinado configurado no Cloudinary Console. |
| `CLOUDINARY_IMAGE_FOLDER` | Não | Pasta raiz usada para organizar os assets no Cloudinary. |
| `CLOUDINARY_UPLOAD_MAX_BYTES` | Não | Limite de tamanho de upload aplicado pelo backend. |
| `CLOUDINARY_ALLOWED_FORMATS` | Não | Formatos de imagem aceitos. |
| `CLOUDINARY_SIGNED_UPLOAD_TTL_SECONDS` | Não | Validade, em segundos, da assinatura gerada. |

\* Obrigatórias apenas se a aplicação for usar upload/gestão de imagens via `cloudinary_service.py`.

## Referência rápida de flags do `pipeline.py`

| Flag | Efeito |
|---|---|
| `--database-url` | Sobrescreve `DATABASE_URL` do `.env`. |
| `--load-sql` | Caminho alternativo para o arquivo de carga de ingredientes. |
| `--policy {standard,strict}` | Política de retenção de ingredientes (ver `data/ETL_INGREDIENTES/06_limpeza/README.md`). |
| `--reset` | Derruba e recria somente os schemas Venus do pacote. Destrutivo. |
| `--skip-demo` | Não executa a carga de dados de demonstração (`sql/30_demo_seed.sql`). |
| `--skip-bi` | Não executa as views analíticas (`sql/50_bi.sql`). |
| `--skip-rpa` | Não executa a integração com o legado, mesmo que `LEGACY_DATABASE_URL` esteja definido. |
| `--legacy-database-url` | Sobrescreve `LEGACY_DATABASE_URL` do `.env`. |
| `--legacy-products-query` / `--legacy-users-query` | Sobrescrevem as queries de extração do legado. |

## Solução de problemas comuns

- **"banco já populado" / recusa de execução**: o pipeline recusa reutilizar um schema `venus` já populado fora do modo `--reset`. Use um banco novo ou execute com `--reset` para reconstruir apenas os schemas gerenciados pelo pacote.
- **Integração com o legado não roda**: confirme que `LEGACY_DATABASE_URL`, `LEGACY_PRODUCTS_QUERY` e `LEGACY_USERS_QUERY` estão preenchidos e que `--skip-rpa` não foi passado.
- **Upload de imagem falha**: confirme as variáveis `CLOUDINARY_*` no `.env` e revise `CLOUDINARY_API.md` para o contrato de assinatura esperado pelo cliente.
- **Diagnóstico de conexão**: use `python diagnostico_postgres.py` para validar rapidamente a conectividade e o estado do banco antes de rodar o pipeline completo.

## Documentação relacionada

- `AUDIT_DECISIONS.md` — o que foi mantido, removido e acrescentado na consolidação.
- `MODEL_CARDINALIDADES.md` — chaves primárias, estrangeiras e cardinalidades do modelo.
- `BACKUP_RECOVERY.md` — procedimento de backup e restauração.
- `CLOUDINARY_API.md` e `CLOUDINARY_IMAGES.md` — contrato de integração de imagens.
- `PACKAGE_CHANGELOG_V7.md` — histórico de mudanças do pacote.
- `PACKAGE_MANIFEST.md` — inventário de arquivos do pacote com tamanho e hash.
- `data/ETL_INGREDIENTES/README.md` — documentação completa do ETL que produziu a carga de ingredientes.
