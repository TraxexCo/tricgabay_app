[CmdletBinding()]
param([string]$ContainerName='supabase_db_tricgabay_batch4_isolated', [string]$LogDirectory=(Join-Path $PSScriptRoot '../.audit-output/batch4/pgtap'))
$ErrorActionPreference='Stop'
if ($ContainerName -notmatch '^supabase_db_tricgabay_batch4_[a-z0-9_]+$') { throw 'Only an isolated Batch 4 database is allowed.' }
New-Item -ItemType Directory -Force -Path $LogDirectory | Out-Null
$existingBookings=docker exec $ContainerName psql -X -A -t -v ON_ERROR_STOP=1 -U supabase_admin -d postgres -c 'select count(*) from public.bookings'
if($LASTEXITCODE -ne 0){throw 'Could not verify the isolated fixture state'}
if([long]($existingBookings -join '').Trim() -ne 0){throw 'pgTAP suites require a freshly reset isolated database. Run validate_database.ps1 before concurrency/API/load/benchmark fixtures.'}
$failures=0; $assertions=0; $suites=0
foreach($file in Get-ChildItem (Join-Path $PSScriptRoot '../supabase/tests') -Filter '*.sql' -File | Sort-Object Name) {
  $output=Get-Content -Raw -LiteralPath $file.FullName | docker exec -i $ContainerName psql -X -A -t -v ON_ERROR_STOP=1 -U supabase_admin -d postgres 2>&1
  $exitCode=$LASTEXITCODE; $text=$output -join "`n"; $suites++
  Set-Content -LiteralPath (Join-Path $LogDirectory ($file.BaseName+'.txt')) -Value $text
  $count=[regex]::Matches($text,'(?m)^ok \d+\b').Count
  $plan=[regex]::Match($text,'(?m)^1\.\.(\d+)\s*$')
  $passed=$exitCode -eq 0 -and $text -notmatch '(?m)^not ok\b' -and $plan.Success -and $count -eq [int]$plan.Groups[1].Value
  if(-not $passed) { $failures++; Write-Output "FAIL $($file.Name) exit=$exitCode assertions=$count" } else { $assertions+=$count; Write-Output "PASS $($file.Name) assertions=$count" }
}
Write-Output "PGTAP_RESULT suites=$suites assertions=$assertions failed_suites=$failures"
if($failures) {exit 1}
