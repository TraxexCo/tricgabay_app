[CmdletBinding()]
param([string]$Workspace=(Join-Path ([IO.Path]::GetTempPath()) 'tricgabay-batch4-isolated'),[string]$LogDirectory=(Join-Path $PSScriptRoot '../.audit-output/batch4'))
$ErrorActionPreference='Stop'
$repo=(Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$target=[IO.Path]::GetFullPath($Workspace)
$temporary=[IO.Path]::GetFullPath([IO.Path]::GetTempPath())
if(-not $target.StartsWith($temporary,[StringComparison]::OrdinalIgnoreCase) -or (Split-Path $target -Leaf) -ne 'tricgabay-batch4-isolated'){throw 'Only the isolated Batch 4 temporary workspace is allowed.'}
if(Test-Path (Join-Path $target 'supabase/.temp/project-ref')){throw 'Refusing a linked project.'}
New-Item -ItemType Directory -Force -Path $target,$LogDirectory | Out-Null
$config=Join-Path $target 'supabase/config.toml'
# Use the pinned CLI defaults (including ports) on every run.
npx --yes supabase@2.121.0 init --force --workdir $target > (Join-Path $LogDirectory 'local-init.txt') 2>&1
if($LASTEXITCODE -ne 0){throw 'Local initialization failed'}
$utf8=[System.Text.UTF8Encoding]::new($false,$true)
$text=[System.IO.File]::ReadAllText($config,$utf8)
$text=[regex]::new('(?m)^project_id[ \t]*=[^\r\n]*').Replace($text,'project_id = "tricgabay_batch4_isolated"',1)
# Limit each edit to its own TOML section, even if its setting is already correct.
$text=[regex]::Replace($text,'(?m)^[ \t]*\[(?<name>[^\]\r\n]+)\][^\r\n]*(?:\r?\n(?![ \t]*\[)[^\r\n]*)*',{
  param($section)
  $name=$section.Groups['name'].Value
  if($name -eq 'auth.email'){
    return [regex]::Replace($section.Value,'(?m)^([ \t]*enable_confirmations[ \t]*=[ \t]*)(?:true|false)\b','${1}true')
  }
  if($name -eq 'realtime'){
    return [regex]::Replace($section.Value,'(?m)^([ \t]*enabled[ \t]*=[ \t]*)(?:true|false)\b','${1}true')
  }
  if($name -match '^auth\.(?:sms\.|external\.|third_party\.|hook\.|email\.smtp$|captcha$)'){
    return [regex]::Replace($section.Value,'(?m)^([ \t]*enabled[ \t]*=[ \t]*)(?:true|false)\b','${1}false')
  }
  return $section.Value
})
[System.IO.File]::WriteAllText($config,$text,$utf8)
New-Item -ItemType Directory -Force -Path (Join-Path $target 'supabase/migrations') | Out-Null
Copy-Item -Path (Join-Path $repo 'supabase/migrations/*.sql') -Destination (Join-Path $target 'supabase/migrations/')
# Realtime, Auth and Storage stay enabled. Startup output contains local keys;
# keep it private and do not publish it as a CI artifact.
npx --yes supabase@2.121.0 start --workdir $target --exclude studio,imgproxy,postgres-meta,edge-runtime,logflare,vector,supavisor > (Join-Path $LogDirectory 'local-start-private.txt') 2>&1
if($LASTEXITCODE -ne 0){throw 'Local Supabase startup failed; inspect the private startup log.'}
Write-Output 'LOCAL_STACK_PASS project=tricgabay_batch4_isolated realtime=true auth=true storage=true'
