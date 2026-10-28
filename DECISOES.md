# Venus
## Decisoes tecnicas sobre a existencia das tabelas

Documento tecnico para registrar por que cada tabela fisica existe, qual problema resolve e qual responsabilidade deve permanecer no banco PostgreSQL do Venus.

## 1. Escopo e estado atual

Este documento acompanha o modelo fisico atual do banco, composto por **65 tabelas**, **79 relacionamentos FK** e os schemas de tabelas `venus`, `venus_audit`, `venus_rpa` e `venus_optimization`.

O inventario e os tipos completos de todas as colunas permanecem no [snapshot fisico do banco](docs/database-logical-model.md). O [snapshot SQL](docs/database-logical-model.sql) registra a estrutura implantada, enquanto `sql/00_schema.sql` e `sql/migrations/` registram a evolucao do schema.

As views de `venus` e `venus_bi` nao sao repetidas como tabelas neste documento. Elas sao objetos derivados para consumo operacional, BI e validacao. A decisao de cada tabela abaixo considera normalizacao, integridade referencial, rastreabilidade, curadoria e separacao de responsabilidades entre PostgreSQL, RPA, Cloudinary, MongoDB, Redis e Neo4j.

## 2. Criterios usados nas decisoes

- **Manter como tabela relacional:** a informacao possui identidade, integridade, relacionamento ou regra de negocio que precisa ser validada pelo PostgreSQL.
- **Manter como tabela de ponte:** a relacao e N:N ou representa uma associacao contextual que nao deve ser armazenada em arrays ou JSON.
- **Manter como historico ou evidencia:** a informacao explica uma decisao, uma mudanca, uma origem ou uma avaliacao e nao deve ser perdida quando o dado atual mudar.
- **Manter como staging operacional:** a tabela controla a ingestao, o lote, a falha ou a reconciliacao entre o legado e o modelo normalizado.
- **Manter como governanca:** a tabela formaliza catalogo, acesso, classificacao ou regras de uso dos dados.
- **Nao substituir por Redis/MongoDB:** cache e documento podem acelerar ou preservar payloads, mas nao substituem PKs, FKs, unicidade, auditoria e consistencia do nucleo relacional.

## 3. Identidade, acesso e governanca

### `venus.users`

- **Funcao:** identidade principal do usuario Venus.
- **O que guarda:** conta, identificadores externos, nome, email, status e datas de controle.
- **Campos e relacionamentos:** `user_id` e PK; `firebase_uid` e `email` sao unicos. E referenciada por perfis, preferencias, alergias, listas, reviews, analises, tracking e atividade.
- **Origem dos dados:** Firebase Authentication, API e formularios do aplicativo.
- **Decisao de existencia:** manter como entidade raiz do dominio de usuarios para evitar que identidade e autenticacao fiquem espalhadas em tabelas de negocio.
- **Observacao de arquitetura:** toda informacao dependente do usuario deve apontar para esta tabela quando houver usuario autenticado.

### `venus.admin_users`

- **Funcao:** identidade e governanca de administradores, moderadores e analistas.
- **O que guarda:** conta administrativa, papel, status e credencial protegida quando aplicavel.
- **Campos e relacionamentos:** `admin_user_id` e PK; `email` e unico. `reports.fk_admin_user_id` referencia esta tabela.
- **Origem dos dados:** provisionamento administrativo.
- **Decisao de existencia:** manter separada de `users` para preservar a fronteira de privilegios e permitir politicas de acesso distintas.
- **Observacao de arquitetura:** nao usar `users.role` para representar administracao do sistema.

### `venus.google_oauth_tokens`

- **Funcao:** persistir tokens de integracao Google associados a uma conta.
- **O que guarda:** tokens, identificador do usuario e metadados de expiracao/atualizacao.
- **Campos e relacionamentos:** `google_oauth_token_id` e PK; `fk_user_id` referencia `users` com relacao 1:0..1.
- **Origem dos dados:** fluxo OAuth do backend.
- **Decisao de existencia:** manter isolada porque credenciais de integracao possuem ciclo de vida e controles de seguranca diferentes dos dados de perfil.
- **Observacao de arquitetura:** acesso restrito; nunca expor token em views de BI ou respostas publicas.

### `venus.data_catalog`

- **Funcao:** catalogo tecnico das tabelas e colunas disponibilizadas pelo banco.
- **O que guarda:** metadados de objetos, colunas, tipos, nulabilidade, descricoes, classificacao e sincronizacao.
- **Campos e relacionamentos:** `data_catalog_id` e PK; e consumida pelas views de catalogo.
- **Origem dos dados:** sincronizacao com `information_schema` e regras documentadas.
- **Decisao de existencia:** manter como camada de governanca para que o schema seja explicavel e auditavel sem depender apenas de documentacao externa.
- **Observacao de arquitetura:** e metadado operacional, nao dado de negocio.

### `venus.data_catalog_rules`

- **Funcao:** regras de negocio, acesso e classificacao por tabela e coluna.
- **O que guarda:** descricoes, regras, niveis de acesso, classificacao de dados e observacoes de governanca.
- **Campos e relacionamentos:** chave tecnica por objeto/tabela/coluna; alimenta a sincronizacao de `data_catalog`.
- **Origem dos dados:** curadoria tecnica e atualizacoes de governanca.
- **Decisao de existencia:** manter separada do catalogo derivado para permitir edicao controlada das regras sem perder os metadados coletados automaticamente.
- **Observacao de arquitetura:** alteracoes devem ser versionadas junto com o SQL/documentacao.

## 4. Catalogo de produtos e evidencias

### `venus.brands`

