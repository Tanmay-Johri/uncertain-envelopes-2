import 'package:flutter/foundation.dart';

/// C6 mock-only: side of a personal order row (UI + tests).
enum PersonalOrderSide { buy, sell }

/// C6 mock-only: limit vs market (drives price field visibility).
enum PersonalOrderType { limit, market }

/// C6 mock-only: lifecycle for the player’s own orders.
///
/// **Cancel (UI):** only [resting] — matches plan “cancel resting only”.
/// [inQueue] / [beingProcessed] show no cancel (command pipeline).
enum PersonalOrderStatus {
  inQueue,
  beingProcessed,
  resting,
  filled,
  cancelled,
}

/// One row in the player’s “active orders” list (mock data until Phase 2).
@immutable
class PersonalOrder {
  const PersonalOrder({
    required this.id,
    required this.side,
    required this.orderType,
    required this.quantity,
    this.limitPrice,
    required this.status,
    this.createdAt,
  });

  final String id;
  final PersonalOrderSide side;
  final PersonalOrderType orderType;
  final int quantity;
  final double? limitPrice;
  final PersonalOrderStatus status;

  /// Mock / Phase 2: wall time when the order was created (dashboard **Created:** line).
  final DateTime? createdAt;

  PersonalOrder copyWith({
    String? id,
    PersonalOrderSide? side,
    PersonalOrderType? orderType,
    int? quantity,
    double? limitPrice,
    PersonalOrderStatus? status,
    DateTime? createdAt,
  }) {
    return PersonalOrder(
      id: id ?? this.id,
      side: side ?? this.side,
      orderType: orderType ?? this.orderType,
      quantity: quantity ?? this.quantity,
      limitPrice: limitPrice ?? this.limitPrice,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Whether the UI may offer **Cancel** for this status (C6 mock rules).
bool personalOrderCanCancel(PersonalOrderStatus status) {
  return status == PersonalOrderStatus.resting;
}
