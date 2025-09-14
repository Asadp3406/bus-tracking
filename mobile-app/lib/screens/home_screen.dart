import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/bus_info_card.dart';
import '../widgets/route_selector.dart';
import '../providers/map_provider.dart';
import '../providers/bus_provider.dart';
import '../models/bus_model.dart';
import '../services/socket_service.dart';
import 'dart:async';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  Bus? _selectedBus;
  bool _isMapLoading = true;
  Timer? _locationUpdateTimer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Initial camera position (you can set to user's location)
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(18.5204, 73.8567), // Pune coordinates
    zoom: 14.0,
  );

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _connectToSocket();
    _startLocationUpdates();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  void _connectToSocket() {
    final socketService = ref.read(socketServiceProvider);
    socketService.connect();
    
    // Listen for real-time bus updates
    socketService.onBusLocationUpdate((data) {
      _updateBusMarker(data);
    });
  }

  void _startLocationUpdates() {
    _locationUpdateTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _fetchBusLocations(),
    );
  }

  Future<void> _fetchBusLocations() async {
    final buses = await ref.read(busProvider.notifier).fetchNearbyBuses();
    _updateMarkers(buses);
  }

  void _updateMarkers(List<Bus> buses) {
    setState(() {
      _markers.clear();
      for (final bus in buses) {
        _markers.add(
          Marker(
            markerId: MarkerId(bus.id),
            position: LatLng(bus.latitude, bus.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              bus.isMoving 
                ? BitmapDescriptor.hueGreen 
                : BitmapDescriptor.hueRed,
            ),
            onTap: () => _onBusSelected(bus),
            infoWindow: InfoWindow(
              title: 'Bus ${bus.registrationNumber}',
              snippet: 'Route: ${bus.routeName} | ETA: ${bus.eta} min',
            ),
          ),
        );
      }
    });
  }

  void _updateBusMarker(Map<String, dynamic> data) {
    final busId = data['busId'] as String;
    final lat = data['latitude'] as double;
    final lng = data['longitude'] as double;
    
    setState(() {
      _markers.removeWhere((marker) => marker.markerId.value == busId);
      _markers.add(
        Marker(
          markerId: MarkerId(busId),
          position: LatLng(lat, lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          onTap: () {
            // Handle tap
          },
        ),
      );
    });
    
    // Animate camera to bus if it's selected
    if (_selectedBus?.id == busId) {
      _animateToBus(lat, lng);
    }
  }

  void _onBusSelected(Bus bus) {
    setState(() {
      _selectedBus = bus;
    });
    _animateToBus(bus.latitude, bus.longitude);
    _showBusInfoSheet(bus);
  }

  void _animateToBus(double lat, double lng) {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(lat, lng),
          zoom: 16.0,
          bearing: 0,
          tilt: 45.0,
        ),
      ),
    );
  }

  void _showBusInfoSheet(Bus bus) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BusInfoCard(
        bus: bus,
        onNavigate: () => _startNavigation(bus),
        onSetAlert: () => _setArrivalAlert(bus),
      ),
    );
  }

  void _startNavigation(Bus bus) {
    // Implement navigation logic
    ref.read(mapProvider.notifier).startNavigation(bus);
  }

  void _setArrivalAlert(Bus bus) {
    // Implement alert logic
    ref.read(busProvider.notifier).setArrivalAlert(bus);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Alert set for Bus ${bus.registrationNumber}'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    _pulseController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buses = ref.watch(busProvider);
    
    return Scaffold(
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            initialCameraPosition: _initialPosition,
            onMapCreated: (controller) {
              _mapController = controller;
              setState(() {
                _isMapLoading = false;
              });
              _fetchBusLocations();
            },
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: true,
            buildingsEnabled: true,
            trafficEnabled: false,
            mapType: MapType.normal,
            style: '''[
              {
                "featureType": "poi.business",
                "stylers": [{"visibility": "off"}]
              },
              {
                "featureType": "transit",
                "elementType": "labels.icon",
                "stylers": [{"visibility": "off"}]
              }
            ]''',
          ),
          
          // Loading overlay
          if (_isMapLoading)
            Container(
              color: theme.colorScheme.surface.withOpacity(0.8),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation(
                        theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading map...',
                      style: theme.textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 300.ms),
          
          // Top gradient overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.colorScheme.surface,
                    theme.colorScheme.surface.withOpacity(0.8),
                    theme.colorScheme.surface.withOpacity(0),
                  ],
                ),
              ),
            ),
          ),
          
          // Search Bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: SearchBarWidget(
              onSearch: (query) {
                // Handle search
                ref.read(busProvider.notifier).searchBuses(query);
              },
              onFilterTap: () {
                // Show filter options
                _showFilterSheet();
              },
            ).animate()
              .fadeIn(duration: 500.ms)
              .slideY(begin: -0.5, end: 0, duration: 500.ms),
          ),
          
          // Route Selector Chips
          Positioned(
            top: MediaQuery.of(context).padding.top + 80,
            left: 0,
            right: 0,
            height: 50,
            child: RouteSelector(
              onRouteSelected: (routeId) {
                ref.read(busProvider.notifier).filterByRoute(routeId);
              },
            ).animate()
              .fadeIn(delay: 200.ms, duration: 500.ms)
              .slideX(begin: -0.2, end: 0, duration: 500.ms),
          ),
          
          // My Location Button
          Positioned(
            bottom: 100,
            right: 16,
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _selectedBus != null ? _pulseAnimation.value : 1.0,
                  child: FloatingActionButton(
                    onPressed: _getCurrentLocation,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    elevation: 4,
                    child: Icon(
                      Icons.my_location,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                );
              },
            ).animate()
              .fadeIn(delay: 400.ms, duration: 500.ms)
              .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),
          ),
          
          // Bottom Navigation Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(Icons.home_rounded, 'Home', true),
                  _buildNavItem(Icons.route_rounded, 'Routes', false),
                  _buildNavItem(Icons.star_rounded, 'Favorites', false),
                  _buildNavItem(Icons.person_rounded, 'Profile', false),
                ],
              ),
            ).animate()
              .fadeIn(delay: 600.ms, duration: 500.ms)
              .slideY(begin: 0.2, end: 0, duration: 500.ms),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive) {
    final theme = Theme.of(context);
    final color = isActive 
      ? theme.colorScheme.primary 
      : theme.colorScheme.onSurfaceVariant;
    
    return InkWell(
      onTap: () {
        // Handle navigation
        HapticFeedback.lightImpact();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    HapticFeedback.mediumImpact();
    final position = await ref.read(mapProvider.notifier).getCurrentLocation();
    if (position != null) {
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 16.0,
          ),
        ),
      );
    }
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter Buses',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            // Add filter options here
          ],
        ),
      ),
    );
  }
}
