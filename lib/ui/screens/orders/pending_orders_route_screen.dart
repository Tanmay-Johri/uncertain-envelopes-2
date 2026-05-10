import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/command_repository_provider.dart';
import '../../../providers/view_data/pending_orders_view_data_provider.dart';
import '../../widgets/fetched_error_panel.dart';
import 'pending_orders_screen.dart';
import 'pending_orders_view_data.dart';

/// Shell route body: loads [pendingOrdersViewDataProvider] (Phase 2B.8).
class PendingOrdersRouteScreen extends ConsumerWidget {
  const PendingOrdersRouteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(pendingOrdersViewDataProvider);
    return async.when(
      loading: () => const Scaffold(
        key: ValueKey('pending-orders-route-loading'),
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        key: const ValueKey('pending-orders-route-error'),
        backgroundColor: AppColors.background,
        body: FetchedErrorPanel(
          message: '$e',
          onRetry: () => ref.invalidate(pendingOrdersViewDataProvider),
        ),
      ),
      data: (items) {
        final viewer = ref.read(authControllerProvider).valueOrNull;
        return PendingOrdersScreen(
          items: items,
          onCancelOrder: viewer == null
              ? null
              : (orderId) {
                  unawaited(
                    (() async {
                      PendingOrderListItem? row;
                      for (final e in items) {
                        if (e.order.id == orderId) {
                          row = e;
                          break;
                        }
                      }
                      if (row == null) return;
                      final cmds = ref.read(commandRepositoryProvider);
                      await cmds.submitCancelOrder(
                        gameId: row.gameId,
                        playerId: viewer.playerId,
                        orderId: orderId,
                      );
                      ref.invalidate(pendingOrdersViewDataProvider);
                    })(),
                  );
                },
        );
      },
    );
  }
}
