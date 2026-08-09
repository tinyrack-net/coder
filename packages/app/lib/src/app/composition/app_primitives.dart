import 'package:uuid/uuid.dart';

/// Public API exposed by this library.
abstract interface class AppClock {
  /// The nowUtc public API member.
  DateTime nowUtc();
}

/// SystemAppClock defines a public contract.
final class SystemAppClock implements AppClock {
  /// Creates a [SystemAppClock].
  const SystemAppClock();

  @override
  DateTime nowUtc() => DateTime.now().toUtc();
}

/// Public API exposed by this library.
abstract interface class AppIdGenerator {
  /// The generate public API member.
  String generate();
}

/// UuidAppIdGenerator defines a public contract.
final class UuidAppIdGenerator implements AppIdGenerator {
  /// Creates a [UuidAppIdGenerator].
  const UuidAppIdGenerator();

  @override
  String generate() => const Uuid().v4();
}
