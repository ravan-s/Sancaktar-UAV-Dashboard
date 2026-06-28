// ============================================================
//  SANCAKTAR GCS — Cockpit Instruments  (v2.2 — Düzeltilmiş & Tamamlanmış)
//  Dosya: lib/views/cockpit/cockpit_instruments.dart
//
//  DEĞİŞİKLİKLER v2.2:
//    • Obx tetikleyici satırları düzeltildi (geçersiz `_=` yerine `.length`)
//    • _UavProxy._ctrl erişimi kapsüllendi (proxy.droneId getter eklendi)
//    • _drawLabel labelR==0 merkez mantığı düzeltildi
//    • _TopBar artık proxy.droneId kullanıyor (doğrudan _ctrl erişimi yok)
//    • Tüm CustomPainter'larda shouldRepaint iyileştirildi
//    • Kod tutarlılığı ve null-safety iyileştirmeleri
// ============================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/uav_controller.dart';
import '../../models/uav_model.dart';

// ── Sancaktar renk paleti ──────────────────────────────────
class _C {
  static const bg = Color(0xFF030A12);
  static const panel = Color(0xFF0A1118);
  static const bezel = Color(0xFF141E2A);
  static const rim = Color(0xFF1E2D3D);
  static const cyan = Color(0xFF00E5FF);
  static const red = Color(0xFFE53935);
  static const amber = Color(0xFFFFB300);
  static const green = Color(0xFF00E676);
  static const white = Color(0xFFECEFF1);
  static const grey = Color(0xFF546E7A);
  static const dimText = Color(0xFF37474F);
  static const skyBlue = Color(0xFF1565C0);
  static const earth = Color(0xFF4E342E);
}

// ── Controller erişim helper'ı ─────────────────────────────
class _UavProxy {
  final UavController _ctrl;
  _UavProxy(this._ctrl);

  UavModel? get _uav => _ctrl.currentUav;

  // Drone kimliği (TopBar için)
  String get droneId =>
      _ctrl.selectedUavId.value.toUpperCase().replaceAll('_', ' ');

  // Telemetri
  double get airspeed => _uav?.speed ?? 0;
  double get altitude => _uav?.altitude ?? 0;
  double get verticalSpeed => _uav?.verticalSpeed ?? 0;

  // Attitude
  double get roll => _uav?.roll ?? 0;
  double get pitch => _uav?.pitch ?? 0;
  double get heading => _uav?.heading ?? 0;

  // Pil
  int get battery => _uav?.battery ?? 0;
  double get batteryVolt => _uav?.battery_volt ?? 0;

  // Status
  String get flightMode => _uav?.flightMode ?? 'UNKNOWN';
  bool get armed => _uav?.isArmed ?? false;
  int get gpsFix => _uav?.gps_fix ?? 0;
  double? get lat => _uav?.lat;
  double? get lon => _uav?.lon;
  int get connStrength => _uav?.connectionStrength ?? 0;
}

// ════════════════════════════════════════════════════════════
//  ANA SAYFA
// ════════════════════════════════════════════════════════════
class CockpitScreen extends StatelessWidget {
  const CockpitScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<UavController>();
    final proxy = _UavProxy(ctrl);

    return Obx(() {
      // Reactive değerlere dokunarak Obx'i Firebase güncellemelerine abone ediyoruz
      ctrl.uavList.length; // RxList için .length reactive'dir
      ctrl.selectedUavId.value; // RxString için .value reactive'dir

      return Scaffold(
        backgroundColor: _C.bg,
        body: Column(
          children: [
            _TopBar(proxy: proxy),
            Expanded(child: _CockpitBody(proxy: proxy)),
            _StatusBar(proxy: proxy),
          ],
        ),
      );
    });
  }
}

