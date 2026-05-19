// lib/services/firebase_service.dart
// Ortak interface — platform'a göre doğru implementasyonu seçer

import 'package:flutter/foundation.dart';
import '../models/uav_model.dart';
import 'firebase_service_rest.dart';
import 'firebase_service_sdk.dart';

// Platform'a göre doğru servisi döndür
FirebaseServiceBase createFirebaseService() {
  if (defaultTargetPlatform == TargetPlatform.linux && !kIsWeb) {
    return FirebaseServiceRest();
  }
  return FirebaseServiceSdk();
}

abstract class FirebaseServiceBase {
  // Telemetri güncelle
  Future<void> updateTelemetry({
    required String droneCode,
    required Map<String, dynamic> data,
  });

  // Tüm drone'ları dinle (mobil için)
  Stream<Map<String, UavModel>> listenToUavs();

  // Komut gönder
  Future<void> sendUavCommand(
    String uavId,
    String commandType, {
    Map<String, dynamic> extraParams = const {},
  });

  // Konum gönder
  Future<void> sendTargetLocation(
    String uavId,
    double lat,
    double lng, {
    double? altitude,
  });

  // Rol seviyesi
  Future<int> getUserRoleLevel();
}