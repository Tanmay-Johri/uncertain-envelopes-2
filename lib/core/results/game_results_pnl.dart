/// Backend-side final PnL for one player row.
///
/// From PRD: `delta_cash + envelope_price * delta_envelopes`.
/// [`envelopePriceUsd`] null ⇒ price unset ⇒ PnL unknown (not computed on frontend speculatively).
double? computeFinalPnlFromEnvelope({
  required double deltaCash,
  required double deltaEnvelopes,
  required double? envelopePriceUsd,
}) {
  if (envelopePriceUsd == null) return null;
  return deltaCash + envelopePriceUsd * deltaEnvelopes;
}

/// Sort key: higher finite PnL first; unknown (`null`) last; stable-ish tiebreaker by id omitted (call sites may add).
int comparePnlDescendingKnownLast(double? a, double? b) {
  if (a == null && b == null) return 0;
  if (a == null) return 1;
  if (b == null) return -1;
  return b.compareTo(a);
}
