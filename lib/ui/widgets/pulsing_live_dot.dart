import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Small circular “live” marker with a repeating opacity pulse (reads as blinking).
class PulsingLiveDot extends StatefulWidget {
  const PulsingLiveDot({
    super.key,
    this.size = 8,
    this.color = AppColors.primary,
    this.minOpacity = 0.35,
    this.period = const Duration(milliseconds: 850),
  });

  final double size;
  final Color color;
  final double minOpacity;
  final Duration period;

  @override
  State<PulsingLiveDot> createState() => _PulsingLiveDotState();
}

class _PulsingLiveDotState extends State<PulsingLiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.period)
      ..repeat(reverse: true);
    _opacity = Tween<double>(
      begin: widget.minOpacity,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(PulsingLiveDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.period != widget.period) {
      _controller.duration = widget.period;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        key: const ValueKey('pulsing-live-dot'),
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
