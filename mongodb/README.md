# MongoDB

O MongoDB guarda dois conjuntos de dados do Venus: as sessões de escaneamento do Venus-CRUD, antes de virarem catálogo no PostgreSQL, e o estado do chatbot, gravado pelo Venus-AI-Sdk e pelo Venus-AI-api. No fim estão os scripts do validador anterior, copiados do `Banco_de_dados.zip`.

## MongoDB `venus`: sessões de escaneamento em `scan_sessions`

A coleção `scan_sessions` conserva a captura do rótulo, os ingredientes reconhecidos, a decisão da equipe e o resultado da inclusão do produto no catálogo.

### 1. Finalidade do banco

> A sessão de escaneamento reúne o material que ainda precisa ser interpretado e revisado antes de alimentar o catálogo compartilhado. Fotografias e texto reconhecido podem conter cortes, trocas de letras e nomes ambíguos. Conservar a leitura original junto com as correspondências encontradas permite à equipe decidir como cada ingrediente deve ser tratado.
>
> O MongoDB acomoda esses dados em um documento que acompanha a sessão: referências de imagens, texto da frente e do verso, composição extraída, revisão e sincronização. O PostgreSQL continua como fonte da verdade do catálogo. A aprovação é registrada no MongoDB antes da tentativa de levar os dados aprovados ao catálogo, preservando a distinção entre decisão tomada e inclusão concluída.
>
> O modelo efetivamente gravado pelo Venus-CRUD usa `ingredients` na raiz, `review` para a revisão, `approved_snapshot` para o conteúdo aprovado e `sync` para acompanhar a inclusão no PostgreSQL. `source` contém `user_id` e `firebase_uid`. Essa organização é a referência deste documento e permite acompanhar a sessão desde o envio até a sincronização ou a recusa.
>
> As fotos permanecem no Cloudinary, e o documento conserva suas referências e características. A versão técnica `version` acompanha alterações concorrentes: uma revisão baseada em uma versão antiga não deve sobrescrever uma alteração já salva por outra pessoa.

### 2. Modelo de dados

#### 2.1. Documento raiz

As datas são conservadas como BSON Date, representando o instante temporal. Os estados e as ações de revisão são gravados como strings em minúsculas.

| Campo | Tipo | Descrição e motivo de existir |
|---|---|---|
| `_id` | ObjectId | Identifica o documento no MongoDB, separadamente do identificador público da sessão. |
| `scan_id` | String UUID | Identifica a captura ao longo do fluxo e permite reconhecer reenvios da mesma sessão. |
| `status` | String | Situação global: `pending_review`, `approved`, `rejected`, `synced` ou `sync_failed`. O enum também tem `in_review`, mas nenhum fluxo do CRUD grava esse estado. |
| `version` | Inteiro de 64 bits | Versão técnica do documento, usada para detectar alterações concorrentes. Não é a versão da composição do produto. |
| `source` | Object | Associa a sessão à pessoa que enviou o material. |
| `device` | Object | Contextualiza o dispositivo e a plataforma da captura. |
| `started_at` | Date | Início do escaneamento, permitindo interpretar sua duração. |
| `finished_at` | Date | Fim da captura e leitura, distinto do momento da revisão. |
| `quality_check` | Object | Medidas e situação da checagem da imagem. |
| `images` | Object | Referências e características das imagens da frente e do verso. |
| `ocr` | Object | Texto integral, linhas e atributos extraídos por lado do rótulo. |
| `ingredients` | Array de objetos | Ingredientes extraídos e suas correspondências com o catálogo. |
| `review` | Object | Decisão da equipe, responsável, instante, justificativa e decisões individuais. |
| `approved_snapshot` | Object | Retrato dos dados aprovados que será utilizado na sincronização. |
| `sync` | Object | Identificadores do catálogo, tentativas e resultado da sincronização. |
| `created_at` | Date | Criação do documento, usada no histórico e na ordenação da fila. |
| `updated_at` | Date | Última atualização da sessão. |
| `_class` | String | Marca técnica de persistência observada nos documentos, sem significado de domínio do cosmético. |

#### 2.2. Origem e dispositivo

