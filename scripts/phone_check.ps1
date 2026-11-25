# Builds the phone-test APK, installs it on the USB-connected phone (keeping
# the sign-in), and records the app's cold start so the launch animation can
# be reviewed frame by frame. Output: build/phone_check/
#   -RecordOnly   skip the build and install; just record a cold start again
param([switch]$RecordOnly, [switch]$Clean, [switch]$Profile)
$ErrorActionPreference = 'Stop'
Set-Location (Split-Path -Parent $PSScriptRoot)
$adb = Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe'
$out = 'build\phone_check'
New-Item -ItemType Directory -Force $out | Out-Null
Start-Transcript -Path "$out\log.txt" -Force | Out-Null
try {
  & $adb devices -l
  if (-not $RecordOnly) {
    if ($Clean) { flutter clean; flutter pub get }
    # -Profile builds optimised code (release speed) so animations can be judged.
    $mode = if ($Profile) { 'profile' } else { 'debug' }
    flutter build apk --$mode --flavor production --dart-define-from-file=config/phone-test.json
    if ($LASTEXITCODE -ne 0) { throw 'Build failed' }
    & $adb install -r "build/app/outputs/flutter-apk/app-production-$mode.apk"
    if ($LASTEXITCODE -ne 0) { throw 'Install failed' }
  }
  # Cold start: stop the app, start recording, launch it, keep recording.
  & $adb shell am force-stop com.tricgabay.app
  & $adb logcat -c
  Start-Sleep -Seconds 1
  $rec = Start-Process -FilePath $adb -ArgumentList 'shell','screenrecord','--time-limit','20','--bit-rate','8000000','/sdcard/tricgabay_launch.mp4' -PassThru -NoNewWindow
  Start-Sleep -Seconds 1
  & $adb shell monkey -p com.tricgabay.app -c android.intent.category.LAUNCHER 1
  $rec.WaitForExit()
  Start-Sleep -Seconds 1
  & $adb pull /sdcard/tricgabay_launch.mp4 "$out\launch.mp4"
  & $adb shell rm /sdcard/tricgabay_launch.mp4
  & $adb logcat -d -v time > "$out\logcat.txt"
  & $adb shell screencap -p /sdcard/tricgabay_shot.png
  & $adb pull /sdcard/tricgabay_shot.png "$out\after_launch.png"
  & $adb shell rm /sdcard/tricgabay_shot.png
  Write-Host 'Done. Results are in build\phone_check' -ForegroundColor Green
} catch {
  Write-Host "Stopped: $_" -ForegroundColor Red
} finally {
  Stop-Transcript | Out-Null
}
