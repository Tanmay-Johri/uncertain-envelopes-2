import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uncertain_envelopes_2/core/router/app_router.dart';
import 'package:uncertain_envelopes_2/core/router/app_router_provider.dart';
import 'package:uncertain_envelopes_2/core/theme/app_theme.dart';
import 'package:uncertain_envelopes_2/data/repositories/in_memory_auth_repository.dart';
import 'package:uncertain_envelopes_2/providers/auth_provider.dart';
import 'package:uncertain_envelopes_2/providers/view_data/home_view_data_provider.dart';
import 'package:uncertain_envelopes_2/ui/screens/home/home_mock_data.dart';
import 'package:uncertain_envelopes_2/ui/screens/auth/auth_screen.dart';
import 'package:uncertain_envelopes_2/ui/screens/auth/login_form.dart';
import 'package:uncertain_envelopes_2/ui/screens/auth/sign_up_form.dart';
import 'package:uncertain_envelopes_2/ui/screens/create_game/create_game_screen.dart';
import 'package:uncertain_envelopes_2/ui/screens/home/home_screen.dart';
import 'package:uncertain_envelopes_2/providers/view_data/lobby_view_data_provider.dart';
import 'package:uncertain_envelopes_2/ui/screens/lobby/game_lobby_screen.dart';
import 'package:uncertain_envelopes_2/ui/screens/lobby/lobby_mock_data.dart';
import 'package:uncertain_envelopes_2/ui/screens/results/game_results_screen.dart';
import 'package:uncertain_envelopes_2/ui/screens/trading/game_trading_screen.dart';
import 'package:uncertain_envelopes_2/ui/screens/trading/trading_stat_format.dart';
import 'package:uncertain_envelopes_2/ui/screens/history/game_history_screen.dart';
import 'package:uncertain_envelopes_2/ui/widgets/app_shell.dart';

List<Override> _lobbyMockOverridesForRouterTests() {
  const ids = <String>[
    'g1',
    'g1pre',
    'g2',
    'g3',
    'g4',
    'g5',
    'abc',
    '550e8400-e29b-41d4-a716-446655440000',
  ];
  return [
    for (final id in ids)
      lobbyViewDataProvider(id).overrideWith(
        (ref) => mockLobbyScenarioForGameId(id),
      ),
  ];
}

Future<GoRouter> _pumpAppWith(
  WidgetTester tester, {
  String initialLocation = AppRoutes.home,
}) async {
  final router = buildAppRouter(initialLocation: initialLocation);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        homeViewDataProvider.overrideWith((ref) async => kMockHomeGames),
        ..._lobbyMockOverridesForRouterTests(),
      ],
      child: MaterialApp.router(theme: buildAppTheme(), routerConfig: router),
    ),
  );
  // One-shot pumps: trading screen live dot repeats opacity forever, so
  // pumpAndSettle would time out waiting for animations to finish.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump();
  return router;
}

