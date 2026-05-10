import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uncertain_envelopes_2/core/theme/app_theme.dart';
import 'package:uncertain_envelopes_2/providers/view_data/home_view_data_provider.dart';
import 'package:uncertain_envelopes_2/ui/screens/home/home_mock_data.dart';
import 'package:uncertain_envelopes_2/ui/screens/home/home_screen.dart';
import 'package:uncertain_envelopes_2/ui/widgets/code_input.dart';
import 'package:uncertain_envelopes_2/ui/widgets/game_card.dart';
import 'package:uncertain_envelopes_2/ui/widgets/neon_button.dart';
import 'package:uncertain_envelopes_2/ui/widgets/status_badge.dart';

import '../../../support/home_view_data_fakes.dart';

void main() {
  group('HomeScreen (joining code strip)', () {
    testWidgets('renders title and code input', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: const HomeScreen(games: []),
        ),
      );
      expect(find.byKey(const ValueKey('home-screen')), findsOneWidget);
      expect(find.text('ENTER JOINING CODE'), findsOneWidget);
      expect(find.byType(CodeInput), findsOneWidget);
    });

    testWidgets(
      'Enter game stays tappable but only submits after five characters',
      (tester) async {
        String? submitted;
        await tester.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(),
            home: HomeScreen(
              games: const [],
              onEnterGame: (c) => submitted = c,
            ),
          ),
        );
        expect(
          tester.widget<NeonButton>(find.byType(NeonButton).first).onPressed,
          isNotNull,
        );

        await tester.tap(find.byType(NeonButton));
        await tester.pump();
        expect(submitted, isNull);

        await tester.tap(find.byKey(const ValueKey('code_cell_0')));
        await tester.pump();
        await tester.enterText(
          find.byKey(const ValueKey('code_cell_0')),
          'ABCDE',
        );
        await tester.pump();
        await tester.tap(find.byType(NeonButton));
        await tester.pump();
        expect(submitted, 'ABCDE');
      },
    );

    testWidgets('Enter game invokes onEnterGame with code', (tester) async {
      String? submitted;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: HomeScreen(games: const [], onEnterGame: (c) => submitted = c),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('code_cell_0')));
      await tester.pump();
      await tester.enterText(
        find.byKey(const ValueKey('code_cell_0')),
        'ZZZZZ',
      );
      await tester.pump();
      await tester.tap(find.byType(NeonButton));
      await tester.pump();
      expect(submitted, 'ZZZZZ');
    });
  });

  group('HomeScreen list + filters', () {
    testWidgets('Joined tab lists joined mock games', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: const HomeScreen(games: kMockHomeGames),
        ),
      );
      await tester.pump();
      expect(find.byType(GameCard), findsNWidgets(4));
      expect(find.text('Penny Stocks Derby'), findsNothing);
    });

    testWidgets('Public tab includes not-joined public game', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: const HomeScreen(games: kMockHomeGames),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('PUBLIC GAMES'));
      await tester.pump();
      expect(find.text('Penny Stocks Derby'), findsOneWidget);
      expect(find.text('Private League Alpha'), findsNothing);
    });

    testWidgets('admin-only toggle hides non-admin rows', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: const HomeScreen(games: kMockHomeGames),
        ),
      );
      await tester.pump();
      await tester.tap(find.byType(Switch));
      await tester.pump();
      expect(find.byType(GameCard), findsNWidgets(2));
      expect(find.text('Forex Masters'), findsNothing);
      expect(find.text('Crypto Basics 101'), findsOneWidget);
    });

    testWidgets('empty state when filters exclude all games', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: HomeScreen(
            games: const [
              MockHomeGame(
                id: 'x',
                title: 'Solo',
                description: 'd',
                status: GameStatusBadge.playing,
                isPublic: false,
                isJoined: false,
                isAdmin: false,
                playerInitials: [],
                maxPlayers: 8,
              ),
            ],
          ),
        ),
      );
      await tester.pump();
      expect(find.text('No games to show.'), findsOneWidget);
    });

    testWidgets('rapid tab toggles stay consistent', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: const HomeScreen(games: kMockHomeGames),
        ),
      );
      await tester.pump();
      for (var i = 0; i < 6; i++) {
        await tester.tap(find.text(i.isEven ? 'PUBLIC GAMES' : 'JOINED GAMES'));
        await tester.pump();
      }
      expect(find.text('Penny Stocks Derby'), findsNothing);
    });

    testWidgets('tapping game card invokes onOpenGame with tile', (tester) async {
      MockHomeGame? opened;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: HomeScreen(
            games: const [
              MockHomeGame(
                id: 'z9',
                title: 'Tap target',
                description: 'd',
                status: GameStatusBadge.playing,
                isPublic: true,
                isJoined: true,
                isAdmin: false,
                playerInitials: ['A'],
                maxPlayers: 6,
              ),
            ],
            onOpenGame: (g) => opened = g,
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('game-card-z9')));
      await tester.pump();
      expect(opened?.id, 'z9');
    });
  });

  group('HomeScreen provider-driven list', () {
    testWidgets('shows loading indicator while homeViewData resolves', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            homeViewDataProvider.overrideWith(HomeViewDataDelayedEmpty.new),
          ],
          child: MaterialApp(theme: buildAppTheme(), home: const HomeScreen()),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows error text when homeViewData fails', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            homeViewDataProvider.overrideWith(HomeViewDataThrowsNetwork.new),
          ],
          child: MaterialApp(theme: buildAppTheme(), home: const HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Bad state'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('home-game-list-retry')),
        findsOneWidget,
      );
    });

    testWidgets('retry refetches homeViewData after provider error', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            homeViewDataProvider.overrideWith(HomeViewDataRetryOnce.new),
          ],
          child: MaterialApp(theme: buildAppTheme(), home: const HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('home-game-list-retry')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('home-game-list-retry')));
      await tester.pumpAndSettle();

      expect(find.text('No games to show.'), findsOneWidget);
    });
  });
}
