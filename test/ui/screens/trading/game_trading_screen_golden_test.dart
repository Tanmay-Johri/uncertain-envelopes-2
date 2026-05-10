import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/core/theme/app_theme.dart';
import 'package:uncertain_envelopes_2/providers/view_data/trading_view_data_provider.dart';
import 'package:uncertain_envelopes_2/ui/screens/trading/game_trading_screen.dart';
import 'package:uncertain_envelopes_2/ui/screens/trading/trading_mock_data.dart';

import '../../../support/golden_trading_minimal_seed.dart'
    show GoldenTradingMinimalHarness, GoldenTradingMinimalSeed;

/// Phase 2 plan §2B.5: pixel contract via [matchesGoldenFile].
///
/// Full `g1` mock mixes 11 hand-authored chart points with only four
/// executions in the log — [tradingViewDataProvider] cannot reproduce that
/// without a separate chart feed, so **mock-vs-adapter parity** is asserted
/// on [GoldenTradingMinimalSeed] instead. The `g1` golden is a **regression
/// baseline** for the rich mock layout only.
void main() {
  const goldenRoot = ValueKey<String>('golden-trading-root');

  group('GameTradingScreen goldens', () {
    testWidgets(
      'minimal fixture: mock view-data and adapter output match same golden',
      (tester) async {
        final binding = TestWidgetsFlutterBinding.ensureInitialized();
        addTearDown(() async {
          await binding.setSurfaceSize(null);
        });
        await binding.setSurfaceSize(const Size(390, 844));

        Future<void> expectTradingGolden() async {
          await expectLater(
            find.byKey(goldenRoot),
            matchesGoldenFile('goldens/trading_minimal_mock_vs_adapter.png'),
          );
        }

        await tester.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(),
            home: RepaintBoundary(
              key: goldenRoot,
              child: GameTradingScreen(
                data: GoldenTradingMinimalSeed.expectedViewData,
                gameId: GoldenTradingMinimalSeed.gameId,
              ),
            ),
          ),
        );
        await tester.pump();
        await expectTradingGolden();

        final harness = GoldenTradingMinimalHarness.create();
        addTearDown(harness.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: harness.container,
            child: MaterialApp(
              theme: buildAppTheme(),
              home: RepaintBoundary(
                key: goldenRoot,
                child: Consumer(
                  builder: (context, ref, _) {
                    final async = ref.watch(
                      tradingViewDataProvider(GoldenTradingMinimalSeed.gameId),
                    );
                    return switch (async) {
                      AsyncData(:final value) => GameTradingScreen(
                          data: value,
                          gameId: GoldenTradingMinimalSeed.gameId,
                        ),
                      AsyncLoading() => const Center(
                          child: CircularProgressIndicator(),
                        ),
                      AsyncError(:final error) => Text(
                          'error $error',
                          textDirection: TextDirection.ltr,
                        ),
                      _ => const SizedBox.shrink(),
                    };
                  },
                ),
              ),
            ),
          ),
        );
        for (var i = 0; i < 40; i++) {
          await tester.pump(const Duration(milliseconds: 16));
          if (find.byKey(const ValueKey('game-trading-scaffold')).evaluate().isNotEmpty) {
            break;
          }
        }
        expect(find.byKey(const ValueKey('game-trading-scaffold')), findsOneWidget);
        await expectTradingGolden();
      },
    );

    testWidgets('g1 mock dashboard golden (regression baseline)', (tester) async {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      addTearDown(() async {
        await binding.setSurfaceSize(null);
      });
      await binding.setSurfaceSize(const Size(390, 844));

      final scenario = mockTradingScenarioForGameId('g1');
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: RepaintBoundary(
            key: goldenRoot,
            child: GameTradingScreen(
              data: scenario.data,
              gameId: 'g1',
            ),
          ),
        ),
      );
      await tester.pump();
      await expectLater(
        find.byKey(goldenRoot),
        matchesGoldenFile('goldens/trading_dashboard_g1_mock.png'),
      );
    });
  });
}
