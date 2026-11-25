@echo off
rem Double-click to render every screen on the phone (sample data).
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0phone_screens.ps1"
echo.
pause
