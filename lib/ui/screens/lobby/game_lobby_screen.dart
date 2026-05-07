import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../widgets/countdown_timer.dart';
import '../../widgets/neon_button.dart';
import '../../widgets/player_list_tile.dart';
import 'lobby_view_data.dart';

/// Game lobby: header, joining code, optional countdown, participants, actions.
class GameLobbyScreen extends StatelessWidget {
  const GameLobbyScreen({
    super.key,
    required this.data,
    required this.phase,
    required this.currentPlayerId,
    required this.isViewerAdmin,
    this.onStartGame,
    this.onEndGame,
    this.onEnterGame,
    this.onJoinGame,
    this.onLeaveGame,
    this.onKickPlayer,
  });

  final GameLobbyViewData data;
  final GameLobbyPhase phase;
  final String currentPlayerId;
  final bool isViewerAdmin;

  final VoidCallback? onStartGame;
  final VoidCallback? onEndGame;
  final VoidCallback? onEnterGame;
  final VoidCallback? onJoinGame;
  final VoidCallback? onLeaveGame;
  final ValueChanged<String>? onKickPlayer;

  String _displayName(LobbyPlayerView p) {
    if (p.id == currentPlayerId) {
      return '${p.username} (You)';
    }
    return p.username;
  }

  bool _showKick(LobbyPlayerView p) {
    if (!isViewerAdmin || phase != GameLobbyPhase.preStart) return false;
    if (p.id == currentPlayerId) return false;
    return true;
  }

  bool get _viewerJoined => lobbyViewerIsInPlayerList(data, currentPlayerId);

  @override
  Widget build(BuildContext context) {
    final codeDisplay = formatJoiningCodeDisplay(data.joiningCodeRaw);
    final count = data.players.length;
    final canKickAny = isViewerAdmin && phase == GameLobbyPhase.preStart;

    return Scaffold(
      key: const ValueKey('game-lobby-scaffold'),
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background.withValues(alpha: 0.95),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: BackButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
        ),
        title: Text(
          'Lobby',
          key: const ValueKey('game-lobby-appbar-title'),
          style: AppTypography.screenTitle,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                data.gameTitle,
                key: const ValueKey('game-lobby-title'),
                style: AppTypography.heroHeadline,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                data.description,
                style: AppTypography.monoSmall.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _InfoCard(
                child: Column(
                  children: [
                    Text(
                      'JOINING CODE',
                      style: AppTypography.microLabel.copyWith(
                        fontSize: 10,
                        letterSpacing: 1,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      codeDisplay,
                      key: const ValueKey('game-lobby-joining-code-display'),
                      style: AppTypography.monoMedium.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        letterSpacing: 4,
                      ),
                    ),
                  ],
                ),
              ),
              if (data.isTimed && data.tradingTimeRemaining != null) ...[
                const SizedBox(height: AppSpacing.md),
                _InfoCard(
                  child: Column(
                    children: [
                      Text(
                        'TIME REMAINING',
                        style: AppTypography.microLabel.copyWith(
                          fontSize: 10,
                          letterSpacing: 1,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      if (phase == GameLobbyPhase.trading)
                        CountdownTimer(
                          key: const ValueKey('game-lobby-countdown'),
                          initialRemaining: data.tradingTimeRemaining!,
                        )
                      else
                        Text(
                          formatCountdownMmSs(data.tradingTimeRemaining!),
                          key: const ValueKey(
                            'game-lobby-time-remaining-static',
                          ),
                          style: AppTypography.monoMedium.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: 2,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _MetaTile(
                      label: 'SECURITY',
                      icon: data.isPublic ? Icons.public : Icons.lock_outline,
                      value: data.isPublic ? 'Public' : 'Private',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _MetaTile(
                      label: 'RANKED',
                      value: data.isRanked ? 'Yes' : 'No',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sectionGap),
              Divider(height: 1, color: AppColors.outlineSubtle),
              const SizedBox(height: AppSpacing.sectionGap),
              Text(
                'PARTICIPANTS ($count/${data.maxPlayers})',
                key: const ValueKey('game-lobby-participants-header'),
                style: AppTypography.microLabel.copyWith(
                  fontSize: 12,
                  letterSpacing: 1.2,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ...data.players.map((p) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: PlayerListTile(
                    key: ValueKey('lobby-player-${p.id}'),
                    playerId: p.id,
                    initials: p.initials,
                    displayName: _displayName(p),
                    isGameAdmin: p.isGameAdmin,
                    highlightRow: p.id == currentPlayerId,
                    showKickButton: _showKick(p),
                    onKick: canKickAny && onKickPlayer != null
                        ? () => onKickPlayer!(p.id)
                        : null,
                  ),
                );
              }),
              const SizedBox(height: AppSpacing.xxl),
              if (isViewerAdmin) ...[
                if (phase == GameLobbyPhase.preStart)
                  NeonButton(
                    key: const ValueKey('game-lobby-start'),
                    label: 'Start Game',
                    onPressed: onStartGame,
                  )
                else
                  NeonButton(
                    key: const ValueKey('game-lobby-enter'),
                    label: 'Enter Game',
                    onPressed: onEnterGame,
                  ),
                const SizedBox(height: AppSpacing.md),
                NeonButton(
                  key: const ValueKey('game-lobby-end'),
                  label: 'End Game',
                  variant: NeonButtonVariant.outlineDanger,
                  onPressed: onEndGame,
                ),
              ] else if (!_viewerJoined) ...[
                NeonButton(
                  key: const ValueKey('game-lobby-join'),
                  label: 'Join Game',
                  onPressed: onJoinGame,
                ),
              ] else if (phase == GameLobbyPhase.preStart) ...[
                NeonButton(
                  key: const ValueKey('game-lobby-leave'),
                  label: 'Leave Game',
                  variant: NeonButtonVariant.outline,
                  onPressed: onLeaveGame,
                ),
              ] else ...[
                NeonButton(
                  key: const ValueKey('game-lobby-enter'),
                  label: 'Enter Game',
                  onPressed: onEnterGame,
                ),
              ],
              const SizedBox(height: AppSpacing.xxxxl),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.outline),
      ),
      child: child,
    );
  }
}

class _MetaTile extends StatelessWidget {
  const _MetaTile({
    required this.label,
    required this.value,
    this.icon,
    this.iconColor,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final valueStyle = AppTypography.bodyMedium.copyWith(
      fontWeight: FontWeight.w600,
    );
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.microLabel.copyWith(
              fontSize: 10,
              letterSpacing: 1,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          if (icon != null)
            Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: iconColor ?? AppColors.textPrimary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    value,
                    style: valueStyle,
                  ),
                ),
              ],
            )
          else
            Text(value, style: valueStyle),
        ],
      ),
    );
  }
}
