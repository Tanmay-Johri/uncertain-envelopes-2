import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/repositories/game_repository.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/game_repository_provider.dart';
import '../../../providers/view_data/home_view_data_provider.dart';
import '../../widgets/code_input.dart';
import '../../widgets/game_card.dart';
import '../../widgets/neon_button.dart';
import 'home_mock_data.dart';

enum _HomeListTab { joined, public }

/// Stream C home: joining code + game discovery.
///
/// When [games] is non-null, that list is used (widget tests / overrides).
/// When [games] is null, tiles load from [homeViewDataProvider] (Phase 2B.2).
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.onEnterGame,
    this.onOpenGame,
    this.games,
  });

  /// Called with a five-character joining code when the user taps Enter.
  ///
  /// When null and [games] is null, [joinByCode] runs against
  /// [gameRepositoryProvider] for the signed-in player.
  final ValueChanged<String>? onEnterGame;

  /// Called with a game id when the user opens a row from the list.
  final ValueChanged<String>? onOpenGame;

  /// When set, this list is shown instead of [homeViewDataProvider].
  final List<MockHomeGame>? games;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _code = '';
  _HomeListTab _tab = _HomeListTab.joined;
  bool _adminOnly = false;

  Iterable<MockHomeGame> _filtered(List<MockHomeGame> games) {
    return games.where(
      (g) => mockHomeGamePassesFilters(
        g,
        joinedTab: _tab == _HomeListTab.joined,
        adminOnly: _adminOnly,
      ),
    );
  }

  Future<void> _submitJoin(BuildContext context, WidgetRef? ref, String code) async {
    if (widget.onEnterGame != null) {
      widget.onEnterGame!.call(code);
      return;
    }
    if (ref == null) return;

    final player = ref.read(authControllerProvider).valueOrNull;
    if (player == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to join a game.')),
      );
      return;
    }

    try {
      final result = await ref.read(gameRepositoryProvider).joinByCode(
            code: code.toUpperCase(),
            playerId: player.playerId,
          );
      if (!context.mounted) return;
      context.go(AppRoutes.gameLobby(result.gameId));
    } on GameNotFoundException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  Widget _buildContent({
    required BuildContext context,
    required List<MockHomeGame> games,
    WidgetRef? ref,
    bool listLoading = false,
    String? listError,
  }) {
    final filtered = _filtered(games).toList();

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
                onPressed: () {
                  if (_code.length == 5) {
                    unawaited(_submitJoin(context, ref, _code));
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
              if (listError != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Text(
                    listError,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                )
              else if (listLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
                  child: Center(
                    child: SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    ),
                  ),
                )
              else if (filtered.isEmpty)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
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

  @override
  Widget build(BuildContext context) {
    final injected = widget.games;
    if (injected != null) {
      return _buildContent(context: context, games: injected, ref: null);
    }

    return Consumer(
      builder: (context, ref, _) {
        final async = ref.watch(homeViewDataProvider);
        return async.when(
          data: (games) => _buildContent(
            context: context,
            games: games,
            ref: ref,
          ),
          loading: () => _buildContent(
            context: context,
            games: const [],
            ref: ref,
            listLoading: true,
          ),
          error: (e, _) => _buildContent(
            context: context,
            games: const [],
            ref: ref,
            listError: '$e',
          ),
        );
      },
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
