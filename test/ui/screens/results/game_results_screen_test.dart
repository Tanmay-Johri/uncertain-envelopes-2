import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:uncertain_envelopes_2/core/router/app_router.dart';
import 'package:uncertain_envelopes_2/core/theme/app_theme.dart';
import 'package:uncertain_envelopes_2/ui/screens/results/game_results_mock_route_host.dart';
import 'package:uncertain_envelopes_2/ui/screens/results/game_results_screen.dart';
import 'package:uncertain_envelopes_2/ui/screens/results/results_mock_data.dart';
import 'package:uncertain_envelopes_2/ui/screens/trading/trading_stat_format.dart';
import 'package:uncertain_envelopes_2/ui/widgets/neon_button.dart';

Future<void> _pump(WidgetTester tester, Widget screen) async {
  // Default ~600px-tall viewport often puts stacked hero + UPDATE under
  // offstage overlays; tall surface matches CreateGameScreen test pattern.
  tester.view.physicalSize = const Size(480, 2200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    MaterialApp.router(
      theme: buildAppTheme(),
      routerConfig: GoRouter(
        initialLocation: '/__results_test',
        routes: [
          GoRoute(
            path: '/__results_test',
            builder: (_, _) => screen,
          ),
          GoRoute(
            path: '/game/:id/lobby',
            builder: (_, state) =>
                Scaffold(body: Text('lob-${state.pathParameters['id']}')),
          ),
          GoRoute(
            path: AppRoutes.home,
            builder: (_, _) => const Scaffold(body: Text('stub-home')),
          ),
          GoRoute(
            path: AppRoutes.create,
            builder: (_, _) => const Scaffold(body: Text('stub-create')),
          ),
          GoRoute(
            path: AppRoutes.orders,
            builder: (_, _) => const Scaffold(body: Text('stub-orders')),
          ),
        ],
      ),
    ),
  );
  await tester.pump();
}

Future<void> _pumpStaleHost(WidgetTester tester, Widget host) async {
  tester.view.physicalSize = const Size(480, 2200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    MaterialApp.router(
      theme: buildAppTheme(),
      routerConfig: GoRouter(
        initialLocation: '/__stale',
        routes: [
          GoRoute(path: '/__stale', builder: (_, _) => host),
          GoRoute(
            path: '/game/:id/lobby',
            builder: (_, _) =>
                const Scaffold(body: Text('stub-lob')),
          ),
          GoRoute(
            path: AppRoutes.home,
            builder: (_, _) =>
                const Scaffold(body: Text('stub-home')),
          ),
          GoRoute(
            path: AppRoutes.create,
            builder: (_, _) =>
                const Scaffold(body: Text('stub-create')),
          ),
          GoRoute(
            path: AppRoutes.orders,
            builder: (_, _) =>
                const Scaffold(body: Text('stub-orders')),
          ),
        ],
      ),
    ),
  );
}

