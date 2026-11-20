[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [string]$DockerExe,
  [string]$Image = 'public.ecr.aws/supabase/postgres:17.11.0.003',
  [string]$ContainerName = "tricgabay-batch9-$PID"
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath $DockerExe)) {
  throw "Docker executable was not found: $DockerExe"
}
if ($ContainerName -notmatch '^tricgabay-batch9-[A-Za-z0-9_.-]+$') {
  throw 'ContainerName must begin with tricgabay-batch9- and contain only safe name characters.'
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) $ContainerName
$createdContainer = $false
$database = 'postgres'
$dbUser = 'postgres'

function Invoke-Docker {
  param([string[]]$Arguments)
  & $DockerExe @Arguments
  if ($LASTEXITCODE -ne 0) {
    throw "Docker command failed with exit code ${LASTEXITCODE}: $($Arguments -join ' ')"
  }
}

function Invoke-PsqlCommand {
  param([string]$Sql, [switch]$TuplesOnly)
  $arguments = @('exec', $ContainerName, 'psql', '-v', 'ON_ERROR_STOP=1', '-U', $dbUser, '-d', $database)
  if ($TuplesOnly) { $arguments += @('-A', '-t') }
  $arguments += @('-c', $Sql)
  $result = & $DockerExe @arguments
  if ($LASTEXITCODE -ne 0) { throw "psql command failed: $Sql" }
  return ($result -join "`n").Trim()
}

function Invoke-PsqlFile {
  param([string]$Path, [string]$User = $dbUser)
  Get-Content -Raw -LiteralPath $Path |
    & $DockerExe exec -i $ContainerName psql -v ON_ERROR_STOP=1 -U $User -d $database
  if ($LASTEXITCODE -ne 0) { throw "psql file failed: $Path" }
}

function Wait-ForQuery {
  param([string]$Sql, [string]$Expected = '1', [int]$Attempts = 200)
  for ($attempt = 0; $attempt -lt $Attempts; $attempt += 1) {
    $value = Invoke-PsqlCommand -Sql $Sql -TuplesOnly
    if ($value -eq $Expected) { return }
    Start-Sleep -Milliseconds 100
  }
  throw "Timed out waiting for database barrier: $Sql"
}

function New-SessionProcess {
  param(
    [string]$ApplicationName,
    [string]$Sql,
    [string]$Label
  )
  $inputPath = Join-Path $tempRoot "$Label.sql"
  $stdoutPath = Join-Path $tempRoot "$Label.stdout.txt"
  $stderrPath = Join-Path $tempRoot "$Label.stderr.txt"
  [System.IO.File]::WriteAllText($inputPath, $Sql, [System.Text.UTF8Encoding]::new($false))
  return Start-Process -FilePath $DockerExe -WindowStyle Hidden -PassThru -ArgumentList @(
    'exec', '-i', '-e', "PGAPPNAME=$ApplicationName", $ContainerName,
    'psql', '-v', 'ON_ERROR_STOP=1', '-U', $dbUser, '-d', $database
  ) -RedirectStandardInput $inputPath -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath
}

function Reset-RecoveryFixture {
  Invoke-PsqlCommand -Sql @"
delete from public.trip_events
 where booking_id='92000000-0000-4000-8000-000000000001'
   and event_type='pickup_code_recovered';
update public.bookings set
  pickup_code_hash=crypt('1111',gen_salt('bf')),
  pickup_code_recovery_id=null,
  pickup_code_recovered_at=null,
  pickup_code_failed_attempts=3,
  pickup_code_locked_until=null,
  status='pending'
where id='92000000-0000-4000-8000-000000000001';
"@ | Out-Null
}

function RecoverySql {
  param([string]$RecoveryId, [string]$Code, [switch]$HoldBeforeCommit)
  $barrier = if ($HoldBeforeCommit) { 'select pg_advisory_lock(9009009);' } else { '' }
  return @"
begin;
set local role authenticated;
select set_config('request.jwt.claim.role','authenticated',true);
select set_config('request.jwt.claim.sub','90000000-0000-4000-8000-000000000101',true);
select public.recover_booking_pickup_code(
  '92000000-0000-4000-8000-000000000001',
  '$RecoveryId',
  '$Code'
);
$barrier
commit;
"@
}

function Assert-RecoveryState {
  param([string]$RecoveryId, [string]$Code, [string]$Scenario)
  $state = Invoke-PsqlCommand -TuplesOnly -Sql @"
select concat_ws('|',
  pickup_code_recovery_id::text,
  (pickup_code_hash=crypt('$Code',pickup_code_hash))::text,
  pickup_code_failed_attempts::text,
  (select count(*) from public.trip_events
    where booking_id=bookings.id and event_type='pickup_code_recovered')::text,
  (not exists(select 1 from public.trip_events
    where booking_id=bookings.id
      and (description like '%$Code%' or metadata::text like '%$Code%')))::text
)
from public.bookings
where id='92000000-0000-4000-8000-000000000001';
"@
  $expected = "$RecoveryId|true|3|1|true"
  if ($state -ne $expected) {
    throw "$Scenario produced unexpected authoritative state. Expected $expected, got $state"
  }
}

