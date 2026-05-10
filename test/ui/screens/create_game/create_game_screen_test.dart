import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uncertain_envelopes_2/core/theme/app_theme.dart';
import 'package:uncertain_envelopes_2/data/enums/end_condition.dart';
import 'package:uncertain_envelopes_2/data/enums/game_security.dart';
import 'package:uncertain_envelopes_2/data/enums/is_ranked.dart';
import 'package:uncertain_envelopes_2/data/models/player.dart';
import 'package:uncertain_envelopes_2/data/repositories/game_repository.dart';
import 'package:uncertain_envelopes_2/data/repositories/in_memory_auth_repository.dart';
import 'package:uncertain_envelopes_2/data/repositories/in_memory_command_repository.dart';
import 'package:uncertain_envelopes_2/data/repositories/in_memory_game_repository.dart';
import 'package:uncertain_envelopes_2/providers/auth_provider.dart';
import 'package:uncertain_envelopes_2/providers/game_repository_provider.dart';
import 'package:uncertain_envelopes_2/ui/screens/create_game/create_game_screen.dart'
    show
        CreateGameDraft,
        CreateGameDurationLimits,
        CreateGameEndCondition,
        CreateGamePlayerLimits,
        CreateGameScreen,
        CreateGameSecurity;

Widget _providerWrappedCreateGameApp(Widget home) {
  final auth = InMemoryAuthRepository();
  auth.setSessionPlayerForTest(
    Player(
      playerId: 'test-player',
      username: 'tester',
      createdAt: DateTime.utc(2026, 1, 1),
      email: 't@test.com',
    ),
  );
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(auth),
      gameRepositoryProvider.overrideWithValue(
        InMemoryGameRepository(
          commandRepository: InMemoryCommandRepository(),
        ),
      ),
    ],
    child: MaterialApp(
      theme: buildAppTheme(),
      home: home,
    ),
  );
}

Future<void> _pump(WidgetTester tester) async {
  await tester.pumpWidget(
    _providerWrappedCreateGameApp(const CreateGameScreen()),
  );
  await tester.pump();
}

