@echo off
rem Double-click for a release-speed (profile) build, install and launch recording.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0phone_check.ps1" -Profile
echo.
pause
