import 'package:flutter/material.dart';
import '../desktop_cockpit.dart';

class YawGauge extends StatelessWidget {
  final double roll, battery;
  final bool armed;
  const YawGauge({
    super.key,
    required this.roll,
    required this.battery,
    required this.armed,
  });
  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: YawPainter(roll, battery.toInt(), armed),
    child: const SizedBox.expand(),
  );
}
