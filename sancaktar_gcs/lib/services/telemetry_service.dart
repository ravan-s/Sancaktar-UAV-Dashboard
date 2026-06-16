import 'package:flutter/foundation.dart';
import '../models/uav_model.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

FirebaseServiceBase createFirebaseService() {
  if (defaultTargetPlatform == TargetPlatform.linux && !kIsWeb) {
    return FirebaseServiceRest();
  }
  return FirebaseServiceSdk();
}

abstract class FirebaseServiceBase {
  Stream<Map<String, UavModel>> listenToUavs();
  Future<void> sendUavCommand(
    String droneId,
    String commandType, {
    Map<String, dynamic>? extra,
  });
  Future<void> sendTargetLocation(
    String droneId,
    double lat,
    double lng, {
    double alt = 10,
  });
  Future<void> sendScanMission({
    required String droneId,
    required String pattern,
    required List<Map<String, double>> waypoints,
    required double altitude,
    required double speed,
  });
}

class FirebaseServiceRest extends FirebaseServiceBase {
  static const _baseUrl =
      'https://sancaktar-2025-default-rtdb.europe-west1.firebasedatabase.app';

  @override
  Stream<Map<String, UavModel>> listenToUavs() {
    final controller = StreamController<Map<String, UavModel>>();
    _startPollLoop(controller);
    return controller.stream;
  }

  void _startPollLoop(StreamController<Map<String, UavModel>> sc) async {
    while (!sc.isClosed) {
      try {
        final uri = Uri.parse('$_baseUrl/uavs.json');
        final response = await http.get(uri);

        if (response.statusCode == 200) {
          final raw = json.decode(response.body);
          if (raw is Map) {
            final result = <String, UavModel>{};
            raw.forEach((droneId, value) {
              if (value is Map) {
                try {
                  // ── telemetry + status birleştir ──
                  final telemetry = Map<String, dynamic>.from(
                    value['telemetry'] as Map? ?? {},
                  );
                  final status = Map<String, dynamic>.from(
                    value['status'] as Map? ?? {},
                  );
                  final merged = {...telemetry, ...status};
                  if (merged.isNotEmpty) {
                    result[droneId.toString()] = UavModel.fromJson(merged);
                  }
                } catch (e) {
                  debugPrint('UavModel parse hatası ($droneId): $e');
                }
              }
            });
            if (!sc.isClosed) sc.add(result);
          }
        } else {
          debugPrint('REST poll HTTP ${response.statusCode}');
        }
      } catch (e) {
        debugPrint('REST poll hatası: $e');
      }
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  @override
  Future<void> sendUavCommand(
    String droneId,
    String commandType, {
    Map<String, dynamic>? extra,
  }) async {
    final uri = Uri.parse('$_baseUrl/uavs/$droneId/command.json');
    try {
      await http.patch(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'action': commandType,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          ...?extra,
        }),
      );
      debugPrint('✅ REST komut: $droneId → $commandType');
    } catch (e) {
      debugPrint('❌ REST komut hatası: $e');
    }
  }

  @override
  Future<void> sendTargetLocation(
    String droneId,
    double lat,
    double lng, {
    double alt = 10,
  }) async {
    await sendUavCommand(
      droneId,
      'GOTO',
      extra: {'lat': lat, 'lon': lng, 'alt': alt},
    );
  }

  @override
  Future<void> sendScanMission({
    required String droneId,
    required String pattern,
    required List<Map<String, double>> waypoints,
    required double altitude,
    required double speed,
  }) async {
    final uri = Uri.parse('$_baseUrl/uavs/$droneId/mission/scan.json');
    try {
      await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'pattern': pattern,
          'waypoints': waypoints,
          'altitude': altitude,
          'speed': speed,
          'status': 'pending',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        }),
      );
      debugPrint('✅ REST tarama: $droneId → $pattern');
    } catch (e) {
      debugPrint('❌ REST tarama hatası: $e');
    }
  }
}

class FirebaseServiceSdk extends FirebaseServiceBase {
  final _db = FirebaseDatabase.instance;

  @override
  Stream<Map<String, UavModel>> listenToUavs() {
    return _db.ref('uavs').onValue.map((event) {
      final result = <String, UavModel>{};
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return result;

      data.forEach((droneId, value) {
        if (value is Map) {
          try {
            // ── telemetry + status birleştir ──
            final telemetry = Map<String, dynamic>.from(
              value['telemetry'] as Map? ?? {},
            );
            final status = Map<String, dynamic>.from(
              value['status'] as Map? ?? {},
            );
            final merged = {...telemetry, ...status};
            if (merged.isNotEmpty) {
              result[droneId.toString()] = UavModel.fromJson(merged);
            }
          } catch (e) {
            debugPrint('UavModel parse hatası ($droneId): $e');
          }
        }
      });
      return result;
    });
  }

  @override
  Future<void> sendUavCommand(
    String droneId,
    String commandType, {
    Map<String, dynamic>? extra,
  }) async {
    await _db.ref('uavs/$droneId/command').set({
      'action': commandType,
      'timestamp': ServerValue.timestamp,
      ...?extra,
    });
  }

  @override
  Future<void> sendTargetLocation(
    String droneId,
    double lat,
    double lng, {
    double alt = 10,
  }) async {
    await sendUavCommand(
      droneId,
      'GOTO',
      extra: {'lat': lat, 'lon': lng, 'alt': alt},
    );
  }

  @override
  Future<void> sendScanMission({
    required String droneId,
    required String pattern,
    required List<Map<String, double>> waypoints,
    required double altitude,
    required double speed,
  }) async {
    await _db.ref('uavs/$droneId/mission/scan').set({
      'pattern': pattern,
      'waypoints': waypoints,
      'altitude': altitude,
      'speed': speed,
      'status': 'pending',
      'timestamp': ServerValue.timestamp,
    });
  }
}
