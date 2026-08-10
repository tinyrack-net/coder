import 'dart:io';

/// Reports errors the RPC boundary replaces with an opaque client failure.
///
/// The transport must never hand an internal error to a client, because the
/// message and stack can carry paths, tokens, and prompt text. Discarding it
/// entirely is the other extreme: an `internal_error` alone names neither the
/// failing method nor the cause, so a failure seen once in CI cannot be
/// diagnosed at all. Every swallowed error goes through this port instead.
abstract interface class RpcDiagnostics {
  /// Reports [error] raised by [method] and converted into `internal_error`.
  void unhandledError(String method, Object error, StackTrace stackTrace);
}

/// Writes unhandled RPC errors to the daemon's standard error stream.
final class StderrRpcDiagnostics implements RpcDiagnostics {
  /// Creates the standard-error diagnostics adapter.
  const StderrRpcDiagnostics();

  @override
  void unhandledError(String method, Object error, StackTrace stackTrace) {
    stderr
      ..writeln('Unhandled RPC error in $method: $error')
      ..writeln(stackTrace);
  }
}
