# Redis: cache de classificações personalizadas do Venus-Classificacao

O cache `classificacoes` conserva em JSON resultados de nota de produtos por usuário, versão do produto e modelo de pontuação, com validade de seis horas.

## 1. Finalidade do banco

> O cache de classificações permite reutilizar uma análise personalizada já existente, evitando recuperar repetidamente o mesmo resultado no PostgreSQL. A análise responde a uma combinação específica de pessoa, versão do produto e modelo de pontuação. A mesma pessoa pode receber resultados diferentes para versões diferentes de um produto, e pessoas distintas podem ter compatibilidades diferentes com a mesma composição.
>
> O Redis é adequado a esse reaproveitamento por chave completa, com prazo de validade definido e descarte quando uma nova análise é gravada pelo fluxo descrito. O valor reúne o resultado da classificação em JSON, em vez de repartir a resposta em várias estruturas de consulta. Esse desenho permite reutilizar um resultado pronto.
>
> O PostgreSQL permanece como origem da análise salva e dos dados de domínio que a fundamentam. O Redis mantém uma cópia temporária dessa análise. Expirar uma chave provoca uma nova leitura do banco. Essa distinção é relevante quando composição, regras ou perfil mudam.

## 2. Modelo de dados

### 2.1. Tipo e formato do valor

| Propriedade | Definição informada | Motivo de existir |
| --- | --- | --- |
| Nome do cache | `classificacoes` | Agrupa resultados de classificação e distingue esse conteúdo dos outros caches. |
| Tipo lógico | Resultado de classificação personalizada | Conserva a análise salva para uma combinação específica. |
| Serialização | JSON com serializador próprio | Define uma representação estruturada para recuperar o resultado completo. |
| Tratamento de datas | Mapeador ajustado para não converter datas ao fuso do contexto, preservando os offsets originais | Evita que a representação temporal seja alterada por essa conversão ao recuperar o resultado. |
| Resultado nulo | Não é cacheado | Evita conservar uma ausência como se fosse uma análise válida. |
| TTL | 6 horas, equivalentes a 21.600 segundos | Limita o tempo de reutilização da cópia. |

### 2.2. Anatomia da chave

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

### 2.3. Conteúdo de domínio relacionado ao resultado

| Elemento de domínio | Regra fornecida | Relação com a necessidade de cache personalizado |
| --- | --- | --- |
| Qualidade do produto | Até 35 pontos por saúde, desempenho, impacto ambiental e ética | Parcela comum às pessoas para o mesmo produto e contexto de cálculo. |
| Compatibilidade com o perfil | Até 65 pontos | Parcela que torna necessário distinguir usuários. |
| Nota total | Escala de 0 a 100 | Resultado global da avaliação, sujeito às travas. |
| Travas | Ingrediente proibido na gestação ou alergia crítica zera a nota e torna o produto contraindicado | Uma classificação antiga pode deixar de representar a situação atual se o perfil ou os dados usados mudarem. |
| Faixas | Ideal, recomendado, aceitável, não recomendado e contraindicado | Expressam a leitura qualitativa da nota e das travas. |

Essa tabela descreve as regras do Venus que dão sentido ao resultado.

## 3. Exemplo de chave

```text
classificacoes::42:7:1
```

A chave ilustrativa representa a análise do usuário `42`, para a versão de produto `7`, no modelo de pontuação `1`. Outra pessoa, outra versão ou outro modelo produz uma chave diferente.

O valor é o resultado da classificação serializado em JSON, com preservação dos offsets das datas.

## 4. Ciclo de vida dos dados

A entrada nasce quando uma leitura obtém no PostgreSQL uma análise salva e a conserva no Redis. Uma leitura da mesma combinação pode reutilizar o resultado até que a entrada expire ou seja invalidada.

Uma nova gravação da análise do mesmo usuário, versão do produto e modelo apaga a chave correspondente. A leitura seguinte retorna ao banco e pode preencher a entrada novamente.

Após seis horas, a cópia deixa de ser válida. Resultado nulo e ausência indicada por 404 não são conservados.

## 5. Política de chaves e expiração

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

## 6. Regras de negócio refletidas no banco

A nota reúne qualidade do produto e compatibilidade com a pessoa. Isso justifica o componente de usuário na chave, mas a identidade da pessoa sozinha não representa a evolução de seu perfil ao longo do tempo. Preferências, alergias e condições informadas podem mudar sem que o identificador do usuário mude.

Versões de produto e modelos de pontuação distinguem resultados calculados em contextos diferentes. Para que essa separação funcione, as consultas precisam usar os identificadores correspondentes ao contexto desejado.

As travas prevalecem sobre a soma de pontos: nos casos fornecidos, a nota é zero e a classificação é contraindicado. O cache conserva o resultado já produzido.