- **Funcao:** cadastro canonico de marcas.
- **O que guarda:** nome, pais, site e claims conhecidos da marca.
- **Campos e relacionamentos:** `brand_id` e PK; `products` e `brand_claim_evidence` referenciam a marca.
- **Origem dos dados:** OCR, sites oficiais, importacao e curadoria administrativa.
- **Decisao de existencia:** manter como entidade independente para evitar repetir atributos da marca em cada produto e permitir evidencias por marca.
- **Observacao de arquitetura:** `NULL` em claims significa desconhecido; nao deve ser convertido automaticamente em `false`.

### `venus.brand_claim_evidence`

- **Funcao:** registrar evidencias que sustentam claims institucionais da marca.
- **O que guarda:** tipo/valor do claim, fonte, nivel de evidencia, nota e metodologia.
- **Campos e relacionamentos:** `brand_claim_evidence_id` e PK; `fk_brand_id` referencia `brands` em 1:N.
- **Origem dos dados:** pesquisa de fonte oficial e validacao administrativa.
- **Decisao de existencia:** manter para separar afirmacao de evidencia e permitir que o sistema diferencie verificado, negativo, conflito e desconhecido.
- **Observacao de arquitetura:** as views de status devem consumir esta tabela, nunca inferir claim a partir do nome da marca.

### `venus.product_categories`

- **Funcao:** taxonomia de produtos.
- **O que guarda:** categorias usadas para navegacao, filtros e classificacao.
- **Campos e relacionamentos:** `product_category_id` e PK; `products` referencia a categoria.
- **Origem dos dados:** curadoria do catalogo e importacoes.
- **Decisao de existencia:** manter normalizada para garantir vocabulário estavel e evitar categorias livres repetidas em `products`.
- **Observacao de arquitetura:** mudancas de nomenclatura devem preservar o identificador tecnico.

### `venus.products`

- **Funcao:** entidade canonica do produto.
- **O que guarda:** marca, categoria, nome, descricao, slug e status de ativacao.
- **Campos e relacionamentos:** `product_id` e PK; `fk_brand_id` e `fk_product_category_id` sao FKs obrigatorias. `product_versions`, favoritos, listas e RPA dependem desta tabela.
- **Origem dos dados:** OCR normalizado, fontes oficiais, importacao e curadoria.
- **Decisao de existencia:** manter como identidade estavel do produto, separando o produto comercial de suas formulacoes e rotulos ao longo do tempo.
- **Observacao de arquitetura:** a unidade de analise de formula nao e `products`, e sim `product_versions`.

### `venus.product_versions`

- **Funcao:** representar a versao efetiva de formula/rotulo de um produto.
- **O que guarda:** nome da versao, status, assinatura da formula, vigencia e origem da deteccao.
- **Campos e relacionamentos:** `product_version_id` e PK; `fk_product_id` referencia `products` em 1:N. E referenciada por rotulo, embalagem, formula, scores, analises, reviews, recomendacoes e evidencias de prontidao.
- **Origem dos dados:** OCR, comparacao de rotulos, fontes oficiais e curadoria.
- **Decisao de existencia:** manter obrigatoriamente para que mudancas de formula nao sobrescrevam historico nem alterem analises ja realizadas.
- **Observacao de arquitetura:** esta e a unidade real de comparacao e scoring.

### `venus.product_labels`

- **Funcao:** texto normalizado do rotulo de uma versao.
- **O que guarda:** texto, idioma, origem e referencia do material lido.
- **Campos e relacionamentos:** `product_label_id` e PK; `fk_product_version_id` e FK unica, formando relacao 1:0..1.
- **Origem dos dados:** OCR e revisao manual.
- **Decisao de existencia:** manter separada para preservar o texto do rotulo sem sobrecarregar a entidade de produto e para rastrear a origem da leitura.
- **Observacao de arquitetura:** texto bruto extenso pode permanecer no MongoDB; o registro normalizado e a referencia ficam no PostgreSQL.

### `venus.packaging`

- **Funcao:** avaliacao da embalagem de uma versao.
- **O que guarda:** material, formato, reciclagem, refilabilidade, biodegradabilidade, confianca e evidencia.
- **Campos e relacionamentos:** `packaging_id` e PK; `fk_product_version_id` e FK unica, relacao 1:0..1.
- **Origem dos dados:** OCR, fonte oficial, curadoria e verificacao manual.
- **Decisao de existencia:** manter como objeto 1:1 porque embalagem tem ciclo de avaliacao proprio e nao deve ser confundida com formula ou claim.
- **Observacao de arquitetura:** ausencia de evidencia deve resultar em `unknown`, nao em inferencia positiva.

### `venus.product_claims`

- **Funcao:** associar claims a uma versao especifica do produto.
- **O que guarda:** claim, verificacao, responsavel, data e fonte.
- **Campos e relacionamentos:** `product_claim_id` e PK; FKs para `product_versions` e `claims`; unicidade por versao/claim.
- **Origem dos dados:** rotulo, fonte oficial, OCR e curadoria.
- **Decisao de existencia:** manter como tabela de ponte porque um produto pode ter varios claims e um claim pode ser reutilizado em varias versoes.
- **Observacao de arquitetura:** a verificacao pertence a associacao, nao ao catalogo abstrato de claims.

### `venus.claims`

- **Funcao:** vocabulario canonico de claims.
- **O que guarda:** nome, tipo e descricao do claim.
- **Campos e relacionamentos:** `claim_id` e PK; e referenciada por `product_claims`.
- **Origem dos dados:** curadoria e normalizacao de claims.
- **Decisao de existencia:** manter como catalogo para evitar texto livre e permitir filtros, BI e regras consistentes.
- **Observacao de arquitetura:** a evidencia e o uso do claim ficam nas tabelas de associacao.

