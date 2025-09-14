const mqtt = require('mqtt');
const logger = require('../utils/logger');
const { updateBusLocation } = require('./locationService');
const { calculateETA } = require('./etaService');
const { redisClient } = require('../config/redis');

let mqttClient;
let io;

// MQTT broker configuration
const MQTT_BROKER_URL = process.env.MQTT_BROKER_URL || 'mqtt://localhost:1883';
const MQTT_OPTIONS = {
    clientId: `smartbus_backend_${Date.now()}`,
    username: process.env.MQTT_USERNAME,
    password: process.env.MQTT_PASSWORD,
    clean: true,
    connectTimeout: 4000,
    reconnectPeriod: 1000,
};

// Topics
const TOPICS = {
    BUS_LOCATION: 'bus/+/location',  // bus/{busId}/location
    BUS_STATUS: 'bus/+/status',      // bus/{busId}/status
    DRIVER_APP: 'driver/+/update',   // driver/{driverId}/update
    IOT_DEVICE: 'iot/+/gps',        // iot/{deviceId}/gps
    ALERTS: 'alerts/+',
    EMERGENCY: 'emergency/+',
};

function initMQTT(socketIo) {
    return new Promise((resolve, reject) => {
        io = socketIo;
        
        // Connect to MQTT broker
        mqttClient = mqtt.connect(MQTT_BROKER_URL, MQTT_OPTIONS);
        
        mqttClient.on('connect', () => {
            logger.info('Connected to MQTT broker');
            
            // Subscribe to topics
            Object.values(TOPICS).forEach(topic => {
                mqttClient.subscribe(topic, (err) => {
                    if (err) {
                        logger.error(`Failed to subscribe to ${topic}:`, err);
                    } else {
                        logger.info(`Subscribed to MQTT topic: ${topic}`);
                    }
                });
            });
            
            resolve(mqttClient);
        });
        
        mqttClient.on('message', handleMQTTMessage);
        
        mqttClient.on('error', (error) => {
            logger.error('MQTT error:', error);
            reject(error);
        });
        
        mqttClient.on('offline', () => {
            logger.warn('MQTT client offline');
        });
        
        mqttClient.on('reconnect', () => {
            logger.info('MQTT client reconnecting...');
        });
    });
}

async function handleMQTTMessage(topic, message) {
    try {
        const data = JSON.parse(message.toString());
        const topicParts = topic.split('/');
        
        switch (topicParts[0]) {
            case 'bus':
                await handleBusUpdate(topicParts[1], topicParts[2], data);
                break;
            case 'driver':
                await handleDriverUpdate(topicParts[1], data);
                break;
            case 'iot':
                await handleIoTUpdate(topicParts[1], data);
                break;
            case 'alerts':
                await handleAlert(topicParts[1], data);
                break;
            case 'emergency':
                await handleEmergency(topicParts[1], data);
                break;
            default:
                logger.warn(`Unknown topic: ${topic}`);
        }
    } catch (error) {
        logger.error(`Error handling MQTT message on topic ${topic}:`, error);
    }
}

async function handleBusUpdate(busId, updateType, data) {
    if (updateType === 'location') {
        // Validate GPS data
        if (!isValidGPSData(data)) {
            logger.warn(`Invalid GPS data for bus ${busId}`);
            return;
        }
        
        // Update location in Redis for fast access
        const locationKey = `bus:${busId}:location`;
        await redisClient.setex(locationKey, 300, JSON.stringify({
            latitude: data.latitude,
            longitude: data.longitude,
            speed: data.speed || 0,
            bearing: data.bearing || 0,
            timestamp: data.timestamp || new Date().toISOString(),
            accuracy: data.accuracy || 10,
        }));
        
        // Update in database
        await updateBusLocation(busId, data);
        
        // Calculate ETA for upcoming stops
        const etaData = await calculateETA(busId, data.latitude, data.longitude);
        
        // Broadcast to connected clients via WebSocket
        io.to(`bus_${busId}`).emit('bus_location_update', {
            busId,
            latitude: data.latitude,
            longitude: data.longitude,
            speed: data.speed,
            bearing: data.bearing,
            eta: etaData,
            timestamp: data.timestamp,
        });
        
        // Broadcast to route subscribers
        const busInfo = await getBusInfo(busId);
        if (busInfo && busInfo.routeId) {
            io.to(`route_${busInfo.routeId}`).emit('route_bus_update', {
                busId,
                routeId: busInfo.routeId,
                location: {
                    latitude: data.latitude,
                    longitude: data.longitude,
                },
                eta: etaData,
            });
        }
        
        // Check for arrival notifications
        await checkArrivalNotifications(busId, data.latitude, data.longitude);
        
    } else if (updateType === 'status') {
        // Handle status updates (active, inactive, breakdown, etc.)
        await updateBusStatus(busId, data);
        
        io.to(`bus_${busId}`).emit('bus_status_update', {
            busId,
            status: data.status,
            message: data.message,
            timestamp: data.timestamp,
        });
    }
}

