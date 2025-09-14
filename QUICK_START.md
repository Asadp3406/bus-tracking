# 🚀 Quick Start Guide - SmartBus Tracker

## ⚡ Instant Demo (No Installation Required!)

### 1. **Live HTML Demo** - Works Immediately!
Simply open this file in your browser:
```
smartbus-tracker\demo\index.html
```

**Features of the demo:**
- ✅ Live moving buses on real map
- ✅ Click buses to track them
- ✅ Real-time speed and ETA updates
- ✅ Beautiful Zomato-like interface
- ✅ Works offline - no server needed!

---

## 📱 Running the Full System

### Option 1: Simple Backend Server (5 minutes setup)

1. **Install Node.js** (if not installed)
   - Download from: https://nodejs.org/

2. **Start the backend server:**
```powershell
cd smartbus-tracker\backend
npm install
npm start
```

The server will run at: http://localhost:3000

3. **Open the API in browser:**
   - API Documentation: http://localhost:3000
   - Health Check: http://localhost:3000/health

### Option 2: Docker Setup (Complete System)

1. **Install Docker Desktop for Windows**
   - Download from: https://www.docker.com/products/docker-desktop/

2. **Start all services:**
```powershell
cd smartbus-tracker\docker
docker-compose up
```

3. **Access services:**
   - Backend API: http://localhost:3000
   - Admin Dashboard: http://localhost:5173
   - pgAdmin: http://localhost:5050
   - Portainer: http://localhost:9000

---

## 🎯 For SIH Presentation

### Quick Demo Steps:

1. **Open the HTML Demo** (smartbus-tracker\demo\index.html)
   - Show live tracking
   - Click on buses to see details
   - Demonstrate real-time movement

2. **Show the Code Structure:**
   - Flutter app code in `mobile-app/`
   - Backend APIs in `backend/`
   - Admin dashboard in `admin-dashboard/`

3. **Highlight Key Features:**
   - Real-time tracking (buses move every 2 seconds)
   - ETA calculations
   - Passenger count tracking
   - Beautiful Material Design UI
   - WebSocket/MQTT ready architecture

---

## 🔧 Troubleshooting

### If the demo doesn't open:
- Right-click on `demo\index.html`
- Select "Open with" > Your browser (Chrome/Edge/Firefox)

### If npm install fails:
```powershell
# Clear npm cache
npm cache clean --force

# Try again
npm install
```

### If Docker doesn't start:
- Make sure Docker Desktop is running
- Check if virtualization is enabled in BIOS
- Restart Docker Desktop

---

## 📊 System Architecture

```
User Apps (Flutter)
     ↓
WebSocket/MQTT
     ↓
Node.js Backend
     ↓
PostgreSQL + Redis + MongoDB
```

---

## 🎨 Screenshots for Presentation

1. Open the demo and take screenshots of:
   - Map with moving buses
   - Bus details panel
   - Active buses list
   - Statistics panel

2. Use these in your PPT to show the working system

---

## 💡 Quick Tips for Demo

1. **Click any bus** on the map to track it
2. **Watch the buses move** in real-time
3. **Check the statistics panel** for live updates
4. **Use the pause button** to control simulation
5. **Click bus cards** at bottom to zoom to specific buses

---

## 📞 Need Help?

If you face any issues:
1. Check if all files are properly extracted
2. Make sure you have a modern browser (Chrome/Edge/Firefox)
3. For the full system, ensure Node.js is installed

Good luck with your SIH presentation! 🏆
