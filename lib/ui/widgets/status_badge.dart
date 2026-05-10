import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Lobby / home card status pill (matches HTML mock palette).
enum GameStatusBadge {
  playing,
  joined,
  notJoined,
  ended,
}

/// Pill-shaped status label for game cards.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final GameStatusBadge status;

  static const _playingBg = Color(0x6622C55E); // green-900 @ ~40%
  static const _playingFg = Color(0xFF4ADE80); // green-400
  static const _playingBorder = Color(0x3322C55E);

  static const _joinedBg = Color(0x6671370A); // yellow-900 @ ~40%
  static const _joinedFg = Color(0xFFFACC15); // yellow-400
  static const _joinedBorder = Color(0x33EAB308);

  static const _endedBg = Color(0x66334154); // slate-900 @ ~40%
  static const _endedFg = Color(0xFFE2E8F0); // slate-200
  static const _endedBorder = Color(0x33475569);

  static const _notJoinedBg = Color(0xFF1E293B); // slate-800
  static const _notJoinedFg = Color(0xFF94A3B8); // slate-400
  static const _notJoinedBorder = Color(0x4D475569); // slate-600 ~30%

  String get _label => switch (status) {
        GameStatusBadge.playing => 'PLAYING',
        GameStatusBadge.joined => 'JOINED',
        GameStatusBadge.notJoined => 'NOT JOINED',
        GameStatusBadge.ended => 'ENDED',
      };

  ({Color bg, Color fg, Color border}) get _colors => switch (status) {
        GameStatusBadge.playing => (
            bg: _playingBg,
            fg: _playingFg,
            border: _playingBorder,
          ),
        GameStatusBadge.joined => (
            bg: _joinedBg,
            fg: _joinedFg,
            border: _joinedBorder,
          ),
        GameStatusBadge.ended => (
            bg: _endedBg,
            fg: _endedFg,
            border: _endedBorder,
          ),
        GameStatusBadge.notJoined => (
            bg: _notJoinedBg,
            fg: _notJoinedFg,
            border: _notJoinedBorder,
          ),
      };

  @override
  Widget build(BuildContext context) {
    final c = _colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: c.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          _label,
          style: AppTypography.microLabel.copyWith(
            color: c.fg,
            fontSize: 10,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}
