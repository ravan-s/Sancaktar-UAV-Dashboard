import 'package:firebase_database/firebase_database.dart';
import '../models/uav_model.dart';

class FirebaseService {
  // Ana referans: 'uavs' düğümü
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref("uavs");

  // --- 1. TELEMETRİ VE TÜM VERİ AKIŞI (STREAM) ---
  Stream<Map<String, UavModel>> listenToUavs() {
    return _dbRef.onValue.map((event) {
      final Map<String, UavModel> uavList = {};
      
      if (event.snapshot.value != null) {
        try {
          // Firebase'den gelen ham veriyi Map'e çeviriyoruz
          final rawData = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
          
          rawData.forEach((key, value) {
            try {
              // 'value' burada tuna_1 düğümünün tamamıdır (telemetry, status, command içerir)
              final uavData = Map<dynamic, dynamic>.from(value as Map);
              
              // UavModel.fromJson doğrudan tüm düğümü (uavData) almalı
              uavList[key.toString()] = UavModel.fromJson(uavData);
              
            } catch (e) {
              print("❌ Tekil İHA Dönüştürme Hatası ($key): $e");
            }
          });
        } catch (e) {
          print("❌ Genel Veri Yapısı Hatası: $e");
        }
      }
      return uavList;
    });
  }

  // --- 2. KOMUT GÖNDERME ---
  Future<void> sendUavCommand(String uavId, String commandType) async {
    try {
      // 'uavs/tuna_1/command' altına yazar. 
      // .update() kullanıyoruz ki mevcut target_lat/lon silinmesin!
      await _dbRef.child("$uavId/command").update({
        "action": commandType,
        "is_executed": false,
        "timestamp": ServerValue.timestamp,
      });
      
      // Log kaydı
      await _logToFirebase(uavId, "$commandType komutu gönderildi.");
      print("✅ BAŞARILI: $uavId -> $commandType");
    } catch (e) {
      print("⚠️ FİREBASE YAZMA HATASI: $e");
      rethrow; 
    }
  }

  // --- 3. KONUM GÖNDERME ---
  Future<void> sendTargetLocation(String uavId, double lat, double lng) async {
    try {
      // Python 'target_lat' ve 'target_lon' bekliyor, isimleri eşitledik
      await _dbRef.child("$uavId/command").update({
        "action": "GOTO",
        "target_lat": lat,
        "target_lon": lng,
        "is_executed": false,
        "timestamp": ServerValue.timestamp,
      });
      await _logToFirebase(uavId, "Yeni hedef konum: $lat, $lng");
    } catch (e) {
      print("📍 Konum Gönderme Hatası: $e");
    }
  }

  // --- 4. LOG YAZMA ---
  Future<void> _logToFirebase(String uavId, String message) async {
    try {
      await FirebaseDatabase.instance.ref("flight_logs/$uavId").push().set({
        "message": message,
        "timestamp": ServerValue.timestamp,
      });
    } catch (e) {
      print("📝 Log Hatası: $e");
    }
  }
}