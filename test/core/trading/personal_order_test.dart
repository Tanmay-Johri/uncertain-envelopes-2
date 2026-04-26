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
        expect(c.foreground.value, 0xFFF87171);
        expect(c.border, AppColors.secondary.withValues(alpha: 0.35));
      }
    });

    test('green for order_closed (filled)', () {
      final c = personalOrderStatusChipStyle(PersonalOrderStatus.filled);
      expect(c.foreground, AppColors.primary);
    });

    test('blue for in-flight statuses', () {
      final c = personalOrderStatusChipStyle(PersonalOrderStatus.inQueue);
      expect(c.foreground.value, 0xFF60A5FA);
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