| Campo | Tipo | Descrição e motivo de existir |
|---|---|---|
| `source.user_id` | Inteiro de 64 bits | Identificador da pessoa no PostgreSQL, usado para recuperar seu histórico de scans. |
| `source.firebase_uid` | String | Referência externa da mesma pessoa no Firebase. |
| `device.device_id` | String | Identifica o dispositivo associado à captura. |
| `device.platform` | String | Plataforma que produziu o material, como Android. |
| `device.app_version` | String | Versão do aplicativo que gerou a sessão. |
| `device.model` | String | Modelo do dispositivo, útil para contextualizar a captura. |

#### 2.3. Checagem de qualidade

| Campo | Tipo | Descrição e motivo de existir |
|---|---|---|
| `quality_check.blur_score` | Double | Medida de desfoque associada à imagem. |
| `quality_check.brightness` | Double | Medida de luminosidade da captura. |
| `quality_check.background_ok` | Boolean | Resultado da avaliação do fundo da imagem. |
| `quality_check.status` | String | Estado da checagem: `processing`, `completed`, `failed` ou `pending_review`. É distinto do estado global da sessão. |

#### 2.4. Imagens

`images.front` e `images.back` são objetos com a mesma estrutura. A frente ajuda a identificar marca e produto; o verso conserva a evidência da composição. Os campos da tabela se aplicam a cada lado.

| Campo em cada lado | Tipo | Descrição e motivo de existir |
|---|---|---|
| `public_id` | String | Referência da imagem no Cloudinary, associada à sessão e ao lado fotografado. |
| `secure_url` | String | Endereço da imagem, preenchido a partir de sua referência para permitir a conferência visual. |
| `width` | Inteiro de 32 bits | Largura em pixels, caracterizando a resolução disponível. |
| `height` | Inteiro de 32 bits | Altura em pixels, complementar à largura. |
| `format` | String | Formato do arquivo, como `jpg`. |
| `bytes` | Inteiro de 64 bits | Tamanho do arquivo referenciado. |

#### 2.5. OCR da frente

| Campo | Tipo | Descrição e motivo de existir |
|---|---|---|
| `ocr.front` | Object | Agrupa a leitura da frente do rótulo. |
| `ocr.front.full_text` | String | Texto integral reconhecido, conservando contexto e eventuais erros da leitura. |
| `ocr.front.lines` | Array de strings | Segmentação em linhas, útil para conferir quebras e agrupamentos. |
| `ocr.front.extracted` | Object | Atributos estruturados extraídos da frente. |
| `ocr.front.extracted.brand` | String | Marca reconhecida no rótulo. |
| `ocr.front.extracted.product_name` | String | Nome reconhecido do produto. |
| `ocr.front.extracted.presentation` | String | Apresentação, como creme, para contextualizar o cosmético. |
| `ocr.front.extracted.capacity` | String | Capacidade ou quantidade reconhecida na frente. |
| `ocr.front.extracted.category` | String | Categoria reconhecida no texto da frente. |
| `ocr.front.extracted.claims` | Array de strings | Alegações reconhecidas na frente da embalagem. |

#### 2.6. OCR do verso

| Campo | Tipo | Descrição e motivo de existir |
|---|---|---|
| `ocr.back` | Object | Agrupa a leitura do verso. |
| `ocr.back.full_text` | String | Texto integral, permitindo revisar ruído, cortes e perdas do reconhecimento. |
| `ocr.back.lines` | Array de strings | Segmentação do texto do verso em linhas. |
| `ocr.back.extracted` | Object | Informações estruturadas reconhecidas no verso. |
| `ocr.back.extracted.ingredients_text` | String | Trecho original da composição; a lista estruturada de ingredientes fica em `ingredients`, na raiz. |
| `ocr.back.extracted.manufacturer` | String | Fabricante identificado no rótulo. |
| `ocr.back.extracted.manufacturer_address` | String | Endereço do fabricante reconhecido na embalagem. |
| `ocr.back.extracted.contact` | String | Informação de contato reconhecida. |
| `ocr.back.extracted.country` | String | País indicado no rótulo. |
| `ocr.back.extracted.batch` | String | Lote da embalagem fotografada. |
| `ocr.back.extracted.registration_number` | String | Número de registro reconhecido. |
| `ocr.back.extracted.net_content` | String | Conteúdo líquido indicado no verso. |
| `ocr.back.extracted.usage` | String | Modo de uso reconhecido. |
| `ocr.back.extracted.precautions` | String | Precauções reconhecidas na embalagem. |
| `ocr.back.extracted.warnings` | String | Advertências reconhecidas. |
| `ocr.back.extracted.barcode` | String | Código de barras conservado como texto. |
| `ocr.back.extracted.claims` | Array de strings | Alegações reconhecidas no verso. |
| `ocr.back.extracted.other_text` | String | Trechos não classificados entre os demais atributos da extração. |

