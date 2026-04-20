import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/data/enums/end_condition.dart';
import 'package:uncertain_envelopes_2/data/enums/game_security.dart';
import 'package:uncertain_envelopes_2/data/enums/game_state.dart';
import 'package:uncertain_envelopes_2/data/enums/is_ranked.dart';
import 'package:uncertain_envelopes_2/data/enums/lobby_status.dart';
import 'package:uncertain_envelopes_2/data/models/game.dart';
import 'package:uncertain_envelopes_2/data/models/game_player.dart';
import 'package:uncertain_envelopes_2/data/repositories/game_repository.dart';
import 'package:uncertain_envelopes_2/data/repositories/in_memory_command_repository.dart';
import 'package:uncertain_envelopes_2/data/repositories/in_memory_game_repository.dart';
import 'package:uncertain_envelopes_2/providers/clock_provider.dart';
import 'package:uncertain_envelopes_2/providers/game_provider.dart';
import 'package:uncertain_envelopes_2/providers/game_repository_provider.dart';

Game _game({
  String id = 'g-1',
  GameState state = GameState.created,
  EndCondition endCondition = EndCondition.endless,
  DateTime? startTime,
  DateTime? endTimeDecided,
  int? duration,
}) {
  return Game(
    gameId: id,
    gameName: 'Game',
    gameCreatedAt: DateTime.utc(2026, 1, 1, 10),
    gameSecurity: GameSecurity.public,
    isRanked: IsRanked.casual,
    gameMaxPlayers: 10,
    joiningCode: 'AB12C',
    endCondition: endCondition,
    gameState: state,
    adminPlayerId: 'p-admin',
    stateVersion: 1,
    updatedAt: DateTime.utc(2026, 1, 1, 10),
    startTime: startTime,
    endTimeDecided: endTimeDecided,
    totalDecidedDurationSeconds: duration,
  );
}

GamePlayer _player({
  required String rowId,
  required String playerId,
  String gameId = 'g-1',
  bool isAdmin = false,
  DateTime? joinedAt,
}) {
  return GamePlayer(
    gamesPlayersRowId: rowId,
    mapGameId: gameId,
    mapPlayerId: playerId,
    lobbyStatus: LobbyStatus.playing,
    joinedAt: joinedAt ?? DateTime.utc(2026, 1, 1, 10),
    isAdmin: isAdmin,
    deltaCash: 0,
    deltaEnvelopes: 0,
    pnl: 0,
  );
}

