// lib/models/uav_model.dart
// ── GÜNCELLEME: roll, pitch, heading, verticalSpeed, detected eklendi ──

class UavModel {
  // Telemetri (T)
  final double altitude;
  final int battery;
  final double battery_volt;
  final double speed;
  final double? lat;
  final double? lon;
  final int gps_fix;

  // Attitude
  final double roll;
  final double pitch;
  final double heading;
  final double verticalSpeed;

  // Tespit — insan_takip ve alan_tarama için (1=tespit var, 0=yok)
  final bool detected;

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
    this.roll = 0.0,
    this.pitch = 0.0,
    this.heading = 0.0,
    this.verticalSpeed = 0.0,
    this.detected = false,
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
      roll: (json['roll'] as num?)?.toDouble() ?? 0.0,
      pitch: (json['pitch'] as num?)?.toDouble() ?? 0.0,
      heading: (json['heading'] as num?)?.toDouble() ?? 0.0,
      verticalSpeed: (json['vertical_speed'] as num?)?.toDouble() ?? 0.0,
      // 1 → true, 0 veya null → false
      detected: ((json['detected'] as num?)?.toInt() ?? 0) == 1,
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
        'roll': roll,
        'pitch': pitch,
        'heading': heading,
        'vertical_speed': verticalSpeed,
        'detected': detected ? 1 : 0,
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

  int get batteryPercent {
    if (battery_volt > 0) {
      const minV = 14.0;
      const maxV = 16.8;
      final pct = ((battery_volt - minV) / (maxV - minV) * 100).clamp(0, 100);
      return pct.toInt();
    }
    return battery;
  }
}
