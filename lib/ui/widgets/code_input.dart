import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Five single-character boxes for a game joining code (A–Z, 0–9).
///
/// - Typing advances focus forward.
/// - Pasting a multi-character string starting at the focused cell fills
///   forward across the remaining cells (max five total).
/// - Backspace on an empty cell moves focus to the previous cell and clears
///   that character.
/// - Letters are forced to uppercase; other characters are dropped.
class CodeInput extends StatefulWidget {
  const CodeInput({
    super.key,
    this.initialCode,
    this.onChanged,
    this.onCompleted,
    this.autofocus = false,
  });

  /// Seed value; only alphanumerics are kept, uppercased, max five used.
  final String? initialCode;

  /// Concatenation of the five cells (each zero or one character).
  final ValueChanged<String>? onChanged;

  /// Fires once when all five cells become non-empty.
  final ValueChanged<String>? onCompleted;

  final bool autofocus;

  @override
  State<CodeInput> createState() => _CodeInputState();
}

class _CodeInputState extends State<CodeInput> {
  static const int _cells = 5;

  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  bool _wasComplete = false;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_cells, (_) => TextEditingController());
    _focusNodes = List.generate(
      _cells,
      (i) => FocusNode(debugLabel: 'code_cell_$i'),
    );
    _applySeed(_normalize(widget.initialCode ?? ''));
    _wasComplete = _isComplete();
    HardwareKeyboard.instance.addHandler(_handleHardwareKey);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onChanged?.call(_fullCode());
      if (widget.autofocus) {
        _focusNodes[0].requestFocus();
      }
    });
  }

  @override
  void didUpdateWidget(covariant CodeInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCode != oldWidget.initialCode) {
      _applySeed(_normalize(widget.initialCode ?? ''));
      _wasComplete = _isComplete();
      widget.onChanged?.call(_fullCode());
    }
  }

  void _applySeed(String seed) {
    for (var i = 0; i < _cells; i++) {
      _controllers[i].text = i < seed.length ? seed[i] : '';
    }
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleHardwareKey);
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String _normalize(String raw) {
    return raw.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  }

  String _fullCode() {
    return _controllers.map((c) => c.text.isEmpty ? '' : c.text[0]).join();
  }

  bool _isComplete() {
    return _controllers.every((c) => c.text.isNotEmpty);
  }

  /// Backspace when the current cell is empty: move to previous and clear it.
  bool _handleHardwareKey(KeyEvent event) {
    if (event is! KeyDownEvent) {
      return false;
    }
    if (event.logicalKey != LogicalKeyboardKey.backspace) {
      return false;
    }
    for (var i = 0; i < _cells; i++) {
      if (!_focusNodes[i].hasFocus) continue;
      if (_controllers[i].text.isNotEmpty) {
        return false;
      }
      if (i <= 0) {
        return false;
      }
      _focusNodes[i - 1].requestFocus();
      _controllers[i - 1].clear();
      setState(() {});
      _wasComplete = _isComplete();
      widget.onChanged?.call(_fullCode());
      return true;
    }
    return false;
  }

  void _onCellChanged(int index, String raw) {
    final upper = _normalize(raw);
    if (upper.length > 1) {
      _applyFromIndex(index, upper);
      return;
    }
    final ch = upper.isEmpty ? '' : upper[0];
    final cur = _controllers[index].text;
    if (cur != ch) {
      _controllers[index].value = TextEditingValue(
        text: ch,
        selection: TextSelection.collapsed(offset: ch.length),
      );
    }
    if (ch.isNotEmpty && index < _cells - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    setState(() {});
    final complete = _isComplete();
    final code = _fullCode();
    widget.onChanged?.call(code);
    if (complete && !_wasComplete) {
      widget.onCompleted?.call(code);
    }
    _wasComplete = complete;
  }

  void _applyFromIndex(int startIndex, String chars) {
    final clean = _normalize(chars);
    if (clean.isEmpty) return;
    final maxWrite = _cells - startIndex;
    final slice = clean.length <= maxWrite
        ? clean
        : clean.substring(0, maxWrite);
    for (var w = 0; w < slice.length; w++) {
      _controllers[startIndex + w].text = slice[w];
    }
    final last = startIndex + slice.length - 1;
    _focusNodes[last.clamp(0, _cells - 1)].requestFocus();
    setState(() {});
    final complete = _isComplete();
    final code = _fullCode();
    widget.onChanged?.call(code);
    if (complete && !_wasComplete) {
      widget.onCompleted?.call(code);
    }
    _wasComplete = complete;
  }

  static const TextStyle _cellStyleBase = AppTypography.statValue;

  /// Must match [NeonButton] default height when `dense` is false (see
  /// `neon_button.dart`). Max digit box side is 2× this.
  static const double _enterGameButtonHeight = 48;
  static const double _maxSquareSide = 2 * _enterGameButtonHeight;

  static const double _preferredGap = AppSpacing.md;
  static const double _minGap = 8;

  TextStyle _cellStyleForSide(double side) {
    final fontSize = math.min(40.0, math.max(14.0, side * 0.58));
    return _cellStyleBase.copyWith(
      fontSize: fontSize,
      letterSpacing: 0,
      height: 1,
    );
  }

  /// Slight upward bias so the caret reads optically centered in the square
  /// (baseline/strut math tends to sit a hair low with tall [cursorHeight]).
  static const TextAlignVertical _cellAlignVertical =
      TextAlignVertical(y: -0.07);

  /// Matches [_cellStyleForSide] so the line box centers in a tall cell.
  StrutStyle _cellStrutForSide(double side) {
    final fontSize = math.min(40.0, math.max(14.0, side * 0.58));
    return StrutStyle(
      fontFamily: _cellStyleBase.fontFamily,
      fontSize: fontSize,
      fontWeight: _cellStyleBase.fontWeight,
      height: 1,
      leading: 0,
      forceStrutHeight: true,
    );
  }

  /// Returns `(side, gap)` so `5*side + 4*gap == w`, `side <= maxSide`, and
  /// gaps absorb extra width instead of growing squares past the cap.
  (double, double) _squareLayout(double w) {
    final gapCount = _cells - 1;
    var gap = _preferredGap;
    var side = (w - gapCount * gap) / _cells;
    if (side <= 0) {
      return (0, gap);
    }
    if (side > _maxSquareSide) {
      side = _maxSquareSide;
      gap = (w - _cells * side) / gapCount;
      if (gap < _minGap) {
        gap = _minGap;
        side = (w - gapCount * gap) / _cells;
        if (side > _maxSquareSide) {
          side = _maxSquareSide;
          gap = (w - _cells * side) / gapCount;
        }
      }
    }
    return (side, gap);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        if (!w.isFinite || w <= 0) {
          return const SizedBox(height: 48);
        }
        final (side, gap) = _squareLayout(w);
        if (side <= 0) {
          return const SizedBox(height: 48);
        }

        final radius = BorderRadius.circular(AppSpacing.sm);
        final fieldTheme = theme.copyWith(
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          inputDecorationTheme: theme.inputDecorationTheme.copyWith(
            contentPadding: EdgeInsets.zero,
            isDense: true,
          ),
        );

        final children = <Widget>[];
        for (var i = 0; i < _cells; i++) {
          if (i > 0) {
            children.add(SizedBox(width: gap));
          }
          children.add(
            ListenableBuilder(
              listenable: _focusNodes[i],
              builder: (context, _) {
                final focused = _focusNodes[i].hasFocus;
                return ClipRRect(
                  borderRadius: radius,
                  clipBehavior: Clip.hardEdge,
                  child: SizedBox.square(
                    dimension: side,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        // Whole square should read as “the field” while focused,
                        // not only the thin editable/caret strip on top of it.
                        color: focused
                            ? Color.alphaBlend(
                                AppColors.primary.withValues(alpha: 0.14),
                                AppColors.surfaceContainer,
                              )
                            : AppColors.surfaceContainer,
                        borderRadius: radius,
                        border: Border.all(
                          color: focused
                              ? AppColors.primary
                              : AppColors.outline,
                          width: focused ? 2 : 1,
                        ),
                      ),
                      child: Theme(
                        data: fieldTheme,
                        child: TextField(
                          key: ValueKey('code_cell_$i'),
                          controller: _controllers[i],
                          focusNode: _focusNodes[i],
                          autofocus: widget.autofocus && i == 0,
                          textAlign: TextAlign.center,
                          textAlignVertical: _cellAlignVertical,
                          expands: true,
                          minLines: null,
                          maxLines: null,
                          style: _cellStyleForSide(side),
                          strutStyle: _cellStrutForSide(side),
                          cursorColor: AppColors.primary,
                          cursorWidth: 2.5,
                          cursorHeight: math.min(44, side * 0.72),
                          // On web, [InputDecoration] fill/outline still tracks
                          // intrinsic text height. Paint the square here instead
                          // and keep the field visually transparent.
                          decoration: const InputDecoration(
                            isDense: true,
                            filled: false,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            focusedErrorBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          textCapitalization: TextCapitalization.characters,
                          keyboardType: TextInputType.text,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[A-Za-z0-9]'),
                            ),
                            FilteringTextInputFormatter.deny(RegExp(r'[\n\r]')),
                          ],
                          onChanged: (v) => _onCellChanged(i, v),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        }

        final rowW = _cells * side + (_cells - 1) * gap;
        return SizedBox(
          width: w,
          height: side,
          child: Align(
            alignment: Alignment.center,
            child: SizedBox(
              width: rowW,
              height: side,
              child: Row(children: children),
            ),
          ),
        );
      },
    );
  }
}
