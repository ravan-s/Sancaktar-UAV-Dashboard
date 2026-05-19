// ============================================================
//  SANCAKTAR GCS — Cockpit Instruments
//  Dosya: lib/views/cockpit/cockpit_instruments.dart
//
//  Kullanım:
//    import 'cockpit_instruments.dart';
//    CockpitScreen()  →  tam sayfa cockpit
//
//  Gereksinimler (pubspec.yaml):
//    get: ^4.x
//  UavModel alanları kullanılanlar:
//    speed, altitude, battery, flightMode,
//    roll, pitch, heading, verticalSpeed, airspeed
//    (yoksa 0.0 / '-' ile fallback)
// ============================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/uav_model.dart'; // ← path'ini ayarla

// ── Sancaktar renk paleti ──────────────────────────────────
class _C {
  static const bg       = Color(0xFF030A12);
  static const panel    = Color(0xFF0A1118);
  static const bezel    = Color(0xFF141E2A);
  static const rim      = Color(0xFF1E2D3D);
  static const cyan     = Color(0xFF00E5FF);
  static const red      = Color(0xFFE53935);
  static const amber    = Color(0xFFFFB300);
  static const green    = Color(0xFF00E676);
  static const white    = Color(0xFFECEFF1);
  static const grey     = Color(0xFF546E7A);
  static const dimText  = Color(0xFF37474F);
  static const skyBlue  = Color(0xFF1565C0);
  static const earth    = Color(0xFF4E342E);
}

// ── Controller erişim helper'ı ────────────────────────────
// UavModel alanlarına direkt erişir (toJson gerekmez).
// roll / pitch / heading / verticalSpeed UavModel'de yoksa 0 döner.
class _UavProxy {
  final dynamic _ctrl;
  _UavProxy(this._ctrl);

  UavModel? get _uav {
    try { return _ctrl.currentUav as UavModel?; } catch (_) { return null; }
  }

  // UavModel'inde olan alanlar — direkt erişim
  double get airspeed      => _uav?.speed      ?? 0;
  double get altitude      => _uav?.altitude   ?? 0;
  int    get battery       => _uav?.battery    ?? 0;
  double get batteryVolt   => _uav?.battery_volt ?? 0;
  String get flightMode    => _uav?.flightMode ?? 'UNKNOWN';
  bool   get armed         => _uav?.isArmed    ?? false;
  int    get gpsFix        => _uav?.gps_fix    ?? 0;
  double? get lat          => _uav?.lat;
  double? get lon          => _uav?.lon;
  int    get connStrength  => _uav?.connectionStrength ?? 0;

  // UavModel'inde YOK — MAVLink geldiğinde ekleyebilirsin, şimdilik 0
  // (Pixhawk bunları da ATTITUDE mesajıyla yollar)
  double get roll          => 0;
  double get pitch         => 0;
  double get heading       => 0;
  double get verticalSpeed => 0;
}

