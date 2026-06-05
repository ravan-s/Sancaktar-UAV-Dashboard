import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import '../services/firebase_service.dart';
import 'uav_controller.dart';

// ── TARAMA PATTERNİ ───────────────────────────────────────────
enum ScanPattern { zigzag, square, rectangle, triangle }

extension ScanPatternExt on ScanPattern {
  String get label {
    switch (this) {
      case ScanPattern.zigzag:
        return 'Zikzak';
      case ScanPattern.square:
        return 'Kare';
      case ScanPattern.rectangle:
        return 'Dikdörtgen';
      case ScanPattern.triangle:
        return 'Üçgen';
    }
  }

  IconData get icon {
    switch (this) {
      case ScanPattern.zigzag:
        return Icons.show_chart;
      case ScanPattern.square:
        return Icons.crop_square;
      case ScanPattern.rectangle:
        return Icons.crop_landscape;
      case ScanPattern.triangle:
        return Icons.change_history;
    }
  }
}

// ── TARAMA PARAMETRELERİ ──────────────────────────────────────
class ScanConfig {
  final ScanPattern pattern;
  final LatLng center; // Tarama merkezi
  final double widthMeters; // Alan genişliği (metre)
  final double
  heightMeters; // Alan yüksekliği (metre)  [triangle için yükseklik]
  final double altitudeM; // Uçuş irtifası
  final double lineSpacingM; // Zikzak şerit aralığı
  final double speedMs; // Uçuş hızı m/s

  const ScanConfig({
    required this.pattern,
    required this.center,
    this.widthMeters = 200,
    this.heightMeters = 200,
    this.altitudeM = 50,
    this.lineSpacingM = 20,
    this.speedMs = 5,
  });

  ScanConfig copyWith({
    ScanPattern? pattern,
    LatLng? center,
    double? widthMeters,
    double? heightMeters,
    double? altitudeM,
    double? lineSpacingM,
    double? speedMs,
  }) => ScanConfig(
    pattern: pattern ?? this.pattern,
    center: center ?? this.center,
    widthMeters: widthMeters ?? this.widthMeters,
    heightMeters: heightMeters ?? this.heightMeters,
    altitudeM: altitudeM ?? this.altitudeM,
    lineSpacingM: lineSpacingM ?? this.lineSpacingM,
    speedMs: speedMs ?? this.speedMs,
  );
}

// ── CONTROLLER ────────────────────────────────────────────────
class ScanController extends GetxController {
  final _uavCtrl = Get.find<UavController>();
  FirebaseServiceBase? _fb;

  final isScanning = false.obs;
  final previewPoints = <LatLng>[].obs; // Haritada gösterilecek önizleme
  final currentConfig = Rxn<ScanConfig>();

  @override
  void onInit() {
    super.onInit();
    _fb = createFirebaseService();
  }

  // ── ÖNİZLEME ─────────────────────────────────────────────
  void preview(ScanConfig cfg) {
    currentConfig.value = cfg;
    previewPoints.assignAll(_generate(cfg));
  }

