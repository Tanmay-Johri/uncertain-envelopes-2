import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/trading/envelope_assumption_bounds.dart';
import '../../core/trading/envelope_value_parse.dart';
import '../../core/trading/projected_pnl.dart';
import '../screens/trading/trading_stat_format.dart';

/// PnL calculator: adjustable envelope assumption, projected PnL (B7 formula).
class PnlCalculator extends StatefulWidget {
  const PnlCalculator({
    super.key,
    required this.marketPrice,
    required this.deltaCash,
    required this.deltaEnvelopes,
  });

  final double marketPrice;
  final double deltaCash;
  final double deltaEnvelopes;

  @override
  State<PnlCalculator> createState() => _PnlCalculatorState();
}

class _PnlCalculatorState extends State<PnlCalculator> {
  late double _envelope;
  late double _minB;
  late double _maxB;
  late final TextEditingController _assumptionField;
  final FocusNode _assumptionFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _envelope = widget.marketPrice;
    final b = envelopeSliderBoundsForCenter(_envelope);
    _minB = b.min;
    _maxB = b.max;
    _assumptionField = TextEditingController(
      text: formatAssumptionInputNumber(_envelope),
    );
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
    super.dispose();
  }

  void _recenterToMarket() {
    _envelope = widget.marketPrice;
    final b = envelopeSliderBoundsForCenter(_envelope);
    _minB = b.min;
    _maxB = b.max;
    _assumptionField.text = formatAssumptionInputNumber(_envelope);
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
      _assumptionField.text = formatAssumptionInputNumber(_envelope);
    });
  }

  void _onAssumptionSubmitted() {
    if (!mounted) {
      return;
    }
    final parsed = tryParseAssumptionValue(_assumptionField.text);
    if (parsed == null) {
      setState(() {
        _assumptionField.text = formatAssumptionInputNumber(_envelope);
      });
      return;
    }
    setState(() {
      _envelope = parsed;
      if (!valueFitsInBounds(parsed, _minB, _maxB)) {
        _setBoundsForCenter(parsed);
      }
      _assumptionField.text = formatAssumptionInputNumber(_envelope);
    });
  }

  @override
  Widget build(BuildContext context) {
    final pnl = projectedPnlUsd(
      widget.deltaCash,
      widget.deltaEnvelopes,
      _envelope,
    );
    final pnlColor = pnl == 0
        ? AppColors.textTertiary
        : (pnl > 0 ? AppColors.primary : AppColors.secondary);

    return Semantics(
      key: const ValueKey('trading-pnl-section'),
      container: true,
      label: 'PnL calculator',
      child: Material(
        color: AppColors.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: AppColors.outline),
        ),
        clipBehavior: Clip.antiAlias,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: true,
            tilePadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 2,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            title: Text(
              'PnL calculator',
              style: AppTypography.bodySmall.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
                color: AppColors.textTertiary,
              ),
            ),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Envelope Value',
                                style: AppTypography.bodySmall.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textTertiary,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ),
                            Text(
                              formatAssumptionText(_envelope),
                              key: const ValueKey('trading-pnl-envelope-label'),
                              style: AppTypography.monoSmall.copyWith(
                                fontSize: 10,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
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
                              tooltip: 'Use market price',
                              icon: Icon(
                                Icons.refresh,
                                size: 18,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            const Text(
                              r'$',
                              style: AppTypography.monoSmall,
                            ),
                            const SizedBox(width: 2),
                            Expanded(
                              child: TextField(
                                key: const ValueKey('trading-pnl-envelope-input'),
                                controller: _assumptionField,
                                focusNode: _assumptionFocus,
                                keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true,
                                  signed: true,
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[-0-9.]'),
                                  ),
                                ],
                                onEditingComplete: _onAssumptionSubmitted,
                                onSubmitted: (_) => _onAssumptionSubmitted,
                                style: AppTypography.monoSmall,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Slider(
                          value: _clampedToSlider,
                          min: _slMin,
                          max: _slMax,
                          onChanged: _onSliderChanged,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              formatAssumptionText(_slMin),
                              key: const ValueKey('trading-pnl-range-min'),
                              style: AppTypography.bodySmall.copyWith(
                                fontSize: 10,
                                color: AppColors.textTertiary,
                                fontFamily: 'monospace',
                              ),
                            ),
                            Text(
                              formatAssumptionText(_slMax),
                              key: const ValueKey('trading-pnl-range-max'),
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
                  const SizedBox(width: AppSpacing.md),
                  Container(
                    width: 1,
                    height: 64,
                    color: AppColors.outline,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'PROJECTED PNL',
                          key: const ValueKey('trading-pnl-projection-label'),
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
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
