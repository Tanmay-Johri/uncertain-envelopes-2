import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/ui/screens/profile/profile_view_data.dart';

void main() {
  group('ProfileViewData', () {
    test('normalizes username to lowercase on construction', () {
      final d = ProfileViewData(
        username: '  CryptoKing99 ',
        email: 'a@b.com',
        emailVerified: true,
        winRatePct: 1,
        gamesPlayed: 2,
      );
      expect(d.username, 'cryptoking99');
    });

    test('copyWith lowercases username when provided', () {
      final d = ProfileViewData(
        username: 'alice',
        email: 'a@b.com',
        emailVerified: true,
        winRatePct: 1,
        gamesPlayed: 2,
      );
      expect(d.copyWith(username: 'BOB').username, 'bob');
    });
  });
}
