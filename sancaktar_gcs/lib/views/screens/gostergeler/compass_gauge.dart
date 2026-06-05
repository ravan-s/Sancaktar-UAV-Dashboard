import 'package:flutter/material.dart';
import 'dart:math' as math; // Matematiksel işlemler için

class CompassGauge extends StatelessWidget {
  final double heading;
  final bool gpsFix;
  const CompassGauge({super.key, required this.heading, required this.gpsFix});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CompassPainter(heading: heading, gpsFix: gpsFix),
    );
  }
}

class _CompassPainter extends CustomPainter {
  final double heading;
  final bool gpsFix;
  _CompassPainter({required this.heading, required this.gpsFix});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Pusula tabanı
    canvas.drawCircle(center, radius, Paint()..color = const Color(0xFF0B121D));

    // Yön işareti (Neon Cyan)
    final textPainter = TextPainter(
      text: TextSpan(
        text: "N",
        style: TextStyle(
          color: gpsFix ? Colors.cyan : Colors.grey,
          fontSize: 16,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      center - Offset(textPainter.width / 2, radius - 15),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
