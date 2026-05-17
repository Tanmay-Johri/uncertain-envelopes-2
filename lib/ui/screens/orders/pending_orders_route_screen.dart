import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/trading/order_type_from_personal.dart';
import '../../../core/trading/personal_order.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/best_effort_post_submit_refresh.dart';
import '../../../providers/command_repository_provider.dart';
import '../../../providers/trading_provider.dart';
import '../../../providers/view_data/pending_orders_view_data_provider.dart';
import '../../widgets/async_route_loading_body.dart';
import '../../widgets/fetched_error_panel.dart';
import '../../widgets/new_order_modal.dart';
import 'pending_orders_screen.dart';
import 'pending_orders_view_data.dart';

/// Shell route body: loads [pendingOrdersViewDataProvider] (Phase 2B.8).
class PendingOrdersRouteScreen extends ConsumerStatefulWidget {
  const PendingOrdersRouteScreen({super.key});

  @override
  ConsumerState<PendingOrdersRouteScreen> createState() =>
      _PendingOrdersRouteScreenState();
}

class _PendingOrdersRouteScreenState
    extends ConsumerState<PendingOrdersRouteScreen> {
  Timer? _poll;
  bool _ordersShellBranchActive = false;

  void _scheduleOrdersRefreshWhenShellTabBecomesVisible() {
    final shell = StatefulNavigationShell.maybeOf(context);
    if (shell == null) return;
    final active = shell.currentIndex == AppShellTabIndex.orders;
    if (active) {
      if (!_ordersShellBranchActive) {
        _ordersShellBranchActive = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final s2 = StatefulNavigationShell.maybeOf(context);
          if (s2 != null && s2.currentIndex == AppShellTabIndex.orders) {
            unawaited(
              ref.read(pendingOrdersViewDataProvider.notifier).silentRefresh(),
            );
          }
        });
      }
    } else {
      _ordersShellBranchActive = false;
    }
  }

  @override
  void initState() {
    super.initState();
    _poll = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      unawaited(
        ref.read(pendingOrdersViewDataProvider.notifier).silentRefresh(),
      );
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _scheduleOrdersRefreshWhenShellTabBecomesVisible();
    final async = ref.watch(pendingOrdersViewDataProvider);
    return async.when(
      loading: () => const Scaffold(
        key: ValueKey('pending-orders-route-loading'),
        backgroundColor: AppColors.background,
        body: AsyncRouteLoadingBody(message: 'Loading pending orders…'),
      ),
      error: (e, _) => Scaffold(
        key: const ValueKey('pending-orders-route-error'),
        backgroundColor: AppColors.background,
        body: FetchedErrorPanel(
          message: '$e',
          onRetry: () => ref.invalidate(pendingOrdersViewDataProvider),
        ),
      ),
      data: (data) {
        final viewer = ref.read(authControllerProvider).valueOrNull;
        final items = data.items;
        return PendingOrdersScreen(
          items: items,
          tradingGamesForNewOrder: data.tradingGamesForNewOrder,
          onSubmitNewOrder: viewer == null
              ? null
              : ({
                  required String gameId,
                  required GameScopedNewOrder created,
                }) async {
                  final cmds = ref.read(commandRepositoryProvider);
                  await cmds.submitCreateOrder(
                    gameId: gameId,
                    playerId: viewer.playerId,
                    type: orderTypeFromPersonalDraft(created.order),
                    quantityInitial: created.order.quantityInitial,
                    pricePerStock: created.order.orderType ==
                            PersonalOrderType.limit
                        ? created.order.limitPrice
                        : null,
                  );
                  await bestEffortPostSubmitRefresh([
                    () => ref.read(ordersProvider(gameId).notifier).refresh(),
                    () => ref
                        .read(
                          pendingCreateOrderCommandsProvider(gameId).notifier,
                        )
                        .refresh(),
                    () => ref
                        .read(pendingOrdersViewDataProvider.notifier)
                        .silentRefresh(),
                  ]);
                },
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
                      await ref
                          .read(pendingOrdersViewDataProvider.notifier)
                          .silentRefresh();
                    })(),
                  );
                },
        );
      },
    );
  }
}