// ════════════════════════════════════════════════════════════
//  ANA SAYFA
// ════════════════════════════════════════════════════════════
class CockpitScreen extends StatelessWidget {
  const CockpitScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // GetX controller'ını bul; bulamazsa boş proxy
    dynamic ctrl;
    try { ctrl = Get.find(); } catch (_) {}
    final proxy = _UavProxy(ctrl);

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
          const Text('SANCAKTAR GCS',
              style: TextStyle(color: _C.white, fontWeight: FontWeight.w900,
                  letterSpacing: 3, fontSize: 13)),
          const SizedBox(width: 4),
          const Text('· COCKPIT',
              style: TextStyle(color: _C.grey, fontSize: 11, letterSpacing: 2)),
          const Spacer(),
          _pill('COCKPIT', _C.cyan),
          const SizedBox(width: 8),
          _pill('v2.0', _C.grey),
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
                Expanded(child: _InstrumentCard(
                  label: 'HIZ · AIRSPEED',
                  child: AirspeedIndicator(speedKnots: proxy.airspeed),
                )),
                const SizedBox(width: 10),
                Expanded(child: _InstrumentCard(
                  label: 'ATİTÜD',
                  child: AttitudeIndicator(
                    rollDeg: proxy.roll, pitchDeg: proxy.pitch),
                )),
                const SizedBox(width: 10),
                Expanded(child: _InstrumentCard(
                  label: 'İRTİFA · ALTIMETER',
                  child: AltimeterIndicator(altitudeM: proxy.altitude),
                )),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _InstrumentCard(
                  label: 'RULO · YAW',
                  child: YawIndicator(
                    rollDeg: proxy.roll,
                    battery: proxy.battery,
                    armed: proxy.armed,
                  ),
                )),
                const SizedBox(width: 10),
                Expanded(child: _InstrumentCard(
                  label: 'PUSULA · HEADING',
                  child: HeadingIndicator(
                    headingDeg: proxy.heading,
                    gpsFix: proxy.gpsFix,
                  ),
                )),
                const SizedBox(width: 10),
                Expanded(child: _InstrumentCard(
                  label: 'DİKEY HIZ · VSI',
                  child: VSIIndicator(vspeedMs: proxy.verticalSpeed),
                )),
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
          BoxShadow(color: _C.cyan.withOpacity(0.04), blurRadius: 12, spreadRadius: 2),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(label,
                style: const TextStyle(color: _C.grey, fontSize: 9, letterSpacing: 1.5)),
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
    return Container(
      height: 32,
      decoration: const BoxDecoration(
        color: _C.panel,
        border: Border(top: BorderSide(color: _C.rim, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _item('MOD', proxy.flightMode),
          _item('BATARYA', '%${proxy.battery}'),
          _item('İRTİFA', '${proxy.altitude.toStringAsFixed(1)}m'),
          _item('HIZ', '${proxy.airspeed.toStringAsFixed(1)}m/s'),
          _item('GPS', proxy.gpsFix == 3 ? '3D FIX' : 'NO FIX'),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: proxy.armed ? _C.red.withOpacity(0.2) : _C.green.withOpacity(0.1),
              border: Border.all(
                color: proxy.armed ? _C.red : _C.green, width: 0.5),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              proxy.armed ? 'ARMED' : 'DISARMED',
              style: TextStyle(
                color: proxy.armed ? _C.red : _C.green,
                fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _item(String l, String v) => Padding(
    padding: const EdgeInsets.only(right: 20),
    child: Row(children: [
      Text('$l: ', style: const TextStyle(color: _C.grey, fontSize: 10)),
      Text(v, style: const TextStyle(color: _C.white, fontSize: 10, fontWeight: FontWeight.bold)),
    ]),
  );
}

// ════════════════════════════════════════════════════════════
//  1. AIR SPEED INDICATOR
// ════════════════════════════════════════════════════════════
class AirspeedIndicator extends StatelessWidget {
  final double speedKnots; // m/s gelebilir — label ayarlı
  const AirspeedIndicator({required this.speedKnots, super.key});

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _AirspeedPainter(speedKnots),
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

    // Arkaplan
    canvas.drawCircle(c, r, Paint()..color = const Color(0xFF0D1A27));
    canvas.drawCircle(c, r, Paint()
      ..style = PaintingStyle.stroke
      ..color = _C.rim
      ..strokeWidth = 3);

    // İç halka
    canvas.drawCircle(c, r * 0.9, Paint()
      ..style = PaintingStyle.stroke
      ..color = _C.dimText.withOpacity(0.4)
      ..strokeWidth = 0.5);

    // Yeşil arc (güvenli hız bölgesi 10-25 arası)
    _drawArc(canvas, c, r * 0.88, 10, 25, 0, 40,
        Paint()..color = _C.green..style = PaintingStyle.stroke..strokeWidth = 4..strokeCap = StrokeCap.butt);

    // Sarı arc (dikkat 25-35)
    _drawArc(canvas, c, r * 0.88, 10, 35, 25, 40,
        Paint()..color = _C.amber..style = PaintingStyle.stroke..strokeWidth = 4..strokeCap = StrokeCap.butt);

    // Kırmızı arc (tehlike 35-40)
    _drawArc(canvas, c, r * 0.88, 10, 40, 35, 40,
        Paint()..color = _C.red..style = PaintingStyle.stroke..strokeWidth = 4..strokeCap = StrokeCap.butt);

    // Tik ve etiketler
    for (int i = 0; i <= 40; i += 5) {
      final angle = _speedToAngle(i.toDouble(), 0, 40);
      final isMajor = i % 10 == 0;
      _drawTick(canvas, c, r, angle, isMajor ? 0.14 : 0.08,
          isMajor ? 1.5 : 0.8, _C.white);
      if (isMajor) {
        _drawLabel(canvas, c, r * 0.68, angle, '$i',
            TextStyle(color: _C.white, fontSize: r * 0.1, fontWeight: FontWeight.bold));
      }
    }

    // İbre
    final needleAngle = _speedToAngle(speed.clamp(0, 40), 0, 40);
    _drawNeedle(canvas, c, r * 0.72, needleAngle, _C.white, r * 0.025);

    // Merkez değer kutusu
    _drawValueBox(canvas, c, r, speed.toStringAsFixed(1), 'm/s', _C.cyan);

    // Merkez daire
    canvas.drawCircle(c, r * 0.06, Paint()..color = _C.rim);
    canvas.drawCircle(c, r * 0.04, Paint()..color = _C.white);
  }

  double _speedToAngle(double v, double min, double max) {
    // -135° to +135° (270° toplam)
    return (v - min) / (max - min) * 270 - 135;
  }

  void _drawArc(Canvas canvas, Offset c, double r,
      double from, double to, double arcFrom, double arcMax, Paint p) {
    final startAngle = _speedToAngle(arcFrom, 0, arcMax) * math.pi / 180 + math.pi / 2;
    final sweepAngle = (_speedToAngle(to, 0, arcMax) - _speedToAngle(from, 0, arcMax)) * math.pi / 180;
    canvas.drawArc(Rect.fromCircle(center: c, radius: r),
        startAngle, sweepAngle, false, p);
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
  const AttitudeIndicator({required this.rollDeg, required this.pitchDeg, super.key});

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

    // Clip dairesi
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: c, radius: r * 0.92)));

    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(roll * math.pi / 180);

    // Pitch offset: her derece = r*0.04 piksel
    final pitchOffset = pitch * r * 0.04;

    // Gökyüzü
    canvas.drawRect(
      Rect.fromLTRB(-r, -r * 2 + pitchOffset, r, pitchOffset),
      Paint()..color = _C.skyBlue,
    );

    // Zemin
    canvas.drawRect(
      Rect.fromLTRB(-r, pitchOffset, r, r * 2),
      Paint()..color = _C.earth,
    );

    // Ufuk çizgisi
    canvas.drawLine(Offset(-r, pitchOffset), Offset(r, pitchOffset),
        Paint()..color = _C.white..strokeWidth = 1.5);

    // Pitch tikleri
    for (int deg = -30; deg <= 30; deg += 5) {
      if (deg == 0) continue;
      final y = pitchOffset - deg * r * 0.04;
      final halfW = (deg % 10 == 0) ? r * 0.28 : r * 0.16;
      canvas.drawLine(Offset(-halfW, y), Offset(halfW, y),
          Paint()..color = _C.white.withOpacity(0.7)..strokeWidth = 0.8);
      if (deg % 10 == 0) {
        _drawTextCentered(canvas, Offset(-halfW - r * 0.1, y),
            '${deg.abs()}', TextStyle(color: _C.white, fontSize: r * 0.1));
      }
    }

    canvas.restore();

    // Roll scale (dış ring, sabit)
    for (int angle in [-60, -45, -30, -20, -10, 0, 10, 20, 30, 45, 60]) {
      final a = (angle - 90) * math.pi / 180;
      final isMajor = angle % 30 == 0;
      final len = isMajor ? r * 0.1 : r * 0.06;
      canvas.drawLine(
        Offset(c.dx + (r * 0.92) * math.cos(a), c.dy + (r * 0.92) * math.sin(a)),
        Offset(c.dx + (r * 0.92 - len) * math.cos(a), c.dy + (r * 0.92 - len) * math.sin(a)),
        Paint()..color = _C.white..strokeWidth = isMajor ? 1.5 : 0.8,
      );
    }

    // Roll pointer (üçgen)
    final rollRad = (roll - 90) * math.pi / 180;
    final px = c.dx + r * 0.85 * math.cos(rollRad);
    final py = c.dy + r * 0.85 * math.sin(rollRad);
    final tri = Path();
    tri.moveTo(px, py);
    final left = Offset(c.dx + r * 0.78 * math.cos(rollRad - 0.08),
                        c.dy + r * 0.78 * math.sin(rollRad - 0.08));
    final right = Offset(c.dx + r * 0.78 * math.cos(rollRad + 0.08),
                         c.dy + r * 0.78 * math.sin(rollRad + 0.08));
    tri.lineTo(left.dx, left.dy);
    tri.lineTo(right.dx, right.dy);
    tri.close();
    canvas.drawPath(tri, Paint()..color = _C.amber);

    // Uçak silueti (sabit orta)
    final planePaint = Paint()..color = _C.amber..strokeWidth = r * 0.035..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(c.dx - r * 0.38, c.dy), Offset(c.dx - r * 0.15, c.dy), planePaint);
    canvas.drawLine(Offset(c.dx + r * 0.15, c.dy), Offset(c.dx + r * 0.38, c.dy), planePaint);
    canvas.drawLine(Offset(c.dx - r * 0.06, c.dy), Offset(c.dx + r * 0.06, c.dy), planePaint);
    canvas.drawCircle(c, r * 0.035, Paint()..color = _C.amber);

    // Çerçeve
    canvas.drawCircle(c, r, Paint()..style = PaintingStyle.stroke..color = _C.rim..strokeWidth = 3);
  }

  void _drawTextCentered(Canvas canvas, Offset pos, String text, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(_AttitudePainter old) => old.roll != roll || old.pitch != pitch;
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
    canvas.drawCircle(c, r, Paint()
      ..style = PaintingStyle.stroke..color = _C.rim..strokeWidth = 3);

    // 100'lük ibre (tam tur = 1000m)
    final needle100 = (alt % 1000) / 1000 * 360 - 90;
    // 1000'lik ibre
    final needle1000 = (alt % 10000) / 10000 * 360 - 90;

    // Tik işaretleri (0-9)
    for (int i = 0; i < 10; i++) {
      final angle = i / 10 * 360 - 90;
      final isMajor = i % 5 == 0;
      _drawTick(canvas, c, r, angle, isMajor ? 0.14 : 0.08,
          isMajor ? 1.5 : 0.8, _C.white);
      if (isMajor || i % 2 == 0) {
        _drawLabel(canvas, c, r * 0.72, angle, '${i * 100}',
            TextStyle(color: _C.white, fontSize: r * 0.09));
      }
    }

    // Küçük ibre (1000'lik)
    _drawNeedle(canvas, c, r * 0.48, needle1000,
        _C.white.withOpacity(0.6), r * 0.018, wide: true);

    // Büyük ibre (100'lük)
    _drawNeedle(canvas, c, r * 0.72, needle100, _C.white, r * 0.025);

    // Değer kutusu
    _drawValueBox(canvas, c, r, alt.toStringAsFixed(0), 'm', _C.amber);

    canvas.drawCircle(c, r * 0.06, Paint()..color = _C.rim);
    canvas.drawCircle(c, r * 0.04, Paint()..color = _C.white);
  }

  @override
  bool shouldRepaint(_AltimeterPainter old) => old.alt != alt;
}

