import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../widgets/partial_cancel_order_modal.dart';
import '../../widgets/pnl_calculator.dart';
import '../../widgets/price_chart.dart';
import '../../widgets/stat_tile.dart';
import '../../widgets/trade_logs_sheet.dart';
import 'order_book_widget.dart';
import 'trading_stat_format.dart';
import 'trading_view_data.dart';

/// Trading dashboard (C6). Layout follows
/// `design-uncertain-envelopes-2/admin_game_trading_dashboard_7/code.html`.
class GameTradingScreen extends StatefulWidget {
  const GameTradingScreen({
    super.key,
    required this.data,
    /// When set (live route), drives [PriceChart] / axis session length so the
    /// line extends as wall-clock session time advances without new trades.
    /// Tests and mocks omit this and use [GameTradingViewData.chartSessionElapsed].
    this.liveChartSessionElapsed,
    this.gameId = '',
    this.backNavigatesToHome = false,
    this.onShowLogs,
    this.onEndGameFromMenu,
    this.onAddTime,
    this.submitCancelOrderCommand,
    this.onSubmitNewOrder,
  });

  final GameTradingViewData data;

  final Duration? liveChartSessionElapsed;

  /// Routing id — used by the back button to return to the game lobby.
  final String gameId;

  /// When true (game already past trading), back goes to [AppRoutes.home]
  /// instead of the lobby — lobby/trading are invalid for post-trading games.
  final bool backNavigatesToHome;

  final VoidCallback? onShowLogs;
  final VoidCallback? onEndGameFromMenu;
  /// Called with the number of minutes chosen by the admin when they confirm
  /// the "Add Time" dialog.
  final void Function(int minutes)? onAddTime;

  /// Completes when the backend acks that a cancel / partial-cancel **command
  /// row** was created. Defaults to [defaultSubmitCancelOrderCommandAck] in
  /// state.
  final SubmitCancelOrderCommand? submitCancelOrderCommand;

  /// When set, new orders from [NewOrderModal] are submitted through the repo
  /// instead of optimistic local-only rows.
  final Future<void> Function(PersonalOrder draft)? onSubmitNewOrder;

  @override
  State<GameTradingScreen> createState() => _GameTradingScreenState();
}

class _GameTradingScreenState extends State<GameTradingScreen> {
  late List<PersonalOrder> _personalOrders;
  var _localOrderSeq = 0;

  /// Keeps [NewOrderModal]’s Last Traded Price line in sync while the dialog is open.
  late final ValueNotifier<double?> _marketPriceNotifier;

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

  /// Opens [PartialCancelOrderModal], then optimistic **Cancelling** until the
  /// command row is ack'd (and for full cancel until the order is cancelled).
  Future<void> _onCancellationRequested(
    BuildContext context,
    PersonalOrder order,
  ) async {
    if (!personalOrderCanCancel(order.status)) return;
    if (order.id.startsWith('cmd:')) return;
    if (order.quantityCurrent < 1) return;

    final notifier = ValueNotifier<int?>(order.quantityCurrent);

    try {
      final selected = await PartialCancelOrderModal.show(
        context,
        initialPending: order.quantityCurrent,
        pendingListenable: notifier,
        liveGameId: widget.gameId.isEmpty ? null : widget.gameId,
        liveOrderId: order.id,
      );

      if (!mounted || selected == null) return;

      setState(() => _pendingCancellationOrderIds.add(order.id));
      unawaited(
        _runCancelOrderCommandFlow(
          order.id,
          quantityToCancel: selected,
        ),
      );
    } finally {
      notifier.dispose();
    }
  }

