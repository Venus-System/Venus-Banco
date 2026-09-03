param([Parameter(Mandatory=$true)][string]$DumpFile,[Parameter(Mandatory=$true)][string]$TargetDatabaseUrl)
$ErrorActionPreference="Stop"
pg_restore --clean --if-exists --no-owner --no-privileges --dbname="$TargetDatabaseUrl" "$DumpFile"
