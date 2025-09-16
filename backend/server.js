const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const cors = require('cors');

console.log('🚌 SmartBus Tracker Backend Starting...');

// Initialize Express app
const app = express();
const server = http.createServer(app);

// Initialize Socket.io with CORS
const io = socketIo(server, {
    cors: {
        origin: '*',
        methods: ['GET', 'POST'],
        credentials: true
    },
    transports: ['websocket', 'polling']
});

// Middleware
app.use(cors({ origin: '*', credentials: true }));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// In-memory database simulation
let busIdCounter = 6;
let routeIdCounter = 4;

// Sample bus data
let buses = [
    {
        id: 'MH12-AB-1234',
        routeId: 1,
        route: 'Route 1: Katraj to Shivajinagar',
        lat: 18.5074,
        lng: 73.8077,
        speed: 35,
        bearing: 45,
        nextStop: 'Swargate',
        nextStopId: 2,
        eta: 5,
        passengers: 42,
        capacity: 60,
        status: 'active',
        driver: {
            name: 'Rajesh Kumar',
            id: 'D001',
            phone: '+91-9876543210',
            license: 'MH12-DL-001'
        },
        busType: 'AC',
        fare: 15,
        lastUpdated: new Date(),
        delay: 2,
        fuelLevel: 75,
        emergencyStatus: false
    },
    {
        id: 'MH12-CD-5678',
        routeId: 2,
        route: 'Route 2: Hadapsar to Pimpri',
        lat: 18.5204,
        lng: 73.8567,
        speed: 28,
        bearing: 90,
        nextStop: 'Pune Station',
        nextStopId: 4,
        eta: 8,
        passengers: 38,
        capacity: 60,
        status: 'active',
        driver: {
            name: 'Amit Sharma',
            id: 'D002',
            phone: '+91-9876543211',
            license: 'MH12-DL-002'
        },
        busType: 'Non-AC',
        fare: 10,
        lastUpdated: new Date(),
        delay: -1,
        fuelLevel: 60,
        emergencyStatus: false
    },
    {
        id: 'MH12-EF-9012',
        routeId: 3,
        route: 'Route 3: Kothrud to Viman Nagar',
        lat: 18.5362,
        lng: 73.8421,
        speed: 32,
        bearing: 180,
        nextStop: 'Deccan',
        nextStopId: 6,
        eta: 3,
        passengers: 55,
        capacity: 60,
        status: 'active',
        driver: {
            name: 'Priya Patel',
            id: 'D003',
            phone: '+91-9876543212',
            license: 'MH12-DL-003'
        },
        busType: 'Electric',
        fare: 12,
        lastUpdated: new Date(),
        delay: 0,
        fuelLevel: 85,
        emergencyStatus: false
    }
];

