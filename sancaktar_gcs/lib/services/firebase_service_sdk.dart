// lib/services/firebase_service_sdk.dart
// Mobil / Windows — Firebase Resmi SDK (WebSocket gerçek zamanlı)

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/uav_model.dart';
import 'firebase_service.dart';

class FirebaseServiceSdk extends FirebaseServiceBase {
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // ── 1. TELEMETRİ GÜNCELLE ────────────────────────
  @override
  Future<void> updateTelemetry({
    required String droneCode,
    required Map<String, dynamic> data,
  }) async {
    try {
      await FirebaseDatabase.instance
          .ref('uavs/$droneCode')
          .update({...data, 'last_update': ServerValue.timestamp});
    } catch (e) {
      print('❌ SDK telemetri hatası: $e');
    }
  }

  // ── 2. DRONE DİNLE (WebSocket) ───────────────────
  @override
  Stream<Map<String, UavModel>> listenToUavs() {
    return FirebaseDatabase.instance.ref('uavs').onValue.map((event) {
      final result = <String, UavModel>{};
      final raw = event.snapshot.value as Map?;
      if (raw == null) return result;

      raw.forEach((key, value) {
        try {
          result[key.toString()] = UavModel.fromJson(
            Map<dynamic, dynamic>.from(value as Map),
          );
        } catch (e) {
          print('❌ Parse hatası ($key): $e');
        }
      });
      return result;
    });
  }

  // ── 3. KOMUT GÖNDER ──────────────────────────────
  @override
  Future<void> sendUavCommand(
    String uavId,
    String commandType, {
    Map<String, dynamic> extraParams = const {},
  }) async {
    _checkAuth();
    _checkAllowed(uavId, commandType);

    final payload = <String, dynamic>{
      'action':      commandType,
      'is_executed': false,
      'sent_by_uid': _uid,
      'timestamp':   ServerValue.timestamp,
      ...extraParams,
    };

    await FirebaseDatabase.instance
        .ref('uavs/$uavId/command')
        .update(payload);

    // Log
    await FirebaseDatabase.instance
        .ref('flight_logs/$uavId')
        .push()
        .set({
      'message':     '$commandType komutu gönderildi.',
      'sent_by_uid': _uid,
      'timestamp':   ServerValue.timestamp,
    });

    print('✅ SDK komut: $uavId → $commandType');
  }

  // ── 4. KONUM GÖNDER ──────────────────────────────
  @override
  Future<void> sendTargetLocation(
    String uavId,
    double lat,
    double lng, {
    double? altitude,
  }) async {
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
      throw Exception('Geçersiz koordinat: $lat, $lng');
    }
    final action = uavId == 'tuna_1' ? 'GO_TO_WAYPOINT' : 'GOTO';
    await sendUavCommand(uavId, action, extraParams: {
      'target_lat': lat,
      'target_lon': lng,
      if (altitude != null) 'altitude': altitude,
    });
  }

  // ── 5. ROL SEVİYESİ ──────────────────────────────
  @override
  Future<int> getUserRoleLevel() async {
    if (_uid == null) return 1;
    final snap = await FirebaseDatabase.instance
        .ref('users/$_uid/role_level')
        .get();
    return (snap.value as int?) ?? 1;
  }

  // ── YARDIMCILAR ──────────────────────────────────
  void _checkAuth() {
    if (_uid == null) throw Exception('Kullanıcı oturumu yok.');
  }

  void _checkAllowed(String uavId, String command) {
    const common = {'HOLD', 'RTL', 'LAND', 'ARM', 'DISARM', 'GOTO'};
    final allowed = <String>{
      ...common,
      if (uavId == 'insan_takip') 'TRACK_TARGET',
      if (uavId == 'kamikaze')    ...{'WAIT', 'ENGAGE'},
      if (uavId == 'tasiyici')    'DELIVER_CARGO',
      if (uavId == 'alan_tarama') 'PATTERN_SEARCH',
      if (uavId == 'tuna_1')      'GO_TO_WAYPOINT',
    };
    if (!allowed.contains(command)) {
      throw Exception('Geçersiz komut: $command');
    }
  }
}