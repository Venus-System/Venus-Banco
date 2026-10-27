# Decisões de score dos produtos e da classificação

## O que o banco faz e o que a API faz

A decisão central foi não transformar o banco em uma segunda implementação da
classificação. O banco prepara, valida e protege os dados de entrada; a
Venus-Classificacao calcula os scores finais dos produtos.

### Responsabilidades do banco

- manter o catálogo de ingredientes;
- resolver o OCR para ingredientes canônicos;
- registrar composição e fonte da fórmula;
- verificar se todos os tokens foram resolvidos;
- verificar se cada ingrediente possui quatro avaliações;
- expor confidence e avaliação para o backend;
- bloquear scores de produto quando os dados de entrada estiverem incompletos;
- preservar histórico de avaliações e scores invalidados;
- automatizar a prontidão de produtos novos.

### Responsabilidades da API de classificação

- calcular `product_scores`;
- calcular os componentes de saúde, ambiental, ética, performance e
  transparência;
- calcular o score geral;
- calcular confidence do resultado;
- gravar ou atualizar os resultados operacionais;
- recalcular os produtos quando os ingredientes ou a metodologia mudarem.

O banco não deve inserir manualmente um `product_score` para “destravar” o
mobile. Isso criaria um resultado que não passou pelo mesmo cálculo dos demais
produtos.

## Por que os resultados antigos pareciam 60–70

O score final é uma composição de componentes. Ele não deve ser interpretado
como média simples dos quatro scores de ingrediente. O resultado depende da
implementação da Venus-Classificacao e dos efeitos associados à composição,
além das dimensões de produto.

Os principais fatores que causavam resultados artificiais eram:

1. ingredientes com `scientific_confidence` positivo por padrão;
2. campos de risco zerados sendo lidos como ausência de risco;
3. produto sem composição completa recebendo fallback;
4. benefícios não validados contando como performance;
5. embalagem, ética ou performance ausentes sendo tratados como valores
   neutros sem distinguir “não informado” de “avaliado”;
6. scores antigos gravados antes da aplicação dos guardrails;
7. biodegradabilidade interpretada na direção errada.

A correção foi feita na entrada e no estado de prontidão. O valor final ainda
deve ser recalculado pela API depois de qualquer alteração relevante.

## Prontidão de uma versão de produto

Uma versão atual só pode ser considerada pronta quando possui, no mínimo:

1. vínculo com ingredientes;
2. recibo de composição atual;
3. recibo com `validation_status = 'VALID'`;
4. contagem esperada igual à contagem resolvida;
5. nenhum token não resolvido;
6. quatro dimensões aprovadas para cada ingrediente usado;
7. dados de embalagem compatíveis com o contrato vigente;
8. demais dimensões exigidas pelo gate atual.

As funções principais são:

- `venus.fn_product_version_data_ready(product_version_id)`;
- `venus.fn_product_version_score_ready(product_version_id)`.

Os triggers de prontidão rebaixam versões incompletas para `needs_review` e
impedem a gravação de score operacional quando o requisito não é atendido.

## Composição e OCR

O OCR não é tratado como fórmula final sem validação. O fluxo é:

```text
imagem/rótulo
    ↓
texto normalizado
    ↓
resolução por INCI, alias e nome comum
    ↓
lista de ingredientes canônicos
    ↓
recibo de composição
    ↓
gate de prontidão
    ↓
Venus-Classificacao
```

Se um token não for encontrado ou for ambíguo, ele entra em
`venus.product_ingredient_resolution_issues`. A composição não deve ser
substituída silenciosamente por uma aproximação.

Para produtos sem composição exata, uma fórmula de referência pode ser
registrada, mas precisa indicar explicitamente:

- `reference_formula = true`;
- produto de referência;
- fonte da fórmula;
- nível de evidência baixo;
- observação de variante.

Uma fórmula de referência não deve ser apresentada como se fosse a fórmula
fotografada do SKU.

## Benefícios e performance

Benefício cosmético e performance do produto não são equivalentes. Um efeito
entra no componente de performance apenas quando:

- está classificado como `benefit`;
- possui `review_status = 'validated'`;
- possui evidência e fonte compatíveis.

Um benefício pendente é convertido para `neutral` no gate, em vez de gerar
bonus artificial. Isso evita transformar descrições de marketing ou funções
genéricas em melhora mensurável de performance.

## Confiança do produto

O confidence do produto não deve ser preenchido manualmente no banco. Ele é
derivado dos ingredientes e da execução oficial da classificação.

O banco fornece os pré-requisitos para que a API produza um confidence
coerente:

- cada ingrediente precisa de assessment;
- proxies ficam identificadas como `assessed_indirect_v2`;
- fontes diretas podem elevar a qualidade sem alterar o contrato;
- produto sem composição não recebe confidence artificial.

Quando a API recalcula um produto, a leitura correta é:

1. score final: resultado da classificação;
2. confidence do resultado: confiança calculada pela API;
3. estado do ingrediente: direto, indireto ou não avaliado;
4. fonte do ingrediente: referência rastreável.

## Por que todos os ingredientes receberam score positivo após a decisão 2

Foi autorizada a aplicação de proxies `v2/low` para os 5.008 ingredientes que
ainda não tinham os quatro assessments. A regra usa piso `1` para impedir que
um ingrediente não estudado pareça ter risco zero.

O resultado no `Venus-qa` foi:

- `5.008` pendentes antes;
- `0` pendentes depois;
- `8.237` ingredientes com os quatro eixos;
- `8.237` ingredientes classificados na view como `assessed_indirect_v2`;
- `8.237` ingredientes com confidence positivo;
- campos legados de risco sem zeros técnicos após a carga.

Isso resolve a prontidão técnica. Não transforma as proxies em estudos
toxicológicos. A apresentação no mobile deve distinguir, se o produto desejar,
“avaliado por proxy” de “evidência direta”.

## Execução da classificação

O banco não chamou a API durante as correções de score. A ordem operacional é:

1. aplicar migrations e cargas do banco;
2. auditar cobertura e prontidão;
3. executar o `POST /api/base-scores` com usuário administrativo;
4. aguardar a atualização de `product_scores`;
5. validar quantidade de resultados, scores nulos, scores zero e confidence;
6. verificar alguns produtos no mobile;
7. registrar eventuais divergências para nova investigação.

Antes da API, as consultas úteis são:

```sql
SELECT COUNT(*) AS ingredientes_sem_quatro_eixos
  FROM venus.ingredients i
 WHERE NOT venus.fn_has_complete_ingredient_assessment(i.ingredient_id);

SELECT COUNT(*) AS versoes_prontas,
       COUNT(*) FILTER (
           WHERE venus.fn_product_version_data_ready(pv.product_version_id)
       ) AS versoes_com_dados_prontos
  FROM venus.product_versions pv
 WHERE pv.is_current;
```

Depois da API, a ausência de `product_scores` deve ser investigada na API,
não resolvida inserindo valores no banco.

## Reclassificação e histórico

Alterar um ingrediente não recalcula magicamente todos os produtos. A mudança
altera a entrada e marca a necessidade de uma nova execução da API.

O histórico existe para permitir comparação entre execuções, mas o resultado
operacional deve ser o da última classificação válida. Scores invalidados não
devem reaparecer no mobile como se fossem atuais.

## Contrato para produtos novos

Produtos novos devem seguir o mesmo fluxo sem intervenção manual nos scores:

1. inserir o produto e sua versão;
2. inserir ou atualizar o rótulo/OCR;
3. deixar o resolvedor automático procurar INCI, alias e nome comum;
4. registrar a composição e os tokens não resolvidos;
5. usar a avaliação proxy automática para ingredientes sem evidência direta;
6. manter o produto em `needs_review` se a composição estiver incompleta;
7. promover automaticamente quando o gate estiver satisfeito;
8. incluir a versão na próxima execução da classificação.

O banco não precisa de uma nova implementação da API para cada produto novo.
As decisões ficam no catálogo, nos triggers e nas procedures versionadas.