void main() {
  group('AppRoutes constants', () {
    test('static path constants are set', () {
      expect(AppRoutes.auth, '/auth');
      expect(AppRoutes.home, '/home');
      expect(AppRoutes.create, '/create');
      expect(AppRoutes.orders, '/orders');
      expect(AppRoutes.profile, '/profile');
      expect(AppRoutes.history, '/history');
    });

    test('game route helpers build the correct path', () {
      expect(AppRoutes.gameLobby('abc'), '/game/abc/lobby');
      expect(AppRoutes.gameTrading('42'), '/game/42/trading');
      expect(AppRoutes.gameResults('zzz'), '/game/zzz/results');
    });

    test('helpers handle UUID-like ids', () {
      final id = '550e8400-e29b-41d4-a716-446655440000';
      expect(AppRoutes.gameLobby(id), '/game/$id/lobby');
    });
  });

  group('shellIndexToDestination', () {
    test('maps indices to destinations', () {
      expect(shellIndexToDestination(0), AppNavDestination.home);
      expect(shellIndexToDestination(1), AppNavDestination.create);
      expect(shellIndexToDestination(2), AppNavDestination.orders);
    });

    test('throws for invalid index', () {
      expect(() => shellIndexToDestination(-1), throwsArgumentError);
      expect(() => shellIndexToDestination(3), throwsArgumentError);
    });
  });

  group('GoRouter shell routes', () {
    testWidgets('default initial location shows HomeScreen under shell',
        (tester) async {
      await _pumpAppWith(tester);
      expect(find.byType(AppShell), findsOneWidget);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('ENTER JOINING CODE'), findsOneWidget);
      // Bottom nav still labels the first branch HOME.
      expect(find.text('HOME'), findsWidgets);
    });

    testWidgets('tapping CREATE switches the shell branch',
        (tester) async {
      await _pumpAppWith(tester);
      await tester.tap(find.text('CREATE'));
      await tester.pumpAndSettle();
      expect(find.byType(CreateGameScreen), findsOneWidget);
      expect(
        find.byKey(const ValueKey('create-game-heading')),
        findsOneWidget,
      );
      expect(find.byType(AppShell), findsOneWidget);
    });

    testWidgets('tapping a home game card navigates to game lobby',
        (tester) async {
      await _pumpAppWith(tester);
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('game-card-g1')));
      await tester.pumpAndSettle();
      expect(find.byType(GameLobbyScreen), findsOneWidget);
      expect(find.text('Forex Masters'), findsWidgets);
      expect(find.text('V 8 J A J'), findsOneWidget);
    });

    testWidgets('tapping ORDERS switches to pending orders shell branch',
        (tester) async {
      await _pumpAppWith(tester);
      await tester.tap(find.text('ORDERS'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('pending-orders-scaffold')),
        findsOneWidget,
      );
      expect(find.byType(AppShell), findsOneWidget);
    });

    testWidgets('switching branches preserves shell chrome (header + nav)',
        (tester) async {
      await _pumpAppWith(tester);
      await tester.tap(find.text('CREATE'));
      await tester.pumpAndSettle();
      expect(find.text('UNCERTAIN ENVELOPES'), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });
  });

  group('GoRouter top-level routes', () {
    testWidgets('/auth renders AuthScreen outside shell', (tester) async {
      await _pumpAppWith(tester, initialLocation: AppRoutes.auth);
      expect(find.byType(AuthScreen), findsOneWidget);
      expect(find.byType(LoginForm), findsOneWidget);
      expect(find.byType(AppShell), findsNothing);
    });

    testWidgets('/auth?tab=signup deep-links to the sign-up tab',
        (tester) async {
      await _pumpAppWith(tester, initialLocation: '/auth?tab=signup');
      expect(find.byType(AuthScreen), findsOneWidget);
      expect(find.byType(SignUpForm), findsOneWidget);
    });

    testWidgets('/auth?tab=nonsense falls back to the login tab',
        (tester) async {
      await _pumpAppWith(tester, initialLocation: '/auth?tab=nonsense');
      expect(find.byType(AuthScreen), findsOneWidget);
      expect(find.byType(LoginForm), findsOneWidget);
    });

    testWidgets('/profile renders ProfileScreen outside shell',
        (tester) async {
      await _pumpAppWith(tester, initialLocation: AppRoutes.profile);
      expect(
        find.byKey(const ValueKey('profile-scaffold')),
        findsOneWidget,
      );
      expect(find.byType(AppShell), findsNothing);
    });

    testWidgets('/history renders GameHistoryScreen outside shell',
        (tester) async {
      await _pumpAppWith(tester, initialLocation: AppRoutes.history);
      expect(find.byType(GameHistoryScreen), findsOneWidget);
      expect(find.byType(AppShell), findsNothing);
    });
  });

  group('GoRouter deep link parsing', () {
    testWidgets('/game/abc/lobby parses id correctly', (tester) async {
      await _pumpAppWith(tester, initialLocation: '/game/abc/lobby');
      expect(find.byType(GameLobbyScreen), findsOneWidget);
      expect(find.text('Forex Masters'), findsWidgets);
    });

    testWidgets(
        '/game/g4/lobby shows Join Game when mock viewer is not seated',
        (tester) async {
      await _pumpAppWith(tester, initialLocation: '/game/g4/lobby');
      expect(find.byType(GameLobbyScreen), findsOneWidget);
      expect(find.byKey(const ValueKey('game-lobby-join')), findsOneWidget);
      expect(find.text('JOIN GAME'), findsOneWidget);
    });

    testWidgets('/game/:id/trading parses id and shows GameTradingScreen',
        (tester) async {
      await _pumpAppWith(tester, initialLocation: '/game/g1/trading');
      expect(find.byType(GameTradingScreen), findsOneWidget);
      expect(find.byKey(const ValueKey('game-trading-scaffold')), findsOneWidget);
      expect(find.text('Forex Masters'), findsWidgets);
    });

    testWidgets('lobby Enter Game navigates to trading for same game id',
        (tester) async {
      await _pumpAppWith(tester, initialLocation: '/game/g1/lobby');
      expect(find.byType(GameLobbyScreen), findsOneWidget);
      await tester.ensureVisible(find.byKey(const ValueKey('game-lobby-enter')));
      await tester.tap(find.byKey(const ValueKey('game-lobby-enter')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(GameTradingScreen), findsOneWidget);
      expect(find.text('Forex Masters'), findsWidgets);
    });

    testWidgets('/game/:id/results parses id correctly', (tester) async {
      await _pumpAppWith(tester, initialLocation: '/game/GAME1/results');
      expect(find.byType(GameResultsScreen), findsOneWidget);
      expect(find.textContaining('Forex Masters'), findsWidgets);
      // Unknown ids resolve to Default player-view mock (“HTML ref” envelope).
      expect(find.text(kUnsetUsdLine), findsWidgets);
    });

    testWidgets('long uuid id is accepted in deep link', (tester) async {
      const uuid = '550e8400-e29b-41d4-a716-446655440000';
      await _pumpAppWith(tester, initialLocation: '/game/$uuid/lobby');
      expect(find.byType(GameLobbyScreen), findsOneWidget);
      expect(find.text('Forex Masters'), findsWidgets);
    });
  });

  group('GoRouter unknown routes', () {
    testWidgets('unknown path renders NOT FOUND error screen',
        (tester) async {
      await _pumpAppWith(tester, initialLocation: '/nope/does-not-exist');
      expect(find.text('NOT FOUND'), findsOneWidget);
      expect(find.textContaining('/nope/does-not-exist'), findsOneWidget);
    });

    testWidgets('empty path falls back to error builder without crash',
        (tester) async {
      final router = buildAppRouter(initialLocation: '/blah');
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            theme: buildAppTheme(),
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('GoRouter programmatic navigation', () {
    testWidgets('account icon in shell navigates to /profile',
        (tester) async {
      await _pumpAppWith(tester);
      await tester.tap(find.byIcon(Icons.account_circle_outlined));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('profile-scaffold')),
        findsOneWidget,
      );
      expect(find.byType(AppShell), findsNothing);
    });

    testWidgets('router.go(AppRoutes.create) switches to CREATE branch',
        (tester) async {
      final router = await _pumpAppWith(tester);
      router.go(AppRoutes.create);
      await tester.pumpAndSettle();
      expect(find.text('CREATE'), findsWidgets);
      expect(find.byType(AppShell), findsOneWidget);
    });

    testWidgets('router.go(AppRoutes.gameLobby(id)) goes to lobby',
        (tester) async {
      final router = await _pumpAppWith(tester);
      router.go(AppRoutes.gameLobby('abc'));
      await tester.pumpAndSettle();
      expect(find.byType(GameLobbyScreen), findsOneWidget);
      expect(find.text('Forex Masters'), findsWidgets);
    });
  });

  group('appRouterProvider auth redirects', () {
    testWidgets('unauthenticated user at /home is redirected to /auth',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          homeViewDataProvider.overrideWith((ref) async => kMockHomeGames),
        ],
      );
      addTearDown(container.dispose);
      final router = container.read(appRouterProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            theme: buildAppTheme(),
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(LoginForm), findsOneWidget);
    });

    testWidgets('authenticated user at /auth is redirected to /home shell',
        (tester) async {
      final repo = InMemoryAuthRepository();
      await repo.signUp(
        email: 'routerauth@test.co',
        password: 'password12',
        username: 'routerauth',
      );
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(repo),
          appRouterInitialLocationProvider.overrideWithValue(AppRoutes.auth),
          homeViewDataProvider.overrideWith((ref) async => kMockHomeGames),
        ],
      );
      addTearDown(container.dispose);
      final router = container.read(appRouterProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            theme: buildAppTheme(),
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AppShell), findsOneWidget);
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });
}
