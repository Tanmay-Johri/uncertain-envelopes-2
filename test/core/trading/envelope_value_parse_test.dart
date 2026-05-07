import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/core/trading/envelope_value_parse.dart'
    show
        formatAssumptionInputNumber,
        formatEnvelopeUsdField,
        tryParseAssumptionValue;

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

  test('formatEnvelopeUsdField always two decimals', () {
    expect(formatEnvelopeUsdField(150), r'$150.00');
    expect(formatEnvelopeUsdField(0), r'$0.00');
    expect(formatEnvelopeUsdField(125.5), r'$125.50');
  });
}
