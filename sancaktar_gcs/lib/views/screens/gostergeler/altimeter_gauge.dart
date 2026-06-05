import 'package:flutter/material.dart';

class AltimeterGauge extends StatelessWidget {
  final double altitude;
  const AltimeterGauge({super.key, required this.altitude});
  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _AltimeterPainter(altitude: altitude));
}

class _AltimeterPainter extends CustomPainter {
  final double altitude;
  _AltimeterPainter({required this.altitude});
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    // İrtifa metni ve skalası buraya
    final textPainter = TextPainter(
      text: TextSpan(
        text: altitude.toStringAsFixed(0),
        style: const TextStyle(color: Colors.white, fontSize: 20),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      center - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
