# Redis

O Redis é usado como cache no Venus-CRUD e no Venus-Classificacao, com TTL de
6 horas (`spring.cache.redis.time-to-live: 6h`). A fonte operacional continua
sendo o PostgreSQL: se o Redis ficar fora do ar, as duas APIs seguem lendo do
banco.

## Documentação

- [`favoritos.md`](favoritos.md): páginas e contagem dos favoritos de cada
  pessoa no Venus-CRUD (caches `favoritos-do-usuario` e
  `contagem-de-favoritos-do-usuario`), com a anatomia das chaves e a
  invalidação depois da gravação no PostgreSQL.
- [`classificacoes.md`](classificacoes.md): resultado salvo da nota
  personalizada no Venus-Classificacao (cache `classificacoes`), por pessoa,
  versão do produto e modelo de pontuação.
