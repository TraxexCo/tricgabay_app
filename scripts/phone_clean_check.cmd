@echo off
rem Double-click for a clean rebuild, install and launch recording.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0phone_check.ps1" -Clean
echo.
pause
