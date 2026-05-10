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
/// Prefer [deadlineUtc]: wall-clock instant when trading ends (DB
/// `end_time_decided`). Each tick recomputes `deadlineUtc - now()` so every
/// device shows the same remaining time given the same deadline and clock.
///
/// When [deadlineUtc] is null, falls back to [initialRemaining] anchored with
/// `now + initialRemaining` (mocks / pre-start lobby display).
class CountdownTimer extends StatefulWidget {
  const CountdownTimer({
    super.key,
    this.deadlineUtc,
    this.initialRemaining = Duration.zero,
    this.onExpired,
    this.textStyle,
    this.now,
  });

  /// Authoritative end instant (e.g. Supabase `games.end_time_decided`).
  /// When non-null, [initialRemaining] is ignored for display math.
  final DateTime? deadlineUtc;

  /// Used only when [deadlineUtc] is null.
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
  /// Only for legacy [initialRemaining] mode: anchor = now + initial.
  late DateTime _anchorDeadline;
  late int _remainingSeconds;
  bool _expiredFired = false;

  DateTime _now() => (widget.now ?? DateTime.now)();

  bool get _usesDbDeadline => widget.deadlineUtc != null;

  void _seedFromInitialRemainingAt(DateTime t) {
    final initialSeconds = math.max(0, widget.initialRemaining.inSeconds);
    _anchorDeadline = t.add(Duration(seconds: initialSeconds));
    _remainingSeconds = math.max(0, _anchorDeadline.difference(t).inSeconds);
  }

  void _recomputeRemaining() {
    if (_usesDbDeadline) {
      final secs = widget.deadlineUtc!.difference(_now()).inSeconds;
      _remainingSeconds = math.max(0, secs);
    } else {
      final secs = _anchorDeadline.difference(_now()).inSeconds;
      _remainingSeconds = math.max(0, secs);
    }
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
    final t = _now();
    if (_usesDbDeadline) {
      _remainingSeconds =
          math.max(0, widget.deadlineUtc!.difference(t).inSeconds);
    } else {
      _seedFromInitialRemainingAt(t);
    }
    _startTickerIfNeeded();
  }

  @override
  void didUpdateWidget(covariant CountdownTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final deadlineChanged =
        oldWidget.deadlineUtc != widget.deadlineUtc;
    final initialChanged =
        oldWidget.initialRemaining != widget.initialRemaining;
    final modeChanged =
        (oldWidget.deadlineUtc != null) != (widget.deadlineUtc != null);

    if (modeChanged || deadlineChanged || (!_usesDbDeadline && initialChanged)) {
      _expiredFired = false;
      _timer?.cancel();
      _timer = null;
      final t = _now();
      if (_usesDbDeadline) {
        _remainingSeconds =
            math.max(0, widget.deadlineUtc!.difference(t).inSeconds);
      } else {
        _seedFromInitialRemainingAt(t);
      }
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
