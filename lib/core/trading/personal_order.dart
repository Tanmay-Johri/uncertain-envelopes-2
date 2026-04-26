import 'package:flutter/foundation.dart';

/// C6 mock-only: side of a personal order row (UI + tests).
enum PersonalOrderSide { buy, sell }

/// C6 mock-only: limit vs market (drives price field visibility).
enum PersonalOrderType { limit, market }

/// C6 mock-only: lifecycle for the player’s own orders (see PRD `orders.status`).
enum PersonalOrderStatus {
  inQueue,
  beingProcessed,
  resting,
  filled,
  cancelled,
}

/// One row in the player’s “active orders” list (mock data until Phase 2).
///
/// Field names align with PRD `orders`: `quantity_initial`, `quantity_current`,
/// `price_per_stock`, `order_created_at`, `status`. **order_id** is [id] but is
/// not shown in the UI.
@immutable
class PersonalOrder {
  const PersonalOrder({
    required this.id,
    required this.side,
    required this.orderType,
    required this.quantityInitial,
    required this.quantityCurrent,
    this.limitPrice,
    required this.status,
    this.createdAt,
  });

  final String id;
  final PersonalOrderSide side;
  final PersonalOrderType orderType;

  /// PRD `quantity_initial` — original size; never changes in the model.
  final int quantityInitial;

  /// PRD `quantity_current` — remaining unmatched quantity.
  final int quantityCurrent;

  /// PRD `price_per_stock` for limit orders; `null` for market.
  final double? limitPrice;
  final PersonalOrderStatus status;

  /// PRD `order_created_at` (UTC in backend); shown as local time in UI.
  final DateTime? createdAt;

  PersonalOrder copyWith({
    String? id,
    PersonalOrderSide? side,
    PersonalOrderType? orderType,
    int? quantityInitial,
    int? quantityCurrent,
    double? limitPrice,
    PersonalOrderStatus? status,
    DateTime? createdAt,
  }) {
    return PersonalOrder(
      id: id ?? this.id,
      side: side ?? this.side,
      orderType: orderType ?? this.orderType,
      quantityInitial: quantityInitial ?? this.quantityInitial,
      quantityCurrent: quantityCurrent ?? this.quantityCurrent,
      limitPrice: limitPrice ?? this.limitPrice,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Whether the player may **send a cancellation request** (PRD: only while
/// `order_resting`).
bool personalOrderCanCancel(PersonalOrderStatus status) {
  return status == PersonalOrderStatus.resting;
}
