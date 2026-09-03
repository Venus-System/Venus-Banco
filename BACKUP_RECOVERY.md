# Venus — Backup e Recuperação

## Backup

Linux/macOS:
```bash
mkdir -p backups
pg_dump "$DATABASE_URL" --format=custom --no-owner --no-privileges --file="backups/venus_$(date +%Y%m%d_%H%M%S).dump"
```

PowerShell:
```powershell
$stamp=Get-Date -Format "yyyyMMdd_HHmmss"
New-Item -ItemType Directory -Force backups | Out-Null
pg_dump $env:DATABASE_URL --format=custom --no-owner --no-privileges --file="backups\venus_$stamp.dump"
```

## Restauração

Crie um database vazio e execute:
```bash
pg_restore --clean --if-exists --no-owner --no-privileges --dbname="$TARGET_DATABASE_URL" backups/venus_YYYYMMDD_HHMMSS.dump
```

Backups devem ser armazenados fora do servidor e a restauração deve ser testada periodicamente. Para o projeto acadêmico, retenção de 7 dias e backup diário são adequados.

## Scripts prontos

Os comandos PowerShell acima já estão empacotados em `ops/backup.ps1` e `ops/restore.ps1`.

Backup:
```powershell
./ops/backup.ps1
```
Gera o arquivo em `backups/venus_<timestamp>.dump`, usando `DATABASE_URL` do ambiente.

Restauração:
```powershell
./ops/restore.ps1 -DumpFile "backups/venus_YYYYMMDD_HHMMSS.dump" -TargetDatabaseUrl "postgresql://USUARIO:SENHA@HOST:5432/DATABASE_ALVO"
```

## Verificação pós-restauração

Depois de restaurar, confirme que o ambiente está íntegro antes de liberar o uso:

1. execute `python diagnostico_postgres.py` apontando para o banco restaurado;
2. confira a contagem de linhas das tabelas principais (`ingredients`, `products`, `users`) contra o backup de origem;
3. rode `sql/99_validation.sql` para checar as validações estruturais do pacote;
4. valide que os schemas `venus`, `venus_audit`, `venus_bi`, `venus_rpa` e `venus_optimization` existem e estão populados conforme esperado.

## O que o backup cobre

`pg_dump --format=custom` captura schema e dados de todo o banco de destino, incluindo os schemas `venus`, `venus_audit`, `venus_bi`, `venus_rpa` e `venus_optimization`. Ele **não** captura os binários armazenados no Cloudinary — apenas os metadados em `venus.media_assets`. Uma estratégia de backup completa para produção deve considerar também a política de retenção do próprio Cloudinary.

## Frequência e retenção recomendadas

| Ambiente | Frequência | Retenção |
|---|---|---|
| Desenvolvimento/acadêmico | Antes de mudanças destrutivas (`--reset`) | 7 dias |
| Produção | Diária, com backup incremental via WAL se disponível | 30 dias ou conforme política da organização |

Mantenha ao menos uma cópia do dump fora do servidor de banco (armazenamento externo/objeto), para sobreviver a uma falha completa da instância.
