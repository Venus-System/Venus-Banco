# Neo4j: grafo do check-up de rotina da Veninha

O grafo relaciona favoritos, produtos, ingredientes e regras de ativos para identificar conflitos, ausências, ordem inadequada e repetições na rotina montada pela Veninha.

## 1. Finalidade do banco

> O Neo4j sustenta um check-up complementar da rotina de cosméticos. Sua finalidade é percorrer relações entre os produtos da pessoa, seus ingredientes e os tipos de ativo associados, verificando se a rotina apresenta combinações conflitantes, um ativo complementar ausente, uma ordem de aplicação incompatível com as regras ou produtos muito semelhantes no mesmo período.
>
> O modelo de grafo é adequado porque essas verificações dependem de caminhos: um produto contém um ingrediente, esse ingrediente pertence a um tipo de ativo e esse tipo mantém uma regra com outro tipo. Representar esses vínculos explicitamente permite consultar a relação entre produtos por meio de sua composição e das regras, sem transformar cada par possível em um cadastro independente. Essa adequação explica o papel da tecnologia no desenho apresentado.
>
> O grafo é uma cópia derivada. O PostgreSQL permanece como fonte da verdade de usuários referenciados, produtos, ingredientes, composição e favoritos; dois arquivos CSV versionados fornecem os mapeamentos de ativos e as regras. O agente de rotina da Veninha consulta a cópia, enquanto a sincronização a reconstrói a partir dessas origens. Não há gravação de mudanças da rotina no grafo pela Veninha no fluxo descrito.
>
> O check-up é opcional: sem ele, a rotina continua sendo montada e a Veninha não comenta essa verificação. Isso distingue a utilidade do grafo da geração principal da rotina. Também explica por que período e ordem de aplicação não são persistidos: são calculados na montagem da rotina e entram na consulta, evitando duplicar essa lógica em uma cópia que é atualizada em outro momento.

## 2. Modelo de dados

### 2.1. Labels e propriedades dos nós

As propriedades abaixo descrevem as entidades e os vínculos usados no check-up.

| Label | Propriedade | Tipo lógico | Descrição e motivo de existir |
| --- | --- | --- | --- |
| `Usuario` | `id` | Identificador | Liga o usuário copiado à referência de origem e permite localizar seus favoritos. Tem unicidade documentada. |
| `Usuario` | `rodada` | Identificador de sincronização | Marca que o nó participou da rodada atual, permitindo distinguir dados ainda presentes dos que deixaram a origem. |
| `Produto` | `id` | Identificador | Distingue o produto do catálogo e serve de referência aos produtos da rotina. Tem unicidade documentada. |
| `Produto` | `nome` | Texto | Permite apresentar o produto envolvido em um aviso. |
| `Produto` | `categoria` | Categoria | Delimita produtos comparáveis na verificação de repetição. |
| `Produto` | `rodada` | Identificador de sincronização | Participa da identificação de produtos atualizados ou removidos da origem. |
| `Ingrediente` | `id` | Identificador | Referencia o ingrediente do PostgreSQL, evitando depender do nome para identificar sua presença na composição. Tem unicidade documentada. |
| `Ingrediente` | `inci` | Texto | Nome INCI usado na associação ao arquivo de tipos de ativo. O mapeamento descrito usa INCI em maiúsculas. |
| `Ingrediente` | `nome` | Texto | Nome do ingrediente para contextualização e apresentação. |
| `Ingrediente` | `rodada` | Identificador de sincronização | Indica participação na cópia atual. |
| `TipoAtivo` | `nome` | Texto | Identifica a categoria funcional de ativo usada pelas regras. Tem unicidade documentada. |
| `TipoAtivo` | `rodada` | Identificador de sincronização | Permite identificar tipos que deixaram de participar da cópia atual. |

### 2.2. Relacionamentos, direção e propriedades

| Origem | Relacionamento | Destino | Propriedades de domínio informadas | Por que existe e como a direção é usada |
| --- | --- | --- | --- | --- |
| `Usuario` | `FAVORITOU` | `Produto` | Nenhuma | Representa os produtos favoritos da pessoa e permite partir dela para os produtos relacionados. |
| `Produto` | `CONTEM` | `Ingrediente` | `posicao` | Expressa a composição e a ordem dos ingredientes, permitindo alcançar ativos a partir do produto. |
| `Ingrediente` | `E_DO_TIPO` | `TipoAtivo` | Nenhuma | Traduz um ingrediente específico para um tipo de ativo ao qual se aplicam as regras. |
| `TipoAtivo` | `CONFLITA_COM` | `TipoAtivo` | `severidade`, `motivo`, `fonte`, `revisado` | Relaciona tipos envolvidos em conflito. A direção armazenada orienta o vínculo; a detecção deve apresentar cada par de produtos uma única vez. |
| `TipoAtivo` | `PRECISA_DE` | `TipoAtivo` | `periodo`, `motivo`, `fonte`, `revisado` | Parte do tipo que necessita de outro e aponta para o tipo exigido; o período restringe onde o complemento precisa aparecer. |
| `TipoAtivo` | `VEM_ANTES_DE` | `TipoAtivo` | `motivo`, `fonte`, `revisado` | Parte do tipo que deve ser aplicado antes e aponta para aquele que deve vir depois. A direção é essencial à interpretação da ordem. |

