import 'package:flutter/material.dart';

class YawGauge extends StatelessWidget {
  final double roll, battery;
  final bool armed;
  const YawGauge({super.key, required this.roll, required this.battery, required this.armed});
  @override
  Widget build(BuildContext context) => CustomPaint(painter: _YawPainter(roll: roll, battery: battery, armed: armed));
}

class _YawPainter extends CustomPainter {
  final double roll, battery;
  final bool armed;
  _YawPainter({required this.roll, required this.battery, required this.armed});
  @override
  void paint(Canvas canvas, Size size) {
    // Burada rulo ve arm durumu için bordo/yeşil daireler çizebilirsin
    canvas.drawCircle(Offset(size.width/2, size.height/2), 10, Paint()..color = armed ? Colors.green : Colors.red);
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}