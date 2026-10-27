# Neo4j — grafo de produtos e compatibilidade

## Papel

Os scripts fornecidos modelam um grafo derivado para consultas de composição e
compatibilidade. Os nós são `Produto`, `Ingrediente`, `TipoAtivo` e `Usuario`.

## Relações

| Relação | Significado |
|---|---|
| `CONTEM` | Produto contém ingrediente; guarda posição e rodada. |
| `FAVORITOU` | Usuário favoritou produto. |
| `E_DO_TIPO` | Ingrediente pertence a um tipo ativo. |
| `CONFLITA_COM` | Dois tipos ativos são incompatíveis em um período. |
| `PRECISA_DE` | Um tipo ativo exige outro tipo ativo. |
| `VEM_ANTES_DE` | Ordem recomendada entre tipos ativos. |

Todas as cargas usam `MERGE` e registram `rodada`, permitindo identificar a
origem temporal da carga. `consultas/` contém os casos de conflito, requisito
ausente, ordem e repetição de produtos.

## Arquivos incorporados

- `constraints.cyp`: unicidade e obrigatoriedade dos nós e relações.
- `carga.cyp`: carga parametrizada em `$dados` e `$rodada`.
- `seed.cyp`: fixture demonstrativo.
- `consultas/*.cyp`: consultas de compatibilidade.

Os scripts foram copiados do `Banco_de_dados.zip` e não foram executados nesta
revisão. Não há conector Neo4j no pipeline PostgreSQL deste repositório; o grafo
deve ser tratado como projeção derivada até que um job de sincronização seja
versionado.

## Ponto de atenção identificado

Em `constraints.cyp`, a constraint `tipo_nome` referencia `p.id` dentro do
bloco de `TipoAtivo`; o contrato esperado é `t.nome`. O script original foi
preservado, mas deve ser corrigido antes de execução.
