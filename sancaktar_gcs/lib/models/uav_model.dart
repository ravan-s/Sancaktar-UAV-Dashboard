class UavModel {
  final Telemetry telemetry;
  final Status status;
  final Command command;

  UavModel({
    required this.telemetry,
    required this.status,
    required this.command,
  });

  factory UavModel.fromJson(Map<dynamic, dynamic> json) {
    // ÇÖZÜM: Gelen veriyi "Map<dynamic, dynamic>.from()" içine alarak 
    // Flutter'ı bunun bir Sözlük (Map) olduğuna ikna ediyoruz.
    return UavModel(
      telemetry: Telemetry.fromJson(Map<dynamic, dynamic>.from(json['telemetry'] ?? {})),
      status: Status.fromJson(Map<dynamic, dynamic>.from(json['status'] ?? {})),
      command: Command.fromJson(Map<dynamic, dynamic>.from(json['command'] ?? {})),
    );
  }
}

class Telemetry {
  final double altitude;
  final int battery;
  final double speed;

  Telemetry({required this.altitude, required this.battery, required this.speed});

  factory Telemetry.fromJson(Map<dynamic, dynamic> json) {
    return Telemetry(
      altitude: (json['altitude'] ?? 0.0).toDouble(),
      battery: (json['battery'] ?? 0).toInt(),
      speed: (json['speed'] ?? 0.0).toDouble(),
    );
  }
}

class Status {
  final int connectionStrength;
  final String flightMode;
  final bool isArmed;

  Status({
    required this.connectionStrength,
    required this.flightMode,
    required this.isArmed,
  });

  factory Status.fromJson(Map<dynamic, dynamic> json) {
    return Status(
      connectionStrength: (json['connection_strength'] ?? 0).toInt(),
      flightMode: json['flight_mode']?.toString() ?? 'UNKNOWN',
      isArmed: json['is_armed'] ?? false,
    );
  }
}

class Command {
  final String action;
  final bool isExecuted;
  final double targetLat;
  final double targetLon;
  final int radius;

  Command({
    required this.action,
    required this.isExecuted,
    required this.targetLat,
    required this.targetLon,
    required this.radius,
  });

  factory Command.fromJson(Map<dynamic, dynamic> json) {
    return Command(
      action: json['action']?.toString() ?? 'NONE',
      isExecuted: json['is_executed'] ?? true,
      targetLat: (json['target_lat'] ?? 0.0).toDouble(),
      targetLon: (json['target_lon'] ?? 0.0).toDouble(),
      radius: (json['radius'] ?? 0).toInt(),
    );
  }
}