  // ── TARAMAYI BAŞLAT ───────────────────────────────────────
  Future<void> startScan(ScanConfig cfg) async {
    final droneId = _uavCtrl.selectedUavId.value;
    if (droneId.isEmpty) {
      Get.snackbar(
        'HATA',
        'Önce bir İHA seçin.',
        backgroundColor: Colors.red.withOpacity(0.6),
        colorText: Colors.white,
      );
      return;
    }

    final waypoints = _generate(cfg);
    if (waypoints.isEmpty) return;

    isScanning.value = true;
    previewPoints.assignAll(waypoints);

    try {
      // Firebase'e tarama görevi yaz
      await _fb?.sendScanMission(
        droneId: droneId,
        pattern: cfg.pattern.name,
        waypoints: waypoints
            .map((p) => {'lat': p.latitude, 'lng': p.longitude})
            .toList(),
        altitude: cfg.altitudeM,
        speed: cfg.speedMs,
      );

      Get.snackbar(
        '🗺 TARAMA BAŞLADI',
        '${waypoints.length} waypoint → $droneId',
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      isScanning.value = false;
      Get.snackbar(
        'HATA',
        'Görev gönderilemedi: $e',
        backgroundColor: Colors.red.withOpacity(0.6),
        colorText: Colors.white,
      );
    }
  }

  void stopScan() {
    isScanning.value = false;
    previewPoints.clear();
    final droneId = _uavCtrl.selectedUavId.value;
    if (droneId.isNotEmpty) {
      _fb?.sendUavCommand(droneId, 'SCAN_ABORT');
    }
  }

  // ── WAYPOINT HESAPLAMA ────────────────────────────────────
  List<LatLng> _generate(ScanConfig cfg) {
    switch (cfg.pattern) {
      case ScanPattern.zigzag:
        return _zigzag(cfg);
      case ScanPattern.square:
        return _square(cfg);
      case ScanPattern.rectangle:
        return _rectangle(cfg);
      case ScanPattern.triangle:
        return _triangle(cfg);
    }
  }

  // Metre → derece (yaklaşık, ekvator dışı için yeterli hassasiyet)
  double _mLat(double meters) => meters / 111320.0;
  double _mLng(double meters, double lat) =>
      meters / (111320.0 * math.cos(lat * math.pi / 180));

  /// ZİKZAK — yatay şeritler, her satır sağa/sola dönüşümlü
  List<LatLng> _zigzag(ScanConfig cfg) {
    final points = <LatLng>[];
    final halfW = cfg.widthMeters / 2;
    final halfH = cfg.heightMeters / 2;
    final lat0 = cfg.center.latitude;
    final lng0 = cfg.center.longitude;
    final rows = (cfg.heightMeters / cfg.lineSpacingM).ceil();

    for (int r = 0; r <= rows; r++) {
      final y = -halfH + r * cfg.lineSpacingM;
      final lat = lat0 + _mLat(y);
      final lngL = lng0 - _mLng(halfW, lat);
      final lngR = lng0 + _mLng(halfW, lat);

      if (r.isEven) {
        points.add(LatLng(lat, lngL));
        points.add(LatLng(lat, lngR));
      } else {
        points.add(LatLng(lat, lngR));
        points.add(LatLng(lat, lngL));
      }
    }
    return points;
  }

  /// KARE — dıştan içe sarmal
  List<LatLng> _square(ScanConfig cfg) {
    final side = math.min(cfg.widthMeters, cfg.heightMeters);
    return _spiralRect(cfg.center, side, side, cfg.lineSpacingM);
  }

  /// DİKDÖRTGEN — dıştan içe sarmal
  List<LatLng> _rectangle(ScanConfig cfg) => _spiralRect(
    cfg.center,
    cfg.widthMeters,
    cfg.heightMeters,
    cfg.lineSpacingM,
  );

  List<LatLng> _spiralRect(LatLng center, double w, double h, double spacing) {
    final points = <LatLng>[];
    double curW = w, curH = h;
    final lat0 = center.latitude;
    final lng0 = center.longitude;

    while (curW > 0 && curH > 0) {
      final hw = curW / 2;
      final hh = curH / 2;
      final lat = lat0;
      final lng = lng0;
      final dlat = _mLat(hh);
      final dlng = _mLng(hw, lat);

      // 4 köşe (saat yönünün tersine)
      points.add(LatLng(lat - dlat, lng - dlng)); // sol-alt
      points.add(LatLng(lat + dlat, lng - dlng)); // sol-üst
      points.add(LatLng(lat + dlat, lng + dlng)); // sağ-üst
      points.add(LatLng(lat - dlat, lng + dlng)); // sağ-alt
      points.add(LatLng(lat - dlat, lng - dlng)); // kapat

      curW -= spacing * 2;
      curH -= spacing * 2;
    }
    return points;
  }

  /// ÜÇGEN — kenarlar boyunca paralel çizgiler
  List<LatLng> _triangle(ScanConfig cfg) {
    final points = <LatLng>[];
    final lat0 = cfg.center.latitude;
    final lng0 = cfg.center.longitude;
    final halfW = cfg.widthMeters / 2;
    final h = cfg.heightMeters;
    final rows = (h / cfg.lineSpacingM).ceil();

    for (int r = 0; r <= rows; r++) {
      final frac = r / rows; // 0 (tepe) → 1 (taban)
      final y = h / 2 - frac * h; // tepe = +h/2, taban = -h/2
      final xHalf = halfW * frac; // tepeden tabana genişler
      final lat = lat0 + _mLat(y);
      final lngL = lng0 - _mLng(xHalf, lat);
      final lngR = lng0 + _mLng(xHalf, lat);

      if (r.isEven) {
        points.add(LatLng(lat, lngL));
        points.add(LatLng(lat, lngR));
      } else {
        points.add(LatLng(lat, lngR));
        points.add(LatLng(lat, lngL));
      }
    }
    return points;
  }
}
