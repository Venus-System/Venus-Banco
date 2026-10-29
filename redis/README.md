# Redis

O Redis é usado como cache no Venus-CRUD e no Venus-Classificacao, com TTL de 6 horas (`spring.cache.redis.time-to-live: 6h`). A fonte operacional continua sendo o PostgreSQL: se o Redis ficar fora do ar, as duas APIs seguem lendo do banco.

## Redis: cache de favoritos do Venus-CRUD

O cache de favoritos conserva temporariamente páginas e contagens de produtos favoritos por usuário, reduzindo leituras repetidas no PostgreSQL.

### 1. Finalidade do banco

> O cache de favoritos atende um padrão recorrente do Venus: uma pessoa consulta mais de uma vez a mesma lista de produtos e sua quantidade total. Repetir essas consultas no PostgreSQL a cada leitura recuperaria, muitas vezes, o mesmo resultado. O Redis mantém uma cópia temporária dessas respostas para reutilização durante seis horas, respeitando a identidade da pessoa e, nas listas, a paginação e a ordenação solicitadas.
>
> O PostgreSQL continua conservando o registro definitivo dos favoritos. O Redis não recebe a responsabilidade de definir quais produtos foram favoritados; sua função é acelerar a recuperação de resultados já obtidos. Essa distinção permite que o fluxo consulte o banco principal quando não há uma entrada válida ou quando o cache falha.
>
> A tecnologia é adequada ao acesso por chave: cada combinação de consulta identifica um resultado reaproveitável, e o TTL limita por quanto tempo essa cópia pode permanecer. Separar páginas e contagem também evita recuperar uma página inteira apenas para responder quantos favoritos existem.

### 2. Modelo de dados

#### 2.1. Tipos e conteúdo lógico

O cache usa duas famílias de chaves: páginas e contagem de favoritos.

| Cache | Tipo lógico do valor | TTL informado | Motivo da separação |
| --- | --- | --- | --- |
| `favoritos-do-usuario` | Fatia, ou slice, de favoritos | 6 horas, equivalentes a 21.600 segundos | Reutiliza uma consulta específica de página, tamanho e ordem. |
| `contagem-de-favoritos-do-usuario` | Número de favoritos | 6 horas, equivalentes a 21.600 segundos | Responde à contagem sem precisar carregar o conteúdo de uma página. |

O TTL é o prazo de validade da entrada.

#### 2.2. Anatomia da chave de páginas

```text
favoritos-do-usuario::{userId}:{página}:{tamanho}:{ordem}
```

| Parte | Significado | Motivo de existir |
| --- | --- | --- |
| `favoritos-do-usuario` | Nome do cache | Distingue páginas de favoritos dos demais resultados armazenados. |
| `::` | Separação entre o nome do cache e a chave da consulta | Mantém o prefixo informado para essa família de entradas. |
| `{userId}` | Identificador do usuário | Associa o resultado à pessoa cuja lista foi consultada. |
| `{página}` | Página solicitada | Impede que uma página seja reutilizada como se fosse outra. O exemplo usa a página `0`. |
| `{tamanho}` | Quantidade solicitada por página | Distingue fatias com tamanhos diferentes e, consequentemente, conteúdos e limites diferentes. |
| `{ordem}` | Expressão de ordenação | Conserva a ordem pedida, que influencia quais itens entram em cada fatia. O exemplo contém `createdAt: DESC`. |
| `:` entre componentes | Separação textual | Compõe a chave informada; a própria ordenação também pode conter dois-pontos. |

O resultado não é identificado apenas pela pessoa. Uma consulta com página diferente, tamanho diferente ou ordem diferente tem sua própria entrada. Essa precisão evita reutilizar conteúdo incompatível com a consulta, mas aumenta a quantidade de chaves possíveis.

#### 2.3. Anatomia da chave de contagem

```text
contagem-de-favoritos-do-usuario::{userId}
```

| Parte | Significado | Motivo de existir |
| --- | --- | --- |
| `contagem-de-favoritos-do-usuario` | Nome do cache de contagem | Separa o total numérico das páginas de conteúdo. |
| `::` | Separação do prefixo e identificador | Segue o padrão informado para essa entrada. |
| `{userId}` | Identificador do usuário | O total pertence à lista da pessoa, independentemente da página ou da ordenação consultada. |

