import 'package:flutter/material.dart';
import '../desktop_cockpit.dart';

// ============================================================
// ALTIMETER GAUGE
// ============================================================
class AltimeterGauge extends StatefulWidget {
  final double altitude;
  const AltimeterGauge({super.key, required this.altitude});
  @override
  State<AltimeterGauge> createState() => _AltimeterGaugeState();
}

class _AltimeterGaugeState extends State<AltimeterGauge>
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
      begin: widget.altitude,
      end: widget.altitude,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(AltimeterGauge old) {
    super.didUpdateWidget(old);
    if (old.altitude != widget.altitude) {
      _anim = Tween(
        begin: _anim.value,
        end: widget.altitude,
      ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
      _ctrl.forward(from: 0);
    }
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
      painter: AltimeterPainter(_anim.value),
      child: const SizedBox.expand(),
    ),
  );
}
