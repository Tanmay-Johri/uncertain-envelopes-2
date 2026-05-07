import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/ui/screens/lobby/lobby_view_data.dart';

void main() {
  group('formatJoiningCodeDisplay', () {
    test('uppercases and inserts spaces between characters', () {
      expect(formatJoiningCodeDisplay('v8jaj'), 'V 8 J A J');
    });

    test('strips existing whitespace first', () {
      expect(formatJoiningCodeDisplay(' v 8 j aj '), 'V 8 J A J');
    });

    test('empty string stays empty', () {
      expect(formatJoiningCodeDisplay(''), '');
    });

    test('single character', () {
      expect(formatJoiningCodeDisplay('a'), 'A');
    });
  });

  group('lobbyViewerIsInPlayerList', () {
    test('true when viewer id matches a player', () {
      const data = GameLobbyViewData(
        gameTitle: 'G',
        description: 'd',
        joiningCodeRaw: 'X',
        isPublic: true,
        isRanked: false,
        maxPlayers: 4,
        players: [
          LobbyPlayerView(
            id: 'p1',
            username: 'A',
            initials: 'A',
            isGameAdmin: false,
          ),
        ],
        isTimed: false,
      );
      expect(lobbyViewerIsInPlayerList(data, 'p1'), isTrue);
    });

    test('false when viewer id is not seated', () {
      const data = GameLobbyViewData(
        gameTitle: 'G',
        description: 'd',
        joiningCodeRaw: 'X',
        isPublic: true,
        isRanked: false,
        maxPlayers: 4,
        players: [
          LobbyPlayerView(
            id: 'p1',
            username: 'A',
            initials: 'A',
            isGameAdmin: false,
          ),
        ],
        isTimed: false,
      );
      expect(lobbyViewerIsInPlayerList(data, 'viewer'), isFalse);
    });
  });
}
