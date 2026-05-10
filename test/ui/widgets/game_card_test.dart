import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/core/theme/app_theme.dart';
import 'package:uncertain_envelopes_2/ui/widgets/game_card.dart';
import 'package:uncertain_envelopes_2/ui/widgets/status_badge.dart';

void main() {
  group('GameCard', () {
    testWidgets('renders title, description, badge, and open control',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: const Scaffold(
            body: GameCard(
              title: 'Forex Masters',
              description: 'A long description that should ellipsize in one line',
              status: GameStatusBadge.playing,
              playerCount: 2,
              maxPlayers: 12,
            ),
          ),
        ),
      );
      expect(find.text('Forex Masters'), findsOneWidget);
      expect(find.textContaining('A long description'), findsOneWidget);
      expect(find.text('PLAYING'), findsOneWidget);
      expect(find.text('2/12 players'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    });

    testWidgets('tap anywhere on card invokes onOpen', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: GameCard(
              title: 'T',
              description: 'D',
              status: GameStatusBadge.joined,
              playerCount: 1,
              maxPlayers: 8,
              onOpen: () => taps++,
            ),
          ),
        ),
      );
      await tester.tap(find.text('T'));
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('shows player count versus capacity', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: const Scaffold(
            body: GameCard(
              title: 'Big',
              description: 'Many players',
              status: GameStatusBadge.playing,
              playerCount: 7,
              maxPlayers: 12,
            ),
          ),
        ),
      );
      expect(find.text('7/12 players'), findsOneWidget);
    });

    testWidgets('zero players shows 0/N', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: const Scaffold(
            body: GameCard(
              title: 'Solo',
              description: 'No one here',
              status: GameStatusBadge.joined,
              playerCount: 0,
              maxPlayers: 12,
            ),
          ),
        ),
      );
      expect(find.text('0/12 players'), findsOneWidget);
    });

    testWidgets('rapid taps on card surface all invoke onOpen', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: GameCard(
              title: 'T',
              description: 'D',
              status: GameStatusBadge.playing,
              playerCount: 1,
              maxPlayers: 4,
              onOpen: () => taps++,
            ),
          ),
        ),
      );
      final target = find.text('D');
      for (var i = 0; i < 5; i++) {
        await tester.tap(target);
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(taps, 5);
    });
  });
}
