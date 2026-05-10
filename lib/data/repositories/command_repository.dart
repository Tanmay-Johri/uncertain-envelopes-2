import '../enums/command_type.dart';
import '../enums/end_condition.dart';
import '../enums/game_security.dart';
import '../enums/is_ranked.dart';
import '../enums/order_type.dart';
import '../models/command.dart';

/// Low-level insert API for `commands` rows. This is the boundary where we
/// construct the exact `payload` JSON shapes that the PL/pgSQL stored
/// procedures expect (Stream A). The higher-level repositories
/// ([GameRepository], [OrderRepository], etc.) compose this one and should
/// not hand-roll their own payload shapes.
///
/// Every submit* method must:
///   1. Build the payload using snake_case keys only.
///   2. Return the new `command_id` so the caller can observe the row's
///      lifecycle (pending -> claimed -> processed / rejected).
///
/// `command_game_id` is non-null for every command type except
/// [CommandType.createGame] (because the game does not exist yet at submit
/// time). Concrete implementations MUST validate this invariant.
abstract class CommandRepository {
  /// Generic command insertion. Validates that [gameId] presence matches
  /// [type].requiresGameId; throws [CommandPayloadValidationException]
  /// otherwise.
  Future<String> insertCommand({
    required CommandType type,
    required String? gameId,
    required String? playerId,
    required Map<String, dynamic> payload,
  });

  Future<String> submitCreateGame({
    required String adminPlayerId,
    required String gameName,
    String? gameDescription,
    required GameSecurity gameSecurity,
    required IsRanked isRanked,
    required int gameMaxPlayers,
    required EndCondition endCondition,
    int? totalDecidedDurationSeconds,
  });

  Future<String> submitJoinGame({
    required String gameId,
    required String playerId,
  });

  Future<String> submitLeaveGame({
    required String gameId,
    required String playerId,
  });

  Future<String> submitKickPlayer({
    required String gameId,
    required String adminPlayerId,
    required String targetPlayerId,
  });

  Future<String> submitStartGame({
    required String gameId,
    required String adminPlayerId,
  });

  Future<String> submitCreateOrder({
    required String gameId,
    required String playerId,
    required OrderType type,
    required int quantityInitial,
    double? pricePerStock,
  });

  Future<String> submitCancelOrder({
    required String gameId,
    required String playerId,
    required String orderId,
  });

  Future<String> submitEndTrading({
    required String gameId,
    required String adminPlayerId,
  });

  Future<String> submitSetEnvelopePrice({
    required String gameId,
    required String adminPlayerId,
    required double envelopePrice,
  });

  Future<String> submitFinaliseGame({
    required String gameId,
    required String adminPlayerId,
  });

  Future<String> submitDiscardGame({
    required String gameId,
    required String adminPlayerId,
  });

  Future<String> submitAddTime({
    required String gameId,
    required String adminPlayerId,
    required int additionalSeconds,
  });

  /// Non-terminal `create_order` commands for this game and player
  /// (`pending`, `claimed`, `failed`). Used to surface placeholder `orders`
  /// rows before the processor creates the real `orders` row (B-GAP-1).
  Future<List<Command>> fetchPendingCreateOrderCommands({
    required String gameId,
    required String playerId,
  });

  /// Non-terminal `create_order` commands for [gameId] (all players).
  ///
  /// Used to seed [pendingCreateOrderCommandsProvider] and the realtime merge
  /// buffer (B-GAP-1b).
  Future<List<Command>> fetchPendingCreateOrderCommandsForGame(String gameId);
}

/// Shared implementation of every `submit*` convenience method. Subclasses
/// only have to provide [insertCommand] and the exception types below.
/// This is the single place where PRD payload shapes live, so any schema
/// drift shows up in exactly one spot.
abstract class BaseCommandRepository implements CommandRepository {
  const BaseCommandRepository();

  /// Validates the game-id-vs-type invariant and delegates to the subclass.
  /// Subclasses should override [doInsert] (not [insertCommand]) so that
  /// the validation runs for every command.
  @override
  Future<String> insertCommand({
    required CommandType type,
    required String? gameId,
    required String? playerId,
    required Map<String, dynamic> payload,
  }) {
    if (type.requiresGameId && gameId == null) {
      throw CommandPayloadValidationException(
        'command type "${type.wireValue}" requires a game id',
      );
    }
    if (!type.requiresGameId && gameId != null) {
      throw CommandPayloadValidationException(
        'command type "${type.wireValue}" must not carry a game id '
        '(the stored procedure backfills it)',
      );
    }
    // Payload may be empty for commands like start_game; that is fine.
    return doInsert(
      type: type,
      gameId: gameId,
      playerId: playerId,
      payload: payload,
    );
  }

  /// Subclass-specific insert. Must return the inserted `command_id`.
  Future<String> doInsert({
    required CommandType type,
    required String? gameId,
    required String? playerId,
    required Map<String, dynamic> payload,
  });

