import 'package:alchemist/alchemist.dart';

/// Builds the golden configuration for [host].
///
/// Linux is the single canonical rendering environment, so it is the only
/// platform whose images are compared. Alchemist resolves a variant per run,
/// and `goldenTest` asserts on an empty one while the file is still loading —
/// which fails every test in that file, not just its goldens. Off Linux the CI
/// variant therefore stands in purely to keep the file loadable; those tests
/// carry the `golden` tag and every non-golden run excludes them.
AlchemistConfig goldenAlchemistConfig(HostPlatform host) => AlchemistConfig(
  platformGoldensConfig: PlatformGoldensConfig(
    platforms: <HostPlatform>{HostPlatform.linux},
  ),
  ciGoldensConfig: CiGoldensConfig(enabled: host != HostPlatform.linux),
);

/// Whether [config] resolves a golden variant on [host].
///
/// Mirrors the rule Alchemist applies when it builds its test variant.
bool resolvesGoldenVariant(AlchemistConfig config, HostPlatform host) {
  final platforms = config.platformGoldensConfig;
  return (platforms.enabled && platforms.platforms.contains(host)) ||
      config.ciGoldensConfig.enabled;
}
