import 'dart:convert';
import 'dart:io';

import 'package:coder_app/src/app.dart';
import 'package:coder_app/src/coder_icons.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

import 'support/real_daemon_fixture.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'project hooks save to coder.json, preserve keys, and reload',
    (tester) async {
      final fixture = await _projectFixture('project-save');
      addTearDown(fixture.$1.dispose);
      final settingsFile = File('${fixture.$2.path}/coder.json');
      await settingsFile.writeAsString(
        '${jsonEncode(<String, Object?>{
          'other': <String, Object?>{'keep': true},
        })}\n',
      );

      await _pumpProjectSettings(tester, fixture.$1);
      await tester.enterText(
        _textInput('Setup (worktree 생성 후)'),
        'dart pub get\n\ndart test',
      );
      await tester.enterText(
        _textInput('Teardown (worktree 제거 전)'),
        'dart run cleanup',
      );
      await tester.tap(find.widgetWithText(TRButton, '저장'));
      await _pumpUntil(tester, find.text('저장했습니다.'));

      final document =
          jsonDecode(await settingsFile.readAsString()) as Map<String, dynamic>;
      expect(document['other'], <String, dynamic>{'keep': true});
      expect(
        document['worktree'],
        <String, dynamic>{
          'setup': <dynamic>['dart pub get', 'dart test'],
          'teardown': <dynamic>['dart run cleanup'],
        },
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await _pumpProjectSettings(tester, fixture.$1);
      expect(find.textContaining('dart pub get'), findsOneWidget);
      expect(find.textContaining('dart run cleanup'), findsOneWidget);
    },
    tags: const <String>[
      'feature_scenario__project_settings__load_save_persist_hooks__e2e',
    ],
  );

  testWidgets(
    'invalid project settings report the daemon error and recover on retry',
    (tester) async {
      final fixture = await _projectFixture('project-recovery');
      addTearDown(fixture.$1.dispose);
      final settingsFile = File('${fixture.$2.path}/coder.json');
      await settingsFile.writeAsString('{not json\n');

      await _pumpProjectSettings(tester, fixture.$1, waitForEditor: false);
      await _pumpUntil(tester, find.textContaining('invalid_project_settings'));
      expect(find.text('다시 시도'), findsOneWidget);

      await settingsFile.writeAsString('{}\n', flush: true);
      await tester.tap(find.widgetWithText(TRButton, '다시 시도'));
      await _pumpUntil(tester, _textInput('Setup (worktree 생성 후)'));
      expect(find.textContaining('invalid_project_settings'), findsNothing);
    },
    tags: const <String>[
      'feature_scenario__project_settings__hook_failure_feedback__e2e',
    ],
  );

  testWidgets(
    'a failed setup hook removes its real Git checkout',
    (tester) async {
      final fixture = await _gitProjectFixture('worktree-setup-failure');
      addTearDown(fixture.$1.dispose);
      final client = await fixture.$1.connect(clientId: 'setup-failure');
      addTearDown(client.close);
      await client.saveProjectSettings(
        fixture.$3,
        ProjectSettingsDto(
          setup: <String>[
            if (Platform.isWindows) 'exit /b 69' else 'exit 69',
          ],
        ),
      );

      await tester.pumpWidget(CoderApp(services: fixture.$1.services));
      await _pumpUntil(tester, find.text('Git Project E2E'));
      final created = await client.createWorktree(
        id: 'failed-worktree',
        workspaceId: fixture.$3,
        mode: WorktreeCreateMode.newBranch,
        branchName: 'setup-must-fail',
        baseBranch: 'main',
      );
      await tester.pumpAndSettle();

      expect(created.hookRuns.single.exitCode, 69);
      expect(created.worktree.archivedAt, isNotNull);
      expect(Directory(created.worktree.path).existsSync(), isFalse);
      expect(
        (await client.getWorkspaceCatalog()).worktrees.map((item) => item.id),
        isNot(contains('failed-worktree')),
      );
      expect(find.text('setup-must-fail'), findsNothing);
    },
    tags: const <String>[
      'feature_scenario__worktree_lifecycle__setup_failure_cleanup__e2e',
    ],
  );

  testWidgets(
    'archive preview cancellation preserves the worktree and Git checkout',
    (tester) async {
      final fixture = await _gitProjectFixture('worktree-archive-cancel');
      addTearDown(fixture.$1.dispose);
      final client = await fixture.$1.connect(clientId: 'archive-cancel');
      addTearDown(client.close);
      final created = await client.createWorktree(
        id: 'cancelled-archive',
        workspaceId: fixture.$3,
        mode: WorktreeCreateMode.newBranch,
        branchName: 'archive-cancel',
        baseBranch: 'main',
      );

      tester.binding.platformDispatcher.localeTestValue = const Locale('ko');
      addTearDown(tester.binding.platformDispatcher.clearLocaleTestValue);
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(CoderApp(services: fixture.$1.services));
      await _pumpUntil(tester, find.text('archive-cancel'));
      final menu = find.byKey(
        const ValueKey<String>('worktree-menu-cancelled-archive'),
      );
      await tester.tap(menu);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Archive'));
      await _pumpUntil(
        tester,
        find.byKey(const ValueKey<String>('worktree-archive-confirm')),
      );
      await tester.tap(find.widgetWithText(TRButton, '취소'));
      await tester.pumpAndSettle();

      expect(Directory(created.worktree.path).existsSync(), isTrue);
      expect(
        (await client.getWorkspaceCatalog()).worktrees.map((item) => item.id),
        contains('cancelled-archive'),
      );
      expect(find.text('archive-cancel'), findsWidgets);
    },
    tags: const <String>[
      'feature_scenario__worktree_lifecycle__archive_preview_cancel__e2e',
    ],
  );
}

