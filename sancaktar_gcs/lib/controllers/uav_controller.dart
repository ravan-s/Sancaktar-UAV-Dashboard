// lib/controllers/uav_controller.dart

import 'dart:io';

import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:sancaktar_gcs/main.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/uav_model.dart';
import 'auth_controller.dart';
import '../services/firebase_service.dart';
import '../services/firestore_log_service.dart';
import '../services/system_tts_stub.dart'
    if (dart.library.io) '../services/system_tts_io.dart';
import 'package:flutter/foundation.dart';

class UavController extends GetxController {
  FirebaseServiceBase? _firebaseService;
  final stt.SpeechToText _speech = stt.SpeechToText();
  final VoiceAssistant assistant = VoiceAssistant();

  AuthController? get _authOrNull =>
      isLinuxDesktop ? null : Get.find<AuthController>();

  AuthController get _auth => Get.find<AuthController>();

  int get _accessLevel =>
      isLinuxDesktop ? 10 : (_authOrNull?.userAccessLevel.value ?? 0);
  final uavList = <String, UavModel>{}.obs;
  final selectedUavId = ''.obs;
  final isListening = false.obs;
  final lastWords = ''.obs;
  final Rx<LatLng?> selectedLocation = Rx<LatLng?>(null);

  final Map<String, DateTime> _lastBatteryWarningTime = {};
  final Map<String, DateTime> _lastAltitudeWarningTime = {};

  // ── DURUM TAKİP ──────────────────────────────────────────────
  final Map<String, bool> _prevArmedState = {};
  bool _allLaunchedAnnounced = false;
  bool _alanTaramaArrivedAnnounced = false;

  // ── TESPİT TAKİBİ (1/0 yükselen kenar) ───────────────────────
  static const Set<String> _detectionDrones = {
    'insan_takip',
    'nesne_tespit',
    'alan_tarama',
  };
  final Map<String, bool> _prevDetected = {};

  UavModel? get currentUav =>
      selectedUavId.value.isEmpty ? null : uavList[selectedUavId.value];

  bool get isLinuxDesktop =>
      defaultTargetPlatform == TargetPlatform.linux && !kIsWeb;

  @override
  void onInit() {
    super.onInit();

    if (!isLinuxDesktop && !Get.isRegistered<AuthController>()) {
      throw Exception('AuthController register edilmemiş!');
    }

    _firebaseService = createFirebaseService();
    FirestoreLogService().start();
    _startListeningToFirebase();

    if (!isLinuxDesktop) {
      _listenConnectionStatus();

      ever(_auth.currentUid, (String uid) {
        debugPrint('🔑 UavController uid güncellendi: $uid');
        debugPrint(
          '🔑 UavController accessLevel: ${_auth.userAccessLevel.value}',
        );
      });
    }

    ever(uavList, (Map<String, UavModel> list) {
      list.forEach((id, uav) {
        _runFailSafeChecks(id, uav);
        _checkLaunchStatus(id, uav);
        _checkMissionEvents(id, uav);
        _checkDetectionEvents(id, uav);
      });
      _checkAllLaunched(list);
    });
  }

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

  Future<void> sendDropMissionLocations(
    Map<String, Map<String, dynamic>> locations,
  ) async {
    try {
      await FirebaseDatabase.instance
          .ref('uavs/tasiyici/mission')
          .set(locations.map((key, val) => MapEntry('${key}_drop', val)));
    } catch (e) {
      debugPrint('Konum gönderme hatası: $e');
    }
  }

