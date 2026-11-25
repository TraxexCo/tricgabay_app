# Checks what the app shows after the notification shade is pulled down and
# up, and after a quick trip to the Home screen: it should stay on the same
# screen, never the blue launch logo. Leave the app open on any screen first.
# Output: build/phone_resume/*.png
$ErrorActionPreference = 'Stop'
Set-Location (Split-Path -Parent $PSScriptRoot)
$adb = Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe'
$out = 'build\phone_resume'
New-Item -ItemType Directory -Force $out | Out-Null
Remove-Item "$out\*.png" -ErrorAction SilentlyContinue
function Shot($name) {
  & $adb shell screencap -p /sdcard/tg_resume.png
  & $adb pull /sdcard/tg_resume.png "$out\$name.png" | Out-Null
}
& $adb shell monkey -p com.tricgabay.app -c android.intent.category.LAUNCHER 1 | Out-Null
Start-Sleep -Seconds 4
Shot '0_before'
# Notification shade down and up.
& $adb shell cmd statusbar expand-notifications
Start-Sleep -Seconds 2
& $adb shell cmd statusbar collapse
Start-Sleep -Milliseconds 300
Shot '1_shade_0.3s'
Start-Sleep -Seconds 1
Shot '2_shade_1.3s'
# Home screen for 5 seconds, then back to the app.
& $adb shell input keyevent KEYCODE_HOME
Start-Sleep -Seconds 5
& $adb shell monkey -p com.tricgabay.app -c android.intent.category.LAUNCHER 1 | Out-Null
Start-Sleep -Milliseconds 400
Shot '3_home_0.4s'
Start-Sleep -Seconds 1
Shot '4_home_1.4s'
& $adb shell rm /sdcard/tg_resume.png
Write-Host 'Done. Screenshots are in build\phone_resume' -ForegroundColor Green
