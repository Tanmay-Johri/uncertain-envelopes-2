// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'execution.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ExecutionImpl _$$ExecutionImplFromJson(Map<String, dynamic> json) =>
    _$ExecutionImpl(
      executionsId: json['executions_id'] as String,
      executionsGameId: json['executions_game_id'] as String,
      buyOrderId: json['buy_order_id'] as String,
      sellOrderId: json['sell_order_id'] as String,
      quantity: (json['quantity'] as num).toInt(),
      executionPrice: (json['execution_price'] as num).toDouble(),
      executedAt: DateTime.parse(json['executed_at'] as String),
    );

Map<String, dynamic> _$$ExecutionImplToJson(_$ExecutionImpl instance) =>
    <String, dynamic>{
      'executions_id': instance.executionsId,
      'executions_game_id': instance.executionsGameId,
      'buy_order_id': instance.buyOrderId,
      'sell_order_id': instance.sellOrderId,
      'quantity': instance.quantity,
      'execution_price': instance.executionPrice,
      'executed_at': instance.executedAt.toIso8601String(),
    };
