import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/core/theme/app_colors.dart';
import 'package:uncertain_envelopes_2/core/trading/personal_order.dart';

void main() {
  group('personalOrderCanCancel', () {
    test('true for queued, processing, and resting; false when terminal', () {
      expect(personalOrderCanCancel(PersonalOrderStatus.inQueue), isTrue);
      expect(
        personalOrderCanCancel(PersonalOrderStatus.beingProcessed),
        isTrue,
      );
      expect(personalOrderCanCancel(PersonalOrderStatus.resting), isTrue);
      expect(personalOrderCanCancel(PersonalOrderStatus.filled), isFalse);
      expect(personalOrderCanCancel(PersonalOrderStatus.cancelled), isFalse);
      expect(personalOrderCanCancel(PersonalOrderStatus.rejected), isFalse);
      expect(personalOrderCanCancel(PersonalOrderStatus.gameEnded), isFalse);
    });
  });

  group('personalOrderClearsCancellationPending', () {
    test('true for terminal outcomes', () {
      expect(
        personalOrderClearsCancellationPending(PersonalOrderStatus.filled),
        isTrue,
      );
      expect(
        personalOrderClearsCancellationPending(PersonalOrderStatus.cancelled),
        isTrue,
      );
      expect(
        personalOrderClearsCancellationPending(PersonalOrderStatus.rejected),
        isTrue,
      );
      expect(
        personalOrderClearsCancellationPending(PersonalOrderStatus.gameEnded),
        isTrue,
      );
      expect(
        personalOrderClearsCancellationPending(PersonalOrderStatus.resting),
        isFalse,
      );
    });
  });

  group('personalOrderStatusChipStyle', () {
    test('red for cancelled, rejected, game_ended', () {
      for (final s in [
        PersonalOrderStatus.cancelled,
        PersonalOrderStatus.rejected,
        PersonalOrderStatus.gameEnded,
      ]) {
        final c = personalOrderStatusChipStyle(s);
        expect(c.foreground.toARGB32(), 0xFFF87171);
        expect(c.border, AppColors.secondary.withValues(alpha: 0.35));
      }
    });

    test('green for order_closed (filled)', () {
      final c = personalOrderStatusChipStyle(PersonalOrderStatus.filled);
      expect(c.foreground, AppColors.primary);
    });

    test('blue for in-flight statuses', () {
      final c = personalOrderStatusChipStyle(PersonalOrderStatus.inQueue);
      expect(c.foreground.toARGB32(), 0xFF60A5FA);
    });
  });

  group('personalOrdersSortedNewestFirst', () {
    test('orders by createdAt descending; nulls last', () {
      final t1 = DateTime.utc(2026, 1, 1, 10);
      final t2 = DateTime.utc(2026, 1, 1, 12);
      final orders = [
        PersonalOrder(
          id: 'old',
          side: PersonalOrderSide.buy,
          orderType: PersonalOrderType.limit,
          quantityInitial: 1,
          quantityCurrent: 1,
          limitPrice: 1,
          status: PersonalOrderStatus.resting,
          createdAt: t1,
        ),
        PersonalOrder(
          id: 'new',
          side: PersonalOrderSide.sell,
          orderType: PersonalOrderType.limit,
          quantityInitial: 1,
          quantityCurrent: 1,
          limitPrice: 2,
          status: PersonalOrderStatus.inQueue,
          createdAt: t2,
        ),
        PersonalOrder(
          id: 'non',
          side: PersonalOrderSide.buy,
          orderType: PersonalOrderType.market,
          quantityInitial: 1,
          quantityCurrent: 1,
          limitPrice: null,
          status: PersonalOrderStatus.inQueue,
          createdAt: null,
        ),
      ];
      final sorted = personalOrdersSortedNewestFirst(orders);
      expect(sorted.map((e) => e.id), ['new', 'old', 'non']);
    });

    test('tie-break by id when same instant', () {
      final t = DateTime.utc(2026, 1, 1);
      final orders = [
        PersonalOrder(
          id: 'b',
          side: PersonalOrderSide.buy,
          orderType: PersonalOrderType.limit,
          quantityInitial: 1,
          quantityCurrent: 1,
          limitPrice: 1,
          status: PersonalOrderStatus.resting,
          createdAt: t,
        ),
        PersonalOrder(
          id: 'a',
          side: PersonalOrderSide.buy,
          orderType: PersonalOrderType.limit,
          quantityInitial: 1,
          quantityCurrent: 1,
          limitPrice: 1,
          status: PersonalOrderStatus.resting,
          createdAt: t,
        ),
      ];
      expect(
        personalOrdersSortedNewestFirst(orders).map((e) => e.id),
        ['a', 'b'],
      );
    });
  });

  group('PersonalOrder.copyWith', () {
    test('replaces id only; keeps null limitPrice', () {
      const o = PersonalOrder(
        id: 'a',
        side: PersonalOrderSide.sell,
        orderType: PersonalOrderType.market,
        quantityInitial: 2,
        quantityCurrent: 2,
        limitPrice: null,
        status: PersonalOrderStatus.inQueue,
      );
      final n = o.copyWith(id: 'b');
      expect(n.id, 'b');
      expect(n.limitPrice, isNull);
      expect(n.side, PersonalOrderSide.sell);
    });
  });
}