// ════════════════════════════════════════════════════════════
//  4. YAW / ROLL INDICATOR (Drone silueti)
// ════════════════════════════════════════════════════════════
class YawIndicator extends StatelessWidget {
  final double rollDeg;
  final int battery;
  final bool armed;
  const YawIndicator({required this.rollDeg, required this.battery, required this.armed, super.key});

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _YawPainter(rollDeg, battery, armed),
    child: const SizedBox.expand(),
  );
}

class _YawPainter extends CustomPainter {
  final double roll;
  final int battery;
  final bool armed;
  _YawPainter(this.roll, this.battery, this.armed);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    canvas.drawCircle(c, r, Paint()..color = const Color(0xFF0D1A27));
    canvas.drawCircle(c, r, Paint()
      ..style = PaintingStyle.stroke..color = _C.rim..strokeWidth = 3);

    // Roll tik çemberi
    for (int i = -180; i < 180; i += 10) {
      final angle = (i - 90) * math.pi / 180;
      final isMajor = i % 30 == 0;
      final len = isMajor ? r * 0.12 : r * 0.06;
      canvas.drawLine(
        Offset(c.dx + r * 0.88 * math.cos(angle), c.dy + r * 0.88 * math.sin(angle)),
        Offset(c.dx + (r * 0.88 - len) * math.cos(angle), c.dy + (r * 0.88 - len) * math.sin(angle)),
        Paint()..color = isMajor ? _C.white : _C.grey..strokeWidth = isMajor ? 1.5 : 0.7,
      );
      if (isMajor) {
        _drawLabel(canvas, c, r * 0.72, i.toDouble() - 90, '${i.abs()}',
            TextStyle(color: _C.grey, fontSize: r * 0.08));
      }
    }

