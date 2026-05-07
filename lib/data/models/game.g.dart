// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$GameImpl _$$GameImplFromJson(Map<String, dynamic> json) => _$GameImpl(
  gameId: json['game_id'] as String,
  gameName: json['game_name'] as String,
  gameDescription: json['game_description'] as String?,
  gameCreatedAt: DateTime.parse(json['game_created_at'] as String),
  gameSecurity: GameSecurity.fromWire(json['game_security'] as String),
  isRanked: IsRanked.fromWire(json['is_ranked'] as String),
  gameMaxPlayers: (json['game_max_players'] as num).toInt(),
  joiningCode: json['joining_code'] as String,
  endCondition: EndCondition.fromWire(json['end_condition'] as String),
  totalDecidedDurationSeconds: (json['total_decided_duration_seconds'] as num?)
      ?.toInt(),
  endTimeDecided: json['end_time_decided'] == null
      ? null
      : DateTime.parse(json['end_time_decided'] as String),
  startTime: json['start_time'] == null
      ? null
      : DateTime.parse(json['start_time'] as String),
  endTimeActual: json['end_time_actual'] == null
      ? null
      : DateTime.parse(json['end_time_actual'] as String),
  gameState: GameState.fromWire(json['game_state'] as String),
  adminPlayerId: json['admin_player_id'] as String,
  lastTradedPrice: (json['last_traded_price'] as num?)?.toDouble(),
  envelopePrice: (json['envelope_price'] as num?)?.toDouble(),
  stateVersion: (json['state_version'] as num).toInt(),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$$GameImplToJson(_$GameImpl instance) =>
    <String, dynamic>{
      'game_id': instance.gameId,
      'game_name': instance.gameName,
      'game_description': instance.gameDescription,
      'game_created_at': instance.gameCreatedAt.toIso8601String(),
      'game_security': GameSecurity.toWire(instance.gameSecurity),
      'is_ranked': IsRanked.toWire(instance.isRanked),
      'game_max_players': instance.gameMaxPlayers,
      'joining_code': instance.joiningCode,
      'end_condition': EndCondition.toWire(instance.endCondition),
      'total_decided_duration_seconds': instance.totalDecidedDurationSeconds,
      'end_time_decided': instance.endTimeDecided?.toIso8601String(),
      'start_time': instance.startTime?.toIso8601String(),
      'end_time_actual': instance.endTimeActual?.toIso8601String(),
      'game_state': GameState.toWire(instance.gameState),
      'admin_player_id': instance.adminPlayerId,
      'last_traded_price': instance.lastTradedPrice,
      'envelope_price': instance.envelopePrice,
      'state_version': instance.stateVersion,
      'updated_at': instance.updatedAt.toIso8601String(),
    };
