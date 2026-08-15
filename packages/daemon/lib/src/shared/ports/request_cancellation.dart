/// Read-only cancellation signal passed across typed host ports.
///
/// Implementations invoke callbacks immediately when cancellation already
/// happened, so a consumer cannot miss a cancellation race while registering.
abstract interface class RequestCancellation {
  /// Whether the owning request has already been cancelled.
  bool get isCancelled;

  /// Registers cleanup that runs once cancellation is requested.
  void onCancel(void Function() callback);
}
