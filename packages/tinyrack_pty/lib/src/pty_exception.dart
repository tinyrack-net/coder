/// An operating-system error raised by a pseudo-terminal operation.
final class PtyException implements Exception {
  /// Creates a PTY exception.
  const PtyException({
    required this.operation,
    required this.errorCode,
    required this.message,
  });

  /// Operation that failed, such as `start`, `read`, or `resize`.
  final String operation;

  /// Native `errno` or Windows system error code.
  final int errorCode;

  /// Native error description.
  final String message;

  @override
  String toString() => 'PtyException($operation, $errorCode): $message';
}
