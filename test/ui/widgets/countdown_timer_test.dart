import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/core/theme/app_theme.dart';
import 'package:uncertain_envelopes_2/ui/widgets/countdown_timer.dart';

void main() {
  group('formatCountdownMmSs', () {
    test('formats zero', () {
      expect(formatCountdownMmSs(Duration.zero), '00:00');
    });

    test('formats under one minute', () {
      expect(formatCountdownMmSs(const Duration(seconds: 5)), '00:05');
    });

    test('formats exactly one minute', () {
      expect(formatCountdownMmSs(const Duration(minutes: 1)), '01:00');
    });

    test('formats 60 minutes', () {
      expect(formatCountdownMmSs(const Duration(minutes: 60)), '60:00');
    });

    test('clamps negative to zero representation', () {
      expect(formatCountdownMmSs(const Duration(seconds: -10)), '00:00');
    });
  });

  group('CountdownTimer', () {
    testWidgets('renders initial MM:SS', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: const Scaffold(
            body: CountdownTimer(
              initialRemaining: Duration(minutes: 1, seconds: 5),
            ),
          ),
        ),
      );
      expect(find.text('01:05'), findsOneWidget);
    });

    testWidgets('decrements when time is pumped', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: const Scaffold(
            body: CountdownTimer(
              initialRemaining: Duration(seconds: 10),
            ),
          ),
        ),
      );
      expect(find.text('00:10'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('00:07'), findsOneWidget);
    });

    testWidgets('onExpired fires once then stays at 00:00', (tester) async {
      var expired = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: CountdownTimer(
              initialRemaining: const Duration(seconds: 2),
              onExpired: () => expired++,
            ),
          ),
        ),
      );
      expect(expired, 0);
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('00:00'), findsOneWidget);
      expect(expired, 1);
      await tester.pump(const Duration(seconds: 50));
      expect(expired, 1);
    });

    testWidgets('zero initial shows 00:00 without throwing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: const Scaffold(
            body: CountdownTimer(initialRemaining: Duration.zero),
          ),
        ),
      );
      expect(find.text('00:00'), findsOneWidget);
    });
  });
}
