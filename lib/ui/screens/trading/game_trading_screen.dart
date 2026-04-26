import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';
import '../../../core/trading/cancel_order_command.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/chart/chart_axis.dart';
import '../../widgets/active_orders_widget.dart';
import '../../widgets/countdown_timer.dart';
import '../../widgets/neon_button.dart';
import '../../widgets/new_order_modal.dart';
import '../../widgets/pnl_calculator.dart';
import '../../widgets/price_chart.dart';
import '../../widgets/stat_tile.dart';
import 'order_book_widget.dart';
import 'trading_stat_format.dart';
import 'trading_view_data.dart';

/// Trading dashboard (C6). Layout follows
/// `design-uncertain-envelopes-2/admin_game_trading_dashboard_7/code.html`.
class GameTradingScreen extends StatefulWidget {
  const GameTradingScreen({
    super.key,
    required this.data,
    this.onShowLogs,
    this.onEndGameFromMenu,
    this.onAddTime,
    this.submitCancelOrderCommand,
  });

  final GameTradingViewData data;
  final VoidCallback? onShowLogs;
  final VoidCallback? onEndGameFromMenu;
  final VoidCallback? onAddTime;

  /// Completes when the backend acks that the `cancel_order` command **row**
  /// was created. Defaults to [defaultSubmitCancelOrderCommandAck] in state.
  final Future<void> Function(String orderId)? submitCancelOrderCommand;

  @override
  State<GameTradingScreen> createState() => _GameTradingScreenState();
}

class _GameTradingScreenState extends State<GameTradingScreen> {
  late List<PersonalOrder> _personalOrders;
  var _localOrderSeq = 0;

  /// Keeps [NewOrderModal]’s Last Traded Price line in sync while the dialog is open.
  late final ValueNotifier<double> _marketPriceNotifier;

  /// Live bid–ask midpoint for [NewOrderModal] (`null` → hyphen in the UI).
  late final ValueNotifier<double?> _bidAskMidpointNotifier;

  /// Mock: after user sends cancel, until backend reports [PersonalOrderStatus.cancelled].
  final Set<String> _pendingCancellationOrderIds = <String>{};

  @override
  void initState() {
    super.initState();
    _marketPriceNotifier = ValueNotifier(widget.data.marketPrice);
    _bidAskMidpointNotifier = ValueNotifier(
      computeBidAskMidpoint(
        widget.data.orderBookBids,
        widget.data.orderBookAsks,
      ),
    );
    _personalOrders = [];
    _reconcilePersonalOrdersWithBackendSnapshot();
  }

