class UavModel {
  // Telemetri (T)
  final double altitude;
  final int battery;
  final double battery_volt;
  final double speed;
  final double? lat;
  final double? lon;
  final int gps_fix;

  // Status (S)
  final String flightMode;
  final bool isArmed;
  final int connectionStrength;

  // Command (C)
  final String? action;
  final bool isExecuted;
  final double? targetLat;
  final double? targetLon;
  final String? targetId;
  final int? radius;

  UavModel({
    this.altitude = 0.0,
    this.battery = 0,
    this.battery_volt = 0.0,
    this.speed = 0.0,
    this.lat,
    this.lon,
    this.gps_fix = 0,
    this.flightMode = 'UNKNOWN',
    this.isArmed = false,
    this.connectionStrength = 0,
    this.action,
    this.isExecuted = false,
    this.targetLat,
    this.targetLon,
    this.targetId,
    this.radius,
  });

  factory UavModel.fromJson(Map<dynamic, dynamic> json) {
    return UavModel(
      altitude: (json['alt_rel'] as num?)?.toDouble() ?? 0.0,
      battery: (json['battery_level'] as num?)?.toInt() ?? 0,
      battery_volt: (json['battery_voltage'] as num?)?.toDouble() ?? 0.0,
      speed: (json['groundspeed'] as num?)?.toDouble() ?? 0.0,
      lat: (json['lat'] as num?)?.toDouble(),
      lon: (json['lon'] as num?)?.toDouble(),
      gps_fix: (json['gps_fix'] as num?)?.toInt() ?? 0,
      flightMode: (json['mode'] as String?) ?? 'UNKNOWN',
      isArmed: (json['armed'] as bool?) ?? false,
      connectionStrength: (json['satellites'] as num?)?.toInt() ?? 0,
      action: (json['action'] as String?),
      isExecuted: (json['is_executed'] as bool?) ?? false,
      targetLat: (json['target_lat'] as num?)?.toDouble(),
      targetLon: (json['target_lon'] as num?)?.toDouble(),
      targetId: (json['target_id'] as String?),
      radius: (json['radius'] as num?)?.toInt(),
    );
  }

  // ── NESNE -> JSON (Firebase'e Yazarken) ─────────────────
  // İŞTE EKSİK OLAN VE GÜNCELLENEN KISIM BURASI:
  Map<String, dynamic> toJson() {
    return {
      'telemetry': {
        'altitude': altitude,
        'battery': battery,
        'battery_volt': battery_volt,
        'speed': speed,
        'lat': lat,
        'lon': lon,
        'gps_fix': gps_fix,
      },
      'status': {
        'flight_mode': flightMode,
        'is_armed': isArmed,
        'connection_strength': connectionStrength,
      },
      'command': {
        'action': action,
        'is_executed': isExecuted,
        'target_lat': targetLat,
        'target_lon': targetLon,
        'target_id': targetId,
        'radius': radius,
      },
    };
  }

  // Yardımcılar
  bool get isBatteryLow => battery < 20;
  bool get isBatteryCritical => battery < 10;
  bool get isOnline => connectionStrength > 0;
  bool get hasLocation => lat != null && lon != null;
  double? get safeLat => (lat == null || lat == 0.0) ? null : lat;
  double? get safeLon => (lon == null || lon == 0.0) ? null : lon;
}
