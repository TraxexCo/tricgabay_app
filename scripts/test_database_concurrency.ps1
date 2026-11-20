[CmdletBinding()]
param([string]$ContainerName='supabase_db_tricgabay_batch4_isolated', [string]$LogDirectory=(Join-Path $PSScriptRoot '../.audit-output/batch4/concurrency'))
$ErrorActionPreference='Stop'
if($ContainerName -notmatch '^supabase_db_tricgabay_batch4_[a-z0-9_]+$'){throw 'Only an isolated Batch 4 container is allowed.'}
New-Item -ItemType Directory -Force -Path $LogDirectory | Out-Null
$dockerExe=(Get-Command docker).Source
function Query([string]$Sql){
 $result=& $dockerExe exec $ContainerName psql -X -A -t -v ON_ERROR_STOP=1 -U supabase_admin -d postgres -c $Sql 2>&1
 if($LASTEXITCODE -ne 0){throw ($result -join "`n")}
 return ($result -join "`n").Trim()
}
function Wait-True([string]$Sql){for($i=0;$i -lt 150;$i++){if((Query $Sql) -eq 't'){return};Start-Sleep -Milliseconds 100};throw "Barrier timeout: $Sql"}
function Session([string]$Name,[string]$Sql){
 $inputPath=Join-Path $LogDirectory ($Name+'.sql');[IO.File]::WriteAllText($inputPath,$Sql,[Text.UTF8Encoding]::new($false))
 $windowOptions=@{};if($IsWindows){$windowOptions.WindowStyle='Hidden'}
 return Start-Process @windowOptions -FilePath $dockerExe -PassThru -ArgumentList @('exec','-i','-e',"PGAPPNAME=$Name",$ContainerName,'psql','-X','-A','-t','-v','ON_ERROR_STOP=1','-U','supabase_admin','-d','postgres') -RedirectStandardInput $inputPath -RedirectStandardOutput (Join-Path $LogDirectory ($Name+'.out')) -RedirectStandardError (Join-Path $LogDirectory ($Name+'.err'))
}
function Identity([string]$Id){return "set local role authenticated;select set_config('request.jwt.claim.role','authenticated',true);select set_config('request.jwt.claim.sub','$Id',true);"}
function Booking([string]$Id,[string]$Request){return (Identity $Id)+"select public.create_booking_with_schedule(null,'cash','Concurrency pickup',14.9571,120.9188,'[{`"spot_id`":`"batch3-concurrency`",`"stop_order`":1}]',1,'','',null,'$Request');"}
function Race([string]$Label,[string]$FirstSql,[string]$SecondSql,[bool]$SecondSucceeds){
 $prefix="batch3_${PID}_$Label";$barrier=$null;$first=$null;$second=$null
 try{
  $barrier=Session ($prefix+'_barrier') 'select pg_advisory_lock(93030001);select pg_sleep(50);'
  Wait-True "select exists(select 1 from pg_locks l join pg_stat_activity a on a.pid=l.pid where a.application_name='${prefix}_barrier' and l.locktype='advisory' and l.granted)"
  $first=Session ($prefix+'_first') ("begin;"+$FirstSql+'select pg_advisory_lock(93030001);commit;')
  Wait-True "select exists(select 1 from pg_stat_activity where application_name='${prefix}_first' and wait_event_type='Lock')"
  $second=Session ($prefix+'_second') ('begin;'+$SecondSql+'commit;')
  Wait-True "select exists(select 1 from pg_stat_activity where application_name='${prefix}_second' and wait_event_type='Lock')"
  Write-Output "LOCK_OVERLAP_PROVED $Label two real PostgreSQL sessions"
  Query "select pg_terminate_backend(pid) from pg_stat_activity where application_name='${prefix}_barrier'" | Out-Null
  if(-not $first.WaitForExit(20000) -or $first.ExitCode -ne 0){throw "First session failed: $Label"}
  if(-not $second.WaitForExit(20000)){throw "Second session timed out: $Label"}
  if(($second.ExitCode -eq 0) -ne $SecondSucceeds){throw "Unexpected second-session result: $Label exit=$($second.ExitCode)"}
  Write-Output "PASS $Label first_exit=$($first.ExitCode) second_exit=$($second.ExitCode)"
 }finally{foreach($process in @($barrier,$first,$second)){if($null -ne $process -and -not $process.HasExited){$process.Kill()}}}
}
$seed=Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot 'fixtures/concurrency.sql');Query $seed | Out-Null
Race 'different_uuid' (Booking 'b3500000-0000-4000-8000-000000000001' 'b3510000-0000-4000-8000-000000000001') (Booking 'b3500000-0000-4000-8000-000000000001' 'b3510000-0000-4000-8000-000000000002') $false
if((Query "select count(*) from public.bookings where tourist_id='b3500000-0000-4000-8000-000000000001'") -ne '1'){throw 'Different UUID race duplicated bookings'}
Race 'same_uuid' (Booking 'b3500000-0000-4000-8000-000000000002' 'b3510000-0000-4000-8000-000000000003') (Booking 'b3500000-0000-4000-8000-000000000002' 'b3510000-0000-4000-8000-000000000003') $true
if((Query "select count(*) from public.bookings where tourist_id='b3500000-0000-4000-8000-000000000002'") -ne '1'){throw 'Same UUID race duplicated bookings'}
Query ('begin;'+(Booking 'b3500000-0000-4000-8000-000000000003' 'b3510000-0000-4000-8000-000000000004')+'commit;') | Out-Null
$bookingId=Query "select id from public.bookings where tourist_id='b3500000-0000-4000-8000-000000000003'"
if((Query "select count(*) from public.booking_offers where booking_id='$bookingId' and status='offered'") -ne '2'){throw 'Both drivers must have real offers before acceptance race'}
Race 'driver_acceptance' ((Identity 'b3500000-0000-4000-8000-000000000101')+"select public.accept_booking('$bookingId');") ((Identity 'b3500000-0000-4000-8000-000000000102')+"select public.accept_booking('$bookingId');") $false
$state=Query "select concat_ws('|',status,driver_id,(select count(*) from public.booking_offers where booking_id=b.id and status='accepted'),(select count(*) from public.trip_events where booking_id=b.id and event_type='booking_accepted')) from public.bookings b where id='$bookingId'"
if($state -ne 'accepted|b3500000-0000-4000-8000-000000000101|1|1'){throw "Acceptance state mismatch: $state"}
Write-Output 'CONCURRENCY_PASS races=3 observed_lock_overlap=3'
# Commit preparation in one session, then resume in an independent new session.
$test=Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot '../supabase/tests/010_privacy_financial_integrity.sql')
$setup=$test.Substring($test.IndexOf("select set_config('request.jwt.claim.role'"))
$setup=$setup.Substring(0,$setup.IndexOf('create temp table before_financial'))
Query ('begin;'+$setup+'commit;') | Out-Null
$before=Query "select md5(string_agg((to_jsonb(l)-'description'-'metadata')::text,',' order by id)) from public.financial_ledger_entries l where booking_id='b3320000-0000-4000-8000-000000000001'"
$prepare="select set_config('request.jwt.claim.role','service_role',false);select public.prepare_account_deletion('b3300000-0000-4000-8000-000000000001','b3360000-0000-4000-8000-000000000001');"
Query $prepare | Out-Null
$anonymousId=Query "select anonymous_id from public.account_deletion_requests where user_id='b3300000-0000-4000-8000-000000000001'"
Query $prepare | Out-Null
if((Query "select anonymous_id from public.account_deletion_requests where user_id='b3300000-0000-4000-8000-000000000001'") -ne $anonymousId){throw 'Resumption created a second identity'}
$after=Query "select md5(string_agg((to_jsonb(l)-'description'-'metadata')::text,',' order by id)) from public.financial_ledger_entries l where booking_id='b3320000-0000-4000-8000-000000000001'"
if($before -ne $after){throw 'Committed deletion/resume changed ledger facts'}
Write-Output 'DELETION_RESUME_PASS independent_committed_sessions=2 ledger_facts_unchanged=true'
