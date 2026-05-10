import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/core/trading/personal_order.dart';
import 'package:uncertain_envelopes_2/ui/screens/orders/pending_orders_mock_data.dart';
import 'package:uncertain_envelopes_2/ui/screens/orders/pending_orders_view_data.dart';

PendingOrderListItem _row(
  String id,
  String gameTitle,
  PersonalOrderSide side, {
  DateTime? createdAt,
}) {
  return PendingOrderListItem(
    gameId: 'g-$gameTitle',
    gameTitle: gameTitle,
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
  group('applyPendingOrdersFilters', () {
    final items = [
      _row('a', 'Alpha', PersonalOrderSide.buy, createdAt: DateTime.utc(2026, 1, 2)),
      _row('b', 'Beta', PersonalOrderSide.sell, createdAt: DateTime.utc(2026, 1, 1)),
    ];

    test('empty directions does not filter by side', () {
      final out = applyPendingOrdersFilters(
        items,
        const PendingOrdersFilterState(
          directions: {},
          selectedGameTitles: {},
        ),
      );
      expect(out.length, 2);
    });

    test('buy-only direction', () {
      final out = applyPendingOrdersFilters(
        items,
        const PendingOrdersFilterState(
          directions: {PersonalOrderSide.buy},
          selectedGameTitles: {},
        ),
      );
      expect(out.single.order.id, 'a');
    });

    test('sell-only direction', () {
      final out = applyPendingOrdersFilters(
        items,
        const PendingOrdersFilterState(
          directions: {PersonalOrderSide.sell},
          selectedGameTitles: {},
        ),
      );
      expect(out.single.order.id, 'b');
    });

    test('explicit both directions matches empty-direction behavior', () {
      final withBoth = applyPendingOrdersFilters(
        items,
        const PendingOrdersFilterState(
          directions: {
            PersonalOrderSide.buy,
            PersonalOrderSide.sell,
          },
          selectedGameTitles: {},
        ),
      );
      final emptyDir = applyPendingOrdersFilters(
        items,
        PendingOrdersFilterState.initial,
      );
      expect(
        withBoth.map((e) => e.order.id).toSet(),
        emptyDir.map((e) => e.order.id).toSet(),
      );
    });

    test('subset of games OR-matches titles', () {
      final three = [
        _row('1', 'G1', PersonalOrderSide.buy),
        _row('2', 'G1', PersonalOrderSide.sell),
        _row('3', 'G2', PersonalOrderSide.buy),
      ];
      final out = applyPendingOrdersFilters(
        three,
        const PendingOrdersFilterState(
          directions: {PersonalOrderSide.buy, PersonalOrderSide.sell},
          selectedGameTitles: {'G1'},
        ),
      );
      expect(out.map((e) => e.order.id).toSet(), {'1', '2'});
    });

    test('empty game set does not filter by title', () {
      final out = applyPendingOrdersFilters(
        items,
        const PendingOrdersFilterState(
          directions: {PersonalOrderSide.buy},
          selectedGameTitles: {},
        ),
      );
      expect(out.length, 1);
    });

    test('non-matching game titles yield empty', () {
      final out = applyPendingOrdersFilters(
        items,
        const PendingOrdersFilterState(
          directions: {PersonalOrderSide.buy, PersonalOrderSide.sell},
          selectedGameTitles: {'Nonexistent'},
        ),
      );
      expect(out, isEmpty);
    });

    test('empty items in empty out', () {
      expect(
        applyPendingOrdersFilters(
          [],
          PendingOrdersFilterState.initial,
        ),
        isEmpty,
      );
    });
  });

  group('PendingOrdersFilterState equality', () {
    test('same sets compare equal', () {
      const a = PendingOrdersFilterState(
        directions: {PersonalOrderSide.buy},
        selectedGameTitles: {'X'},
      );
      const b = PendingOrdersFilterState(
        directions: {PersonalOrderSide.buy},
        selectedGameTitles: {'X'},
      );
      expect(a, b);
    });
  });

  group('pendingOrderListItemsSortedNewestFirst', () {
    test('sorts by createdAt descending; nulls last', () {
      final a = _row('old', 'G', PersonalOrderSide.buy, createdAt: DateTime.utc(2026, 1, 1));
      final b = _row('new', 'G', PersonalOrderSide.sell, createdAt: DateTime.utc(2026, 6, 1));
      final c = _row('non', 'G', PersonalOrderSide.buy, createdAt: null);
      final sorted = pendingOrderListItemsSortedNewestFirst([a, b, c]);
      expect(sorted.map((e) => e.order.id).toList(), ['new', 'old', 'non']);
    });

    test('stable tie-break on id when same instant', () {
      final t = DateTime.utc(2026, 1, 1);
      final x = _row('zz', 'G', PersonalOrderSide.buy, createdAt: t);
      final y = _row('aa', 'G', PersonalOrderSide.sell, createdAt: t);
      final sorted = pendingOrderListItemsSortedNewestFirst([x, y]);
      expect(sorted.map((e) => e.order.id).toList(), ['aa', 'zz']);
    });
  });

  group('kMockPendingOrders', () {
    test('non-empty, cancellable statuses, sample times before now', () {
      final list = kMockPendingOrders();
      expect(list, isNotEmpty);
      final now = DateTime.now().toUtc();
      for (final e in list) {
        expect(
          personalOrderCanCancel(e.order.status),
          isTrue,
          reason: e.order.id,
        );
        final c = e.order.createdAt;
        expect(c, isNotNull, reason: e.order.id);
        expect(c!.isBefore(now), isTrue, reason: e.order.id);
      }
    });
  });
}
