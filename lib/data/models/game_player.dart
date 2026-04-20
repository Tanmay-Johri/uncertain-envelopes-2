import 'package:freezed_annotation/freezed_annotation.dart';

import '../enums/lobby_status.dart';

part 'game_player.freezed.dart';
part 'game_player.g.dart';

/// Mirror of the `games_players` junction table. See PRD §games_players.
///
/// `deltaEnvelopes` is an integer because every execution settles integer
/// quantities. `pnl` is populated at finalise time via the PRD formula
/// `delta_cash + envelope_price * delta_envelopes`.
@freezed
class GamePlayer with _$GamePlayer {
  const factory GamePlayer({
    @JsonKey(name: 'games_players_row_id') required String gamesPlayersRowId,
    @JsonKey(name: 'map_game_id') required String mapGameId,
    @JsonKey(name: 'map_player_id') required String mapPlayerId,
    @JsonKey(
      name: 'lobby_status',
      fromJson: LobbyStatus.fromWire,
      toJson: LobbyStatus.toWire,
    )
    required LobbyStatus lobbyStatus,
    @JsonKey(name: 'joined_at') required DateTime joinedAt,
    @JsonKey(name: 'is_admin') required bool isAdmin,
    @JsonKey(name: 'delta_cash') required double deltaCash,
    @JsonKey(name: 'delta_envelopes') required int deltaEnvelopes,
    @JsonKey(name: 'pnl') required double pnl,
  }) = _GamePlayer;

  factory GamePlayer.fromJson(Map<String, dynamic> json) =>
      _$GamePlayerFromJson(json);
}