## 5. Ingredientes, classificacao e regulacao

### `venus.ingredient_categories`

- **Funcao:** hierarquia de categorias de ingredientes.
- **O que guarda:** categorias, descricoes e relacionamento pai/filho.
- **Campos e relacionamentos:** `ingredient_category_id` e PK; `parent_ingredient_category_id` referencia a propria tabela em relacao recursiva 0..1:N.
- **Origem dos dados:** curadoria do catalogo.
- **Decisao de existencia:** manter como arvore relacional para suportar classificacao, navegacao e CTE recursiva sem duplicar caminhos.
- **Observacao de arquitetura:** a view de arvore e derivada; a tabela e a fonte de verdade.

### `venus.ingredients`

- **Funcao:** catalogo canonico de ingredientes INCI.
- **O que guarda:** nomes INCI/comuns, funcao, riscos, confianca cientifica, categoria e origem.
- **Campos e relacionamentos:** `ingredient_id` e PK; `inci_name` e unico; `fk_ingredient_category_id` referencia `ingredient_categories`.
- **Origem dos dados:** importacao, OCR normalizado, fontes oficiais e curadoria.
- **Decisao de existencia:** manter como entidade central para que formulas, alergias, efeitos, propriedades e regulacoes compartilhem a mesma identidade.
- **Observacao de arquitetura:** scores legados sao sinais de catalogo; conclusoes de risco aprovadas ficam em `ingredient_risk_assessments`.

### `venus.ingredient_aliases`

- **Funcao:** nomes alternativos para busca e resolucao de OCR.
- **O que guarda:** alias, idioma, origem e referencia do nome.
- **Campos e relacionamentos:** `ingredient_alias_id` e PK; `fk_ingredient_id` referencia `ingredients`; unicidade por ingrediente, alias e idioma.
- **Origem dos dados:** OCR, importacao e curadoria.
- **Decisao de existencia:** manter separada para nao poluir o nome canonico e para permitir novos aliases sem alterar a identidade INCI.
- **Observacao de arquitetura:** participa da busca insensivel a acentos e da normalizacao do pipeline.

### `venus.ingredient_properties`

- **Funcao:** propriedades extensivas de ingredientes.
- **O que guarda:** nome da propriedade, valor, unidade, origem e referencia.
- **Campos e relacionamentos:** `ingredient_property_id` e PK; `fk_ingredient_id` referencia `ingredients`; unicidade por propriedade/unidade.
- **Origem dos dados:** fontes tecnicas, importacao e curadoria.
- **Decisao de existencia:** manter normalizada para acomodar propriedades variaveis sem alterar a tabela principal a cada nova caracteristica.
- **Observacao de arquitetura:** valores devem manter unidade e fonte para permanecerem comparaveis.

### `venus.ingredient_effects`

- **Funcao:** relacionar ingrediente a efeito sobre um perfil ou tag.
- **O que guarda:** categoria do efeito, nome, intensidade, evidencia, status de revisao e fonte.
- **Campos e relacionamentos:** `ingredient_effect_id` e PK; FKs para `ingredients` e `profile_tags`; unicidade por ingrediente/tag/categoria/nome.
- **Origem dos dados:** regras de curadoria, metodologia e importacao validada.
- **Decisao de existencia:** manter porque compatibilidade e uma relacao contextual entre ingrediente e perfil, nao um atributo simples do ingrediente.
- **Observacao de arquitetura:** efeitos podem gerar regras, alertas e explicacoes; nao representam diagnostico medico.

### `venus.ingredient_category_assignments`

- **Funcao:** associar ingredientes a categorias canonicas.
- **O que guarda:** vinculo, origem, confianca e status da classificacao.
- **Campos e relacionamentos:** PK tecnica; FKs para `ingredients` e `ingredient_categories`.
- **Origem dos dados:** reclassificacao, OCR e curadoria.
- **Decisao de existencia:** manter como ponte porque um ingrediente pode pertencer a mais de uma categoria e uma categoria possui muitos ingredientes.
- **Observacao de arquitetura:** a tabela permite reclassificacao auditavel sem substituir o catalogo base.

### `venus.allergies`

- **Funcao:** catalogo de alergias e substancias/condicoes relevantes.
- **O que guarda:** nome, tipo, visibilidade e datas de controle.
- **Campos e relacionamentos:** `allergy_id` e PK; `user_allergies` e `allergy_ingredients` referenciam a tabela.
- **Origem dos dados:** curadoria, questionario e catalogo operacional.
- **Decisao de existencia:** manter como vocabulario controlado para evitar alergias duplicadas e permitir compatibilidade consistente.
- **Observacao de arquitetura:** visibilidade no catalogo e diferente de existencia historica do registro.

### `venus.allergy_ingredients`

- **Funcao:** associar alergias a ingredientes INCI.
- **O que guarda:** pares alergia/ingrediente, origem e referencia da associacao.
- **Campos e relacionamentos:** FKs para `allergies` e `ingredients`; unicidade do par; relacao N:N resolvida por tabela.
- **Origem dos dados:** curadoria e fontes tecnicas.
- **Decisao de existencia:** manter como ponte explicita porque a relacao e muitos-para-muitos e precisa de fonte e auditoria.
- **Observacao de arquitetura:** e uma entrada forte para bloqueios de compatibilidade.

### `venus.ingredient_regulations`

- **Funcao:** associar ingredientes a regulacoes.
- **O que guarda:** tipo de restricao, limite de concentracao, unidade, notas e fonte.
- **Campos e relacionamentos:** FKs para `ingredients` e `regulations`; unicidade do par.
- **Origem dos dados:** fontes regulatorias e curadoria.
- **Decisao de existencia:** manter como ponte porque uma regulacao cobre varios ingredientes e um ingrediente pode ter varias regras por jurisdicao.
- **Observacao de arquitetura:** limites sem unidade ou fonte nao devem ser usados como evidencia final.

