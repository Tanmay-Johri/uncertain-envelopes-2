import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/data/enums/command_type.dart';
import 'package:uncertain_envelopes_2/data/enums/end_condition.dart';
import 'package:uncertain_envelopes_2/data/enums/game_security.dart';
import 'package:uncertain_envelopes_2/data/enums/game_state.dart';
import 'package:uncertain_envelopes_2/data/enums/is_ranked.dart';
import 'package:uncertain_envelopes_2/data/models/game.dart';
import 'package:uncertain_envelopes_2/data/repositories/game_repository.dart';
import 'package:uncertain_envelopes_2/data/repositories/in_memory_command_repository.dart';
import 'package:uncertain_envelopes_2/data/repositories/in_memory_game_repository.dart';
import 'package:uncertain_envelopes_2/data/repositories/supabase_game_repository.dart';
import 'package:uncertain_envelopes_2/services/supabase_game_gateway.dart';

Game _game({
  required String id,
  String name = 'G',
  String code = 'ABCDE',
  GameSecurity security = GameSecurity.public,
  GameState state = GameState.created,
  String admin = 'p-admin',
  DateTime? createdAt,
}) {
  return Game(
    gameId: id,
    gameName: name,
    gameCreatedAt: createdAt ?? DateTime.utc(2026, 1, 1),
    gameSecurity: security,
    isRanked: IsRanked.ranked,
    gameMaxPlayers: 10,
    joiningCode: code,
    endCondition: EndCondition.endless,
    gameState: state,
    adminPlayerId: admin,
    stateVersion: 1,
    updatedAt: DateTime.utc(2026, 1, 1),
  );
}

