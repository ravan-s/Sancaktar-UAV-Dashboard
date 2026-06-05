// lib/controllers/uav_controller.dart
//
// Veri akışı:
//   Pixhawk → DroneKit (Raspberry Pi) → WiFi → Firebase
//   Firebase → [bu controller] → UI

import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/uav_model.dart';
import 'auth_controller.dart';
import '../services/firebase_service.dart';
import '../services/firestore_log_service.dart';

class UavController extends GetxController {
  FirebaseServiceBase? _firebaseService;
  final stt.SpeechToText _speech = stt.SpeechToText();
  final VoiceAssistant assistant = VoiceAssistant();

  AuthController? get _auth {
    try {
      return Get.find<AuthController>();
    } catch (_) {
      return null;
    }
  }

  final uavList = <String, UavModel>{}.obs;
  final selectedUavId = ''.obs;
  final isListening = false.obs;
  final lastWords = ''.obs;

  final Map<String, DateTime> _lastBatteryWarningTime = {};
  final Map<String, DateTime> _lastAltitudeWarningTime = {};

  UavModel? get currentUav =>
      selectedUavId.value.isEmpty ? null : uavList[selectedUavId.value];

  int get _accessLevel => _auth?.userAccessLevel.value ?? 10;

  @override
  void onInit() {
    super.onInit();
    _firebaseService = createFirebaseService();
    FirestoreLogService().start();

    // Raspberry Pi → Firebase → burası dinler
    _startListeningToFirebase();

    ever(uavList, (Map<String, UavModel> list) {
      list.forEach((id, uav) => _runFailSafeChecks(id, uav));
    });
  }

  // UavController içinde
  final Rx<LatLng?> selectedLocation = Rx<LatLng?>(null);

  void addSelectedMarker(LatLng latLng) {
    selectedLocation.value = latLng;
  }