function Invoke-RecoveryRace {
  param(
    [string]$Scenario,
    [string]$FirstRecoveryId,
    [string]$FirstCode,
    [string]$SecondRecoveryId,
    [string]$SecondCode,
    [bool]$SecondShouldSucceed
  )
  Reset-RecoveryFixture
  $barrierName = "batch9_barrier_$Scenario"
  $firstName = "batch9_first_$Scenario"
  $secondName = "batch9_second_$Scenario"

  $barrier = New-SessionProcess -ApplicationName $barrierName -Label "$Scenario-barrier" -Sql @"
select pg_advisory_lock(9009009);
select pg_sleep(300);
"@
  Wait-ForQuery -Sql "select count(*) from pg_locks l join pg_stat_activity a on a.pid=l.pid where a.application_name='$barrierName' and l.locktype='advisory' and l.granted" | Out-Null

  $first = New-SessionProcess -ApplicationName $firstName -Label "$Scenario-first" -Sql (
    RecoverySql -RecoveryId $FirstRecoveryId -Code $FirstCode -HoldBeforeCommit
  )
  Wait-ForQuery -Sql "select count(*) from pg_stat_activity where application_name='$firstName' and wait_event_type='Lock'" | Out-Null

  $second = New-SessionProcess -ApplicationName $secondName -Label "$Scenario-second" -Sql (
    RecoverySql -RecoveryId $SecondRecoveryId -Code $SecondCode
  )
  Wait-ForQuery -Sql "select count(*) from pg_stat_activity where application_name='$secondName' and wait_event_type='Lock'" | Out-Null

  Invoke-PsqlCommand -Sql "select pg_terminate_backend(pid) from pg_stat_activity where application_name='$barrierName';" | Out-Null
  if (-not $first.WaitForExit(30000)) { throw "$Scenario first session did not finish" }
  if (-not $second.WaitForExit(30000)) { throw "$Scenario second session did not finish" }
  if (-not $barrier.WaitForExit(30000)) { throw "$Scenario barrier session did not finish" }
  if ($first.ExitCode -ne 0) { throw "$Scenario first session failed" }
  if ($SecondShouldSucceed -and $second.ExitCode -ne 0) {
    throw "$Scenario identical retry should have succeeded"
  }
  if (-not $SecondShouldSucceed -and $second.ExitCode -eq 0) {
    throw "$Scenario conflicting retry should have failed"
  }
  Assert-RecoveryState -RecoveryId $FirstRecoveryId -Code $FirstCode -Scenario $Scenario
  Write-Output "PASS $Scenario (second_exit=$($second.ExitCode))"
}

