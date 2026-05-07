import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart'
    show AppFontFamilies, AppTypography;
import 'status_badge.dart';
import 'surface_card.dart';

/// Game summary row for the home discovery list.
class GameCard extends StatelessWidget {
  const GameCard({
    super.key,
    required this.title,
    required this.description,
    required this.status,
    required this.playerCount,
    required this.maxPlayers,
    this.onOpen,
  });

  final String title;
  final String description;
  final GameStatusBadge status;
  final int playerCount;
  final int maxPlayers;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      radius: AppRadius.lg,
      padding: const EdgeInsets.all(AppSpacing.lg),
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              StatusBadge(status: status),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontFamily: AppFontFamilies.body,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  '$playerCount/$maxPlayers players',
                  style: AppTypography.monoSmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xs),
                child: Icon(
                  Icons.arrow_forward,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
