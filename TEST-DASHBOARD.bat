@echo off
title SmartBus Dashboard Test
color 0A

echo ========================================
echo    🧪 Testing SmartBus Dashboard
echo ========================================
echo.

echo 🔍 Checking files...

if exist "index.html" (
    echo ✅ Main dashboard found
) else (
    echo ❌ Main dashboard missing
    pause
    exit /b 1
)

if exist "backend\server.js" (
    echo ✅ Backend server found
) else (
    echo ❌ Backend server missing
    pause
    exit /b 1
)

echo.
echo 🚀 Starting backend server...
cd backend
start "SmartBus Backend" cmd /k "echo 🚌 Starting SmartBus Backend... && node server.js"

echo.
echo ⏳ Waiting for server to start...
timeout /t 3 /nobreak > nul

echo.
echo 🌐 Opening dashboard...
cd ..
start "" "index.html"

echo.
echo ✅ Test Complete!
echo.
echo 📋 What to test:
echo    1. Switch between Passenger and Admin modes
echo    2. Search for buses (try: Katraj to Shivajinagar)
echo    3. Click on buses on the map
echo    4. In Admin mode, try adding a new bus
echo    5. Check if buses are moving on the map
echo.
echo 🎯 Expected Results:
echo    • Search should show available routes
echo    • Map should show moving buses
echo    • Admin mode should allow adding buses/routes
echo    • Everything should be responsive on mobile
echo.
pause