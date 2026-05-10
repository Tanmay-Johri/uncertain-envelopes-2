import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'status_badge.dart';

/// One participant row in the game lobby (avatar, name, admin crown, chip).
///
/// When [showKickButton] is true, a small dismiss control is shown (admin
/// kicking another player). Per product rules, callers should pass `false`
/// for the current user's row.
class PlayerListTile extends StatelessWidget {
  const PlayerListTile({
    super.key,
    required this.playerId,
    required this.initials,
    required this.displayName,
    this.isGameAdmin = false,
    this.highlightRow = false,
    this.showKickButton = false,
    this.onKick,
  });

  final String playerId;
  final String initials;
  final String displayName;
  final bool isGameAdmin;
  final bool highlightRow;

  /// Whether the red kick control is shown (e.g. admin + pre-start only).
  final bool showKickButton;
  final VoidCallback? onKick;

  @override
  Widget build(BuildContext context) {
    final initialsUpper = initials.trim().toUpperCase();
    final short = initialsUpper.length >= 2
        ? initialsUpper.substring(0, 2)
        : initialsUpper.padRight(2, 'X');

    final avatarBg = highlightRow
        ? AppColors.primary
        : AppColors.surfaceContainerHigh;
    final avatarFg = highlightRow
        ? AppColors.background
        : AppColors.textSecondary;

    final borderColor = highlightRow ? AppColors.primary.withValues(alpha: 0.35) : AppColors.outline;
    final borderWidth = highlightRow ? 1.5 : 1.0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: borderColor, width: borderWidth),
            boxShadow: highlightRow
                ? const [
                    BoxShadow(
                      color: AppColors.primaryGlowSubtle,
                      blurRadius: 10,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: avatarBg,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  short,
                  style: AppTypography.monoSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: avatarFg,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        displayName,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isGameAdmin) ...[
                      const SizedBox(width: AppSpacing.xs),
                      const Icon(
                        Icons.workspace_premium,
                        size: 16,
                        color: Color(0xFFEAB308),
                      ),
                    ],
                  ],
                ),
              ),
              const StatusBadge(status: GameStatusBadge.joined),
            ],
          ),
        ),
        if (showKickButton)
          Positioned(
            top: -6,
            right: -6,
            child: Material(
              color: AppColors.background,
              clipBehavior: Clip.antiAlias,
              shape: const CircleBorder(
                side: BorderSide(color: AppColors.secondary),
              ),
              child: InkWell(
                key: ValueKey('lobby-kick-$playerId'),
                customBorder: const CircleBorder(),
                onTap: onKick,
                splashColor: AppColors.secondary.withValues(alpha: 0.45),
                highlightColor: AppColors.secondary.withValues(alpha: 0.18),
                splashFactory: InkRipple.splashFactory,
                radius: 22,
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(
                    Icons.close,
                    size: 12,
                    color: AppColors.secondary,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
