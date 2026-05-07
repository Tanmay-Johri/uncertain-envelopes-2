// Silences `invalid_annotation_target` for `@JsonKey(name: ...)` on
// freezed constructor parameters — see lib/data/models/game.dart.
// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

import '../enums/command_status.dart';
import '../enums/command_type.dart';

part 'command.freezed.dart';
part 'command.g.dart';

/// Mirror of the `commands` table. See PRD §commands.
///
/// [commandGameId] is nullable because the `create_game` command is submitted
/// before the game exists — the stored procedure backfills the game id after
/// creating the row. Every other command must carry a non-null game id.
///
/// [playerId] is nullable because the sweeper inserts system-triggered
/// commands (e.g., auto `end_trading` for timed games) with no originating
/// player.
///
/// [payload] is a raw JSON object and its shape varies by [commandType].
@freezed
class Command with _$Command {
  const factory Command({
    @JsonKey(name: 'command_id') required String commandId,
    @JsonKey(name: 'command_game_id') String? commandGameId,
    @JsonKey(name: 'command_created_at') required DateTime commandCreatedAt,
    @JsonKey(name: 'player_id') String? playerId,
    @JsonKey(
      name: 'command_type',
      fromJson: CommandType.fromWire,
      toJson: CommandType.toWire,
    )
    required CommandType commandType,
    @JsonKey(name: 'payload') required Map<String, dynamic> payload,
    @JsonKey(
      name: 'command_status',
      fromJson: CommandStatus.fromWire,
      toJson: CommandStatus.toWire,
    )
    required CommandStatus commandStatus,
    @JsonKey(name: 'claim_token') String? claimToken,
    @JsonKey(name: 'claimed_at') DateTime? claimedAt,
    @JsonKey(name: 'attempt_count') required int attemptCount,
    @JsonKey(name: 'finished_at') DateTime? finishedAt,
  }) = _Command;

  factory Command.fromJson(Map<String, dynamic> json) =>
      _$CommandFromJson(json);
}
