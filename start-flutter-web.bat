@echo off
title Royal Ancestry - Flutter Web Launcher
echo ========================================================
echo       Starting Royal Ancestry Flutter Web App
echo ========================================================
echo.

cd /d "%~dp0"

echo [1/2] Starting Django Backend (Port 8000, 0.0.0.0 for LAN/Wi-Fi)...
start "FamilyTree Backend (Django)" cmd /k "cd backend && ..\.venv\Scripts\python.exe manage.py runserver 0.0.0.0:8000"

timeout /t 2 /nobreak >nul

echo [2/2] Starting Flutter Web Server (Port 8085)...
start "Royal Ancestry Flutter Web" cmd /k ".\.venv\Scripts\python.exe -m http.server 8085 --directory flutter_frontend\build\web"

timeout /t 2 /nobreak >nul

echo.
echo ========================================================
echo Servers running!
echo.
echo   Flutter Web App:   http://localhost:8085
echo   Backend API:       http://localhost:8000/api/
echo   API Swagger Docs:  http://localhost:8000/api/docs/
echo   Django Admin:      http://localhost:8000/admin/
echo ========================================================
echo.

start http://localhost:8085
