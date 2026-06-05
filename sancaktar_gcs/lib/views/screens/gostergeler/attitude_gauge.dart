import 'package:flutter/material.dart';
import 'dart:math' as math;

class AttitudeGauge extends StatelessWidget {
  final double roll, pitch;
  const AttitudeGauge({super.key, required this.roll, required this.pitch});
  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _AttitudePainter(roll: roll, pitch: pitch),
  );
}

class _AttitudePainter extends CustomPainter {
  final double roll, pitch;
  _AttitudePainter({required this.roll, required this.pitch});
  @override
  void paint(Canvas canvas, Size size) {
    // Ufuk çizgisi ve yatış açısı için rotasyon
    final center = Offset(size.width / 2, size.height / 2);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(roll * math.pi / 180);
    canvas.drawRect(
      Rect.fromLTWH(-size.width / 2, -2, size.width, 4),
      Paint()..color = Colors.blue,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