  void _listenConnectionStatus() {
    FirebaseDatabase.instance.ref('.info/connected').onValue.listen((event) {
      final connected = event.snapshot.value as bool? ?? false;
      if (!connected) {
        Get.snackbar(
          '🔴 BAĞLANTI KESİLDİ',
          'Firebase bağlantısı yok. Veriler güncel olmayabilir.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red.withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
          isDismissible: false,
        );
      } else {
        if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();
        Get.snackbar(
          '🟢 BAĞLANDI',
          'Firebase bağlantısı yeniden kuruldu.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green.withOpacity(0.8),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      }
    });
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

  // ── KALDIŞ MUTABAKATI ────────────────────────────────────────
  void _checkLaunchStatus(String id, UavModel uav) {
    final prev = _prevArmedState[id];
    if (prev == false && uav.isArmed == true) {
      assistant.say('${_droneDisplayName(id)} kalkış yaptı.');
    }
    _prevArmedState[id] = uav.isArmed;
  }

  void _checkAllLaunched(Map<String, UavModel> list) {
    if (_allLaunchedAnnounced || list.isEmpty) return;
    if (list.values.every((uav) => uav.isArmed)) {
      _allLaunchedAnnounced = true;
      assistant.say(
        'Tüm dronlar görevlerini yapmak üzere kalkış yaptılar. Eve dönülüyor.',
      );
    }
  }

  // ── GÖREV OLAYLARI ───────────────────────────────────────────
  void _checkMissionEvents(String id, UavModel uav) {
    if (id == 'alan_tarama') {
      if (uav.action == 'ARRIVED' && !_alanTaramaArrivedAnnounced) {
        _alanTaramaArrivedAnnounced = true;
        assistant.say('Konuma ulaşıldı. Tarama başlıyor.');
      }
      if (uav.action != 'ARRIVED') _alanTaramaArrivedAnnounced = false;
    }
  }

  // ── TESPİT OLAYLARI (mobil + Linux, uavList üzerinden) ───────
  // Bayrak 0→1 olunca bir kez bildirim + sesli asistan; 1→0 olunca sıfırlanır.
  void _checkDetectionEvents(String id, UavModel uav) {
    if (!_detectionDrones.contains(id)) return;

    final prev = _prevDetected[id] ?? false;
    if (!prev && uav.detected) {
      final (title, message) = _detectionTexts(id);
      assistant.say(message);
      _showDetectionNotification(id, title, message);
    }
    _prevDetected[id] = uav.detected;
  }

  // Drone ID → (bildirim başlığı, sesli/yazılı mesaj)
  (String, String) _detectionTexts(String id) {
    switch (id) {
      case 'insan_takip':
        return (
          '🚨 İNSAN TESPİT EDİLDİ',
          'İnsan tespit edildi. Takip başlatıldı.',
        );
      case 'nesne_tespit':
        return ('🎯 NESNE TESPİT EDİLDİ', 'Nesne tespit edildi.');
      case 'alan_tarama':
        return (
          '📡 ALAN TARAMA — HEDEF',
          'Alan tarama bölgesinde hedef tespit edildi.',
        );
      default:
        return ('TESPİT', 'Tespit edildi.');
    }
  }

  void _showDetectionNotification(String id, String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.red.withOpacity(0.9),
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
      icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
      shouldIconPulse: true,
      margin: const EdgeInsets.all(12),
    );
  }

  // Drone ID → Türkçe görünen isim
  String _droneDisplayName(String id) {
    switch (id) {
      case 'nesne_tespit':
        return 'Nesne Tespit';
      case 'insan_takip':
        return 'İnsan Takibi';
      case 'alan_tarama':
        return 'Alan Tarama';
      case 'kamikaze':
        return 'Kamikaze';
      case 'tasiyici':
        return 'Taşıyıcı';
      default:
        return id;
    }
  }

  // ── FİREBASE STREAM ──────────────────────────────────────────
  void _startListeningToFirebase() {
    _firebaseService!.listenToUavs().listen((data) {
      uavList.assignAll(data);
      if (uavList.isNotEmpty && selectedUavId.value.isEmpty) {
        selectedUavId.value = uavList.containsKey('nesne_tespit')
            ? 'nesne_tespit'
            : uavList.keys.first;
      }
    }, onError: (e) => debugPrint('🚨 Firebase stream hatası: $e'));
  }

  // ── DRONE SEÇ ────────────────────────────────────────────────
  void selectUav(String id) {
    if (uavList.containsKey(id)) selectedUavId.value = id;
  }

  // ── KOMUT GÖNDER ─────────────────────────────────────────────
  void sendCommand(String commandType, {Map<String, dynamic>? extra}) {
    final int level = _accessLevel;
    final String uid = isLinuxDesktop
        ? 'DESKTOP_STATION'
        : (_authOrNull?.currentUid.value ?? '');

    debugPrint('🚁 _accessLevel (fresh): $level');
    debugPrint('🚁 currentUid (fresh): $uid');
    debugPrint(
      '🚁 userAccessLevel (fresh): ${_authOrNull?.userAccessLevel.value ?? 10}',
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

    if (uid.isEmpty) {
      Get.snackbar(
        'YETKİSİZ',
        'Oturum bilgisi alınamadı. Lütfen tekrar giriş yapın.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.withOpacity(0.8),
        colorText: Colors.white,
      );
      return;
    }

    FirestoreLogService().logCommand(
      droneId: selectedUavId.value,
      action: commandType,
      sentByUid: uid,
    );

    if (level >= 3) {
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
      Get.snackbar(
        'YETKİSİZ',
        'Bu işlem için yetki gereklidir. (Seviye: $level)',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  // ── ALAN TARAMA GÖREVİ ───────────────────────────────────────
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
      sentByUid: isLinuxDesktop
          ? 'DESKTOP_STATION'
          : (_authOrNull?.currentUid.value ?? ''),
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

    if (_accessLevel > 1) {
      _firebaseService?.sendTargetLocation(selectedUavId.value, lat, lng);
      Get.snackbar(
        '📍 HEDEF',
        'Konum iletildi: $lat, $lng',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green.withOpacity(0.9),
        colorText: Colors.white,
      );
    } else {
      Get.snackbar('YETKİSİZ', 'Bu işlem için yetki gereklidir.');
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

  // ── ANLIK KONUM RAPORLA ──────────────────────────────────────
  Future<void> sendInstantLocationFor(String droneId) async {
    if (droneId.isEmpty) {
      Get.snackbar('HATA', 'Lütfen bir dron seçin.');
      return;
    }
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm != LocationPermission.always &&
          perm != LocationPermission.whileInUse) {
        Get.snackbar(
          'İZİN REDDEDİLDİ',
          'GPS izni gereklidir.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.withOpacity(0.8),
          colorText: Colors.white,
        );
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final uid = isLinuxDesktop
          ? 'DESKTOP_STATION'
          : (_authOrNull?.currentUid.value ?? '');

      await FirebaseDatabase.instance.ref('instant_locations/$droneId').set({
        'lat': pos.latitude,
        'lon': pos.longitude,
        'accuracy': pos.accuracy,
        'sent_by_uid': uid,
        'timestamp': ServerValue.timestamp,
      });

      assistant.say('${_droneDisplayName(droneId)} anlık konumu gönderildi.');
      Get.snackbar(
        '📍 ANLIK KONUM GÖNDERİLDİ',
        '${_droneDisplayName(droneId)} → '
            '${pos.latitude.toStringAsFixed(6)}, '
            '${pos.longitude.toStringAsFixed(6)}',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green.withOpacity(0.85),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      Get.snackbar(
        'GPS HATASI',
        'Konum alınamadı: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }
}
// uav_controller.dart'ın EN ALTINA koy (mevcut VoiceAssistant class'ını bununla değiştir)

// ── SESLİ ASISTAN ─────────────────────────────────────────────
class VoiceAssistant {
  dynamic _tts;

  VoiceAssistant() {
    _initTts();
  }

  Future<void> _initTts() async {
    if (defaultTargetPlatform == TargetPlatform.linux && !kIsWeb) {
      debugPrint('ℹ️ TTS Linux desteklemiyor, sistem TTS denenecek.');
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
    if (defaultTargetPlatform == TargetPlatform.linux && !kIsWeb) {
      final ok = await speakViaSystem(text);
      if (!ok) {
        debugPrint('🔊 TTS (espeak/spd-say kur): $text');
      }
      return;
    }
    if (_tts == null) {
      debugPrint('🔊 TTS: $text');
      return;
    }
    await _tts.speak(text);
  }

  /// Linux için sistem TTS (espeak veya spd-say)
  Future<bool> speakViaSystem(String text) async {
    try {
      // spd-say dene
      var result = await Process.run('spd-say', [text]);
      if (result.exitCode == 0) return true;

      // espeak dene
      result = await Process.run('espeak', ['-v', 'tr', text]);
      if (result.exitCode == 0) return true;

      return false;
    } catch (_) {
      return false;
    }
  }
}