#### 2.4. Formato lógico do valor

O valor de página é uma slice: contém itens, dados de paginação e informação de existência de próxima página. Os elementos da tabela descrevem o conteúdo conhecido, sem propor nomes de campos serializados.

| Elemento lógico | Tipo lógico | Finalidade e motivo |
| --- | --- | --- |
| Conteúdo da página | Coleção de favoritos | Reúne somente a fatia solicitada. |
| Identificador do favorito em cada item | Identificador | Distingue o registro do favorito do próprio produto. |
| Identificador do usuário em cada item | Identificador | Associa o item à pessoa, além dessa referência já existir na chave. |
| Identificador do produto em cada item | Identificador | Liga o favorito ao catálogo no PostgreSQL. |
| Data de criação em cada item | Data/hora | Registra quando o produto foi favoritado e participa da ordenação exemplificada. |
| Informações de paginação | Estrutura | Contextualizam a fatia retornada. |
| Indicação de próxima página | Valor lógico booleano | Informa se a navegação pode continuar. |
| Valor da contagem | Número | Conserva a quantidade total de favoritos do usuário. |

A existência de um cache próprio de contagem atende uma necessidade diferente da indicação de próxima página.

### 3. Exemplo de chave

Chaves ilustrativas no padrão fornecido:

```text
favoritos-do-usuario::10:0:20:createdAt: DESC
favoritos-do-usuario::10:1:20:createdAt: DESC
contagem-de-favoritos-do-usuario::10
```

As duas primeiras representam páginas distintas da mesma pessoa, com tamanho de 20 itens e a mesma ordem. A terceira representa sua contagem total. Um valor lógico ilustrativo para a contagem é 37. Nesse cenário, a primeira página pode conter 20 itens e indicar continuação, enquanto a segunda pode conter os 17 restantes.

Esse cenário ilustra a diferença entre página e contagem.

### 4. Ciclo de vida dos dados

Na primeira leitura sem entrada válida, o resultado é obtido no PostgreSQL e conservado no cache correspondente. Uma leitura repetida da mesma combinação pode reutilizar a entrada. As verificações descritas no material demonstram que a repetição da mesma página consulta o banco uma única vez, que páginas diferentes têm chaves próprias e que a contagem também é reaproveitada.

Quando a pessoa favorita ou desfavorita, a gravação é primeiro confirmada no PostgreSQL. Depois dessa confirmação, todas as entradas do cache `favoritos-do-usuario` são apagadas, incluindo as páginas de todos os usuários. No cache `contagem-de-favoritos-do-usuario`, somente a chave do usuário afetado é removida. As próximas leituras de páginas retornam ao banco e podem preencher novamente o cache; as contagens das outras pessoas permanecem disponíveis.

A entrada também deixa de ser válida ao completar seu TTL de seis horas. Como podem ser preenchidas em momentos distintos, suas validades não precisam terminar juntas.

### 5. Política de chaves e expiração

O acesso é feito pela chave completa. A política central combina TTL e invalidação por alteração confirmada.

| Situação | Política informada | Efeito sobre o dado |
| --- | --- | --- |
| Página solicitada | Uma entrada por usuário, página, tamanho e ordem | Reutilização apenas da mesma combinação. |
| Contagem solicitada | Uma entrada por usuário | Reutilização do total independentemente das páginas. |
| Tempo de vida | 6 horas nos dois caches | A cópia deixa de atender após o prazo; uma nova leitura pode repô-la. |
| Favorito incluído ou removido | Apaga todas as páginas de todos os usuários e a contagem somente do usuário afetado, após confirmação no banco | A próxima leitura de qualquer página consulta o PostgreSQL; o total é recarregado apenas para a pessoa afetada. |
| Alteração de outro usuário | Apaga também as páginas já guardadas das demais pessoas, mas conserva suas contagens | O conteúdo continua individual por chave, enquanto o descarte das páginas tem alcance global. |

