import 'package:alchemist/alchemist.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/golden_config.dart';

void main() {
  test(
    'every host resolves a golden variant',
    () {
      // `goldenTest` asserts on an empty variant while the file is still
      // loading, so a host that matches none does not merely skip its
      // goldens: the file fails to load and takes every test in it along.
      for (final host in HostPlatform.values) {
        expect(
          resolvesGoldenVariant(goldenAlchemistConfig(host), host),
          isTrue,
          reason: 'no golden variant resolves on $host',
        );
      }
    },
    tags: const <String>['feature_test__desktop_window_chrome__unit'],
  );

  test(
    'only Linux compares the canonical images',
    () {
      for (final host in HostPlatform.values) {
        final config = goldenAlchemistConfig(host);
        expect(
          config.platformGoldensConfig.platforms,
          <HostPlatform>{HostPlatform.linux},
          reason: 'the canonical platform must not follow the host',
        );
        expect(
          config.ciGoldensConfig.enabled,
          host != HostPlatform.linux,
          reason: 'Linux compares its own images, not the CI stand-in',
        );
      }
    },
    tags: const <String>['feature_test__desktop_window_chrome__unit'],
  );
}
