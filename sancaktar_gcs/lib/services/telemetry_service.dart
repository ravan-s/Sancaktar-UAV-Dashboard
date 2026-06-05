import 'package:flutter/foundation.dart';
import '../models/uav_model.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

// ── PLATFORM FACTORY ─────────────────────────────────────────
FirebaseServiceBase createFirebaseService() {
  if (defaultTargetPlatform == TargetPlatform.linux && !kIsWeb) {
    return FirebaseServiceRest(); // Linux desktop → REST
  }
  return FirebaseServiceSdk(); // iOS / Android → SDK
}

// ── ABSTRACT BASE ─────────────────────────────────────────────
abstract class FirebaseServiceBase {
  /// drones/{drone_id}/telemetry  stream'ini dinler
  Stream<Map<String, UavModel>> listenToUavs();

  /// drones/{drone_id}/command  altına komut yazar
  /// Raspberry Pi bu node'u dinler, DroneKit'e iletir.
  Future<void> sendUavCommand(
    String droneId,
    String commandType, {
    Map<String, dynamic>? extra,
  });

  /// drones/{drone_id}/command  altına waypoint yazar
  Future<void> sendTargetLocation(
    String droneId,
    double lat,
    double lng, {
    double alt = 10,
  });
}

// ── REST İMPLEMENTASYONU (Linux) ─────────────────────────────

class FirebaseServiceRest extends FirebaseServiceBase {
  static const _baseUrl =
      'https://<YOUR-PROJECT>.firebaseio.com'; // kendi URL'in
  static const _secret =
      ''; // opsiyonel: DB secret (rules izin veriyorsa boş bırak)

  String get _auth => _secret.isNotEmpty ? '?auth=$_secret' : '';

  // ── Stream: Server-Sent Events (SSE) ─────────────────────────
  @override
  Stream<Map<String, UavModel>> listenToUavs() {
    final controller = StreamController<Map<String, UavModel>>();
    _startSseLoop(controller);
    return controller.stream;
  }

  void _startSseLoop(StreamController<Map<String, UavModel>> sc) async {
    while (!sc.isClosed) {
      try {
        final uri = Uri.parse('$_baseUrl/drones.json$_auth');
        final response = await http.get(
          uri,
          headers: {'Accept': 'text/event-stream', 'Cache-Control': 'no-cache'},
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body) as Map<String, dynamic>?;
          if (data != null) {
            final result = <String, UavModel>{};
            data.forEach((droneId, value) {
              if (value is Map) {
                final telemetry = value['telemetry'];
                if (telemetry is Map) {
                  result[droneId] = UavModel.fromJson(
                    Map<String, dynamic>.from(telemetry),
                  );
                }
              }
            });
            if (!sc.isClosed) sc.add(result);
          }
        }
      } catch (e) {
        debugPrint('REST poll hatası: $e');
      }
      await Future.delayed(const Duration(seconds: 1)); // 1 Hz polling
    }
  }

  // ── Komut Gönder ─────────────────────────────────────────────
  @override
  Future<void> sendUavCommand(
    String droneId,
    String commandType, {
    Map<String, dynamic>? extra,
  }) async {
    final uri = Uri.parse('$_baseUrl/drones/$droneId/command.json$_auth');
    final body = json.encode({
      'action': commandType,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      ...?extra,
    });
    await http.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
  }

  // ── Waypoint Gönder ──────────────────────────────────────────
  @override
  Future<void> sendTargetLocation(
    String droneId,
    double lat,
    double lng, {
    double alt = 10,
  }) async {
    await sendUavCommand(
      droneId,
      'WAYPOINT',
      extra: {'lat': lat, 'lng': lng, 'alt': alt},
    );
  }
}

// ── SDK İMPLEMENTASYONU (iOS / Android) ──────────────────────

class FirebaseServiceSdk extends FirebaseServiceBase {
  final _db = FirebaseDatabase.instance;

  // ── Stream: onValue listener ─────────────────────────────────
  @override
  Stream<Map<String, UavModel>> listenToUavs() {
    return _db.ref('drones').onValue.map((event) {
      final result = <String, UavModel>{};
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return result;

      data.forEach((droneId, value) {
        if (value is Map) {
          final telemetry = value['telemetry'];
          if (telemetry is Map) {
            result[droneId.toString()] = UavModel.fromJson(
              Map<String, dynamic>.from(telemetry),
            );
          }
        }
      });
      return result;
    });
  }

  // ── Komut Gönder ─────────────────────────────────────────────
  @override
  Future<void> sendUavCommand(
    String droneId,
    String commandType, {
    Map<String, dynamic>? extra,
  }) async {
    await _db.ref('drones/$droneId/command').set({
      'action': commandType,
      'timestamp': ServerValue.timestamp,
      ...?extra,
    });
  }

  // ── Waypoint Gönder ──────────────────────────────────────────
  @override
  Future<void> sendTargetLocation(
    String droneId,
    double lat,
    double lng, {
    double alt = 10,
  }) async {
    await sendUavCommand(
      droneId,
      'WAYPOINT',
      extra: {'lat': lat, 'lng': lng, 'alt': alt},
    );
  }
}
