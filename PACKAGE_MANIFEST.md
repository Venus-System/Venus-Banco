# Manifesto do repositório

Este arquivo substitui o manifesto histórico baseado em tamanhos e hashes
fixos. Como o repositório recebe migrations, modelos e snapshots regeneráveis,
uma lista estática de bytes fica obsoleta rapidamente.

## Fontes canônicas

- [`README.md`](README.md) — execução rápida e mapa do repositório.
- [`docs/README.md`](docs/README.md) — índice completo da documentação.
- [`docs/database-logical-model.md`](docs/database-logical-model.md) — catálogo
  gerado do PostgreSQL real.
- [`docs/arquitetura-dados/`](<docs/arquitetura-dados/>) — documentação por
  tecnologia e limites de evidência.

## Integridade sob demanda

Para calcular o hash de um arquivo no PowerShell:

```powershell
Get-FileHash -Algorithm SHA256 -LiteralPath .\caminho\arquivo
```

Para reproduzir o snapshot SQL, use `python ops/generate_database_model.py` em
uma sessão com `DATABASE_URL` configurada. O gerador consulta metadados e não
cria, atualiza ou remove objetos do banco.
