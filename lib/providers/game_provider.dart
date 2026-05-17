import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/enums/end_condition.dart';
import '../data/models/game.dart';
import '../data/models/game_player.dart';
import '../data/models/game_session_state.dart';
import '../data/repositories/game_repository.dart';
import 'clock_provider.dart';
import 'game_repository_provider.dart';

part 'game_provider.g.dart';

/// Fetches the full game + players snapshot and exposes mutation hooks
/// used by the realtime service (B10) to apply realtime deltas.
@riverpod
class CurrentGame extends _$CurrentGame {
  @override
  Future<GameSessionState> build(String gameId) async {
    final repo = ref.watch(gameRepositoryProvider);
    return _load(repo, gameId);
  }

  Future<GameSessionState> _load(
    GameRepository repo,
    String gameId,
  ) async {
    // After join_game / create_game the processor may lag briefly; RLS can
    // hide `games` until membership exists — retry without surfacing a
    // misleading "joining code" error that shows a UUID.
    const maxAttempts = 28;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final game = await repo.fetchGame(gameId);
      if (game != null) {
        final players = await repo.fetchGamePlayers(gameId);
        return GameSessionState(game: game, players: players);
      }
      final delayMs = attempt < 8 ? 80 : 160;
      await Future<void>.delayed(Duration(milliseconds: delayMs));
    }
    throw GameNotFoundException.gameUnavailable(gameId);
  }

  /// Re-fetches the whole snapshot from the repository. Used on
  /// realtime version mismatches (the repair path).
  ///
  /// Does **not** set [AsyncLoading] first: downstream providers that
  /// `await ref.watch(currentGameProvider(gameId).future)` (e.g. results /
  /// trading view data) share Riverpod's internal future-completer machinery
  /// with this notifier; forcing an extra loading transition after data has
  /// already loaded can trigger `StateError: Bad state: Future already
  /// completed` when that transition races with an in-flight await (common
  /// right after **end game**, when this refresh runs alongside realtime).
  Future<void> refresh() async {
    final repo = ref.read(gameRepositoryProvider);
    state = await AsyncValue.guard(() => _load(repo, gameId));
  }

  /// Replace the entire snapshot. Used when the realtime service performs
  /// a full-refresh after a version mismatch.
  void replaceSnapshot(GameSessionState snapshot) {
    state = AsyncValue.data(snapshot);
  }

  /// Applies a delta to the [Game] row (INSERT/UPDATE realtime events).
  /// Silently ignored if the state has not yet loaded data.
  void applyGameUpdate(Game updated) {
    final current = state.valueOrNull;
    if (current == null) return;
    if (updated.gameId != current.game.gameId) return;
    state = AsyncValue.data(current.copyWith(game: updated));
  }

  /// Upserts a single `games_players` row.
  void applyPlayerUpsert(GamePlayer player) {
    final current = state.valueOrNull;
    if (current == null) return;
    if (player.mapGameId != current.game.gameId) return;
    state = AsyncValue.data(current.upsertPlayer(player));
  }

  /// Removes a player by `map_player_id` (leave / kick event).
  void applyPlayerRemoval(String playerId) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncValue.data(current.removePlayerByPlayerId(playerId));
  }
}

/// Just the lobby players list, sorted by `joined_at` ascending so the UI
/// shows players in join order. Returns an empty list while the snapshot
/// is still loading so the UI can show a skeleton without null-checking.
@riverpod
List<GamePlayer> lobbyPlayers(Ref ref, String gameId) {
  final snapshot = ref.watch(currentGameProvider(gameId));
  final players = snapshot.valueOrNull?.players ?? const <GamePlayer>[];
  final sorted = [...players]
    ..sort((a, b) => a.joinedAt.compareTo(b.joinedAt));
  return List.unmodifiable(sorted);
}

/// Seconds remaining in a timed game. Semantics:
///   - Returns null when the game has not loaded yet.
///   - Returns null for endless games or timed games with no
///     `end_time_decided` (i.e. the game has not started).
///   - Returns >= 0 otherwise; clamped to 0 when the deadline has passed.
///
/// Reactivity: recomputes on every tick of [timerTickStreamProvider] and
/// on every change to [currentGameProvider] (so `add_time` updates are
/// reflected within one tick).
@riverpod
int? gameSecondsRemaining(Ref ref, String gameId) {
  final snapshot = ref.watch(currentGameProvider(gameId));
  final game = snapshot.valueOrNull?.game;
  if (game == null) return null;
  if (game.endCondition != EndCondition.timed) return null;
  final deadline = game.endTimeDecided;
  if (deadline == null) return null;

  final tickAsync = ref.watch(timerTickStreamProvider);
  final now = tickAsync.valueOrNull ?? ref.read(clockProvider)();

  final remaining = deadline.difference(now).inSeconds;
  return remaining < 0 ? 0 : remaining;
}
