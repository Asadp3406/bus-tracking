@echo off
title Smart Bus Tracker
color 0A

echo ╔════════════════════════════════════════╗
echo ║        🚌 Smart Bus Tracker            ║
echo ╚════════════════════════════════════════╝
echo.

:: Check if Node.js is installed
node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Node.js is not installed!
    echo 📥 Please install Node.js from: https://nodejs.org/
    pause
    exit /b 1
)

echo ✅ Node.js found
echo.

:: Install dependencies if needed
cd backend
if not exist node_modules (
    echo 📦 Installing dependencies...
    npm install
)

echo 🚀 Starting backend server...
start "Bus Tracker Backend" cmd /k "node server.js"

echo ⏳ Waiting for server...
timeout /t 3 /nobreak > nul

echo 🌐 Opening dashboard...
cd ..
start "" "index.html"

echo.
echo ✅ Smart Bus Tracker is running!
echo.
echo 📋 What you can do:
echo    • Switch between Passenger/Admin modes
echo    • Search buses (try: Katraj to Shivajinagar)
echo    • Click buses on map for details
echo    • Add/edit buses in Admin mode
echo.
pause