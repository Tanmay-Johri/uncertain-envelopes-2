import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/data/enums/command_status.dart';
import 'package:uncertain_envelopes_2/data/enums/command_type.dart';
import 'package:uncertain_envelopes_2/data/enums/end_condition.dart';
import 'package:uncertain_envelopes_2/data/enums/game_security.dart';
import 'package:uncertain_envelopes_2/data/enums/game_state.dart';
import 'package:uncertain_envelopes_2/data/enums/is_ranked.dart';
import 'package:uncertain_envelopes_2/data/enums/lobby_status.dart';
import 'package:uncertain_envelopes_2/data/enums/order_status.dart';
import 'package:uncertain_envelopes_2/data/enums/order_type.dart';
import 'package:uncertain_envelopes_2/data/models/command.dart';
import 'package:uncertain_envelopes_2/data/models/execution.dart';
import 'package:uncertain_envelopes_2/data/models/game.dart';
import 'package:uncertain_envelopes_2/data/models/game_player.dart';
import 'package:uncertain_envelopes_2/data/models/order.dart';
import 'package:uncertain_envelopes_2/data/models/player.dart';

/// These tests intentionally use *snake_case* keys in the JSON maps because
/// that is exactly what Supabase returns. Any drift between the PRD column
/// names and the models' @JsonKey names should break these tests.
void main() {
  group('Player model', () {
    final json = <String, dynamic>{
      'player_id': 'p-1',
      'username': 'alice',
      'created_at': '2026-01-01T12:00:00.000Z',
      'email': 'alice@example.com',
    };
    test('fromJson parses every column name correctly', () {
      final p = Player.fromJson(json);
      expect(p.playerId, 'p-1');
      expect(p.username, 'alice');
      expect(p.createdAt, DateTime.utc(2026, 1, 1, 12));
      expect(p.email, 'alice@example.com');
    });
    test('toJson emits snake_case keys exactly', () {
      final p = Player.fromJson(json);
      final out = p.toJson();
      expect(out.keys.toSet(), json.keys.toSet());
    });
    test('round-trip preserves equality', () {
      final a = Player.fromJson(json);
      final b = Player.fromJson(a.toJson());
      expect(a, b);
    });
    test('copyWith changes only the specified field', () {
      final p = Player.fromJson(json);
      final renamed = p.copyWith(username: 'bob');
      expect(renamed.username, 'bob');
      expect(renamed.playerId, p.playerId);
      expect(renamed.email, p.email);
      expect(renamed.createdAt, p.createdAt);
      expect(renamed, isNot(equals(p)));
    });
  });

  group('Game model', () {
    Map<String, dynamic> timedJson() => <String, dynamic>{
          'game_id': 'g-1',
          'game_name': 'Test Game',
          'game_description': 'A game for testing',
          'game_created_at': '2026-01-01T10:00:00.000Z',
          'game_security': 'public',
          'is_ranked': 'ranked',
          'game_max_players': 50,
          'joining_code': 'AB12C',
          'end_condition': 'timed',
          'total_decided_duration_seconds': 600,
          'end_time_decided': '2026-01-01T10:10:00.000Z',
          'start_time': '2026-01-01T10:00:00.000Z',
          'end_time_actual': null,
          'game_state': 'trading_started',
          'admin_player_id': 'p-1',
          'last_traded_price': 123.45,
          'envelope_price': null,
          'state_version': 3,
          'updated_at': '2026-01-01T10:05:00.000Z',
        };

    test('fromJson decodes all enum + nullable fields', () {
      final g = Game.fromJson(timedJson());
      expect(g.gameId, 'g-1');
      expect(g.gameSecurity, GameSecurity.public);
      expect(g.isRanked, IsRanked.ranked);
      expect(g.endCondition, EndCondition.timed);
      expect(g.gameState, GameState.tradingStarted);
      expect(g.gameDescription, 'A game for testing');
      expect(g.lastTradedPrice, 123.45);
      expect(g.envelopePrice, isNull);
      expect(g.endTimeActual, isNull);
      expect(g.totalDecidedDurationSeconds, 600);
    });

    test('round-trip preserves every field incl nullables', () {
      final json = timedJson();
      final g = Game.fromJson(json);
      final again = Game.fromJson(g.toJson());
      expect(again, g);
    });

    test('endless game decodes with null timer fields', () {
      final j = timedJson()
        ..['end_condition'] = 'endless'
        ..['total_decided_duration_seconds'] = null
        ..['end_time_decided'] = null;
      final g = Game.fromJson(j);
      expect(g.endCondition, EndCondition.endless);
      expect(g.totalDecidedDurationSeconds, isNull);
      expect(g.endTimeDecided, isNull);
    });

    test('pre-start game (start_time null, state=created) round-trips', () {
      final j = timedJson()
        ..['game_state'] = 'created'
        ..['start_time'] = null
        ..['last_traded_price'] = null;
      final g = Game.fromJson(j);
      expect(g.gameState, GameState.created);
      expect(g.startTime, isNull);
      expect(g.lastTradedPrice, isNull);
      expect(Game.fromJson(g.toJson()), g);
    });

    test('invalid enum string throws ArgumentError', () {
      final j = timedJson()..['game_state'] = 'Created';
      expect(() => Game.fromJson(j), throwsArgumentError);
    });

    test('copyWith updates stateVersion without breaking identity', () {
      final g = Game.fromJson(timedJson());
      final bumped = g.copyWith(stateVersion: g.stateVersion + 1);
      expect(bumped.stateVersion, 4);
      expect(bumped.gameId, g.gameId);
    });
  });

  group('GamePlayer model', () {
    final json = <String, dynamic>{
      'games_players_row_id': 'gp-1',
      'map_game_id': 'g-1',
      'map_player_id': 'p-1',
      'lobby_status': 'playing',
      'joined_at': '2026-01-01T10:00:00.000Z',
      'is_admin': true,
      'delta_cash': -120.5,
      'delta_envelopes': 3,
      'pnl': 0.0,
    };
    test('decodes negative deltaCash and admin flag', () {
      final gp = GamePlayer.fromJson(json);
      expect(gp.lobbyStatus, LobbyStatus.playing);
      expect(gp.isAdmin, true);
      expect(gp.deltaCash, -120.5);
      expect(gp.deltaEnvelopes, 3);
      expect(gp.pnl, 0.0);
    });
    test('round-trip', () {
      final gp = GamePlayer.fromJson(json);
      expect(GamePlayer.fromJson(gp.toJson()), gp);
    });
    test('decodes zero deltas (fresh lobby join)', () {
      final j = Map<String, dynamic>.from(json)
        ..['delta_cash'] = 0
        ..['delta_envelopes'] = 0;
      final gp = GamePlayer.fromJson(j);
      expect(gp.deltaCash, 0.0);
      expect(gp.deltaEnvelopes, 0);
    });
  });

  group('Order model', () {
    Map<String, dynamic> limitJson() => <String, dynamic>{
          'order_id': 'o-1',
          'created_by_player_id': 'p-1',
          'game_id': 'g-1',
          'type': 'limit_buy',
          'quantity_initial': 10,
          'quantity_current': 4,
          'price_per_stock': 99.5,
          'status': 'order_resting',
          'order_created_at': '2026-01-01T10:01:00.000Z',
          'order_updated_at': '2026-01-01T10:02:00.000Z',
        };
    test('limit order round-trips with price', () {
      final o = Order.fromJson(limitJson());
      expect(o.type, OrderType.limitBuy);
      expect(o.status, OrderStatus.orderResting);
      expect(o.pricePerStock, 99.5);
      expect(Order.fromJson(o.toJson()), o);
    });
    test('market order has null price', () {
      final j = limitJson()
        ..['type'] = 'market_sell'
        ..['price_per_stock'] = null
        ..['status'] = 'order_closed';
      final o = Order.fromJson(j);
      expect(o.type, OrderType.marketSell);
      expect(o.pricePerStock, isNull);
      expect(o.status, OrderStatus.orderClosed);
      expect(Order.fromJson(o.toJson()), o);
    });
    test('all 4 order types decode', () {
      for (final t in OrderType.values) {
        final j = limitJson()..['type'] = t.wireValue;
        if (t.isMarket) j['price_per_stock'] = null;
        expect(Order.fromJson(j).type, t);
      }
    });
    test('all 6 order statuses decode', () {
      for (final s in OrderStatus.values) {
        final j = limitJson()..['status'] = s.wireValue;
        expect(Order.fromJson(j).status, s);
      }
    });
  });

  group('Execution model', () {
    final json = <String, dynamic>{
      'executions_id': 'e-1',
      'executions_game_id': 'g-1',
      'buy_order_id': 'o-buy',
      'sell_order_id': 'o-sell',
      'quantity': 2,
      'execution_price': 50.25,
      'executed_at': '2026-01-01T10:05:30.000Z',
    };
    test('decodes all fields', () {
      final e = Execution.fromJson(json);
      expect(e.executionsId, 'e-1');
      expect(e.buyOrderId, 'o-buy');
      expect(e.sellOrderId, 'o-sell');
      expect(e.quantity, 2);
      expect(e.executionPrice, 50.25);
    });
    test('round-trip', () {
      final e = Execution.fromJson(json);
      expect(Execution.fromJson(e.toJson()), e);
    });
    test('accepts integer-valued prices as doubles', () {
      final j = Map<String, dynamic>.from(json)..['execution_price'] = 100;
      final e = Execution.fromJson(j);
      expect(e.executionPrice, 100.0);
    });
  });

  group('Command model', () {
    Map<String, dynamic> orderCmdJson() => <String, dynamic>{
          'command_id': 'c-1',
          'command_game_id': 'g-1',
          'command_created_at': '2026-01-01T10:01:00.000Z',
          'player_id': 'p-1',
          'command_type': 'create_order',
          'payload': {
            'type': 'limit_buy',
            'quantity_initial': 5,
            'price_per_stock': 100.0,
          },
          'command_status': 'pending',
          'claim_token': null,
          'claimed_at': null,
          'attempt_count': 0,
          'finished_at': null,
        };

    test('decodes a create_order command with arbitrary payload', () {
      final c = Command.fromJson(orderCmdJson());
      expect(c.commandType, CommandType.createOrder);
      expect(c.commandStatus, CommandStatus.pending);
      expect(c.payload['type'], 'limit_buy');
      expect(c.payload['quantity_initial'], 5);
    });

    test('create_game command decodes with null commandGameId', () {
      final j = orderCmdJson()
        ..['command_type'] = 'create_game'
        ..['command_game_id'] = null
        ..['payload'] = {
          'game_name': 'New',
          'game_security': 'public',
          'is_ranked': 'casual',
        };
      final c = Command.fromJson(j);
      expect(c.commandType, CommandType.createGame);
      expect(c.commandGameId, isNull);
    });

    test('system-triggered command decodes with null playerId', () {
      final j = orderCmdJson()
        ..['player_id'] = null
        ..['command_type'] = 'end_trading'
        ..['payload'] = <String, dynamic>{};
      final c = Command.fromJson(j);
      expect(c.playerId, isNull);
      expect(c.commandType, CommandType.endTrading);
    });

    test('round-trip preserves payload contents', () {
      final c = Command.fromJson(orderCmdJson());
      final again = Command.fromJson(c.toJson());
      expect(again, c);
      expect(again.payload, c.payload);
    });

    test('all 12 command types decode', () {
      for (final t in CommandType.values) {
        final j = orderCmdJson()..['command_type'] = t.wireValue;
        if (t == CommandType.createGame) j['command_game_id'] = null;
        expect(Command.fromJson(j).commandType, t);
      }
    });

    test('claimed command with token + attempt_count decodes', () {
      final j = orderCmdJson()
        ..['command_status'] = 'claimed'
        ..['claim_token'] = 'tok-abc'
        ..['claimed_at'] = '2026-01-01T10:01:05.000Z'
        ..['attempt_count'] = 1;
      final c = Command.fromJson(j);
      expect(c.commandStatus, CommandStatus.claimed);
      expect(c.claimToken, 'tok-abc');
      expect(c.attemptCount, 1);
      expect(c.claimedAt, isNotNull);
    });
  });
}