    // Roll pointer
    final rollRad = (roll - 90) * math.pi / 180;
    final px = c.dx + r * 0.82 * math.cos(rollRad);
    final py = c.dy + r * 0.82 * math.sin(rollRad);
    final tri = Path();
    tri.moveTo(px, py);
    tri.lineTo(c.dx + r * 0.74 * math.cos(rollRad - 0.07),
               c.dy + r * 0.74 * math.sin(rollRad - 0.07));
    tri.lineTo(c.dx + r * 0.74 * math.cos(rollRad + 0.07),
               c.dy + r * 0.74 * math.sin(rollRad + 0.07));
    tri.close();
    canvas.drawPath(tri, Paint()..color = _C.cyan);

    // Drone silueti (merkez)
    _drawDroneSilhouette(canvas, c, r * 0.36);

    // Batarya arc
    final batAngle = battery / 100 * 2 * math.pi;
    final batColor = battery > 50 ? _C.green : battery > 20 ? _C.amber : _C.red;
    canvas.drawArc(Rect.fromCircle(center: c, radius: r * 0.92),
        -math.pi / 2, -batAngle, false,
        Paint()..color = batColor..style = PaintingStyle.stroke..strokeWidth = 4..strokeCap = StrokeCap.round);

    // Armed/Disarmed etiket
    _drawLabel(canvas, c, r * 0, 90,
        armed ? 'ARMED' : 'DISARMED',
        TextStyle(color: armed ? _C.red : _C.green,
            fontSize: r * 0.11, fontWeight: FontWeight.bold));

