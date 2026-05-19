import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
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
    try { return Get.find<AuthController>(); } catch (_) { return null; }
  }

  final uavList           = <String, UavModel>{}.obs;
  final selectedUavId     = ''.obs;
  final isListening       = false.obs;
  final lastWords         = ''.obs;

  final Map<String, DateTime> _lastBatteryWarningTime  = {};
  final Map<String, DateTime> _lastAltitudeWarningTime = {};

  UavModel? get currentUav =>
      selectedUavId.value.isEmpty ? null : uavList[selectedUavId.value];

  bool get isLinuxDesktop =>
      defaultTargetPlatform == TargetPlatform.linux && !kIsWeb;

  int get _accessLevel {
    if (isLinuxDesktop) return 5;
    return _auth?.userAccessLevel.value ?? 0;
  }

  @override
  void onInit() {
    super.onInit();

    // FirebaseService her platformda çalışır
    // Linux'ta REST, mobilde SDK kullanır
   _firebaseService = createFirebaseService();
    FirestoreLogService().start();
    if (!isLinuxDesktop) {
      _startListeningToFirebase();
    } else {
      print('ℹ️ Linux desktop — USB telemetri aktif, Firebase REST kullanılıyor');
    }

    ever(uavList, (Map<String, UavModel> list) {
      list.forEach((id, uav) => _runFailSafeChecks(id, uav));
    });
  }

  // ── FAİLSAFE ─────────────────────────────────────
  void _runFailSafeChecks(String id, UavModel uav) {
    final now = DateTime.now();
    if (uav.battery <= 20) {
      if (!_lastBatteryWarningTime.containsKey(id) ||
          now.difference(_lastBatteryWarningTime[id]!).inSeconds >= 40) {
        assistant.say('Dikkat! $id bataryası kritik. Yüzde ${uav.battery}.');
        _lastBatteryWarningTime[id] = now;
      }
    }
    if (uav.altitude > 200) {
      if (!_lastAltitudeWarningTime.containsKey(id) ||
          now.difference(_lastAltitudeWarningTime[id]!).inMinutes >= 1) {
        assistant.say('Uyarı! $id irtifa sınırını aşıyor. ${uav.altitude.toInt()} metre.');
        _lastAltitudeWarningTime[id] = now;
      }
    }
  }

  // ── FİREBASE STREAM (Mobil) ───────────────────────
  void _startListeningToFirebase() {
    _firebaseService!.listenToUavs().listen((data) {
      uavList.assignAll(data);
      if (uavList.isNotEmpty && selectedUavId.value.isEmpty) {
        selectedUavId.value = uavList.containsKey('tuna_1')
            ? 'tuna_1' : uavList.keys.first;
      }
    }, onError: (e) => print('🚨 Firebase stream hatası: $e'));
  }

  // ── USB'DEN GELEN VERİYİ GÜNCELLE (Linux) ────────
  void updateUavFromUsb(String droneId, UavModel uav) {
  uavList[droneId] = uav;
  
  _firebaseService?.updateTelemetry(
    droneCode: droneId,
    data: uav.toJson(),
  );

  // ← BU SATIR VAR MI?
  FirestoreLogService().updateBuffer(droneId, uav.toJson());

  if (selectedUavId.value.isEmpty) {
    selectedUavId.value = droneId;
  }
  uavList.refresh();
}

  // ── DRONE SEÇ ────────────────────────────────────
  void selectUav(String id) {
    if (uavList.containsKey(id)) selectedUavId.value = id;
  }

  // ── KOMUT GÖNDER ─────────────────────────────────
  void sendCommand(String commandType) {
    FirestoreLogService().logCommand(
  droneId: selectedUavId.value,
  action: commandType,
sentByUid: _auth?.currentUid.value ?? 'DESKTOP',);
    if (selectedUavId.value.isEmpty) {
      Get.snackbar('HATA', 'Lütfen bir İHA seçin.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.5));
      return;
    }
    if (_accessLevel >= 3) {
      _firebaseService?.sendUavCommand(selectedUavId.value, commandType);
      Get.snackbar('KOMUT', '${selectedUavId.value} → $commandType',
        snackPosition: SnackPosition.BOTTOM, colorText: Colors.white);
    } else {
      Get.snackbar('YETKİSİZ', 'Bu işlem için yetki gereklidir.');
    }
  }

  // ── WAYPOINT ─────────────────────────────────────
  Future<void> sendWaypointToUav(double lat, double lng) async {
    if (selectedUavId.value.isEmpty) return;
    try {
      await _firebaseService?.sendTargetLocation(selectedUavId.value, lat, lng);
      assistant.say('Yeni koordinatlar gönderildi.');
    } catch (e) {
      print('Waypoint hatası: $e');
    }
  }

  // ── KONUM GÖNDER ─────────────────────────────────
  void sendTargetPosition(double lat, double lng) {
    if (selectedUavId.value.isEmpty) {
      Get.snackbar('HATA', 'Lütfen önce bir İHA seçin.');
      return;
    }
    if (_accessLevel >= 4) {
      _firebaseService?.sendTargetLocation(selectedUavId.value, lat, lng);
      Get.snackbar('📍 HEDEF', 'Konum iletildi: $lat, $lng',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green.withOpacity(0.9),
        colorText: Colors.white);
    } else {
      Get.snackbar('YETKİSİZ', 'Seviye 4 yetki gereklidir.');
    }
  }

  // ── SESLİ KOMUT ──────────────────────────────────
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
        lastWords.value   = 'Dinleniyor...';
        _speech.listen(
          onResult: (r) {
            lastWords.value = r.recognizedWords;
            if (r.finalResult) {
              _processVoiceCommand(r.recognizedWords.toLowerCase());
            }
          },
          localeId: 'tr_TR');
      }
    } else {
      isListening.value = false;
      _speech.stop();
    }
  }

  void _processVoiceCommand(String cmd) {
    if (cmd.contains('kalkış') || cmd.contains('havalan')) {
      assistant.say('Havalanıyor.'); sendCommand('TAKEOFF');
    } else if (cmd.contains('iniş') || cmd.contains('çök')) {
      assistant.say('İniş başlatıldı.'); sendCommand('LAND');
    } else if (cmd.contains('eve dön') || cmd.contains('merkez')) {
      assistant.say('Ana üsse dönüş.'); sendCommand('RTL');
    } else if (cmd.contains('acil') || cmd.contains('iptal')) {
      assistant.say('Durduruldu!'); sendCommand('HOLD');
    }
  }

  // ── KONUMUMU GÖNDER ──────────────────────────────
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
          desiredAccuracy: LocationAccuracy.high);
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

// ── SESLİ ASISTAN ────────────────────────────────────
class VoiceAssistant {
  dynamic _tts;

  VoiceAssistant() { _initTts(); }

  Future<void> _initTts() async {
    if (defaultTargetPlatform == TargetPlatform.linux && !kIsWeb) {
      print('ℹ️ TTS Linux desteklemiyor.');
      return;
    }
    try {
      final tts = FlutterTts();
      await tts.setLanguage('tr-TR');
      await tts.setPitch(1.0);
      await tts.setSpeechRate(0.5);
      _tts = tts;
    } catch (e) {
      print('TTS başlatma hatası: $e');
    }
  }

  Future<void> say(String text) async {
    if (_tts == null) { print('🔊 TTS: $text'); return; }
    await _tts.speak(text);
  }
}