import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/enums/game_security.dart';
import '../../data/enums/game_state.dart';
import '../../data/models/game.dart';
import '../../data/repositories/game_repository.dart';
import '../../ui/screens/home/home_mock_data.dart';
import '../../ui/widgets/status_badge.dart';
import '../auth_provider.dart';
import '../game_repository_provider.dart';

part 'home_view_data_provider.g.dart';

/// Maps [Game] rows into [MockHomeGame] tiles for [HomeScreen].
///
/// Exposed for unit tests (Phase 2B.2 contract).
List<MockHomeGame> mockHomeGamesFromRepositorySnapshot({
  required List<Game> joinedGames,
  required List<Game> publicGames,
  required Map<String, List<String>> playerInitialsByGameId,
  required String viewerPlayerId,
}) {
  final joinedIds = joinedGames.map((g) => g.gameId).toSet();
  final out = <MockHomeGame>[];

  void addTile(Game g, {required bool isJoined}) {
    final initials = playerInitialsByGameId[g.gameId] ?? const <String>[];
    out.add(
      MockHomeGame(
        id: g.gameId,
        title: g.gameName,
        description: g.gameDescription ?? '',
        status: _statusBadge(g, isJoined: isJoined, viewerPlayerId: viewerPlayerId),
        isPublic: g.gameSecurity == GameSecurity.public,
        isJoined: isJoined,
        isAdmin: g.adminPlayerId == viewerPlayerId,
        playerInitials: initials,
        maxPlayers: g.gameMaxPlayers,
      ),
    );
  }

  for (final g in joinedGames) {
    addTile(g, isJoined: true);
  }
  for (final g in publicGames) {
    if (!joinedIds.contains(g.gameId)) {
      addTile(g, isJoined: false);
    }
  }
  return out;
}

GameStatusBadge _statusBadge(
  Game g, {
  required bool isJoined,
  required String viewerPlayerId,
}) {
  switch (g.gameState) {
    case GameState.tradingStarted:
      return GameStatusBadge.active;
    case GameState.created:
      if (!isJoined) return GameStatusBadge.notJoined;
      if (g.adminPlayerId == viewerPlayerId) return GameStatusBadge.ready;
      return GameStatusBadge.joined;
    case GameState.tradingEnded:
    case GameState.gameFinalised:
    case GameState.discarded:
      return GameStatusBadge.joined;
  }
}

Future<Map<String, List<String>>> _initialsByGame(
  GameRepository repo,
  Iterable<Game> games,
) async {
  final map = <String, List<String>>{};
  for (final g in games) {
    final players = await repo.fetchGamePlayers(g.gameId);
    map[g.gameId] = [
      for (var i = 0; i < players.length; i++)
        String.fromCharCode(65 + (i % 26)),
    ];
  }
  return map;
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
    final joined = await repo.fetchJoinedGames(player.playerId);
    final public = await repo.fetchPublicGames();

    final joinedIds = joined.map((g) => g.gameId).toSet();
    final publicOnly =
        public.where((g) => !joinedIds.contains(g.gameId)).toList();
    final forInitials = [...joined, ...publicOnly];
    final initialsMap = await _initialsByGame(repo, forInitials);

    return mockHomeGamesFromRepositorySnapshot(
      joinedGames: joined,
      publicGames: publicOnly,
      playerInitialsByGameId: initialsMap,
      viewerPlayerId: player.playerId,
    );
  }
}
