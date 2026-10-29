# MongoDB `venus`: histórico, memória, métricas e limites do chatbot

O banco `venus` conserva conversas, memórias de longo prazo, métricas de requisições e contadores de mensagens da Veninha.

## 1. Finalidade do banco

> O banco `venus` permite que uma conversa da Veninha tenha continuidade e que informações da pessoa possam ser recuperadas em conversas futuras. São necessidades diferentes: retomar o estado de uma conversa exige os checkpoints daquele diálogo; lembrar um assunto sobre a pessoa exige uma memória organizada por usuário, independente do diálogo em que surgiu.
>
> As coleções `checkpoints` e `checkpoint_writes` seguem o padrão de persistência de checkpoints do LangGraph. Elas registram estados e escritas intermediárias do grafo de agentes, incluindo conteúdo serializado em MessagePack. Já `memorias_longo_prazo` usa documentos com conteúdo variável por assunto. O MongoDB acomoda esses objetos e os conteúdos binários no mesmo modelo documental, sem exigir que cada variação do estado conversacional seja convertida em tabelas do catálogo.
>
> O PostgreSQL continua responsável pelos dados estruturados de domínio, como produtos e ingredientes. O MongoDB conserva o estado conversacional e as memórias que ajudam a Veninha a contextualizar as respostas. Essa divisão descreve o papel da tecnologia. A coleção `metricas_requisicoes` observa volume, latência e erros. A coleção `limites_chat` conta mensagens por pessoa em janelas de minuto e dia. Essas duas finalidades permanecem separadas do estado e do conteúdo das conversas.

## 2. Modelo de dados

São cinco coleções com finalidades distintas: `checkpoint_writes`, `checkpoints`, `memorias_longo_prazo`, `metricas_requisicoes` e `limites_chat`. O nome do banco utilizado pelo chatbot é `venus`.

### 2.1. `checkpoint_writes`

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

### 2.2. `checkpoints`

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

### 2.3. Por que usar conteúdo binário

MessagePack, identificado por `msgpack`, serializa valores estruturados em bytes. O uso de BinData conserva o estado no formato esperado pelo mecanismo de checkpoints, sem exigir que cada elemento interno se torne um campo BSON independente. Isso é particularmente adequado a estados e mensagens que podem ter composições variadas no grafo.

Essa representação tem uma consequência para a documentação e a consulta: o conteúdo da conversa não fica exposto como campos textuais comuns dentro de `checkpoint` ou `value`. Os campos externos, como `thread_id`, `checkpoint_ns` e `checkpoint_id`, localizam o registro; o conteúdo binário precisa ser interpretado conforme seu formato.

### 2.4. `memorias_longo_prazo`

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

### 2.5. `metricas_requisicoes`

| Campo | Tipo informado | Descrição e motivo de existir |
| --- | --- | --- |
| `_id` | Identificador | Identificador do registro de medição. |
| `metodo` | String | Método associado à requisição medida; permite segmentar contagens e duração. |
| `rota` | String | Identificador textual de origem da medição, conforme o campo fornecido. |
| `status` | Inteiro | Código de resultado da requisição, útil para analisar ocorrências de erro. Não é um estado de conversa. |
| `duracao_ms` | Double | Tempo medido em milissegundos, permitindo observar latência. |
| `momento` | Data/hora | Instante da medição, necessário para análise temporal. |

A separação evita misturar cada medição com o conteúdo da conversa. Métricas podem existir mesmo sem mensagem útil ou checkpoint correspondente.

### 2.6. `limites_chat`

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

## 3. Ciclo de vida dos dados

Durante uma conversa, o processamento do grafo produz escritas e checkpoints. Os documentos são associados a `thread_id` e ao namespace correspondente; `parent_checkpoint_id` relaciona um estado ao anterior.

