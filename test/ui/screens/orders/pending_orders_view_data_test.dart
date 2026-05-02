import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/core/trading/personal_order.dart';
import 'package:uncertain_envelopes_2/ui/screens/orders/pending_orders_mock_data.dart';
import 'package:uncertain_envelopes_2/ui/screens/orders/pending_orders_view_data.dart';

PendingOrderListItem _item(
  String id,
  PersonalOrderSide side, {
  DateTime? createdAt,
}) {
  return PendingOrderListItem(
    gameTitle: id,
    gameDescription: 'd',
    order: PersonalOrder(
      id: id,
      side: side,
      orderType: PersonalOrderType.limit,
      quantityInitial: 1,
      quantityCurrent: 1,
      limitPrice: 1,
      status: PersonalOrderStatus.resting,
      createdAt: createdAt,
    ),
  );
}

void main() {
  group('applyPendingOrdersSideFilter', () {
    final items = [
      _item('a', PersonalOrderSide.buy, createdAt: DateTime.utc(2026, 1, 2)),
      _item('b', PersonalOrderSide.sell, createdAt: DateTime.utc(2026, 1, 1)),
    ];

    test('all returns copy of list', () {
      final out = applyPendingOrdersSideFilter(
        items,
        PendingOrdersSideFilter.all,
      );
      expect(out.length, 2);
      expect(identical(out, items), isFalse);
    });

    test('buy keeps only buys', () {
      final out = applyPendingOrdersSideFilter(
        items,
        PendingOrdersSideFilter.buy,
      );
      expect(out.length, 1);
      expect(out.single.order.id, 'a');
    });

    test('sell keeps only sells', () {
      final out = applyPendingOrdersSideFilter(
        items,
        PendingOrdersSideFilter.sell,
      );
      expect(out.length, 1);
      expect(out.single.order.id, 'b');
    });

    test('empty in empty out', () {
      expect(
        applyPendingOrdersSideFilter(
          [],
          PendingOrdersSideFilter.buy,
        ),
        isEmpty,
      );
    });
  });

  group('pendingOrderListItemsSortedNewestFirst', () {
    test('sorts by createdAt descending; nulls last', () {
      final a = _item('old', PersonalOrderSide.buy, createdAt: DateTime.utc(2026, 1, 1));
      final b = _item('new', PersonalOrderSide.sell, createdAt: DateTime.utc(2026, 6, 1));
      final c = _item('non', PersonalOrderSide.buy, createdAt: null);
      final sorted = pendingOrderListItemsSortedNewestFirst([a, b, c]);
      expect(sorted.map((e) => e.order.id).toList(), ['new', 'old', 'non']);
    });

    test('stable tie-break on id when same instant', () {
      final t = DateTime.utc(2026, 1, 1);
      final x = _item('zz', PersonalOrderSide.buy, createdAt: t);
      final y = _item('aa', PersonalOrderSide.sell, createdAt: t);
      final sorted = pendingOrderListItemsSortedNewestFirst([x, y]);
      expect(sorted.map((e) => e.order.id).toList(), ['aa', 'zz']);
    });
  });

  group('kMockPendingOrders', () {
    test('non-empty and all orders are cancellable statuses', () {
      final list = kMockPendingOrders();
      expect(list, isNotEmpty);
      for (final e in list) {
        expect(
          personalOrderCanCancel(e.order.status),
          isTrue,
          reason: e.order.id,
        );
      }
    });
  });
}
