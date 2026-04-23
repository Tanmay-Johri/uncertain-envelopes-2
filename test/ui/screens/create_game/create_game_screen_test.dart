import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/core/theme/app_theme.dart';
import 'package:uncertain_envelopes_2/ui/screens/create_game/create_game_screen.dart'
    show CreateGameScreen, CreateGameSecurity;

Future<void> _pump(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(),
      home: const CreateGameScreen(),
    ),
  );
}

void main() {
  group('CreateGameScreen (C4a scaffold)', () {
    testWidgets('renders scaffold keys and heading', (tester) async {
      await _pump(tester);
      expect(find.byKey(const ValueKey('create-game-screen')), findsOneWidget);
      expect(find.byKey(const ValueKey('create-game-heading')), findsOneWidget);
      expect(find.text('CREATE GAME'), findsOneWidget);
    });
  });

  group('CreateGameScreen (C4b name + description)', () {
    testWidgets('renders name and description fields', (tester) async {
      await _pump(tester);
      expect(find.byKey(const ValueKey('create-game-name-field')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('create-game-description-field')),
        findsOneWidget,
      );
    });

    testWidgets('empty trimmed name fails validation', (tester) async {
      await _pump(tester);
      await tester.enterText(
        find.byKey(const ValueKey('create-game-name-field')),
        '   ',
      );
      final formState = tester.state<FormState>(find.byType(Form));
      expect(formState.validate(), isFalse);
      await tester.pump();
      expect(find.text('Required'), findsOneWidget);
    });

    testWidgets('name longer than 32 characters fails', (tester) async {
      await _pump(tester);
      await tester.enterText(
        find.byKey(const ValueKey('create-game-name-field')),
        'A' * 33,
      );
      final formState = tester.state<FormState>(find.byType(Form));
      expect(formState.validate(), isFalse);
      await tester.pump();
      expect(find.text('Max 32 characters'), findsOneWidget);
    });

    testWidgets('exactly 32 character name is valid', (tester) async {
      await _pump(tester);
      await tester.enterText(
        find.byKey(const ValueKey('create-game-name-field')),
        'A' * 32,
      );
      final formState = tester.state<FormState>(find.byType(Form));
      expect(formState.validate(), isTrue);
      await tester.pump();
      expect(find.text('Required'), findsNothing);
      expect(find.text('Max 32 characters'), findsNothing);
    });

    testWidgets('description longer than 256 characters fails', (tester) async {
      await _pump(tester);
      await tester.enterText(
        find.byKey(const ValueKey('create-game-name-field')),
        'ValidName',
      );
      await tester.enterText(
        find.byKey(const ValueKey('create-game-description-field')),
        'B' * 257,
      );
      final formState = tester.state<FormState>(find.byType(Form));
      expect(formState.validate(), isFalse);
      await tester.pump();
      expect(find.text('Max 256 characters'), findsOneWidget);
    });

    testWidgets('empty description is valid with non-empty name', (tester) async {
      await _pump(tester);
      await tester.enterText(
        find.byKey(const ValueKey('create-game-name-field')),
        'My Game',
      );
      final formState = tester.state<FormState>(find.byType(Form));
      expect(formState.validate(), isTrue);
    });

    testWidgets('256 character description is valid', (tester) async {
      await _pump(tester);
      await tester.enterText(
        find.byKey(const ValueKey('create-game-name-field')),
        'G',
      );
      await tester.enterText(
        find.byKey(const ValueKey('create-game-description-field')),
        'C' * 256,
      );
      final formState = tester.state<FormState>(find.byType(Form));
      expect(formState.validate(), isTrue);
    });
  });

  group('CreateGameScreen (C4c security + ranked)', () {
    testWidgets('renders security control and ranked switch', (tester) async {
      await _pump(tester);
      expect(
        find.byKey(const ValueKey('create-game-security-segmented')),
        findsOneWidget,
      );
      expect(find.text('Public'), findsOneWidget);
      expect(find.text('Private'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('create-game-ranked-tile')),
        findsOneWidget,
      );
      expect(find.text('SECURITY'), findsOneWidget);
      expect(find.text('RANKED'), findsOneWidget);
    });

    testWidgets('security defaults to Public', (tester) async {
      await _pump(tester);
      final seg = tester.widget<SegmentedButton<CreateGameSecurity>>(
        find.byKey(const ValueKey('create-game-security-segmented')),
      );
      expect(seg.selected, {CreateGameSecurity.public});
    });

    testWidgets('selecting Private updates selection', (tester) async {
      await _pump(tester);
      await tester.tap(find.text('Private'));
      await tester.pump();
      final seg = tester.widget<SegmentedButton<CreateGameSecurity>>(
        find.byKey(const ValueKey('create-game-security-segmented')),
      );
      expect(seg.selected, {CreateGameSecurity.private});
    });

    testWidgets('ranked switch toggles off to on', (tester) async {
      await _pump(tester);
      final tileFinder = find.byKey(const ValueKey('create-game-ranked-tile'));
      expect(tester.widget<SwitchListTile>(tileFinder).value, isFalse);
      await tester.tap(tileFinder);
      await tester.pump();
      expect(tester.widget<SwitchListTile>(tileFinder).value, isTrue);
    });

    testWidgets('rapid ranked toggles end in consistent state', (tester) async {
      await _pump(tester);
      await tester.enterText(
        find.byKey(const ValueKey('create-game-name-field')),
        'Rapid',
      );
      final tileFinder = find.byKey(const ValueKey('create-game-ranked-tile'));
      for (var i = 0; i < 5; i++) {
        await tester.tap(tileFinder);
        await tester.pump();
      }
      expect(tester.widget<SwitchListTile>(tileFinder).value, isTrue);
      final formState = tester.state<FormState>(find.byType(Form));
      expect(formState.validate(), isTrue);
    });
  });
}