void main() {
  group('GameResultsScreen', () {
    testWidgets(
      'non-admin: no UPDATE, hyphen envelope until backend commits price',
      (tester) async {
      final data =
          mockGameResultsViewDataForGameId(kMockGameResultsPlayerId);
      await _pump(
        tester,
        GameResultsScreen(
          gameId: kMockGameResultsPlayerId,
          data: data,
        ),
      );
      expect(find.byKey(const ValueKey('game-results-scaffold')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('game-results-update-envelope')),
        findsNothing,
      );
      expect(find.text(kUnsetUsdLine), findsWidgets);
      expect(find.textContaining('TraderKing'), findsOneWidget);
    });

    testWidgets('admin optimistic hero tracks valid digits', (tester) async {
      final data =
          mockGameResultsViewDataForGameId(kMockGameResultsAdminId);
      var calls = 0;
      Future<void> submit(double? v) async {
        expect(v, 146);
        calls++;
      }

      await _pump(
        tester,
        GameResultsScreen(
          gameId: kMockGameResultsAdminId,
          data: data,
          onUpdateEnvelopePrice: submit,
          pollCommittedEnvelopePrice: null,
          onEndGame: ({required bool discardBecauseNoPrice}) {},
        ),
      );

      await tester.ensureVisible(find.text(kUnsetUsdLine).first);
      await tester.tap(find.text(kUnsetUsdLine).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(find.byType(TextField), '146');
      await tester.pump();
      final tf = tester.widget<TextField>(find.byType(TextField));
      expect(tf.controller?.text, '146');

      final updateBtn = find.byKey(const ValueKey('game-results-update-envelope'));
      await tester.ensureVisible(updateBtn);
      await tester.pump();
      await tester.tap(updateBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(calls, 1);
    });

    testWidgets(
      'admin clears field and blurs: shows unset line until UPDATE, not old price',
      (tester) async {
      final data = mockGameResultsViewDataForGameId(kMockGameResultsAdminId)
          .withEnvelopeUsd(200);
      await _pump(
        tester,
        GameResultsScreen(
          gameId: kMockGameResultsAdminId,
          data: data,
          onUpdateEnvelopePrice: (_) async {},
          pollCommittedEnvelopePrice: null,
          onEndGame: ({required bool discardBecauseNoPrice}) {},
        ),
      );

      await tester.ensureVisible(find.text(r'$200.00').first);
      await tester.tap(find.text(r'$200.00').first);
      await tester.pump();
      await tester.enterText(find.byType(TextField), '');
      await tester.pump();
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();

      expect(find.text(kUnsetUsdLine), findsWidgets);
      expect(find.text(r'$200.00'), findsNothing);
      final update = tester.widget<NeonButton>(
        find.byKey(const ValueKey('game-results-update-envelope')),
      );
      expect(update.onPressed, isNotNull);
    });

    testWidgets(
      'UPDATE disabled when nothing to submit (unset price + empty field)',
      (tester) async {
      final data =
          mockGameResultsViewDataForGameId(kMockGameResultsAdminId);
      await _pump(
        tester,
        GameResultsScreen(
          gameId: kMockGameResultsAdminId,
          data: data,
          onUpdateEnvelopePrice: (_) async {},
          pollCommittedEnvelopePrice: () async => data.envelopePriceUsd,
          onEndGame: ({required bool discardBecauseNoPrice}) {},
        ),
      );

      await tester.ensureVisible(find.text(kUnsetUsdLine).first);
      await tester.tap(find.text(kUnsetUsdLine).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(find.byType(TextField), '');
      await tester.pump();

      final update = tester.widget<NeonButton>(
        find.byKey(const ValueKey('game-results-update-envelope')),
      );
      expect(update.onPressed, isNull);
    });

    testWidgets('admin submits empty text to clear committed price', (
      tester,
    ) async {
      final data =
          mockGameResultsViewDataForGameId(kMockGameResultsAdminId)
              .withEnvelopeUsd(200);
      double? captured;
      await _pump(
        tester,
        GameResultsScreen(
          gameId: kMockGameResultsAdminId,
          data: data,
          pollCommittedEnvelopePrice: null,
          onUpdateEnvelopePrice: (v) async {
            captured = v;
          },
          onEndGame: ({required bool discardBecauseNoPrice}) {},
        ),
      );

      await tester.ensureVisible(find.text(r'$200.00').first);
      await tester.tap(find.text(r'$200.00').first);
      await tester.pump();
      await tester.enterText(find.byType(TextField), '');
      await tester.pump();

      await tester.ensureVisible(find.byKey(const ValueKey('game-results-update-envelope')));
      await tester.tap(find.byKey(const ValueKey('game-results-update-envelope')));
      await tester.pump();
      expect(captured, isNull);
    });

    testWidgets('end-game dialog copy when envelope unset asks discard without price',
        (tester) async {
      final data =
          mockGameResultsViewDataForGameId(kMockGameResultsAdminNoPriceId);
      await _pump(
        tester,
        GameResultsScreen(
          gameId: kMockGameResultsAdminNoPriceId,
          data: data,
          onUpdateEnvelopePrice: (_) async {},
          pollCommittedEnvelopePrice: () async => null,
          onEndGame: ({required bool discardBecauseNoPrice}) {},
        ),
      );

      await tester.ensureVisible(
        find.byKey(const ValueKey('game-results-end-game')),
      );
      await tester.tap(find.byKey(const ValueKey('game-results-end-game')));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('without entering the price'),
        findsOneWidget,
      );
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();
    });

    testWidgets('GAME ENDED freezes UPDATE and swaps end CTA', (tester) async {
      final data = mockGameResultsViewDataForGameId(kMockGameResultsAdminId)
          .withEnvelopeUsd(100)
          .withGameEnded(true);
      await _pump(
        tester,
        GameResultsScreen(
          gameId: kMockGameResultsAdminId,
          data: data,
          onUpdateEnvelopePrice: (_) async {},
          onEndGame: ({required bool discardBecauseNoPrice}) {},
        ),
      );

      final update = tester.widget<NeonButton>(
        find.byKey(const ValueKey('game-results-update-envelope')),
      );
      expect(update.onPressed, isNull);
      expect(find.byKey(const ValueKey('game-results-end-game-ended')), findsOneWidget);
    });
  });

  group('mock host reconcile revert', () {
    testWidgets('simulateStalePoll revert shows snackbar', (tester) async {
      await _pumpStaleHost(
        tester,
        const GameResultsMockRouteHost(
          gameId: kMockGameResultsAdminId,
          simulateStalePoll: true,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(kUnsetUsdLine).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(find.byType(TextField), '155');
      await tester.pump();
      final updateBtn = find.byKey(const ValueKey('game-results-update-envelope'));
      await tester.ensureVisible(updateBtn);
      await tester.pump();
      await tester.tap(updateBtn);
      await tester.pump(const Duration(milliseconds: 50));

      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.textContaining('Reverted'),
        ),
        findsOneWidget,
      );
    });
  });

  group('GoRouter — results shortcut', () {
    testWidgets('deep link resolves GameResultsScreen', (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          theme: buildAppTheme(),
          routerConfig: GoRouter(
            initialLocation: '/game/gResults/results',
            routes: [
              GoRoute(
                path: '/game/:id/results',
                builder: (_, state) => GameResultsMockRouteHost(
                  gameId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(GameResultsScreen), findsOneWidget);
      expect(find.textContaining('AdminUser'), findsWidgets);
    });

    testWidgets('back navigates to this game lobby', (tester) async {
      await _pump(
        tester,
        GameResultsScreen(
          gameId: 'z99',
          data: mockGameResultsViewDataForAdmin(),
          onEndGame: ({required bool discardBecauseNoPrice}) {},
        ),
      );
      await tester.tap(find.byTooltip('Back to lobby'));
      await tester.pumpAndSettle();
      expect(find.text('lob-z99'), findsOneWidget);
    });
  });
}
