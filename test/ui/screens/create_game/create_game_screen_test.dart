import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/core/theme/app_theme.dart';
import 'package:uncertain_envelopes_2/ui/screens/create_game/create_game_screen.dart'
    show
        CreateGameDurationLimits,
        CreateGamePlayerLimits,
        CreateGameScreen;

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
      final title = tester.widget<Text>(
        find.byKey(const ValueKey('create-game-heading')),
      );
      expect(title.data, 'CREATE GAME');
      expect(find.byKey(const ValueKey('create-game-submit')), findsOneWidget);
    });
  });

  group('CreateGameScreen (C4b name + description)', () {
    testWidgets('renders name and description fields', (tester) async {
      await _pump(tester);
      expect(find.byKey(const ValueKey('create-game-name-field')), findsOneWidget);
      final descriptionFinder =
          find.byKey(const ValueKey('create-game-description-field'));
      expect(descriptionFinder, findsOneWidget);
      final innerTextField = tester.widget<TextField>(
        find.descendant(
          of: descriptionFinder,
          matching: find.byType(TextField),
        ),
      );
      expect(
        innerTextField.decoration?.hintText,
        'OPTIONAL - MAX 256 CHARACTERS. Brief mission statement for traders...',
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
        find.byKey(const ValueKey('create-game-security-public')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('create-game-security-private')),
        findsOneWidget,
      );
      expect(find.text('Public'), findsOneWidget);
      expect(find.text('Private'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('create-game-ranked-switch')),
        findsOneWidget,
      );
      expect(find.text('SECURITY ACCESS'), findsOneWidget);
      expect(find.text('Ranked Mode'), findsOneWidget);
    });

    testWidgets('security defaults to Public', (tester) async {
      await _pump(tester);
      expect(
        find.text('Anyone can see this game under Public games.'),
        findsOneWidget,
      );
    });

    testWidgets('selecting Private updates selection', (tester) async {
      await _pump(tester);
      await tester.tap(
        find.byKey(const ValueKey('create-game-security-private')),
      );
      await tester.pump();
      expect(
        find.text('Only people with the joining code can join.'),
        findsOneWidget,
      );
    });

    testWidgets('ranked switch toggles off to on', (tester) async {
      await _pump(tester);
      final s = find.byKey(const ValueKey('create-game-ranked-switch'));
      expect(tester.widget<Switch>(s).value, isFalse);
      await tester.tap(s);
      await tester.pump();
      expect(tester.widget<Switch>(s).value, isTrue);
    });

    testWidgets('rapid ranked toggles end in consistent state', (tester) async {
      await _pump(tester);
      await tester.enterText(
        find.byKey(const ValueKey('create-game-name-field')),
        'Rapid',
      );
      final s = find.byKey(const ValueKey('create-game-ranked-switch'));
      for (var i = 0; i < 5; i++) {
        await tester.tap(s);
        await tester.pump();
      }
      expect(tester.widget<Switch>(s).value, isTrue);
      final formState = tester.state<FormState>(find.byType(Form));
      expect(formState.validate(), isTrue);
    });
  });

  group('CreateGameScreen (C4d max players)', () {
    int readMaxPlayers(WidgetTester tester) {
      final field = tester.widget<TextField>(
        find.byKey(const ValueKey('create-game-max-players-value')),
      );
      return int.parse(field.controller!.text);
    }

    Future<void> commitMaxPlayersField(WidgetTester tester) async {
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
    }

    Future<void> revealStepper(WidgetTester tester) async {
      await tester.ensureVisible(
        find.byKey(const ValueKey('create-game-max-players-plus')),
      );
      await tester.pump();
    }

    testWidgets('renders max players stepper with default', (tester) async {
      await _pump(tester);
      await revealStepper(tester);
      expect(find.text('MAXIMUM PLAYERS'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('create-game-max-players-minus')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('create-game-max-players-plus')),
        findsOneWidget,
      );
      expect(readMaxPlayers(tester), CreateGamePlayerLimits.defaultMaxPlayers);
    });

    testWidgets('plus increments until cap', (tester) async {
      await _pump(tester);
      await revealStepper(tester);
      final plus = find.byKey(const ValueKey('create-game-max-players-plus'));
      for (var i = CreateGamePlayerLimits.defaultMaxPlayers;
          i < CreateGamePlayerLimits.max;
          i++) {
        await tester.tap(plus);
        await tester.pump();
        expect(readMaxPlayers(tester), i + 1);
      }
      expect(readMaxPlayers(tester), CreateGamePlayerLimits.max);
      await tester.tap(plus);
      await tester.pump();
      expect(readMaxPlayers(tester), CreateGamePlayerLimits.max);
    });

    testWidgets('minus decrements until floor', (tester) async {
      await _pump(tester);
      await revealStepper(tester);
      final minus = find.byKey(const ValueKey('create-game-max-players-minus'));
      for (var i = CreateGamePlayerLimits.defaultMaxPlayers;
          i > CreateGamePlayerLimits.min;
          i--) {
        await tester.tap(minus);
        await tester.pump();
        expect(readMaxPlayers(tester), i - 1);
      }
      expect(readMaxPlayers(tester), CreateGamePlayerLimits.min);
      await tester.tap(minus);
      await tester.pump();
      expect(readMaxPlayers(tester), CreateGamePlayerLimits.min);
    });

    testWidgets('rapid plus taps from 120 reach 128 then clamp', (tester) async {
      await _pump(tester);
      await revealStepper(tester);
      final plus = find.byKey(const ValueKey('create-game-max-players-plus'));
      for (var i = CreateGamePlayerLimits.defaultMaxPlayers;
          i < 120;
          i++) {
        await tester.tap(plus);
        await tester.pump();
      }
      expect(readMaxPlayers(tester), 120);
      for (var k = 0; k < 20; k++) {
        await tester.tap(plus);
        await tester.pump();
      }
      expect(readMaxPlayers(tester), CreateGamePlayerLimits.max);
    });

    testWidgets('max players field caps input at 128', (tester) async {
      await _pump(tester);
      await revealStepper(tester);
      final field = find.byKey(const ValueKey('create-game-max-players-value'));
      await tester.enterText(field, '999.2');
      await commitMaxPlayersField(tester);
      expect(readMaxPlayers(tester), 128);
    });

    testWidgets('max players field floors decimals and low bound', (tester) async {
      await _pump(tester);
      await revealStepper(tester);
      final field = find.byKey(const ValueKey('create-game-max-players-value'));
      await tester.enterText(field, '31.9');
      await commitMaxPlayersField(tester);
      expect(readMaxPlayers(tester), 31);

      await tester.enterText(field, '0.8');
      await commitMaxPlayersField(tester);
      expect(readMaxPlayers(tester), 1);
    });
  });

  group('CreateGameScreen (C4e end condition + duration)', () {
    int readDurationMinutes(WidgetTester tester) {
      final field = tester.widget<TextField>(
        find.byKey(const ValueKey('create-game-duration-value')),
      );
      return int.parse(field.controller!.text);
    }

    Future<void> commitDurationField(WidgetTester tester) async {
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
    }

    Future<void> revealEndSection(WidgetTester tester) async {
      await tester.ensureVisible(
        find.byKey(const ValueKey('create-game-end-dropdown')),
      );
      await tester.pump();
    }

    Future<void> selectEndCondition(
      WidgetTester tester,
      String label,
    ) async {
      await tester.tap(
        find.byKey(const ValueKey('create-game-end-dropdown')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
    }

    Future<void> revealDurationStepper(WidgetTester tester) async {
      await tester.ensureVisible(
        find.byKey(const ValueKey('create-game-duration-plus')),
      );
      await tester.pump();
    }

    testWidgets('Timed default shows duration stepper', (tester) async {
      await _pump(tester);
      await revealEndSection(tester);
      expect(find.text('END CONDITION'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('create-game-end-dropdown')),
        findsOneWidget,
      );
      expect(find.text('Timed'), findsWidgets);
      await revealDurationStepper(tester);
      expect(
        find.byKey(const ValueKey('create-game-duration-value')),
        findsOneWidget,
      );
      expect(
        readDurationMinutes(tester),
        CreateGameDurationLimits.defaultMinutes,
      );
    });

    testWidgets(
        'Endless hides duration; Timed restores preserved minutes',
        (tester) async {
      await _pump(tester);
      await revealEndSection(tester);
      await revealDurationStepper(tester);
      final plus = find.byKey(const ValueKey('create-game-duration-plus'));
      for (var i = 0; i < 15; i++) {
        await tester.tap(plus);
        await tester.pump();
      }
      expect(readDurationMinutes(tester), 45);

      await selectEndCondition(tester, 'Endless');
      expect(
        find.byKey(const ValueKey('create-game-duration-value')),
        findsNothing,
      );

      await selectEndCondition(tester, 'Timed');
      await revealDurationStepper(tester);
      expect(readDurationMinutes(tester), 45);
    });

    testWidgets('duration plus and minus respect bounds', (tester) async {
      await _pump(tester);
      await revealEndSection(tester);
      await revealDurationStepper(tester);
      final plus = find.byKey(const ValueKey('create-game-duration-plus'));
      final minus = find.byKey(const ValueKey('create-game-duration-minus'));

      while (readDurationMinutes(tester) < CreateGameDurationLimits.maxMinutes) {
        await tester.tap(plus);
        await tester.pump();
      }
      expect(readDurationMinutes(tester), CreateGameDurationLimits.maxMinutes);
      await tester.tap(plus);
      await tester.pump();
      expect(readDurationMinutes(tester), CreateGameDurationLimits.maxMinutes);

      while (readDurationMinutes(tester) > CreateGameDurationLimits.minMinutes) {
        await tester.tap(minus);
        await tester.pump();
      }
      expect(readDurationMinutes(tester), CreateGameDurationLimits.minMinutes);
      await tester.tap(minus);
      await tester.pump();
      expect(readDurationMinutes(tester), CreateGameDurationLimits.minMinutes);
    });

    testWidgets('rapid duration plus from 595 clamps at 600', (tester) async {
      await _pump(tester);
      await revealEndSection(tester);
      await revealDurationStepper(tester);
      final plus = find.byKey(const ValueKey('create-game-duration-plus'));
      for (var m = CreateGameDurationLimits.defaultMinutes; m < 595; m++) {
        await tester.tap(plus);
        await tester.pump();
      }
      expect(readDurationMinutes(tester), 595);
      for (var k = 0; k < 20; k++) {
        await tester.tap(plus);
        await tester.pump();
      }
      expect(readDurationMinutes(tester), CreateGameDurationLimits.maxMinutes);
    });

    testWidgets('duration field caps high decimals at 600', (tester) async {
      await _pump(tester);
      await revealEndSection(tester);
      await revealDurationStepper(tester);
      final field = find.byKey(const ValueKey('create-game-duration-value'));
      await tester.enterText(field, '999.7');
      await commitDurationField(tester);
      expect(readDurationMinutes(tester), 600);
    });

    testWidgets('duration field floors decimals and respects low bound',
        (tester) async {
      await _pump(tester);
      await revealEndSection(tester);
      await revealDurationStepper(tester);
      final field = find.byKey(const ValueKey('create-game-duration-value'));
      await tester.enterText(field, '45.9');
      await commitDurationField(tester);
      expect(readDurationMinutes(tester), 45);

      await tester.enterText(field, '0.3');
      await commitDurationField(tester);
      expect(readDurationMinutes(tester), 1);
    });

    testWidgets('duration field treats garbage as 1', (tester) async {
      await _pump(tester);
      await revealEndSection(tester);
      await revealDurationStepper(tester);
      final field = find.byKey(const ValueKey('create-game-duration-value'));
      await tester.enterText(field, 'abc');
      await commitDurationField(tester);
      expect(readDurationMinutes(tester), 1);
    });
  });
}