void main() {
  group('InMemoryGameRepository', () {
    late InMemoryCommandRepository commands;
    late InMemoryGameRepository repo;

    setUp(() {
      commands = InMemoryCommandRepository();
      repo = InMemoryGameRepository(commandRepository: commands);
    });

    test('submitCreateGame forwards to command repository', () async {
      final id = await repo.submitCreateGame(
        adminPlayerId: 'p-1',
        gameName: 'New',
        gameSecurity: GameSecurity.public,
        isRanked: IsRanked.casual,
        gameMaxPlayers: 5,
        endCondition: EndCondition.endless,
      );
      expect(id, commands.inserts.single.commandId);
      expect(commands.inserts.single.type, CommandType.createGame);
      expect(commands.inserts.single.playerId, 'p-1');
    });

    test('createGameAndReturnGameId rejects duplicate active game_name', () async {
      await repo.createGameAndReturnGameId(
        adminPlayerId: 'p-admin',
        gameName: 'Taken',
        gameSecurity: GameSecurity.public,
        isRanked: IsRanked.casual,
        gameMaxPlayers: 4,
        endCondition: EndCondition.endless,
      );
      expect(
        () => repo.createGameAndReturnGameId(
          adminPlayerId: 'p-admin',
          gameName: 'Taken',
          gameSecurity: GameSecurity.public,
          isRanked: IsRanked.casual,
          gameMaxPlayers: 4,
          endCondition: EndCondition.endless,
        ),
        throwsA(isA<ActiveGameNameInUseException>()),
      );
    });

    test('createGameAndReturnGameId allows name reuse after game_finalised',
        () async {
      final firstId = await repo.createGameAndReturnGameId(
        adminPlayerId: 'p-admin',
        gameName: 'Reuse Me',
        gameSecurity: GameSecurity.public,
        isRanked: IsRanked.casual,
        gameMaxPlayers: 4,
        endCondition: EndCondition.endless,
      );
      final ended = (await repo.fetchGame(firstId))!;
      repo.seedGame(
        Game(
          gameId: ended.gameId,
          gameName: ended.gameName,
          gameDescription: ended.gameDescription,
          gameCreatedAt: ended.gameCreatedAt,
          gameSecurity: ended.gameSecurity,
          isRanked: ended.isRanked,
          gameMaxPlayers: ended.gameMaxPlayers,
          joiningCode: ended.joiningCode,
          endCondition: ended.endCondition,
          totalDecidedDurationSeconds: ended.totalDecidedDurationSeconds,
          endTimeDecided: ended.endTimeDecided,
          startTime: ended.startTime,
          endTimeActual: ended.endTimeActual,
          gameState: GameState.gameFinalised,
          adminPlayerId: ended.adminPlayerId,
          lastTradedPrice: ended.lastTradedPrice,
          envelopePrice: ended.envelopePrice,
          stateVersion: ended.stateVersion,
          updatedAt: ended.updatedAt,
        ),
      );
      final secondId = await repo.createGameAndReturnGameId(
        adminPlayerId: 'p-admin',
        gameName: 'Reuse Me',
        gameSecurity: GameSecurity.public,
        isRanked: IsRanked.casual,
        gameMaxPlayers: 4,
        endCondition: EndCondition.endless,
      );
      expect(secondId, isNot(firstId));
    });

    test('createGameAndReturnGameId inserts game and admin membership', () async {
      final gameId = await repo.createGameAndReturnGameId(
        adminPlayerId: 'p-admin',
        gameName: 'Fresh',
        gameDescription: 'd',
        gameSecurity: GameSecurity.private,
        isRanked: IsRanked.ranked,
        gameMaxPlayers: 8,
        endCondition: EndCondition.timed,
        totalDecidedDurationSeconds: 120,
      );
      expect(gameId, isNotEmpty);
      expect(commands.inserts.single.type, CommandType.createGame);
      final g = await repo.fetchGame(gameId);
      expect(g?.gameName, 'Fresh');
      expect(g?.gameSecurity, GameSecurity.private);
      expect(g?.joiningCode.length, 5);
      final players = await repo.fetchGamePlayers(gameId);
      expect(players.single.mapPlayerId, 'p-admin');
      expect(players.single.isAdmin, isTrue);
    });

    test('fetchGame returns null when not seeded', () async {
      expect(await repo.fetchGame('nope'), isNull);
    });

    test('fetchGame returns seeded game', () async {
      repo.seedGame(_game(id: 'g-1'));
      expect((await repo.fetchGame('g-1'))?.gameId, 'g-1');
    });

    test('fetchPublicGames filters by security and state', () async {
      repo.seedGame(_game(id: 'g-public-created', state: GameState.created));
      repo.seedGame(_game(
        id: 'g-public-trading',
        state: GameState.tradingStarted,
        code: 'CODE2',
      ));
      repo.seedGame(_game(
        id: 'g-private',
        security: GameSecurity.private,
        code: 'CODE3',
      ));
      repo.seedGame(_game(
        id: 'g-discarded',
        state: GameState.discarded,
        code: 'CODE4',
      ));
      repo.seedGame(_game(
        id: 'g-finalised',
        state: GameState.gameFinalised,
        code: 'CODE5',
      ));

      final ids = (await repo.fetchPublicGames()).map((g) => g.gameId).toSet();
      expect(ids, {'g-public-created', 'g-public-trading'});
    });

    test('fetchJoinedGames returns games based on membership only', () async {
      repo.seedGame(_game(id: 'g-1'));
      repo.seedGame(_game(id: 'g-2', code: 'CODE2'));
      repo.seedGame(_game(id: 'g-3', code: 'CODE3'));
      repo.seedMembership('g-1', 'p-1');
      repo.seedMembership('g-2', 'p-1');
      repo.seedMembership('g-3', 'p-other');

      final ids = (await repo.fetchJoinedGames('p-1')).map((g) => g.gameId);
      expect(ids.toSet(), {'g-1', 'g-2'});
      expect(await repo.fetchJoinedGames('p-none'), isEmpty);
    });

    test('lookupGameByCode is case-insensitive on input', () async {
      repo.seedGame(_game(id: 'g-1', code: 'XY99Z'));
      expect((await repo.lookupGameByCode('xy99z'))?.gameId, 'g-1');
      expect((await repo.lookupGameByCode('XY99Z'))?.gameId, 'g-1');
      expect(await repo.lookupGameByCode('OTHER'), isNull);
    });

    test(
        'joinByCode submits a join_game command AND records membership',
        () async {
      repo.seedGame(_game(id: 'g-1', code: 'XY99Z'));
      final result = await repo.joinByCode(code: 'xy99z', playerId: 'p-2');
      expect(result.gameId, 'g-1');
      expect(commands.lastOfType(CommandType.joinGame)?.gameId, 'g-1');
      expect(commands.lastOfType(CommandType.joinGame)?.playerId, 'p-2');
      final joined = await repo.fetchJoinedGames('p-2');
      expect(joined.map((g) => g.gameId), ['g-1']);
    });

    test('joinByCode throws GameNotFoundException for unknown code', () {
      expect(
        () => repo.joinByCode(code: 'NONE1', playerId: 'p-2'),
        throwsA(isA<GameNotFoundException>()),
      );
      expect(commands.inserts, isEmpty);
    });

    test('rapid joinByCode for different players records all memberships',
        () async {
      repo.seedGame(_game(id: 'g-1', code: 'XYZ12'));
      for (var i = 0; i < 5; i++) {
        await repo.joinByCode(code: 'XYZ12', playerId: 'p-$i');
      }
      expect(commands.inserts.length, 5);
      for (var i = 0; i < 5; i++) {
        final joined = await repo.fetchJoinedGames('p-$i');
        expect(joined.map((g) => g.gameId), ['g-1']);
      }
    });
  });

  group('SupabaseGameRepository (fake gateway + fake commands)', () {
    late _FakeGameGateway gateway;
    late InMemoryCommandRepository commands;
    late SupabaseGameRepository repo;

    setUp(() {
      gateway = _FakeGameGateway();
      commands = InMemoryCommandRepository();
      repo = SupabaseGameRepository(
        commandRepository: commands,
        gateway: gateway,
        createGamePollInterval: Duration.zero,
      );
    });

    test('submitCreateGame delegates to command repository', () async {
      final id = await repo.submitCreateGame(
        adminPlayerId: 'p-1',
        gameName: 'N',
        gameSecurity: GameSecurity.public,
        isRanked: IsRanked.ranked,
        gameMaxPlayers: 5,
        endCondition: EndCondition.timed,
        totalDecidedDurationSeconds: 600,
      );
      expect(commands.inserts.single.commandId, id);
      expect(gateway.calls, isEmpty); // no game-table read
    });

    test('createGameAndReturnGameId polls until processed', () async {
      gateway.commandPollPhasesById['cmd-1'] = [
        {'command_status': 'pending', 'command_game_id': null},
        {'command_status': 'processed', 'command_game_id': 'g-new'},
      ];
      final gameId = await repo.createGameAndReturnGameId(
        adminPlayerId: 'p-1',
        gameName: 'N',
        gameSecurity: GameSecurity.public,
        isRanked: IsRanked.ranked,
        gameMaxPlayers: 5,
        endCondition: EndCondition.timed,
        totalDecidedDurationSeconds: 600,
      );
      expect(gameId, 'g-new');
      expect(
        gateway.calls.where((c) => c.startsWith('fetchCommandStatusRow')),
        isNotEmpty,
      );
    });

    test('createGameAndReturnGameId throws on rejected', () async {
      gateway.commandPollPhasesById['cmd-1'] = [
        {'command_status': 'rejected', 'command_game_id': null},
      ];
      await expectLater(
        repo.createGameAndReturnGameId(
          adminPlayerId: 'p-1',
          gameName: 'N',
          gameSecurity: GameSecurity.public,
          isRanked: IsRanked.ranked,
          gameMaxPlayers: 5,
          endCondition: EndCondition.timed,
          totalDecidedDurationSeconds: 1,
        ),
        throwsA(isA<CreateGameCommandFailedException>()),
      );
    });

    test('createGameAndReturnGameId times out when status stays pending',
        () async {
      gateway.commandPollPhasesById['cmd-1'] = List<Map<String, dynamic>>.filled(
        20,
        {'command_status': 'pending', 'command_game_id': null},
      );
      final stuck = SupabaseGameRepository(
        commandRepository: commands,
        gateway: gateway,
        createGamePollInterval: Duration.zero,
        createGameMaxPollAttempts: 4,
      );
      await expectLater(
        stuck.createGameAndReturnGameId(
          adminPlayerId: 'p-1',
          gameName: 'N',
          gameSecurity: GameSecurity.public,
          isRanked: IsRanked.ranked,
          gameMaxPlayers: 5,
          endCondition: EndCondition.endless,
        ),
        throwsA(isA<CreateGameTimeoutException>()),
      );
    });

    test('fetchGame decodes row from gateway', () async {
      gateway.gameRows['g-1'] = _gameRow('g-1');
      final g = await repo.fetchGame('g-1');
      expect(g?.gameId, 'g-1');
      expect(gateway.calls, ['fetchGameRow(g-1)']);
    });

    test('fetchPublicGames passes through', () async {
      gateway.publicRows = [_gameRow('g-1'), _gameRow('g-2', code: 'CODE2')];
      final games = await repo.fetchPublicGames();
      expect(games.map((g) => g.gameId), ['g-1', 'g-2']);
    });

    test('fetchJoinedGames passes through', () async {
      gateway.joinedByPlayer['p-1'] = [_gameRow('g-9')];
      final games = await repo.fetchJoinedGames('p-1');
      expect(games.single.gameId, 'g-9');
    });

    test('lookupGameByCode uppercases before calling gateway', () async {
      gateway.codeRows['XY99Z'] = _gameRow('g-1', code: 'XY99Z');
      final g = await repo.lookupGameByCode('xy99z');
      expect(g?.gameId, 'g-1');
      expect(gateway.codeLookups.single, 'XY99Z');
    });

    test('joinByCode looks up then submits join command', () async {
      gateway.codeRows['XY99Z'] = _gameRow('g-1', code: 'XY99Z');
      final result = await repo.joinByCode(
        code: 'xy99z',
        playerId: 'p-2',
      );
      expect(result.gameId, 'g-1');
      expect(commands.lastOfType(CommandType.joinGame)?.gameId, 'g-1');
    });

    test('joinByCode throws GameNotFoundException on unknown code', () {
      expect(
        () => repo.joinByCode(code: 'NONE1', playerId: 'p-2'),
        throwsA(isA<GameNotFoundException>()),
      );
    });

    test(
      'joinByCode resolves PRIVATE game via RPC when row SELECT is blocked '
      '(RLS regression — bug 2: "No game found with joining code"). '
      'lookupGameRowByCode returns null because the user is not yet a '
      'member; the SECURITY DEFINER RPC must still resolve the id.',
      () async {
        gateway.gameIdsByCode['ZZZZZ'] = 'g-private';
        final result = await repo.joinByCode(
          code: 'zzzzz',
          playerId: 'p-2',
        );
        expect(result.gameId, 'g-private');
        expect(gateway.rpcCodeLookups.single, 'ZZZZZ');
        expect(
          gateway.codeLookups,
          isEmpty,
          reason: 'joinByCode must NOT use the RLS-bound row lookup',
        );
        expect(
          commands.lastOfType(CommandType.joinGame)?.gameId,
          'g-private',
        );
      },
    );
  });
}

