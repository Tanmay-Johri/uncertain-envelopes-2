import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/core/theme/app_theme.dart';
import 'package:uncertain_envelopes_2/ui/screens/create_game/create_game_screen.dart';

void main() {
  group('CreateGameScreen (C4a scaffold)', () {
    testWidgets('renders scaffold keys and heading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: const CreateGameScreen(),
        ),
      );
      expect(find.byKey(const ValueKey('create-game-screen')), findsOneWidget);
      expect(find.byKey(const ValueKey('create-game-heading')), findsOneWidget);
      expect(find.text('CREATE GAME'), findsOneWidget);
    });
  });
}
