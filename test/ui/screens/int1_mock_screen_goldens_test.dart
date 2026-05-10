import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:uncertain_envelopes_2/ui/screens/auth/auth_screen.dart';
import 'package:uncertain_envelopes_2/ui/screens/create_game/create_game_screen.dart';
import 'package:uncertain_envelopes_2/core/theme/app_theme.dart';
import 'package:uncertain_envelopes_2/ui/screens/history/game_history_mock_data.dart';
import 'package:uncertain_envelopes_2/ui/screens/history/game_history_screen.dart';
import 'package:uncertain_envelopes_2/ui/screens/home/home_mock_data.dart';
import 'package:uncertain_envelopes_2/ui/screens/home/home_screen.dart';
import 'package:uncertain_envelopes_2/ui/screens/lobby/game_lobby_screen.dart';
import 'package:uncertain_envelopes_2/ui/screens/lobby/lobby_mock_data.dart';
import 'package:uncertain_envelopes_2/ui/screens/orders/pending_orders_screen.dart';
import 'package:uncertain_envelopes_2/ui/screens/profile/profile_mock_data.dart';
import 'package:uncertain_envelopes_2/ui/screens/profile/profile_screen.dart';
import 'package:uncertain_envelopes_2/ui/screens/results/game_results_screen.dart';
import 'package:uncertain_envelopes_2/ui/screens/results/results_mock_data.dart';
import 'package:uncertain_envelopes_2/ui/widgets/auth_tab_switcher.dart';

import '../../support/golden_app_shell.dart';

void main() {
  const rootKey = ValueKey<String>('int1-golden-root');

  Future<void> pumpGolden(
    WidgetTester tester, {
    required Size surface,
    required Widget child,
    bool wrapRouter = false,
  }) async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    addTearDown(() async {
      await binding.setSurfaceSize(null);
    });
    await binding.setSurfaceSize(surface);

    final wrapped = wrapRouter
        ? goldenMaterialAppRouter(child: child)
        : MaterialApp(theme: buildAppTheme(), home: child);

    await tester.pumpWidget(RepaintBoundary(key: rootKey, child: wrapped));
    await tester.pump();
  }

  group('INT1 mock screen goldens (Phase 2 plan §2B recipe)', () {
    testWidgets('auth login tab', (tester) async {
      await pumpGolden(
        tester,
        surface: const Size(390, 844),
        child: const AuthScreen(initialTab: AuthTab.logIn),
      );
      await expectLater(
        find.byKey(rootKey),
        matchesGoldenFile('goldens/auth_login_mock.png'),
      );
    });

    testWidgets('home with kMockHomeGames', (tester) async {
      await pumpGolden(
        tester,
        surface: const Size(390, 844),
        wrapRouter: true,
        child: HomeScreen(games: kMockHomeGames),
      );
      await expectLater(
        find.byKey(rootKey),
        matchesGoldenFile('goldens/home_mock.png'),
      );
    });

    testWidgets('create game form', (tester) async {
      await pumpGolden(
        tester,
        surface: const Size(390, 844),
        child: ProviderScope(
          child: MaterialApp(
            theme: buildAppTheme(),
            home: CreateGameScreen(onSubmit: (_) async {}),
          ),
        ),
      );
      await expectLater(
        find.byKey(rootKey),
        matchesGoldenFile('goldens/create_game_mock.png'),
      );
    });

    testWidgets('lobby g2 admin pre-start', (tester) async {
      final scenario = mockLobbyScenarioForGameId('g2');
      await pumpGolden(
        tester,
        surface: const Size(390, 844),
        wrapRouter: true,
        child: GameLobbyScreen(
          data: scenario.data,
          phase: scenario.phase,
          currentPlayerId: scenario.currentPlayerId,
          isViewerAdmin: scenario.isViewerAdmin,
        ),
      );
      await expectLater(
        find.byKey(rootKey),
        matchesGoldenFile('goldens/lobby_mock.png'),
      );
    });

    testWidgets('results admin trading-ended', (tester) async {
      await pumpGolden(
        tester,
        surface: const Size(390, 2200),
        wrapRouter: true,
        child: GameResultsScreen(
          gameId: kMockGameResultsAdminId,
          data: mockGameResultsViewDataForAdmin(),
        ),
      );
      await expectLater(
        find.byKey(rootKey),
        matchesGoldenFile('goldens/results_admin_mock.png'),
      );
    });

    testWidgets('profile default mock', (tester) async {
      await pumpGolden(
        tester,
        surface: const Size(390, 844),
        wrapRouter: true,
        child: ProfileScreen(data: mockProfileViewDataDefault()),
      );
      await expectLater(
        find.byKey(rootKey),
        matchesGoldenFile('goldens/profile_mock.png'),
      );
    });

    testWidgets('pending orders mock list', (tester) async {
      await pumpGolden(
        tester,
        surface: const Size(390, 1200),
        child: const PendingOrdersScreen(),
      );
      await expectLater(
        find.byKey(rootKey),
        matchesGoldenFile('goldens/pending_orders_mock.png'),
      );
    });

    testWidgets('game history mock list', (tester) async {
      await pumpGolden(
        tester,
        surface: const Size(390, 1400),
        wrapRouter: true,
        child: GameHistoryScreen(entries: kMockGameHistory()),
      );
      await expectLater(
        find.byKey(rootKey),
        matchesGoldenFile('goldens/game_history_mock.png'),
      );
    });
  });
}
