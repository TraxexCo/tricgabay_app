@echo off
rem Double-click to build, install and record the app's launch on the phone.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0phone_check.ps1" %*
echo.
pause
