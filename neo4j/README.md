# Neo4j — grafo de produtos e compatibilidade

## Documentação

- [`checkup_rotina.md`](checkup_rotina.md): o grafo do check-up da rotina da
  Veninha, com nós, relações, regras dos CSV, sincronização por `rodada` e as
  quatro verificações (conflito, ativo faltando, ordem e produtos repetidos).

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
revisão. Não há conector Neo4j no pipeline PostgreSQL deste repositório; a
sincronização do grafo está no Venus-AI-Sdk (`venus_sdk/checkup/sincronizar.py`)
e roda manualmente pelo workflow `Sincronizar Neo4j` do Venus-AI-api. O grafo é
uma projeção derivada do PostgreSQL.

## Ponto de atenção identificado

Em `constraints.cyp`, a constraint `tipo_nome` referencia `p.id` dentro do
bloco de `TipoAtivo`; o contrato esperado é `t.nome`. O script original foi
preservado, mas deve ser corrigido antes de execução.
