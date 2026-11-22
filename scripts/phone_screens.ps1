# Renders every screen ON THE PHONE with sample data (no accounts, nothing
# saved) and saves the screenshots to build/phone_screens/. The test app
# replaces the installed app while it runs; the normal app is reinstalled at
# the end from the last profile or debug build.
$ErrorActionPreference = 'Stop'
Set-Location (Split-Path -Parent $PSScriptRoot)
$adb = Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe'
New-Item -ItemType Directory -Force 'build\phone_screens' | Out-Null
Start-Transcript -Path 'build\phone_screens\log.txt' -Force | Out-Null
try {
  $device = (& $adb devices | Select-String '\tdevice$' | Select-Object -First 1).ToString().Split("`t")[0]
  flutter drive --driver=test_driver/integration_test.dart --target=integration_test/screens_on_device_test.dart --flavor production --dart-define=APP_ENV=production -d $device
  $apk = @('build/app/outputs/flutter-apk/app-production-profile.apk', 'build/app/outputs/flutter-apk/app-production-debug.apk') | Where-Object { Test-Path $_ } | Select-Object -First 1
  if ($apk) { & $adb install -r $apk }
  Write-Host 'Done. Screenshots are in build\phone_screens' -ForegroundColor Green
} catch {
  Write-Host "Stopped: $_" -ForegroundColor Red
} finally {
  Stop-Transcript | Out-Null
}
