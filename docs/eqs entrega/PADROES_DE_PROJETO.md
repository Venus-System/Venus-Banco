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

### 28.3 Resultado da verificação dos repositórios

A busca transversal encontrou evidência explícita de `Repository`, `DTO` e `Mapper` no Venus-CRUD. Nos demais repositórios, não foi localizado um artefato versionado que permita afirmar a aplicação de outro padrão de projeto. Portanto, esta documentação não atribui padrões adicionais ao Venus-Banco, Venus-Classificacao, Venus-Web, Venus-mobile, Venus-AI-api, Venus-AI-Sdk ou Venus-1ANO-CRUD.

### 28.4 Limite da entrega

Os padrões acima descrevem componentes que já existiam e continuam sendo usados pelo sistema. Nenhuma implementação funcional foi modificada para produzir esta seção.
\n