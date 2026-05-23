import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/results/game_results_envelope_edit.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/trading/usd_limit_price_display.dart';
import '../trading/trading_stat_format.dart';
import '../../widgets/app_bottom_navigation_bar.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/game_result_player_card.dart';
import '../../widgets/neon_button.dart';
import 'results_view_data.dart';

const _kEnvelopeReconcileTotal = Duration(milliseconds: 2500);
const _kEnvelopePollInterval = Duration(milliseconds: 200);

/// Game-final results dashboard (plan **C7**).
class GameResultsScreen extends StatefulWidget {
  const GameResultsScreen({
    super.key,
    required this.gameId,
    required this.data,
    this.onUpdateEnvelopePrice,
    this.pollCommittedEnvelopePrice,
    this.onEndGame,
  });

  final String gameId;
  final GameResultsViewData data;

  final Future<void> Function(double? envelopePriceUsd)? onUpdateEnvelopePrice;

  /// When null, skips post-update reconcile (still runs [onUpdateEnvelopePrice]).
  final Future<double?> Function()? pollCommittedEnvelopePrice;

  final void Function({required bool discardBecauseNoPrice})? onEndGame;

  @override
  State<GameResultsScreen> createState() => _GameResultsScreenState();
}

class _GameResultsScreenState extends State<GameResultsScreen> {
  late final TextEditingController _controller;
  late final FocusNode _focus;
  var _busy = false;
  var _disposed = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: envelopePriceSeedForEditing(widget.data.envelopePriceUsd),
    );
    _focus = FocusNode(debugLabel: 'results-envelope');
    _focus.addListener(_onEnvelopeFocusChanged);
    _controller.addListener(_onFieldChanged);
  }

  void _onEnvelopeFocusChanged() {
    if (!_focus.hasFocus) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_focus.hasFocus) return;
      final len = _controller.text.length;
      _controller.selection = TextSelection.collapsed(offset: len);
    });
  }

  void _onFieldChanged() => setState(() {});

  @override
  void didUpdateWidget(covariant GameResultsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data.envelopePriceUsd != widget.data.envelopePriceUsd) {
      final seed =
          envelopePriceSeedForEditing(widget.data.envelopePriceUsd);
      if (!_focus.hasFocus) {
        _controller
          ..removeListener(_onFieldChanged)
          ..text = seed
          ..addListener(_onFieldChanged);
      }
      setState(() {});
    }
    if (!oldWidget.data.gameEnded && widget.data.gameEnded) {
      _focus.unfocus();
    }
  }

  double? _parsed() => parseEnvelopePriceUsd(_controller.text);

  String _heroLine() {
    if (!widget.data.isViewerAdmin) {
      final v = widget.data.envelopePriceUsd;
      if (v == null) return kUnsetUsdLine;
      return formatUsdLimitForActiveOrder(v);
    }
    // Admin: empty draft (after blur) shows unset — do not fall back to committed price.
    final raw = _controller.text.trim();
    if (raw.isEmpty) {
      return kUnsetUsdLine;
    }
    final parsed = _parsed();
    if (parsed != null) {
      return formatUsdLimitForActiveOrder(parsed);
    }
    return kUnsetUsdLine;
  }

  bool get _canSubmitCommittedEnvelope {
    final raw = _controller.text.trim();
    if (raw.isEmpty) {
      return widget.data.envelopePriceUsd != null;
    }
    return _parsed() != null;
  }

  bool get _updateEnabled =>
      widget.data.isViewerAdmin &&
      !_busy &&
      !widget.data.gameEnded &&
      _canSubmitCommittedEnvelope &&
      widget.onUpdateEnvelopePrice != null;

  bool _envelopeSnapshotsMatch(double? committed, double? expected) {
    if (committed == null && expected == null) return true;
    if (committed == null || expected == null) return false;
    return (committed - expected).abs() < 1e-6;
  }

  @override
  void dispose() {
    _disposed = true;
    _focus.removeListener(_onEnvelopeFocusChanged);
    _controller.removeListener(_onFieldChanged);
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _runReconcile(double? expectedUsd) async {
    final poll = widget.pollCommittedEnvelopePrice;
    if (poll == null || !mounted) return;

    // Iteration cap (not wall-clock): `DateTime.now()` does not track
    // `tester.pump(Duration)`, so tests would spin until real time passed
    // or leave `Future.delayed` timers pending.
    final maxIterations = (_kEnvelopeReconcileTotal.inMilliseconds /
            _kEnvelopePollInterval.inMilliseconds)
        .ceil();
    for (var i = 0; i < maxIterations && !_disposed && mounted; i++) {
      await Future<void>.delayed(_kEnvelopePollInterval);
      if (_disposed || !mounted) return;
      try {
        final v = await poll();
        if (_disposed || !mounted) return;
        if (_envelopeSnapshotsMatch(v, expectedUsd)) return;
      } catch (_) {
        // ignore; keep polling until iteration budget is exhausted
      }
    }
    if (!mounted || _disposed) return;
    await _revertCommittedUi(
      'Could not confirm envelope price against the server. Reverted.',
    );
  }

  Future<void> _revertCommittedUi(String message) async {
    final seed =
        envelopePriceSeedForEditing(widget.data.envelopePriceUsd);
    setState(() {
      _busy = false;
      _controller.removeListener(_onFieldChanged);
      _controller.text = seed;
      _controller.addListener(_onFieldChanged);
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _onUpdateTap() async {
    if (!_updateEnabled || _busy) return;
    final submit = widget.onUpdateEnvelopePrice;
    if (submit == null) return;

    final trimmed = _controller.text.trim();
    final double? nextEnvelope = trimmed.isEmpty ? null : _parsed();
    if (trimmed.isNotEmpty && nextEnvelope == null) return;

    setState(() => _busy = true);
    try {
      await submit(nextEnvelope);
    } catch (_) {
      if (!mounted) return;
      await _revertCommittedUi(
        'Envelope price could not be updated. Try again.',
      );
      return;
    }

    await _runReconcile(nextEnvelope);
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _maybeEndGame() async {
    if (widget.data.gameEnded) return;
    final hasCommittedEnvelope = widget.data.envelopePriceUsd != null;
    final ok = await ConfirmationDialog.show(
      context,
      title: 'End game',
      uppercaseActionLabels: false,
      message: hasCommittedEnvelope
          ? 'Are you sure? You won’t be able to change the envelope price later.'
          : 'Are you sure you want to discard this game without entering the price?',
      confirmLabel: 'End',
      cancelLabel: 'Back',
      destructive: true,
    );
    if (ok != true || !mounted) return;
    widget.onEndGame?.call(
      discardBecauseNoPrice: !hasCommittedEnvelope,
    );
  }

  void _branchNav(int shellIndex, BuildContext navContext) {
    switch (shellIndex) {
      case 0:
        navContext.go(AppRoutes.home);
        return;
      case 1:
        navContext.go(AppRoutes.create);
        return;
      default:
        navContext.go(AppRoutes.orders);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final admin = data.isViewerAdmin;

    return Scaffold(
      key: const ValueKey('game-results-scaffold'),
      backgroundColor: AppColors.background,
      bottomNavigationBar: Material(
        color: AppColors.background,
        child: AppBottomNavigationBar(
          visualSelectionEnabled: false,
          currentIndex: 0,
          onTap: (ix) => _branchNav(ix, context),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ResultsStickyHeader(
            gameId: widget.gameId,
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  top: AppSpacing.lg,
                  bottom: AppSpacing.sectionGap + 96,
                ),
                child: ConstrainedBox(
                  constraints:
                      BoxConstraints(minHeight: MediaQuery.sizeOf(context).height * 0.5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        data.gameTitle,
                        textAlign: TextAlign.center,
                        style: AppTypography.sectionHeader.copyWith(fontSize: 18),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      Text(
                        'ENVELOPE PRICE',
                        textAlign: TextAlign.center,
                        style: AppTypography.label.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Align(
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width > 560
                              ? 400
                              : double.infinity,
                          child: admin
                              ? _AdminEnvelopeHero(
                                  focusNode: _focus,
                                  controller: _controller,
                                  displayHeroLine: _heroLine(),
                                  enabled: !_busy && !data.gameEnded,
                                )
                              : Text(
                                  _heroLine(),
                                  textAlign: TextAlign.center,
                                  style: AppTypography.heroHeadline.copyWith(
                                    fontFamily: AppFontFamilies.mono,
                                    fontSize: 54,
                                    color: AppColors.primary,
                                  ),
                                ),
                        ),
                      ),
                      if (admin) ...[
                        const SizedBox(height: AppSpacing.lg),
                        NeonButton(
                          key: const ValueKey('game-results-update-envelope'),
                          label: 'UPDATE FOR EVERYONE',
                          variant: NeonButtonVariant.outline,
                          expand: true,
                          onPressed: _updateEnabled ? () => _onUpdateTap() : null,
                        ),
                      ],
                      const SizedBox(height: AppSpacing.sectionGap),
                      Container(height: 1, color: AppColors.outlineSubtle),
                      const SizedBox(height: AppSpacing.sectionGap),
                      Text(
                        'RESULTS',
                        style: AppTypography.label.copyWith(
                          color: AppColors.primary,
                          fontSize: 11,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      for (final p in data.players) ...[
                        GameResultPlayerCard(
                          displayName: p.displayName,
                          avatarInitials: p.avatarInitials,
                          deltaCash: p.deltaCash,
                          deltaEnvelopes: p.deltaEnvelopes,
                          pnl: p.pnl,
                          highlightBorder:
                              p.playerId == data.highlightPlayerId,
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      if (admin && widget.onEndGame != null) ...[
                        const SizedBox(height: AppSpacing.xxl),
                        if (data.gameEnded)
                          NeonButton(
                            key: const ValueKey('game-results-end-game-ended'),
                            label: 'GAME ENDED',
                            variant: NeonButtonVariant.outline,
                            expand: true,
                            onPressed: null,
                          )
                        else
                          NeonButton(
                            key: const ValueKey('game-results-end-game'),
                            label: 'END GAME',
                            variant: NeonButtonVariant.outlineDanger,
                            expand: true,
                            onPressed: _busy ? null : () => _maybeEndGame(),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultsStickyHeader extends StatelessWidget {
  const _ResultsStickyHeader({required this.gameId});

  final String gameId;

  static const double _edgeSlot = 48;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.96),
            border: const Border(
              bottom: BorderSide(color: AppColors.outlineSubtle),
            ),
          ),
          padding: EdgeInsets.only(
            top: MediaQuery.paddingOf(context).top + 8,
            left: 4,
            right: 8,
            bottom: 12,
          ),
          child: Row(
            children: [
              SizedBox(
                width: _edgeSlot,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Back to home',
                    icon: Icon(
                      Icons.arrow_back_ios_new,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    onPressed: () => context.go(AppRoutes.home),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'UNCERTAIN ENVELOPES',
                  textAlign: TextAlign.center,
                  style: AppTypography.brandHeader,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: _edgeSlot),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminEnvelopeHero extends StatelessWidget {
  const _AdminEnvelopeHero({
    required this.focusNode,
    required this.controller,
    required this.displayHeroLine,
    required this.enabled,
  });

  final FocusNode focusNode;
  final TextEditingController controller;
  final String displayHeroLine;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final monoStyle = TextStyle(
      fontFamily: AppFontFamilies.mono,
      fontWeight: FontWeight.w700,
      fontSize: 54,
      color: AppColors.primary,
      height: 1.05,
      shadows: const [
        Shadow(
          blurRadius: 15,
          color: Color.fromRGBO(64, 243, 32, 0.25),
        ),
      ],
    );

    final borderColor = Colors.white.withValues(alpha: focusNode.hasFocus ? 0.12 : 0.05);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: AnimatedBuilder(
        animation: Listenable.merge([focusNode, controller]),
        builder: (context, _) {
          final showOverlay = enabled && !focusNode.hasFocus;

          final field = Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
            child: Opacity(
              opacity: showOverlay ? 0 : 1,
              child: TextField(
                focusNode: focusNode,
                controller: controller,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true, signed: true),
                textAlign: TextAlign.center,
                style: monoStyle.copyWith(height: 1.1),
                cursorColor: AppColors.primary,
                enabled: enabled,
                onTap: () {
                  final len = controller.text.length;
                  controller.selection = TextSelection.collapsed(offset: len);
                },
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^-?\d*\.?\d{0,5}$'),
                  ),
                ],
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isCollapsed: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          );

          return Container(
            key: const ValueKey('game-results-envelope-hero'),
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            decoration: BoxDecoration(
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                field,
                if (showOverlay)
                  Positioned.fill(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: enabled ? () => focusNode.requestFocus() : null,
                        customBorder: const RoundedRectangleBorder(),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            child: Semantics(
                              label: 'Envelope price, tap to edit',
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  displayHeroLine,
                                  textAlign: TextAlign.center,
                                  style: monoStyle,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
