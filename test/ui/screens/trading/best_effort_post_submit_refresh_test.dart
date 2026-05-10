import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/ui/screens/trading/game_trading_route_screen.dart';

void main() {
  group('bestEffortPostSubmitRefresh', () {
    test('runs all refresh functions when they all succeed', () async {
      final calls = <String>[];
      await bestEffortPostSubmitRefresh([
        () async {
          calls.add('orders');
        },
        () async {
          calls.add('pending');
        },
      ]);
      expect(calls, ['orders', 'pending']);
    });

    test('does NOT rethrow when one refresh throws synchronously', () async {
      // The user-reported scenario: submitCreateOrder succeeds, the order is
      // created on the server, but a follow-up refresh blows up. The route
      // callback must complete normally so the screen does not surface the
      // false-positive "Could not submit order" snackbar.
      final calls = <String>[];
      await expectLater(
        bestEffortPostSubmitRefresh([
          () async {
            calls.add('orders');
            throw StateError('orders refresh boom');
          },
          () async {
            calls.add('pending');
          },
        ]),
        completes,
      );
      expect(calls, containsAll(<String>['orders', 'pending']));
    });

    test('does NOT rethrow when one refresh throws asynchronously', () async {
      await expectLater(
        bestEffortPostSubmitRefresh([
          () async {
            await Future<void>.delayed(const Duration(milliseconds: 1));
            throw const FormatException('async parser failure');
          },
          () async {},
        ]),
        completes,
      );
    });

    test('does NOT rethrow when ALL refreshes throw', () async {
      await expectLater(
        bestEffortPostSubmitRefresh([
          () async => throw StateError('a'),
          () async => throw StateError('b'),
        ]),
        completes,
      );
    });

    test('completes immediately when given an empty list', () async {
      await expectLater(
        bestEffortPostSubmitRefresh(const []),
        completes,
      );
    });

    test('runs refreshes concurrently (Future.wait semantics)', () async {
      // If the implementation accidentally awaited each one sequentially,
      // total elapsed would be ~3 ticks. With Future.wait it should be ~1.
      final completer1 = Completer<void>();
      final completer2 = Completer<void>();
      final completer3 = Completer<void>();

      final fut = bestEffortPostSubmitRefresh([
        () => completer1.future,
        () => completer2.future,
        () => completer3.future,
      ]);

      var done = false;
      // ignore: unawaited_futures
      fut.then((_) => done = true);

      await Future<void>.delayed(Duration.zero);
      expect(done, isFalse);

      // Completing in any order should still let Future.wait progress.
      completer3.complete();
      completer1.complete();
      completer2.complete();

      await fut;
      expect(done, isTrue);
    });
  });
}
