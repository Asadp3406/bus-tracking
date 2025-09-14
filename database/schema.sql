-- SmartBus Tracker PostgreSQL Database Schema
-- Version: 1.0.0
-- Created: 2024

-- Create database
CREATE DATABASE IF NOT EXISTS smartbus_tracker;
USE smartbus_tracker;

-- Enable PostGIS extension for geographical data
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- USERS AND AUTHENTICATION
-- =====================================================

CREATE TABLE users (
    user_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20) UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL DEFAULT 'commuter',
    avatar_url TEXT,
    fcm_token TEXT,
    is_active BOOLEAN DEFAULT true,
    email_verified BOOLEAN DEFAULT false,
    phone_verified BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP WITH TIME ZONE,
    CONSTRAINT valid_role CHECK (role IN ('commuter', 'driver', 'admin', 'supervisor'))
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_users_role ON users(role);

-- =====================================================
-- DRIVERS
-- =====================================================

CREATE TABLE drivers (
    driver_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID UNIQUE REFERENCES users(user_id) ON DELETE CASCADE,
    employee_id VARCHAR(50) UNIQUE NOT NULL,
    license_number VARCHAR(50) UNIQUE NOT NULL,
    license_expiry DATE NOT NULL,
    years_of_experience INTEGER DEFAULT 0,
    rating DECIMAL(3,2) DEFAULT 0.00,
    total_trips INTEGER DEFAULT 0,
    status VARCHAR(50) DEFAULT 'off_duty',
    current_bus_id UUID,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_status CHECK (status IN ('on_duty', 'off_duty', 'break', 'leave'))
);

CREATE INDEX idx_drivers_user_id ON drivers(user_id);
CREATE INDEX idx_drivers_status ON drivers(status);

-- =====================================================
-- ROUTES
-- =====================================================

CREATE TABLE routes (
    route_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    route_number VARCHAR(20) UNIQUE NOT NULL,
    route_name VARCHAR(255) NOT NULL,
    start_point VARCHAR(255) NOT NULL,
    end_point VARCHAR(255) NOT NULL,
    route_type VARCHAR(50) DEFAULT 'regular',
    total_distance DECIMAL(10,2), -- in kilometers
    estimated_duration INTEGER, -- in minutes
    fare_per_km DECIMAL(10,2) DEFAULT 2.00,
    base_fare DECIMAL(10,2) DEFAULT 10.00,
    is_active BOOLEAN DEFAULT true,
    polyline TEXT, -- Encoded polyline for the route
    color VARCHAR(7), -- Hex color for route display
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_route_type CHECK (route_type IN ('regular', 'express', 'night', 'special'))
);

CREATE INDEX idx_routes_number ON routes(route_number);
CREATE INDEX idx_routes_active ON routes(is_active);

-- =====================================================
-- STOPS
-- =====================================================

