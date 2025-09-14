require('dotenv').config();
const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');

// Import custom modules
const { connectPostgreSQL } = require('./config/postgres');
const { connectRedis } = require('./config/redis');
const { connectMongoDB } = require('./config/mongodb');
const { initMQTT } = require('./services/mqttService');
const { initSocketHandlers } = require('./services/socketHandlers');
const logger = require('./utils/logger');
const { startCronJobs } = require('./jobs/cronJobs');

// Import routes
const busRoutes = require('./routes/busRoutes');
const routeRoutes = require('./routes/routeRoutes');
const stopRoutes = require('./routes/stopRoutes');
const adminRoutes = require('./routes/adminRoutes');
const authRoutes = require('./routes/authRoutes');
const trackingRoutes = require('./routes/trackingRoutes');

// Initialize Express app
const app = express();
const server = http.createServer(app);

// Initialize Socket.io with CORS
const io = socketIo(server, {
    cors: {
        origin: process.env.CLIENT_URL || '*',
        methods: ['GET', 'POST'],
        credentials: true
    },
    transports: ['websocket', 'polling']
});

// Make io accessible throughout the app
app.set('io', io);

// Middleware
app.use(helmet());
app.use(compression());
app.use(cors({
    origin: process.env.CLIENT_URL || '*',
    credentials: true
}));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(morgan('combined', { stream: { write: message => logger.info(message) } }));

// Rate limiting
const limiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100, // limit each IP to 100 requests per windowMs
    message: 'Too many requests from this IP, please try again later.'
});
app.use('/api/', limiter);

// API Routes
app.use('/api/buses', busRoutes);
app.use('/api/routes', routeRoutes);
app.use('/api/stops', stopRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/auth', authRoutes);
app.use('/api/tracking', trackingRoutes);

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({
        status: 'healthy',
        timestamp: new Date().toISOString(),
        uptime: process.uptime(),
        services: {
            postgres: 'connected',
            redis: 'connected',
            mongodb: 'connected',
            mqtt: 'connected',
            websocket: 'active'
        }
    });
});

// Root endpoint
app.get('/', (req, res) => {
    res.json({
        name: 'SmartBus Tracker API',
        version: '1.0.0',
        endpoints: {
            health: '/health',
            api: {
                buses: '/api/buses',
                routes: '/api/routes',
                stops: '/api/stops',
                tracking: '/api/tracking',
                admin: '/api/admin',
                auth: '/api/auth'
            },
            websocket: 'ws://localhost:3000'
        }
    });
});

// Error handling middleware
app.use((err, req, res, next) => {
    logger.error(err.stack);
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
            status: 404
        }
    });
});

// Initialize services and start server
async function startServer() {
    try {
        // Connect to databases
        await connectPostgreSQL();
        logger.info('PostgreSQL connected');
        
        await connectRedis();
        logger.info('Redis connected');
        
        await connectMongoDB();
        logger.info('MongoDB connected');
        
        // Initialize MQTT
        await initMQTT(io);
        logger.info('MQTT broker connected');
        
        // Initialize Socket.io handlers
        initSocketHandlers(io);
        logger.info('Socket.io handlers initialized');
        
        // Start cron jobs
        startCronJobs();
        logger.info('Cron jobs started');
        
        // Start server
        const PORT = process.env.PORT || 3000;
        server.listen(PORT, () => {
            logger.info(`Server running on port ${PORT}`);
            console.log(`
╔════════════════════════════════════════╗
║     SmartBus Tracker Backend           ║
║     Server running on port ${PORT}        ║
║     WebSocket: ws://localhost:${PORT}     ║
║     API: http://localhost:${PORT}/api     ║
╚════════════════════════════════════════╝
            `);
        });
    } catch (error) {
        logger.error('Failed to start server:', error);
        process.exit(1);
    }
}

// Handle graceful shutdown
process.on('SIGTERM', async () => {
    logger.info('SIGTERM signal received: closing HTTP server');
    server.close(() => {
        logger.info('HTTP server closed');
    });
    
    // Close database connections
    // await closePostgreSQL();
    // await closeRedis();
    // await closeMongoDB();
    
    process.exit(0);
});

process.on('unhandledRejection', (reason, promise) => {
    logger.error('Unhandled Rejection at:', promise, 'reason:', reason);
});

process.on('uncaughtException', (error) => {
    logger.error('Uncaught Exception:', error);
    process.exit(1);
});

// Start the server
startServer();
