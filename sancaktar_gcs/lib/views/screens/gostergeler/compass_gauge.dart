import 'package:flutter/material.dart';
import '../desktop_cockpit.dart';

// ============================================================
// COMPASS GAUGE (heading + fix)
// ============================================================
class CompassGauge extends StatefulWidget {
  final double heading;
  final bool gpsFix;
  const CompassGauge({super.key, required this.heading, required this.gpsFix});
  @override
  State<CompassGauge> createState() => _CompassGaugeState();
}

class _CompassGaugeState extends State<CompassGauge>
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
      begin: widget.heading,
      end: widget.heading,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(CompassGauge old) {
    super.didUpdateWidget(old);
    if (old.heading != widget.heading) {
      _anim = Tween(
        begin: _anim.value,
        end: widget.heading,
      ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
      _ctrl.forward(from: 0);
    }
    // fix boolean anlık değişir, animasyona gerek yok, sadece repaint tetiklenir.
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
      painter: HeadingPainter(_anim.value, widget.gpsFix ? 1 : 0),
      child: const SizedBox.expand(),
    ),
  );
}
