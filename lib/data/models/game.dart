import 'package:freezed_annotation/freezed_annotation.dart';

import '../enums/end_condition.dart';
import '../enums/game_security.dart';
import '../enums/game_state.dart';
import '../enums/is_ranked.dart';

part 'game.freezed.dart';
part 'game.g.dart';

/// Mirror of the `games` table. See PRD §games.
///
/// Nullable fields reflect schema nullability, not Dart convenience:
///   - [gameDescription]: optional per PRD.
///   - [totalDecidedDurationSeconds] / [endTimeDecided]: only meaningful for
///     `timed` games.
///   - [startTime]: null until admin starts the game.
///   - [endTimeActual]: null until trading ends.
///   - [lastTradedPrice]: null until first execution.
///   - [envelopePrice]: null until admin sets it in `trading_ended`.
@freezed
class Game with _$Game {
  const factory Game({
    @JsonKey(name: 'game_id') required String gameId,
    @JsonKey(name: 'game_name') required String gameName,
    @JsonKey(name: 'game_description') String? gameDescription,
    @JsonKey(name: 'game_created_at') required DateTime gameCreatedAt,
    @JsonKey(
      name: 'game_security',
      fromJson: GameSecurity.fromWire,
      toJson: GameSecurity.toWire,
    )
    required GameSecurity gameSecurity,
    @JsonKey(
      name: 'is_ranked',
      fromJson: IsRanked.fromWire,
      toJson: IsRanked.toWire,
    )
    required IsRanked isRanked,
    @JsonKey(name: 'game_max_players') required int gameMaxPlayers,
    @JsonKey(name: 'joining_code') required String joiningCode,
    @JsonKey(
      name: 'end_condition',
      fromJson: EndCondition.fromWire,
      toJson: EndCondition.toWire,
    )
    required EndCondition endCondition,
    @JsonKey(name: 'total_decided_duration_seconds')
    int? totalDecidedDurationSeconds,
    @JsonKey(name: 'end_time_decided') DateTime? endTimeDecided,
    @JsonKey(name: 'start_time') DateTime? startTime,
    @JsonKey(name: 'end_time_actual') DateTime? endTimeActual,
    @JsonKey(
      name: 'game_state',
      fromJson: GameState.fromWire,
      toJson: GameState.toWire,
    )
    required GameState gameState,
    @JsonKey(name: 'admin_player_id') required String adminPlayerId,
    @JsonKey(name: 'last_traded_price') double? lastTradedPrice,
    @JsonKey(name: 'envelope_price') double? envelopePrice,
    @JsonKey(name: 'state_version') required int stateVersion,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _Game;

  factory Game.fromJson(Map<String, dynamic> json) => _$GameFromJson(json);
}