  Future<void> _runCancelOrderCommandFlow(
    String orderId, {
    required int quantityToCancel,
  }) async {
    final customSubmit = widget.submitCancelOrderCommand;
    final pendingQty = () {
      for (final e in _personalOrders) {
        if (e.id == orderId) return e.quantityCurrent;
      }
      return quantityToCancel;
    }();

    Future<CancelOrderSubmitOutcome> submit() {
      if (customSubmit != null) {
        return customSubmit(
          orderId: orderId,
          quantityToCancel: quantityToCancel,
        );
      }
      return defaultSubmitCancelOrderCommandAck(
        orderId: orderId,
        quantityToCancel: quantityToCancel,
        pendingQuantityCurrent: pendingQty,
      );
    }

    try {
      final outcome = await submit().timeout(
        AppConstants.cancelOrderCommandAckTimeout,
      );
      if (!mounted) return;
      if (outcome == CancelOrderSubmitOutcome.partialCommandQueued) {
        setState(() => _pendingCancellationOrderIds.remove(orderId));
      }
    } on TimeoutException {
      if (!mounted) return;
      setState(() => _pendingCancellationOrderIds.remove(orderId));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(kCancelOrderCommandAckFailedMessage),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    } catch (_) {
      if (!mounted) return;
      setState(() => _pendingCancellationOrderIds.remove(orderId));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(kCancelOrderCommandAckFailedMessage),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!mounted) return;
    if (customSubmit == null) {
      final usedPartial =
          quantityToCancel < pendingQty;
      if (usedPartial) {
        _scheduleMockWorkerOrderPartiallyCancelled(orderId, quantityToCancel);
      } else {
        _scheduleMockWorkerOrderCancelled(orderId);
      }
    }
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

  void _scheduleMockWorkerOrderPartiallyCancelled(String id, int delta) {
    Future<void>.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      setState(() {
        _personalOrders = [
          for (final o in _personalOrders)
            if (o.id == id)
              o.copyWith(quantityCurrent: o.quantityCurrent - delta)
            else
              o,
        ];
      });
    });
  }

  Future<void> _openAddTimeDialog(BuildContext context) async {
    final minutes = await showDialog<int>(
      context: context,
      builder: (_) => const _AddTimeDialog(),
    );
    if (minutes != null) widget.onAddTime?.call(minutes);
  }

  void _openLogsSheet(BuildContext context) {
    TradeLogsSheet.show(
      context,
      logs: widget.data.tradeLogs,
      viewerPlayerId: widget.data.currentPlayerId,
    );
  }

  Future<void> _openNewOrder(BuildContext context) async {
    final created = await NewOrderModal.show(
      context,
      marketPrice: widget.data.marketPrice,
      marketPriceListenable: _marketPriceNotifier,
      bidAskMidpointListenable: _bidAskMidpointNotifier,
    );
    if (!mounted || created == null) return;
    if (widget.onSubmitNewOrder != null) {
      try {
        await widget.onSubmitNewOrder!(created);
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not submit order'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
      return;
    }
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
    final chartSessionElapsed =
        widget.liveChartSessionElapsed ?? data.chartSessionElapsed;
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
              onPressed: () => unawaited(_openNewOrder(context)),
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
              gameId: widget.gameId,
              isViewerAdmin: data.isViewerAdmin,
              backNavigatesToHome: widget.backNavigatesToHome,
              onShowLogs: () {
                widget.onShowLogs?.call();
                _openLogsSheet(context);
              },
              onEndGameFromMenu: widget.onEndGameFromMenu,
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
                    if (data.isTimed &&
                        (data.tradingDeadlineUtc != null ||
                            data.tradingTimeRemaining != null))
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Invisible left spacer balances the "+" on the
                          // right so the clock stays at true screen centre.
                          if (data.isViewerAdmin)
                            const SizedBox(width: AppSpacing.md + 40),
                          CountdownTimer(
                            key: const ValueKey('game-trading-countdown'),
                            deadlineUtc: data.tradingDeadlineUtc,
                            initialRemaining: data.tradingTimeRemaining ??
                                Duration.zero,
                            textStyle: AppTypography.timerDisplay,
                          ),
                          if (data.isViewerAdmin) ...[
                            const SizedBox(width: AppSpacing.md),
                            _AddTimeButton(
                              onPressed: () => _openAddTimeDialog(context),
                            ),
                          ],
                        ],
                      ),
                    if (data.isTimed &&
                        (data.tradingDeadlineUtc != null ||
                            data.tradingTimeRemaining != null))
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
                      chartSessionElapsed: chartSessionElapsed,
                      gameStartedAtUtc: data.gameStartedAtUtc,
                      axis: ChartAxisConfig.fromExecutionHistory(
                        sessionElapsed: chartSessionElapsed,
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
                      onCancellationRequested: (ctx, o) =>
                          unawaited(_onCancellationRequested(ctx, o)),
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

/// Sticky frosted header: back arrow (left), `TRADING WINDOW` (center),
/// three-dots menu (right, always visible).
class _TradingWindowHeader extends StatelessWidget {
  const _TradingWindowHeader({
    required this.gameId,
    required this.isViewerAdmin,
    this.backNavigatesToHome = false,
    required this.onShowLogs,
    this.onEndGameFromMenu,
  });

  final String gameId;
  final bool isViewerAdmin;
  final bool backNavigatesToHome;
  final VoidCallback onShowLogs;
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
                    // Back arrow → game lobby
                    IconButton(
                      key: const ValueKey('game-trading-back'),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: _toolbarHeight,
                      ),
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      tooltip: backNavigatesToHome ? 'Back to home' : 'Back to lobby',
                      onPressed: () {
                        if (backNavigatesToHome) {
                          context.go(AppRoutes.home);
                          return;
                        }
                        if (gameId.isNotEmpty) {
                          context.go(AppRoutes.gameLobby(gameId));
                        } else {
                          Navigator.of(context).maybePop();
                        }
                      },
                    ),
                    // Three-dots menu — always visible
                    PopupMenuButton<String>(
                      key: const ValueKey('game-trading-menu'),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: _toolbarHeight,
                      ),
                      icon: const Icon(
                        Icons.more_vert,
                        color: AppColors.textSecondary,
                        size: 22,
                      ),
                      onSelected: (value) {
                        switch (value) {
                          case 'logs':
                            onShowLogs();
                          case 'end':
                            onEndGameFromMenu?.call();
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'logs',
                          child: Row(
                            children: [
                              const Icon(
                                Icons.receipt_long_outlined,
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
                        if (isViewerAdmin)
                          PopupMenuItem(
                            value: 'end',
                            child: Row(
                              children: [
                                const Icon(
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
                    ),
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

// ---------------------------------------------------------------------------
// Add-time dialog
// ---------------------------------------------------------------------------

/// Step size and bounds for the add-time stepper.
abstract final class _AddTimeLimits {
  static const int step = 5;
  static const int min = 1;   // any natural number via keyboard
  static const int max = 600; // 10 hours
  static const int defaultValue = 5;
}

class _AddTimeDialog extends StatefulWidget {
  const _AddTimeDialog();

  @override
  State<_AddTimeDialog> createState() => _AddTimeDialogState();
}

class _AddTimeDialogState extends State<_AddTimeDialog> {
  int _minutes = _AddTimeLimits.defaultValue;
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${_AddTimeLimits.defaultValue}');
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) _commitFromField();
  }

  void _commitFromField() {
    final raw = _controller.text.trim();
    final parsed = int.tryParse(raw);
    if (parsed == null || parsed < _AddTimeLimits.min) {
      _setMinutes(_minutes); // revert to last valid
      return;
    }
    // Free-form entry: any natural number, just clamp to max.
    _setMinutes(parsed.clamp(_AddTimeLimits.min, _AddTimeLimits.max));
  }

  void _setMinutes(int value) {
    setState(() => _minutes = value.clamp(_AddTimeLimits.min, _AddTimeLimits.max));
    _controller.text = '$_minutes';
  }

  void _adjust(int delta) {
    final next = _minutes + delta * _AddTimeLimits.step;
    _setMinutes(next);
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: const BorderSide(color: AppColors.outlineSubtle),
      ),
      title: Text(
        'ADD TIME',
        style: AppTypography.microLabel.copyWith(
          color: AppColors.primary,
          fontSize: 13,
          letterSpacing: 1.4,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'DURATION (MINUTES)',
            style: AppTypography.microLabel.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _StepperSideButton(
                key: const ValueKey('add-time-minus'),
                icon: Icons.remove,
                onPressed: _minutes > _AddTimeLimits.min
                    ? () => _adjust(-1)
                    : null,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: TextField(
                  key: const ValueKey('add-time-value'),
                  controller: _controller,
                  focusNode: _focusNode,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: AppTypography.statValue.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.background,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.md,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: const BorderSide(color: AppColors.outline),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  onEditingComplete: _commitFromField,
                  onSubmitted: (_) => _commitFromField(),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              _StepperSideButton(
                key: const ValueKey('add-time-plus'),
                icon: Icons.add,
                onPressed: _minutes < _AddTimeLimits.max
                    ? () => _adjust(1)
                    : null,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Max 600 min (10 hours)',
            style: AppTypography.microLabel.copyWith(
              color: AppColors.textTertiary,
              fontSize: 10,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          key: const ValueKey('add-time-cancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'CANCEL',
            style: AppTypography.microLabel.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
        ),
        TextButton(
          key: const ValueKey('add-time-confirm'),
          onPressed: () => Navigator.of(context).pop(_minutes),
          child: Text(
            'ADD',
            style: AppTypography.microLabel.copyWith(
              color: AppColors.primary,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Add-time circular "+" button
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Stepper ± button shared by _AddTimeDialog
// ---------------------------------------------------------------------------

class _StepperSideButton extends StatelessWidget {
  const _StepperSideButton({
    super.key,
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Material(
      color: AppColors.surfaceContainer,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(
            icon,
            color: enabled ? AppColors.textPrimary : AppColors.textDisabled,
          ),
        ),
      ),
    );
  }
}

