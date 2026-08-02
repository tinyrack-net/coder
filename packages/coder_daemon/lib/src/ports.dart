import 'dart:io';

import 'package:uuid/uuid.dart';

/// Public API exposed by this library.
abstract interface class Clock {
  /// The nowUtc public API member.
  DateTime nowUtc();
}

/// SystemClock defines a public contract.
final class SystemClock implements Clock {
  /// Creates a [SystemClock].
  const SystemClock();

  @override
  DateTime nowUtc() => DateTime.now().toUtc();
}

/// Public API exposed by this library.
abstract interface class IdGenerator {
  /// The generate public API member.
  String generate();
}

/// UuidIdGenerator defines a public contract.
final class UuidIdGenerator implements IdGenerator {
  /// Creates a [UuidIdGenerator].
  const UuidIdGenerator();

  @override
  String generate() => const Uuid().v4();
}

/// Public API exposed by this library.
abstract interface class WorkspaceCanonicalizer {
  /// The canonicalizeExistingDirectory public API member.
  String canonicalizeExistingDirectory(String path);
}

/// IoWorkspaceCanonicalizer defines a public contract.
final class IoWorkspaceCanonicalizer implements WorkspaceCanonicalizer {
  /// Creates a [IoWorkspaceCanonicalizer].
  const IoWorkspaceCanonicalizer();

  @override
  String canonicalizeExistingDirectory(String path) {
    final directory = Directory(path);
    if (!directory.existsSync()) {
      throw const FormatException('Workspace directory not found.');
    }
    return directory.resolveSymbolicLinksSync();
  }
}
