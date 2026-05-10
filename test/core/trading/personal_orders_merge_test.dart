import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/core/trading/personal_orders_merge.dart';
import 'package:uncertain_envelopes_2/data/enums/order_status.dart';
import 'package:uncertain_envelopes_2/data/enums/order_type.dart';
import 'package:uncertain_envelopes_2/data/models/order.dart';

Order _o({
  required String id,
  required OrderType type,
  required int qty,
  double? price,
  required DateTime at,
}) {
  return Order(
    orderId: id,
    createdByPlayerId: 'p1',
    gameId: 'g1',
    type: type,
    quantityInitial: qty,
    quantityCurrent: qty,
    pricePerStock: price,
    status: OrderStatus.orderResting,
    orderCreatedAt: at,
    orderUpdatedAt: at,
  );
}

void main() {
  final t0 = DateTime.utc(2026, 5, 9, 12);
  final t1 = DateTime.utc(2026, 5, 9, 12, 0, 30);
  final tOld = DateTime.utc(2026, 5, 9, 11);

  group('mergePersonalOrdersDedupingPlaceholders', () {
    test('drops synthetic when a matching real appears after the command time',
        () {
      final synth = _o(
        id: 'cmd:abc',
        type: OrderType.limitBuy,
        qty: 3,
        price: 10,
        at: t0,
      );
      final real = _o(
        id: 'ord-1',
        type: OrderType.limitBuy,
        qty: 3,
        price: 10,
        at: t1,
      );
      final out = mergePersonalOrdersDedupingPlaceholders(
        mineReal: [real],
        synthetic: [synth],
      );
      expect(out.map((e) => e.orderId).toList(), ['ord-1']);
    });

    test('keeps synthetic when real is too old (no cmd linkage false positive)',
        () {
      final synth = _o(
        id: 'cmd:abc',
        type: OrderType.limitBuy,
        qty: 3,
        price: 10,
        at: t0,
      );
      final real = _o(
        id: 'ord-old',
        type: OrderType.limitBuy,
        qty: 3,
        price: 10,
        at: tOld,
      );
      final out = mergePersonalOrdersDedupingPlaceholders(
        mineReal: [real],
        synthetic: [synth],
      );
      expect(out.map((e) => e.orderId).toList(), ['cmd:abc', 'ord-old']);
    });

    test('FIFO: oldest synthetic pairs earliest eligible real', () {
      final s1 = _o(
        id: 'cmd:1',
        type: OrderType.limitSell,
        qty: 1,
        price: 5,
        at: t0,
      );
      final s2 = _o(
        id: 'cmd:2',
        type: OrderType.limitSell,
        qty: 1,
        price: 5,
        at: t0.add(const Duration(seconds: 1)),
      );
      final r1 = _o(
        id: 'r-a',
        type: OrderType.limitSell,
        qty: 1,
        price: 5,
        at: t0.add(const Duration(seconds: 10)),
      );
      final r2 = _o(
        id: 'r-b',
        type: OrderType.limitSell,
        qty: 1,
        price: 5,
        at: t0.add(const Duration(seconds: 20)),
      );
      final out = mergePersonalOrdersDedupingPlaceholders(
        mineReal: [r2, r1],
        synthetic: [s2, s1],
      );
      expect(out.map((e) => e.orderId).toList(), ['r-b', 'r-a']);
    });

    test('does not pair two synthetics to one real', () {
      final s1 = _o(
        id: 'cmd:1',
        type: OrderType.marketBuy,
        qty: 2,
        price: null,
        at: t0,
      );
      final s2 = _o(
        id: 'cmd:2',
        type: OrderType.marketBuy,
        qty: 2,
        price: null,
        at: t0.add(const Duration(seconds: 1)),
      );
      final r1 = _o(
        id: 'only',
        type: OrderType.marketBuy,
        qty: 2,
        price: null,
        at: t1,
      );
      final out = mergePersonalOrdersDedupingPlaceholders(
        mineReal: [r1],
        synthetic: [s2, s1],
      );
      final ids = out.map((e) => e.orderId).toSet();
      expect(ids, contains('only'));
      expect(ids.where((id) => id.startsWith('cmd:')), hasLength(1));
    });

    test('qty mismatch does not dedup', () {
      final synth = _o(
        id: 'cmd:x',
        type: OrderType.limitBuy,
        qty: 5,
        price: 1,
        at: t0,
      );
      final real = _o(
        id: 'r1',
        type: OrderType.limitBuy,
        qty: 6,
        price: 1,
        at: t1,
      );
      final out = mergePersonalOrdersDedupingPlaceholders(
        mineReal: [real],
        synthetic: [synth],
      );
      expect(out, hasLength(2));
    });

    test('respects custom backward skew', () {
      final synth = _o(
        id: 'cmd:x',
        type: OrderType.limitBuy,
        qty: 1,
        price: 2,
        at: t0,
      );
      final real = _o(
        id: 'r1',
        type: OrderType.limitBuy,
        qty: 1,
        price: 2,
        at: t0.subtract(const Duration(seconds: 15)),
      );
      expect(
        mergePersonalOrdersDedupingPlaceholders(
          mineReal: [real],
          synthetic: [synth],
        ),
        hasLength(1),
      );
      expect(
        mergePersonalOrdersDedupingPlaceholders(
          mineReal: [real],
          synthetic: [synth],
          clockSkewBackward: const Duration(seconds: 10),
        ),
        hasLength(2),
      );
    });
  });
}
