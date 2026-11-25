[CmdletBinding()]
param([string]$Workspace=(Join-Path ([IO.Path]::GetTempPath()) 'tricgabay-batch4-isolated'),[string]$LogDirectory=(Join-Path $PSScriptRoot '../.audit-output/batch4'),[switch]$SkipConcurrency)
$ErrorActionPreference='Stop'
$repoRoot=(Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$resolvedWorkspace=(Resolve-Path -LiteralPath $Workspace).Path
$temporaryRoot=[IO.Path]::GetFullPath([IO.Path]::GetTempPath())
if(-not $resolvedWorkspace.StartsWith($temporaryRoot,[StringComparison]::OrdinalIgnoreCase) -or (Split-Path $resolvedWorkspace -Leaf) -ne 'tricgabay-batch4-isolated'){throw 'Only the explicitly isolated temporary workspace may be reset.'}
if((Get-Content -Raw (Join-Path $resolvedWorkspace 'supabase/config.toml')) -notmatch 'project_id = "tricgabay_batch4_isolated"'){throw 'Unexpected local project ID.'}
if(Test-Path (Join-Path $resolvedWorkspace 'supabase/.temp/project-ref')){throw 'Refusing a linked workspace.'}
New-Item -ItemType Directory -Force -Path $LogDirectory | Out-Null
foreach($file in Get-ChildItem (Join-Path $repoRoot 'supabase/migrations') -File){Copy-Item -LiteralPath $file.FullName -Destination (Join-Path $resolvedWorkspace 'supabase/migrations/')}
npx --yes supabase@2.121.0 db reset --local --workdir $resolvedWorkspace --yes > (Join-Path $LogDirectory 'full-chain-reset.txt') 2>&1
if($LASTEXITCODE -ne 0){throw 'Full migration chain failed; see full-chain-reset.txt'}
Get-Content -Raw (Join-Path $repoRoot 'supabase/bootstrap/managed_extensions.sql') | docker exec -i supabase_db_tricgabay_batch4_isolated psql -X -q -v ON_ERROR_STOP=1 -U supabase_admin -d postgres > (Join-Path $LogDirectory 'managed-extension-bootstrap.txt') 2>&1
if($LASTEXITCODE -ne 0){throw 'Managed extension owner bootstrap failed'}
$count=(Get-ChildItem (Join-Path $repoRoot 'supabase/migrations') -Filter '*.sql' -File).Count
Write-Output "FULL_CHAIN_PASS migrations=$count clean_database=true storage_auth=real_services realtime=true managed_owner_bootstrap=true"
pwsh -NoProfile -File (Join-Path $PSScriptRoot 'check_sql.ps1') -SkipBuild > (Join-Path $LogDirectory 'sql-parser-final.txt') 2>&1
if($LASTEXITCODE -ne 0){throw 'SQL parser failed'}
pwsh -NoProfile -File (Join-Path $PSScriptRoot 'test_local_database.ps1') -LogDirectory (Join-Path $LogDirectory 'pgtap')
if($LASTEXITCODE -ne 0){throw 'pgTAP failed'}
if(-not $SkipConcurrency){pwsh -NoProfile -File (Join-Path $PSScriptRoot 'test_database_concurrency.ps1') -LogDirectory (Join-Path $LogDirectory 'concurrency');if($LASTEXITCODE -ne 0){throw 'Concurrency tests failed'}}
