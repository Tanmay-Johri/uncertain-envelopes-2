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

    test('just now for very recent', () {
      expect(
        pendingOrderPlacedLabel(
          createdAt: now.subtract(const Duration(seconds: 10)),
          now: now,
        ),
        'just now',
      );
    });

    test('minutes ago', () {
      expect(
        pendingOrderPlacedLabel(
          createdAt: now.subtract(const Duration(minutes: 2)),
          now: now,
        ),
        '2m ago',
      );
    });

    test('hours ago', () {
      expect(
        pendingOrderPlacedLabel(
          createdAt: now.subtract(const Duration(hours: 3)),
          now: now,
        ),
        '3h ago',
      );
    });

    test('days ago', () {
      expect(
        pendingOrderPlacedLabel(
          createdAt: now.subtract(const Duration(days: 5)),
          now: now,
        ),
        '5d ago',
      );
    });

    test('negative duration falls back to absolute date', () {
      final future = now.add(const Duration(hours: 1));
      final s = pendingOrderPlacedLabel(createdAt: future, now: now);
      expect(s, isNot('—'));
      expect(s.isNotEmpty, isTrue);
    });
  });
}