    // Batarya etiket
    final batTp = TextPainter(
      text: TextSpan(text: '%$battery', style: TextStyle(color: batColor, fontSize: r * 0.12, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    )..layout();
    batTp.paint(canvas, Offset(c.dx - batTp.width / 2, c.dy + r * 0.45));
  }

  void _drawDroneSilhouette(Canvas canvas, Offset c, double r) {
    final p = Paint()..color = _C.white..style = PaintingStyle.stroke..strokeWidth = r * 0.07..strokeCap = StrokeCap.round;
    final pb = Paint()..color = _C.white..style = PaintingStyle.fill;

    // Gövde
    canvas.drawRect(Rect.fromCenter(center: c, width: r * 0.5, height: r * 0.2), pb);

    // Kollar
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
      // Motor daire
      canvas.drawCircle(
        Offset(c.dx + arm[1].dx * r, c.dy + arm[1].dy * r),
        r * 0.18, Paint()..color = _C.rim..style = PaintingStyle.stroke..strokeWidth = r * 0.05,
      );
    }
  }

  @override
  bool shouldRepaint(_YawPainter old) =>
      old.roll != roll || old.battery != battery || old.armed != armed;
}

// ════════════════════════════════════════════════════════════
//  5. HEADING INDICATOR (Pusula)
// ════════════════════════════════════════════════════════════
class HeadingIndicator extends StatelessWidget {
  final double headingDeg;
  final int gpsFix;
  const HeadingIndicator({required this.headingDeg, required this.gpsFix, super.key});

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
    canvas.drawCircle(c, r, Paint()
      ..style = PaintingStyle.stroke..color = _C.rim..strokeWidth = 3);

    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(-heading * math.pi / 180);

