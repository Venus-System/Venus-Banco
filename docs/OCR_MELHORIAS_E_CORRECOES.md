# OCR — pontos para corrigir e melhorar

Documento de referência para o fluxo de leitura de rótulos, composição, resolução de ingredientes e liberação do produto para classificação.

## Objetivo

O OCR deve transformar uma imagem de rótulo em uma composição canônica, auditável e segura para o banco, sem inventar ingredientes, notas de risco ou evidências. O resultado esperado é:

1. extrair o texto bruto;
2. separar os ingredientes na ordem do rótulo;
3. resolver cada token para um ingrediente canônico;
4. registrar os casos não resolvidos ou ambíguos;
5. validar a composição;
6. promover automaticamente o produto quando todos os requisitos estiverem atendidos;
7. deixar a classificação para a API de classificação, depois que os dados estiverem prontos.

## Fluxo correto

```text
Imagem do rótulo
    ↓
OCR bruto + confiança + versão do motor
    ↓
Texto normalizado, preservando o original
    ↓
Tokens de ingredientes com posição
    ↓
Resolução por chave exata, alias e regras controladas
    ↓
product_ingredients + issues de resolução
    ↓
Recibo de composição e validação
    ↓
needs_review ou produto pronto/verified
    ↓
POST /api/base-scores executado separadamente
```

## O que o banco já oferece

O banco já possui estruturas para suportar o fluxo:

- `product_labels`: texto normalizado do rótulo;
- `product_composition_receipts`: texto bruto, origem, hash da fórmula, contagens e status de validação;
- `product_ingredient_resolution_issues`: tokens não encontrados ou ambíguos;
- `ingredient_resolution_keys`: chaves de resolução normalizadas;
- `ingredient_aliases`: nomes alternativos e aliases dos ingredientes;
- `product_ingredients`: vínculo do produto com o ingrediente canônico e posição no rótulo;
- `product_versions.formula_signature`: identificação estável da composição;
- triggers para resolver ingredientes e promover/rebaixar produtos;
- `v_product_score_readiness`: visão de prontidão para classificação.

Essas estruturas só funcionam corretamente se o OCR enviar dados completos e não mascarar incertezas.

## Correções prioritárias

### P0 — Bloqueadores de qualidade

#### 1. Preservar sempre o texto bruto

O OCR não pode substituir o texto original pelo texto corrigido.

Registrar sempre:

- imagem ou referência do arquivo;
- texto bruto retornado pelo motor;
- texto normalizado usado para resolução;
- idioma detectado;
- motor e versão do OCR;
- data da extração;
- confiança global e, quando possível, confiança por bloco/token;
- coordenadas do texto ou bounding boxes;
- hash da imagem e hash do texto.

O texto normalizado serve para buscar; o texto bruto serve para auditoria e revisão.

#### 2. Corrigir a separação dos ingredientes

O parser precisa tratar corretamente:

- vírgulas, ponto e vírgula, quebras de linha e listas numeradas;
- parênteses e colchetes;
- percentuais e concentrações;
- nomes com hífen, barra, ponto e acentos;
- `Aqua/Water`, `Parfum/Fragrance` e nomes multilíngues;
- ingredientes que aparecem em mais de uma linha;
- texto antes de `Ingredients`, `Ingredientes` ou equivalentes;
- texto depois do fim da composição;
- rótulos com duas colunas;
- ingredientes cortados ou parcialmente ilegíveis.

O parser não deve separar por vírgula dentro de parênteses nem descartar tokens apenas porque contêm números ou símbolos.

#### 3. Normalizar sem alterar o significado

Aplicar uma normalização determinística:

- remover espaços duplicados;
- normalizar maiúsculas/minúsculas;
- normalizar Unicode e acentos somente para a chave de busca;
- uniformizar hífens, aspas e caracteres invisíveis;
- remover pontuação externa;
- preservar a forma original para exibição/auditoria;
- normalizar espaços ao redor de `/`, `-`, `(` e `)`;
- não remover números, percentuais ou sufixos que diferenciem ingredientes.

