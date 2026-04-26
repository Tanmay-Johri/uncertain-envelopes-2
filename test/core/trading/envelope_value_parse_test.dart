import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/core/trading/envelope_value_parse.dart'
    show formatAssumptionInputNumber, tryParseAssumptionValue;

void main() {
  test('1. and trailing dot parse as 1', () {
    expect(tryParseAssumptionValue('1.'), 1.0);
    expect(tryParseAssumptionValue('1.  '), 1.0);
  });

  test('normal numbers', () {
    expect(tryParseAssumptionValue('1.1'), 1.1);
    expect(tryParseAssumptionValue('125'), 125.0);
  });

  test('empty and invalid', () {
    expect(tryParseAssumptionValue(''), isNull);
    expect(tryParseAssumptionValue('x'), isNull);
  });

  test('formatAssumptionInputNumber', () {
    expect(formatAssumptionInputNumber(150), '150');
    expect(formatAssumptionInputNumber(125.5), '125.50');
  });
}
