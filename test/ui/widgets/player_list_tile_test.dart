import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/core/theme/app_theme.dart';
import 'package:uncertain_envelopes_2/ui/widgets/player_list_tile.dart';

void main() {
  group('PlayerListTile', () {
    testWidgets('renders name, initials chip, and JOINED', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: const Scaffold(
            body: PlayerListTile(
              playerId: 'p1',
              initials: 'js',
              displayName: 'JohnSmith',
            ),
          ),
        ),
      );
      expect(find.text('JohnSmith'), findsOneWidget);
      expect(find.text('JS'), findsOneWidget);
      expect(find.text('JOINED'), findsOneWidget);
    });

    testWidgets('shows crown when isGameAdmin', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: const Scaffold(
            body: PlayerListTile(
              playerId: 'a',
              initials: 'ad',
              displayName: 'AdminUser',
              isGameAdmin: true,
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.workspace_premium), findsOneWidget);
    });

    testWidgets('kick control when showKickButton', (tester) async {
      var kicks = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: PlayerListTile(
              playerId: 'other',
              initials: 'x',
              displayName: 'Target',
              showKickButton: true,
              onKick: () => kicks++,
            ),
          ),
        ),
      );
      expect(find.byKey(const ValueKey('lobby-kick-other')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('lobby-kick-other')));
      await tester.pump();
      expect(kicks, 1);
    });

    testWidgets('rapid kick taps invoke callback each time', (tester) async {
      var kicks = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: PlayerListTile(
              playerId: 'x',
              initials: 'y',
              displayName: 'Zed',
              showKickButton: true,
              onKick: () => kicks++,
            ),
          ),
        ),
      );
      final kick = find.byKey(const ValueKey('lobby-kick-x'));
      for (var i = 0; i < 4; i++) {
        await tester.tap(kick);
        await tester.pump();
      }
      expect(kicks, 4);
    });

    testWidgets('truncates long display name with ellipsis', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: const Scaffold(
            body: SizedBox(
              width: 200,
              child: PlayerListTile(
                playerId: 'p',
                initials: 'ab',
                displayName: 'VeryLongUsernameThatShouldEllipsizeInTheRow',
              ),
            ),
          ),
        ),
      );
      expect(find.textContaining('VeryLong'), findsOneWidget);
    });
  });
}
