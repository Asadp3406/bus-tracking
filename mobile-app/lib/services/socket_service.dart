import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

final socketServiceProvider = Provider<SocketService>((ref) {
  return SocketService();
});

class SocketService {
  late IO.Socket _socket;
  final StreamController<Map<String, dynamic>> _locationController = 
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _notificationController = 
      StreamController<Map<String, dynamic>>.broadcast();
  
  bool _isConnected = false;
  
  // Server URL - Update this with your actual server URL
  static const String _serverUrl = 'http://localhost:3000';
  
  void connect() {
    if (_isConnected) return;
    
    _socket = IO.io(_serverUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'reconnection': true,
      'reconnectionDelay': 1000,
      'reconnectionDelayMax': 5000,
      'reconnectionAttempts': 5,
    });
    
    _socket.onConnect((_) {
      print('Connected to WebSocket server');
      _isConnected = true;
      _subscribeToChannels();
    });
    
    _socket.onDisconnect((_) {
      print('Disconnected from WebSocket server');
      _isConnected = false;
    });
    
    _socket.onConnectError((error) {
      print('Connection Error: $error');
      _isConnected = false;
    });
    
    _socket.on('bus_location_update', (data) {
      _locationController.add(Map<String, dynamic>.from(data));
    });
    
    _socket.on('bus_arrival_notification', (data) {
      _notificationController.add(Map<String, dynamic>.from(data));
    });
    
    _socket.on('route_update', (data) {
      // Handle route updates
      print('Route update received: $data');
    });
    
    _socket.on('traffic_alert', (data) {
      // Handle traffic alerts
      print('Traffic alert: $data');
    });
    
    _socket.connect();
  }
  
  void _subscribeToChannels() {
    // Subscribe to specific bus routes or areas
    _socket.emit('subscribe', {
      'channels': ['all_buses', 'user_routes', 'alerts'],
    });
  }
  
  void subscribeToRoute(String routeId) {
    if (_isConnected) {
      _socket.emit('subscribe_route', {'route_id': routeId});
    }
  }
  
  void unsubscribeFromRoute(String routeId) {
    if (_isConnected) {
      _socket.emit('unsubscribe_route', {'route_id': routeId});
    }
  }
  
  void subscribeToBus(String busId) {
    if (_isConnected) {
      _socket.emit('subscribe_bus', {'bus_id': busId});
    }
  }
  
  void unsubscribeFromBus(String busId) {
    if (_isConnected) {
      _socket.emit('unsubscribe_bus', {'bus_id': busId});
    }
  }
  
  void sendUserLocation(double latitude, double longitude) {
    if (_isConnected) {
      _socket.emit('user_location', {
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }
  
  void requestBusETA(String busId, String stopId) {
    if (_isConnected) {
      _socket.emit('request_eta', {
        'bus_id': busId,
        'stop_id': stopId,
      });
    }
  }
  
  void onBusLocationUpdate(Function(Map<String, dynamic>) callback) {
    _locationController.stream.listen(callback);
  }
  
  void onNotification(Function(Map<String, dynamic>) callback) {
    _notificationController.stream.listen(callback);
  }
  
  Stream<Map<String, dynamic>> get locationStream => _locationController.stream;
  Stream<Map<String, dynamic>> get notificationStream => _notificationController.stream;
  
  bool get isConnected => _isConnected;
  
  void disconnect() {
    if (_isConnected) {
      _socket.disconnect();
      _isConnected = false;
    }
  }
  
  void dispose() {
    _locationController.close();
    _notificationController.close();
    disconnect();
  }
}
