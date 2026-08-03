import 'package:flutter/widgets.dart';
import 'package:integration_test/integration_test.dart';

import '../test/support/localization.dart';

/// Pins the platform locale so end-to-end runs resolve the same strings.
///
/// Without this the app follows the locale of whichever machine runs the
/// suite, and every assertion on user-visible text becomes host-dependent.
Future<void> testExecutable(Future<void> Function() testMain) {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized().platformDispatcher
    ..localeTestValue = testLocale
    ..localesTestValue = <Locale>[testLocale];
  return testMain();
}
