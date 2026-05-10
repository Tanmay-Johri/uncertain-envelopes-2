import '../../data/models/order.dart';

/// How far **before** a synthetic `cmd:*` row’s [Order.orderCreatedAt] a
/// materialised real row may still be considered the same submission (clock
/// skew, client/server ordering).
const Duration kPersonalOrdersDedupClockSkewBackward = Duration(minutes: 2);

bool _sameCreateOrderSignature(Order real, Order synthetic) {
  if (real.type != synthetic.type) return false;
  if (real.quantityInitial != synthetic.quantityInitial) return false;
  final rp = real.pricePerStock;
  final sp = synthetic.pricePerStock;
  if (rp == null && sp == null) return true;
  if (rp == null || sp == null) return false;
  return rp == sp;
}

bool _isCmdPlaceholder(Order o) => o.orderId.startsWith('cmd:');

/// Merges the player’s real `orders` rows with synthetic `cmd:*` rows built
/// from pending `create_order` commands, then drops synthetics that already
/// have a matching materialised row (B-GAP-1 dedup when the backend does not
/// link `order_id` to the command).
///
/// [mineReal] must already be filtered to this player. [synthetic] are
/// typically from [orderFromPendingCreateCommand]. Newest first.
List<Order> mergePersonalOrdersDedupingPlaceholders({
  required List<Order> mineReal,
  required List<Order> synthetic,
  Duration clockSkewBackward = kPersonalOrdersDedupClockSkewBackward,
}) {
  final reals = [
    for (final o in mineReal)
      if (!_isCmdPlaceholder(o)) o,
  ];
  final synthetics = [
    for (final o in synthetic)
      if (_isCmdPlaceholder(o)) o,
  ];

  final synthSorted = [...synthetics]
    ..sort((a, b) => a.orderCreatedAt.compareTo(b.orderCreatedAt));

  final usedRealIds = <String>{};
  final keptSynthetic = <Order>[];

  for (final s in synthSorted) {
    Order? chosen;
    for (final r in reals) {
      if (usedRealIds.contains(r.orderId)) continue;
      if (!_sameCreateOrderSignature(r, s)) continue;
      if (r.orderCreatedAt.isBefore(s.orderCreatedAt.subtract(clockSkewBackward))) {
        continue;
      }
      if (chosen == null || r.orderCreatedAt.isBefore(chosen.orderCreatedAt)) {
        chosen = r;
      }
    }
    if (chosen != null) {
      usedRealIds.add(chosen.orderId);
    } else {
      keptSynthetic.add(s);
    }
  }

  final merged = [...mineReal, ...keptSynthetic]
    ..sort((a, b) => b.orderCreatedAt.compareTo(a.orderCreatedAt));
  return List.unmodifiable(merged);
}