  Future<void> sendManualLocation(double lat, double lng) async {
    try {
      await FirebaseDatabase.instance
          .ref('uavs/${selectedUavId.value}/command')
          .set({
            'type': 'MANUAL_LOCATION',
            'latitude': lat,
            'longitude': lng,
            'timestamp': ServerValue.timestamp,
          });

      Get.snackbar(
        'Başarılı',
        'Konum gönderildi',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Hata',
        'Konum gönderilemedi: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  // ── FAİLSAFE ─────────────────────────────────────────────────
  void _runFailSafeChecks(String id, UavModel uav) {
    final now = DateTime.now();
    if (uav.battery <= 20) {
      final last = _lastBatteryWarningTime[id];
      if (last == null || now.difference(last).inSeconds >= 40) {
        assistant.say('Dikkat! $id bataryası kritik. Yüzde ${uav.battery}.');
        _lastBatteryWarningTime[id] = now;
      }
    }
    if (uav.altitude > 200) {
      final last = _lastAltitudeWarningTime[id];
      if (last == null || now.difference(last).inMinutes >= 1) {
        assistant.say(
          'Uyarı! $id irtifa sınırını aşıyor. ${uav.altitude.toInt()} metre.',
        );
        _lastAltitudeWarningTime[id] = now;
      }
    }
  }

  // ── FİREBASE STREAM ──────────────────────────────────────────
  void _startListeningToFirebase() {
    _firebaseService!.listenToUavs().listen((data) {
      uavList.assignAll(data);
      if (uavList.isNotEmpty && selectedUavId.value.isEmpty) {
        selectedUavId.value = uavList.containsKey('tuna_1')
            ? 'tuna_1'
            : uavList.keys.first;
      }
    }, onError: (e) => debugPrint('🚨 Firebase stream hatası: $e'));
  }

  // ── DRONE SEÇ ────────────────────────────────────────────────
  void selectUav(String id) {
    if (uavList.containsKey(id)) selectedUavId.value = id;
  }

  // ── KOMUT GÖNDER ─────────────────────────────────────────────
  // Firebase'e yazar → Raspberry Pi dinler → DroneKit'e iletir
  void sendCommand(String commandType, {Map<String, dynamic>? extra}) {
    debugPrint('🚁 _accessLevel: $_accessLevel');
    debugPrint('🚁 _auth: $_auth');
    debugPrint('🚁 userAccessLevel: ${_auth?.userAccessLevel.value}');
    FirestoreLogService().logCommand(
      droneId: selectedUavId.value,
      action: commandType,
      sentByUid: _auth?.currentUid.value ?? 'UNKNOWN',
    );

    if (selectedUavId.value.isEmpty) {
      Get.snackbar(
        'HATA',
        'Lütfen bir İHA seçin.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.5),
      );
      return;
    }

    if (_accessLevel >= 3) {
      _firebaseService?.sendUavCommand(
        selectedUavId.value,
        commandType,
        extraParams: extra ?? {},
      );
      Get.snackbar(
        'KOMUT',
        '${selectedUavId.value} → $commandType',
        snackPosition: SnackPosition.BOTTOM,
        colorText: Colors.white,
      );
    } else {
      Get.snackbar('YETKİSİZ', 'Bu işlem için yetki gereklidir.');
    }
  }

  // ── ALAN TARAMA GÖREVİ ───────────────────────────────────────
  // Firebase'e yazar → Raspberry Pi dinler → DroneKit SURVEY modu
  Future<void> sendScanMission({
    required String pattern,
    required List<Map<String, double>> waypoints,
    required double altitude,
    required double speed,
  }) async {
    final droneId = selectedUavId.value;

    if (droneId.isEmpty) {
      Get.snackbar('HATA', 'Lütfen önce bir İHA seçin.');
      return;
    }

    if (droneId != 'alan_tarama') {
      Get.snackbar(
        'UYARI',
        'Bu görev sadece ALAN TARAMA dronu için geçerlidir.',
      );
      return;
    }

    if (_accessLevel < 3) {
      Get.snackbar('YETKİSİZ', 'Bu işlem için yetki gereklidir.');
      return;
    }

    await _firebaseService?.sendScanMission(
      droneId: droneId,
      pattern: pattern,
      waypoints: waypoints,
      altitude: altitude,
      speed: speed,
    );

    FirestoreLogService().logCommand(
      droneId: droneId,
      action: 'SCAN_MISSION:$pattern',
      sentByUid: _auth?.currentUid.value ?? 'UNKNOWN',
    );
  }

  // ── WAYPOINT ─────────────────────────────────────────────────
  Future<void> sendWaypointToUav(
    double lat,
    double lng, {
    double alt = 10,
  }) async {
    if (selectedUavId.value.isEmpty) return;
    try {
      await _firebaseService?.sendTargetLocation(selectedUavId.value, lat, lng);
      assistant.say('Yeni koordinatlar gönderildi.');
    } catch (e) {
      debugPrint('Waypoint hatası: $e');
    }
  }

  // ── KONUM GÖNDER ─────────────────────────────────────────────
  void sendTargetPosition(double lat, double lng) {
    if (selectedUavId.value.isEmpty) {
      Get.snackbar('HATA', 'Lütfen önce bir İHA seçin.');
      return;
    }
    if (_accessLevel >= 1) {
      _firebaseService?.sendTargetLocation(selectedUavId.value, lat, lng);
      Get.snackbar(
        '📍 HEDEF',
        'Konum iletildi: $lat, $lng',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green.withOpacity(0.9),
        colorText: Colors.white,
      );
    } else {
      Get.snackbar('YETKİSİZ', 'Seviye 4 yetki gereklidir.');
    }
  }

  // ── SESLİ KOMUT ──────────────────────────────────────────────
  void toggleListening() async {
    if (!isListening.value) {
      final ok = await _speech.initialize(
        onStatus: (s) {
          if (s == 'done' || s == 'notListening') isListening.value = false;
        },
        onError: (_) => isListening.value = false,
      );
      if (ok) {
        isListening.value = true;
        lastWords.value = 'Dinleniyor...';
        _speech.listen(
          onResult: (r) {
            lastWords.value = r.recognizedWords;
            if (r.finalResult) {
              _processVoiceCommand(r.recognizedWords.toLowerCase());
            }
          },
          localeId: 'tr_TR',
        );
      }
    } else {
      isListening.value = false;
      _speech.stop();
    }
  }

  void _processVoiceCommand(String cmd) {
    if (cmd.contains('kalkış') || cmd.contains('havalan')) {
      assistant.say('Havalanıyor.');
      sendCommand('TAKEOFF');
    } else if (cmd.contains('iniş') || cmd.contains('çök')) {
      assistant.say('İniş başlatıldı.');
      sendCommand('LAND');
    } else if (cmd.contains('eve dön') || cmd.contains('merkez')) {
      assistant.say('Ana üsse dönüş.');
      sendCommand('RTL');
    } else if (cmd.contains('acil') || cmd.contains('iptal')) {
      assistant.say('Durduruldu!');
      sendCommand('HOLD');
    } else if (cmd.contains('tara') || cmd.contains('tarama')) {
      assistant.say('Alan tarama ekranına geçiliyor.');
      Get.toNamed('/scan');
    }
  }

  // ── OPERATÖR KONUMUNU GÖNDER ─────────────────────────────────
  Future<void> sendMyCurrentLocation() async {
    if (selectedUavId.value.isEmpty) {
      Get.snackbar('HATA', 'Lütfen önce bir İHA seçin.');
      return;
    }
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.always ||
          perm == LocationPermission.whileInUse) {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        sendTargetPosition(pos.latitude, pos.longitude);
        assistant.say('Operatör konumu alındı.');
      } else {
        Get.snackbar('İZİN REDDEDİLDİ', 'GPS izni gereklidir.');
      }
    } catch (e) {
      Get.snackbar('GPS HATASI', 'Konum alınamadı: $e');
    }
  }
}

// ── SESLİ ASISTAN ─────────────────────────────────────────────
class VoiceAssistant {
  dynamic _tts;

  VoiceAssistant() {
    _initTts();
  }

  Future<void> _initTts() async {
    if (defaultTargetPlatform == TargetPlatform.linux && !kIsWeb) {
      debugPrint('ℹ️ TTS Linux desteklemiyor, konsola yazılacak.');
      return;
    }
    try {
      final tts = FlutterTts();
      await tts.setLanguage('tr-TR');
      await tts.setPitch(1.0);
      await tts.setSpeechRate(0.5);
      _tts = tts;
    } catch (e) {
      debugPrint('TTS başlatma hatası: $e');
    }
  }

  Future<void> say(String text) async {
    if (_tts == null) {
      debugPrint('🔊 TTS: $text');
      return;
    }
    await _tts.speak(text);
  }
}