### `venus.regulations`

- **Funcao:** catalogo de regulacoes e jurisdicoes.
- **O que guarda:** nome, pais/jurisdicao, status, referencia e vigencia.
- **Campos e relacionamentos:** `regulation_id` e PK; `ingredient_regulations` referencia a tabela.
- **Origem dos dados:** fontes regulatorias e curadoria.
- **Decisao de existencia:** manter como entidade independente para reutilizar a mesma regulacao e controlar seu ciclo de vida.
- **Observacao de arquitetura:** status/deprecated preserva historico sem apagar regras antigas.

### `venus.ingredient_risk_methodologies`

- **Funcao:** versionar a metodologia de avaliacao de risco.
- **O que guarda:** versao, descricao, status, origem e datas da metodologia.
- **Campos e relacionamentos:** `methodology_version` e identificador da metodologia; `ingredient_risk_methodology_dimensions` referencia a versao.
- **Origem dos dados:** governanca tecnica e revisao do modelo.
- **Decisao de existencia:** manter para que scores possam ser reproduzidos e auditados mesmo quando a regra de calculo evoluir.
- **Observacao de arquitetura:** metodologia e dado de governanca, nao deve ser codificada apenas no backend.

### `venus.ingredient_risk_methodology_dimensions`

- **Funcao:** detalhar os eixos e criterios de cada metodologia.
- **O que guarda:** dimensao, evidencia minima, ancoras e definicoes de avaliacao.
- **Campos e relacionamentos:** chave composta por metodologia/dimensao; FK para `ingredient_risk_methodologies`.
- **Origem dos dados:** governanca tecnica.
- **Decisao de existencia:** manter para separar a versao da metodologia de suas dimensoes e permitir validacao por eixo.
- **Observacao de arquitetura:** a tabela sustenta contratos de completude dos quatro eixos de risco.

### `venus.ingredient_risk_assessments`

- **Funcao:** registrar avaliacao aprovada de risco por ingrediente e dimensao.
- **O que guarda:** dimensao, score, evidencia, status, fonte e versao da avaliacao.
- **Campos e relacionamentos:** `ingredient_risk_assessment_id` e PK; `fk_ingredient_id` referencia `ingredients`.
- **Origem dos dados:** regras de inferencia, avaliacao tecnica e curadoria.
- **Decisao de existencia:** manter porque um valor de score no catalogo nao substitui uma avaliacao aprovada com evidencia.
- **Observacao de arquitetura:** score zero sem registro aprovado nao deve ser interpretado como ausencia de risco.

### `venus.ingredient_evidence_queue`

- **Funcao:** fila de curadoria para ingredientes sem evidencia suficiente.
- **O que guarda:** ingrediente pendente, dimensao, prioridade, motivo e estado de atendimento.
- **Campos e relacionamentos:** `ingredient_evidence_queue_id` e PK; `fk_ingredient_id` referencia `ingredients` com unicidade por caso aberto.
- **Origem dos dados:** regras de prontidao e revisao automatica.
- **Decisao de existencia:** manter para transformar lacunas de dados em trabalho operacional rastreavel, em vez de esconder desconhecimento.
- **Observacao de arquitetura:** a fila nao e fonte de score; e fonte de pendencias.

### `venus.ingredient_effect_validation_audit`

- **Funcao:** historizar validacoes e correcoes de efeitos de ingredientes.
- **O que guarda:** estado anterior/novo, decisao, responsavel, fonte e timestamp da validacao.
- **Campos e relacionamentos:** PK tecnica; FK para `ingredients`.
- **Origem dos dados:** curadoria e validadores do pipeline.
- **Decisao de existencia:** manter como trilha de auditoria especifica para permitir explicar por que um efeito foi aceito, alterado ou rejeitado.
- **Observacao de arquitetura:** nao substituir por log textual da aplicacao; a relacao com o ingrediente deve ser consultavel.

### `venus.ingredient_resolution_keys`

- **Funcao:** chaves de resolucao entre tokens normalizados e ingredientes canonicos.
- **O que guarda:** token/chave, ingrediente relacionado e metadados de resolucao.
- **Campos e relacionamentos:** chave composta para evitar duplicidade; FK para `ingredients`.
- **Origem dos dados:** OCR, normalizacao e curadoria.
- **Decisao de existencia:** manter para tornar a resolucao deterministica, reutilizavel e auditavel sem alterar o nome INCI oficial.
- **Observacao de arquitetura:** apoia ingestao e busca; nao deve substituir `ingredient_aliases` quando a informacao for um alias de exibicao.

## 6. Scoring, compatibilidade e recomendacao

### `venus.profile_tags`

- **Funcao:** vocabulario de caracteristicas e necessidades usadas pelo motor.
- **O que guarda:** nome, slug, descricao e categoria da tag.
- **Campos e relacionamentos:** `profile_tag_id` e PK; e referenciada por perfis, efeitos, regras e recomendacoes.
- **Origem dos dados:** produto, questionario e curadoria.
- **Decisao de existencia:** manter como dimensao controlada para que o motor nao dependa de strings livres.
- **Observacao de arquitetura:** tags conectam perfil do usuario a evidencias de ingrediente.

### `venus.scoring_models`

- **Funcao:** versionar modelos de pontuacao.
- **O que guarda:** nome, versao, descricao e status de ativacao.
- **Campos e relacionamentos:** `scoring_model_id` e PK; e referenciada por categorias, regras, scores e analises.
- **Origem dos dados:** governanca do produto e configuracao do motor.
- **Decisao de existencia:** manter para reproduzir resultados e permitir evolucao do algoritmo sem sobrescrever o modelo usado no passado.
- **Observacao de arquitetura:** resultados sempre devem carregar o modelo que os produziu.

