import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/repositories/game_repository.dart';
import '../data/repositories/in_memory_game_repository.dart';
import '../data/repositories/supabase_game_repository.dart';
import '../services/supabase_game_gateway.dart';
import '_environment.dart';
import 'command_repository_provider.dart';

part 'game_repository_provider.g.dart';

/// Global [GameRepository]. Defaults to in-memory; uses Supabase when
/// `USE_REAL_BACKEND=true`.
@Riverpod(keepAlive: true)
GameRepository gameRepository(Ref ref) {
  final commands = ref.watch(commandRepositoryProvider);
  if (useRealBackend) {
    return SupabaseGameRepository(
      commandRepository: commands,
      gateway: RealSupabaseGameGateway(Supabase.instance.client),
    );
  }
  return InMemoryGameRepository(commandRepository: commands);
}
