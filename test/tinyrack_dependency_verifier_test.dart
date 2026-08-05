import 'dart:io';

import 'package:coder_workspace/src/tinyrack_dependency_verifier.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  const verifier = TinyrackDependencyVerifier();

  test('rejects hosted Tinyrack dependencies in manifests and lockfiles', () {
    final root = Directory.systemTemp.createTempSync('tinyrack-sources-');
    addTearDown(() => root.deleteSync(recursive: true));
    File(p.join(root.path, 'pubspec.yaml')).writeAsStringSync('''
name: fixture
dependencies:
  tinyrack_ui: ^0.8.0
''');
    File(p.join(root.path, 'pubspec.lock')).writeAsStringSync('''
packages:
  cliweave:
    dependency: transitive
    description:
      name: cliweave
      url: https://pub.dev
    source: hosted
    version: 0.2.2
''');

    expect(
      verifier.verify(root.path).map((violation) => violation.rule),
      containsAll(<String>['tinyrack_manifest_source', 'tinyrack_lock_source']),
    );
  });

  test('rejects movable refs, mismatched resolved refs, and wrong paths', () {
    final root = Directory.systemTemp.createTempSync('tinyrack-sources-');
    addTearDown(() => root.deleteSync(recursive: true));
    File(p.join(root.path, 'pubspec.yaml')).writeAsStringSync('''
name: fixture
dependencies:
  tinyrack_ui:
    git:
      url: https://github.com/tinyrack-net/design.git
      ref: main
      path: packages/not_ui_flutter
''');
    File(p.join(root.path, 'pubspec.lock')).writeAsStringSync('''
packages:
  tinyrack_ui:
    dependency: direct main
    description:
      path: packages/ui_flutter
      ref: 377345c240d0d3dd1a4aeae0301a89567755fe10
      resolved-ref: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
      url: https://github.com/tinyrack-net/design.git
    source: git
    version: 0.8.0
''');

    final rules = verifier.verify(root.path).map((violation) => violation.rule);
    expect(
      rules,
      containsAll(<String>[
        'tinyrack_git_ref',
        'tinyrack_git_path',
        'tinyrack_lock_ref',
      ]),
    );
  });

  test('accepts exact Tinyrack Git sources and ignores build output', () {
    final root = Directory.systemTemp.createTempSync('tinyrack-sources-');
    addTearDown(() => root.deleteSync(recursive: true));
    Directory(p.join(root.path, 'apps', 'app')).createSync(recursive: true);
    File(p.join(root.path, 'apps', 'app', 'pubspec.yaml')).writeAsStringSync('''
name: fixture
dependencies:
  tinyrack_ui:
    git:
      url: https://github.com/tinyrack-net/design.git
      ref: 377345c240d0d3dd1a4aeae0301a89567755fe10
      path: packages/ui_flutter
''');
    Directory(p.join(root.path, 'build')).createSync();
    File(p.join(root.path, 'build', 'pubspec.yaml')).writeAsStringSync('''
name: ignored
dependencies:
  dartage: any
''');
    File(p.join(root.path, 'pubspec.lock')).writeAsStringSync('''
packages:
  tinyrack_ui:
    dependency: direct main
    description:
      path: packages/ui_flutter
      ref: 377345c240d0d3dd1a4aeae0301a89567755fe10
      resolved-ref: 377345c240d0d3dd1a4aeae0301a89567755fe10
      url: https://github.com/tinyrack-net/design.git
    source: git
    version: 0.8.0
''');

    expect(verifier.verify(root.path), isEmpty);
  });
}
