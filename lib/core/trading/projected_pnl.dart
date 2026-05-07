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
