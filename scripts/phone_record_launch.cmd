@echo off
rem Double-click to record the app's cold start again (no rebuild).
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0phone_check.ps1" -RecordOnly
echo.
pause