Future<(RealDaemonFixture, Directory)> _projectFixture(String id) async {
  final fixture = await RealDaemonFixture.start(id: id);
  final root = Directory('${fixture.home.path}/project')..createSync();
  final client = await fixture.connect(clientId: '$id-setup');
  try {
    await client.registerWorkspace(
      workspaceId: id,
      checkoutId: '$id-main',
      rootPath: root.path,
      name: 'Project E2E',
    );
  } finally {
    await client.close();
  }
  return (fixture, root);
}

Future<(RealDaemonFixture, Directory, String)> _gitProjectFixture(
  String id,
) async {
  final fixture = await RealDaemonFixture.start(id: id);
  final root = Directory('${fixture.home.path}/git-project')..createSync();
  await _runGit(root.path, <String>['init', '-b', 'main']);
  await File('${root.path}/README.md').writeAsString('# fixture\n');
  await _runGit(root.path, <String>['add', 'README.md']);
  await _runGit(root.path, <String>[
    '-c',
    'user.name=Coder E2E',
    '-c',
    'user.email=coder-e2e@example.invalid',
    'commit',
    '-m',
    'Initial fixture',
  ]);
  final client = await fixture.connect(clientId: '$id-setup');
  try {
    await client.registerWorkspace(
      workspaceId: id,
      checkoutId: '$id-main',
      rootPath: root.path,
      name: 'Git Project E2E',
    );
  } finally {
    await client.close();
  }
  return (fixture, root, id);
}

Future<void> _runGit(String path, List<String> arguments) async {
  final result = await Process.run('git', arguments, workingDirectory: path);
  if (result.exitCode != 0) {
    throw TestFailure('git ${arguments.join(' ')} failed: ${result.stderr}');
  }
}

Future<void> _pumpProjectSettings(
  WidgetTester tester,
  RealDaemonFixture fixture, {
  bool waitForEditor = true,
}) async {
  tester.binding.platformDispatcher.localeTestValue = const Locale('ko');
  addTearDown(tester.binding.platformDispatcher.clearLocaleTestValue);
  await tester.binding.setSurfaceSize(const Size(1200, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(CoderApp(services: fixture.services));
  await tester.pumpAndSettle();
  await _pumpUntil(tester, find.text('Project E2E'));
  await tester.tap(find.byIcon(CoderIcons.settings));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Projects'));
  await tester.pumpAndSettle();
  if (waitForEditor) {
    await _pumpUntil(tester, _textInput('Setup (worktree 생성 후)'));
  }
}

Finder _textInput(String label) => find.descendant(
  of: find.byWidgetPredicate(
    (widget) => widget is TRTextField && widget.label == label,
  ),
  matching: find.byType(EditableText),
);

Future<void> _pumpUntil(
  WidgetTester tester,
  Finder finder, {
  int attempts = 100,
}) async {
  for (var attempt = 0; attempt < attempts; attempt += 1) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
  throw TestFailure('Timed out waiting for $finder.');
}