### `venus.score_categories`

- **Funcao:** catalogar dimensoes de pontuacao.
- **O que guarda:** nome, chave e descricao das dimensoes.
- **Campos e relacionamentos:** `score_category_id` e PK; `scoring_model_categories` referencia a tabela.
- **Origem dos dados:** definicao do produto e governanca do modelo.
- **Decisao de existencia:** manter como catalogo para permitir diferentes composicoes por modelo sem duplicar nomes de dimensao.
- **Observacao de arquitetura:** dimensao nao e resultado; resultado fica em scores/analises.

### `venus.scoring_model_categories`

- **Funcao:** configurar quais categorias pertencem a cada modelo.
- **O que guarda:** associacao entre modelo e dimensao, peso e configuracao aplicavel.
- **Campos e relacionamentos:** FKs para `scoring_models` e `score_categories`; unicidade do par.
- **Origem dos dados:** configuracao do motor.
- **Decisao de existencia:** manter como ponte N:N porque um modelo usa varias categorias e uma categoria pode participar de mais de um modelo.
- **Observacao de arquitetura:** pesos e regras devem ser versionados com o modelo.

### `venus.compatibility_rules`

- **Funcao:** converter efeitos de ingredientes em acoes e variacoes de score.
- **O que guarda:** tipo de efeito, delta, peso, prioridade, bloqueio/alerta, evidencia e justificativa.
- **Campos e relacionamentos:** FKs para `ingredient_effects` e `scoring_models`; unicidade do efeito por modelo.
- **Origem dos dados:** curadoria, metodologia e regras personalizadas v1.
- **Decisao de existencia:** manter como configuracao de negocio para alterar comportamento do motor com rastreabilidade e sem reimplantar toda a aplicacao.
- **Observacao de arquitetura:** regras nao substituem evidencias; devem carregar origem e nivel de evidencia.

### `venus.product_scores`

- **Funcao:** score generico de um produto/versionamento por modelo.
- **O que guarda:** score geral, dimensoes, confianca e data de calculo.
- **Campos e relacionamentos:** FKs para `product_versions` e `scoring_models`; unicidade por versao/modelo.
- **Origem dos dados:** motor de scoring.
- **Decisao de existencia:** manter separado de `analysis_results` porque score generico nao depende de um usuario especifico.
- **Observacao de arquitetura:** e candidato natural a consumo de BI e cache, mas a fonte de verdade e relacional.

### `venus.product_score_history`

- **Funcao:** preservar scores removidos ou invalidados por falta de prontidao.
- **O que guarda:** snapshot do score, motivo da remocao, origem e timestamps.
- **Campos e relacionamentos:** PK tecnica e referencias logicas ao produto/modelo conforme o snapshot.
- **Origem dos dados:** transicoes de prontidao e reprocessamento.
- **Decisao de existencia:** manter para nao perder explicabilidade quando um score deixa de ser elegivel para consumo atual.
- **Observacao de arquitetura:** historico nao deve voltar automaticamente para a tabela ativa.

### `venus.analysis_results`

- **Funcao:** resultado de uma analise feita para um usuario e produto.
- **O que guarda:** scores por dimensao, confianca, status, resumo e tempo de processamento.
- **Campos e relacionamentos:** FKs para `users`, `product_versions` e `scoring_models`; uma analise possui varias `rule_evaluations`.
- **Origem dos dados:** backend apos OCR, normalizacao e scoring.
- **Decisao de existencia:** manter como fato historico da consulta do usuario, separado do score generico e das regras usadas.
- **Observacao de arquitetura:** e uma das tabelas acionadas pelo tracking de atividade e deve conservar o resultado apresentado ao usuario.

### `venus.rule_evaluations`

- **Funcao:** explicar quais regras foram avaliadas em uma analise.
- **O que guarda:** regra, ingrediente, tag, correspondencia, deltas e explicacao.
- **Campos e relacionamentos:** FKs para `analysis_results`, `compatibility_rules`, `ingredients` e `profile_tags`; unicidade por conjunto avaliado.
- **Origem dos dados:** motor de compatibilidade.
- **Decisao de existencia:** manter para garantir explicabilidade, depuracao e auditoria do score final.
- **Observacao de arquitetura:** limpar justificativas genericas nao elimina a necessidade de manter o registro da regra.

### `venus.personalized_scores`

- **Funcao:** score final personalizado por usuario, versao e modelo.
- **O que guarda:** nota final, percentual de compatibilidade, risco, recomendacao e resumo.
- **Campos e relacionamentos:** FKs para `users`, `product_versions`, `analysis_results` e `scoring_models`; unicidade por usuario/versao/modelo.
- **Origem dos dados:** motor de scoring personalizado.
- **Decisao de existencia:** manter porque o resultado personalizado nao pode ser reconstruido com seguranca apenas a partir do score generico.
- **Observacao de arquitetura:** explicacoes amigaveis devem ser produzidas a partir dos fatos persistidos e das regras aplicadas.

### `venus.recommendations`

- **Funcao:** resultado ranqueado de recomendacoes para um usuario.
- **O que guarda:** usuario, tag, versao, analise, tipo, confianca, posicao e motivo.
- **Campos e relacionamentos:** FKs para `users`, `profile_tags`, `product_versions` e `analysis_results`.
- **Origem dos dados:** motor de recomendacao.
- **Decisao de existencia:** manter quando a recomendacao precisa ser exibida, ranqueada ou auditada de forma consistente entre chamadas.
- **Observacao de arquitetura:** o registro e derivado, mas sua persistencia reduz recalculo e conserva o contexto entregue.

