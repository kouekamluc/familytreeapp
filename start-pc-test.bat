@echo off
powershell -NoProfile -File "%~dp0scripts\start-pc-test.ps1" %*
if errorlevel 1 pause
