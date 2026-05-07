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

void main() {
  group('GameState', () {
    test('round-trip covers every variant', () {
      expect(GameState.values.length, 5);
      for (final v in GameState.values) {
        expect(GameState.fromWire(v.wireValue), v);
      }
    });
    test('wire values are exact snake_case from PRD', () {
      expect(GameState.created.wireValue, 'created');
      expect(GameState.tradingStarted.wireValue, 'trading_started');
      expect(GameState.tradingEnded.wireValue, 'trading_ended');
      expect(GameState.gameFinalised.wireValue, 'game_finalised');
      expect(GameState.discarded.wireValue, 'discarded');
    });
    test('fromWire rejects unknown values', () {
      expect(() => GameState.fromWire('Created'), throwsArgumentError);
      expect(() => GameState.fromWire(''), throwsArgumentError);
      expect(() => GameState.fromWire('trading'), throwsArgumentError);
    });
    test('tryFromWire returns null on unknown / null', () {
      expect(GameState.tryFromWire(null), isNull);
      expect(GameState.tryFromWire('Created'), isNull);
      expect(GameState.tryFromWire('trading_started'), GameState.tradingStarted);
    });
  });

  group('GameSecurity', () {
    test('round-trip covers every variant', () {
      expect(GameSecurity.values.length, 2);
      for (final v in GameSecurity.values) {
        expect(GameSecurity.fromWire(v.wireValue), v);
      }
    });
    test('rejects PUBLIC (case sensitive)', () {
      expect(() => GameSecurity.fromWire('PUBLIC'), throwsArgumentError);
    });
  });

  group('IsRanked', () {
    test('round-trip covers every variant', () {
      expect(IsRanked.values.length, 2);
      expect(IsRanked.fromWire('ranked'), IsRanked.ranked);
      expect(IsRanked.fromWire('casual'), IsRanked.casual);
    });
    test('true/false are NOT valid (enum, not boolean)', () {
      expect(() => IsRanked.fromWire('true'), throwsArgumentError);
      expect(() => IsRanked.fromWire('false'), throwsArgumentError);
    });
  });

  group('EndCondition', () {
    test('round-trip', () {
      expect(EndCondition.values.length, 2);
      expect(EndCondition.fromWire('timed'), EndCondition.timed);
      expect(EndCondition.fromWire('endless'), EndCondition.endless);
    });
  });

  group('OrderType', () {
    test('round-trip covers all 4 variants', () {
      expect(OrderType.values.length, 4);
      for (final v in OrderType.values) {
        expect(OrderType.fromWire(v.wireValue), v);
      }
    });
    test('wire values', () {
      expect(OrderType.limitBuy.wireValue, 'limit_buy');
      expect(OrderType.limitSell.wireValue, 'limit_sell');
      expect(OrderType.marketBuy.wireValue, 'market_buy');
      expect(OrderType.marketSell.wireValue, 'market_sell');
    });
    test('side + execution kind helpers', () {
      expect(OrderType.limitBuy.isBuy, true);
      expect(OrderType.limitBuy.isSell, false);
      expect(OrderType.limitBuy.isLimit, true);
      expect(OrderType.limitBuy.isMarket, false);

      expect(OrderType.marketSell.isBuy, false);
      expect(OrderType.marketSell.isSell, true);
      expect(OrderType.marketSell.isLimit, false);
      expect(OrderType.marketSell.isMarket, true);

      expect(OrderType.limitSell.isBuy, false);
      expect(OrderType.limitSell.isSell, true);
      expect(OrderType.limitSell.isLimit, true);

      expect(OrderType.marketBuy.isBuy, true);
      expect(OrderType.marketBuy.isMarket, true);
    });
  });

  group('OrderStatus', () {
    test('round-trip covers all 6 variants', () {
      expect(OrderStatus.values.length, 6);
      for (final v in OrderStatus.values) {
        expect(OrderStatus.fromWire(v.wireValue), v);
      }
    });
    test('isTerminal matches PRD semantics', () {
      expect(OrderStatus.inQueue.isTerminal, false);
      expect(OrderStatus.beingProcessed.isTerminal, false);
      expect(OrderStatus.orderResting.isTerminal, false);
      expect(OrderStatus.orderClosed.isTerminal, true);
      expect(OrderStatus.cancelled.isTerminal, true);
      expect(OrderStatus.gameEnded.isTerminal, true);
    });
    test('isActive is the complement of isTerminal', () {
      for (final s in OrderStatus.values) {
        expect(s.isActive, isNot(s.isTerminal));
      }
    });
  });

  group('CommandType', () {
    test('covers all 12 PRD command types', () {
      expect(CommandType.values.length, 12);
      const expected = {
        'create_game',
        'join_game',
        'leave_game',
        'kick_player',
        'start_game',
        'create_order',
        'cancel_order',
        'end_trading',
        'set_envelope_price',
        'finalise_game',
        'discard_game',
        'add_time',
      };
      expect(
        CommandType.values.map((e) => e.wireValue).toSet(),
        expected,
      );
    });
    test('only create_game does NOT require a game id', () {
      for (final c in CommandType.values) {
        expect(c.requiresGameId, c != CommandType.createGame);
      }
    });
  });

  group('CommandStatus', () {
    test('covers all 5 PRD statuses', () {
      expect(CommandStatus.values.length, 5);
      for (final v in CommandStatus.values) {
        expect(CommandStatus.fromWire(v.wireValue), v);
      }
    });
    test('terminal set is {processed, rejected} — failed is NOT terminal', () {
      expect(CommandStatus.processed.isTerminal, true);
      expect(CommandStatus.rejected.isTerminal, true);
      expect(CommandStatus.pending.isTerminal, false);
      expect(CommandStatus.claimed.isTerminal, false);
      expect(CommandStatus.failed.isTerminal, false);
    });
  });

  group('LobbyStatus', () {
    test('round-trip', () {
      expect(LobbyStatus.values.length, 2);
      expect(LobbyStatus.fromWire('playing'), LobbyStatus.playing);
      expect(LobbyStatus.fromWire('finished'), LobbyStatus.finished);
    });
  });
}