#### 2.7. Ingredientes e correspondências

| Campo | Tipo | Descrição e motivo de existir |
|---|---|---|
| `ingredients[]` | Object | Um ingrediente extraído da lista do rótulo. |
| `ingredients[].position` | Inteiro de 32 bits | Posição na composição, preservada na revisão e na formação da versão do produto. |
| `ingredients[].raw_name` | String | Nome como foi reconhecido pelo OCR. |
| `ingredients[].normalized_name` | String | Nome tratado para a procura por INCI e nomes alternativos no catálogo. |
| `ingredients[].match` | Object | Resultado da correspondência automática. |
| `ingredients[].match.status` | String | `known`, `alias`, `ambiguous` ou `new`, distinguindo nome INCI, nome alternativo, múltiplos candidatos e ausência de correspondência. |
| `ingredients[].match.ingredient_id` | Inteiro de 64 bits | Identificador encontrado no PostgreSQL quando há correspondência única. |
| `ingredients[].match.matched_name` | String | Nome INCI do ingrediente associado ao resultado. |
| `ingredients[].match.candidates` | Array de objetos | Alternativas encontradas quando a correspondência é ambígua. |
| `ingredients[].match.candidates[].ingredient_id` | Inteiro de 64 bits | Identificador de um candidato no catálogo. |
| `ingredients[].match.candidates[].inci_name` | String | Nome INCI do candidato, permitindo comparação com a leitura. |

A correspondência procura primeiro o nome INCI. Quando não encontra esse nome, procura nomes alternativos. Um único resultado produz `known` ou `alias`; vários resultados produzem `ambiguous`; nenhum resultado produz `new`. Essa classificação conserva a diferença entre o texto lido e a entidade do catálogo.

#### 2.8. Revisão

| Campo | Tipo | Descrição e motivo de existir |
|---|---|---|
| `review.decided_by_admin_id` | Inteiro de 64 bits | Referência de quem registrou a decisão global. |
| `review.decided_at` | Date | Instante da decisão, separado do término da captura. |
| `review.reason` | String | Justificativa da aprovação ou recusa. |
| `review.ingredient_decisions` | Array de objetos | Decisões explicitamente registradas por posição da composição. |
| `review.ingredient_decisions[].position` | Inteiro de 32 bits | Associa a decisão ao ingrediente extraído. |
| `review.ingredient_decisions[].action` | String | `link`, `create` ou `discard`: vincular, criar ou descartar o item. |
| `review.ingredient_decisions[].ingredient_id` | Inteiro de 64 bits | Ingrediente de destino quando a ação é vincular. |
| `review.ingredient_decisions[].inci_name` | String | Nome INCI decidido quando a ação é criar. |

#### 2.9. Retrato aprovado

`approved_snapshot` conserva o conteúdo resolvido para sincronização. Ele distingue o resultado final aprovado da leitura original e das decisões recebidas durante a revisão. Ingredientes conhecidos podem ser vinculados automaticamente; os descartados não entram na lista final aprovada.

| Campo | Tipo | Descrição e motivo de existir |
|---|---|---|
| `approved_snapshot.product` | Object | Produto existente selecionado ou dados aprovados para um novo produto. |
| `approved_snapshot.product.product_id` | Inteiro de 64 bits | Produto já existente que será reutilizado. |
| `approved_snapshot.product.name` | String | Nome aprovado para um produto novo. |
| `approved_snapshot.product.brand_id` | Inteiro de 64 bits | Marca do novo produto no PostgreSQL. |
| `approved_snapshot.product.product_category_id` | Inteiro de 64 bits | Categoria do novo produto no catálogo. |
| `approved_snapshot.ingredients` | Array de objetos | Composição final aprovada, com os itens que efetivamente serão sincronizados. |
| `approved_snapshot.ingredients[].position` | Inteiro de 32 bits | Ordem do ingrediente na composição aprovada. |
| `approved_snapshot.ingredients[].action` | String | `link` ou `create`, após a resolução da revisão. |
| `approved_snapshot.ingredients[].ingredient_id` | Inteiro de 64 bits | Ingrediente existente a ser associado à composição. |
| `approved_snapshot.ingredients[].inci_name` | String | Nome INCI aprovado para criação do ingrediente. |