    // Yön noktaları
    final dirs = {'N': 0.0, 'E': 90.0, 'S': 180.0, 'W': 270.0};
    for (final d in dirs.entries) {
      final a = (d.value - 90) * math.pi / 180;
      final isNS = d.key == 'N' || d.key == 'S';
      _drawTextCentered(
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

    // Her 10 derecelik tikler
    for (int i = 0; i < 36; i++) {
      final angle = (i * 10 - 90) * math.pi / 180;
      final isMajor = i % 3 == 0;
      final len = isMajor ? r * 0.12 : r * 0.06;
      canvas.drawLine(
        Offset(r * 0.88 * math.cos(angle), r * 0.88 * math.sin(angle)),
        Offset((r * 0.88 - len) * math.cos(angle), (r * 0.88 - len) * math.sin(angle)),
        Paint()..color = isMajor ? _C.white : _C.grey..strokeWidth = isMajor ? 1.5 : 0.7,
      );
      if (isMajor && i % 6 == 0 && i != 0 && !dirs.values.contains(i * 10.0)) {
        _drawTextCentered(
          canvas,
          Offset(r * 0.72 * math.cos(angle), r * 0.72 * math.sin(angle)),
          '${i * 10}',
          TextStyle(color: _C.grey, fontSize: r * 0.09),
        );
      }
    }

    canvas.restore();

    // Sabit işaretçi (yukarı üçgen)
    final tri = Path();
    tri.moveTo(c.dx, c.dy - r * 0.82);
    tri.lineTo(c.dx - r * 0.05, c.dy - r * 0.7);
    tri.lineTo(c.dx + r * 0.05, c.dy - r * 0.7);
    tri.close();
    canvas.drawPath(tri, Paint()..color = _C.cyan);

    // Merkez değer
    _drawValueBox(canvas, c, r, '${heading.toStringAsFixed(0)}°', '', _C.cyan);

    // GPS fix göstergesi
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

  void _drawTextCentered(Canvas canvas, Offset pos, String text, TextStyle style) {
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
//  6. VERTICAL SPEED INDICATOR
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
    canvas.drawCircle(c, r, Paint()
      ..style = PaintingStyle.stroke..color = _C.rim..strokeWidth = 3);

    // -10 to +10 m/s, 0° top
    // +10 → 135° saat yönünde, -10 → -135° (270° aralık)
    const maxVs = 10.0;
    for (int v = -10; v <= 10; v += 2) {
      final angle = v / maxVs * 135 - 90;
      final isMajor = v % 5 == 0;
      _drawTick(canvas, c, r, angle, isMajor ? 0.14 : 0.08,
          isMajor ? 1.5 : 0.8, _C.white);
      if (isMajor) {
        _drawLabel(canvas, c, r * 0.7, angle, '${v > 0 ? '+' : ''}$v',
            TextStyle(color: v > 0 ? _C.green : v < 0 ? _C.red : _C.white,
                fontSize: r * 0.1, fontWeight: FontWeight.bold));
      }
    }

    // Merkez yatay çizgi
    canvas.drawLine(
      Offset(c.dx - r * 0.3, c.dy),
      Offset(c.dx + r * 0.3, c.dy),
      Paint()..color = _C.white.withOpacity(0.3)..strokeWidth = 0.5,
    );

    // İbre
    final clamped = vs.clamp(-maxVs, maxVs);
    final needleAngle = clamped / maxVs * 135 - 90;
    final needleColor = vs > 0 ? _C.green : vs < 0 ? _C.red : _C.white;
    _drawNeedle(canvas, c, r * 0.72, needleAngle, needleColor, r * 0.025);

    // Değer kutusu
    _drawValueBox(canvas, c, r,
        '${vs > 0 ? '+' : ''}${vs.toStringAsFixed(1)}', 'm/s',
        vs > 0 ? _C.green : vs < 0 ? _C.red : _C.white);

    // Etiketler
    _drawLabel(canvas, c, r * 0, -120, 'ÇIKMA',
        TextStyle(color: _C.green.withOpacity(0.7), fontSize: r * 0.09));
    _drawLabel(canvas, c, r * 0, 120, 'ALÇALMA',
        TextStyle(color: _C.red.withOpacity(0.7), fontSize: r * 0.09));

    canvas.drawCircle(c, r * 0.06, Paint()..color = _C.rim);
    canvas.drawCircle(c, r * 0.04, Paint()..color = needleColor);
  }

  void _drawLabel2(Canvas canvas, Offset c, double labelR, double angleDeg,
      String text, TextStyle style) {
    _drawLabel(canvas, c, labelR, angleDeg, text, style);
  }

  @override
  bool shouldRepaint(_VSIPainter old) => old.vs != vs;
}

// ════════════════════════════════════════════════════════════
//  SHARED PAINT HELPERS
// ════════════════════════════════════════════════════════════

void _drawTick(Canvas canvas, Offset c, double r, double angleDeg,
    double lengthRatio, double strokeWidth, Color color) {
  final a = (angleDeg - 90) * math.pi / 180;
  canvas.drawLine(
    Offset(c.dx + r * 0.92 * math.cos(a), c.dy + r * 0.92 * math.sin(a)),
    Offset(c.dx + r * (0.92 - lengthRatio) * math.cos(a),
           c.dy + r * (0.92 - lengthRatio) * math.sin(a)),
    Paint()..color = color..strokeWidth = strokeWidth..strokeCap = StrokeCap.butt,
  );
}

void _drawLabel(Canvas canvas, Offset c, double labelR, double angleDeg,
    String text, TextStyle style) {
  final a = (angleDeg - 90) * math.pi / 180;
  final pos = labelR == 0
      ? Offset(c.dx, c.dy - labelR * 0.3)
      : Offset(c.dx + labelR * math.cos(a), c.dy + labelR * math.sin(a));

  final tp = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
}

void _drawNeedle(Canvas canvas, Offset c, double length, double angleDeg,
    Color color, double width, {bool wide = false}) {
  final a = (angleDeg - 90) * math.pi / 180;
  final tip = Offset(c.dx + length * math.cos(a), c.dy + length * math.sin(a));
  final tail = Offset(c.dx - length * 0.2 * math.cos(a),
                      c.dy - length * 0.2 * math.sin(a));

  if (wide) {
    final path = Path();
    final perp = a + math.pi / 2;
    path.moveTo(c.dx + width * 1.5 * math.cos(perp),
                c.dy + width * 1.5 * math.sin(perp));
    path.lineTo(tip.dx, tip.dy);
    path.lineTo(c.dx - width * 1.5 * math.cos(perp),
                c.dy - width * 1.5 * math.sin(perp));
    canvas.drawPath(path,
        Paint()..color = color.withOpacity(0.6)..style = PaintingStyle.fill);
  } else {
    canvas.drawLine(tail, tip,
        Paint()..color = color..strokeWidth = width..strokeCap = StrokeCap.round);
  }
}

void _drawValueBox(Canvas canvas, Offset c, double r,
    String value, String unit, Color color) {
  final rrect = RRect.fromRectAndRadius(
    Rect.fromCenter(center: Offset(c.dx, c.dy + r * 0.32),
        width: r * 0.7, height: r * 0.22),
    const Radius.circular(4),
  );
  canvas.drawRRect(rrect,
      Paint()..color = Colors.black.withOpacity(0.6));
  canvas.drawRRect(rrect,
      Paint()..color = color.withOpacity(0.4)..style = PaintingStyle.stroke..strokeWidth = 0.8);

  final valTp = TextPainter(
    text: TextSpan(
      children: [
        TextSpan(text: value, style: TextStyle(color: color, fontSize: r * 0.13, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
        if (unit.isNotEmpty)
          TextSpan(text: ' $unit', style: TextStyle(color: color.withOpacity(0.7), fontSize: r * 0.08)),
      ],
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  valTp.paint(canvas,
      Offset(c.dx - valTp.width / 2, c.dy + r * 0.32 - valTp.height / 2));
}