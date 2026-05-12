import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/core/router/app_router.dart';
import 'package:uncertain_envelopes_2/core/router/game_flow.dart';
import 'package:uncertain_envelopes_2/data/enums/game_state.dart';
import 'package:uncertain_envelopes_2/ui/screens/home/home_mock_data.dart';
import 'package:uncertain_envelopes_2/ui/widgets/status_badge.dart';

void main() {
  group('gameStateShowsEnvelopeFlowOnly', () {
    test('false for created and trading_started', () {
      expect(gameStateShowsEnvelopeFlowOnly(GameState.created), isFalse);
      expect(
        gameStateShowsEnvelopeFlowOnly(GameState.tradingStarted),
        isFalse,
      );
    });

    test('true for trading ended and terminal states', () {
      expect(gameStateShowsEnvelopeFlowOnly(GameState.tradingEnded), isTrue);
      expect(gameStateShowsEnvelopeFlowOnly(GameState.gameFinalised), isTrue);
      expect(gameStateShowsEnvelopeFlowOnly(GameState.discarded), isTrue);
    });
  });

  group('homeGameEntryRoute', () {
    test('ended status routes to results', () {
      expect(
        homeGameEntryRoute(
          const MockHomeGame(
            id: 'x',
            title: '',
            description: '',
            status: GameStatusBadge.ended,
            isPublic: true,
            isJoined: true,
            isAdmin: false,
            playerInitials: [],
            maxPlayers: 8,
          ),
        ),
        AppRoutes.gameResults('x'),
      );
    });

    test('openEnvelopeResults routes to results even if badge says joined', () {
      expect(
        homeGameEntryRoute(
          const MockHomeGame(
            id: 'y',
            title: '',
            description: '',
            status: GameStatusBadge.joined,
            isPublic: true,
            isJoined: true,
            isAdmin: false,
            playerInitials: [],
            maxPlayers: 8,
            openEnvelopeResults: true,
          ),
        ),
        AppRoutes.gameResults('y'),
      );
    });

    test('playing + openEnvelopeResults routes to results (envelope stage)', () {
      expect(
        homeGameEntryRoute(
          const MockHomeGame(
            id: 'env',
            title: '',
            description: '',
            status: GameStatusBadge.playing,
            isPublic: true,
            isJoined: true,
            isAdmin: false,
            playerInitials: [],
            maxPlayers: 8,
            openEnvelopeResults: true,
          ),
        ),
        AppRoutes.gameResults('env'),
      );
    });

    test('playing routes to lobby (enter trading from lobby)', () {
      expect(
        homeGameEntryRoute(
          const MockHomeGame(
            id: 'z',
            title: '',
            description: '',
            status: GameStatusBadge.playing,
            isPublic: true,
            isJoined: true,
            isAdmin: false,
            playerInitials: [],
            maxPlayers: 8,
          ),
        ),
        AppRoutes.gameLobby('z'),
      );
    });

    test('joined (pre-start) routes to lobby', () {
      expect(
        homeGameEntryRoute(
          const MockHomeGame(
            id: 'w',
            title: '',
            description: '',
            status: GameStatusBadge.joined,
            isPublic: true,
            isJoined: true,
            isAdmin: false,
            playerInitials: [],
            maxPlayers: 8,
          ),
        ),
        AppRoutes.gameLobby('w'),
      );
    });
  });
}
