/// User-visible copy when a `cancel_order` command row was not ack'd in time.
const kCancelOrderCommandAckFailedMessage =
    'Could not create cancellation request';

/// Mock / default: completes shortly after “command row created.”
///
/// Phase 2: perform the real insert (or RPC) and complete when the client
/// receives confirmation that the row exists.
Future<void> defaultSubmitCancelOrderCommandAck(String orderId) async {
  await Future<void>.delayed(const Duration(milliseconds: 50));
}
