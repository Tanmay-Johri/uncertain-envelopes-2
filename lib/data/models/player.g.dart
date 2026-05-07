// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PlayerImpl _$$PlayerImplFromJson(Map<String, dynamic> json) => _$PlayerImpl(
  playerId: json['player_id'] as String,
  username: json['username'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
  email: json['email'] as String,
);

Map<String, dynamic> _$$PlayerImplToJson(_$PlayerImpl instance) =>
    <String, dynamic>{
      'player_id': instance.playerId,
      'username': instance.username,
      'created_at': instance.createdAt.toIso8601String(),
      'email': instance.email,
    };
