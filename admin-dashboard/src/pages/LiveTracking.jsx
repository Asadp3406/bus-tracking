import React, { useState, useEffect, useRef, useCallback } from 'react';
import Map, { Marker, Source, Layer, NavigationControl, GeolocateControl } from 'react-map-gl';
import { motion } from 'framer-motion';
import { 
  MagnifyingGlassIcon, 
  MapPinIcon, 
  TruckIcon,
  ClockIcon,
  UsersIcon,
  ExclamationTriangleIcon,
  ArrowPathIcon,
  FunnelIcon,
  ChevronRightIcon
} from '@heroicons/react/24/outline';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import toast from 'react-hot-toast';
import { format } from 'date-fns';

// Services
import { getBuses, getBusLocation } from '../services/busService';
import { getRoutes } from '../services/routeService';
import { subscribeToLiveUpdates } from '../services/socketService';

// Components
import BusMarker from '../components/map/BusMarker';
import RouteLayer from '../components/map/RouteLayer';
import StopMarker from '../components/map/StopMarker';
import BusInfoPanel from '../components/BusInfoPanel';
import FilterPanel from '../components/FilterPanel';

const MAPBOX_TOKEN = import.meta.env.VITE_MAPBOX_TOKEN || 'your-mapbox-token';

function LiveTracking() {
  const mapRef = useRef();
  const queryClient = useQueryClient();
  
  // State
  const [viewport, setViewport] = useState({
    latitude: 18.5204,
    longitude: 73.8567,
    zoom: 12,
  });
  const [selectedBus, setSelectedBus] = useState(null);
  const [selectedRoute, setSelectedRoute] = useState(null);
  const [showFilters, setShowFilters] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [busLocations, setBusLocations] = useState({});
  const [filters, setFilters] = useState({
    status: 'all',
    route: 'all',
    speed: 'all',
  });

  // Fetch buses
  const { data: buses, isLoading: busesLoading } = useQuery({
    queryKey: ['buses', filters],
    queryFn: () => getBuses(filters),
    refetchInterval: 10000, // Refetch every 10 seconds
  });

  // Fetch routes
  const { data: routes } = useQuery({
    queryKey: ['routes'],
    queryFn: getRoutes,
  });

  // Subscribe to real-time updates
  useEffect(() => {
    const unsubscribe = subscribeToLiveUpdates((update) => {
      if (update.type === 'bus_location') {
        setBusLocations(prev => ({
          ...prev,
          [update.busId]: {
            latitude: update.latitude,
            longitude: update.longitude,
            speed: update.speed,
            bearing: update.bearing,
            timestamp: update.timestamp,
          }
        }));
        
        // Update selected bus info if it's the one being tracked
        if (selectedBus?.id === update.busId) {
          setSelectedBus(prev => ({
            ...prev,
            ...update,
          }));
        }
      }
    });

    return () => unsubscribe();
  }, [selectedBus]);

  // Handle bus selection
  const handleBusSelect = useCallback((bus) => {
    setSelectedBus(bus);
    
    // Fly to bus location
    mapRef.current?.flyTo({
      center: [bus.longitude, bus.latitude],
      zoom: 16,
      duration: 2000,
    });
  }, []);

  // Handle route selection
  const handleRouteSelect = useCallback((route) => {
    setSelectedRoute(route);
    setFilters(prev => ({ ...prev, route: route.id }));
  }, []);

  // Calculate statistics
  const statistics = {
    totalBuses: buses?.length || 0,
    activeBuses: buses?.filter(b => b.status === 'active').length || 0,
    delayedBuses: buses?.filter(b => b.status === 'delayed').length || 0,
    avgSpeed: buses?.reduce((acc, b) => acc + (b.speed || 0), 0) / (buses?.length || 1) || 0,
  };

  return (
    <div className="h-screen flex flex-col bg-gray-50">
      {/* Header */}
      <div className="bg-white shadow-sm border-b border-gray-200 px-6 py-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center space-x-4">
            <h1 className="text-2xl font-bold text-gray-900">Live Bus Tracking</h1>
            <div className="flex items-center space-x-2">
              <span className="flex h-3 w-3 relative">
                <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-green-400 opacity-75"></span>
                <span className="relative inline-flex rounded-full h-3 w-3 bg-green-500"></span>
              </span>
              <span className="text-sm text-gray-600">Live</span>
            </div>
          </div>
          
          {/* Search Bar */}
          <div className="flex items-center space-x-4">
            <div className="relative">
              <input
                type="text"
                placeholder="Search bus, route, or driver..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="w-96 pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
              <MagnifyingGlassIcon className="absolute left-3 top-2.5 h-5 w-5 text-gray-400" />
            </div>
            
            <button
              onClick={() => setShowFilters(!showFilters)}
              className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
            >
              <FunnelIcon className="h-5 w-5 text-gray-600" />
            </button>
            
            <button
              onClick={() => queryClient.invalidateQueries(['buses'])}
              className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
            >
              <ArrowPathIcon className="h-5 w-5 text-gray-600" />
            </button>
          </div>
        </div>
        
        {/* Statistics Bar */}
        <div className="mt-4 grid grid-cols-4 gap-4">
          <div className="bg-blue-50 rounded-lg px-4 py-3">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-blue-600 font-medium">Total Buses</p>
                <p className="text-2xl font-bold text-blue-900">{statistics.totalBuses}</p>
              </div>
              <TruckIcon className="h-8 w-8 text-blue-500" />
            </div>
          </div>
          
          <div className="bg-green-50 rounded-lg px-4 py-3">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-green-600 font-medium">Active</p>
                <p className="text-2xl font-bold text-green-900">{statistics.activeBuses}</p>
              </div>
              <div className="flex h-8 w-8 items-center justify-center">
                <span className="flex h-3 w-3">
                  <span className="animate-ping absolute inline-flex h-3 w-3 rounded-full bg-green-400 opacity-75"></span>
                  <span className="relative inline-flex rounded-full h-3 w-3 bg-green-500"></span>
                </span>
              </div>
            </div>
          </div>
          
          <div className="bg-amber-50 rounded-lg px-4 py-3">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-amber-600 font-medium">Delayed</p>
                <p className="text-2xl font-bold text-amber-900">{statistics.delayedBuses}</p>
              </div>
              <ExclamationTriangleIcon className="h-8 w-8 text-amber-500" />
            </div>
          </div>
          
          <div className="bg-purple-50 rounded-lg px-4 py-3">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-purple-600 font-medium">Avg Speed</p>
                <p className="text-2xl font-bold text-purple-900">{statistics.avgSpeed.toFixed(1)} km/h</p>
              </div>
              <ClockIcon className="h-8 w-8 text-purple-500" />
            </div>
          </div>
        </div>
      </div>
      
      {/* Main Content */}
      <div className="flex-1 flex relative">
        {/* Filter Panel */}
        {showFilters && (
          <motion.div 
            initial={{ x: -300 }}
            animate={{ x: 0 }}
            exit={{ x: -300 }}
            className="w-80 bg-white shadow-lg z-10"
          >
            <FilterPanel 
              filters={filters}
              onFilterChange={setFilters}
              routes={routes}
              onClose={() => setShowFilters(false)}
            />
          </motion.div>
        )}
        
        {/* Map Container */}
        <div className="flex-1 relative">
          <Map
            ref={mapRef}
            {...viewport}
            onMove={evt => setViewport(evt.viewState)}
            mapStyle="mapbox://styles/mapbox/light-v11"
            mapboxAccessToken={MAPBOX_TOKEN}
            style={{ width: '100%', height: '100%' }}
          >
            {/* Controls */}
            <NavigationControl position="top-right" />
            <GeolocateControl position="top-right" />
            
            {/* Route Layers */}
            {selectedRoute && (
              <RouteLayer route={selectedRoute} />
            )}
            
            {/* Bus Markers */}
            {buses?.map(bus => {
              const location = busLocations[bus.id] || {
                latitude: bus.latitude,
                longitude: bus.longitude,
              };
              
              return (
                <BusMarker
                  key={bus.id}
                  bus={{ ...bus, ...location }}
                  isSelected={selectedBus?.id === bus.id}
                  onClick={() => handleBusSelect(bus)}
                />
              );
            })}
            
            {/* Stop Markers */}
            {selectedRoute?.stops?.map(stop => (
              <StopMarker
                key={stop.id}
                stop={stop}
              />
            ))}
          </Map>
          
          {/* Bus Info Panel */}
          {selectedBus && (
            <motion.div
              initial={{ x: 400 }}
              animate={{ x: 0 }}
              exit={{ x: 400 }}
              className="absolute right-0 top-0 bottom-0 w-96 bg-white shadow-lg z-10"
            >
              <BusInfoPanel
                bus={selectedBus}
                onClose={() => setSelectedBus(null)}
                onTrack={() => handleBusSelect(selectedBus)}
              />
            </motion.div>
          )}
          
          {/* Active Buses List */}
          <motion.div
            initial={{ y: 100 }}
            animate={{ y: 0 }}
            className="absolute bottom-4 left-4 right-4 max-w-4xl mx-auto"
          >
            <div className="bg-white rounded-xl shadow-lg p-4">
              <div className="flex items-center justify-between mb-3">
                <h3 className="font-semibold text-gray-900">Active Buses</h3>
                <span className="text-sm text-gray-500">{statistics.activeBuses} buses</span>
              </div>
              
              <div className="flex space-x-4 overflow-x-auto pb-2">
                {buses?.filter(b => b.status === 'active').map(bus => (
                  <motion.div
                    key={bus.id}
                    whileHover={{ scale: 1.02 }}
                    onClick={() => handleBusSelect(bus)}
                    className="flex-shrink-0 bg-gray-50 rounded-lg p-3 cursor-pointer hover:bg-gray-100 transition-colors min-w-[200px]"
                  >
                    <div className="flex items-center justify-between mb-2">
                      <span className="font-medium text-gray-900">{bus.registrationNumber}</span>
                      <span className="flex h-2 w-2">
                        <span className="animate-ping absolute inline-flex h-2 w-2 rounded-full bg-green-400 opacity-75"></span>
                        <span className="relative inline-flex rounded-full h-2 w-2 bg-green-500"></span>
                      </span>
                    </div>
                    
                    <div className="space-y-1">
                      <div className="flex items-center text-xs text-gray-600">
                        <MapPinIcon className="h-3 w-3 mr-1" />
                        <span>{bus.routeName}</span>
                      </div>
                      <div className="flex items-center text-xs text-gray-600">
                        <ClockIcon className="h-3 w-3 mr-1" />
                        <span>ETA: {bus.eta} min</span>
                      </div>
                      <div className="flex items-center text-xs text-gray-600">
                        <UsersIcon className="h-3 w-3 mr-1" />
                        <span>{bus.currentCapacity}/{bus.maxCapacity}</span>
                      </div>
                    </div>
                  </motion.div>
                ))}
              </div>
            </div>
          </motion.div>
        </motion.div>
      </div>
    </div>
  );
}

export default LiveTracking;
