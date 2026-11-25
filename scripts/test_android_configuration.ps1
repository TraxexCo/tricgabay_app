param([string]$LogDirectory=(Join-Path $PSScriptRoot '../.audit-output/batch4/android-config'))
$ErrorActionPreference='Stop'
$repo=(Resolve-Path (Join-Path $PSScriptRoot '..')).Path
New-Item -ItemType Directory -Force -Path $LogDirectory | Out-Null
$previousSigning=$env:ALLOW_DEBUG_RELEASE_SIGNING
# Only validation tasks run here; no signed release artifact is produced.
$env:ALLOW_DEBUG_RELEASE_SIGNING='true'
$checks=0
function Check-Configuration([string]$Flavor,[string]$Missing=''){
  $values=[ordered]@{APP_ENV=$Flavor;SUPABASE_URL="https://$Flavor.example.invalid";SUPABASE_PUBLISHABLE_KEY='synthetic-publishable-fixture';MAPBOX_PUBLIC_TOKEN='pk.synthetic-fixture';FIREBASE_API_KEY='synthetic-firebase-fixture';FIREBASE_APP_ID='1:123:android:synthetic';FIREBASE_MESSAGING_SENDER_ID='123';FIREBASE_PROJECT_ID='synthetic-fixture'}
  if($Missing){$values.Remove($Missing)}
  $encoded=($values.GetEnumerator() | ForEach-Object {[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("$($_.Key)=$($_.Value)"))}) -join ','
  $capitalized=$Flavor.Substring(0,1).ToUpper()+$Flavor.Substring(1)
  $arguments=@('-p',(Join-Path $repo 'android'),":app:validate${capitalized}ReleaseConfiguration","-Pdart-defines=$encoded",'--console=plain')
  $file=Join-Path $LogDirectory ("$Flavor-"+$(if($Missing){"missing-$Missing"}else{'configured'})+'.txt')
  if($IsWindows){& (Join-Path $repo 'android/gradlew.bat') @arguments > $file 2>&1}
  else{& bash (Join-Path $repo 'android/gradlew') @arguments > $file 2>&1}
  $exit=$LASTEXITCODE;$text=Get-Content -Raw $file
  if($Missing){if($exit -eq 0 -or $text -notmatch [regex]::Escape("Missing release configuration: $Missing")){throw "Missing value was not rejected: $Missing"}}
  elseif($exit -ne 0){throw "Synthetic configuration validation failed: $Flavor"}
  $script:checks++
}
try{
  foreach($flavor in @('dev','staging','production')){Check-Configuration $flavor}
  foreach($key in @('SUPABASE_URL','SUPABASE_PUBLISHABLE_KEY','MAPBOX_PUBLIC_TOKEN','FIREBASE_API_KEY','FIREBASE_APP_ID','FIREBASE_MESSAGING_SENDER_ID','FIREBASE_PROJECT_ID')){Check-Configuration 'production' $key}
  Write-Output "ANDROID_CONFIGURATION_PASS checks=$checks flavors=3 required_service_values_fail_closed=true synthetic_values_only=true"
  # The last check expects Gradle to fail, which leaves LASTEXITCODE at 1.
  # GitHub's pwsh step exits with LASTEXITCODE, so clear it once all checks pass.
  $global:LASTEXITCODE=0
}finally{$env:ALLOW_DEBUG_RELEASE_SIGNING=$previousSigning}
