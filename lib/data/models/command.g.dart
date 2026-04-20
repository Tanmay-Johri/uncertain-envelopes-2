// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'command.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CommandImpl _$$CommandImplFromJson(Map<String, dynamic> json) =>
    _$CommandImpl(
      commandId: json['command_id'] as String,
      commandGameId: json['command_game_id'] as String?,
      commandCreatedAt: DateTime.parse(json['command_created_at'] as String),
      playerId: json['player_id'] as String?,
      commandType: CommandType.fromWire(json['command_type'] as String),
      payload: json['payload'] as Map<String, dynamic>,
      commandStatus: CommandStatus.fromWire(json['command_status'] as String),
      claimToken: json['claim_token'] as String?,
      claimedAt: json['claimed_at'] == null
          ? null
          : DateTime.parse(json['claimed_at'] as String),
      attemptCount: (json['attempt_count'] as num).toInt(),
      finishedAt: json['finished_at'] == null
          ? null
          : DateTime.parse(json['finished_at'] as String),
    );

Map<String, dynamic> _$$CommandImplToJson(_$CommandImpl instance) =>
    <String, dynamic>{
      'command_id': instance.commandId,
      'command_game_id': instance.commandGameId,
      'command_created_at': instance.commandCreatedAt.toIso8601String(),
      'player_id': instance.playerId,
      'command_type': CommandType.toWire(instance.commandType),
      'payload': instance.payload,
      'command_status': CommandStatus.toWire(instance.commandStatus),
      'claim_token': instance.claimToken,
      'claimed_at': instance.claimedAt?.toIso8601String(),
      'attempt_count': instance.attemptCount,
      'finished_at': instance.finishedAt?.toIso8601String(),
    };
