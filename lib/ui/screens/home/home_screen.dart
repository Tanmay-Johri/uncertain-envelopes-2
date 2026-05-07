import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../widgets/code_input.dart';
import '../../widgets/game_card.dart';
import '../../widgets/neon_button.dart';
import '../../widgets/status_badge.dart';
import 'home_mock_data.dart';

enum _HomeListTab { joined, public }

/// Stream C home: joining code + game discovery (mock data).
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.onEnterGame,
    this.onOpenGame,
    this.games = kMockHomeGames,
  });

  /// Called with a five-character joining code when the user taps Enter.
  final ValueChanged<String>? onEnterGame;

  /// Called with a game id when the user opens a row from the list.
  final ValueChanged<String>? onOpenGame;

  /// Override for tests; defaults to [kMockHomeGames].
  final List<MockHomeGame> games;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _code = '';
  _HomeListTab _tab = _HomeListTab.joined;
  bool _adminOnly = false;

  Iterable<MockHomeGame> get _filtered {
    return widget.games.where(
      (g) => mockHomeGamePassesFilters(
        g,
        joinedTab: _tab == _HomeListTab.joined,
        adminOnly: _adminOnly,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered.toList();

    return Scaffold(
      key: const ValueKey('home-screen'),
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xxl,
            AppSpacing.md,
            AppSpacing.xxl,
            AppSpacing.xxxxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'ENTER JOINING CODE',
                textAlign: TextAlign.center,
                style: AppTypography.label.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              CodeInput(
                onChanged: (c) => setState(() => _code = c),
              ),
              const SizedBox(height: AppSpacing.md),
              NeonButton(
                label: 'Enter game',
                expand: true,
                // Always primary (green); submission only when code is complete.
                onPressed: () {
                  if (_code.length == 5) {
                    widget.onEnterGame?.call(_code);
                  }
                },
              ),
              const SizedBox(height: AppSpacing.sectionGap),
              _TabBar(
                tab: _tab,
                onChanged: (t) => setState(() => _tab = t),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'YOU ARE ADMIN',
                    style: AppTypography.microLabel,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Switch(
                    value: _adminOnly,
                    activeThumbColor: AppColors.primary,
                    activeTrackColor: AppColors.primary.withValues(alpha: 0.35),
                    inactiveThumbColor: AppColors.textSecondary,
                    inactiveTrackColor: AppColors.surfaceContainerHigh,
                    onChanged: (v) => setState(() => _adminOnly = v),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              if (filtered.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
                  child: Text(
                    'No games match your filters.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, i) {
                    final g = filtered[i];
                    return GameCard(
                      key: ValueKey('game-card-${g.id}'),
                      title: g.title,
                      description: g.description,
                      status: g.status,
                      playerCount: g.playerInitials.length,
                      maxPlayers: g.maxPlayers,
                      onOpen: () => widget.onOpenGame?.call(g.id),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({
    required this.tab,
    required this.onChanged,
  });

  final _HomeListTab tab;
  final ValueChanged<_HomeListTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TabButton(
            label: 'JOINED GAMES',
            selected: tab == _HomeListTab.joined,
            onTap: () => onChanged(_HomeListTab.joined),
          ),
        ),
        Expanded(
          child: _TabButton(
            label: 'PUBLIC GAMES',
            selected: tab == _HomeListTab.public,
            onTap: () => onChanged(_HomeListTab.public),
          ),
        ),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const double _indicatorHeight = 2;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.lg,
          horizontal: AppSpacing.sm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTypography.label.copyWith(
                color: selected ? AppColors.primary : AppColors.textTertiary,
                fontSize: 12,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: _indicatorHeight,
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
