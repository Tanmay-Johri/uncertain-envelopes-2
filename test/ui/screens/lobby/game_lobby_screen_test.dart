import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/core/theme/app_theme.dart';
import 'package:uncertain_envelopes_2/ui/screens/lobby/game_lobby_screen.dart';
import 'package:uncertain_envelopes_2/ui/screens/lobby/lobby_mock_data.dart';
import 'package:uncertain_envelopes_2/ui/screens/lobby/lobby_view_data.dart';
import 'package:uncertain_envelopes_2/ui/widgets/countdown_timer.dart';

void main() {
  group('GameLobbyScreen', () {
    testWidgets('g1pre mock shows pre-start Leave Game and static timer',
        (tester) async {
      final s = mockLobbyScenarioForGameId('g1pre');
      expect(s.phase, GameLobbyPhase.preStart);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: GameLobbyScreen(
            data: s.data,
            phase: s.phase,
            currentPlayerId: s.currentPlayerId,
            isViewerAdmin: s.isViewerAdmin,
          ),
        ),
      );
      expect(find.byKey(const ValueKey('game-lobby-leave')), findsOneWidget);
      expect(find.text('LEAVE GAME'), findsOneWidget);
      expect(find.byType(CountdownTimer), findsNothing);
      expect(find.text('60:00'), findsOneWidget);
    });

    testWidgets('g1 mock shows trading Enter Game and joining code',
        (tester) async {
      final s = mockLobbyScenarioForGameId('g1');
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: GameLobbyScreen(
            data: s.data,
            phase: s.phase,
            currentPlayerId: s.currentPlayerId,
            isViewerAdmin: s.isViewerAdmin,
          ),
        ),
      );
      expect(find.byKey(const ValueKey('game-lobby-scaffold')), findsOneWidget);
      expect(find.text('Forex Masters'), findsWidgets);
      expect(find.textContaining('CryptoWhale (You)'), findsOneWidget);
      expect(find.text('V 8 J A J'), findsOneWidget);
      expect(find.text('PARTICIPANTS (4/8)'), findsOneWidget);
      expect(find.byKey(const ValueKey('game-lobby-enter')), findsOneWidget);
      expect(find.text('START GAME'), findsNothing);
      expect(find.text('JOIN GAME'), findsNothing);
      expect(find.byKey(const ValueKey('game-lobby-end')), findsNothing);
      expect(find.byType(CountdownTimer), findsOneWidget);
    });

    testWidgets(
        'admin in trading phase sees Enter Game and End Game, not Start',
        (tester) async {
      final s = mockLobbyScenarioForGameId('g2');
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: GameLobbyScreen(
            data: s.data,
            phase: GameLobbyPhase.trading,
            currentPlayerId: s.currentPlayerId,
            isViewerAdmin: true,
          ),
        ),
      );
      expect(find.byKey(const ValueKey('game-lobby-enter')), findsOneWidget);
      expect(find.byKey(const ValueKey('game-lobby-end')), findsOneWidget);
      expect(find.text('START GAME'), findsNothing);
    });

    testWidgets('g2 mock shows Start/End and kick on others only',
        (tester) async {
      var kicked = '';
      final s = mockLobbyScenarioForGameId('g2');
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: GameLobbyScreen(
            data: s.data,
            phase: s.phase,
            currentPlayerId: s.currentPlayerId,
            isViewerAdmin: s.isViewerAdmin,
            onKickPlayer: (id) => kicked = id,
          ),
        ),
      );
      expect(find.byKey(const ValueKey('game-lobby-start')), findsOneWidget);
      expect(find.byKey(const ValueKey('game-lobby-end')), findsOneWidget);
      expect(find.text('ENTER GAME'), findsNothing);
      expect(find.byKey(const ValueKey('lobby-kick-p_js')), findsOneWidget);
      expect(find.byKey(const ValueKey('lobby-kick-p_ad')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('lobby-kick-p_js')));
      await tester.pump();
      expect(kicked, 'p_js');
    });

    testWidgets('preStart shows static time remaining; does not tick',
        (tester) async {
      final s = mockLobbyScenarioForGameId('g2');
      expect(s.phase, GameLobbyPhase.preStart);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: GameLobbyScreen(
            data: s.data,
            phase: s.phase,
            currentPlayerId: s.currentPlayerId,
            isViewerAdmin: s.isViewerAdmin,
          ),
        ),
      );
      expect(find.text('60:00'), findsOneWidget);
      expect(find.byType(CountdownTimer), findsNothing);
      expect(
        find.byKey(const ValueKey('game-lobby-time-remaining-static')),
        findsOneWidget,
      );
      await tester.pump(const Duration(minutes: 2));
      expect(find.text('60:00'), findsOneWidget);
    });

    testWidgets(
        'non-admin joined preStart shows Leave Game, not Start or Join',
        (tester) async {
      var left = false;
      final s = mockLobbyScenarioForGameId('g2');
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: GameLobbyScreen(
            data: s.data,
            phase: GameLobbyPhase.preStart,
            currentPlayerId: 'p_js',
            isViewerAdmin: false,
            onLeaveGame: () => left = true,
          ),
        ),
      );
      expect(find.byKey(const ValueKey('game-lobby-leave')), findsOneWidget);
      expect(find.text('LEAVE GAME'), findsOneWidget);
      expect(find.text('START GAME'), findsNothing);
      expect(find.text('JOIN GAME'), findsNothing);
      expect(find.byKey(const ValueKey('lobby-kick-p_ad')), findsNothing);
      await tester.ensureVisible(
        find.byKey(const ValueKey('game-lobby-leave')),
      );
      await tester.tap(find.byKey(const ValueKey('game-lobby-leave')));
      await tester.pump();
      expect(left, isTrue);
    });

    testWidgets(
        'non-admin not joined preStart shows Join Game regardless of phase',
        (tester) async {
      var joined = false;
      final s = mockLobbyScenarioForGameId('g2');
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: GameLobbyScreen(
            data: s.data,
            phase: GameLobbyPhase.preStart,
            currentPlayerId: 'spectator',
            isViewerAdmin: false,
            onJoinGame: () => joined = true,
          ),
        ),
      );
      expect(find.byKey(const ValueKey('game-lobby-join')), findsOneWidget);
      expect(find.text('JOIN GAME'), findsOneWidget);
      expect(find.text('LEAVE GAME'), findsNothing);
      await tester.ensureVisible(
        find.byKey(const ValueKey('game-lobby-join')),
      );
      await tester.tap(find.byKey(const ValueKey('game-lobby-join')));
      await tester.pump();
      expect(joined, isTrue);
    });

    testWidgets(
        'non-admin not joined trading shows Join Game not Enter',
        (tester) async {
      final s = mockLobbyScenarioForGameId('g1');
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: GameLobbyScreen(
            data: s.data,
            phase: GameLobbyPhase.trading,
            currentPlayerId: 'not-a-player',
            isViewerAdmin: false,
          ),
        ),
      );
      expect(find.byKey(const ValueKey('game-lobby-join')), findsOneWidget);
      expect(find.text('ENTER GAME'), findsNothing);
      expect(find.byType(CountdownTimer), findsOneWidget);
    });

    testWidgets('trading phase renders live CountdownTimer when timed',
        (tester) async {
      // Tick-down behaviour itself lives in countdown_timer_test.dart (which
      // exercises the wall-clock-anchored implementation against simulated
      // throttling, add-time, and zero-cross). This test only verifies the
      // lobby wires the live CountdownTimer in during trading phase with the
      // correct initial value.
      final s = mockLobbyScenarioForGameId('g1');
      expect(s.phase, GameLobbyPhase.trading);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: GameLobbyScreen(
            data: s.data,
            phase: s.phase,
            currentPlayerId: s.currentPlayerId,
            isViewerAdmin: s.isViewerAdmin,
          ),
        ),
      );
      expect(find.byKey(const ValueKey('game-lobby-countdown')), findsOneWidget);
      expect(find.text('60:00'), findsOneWidget);
    });

    testWidgets('timed game shows TIME REMAINING placeholder when duration unknown',
        (tester) async {
      final s = mockLobbyScenarioForGameId('g1');
      final data = GameLobbyViewData(
        gameTitle: s.data.gameTitle,
        description: s.data.description,
        joiningCodeRaw: s.data.joiningCodeRaw,
        isPublic: s.data.isPublic,
        isRanked: s.data.isRanked,
        maxPlayers: s.data.maxPlayers,
        players: s.data.players,
        isTimed: true,
        tradingTimeRemaining: null,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: GameLobbyScreen(
            data: data,
            phase: GameLobbyPhase.preStart,
            currentPlayerId: s.currentPlayerId,
            isViewerAdmin: s.isViewerAdmin,
          ),
        ),
      );
      expect(find.text('TIME REMAINING'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('game-lobby-time-remaining-unknown')),
        findsOneWidget,
      );
      expect(find.text('--:--'), findsOneWidget);
      expect(find.byKey(const ValueKey('game-lobby-countdown')), findsNothing);
    });

    testWidgets('hides countdown when not timed', (tester) async {
      final s = mockLobbyScenarioForGameId('g1');
      final data = GameLobbyViewData(
        gameTitle: s.data.gameTitle,
        description: s.data.description,
        joiningCodeRaw: s.data.joiningCodeRaw,
        isPublic: s.data.isPublic,
        isRanked: s.data.isRanked,
        maxPlayers: s.data.maxPlayers,
        players: s.data.players,
        isTimed: false,
        tradingTimeRemaining: null,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: GameLobbyScreen(
            data: data,
            phase: s.phase,
            currentPlayerId: s.currentPlayerId,
            isViewerAdmin: s.isViewerAdmin,
          ),
        ),
      );
      expect(find.byKey(const ValueKey('game-lobby-countdown')), findsNothing);
      expect(find.text('TIME REMAINING'), findsNothing);
    });
  });
}
