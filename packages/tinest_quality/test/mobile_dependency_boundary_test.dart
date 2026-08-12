import 'dart:io';

import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  final root =
      Directory.current.path.endsWith(
        'packages${Platform.pathSeparator}tinest_quality',
      )
      ? Directory('../..').absolute
      : Directory.current.absolute;
  File workspaceFile(String path) => File('${root.path}/$path');
  Directory workspaceDirectory(String path) => Directory('${root.path}/$path');

  test('the mobile app dependency boundary excludes the embedded daemon', () {
    final manifests = <String, YamlMap>{};
    for (final entity in workspaceDirectory(
      'packages',
    ).listSync().whereType<Directory>()) {
      final file = File('${entity.path}/pubspec.yaml');
      if (!file.existsSync()) continue;
      final manifest = loadYaml(file.readAsStringSync()) as YamlMap;
      manifests[manifest['name'] as String] = manifest;
    }
    final closure = <String>{};
    void visit(String package) {
      if (!closure.add(package)) return;
      final dependencies = manifests[package]?['dependencies'];
      if (dependencies is! YamlMap) return;
      dependencies.keys.cast<String>().forEach(visit);
    }

    visit('app');
    expect(closure, isNot(contains(anyOf('daemon', 'drift', 'sqlite3'))));

    final pubspec = manifests['app']!;
    final devDependencies = (pubspec['dev_dependencies'] as YamlMap).keys
        .cast<String>()
        .toSet();

    expect(devDependencies, isNot(contains('daemon')));
  });

  test('mobile production sources cannot import the embedded daemon', () {
    final violations = workspaceDirectory('packages/app/lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where(
          (file) => file.readAsStringSync().contains('package:daemon/'),
        )
        .map((file) => file.path.replaceAll(r'\', '/'))
        .toList(growable: false);

    expect(violations, isEmpty);
  });

  test('app production sources cannot import the test-only facade', () {
    final violations = workspaceDirectory('packages/app/lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where(
          (file) => !file.path.replaceAll(r'\', '/').contains('/lib/testing'),
        )
        .where(
          (file) => file.readAsStringSync().contains('package:app/testing'),
        )
        .map((file) => file.path.replaceAll(r'\', '/'))
        .toList(growable: false);

    expect(violations, isEmpty);
  });

  test('desktop composition has its own package and matching version', () {
    final mobile =
        loadYaml(
              workspaceFile('packages/app/pubspec.yaml').readAsStringSync(),
            )
            as YamlMap;
    final desktopFile = workspaceFile('packages/desktop_app/pubspec.yaml');

    expect(desktopFile.existsSync(), isTrue);
    final desktop = loadYaml(desktopFile.readAsStringSync()) as YamlMap;
    expect(desktop['version'], mobile['version']);
    expect((desktop['dependencies'] as YamlMap).keys, contains('daemon'));
  });

  test('mobile and desktop launch assets stay byte-identical', () {
    for (final directory in const <String>['brand', 'tray']) {
      final mobileDirectory = workspaceDirectory(
        'packages/app/assets/$directory',
      );
      final desktopDirectory = workspaceDirectory(
        'packages/desktop_app/assets/$directory',
      );
      final mobileFiles = mobileDirectory
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => !file.path.endsWith('.md'));
      for (final mobileFile in mobileFiles) {
        final relative = mobileFile.path.substring(mobileDirectory.path.length);
        final desktopFile = File('${desktopDirectory.path}$relative');
        expect(desktopFile.existsSync(), isTrue, reason: relative);
        expect(
          desktopFile.readAsBytesSync(),
          mobileFile.readAsBytesSync(),
          reason: relative,
        );
      }
    }
  });
}