/// Same auth/session as [_providerWrappedCreateGameApp] but injects a custom
/// [GameRepository] (e.g. simulated create failures).
Future<void> _pumpCreateGameWithGameRepo(
  WidgetTester tester,
  GameRepository gameRepo,
) async {
  final auth = InMemoryAuthRepository();
  auth.setSessionPlayerForTest(
    Player(
      playerId: 'test-player',
      username: 'tester',
      createdAt: DateTime.utc(2026, 1, 1),
      email: 't@test.com',
    ),
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        gameRepositoryProvider.overrideWithValue(gameRepo),
      ],
      child: MaterialApp(
        theme: buildAppTheme(),
        home: const CreateGameScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  final container = ProviderScope.containerOf(
    tester.element(find.byType(CreateGameScreen)),
  );
  await container.read(authControllerProvider.future);
}

class _ThrowOnCreateGameRepository extends InMemoryGameRepository {
  _ThrowOnCreateGameRepository()
      : super(commandRepository: InMemoryCommandRepository());

  @override
  Future<String> createGameAndReturnGameId({
    required String adminPlayerId,
    required String gameName,
    String? gameDescription,
    required GameSecurity gameSecurity,
    required IsRanked isRanked,
    required int gameMaxPlayers,
    required EndCondition endCondition,
    int? totalDecidedDurationSeconds,
  }) async {
    throw const CreateGameCommandFailedException('Simulated create failure');
  }
}

/// Tall surface so CREATE GAME is in the hit-testable viewport (default ~600px
/// tall tests put the button under overlays that absorb taps).
void _bindTallSurfaceForSubmit(WidgetTester tester) {
  tester.view.physicalSize = const Size(480, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
}

Future<void> _tapCreateGameSubmit(WidgetTester tester) async {
  final submit = find.byKey(const ValueKey('create-game-submit'));
  await tester.ensureVisible(submit);
  await tester.pump();
  await tester.tap(submit);
  await tester.pumpAndSettle();
}

Future<void> _selectEndCondition(WidgetTester tester, String label) async {
  final drop = find.byKey(const ValueKey('create-game-end-dropdown'));
  await tester.ensureVisible(drop);
  await tester.pump();
  await tester.tap(drop);
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
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
        'OPTIONAL - MAX 256 CHARACTERS\n(Brief mission statement for traders)',
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

    testWidgets('security defaults to Private', (tester) async {
      await _pump(tester);
      expect(
        find.text('Only people with the joining code can join.'),
        findsOneWidget,
      );
    });

    testWidgets('selecting Public updates selection', (tester) async {
      await _pump(tester);
      await tester.tap(
        find.byKey(const ValueKey('create-game-security-public')),
      );
      await tester.pump();
      expect(
        find.text('Anyone can see this game under Public games.'),
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
      await _selectEndCondition(tester, label);
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

  group('CreateGameScreen (C4f submit)', () {
    testWidgets('submit does not call onSubmit when name empty', (tester) async {
      _bindTallSurfaceForSubmit(tester);
      var calls = 0;
      await tester.pumpWidget(
        _providerWrappedCreateGameApp(
          CreateGameScreen(
            onSubmit: (_) async {
              calls++;
            },
          ),
        ),
      );
      await _tapCreateGameSubmit(tester);
      expect(calls, 0);
      expect(find.text('Required'), findsOneWidget);
    });

    testWidgets('submit does not call onSubmit when name too long',
        (tester) async {
      _bindTallSurfaceForSubmit(tester);
      var calls = 0;
      await tester.pumpWidget(
        _providerWrappedCreateGameApp(
          CreateGameScreen(
            onSubmit: (_) async {
              calls++;
            },
          ),
        ),
      );
      await tester.enterText(
        find.byKey(const ValueKey('create-game-name-field')),
        'A' * 33,
      );
      await _tapCreateGameSubmit(tester);
      expect(calls, 0);
      expect(find.text('Max 32 characters'), findsOneWidget);
    });

    testWidgets('submit with valid form emits trimmed draft and toJson',
        (tester) async {
      _bindTallSurfaceForSubmit(tester);
      CreateGameDraft? last;
      await tester.pumpWidget(
        _providerWrappedCreateGameApp(
          CreateGameScreen(
            onSubmit: (d) async {
              last = d;
            },
          ),
        ),
      );
      await tester.enterText(
        find.byKey(const ValueKey('create-game-name-field')),
        '  Nova Session  ',
      );
      await tester.enterText(
        find.byKey(const ValueKey('create-game-description-field')),
        '  Brief  ',
      );
      await _tapCreateGameSubmit(tester);
      expect(last, isNotNull);
      expect(
        last,
        const CreateGameDraft(
          name: 'Nova Session',
          description: 'Brief',
          security: CreateGameSecurity.private,
          ranked: false,
          maxPlayers: 16,
          endCondition: CreateGameEndCondition.timed,
          durationMinutes: 30,
        ),
      );
      expect(last!.toJson()['endCondition'], 'timed');
      expect(last!.toJson()['durationMinutes'], 30);
    });

    testWidgets('submit uses null duration when Endless', (tester) async {
      _bindTallSurfaceForSubmit(tester);
      CreateGameDraft? last;
      await tester.pumpWidget(
        _providerWrappedCreateGameApp(
          CreateGameScreen(
            onSubmit: (d) async {
              last = d;
            },
          ),
        ),
      );
      await tester.enterText(
        find.byKey(const ValueKey('create-game-name-field')),
        'E2E',
      );
      await _selectEndCondition(tester, 'Endless');
      await _tapCreateGameSubmit(tester);
      expect(last, isNotNull);
      expect(last!.endCondition, CreateGameEndCondition.endless);
      expect(last!.durationMinutes, isNull);
      expect(last!.toJson()['durationMinutes'], isNull);
    });

    testWidgets('rapid duplicate submits each invoke callback', (tester) async {
      _bindTallSurfaceForSubmit(tester);
      var calls = 0;
      await tester.pumpWidget(
        _providerWrappedCreateGameApp(
          CreateGameScreen(
            onSubmit: (_) async {
              calls++;
            },
          ),
        ),
      );
      await tester.enterText(
        find.byKey(const ValueKey('create-game-name-field')),
        'RapidSubmit',
      );
      await _tapCreateGameSubmit(tester);
      await _tapCreateGameSubmit(tester);
      expect(calls, 2);
    });
  });

  group('CreateGameScreen (POL3 repository error)', () {
    testWidgets('createGame failure shows message and Retry', (tester) async {
      _bindTallSurfaceForSubmit(tester);
      await _pumpCreateGameWithGameRepo(
        tester,
        _ThrowOnCreateGameRepository(),
      );
      await tester.enterText(
        find.byKey(const ValueKey('create-game-name-field')),
        'Broken Repo Game',
      );
      await _tapCreateGameSubmit(tester);
      expect(find.text('Simulated create failure'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('create-game-submit-retry')),
        findsOneWidget,
      );
    });
  });
}
