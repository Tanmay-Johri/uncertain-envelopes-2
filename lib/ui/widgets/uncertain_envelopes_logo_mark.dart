import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Vector mark from [logo/uncertain-envelopes-E.svg] for headers and splash.
///
/// [semanticLabel] is exposed so widget tests can target
/// [find.bySemanticsLabel] instead of brittle text matching.
class UncertainEnvelopesLogoMark extends StatelessWidget {
  const UncertainEnvelopesLogoMark({
    super.key,
    this.height = 22,
    this.alignment = Alignment.center,
    this.semanticLabel = kUncertainEnvelopesBrandSemanticsLabel,
  });

  static const kUncertainEnvelopesBrandSemanticsLabel = 'Uncertain Envelopes';

  final double height;
  final AlignmentGeometry alignment;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final svg = SvgPicture.asset(
      'logo/uncertain-envelopes-E.svg',
      height: height,
      fit: BoxFit.contain,
      alignment: alignment,
    );
    if (semanticLabel == null || semanticLabel!.isEmpty) {
      return svg;
    }
    return Semantics(label: semanticLabel, child: svg);
  }
}
