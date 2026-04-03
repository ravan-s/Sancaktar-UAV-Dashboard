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
    return UavModel(
      // Ekran görüntündeki hiyerarşiye göre Map'e zorluyoruz
      telemetry: Telemetry.fromJson(Map<String, dynamic>.from(json['telemetry'] ?? {})),
      status: Status.fromJson(Map<String, dynamic>.from(json['status'] ?? {})),
      command: Command.fromJson(Map<String, dynamic>.from(json['command'] ?? {})),
    );
  }
}

class Telemetry {
  final double altitude;
  final int battery;
  final double speed;

  Telemetry({required this.altitude, required this.battery, required this.speed});

  factory Telemetry.fromJson(Map<String, dynamic> json) {
    return Telemetry(
      // Firebase'den gelen int/double karmaşasını toDouble() ile çözüyoruz
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

  factory Status.fromJson(Map<String, dynamic> json) {
    return Status(
      // ÖNEMLİ: Ekran görüntünde 'connection_strength' yazıyor, o yüzden alt tireli kullanmalısın
      connectionStrength: (json['connection_strength'] ?? 0).toInt(),
      flightMode: json['flight_mode']?.toString() ?? 'UNKNOWN',
      isArmed: json['is_armed'] == true,
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

  factory Command.fromJson(Map<String, dynamic> json) {
    return Command(
      action: json['action']?.toString() ?? 'NONE',
      isExecuted: json['is_executed'] == true,
      // ÖNEMLİ: Ekran görüntünde 'target_lat' ve 'target_lon' yazıyor
      targetLat: (json['target_lat'] ?? 0.0).toDouble(),
      targetLon: (json['target_lon'] ?? 0.0).toDouble(),
      radius: (json['radius'] ?? 0).toInt(),
    );
  }
}