Uma inclusão ou remoção pode deslocar itens entre as páginas do usuário e mudar a indicação de continuação. O mecanismo de invalidação utilizado remove uma chave exata ou todas as entradas do cache; ele não remove páginas pelo prefixo de um usuário. Por isso, a configuração atual descarta o cache inteiro de páginas. Esse alcance também elimina cópias de outras pessoas, que precisam ser recuperadas novamente do PostgreSQL.

### 6. Regras de negócio refletidas no banco

A identidade do usuário integra ambas as famílias de chaves porque favoritos são individuais. Página, tamanho e ordenação integram a chave da lista porque alteram o resultado. A contagem usa apenas a pessoa, pois não varia com a forma de percorrer a lista. Essa separação do conteúdo por usuário convive com duas abrangências de descarte: global para páginas e individual para contagem.

Confirmar a alteração no PostgreSQL antes de invalidar conserva a sequência entre a mudança definitiva e o descarte das cópias. A invalidação descarta as páginas de todos os usuários e a contagem somente da pessoa afetada, fazendo com que as próximas consultas dessas entradas recuperem os dados no banco principal.

O TTL limita a permanência de uma entrada, mas não substitui a invalidação quando a pessoa modifica a lista. O comportamento documentado procura refletir essas mudanças já na leitura seguinte ao descarte das entradas correspondentes.

## Redis: cache de classificações personalizadas do Venus-Classificacao

O cache `classificacoes` conserva em JSON resultados de nota de produtos por usuário, versão do produto e modelo de pontuação, com validade de seis horas.

### 1. Finalidade do banco

> O cache de classificações permite reutilizar uma análise personalizada já existente, evitando recuperar repetidamente o mesmo resultado no PostgreSQL. A análise responde a uma combinação específica de pessoa, versão do produto e modelo de pontuação. A mesma pessoa pode receber resultados diferentes para versões diferentes de um produto, e pessoas distintas podem ter compatibilidades diferentes com a mesma composição.
>
> O Redis é adequado a esse reaproveitamento por chave completa, com prazo de validade definido e descarte quando uma nova análise é gravada pelo fluxo descrito. O valor reúne o resultado da classificação em JSON, em vez de repartir a resposta em várias estruturas de consulta. Esse desenho permite reutilizar um resultado pronto.
>
> O PostgreSQL permanece como origem da análise salva e dos dados de domínio que a fundamentam. O Redis mantém uma cópia temporária dessa análise. Expirar uma chave provoca uma nova leitura do banco. Essa distinção é relevante quando composição, regras ou perfil mudam.

### 2. Modelo de dados

#### 2.1. Tipo e formato do valor

| Propriedade | Definição informada | Motivo de existir |
| --- | --- | --- |
| Nome do cache | `classificacoes` | Agrupa resultados de classificação e distingue esse conteúdo dos outros caches. |
| Tipo lógico | Resultado de classificação personalizada | Conserva a análise salva para uma combinação específica. |
| Serialização | JSON com serializador próprio | Define uma representação estruturada para recuperar o resultado completo. |
| Tratamento de datas | Mapeador ajustado para não converter datas ao fuso do contexto, preservando os offsets originais | Evita que a representação temporal seja alterada por essa conversão ao recuperar o resultado. |
| Resultado nulo | Não é cacheado | Evita conservar uma ausência como se fosse uma análise válida. |
| TTL | 6 horas, equivalentes a 21.600 segundos | Limita o tempo de reutilização da cópia. |

#### 2.2. Anatomia da chave

```text
classificacoes::{usuário}:{versão do produto}:{modelo de pontuação}
```

| Parte | Significado | Motivo de existir |
| --- | --- | --- |
| `classificacoes` | Nome do cache | Identifica a família de resultados personalizados. |
| `::` | Separação entre nome e identidade da entrada | Mantém o padrão fornecido para o cache. |
| `{usuário}` | Identificador da pessoa | Distingue análises cuja compatibilidade depende do perfil. |
| `{versão do produto}` | Identificador de versão associado ao produto | Evita reutilizar uma análise de uma formulação anterior quando a composição muda e uma nova versão é usada. |
| `{modelo de pontuação}` | Identificador do modelo de cálculo | Diferencia resultados produzidos por regras de pontuação distintas. |
| `:` entre componentes | Separação textual dos identificadores | Compõe a identidade completa informada. |

