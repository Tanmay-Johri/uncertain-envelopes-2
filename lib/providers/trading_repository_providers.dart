import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/repositories/execution_repository.dart';
import '../data/repositories/in_memory_execution_repository.dart';
import '../data/repositories/in_memory_order_repository.dart';
import '../data/repositories/order_repository.dart';
import '../data/repositories/supabase_execution_repository.dart';
import '../data/repositories/supabase_order_repository.dart';
import '../services/supabase_execution_gateway.dart';
import '../services/supabase_order_gateway.dart';
import '_environment.dart';

part 'trading_repository_providers.g.dart';

@Riverpod(keepAlive: true)
OrderRepository orderRepository(Ref ref) {
  if (useRealBackend) {
    return SupabaseOrderRepository(
      RealSupabaseOrderGateway(Supabase.instance.client),
    );
  }
  return InMemoryOrderRepository();
}

@Riverpod(keepAlive: true)
ExecutionRepository executionRepository(Ref ref) {
  if (useRealBackend) {
    return SupabaseExecutionRepository(
      RealSupabaseExecutionGateway(Supabase.instance.client),
    );
  }
  return InMemoryExecutionRepository();
}
