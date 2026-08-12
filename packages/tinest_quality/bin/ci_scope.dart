import 'dart:convert';
import 'dart:io';

// This bootstrap must run before Pub resolves the Flutter workspace in CI.
// ignore: avoid_relative_lib_imports
import '../lib/src/ci_change_scope.dart';

/// Dependency-free CI bootstrap for hosts that intentionally lack Flutter.
Future<void> main() async {
  final files = await stdin
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .toList();
  stdout.writeln(CiChangeScope.forPullRequest(files).outputValue);
}