Deve existir uma única função de normalização usada pelo OCR, banco e reprocessamento. Duas regras diferentes geram duplicidade e resolução inconsistente.

#### 4. Resolver por ingrediente canônico

A ordem de resolução deve ser:

1. `inci_name` exato após normalização;
2. alias exato em `ingredient_aliases`;
3. chave em `ingredient_resolution_keys`;
4. regra específica aprovada para variantes conhecidas;
5. candidato ambíguo ou não encontrado.

O OCR nunca deve criar um novo ingrediente apenas porque não encontrou correspondência. Criação automática só pode ocorrer quando houver uma regra de cadastro controlada, com fonte e status de revisão.

#### 5. Tratar ambiguidade como ambiguidade

Quando dois ou mais ingredientes podem corresponder ao token, o resultado não pode ser escolhido silenciosamente.

Registrar:

- token original;
- candidatos;
- método de resolução;
- confiança da resolução;
- motivo da ambiguidade;
- posição no rótulo;
- origem e versão da regra.

O produto deve permanecer em `needs_review` até a decisão, salvo uma regra canônica previamente aprovada para aquele alias.

#### 6. Não inventar notas de ingrediente

O OCR não deve preencher:

- `irritation_risk_level`;
- `comedogenicity_score`;
- `biodegradability_level`;
- `environmental_risk_level`;
- `scientific_confidence`.

Para ingrediente novo ou não avaliado, o estado correto é:

```text
scientific_confidence = 0
scientific_confidence_state = default
```

As quatro notas só devem ser preenchidas por avaliações registradas em `ingredient_risk_assessments`, com metodologia, versão, fonte, justificativa e status aprovado.

O OCR pode resolver o ingrediente; ele não pode transformar resolução em avaliação científica.

### P1 — Composição e validação

#### 7. Garantir contagens coerentes

O recibo de composição deve permitir conferir:

```text
expected_count = quantidade de tokens válidos extraídos
resolved_count = tokens vinculados a ingredientes canônicos
unresolved_count = tokens sem resolução ou ambíguos
```

Regras:

- `resolved_count + unresolved_count` deve corresponder ao conjunto de tokens processáveis;
- token ignorado deve ter motivo registrado;
- token duplicado deve manter sua posição, mesmo que o vínculo canônico seja o mesmo;
- `validation_status = VALID` somente quando não existir pendência;
- `WARNING`, `INVALID` e `LEGACY_UNVERIFIED` não devem liberar classificação como composição válida;
- todo recibo precisa ter `source_reference` e `formula_hash`.

#### 8. Não confundir ingrediente repetido com token perdido

`product_ingredients` representa o ingrediente canônico usado pelo produto, enquanto o OCR trabalha com tokens posicionais.

O fluxo precisa preservar os dois níveis:

- tokens do rótulo para auditoria e contagem;
- vínculos canônicos para classificação.

Se o mesmo ingrediente aparecer duas vezes, a posição e o texto bruto devem permanecer auditáveis sem criar duplicidade artificial no catálogo.

#### 9. Criar tipos de issue suficientes

Além de “não encontrado”, registrar pelo menos:

- `OCR_LOW_CONFIDENCE`;
- `TRUNCATED_TOKEN`;
- `PARSER_ERROR`;
- `NOT_FOUND`;
- `AMBIGUOUS_MATCH`;
- `DUPLICATE_TOKEN`;
- `UNSUPPORTED_FORMAT`;
- `MISSING_LABEL_SECTION`;
- `SOURCE_CONFLICT`;
- `REFERENCE_FORMULA_ONLY`.

Cada issue precisa conter posição, token bruto, mensagem, origem e data.

#### 10. Reprocessar de forma idempotente

Reprocessar a mesma imagem ou fórmula não pode duplicar:

- produto;
- versão;
- ingrediente;
- alias;
- vínculo em `product_ingredients`;
- recibo;
- issue.

Usar `image_hash`, `formula_hash`, `formula_signature` e chaves únicas. Um novo OCR da mesma imagem deve criar uma nova tentativa auditável ou atualizar a tentativa atual, conforme a política definida, mas nunca gerar duplicidade silenciosa.

