import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/localization.dart';

/// Pins the platform locale for the app test suite.
///
/// Tests that build the real app then resolve the same strings on every
/// machine instead of following the host. Tests that exercise the language
/// setting override it themselves.
Future<void> testExecutable(Future<void> Function() testMain) {
  TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher
    ..localeTestValue = testLocale
    ..localesTestValue = <Locale>[testLocale];
  return testMain();
}
