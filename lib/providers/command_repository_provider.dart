import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/repositories/command_repository.dart';
import '../data/repositories/in_memory_command_repository.dart';
import '../data/repositories/supabase_command_repository.dart';
import '../services/supabase_command_gateway.dart';
import '_environment.dart';

part 'command_repository_provider.g.dart';

@Riverpod(keepAlive: true)
CommandRepository commandRepository(Ref ref) {
  if (useRealBackend) {
    return SupabaseCommandRepository(
      RealSupabaseCommandGateway(Supabase.instance.client),
    );
  }
  return InMemoryCommandRepository();
}
