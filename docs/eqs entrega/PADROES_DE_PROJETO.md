## 28. Padrões de projeto evidenciados

Esta seção registra somente padrões identificados no código e na documentação versionados nos repositórios do projeto. A inclusão é documental: não foram criadas classes, rotas, anotações ou alterações de comportamento.

Os arquivos **Padrão de Projeto.docx** e **Requisitos.xlsx**, citados no planejamento, não foram encontrados nos repositórios do projeto. Por isso, a entrega considera apenas os padrões comprováveis no código existente.

### 28.1 Repository

O padrão Repository está aplicado no **Venus-CRUD** para encapsular a persistência e separar o acesso ao PostgreSQL e ao MongoDB da regra de negócio. Os services dependem de interfaces Spring Data, enquanto as entities e documentos permanecem isolados da camada HTTP.

Evidências:

- [ProductRepository.java](https://github.com/Venus-System/Venus-CRUD/blob/main/src/main/java/com/venus/crud/repository/jpa/product/ProductRepository.java)
- [ScanSessionRepository.java](https://github.com/Venus-System/Venus-CRUD/blob/main/src/main/java/com/venus/crud/repository/mongo/ScanSessionRepository.java)
- [Decisão de organização das camadas](https://github.com/Venus-System/Venus-CRUD/blob/main/docs/decisoes/04-pacotes-mvc.md)

### 28.2 DTO + Mapper

O padrão DTO + Mapper está aplicado no **Venus-CRUD** para impedir que entities JPA ou documentos Mongo sejam expostos diretamente pela API. Os DTOs definem o contrato externo e os mappers MapStruct realizam a conversão entre request/response e o modelo interno.

A configuração `VenusMapperConfig` registra os mappers como beans Spring e faz o build falhar quando um campo de destino fica sem mapeamento. O `ProductMapper` exemplifica as conversões `toEntity`, `toResponse`, `updateEntity` e `patchEntity`.

Evidências:

- [VenusMapperConfig.java](https://github.com/Venus-System/Venus-CRUD/blob/main/src/main/java/com/venus/crud/config/VenusMapperConfig.java)
- [ProductMapper.java](https://github.com/Venus-System/Venus-CRUD/blob/main/src/main/java/com/venus/crud/mapper/jpa/product/ProductMapper.java)
- [ProductResponse.java](https://github.com/Venus-System/Venus-CRUD/blob/main/src/main/java/com/venus/crud/dto/jpa/response/product/ProductResponse.java)
- [Decisão sobre MapStruct e DTOs](https://github.com/Venus-System/Venus-CRUD/blob/main/docs/decisoes/04-pacotes-mvc.md)

### 28.3 Strategy

O padrão Strategy está aplicado no **Venus-Classificacao**, que separa o contrato de cálculo de uma nota de qualidade das implementações concretas por dimensão. O motor pode executar estratégias independentes para qualidade ambiental, ética, saúde e desempenho, mantendo o fluxo aberto para novas regras.

Evidências:

- [BucketScoreStrategy.java](https://github.com/Venus-System/Venus-Classificacao/blob/develop/src/main/java/com/venus/classificacao/service/quality/strategy/BucketScoreStrategy.java)
- [EnvironmentalScoreStrategy.java](https://github.com/Venus-System/Venus-Classificacao/blob/develop/src/main/java/com/venus/classificacao/service/quality/strategy/EnvironmentalScoreStrategy.java)
- [HealthScoreStrategy.java](https://github.com/Venus-System/Venus-Classificacao/blob/develop/src/main/java/com/venus/classificacao/service/quality/strategy/HealthScoreStrategy.java)
- [README do Venus-Classificacao](https://github.com/Venus-System/Venus-Classificacao/blob/develop/README.md)

### 28.4 Resultado da verificação dos repositórios

A busca transversal encontrou evidência explícita de `Repository` e `DTO + Mapper` no Venus-CRUD e de `Strategy` no Venus-Classificacao. Estes são os padrões de projeto evidenciados nos repos do projeto; não foram atribuídos padrões adicionais sem artefato versionado suficiente.

### 28.5 Limite da entrega

Os padrões acima descrevem componentes que já existiam e continuam sendo usados pelo sistema. Nenhuma implementação funcional foi modificada para produzir esta seção.
\n