A estratégia geral informa que nós e relações recebem `rodada`; as relações de regra também são expressamente descritas com essa propriedade. Assim, `rodada` é uma marca técnica adicional às propriedades de domínio da tabela, inclusive nos vínculos de composição e favoritos segundo a estratégia apresentada.

| Propriedade de relacionamento | Tipo lógico ou domínio fornecido | Motivo de existir |
| --- | --- | --- |
| `CONTEM.posicao` | Ordem numérica | Preserva a posição na lista INCI, descrita no material como indicação de concentração decrescente. |
| `CONFLITA_COM.severidade` | Nível | Qualifica o conflito. |
| `PRECISA_DE.periodo` | Manhã, noite ou vazio; no CSV, `manha`, `noite` ou vazio | Indica o período em que o ativo exigido precisa existir. Não é o período de uso armazenado no produto. |
| `motivo` | Texto | Explica por que a regra gera um aviso, evitando uma relação sem justificativa legível. |
| `fonte` | Referência | Conserva a origem que fundamenta a regra e acompanha a explicação do aviso. |
| `revisado` | Indicador derivado de `sim` ou não no CSV | Registra a situação de revisão da regra. |
| `rodada` | Identificador único da rodada | Permite detectar relações que não foram renovadas pela cópia atual, como um favorito desfeito ou regra removida. |

### 2.3. Fontes das regras

`tipos_de_ativo.csv` fornece o vínculo entre ingrediente e tipo. Não contém uma lista de produtos, períodos ou sequências de aplicação.

| Coluna | Conteúdo | Papel no grafo |
| --- | --- | --- |
| `ingrediente_inci` | Nome INCI em maiúsculas | Localiza o ingrediente que será associado ao tipo. |
| `tipo` | Nome do tipo de ativo | Identifica o destino de `E_DO_TIPO`. |

`regras.csv` define relações entre tipos. Cada linha é validada; uma linha inválida interrompe a sincronização com a indicação da linha que causou o erro.

| Coluna | Conteúdo informado | Papel e motivo |
| --- | --- | --- |
| `tipo` | Tipo de ativo de origem | Define de onde parte a regra. |
| `regra` | `conflita_com`, `precisa_de` ou `vem_antes_de` | Seleciona o relacionamento correspondente. |
| `outro_tipo` | Tipo de ativo de destino | Define o outro lado da regra. |
| `periodo` | Vazio, `manha` ou `noite` | Só possui sentido em `PRECISA_DE`. |
| `severidade` | Nível da regra | Alimenta a gravidade quando aplicável; a propriedade está explicitamente prevista em `CONFLITA_COM`. |
| `motivo` | Texto | Explica a regra e o aviso que ela pode gerar. |
| `fonte` | Referência | Registra a fundamentação da regra. |
| `revisado` | `sim` ou não | Indica a revisão conforme o arquivo. |

Há uma segunda origem para o tipo `Filtro UV`: ingredientes pertencentes à categoria de mesmo nome, ou às categorias filhas no PostgreSQL, são associados automaticamente a esse tipo. Quando essa categoria não está disponível no conjunto de dados de origem, o mapeamento utiliza apenas o CSV. A hierarquia de categorias participa dessa derivação.

### 2.4. Informações que entram na consulta

O período e a ordem dos produtos são calculados pela Veninha e fornecidos à verificação. Eles não são propriedades dos nós `Produto` nem dos vínculos `FAVORITOU`. Um favorito representa o interesse da pessoa. O período e a posição de uso pertencem à rotina.

Essa divisão conserva uma única lógica de montagem da rotina. Se manhã, noite e posição de aplicação também fossem copiados para o grafo, haveria uma segunda representação sujeita a ficar diferente da rotina recém-montada. O grafo fornece composição e regras; a rotina consultada fornece o contexto de uso.

## 3. Exemplo de check-up da rotina

Considere uma rotina com Produto A, associado a um retinoide, à noite, e Produto B, associado a Filtro UV, pela manhã. A relação de necessidade exige Filtro UV pela manhã. O produto matinal pode atender à exigência do produto noturno. Se o Produto B estiver apenas à noite, a necessidade matinal permanece. A verificação considera o dia inteiro antes de filtrar os avisos pelo período solicitado.