### `venus.packaging_evaluation_policies`

- **Funcao:** definir a politica de prontidao para avaliar embalagem.
- **O que guarda:** dimensoes, evidencias exigidas, versao e status da politica.
- **Campos e relacionamentos:** PK tecnica; relacionamento logico com a avaliacao de `packaging`.
- **Origem dos dados:** governanca do scoring e curadoria.
- **Decisao de existencia:** manter como configuracao versionada para que o gate de embalagem nao fique espalhado em SQL e codigo da API.
- **Observacao de arquitetura:** ausencia de dado deve produzir estado desconhecido conforme a politica ativa.

### `venus.product_composition_receipts`

- **Funcao:** recibo de composicao bruta, resolucao e validacao de uma versao.
- **O que guarda:** assinatura, payload/resumo, contagens, status e evidencia de processamento.
- **Campos e relacionamentos:** `product_composition_receipt_id` e PK; `fk_product_version_id` referencia `product_versions`.
- **Origem dos dados:** pipeline OCR e normalizacao.
- **Decisao de existencia:** manter para provar qual composicao foi usada antes de liberar o produto para scoring.
- **Observacao de arquitetura:** payloads longos podem ser armazenados no MongoDB; o recibo de integridade permanece no PostgreSQL.

### `venus.product_dimension_assessments`

- **Funcao:** aprovar dimensoes individuais antes do score geral.
- **O que guarda:** dimensao, status, evidencia, nota e responsavel da avaliacao.
- **Campos e relacionamentos:** `product_dimension_assessment_id` e PK; `fk_product_version_id` referencia `product_versions`.
- **Origem dos dados:** avaliacao de prontidao e curadoria.
- **Decisao de existencia:** manter para impedir que score geral esconda dimensao sem evidencia suficiente.
- **Observacao de arquitetura:** cada dimensao possui ciclo de aprovacao proprio.

### `venus.product_ingredient_resolution_issues`

- **Funcao:** registrar tokens de ingrediente que nao foram resolvidos ou ficaram ambiguos.
- **O que guarda:** versao, token, motivo, sugestao e estado da pendencia.
- **Campos e relacionamentos:** `product_ingredient_resolution_issue_id` e PK; `fk_product_version_id` referencia `product_versions`.
- **Origem dos dados:** OCR e normalizacao automatica.
- **Decisao de existencia:** manter para que falhas de resolucao sejam tratadas como pendencias explicitas e nao descartadas silenciosamente.
- **Observacao de arquitetura:** a existencia de uma issue impede ou condiciona a liberacao do score conforme a politica vigente.

### `venus.product_ingredients`

- **Funcao:** relacionar os ingredientes que compoem uma versao de produto.
- **O que guarda:** versao, ingrediente, posicao no rotulo e datas da associacao.
- **Campos e relacionamentos:** FKs para `product_versions` e `ingredients`; unicidade por versao/ingrediente e por versao/posicao.
- **Origem dos dados:** OCR normalizado, rotulo oficial e curadoria.
- **Decisao de existencia:** manter como tabela de ponte porque uma versao possui muitos ingredientes e um ingrediente aparece em muitas versoes; a ordem da formula e dado de negocio.
- **Observacao de arquitetura:** a formula validada deve permanecer relacional e nao ser substituida por uma lista JSON.

## 7. Comunidade, listas e historico do usuario

### `venus.favorites`

- **Funcao:** registrar produtos favoritos do usuario.
- **O que guarda:** usuario, produto e data da marcacao.
- **Campos e relacionamentos:** FKs para `users` e `products`; unicidade por usuario/produto.
- **Origem dos dados:** acao do usuario.
- **Decisao de existencia:** manter como relacao simples e transacional para leitura rapida, integridade e personalizacao.
- **Observacao de arquitetura:** tambem gera atividade de usuario via trigger.

### `venus.user_lists`

- **Funcao:** listas nomeadas criadas pelo usuario.
- **O que guarda:** dono, nome, descricao, capa, tipo e timestamps.
- **Campos e relacionamentos:** `user_list_id` e PK; `fk_user_id` referencia `users`; `media_assets` pode referenciar a lista.
- **Origem dos dados:** acao do usuario e backend.
- **Decisao de existencia:** manter como cabecalho relacional para agrupar itens e aplicar unicidade por usuario/nome.
- **Observacao de arquitetura:** atividade de listas e rastreada por trigger.

### `venus.user_list_items`

- **Funcao:** itens de produto dentro de uma lista.
- **O que guarda:** lista, produto, posicao e data de inclusao.
- **Campos e relacionamentos:** FKs para `user_lists` e `products`; unicidade do produto e da posicao dentro da lista.
- **Origem dos dados:** acao do usuario.
- **Decisao de existencia:** manter como tabela de ponte porque a lista e um relacionamento N:N contextualizado por ordem.
- **Observacao de arquitetura:** nao armazenar IDs de produtos em JSON na tabela de listas.

### `venus.reviews`

- **Funcao:** avaliacao textual de uma versao por um usuario.
- **O que guarda:** nota, titulo, comentario, uso verificado e timestamps.
- **Campos e relacionamentos:** FKs para `users` e `product_versions`; unicidade por usuario/versao.
- **Origem dos dados:** acao do usuario e moderacao.
- **Decisao de existencia:** manter no PostgreSQL por integridade, moderacao, ordenacao e relacionamento com votos.
- **Observacao de arquitetura:** a versao exata e obrigatoria para nao misturar feedbacks de formulas diferentes.

### `venus.review_votes`

