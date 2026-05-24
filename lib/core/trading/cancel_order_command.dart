/// User-visible copy when a `cancel_order` command row was not ack'd in time.
const kCancelOrderCommandAckFailedMessage =
    'Could not create cancellation request';

/// Result of inserting a cancel / partial-cancel command row (command processor
/// ack). Drives how long the UI shows **Cancelling** on a resting order.
enum CancelOrderSubmitOutcome {
  /// `cancel_order` was inserted; wait until the order is `cancelled`.
  fullCommandQueued,

  /// `partial_cancel_order` was inserted; order stays resting — clear the
  /// optimistic **Cancelling** state as soon as the row is ack'd.
  partialCommandQueued,
}

/// Live route: insert `cancel_order` or `partial_cancel_order`, then return
/// [CancelOrderSubmitOutcome] for UI pending-state handling.
typedef SubmitCancelOrderCommand = Future<CancelOrderSubmitOutcome> Function({
  required String orderId,
  required int quantityToCancel,
});

/// Mock / default: completes shortly after “command row created.”
///
/// [pendingQuantityCurrent] is the resting quantity when the user confirmed;
/// used only when [submitCancelOrderCommand] is null so tests can simulate
/// partial vs full without a real backend.
Future<CancelOrderSubmitOutcome> defaultSubmitCancelOrderCommandAck({
  required String orderId,
  required int quantityToCancel,
  required int pendingQuantityCurrent,
}) async {
  await Future<void>.delayed(const Duration(milliseconds: 50));
  return quantityToCancel >= pendingQuantityCurrent
      ? CancelOrderSubmitOutcome.fullCommandQueued
      : CancelOrderSubmitOutcome.partialCommandQueued;
}