#### 2.10. Sincronização

| Campo | Tipo | Descrição e motivo de existir |
|---|---|---|
| `sync.product_id` | Inteiro de 64 bits | Produto efetivamente associado à sessão no PostgreSQL. |
| `sync.product_version_id` | Inteiro de 64 bits | Versão da composição criada ou reutilizada. |
| `sync.synced_at` | Date | Instante da sincronização concluída. |
| `sync.attempts` | Inteiro de 32 bits | Número de tentativas de sincronização registradas; a primeira recebe 1. |
| `sync.last_error` | String | Descrição da última falha, conservada para acompanhamento. |
| `sync.failed_at` | Date | Instante da falha registrada. |

### 3. Ciclo de vida dos dados

A criação recebe o identificador UUID da captura e procura uma sessão com o mesmo `scan_id`. Se ela já existe, o registro existente é reutilizado. Para uma sessão nova, o estado inicial é `pending_review`; a origem é preenchida com os identificadores da pessoa, as referências de imagem são completadas e a correspondência dos ingredientes é calculada antes da gravação.

A revisão pode aprovar ou recusar uma sessão pendente. A aprovação grava `review`, forma `approved_snapshot` e registra `approved` antes de tentar a sincronização. A recusa grava `rejected`, responsável, instante e motivo, sem iniciar a inclusão no catálogo.

A sincronização usa o retrato aprovado, incrementa `sync.attempts` e procura ou cria os registros necessários no PostgreSQL. Ao encontrar uma versão do produto com a mesma assinatura de composição, reutiliza essa versão. No sucesso, grava os identificadores e `sync.synced_at`, limpa os dados da última falha e muda o estado para `synced`. Na falha, conserva a aprovação, registra `sync.last_error` e `sync.failed_at` e muda o estado para `sync_failed`.

Uma nova tentativa é admitida para sessões `approved` ou `sync_failed`. O campo `version` acompanha as atualizações do documento e impede salvar uma revisão sobre uma versão já substituída. Registros antigos com versão ausente ou nula recebem o valor inicial 0 durante a preparação dos dados.

### 4. Índices

#### 4.1. Índices configurados pelo CRUD

Estes índices correspondem ao formato efetivamente gravado e às consultas de identificação, fila e histórico de usuário.

| Nome | Campos e ordem | Finalidade |
|---|---|---|
| `ux_scan_sessions_scan_id` | `scan_id` crescente; único | Reconhecer a mesma captura e impedir duplicação por identificador público. |
| `idx_scan_sessions_status_created_at` | `status` crescente e `created_at` decrescente | Recuperar sessões por estado, com as mais recentes primeiro. |
| `idx_scan_sessions_user_created_at` | `source.user_id` crescente e `created_at` decrescente | Consultar o histórico da pessoa usando o caminho gravado em `source`. |

#### 4.2. Diferenças em relação aos índices do outro modelo

Os nomes legados abaixo apontam para campos que não pertencem às consultas e ao formato atual do CRUD. Sua presença não os torna índices úteis para essas consultas.

| Nome legado | Divergência | Forma usada no conjunto corrigido de índices do outro modelo |
|---|---|---|
| `status_1_admin_review.queue.visible_source_1_createdAt_-1` | Inclui a visibilidade de uma fila de outro modelo e a data `createdAt`. | Consulta por `status` e `created_at`, sem o campo de visibilidade. |
| `postgres_sync.status_1_updatedAt_-1` | Usa `updatedAt`, enquanto a sessão grava `updated_at`. Também se refere a um agrupamento de sincronização diferente de `sync`. | Usa `updated_at` junto do estado de sincronização daquele modelo. |
| `interpretation.product_match.postegres_product_id_1` | Contém `postegres_product_id`, com grafia incorreta, em um caminho de interpretação que não faz parte da sessão gravada. | Usa `postgres_product_id` no agrupamento de interpretação daquele modelo. |

