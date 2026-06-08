import 'package:flutter/material.dart';
import '../desktop_cockpit.dart';

class CompassGauge extends StatelessWidget {
  final double heading;
  final bool gpsFix;
  const CompassGauge({super.key, required this.heading, required this.gpsFix});
  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: HeadingPainter(heading, gpsFix ? 3 : 0),
    child: const SizedBox.expand(),
  );
}
