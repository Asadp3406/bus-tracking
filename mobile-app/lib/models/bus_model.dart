class Bus {
  final String id;
  final String registrationNumber;
  final String routeId;
  final String routeName;
  final double latitude;
  final double longitude;
  final double speed;
  final double bearing;
  final bool isMoving;
  final int eta; // in minutes
  final String driverName;
  final String driverPhone;
  final int currentCapacity;
  final int maxCapacity;
  final List<Stop> upcomingStops;
  final DateTime lastUpdated;
  final BusStatus status;

  Bus({
    required this.id,
    required this.registrationNumber,
    required this.routeId,
    required this.routeName,
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.bearing,
    required this.isMoving,
    required this.eta,
    required this.driverName,
    required this.driverPhone,
    required this.currentCapacity,
    required this.maxCapacity,
    required this.upcomingStops,
    required this.lastUpdated,
    required this.status,
  });

  factory Bus.fromJson(Map<String, dynamic> json) {
    return Bus(
      id: json['bus_id'] ?? '',
      registrationNumber: json['reg_no'] ?? '',
      routeId: json['route_id'] ?? '',
      routeName: json['route_name'] ?? '',
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      speed: (json['speed'] ?? 0).toDouble(),
      bearing: (json['bearing'] ?? 0).toDouble(),
      isMoving: json['is_moving'] ?? false,
      eta: json['eta'] ?? 0,
      driverName: json['driver_name'] ?? '',
      driverPhone: json['driver_phone'] ?? '',
      currentCapacity: json['current_capacity'] ?? 0,
      maxCapacity: json['max_capacity'] ?? 50,
      upcomingStops: (json['upcoming_stops'] as List<dynamic>?)
          ?.map((stop) => Stop.fromJson(stop))
          .toList() ?? [],
      lastUpdated: DateTime.parse(json['last_updated'] ?? DateTime.now().toIso8601String()),
      status: BusStatus.fromString(json['status'] ?? 'active'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bus_id': id,
      'reg_no': registrationNumber,
      'route_id': routeId,
      'route_name': routeName,
      'latitude': latitude,
      'longitude': longitude,
      'speed': speed,
      'bearing': bearing,
      'is_moving': isMoving,
      'eta': eta,
      'driver_name': driverName,
      'driver_phone': driverPhone,
      'current_capacity': currentCapacity,
      'max_capacity': maxCapacity,
      'upcoming_stops': upcomingStops.map((stop) => stop.toJson()).toList(),
      'last_updated': lastUpdated.toIso8601String(),
      'status': status.value,
    };
  }

  Bus copyWith({
    String? id,
    String? registrationNumber,
    String? routeId,
    String? routeName,
    double? latitude,
    double? longitude,
    double? speed,
    double? bearing,
    bool? isMoving,
    int? eta,
    String? driverName,
    String? driverPhone,
    int? currentCapacity,
    int? maxCapacity,
    List<Stop>? upcomingStops,
    DateTime? lastUpdated,
    BusStatus? status,
  }) {
    return Bus(
      id: id ?? this.id,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      routeId: routeId ?? this.routeId,
      routeName: routeName ?? this.routeName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      speed: speed ?? this.speed,
      bearing: bearing ?? this.bearing,
      isMoving: isMoving ?? this.isMoving,
      eta: eta ?? this.eta,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      currentCapacity: currentCapacity ?? this.currentCapacity,
      maxCapacity: maxCapacity ?? this.maxCapacity,
      upcomingStops: upcomingStops ?? this.upcomingStops,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      status: status ?? this.status,
    );
  }
}

class Stop {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final int eta; // in minutes
  final int order;

  Stop({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.eta,
    required this.order,
  });

  factory Stop.fromJson(Map<String, dynamic> json) {
    return Stop(
      id: json['stop_id'] ?? '',
      name: json['name'] ?? '',
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      eta: json['eta'] ?? 0,
      order: json['order'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stop_id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'eta': eta,
      'order': order,
    };
  }
}

class BusRoute {
  final String id;
  final String name;
  final String startPoint;
  final String endPoint;
  final List<Stop> stops;
  final List<LatLng> polylinePoints;
  final String schedule;
  final double totalDistance;
  final int estimatedDuration; // in minutes

  BusRoute({
    required this.id,
    required this.name,
    required this.startPoint,
    required this.endPoint,
    required this.stops,
    required this.polylinePoints,
    required this.schedule,
    required this.totalDistance,
    required this.estimatedDuration,
  });

  factory BusRoute.fromJson(Map<String, dynamic> json) {
    return BusRoute(
      id: json['route_id'] ?? '',
      name: json['name'] ?? '',
      startPoint: json['start_point'] ?? '',
      endPoint: json['end_point'] ?? '',
      stops: (json['stops'] as List<dynamic>?)
          ?.map((stop) => Stop.fromJson(stop))
          .toList() ?? [],
      polylinePoints: (json['polyline_points'] as List<dynamic>?)
          ?.map((point) => LatLng(
                (point['lat'] ?? 0).toDouble(),
                (point['lng'] ?? 0).toDouble(),
              ))
          .toList() ?? [],
      schedule: json['schedule'] ?? '',
      totalDistance: (json['total_distance'] ?? 0).toDouble(),
      estimatedDuration: json['estimated_duration'] ?? 0,
    );
  }
}

class LatLng {
  final double latitude;
  final double longitude;

  LatLng(this.latitude, this.longitude);
}

enum BusStatus {
  active('active'),
  inactive('inactive'),
  maintenance('maintenance'),
  delayed('delayed');

  final String value;
  const BusStatus(this.value);

  static BusStatus fromString(String status) {
    return BusStatus.values.firstWhere(
      (e) => e.value == status,
      orElse: () => BusStatus.active,
    );
  }
}
