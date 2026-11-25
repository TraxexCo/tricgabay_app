@echo off
rem Double-click to save the app's Flutter log from the USB phone to build\phone_check\flutter_log.txt
cd /d "%~dp0.."
if not exist build\phone_check mkdir build\phone_check
"%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe" logcat -d -v time -s flutter > build\phone_check\flutter_log.txt
echo Saved build\phone_check\flutter_log.txt
timeout /t 3 >nul