Map<String, dynamic> _gameRow(String id,
    {String code = 'ABCDE', String state = 'created'}) {
  return <String, dynamic>{
    'game_id': id,
    'game_name': 'G',
    'game_description': null,
    'game_created_at': '2026-01-01T00:00:00.000Z',
    'game_security': 'public',
    'is_ranked': 'ranked',
    'game_max_players': 10,
    'joining_code': code,
    'end_condition': 'endless',
    'total_decided_duration_seconds': null,
    'end_time_decided': null,
    'start_time': null,
    'end_time_actual': null,
    'game_state': state,
    'admin_player_id': 'p-admin',
    'last_traded_price': null,
    'envelope_price': null,
    'state_version': 1,
    'updated_at': '2026-01-01T00:00:00.000Z',
  };
}

class _FakeGameGateway implements SupabaseGameGateway {
  final Map<String, Map<String, dynamic>> gameRows = {};
  List<Map<String, dynamic>> publicRows = [];
  final Map<String, List<Map<String, dynamic>>> joinedByPlayer = {};
  final Map<String, Map<String, dynamic>> codeRows = {};
  final Map<String, String> gameIdsByCode = {};
  final List<String> codeLookups = [];
  final List<String> rpcCodeLookups = [];
  final List<String> calls = [];

  /// Per [commandId], ordered rows for [fetchCommandStatusRow]. When absent,
  /// defaults to one `pending` then `processed` with game id `g-new`.
  final Map<String, List<Map<String, dynamic>>> commandPollPhasesById = {};
  final Map<String, int> _commandPollIndex = {};