## 4. Ciclo de vida dos dados

A sincronização é acionada manualmente. A atualização do grafo depende de uma execução iniciada após mudanças no catálogo, nos favoritos ou nas regras; essas alterações não disparam automaticamente uma cópia. O fluxo de sincronização foi definido sem agendamento periódico. Cada execução gera um identificador único, `rodada`. Os dados lidos das fontes são gravados ou atualizados com essa marca, em lotes de 1.000. A própria sincronização cria as constraints de unicidade descritas na seção 5.

Ao final, nós e relações com marca antiga são eliminados. Um favorito desfeito, um produto retirado da origem ou uma regra removida do CSV deixa de ser renovado e pode ser identificado nessa limpeza. O descarte decorre da comparação com a rodada atual e das mudanças nas fontes.

A intenção declarada é conservar os dados anteriores durante a atualização, evitando esvaziar o grafo antes de copiar os dados novos. O uso de marcação e limpeza ao final atende a essa intenção de substituição progressiva.

## 5. Restrições de unicidade

Quatro constraints de unicidade são documentadas. Elas distinguem entidades da mesma label e sustentam a atualização dos mesmos registros entre rodadas, em vez de criar uma nova entidade lógica para cada cópia.

| Constraint informada | Consulta ou operação atendida | Motivo |
| --- | --- | --- |
| Unicidade de `Produto.id` | Localizar ou atualizar um produto pela referência de origem e selecionar produtos da rotina. | Evita múltiplos nós para o mesmo identificador de produto. |
| Unicidade de `Ingrediente.id` | Relacionar composições ao ingrediente correspondente. | Mantém um ingrediente compartilhado entre diferentes produtos. |
| Unicidade de `Usuario.id` | Recuperar os favoritos do usuário copiado. | Evita duplicar a pessoa entre rodadas. |
| Unicidade de `TipoAtivo.nome` | Localizar os tipos citados pelos mapeamentos e pelas regras. | Mantém um ponto comum para os ingredientes de um mesmo tipo. |

## 6. Regras de negócio refletidas no banco

### 6.1. Conflitos no mesmo período

A verificação parte dos produtos da rotina e alcança seus tipos de ativo por `CONTEM` e `E_DO_TIPO`. Quando dois produtos do mesmo período estão associados a tipos relacionados por `CONFLITA_COM`, pode ser produzido um aviso. Cada par de produtos aparece uma única vez, mesmo que existam vários caminhos entre seus ingredientes e tipos.

O período faz parte do contexto da rotina. Retinoide à noite e ácido pela manhã não configuram o conflito de mesmo período descrito no material.

### 6.2. Ativo complementar faltando

Para cada tipo presente, a verificação percorre `PRECISA_DE` e procura um produto com o tipo exigido no período indicado pela regra. É sempre usada a rotina do dia inteiro. Assim, um produto matinal pode atender a uma exigência associada a um produto noturno.

O exemplo fornecido exige filtro UV pela manhã: um protetor usado apenas à noite não satisfaz esse requisito. O papel de `periodo` é restringir a presença do complemento, e não copiar para o grafo o período em que o produto de origem é utilizado.

### 6.3. Ordem de aplicação

A verificação compara as posições fornecidas na rotina com a direção de `VEM_ANTES_DE`. Se o produto com o tipo de origem estiver depois do produto com o tipo de destino, há uma ordem a ajustar. `CONTEM.posicao` não participa como posição de aplicação: esse campo representa a ordem dos ingredientes no rótulo, que é uma informação diferente.

### 6.4. Produtos repetidos

A repetição compara dois produtos da mesma categoria, no mesmo período. Para cada produto, são considerados seus ingredientes. O índice de Jaccard é o número de ingredientes em comum dividido pelo número total de ingredientes distintos presentes em pelo menos um dos dois produtos. Um valor de 60% ou mais gera o aviso descrito.

Por exemplo, se dois conjuntos têm 6 ingredientes em comum e 10 ingredientes distintos na união, a similaridade é 6/10, ou 60%, atingindo o limite. Isso mede sobreposição de composição, sem determinar igualdade de concentrações ou de desempenho. O critério fornecido não atribui peso pela posição dos ingredientes.

### 6.5. Conteúdo dos avisos

Cada aviso informa tipo, período, produtos ou ativos envolvidos, motivo e fonte. Os avisos são filtrados pelo período pedido: manhã, noite ou ambos. A seleção do período de saída não deve ser confundida com reduzir a entrada apenas à metade do dia, pois a regra de necessidade usa a rotina completa.
