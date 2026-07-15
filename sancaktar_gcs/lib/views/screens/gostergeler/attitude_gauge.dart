import 'package:flutter/material.dart';
import '../desktop_cockpit.dart';

// ============================================================
// ATTITUDE GAUGE (roll + pitch, iki ayrı controller)
// ============================================================
class AttitudeGauge extends StatefulWidget {
  final double roll;
  final double pitch;
  const AttitudeGauge({super.key, required this.roll, required this.pitch});
  @override
  State<AttitudeGauge> createState() => _AttitudeGaugeState();
}

class _AttitudeGaugeState extends State<AttitudeGauge>
    with TickerProviderStateMixin {
  late AnimationController _rollCtrl;
  late AnimationController _pitchCtrl;
  late Animation<double> _rollAnim;
  late Animation<double> _pitchAnim;

  @override
  void initState() {
    super.initState();
    _rollCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _pitchCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _rollAnim = Tween(
      begin: widget.roll,
      end: widget.roll,
    ).animate(CurvedAnimation(parent: _rollCtrl, curve: Curves.easeOut));
    _pitchAnim = Tween(
      begin: widget.pitch,
      end: widget.pitch,
    ).animate(CurvedAnimation(parent: _pitchCtrl, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(AttitudeGauge old) {
    super.didUpdateWidget(old);
    if (old.roll != widget.roll) {
      _rollAnim = Tween(
        begin: _rollAnim.value,
        end: widget.roll,
      ).animate(CurvedAnimation(parent: _rollCtrl, curve: Curves.easeOut));
      _rollCtrl.forward(from: 0);
    }
    if (old.pitch != widget.pitch) {
      _pitchAnim = Tween(
        begin: _pitchAnim.value,
        end: widget.pitch,
      ).animate(CurvedAnimation(parent: _pitchCtrl, curve: Curves.easeOut));
      _pitchCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _rollCtrl.dispose();
    _pitchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([_rollAnim, _pitchAnim]),
    builder: (_, __) => CustomPaint(
      painter: AttitudePainter(_rollAnim.value, _pitchAnim.value),
      child: const SizedBox.expand(),
    ),
  );
}
