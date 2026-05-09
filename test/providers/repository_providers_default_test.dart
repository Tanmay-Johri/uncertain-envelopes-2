import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/data/repositories/in_memory_auth_repository.dart';
import 'package:uncertain_envelopes_2/data/repositories/in_memory_command_repository.dart';
import 'package:uncertain_envelopes_2/data/repositories/in_memory_execution_repository.dart';
import 'package:uncertain_envelopes_2/data/repositories/in_memory_game_repository.dart';
import 'package:uncertain_envelopes_2/data/repositories/in_memory_order_repository.dart';
import 'package:uncertain_envelopes_2/data/repositories/in_memory_player_repository.dart';
import 'package:uncertain_envelopes_2/providers/_environment.dart';
import 'package:uncertain_envelopes_2/providers/auth_provider.dart';
import 'package:uncertain_envelopes_2/providers/command_repository_provider.dart';
import 'package:uncertain_envelopes_2/providers/game_repository_provider.dart';
import 'package:uncertain_envelopes_2/providers/player_repository_provider.dart';
import 'package:uncertain_envelopes_2/providers/trading_repository_providers.dart';

void main() {
  test(
    'repository providers expose in-memory stack when useRealBackend is false',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(authRepositoryProvider), isA<InMemoryAuthRepository>());
      expect(
        container.read(commandRepositoryProvider),
        isA<InMemoryCommandRepository>(),
      );
      expect(container.read(gameRepositoryProvider), isA<InMemoryGameRepository>());
      expect(container.read(orderRepositoryProvider), isA<InMemoryOrderRepository>());
      expect(
        container.read(executionRepositoryProvider),
        isA<InMemoryExecutionRepository>(),
      );
      expect(
        container.read(playerRepositoryProvider),
        isA<InMemoryPlayerRepository>(),
      );

      expect(
        identical(
          container.read(authRepositoryProvider),
          container.read(authRepositoryProvider),
        ),
        isTrue,
      );
    },
    skip: useRealBackend
        ? 'Compiled with USE_REAL_BACKEND=true; this contract targets the in-memory default.'
        : null,
  );

  test('authRepositoryProvider override replaces default', () {
    final custom = InMemoryAuthRepository();
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(custom),
      ],
    );
    addTearDown(container.dispose);
    expect(container.read(authRepositoryProvider), same(custom));
  });
}