O conjunto corrigido do outro modelo ajusta as datas para `created_at` e `updated_at` e a grafia para `postgres_product_id`, mas continua usando agrupamentos como `postgres_sync`, `admin_review`, `source.user` e `interpretation`. Esses caminhos não substituem `sync`, `review`, `source.user_id` e `approved_snapshot` no documento do CRUD.

`scan_id_1` também se refere ao identificador público, enquanto o índice configurado pelo CRUD se chama `ux_scan_sessions_scan_id` e declara unicidade. Os nomes e caminhos são descritos aqui de acordo com sua origem; a estrutura da sessão segue o formato de gravação do CRUD.

### 5. Regras de negócio refletidas no banco

A sessão separa evidência, interpretação e decisão: `ocr` preserva o reconhecimento, `ingredients` registra correspondências, `review` conserva a decisão e `approved_snapshot` consolida o conteúdo aprovado. `sync` registra o resultado no catálogo. A decisão favorável pode continuar válida mesmo quando a sincronização precisa ser repetida.

Para aprovação, um produto existente é indicado por seu identificador. Um produto novo usa nome, marca e categoria. A composição final precisa conter ao menos um ingrediente. Itens `known` e `alias` podem ser vinculados ao catálogo sem decisão individual adicional; itens `ambiguous` ou `new` exigem resolução explícita. Vínculos ambíguos respeitam os candidatos encontrados, e itens descartados ficam fora da composição final.

Os estados gravados pelo CRUD são `pending_review`, `approved`, `rejected`, `synced` e `sync_failed`; `in_review` existe no enum, mas nenhum fluxo o grava, e a sessão passa de `pending_review` direto para `approved` ou `rejected`. A criação começa em `pending_review`; a aprovação e a recusa operam sobre sessões nesse estado. A sincronização pode partir de `approved` ou `sync_failed`. A versão técnica do documento conserva a coerência quando duas revisões tentam salvar alterações sobre a mesma sessão.

O formato descrito é o gravado pelo CRUD. A validação da coleção precisa ser compatível com esses campos para aceitar a sessão; uma validação que exija os agrupamentos do outro modelo não representa essa estrutura.

## MongoDB `venus`: histórico, memória, métricas e limites do chatbot

O banco `venus` conserva conversas, memórias de longo prazo, métricas de requisições e contadores de mensagens da Veninha.

### 1. Finalidade do banco

> O banco `venus` permite que uma conversa da Veninha tenha continuidade e que informações da pessoa possam ser recuperadas em conversas futuras. São necessidades diferentes: retomar o estado de uma conversa exige os checkpoints daquele diálogo; lembrar um assunto sobre a pessoa exige uma memória organizada por usuário, independente do diálogo em que surgiu.
>
> As coleções `checkpoints` e `checkpoint_writes` seguem o padrão de persistência de checkpoints do LangGraph. Elas registram estados e escritas intermediárias do grafo de agentes, incluindo conteúdo serializado em MessagePack. Já `memorias_longo_prazo` usa documentos com conteúdo variável por assunto. O MongoDB acomoda esses objetos e os conteúdos binários no mesmo modelo documental, sem exigir que cada variação do estado conversacional seja convertida em tabelas do catálogo.
>
> O PostgreSQL continua responsável pelos dados estruturados de domínio, como produtos e ingredientes. O MongoDB conserva o estado conversacional e as memórias que ajudam a Veninha a contextualizar as respostas. Essa divisão descreve o papel da tecnologia. A coleção `metricas_requisicoes` observa volume, latência e erros. A coleção `limites_chat` conta mensagens por pessoa em janelas de minuto e dia. Essas duas finalidades permanecem separadas do estado e do conteúdo das conversas.

### 2. Modelo de dados

São cinco coleções com finalidades distintas: `checkpoint_writes`, `checkpoints`, `memorias_longo_prazo`, `metricas_requisicoes` e `limites_chat`. O nome do banco utilizado pelo chatbot é `venus`.

#### 2.1. `checkpoint_writes`

Uma escrita registra uma contribuição ao estado do grafo, vinculada a uma tarefa, a um canal e a um checkpoint. Isso permite conservar alterações intermediárias separadamente do estado consolidado.

