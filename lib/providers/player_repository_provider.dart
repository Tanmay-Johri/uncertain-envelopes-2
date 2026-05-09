import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/repositories/in_memory_player_repository.dart';
import '../data/repositories/player_repository.dart';
import '../data/repositories/supabase_player_repository.dart';
import '../services/supabase_player_gateway.dart';
import '_environment.dart';

part 'player_repository_provider.g.dart';

@Riverpod(keepAlive: true)
PlayerRepository playerRepository(Ref ref) {
  if (useRealBackend) {
    return SupabasePlayerRepository(
      RealSupabasePlayerGateway(Supabase.instance.client),
    );
  }
  return InMemoryPlayerRepository();
}
