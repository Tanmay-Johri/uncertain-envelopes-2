import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/core/theme/app_theme.dart';
import 'package:uncertain_envelopes_2/core/theme/app_typography.dart';
import 'package:uncertain_envelopes_2/ui/widgets/countdown_timer.dart';

/// Test clock controlled directly by the test body. Lets us simulate real
/// wall-clock advance without relying on `tester.pump`'s fake timer ticks.
class _TestClock {
  _TestClock(this._now);
  DateTime _now;
  DateTime call() => _now;
  void advance(Duration d) => _now = _now.add(d);
  void set(DateTime t) => _now = t;
}

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
    testWidgets('deadlineUtc recomputes from wall instant each tick',
        (tester) async {
      final clock = _TestClock(DateTime.utc(2030, 1, 1, 12));
      final deadline =
          DateTime.utc(2030, 1, 1, 12, 5, 30); // 5m 30s after clock start
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: CountdownTimer(
              deadlineUtc: deadline,
              now: clock.call,
            ),
          ),
        ),
      );
      expect(find.text('05:30'), findsOneWidget);

      clock.advance(const Duration(seconds: 90));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('04:00'), findsOneWidget);
    });

    testWidgets('renders initial MM:SS', (tester) async {
      final clock = _TestClock(DateTime.utc(2030, 1, 1, 12));
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: CountdownTimer(
              initialRemaining: const Duration(minutes: 1, seconds: 5),
              now: clock.call,
            ),
          ),
        ),
      );
      expect(find.text('01:05'), findsOneWidget);
    });

    testWidgets('decrements as wall clock advances', (tester) async {
      final clock = _TestClock(DateTime.utc(2030, 1, 1, 12));
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: CountdownTimer(
              initialRemaining: const Duration(seconds: 10),
              now: clock.call,
            ),
          ),
        ),
      );
      expect(find.text('00:10'), findsOneWidget);
      clock.advance(const Duration(seconds: 3));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('00:07'), findsOneWidget);
    });

    testWidgets(
        'does NOT drift when periodic ticks are delayed (regression: '
        'lobby was 2 minutes off after backgrounding)', (tester) async {
      final clock = _TestClock(DateTime.utc(2030, 1, 1, 12));
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: CountdownTimer(
              initialRemaining: const Duration(minutes: 27),
              now: clock.call,
            ),
          ),
        ),
      );
      expect(find.text('27:00'), findsOneWidget);

      // Simulate the device being backgrounded / OS-throttled for 2 minutes:
      // wall clock advances, but the periodic timer effectively misses many
      // ticks. We model this by advancing the clock without pumping in
      // between, then firing a single tick.
      clock.advance(const Duration(minutes: 2));
      await tester.pump(const Duration(seconds: 1));

      // With the OLD decrement-locally implementation this would still show
      // ~26:59 (one tick lost per minute of throttling). With wall-clock
      // anchoring it correctly snaps to ~25:00.
      expect(find.text('25:00'), findsOneWidget);
    });

    testWidgets('long throttled gap that crosses zero expires correctly',
        (tester) async {
      var expired = 0;
      final clock = _TestClock(DateTime.utc(2030, 1, 1, 12));
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: CountdownTimer(
              initialRemaining: const Duration(seconds: 30),
              now: clock.call,
              onExpired: () => expired++,
            ),
          ),
        ),
      );
      expect(find.text('00:30'), findsOneWidget);

      clock.advance(const Duration(minutes: 5));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('00:00'), findsOneWidget);
      expect(expired, 1);

      clock.advance(const Duration(minutes: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(expired, 1);
    });

    testWidgets('re-anchors when initialRemaining changes (add-time / resync)',
        (tester) async {
      final clock = _TestClock(DateTime.utc(2030, 1, 1, 12));
      Widget buildWith(Duration remaining) => MaterialApp(
            theme: buildAppTheme(),
            home: Scaffold(
              body: CountdownTimer(
                initialRemaining: remaining,
                now: clock.call,
              ),
            ),
          );

      await tester.pumpWidget(buildWith(const Duration(seconds: 30)));
      expect(find.text('00:30'), findsOneWidget);

      clock.advance(const Duration(seconds: 10));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('00:20'), findsOneWidget);

      // Provider re-snapshots with a new authoritative remaining (e.g. admin
      // pressed "Add Time" or the lobby provider rebuilt with fresher data).
      await tester.pumpWidget(buildWith(const Duration(minutes: 5)));
      expect(find.text('05:00'), findsOneWidget);

      clock.advance(const Duration(seconds: 5));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('04:55'), findsOneWidget);
    });

    testWidgets('onExpired fires once then stays at 00:00', (tester) async {
      var expired = 0;
      final clock = _TestClock(DateTime.utc(2030, 1, 1, 12));
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: CountdownTimer(
              initialRemaining: const Duration(seconds: 2),
              now: clock.call,
              onExpired: () => expired++,
            ),
          ),
        ),
      );
      expect(expired, 0);
      clock.advance(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('00:00'), findsOneWidget);
      expect(expired, 1);
      clock.advance(const Duration(seconds: 50));
      await tester.pump(const Duration(seconds: 1));
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

    testWidgets('uses custom textStyle when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: CountdownTimer(
              initialRemaining: const Duration(minutes: 1),
              textStyle: AppTypography.timerDisplay,
            ),
          ),
        ),
      );
      final text = tester
          .widget<Text>(find.byKey(const ValueKey('lobby-countdown-mmss')));
      expect(text.style?.fontSize, 48);
    });
  });
}