  @override
  Future<Map<String, dynamic>?> fetchGameRow(String gameId) async {
    calls.add('fetchGameRow($gameId)');
    return gameRows[gameId];
  }

  final Map<String, List<Map<String, dynamic>>> playersByGame = {};

  @override
  Future<List<Map<String, dynamic>>> fetchGamePlayerRows(String gameId) async {
    calls.add('fetchGamePlayerRows($gameId)');
    return playersByGame[gameId] ?? const [];
  }

  @override
  Future<List<Map<String, dynamic>>> fetchPublicGameRows() async {
    calls.add('fetchPublicGameRows');
    return publicRows;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchJoinedGameRows(
    String playerId,
  ) async {
    calls.add('fetchJoinedGameRows($playerId)');
    return joinedByPlayer[playerId] ?? [];
  }

  @override
  Future<Map<String, dynamic>?> lookupGameRowByCode(String code) async {
    codeLookups.add(code);
    calls.add('lookupGameRowByCode($code)');
    return codeRows[code];
  }

  @override
  Future<String?> lookupGameIdByJoiningCode(String code) async {
    final up = code.toUpperCase();
    rpcCodeLookups.add(up);
    calls.add('lookupGameIdByJoiningCode($up)');
    final mapped = gameIdsByCode[up];
    if (mapped != null) return mapped;
    final row = codeRows[up];
    return row?['game_id'] as String?;
  }

  @override
  Future<Map<String, dynamic>?> fetchCommandStatusRow(String commandId) async {
    calls.add('fetchCommandStatusRow($commandId)');
    final phases = commandPollPhasesById[commandId] ??
        [
          {'command_status': 'pending', 'command_game_id': null},
          {'command_status': 'processed', 'command_game_id': 'g-new'},
        ];
    final i = _commandPollIndex[commandId] ?? 0;
    final idx = i < phases.length ? i : phases.length - 1;
    _commandPollIndex[commandId] = i + 1;
    return phases[idx];
  }
}
