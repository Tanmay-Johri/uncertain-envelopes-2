// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_player.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$GamePlayerImpl _$$GamePlayerImplFromJson(Map<String, dynamic> json) =>
    _$GamePlayerImpl(
      gamesPlayersRowId: json['games_players_row_id'] as String,
      mapGameId: json['map_game_id'] as String,
      mapPlayerId: json['map_player_id'] as String,
      lobbyStatus: LobbyStatus.fromWire(json['lobby_status'] as String),
      joinedAt: DateTime.parse(json['joined_at'] as String),
      isAdmin: json['is_admin'] as bool,
      deltaCash: (json['delta_cash'] as num).toDouble(),
      deltaEnvelopes: (json['delta_envelopes'] as num).toInt(),
      pnl: (json['pnl'] as num).toDouble(),
    );

Map<String, dynamic> _$$GamePlayerImplToJson(_$GamePlayerImpl instance) =>
    <String, dynamic>{
      'games_players_row_id': instance.gamesPlayersRowId,
      'map_game_id': instance.mapGameId,
      'map_player_id': instance.mapPlayerId,
      'lobby_status': LobbyStatus.toWire(instance.lobbyStatus),
      'joined_at': instance.joinedAt.toIso8601String(),
      'is_admin': instance.isAdmin,
      'delta_cash': instance.deltaCash,
      'delta_envelopes': instance.deltaEnvelopes,
      'pnl': instance.pnl,
    };
