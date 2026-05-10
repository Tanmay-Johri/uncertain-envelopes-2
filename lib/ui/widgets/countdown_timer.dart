import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Formats a non-negative duration as `MM:SS` (minutes may exceed 59).
/// Public on purpose: `game_lobby_screen.dart` reuses it for the
/// header chip so the lobby and the timer widget never drift apart.
String formatCountdownMmSs(Duration remaining) {
  final secs = math.max(0, remaining.inSeconds);
  final mm = secs ~/ 60;
  final ss = secs % 60;
  return '${mm.toString().padLeft(2, '0')}:${ss.toString().padLeft(2, '0')}';
}

/// Live countdown label.
///
/// Anchored to a wall-clock **deadline** (computed once from `now() +
/// initialRemaining`) instead of decrementing a local counter on every tick.
/// This means the displayed value is always `deadline - now()` and is
/// **drift-proof**: if the periodic timer ever misses ticks (app backgrounded,
/// device sleep, OS throttling, jank), the next tick recomputes from the
/// current clock and the display jumps back to the correct value rather than
/// silently lagging behind real time.
///
/// When [initialRemaining] changes (e.g. the upstream provider re-snapshots,
/// or admin "add time" extends the game), the deadline is re-anchored in
/// [didUpdateWidget] so the display resyncs with the authoritative server
/// value on the next build.
class CountdownTimer extends StatefulWidget {
  const CountdownTimer({
    super.key,
    required this.initialRemaining,
    this.onExpired,
    this.textStyle,
    this.now,
  });

  final Duration initialRemaining;
  final VoidCallback? onExpired;

  /// When null, uses the default lobby-sized style.
  final TextStyle? textStyle;

  /// Injectable wall clock. Defaults to [DateTime.now]. Tests pass a
  /// controllable function so they can advance time deterministically.
  final DateTime Function()? now;

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  Timer? _timer;
  late DateTime _deadline;
  late int _remainingSeconds;
  bool _expiredFired = false;

  DateTime _now() => (widget.now ?? DateTime.now)();

  void _anchorDeadlineFromInitial() {
    final initialSeconds = math.max(0, widget.initialRemaining.inSeconds);
    _deadline = _now().add(Duration(seconds: initialSeconds));
    _remainingSeconds = initialSeconds;
  }

  void _recomputeRemaining() {
    final secs = _deadline.difference(_now()).inSeconds;
    _remainingSeconds = math.max(0, secs);
  }

  void _startTickerIfNeeded() {
    if (_timer != null) return;
    if (_remainingSeconds == 0) {
      _fireExpiredIfNeeded();
      return;
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _recomputeRemaining();
        if (_remainingSeconds == 0) {
          _timer?.cancel();
          _timer = null;
          _fireExpiredIfNeeded();
        }
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _anchorDeadlineFromInitial();
    _startTickerIfNeeded();
  }

  @override
  void didUpdateWidget(covariant CountdownTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialRemaining != widget.initialRemaining) {
      // Authoritative resync: re-anchor the deadline whenever the upstream
      // snapshot changes (provider rebuild, add-time, etc.).
      _expiredFired = false;
      _anchorDeadlineFromInitial();
      _startTickerIfNeeded();
    }
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
    final style = widget.textStyle ??
        AppTypography.monoMedium.copyWith(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: 2,
        );
    return Text(
      text,
      key: const ValueKey('lobby-countdown-mmss'),
      style: style,
    );
  }
}
