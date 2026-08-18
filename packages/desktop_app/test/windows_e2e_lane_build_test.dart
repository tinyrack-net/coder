import 'dart:io';

import 'package:test/test.dart';

import '../tool/src/windows_e2e_lane_build.dart';

void main() {
  test('lane reset deletes only an ordinary lane-owned subtree', () async {
    final root = await Directory.systemTemp.createTemp(
      'tinest-windows-e2e-ordinary-',
    );
    final project = Directory(
      '${root.path}${Platform.pathSeparator}project',
    );
    final lane = Directory(
      '${project.path}${Platform.pathSeparator}build'
      '${Platform.pathSeparator}e2e${Platform.pathSeparator}lane-0'
      '${Platform.pathSeparator}windows',
    );
    final sibling = File(
      '${project.path}${Platform.pathSeparator}build'
      '${Platform.pathSeparator}e2e${Platform.pathSeparator}lane-1'
      '${Platform.pathSeparator}windows${Platform.pathSeparator}keep.txt',
    );
    final ephemeral = Directory(
      '${project.path}${Platform.pathSeparator}windows'
      '${Platform.pathSeparator}flutter${Platform.pathSeparator}ephemeral',
    );
    addTearDown(() => root.delete(recursive: true));
    await lane.create(recursive: true);
    await File(
      '${lane.path}${Platform.pathSeparator}stale.txt',
    ).writeAsString('stale');
    await sibling.create(recursive: true);
    await sibling.writeAsString('keep');
    await ephemeral.create(recursive: true);
    await File(
      '${ephemeral.path}${Platform.pathSeparator}stale.cc',
    ).writeAsString('stale');
    await resetWindowsE2eLaneBuild(
      projectDirectory: project.path,
      laneIndex: 0,
    );

    expect(lane.existsSync(), isFalse);
    expect(ephemeral.existsSync(), isFalse);
    expect(sibling.readAsStringSync(), 'keep');
  });

  test(
    'lane reset still removes shared ephemeral without a lane path',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'tinest-windows-e2e-missing-',
      );
      final project = Directory(
        '${root.path}${Platform.pathSeparator}project',
      );
      addTearDown(() => root.delete(recursive: true));
      await project.create();
      final ephemeral = Directory(
        '${project.path}${Platform.pathSeparator}windows'
        '${Platform.pathSeparator}flutter${Platform.pathSeparator}ephemeral',
      );
      await ephemeral.create(recursive: true);

      await resetWindowsE2eLaneBuild(
        projectDirectory: project.path,
        laneIndex: 0,
      );

      expect(project.existsSync(), isTrue);
      expect(ephemeral.existsSync(), isFalse);
    },
  );

  test('lane reset fails closed for a non-directory segment', () async {
    final root = await Directory.systemTemp.createTemp(
      'tinest-windows-e2e-file-',
    );
    final project = Directory(
      '${root.path}${Platform.pathSeparator}project',
    );
    final build = File(
      '${project.path}${Platform.pathSeparator}build',
    );
    addTearDown(() => root.delete(recursive: true));
    await project.create();
    await build.writeAsString('must survive');

    await expectLater(
      resetWindowsE2eLaneBuild(
        projectDirectory: project.path,
        laneIndex: 0,
      ),
      throwsStateError,
    );
    expect(build.readAsStringSync(), 'must survive');
  });

  test('lane reset fails closed for a directory link target', () async {
    final root = await Directory.systemTemp.createTemp(
      'tinest-windows-e2e-reset-',
    );
    final project = Directory(
      '${root.path}${Platform.pathSeparator}project',
    );
    final outside = Directory(
      '${root.path}${Platform.pathSeparator}outside',
    );
    final sentinel = File(
      '${outside.path}${Platform.pathSeparator}sentinel.txt',
    );
    final lane =
        '${project.path}${Platform.pathSeparator}build'
        '${Platform.pathSeparator}e2e${Platform.pathSeparator}lane-0'
        '${Platform.pathSeparator}windows';
    addTearDown(() async {
      if (FileSystemEntity.typeSync(lane, followLinks: false) ==
          FileSystemEntityType.link) {
        await Link(lane).delete();
      }
      await root.delete(recursive: true);
    });
    await project.create();
    await outside.create();
    await sentinel.writeAsString('must survive');
    await Directory(lane).parent.create(recursive: true);
    await _createDirectoryLink(link: lane, target: outside.path);
    expect(
      FileSystemEntity.typeSync(lane, followLinks: false),
      FileSystemEntityType.link,
    );
    await expectLater(
      resetWindowsE2eLaneBuild(
        projectDirectory: project.path,
        laneIndex: 0,
      ),
      throwsStateError,
    );
    expect(sentinel.readAsStringSync(), 'must survive');
    expect(
      FileSystemEntity.typeSync(lane, followLinks: false),
      FileSystemEntityType.link,
    );
  });

  test('lane reset fails closed for a linked parent segment', () async {
    final root = await Directory.systemTemp.createTemp(
      'tinest-windows-e2e-parent-link-',
    );
    final project = Directory(
      '${root.path}${Platform.pathSeparator}project',
    );
    final outsideBuild = Directory(
      '${root.path}${Platform.pathSeparator}outside-build',
    );
    final linkedBuild = '${project.path}${Platform.pathSeparator}build';
    final outsideLane = Directory(
      '${outsideBuild.path}${Platform.pathSeparator}e2e'
      '${Platform.pathSeparator}lane-0${Platform.pathSeparator}windows',
    );
    final sentinel = File(
      '${outsideLane.path}${Platform.pathSeparator}sentinel.txt',
    );
    addTearDown(() async {
      if (FileSystemEntity.typeSync(linkedBuild, followLinks: false) ==
          FileSystemEntityType.link) {
        await Link(linkedBuild).delete();
      }
      await root.delete(recursive: true);
    });
    await project.create();
    await outsideLane.create(recursive: true);
    await sentinel.writeAsString('must survive');
    await _createDirectoryLink(link: linkedBuild, target: outsideBuild.path);
    expect(
      FileSystemEntity.typeSync(linkedBuild, followLinks: false),
      FileSystemEntityType.link,
    );
    await expectLater(
      resetWindowsE2eLaneBuild(
        projectDirectory: project.path,
        laneIndex: 0,
      ),
      throwsStateError,
    );
    expect(sentinel.readAsStringSync(), 'must survive');
    expect(
      FileSystemEntity.typeSync(linkedBuild, followLinks: false),
      FileSystemEntityType.link,
    );
  });

  test('lane reset fails closed for a linked shared ephemeral', () async {
    final root = await Directory.systemTemp.createTemp(
      'tinest-windows-e2e-ephemeral-link-',
    );
    final project = Directory(
      '${root.path}${Platform.pathSeparator}project',
    );
    final outside = Directory(
      '${root.path}${Platform.pathSeparator}outside',
    );
    final sentinel = File(
      '${outside.path}${Platform.pathSeparator}sentinel.txt',
    );
    final ephemeral =
        '${project.path}${Platform.pathSeparator}windows'
        '${Platform.pathSeparator}flutter${Platform.pathSeparator}ephemeral';
    addTearDown(() async {
      if (FileSystemEntity.typeSync(ephemeral, followLinks: false) ==
          FileSystemEntityType.link) {
        await Link(ephemeral).delete();
      }
      await root.delete(recursive: true);
    });
    await Directory(ephemeral).parent.create(recursive: true);
    await outside.create();
    await sentinel.writeAsString('must survive');
    await _createDirectoryLink(link: ephemeral, target: outside.path);

    await expectLater(
      resetWindowsE2eLaneBuild(
        projectDirectory: project.path,
        laneIndex: 0,
      ),
      throwsStateError,
    );
    expect(sentinel.readAsStringSync(), 'must survive');
    expect(
      FileSystemEntity.typeSync(ephemeral, followLinks: false),
      FileSystemEntityType.link,
    );
  });
}

Future<void> _createDirectoryLink({
  required String link,
  required String target,
}) async {
  if (!Platform.isWindows) {
    await Link(link).create(target);
    return;
  }
  final result = await Process.run('cmd.exe', <String>[
    '/d',
    '/c',
    'mklink',
    '/J',
    link,
    target,
  ]);
  expect(
    result.exitCode,
    0,
    reason: '${result.stdout}\n${result.stderr}',
  );
}
