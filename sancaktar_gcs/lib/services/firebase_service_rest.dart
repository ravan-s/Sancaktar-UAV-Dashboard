// lib/services/firebase_service_rest.dart
// Linux Yer İstasyonu — Firebase HTTP REST API

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/uav_model.dart';
import 'firebase_service.dart';

class FirebaseServiceRest extends FirebaseServiceBase {
  static const _dbUrl =
      'https://sancaktar-2025-default-rtdb.europe-west1.firebasedatabase.app';

  // ── 1. TELEMETRİ GÜNCELLE ────────────────────────
  @override
  Future<void> updateTelemetry({
    required String droneCode,
    required Map<String, dynamic> data,
  }) async {
    try {
      await http.patch(
        Uri.parse('$_dbUrl/uavs/$droneCode.json'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          ...data,
          'last_update': {'.sv': 'timestamp'},
        }),
      );
    } catch (e) {
      print('❌ REST telemetri hatası: $e');
    }
  }

  // ── 2. DRONE DİNLE ───────────────────────────────
  @override
  Stream<Map<String, UavModel>> listenToUavs() {
    return Stream.value({});
  }

  // ── 3. KOMUT GÖNDER ──────────────────────────────
  @override
  Future<void> sendUavCommand(
    String uavId,
    String commandType, {
    Map<String, dynamic> extraParams = const {},
  }) async {
    final payload = <String, dynamic>{
      'action': commandType,
      'is_executed': false,
      'sent_by_uid': 'DESKTOP_STATION',
      'timestamp': {'.sv': 'timestamp'},
      ...extraParams,
    };

    try {
      await http.patch(
        Uri.parse('$_dbUrl/uavs/$uavId/command.json'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      print('✅ REST komut: $uavId → $commandType');
    } catch (e) {
      print('❌ REST komut hatası: $e');
    }
  }

  // ── 4. KONUM GÖNDER ──────────────────────────────
  @override
  Future<void> sendTargetLocation(
    String uavId,
    double lat,
    double lng, {
    double? altitude,
  }) async {
    final action = uavId == 'nesne_tespit' ? 'GO_TO_WAYPOINT' : 'GOTO';
    await sendUavCommand(
      uavId,
      action,
      extraParams: {
        'target_lat': lat,
        'target_lon': lng,
        if (altitude != null) 'altitude': altitude,
      },
    );
  }

  // ── 5. ROL SEVİYESİ ──────────────────────────────
  @override
  Future<int> getUserRoleLevel() async {
    return 5; // Yer istasyonu tam yetkili
  }

  // ── 6. ALAN TARAMA GÖREVİ ────────────────────────
  @override
  Future<void> sendScanMission({
    required String droneId,
    required String pattern,
    required List<Map<String, double>> waypoints,
    required double altitude,
    required double speed,
  }) async {
    try {
      await http.put(
        Uri.parse('$_dbUrl/uavs/$droneId/mission/scan.json'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'pattern': pattern,
          'waypoints': waypoints,
          'altitude': altitude,
          'speed': speed,
          'status': 'pending',
          'sent_by_uid': 'DESKTOP_STATION',
          'timestamp': {'.sv': 'timestamp'},
        }),
      );
      print(
        '✅ REST tarama görevi: $droneId → $pattern (${waypoints.length} wp)',
      );
    } catch (e) {
      print('❌ REST tarama hatası: $e');
    }
  }
}
