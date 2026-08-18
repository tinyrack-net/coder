import 'dart:io';

import 'package:app/testing/devtools/desktop_e2e_runner.dart';

/// Removes one E2E lane's Windows output and Flutter's shared generated files.
///
/// Every Windows build directory compiles sources from
/// `windows/flutter/ephemeral`. Switching between the ordinary app build and
/// isolated E2E build directories can therefore leave a valid CMake project
/// pointing at wrapper sources another build removed. The project build lease
/// protects both generated subtrees while Flutter recreates them.
Future<void> resetWindowsE2eLaneBuild({
  required String projectDirectory,
  required int laneIndex,
}) async {
  final project = Directory(projectDirectory).absolute;
  final targets = <Directory?>[
    _validatedGeneratedDirectory(
      project,
      desktopE2eWindowsLaneBuildPath(laneIndex),
    ),
    _validatedGeneratedDirectory(project, 'windows/flutter/ephemeral'),
  ];
  for (final target in targets.nonNulls) {
    await target.delete(recursive: true);
  }
}

Directory? _validatedGeneratedDirectory(
  Directory project,
  String relativePath,
) {
  final nativeRelativePath = relativePath.replaceAll(
    '/',
    Platform.pathSeparator,
  );
  final target = Directory(
    '${project.path}${Platform.pathSeparator}$nativeRelativePath',
  ).absolute;
  final projectPrefix = '${project.path}${Platform.pathSeparator}';
  if (!target.path.startsWith(projectPrefix)) {
    throw StateError('Windows generated path escaped the desktop project.');
  }

  final candidatePath = StringBuffer(project.path);
  for (final segment in nativeRelativePath.split(Platform.pathSeparator)) {
    candidatePath
      ..write(Platform.pathSeparator)
      ..write(segment);
    final path = candidatePath.toString();
    final type = FileSystemEntity.typeSync(
      path,
      followLinks: false,
    );
    if (type == FileSystemEntityType.notFound) return null;
    if (type == FileSystemEntityType.link) {
      throw StateError(
        'Windows generated path contains a symbolic link or junction: '
        '$path',
      );
    }
    if (type != FileSystemEntityType.directory) {
      throw StateError(
        'Windows generated path contains a non-directory entry: '
        '$path',
      );
    }
  }
  return target;
}