| Campo | Tipo informado ou observado | Descrição e motivo de existir |
| --- | --- | --- |
| `_id` | Identificador | Identificador do documento na coleção. |
| `checkpoint_id` | Identificador UUID | Identifica o checkpoint ao qual a escrita pertence. Permite recuperar as escritas de um estado específico. |
| `checkpoint_ns` | String, vazia no exemplo | Namespace do checkpoint. Distingue contextos de estado dentro do mesmo mecanismo de persistência. |
| `idx` | Inteiro | Ordem da escrita no contexto correspondente. |
| `task_id` | Identificador | Associa a escrita à tarefa que a produziu. |
| `task_path` | String | Caminho da tarefa no grafo, como `~__pregel_pull, start`. Contextualiza a origem da alteração no processamento. |
| `thread_id` | Identificador textual no exemplo | Identifica a conversa à qual o estado pertence. |
| `channel` | String | Canal do estado, como `mensagem_usuario`. Informa que parte do estado recebeu a escrita. |
| `type` | String, `msgpack` no exemplo | Identifica o formato serializado de `value`, necessário para interpretar o conteúdo. |
| `value` | BinData | Conteúdo serializado em MessagePack. No exemplo de origem, representa uma mensagem de apresentação da pessoa. |

#### 2.2. `checkpoints`

Um checkpoint representa um estado persistido do grafo em determinado momento do processamento. A relação com seu predecessor forma a linha do tempo da conversa, enquanto `checkpoint_writes` conserva escritas associadas a esse estado.

| Campo | Tipo informado ou observado | Descrição e motivo de existir |
| --- | --- | --- |
| `_id` | Identificador | Identifica o documento na coleção. |
| `checkpoint_id` | Identificador | Distingue o estado persistido e permite sua associação com as escritas. |
| `checkpoint_ns` | String | Define o contexto do checkpoint e precisa ser considerado junto com os identificadores na recuperação. |
| `thread_id` | Identificador da conversa | Agrupa os estados de uma mesma conversa, conservando sua continuidade. |
| `checkpoint` | BinData | Estado serializado do grafo. |
| `metadata` | Object | Contexto do checkpoint, separado do estado principal para representar sua origem e encadeamento lógico. |
| `metadata.source` | Par `['msgpack', BinData]` | Origem do checkpoint, armazenada no formato serializado informado. Não é uma string simples no exemplo. |
| `metadata.step` | Par `['msgpack', BinData]` | Etapa do processamento. O valor lógico depende da leitura do conteúdo binário. |
| `metadata.parents` | Par `['msgpack', BinData]` | Informação de parentesco do processamento mantida nos metadados. |
| `metadata.thread_id` | Par `['msgpack', BinData]` | Referência à conversa dentro dos metadados. Sua representação difere de `thread_id` no primeiro nível. |
| `parent_checkpoint_id` | Identificador do checkpoint anterior | Liga o estado ao predecessor, permitindo reconstruir a sequência de evolução. |
| `type` | String, `msgpack` no exemplo | Identifica o formato de serialização do estado. |

O identificador do predecessor não equivale a uma posição numérica na conversa. Para percorrer a linha do tempo, é necessário interpretar a ligação entre checkpoints.

#### 2.3. Por que usar conteúdo binário

MessagePack, identificado por `msgpack`, serializa valores estruturados em bytes. O uso de BinData conserva o estado no formato esperado pelo mecanismo de checkpoints, sem exigir que cada elemento interno se torne um campo BSON independente. Isso é particularmente adequado a estados e mensagens que podem ter composições variadas no grafo.

Essa representação tem uma consequência para a documentação e a consulta: o conteúdo da conversa não fica exposto como campos textuais comuns dentro de `checkpoint` ou `value`. Os campos externos, como `thread_id`, `checkpoint_ns` e `checkpoint_id`, localizam o registro; o conteúdo binário precisa ser interpretado conforme seu formato.

#### 2.4. `memorias_longo_prazo`

