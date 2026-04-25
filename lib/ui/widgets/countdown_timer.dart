import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Formats a non-negative duration as `MM:SS` (minutes may exceed 59).
@visibleForTesting
String formatCountdownMmSs(Duration remaining) {
  final secs = math.max(0, remaining.inSeconds);
  final mm = secs ~/ 60;
  final ss = secs % 60;
  return '${mm.toString().padLeft(2, '0')}:${ss.toString().padLeft(2, '0')}';
}

/// Live countdown label; uses a one-second periodic timer so the widget tree
/// settles between ticks (e.g. `pumpAndSettle` in parent tests).
class CountdownTimer extends StatefulWidget {
  const CountdownTimer({
    super.key,
    required this.initialRemaining,
    this.onExpired,
  });

  final Duration initialRemaining;
  final VoidCallback? onExpired;

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  Timer? _timer;
  late int _remainingSeconds;
  bool _expiredFired = false;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = math.max(0, widget.initialRemaining.inSeconds);
    if (_remainingSeconds == 0) {
      _fireExpiredIfNeeded();
      return;
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _remainingSeconds = math.max(0, _remainingSeconds - 1);
        if (_remainingSeconds == 0) {
          _timer?.cancel();
          _timer = null;
          _fireExpiredIfNeeded();
        }
      });
    });
  }

  void _fireExpiredIfNeeded() {
    if (_expiredFired) return;
    _expiredFired = true;
    widget.onExpired?.call();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = formatCountdownMmSs(Duration(seconds: _remainingSeconds));
    return Text(
      text,
      key: const ValueKey('lobby-countdown-mmss'),
      style: AppTypography.monoMedium.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: 2,
      ),
    );
  }
}
