import 'dart:io';

import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import 'support/repo_root.dart';

void main() {
  useRepositoryRoot();
  test('workspace packages use the unprefixed package topology', () {
    const expectedPackages = <String>{
      'agent',
      'app',
      'cli',
      'client',
      'daemon',
      'protocol',
      'relay',
      'relay_protocol',
      'tinest_quality',
    };
    final packagesDirectory = Directory('packages');
    final actualPackages = packagesDirectory
        .listSync()
        .whereType<Directory>()
        .map(
          (directory) => directory.uri.pathSegments.reversed.firstWhere(
            (segment) => segment.isNotEmpty,
          ),
        )
        .toSet();

    expect(actualPackages, expectedPackages);
    expect(Directory('apps').existsSync(), isFalse);

    for (final package in expectedPackages) {
      final pubspec =
          loadYaml(
                File('packages/$package/pubspec.yaml').readAsStringSync(),
              )
              as YamlMap;
      expect(
        pubspec['name'],
        package,
        reason: 'packages/$package/pubspec.yaml',
      );
    }
  });
}