| Campo | Tipo informado ou observado | Descrição e motivo de existir |
| --- | --- | --- |
| `_id` | Identificador | Identificador do documento na coleção. |
| `key` | String | Assunto da memória, como `perfil`. Permite organizar lembranças distintas da mesma pessoa. |
| `namespace` | Array, com strings no exemplo | Caminho lógico, como `['memorias', '<identificador da pessoa>']`. Agrupa memórias de um usuário entre conversas. |
| `namespace[]` | String no exemplo | Segmento do caminho: o primeiro indica o grupo e o seguinte identifica a pessoa no exemplo fornecido. |
| `namespace_str` | String JSON | Representação textual do mesmo array, destinada à consulta e indexação. Evita depender da interpretação de cada elemento do array para localizar o namespace completo. |
| `value` | Object livre | Conteúdo lembrado sobre o assunto. A flexibilidade permite assuntos com atributos diferentes. |
| `value.nome` | String apenas no exemplo | Nome conservado como atributo de uma memória sobre a pessoa. |
| `created_at` | Data/hora | Registra a criação da memória. |
| `updated_at` | Data/hora | Situa a última alteração e ajuda a interpretar a atualidade da lembrança. |

A memória de curto prazo é organizada por `thread_id`: corresponde à continuidade de uma conversa. A memória de longo prazo é organizada por pessoa e assunto: pode ser reutilizada em outra conversa, com outro `thread_id`. Esses identificadores atendem perguntas diferentes e não são intercambiáveis.

#### 2.5. `metricas_requisicoes`

| Campo | Tipo informado | Descrição e motivo de existir |
| --- | --- | --- |
| `_id` | Identificador | Identificador do registro de medição. |
| `metodo` | String | Método associado à requisição medida; permite segmentar contagens e duração. |
| `rota` | String | Identificador textual de origem da medição, conforme o campo fornecido. |
| `status` | Inteiro | Código de resultado da requisição, útil para analisar ocorrências de erro. Não é um estado de conversa. |
| `duracao_ms` | Double | Tempo medido em milissegundos, permitindo observar latência. |
| `momento` | Data/hora | Instante da medição, necessário para análise temporal. |

A separação evita misturar cada medição com o conteúdo da conversa. Métricas podem existir mesmo sem mensagem útil ou checkpoint correspondente.

#### 2.6. `limites_chat`

A coleção conserva um documento por pessoa, identificado pelo UID do Firebase em `_id`. O mesmo documento reúne as janelas fixas de minuto e de dia UTC. Separar os dois contadores permite limitar tanto a concentração de mensagens em um minuto quanto o volume diário, sem consultar o conteúdo das conversas.

| Campo | Tipo | Descrição e motivo de existir |
|---|---|---|
| `_id` | String | UID da pessoa no Firebase, identificando seu documento de contagem. |
| `minuto_inicio` | Inteiro | Início do minuto corrente em segundos desde a época Unix, usado para reconhecer a mudança da janela. |
| `minuto_contador` | Inteiro | Quantidade de mensagens registradas na janela de minuto correspondente. |
| `dia_inicio` | Inteiro | Início do dia corrente em segundos desde a época Unix, com a fronteira diária definida em UTC. |
| `dia_contador` | Inteiro | Quantidade de mensagens registradas no dia correspondente. |
| `expira_em` | Date | Instante do fim do dia UTC, usado pelo índice TTL para remover automaticamente o documento. |

O registro de uma mensagem atualiza os dois contadores na mesma operação. Se o início gravado corresponde à janela atual, o contador é incrementado; se a janela mudou, seu contador passa a 1. Dessa forma, a renovação da janela não depende de o documento anterior já ter sido removido pelo TTL.

### 3. Ciclo de vida dos dados

Durante uma conversa, o processamento do grafo produz escritas e checkpoints. Os documentos são associados a `thread_id` e ao namespace correspondente; `parent_checkpoint_id` relaciona um estado ao anterior.

Uma memória de longo prazo nasce quando uma informação é conservada sob um namespace e uma `key`. Os campos `created_at` e `updated_at` representam sua criação e atualização. Uma atualização conserva a data original de criação e renova a de atualização. A remoção de uma memória atua sobre seu namespace e sua chave. Sua organização permite continuar existindo independentemente de uma conversa específica.

As métricas nascem a partir das requisições medidas. Nas respostas concluídas normalmente, a medição é gravada depois do envio da resposta. O campo `momento` permite agrupá-las por tempo.

Em `limites_chat`, a primeira mensagem cria o documento da pessoa; as seguintes atualizam as duas janelas. A preparação do índice TTL começa no primeiro registro de mensagem. `expira_em` aponta para o fim do dia UTC e torna o documento elegível à remoção automática. A expiração dos contadores é independente da persistência de conversas e memórias.

