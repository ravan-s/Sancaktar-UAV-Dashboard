import 'package:flutter/material.dart';
import '../desktop_cockpit.dart';

class VSIGauge extends StatefulWidget {
  final double verticalSpeed;
  const VSIGauge({super.key, required this.verticalSpeed});
  @override
  State<VSIGauge> createState() => _VSIGaugeState();
}

class _VSIGaugeState extends State<VSIGauge>
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
      begin: widget.verticalSpeed,
      end: widget.verticalSpeed,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(VSIGauge old) {
    super.didUpdateWidget(old);
    if (old.verticalSpeed != widget.verticalSpeed) {
      _anim = Tween(
        begin: _anim.value,
        end: widget.verticalSpeed,
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
      painter: VSIPainter(_anim.value),
      child: const SizedBox.expand(),
    ),
  );
}