- **Funcao:** votos de utilidade das reviews.
- **O que guarda:** review, usuario, tipo do voto e data.
- **Campos e relacionamentos:** FKs para `reviews` e `users`; unicidade por review/usuario.
- **Origem dos dados:** acao do usuario.
- **Decisao de existencia:** manter como ponte transacional para impedir votos duplicados e calcular utilidade com consistencia.
- **Observacao de arquitetura:** nao substituir por contador desnormalizado sem manter a origem do voto.

### `venus.reports`

- **Funcao:** denuncias e pedidos de revisao/moderacao.
- **O que guarda:** autor, alvo, motivo, status, administrador responsavel e datas.
- **Campos e relacionamentos:** FKs para `users` e, opcionalmente, `admin_users`; o alvo e polimorfico por tipo/id.
- **Origem dos dados:** usuario, moderacao e backend.
- **Decisao de existencia:** manter para preservar fluxo de moderacao, responsabilidade e historico de tratamento.
- **Observacao de arquitetura:** `target_type`/`target_id` e deliberadamente polimorfico; novas tabelas alvo nao exigem alteracao estrutural imediata.

### `venus.user_profiles`

- **Funcao:** perfil fisico e comportamental do usuario.
- **O que guarda:** pele, fototipo, cabelo, couro cabeludo, faixa etaria, condicoes e preferencias de perfil.
- **Campos e relacionamentos:** `user_profile_id` e PK; `fk_user_id` e FK unica para `users`, relacao 1:0..1.
- **Origem dos dados:** questionario e edicao do usuario.
- **Decisao de existencia:** manter 1:1 com `users` para separar identidade de atributos de personalizacao sem duplicar conta.
- **Observacao de arquitetura:** o perfil alimenta compatibilidade, mas nao deve conter historico de analises.

### `venus.user_preferences`

- **Funcao:** preferencias explicitas declaradas pelo usuario.
- **O que guarda:** flags como cruelty-free, vegan, sustentabilidade, fragrancia, parabenos, sulfatos e silicones.
- **Campos e relacionamentos:** `user_preference_id` e PK; `fk_user_id` e FK unica para `users`.
- **Origem dos dados:** questionario e configuracoes do aplicativo.
- **Decisao de existencia:** manter separada de `user_profiles` porque preferencias sao escolhas explicitas e possuem governanca de privacidade distinta de caracteristicas de perfil.
- **Observacao de arquitetura:** deve ser lida junto com perfil e tags no motor personalizado.

### `venus.user_allergies`

- **Funcao:** alergias informadas por cada usuario.
- **O que guarda:** usuario, alergia, severidade e datas.
- **Campos e relacionamentos:** FKs para `users` e `allergies`; unicidade por usuario/alergia.
- **Origem dos dados:** questionario e edicao do usuario.
- **Decisao de existencia:** manter como ponte N:N para suportar varias alergias por usuario e severidade por relacionamento.
- **Observacao de arquitetura:** participa de bloqueios fortes de compatibilidade.

### `venus.user_profile_tags`

- **Funcao:** associar tags ao perfil do usuario.
- **O que guarda:** usuario, tag, estado e data de associacao.
- **Campos e relacionamentos:** FKs para `users` e `profile_tags`; unicidade por usuario/tag.
- **Origem dos dados:** questionario, regras de perfil e curadoria.
- **Decisao de existencia:** manter como ponte para que o motor use varias tags por usuario sem alterar a estrutura do perfil a cada nova necessidade.
- **Observacao de arquitetura:** e uma das pontes centrais entre usuario e efeitos de ingredientes.

## 8. Tracking e atividade

### `venus.user_access_events`

- **Funcao:** registrar acesso e atividade operacional para DAU.
- **O que guarda:** usuario, tipo de acesso, momento, aplicacao, IP e metadados de atividade.
- **Campos e relacionamentos:** `access_event_id` e PK; `fk_user_id` referencia `users` em 1:N com `ON DELETE CASCADE`.
- **Origem dos dados:** trigger de login e triggers de atividade em analises, favoritos, listas, reviews e reports.
- **Decisao de existencia:** manter como fato leve e append-oriented para medir atividade diaria sem misturar telemetria detalhada com dados de negocio.
- **Observacao de arquitetura:** e a fonte das views `v_dau` e `v_dau_rolling_30d`.

### `venus.user_tracking_events`

- **Funcao:** registrar eventos detalhados de uso das aplicacoes web e mobile.
- **O que guarda:** usuario autenticado/externo/anonimo, plataforma, evento, sessao, tela, versao, dispositivo, timestamp original e metadata JSON.
- **Campos e relacionamentos:** `tracking_event_id` e PK; `fk_user_id` e FK opcional para `users` com `ON DELETE SET NULL`; indices por usuario, evento, plataforma e sessao.
- **Origem dos dados:** API autorizada, clientes mobile/web e integracoes legadas.
- **Decisao de existencia:** manter separada de `user_access_events` porque telemetria de produto tem granularidade, volume, retencao e contrato de privacidade diferentes da base de DAU.
- **Observacao de arquitetura:** nao armazenar tokens, senhas ou dados pessoais brutos em `metadata`; `anonymous_id` e `device_id_hash` devem permanecer tecnicos.

## 9. Midia e integracao externa

### `venus.media_assets`

- **Funcao:** catalogo relacional dos arquivos de midia usados pelo Venus.
- **O que guarda:** chave externa, URL, provedor, tipo, finalidade, hash, status e vinculo com usuario, produto ou lista.
- **Campos e relacionamentos:** `media_asset_id` e PK; FKs opcionais para `users`, `product_versions` e `user_lists`.
- **Origem dos dados:** upload da aplicacao, Cloudinary e processamento de imagens.
- **Decisao de existencia:** manter o registro e os metadados no PostgreSQL, deixando o binario no Cloudinary; isso permite integridade e consulta sem transformar o banco relacional em storage de arquivos.
- **Observacao de arquitetura:** URLs e chaves devem ser tratadas como metadados controlados, nao como fonte de autorizacao isolada.

