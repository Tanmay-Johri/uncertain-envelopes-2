import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:uncertain_envelopes_2/ui/screens/trading/trading_stat_format.dart';

void main() {
  group('formatTradingDeltaCash', () {
    test('prefixes plus for positive', () {
      expect(formatTradingDeltaCash(12500), r'+$12,500');
    });

    test('prefixes minus before dollar for negative', () {
      expect(formatTradingDeltaCash(-12500), r'-$12,500');
    });

    test('zero is neutral currency', () {
      expect(formatTradingDeltaCash(0), r'$0');
    });
  });

  group('formatTradingDeltaEnvelopes', () {
    test('prefixes plus for positive', () {
      expect(formatTradingDeltaEnvelopes(45), '+45');
    });

    test('keeps minus for negative', () {
      expect(formatTradingDeltaEnvelopes(-45), '-45');
    });

    test('zero has no plus', () {
      expect(formatTradingDeltaEnvelopes(0), '0');
    });
  });

  group('formatTradeLogTime', () {
    test('matches DateFormat Hm on local instant', () {
      final utc = DateTime.utc(2026, 5, 10, 19, 7);
      expect(
        formatTradeLogTime(utc, localeName: 'en_US'),
        DateFormat.Hm('en_US').format(utc.toLocal()),
      );
    });
  });

  group('formatProjectedPnl', () {
    test('matches whole-dollar cash convention', () {
      expect(formatProjectedPnl(5750), r'+$5,750');
      expect(formatProjectedPnl(0), r'$0');
    });
  });
}
