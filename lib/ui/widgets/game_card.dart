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
    required this.playerInitials,
    this.dimmed = false,
    this.onOpen,
  });

  final String title;
  final String description;
  final GameStatusBadge status;
  final List<String> playerInitials;
  final bool dimmed;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final opacity = dimmed ? 0.72 : 1.0;

    return Opacity(
      opacity: opacity,
      child: SurfaceCard(
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
                Expanded(child: _AvatarStack(initials: playerInitials)),
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
      ),
    );
  }
}

class _AvatarStack extends StatelessWidget {
  const _AvatarStack({required this.initials});

  final List<String> initials;

  @override
  Widget build(BuildContext context) {
    if (initials.isEmpty) {
      return Text(
        'no players yet',
        style: AppTypography.monoSmall.copyWith(color: AppColors.textTertiary),
      );
    }

    if (initials.length <= 3) {
      return _OverlappingCircles(
        children: initials
            .map(
              (s) => _Circle(initial: s.isEmpty ? '?' : s[0].toUpperCase()),
            )
            .toList(),
      );
    }

    final extra = initials.length - 2;
    return _OverlappingCircles(
      children: [
        _Circle(initial: initials[0].toUpperCase()),
        _Circle(initial: initials[1].toUpperCase()),
        _Circle(overflow: '+$extra'),
      ],
    );
  }
}

class _OverlappingCircles extends StatelessWidget {
  const _OverlappingCircles({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    const size = 24.0;
    final overlap = size * 0.55;
    final width = size + (children.length - 1) * overlap;
    return SizedBox(
      width: width,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < children.length; i++)
            Positioned(
              left: i * overlap,
              child: children[i],
            ),
        ],
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  const _Circle({this.initial, this.overflow})
      : assert(
          (initial != null && overflow == null) ||
              (initial == null && overflow != null),
        );

  final String? initial;
  final String? overflow;

  @override
  Widget build(BuildContext context) {
    final isOverflow = overflow != null;
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isOverflow ? AppColors.surfaceHighlight : AppColors.surfaceContainerHigh,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.background, width: 1),
      ),
      child: Text(
        isOverflow ? overflow! : initial!,
        style: TextStyle(
          fontFamily: AppFontFamilies.mono,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: isOverflow ? AppColors.textTertiary : AppColors.textPrimary,
        ),
      ),
    );
  }
}
