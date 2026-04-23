import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Lobby / home card status pill (matches HTML mock palette).
enum GameStatusBadge {
  active,
  joined,
  ready,
  notJoined,
}

/// Pill-shaped status label for game cards.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final GameStatusBadge status;

  static const _activeBg = Color(0x6622C55E); // green-900 @ ~40%
  static const _activeFg = Color(0xFF4ADE80); // green-400
  static const _activeBorder = Color(0x3322C55E);

  static const _readyBg = Color(0x661E3A8A); // blue-900 @ ~40%
  static const _readyFg = Color(0xFF60A5FA); // blue-400
  static const _readyBorder = Color(0x333B82F6);

  static const _joinedBg = Color(0x6671370A); // yellow-900 @ ~40%
  static const _joinedFg = Color(0xFFFACC15); // yellow-400
  static const _joinedBorder = Color(0x33EAB308);

  static const _notJoinedBg = Color(0xFF1E293B); // slate-800
  static const _notJoinedFg = Color(0xFF94A3B8); // slate-400
  static const _notJoinedBorder = Color(0x4D475569); // slate-600 ~30%

  String get _label => switch (status) {
        GameStatusBadge.active => 'ACTIVE',
        GameStatusBadge.joined => 'JOINED',
        GameStatusBadge.ready => 'READY',
        GameStatusBadge.notJoined => 'NOT JOINED',
      };

  ({Color bg, Color fg, Color border}) get _colors => switch (status) {
        GameStatusBadge.active => (
            bg: _activeBg,
            fg: _activeFg,
            border: _activeBorder,
          ),
        GameStatusBadge.ready => (
            bg: _readyBg,
            fg: _readyFg,
            border: _readyBorder,
          ),
        GameStatusBadge.joined => (
            bg: _joinedBg,
            fg: _joinedFg,
            border: _joinedBorder,
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