// Sample routes data
let routes = [
    {
        id: 1,
        name: 'Route 1: Katraj to Shivajinagar',
        routeNumber: '1A',
        stops: [
            { id: 1, name: 'Katraj', lat: 18.4575, lng: 73.8677, fare: 0, estimatedTime: 0 },
            { id: 2, name: 'Market Yard', lat: 18.4989, lng: 73.8543, fare: 5, estimatedTime: 8 },
            { id: 3, name: 'Swargate', lat: 18.5074, lng: 73.8077, fare: 10, estimatedTime: 15 },
            { id: 4, name: 'Pune Station', lat: 18.5204, lng: 73.8567, fare: 12, estimatedTime: 22 },
            { id: 5, name: 'Shivajinagar', lat: 18.5308, lng: 73.8474, fare: 15, estimatedTime: 30 }
        ],
        color: '#10b981',
        frequency: 15,
        operatingHours: { start: '05:30', end: '23:00' },
        distance: 18.5,
        avgTravelTime: 35,
        busTypes: ['AC', 'Non-AC'],
        operator: 'PMPML'
    },
    {
        id: 2,
        name: 'Route 2: Hadapsar to Pimpri',
        routeNumber: '2B',
        stops: [
            { id: 6, name: 'Hadapsar', lat: 18.5018, lng: 73.9200, fare: 0, estimatedTime: 0 },
            { id: 7, name: 'Koregaon Park', lat: 18.5362, lng: 73.8941, fare: 8, estimatedTime: 12 },
            { id: 8, name: 'Pune Station', lat: 18.5204, lng: 73.8567, fare: 10, estimatedTime: 20 },
            { id: 9, name: 'Pimpri', lat: 18.5433, lng: 73.8097, fare: 15, estimatedTime: 35 }
        ],
        color: '#3b82f6',
        frequency: 20,
        operatingHours: { start: '06:00', end: '22:30' },
        distance: 22.3,
        avgTravelTime: 40,
        busTypes: ['Non-AC', 'Electric'],
        operator: 'PMPML'
    },
    {
        id: 3,
        name: 'Route 3: Kothrud to Viman Nagar',
        routeNumber: '3C',
        stops: [
            { id: 10, name: 'Kothrud', lat: 18.5074, lng: 73.8077, fare: 0, estimatedTime: 0 },
            { id: 11, name: 'Deccan', lat: 18.5204, lng: 73.8421, fare: 6, estimatedTime: 10 },
            { id: 12, name: 'FC Road', lat: 18.5362, lng: 73.8567, fare: 10, estimatedTime: 18 },
            { id: 13, name: 'Viman Nagar', lat: 18.5602, lng: 73.9087, fare: 12, estimatedTime: 28 }
        ],
        color: '#f59e0b',
        frequency: 12,
        operatingHours: { start: '05:45', end: '23:30' },
        distance: 16.8,
        avgTravelTime: 32,
        busTypes: ['AC', 'Electric'],
        operator: 'PMPML'
    }
];

// API Routes
app.get('/api/buses', (req, res) => {
    let filteredBuses = [...buses];
    
    if (req.query.status) {
        filteredBuses = filteredBuses.filter(bus => bus.status === req.query.status);
    }
    
    if (req.query.routeId) {
        filteredBuses = filteredBuses.filter(bus => bus.routeId === parseInt(req.query.routeId));
    }
    
    res.json({
        success: true,
        data: filteredBuses,
        count: filteredBuses.length,
        total: buses.length
    });
});

app.get('/api/buses/:id', (req, res) => {
    const bus = buses.find(b => b.id === req.params.id);
    if (!bus) {
        return res.status(404).json({ success: false, message: 'Bus not found' });
    }
    res.json({ success: true, data: bus });
});

app.get('/api/routes', (req, res) => {
    const routesWithStats = routes.map(route => {
        const routeBuses = buses.filter(bus => bus.routeId === route.id);
        return {
            ...route,
            activeBuses: routeBuses.filter(bus => bus.status === 'active').length,
            totalBuses: routeBuses.length,
            avgOccupancy: routeBuses.length > 0 
                ? (routeBuses.reduce((sum, bus) => sum + (bus.passengers / bus.capacity), 0) / routeBuses.length * 100).toFixed(1)
                : 0
        };
    });
    
    res.json({
        success: true,
        data: routesWithStats,
        count: routesWithStats.length
    });
});

app.get('/api/routes/:id', (req, res) => {
    const route = routes.find(r => r.id === parseInt(req.params.id));
    if (!route) {
        return res.status(404).json({ success: false, message: 'Route not found' });
    }
    res.json({ success: true, data: route });
});

app.get('/api/drivers', (req, res) => {
    const drivers = buses.map(bus => ({
        ...bus.driver,
        busId: bus.id,
        busStatus: bus.status,
        currentRoute: bus.route,
        lastUpdated: bus.lastUpdated
    }));
    
    res.json({
        success: true,
        data: drivers,
        count: drivers.length
    });
});

app.get('/api/stops', (req, res) => {
    const allStops = [];
    routes.forEach(route => {
        route.stops.forEach(stop => {
            allStops.push({
                ...stop,
                routeId: route.id,
                routeName: route.name,
                routeNumber: route.routeNumber
            });
        });
    });
    
    res.json({
        success: true,
        data: allStops,
        count: allStops.length
    });
});