## 10. RPA, carga e reconciliacao

### `venus_rpa.rpa_run`

- **Funcao:** controlar cada lote de execucao da migracao do legado.
- **O que guarda:** batch, inicio/fim, status, origem, hashes/consultas, contagens e mensagem de erro.
- **Campos e relacionamentos:** `batch_id` e PK logica do lote; `rpa_error`, `rpa_stage_product` e `rpa_stage_user` referenciam o batch.
- **Origem dos dados:** executor RPA e `rpa_migrate.py`.
- **Decisao de existencia:** manter como cabecalho de controle para permitir idempotencia, monitoramento e reprocessamento seguro.
- **Observacao de arquitetura:** um lote deve ser identificavel sem depender apenas de logs da maquina que executou a carga.

### `venus_rpa.rpa_error`

- **Funcao:** registrar falhas associadas a um lote RPA.
- **O que guarda:** tabela de origem, chave legada, tipo, mensagem e payload de erro.
- **Campos e relacionamentos:** `error_id` e PK; `batch_id` referencia `rpa_run` em 1:N.
- **Origem dos dados:** executor RPA.
- **Decisao de existencia:** manter para tratar erro por registro sem invalidar o lote inteiro e para permitir reprocessamento seletivo.
- **Observacao de arquitetura:** payload de erro deve ser suficiente para diagnostico, mas nao carregar segredo.

### `venus_rpa.rpa_stage_product`

- **Funcao:** staging e reconciliacao de produtos vindos do legado.
- **O que guarda:** campos legados, texto de ingredientes, normalizacao, validacao e `loaded_product_id`.
- **Campos e relacionamentos:** PK composta do lote/legado; FKs para `rpa_run` e, quando carregado, `venus.products`.
- **Origem dos dados:** banco legado e transformacoes RPA.
- **Decisao de existencia:** manter como zona de transicao para separar dado legado de entidade canonica e tornar falhas/revisoes reprocessaveis.
- **Observacao de arquitetura:** nao e fonte de verdade do catalogo depois que o produto e carregado.

### `venus_rpa.rpa_stage_user`

- **Funcao:** staging e reconciliacao de usuarios vindos do legado.
- **O que guarda:** identificador legado, nome, email, status, normalizacao, validacao e `loaded_user_id`.
- **Campos e relacionamentos:** PK composta do lote/legado; FKs para `rpa_run` e, quando carregado, `venus.users`.
- **Origem dos dados:** banco legado e transformacoes RPA.
- **Decisao de existencia:** manter para preservar a chave de origem, controlar duplicidade e permitir carga idempotente antes de criar o usuario canonico.
- **Observacao de arquitetura:** dados pessoais devem obedecer as regras de acesso e retencao do banco.

## 11. Auditoria e operacao

### `venus_audit.audit_logs`

- **Funcao:** trilha de auditoria de alteracoes nas tabelas do sistema.
- **O que guarda:** schema, tabela, operacao, dados antigos/novos, responsavel, aplicacao e timestamp.
- **Campos e relacionamentos:** `audit_id` e PK; a referencia ao objeto auditado e metadado, nao FK, para permitir auditar varias tabelas e schemas.
- **Origem dos dados:** triggers de auditoria do PostgreSQL.
- **Decisao de existencia:** manter fora de `venus` para separar auditoria transversal de dados funcionais e evitar acoplamento circular.
- **Observacao de arquitetura:** nao confundir com `user_access_events` ou `user_tracking_events`; auditoria registra mudanca, tracking registra uso.

### `venus_optimization.readme`

- **Funcao:** registrar no proprio banco o proposito dos objetos de otimizacao.
- **O que guarda:** chave e descricao operacional das medidas, indices e consultas analisadas.
- **Campos e relacionamentos:** `item` e PK; nao possui FK por ser uma tabela de orientacao operacional.
- **Origem dos dados:** manutencao tecnica e analise de performance.
- **Decisao de existencia:** manter pequena e isolada para documentar decisoes de tuning junto ao ambiente que as executa.
- **Observacao de arquitetura:** nao e tabela de negocio nem fonte de metricas analiticas.

## 12. Objetos derivados que dependem destas tabelas

As views nao entram no inventario de tabelas, mas fazem parte da arquitetura:

- `venus.v_dau` e `venus.v_dau_rolling_30d` consomem `user_access_events`.
- Views de prontidao e risco consomem `ingredient_risk_assessments`, `ingredient_risk_methodologies`, `ingredient_evidence_queue`, `packaging_evaluation_policies`, `product_composition_receipts` e `product_dimension_assessments`.
- Views de fotos consomem `media_assets` e expõem apenas metadados adequados ao consumo da API.
- `venus_bi` fornece dimensoes, fatos e visoes analiticas para BI; nao duplica fisicamente as tabelas operacionais.

## 13. Regras de manutencao deste documento

1. Toda nova tabela deve entrar neste arquivo na mesma migracao que a cria.
2. A secao da tabela deve explicar funcao, origem, relacionamentos e o motivo da existencia.
3. A decisao deve ser revisada quando a tabela mudar de responsabilidade, receber nova FK ou deixar de ser usada pelo fluxo.
4. O dicionario completo de campos deve ser atualizado em `docs/database-logical-model.md` e no SQL de migracao correspondente.
5. Tabelas removidas nao devem ser apagadas silenciosamente: registrar a retirada no historico da PR ou na documentacao de migracao.