### 4. Índices e consultas

Os campos de identificação organizam a recuperação de estados, memórias e métricas.

| Coleção | Consulta que o modelo precisa sustentar | Por que os campos importam |
| --- | --- | --- |
| `checkpoints` | Recuperar estados de uma conversa e de um namespace, incluindo um checkpoint específico. | `thread_id`, `checkpoint_ns` e `checkpoint_id` delimitam o contexto de recuperação. |
| `checkpoint_writes` | Recuperar as escritas de um checkpoint, com sua tarefa e ordem. | O trio de identificadores seleciona o conjunto; `task_id` e `idx` contextualizam as escritas dentro dele. |
| `memorias_longo_prazo` | Localizar uma lembrança pelo namespace completo e assunto. | `namespace_str` e `key` expressam a identidade lógica pretendida para a memória. |
| `metricas_requisicoes` | Observar erros em um intervalo e volume ao longo do tempo. | `status` distingue resultados e `momento` delimita o período. |
| `limites_chat` | Localizar os contadores de uma pessoa e remover documentos vencidos. | `_id` identifica a pessoa e `expira_em` determina a expiração. |

#### 4.1. Memórias e contadores

| Coleção | Índice | Configuração e finalidade |
|---|---|---|
| `memorias_longo_prazo` | `namespace_str_1_key_1` | Único em `namespace_str` e `key`, incluindo os documentos que possuem `namespace_str`. Mantém uma memória por namespace completo e assunto. |
| `limites_chat` | Identificação por `_id` | A unicidade de `_id` mantém um documento de contagem por pessoa. |
| `limites_chat` | TTL em `expira_em` | Expiração com `expireAfterSeconds` igual a 0: a data armazenada determina quando o documento vence. |

A representação textual do namespace preserva o caminho completo como um único valor para a identidade da memória. A preparação da coleção preenche `namespace_str` nos registros antigos e substitui o índice único anterior baseado no array `namespace`. O array continua presente para consultas por prefixo, enquanto a consulta por assunto usa `namespace_str` e `key`.

### 5. Regras de negócio refletidas no banco

A Veninha conserva continuidade dentro de uma conversa por checkpoints e entre conversas por memórias da pessoa. Um novo `thread_id` não muda, por si só, o namespace de longo prazo. Ao mesmo tempo, uma lembrança em `value` não substitui o catálogo usado pelos especialistas para fundamentar respostas sobre produtos e ingredientes.

`parent_checkpoint_id` representa a evolução do estado; `task_id`, `channel` e `idx` registram o contexto de escritas. A presença de MessagePack significa que a recuperação deve respeitar o formato indicado por `type`. As métricas têm uma finalidade de observação, por isso não são interpretadas como falas, memórias ou decisões do agente juiz.

Cada mensagem registrada em `limites_chat` participa dos contadores de minuto e de dia, inclusive a tentativa que excede o limite. Quando um contador supera o limite definido para sua janela, o controle indica o tempo de espera para uma nova tentativa. Se as duas janelas forem excedidas, é considerado o maior tempo restante. O contador limita o volume de mensagens; não substitui os checkpoints nem armazena o texto da conversa.

## Scripts do validador anterior

O validador abaixo foi copiado do `Banco_de_dados.zip`. O Venus-CRUD grava outro formato (`ingredients` na raiz, `review`, `approved_snapshot` e `sync`), descrito na seção da coleção `scan_sessions`; com este validador ativo na coleção, o insert do CRUD seria recusado.

### Contrato do validador (`validation.js`)

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

### Arquivos incorporados

- `validation.js`: validador JSON Schema da coleção.
- `indexes_novo.js`: índices de fila, usuário, sincronização e produto.
- `seed.js`: documentos demonstrativos idempotentes.
- `consultas.js`: consultas operacionais para revisão e sincronização.

Os arquivos foram copiados do `Banco_de_dados.zip` fornecido e preservados como
referência. Eles não foram executados nesta revisão, conforme a regra de validar
diretamente apenas o SQL.

### Observações para execução

`validation.js` usa a variável `nomeDB`; defina-a no contexto do `mongosh` antes
de executar o script, por exemplo `const nomeDB = "venus_scan"`. Valide também
se o nome do banco e a autenticação correspondem ao ambiente escolhido.