async function handleDriverUpdate(driverId, data) {
    // Handle updates from driver mobile app
    logger.info(`Driver update from ${driverId}:`, data);
    
    if (data.busId && data.location) {
        await handleBusUpdate(data.busId, 'location', data.location);
    }
    
    if (data.status) {
        // Update driver status (on duty, break, off duty)
        await updateDriverStatus(driverId, data.status);
    }
    
    if (data.emergency) {
        await handleEmergency(driverId, data.emergency);
    }
}

async function handleIoTUpdate(deviceId, data) {
    // Handle updates from IoT GPS devices
    logger.info(`IoT GPS update from device ${deviceId}:`, data);
    
    // Get bus associated with this device
    const busId = await getBusByDeviceId(deviceId);
    
    if (busId) {
        await handleBusUpdate(busId, 'location', {
            latitude: data.lat,
            longitude: data.lng,
            speed: data.speed,
            bearing: data.bearing,
            timestamp: data.timestamp,
            accuracy: data.accuracy,
        });
    } else {
        logger.warn(`No bus found for IoT device ${deviceId}`);
    }
}

async function handleAlert(alertType, data) {
    logger.warn(`Alert received - Type: ${alertType}`, data);
    
    // Broadcast alert to admin dashboard
    io.to('admin').emit('system_alert', {
        type: alertType,
        data,
        timestamp: new Date().toISOString(),
    });
    
    // Store alert in database
    await storeAlert(alertType, data);
}

async function handleEmergency(source, data) {
    logger.error(`EMERGENCY from ${source}:`, data);
    
    // Immediate broadcast to all admin users
    io.to('admin').emit('emergency_alert', {
        source,
        data,
        timestamp: new Date().toISOString(),
        priority: 'HIGH',
    });
    
    // Send SMS/Email notifications to authorities
    await sendEmergencyNotifications(source, data);
    
    // Store in database with high priority
    await storeEmergency(source, data);
}

function isValidGPSData(data) {
    return (
        data &&
        typeof data.latitude === 'number' &&
        typeof data.longitude === 'number' &&
        data.latitude >= -90 && data.latitude <= 90 &&
        data.longitude >= -180 && data.longitude <= 180
    );
}

async function checkArrivalNotifications(busId, lat, lng) {
    // Check if bus is approaching any stops where users are waiting
    const upcomingStops = await getUpcomingStops(busId);
    
    for (const stop of upcomingStops) {
        const distance = calculateDistance(lat, lng, stop.latitude, stop.longitude);
        
        // If bus is within 500 meters of a stop
        if (distance <= 500) {
            // Get users waiting at this stop
            const waitingUsers = await getWaitingUsers(stop.id, busId);
            
            for (const userId of waitingUsers) {
                io.to(`user_${userId}`).emit('bus_arrival_notification', {
                    busId,
                    stopId: stop.id,
                    stopName: stop.name,
                    distance,
                    eta: Math.ceil(distance / 250), // Rough ETA in minutes
                    message: `Bus is arriving at ${stop.name} in approximately ${Math.ceil(distance / 250)} minutes`,
                });
            }
        }
    }
}

function publishLocationUpdate(busId, location) {
    if (mqttClient && mqttClient.connected) {
        mqttClient.publish(
            `bus/${busId}/location/processed`,
            JSON.stringify(location),
            { qos: 1 }
        );
    }
}

// Helper functions (implementations would connect to actual services/databases)
async function updateBusLocation(busId, data) {
    // Implementation to update bus location in PostgreSQL
}

async function updateBusStatus(busId, data) {
    // Implementation to update bus status
}

async function updateDriverStatus(driverId, status) {
    // Implementation to update driver status
}

async function getBusByDeviceId(deviceId) {
    // Implementation to get bus ID by IoT device ID
    return null;
}

async function getBusInfo(busId) {
    // Implementation to get bus information
    return null;
}

async function getUpcomingStops(busId) {
    // Implementation to get upcoming stops for a bus
    return [];
}

async function getWaitingUsers(stopId, busId) {
    // Implementation to get users waiting at a stop for a specific bus
    return [];
}

async function storeAlert(type, data) {
    // Implementation to store alert in database
}

async function storeEmergency(source, data) {
    // Implementation to store emergency in database
}

async function sendEmergencyNotifications(source, data) {
    // Implementation to send SMS/Email for emergencies
}

function calculateDistance(lat1, lng1, lat2, lng2) {
    // Haversine formula to calculate distance between two points
    const R = 6371e3; // Earth's radius in meters
    const φ1 = lat1 * Math.PI / 180;
    const φ2 = lat2 * Math.PI / 180;
    const Δφ = (lat2 - lat1) * Math.PI / 180;
    const Δλ = (lng2 - lng1) * Math.PI / 180;
    
    const a = Math.sin(Δφ/2) * Math.sin(Δφ/2) +
              Math.cos(φ1) * Math.cos(φ2) *
              Math.sin(Δλ/2) * Math.sin(Δλ/2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
    
    return R * c; // Distance in meters
}

module.exports = {
    initMQTT,
    publishLocationUpdate,
    mqttClient,
};
