import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/data/enums/command_type.dart';
import 'package:uncertain_envelopes_2/data/enums/end_condition.dart';
import 'package:uncertain_envelopes_2/data/enums/game_security.dart';
import 'package:uncertain_envelopes_2/data/enums/is_ranked.dart';
import 'package:uncertain_envelopes_2/data/enums/order_type.dart';
import 'package:uncertain_envelopes_2/data/repositories/command_repository.dart';
import 'package:uncertain_envelopes_2/data/repositories/in_memory_command_repository.dart';
import 'package:uncertain_envelopes_2/data/repositories/supabase_command_repository.dart';
import 'package:uncertain_envelopes_2/services/supabase_command_gateway.dart';

/// Shared shape for assertions across both implementations.
class _Record {
  _Record({
    required this.type,
    required this.gameId,
    required this.playerId,
    required this.payload,
  });
  final CommandType type;
  final String? gameId;
  final String? playerId;
  final Map<String, dynamic> payload;
}

/// Every `submit*` method's payload shape lives in the shared
/// [BaseCommandRepository]. Running the same tests against both subclasses
/// proves the two code paths never drift.
void main() {
  group('InMemoryCommandRepository', () {
    final fixture = () {
      final repo = InMemoryCommandRepository();
      return _Fixture(
        repo: repo,
        records: () => repo.inserts
            .map((c) => _Record(
                  type: c.type,
                  gameId: c.gameId,
                  playerId: c.playerId,
                  payload: c.payload,
                ))
            .toList(),
      );
    };
    _runContract(fixture);
  });

  group('SupabaseCommandRepository (fake gateway)', () {
    final fixture = () {
      final gateway = _FakeCommandGateway();
      return _Fixture(
        repo: SupabaseCommandRepository(gateway),
        records: () => gateway.calls,
      );
    };
    _runContract(fixture);
  });
}

class _Fixture {
  _Fixture({required this.repo, required this.records});
  final CommandRepository repo;
  final List<_Record> Function() records;
}

