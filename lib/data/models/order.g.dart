// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$OrderImpl _$$OrderImplFromJson(Map<String, dynamic> json) => _$OrderImpl(
  orderId: json['order_id'] as String,
  createdByPlayerId: json['created_by_player_id'] as String,
  gameId: json['game_id'] as String,
  type: OrderType.fromWire(json['type'] as String),
  quantityInitial: (json['quantity_initial'] as num).toInt(),
  quantityCurrent: (json['quantity_current'] as num).toInt(),
  pricePerStock: (json['price_per_stock'] as num?)?.toDouble(),
  status: OrderStatus.fromWire(json['status'] as String),
  orderCreatedAt: DateTime.parse(json['order_created_at'] as String),
  orderUpdatedAt: DateTime.parse(json['order_updated_at'] as String),
);

Map<String, dynamic> _$$OrderImplToJson(_$OrderImpl instance) =>
    <String, dynamic>{
      'order_id': instance.orderId,
      'created_by_player_id': instance.createdByPlayerId,
      'game_id': instance.gameId,
      'type': OrderType.toWire(instance.type),
      'quantity_initial': instance.quantityInitial,
      'quantity_current': instance.quantityCurrent,
      'price_per_stock': instance.pricePerStock,
      'status': OrderStatus.toWire(instance.status),
      'order_created_at': instance.orderCreatedAt.toIso8601String(),
      'order_updated_at': instance.orderUpdatedAt.toIso8601String(),
    };