CREATE TABLE stops (
    stop_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    stop_code VARCHAR(20) UNIQUE NOT NULL,
    stop_name VARCHAR(255) NOT NULL,
    description TEXT,
    location GEOGRAPHY(POINT, 4326) NOT NULL,
    latitude DECIMAL(10,8) NOT NULL,
    longitude DECIMAL(11,8) NOT NULL,
    address TEXT,
    landmark VARCHAR(255),
    stop_type VARCHAR(50) DEFAULT 'regular',
    has_shelter BOOLEAN DEFAULT false,
    has_seating BOOLEAN DEFAULT false,
    accessibility_features TEXT[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_stop_type CHECK (stop_type IN ('regular', 'terminal', 'depot', 'interchange'))
);

CREATE INDEX idx_stops_location ON stops USING GIST(location);
CREATE INDEX idx_stops_code ON stops(stop_code);

-- =====================================================
-- ROUTE STOPS (Junction table)
-- =====================================================

CREATE TABLE route_stops (
    route_stop_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    route_id UUID REFERENCES routes(route_id) ON DELETE CASCADE,
    stop_id UUID REFERENCES stops(stop_id) ON DELETE CASCADE,
    stop_order INTEGER NOT NULL,
    distance_from_start DECIMAL(10,2), -- in kilometers
    time_from_start INTEGER, -- in minutes
    arrival_time TIME,
    departure_time TIME,
    is_major_stop BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(route_id, stop_order),
    UNIQUE(route_id, stop_id)
);

CREATE INDEX idx_route_stops_route ON route_stops(route_id);
CREATE INDEX idx_route_stops_stop ON route_stops(stop_id);

-- =====================================================
-- BUSES
-- =====================================================

CREATE TABLE buses (
    bus_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    registration_number VARCHAR(20) UNIQUE NOT NULL,
    vehicle_number VARCHAR(20) UNIQUE NOT NULL,
    model VARCHAR(100),
    manufacturer VARCHAR(100),
    year_of_manufacture INTEGER,
    capacity INTEGER NOT NULL,
    current_capacity INTEGER DEFAULT 0,
    fuel_type VARCHAR(50) DEFAULT 'diesel',
    route_id UUID REFERENCES routes(route_id) ON DELETE SET NULL,
    driver_id UUID REFERENCES drivers(driver_id) ON DELETE SET NULL,
    status VARCHAR(50) DEFAULT 'inactive',
    current_location GEOGRAPHY(POINT, 4326),
    current_latitude DECIMAL(10,8),
    current_longitude DECIMAL(11,8),
    current_speed DECIMAL(5,2) DEFAULT 0, -- km/h
    bearing DECIMAL(5,2) DEFAULT 0, -- degrees
    last_location_update TIMESTAMP WITH TIME ZONE,
    features TEXT[],
    insurance_expiry DATE,
    fitness_certificate_expiry DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_fuel CHECK (fuel_type IN ('diesel', 'petrol', 'cng', 'electric', 'hybrid')),
    CONSTRAINT valid_bus_status CHECK (status IN ('active', 'inactive', 'maintenance', 'breakdown', 'delayed'))
);

CREATE INDEX idx_buses_registration ON buses(registration_number);
CREATE INDEX idx_buses_status ON buses(status);
CREATE INDEX idx_buses_route ON buses(route_id);
CREATE INDEX idx_buses_location ON buses USING GIST(current_location);

-- =====================================================
-- TRIPS
-- =====================================================

CREATE TABLE trips (
    trip_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    bus_id UUID REFERENCES buses(bus_id) ON DELETE CASCADE,
    route_id UUID REFERENCES routes(route_id) ON DELETE CASCADE,
    driver_id UUID REFERENCES drivers(driver_id) ON DELETE SET NULL,
    trip_date DATE NOT NULL,
    scheduled_start_time TIME NOT NULL,
    scheduled_end_time TIME NOT NULL,
    actual_start_time TIMESTAMP WITH TIME ZONE,
    actual_end_time TIMESTAMP WITH TIME ZONE,
    status VARCHAR(50) DEFAULT 'scheduled',
    total_passengers INTEGER DEFAULT 0,
    total_revenue DECIMAL(10,2) DEFAULT 0,
    delay_minutes INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_trip_status CHECK (status IN ('scheduled', 'ongoing', 'completed', 'cancelled'))
);

CREATE INDEX idx_trips_bus ON trips(bus_id);
CREATE INDEX idx_trips_route ON trips(route_id);
CREATE INDEX idx_trips_date ON trips(trip_date);
CREATE INDEX idx_trips_status ON trips(status);

-- =====================================================
-- REAL-TIME TRACKING (Latest position cache)
-- =====================================================

CREATE TABLE bus_tracking (
    tracking_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    bus_id UUID REFERENCES buses(bus_id) ON DELETE CASCADE,
    trip_id UUID REFERENCES trips(trip_id) ON DELETE CASCADE,
    location GEOGRAPHY(POINT, 4326) NOT NULL,
    latitude DECIMAL(10,8) NOT NULL,
    longitude DECIMAL(11,8) NOT NULL,
    speed DECIMAL(5,2) DEFAULT 0,
    bearing DECIMAL(5,2) DEFAULT 0,
    accuracy DECIMAL(5,2),
    altitude DECIMAL(8,2),
    provider VARCHAR(50), -- gps, network, fused
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_tracking_bus ON bus_tracking(bus_id);
CREATE INDEX idx_tracking_trip ON bus_tracking(trip_id);
CREATE INDEX idx_tracking_timestamp ON bus_tracking(timestamp DESC);
CREATE INDEX idx_tracking_location ON bus_tracking USING GIST(location);

-- =====================================================
-- SCHEDULES
-- =====================================================

CREATE TABLE schedules (
    schedule_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    route_id UUID REFERENCES routes(route_id) ON DELETE CASCADE,
    bus_id UUID REFERENCES buses(bus_id) ON DELETE SET NULL,
    day_of_week INTEGER NOT NULL, -- 0=Sunday, 6=Saturday
    departure_time TIME NOT NULL,
    arrival_time TIME NOT NULL,
    is_active BOOLEAN DEFAULT true,
    effective_from DATE,
    effective_to DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_day CHECK (day_of_week BETWEEN 0 AND 6)
);

CREATE INDEX idx_schedules_route ON schedules(route_id);
CREATE INDEX idx_schedules_bus ON schedules(bus_id);
CREATE INDEX idx_schedules_day ON schedules(day_of_week);

-- =====================================================
-- FAVORITES (User's favorite routes/stops)
-- =====================================================

CREATE TABLE user_favorites (
    favorite_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(user_id) ON DELETE CASCADE,
    route_id UUID REFERENCES routes(route_id) ON DELETE CASCADE,
    stop_id UUID REFERENCES stops(stop_id) ON DELETE CASCADE,
    favorite_type VARCHAR(20) NOT NULL,
    custom_name VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_favorite CHECK (favorite_type IN ('route', 'stop')),
    CONSTRAINT unique_favorite UNIQUE(user_id, route_id, stop_id)
);

CREATE INDEX idx_favorites_user ON user_favorites(user_id);

-- =====================================================
-- NOTIFICATIONS
-- =====================================================

CREATE TABLE notifications (
    notification_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(user_id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    type VARCHAR(50) NOT NULL,
    data JSONB,
    is_read BOOLEAN DEFAULT false,
    sent_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    read_at TIMESTAMP WITH TIME ZONE,
    CONSTRAINT valid_notification_type CHECK (type IN ('arrival', 'delay', 'emergency', 'info', 'promotion'))
);

CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_notifications_read ON notifications(is_read);

-- =====================================================
-- ALERTS (System-wide alerts)
-- =====================================================

CREATE TABLE alerts (
    alert_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    alert_type VARCHAR(50) NOT NULL,
    severity VARCHAR(20) NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    affected_routes UUID[],
    affected_buses UUID[],
    location GEOGRAPHY(POINT, 4326),
    radius DECIMAL(10,2), -- affected radius in km
    is_active BOOLEAN DEFAULT true,
    created_by UUID REFERENCES users(user_id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE,
    CONSTRAINT valid_alert_type CHECK (alert_type IN ('traffic', 'accident', 'breakdown', 'weather', 'strike', 'other')),
    CONSTRAINT valid_severity CHECK (severity IN ('low', 'medium', 'high', 'critical'))
);

CREATE INDEX idx_alerts_active ON alerts(is_active);
CREATE INDEX idx_alerts_type ON alerts(alert_type);

-- =====================================================
-- REPORTS (User reports/complaints)
-- =====================================================

CREATE TABLE reports (
    report_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reporter_id UUID REFERENCES users(user_id),
    bus_id UUID REFERENCES buses(bus_id),
    trip_id UUID REFERENCES trips(trip_id),
    report_type VARCHAR(50) NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    location GEOGRAPHY(POINT, 4326),
    images TEXT[],
    status VARCHAR(50) DEFAULT 'pending',
    priority VARCHAR(20) DEFAULT 'medium',
    assigned_to UUID REFERENCES users(user_id),
    resolution TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP WITH TIME ZONE,
    CONSTRAINT valid_report_type CHECK (report_type IN ('overcrowding', 'breakdown', 'accident', 'misconduct', 'delay', 'other')),
    CONSTRAINT valid_report_status CHECK (status IN ('pending', 'investigating', 'resolved', 'closed')),
    CONSTRAINT valid_priority CHECK (priority IN ('low', 'medium', 'high', 'critical'))
);

CREATE INDEX idx_reports_status ON reports(status);
CREATE INDEX idx_reports_bus ON reports(bus_id);

-- =====================================================
-- ANALYTICS (Aggregated data for reporting)
-- =====================================================

CREATE TABLE daily_analytics (
    analytics_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    date DATE NOT NULL,
    route_id UUID REFERENCES routes(route_id),
    bus_id UUID REFERENCES buses(bus_id),
    total_trips INTEGER DEFAULT 0,
    total_passengers INTEGER DEFAULT 0,
    total_revenue DECIMAL(10,2) DEFAULT 0,
    average_delay_minutes DECIMAL(5,2) DEFAULT 0,
    average_speed DECIMAL(5,2) DEFAULT 0,
    total_distance DECIMAL(10,2) DEFAULT 0,
    fuel_consumed DECIMAL(10,2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(date, route_id, bus_id)
);

CREATE INDEX idx_analytics_date ON daily_analytics(date);
CREATE INDEX idx_analytics_route ON daily_analytics(route_id);

-- =====================================================
-- FUNCTIONS AND TRIGGERS
-- =====================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply update trigger to all relevant tables
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_buses_updated_at BEFORE UPDATE ON buses
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_routes_updated_at BEFORE UPDATE ON routes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_stops_updated_at BEFORE UPDATE ON stops
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_trips_updated_at BEFORE UPDATE ON trips
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to calculate distance between two points
CREATE OR REPLACE FUNCTION calculate_distance(
    lat1 DECIMAL, lon1 DECIMAL, 
    lat2 DECIMAL, lon2 DECIMAL
)
RETURNS DECIMAL AS $$
BEGIN
    RETURN ST_Distance(
        ST_MakePoint(lon1, lat1)::geography,
        ST_MakePoint(lon2, lat2)::geography
    ) / 1000; -- Return in kilometers
END;
$$ LANGUAGE plpgsql;

-- Function to get nearby buses
CREATE OR REPLACE FUNCTION get_nearby_buses(
    user_lat DECIMAL, 
    user_lon DECIMAL, 
    radius_km DECIMAL DEFAULT 5
)
RETURNS TABLE(
    bus_id UUID,
    registration_number VARCHAR,
    distance_km DECIMAL,
    route_name VARCHAR,
    current_capacity INTEGER,
    max_capacity INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        b.bus_id,
        b.registration_number,
        ROUND(ST_Distance(
            ST_MakePoint(user_lon, user_lat)::geography,
            b.current_location
        ) / 1000, 2) AS distance_km,
        r.route_name,
        b.current_capacity,
        b.capacity
    FROM buses b
    LEFT JOIN routes r ON b.route_id = r.route_id
    WHERE b.status = 'active'
    AND ST_DWithin(
        ST_MakePoint(user_lon, user_lat)::geography,
        b.current_location,
        radius_km * 1000
    )
    ORDER BY distance_km;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- INITIAL DATA
-- =====================================================

-- Insert default admin user
INSERT INTO users (email, phone, password_hash, full_name, role) 
VALUES ('admin@smartbus.com', '+911234567890', '$2a$10$YourHashedPasswordHere', 'System Admin', 'admin');

-- Insert sample stops
INSERT INTO stops (stop_code, stop_name, latitude, longitude, location, stop_type) VALUES
('ST001', 'Central Bus Station', 18.5204, 73.8567, ST_MakePoint(73.8567, 18.5204)::geography, 'terminal'),
('ST002', 'City Mall', 18.5304, 73.8467, ST_MakePoint(73.8467, 18.5304)::geography, 'regular'),
('ST003', 'Tech Park', 18.5404, 73.8367, ST_MakePoint(73.8367, 18.5404)::geography, 'regular');

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================

CREATE INDEX idx_bus_tracking_recent ON bus_tracking(bus_id, timestamp DESC);
CREATE INDEX idx_trips_current ON trips(status, trip_date) WHERE status IN ('scheduled', 'ongoing');
CREATE INDEX idx_notifications_unread ON notifications(user_id, is_read) WHERE is_read = false;
