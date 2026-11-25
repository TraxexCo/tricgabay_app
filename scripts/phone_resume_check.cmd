@echo off
rem Double-click: checks the app stays put after the notification shade and Home.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0phone_resume_check.ps1"
timeout /t 3 >nul
