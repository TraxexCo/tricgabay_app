[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$BaseUrl,[int]$MinimumAgeSeconds=120,[switch]$DryRun)
$ErrorActionPreference='Stop'
$uri=[Uri]$BaseUrl
if($uri.Scheme -ne 'http' -or $uri.Host -notin @('127.0.0.1','localhost')){throw 'This checked-in runner only permits isolated local endpoints. Production must use separately approved operations tooling.'}
$serviceKey=$env:LOCAL_SUPABASE_SERVICE_ROLE_KEY
if([string]::IsNullOrWhiteSpace($serviceKey)){throw 'Set LOCAL_SUPABASE_SERVICE_ROLE_KEY from the isolated local stack; do not print or check it in.'}
$headers=@{apikey=$serviceKey;Authorization="Bearer $serviceKey"}
$cutoff=[Uri]::EscapeDataString([DateTime]::UtcNow.AddSeconds(-$MinimumAgeSeconds).ToString('o'))
$requests=Invoke-RestMethod -Uri "$($BaseUrl.TrimEnd('/'))/rest/v1/account_deletion_requests?select=user_id,request_id&prepared_at=lt.$cutoff" -Headers $headers
Write-Output "RECOVERY_REQUESTS count=$(@($requests).Count) dry_run=$DryRun"
if($DryRun){return}
$completed=0
foreach($request in $requests){
 $body=@{user_id=$request.user_id;request_id=$request.request_id;confirmation='DELETE'}|ConvertTo-Json
 $result=Invoke-RestMethod -Uri "$($BaseUrl.TrimEnd('/'))/functions/v1/delete-account" -Method Post -Headers $headers -ContentType 'application/json' -Body $body
 if($result.deleted -ne $true){throw 'Recovery did not confirm completion; leave the durable request for retry.'}
 $completed++
}
Write-Output "RECOVERY_COMPLETE count=$completed"
