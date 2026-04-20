import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/repositories/game_repository.dart';

part 'game_repository_provider.g.dart';

/// Injection point for the [GameRepository] implementation. `main()` and
/// tests must override this provider.
@Riverpod(keepAlive: true)
GameRepository gameRepository(Ref ref) {
  throw UnimplementedError(
    'gameRepositoryProvider must be overridden '
    '(in main() with SupabaseGameRepository, or in tests with InMemoryGameRepository).',
  );
}
