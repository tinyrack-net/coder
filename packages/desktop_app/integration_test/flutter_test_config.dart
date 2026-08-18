import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/support/localization.dart';

/// Pins the platform locale and brightness so end-to-end runs resolve the
/// same strings and exercise the canonical dark desktop theme.
///
/// Without this the app follows the locale of whichever machine runs the
/// suite, and every assertion on user-visible text becomes host-dependent.
///
/// A tap that misses its target is promoted to a failure at the tap itself.
/// On a real desktop window an edge-adjacent control can measure its center a
/// fraction of a pixel off screen; the silent miss otherwise surfaces minutes
/// later as an unrelated wait timeout. Use `tapVisible` from
/// `support/tap_visible.dart` for controls that can touch a window edge.
Future<void> testExecutable(Future<void> Function() testMain) {
  WidgetController.hitTestWarningShouldBeFatal = true;
  IntegrationTestWidgetsFlutterBinding.ensureInitialized().platformDispatcher
    ..localeTestValue = testLocale
    ..localesTestValue = <Locale>[testLocale]
    ..platformBrightnessTestValue = Brightness.dark;
  return testMain();
}
