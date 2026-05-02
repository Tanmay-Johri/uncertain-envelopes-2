import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/ui/screens/orders/pending_orders_placed_label.dart';

void main() {
  group('pendingOrderPlacedLabel', () {
    final now = DateTime.utc(2026, 5, 3, 12, 0);

    test('null createdAt returns em dash', () {
      expect(
        pendingOrderPlacedLabel(createdAt: null, now: now),
        '—',
      );
    });

    test('just now clause includes localized clock separator', () {
      final s = pendingOrderPlacedLabel(
        createdAt: now.subtract(const Duration(seconds: 10)),
        now: now,
      );
      expect(s, startsWith('just now'));
      expect(s, contains('·'));
    });

    test('minutes ago includes clock separator', () {
      final s = pendingOrderPlacedLabel(
        createdAt: now.subtract(const Duration(minutes: 2)),
        now: now,
      );
      expect(s, startsWith('2m ago'));
      expect(s, contains('·'));
    });

    test('hours ago includes clock separator', () {
      final s = pendingOrderPlacedLabel(
        createdAt: now.subtract(const Duration(hours: 3)),
        now: now,
      );
      expect(s, startsWith('3h ago'));
      expect(s, contains('·'));
    });

    test('days ago includes clock separator until calendar branch', () {
      final s = pendingOrderPlacedLabel(
        createdAt: now.subtract(const Duration(days: 5)),
        now: now,
      );
      expect(s, startsWith('5d ago'));
      expect(s, contains('·'));
    });

    test('old orders use calendar line with literal at + time', () {
      final s = pendingOrderPlacedLabel(
        createdAt: DateTime.utc(2025, 1, 15, 8, 7),
        now: now,
      );
      expect(s.toLowerCase(), contains('2025'));
      expect(s, contains(' at '));
      expect(RegExp('[0-9]').hasMatch(s), isTrue);
    });

    test('negative duration uses calendar formatting with time', () {
      final future = now.add(const Duration(hours: 1));
      final s = pendingOrderPlacedLabel(createdAt: future, now: now);
      expect(s, isNot('—'));
      expect(s, contains(' at '));
    });
  });
}