try {
  New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null
  Invoke-Docker -Arguments @('run', '--name', $ContainerName, '-e', 'POSTGRES_PASSWORD=postgres', '-d', $Image)
  $createdContainer = $true
  for ($attempt = 0; $attempt -lt 120; $attempt += 1) {
    & $DockerExe exec $ContainerName pg_isready -U $dbUser -d $database *> $null
    if ($LASTEXITCODE -eq 0) { break }
    Start-Sleep -Milliseconds 250
  }
  if ($LASTEXITCODE -ne 0) { throw 'PostgreSQL did not become ready.' }
  $initComplete = $false
  for ($attempt = 0; $attempt -lt 240; $attempt += 1) {
    $logs = & $DockerExe logs $ContainerName 2>&1
    if (($logs -join "`n") -match 'PostgreSQL init process complete; ready for start up') {
      $initComplete = $true
      break
    }
    Start-Sleep -Milliseconds 250
  }
  if (-not $initComplete) { throw 'Supabase PostgreSQL image initialization did not complete.' }
  for ($attempt = 0; $attempt -lt 120; $attempt += 1) {
    & $DockerExe exec $ContainerName pg_isready -U $dbUser -d $database *> $null
    if ($LASTEXITCODE -eq 0) { break }
    Start-Sleep -Milliseconds 250
  }
  if ($LASTEXITCODE -ne 0) { throw 'Final PostgreSQL server did not become ready.' }
  $rolesReady = $false
  for ($attempt = 0; $attempt -lt 240; $attempt += 1) {
    $roleCount = & $DockerExe exec $ContainerName psql -U $dbUser -d $database -A -t -c `
      "select (select count(*) from pg_roles where rolname in ('anon','authenticated','service_role','supabase_storage_admin'))::text || '|' || (to_regclass('auth.users') is not null)::text;" 2>$null
    if ($LASTEXITCODE -eq 0 -and ($roleCount -join '').Trim() -eq '4|true') {
      $rolesReady = $true
      break
    }
    Start-Sleep -Milliseconds 250
  }
  if (-not $rolesReady) { throw 'Supabase database roles did not finish initializing.' }

  Invoke-PsqlFile -Path (Join-Path $repoRoot 'supabase\local_validation\storage_bootstrap.sql') `
    -User 'supabase_admin'
  foreach ($migration in Get-ChildItem (Join-Path $repoRoot 'supabase\migrations') -File | Sort-Object Name) {
    Invoke-PsqlFile -Path $migration.FullName -User 'supabase_admin'
  }

  $pgTapAssertions = 0
  foreach ($testFile in Get-ChildItem (Join-Path $repoRoot 'supabase\tests') -Filter '*.sql' -File | Sort-Object Name) {
    $testOutput = Get-Content -Raw -LiteralPath $testFile.FullName |
      & $DockerExe exec -i $ContainerName psql -X -v ON_ERROR_STOP=1 -U supabase_admin -d $database 2>&1
    $testExit = $LASTEXITCODE
    $testText = ($testOutput -join "`n")
    if ($testExit -ne 0 -or $testText -match '(?m)^\s*not ok\b') {
      throw "pgTAP suite failed: $($testFile.Name)`n$testText"
    }
    $count = [regex]::Matches($testText, '(?m)^\s*ok\s+\d+\b').Count
    $pgTapAssertions += $count
    Write-Output "PASS $($testFile.Name) ($count assertions)"
  }
  Write-Output "PGTAP_PASS assertions=$pgTapAssertions suites=$((Get-ChildItem (Join-Path $repoRoot 'supabase\tests') -Filter '*.sql' -File).Count)"

  Invoke-PsqlCommand -Sql @"
insert into auth.users(id,email,raw_user_meta_data)
values ('90000000-0000-4000-8000-000000000101','batch9-owner@test.local','{"full_name":"Batch 9 Owner"}');
insert into public.fare_revisions(id,custom_fare_centavos,package_fares,is_current,reason)
values ('91000000-0000-4000-8000-000000000001',12500,'{}',false,'Batch 9');
insert into public.cancellation_policies(id,is_current,terms)
values ('91000000-0000-4000-8000-000000000002',false,'Batch 9');
insert into public.bookings(
  id,tourist_id,fare_revision_id,cancellation_policy_id,quoted_amount_centavos,
  payment_method,payment_status,status,pickup_address,pickup_latitude,
  pickup_longitude,pickup_code_hash,pickup_code_failed_attempts
) values (
  '92000000-0000-4000-8000-000000000001',
  '90000000-0000-4000-8000-000000000101',
  '91000000-0000-4000-8000-000000000001',
  '91000000-0000-4000-8000-000000000002',
  12500,'cash','unpaid','pending','Batch 9',14.95,120.91,
  crypt('1111',gen_salt('bf')),3
);
"@ | Out-Null

  Invoke-RecoveryRace -Scenario 'same-request' `
    -FirstRecoveryId '93000000-0000-4000-8000-000000000001' -FirstCode '4827' `
    -SecondRecoveryId '93000000-0000-4000-8000-000000000001' -SecondCode '4827' `
    -SecondShouldSucceed $true
  Invoke-RecoveryRace -Scenario 'different-request' `
    -FirstRecoveryId '93000000-0000-4000-8000-000000000002' -FirstCode '1954' `
    -SecondRecoveryId '93000000-0000-4000-8000-000000000003' -SecondCode '2356' `
    -SecondShouldSucceed $false
  Invoke-RecoveryRace -Scenario 'same-request-different-code' `
    -FirstRecoveryId '93000000-0000-4000-8000-000000000004' -FirstCode '3478' `
    -SecondRecoveryId '93000000-0000-4000-8000-000000000004' -SecondCode '7631' `
    -SecondShouldSucceed $false

  Reset-RecoveryFixture
  $discarded = New-SessionProcess -ApplicationName 'batch9_lost_response' -Label 'lost-response' -Sql (
    RecoverySql -RecoveryId '93000000-0000-4000-8000-000000000005' -Code '8642'
  )
  if (-not $discarded.WaitForExit(30000) -or $discarded.ExitCode -ne 0) {
    throw 'Lost-response setup session failed'
  }
  $retryResult = Invoke-PsqlCommand -TuplesOnly -Sql (RecoverySql `
    -RecoveryId '93000000-0000-4000-8000-000000000005' -Code '8642')
  if ($retryResult -notmatch '8642') { throw 'Lost-response retry did not return the authoritative code' }
  Assert-RecoveryState -RecoveryId '93000000-0000-4000-8000-000000000005' -Code '8642' -Scenario 'lost-response'
  Write-Output 'PASS lost-response retry from an independent session'
  Write-Output 'BATCH9_CONCURRENCY_PASS'
}
finally {
  if ($createdContainer -and $ContainerName -match '^tricgabay-batch9-') {
    & $DockerExe rm -f $ContainerName *> $null
  }
  if (Test-Path -LiteralPath $tempRoot) {
    Remove-Item -LiteralPath $tempRoot -Recurse -Force
  }
}