  @override
  Future<String> submitCreateGame({
    required String adminPlayerId,
    required String gameName,
    String? gameDescription,
    required GameSecurity gameSecurity,
    required IsRanked isRanked,
    required int gameMaxPlayers,
    required EndCondition endCondition,
    int? totalDecidedDurationSeconds,
  }) {
    if (endCondition == EndCondition.timed &&
        totalDecidedDurationSeconds == null) {
      throw const CommandPayloadValidationException(
        'timed games require totalDecidedDurationSeconds',
      );
    }
    if (endCondition == EndCondition.endless &&
        totalDecidedDurationSeconds != null) {
      throw const CommandPayloadValidationException(
        'endless games must not carry totalDecidedDurationSeconds',
      );
    }
    return insertCommand(
      type: CommandType.createGame,
      gameId: null,
      playerId: adminPlayerId,
      payload: <String, dynamic>{
        'game_name': gameName,
        'game_description': gameDescription,
        'game_security': gameSecurity.wireValue,
        'is_ranked': isRanked.wireValue,
        'game_max_players': gameMaxPlayers,
        'end_condition': endCondition.wireValue,
        'total_decided_duration_seconds': totalDecidedDurationSeconds,
      },
    );
  }

  @override
  Future<String> submitJoinGame({
    required String gameId,
    required String playerId,
  }) {
    return insertCommand(
      type: CommandType.joinGame,
      gameId: gameId,
      playerId: playerId,
      payload: const <String, dynamic>{},
    );
  }

  @override
  Future<String> submitLeaveGame({
    required String gameId,
    required String playerId,
  }) {
    return insertCommand(
      type: CommandType.leaveGame,
      gameId: gameId,
      playerId: playerId,
      payload: const <String, dynamic>{},
    );
  }

  @override
  Future<String> submitKickPlayer({
    required String gameId,
    required String adminPlayerId,
    required String targetPlayerId,
  }) {
    return insertCommand(
      type: CommandType.kickPlayer,
      gameId: gameId,
      playerId: adminPlayerId,
      payload: <String, dynamic>{
        'target_player_id': targetPlayerId,
      },
    );
  }

  @override
  Future<String> submitStartGame({
    required String gameId,
    required String adminPlayerId,
  }) {
    return insertCommand(
      type: CommandType.startGame,
      gameId: gameId,
      playerId: adminPlayerId,
      payload: const <String, dynamic>{},
    );
  }

  @override
  Future<String> submitCreateOrder({
    required String gameId,
    required String playerId,
    required OrderType type,
    required int quantityInitial,
    double? pricePerStock,
  }) {
    if (quantityInitial <= 0) {
      throw const CommandPayloadValidationException(
        'quantity_initial must be positive',
      );
    }
    if (type.isLimit && pricePerStock == null) {
      throw const CommandPayloadValidationException(
        'limit orders require price_per_stock',
      );
    }
    if (type.isMarket && pricePerStock != null) {
      throw const CommandPayloadValidationException(
        'market orders must not carry price_per_stock',
      );
    }
    return insertCommand(
      type: CommandType.createOrder,
      gameId: gameId,
      playerId: playerId,
      payload: <String, dynamic>{
        'type': type.wireValue,
        'quantity_initial': quantityInitial,
        'price_per_stock': pricePerStock,
      },
    );
  }

  @override
  Future<String> submitCancelOrder({
    required String gameId,
    required String playerId,
    required String orderId,
  }) {
    return insertCommand(
      type: CommandType.cancelOrder,
      gameId: gameId,
      playerId: playerId,
      payload: <String, dynamic>{
        'order_id': orderId,
      },
    );
  }

  @override
  Future<String> submitEndTrading({
    required String gameId,
    required String adminPlayerId,
  }) {
    return insertCommand(
      type: CommandType.endTrading,
      gameId: gameId,
      playerId: adminPlayerId,
      payload: const <String, dynamic>{},
    );
  }

  @override
  Future<String> submitSetEnvelopePrice({
    required String gameId,
    required String adminPlayerId,
    required double envelopePrice,
  }) {
    return insertCommand(
      type: CommandType.setEnvelopePrice,
      gameId: gameId,
      playerId: adminPlayerId,
      payload: <String, dynamic>{
        'envelope_price': envelopePrice,
      },
    );
  }

  @override
  Future<String> submitFinaliseGame({
    required String gameId,
    required String adminPlayerId,
  }) {
    return insertCommand(
      type: CommandType.finaliseGame,
      gameId: gameId,
      playerId: adminPlayerId,
      payload: const <String, dynamic>{},
    );
  }

  @override
  Future<String> submitDiscardGame({
    required String gameId,
    required String adminPlayerId,
  }) {
    return insertCommand(
      type: CommandType.discardGame,
      gameId: gameId,
      playerId: adminPlayerId,
      payload: const <String, dynamic>{},
    );
  }

  @override
  Future<String> submitAddTime({
    required String gameId,
    required String adminPlayerId,
    required int additionalSeconds,
  }) {
    if (additionalSeconds <= 0) {
      throw const CommandPayloadValidationException(
        'additional_seconds must be positive',
      );
    }
    return insertCommand(
      type: CommandType.addTime,
      gameId: gameId,
      playerId: adminPlayerId,
      payload: <String, dynamic>{
        'additional_seconds': additionalSeconds,
      },
    );
  }
}

sealed class CommandRepositoryException implements Exception {
  const CommandRepositoryException(this.message);
  final String message;
  @override
  String toString() => '$runtimeType($message)';
}

class CommandPayloadValidationException extends CommandRepositoryException {
  const CommandPayloadValidationException(super.message);
}