Versão da formulação do cosmético e modelo de pontuação representam mudanças diferentes: a primeira corresponde aos dados do produto usados na análise; o segundo corresponde às regras de cálculo.

#### 2.3. Conteúdo de domínio relacionado ao resultado

| Elemento de domínio | Regra fornecida | Relação com a necessidade de cache personalizado |
| --- | --- | --- |
| Qualidade do produto | Até 35 pontos por saúde, desempenho, impacto ambiental e ética | Parcela comum às pessoas para o mesmo produto e contexto de cálculo. |
| Compatibilidade com o perfil | Até 65 pontos | Parcela que torna necessário distinguir usuários. |
| Nota total | Escala de 0 a 100 | Resultado global da avaliação, sujeito às travas. |
| Travas | Ingrediente proibido na gestação ou alergia crítica zera a nota e torna o produto contraindicado | Uma classificação antiga pode deixar de representar a situação atual se o perfil ou os dados usados mudarem. |
| Faixas | Ideal, recomendado, aceitável, não recomendado e contraindicado | Expressam a leitura qualitativa da nota e das travas. |

Essa tabela descreve as regras do Venus que dão sentido ao resultado.

### 3. Exemplo de chave

```text
classificacoes::42:7:1
```

A chave ilustrativa representa a análise do usuário `42`, para a versão de produto `7`, no modelo de pontuação `1`. Outra pessoa, outra versão ou outro modelo produz uma chave diferente.

O valor é o resultado da classificação serializado em JSON, com preservação dos offsets das datas.

### 4. Ciclo de vida dos dados

A entrada nasce quando uma leitura obtém no PostgreSQL uma análise salva e a conserva no Redis. Uma leitura da mesma combinação pode reutilizar o resultado até que a entrada expire ou seja invalidada.

Uma nova gravação da análise do mesmo usuário, versão do produto e modelo apaga a chave correspondente. A leitura seguinte retorna ao banco e pode preencher a entrada novamente.

Após seis horas, a cópia deixa de ser válida. Resultado nulo e ausência indicada por 404 não são conservados.

### 5. Política de chaves e expiração

O acesso é feito pela chave completa. A política de validade combina três componentes de identidade, descarte após nova gravação e TTL.

| Situação | Política informada | Efeito sobre o resultado |
| --- | --- | --- |
| Mesma pessoa, versão e modelo | Mesma chave | Reaproveita a análise dessa combinação. |
| Nova versão do produto | Outra chave | Impede usar a entrada da versão anterior nessa nova consulta. |
| Outro modelo de pontuação | Outra chave | Separa resultados associados a modelos diferentes. |
| Nova gravação da mesma combinação | Apaga a chave | A próxima leitura busca a análise salva no banco. |
| Resultado nulo ou 404 | Não cacheia | Uma ausência não fica conservada por seis horas. |
| Tempo transcorrido | TTL de seis horas | Limita a permanência de cada cópia. |
| Alteração direta no banco ou pelo Venus-CRUD | Atualização após expiração da entrada | A cópia existente pode continuar sendo lida até expirar. |

A limitação informada é de consistência eventual de até seis horas para a cópia já armazenada. Esse prazo descreve a permanência da entrada atual. A atualização efetiva percebida após uma nova leitura depende de o resultado salvo no PostgreSQL já refletir a mudança.

### 6. Regras de negócio refletidas no banco

A nota reúne qualidade do produto e compatibilidade com a pessoa. Isso justifica o componente de usuário na chave, mas a identidade da pessoa sozinha não representa a evolução de seu perfil ao longo do tempo. Preferências, alergias e condições informadas podem mudar sem que o identificador do usuário mude.

Versões de produto e modelos de pontuação distinguem resultados calculados em contextos diferentes. Para que essa separação funcione, as consultas precisam usar os identificadores correspondentes ao contexto desejado.

As travas prevalecem sobre a soma de pontos: nos casos fornecidos, a nota é zero e a classificação é contraindicado. O cache conserva o resultado já produzido.
