const express = require('express');
const router = express.Router();
const { body, param, query, validationResult } = require('express-validator');
const busController = require('../controllers/busController');
const { authenticate, authorize } = require('../middleware/auth');
const { cache } = require('../middleware/cache');

// Validation middleware
const validateRequest = (req, res, next) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
    }
    next();
};

// GET /api/buses - Get all buses
router.get('/', 
    [
        query('page').optional().isInt({ min: 1 }),
        query('limit').optional().isInt({ min: 1, max: 100 }),
        query('routeId').optional().isString(),
        query('status').optional().isIn(['active', 'inactive', 'maintenance', 'delayed']),
    ],
    validateRequest,
    cache(60), // Cache for 60 seconds
    busController.getAllBuses
);

// GET /api/buses/nearby - Get nearby buses
router.get('/nearby',
    [
        query('lat').isFloat({ min: -90, max: 90 }),
        query('lng').isFloat({ min: -180, max: 180 }),
        query('radius').optional().isFloat({ min: 0.1, max: 50 }), // radius in km
    ],
    validateRequest,
    cache(10), // Cache for 10 seconds
    busController.getNearbyBuses
);

// GET /api/buses/:id - Get specific bus details
router.get('/:id',
    [
        param('id').isString().notEmpty(),
    ],
    validateRequest,
    cache(30),
    busController.getBusById
);

// GET /api/buses/:id/location - Get real-time bus location
router.get('/:id/location',
    [
        param('id').isString().notEmpty(),
    ],
    validateRequest,
    busController.getBusLocation
);

// GET /api/buses/:id/route - Get bus route details
router.get('/:id/route',
    [
        param('id').isString().notEmpty(),
    ],
    validateRequest,
    cache(300), // Cache for 5 minutes
    busController.getBusRoute
);

// GET /api/buses/:id/stops - Get upcoming stops for a bus
router.get('/:id/stops',
    [
        param('id').isString().notEmpty(),
    ],
    validateRequest,
    cache(60),
    busController.getBusStops
);

// GET /api/buses/:id/eta/:stopId - Get ETA for a specific stop
router.get('/:id/eta/:stopId',
    [
        param('id').isString().notEmpty(),
        param('stopId').isString().notEmpty(),
    ],
    validateRequest,
    busController.getBusETA
);

// GET /api/buses/:id/history - Get bus location history
router.get('/:id/history',
    [
        param('id').isString().notEmpty(),
        query('from').optional().isISO8601(),
        query('to').optional().isISO8601(),
        query('limit').optional().isInt({ min: 1, max: 1000 }),
    ],
    validateRequest,
    authenticate,
    busController.getBusHistory
);

// POST /api/buses - Create a new bus (Admin only)
router.post('/',
    authenticate,
    authorize('admin'),
    [
        body('registrationNumber').isString().notEmpty(),
        body('routeId').isString().notEmpty(),
        body('capacity').isInt({ min: 1 }),
        body('model').optional().isString(),
        body('year').optional().isInt({ min: 1990, max: new Date().getFullYear() }),
        body('features').optional().isArray(),
    ],
    validateRequest,
    busController.createBus
);

// PUT /api/buses/:id - Update bus details (Admin only)
router.put('/:id',
    authenticate,
    authorize('admin'),
    [
        param('id').isString().notEmpty(),
        body('registrationNumber').optional().isString(),
        body('routeId').optional().isString(),
        body('status').optional().isIn(['active', 'inactive', 'maintenance', 'delayed']),
        body('capacity').optional().isInt({ min: 1 }),
    ],
    validateRequest,
    busController.updateBus
);

// PUT /api/buses/:id/assign-driver - Assign driver to bus (Admin only)
router.put('/:id/assign-driver',
    authenticate,
    authorize('admin'),
    [
        param('id').isString().notEmpty(),
        body('driverId').isString().notEmpty(),
    ],
    validateRequest,
    busController.assignDriver
);

// PUT /api/buses/:id/status - Update bus status (Admin/Driver)
router.put('/:id/status',
    authenticate,
    authorize(['admin', 'driver']),
    [
        param('id').isString().notEmpty(),
        body('status').isIn(['active', 'inactive', 'maintenance', 'delayed', 'breakdown']),
        body('message').optional().isString(),
    ],
    validateRequest,
    busController.updateBusStatus
);

// DELETE /api/buses/:id - Delete bus (Admin only)
router.delete('/:id',
    authenticate,
    authorize('admin'),
    [
        param('id').isString().notEmpty(),
    ],
    validateRequest,
    busController.deleteBus
);

// POST /api/buses/:id/report - Report an issue with the bus
router.post('/:id/report',
    [
        param('id').isString().notEmpty(),
        body('type').isIn(['overcrowding', 'breakdown', 'accident', 'delay', 'other']),
        body('description').isString().notEmpty(),
        body('location').optional().isObject(),
        body('reporterContact').optional().isString(),
    ],
    validateRequest,
    busController.reportIssue
);

// WebSocket endpoints (documented here but handled in socketHandlers)
// WS /buses/:id/track - Subscribe to real-time bus tracking
// WS /buses/:id/untrack - Unsubscribe from bus tracking

module.exports = router;
