import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/trading/envelope_assumption_bounds.dart';
import '../../core/trading/envelope_value_parse.dart';
import '../../core/trading/projected_pnl.dart';
import '../screens/trading/trading_stat_format.dart';

/// Default envelope center when [marketPrice] is unknown (slider uses [envelopeSliderBoundsForCenter]).
const double _kEnvelopeCenterWhenNoMarketPrice = 100.0;

/// PnL calculator: adjustable envelope assumption, projected PnL (B7 formula).
class PnlCalculator extends StatefulWidget {
  const PnlCalculator({
    super.key,
    required this.marketPrice,
    required this.deltaCash,
    required this.deltaEnvelopes,
  });

  /// `null` before any reference price exists — internal slider recenters to
  /// [_kEnvelopeCenterWhenNoMarketPrice].
  final double? marketPrice;
  final double deltaCash;
  final double deltaEnvelopes;

  @override
  State<PnlCalculator> createState() => _PnlCalculatorState();
}

class _PnlCalculatorState extends State<PnlCalculator> {
  final ExpansibleController _pnlExpansionController = ExpansibleController();

  late double _envelope;
  late double _minB;
  late double _maxB;
  late final TextEditingController _assumptionField;
  final FocusNode _assumptionFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _envelope = widget.marketPrice ?? _kEnvelopeCenterWhenNoMarketPrice;
    final b = envelopeSliderBoundsForCenter(_envelope);
    _minB = b.min;
    _maxB = b.max;
    _assumptionField = TextEditingController();
    _syncEnvelopeFieldDisplay();
    _assumptionFocus.addListener(_onAssumptionFocusChange);
  }

  void _onAssumptionFocusChange() {
    if (!_assumptionFocus.hasFocus) {
      _onAssumptionSubmitted();
    }
  }

  @override
  void didUpdateWidget(covariant PnlCalculator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.marketPrice != widget.marketPrice) {
      setState(_recenterToMarket);
    }
  }

  @override
  void dispose() {
    _assumptionFocus.removeListener(_onAssumptionFocusChange);
    _assumptionField.dispose();
    _assumptionFocus.dispose();
    _pnlExpansionController.dispose();
    super.dispose();
  }

  void _syncEnvelopeFieldDisplay() {
    final t = formatEnvelopeUsdField(_envelope);
    _assumptionField.value = TextEditingValue(
      text: t,
      selection: TextSelection.collapsed(offset: t.length),
    );
  }

  void _recenterToMarket() {
    _envelope = widget.marketPrice ?? _kEnvelopeCenterWhenNoMarketPrice;
    final b = envelopeSliderBoundsForCenter(_envelope);
    _minB = b.min;
    _maxB = b.max;
    _syncEnvelopeFieldDisplay();
  }

  void _setBoundsForCenter(double center) {
    final b = envelopeSliderBoundsForCenter(center);
    _minB = b.min;
    _maxB = b.max;
  }

  /// Slider endpoints when the stored logical range is degenerate (e.g. v = 0).
  double get _slMin => (_minB < _maxB) ? _minB : 0.0;
  double get _slMax => (_minB < _maxB) ? _maxB : 1.0;

  double get _clampedToSlider => _envelope.clamp(_slMin, _slMax);

  void _onSliderChanged(double v) {
    setState(() {
      _envelope = v;
      if (!valueFitsInBounds(_envelope, _minB, _maxB)) {
        _setBoundsForCenter(_envelope);
      }
      _syncEnvelopeFieldDisplay();
    });
  }

  void _onAssumptionSubmitted() {
    if (!mounted) {
      return;
    }
    final parsed = tryParseAssumptionValue(_assumptionField.text);
    if (parsed == null) {
      setState(_syncEnvelopeFieldDisplay);
      return;
    }
    setState(() {
      _envelope = parsed;
      if (!valueFitsInBounds(parsed, _minB, _maxB)) {
        _setBoundsForCenter(parsed);
      }
      _syncEnvelopeFieldDisplay();
    });
  }

  void _setEnvelopeToBreakEven() {
    final target = envelopeValueForZeroProjectedPnl(
      widget.deltaCash,
      widget.deltaEnvelopes,
    );
    if (target == null) return;
    setState(() {
      _envelope = target;
      if (!valueFitsInBounds(_envelope, _minB, _maxB)) {
        _setBoundsForCenter(_envelope);
      }
      _syncEnvelopeFieldDisplay();
    });
  }

  @override
  Widget build(BuildContext context) {
    final breakEvenEnvelope = envelopeValueForZeroProjectedPnl(
      widget.deltaCash,
      widget.deltaEnvelopes,
    );
    final canBreakEven = breakEvenEnvelope != null;

    final pnl = projectedPnlUsd(
      widget.deltaCash,
      widget.deltaEnvelopes,
      _envelope,
    );
    final pnlColor = pnl == 0
        ? AppColors.textTertiary
        : (pnl > 0 ? AppColors.primary : AppColors.secondary);

    final headerFill = Color.lerp(
      AppColors.background,
      AppColors.surfaceContainer,
      0.2,
    )!;

    return Semantics(
      key: const ValueKey('trading-pnl-section'),
      container: true,
      label: 'PnL Calculator',
      child: Material(
        color: AppColors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: AppColors.outline),
        ),
        clipBehavior: Clip.antiAlias,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            controller: _pnlExpansionController,
            initiallyExpanded: true,
            showTrailingIcon: false,
            tilePadding: EdgeInsets.zero,
            collapsedBackgroundColor: Colors.transparent,
            backgroundColor: Colors.transparent,
            collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
            shape: const RoundedRectangleBorder(side: BorderSide.none),
            title: ListenableBuilder(
              listenable: _pnlExpansionController,
              builder: (context, _) {
                return ColoredBox(
                  color: headerFill,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'PnL Calculator',
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        AnimatedRotation(
                          turns: _pnlExpansionController.isExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeIn,
                          child: Icon(
                            Icons.expand_more,
                            size: 22,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            childrenPadding: const EdgeInsets.only(bottom: AppSpacing.lg),
            children: [
              Divider(
                height: 1,
                thickness: 1,
                color: AppColors.textDisabled.withValues(alpha: 0.55),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  0,
                ),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Text(
                                      'ENVELOPE VALUE',
                                      style: AppTypography.bodySmall.copyWith(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.2,
                                        color: AppColors.textTertiary,
                                      ),
                                    ),
                                  ),
                                  IntrinsicWidth(
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        minWidth: 56,
                                      ),
                                      child: TextField(
                                        key: const ValueKey(
                                          'trading-pnl-envelope-input',
                                        ),
                                        controller: _assumptionField,
                                        focusNode: _assumptionFocus,
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                              signed: true,
                                            ),
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(
                                            RegExp(r'[\$\-0-9.,]'),
                                          ),
                                        ],
                                        onEditingComplete:
                                            _onAssumptionSubmitted,
                                        onSubmitted: (_) =>
                                            _onAssumptionSubmitted,
                                        style: AppTypography.monoSmall.copyWith(
                                          fontSize: 10,
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w700,
                                          fontFeatures: const [
                                            FontFeature.tabularFigures(),
                                          ],
                                        ),
                                        decoration: const InputDecoration(
                                          isDense: true,
                                          isCollapsed: true,
                                          contentPadding: EdgeInsets.zero,
                                          border: InputBorder.none,
                                        ),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    key: const ValueKey('trading-pnl-zero-pnl'),
                                    onPressed:
                                        canBreakEven ? _setEnvelopeToBreakEven : null,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 32,
                                      minHeight: 32,
                                    ),
                                    tooltip: canBreakEven
                                        ? 'Set envelope for \$0 projected PnL'
                                        : 'Projected PnL does not depend on envelope value',
                                    icon: Icon(
                                      Icons.refresh,
                                      size: 18,
                                      color: canBreakEven
                                          ? AppColors.textDisabled
                                          : AppColors.textDisabled
                                              .withValues(alpha: 0.35),
                                    ),
                                  ),
                                  IconButton(
                                    key: const ValueKey('trading-pnl-reset'),
                                    onPressed: () {
                                      setState(_recenterToMarket);
                                    },
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 32,
                                      minHeight: 32,
                                    ),
                                    tooltip: 'Latest market price',
                                    icon: Icon(
                                      Icons.show_chart,
                                      size: 18,
                                      color: AppColors.textDisabled,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: AppColors.primary,
                                  inactiveTrackColor: AppColors.textTertiary
                                      .withValues(alpha: 0.45),
                                  thumbColor: AppColors.primary,
                                  trackHeight: 4,
                                  // Full-width track so it lines up with the $min / $max row
                                  // (default horizontal inset is half the thumb size).
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                ),
                                child: Slider(
                                  value: _clampedToSlider,
                                  min: _slMin,
                                  max: _slMax,
                                  onChanged: _onSliderChanged,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    formatAssumptionText(_slMin),
                                    key: const ValueKey(
                                      'trading-pnl-range-min',
                                    ),
                                    style: AppTypography.bodySmall.copyWith(
                                      fontSize: 10,
                                      color: AppColors.textTertiary,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                  Text(
                                    formatAssumptionText(_slMax),
                                    key: const ValueKey(
                                      'trading-pnl-range-max',
                                    ),
                                    style: AppTypography.bodySmall.copyWith(
                                      fontSize: 10,
                                      color: AppColors.textTertiary,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(
                                color: AppColors.textDisabled.withValues(
                                  alpha: 0.55,
                                ),
                                width: 1,
                              ),
                            ),
                          ),
                          padding: const EdgeInsets.only(left: AppSpacing.md),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'PROJECTED PNL',
                                  key: const ValueKey(
                                    'trading-pnl-projection-label',
                                  ),
                                  style: AppTypography.bodySmall.copyWith(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.2,
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  formatProjectedPnl(pnl),
                                  key: const ValueKey('trading-pnl-projected'),
                                  style: AppTypography.monoLarge.copyWith(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: pnlColor,
                                    height: 1.0,
                                    letterSpacing: -0.2,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