app.get('/api/stops/:stopId/eta', (req, res) => {
    const stopId = parseInt(req.params.stopId);
    const busesAtStop = buses.filter(bus => bus.nextStopId === stopId);
    
    const etaData = busesAtStop.map(bus => ({
        busId: bus.id,
        routeNumber: routes.find(r => r.id === bus.routeId)?.routeNumber,
        eta: bus.eta,
        delay: bus.delay,
        passengers: bus.passengers,
        capacity: bus.capacity,
        busType: bus.busType
    }));
    
    res.json({
        success: true,
        stopId: stopId,
        data: etaData,
        count: etaData.length
    });
});

app.post('/api/buses', (req, res) => {
    const { id, routeId, busType, capacity, driverName, driverPhone } = req.body;
    
    if (!id || !routeId || !busType || !capacity || !driverName) {
        return res.status(400).json({
            success: false,
            message: 'Missing required fields: id, routeId, busType, capacity, driverName'
        });
    }
    
    if (buses.find(bus => bus.id === id)) {
        return res.status(400).json({
            success: false,
            message: 'Bus ID already exists'
        });
    }
    
    const route = routes.find(r => r.id === parseInt(routeId));
    if (!route) {
        return res.status(400).json({
            success: false,
            message: 'Route not found'
        });
    }
    
    const newBus = {
        id,
        routeId: parseInt(routeId),
        route: route.name,
        lat: route.stops[0].lat,
        lng: route.stops[0].lng,
        speed: 0,
        bearing: 0,
        nextStop: route.stops[1]?.name || route.stops[0].name,
        nextStopId: route.stops[1]?.id || route.stops[0].id,
        eta: 0,
        passengers: 0,
        capacity: parseInt(capacity),
        status: 'inactive',
        driver: {
            name: driverName,
            id: `D${String(busIdCounter++).padStart(3, '0')}`,
            phone: driverPhone || '+91-0000000000',
            license: `MH12-DL-${String(busIdCounter).padStart(3, '0')}`
        },
        busType,
        fare: busType === 'AC' ? 15 : busType === 'Electric' ? 12 : 10,
        lastUpdated: new Date(),
        delay: 0,
        fuelLevel: 100,
        emergencyStatus: false
    };
    
    buses.push(newBus);
    
    res.status(201).json({
        success: true,
        message: 'Bus created successfully',
        data: newBus
    });
});

app.delete('/api/buses/:id', (req, res) => {
    const busId = req.params.id;
    const busIndex = buses.findIndex(bus => bus.id === busId);
    
    if (busIndex === -1) {
        return res.status(404).json({
            success: false,
            message: 'Bus not found'
        });
    }
    
    const deletedBus = buses.splice(busIndex, 1)[0];
    
    res.json({
        success: true,
        message: 'Bus deleted successfully',
        data: deletedBus
    });
});

app.post('/api/routes', (req, res) => {
    const { name, routeNumber, operator } = req.body;
    
    if (!name || !routeNumber) {
        return res.status(400).json({
            success: false,
            message: 'Missing required fields: name, routeNumber'
        });
    }
    
    if (routes.find(route => route.routeNumber === routeNumber)) {
        return res.status(400).json({
            success: false,
            message: 'Route number already exists'
        });
    }
    
    const newRoute = {
        id: routeIdCounter++,
        name,
        routeNumber,
        stops: [
            { id: 100 + routeIdCounter, name: 'Start Point', lat: 18.5204, lng: 73.8567, fare: 0, estimatedTime: 0 },
            { id: 101 + routeIdCounter, name: 'End Point', lat: 18.5304, lng: 73.8667, fare: 10, estimatedTime: 20 }
        ],
        color: `#${Math.floor(Math.random()*16777215).toString(16)}`,
        frequency: 15,
        operatingHours: { start: '06:00', end: '22:00' },
        distance: 10,
        avgTravelTime: 25,
        busTypes: ['Non-AC'],
        operator: operator || 'PMPML'
    };
    
    routes.push(newRoute);
    
    res.status(201).json({
        success: true,
        message: 'Route created successfully',
        data: newRoute
    });
});

