import 'dart:io';

import 'package:app/testing/devtools/desktop_e2e_runner.dart';

/// Removes the persistent Windows build subtree owned by one E2E lane.
Future<void> resetWindowsE2eLaneBuild({
  required String projectDirectory,
  required int laneIndex,
}) async {
  final project = Directory(projectDirectory).absolute;
  final relativeLanePath = desktopE2eWindowsLaneBuildPath(
    laneIndex,
  ).replaceAll('/', Platform.pathSeparator);
  final laneWindows = Directory(
    '${project.path}${Platform.pathSeparator}$relativeLanePath',
  ).absolute;
  final projectPrefix = '${project.path}${Platform.pathSeparator}';
  if (!laneWindows.path.startsWith(projectPrefix)) {
    throw StateError('Windows E2E build path escaped the desktop project.');
  }

  final candidatePath = StringBuffer(project.path);
  for (final segment in relativeLanePath.split(Platform.pathSeparator)) {
    candidatePath
      ..write(Platform.pathSeparator)
      ..write(segment);
    final path = candidatePath.toString();
    final type = FileSystemEntity.typeSync(
      path,
      followLinks: false,
    );
    if (type == FileSystemEntityType.notFound) return;
    if (type == FileSystemEntityType.link) {
      throw StateError(
        'Windows E2E build path contains a symbolic link or junction: '
        '$path',
      );
    }
    if (type != FileSystemEntityType.directory) {
      throw StateError(
        'Windows E2E build path contains a non-directory entry: '
        '$path',
      );
    }
  }
  await laneWindows.delete(recursive: true);
}
