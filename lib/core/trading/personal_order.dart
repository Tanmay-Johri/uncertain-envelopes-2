import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';

import '../theme/app_colors.dart';

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
  rejected,
  gameEnded,
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

/// Active-orders panel: **newest** [PersonalOrder.createdAt] at the top.
/// Missing [createdAt] sorts **last** (stable tie-break: [PersonalOrder.id]).
List<PersonalOrder> personalOrdersSortedNewestFirst(List<PersonalOrder> orders) {
  final copy = List<PersonalOrder>.from(orders);
  copy.sort((a, b) {
    final ta = a.createdAt;
    final tb = b.createdAt;
    if (ta == null && tb == null) return a.id.compareTo(b.id);
    if (ta == null) return 1;
    if (tb == null) return -1;
    final cmp = tb.compareTo(ta);
    if (cmp != 0) return cmp;
    return a.id.compareTo(b.id);
  });
  return copy;
}

/// PRD pipeline statuses still eligible to match or rest: `in_queue`,
/// `being_processed`, `order_resting`. Used for the trading screen
/// “active only” filter (hides `order_closed`, `cancelled`, etc.).
bool personalOrderIsPipelineActive(PersonalOrderStatus status) {
  return switch (status) {
    PersonalOrderStatus.inQueue ||
    PersonalOrderStatus.beingProcessed ||
    PersonalOrderStatus.resting =>
      true,
    PersonalOrderStatus.filled ||
    PersonalOrderStatus.cancelled ||
    PersonalOrderStatus.rejected ||
    PersonalOrderStatus.gameEnded =>
      false,
  };
}

/// Whether the player may **send a cancellation request** from the UI.
///
/// Backend only accepts cancel / partial-cancel while `order_resting`; the UI
/// matches that so we never show a working cancel button for pipeline rows
/// that the processor would reject (UE002).
bool personalOrderCanCancel(PersonalOrderStatus status) {
  return switch (status) {
    PersonalOrderStatus.resting => true,
    PersonalOrderStatus.inQueue ||
    PersonalOrderStatus.beingProcessed ||
    PersonalOrderStatus.filled ||
    PersonalOrderStatus.cancelled ||
    PersonalOrderStatus.rejected ||
    PersonalOrderStatus.gameEnded =>
      false,
  };
}

/// Backend snapshot resolved an in-flight cancel (or the order ended another way).
bool personalOrderClearsCancellationPending(PersonalOrderStatus status) {
  return switch (status) {
    PersonalOrderStatus.filled ||
    PersonalOrderStatus.cancelled ||
    PersonalOrderStatus.rejected ||
    PersonalOrderStatus.gameEnded =>
      true,
    PersonalOrderStatus.inQueue ||
    PersonalOrderStatus.beingProcessed ||
    PersonalOrderStatus.resting =>
      false,
  };
}

/// PRD `orders.status` chip colours: red / green / blue families.
@immutable
class PersonalOrderStatusChipStyle {
  const PersonalOrderStatusChipStyle({
    required this.foreground,
    required this.border,
    required this.background,
  });

  final Color foreground;
  final Color border;
  final Color background;
}

/// - `cancelled`, `rejected`, `game_ended` → red
/// - `order_closed` ([PersonalOrderStatus.filled]) → green
/// - otherwise → blue
PersonalOrderStatusChipStyle personalOrderStatusChipStyle(
  PersonalOrderStatus status,
) {
  return switch (status) {
    PersonalOrderStatus.cancelled ||
    PersonalOrderStatus.rejected ||
    PersonalOrderStatus.gameEnded =>
      PersonalOrderStatusChipStyle(
        foreground: const Color(0xFFF87171),
        border: AppColors.secondary.withValues(alpha: 0.35),
        background: AppColors.secondary.withValues(alpha: 0.12),
      ),
    PersonalOrderStatus.filled => PersonalOrderStatusChipStyle(
        foreground: AppColors.primary,
        border: AppColors.primary.withValues(alpha: 0.35),
        background: AppColors.primary.withValues(alpha: 0.12),
      ),
    PersonalOrderStatus.inQueue ||
    PersonalOrderStatus.beingProcessed ||
    PersonalOrderStatus.resting =>
      const PersonalOrderStatusChipStyle(
        foreground: Color(0xFF60A5FA),
        border: Color(0x4D3B82F6),
        background: Color(0x1A3B82F6),
      ),
  };
}
