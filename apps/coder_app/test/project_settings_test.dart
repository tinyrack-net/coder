import 'package:coder_app/src/app.dart';
import 'package:coder_app/src/controller.dart';
import 'package:coder_app/src/project_settings_page.dart';
import 'package:coder_app/src/workspace/worktree_hook_report.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'support/fake_coder_api.dart';

void main() {
  final now = DateTime.utc(2026, 8, 3);
  WorkspaceDto workspace(String id, String name) => WorkspaceDto(
    id: id,
    name: name,
    rootPath: '/repos/$name',
    kind: WorkspaceKind.git,
    createdAt: now,
  );

  test('hook commands round-trip one command per non-blank line', () {
    expect(
      parseHookCommands(' npm ci \n\n  \nnpm run build\n'),
      <String>['npm ci', 'npm run build'],
    );
    expect(parseHookCommands('   '), isEmpty);
    expect(
      formatHookCommands(const <String>['npm ci', 'npm run build']),
      'npm ci\nnpm run build',
    );
  });

  test('only a non-zero exit code is reported as a hook failure', () {
    expect(failedWorktreeHook(const <WorktreeHookRunDto>[]), isNull);
    expect(
      failedWorktreeHook(const <WorktreeHookRunDto>[
        WorktreeHookRunDto(
          phase: WorktreeHookPhase.setup,
          command: 'npm ci',
          exitCode: 0,
          stdout: '',
          stderr: '',
        ),
      ]),
      isNull,
    );
    expect(
      failedWorktreeHook(const <WorktreeHookRunDto>[
        WorktreeHookRunDto(
          phase: WorktreeHookPhase.setup,
          command: 'npm ci',
          exitCode: 0,
          stdout: '',
          stderr: '',
        ),
        WorktreeHookRunDto(
          phase: WorktreeHookPhase.setup,
          command: 'npm run build',
          exitCode: 2,
          stdout: '',
          stderr: 'boom',
        ),
      ])?.command,
      'npm run build',
    );
  });

  testWidgets(
    'project settings lists projects and saves worktree lifecycle hooks',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final api = FakeCoderApi(
        workspaces: <WorkspaceDto>[
          workspace('design', 'design'),
          workspace('workspace', 'coder'),
        ],
      )..projectSettings['coder'] = const ProjectSettingsDto();
      final router = await _pumpRoute(
        tester,
        api,
        const ProjectSettingsRoute(hostId: 'server').location,
      );
      addTearDown(router.dispose);

      // Projects are sorted by name, so `coder` is selected by default.
      expect(find.text('Projects'), findsWidgets);
      expect(find.text('design'), findsOneWidget);
      expect(find.text('/projects/workspace/coder.json'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextField, 'Setup (worktree 생성 후)'),
        'npm ci\n\nnpm run build',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Teardown (worktree 제거 전)'),
        'docker compose down',
      );
      await tester.tap(find.widgetWithText(FilledButton, '저장'));
      await tester.pumpAndSettle();

      expect(
        api.projectSettings['workspace'],
        const ProjectSettingsDto(
          setup: <String>['npm ci', 'npm run build'],
          teardown: <String>['docker compose down'],
        ),
      );
      expect(find.text('저장했습니다.'), findsOneWidget);
    },
    tags: const <String>['feature_test__project_settings__widget'],
  );

  testWidgets('project settings switches between projects', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final api =
        FakeCoderApi(
            workspaces: <WorkspaceDto>[
              workspace('design', 'design'),
              workspace('workspace', 'coder'),
            ],
          )
          ..projectSettings['design'] = const ProjectSettingsDto(
            setup: <String>['bundle install'],
          );
    final router = await _pumpRoute(
      tester,
      api,
      const ProjectSettingsRoute(hostId: 'server').location,
    );
    addTearDown(router.dispose);

    await tester.tap(find.text('design'));
    await tester.pumpAndSettle();

    expect(find.text('/projects/design/coder.json'), findsOneWidget);
    expect(find.text('bundle install'), findsOneWidget);
  });

  testWidgets('project settings reports an empty catalog', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final router = await _pumpRoute(
      tester,
      FakeCoderApi(),
      const ProjectSettingsRoute(hostId: 'server').location,
    );
    addTearDown(router.dispose);

    expect(find.text('등록된 project가 없습니다.'), findsOneWidget);
  });

  testWidgets('mobile project settings navigates from list to editor', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final api = FakeCoderApi(
      workspaces: <WorkspaceDto>[workspace('workspace', 'coder')],
    );
    final router = await _pumpRoute(
      tester,
      api,
      const ProjectSettingsRoute(hostId: 'server').location,
    );
    addTearDown(router.dispose);

    expect(find.text('/projects/workspace/coder.json'), findsNothing);
    await tester.tap(find.text('coder'));
    await tester.pumpAndSettle();
    expect(find.text('/projects/workspace/coder.json'), findsOneWidget);

    await tester.tap(find.byTooltip('Project 목록'));
    await tester.pumpAndSettle();
    expect(find.text('/projects/workspace/coder.json'), findsNothing);
  });
}

Future<GoRouter> _pumpRoute(
  WidgetTester tester,
  FakeCoderApi api,
  String location,
) async {
  final router = GoRouter(initialLocation: location, routes: $appRoutes);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appServicesProvider.overrideWithValue(fakeAppServices(api)),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}
