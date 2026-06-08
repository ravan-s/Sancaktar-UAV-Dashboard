import 'package:flutter/material.dart';
import '../desktop_cockpit.dart';

class AttitudeGauge extends StatelessWidget {
  final double roll, pitch;
  const AttitudeGauge({super.key, required this.roll, required this.pitch});
  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: AttitudePainter(roll, pitch),
    child: const SizedBox.expand(),
  );
}