app.delete('/api/routes/:id', (req, res) => {
    const routeId = parseInt(req.params.id);
    const routeIndex = routes.findIndex(route => route.id === routeId);
    
    if (routeIndex === -1) {
        return res.status(404).json({
            success: false,
            message: 'Route not found'
        });
    }
    
    const routeBuses = buses.filter(bus => bus.routeId === routeId);
    if (routeBuses.length > 0) {
        return res.status(400).json({
            success: false,
            message: `Cannot delete route. ${routeBuses.length} buses are assigned to this route.`
        });
    }
    
    const deletedRoute = routes.splice(routeIndex, 1)[0];
    
    res.json({
        success: true,
        message: 'Route deleted successfully',
        data: deletedRoute
    });
});

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({
        status: 'healthy',
        timestamp: new Date().toISOString(),
        uptime: process.uptime(),
        services: {
            api: 'active',
            websocket: 'active'
        }
    });
});

// Root endpoint
app.get('/', (req, res) => {
    res.json({
        name: 'SmartBus Tracker API',
        version: '1.0.0',
        description: 'Real-time bus tracking system for Smart India Hackathon',
        endpoints: {
            health: '/health',
            api: {
                buses: '/api/buses',
                'bus by id': '/api/buses/:id',
                routes: '/api/routes',
                'route by id': '/api/routes/:id',
                drivers: '/api/drivers',
                stops: '/api/stops',
                'stop eta': '/api/stops/:id/eta'
            },
            websocket: `ws://localhost:3000`
        }
    });
});

// WebSocket handling
io.on('connection', (socket) => {
    console.log('📱 Client connected:', socket.id);
    
    socket.emit('bus_data', buses);
    
    socket.on('subscribe_bus', (busId) => {
        socket.join(`bus_${busId}`);
        console.log(`Client ${socket.id} subscribed to bus ${busId}`);
    });
    
    socket.on('disconnect', () => {
        console.log('📱 Client disconnected:', socket.id);
    });
});

// Error handling middleware
app.use((err, req, res, next) => {
    console.error('❌ Error:', err.stack);
    res.status(err.status || 500).json({
        error: {
            message: err.message || 'Internal Server Error',
            status: err.status || 500
        }
    });
});

// 404 handler
app.use((req, res) => {
    res.status(404).json({
        error: {
            message: 'Endpoint not found',
            status: 404,
            availableEndpoints: [
                '/health',
                '/api/buses',
                '/api/routes',
                '/api/drivers',
                '/api/stops'
            ]
        }
    });
});

// Start the server
const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
    console.log(`
╔════════════════════════════════════════╗
║     🚌 SmartBus Tracker Backend        ║
║     ✅ Server running on port ${PORT}        ║
║     🌐 API: http://localhost:${PORT}/api     ║
║     📡 WebSocket: ws://localhost:${PORT}     ║
║     📊 Health: http://localhost:${PORT}/health ║
╚════════════════════════════════════════╝
    `);
    
    // Simulate bus movement every 5 seconds
    setInterval(() => {
        buses.forEach((bus, index) => {
            // Simulate realistic movement
            const movement = 0.0005;
            const angle = (Date.now() / 1000 + index * 60) * 0.05;
            
            bus.lat += Math.sin(angle) * movement;
            bus.lng += Math.cos(angle) * movement;
            
            // Update speed randomly
            bus.speed = Math.floor(15 + Math.random() * 40);
            
            // Update ETA
            bus.eta = Math.max(1, bus.eta - 0.2 + Math.random() * 0.4);
            if (bus.eta < 1) bus.eta = Math.floor(Math.random() * 15) + 5;
            
            // Update passengers randomly
            if (Math.random() > 0.9) {
                const change = Math.floor(Math.random() * 10 - 5);
                bus.passengers = Math.min(bus.capacity, Math.max(5, bus.passengers + change));
            }
            
            bus.lastUpdated = new Date();
        });
        
        // Broadcast updates to all connected clients
        io.emit('bus_location_update', buses);
    }, 5000);
    
    console.log('🚌 Real-time bus simulation started');
    console.log('📡 WebSocket server ready for connections');
    console.log('✅ SmartBus Tracker Backend is fully operational!');
    console.log('');
    console.log('🔗 Test the API:');
    console.log(`   • http://localhost:${PORT}/health`);
    console.log(`   • http://localhost:${PORT}/api/buses`);
    console.log(`   • http://localhost:${PORT}/api/routes`);
    console.log('');
});