#### 11. Corrigir a ordem de gravação

O fluxo recomendado é:

1. criar ou localizar produto e versão;
2. registrar imagem/rótulo e texto bruto;
3. salvar o recibo da composição;
4. extrair e resolver os tokens;
5. gravar `product_ingredients`;
6. recalcular contagens e issues;
7. validar o recibo;
8. deixar o trigger promover ou rebaixar a versão.

Não marcar a versão como pronta antes de o recibo e os vínculos canônicos existirem.

### P1 — Regras específicas de catálogo

#### 12. Consolidar aliases de fragrância

Os seguintes textos devem apontar para a categoria canônica `Agente Perfumante` quando o contexto for cosmético:

- `PARFUM`;
- `FRAGRANCE`;
- `PARFUM / FRAGRANCE`;
- `AROMA`.

O aviso do produto deve depender da categoria canônica, não de uma lista fixa de IDs ou do texto exato extraído pelo OCR.

#### 13. Resolver marcas e produtos sem duplicar

Normalizar marca e nome de produto antes de inserir:

- caixa e espaços;
- acentos e caracteres especiais;
- hífens e abreviações;
- volume e unidade;
- variantes de embalagem;
- nomes iguais em fontes diferentes.

Antes de criar uma marca, consultar a marca canônica. Antes de criar uma nova versão, comparar a `formula_signature`.

Marcas como CeraVe, La Roche-Posay e Rexona não podem voltar a ser duplicadas por variação de cadastro.

#### 14. Não copiar fórmula de referência como se fosse a fórmula do produto

Quando a composição oficial exata não estiver disponível, uma fórmula de referência pode ser usada apenas se estiver claramente marcada como referência:

- `source_type = system` ou equivalente;
- `source_reference` com a fonte original;
- `evidence_level = low` quando aplicável;
- `validation_status` diferente de `VALID` até a confirmação do rótulo;
- issue `REFERENCE_FORMULA_ONLY`.

A composição de outro produto ou da mesma linha não deve ser apresentada como composição exata do SKU analisado.

#### 15. Não gerar descrição de usuário a partir do texto técnico do OCR

O OCR deve resolver o ingrediente canônico. A descrição exibida deve vir de `ingredients.description`, em português, e não de `function_summary` ou do token bruto.

O campo `function_summary` continua sendo técnico/canônico. O campo `description` é a explicação destinada ao usuário.

### P1 — Status e liberação

#### 16. Definir claramente quando usar `needs_review`

A versão deve ficar em `needs_review` quando houver:

- token não resolvido;
- correspondência ambígua;
- OCR com baixa confiança em parte crítica do rótulo;
- recibo ausente ou inconsistente;
- fórmula de referência não confirmada;
- conflito entre fonte oficial e OCR;
- ingrediente canônico sem avaliação necessária para a classificação.

Não usar `needs_review` para exigir aprovação manual de embalagem, ética ou performance quando a regra do produto não exigir isso.

#### 17. Promover automaticamente somente produto realmente pronto

O trigger pode promover a versão para `verified` somente quando:

- ela é a versão atual;
- existe recibo atual;
- o recibo é `VALID`;
- `unresolved_count = 0`;
- existe pelo menos um ingrediente vinculado;
- todos os ingredientes usados têm avaliação válida;
- nenhum issue bloqueador está aberto.

Qualquer alteração posterior no rótulo, composição, ingrediente ou avaliação deve invalidar o score antigo e reavaliar a prontidão.

#### 18. Separar “resolvido” de “avaliado”

Um ingrediente pode estar resolvido no catálogo e ainda não ter avaliação científica.

O OCR deve retornar estados separados:

```text
resolution_status = resolved | ambiguous | unresolved
evaluation_status = evaluated | not_evaluated
```

Não usar `scientific_confidence` padrão como prova de avaliação.

### P2 — Observabilidade, segurança e operação

#### 19. Registrar métricas do OCR

Acompanhar por motor, versão e origem:

- imagens processadas;
- extrações bem-sucedidas;
- tempo médio e percentis;
- tokens por rótulo;
- taxa de resolução automática;
- taxa de ambiguidade;
- taxa de não encontrados;
- taxa de baixa confiança;
- produtos promovidos;
- produtos enviados para revisão;
- reprocessamentos;
- divergências entre OCR e fonte oficial.

#### 20. Ter fila de revisão operacional

A fila deve permitir revisar o token e o rótulo original, escolher o ingrediente canônico, cadastrar alias quando aprovado e reprocessar somente a versão afetada.

Toda decisão manual precisa registrar usuário, data, justificativa e fonte. A correção manual não deve apagar o token original.

#### 21. Garantir segurança do upload

Validar antes do OCR:

- tamanho máximo;
- tipo MIME real;
- extensão;
- resolução mínima;
- conteúdo não executável;
- limite de páginas/imagens;
- remoção de metadados sensíveis quando necessário.

Não registrar tokens, imagens ou dados pessoais completos em logs de aplicação sem necessidade.

#### 22. Separar filas de retry e erro definitivo

Falha temporária do motor OCR deve ser reprocessável. Erro de formato, rótulo ilegível ou fonte ausente deve ir para uma fila de revisão, sem loop infinito.

Registrar tentativas, último erro, próxima tentativa e versão do motor usada.

## Contrato recomendado de saída do OCR

```json
{
  "productVersionId": 123,
  "source": {
    "type": "ocr",
    "reference": "media_assets:456",
    "engine": "nome-do-motor",
    "engineVersion": "1.0.0",
    "imageHash": "...",
    "textHash": "..."
  },
  "rawText": "INGREDIENTS: AQUA, PARFUM, ...",
  "normalizedText": "AQUA, PARFUM, ...",
  "tokens": [
    {
      "position": 1,
      "raw": "AQUA",
      "normalized": "aqua",
      "ingredientId": 1,
      "resolutionStatus": "resolved",
      "resolutionMethod": "inci_exact",
      "confidence": 0.99,
      "bbox": [0, 0, 100, 20]
    }
  ],
  "validation": {
    "expectedCount": 2,
    "resolvedCount": 2,
    "unresolvedCount": 0,
    "status": "VALID"
  }
}
```

## Checklist de aceite

Antes de considerar o OCR pronto para produção, validar:

- [ ] o texto bruto é preservado;
- [ ] a versão do motor e a origem são registradas;
- [ ] a extração funciona em rótulos com uma e duas colunas;
- [ ] parênteses, barras, percentuais e quebras de linha não quebram o parser;
- [ ] `PARFUM`, `FRAGRANCE` e `AROMA` são resolvidos pela regra canônica;
- [ ] todo token tem estado de resolução;
- [ ] ambiguidades nunca são escolhidas silenciosamente;
- [ ] nenhum ingrediente novo recebe nota ou confiança inventada;
- [ ] `expected_count`, `resolved_count` e `unresolved_count` fecham matematicamente;
- [ ] `VALID` não é usado com pendência;
- [ ] a composição de referência é diferenciada da composição exata;
- [ ] o processamento é idempotente;
- [ ] o produto só sai de `needs_review` quando o gate estiver completo;
- [ ] alterações posteriores invalidam scores antigos;
- [ ] há fila e auditoria para revisão manual;
- [ ] há métricas e retry controlado;
- [ ] o OCR não chama a API de classificação automaticamente sem autorização operacional.

## Ordem recomendada de execução

1. corrigir o contrato de entrada/saída do OCR;
2. preservar imagem, texto bruto, hash e versão do motor;
3. corrigir parser e normalização;
4. consolidar aliases e chaves de resolução;
5. implementar resolução com estados `resolved`, `ambiguous` e `unresolved`;
6. validar recibo e contagens;
7. conectar os triggers de prontidão;
8. revisar os casos pendentes existentes;
9. executar testes de regressão nos produtos atuais;
10. só então executar novamente o cálculo de classificação.

## Regra principal

O OCR pode descobrir e organizar evidências. Ele não pode transformar incerteza em dado científico, nem transformar uma fórmula parecida em fórmula oficial. Toda informação não confirmada deve permanecer visível como pendência e impedir a promoção automática quando afetar a composição ou a classificação.
