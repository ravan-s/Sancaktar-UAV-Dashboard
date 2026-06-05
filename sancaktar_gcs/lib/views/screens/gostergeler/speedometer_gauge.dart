import 'package:flutter/material.dart';
import 'dart:math' as math;

class Speedometer extends StatelessWidget {
  final double value;
  const Speedometer({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _SpeedometerPainter(value: value));
  }
}

class _SpeedometerPainter extends CustomPainter {
  final double value;
  _SpeedometerPainter({required this.value});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Arka plan derinliği
    final paintBg = Paint()
      ..shader = RadialGradient(
        colors: [const Color(0xFF162130), const Color(0xFF03060A)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paintBg);

    // Bordo vurgu halkası
    canvas.drawCircle(
      center,
      radius - 2,
      Paint()
        ..color = const Color(0xFF800020)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // İbre
    final needlePaint = Paint()
      ..color = Colors.redAccent
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    double angle = -135 + (value / 100 * 270);
    double rad = angle * (math.pi / 180);
    canvas.drawLine(
      center,
      center +
          Offset(math.cos(rad) * (radius - 10), math.sin(rad) * (radius - 10)),
      needlePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
