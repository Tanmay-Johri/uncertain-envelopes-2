import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_layout.dart';

/// Centers [child] horizontally and caps its width on wide viewports (POL1).
///
/// Below [maxContentWidth] the child receives the full screen width. At or
/// above, the child is given exactly [maxContentWidth] logical pixels so
/// layouts stay readable on desktop web.
class MaxWidthCenteredLayout extends StatelessWidget {
  const MaxWidthCenteredLayout({
    super.key,
    required this.child,
    this.maxContentWidth = AppLayout.maxContentWidth,
  });

  final Widget child;
  final double maxContentWidth;

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    final w = math.min(screenW, maxContentWidth);
    return ColoredBox(
      color: AppColors.background,
      child: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: w,
          child: child,
        ),
      ),
    );
  }
}
