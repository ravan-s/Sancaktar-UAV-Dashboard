import 'package:flutter/material.dart';
class VSIGauge extends StatelessWidget {
  final double verticalSpeed;
  const VSIGauge({super.key, required this.verticalSpeed});
  @override
  Widget build(BuildContext context) => CustomPaint(painter: _VSIPainter(vs: verticalSpeed));
}

class _VSIPainter extends CustomPainter {
  final double vs;
  _VSIPainter({required this.vs});
  @override
  void paint(Canvas canvas, Size size) {
    // Dikey hız göstergesi (Yukarı/Aşağı oklar)
    final paint = Paint()..color = vs > 0 ? Colors.green : Colors.red..strokeWidth = 3;
    canvas.drawLine(Offset(size.width/2, size.height/2), Offset(size.width/2, size.height/2 - (vs * 2)), paint);
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}