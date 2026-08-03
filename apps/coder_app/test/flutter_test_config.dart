import 'package:alchemist/alchemist.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/localization.dart';

/// Configures Linux as the single canonical golden rendering environment.
///
/// The platform locale is pinned too, so tests that build the real app
/// resolve the same strings on every machine instead of following the host.
/// Tests that exercise the language setting override it themselves.
Future<void> testExecutable(Future<void> Function() testMain) {
  TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher
    ..localeTestValue = testLocale
    ..localesTestValue = <Locale>[testLocale];
  return AlchemistConfig.runWithConfig(
    config: AlchemistConfig(
      platformGoldensConfig: PlatformGoldensConfig(
        platforms: <HostPlatform>{HostPlatform.linux},
      ),
      ciGoldensConfig: const CiGoldensConfig(enabled: false),
    ),
    run: testMain,
  );
}
