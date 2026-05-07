import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/repositories/execution_repository.dart';
import '../data/repositories/order_repository.dart';

part 'trading_repository_providers.g.dart';

@Riverpod(keepAlive: true)
OrderRepository orderRepository(Ref ref) {
  throw UnimplementedError(
    'orderRepositoryProvider must be overridden '
    '(in main() with SupabaseOrderRepository, or in tests with InMemoryOrderRepository).',
  );
}

@Riverpod(keepAlive: true)
ExecutionRepository executionRepository(Ref ref) {
  throw UnimplementedError(
    'executionRepositoryProvider must be overridden '
    '(in main() with SupabaseExecutionRepository, or in tests with InMemoryExecutionRepository).',
  );
}
