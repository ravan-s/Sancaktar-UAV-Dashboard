import 'package:flutter/material.dart';
import '../desktop_cockpit.dart';

// ============================================================
// YAW GAUGE (roll + battery + armed)
// ============================================================
class YawGauge extends StatefulWidget {
  final double roll;
  final double battery;
  final bool armed;
  const YawGauge({
    super.key,
    required this.roll,
    required this.battery,
    required this.armed,
  });
  @override
  State<YawGauge> createState() => _YawGaugeState();
}

class _YawGaugeState extends State<YawGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _anim = Tween(
      begin: widget.roll,
      end: widget.roll,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(YawGauge old) {
    super.didUpdateWidget(old);
    if (old.roll != widget.roll) {
      _anim = Tween(
        begin: _anim.value,
        end: widget.roll,
      ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
      _ctrl.forward(from: 0);
    }
    // battery ve armed animasyonsuz, direkt painter'a geçiyor.
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _anim,
    builder: (_, __) => CustomPaint(
      painter: YawPainter(_anim.value, widget.battery.toInt(), widget.armed),
      child: const SizedBox.expand(),
    ),
  );
}
