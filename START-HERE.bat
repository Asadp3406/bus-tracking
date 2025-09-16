@echo off
title SmartBus Tracker - Complete System
color 0A

echo.
echo ╔════════════════════════════════════════╗
echo ║        🚌 SmartBus Tracker             ║
echo ║     Complete Transport System          ║
echo ╚════════════════════════════════════════╝
echo.

echo 🔍 Checking system requirements...

:: Check if Node.js is installed
node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Node.js is not installed!
    echo 📥 Please install Node.js from: https://nodejs.org/
    echo.
    pause
    exit /b 1
)

echo ✅ Node.js is installed
echo.

echo 📦 Installing minimal dependencies...
cd backend
if not exist node_modules (
    echo Installing express, cors, socket.io...
    npm install express@^4.18.2 cors@^2.8.5 socket.io@^4.6.0
    if %errorlevel% neq 0 (
        echo ❌ Failed to install dependencies
        echo 💡 Try running: npm install --no-optional
        pause
        exit /b 1
    )
)

echo ✅ Dependencies ready
echo.

echo 🚀 Starting SmartBus Backend Server...
start "SmartBus Backend" cmd /k "echo 🚌 SmartBus Backend Starting... && node server.js"

echo ⏳ Waiting for server to start...
timeout /t 5 /nobreak > nul

echo 🌐 Opening SmartBus Dashboard...
cd ..
start "" "index.html"

echo.
echo ✅ SmartBus Tracker is now running!
echo.
echo 📋 Access Points:
echo    • Backend API: http://localhost:3000
echo    • Main Dashboard: index.html (opened)
echo    • Health Check: http://localhost:3000/health
echo.
echo 🎯 Features Available:
echo    • ✅ Real-time bus tracking
echo    • ✅ Add/Edit/Delete buses and routes
echo    • ✅ Passenger search and ETA
echo    • ✅ Live map with moving buses
echo    • ✅ Admin dashboard with analytics
echo.
echo 🔄 System auto-refreshes every 5 seconds
echo 🚌 Switch between Passenger/Admin modes in dashboard
echo.
echo 💡 Tip: If dashboard doesn't open automatically,
echo    manually open: index.html
echo.
pause