import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/ui/screens/home/home_mock_data.dart';
void main() {
  group('mockHomeGamePassesFilters', () {
    test('joined tab keeps only joined games', () {
      final joined = kMockHomeGames
          .where((g) => mockHomeGamePassesFilters(g, joinedTab: true, adminOnly: false))
          .map((g) => g.id)
          .toList();
      expect(joined, contains('g1'));
      expect(joined, isNot(contains('g4')));
    });

    test('public tab excludes private games', () {
      final pub = kMockHomeGames
          .where((g) => mockHomeGamePassesFilters(g, joinedTab: false, adminOnly: false))
          .map((g) => g.id)
          .toList();
      expect(pub, isNot(contains('g5')));
    });

    test('admin toggle filters to admin games only', () {
      final adminJoined = kMockHomeGames
          .where((g) => mockHomeGamePassesFilters(g, joinedTab: true, adminOnly: true))
          .map((g) => g.id)
          .toList();
      expect(adminJoined, ['g2', 'g5']);
    });
  });
}
