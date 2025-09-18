# 🚌 Smart Bus Tracker

A real-time bus tracking system with live map interface and admin dashboard.

## ✅ What's Working

- **Real-time bus tracking** with live map updates every 5 seconds
- **Interactive dashboard** with passenger and admin modes
- **Bus search** between stops with route information
- **Live bus movement** simulation on map
- **Admin panel** to add/edit/delete buses and routes
- **WebSocket** real-time updates
- **Mobile responsive** design

## � Quihck Start

### Option 1: Use the Batch File
```bash
# Double-click this file:
START-HERE.bat
```

### Option 2: Manual Start
```bash
# 1. Start backend server
cd backend
npm install
node server.js

# 2. Open index.html in your browser
```

## 🛠️ Tech Stack

- **Backend**: Node.js + Express + Socket.io
- **Frontend**: HTML5 + Tailwind CSS + Leaflet Maps
- **Real-time**: WebSocket connections
- **Data**: In-memory with realistic simulation

## 📂 Project Structure

```
Smart-Bus-Tracker/
├── backend/
│   ├── server.js           # Main backend server
│   ├── package.json        # Dependencies
│   └── node_modules/       # Installed packages
├── index.html              # Main dashboard
├── START-HERE.bat          # Quick start script
└── README.md               # This file
```

## 🎯 Features

### For Passengers
- Search buses between stops
- View live bus locations on map
- Check arrival times and bus details
- Mobile-friendly interface

### For Admins
- Add/edit/delete buses and routes
- View fleet dashboard with statistics
- Monitor live bus movements
- Manage driver information

## 📡 API Endpoints

- `GET /api/buses` - Get all buses
- `GET /api/routes` - Get all routes
- `GET /api/drivers` - Get all drivers
- `POST /api/buses` - Add new bus
- `DELETE /api/buses/:id` - Delete bus
- `GET /health` - Health check

## 🌐 Access Points

- **Main Dashboard**: Open `index.html`
- **Backend API**: http://localhost:3000
- **Health Check**: http://localhost:3000/health

## 🔧 How to Use

1. **Start the system** using `START-HERE.bat`
2. **Switch modes** between Passenger and Admin
3. **Search buses** (try: Katraj to Shivajinagar)
4. **Click buses on map** for details
5. **Add buses/routes** in Admin mode

---

**🚌 Ready to use! No complex setup required.**