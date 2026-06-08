import 'package:flutter/material.dart';
import '../desktop_cockpit.dart';

class Speedometer extends StatelessWidget {
  final double value;
  const Speedometer({super.key, required this.value});
  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: AirspeedPainter(value),
    child: const SizedBox.expand(),
  );
}
