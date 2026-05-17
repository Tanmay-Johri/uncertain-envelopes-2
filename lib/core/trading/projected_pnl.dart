/// Projected PnL for a hypothetical envelope (market) value.
///
/// [deltaCash] and [deltaEnvelopes] are the player’s current deltas; [envelope]
/// is the user’s **assumed** $ value per envelope.
double projectedPnlUsd(
  double deltaCash,
  double deltaEnvelopes,
  double envelope,
) {
  return deltaCash + envelope * deltaEnvelopes;
}

/// Envelope assumption where [projectedPnlUsd] is exactly zero.
///
/// Returns `null` when PnL does not depend on the envelope assumption
/// ([deltaEnvelopes] is zero) or the result is non-finite.
double? envelopeValueForZeroProjectedPnl(
  double deltaCash,
  double deltaEnvelopes,
) {
  if (deltaEnvelopes == 0 || deltaEnvelopes.isNaN) return null;
  final v = -deltaCash / deltaEnvelopes;
  if (v.isNaN || v.isInfinite) return null;
  return v;
}
