import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/core/trading/order_quantity_input.dart';

void main() {
  group('normalizeOrderQtyFieldText', () {
    test('empty becomes 1', () {
      expect(normalizeOrderQtyFieldText(''), '1');
      expect(normalizeOrderQtyFieldText('   '), '1');
    });

    test('floors decimals and enforces min 1', () {
      expect(normalizeOrderQtyFieldText('3.7'), '3');
      expect(normalizeOrderQtyFieldText('3.99'), '3');
      expect(normalizeOrderQtyFieldText('0.9'), '1');
      expect(normalizeOrderQtyFieldText('0'), '1');
      expect(normalizeOrderQtyFieldText('-2'), '1');
    });

    test('garbage becomes 1', () {
      expect(normalizeOrderQtyFieldText('abc'), '1');
      expect(normalizeOrderQtyFieldText('1x'), '1');
    });

    test('integers pass through', () {
      expect(normalizeOrderQtyFieldText('42'), '42');
    });
  });

  group('parseOrderQtyForSubmit', () {
    test('empty is null', () {
      expect(parseOrderQtyForSubmit(''), isNull);
      expect(parseOrderQtyForSubmit('  '), isNull);
    });

    test('floors and requires >= 1', () {
      expect(parseOrderQtyForSubmit('3.7'), 3);
      expect(parseOrderQtyForSubmit('9.01'), 9);
    });

    test('below 1 after floor is null', () {
      expect(parseOrderQtyForSubmit('0'), isNull);
      expect(parseOrderQtyForSubmit('0.9'), isNull);
    });

    test('invalid is null', () {
      expect(parseOrderQtyForSubmit('abc'), isNull);
    });
  });

  group('OrderQtyDecimalTextInputFormatter', () {
    test('rejects second decimal point', () {
      const f = OrderQtyDecimalTextInputFormatter();
      const oldV = TextEditingValue(text: '1.2');
      const newV = TextEditingValue(text: '1.2.3');
      expect(f.formatEditUpdate(oldV, newV), oldV);
    });
  });
}
