import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/enums/game_security.dart';
import '../../data/enums/game_state.dart';
import '../../data/models/game.dart';
import '../../ui/screens/home/home_mock_data.dart';
import '../../ui/widgets/status_badge.dart';
import '../auth_provider.dart';
import '../game_repository_provider.dart';

part 'home_view_data_provider.g.dart';

/// Admin set envelope price / discarded — no longer "in play" for home retention.
bool _gameFullyConcluded(GameState state) {
  return state == GameState.gameFinalised || state == GameState.discarded;
}

/// `trading_ended` is still an active session (envelope / results stage), not a
/// terminal "game over" row — joined tiles stay until [GameState] is fully
/// concluded, then the usual recent window applies.
bool _joinedTileEligibleForRecentEndedWindow(GameState state) {
  return _gameFullyConcluded(state);
}

/// Public discovery: only games players can still join.
bool _publicGameJoinable(GameState state) {
  return state == GameState.created || state == GameState.tradingStarted;
}

/// When [GameState] is [GameState.gameFinalised] or [GameState.discarded],
/// [Game.endTimeActual] is when trading stopped — not when the game concluded.
/// [Game.updatedAt] is bumped on that transition (DB `games_set_updated_at`).
DateTime _gameConcludedAtUtc(Game g) => g.updatedAt;

bool _concludedWithinTenMinutes(Game g, DateTime nowUtc) {
  final concludedAt = _gameConcludedAtUtc(g);
  return nowUtc.difference(concludedAt) <= const Duration(minutes: 10);
}

bool _shouldShowJoinedTile(Game g, DateTime nowUtc) {
  if (!_joinedTileEligibleForRecentEndedWindow(g.gameState)) return true;
  return _concludedWithinTenMinutes(g, nowUtc);
}

bool _shouldShowPublicNotJoinedTile(Game g) {
  return _publicGameJoinable(g.gameState);
}

/// Maps [Game] rows into [MockHomeGame] tiles for [HomeScreen].
///
/// Exposed for unit tests (Phase 2B.2 contract).
///
/// [nowUtc] defaults to [DateTime.now] (UTC comparison uses stored UTC fields).
List<MockHomeGame> mockHomeGamesFromRepositorySnapshot({
  required List<Game> joinedGames,
  required List<Game> publicGames,
  required Map<String, int> playerCountByGameId,
  required String viewerPlayerId,
  DateTime? nowUtc,
}) {
  final clock = nowUtc ?? DateTime.now().toUtc();
  final joinedIds = joinedGames.map((g) => g.gameId).toSet();
  final out = <MockHomeGame>[];

  void addTile(Game g, {required bool isJoined}) {
    final openEnvelope = isJoined && g.gameState == GameState.tradingEnded;
    out.add(
      MockHomeGame(
        id: g.gameId,
        title: g.gameName,
        description: g.gameDescription ?? '',
        status: _statusBadge(
          g,
          isJoined: isJoined,
        ),
        isPublic: g.gameSecurity == GameSecurity.public,
        isJoined: isJoined,
        isAdmin: g.adminPlayerId == viewerPlayerId,
        playerCount: playerCountByGameId[g.gameId] ?? 0,
        maxPlayers: g.gameMaxPlayers,
        openEnvelopeResults: openEnvelope,
      ),
    );
  }

  for (final g in joinedGames) {
    if (!_shouldShowJoinedTile(g, clock)) continue;
    addTile(g, isJoined: true);
  }
  for (final g in publicGames) {
    if (!joinedIds.contains(g.gameId)) {
      if (!_shouldShowPublicNotJoinedTile(g)) continue;
      addTile(g, isJoined: false);
    }
  }
  return out;
}

GameStatusBadge _statusBadge(
  Game g, {
  required bool isJoined,
}) {
  if (!isJoined) {
    return GameStatusBadge.notJoined;
  }
  switch (g.gameState) {
    case GameState.created:
      return GameStatusBadge.joined;
    case GameState.tradingStarted:
    case GameState.tradingEnded:
      return GameStatusBadge.playing;
    case GameState.gameFinalised:
    case GameState.discarded:
      return GameStatusBadge.ended;
  }
}

/// Joined + public discovery rows for the signed-in player (Phase 2B.2).
///
/// [silentRefresh] updates the list **without** going through [AsyncLoading],
/// so periodic / resume refreshes do not flash the loading skeleton.
@Riverpod(keepAlive: true)
class HomeViewData extends _$HomeViewData {
  @override
  Future<List<MockHomeGame>> build() async => _load();

  /// Background refresh (timer / resume / post-command). Keeps prior data
  /// visible while fetching — no loading flicker on success.
  Future<void> silentRefresh() async {
    try {
      final next = await _load();
      state = AsyncValue.data(next);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<List<MockHomeGame>> _load() async {
    final player = await ref.watch(authControllerProvider.future);
    if (player == null) return const [];

    final repo = ref.watch(gameRepositoryProvider);
    final listResults = await Future.wait([
      repo.fetchJoinedGames(player.playerId),
      repo.fetchPublicGames(),
    ]);
    final joined = listResults[0];
    final public = listResults[1];

    final joinedIds = joined.map((g) => g.gameId).toSet();
    final publicOnly =
        public.where((g) => !joinedIds.contains(g.gameId)).toList();
    final gameIds = [
      for (final g in joined) g.gameId,
      for (final g in publicOnly) g.gameId,
    ];
    final playerCountByGameId = await repo.fetchPlayerCountsByGameIds(gameIds);

    return mockHomeGamesFromRepositorySnapshot(
      joinedGames: joined,
      publicGames: publicOnly,
      playerCountByGameId: playerCountByGameId,
      viewerPlayerId: player.playerId,
    );
  }
}
