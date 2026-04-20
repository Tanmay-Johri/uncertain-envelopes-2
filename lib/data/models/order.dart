import 'package:freezed_annotation/freezed_annotation.dart';

import '../enums/order_status.dart';
import '../enums/order_type.dart';

part 'order.freezed.dart';
part 'order.g.dart';

/// Mirror of the `orders` table. See PRD §orders.
///
/// `pricePerStock` is null exactly when [type] is a market order. The
/// stored-proc contract enforces this; the Dart model allows null so we can
/// round-trip such rows without fighting the constraint at decode time.
@freezed
class Order with _$Order {
  const factory Order({
    @JsonKey(name: 'order_id') required String orderId,
    @JsonKey(name: 'created_by_player_id') required String createdByPlayerId,
    @JsonKey(name: 'game_id') required String gameId,
    @JsonKey(
      name: 'type',
      fromJson: OrderType.fromWire,
      toJson: OrderType.toWire,
    )
    required OrderType type,
    @JsonKey(name: 'quantity_initial') required int quantityInitial,
    @JsonKey(name: 'quantity_current') required int quantityCurrent,
    @JsonKey(name: 'price_per_stock') double? pricePerStock,
    @JsonKey(
      name: 'status',
      fromJson: OrderStatus.fromWire,
      toJson: OrderStatus.toWire,
    )
    required OrderStatus status,
    @JsonKey(name: 'order_created_at') required DateTime orderCreatedAt,
    @JsonKey(name: 'order_updated_at') required DateTime orderUpdatedAt,
  }) = _Order;

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);
}
