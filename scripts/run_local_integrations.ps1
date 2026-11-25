param([string]$Workspace=(Join-Path ([IO.Path]::GetTempPath()) 'tricgabay-batch4-isolated'),[string]$LogDirectory=(Join-Path $PSScriptRoot '../.audit-output/batch4'),[switch]$SkipLoad)
$ErrorActionPreference='Stop'
if((Get-Content -Raw (Join-Path $Workspace 'supabase/config.toml')) -notmatch 'project_id = "tricgabay_batch4_isolated"' -or (Test-Path (Join-Path $Workspace 'supabase/.temp/project-ref'))){throw 'An unlinked Batch 4 stack is required'}
New-Item -ItemType Directory -Force -Path $LogDirectory | Out-Null
$status=npx --yes supabase@2.121.0 status --workdir $Workspace -o json 2>$null | ConvertFrom-Json
if($LASTEXITCODE -ne 0 -or $status.API_URL -notmatch '^http://(127\.0\.0\.1|localhost):\d+$'){throw 'Only a running loopback API may be tested'}
$env:LOCAL_SUPABASE_URL=$status.API_URL;$env:LOCAL_SUPABASE_ANON_KEY=$status.ANON_KEY;$env:LOCAL_SUPABASE_SERVICE_ROLE_KEY=$status.SERVICE_ROLE_KEY;$env:LOCAL_JWT_SECRET=$status.JWT_SECRET;$env:VALIDATION_LOG_DIR=$LogDirectory
try{
  deno test --config supabase/functions/deno.json --allow-env --allow-net=127.0.0.1,localhost supabase/functions/tests > (Join-Path $LogDirectory 'deno-tests.txt') 2>&1
  if($LASTEXITCODE -ne 0){throw 'Deno tests failed'}
  deno run --allow-env --allow-run=docker --allow-net=127.0.0.1,localhost --allow-write=$LogDirectory scripts/test_storage_access.ts > (Join-Path $LogDirectory 'storage-authorization.txt') 2>&1
  if($LASTEXITCODE -ne 0){throw 'Storage matrix failed'}
  if(-not $SkipLoad){
    deno run --allow-env --allow-run=docker --allow-net=127.0.0.1,localhost --allow-write=$LogDirectory scripts/test_realtime_load.ts > (Join-Path $LogDirectory 'realtime-load.txt') 2>&1
    if($LASTEXITCODE -ne 0){throw 'Realtime load/reconnect failed'}
  }
  Write-Output 'LOCAL_INTEGRATIONS_PASS deno=true storage=true'
}finally{foreach($name in @('LOCAL_SUPABASE_URL','LOCAL_SUPABASE_ANON_KEY','LOCAL_SUPABASE_SERVICE_ROLE_KEY','LOCAL_JWT_SECRET')){[Environment]::SetEnvironmentVariable($name,$null,'Process')}}