void _runContract(_Fixture Function() build) {
  late _Fixture fix;
  setUp(() {
    fix = build();
  });

  test('create_game payload shape (timed)', () async {
    final id = await fix.repo.submitCreateGame(
      adminPlayerId: 'p-admin',
      gameName: 'My Game',
      gameDescription: 'envelope = avg wingspan',
      gameSecurity: GameSecurity.public,
      isRanked: IsRanked.ranked,
      gameMaxPlayers: 20,
      endCondition: EndCondition.timed,
      totalDecidedDurationSeconds: 600,
    );
    expect(id, startsWith('cmd-'));
    final rec = fix.records().single;
    expect(rec.type, CommandType.createGame);
    expect(rec.gameId, isNull);
    expect(rec.playerId, 'p-admin');
    expect(rec.payload, {
      'game_name': 'My Game',
      'game_description': 'envelope = avg wingspan',
      'game_security': 'public',
      'is_ranked': 'ranked',
      'game_max_players': 20,
      'end_condition': 'timed',
      'total_decided_duration_seconds': 600,
    });
  });

  test('create_game payload shape (endless)', () async {
    await fix.repo.submitCreateGame(
      adminPlayerId: 'p-admin',
      gameName: 'Endless',
      gameSecurity: GameSecurity.private,
      isRanked: IsRanked.casual,
      gameMaxPlayers: 5,
      endCondition: EndCondition.endless,
    );
    final rec = fix.records().single;
    expect(rec.payload['end_condition'], 'endless');
    expect(rec.payload['total_decided_duration_seconds'], isNull);
    expect(rec.payload['game_description'], isNull);
  });

  test('create_game timed without duration is rejected', () {
    expect(
      () => fix.repo.submitCreateGame(
        adminPlayerId: 'p-admin',
        gameName: 'Bad',
        gameSecurity: GameSecurity.public,
        isRanked: IsRanked.casual,
        gameMaxPlayers: 5,
        endCondition: EndCondition.timed,
      ),
      throwsA(isA<CommandPayloadValidationException>()),
    );
    expect(fix.records(), isEmpty);
  });

  test('create_game endless with duration is rejected', () {
    expect(
      () => fix.repo.submitCreateGame(
        adminPlayerId: 'p-admin',
        gameName: 'Bad',
        gameSecurity: GameSecurity.public,
        isRanked: IsRanked.casual,
        gameMaxPlayers: 5,
        endCondition: EndCondition.endless,
        totalDecidedDurationSeconds: 600,
      ),
      throwsA(isA<CommandPayloadValidationException>()),
    );
    expect(fix.records(), isEmpty);
  });

  test(
      'join / leave / start / end_trading / finalise / discard carry '
      'game+player and empty payload', () async {
    await fix.repo.submitJoinGame(gameId: 'g-1', playerId: 'p-1');
    await fix.repo.submitLeaveGame(gameId: 'g-1', playerId: 'p-1');
    await fix.repo.submitStartGame(gameId: 'g-1', adminPlayerId: 'p-admin');
    await fix.repo.submitEndTrading(gameId: 'g-1', adminPlayerId: 'p-admin');
    await fix.repo.submitFinaliseGame(gameId: 'g-1', adminPlayerId: 'p-admin');
    await fix.repo.submitDiscardGame(gameId: 'g-1', adminPlayerId: 'p-admin');

    final recs = fix.records();
    expect(recs.map((r) => r.type.wireValue).toList(), [
      'join_game',
      'leave_game',
      'start_game',
      'end_trading',
      'finalise_game',
      'discard_game',
    ]);
    for (final r in recs) {
      expect(r.gameId, 'g-1');
      expect(r.playerId, isNotNull);
      expect(r.payload, isEmpty);
    }
  });

  test('kick_player payload carries target_player_id', () async {
    await fix.repo.submitKickPlayer(
      gameId: 'g-1',
      adminPlayerId: 'p-admin',
      targetPlayerId: 'p-bad',
    );
    final rec = fix.records().single;
    expect(rec.type, CommandType.kickPlayer);
    expect(rec.payload, {'target_player_id': 'p-bad'});
    expect(rec.playerId, 'p-admin');
  });

  test('create_order limit vs market payload shapes', () async {
    await fix.repo.submitCreateOrder(
      gameId: 'g-1',
      playerId: 'p-1',
      type: OrderType.limitBuy,
      quantityInitial: 5,
      pricePerStock: 100.0,
    );
    await fix.repo.submitCreateOrder(
      gameId: 'g-1',
      playerId: 'p-1',
      type: OrderType.marketSell,
      quantityInitial: 3,
    );

    final recs = fix.records();
    expect(recs[0].payload, {
      'type': 'limit_buy',
      'quantity_initial': 5,
      'price_per_stock': 100.0,
    });
    expect(recs[1].payload, {
      'type': 'market_sell',
      'quantity_initial': 3,
      'price_per_stock': null,
    });
  });

  test('create_order limit without price is rejected', () {
    expect(
      () => fix.repo.submitCreateOrder(
        gameId: 'g-1',
        playerId: 'p-1',
        type: OrderType.limitBuy,
        quantityInitial: 5,
      ),
      throwsA(isA<CommandPayloadValidationException>()),
    );
  });

  test('create_order market with price is rejected', () {
    expect(
      () => fix.repo.submitCreateOrder(
        gameId: 'g-1',
        playerId: 'p-1',
        type: OrderType.marketBuy,
        quantityInitial: 5,
        pricePerStock: 50,
      ),
      throwsA(isA<CommandPayloadValidationException>()),
    );
  });

  test('create_order non-positive quantity is rejected', () {
    expect(
      () => fix.repo.submitCreateOrder(
        gameId: 'g-1',
        playerId: 'p-1',
        type: OrderType.limitBuy,
        quantityInitial: 0,
        pricePerStock: 50,
      ),
      throwsA(isA<CommandPayloadValidationException>()),
    );
    expect(
      () => fix.repo.submitCreateOrder(
        gameId: 'g-1',
        playerId: 'p-1',
        type: OrderType.limitBuy,
        quantityInitial: -2,
        pricePerStock: 50,
      ),
      throwsA(isA<CommandPayloadValidationException>()),
    );
  });

  test('cancel_order payload carries order_id', () async {
    await fix.repo.submitCancelOrder(
      gameId: 'g-1',
      playerId: 'p-1',
      orderId: 'o-42',
    );
    final rec = fix.records().single;
    expect(rec.type, CommandType.cancelOrder);
    expect(rec.payload, {'order_id': 'o-42'});
  });

  test('set_envelope_price payload carries envelope_price', () async {
    await fix.repo.submitSetEnvelopePrice(
      gameId: 'g-1',
      adminPlayerId: 'p-admin',
      envelopePrice: 123.45,
    );
    final rec = fix.records().single;
    expect(rec.payload, {'envelope_price': 123.45});
  });

  test('add_time payload carries additional_seconds', () async {
    await fix.repo.submitAddTime(
      gameId: 'g-1',
      adminPlayerId: 'p-admin',
      additionalSeconds: 120,
    );
    final rec = fix.records().single;
    expect(rec.payload, {'additional_seconds': 120});
  });

  test('add_time non-positive seconds is rejected', () {
    expect(
      () => fix.repo.submitAddTime(
        gameId: 'g-1',
        adminPlayerId: 'p-admin',
        additionalSeconds: 0,
      ),
      throwsA(isA<CommandPayloadValidationException>()),
    );
  });

  test('insertCommand rejects missing game id when required', () {
    expect(
      () => fix.repo.insertCommand(
        type: CommandType.joinGame,
        gameId: null,
        playerId: 'p-1',
        payload: const {},
      ),
      throwsA(isA<CommandPayloadValidationException>()),
    );
  });

  test('insertCommand rejects game id on create_game', () {
    expect(
      () => fix.repo.insertCommand(
        type: CommandType.createGame,
        gameId: 'g-should-not-exist',
        playerId: 'p-1',
        payload: const {},
      ),
      throwsA(isA<CommandPayloadValidationException>()),
    );
  });

  test('returned command ids are unique', () async {
    final ids = <String>[];
    for (var i = 0; i < 5; i++) {
      ids.add(await fix.repo.submitStartGame(
        gameId: 'g-1',
        adminPlayerId: 'p-admin',
      ));
    }
    expect(ids.toSet().length, ids.length);
  });
}

class _FakeCommandGateway implements SupabaseCommandGateway {
  final List<_Record> calls = [];
  int _next = 1;

  @override
  Future<String> insertCommandRow({
    required CommandType type,
    required String? gameId,
    required String? playerId,
    required Map<String, dynamic> payload,
  }) async {
    final id = 'cmd-${_next++}';
    calls.add(
      _Record(
        type: type,
        gameId: gameId,
        playerId: playerId,
        payload: Map<String, dynamic>.unmodifiable(payload),
      ),
    );
    return id;
  }
}
