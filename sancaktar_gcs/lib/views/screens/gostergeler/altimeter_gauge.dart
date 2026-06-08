import 'package:flutter/material.dart';
import '../desktop_cockpit.dart';

class AltimeterGauge extends StatelessWidget {
  final double altitude;
  const AltimeterGauge({super.key, required this.altitude});
  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: AltimeterPainter(altitude),
    child: const SizedBox.expand(),
  );
}
