// Silences `invalid_annotation_target` for `@JsonKey(name: ...)` on
// freezed constructor parameters — see lib/data/models/game.dart.
// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'player.freezed.dart';
part 'player.g.dart';

/// Mirror of the `players` table. Auth is handled by Supabase Auth; this row
/// stores game-facing profile data. See PRD §players.
@freezed
class Player with _$Player {
  const factory Player({
    @JsonKey(name: 'player_id') required String playerId,
    @JsonKey(name: 'username') required String username,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'email') required String email,
  }) = _Player;

  factory Player.fromJson(Map<String, dynamic> json) => _$PlayerFromJson(json);
}
