param(
  [string]$OutputDirectory = "backups"
)

$ErrorActionPreference = "Stop"
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$resolved = Join-Path (Get-Location) $OutputDirectory
New-Item -ItemType Directory -Force -Path $resolved | Out-Null
$schema = Join-Path $resolved "tricgabay-schema-$stamp.sql"
$data = Join-Path $resolved "tricgabay-data-$stamp.sql"

supabase db dump --linked --file $schema
supabase db dump --linked --data-only --use-copy --file $data

if ((Get-Item $schema).Length -eq 0 -or (Get-Item $data).Length -eq 0) {
  throw "Backup validation failed: one or more dump files are empty."
}

Write-Host "Validated backup written to $resolved"
