import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/core/trading/personal_order.dart';

void main() {
  group('personalOrderCanCancel', () {
    test('true only for resting', () {
      expect(personalOrderCanCancel(PersonalOrderStatus.resting), isTrue);
      expect(personalOrderCanCancel(PersonalOrderStatus.inQueue), isFalse);
      expect(
        personalOrderCanCancel(PersonalOrderStatus.beingProcessed),
        isFalse,
      );
      expect(personalOrderCanCancel(PersonalOrderStatus.filled), isFalse);
      expect(personalOrderCanCancel(PersonalOrderStatus.cancelled), isFalse);
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