void main() {
  late InMemoryGameRepository repo;
  late InMemoryCommandRepository commands;

  setUp(() {
    commands = InMemoryCommandRepository();
    repo = InMemoryGameRepository(commandRepository: commands);
  });

  ProviderContainer containerWithClock({
    DateTime Function()? clock,
    StreamController<DateTime>? ticks,
  }) {
    return ProviderContainer(
      overrides: [
        gameRepositoryProvider.overrideWithValue(repo),
        if (clock != null) clockProvider.overrideWith((_) => clock),
        if (ticks != null)
          timerTickStreamProvider.overrideWith((_) => ticks.stream),
      ],
    );
  }

  group('CurrentGame', () {
    test('loads game + players from the repository', () async {
      repo.seedGame(_game());
      repo.seedGamePlayer(_player(
        rowId: 'r-1',
        playerId: 'p-admin',
        isAdmin: true,
        joinedAt: DateTime.utc(2026, 1, 1, 10),
      ));
      repo.seedGamePlayer(_player(
        rowId: 'r-2',
        playerId: 'p-2',
        joinedAt: DateTime.utc(2026, 1, 1, 10, 1),
      ));

      final container = containerWithClock();
      addTearDown(container.dispose);

      final snapshot =
          await container.read(currentGameProvider('g-1').future);
      expect(snapshot.game.gameId, 'g-1');
      expect(snapshot.players.length, 2);
      expect(snapshot.isAdmin('p-admin'), true);
      expect(snapshot.isAdmin('p-2'), false);
    });

    test('throws GameNotFoundException when the game is missing', () async {
      final container = containerWithClock();
      addTearDown(container.dispose);
      expect(
        () => container.read(currentGameProvider('missing').future),
        throwsA(isA<GameNotFoundException>()),
      );
    });

    test('applyPlayerUpsert adds a new player without refetching', () async {
      repo.seedGame(_game());
      final container = containerWithClock();
      addTearDown(container.dispose);
      await container.read(currentGameProvider('g-1').future);

      container
          .read(currentGameProvider('g-1').notifier)
          .applyPlayerUpsert(_player(rowId: 'r-1', playerId: 'p-1'));

      final snapshot =
          container.read(currentGameProvider('g-1')).valueOrNull!;
      expect(snapshot.players.map((p) => p.mapPlayerId), ['p-1']);
    });

    test('applyPlayerUpsert updates an existing row by row id', () async {
      repo.seedGame(_game());
      final container = containerWithClock();
      addTearDown(container.dispose);
      await container.read(currentGameProvider('g-1').future);

      final notifier = container.read(currentGameProvider('g-1').notifier);
      notifier.applyPlayerUpsert(_player(rowId: 'r-1', playerId: 'p-1'));
      notifier.applyPlayerUpsert(
        _player(rowId: 'r-1', playerId: 'p-1', isAdmin: true),
      );

      final snapshot =
          container.read(currentGameProvider('g-1')).valueOrNull!;
      expect(snapshot.players.length, 1);
      expect(snapshot.players.single.isAdmin, true);
    });

    test('applyPlayerRemoval removes by player id', () async {
      repo.seedGame(_game());
      final container = containerWithClock();
      addTearDown(container.dispose);
      await container.read(currentGameProvider('g-1').future);

      final notifier = container.read(currentGameProvider('g-1').notifier);
      notifier.applyPlayerUpsert(_player(rowId: 'r-1', playerId: 'p-1'));
      notifier.applyPlayerUpsert(_player(rowId: 'r-2', playerId: 'p-2'));
      notifier.applyPlayerRemoval('p-1');

      final snapshot =
          container.read(currentGameProvider('g-1')).valueOrNull!;
      expect(snapshot.players.map((p) => p.mapPlayerId), ['p-2']);
    });

    test('applyGameUpdate ignores updates for a different gameId', () async {
      repo.seedGame(_game());
      final container = containerWithClock();
      addTearDown(container.dispose);
      await container.read(currentGameProvider('g-1').future);

      container.read(currentGameProvider('g-1').notifier).applyGameUpdate(
            _game(id: 'g-other', state: GameState.tradingEnded),
          );
      final snapshot =
          container.read(currentGameProvider('g-1')).valueOrNull!;
      expect(snapshot.game.gameState, GameState.created);
    });

    test('applyGameUpdate swaps the game field when id matches', () async {
      repo.seedGame(_game());
      final container = containerWithClock();
      addTearDown(container.dispose);
      await container.read(currentGameProvider('g-1').future);

      container.read(currentGameProvider('g-1').notifier).applyGameUpdate(
            _game(id: 'g-1', state: GameState.tradingStarted),
          );
      final snapshot =
          container.read(currentGameProvider('g-1')).valueOrNull!;
      expect(snapshot.game.gameState, GameState.tradingStarted);
    });

    test('refresh re-reads from the repository', () async {
      repo.seedGame(_game());
      final container = containerWithClock();
      addTearDown(container.dispose);
      await container.read(currentGameProvider('g-1').future);

      // Simulate a backend change outside the provider.
      repo.seedGame(_game(state: GameState.tradingStarted));

      await container.read(currentGameProvider('g-1').notifier).refresh();
      final snapshot =
          container.read(currentGameProvider('g-1')).valueOrNull!;
      expect(snapshot.game.gameState, GameState.tradingStarted);
    });

    test('delta applied BEFORE data loads is silently ignored', () async {
      final container = containerWithClock();
      addTearDown(container.dispose);
      // Read the notifier but don't await the future; state is loading.
      final notifier = container.read(currentGameProvider('g-1').notifier);
      notifier.applyPlayerUpsert(_player(rowId: 'r-1', playerId: 'p-1'));
      // No exception, no state flip to data.
      expect(container.read(currentGameProvider('g-1')).valueOrNull, isNull);
    });
  });

  group('lobbyPlayers', () {
    test('is empty while loading', () async {
      final container = containerWithClock();
      addTearDown(container.dispose);
      expect(container.read(lobbyPlayersProvider('g-1')), isEmpty);
    });

    test('sorts by joinedAt ascending', () async {
      repo.seedGame(_game());
      repo.seedGamePlayer(_player(
        rowId: 'r-3',
        playerId: 'p-3',
        joinedAt: DateTime.utc(2026, 1, 1, 10, 3),
      ));
      repo.seedGamePlayer(_player(
        rowId: 'r-1',
        playerId: 'p-1',
        joinedAt: DateTime.utc(2026, 1, 1, 10, 1),
      ));
      repo.seedGamePlayer(_player(
        rowId: 'r-2',
        playerId: 'p-2',
        joinedAt: DateTime.utc(2026, 1, 1, 10, 2),
      ));

      final container = containerWithClock();
      addTearDown(container.dispose);
      await container.read(currentGameProvider('g-1').future);

      final ids = container
          .read(lobbyPlayersProvider('g-1'))
          .map((p) => p.mapPlayerId)
          .toList();
      expect(ids, ['p-1', 'p-2', 'p-3']);
    });

    test('updates when a player is upserted via CurrentGame', () async {
      repo.seedGame(_game());
      final container = containerWithClock();
      addTearDown(container.dispose);
      await container.read(currentGameProvider('g-1').future);

      container
          .read(currentGameProvider('g-1').notifier)
          .applyPlayerUpsert(_player(rowId: 'r-new', playerId: 'p-new'));
      expect(
        container.read(lobbyPlayersProvider('g-1')).length,
        1,
      );
    });
  });

  group('gameSecondsRemaining', () {
    test('returns null for an endless game', () async {
      repo.seedGame(_game(endCondition: EndCondition.endless));
      final container = containerWithClock(
        clock: () => DateTime.utc(2026, 1, 1, 10),
      );
      addTearDown(container.dispose);
      await container.read(currentGameProvider('g-1').future);
      expect(container.read(gameSecondsRemainingProvider('g-1')), isNull);
    });

    test(
      'returns null for a timed game that has not started yet',
      () async {
        repo.seedGame(_game(endCondition: EndCondition.timed));
        final container = containerWithClock(
          clock: () => DateTime.utc(2026, 1, 1, 10),
        );
        addTearDown(container.dispose);
        await container.read(currentGameProvider('g-1').future);
        expect(
          container.read(gameSecondsRemainingProvider('g-1')),
          isNull,
        );
      },
    );

    test(
      'computes seconds from clock to end_time_decided',
      () async {
        repo.seedGame(_game(
          endCondition: EndCondition.timed,
          startTime: DateTime.utc(2026, 1, 1, 10),
          endTimeDecided: DateTime.utc(2026, 1, 1, 10, 5),
          duration: 300,
        ));
        final clock = DateTime.utc(2026, 1, 1, 10, 1);
        final container = containerWithClock(clock: () => clock);
        addTearDown(container.dispose);
        await container.read(currentGameProvider('g-1').future);
        expect(
          container.read(gameSecondsRemainingProvider('g-1')),
          4 * 60,
        );
      },
    );

    test(
      'ticks via timerTickStreamProvider override',
      () async {
        repo.seedGame(_game(
          endCondition: EndCondition.timed,
          startTime: DateTime.utc(2026, 1, 1, 10),
          endTimeDecided: DateTime.utc(2026, 1, 1, 10, 0, 10),
          duration: 10,
        ));
        final controller = StreamController<DateTime>.broadcast();
        addTearDown(controller.close);
        final container = containerWithClock(
          clock: () => DateTime.utc(2026, 1, 1, 10),
          ticks: controller,
        );
        addTearDown(container.dispose);
        await container.read(currentGameProvider('g-1').future);

        // Subscribe so the provider is alive.
        container.listen<int?>(
          gameSecondsRemainingProvider('g-1'),
          (_, __) {},
          fireImmediately: true,
        );

        controller.add(DateTime.utc(2026, 1, 1, 10, 0, 3));
        await Future<void>.delayed(Duration.zero);
        expect(container.read(gameSecondsRemainingProvider('g-1')), 7);

        controller.add(DateTime.utc(2026, 1, 1, 10, 0, 9));
        await Future<void>.delayed(Duration.zero);
        expect(container.read(gameSecondsRemainingProvider('g-1')), 1);

        // Past the deadline: clamped to 0, never negative.
        controller.add(DateTime.utc(2026, 1, 1, 10, 0, 20));
        await Future<void>.delayed(Duration.zero);
        expect(container.read(gameSecondsRemainingProvider('g-1')), 0);
      },
    );

    test('reacts to add_time by recomputing against new end_time_decided',
        () async {
      repo.seedGame(_game(
        endCondition: EndCondition.timed,
        startTime: DateTime.utc(2026, 1, 1, 10),
        endTimeDecided: DateTime.utc(2026, 1, 1, 10, 0, 5),
        duration: 5,
      ));
      final container = containerWithClock(
        clock: () => DateTime.utc(2026, 1, 1, 10),
      );
      addTearDown(container.dispose);
      await container.read(currentGameProvider('g-1').future);

      expect(container.read(gameSecondsRemainingProvider('g-1')), 5);

      container.read(currentGameProvider('g-1').notifier).applyGameUpdate(
            _game(
              id: 'g-1',
              endCondition: EndCondition.timed,
              startTime: DateTime.utc(2026, 1, 1, 10),
              endTimeDecided: DateTime.utc(2026, 1, 1, 10, 0, 30),
              duration: 30,
            ),
          );

      expect(container.read(gameSecondsRemainingProvider('g-1')), 30);
    });
  });
}