  @override
  void didUpdateWidget(covariant GameTradingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data.marketPrice != _marketPriceNotifier.value) {
      _marketPriceNotifier.value = widget.data.marketPrice;
    }
    final nextMid = computeBidAskMidpoint(
      widget.data.orderBookBids,
      widget.data.orderBookAsks,
    );
    if (nextMid != _bidAskMidpointNotifier.value) {
      _bidAskMidpointNotifier.value = nextMid;
    }
    if (!identical(oldWidget.data, widget.data)) {
      _reconcilePersonalOrdersWithBackendSnapshot();
    }
  }

  @override
  void dispose() {
    _marketPriceNotifier.dispose();
    _bidAskMidpointNotifier.dispose();
    super.dispose();
  }

  /// [widget.data.personalOrders] is authoritative: any id not in that list is
  /// removed (except optimistic `local_*` rows not yet echoed by the server).
  void _reconcilePersonalOrdersWithBackendSnapshot() {
    final incoming = List<PersonalOrder>.from(widget.data.personalOrders);
    final incomingIds = incoming.map((e) => e.id).toSet();
    final optimisticLocal = _personalOrders
        .where((o) => o.id.startsWith('local_') && !incomingIds.contains(o.id))
        .toList();
    _personalOrders = [...incoming, ...optimisticLocal];
    _pendingCancellationOrderIds.removeWhere((id) {
      final i = _personalOrders.indexWhere((o) => o.id == id);
      if (i < 0) return true;
      return personalOrderClearsCancellationPending(_personalOrders[i].status);
    });
  }

  String _allocateOrderId() {
    _localOrderSeq++;
    return 'local_${widget.data.currentPlayerId}_$_localOrderSeq';
  }

  /// Optimistic **Cancelling** → await command-row ack (with timeout) → keep
  /// **Cancelling** until mock/worker sets order to [PersonalOrderStatus.cancelled].
  void _onCancellationRequested(BuildContext context, String orderId) {
    setState(() => _pendingCancellationOrderIds.add(orderId));
    unawaited(_runCancelOrderCommandFlow(context, orderId));
  }

  Future<void> _runCancelOrderCommandFlow(
    BuildContext context,
    String orderId,
  ) async {
    final submit = widget.submitCancelOrderCommand ??
        defaultSubmitCancelOrderCommandAck;
    try {
      await submit(orderId).timeout(AppConstants.cancelOrderCommandAckTimeout);
    } on TimeoutException {
      if (!mounted) return;
      setState(() => _pendingCancellationOrderIds.remove(orderId));
      if (context.mounted) {
        _showCancelCommandAckFailedBanner(context);
      }
      return;
    } catch (_) {
      if (!mounted) return;
      setState(() => _pendingCancellationOrderIds.remove(orderId));
      if (context.mounted) {
        _showCancelCommandAckFailedBanner(context);
      }
      return;
    }

    if (!mounted) return;
    _scheduleMockWorkerOrderCancelled(orderId);
  }

  void _showCancelCommandAckFailedBanner(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(kCancelOrderCommandAckFailedMessage),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// After command row exists: mock worker delay, then same local update as a
  /// snapshot with `cancelled`. Phase 2: remove; rely on backend orders feed.
  void _scheduleMockWorkerOrderCancelled(String id) {
    Future<void>.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      setState(() {
        _pendingCancellationOrderIds.remove(id);
        _personalOrders = [
          for (final o in _personalOrders)
            if (o.id == id)
              o.copyWith(status: PersonalOrderStatus.cancelled)
            else
              o,
        ];
      });
    });
  }

  Future<void> _openNewOrder(BuildContext context) async {
    final created = await NewOrderModal.show(
      context,
      marketPrice: widget.data.marketPrice,
      marketPriceListenable: _marketPriceNotifier,
      bidAskMidpointListenable: _bidAskMidpointNotifier,
    );
    if (!mounted || created == null) return;
    setState(() {
      _personalOrders = [
        ..._personalOrders,
        created.copyWith(id: _allocateOrderId()),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    return Scaffold(
      key: const ValueKey('game-trading-scaffold'),
      backgroundColor: AppColors.background,
      bottomNavigationBar: Material(
        color: AppColors.background,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: NeonButton(
              key: const ValueKey('game-trading-new-order'),
              label: 'Create new order',
              onPressed: () => _openNewOrder(context),
            ),
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SafeArea(
            bottom: false,
            child: _TradingWindowHeader(
              isViewerAdmin: data.isViewerAdmin,
              onShowLogs: widget.onShowLogs,
              onEndGameFromMenu: widget.onEndGameFromMenu,
              onAccountTap: () => context.go(AppRoutes.profile),
            ),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      data.gameTitle,
                      key: const ValueKey('game-trading-title'),
                      textAlign: TextAlign.center,
                      style: AppTypography.sectionHeader.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      data.description,
                      key: const ValueKey('game-trading-description'),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.monoSmall.copyWith(
                        fontSize: 12,
                        color: AppColors.textTertiary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (data.isTimed &&
                            data.tradingTimeRemaining != null) ...[
                          CountdownTimer(
                            key: const ValueKey('game-trading-countdown'),
                            initialRemaining: data.tradingTimeRemaining!,
                            textStyle: AppTypography.timerDisplay,
                          ),
                          if (data.isViewerAdmin) ...[
                            const SizedBox(width: AppSpacing.md),
                            _AddTimeButton(onPressed: widget.onAddTime),
                          ],
                        ],
                      ],
                    ),
                    if (data.isTimed && data.tradingTimeRemaining != null)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.sm),
                        child: Text(
                          'TIME REMAINING',
                          key: const ValueKey('game-trading-time-label'),
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySmall.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.4,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.sectionGap),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: StatTile(
                            key: const ValueKey('trading-stat-delta-cash'),
                            label: 'Delta Cash',
                            value: formatTradingDeltaCash(data.deltaCash),
                            signedValue: data.deltaCash,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: StatTile(
                            key: const ValueKey('trading-stat-delta-envelopes'),
                            label: 'Delta Envelopes',
                            value: formatTradingDeltaEnvelopes(
                              data.deltaEnvelopes,
                            ),
                            signedValue: data.deltaEnvelopes,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    PnlCalculator(
                      marketPrice: data.marketPrice,
                      deltaCash: data.deltaCash,
                      deltaEnvelopes: data.deltaEnvelopes,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    PriceChart(
                      key: const ValueKey('trading-chart-section'),
                      marketPrice: data.marketPrice,
                      points: data.priceHistory,
                      gameStartedAtUtc: data.gameStartedAtUtc,
                      axis: ChartAxisConfig.fromExecutionHistory(
                        sessionElapsed: data.chartSessionElapsed,
                        points: data.priceHistory,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    OrderBookWidget(
                      key: const ValueKey('trading-orderbook-section'),
                      bids: data.orderBookBids,
                      asks: data.orderBookAsks,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    ActiveOrdersWidget(
                      key: const ValueKey('trading-active-orders-section'),
                      orders: _personalOrders,
                      pendingCancellationOrderIds: _pendingCancellationOrderIds,
                      onCancellationRequested: _onCancellationRequested,
                    ),
                    const SizedBox(height: AppSpacing.xxxxl),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sticky frosted header: account (left), `TRADING WINDOW` (center), overflow (right).
class _TradingWindowHeader extends StatelessWidget {
  const _TradingWindowHeader({
    required this.isViewerAdmin,
    required this.onAccountTap,
    this.onShowLogs,
    this.onEndGameFromMenu,
  });

  final bool isViewerAdmin;
  final VoidCallback onAccountTap;
  final VoidCallback? onShowLogs;
  final VoidCallback? onEndGameFromMenu;

  /// Content row only; padding is added outside this height.
  static const double _toolbarHeight = 36;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.95),
            border: const Border(
              bottom: BorderSide(color: AppColors.outlineSubtle),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: SizedBox(
            height: _toolbarHeight,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  'TRADING WINDOW',
                  key: const ValueKey('game-trading-appbar-title'),
                  style: AppTypography.tradingWindowHeaderTitle.copyWith(
                    fontSize: 12,
                    height: 1.0,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: _toolbarHeight,
                      ),
                      icon: Icon(
                        Icons.account_circle_outlined,
                        color: AppColors.textSecondary,
                        size: 22,
                      ),
                      tooltip: 'Profile',
                      onPressed: onAccountTap,
                    ),
                    if (isViewerAdmin)
                      PopupMenuButton<String>(
                        key: const ValueKey('game-trading-admin-menu'),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: _toolbarHeight,
                        ),
                        icon: Icon(
                          Icons.more_vert,
                          color: AppColors.textSecondary,
                          size: 22,
                        ),
                        onSelected: (value) {
                          switch (value) {
                            case 'logs':
                              onShowLogs?.call();
                            case 'end':
                              onEndGameFromMenu?.call();
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'logs',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.terminal,
                                  size: 18,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Show Logs',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'end',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.stop_circle_outlined,
                                  size: 18,
                                  color: AppColors.secondary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'End Game',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.secondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    else
                      const SizedBox(width: 36),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddTimeButton extends StatelessWidget {
  const _AddTimeButton({this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.1),
      shape: const CircleBorder(
        side: BorderSide(color: AppColors.outlineSubtle),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: const ValueKey('game-trading-add-time'),
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Icon(Icons.add, color: AppColors.textPrimary, size: 24),
        ),
      ),
    );
  }
}

