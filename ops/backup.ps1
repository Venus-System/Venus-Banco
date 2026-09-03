$ErrorActionPreference="Stop"
$stamp=Get-Date -Format "yyyyMMdd_HHmmss"
New-Item -ItemType Directory -Force backups | Out-Null
pg_dump $env:DATABASE_URL --format=custom --no-owner --no-privileges --file="backups\venus_$stamp.dump"
