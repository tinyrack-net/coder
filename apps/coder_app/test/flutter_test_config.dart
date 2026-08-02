import 'package:alchemist/alchemist.dart';

/// Configures Linux as the single canonical golden rendering environment.
Future<void> testExecutable(Future<void> Function() testMain) =>
    AlchemistConfig.runWithConfig(
      config: AlchemistConfig(
        platformGoldensConfig: PlatformGoldensConfig(
          platforms: <HostPlatform>{HostPlatform.linux},
        ),
        ciGoldensConfig: const CiGoldensConfig(enabled: false),
      ),
      run: testMain,
    );
