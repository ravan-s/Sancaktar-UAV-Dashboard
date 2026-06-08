import 'package:flutter/material.dart';
import '../desktop_cockpit.dart';

class VSIGauge extends StatelessWidget {
  final double verticalSpeed;
  const VSIGauge({super.key, required this.verticalSpeed});
  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: VSIPainter(verticalSpeed),
    child: const SizedBox.expand(),
  );
}
