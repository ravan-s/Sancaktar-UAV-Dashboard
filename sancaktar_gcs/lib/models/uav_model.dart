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

  // ── JSON -> NESNE (Firebase'den Okurken) ─────────────────
  factory UavModel.fromJson(Map<dynamic, dynamic> json) {
    final t = json['telemetry'] != null ? Map<dynamic, dynamic>.from(json['telemetry'] as Map) : {};
    final s = json['status'] != null ? Map<dynamic, dynamic>.from(json['status'] as Map) : {};
    final c = json['command'] != null ? Map<dynamic, dynamic>.from(json['command'] as Map) : {};

    return UavModel(
      altitude:     (t['altitude']     as num?)?.toDouble() ?? 0.0,
      battery:      (t['battery']      as num?)?.toInt()    ?? 0,
      battery_volt: (t['battery_volt'] as num?)?.toDouble() ?? 0.0,
      speed:        (t['speed']        as num?)?.toDouble() ?? 0.0,
      lat:          (t['lat']          as num?)?.toDouble(),
      lon:          (t['lon']          as num?)?.toDouble(),
      gps_fix:      (t['gps_fix']      as num?)?.toInt()    ?? 0,
      flightMode:   (s['flight_mode']         as String?) ?? 'UNKNOWN',
      isArmed:      (s['is_armed']             as bool?)   ?? false,
      connectionStrength: (s['connection_strength'] as num?)?.toInt() ?? 0,
      action:       (c['action']      as String?),
      isExecuted:   (c['is_executed'] as bool?)   ?? false,
      targetLat:    (c['target_lat']  as num?)?.toDouble(),
      targetLon:    (c['target_lon']  as num?)?.toDouble(),
      targetId:     (c['target_id']   as String?),
      radius:       (c['radius']      as num?)?.toInt(),
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
  bool get isBatteryLow      => battery < 20;
  bool get isBatteryCritical => battery < 10;
  bool get isOnline          => connectionStrength > 0;
  bool get hasLocation       => lat != null && lon != null;
}