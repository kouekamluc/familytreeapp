@echo off
title Family Tree App Launcher
echo ========================================================
echo       Starting Family Tree Local Development
echo ========================================================
echo.

cd /d "%~dp0"

echo [1/2] Starting Django Backend (Port 8000)...
start "FamilyTree Backend (Django)" cmd /k "cd backend && ..\.venv\Scripts\python.exe manage.py runserver 127.0.0.1:8000"

timeout /t 2 /nobreak >nul

echo [2/2] Starting Vite Frontend (Port 5173)...
start "FamilyTree Frontend (Vite)" cmd /k "cd frontend && npm run dev"

timeout /t 3 /nobreak >nul

echo.
echo ========================================================
echo Development servers started successfully!
echo.
echo   Frontend App:   http://localhost:5173
echo   Backend API:    http://localhost:8000
echo   API Swagger:    http://localhost:8000/api/docs/
echo   Django Admin:   http://localhost:8000/admin/
echo.
echo   Demo Login:
echo     Username:     testuser
echo     Password:     password123
echo ========================================================
echo.

start http://localhost:5173
