# Redis: cache de favoritos do Venus-CRUD

O cache de favoritos conserva temporariamente páginas e contagens de produtos favoritos por usuário, reduzindo leituras repetidas no PostgreSQL.

## 1. Finalidade do banco

> O cache de favoritos atende um padrão recorrente do Venus: uma pessoa consulta mais de uma vez a mesma lista de produtos e sua quantidade total. Repetir essas consultas no PostgreSQL a cada leitura recuperaria, muitas vezes, o mesmo resultado. O Redis mantém uma cópia temporária dessas respostas para reutilização durante seis horas, respeitando a identidade da pessoa e, nas listas, a paginação e a ordenação solicitadas.
>
> O PostgreSQL continua conservando o registro definitivo dos favoritos. O Redis não recebe a responsabilidade de definir quais produtos foram favoritados; sua função é acelerar a recuperação de resultados já obtidos. Essa distinção permite que o fluxo consulte o banco principal quando não há uma entrada válida ou quando o cache falha.
>
> A tecnologia é adequada ao acesso por chave: cada combinação de consulta identifica um resultado reaproveitável, e o TTL limita por quanto tempo essa cópia pode permanecer. Separar páginas e contagem também evita recuperar uma página inteira apenas para responder quantos favoritos existem.

## 2. Modelo de dados

### 2.1. Tipos e conteúdo lógico

O cache usa duas famílias de chaves: páginas e contagem de favoritos.

| Cache | Tipo lógico do valor | TTL informado | Motivo da separação |
| --- | --- | --- | --- |
| `favoritos-do-usuario` | Fatia, ou slice, de favoritos | 6 horas, equivalentes a 21.600 segundos | Reutiliza uma consulta específica de página, tamanho e ordem. |
| `contagem-de-favoritos-do-usuario` | Número de favoritos | 6 horas, equivalentes a 21.600 segundos | Responde à contagem sem precisar carregar o conteúdo de uma página. |

O TTL é o prazo de validade da entrada.

### 2.2. Anatomia da chave de páginas

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

### 2.3. Anatomia da chave de contagem

```text
contagem-de-favoritos-do-usuario::{userId}
```

| Parte | Significado | Motivo de existir |
| --- | --- | --- |
| `contagem-de-favoritos-do-usuario` | Nome do cache de contagem | Separa o total numérico das páginas de conteúdo. |
| `::` | Separação do prefixo e identificador | Segue o padrão informado para essa entrada. |
| `{userId}` | Identificador do usuário | O total pertence à lista da pessoa, independentemente da página ou da ordenação consultada. |

### 2.4. Formato lógico do valor

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

## 3. Exemplo de chave

Chaves ilustrativas no padrão fornecido:

```text
favoritos-do-usuario::10:0:20:createdAt: DESC
favoritos-do-usuario::10:1:20:createdAt: DESC
contagem-de-favoritos-do-usuario::10
```

As duas primeiras representam páginas distintas da mesma pessoa, com tamanho de 20 itens e a mesma ordem. A terceira representa sua contagem total. Um valor lógico ilustrativo para a contagem é 37. Nesse cenário, a primeira página pode conter 20 itens e indicar continuação, enquanto a segunda pode conter os 17 restantes.

Esse cenário ilustra a diferença entre página e contagem.

## 4. Ciclo de vida dos dados

Na primeira leitura sem entrada válida, o resultado é obtido no PostgreSQL e conservado no cache correspondente. Uma leitura repetida da mesma combinação pode reutilizar a entrada. As verificações descritas no material demonstram que a repetição da mesma página consulta o banco uma única vez, que páginas diferentes têm chaves próprias e que a contagem também é reaproveitada.

Quando a pessoa favorita ou desfavorita, a gravação é primeiro confirmada no PostgreSQL. Depois dessa confirmação, todas as entradas do cache `favoritos-do-usuario` são apagadas, incluindo as páginas de todos os usuários. No cache `contagem-de-favoritos-do-usuario`, somente a chave do usuário afetado é removida. As próximas leituras de páginas retornam ao banco e podem preencher novamente o cache; as contagens das outras pessoas permanecem disponíveis.

A entrada também deixa de ser válida ao completar seu TTL de seis horas. Como podem ser preenchidas em momentos distintos, suas validades não precisam terminar juntas.

## 5. Política de chaves e expiração

O acesso é feito pela chave completa. A política central combina TTL e invalidação por alteração confirmada.

| Situação | Política informada | Efeito sobre o dado |
| --- | --- | --- |
| Página solicitada | Uma entrada por usuário, página, tamanho e ordem | Reutilização apenas da mesma combinação. |
| Contagem solicitada | Uma entrada por usuário | Reutilização do total independentemente das páginas. |
| Tempo de vida | 6 horas nos dois caches | A cópia deixa de atender após o prazo; uma nova leitura pode repô-la. |
| Favorito incluído ou removido | Apaga todas as páginas de todos os usuários e a contagem somente do usuário afetado, após confirmação no banco | A próxima leitura de qualquer página consulta o PostgreSQL; o total é recarregado apenas para a pessoa afetada. |
| Alteração de outro usuário | Apaga também as páginas já guardadas das demais pessoas, mas conserva suas contagens | O conteúdo continua individual por chave, enquanto o descarte das páginas tem alcance global. |

Uma inclusão ou remoção pode deslocar itens entre as páginas do usuário e mudar a indicação de continuação. O mecanismo de invalidação utilizado remove uma chave exata ou todas as entradas do cache; ele não remove páginas pelo prefixo de um usuário. Por isso, a configuração atual descarta o cache inteiro de páginas. Esse alcance também elimina cópias de outras pessoas, que precisam ser recuperadas novamente do PostgreSQL.

## 6. Regras de negócio refletidas no banco

A identidade do usuário integra ambas as famílias de chaves porque favoritos são individuais. Página, tamanho e ordenação integram a chave da lista porque alteram o resultado. A contagem usa apenas a pessoa, pois não varia com a forma de percorrer a lista. Essa separação do conteúdo por usuário convive com duas abrangências de descarte: global para páginas e individual para contagem.

Confirmar a alteração no PostgreSQL antes de invalidar conserva a sequência entre a mudança definitiva e o descarte das cópias. A invalidação descarta as páginas de todos os usuários e a contagem somente da pessoa afetada, fazendo com que as próximas consultas dessas entradas recuperem os dados no banco principal.

O TTL limita a permanência de uma entrada, mas não substitui a invalidação quando a pessoa modifica a lista. O comportamento documentado procura refletir essas mudanças já na leitura seguinte ao descarte das entradas correspondentes.