// ── Üst bar ───────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final _UavProxy proxy;
  const _TopBar({required this.proxy, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: const BoxDecoration(
        color: _C.panel,
        border: Border(bottom: BorderSide(color: _C.rim, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          const Icon(Icons.radar, color: _C.cyan, size: 18),
          const SizedBox(width: 8),
          const Text(
            'SANCAKTAR GCS',
            style: TextStyle(
              color: _C.white,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            '· COCKPIT',
            style: TextStyle(color: _C.grey, fontSize: 11, letterSpacing: 2),
          ),
          const Spacer(),
          _pill(proxy.droneId, _C.amber),
          const SizedBox(width: 8),
          _pill('COCKPIT', _C.cyan),
          const SizedBox(width: 8),
          _pill('v2.2', _C.grey),
        ],
      ),
    );
  }

  Widget _pill(String t, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      border: Border.all(color: c.withOpacity(0.4)),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(t, style: TextStyle(color: c, fontSize: 9, letterSpacing: 1)),
  );
}

// ── Ana cockpit grid ──────────────────────────────────────
class _CockpitBody extends StatelessWidget {
  final _UavProxy proxy;
  const _CockpitBody({required this.proxy, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _InstrumentCard(
                    label: 'HIZ · AIRSPEED',
                    child: AirspeedIndicator(speedMs: proxy.airspeed),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _InstrumentCard(
                    label: 'ATİTÜD · YAPAY UFUK',
                    child: AttitudeIndicator(
                      rollDeg: proxy.roll,
                      pitchDeg: proxy.pitch,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _InstrumentCard(
                    label: 'İRTİFA · ALTIMETER',
                    child: AltimeterIndicator(altitudeM: proxy.altitude),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _InstrumentCard(
                    label: 'RULO · YAW',
                    child: YawIndicator(
                      rollDeg: proxy.roll,
                      battery: proxy.battery,
                      batteryVolt: proxy.batteryVolt,
                      armed: proxy.armed,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _InstrumentCard(
                    label: 'PUSULA · HEADING',
                    child: HeadingIndicator(
                      headingDeg: proxy.heading,
                      gpsFix: proxy.gpsFix,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _InstrumentCard(
                    label: 'DİKEY HIZ · VSI',
                    child: VSIIndicator(vspeedMs: proxy.verticalSpeed),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Instrument kart çerçevesi ─────────────────────────────
class _InstrumentCard extends StatelessWidget {
  final String label;
  final Widget child;
  const _InstrumentCard({required this.label, required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _C.bezel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.rim, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _C.cyan.withOpacity(0.04),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              label,
              style: const TextStyle(
                color: _C.grey,
                fontSize: 9,
                letterSpacing: 1.5,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: LayoutBuilder(
                builder: (_, c) {
                  final size = math.min(c.maxWidth, c.maxHeight);
                  return Center(
                    child: SizedBox(width: size, height: size, child: child),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Alt durum çubuğu ─────────────────────────────────────
class _StatusBar extends StatelessWidget {
  final _UavProxy proxy;
  const _StatusBar({required this.proxy, super.key});

  @override
  Widget build(BuildContext context) {
    final batColor = proxy.battery > 50
        ? _C.green
        : proxy.battery > 20
        ? _C.amber
        : _C.red;

    return Container(
      height: 36,
      decoration: const BoxDecoration(
        color: _C.panel,
        border: Border(top: BorderSide(color: _C.rim, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _item('MOD', proxy.flightMode),
          _item('PİL', '%${proxy.battery}', valueColor: batColor),
          if (proxy.batteryVolt > 0)
            _item(
              'VOLT',
              '${proxy.batteryVolt.toStringAsFixed(1)}V',
              valueColor: batColor,
            ),
          _item('İRTİFA', '${proxy.altitude.toStringAsFixed(1)}m'),
          _item('HIZ', '${proxy.airspeed.toStringAsFixed(1)}m/s'),
          _item(
            'VSI',
            '${proxy.verticalSpeed > 0 ? '+' : ''}${proxy.verticalSpeed.toStringAsFixed(1)}m/s',
          ),
          _item(
            'GPS',
            proxy.gpsFix == 3 ? '3D FIX' : 'NO FIX',
            valueColor: proxy.gpsFix == 3 ? _C.green : _C.red,
          ),
          const Spacer(),
          _item('SAT', '${proxy.connStrength}', valueColor: _C.cyan),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: proxy.armed
                  ? _C.red.withOpacity(0.2)
                  : _C.green.withOpacity(0.1),
              border: Border.all(
                color: proxy.armed ? _C.red : _C.green,
                width: 0.5,
              ),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              proxy.armed ? '⬤ ARMED' : '◌ DISARMED',
              style: TextStyle(
                color: proxy.armed ? _C.red : _C.green,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _item(String l, String v, {Color? valueColor}) => Padding(
    padding: const EdgeInsets.only(right: 16),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$l: ', style: const TextStyle(color: _C.grey, fontSize: 10)),
        Text(
          v,
          style: TextStyle(
            color: valueColor ?? _C.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

// ════════════════════════════════════════════════════════════
//  1. AIR SPEED INDICATOR
// ════════════════════════════════════════════════════════════
class AirspeedIndicator extends StatelessWidget {
  final double speedMs;
  const AirspeedIndicator({required this.speedMs, super.key});

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _AirspeedPainter(speedMs),
    child: const SizedBox.expand(),
  );
}

class _AirspeedPainter extends CustomPainter {
  final double speed;
  _AirspeedPainter(this.speed);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    canvas.drawCircle(c, r, Paint()..color = const Color(0xFF0D1A27));
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = _C.rim
        ..strokeWidth = 3,
    );
    canvas.drawCircle(
      c,
      r * 0.9,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = _C.dimText.withOpacity(0.4)
        ..strokeWidth = 0.5,
    );

    // Renkli hız bölgeleri
    _drawArc(
      canvas,
      c,
      r * 0.88,
      10,
      25,
      0,
      40,
      Paint()
        ..color = _C.green
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.butt,
    );
    _drawArc(
      canvas,
      c,
      r * 0.88,
      25,
      35,
      0,
      40,
      Paint()
        ..color = _C.amber
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.butt,
    );
    _drawArc(
      canvas,
      c,
      r * 0.88,
      35,
      40,
      0,
      40,
      Paint()
        ..color = _C.red
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.butt,
    );

    // Tik işaretleri ve etiketler
    for (int i = 0; i <= 40; i += 5) {
      final angle = _speedToAngle(i.toDouble(), 0, 40);
      final isMajor = i % 10 == 0;
      _drawTick(
        canvas,
        c,
        r,
        angle,
        isMajor ? 0.14 : 0.08,
        isMajor ? 1.5 : 0.8,
        _C.white,
      );
      if (isMajor) {
        _drawLabel(
          canvas,
          c,
          r * 0.68,
          angle,
          '$i',
          TextStyle(
            color: _C.white,
            fontSize: r * 0.1,
            fontWeight: FontWeight.bold,
          ),
        );
      }
    }

    // İbre
    final needleAngle = _speedToAngle(speed.clamp(0, 40), 0, 40);
    _drawNeedle(canvas, c, r * 0.72, needleAngle, _C.white, r * 0.025);
    _drawValueBox(canvas, c, r, speed.toStringAsFixed(1), 'm/s', _C.cyan);

    canvas.drawCircle(c, r * 0.06, Paint()..color = _C.rim);
    canvas.drawCircle(c, r * 0.04, Paint()..color = _C.white);
  }

  double _speedToAngle(double v, double min, double max) =>
      (v - min) / (max - min) * 270 - 135;

  void _drawArc(
    Canvas canvas,
    Offset c,
    double r,
    double from,
    double to,
    double arcFrom,
    double arcMax,
    Paint p,
  ) {
    final startAngle =
        _speedToAngle(from, arcFrom, arcMax) * math.pi / 180 + math.pi / 2;
    final sweepAngle =
        (_speedToAngle(to, arcFrom, arcMax) -
            _speedToAngle(from, arcFrom, arcMax)) *
        math.pi /
        180;
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      startAngle,
      sweepAngle,
      false,
      p,
    );
  }

  @override
  bool shouldRepaint(_AirspeedPainter old) => old.speed != speed;
}

// ════════════════════════════════════════════════════════════
//  2. ATTITUDE INDICATOR (Yapay Ufuk)
// ════════════════════════════════════════════════════════════
class AttitudeIndicator extends StatelessWidget {
  final double rollDeg;
  final double pitchDeg;
  const AttitudeIndicator({
    required this.rollDeg,
    required this.pitchDeg,
    super.key,
  });

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _AttitudePainter(rollDeg, pitchDeg),
    child: const SizedBox.expand(),
  );
}

class _AttitudePainter extends CustomPainter {
  final double roll;
  final double pitch;
  _AttitudePainter(this.roll, this.pitch);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: c, radius: r * 0.92)),
    );

    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(roll * math.pi / 180);

    final pitchOffset = pitch * r * 0.04;

    canvas.drawRect(
      Rect.fromLTRB(-r, -r * 2 + pitchOffset, r, pitchOffset),
      Paint()..color = _C.skyBlue,
    );
    canvas.drawRect(
      Rect.fromLTRB(-r, pitchOffset, r, r * 2),
      Paint()..color = _C.earth,
    );
    canvas.drawLine(
      Offset(-r, pitchOffset),
      Offset(r, pitchOffset),
      Paint()
        ..color = _C.white
        ..strokeWidth = 1.5,
    );

    // Pitch tik çizgileri
    for (int deg = -30; deg <= 30; deg += 5) {
      if (deg == 0) continue;
      final y = pitchOffset - deg * r * 0.04;
      final halfW = (deg % 10 == 0) ? r * 0.28 : r * 0.16;
      canvas.drawLine(
        Offset(-halfW, y),
        Offset(halfW, y),
        Paint()
          ..color = _C.white.withOpacity(0.7)
          ..strokeWidth = 0.8,
      );
      if (deg % 10 == 0) {
        _drawTextCentered(
          canvas,
          Offset(-halfW - r * 0.1, y),
          '${deg.abs()}',
          TextStyle(color: _C.white, fontSize: r * 0.1),
        );
      }
    }
    canvas.restore();

    // Roll ölçeği (dış ring, sabit)
    for (int angle in [-60, -45, -30, -20, -10, 0, 10, 20, 30, 45, 60]) {
      final a = (angle - 90) * math.pi / 180;
      final isMajor = angle % 30 == 0;
      final len = isMajor ? r * 0.1 : r * 0.06;
      canvas.drawLine(
        Offset(c.dx + r * 0.92 * math.cos(a), c.dy + r * 0.92 * math.sin(a)),
        Offset(
          c.dx + (r * 0.92 - len) * math.cos(a),
          c.dy + (r * 0.92 - len) * math.sin(a),
        ),
        Paint()
          ..color = _C.white
          ..strokeWidth = isMajor ? 1.5 : 0.8,
      );
    }

    // Roll pointer (üçgen)
    final rollRad = (roll - 90) * math.pi / 180;
    final tri = Path();
    tri.moveTo(
      c.dx + r * 0.85 * math.cos(rollRad),
      c.dy + r * 0.85 * math.sin(rollRad),
    );
    tri.lineTo(
      c.dx + r * 0.78 * math.cos(rollRad - 0.08),
      c.dy + r * 0.78 * math.sin(rollRad - 0.08),
    );
    tri.lineTo(
      c.dx + r * 0.78 * math.cos(rollRad + 0.08),
      c.dy + r * 0.78 * math.sin(rollRad + 0.08),
    );
    tri.close();
    canvas.drawPath(tri, Paint()..color = _C.amber);

    // Uçak silueti
    final planePaint = Paint()
      ..color = _C.amber
      ..strokeWidth = r * 0.035
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(c.dx - r * 0.38, c.dy),
      Offset(c.dx - r * 0.15, c.dy),
      planePaint,
    );
    canvas.drawLine(
      Offset(c.dx + r * 0.15, c.dy),
      Offset(c.dx + r * 0.38, c.dy),
      planePaint,
    );
    canvas.drawLine(
      Offset(c.dx - r * 0.06, c.dy),
      Offset(c.dx + r * 0.06, c.dy),
      planePaint,
    );
    canvas.drawCircle(c, r * 0.035, Paint()..color = _C.amber);

    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = _C.rim
        ..strokeWidth = 3,
    );
  }

  void _drawTextCentered(
    Canvas canvas,
    Offset pos,
    String text,
    TextStyle style,
  ) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(_AttitudePainter old) =>
      old.roll != roll || old.pitch != pitch;
}

// ════════════════════════════════════════════════════════════
//  3. ALTIMETER
// ════════════════════════════════════════════════════════════
class AltimeterIndicator extends StatelessWidget {
  final double altitudeM;
  const AltimeterIndicator({required this.altitudeM, super.key});

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _AltimeterPainter(altitudeM),
    child: const SizedBox.expand(),
  );
}

class _AltimeterPainter extends CustomPainter {
  final double alt;
  _AltimeterPainter(this.alt);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    canvas.drawCircle(c, r, Paint()..color = const Color(0xFF0D1A27));
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = _C.rim
        ..strokeWidth = 3,
    );

    final needle100 = (alt % 1000) / 1000 * 360 - 90;
    final needle1000 = (alt % 10000) / 10000 * 360 - 90;

    for (int i = 0; i < 10; i++) {
      final angle = i / 10 * 360 - 90;
      final isMajor = i % 5 == 0;
      _drawTick(
        canvas,
        c,
        r,
        angle,
        isMajor ? 0.14 : 0.08,
        isMajor ? 1.5 : 0.8,
        _C.white,
      );
      if (isMajor || i % 2 == 0) {
        _drawLabel(
          canvas,
          c,
          r * 0.72,
          angle,
          '${i * 100}',
          TextStyle(color: _C.white, fontSize: r * 0.09),
        );
      }
    }

    // 1000m ibresi (geniş, soluk)
    _drawNeedle(
      canvas,
      c,
      r * 0.48,
      needle1000,
      _C.white.withOpacity(0.6),
      r * 0.018,
      wide: true,
    );
    // 100m ibresi (ince, parlak)
    _drawNeedle(canvas, c, r * 0.72, needle100, _C.white, r * 0.025);
    _drawValueBox(canvas, c, r, alt.toStringAsFixed(0), 'm', _C.amber);

    canvas.drawCircle(c, r * 0.06, Paint()..color = _C.rim);
    canvas.drawCircle(c, r * 0.04, Paint()..color = _C.white);
  }

  @override
  bool shouldRepaint(_AltimeterPainter old) => old.alt != alt;
}

// ════════════════════════════════════════════════════════════
//  4. YAW / ROLL INDICATOR — Batarya volt + yüzde
// ════════════════════════════════════════════════════════════
class YawIndicator extends StatelessWidget {
  final double rollDeg;
  final int battery;
  final double batteryVolt;
  final bool armed;
  const YawIndicator({
    required this.rollDeg,
    required this.battery,
    required this.batteryVolt,
    required this.armed,
    super.key,
  });

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _YawPainter(rollDeg, battery, batteryVolt, armed),
    child: const SizedBox.expand(),
  );
}

class _YawPainter extends CustomPainter {
  final double roll;
  final int battery;
  final double batteryVolt;
  final bool armed;
  _YawPainter(this.roll, this.battery, this.batteryVolt, this.armed);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    canvas.drawCircle(c, r, Paint()..color = const Color(0xFF0D1A27));
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = _C.rim
        ..strokeWidth = 3,
    );

    // Roll tik çemberi
    for (int i = -180; i < 180; i += 10) {
      final angle = (i - 90) * math.pi / 180;
      final isMajor = i % 30 == 0;
      final len = isMajor ? r * 0.12 : r * 0.06;
      canvas.drawLine(
        Offset(
          c.dx + r * 0.88 * math.cos(angle),
          c.dy + r * 0.88 * math.sin(angle),
        ),
        Offset(
          c.dx + (r * 0.88 - len) * math.cos(angle),
          c.dy + (r * 0.88 - len) * math.sin(angle),
        ),
        Paint()
          ..color = isMajor ? _C.white : _C.grey
          ..strokeWidth = isMajor ? 1.5 : 0.7,
      );
      if (isMajor) {
        _drawLabel(
          canvas,
          c,
          r * 0.72,
          i.toDouble() - 90,
          '${i.abs()}',
          TextStyle(color: _C.grey, fontSize: r * 0.08),
        );
      }
    }

    // Roll pointer (üçgen)
    final rollRad = (roll - 90) * math.pi / 180;
    final tri = Path();
    tri.moveTo(
      c.dx + r * 0.82 * math.cos(rollRad),
      c.dy + r * 0.82 * math.sin(rollRad),
    );
    tri.lineTo(
      c.dx + r * 0.74 * math.cos(rollRad - 0.07),
      c.dy + r * 0.74 * math.sin(rollRad - 0.07),
    );
    tri.lineTo(
      c.dx + r * 0.74 * math.cos(rollRad + 0.07),
      c.dy + r * 0.74 * math.sin(rollRad + 0.07),
    );
    tri.close();
    canvas.drawPath(tri, Paint()..color = _C.cyan);

    // Drone silueti
    _drawDroneSilhouette(canvas, c, r * 0.36);

    // Batarya arc
    final batColor = battery > 50
        ? _C.green
        : battery > 20
        ? _C.amber
        : _C.red;
    final batAngle = battery / 100 * 2 * math.pi;

    // Arka plan (gri tam çember)
    canvas.drawCircle(
      c,
      r * 0.92,
      Paint()
        ..color = _C.dimText.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5,
    );
    // Dolu kısım
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r * 0.92),
      -math.pi / 2,
      batAngle,
      false,
      Paint()
        ..color = batColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );

    // Armed / Disarmed etiketi
    _drawCenteredText(
      canvas,
      Offset(c.dx, c.dy - r * 0.28),
      armed ? 'ARMED' : 'DISARMED',
      TextStyle(
        color: armed ? _C.red : _C.green,
        fontSize: r * 0.11,
        fontWeight: FontWeight.bold,
      ),
    );

    // Batarya yüzde
    _drawCenteredText(
      canvas,
      Offset(c.dx, c.dy + r * 0.44),
      '%$battery',
      TextStyle(
        color: batColor,
        fontSize: r * 0.14,
        fontWeight: FontWeight.bold,
      ),
    );

    // Volt değeri (varsa)
    if (batteryVolt > 0) {
      _drawCenteredText(
        canvas,
        Offset(c.dx, c.dy + r * 0.60),
        '${batteryVolt.toStringAsFixed(1)}V',
        TextStyle(color: batColor.withOpacity(0.8), fontSize: r * 0.10),
      );
    }
  }

  /// Merkeze hizalı metin çizer
  void _drawCenteredText(
    Canvas canvas,
    Offset center,
    String text,
    TextStyle style,
  ) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(center.dx - tp.width / 2, center.dy - tp.height / 2),
    );
  }

  void _drawDroneSilhouette(Canvas canvas, Offset c, double r) {
    final p = Paint()
      ..color = _C.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.07
      ..strokeCap = StrokeCap.round;
    final pb = Paint()
      ..color = _C.white
      ..style = PaintingStyle.fill;

    // Gövde
    canvas.drawRect(
      Rect.fromCenter(center: c, width: r * 0.5, height: r * 0.2),
      pb,
    );

    // Kollar ve motorlar
    final arms = [
      [Offset(-0.55, -0.55), Offset(-0.9, -0.9)],
      [Offset(0.55, -0.55), Offset(0.9, -0.9)],
      [Offset(-0.55, 0.55), Offset(-0.9, 0.9)],
      [Offset(0.55, 0.55), Offset(0.9, 0.9)],
    ];
    for (final arm in arms) {
      canvas.drawLine(
        Offset(c.dx + arm[0].dx * r, c.dy + arm[0].dy * r),
        Offset(c.dx + arm[1].dx * r, c.dy + arm[1].dy * r),
        p,
      );
      canvas.drawCircle(
        Offset(c.dx + arm[1].dx * r, c.dy + arm[1].dy * r),
        r * 0.18,
        Paint()
          ..color = _C.rim
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.05,
      );
    }
  }

  @override
  bool shouldRepaint(_YawPainter old) =>
      old.roll != roll ||
      old.battery != battery ||
      old.batteryVolt != batteryVolt ||
      old.armed != armed;
}

// ════════════════════════════════════════════════════════════
//  5. HEADING INDICATOR (Pusula)
// ════════════════════════════════════════════════════════════
class HeadingIndicator extends StatelessWidget {
  final double headingDeg;
  final int gpsFix;
  const HeadingIndicator({
    required this.headingDeg,
    required this.gpsFix,
    super.key,
  });

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _HeadingPainter(headingDeg, gpsFix),
    child: const SizedBox.expand(),
  );
}

class _HeadingPainter extends CustomPainter {
  final double heading;
  final int gpsFix;
  _HeadingPainter(this.heading, this.gpsFix);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    canvas.drawCircle(c, r, Paint()..color = const Color(0xFF0D1A27));
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = _C.rim
        ..strokeWidth = 3,
    );

    // Dönen kadran
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(-heading * math.pi / 180);

    const dirs = {'N': 0.0, 'E': 90.0, 'S': 180.0, 'W': 270.0};
    for (final d in dirs.entries) {
      final a = (d.value - 90) * math.pi / 180;
      _drawTextCenteredLocal(
        canvas,
        Offset(r * 0.7 * math.cos(a), r * 0.7 * math.sin(a)),
        d.key,
        TextStyle(
          color: d.key == 'N' ? _C.red : _C.white,
          fontSize: r * 0.14,
          fontWeight: FontWeight.w900,
        ),
      );
    }

    for (int i = 0; i < 36; i++) {
      final angle = (i * 10 - 90) * math.pi / 180;
      final isMajor = i % 3 == 0;
      final len = isMajor ? r * 0.12 : r * 0.06;
      canvas.drawLine(
        Offset(r * 0.88 * math.cos(angle), r * 0.88 * math.sin(angle)),
        Offset(
          (r * 0.88 - len) * math.cos(angle),
          (r * 0.88 - len) * math.sin(angle),
        ),
        Paint()
          ..color = isMajor ? _C.white : _C.grey
          ..strokeWidth = isMajor ? 1.5 : 0.7,
      );
      // Ana yönler dışındaki her 60° de sayı yaz
      if (isMajor && i % 6 == 0 && i != 0 && !dirs.values.contains(i * 10.0)) {
        _drawTextCenteredLocal(
          canvas,
          Offset(r * 0.72 * math.cos(angle), r * 0.72 * math.sin(angle)),
          '${i * 10}',
          TextStyle(color: _C.grey, fontSize: r * 0.09),
        );
      }
    }
    canvas.restore();

    // Sabit işaretçi üçgeni (yukarı)
    final tri = Path();
    tri.moveTo(c.dx, c.dy - r * 0.82);
    tri.lineTo(c.dx - r * 0.05, c.dy - r * 0.7);
    tri.lineTo(c.dx + r * 0.05, c.dy - r * 0.7);
    tri.close();
    canvas.drawPath(tri, Paint()..color = _C.cyan);

    _drawValueBox(canvas, c, r, '${heading.toStringAsFixed(0)}°', '', _C.cyan);

    // GPS fix durumu
    final gpsColor = gpsFix == 3 ? _C.green : _C.red;
    final gpsTp = TextPainter(
      text: TextSpan(
        text: gpsFix == 3 ? '⬤ 3D FIX' : '◌ NO FIX',
        style: TextStyle(color: gpsColor, fontSize: r * 0.1),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    gpsTp.paint(canvas, Offset(c.dx - gpsTp.width / 2, c.dy + r * 0.5));

    canvas.drawCircle(c, r * 0.06, Paint()..color = _C.rim);
    canvas.drawCircle(c, r * 0.04, Paint()..color = _C.cyan);
  }

  void _drawTextCenteredLocal(
    Canvas canvas,
    Offset pos,
    String text,
    TextStyle style,
  ) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(_HeadingPainter old) =>
      old.heading != heading || old.gpsFix != gpsFix;
}

// ════════════════════════════════════════════════════════════
//  6. VERTICAL SPEED INDICATOR (VSI)
// ════════════════════════════════════════════════════════════
class VSIIndicator extends StatelessWidget {
  final double vspeedMs;
  const VSIIndicator({required this.vspeedMs, super.key});

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _VSIPainter(vspeedMs),
    child: const SizedBox.expand(),
  );
}

class _VSIPainter extends CustomPainter {
  final double vs;
  _VSIPainter(this.vs);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    canvas.drawCircle(c, r, Paint()..color = const Color(0xFF0D1A27));
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = _C.rim
        ..strokeWidth = 3,
    );

    const maxVs = 10.0;
    for (int v = -10; v <= 10; v += 2) {
      final angle = v / maxVs * 135 - 90;
      final isMajor = v % 5 == 0;
      _drawTick(
        canvas,
        c,
        r,
        angle,
        isMajor ? 0.14 : 0.08,
        isMajor ? 1.5 : 0.8,
        _C.white,
      );
      if (isMajor) {
        _drawLabel(
          canvas,
          c,
          r * 0.7,
          angle,
          '${v > 0 ? '+' : ''}$v',
          TextStyle(
            color: v > 0
                ? _C.green
                : v < 0
                ? _C.red
                : _C.white,
            fontSize: r * 0.1,
            fontWeight: FontWeight.bold,
          ),
        );
      }
    }

    // Yatay referans çizgisi (0 m/s)
    canvas.drawLine(
      Offset(c.dx - r * 0.3, c.dy),
      Offset(c.dx + r * 0.3, c.dy),
      Paint()
        ..color = _C.white.withOpacity(0.3)
        ..strokeWidth = 0.5,
    );

    final clamped = vs.clamp(-maxVs, maxVs);
    final needleAngle = clamped / maxVs * 135 - 90;
    final needleColor = vs > 0
        ? _C.green
        : vs < 0
        ? _C.red
        : _C.white;

    _drawNeedle(canvas, c, r * 0.72, needleAngle, needleColor, r * 0.025);
    _drawValueBox(
      canvas,
      c,
      r,
      '${vs > 0 ? '+' : ''}${vs.toStringAsFixed(1)}',
      'm/s',
      needleColor,
    );

    // ÇIKMA / ALÇALMA etiketleri
    _drawLabel(
      canvas,
      c,
      r * 0.5,
      -120,
      'ÇIKMA',
      TextStyle(color: _C.green.withOpacity(0.7), fontSize: r * 0.09),
    );
    _drawLabel(
      canvas,
      c,
      r * 0.5,
      120,
      'ALÇALMA',
      TextStyle(color: _C.red.withOpacity(0.7), fontSize: r * 0.09),
    );

    canvas.drawCircle(c, r * 0.06, Paint()..color = _C.rim);
    canvas.drawCircle(c, r * 0.04, Paint()..color = needleColor);
  }

  @override
  bool shouldRepaint(_VSIPainter old) => old.vs != vs;
}

// ════════════════════════════════════════════════════════════
//  SHARED PAINT HELPERS
// ════════════════════════════════════════════════════════════

/// Daire üzerinde tik çizer (açı: derece cinsinden, 0° = saat 12)
void _drawTick(
  Canvas canvas,
  Offset c,
  double r,
  double angleDeg,
  double lengthRatio,
  double strokeWidth,
  Color color,
) {
  final a = (angleDeg - 90) * math.pi / 180;
  canvas.drawLine(
    Offset(c.dx + r * 0.92 * math.cos(a), c.dy + r * 0.92 * math.sin(a)),
    Offset(
      c.dx + r * (0.92 - lengthRatio) * math.cos(a),
      c.dy + r * (0.92 - lengthRatio) * math.sin(a),
    ),
    Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt,
  );
}

/// Belirtilen yarıçap ve açıda ortalanmış metin çizer.
/// [labelR] == 0 ise merkeze yazar.
void _drawLabel(
  Canvas canvas,
  Offset c,
  double labelR,
  double angleDeg,
  String text,
  TextStyle style,
) {
  final Offset pos;
  if (labelR == 0) {
    pos = c; // Merkez
  } else {
    final a = (angleDeg - 90) * math.pi / 180;
    pos = Offset(c.dx + labelR * math.cos(a), c.dy + labelR * math.sin(a));
  }

  final tp = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
}

/// İbre çizer. [wide]=true ise dolgulu üçgen şeklinde.
void _drawNeedle(
  Canvas canvas,
  Offset c,
  double length,
  double angleDeg,
  Color color,
  double width, {
  bool wide = false,
}) {
  final a = (angleDeg - 90) * math.pi / 180;
  final tip = Offset(c.dx + length * math.cos(a), c.dy + length * math.sin(a));
  final tail = Offset(
    c.dx - length * 0.2 * math.cos(a),
    c.dy - length * 0.2 * math.sin(a),
  );

  if (wide) {
    final path = Path();
    final perp = a + math.pi / 2;
    path.moveTo(
      c.dx + width * 1.5 * math.cos(perp),
      c.dy + width * 1.5 * math.sin(perp),
    );
    path.lineTo(tip.dx, tip.dy);
    path.lineTo(
      c.dx - width * 1.5 * math.cos(perp),
      c.dy - width * 1.5 * math.sin(perp),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withOpacity(0.6)
        ..style = PaintingStyle.fill,
    );
  } else {
    canvas.drawLine(
      tail,
      tip,
      Paint()
        ..color = color
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round,
    );
  }
}

/// Enstrüman ortasına değer kutucuğu çizer.
void _drawValueBox(
  Canvas canvas,
  Offset c,
  double r,
  String value,
  String unit,
  Color color,
) {
  final rrect = RRect.fromRectAndRadius(
    Rect.fromCenter(
      center: Offset(c.dx, c.dy + r * 0.32),
      width: r * 0.75,
      height: r * 0.22,
    ),
    const Radius.circular(4),
  );
  canvas.drawRRect(rrect, Paint()..color = const Color(0xA6000000));
  canvas.drawRRect(
    rrect,
    Paint()
      ..color = color.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8,
  );

  final valTp = TextPainter(
    text: TextSpan(
      children: [
        TextSpan(
          text: value,
          style: TextStyle(
            color: color,
            fontSize: r * 0.13,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
        if (unit.isNotEmpty)
          TextSpan(
            text: ' $unit',
            style: TextStyle(color: color.withOpacity(0.7), fontSize: r * 0.08),
          ),
      ],
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  valTp.paint(
    canvas,
    Offset(c.dx - valTp.width / 2, c.dy + r * 0.32 - valTp.height / 2),
  );
}