Uma memória de longo prazo nasce quando uma informação é conservada sob um namespace e uma `key`. Os campos `created_at` e `updated_at` representam sua criação e atualização. Uma atualização conserva a data original de criação e renova a de atualização. A remoção de uma memória atua sobre seu namespace e sua chave. Sua organização permite continuar existindo independentemente de uma conversa específica.

As métricas nascem a partir das requisições medidas. Nas respostas concluídas normalmente, a medição é gravada depois do envio da resposta. O campo `momento` permite agrupá-las por tempo.

Em `limites_chat`, a primeira mensagem cria o documento da pessoa; as seguintes atualizam as duas janelas. A preparação do índice TTL começa no primeiro registro de mensagem. `expira_em` aponta para o fim do dia UTC e torna o documento elegível à remoção automática. A expiração dos contadores é independente da persistência de conversas e memórias.

## 4. Índices e consultas

Os campos de identificação organizam a recuperação de estados, memórias e métricas.

| Coleção | Consulta que o modelo precisa sustentar | Por que os campos importam |
| --- | --- | --- |
| `checkpoints` | Recuperar estados de uma conversa e de um namespace, incluindo um checkpoint específico. | `thread_id`, `checkpoint_ns` e `checkpoint_id` delimitam o contexto de recuperação. |
| `checkpoint_writes` | Recuperar as escritas de um checkpoint, com sua tarefa e ordem. | O trio de identificadores seleciona o conjunto; `task_id` e `idx` contextualizam as escritas dentro dele. |
| `memorias_longo_prazo` | Localizar uma lembrança pelo namespace completo e assunto. | `namespace_str` e `key` expressam a identidade lógica pretendida para a memória. |
| `metricas_requisicoes` | Observar erros em um intervalo e volume ao longo do tempo. | `status` distingue resultados e `momento` delimita o período. |
| `limites_chat` | Localizar os contadores de uma pessoa e remover documentos vencidos. | `_id` identifica a pessoa e `expira_em` determina a expiração. |

### 4.1. Memórias e contadores

| Coleção | Índice | Configuração e finalidade |
|---|---|---|
| `memorias_longo_prazo` | `namespace_str_1_key_1` | Único em `namespace_str` e `key`, incluindo os documentos que possuem `namespace_str`. Mantém uma memória por namespace completo e assunto. |
| `limites_chat` | Identificação por `_id` | A unicidade de `_id` mantém um documento de contagem por pessoa. |
| `limites_chat` | TTL em `expira_em` | Expiração com `expireAfterSeconds` igual a 0: a data armazenada determina quando o documento vence. |

A representação textual do namespace preserva o caminho completo como um único valor para a identidade da memória. A preparação da coleção preenche `namespace_str` nos registros antigos e substitui o índice único anterior baseado no array `namespace`. O array continua presente para consultas por prefixo, enquanto a consulta por assunto usa `namespace_str` e `key`.

## 5. Regras de negócio refletidas no banco

A Veninha conserva continuidade dentro de uma conversa por checkpoints e entre conversas por memórias da pessoa. Um novo `thread_id` não muda, por si só, o namespace de longo prazo. Ao mesmo tempo, uma lembrança em `value` não substitui o catálogo usado pelos especialistas para fundamentar respostas sobre produtos e ingredientes.

`parent_checkpoint_id` representa a evolução do estado; `task_id`, `channel` e `idx` registram o contexto de escritas. A presença de MessagePack significa que a recuperação deve respeitar o formato indicado por `type`. As métricas têm uma finalidade de observação, por isso não são interpretadas como falas, memórias ou decisões do agente juiz.

Cada mensagem registrada em `limites_chat` participa dos contadores de minuto e de dia, inclusive a tentativa que excede o limite. Quando um contador supera o limite definido para sua janela, o controle indica o tempo de espera para uma nova tentativa. Se as duas janelas forem excedidas, é considerado o maior tempo restante. O contador limita o volume de mensagens; não substitui os checkpoints nem armazena o texto da conversa.
