# 09 — Procedimento de reprodução

## Objetivo

Recriar, de forma controlada, a cadeia que originalmente produziu o SQL bruto e depois o catálogo limpo.

## Fase A — dados de origem

1. colocar a planilha ANVISA em `01_fontes/`;
2. obter uma versão datada das fontes UE/CosIng/EUR-Lex usadas no projeto;
3. consultar PubChem para os CAS/identificadores necessários;
4. guardar cache/resposta bruta e data de consulta.

## Fase B — construção do dataset intermediário

1. normalizar INCI/CAS;
2. consolidar duplicidades;
3. anexar tradução ANVISA;
4. anexar evidência europeia;
5. anexar propriedades PubChem;
6. gerar propriedades, aliases, efeitos e regulações;
7. emitir um dataset intermediário versionado.

## Fase C — geração do SQL

Gerar `venus_v12_load.sql` a partir do dataset intermediário.

O SQL deve manter:

- `source_type`;
- `source_reference`;
- id lógico INCI;
- relações por FK;
- `ON CONFLICT` consistente com o modelo destino.

## Fase D — QA da carga bruta

Antes de inserir no banco final:

- contar cada tipo de INSERT;
- verificar referências a categorias/regulações/profile tags;
- validar parsing;
- calcular SHA-256 do arquivo;
- registrar manifesto da execução.

## Fase E — limpeza

Executar no novo pipeline:

1. diagnóstico;
2. reparo de `common_name`;
3. decisão da política `standard`;
4. geração do snapshot limpo;
5. validação de órfãos;
6. carga transacional.

No pipeline unificado atual, a melhor implementação é fazer as decisões em memória e inserir apenas o snapshot aprovado. Isso evita carregar os 18.122 candidatos removíveis no banco novo.

## Fase F — validação final

Conferir:

- 7.000+ ingredientes;
- zero órfãos;
- categorias resolvidas;
- aliases/efeitos/propriedades consistentes;
- fontes presentes;
- catálogo técnico populado;
- índices e funções criados.

## Regra de ouro

O número "7.923" é a evidência de uma execução histórica específica. Ele deve ser usado como **meta de regressão**, não como uma constante cega: se as fontes externas ou as tabelas de referência mudarem, o manifesto deve explicar a diferença.

## Ver também

- `REFERENCIAS_HISTORICAS.md` — artefatos originais que fundamentam este procedimento.
- `../PROCESSO_ETL_COMPLETO.md` — versão executiva/resumida desta mesma cadeia.
- `../08_qa_evidencias/README.md` — evidências reais da Fase D/F já executada em 13/08/2026.
