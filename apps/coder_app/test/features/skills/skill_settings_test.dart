import 'package:coder_app/src/app/composition/app_providers.dart';
import 'package:coder_app/src/app/router/app_router.dart';
import 'package:coder_app/src/shared/presentation/coder_list_row.dart';
import 'package:coder_app/src/shared/presentation/settings_layout.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

import '../../support/fake_coder_api.dart';
import '../../support/localization.dart';

void main() {
  final now = DateTime.utc(2026, 8, 4);
  final workspace = WorkspaceDto(
    id: 'workspace',
    name: 'Coder',
    rootPath: '/repos/coder',
    kind: WorkspaceKind.git,
    createdAt: now,
  );
  const projectSkill = SkillDto(
    id: 'migrate',
    name: 'migrate',
    description: 'Runs the migration.',
    source: SkillSource.project,
    sourcePath: '/repos/coder/.agents/skills/migrate/SKILL.md',
    contentHash: 'migrate-hash',
    body: 'Run the migration script.',
    isEditable: true,
  );

  testWidgets(
    'skill settings shows every source with its badge and toggles one skill',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final api = FakeCoderApi(workspaces: <WorkspaceDto>[workspace]);
      final router = await _pumpSkills(tester, api);
      addTearDown(router.dispose);

      expect(find.text('스킬'), findsWidgets);
      expect(find.text('coding-conventions'), findsWidgets);
      expect(find.text('commit'), findsWidgets);
      expect(find.text('내장'), findsWidgets);
      expect(find.text('설정'), findsWidgets);

      // The mandatory built-in cannot be turned off.
      final mandatory = find.descendant(
        of: find.widgetWithText(CoderListRow, 'coding-conventions'),
        matching: find.byType(TRSwitch),
      );
      final toggleable = find.descendant(
        of: find.widgetWithText(CoderListRow, 'commit'),
        matching: find.byType(TRSwitch),
      );
      expect(tester.widget<TRSwitch>(mandatory).onCheckedChange, isNull);
      expect(tester.widget<TRSwitch>(toggleable).onCheckedChange, isNotNull);

      await tester.tap(toggleable);
      await tester.pumpAndSettle();
      expect((await api.prompts.getSkill('commit')).isEnabled, isFalse);
    },
    tags: const <String>[
      'feature_test__skill_management__widget',
      'feature_test__skill_invocation__widget',
    ],
  );

  testWidgets(
    'the desktop project selector stays inset inside the collection pane',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final api = FakeCoderApi(workspaces: <WorkspaceDto>[workspace]);
      final router = await _pumpSkills(tester, api);
      addTearDown(router.dispose);

      final selector = find.descendant(
        of: find.byType(TRSelectFormField<String?>),
        matching: find.byType(TextButton),
      );
      expect(selector, findsOneWidget);
      expect(
        tester.getSize(selector).width,
        TRMeasurements.paneMd - 2 * TRSpacing.large,
      );
      expect(
        tester.getTopLeft(selector).dx,
        tester.getTopLeft(find.byType(SettingsPaneHeader).first).dx +
            TRSpacing.large,
      );
    },
    tags: const <String>['feature_test__skill_management__widget'],
  );

  testWidgets(
    'built-in skills are read-only while config skills can be edited',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final api = FakeCoderApi(workspaces: <WorkspaceDto>[workspace]);
      final router = await _pumpSkills(tester, api);
      addTearDown(router.dispose);

      // The first entry sorts to coding-conventions, the mandatory built-in.
      expect(find.text('내장 스킬은 앱에 포함되어 있어 편집할 수 없습니다.'), findsOneWidget);
      expect(find.widgetWithText(TRButton, '저장'), findsNothing);

      await tester.tap(find.text('commit').first);
      await tester.pumpAndSettle();
      expect(find.text('포함된 파일'), findsOneWidget);
      expect(find.text('scripts/split.sh'), findsOneWidget);

      await tester.enterText(
        _textInput('지시문 (Markdown)'),
        'Stage each purpose on its own.',
      );
      await tester.tap(find.widgetWithText(TRButton, '저장'));
      await tester.pumpAndSettle();
      expect(
        (await api.prompts.getSkill('commit')).body,
        'Stage each purpose on its own.',
      );
    },
    tags: const <String>['feature_test__skill_management__widget'],
  );

  testWidgets(
    'a save conflict offers reload or overwrite',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final api = FakeCoderApi(
        workspaces: <WorkspaceDto>[workspace],
        failNextSkillUpdate: true,
      );
      final router = await _pumpSkills(tester, api);
      addTearDown(router.dispose);

      await tester.tap(find.text('commit').first);
      await tester.pumpAndSettle();
      await tester.enterText(
        _textInput('지시문 (Markdown)'),
        'Forced body.',
      );
      await tester.tap(find.widgetWithText(TRButton, '저장'));
      await tester.pumpAndSettle();

      expect(find.text('스킬을 저장하지 못했습니다'), findsOneWidget);
      await tester.tap(find.widgetWithText(TRButton, '덮어쓰기'));
      await tester.pumpAndSettle();
      expect((await api.prompts.getSkill('commit')).body, 'Forced body.');
    },
    tags: const <String>['feature_test__skill_management__widget'],
  );

  testWidgets(
    'picking a project reveals its skills and allows creating one there',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final api = FakeCoderApi(
        workspaces: <WorkspaceDto>[workspace],
        projectSkills: <SkillDto>[projectSkill],
      );
      final router = await _pumpSkills(tester, api);
      addTearDown(router.dispose);

      expect(find.text('migrate'), findsNothing);

      await tester.tap(
        find.descendant(
          of: find.byType(TRSelectFormField<String?>),
          matching: find.byType(TextButton),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Coder').last);
      await tester.pumpAndSettle();

      expect(find.text('migrate'), findsWidgets);
      expect(find.text('프로젝트'), findsWidgets);

      await tester.tap(findAccessibleAction('스킬 추가'));
      await tester.pumpAndSettle();
      await tester.enterText(
        _textInput('ID (디렉터리 이름)'),
        'release-notes',
      );
      await tester.enterText(
        _textInput('이름').last,
        'release-notes',
      );
      await tester.enterText(
        _textInput('설명').last,
        'Writes release notes.',
      );
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      final create = find.widgetWithText(TRButton, '생성');
      await tester.ensureVisible(create);
      await tester.tap(create);
      await tester.pumpAndSettle();

      expect(find.text('release-notes'), findsWidgets);
      expect(
        (await api.prompts.getSkill(
          'release-notes',
          workspaceId: workspace.id,
        )).source,
        SkillSource.config,
      );
    },
    tags: const <String>['feature_test__skill_management__widget'],
  );

  testWidgets(
    'deleting a skill asks for confirmation first',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final api = FakeCoderApi(workspaces: <WorkspaceDto>[workspace]);
      final router = await _pumpSkills(tester, api);
      addTearDown(router.dispose);

      await tester.tap(find.text('commit').first);
      await tester.pumpAndSettle();
      await tester.tap(findAccessibleAction('스킬 삭제'));
      await tester.pumpAndSettle();
      expect(find.text('commit 을(를) 삭제할까요?'), findsOneWidget);

      await tester.tap(find.widgetWithText(TRButton, '취소'));
      await tester.pumpAndSettle();
      expect(await api.prompts.listSkills(), hasLength(2));

      await tester.tap(findAccessibleAction('스킬 삭제'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TRButton, '삭제'));
      await tester.pumpAndSettle();
      expect(await api.prompts.listSkills(), hasLength(1));
    },
    tags: const <String>['feature_test__skill_management__widget'],
  );

  testWidgets(
    'a failing catalog load offers a retry',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final api = FakeCoderApi(
        workspaces: <WorkspaceDto>[workspace],
        skillListError: Exception('daemon offline'),
      );
      final router = await _pumpSkills(tester, api);
      addTearDown(router.dispose);

      expect(find.textContaining('daemon offline'), findsOneWidget);
      api.skillListError = null;
      await tester.tap(find.widgetWithText(TRButton, '다시 시도'));
      await tester.pumpAndSettle();
      expect(find.text('commit'), findsWidgets);
    },
    tags: const <String>['feature_test__skill_management__widget'],
  );

  testWidgets(
    'the narrow layout opens one skill and returns to the list',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 760));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final api = FakeCoderApi(workspaces: <WorkspaceDto>[workspace]);
      final router = await _pumpSkills(tester, api);
      addTearDown(router.dispose);

      expect(findAccessibleAction('스킬 목록'), findsNothing);
      await tester.tap(find.text('commit').first);
      await tester.pumpAndSettle();
      expect(findAccessibleAction('스킬 목록'), findsNothing);

      await tester.tap(
        find.byKey(const ValueKey<String>('settings-back-button')),
      );
      await tester.pumpAndSettle();
      expect(findAccessibleAction('스킬 추가'), findsOneWidget);
    },
    tags: const <String>['feature_test__skill_management__widget'],
  );
}

Finder _textInput(String label) => find.descendant(
  of: find.byWidgetPredicate(
    (widget) => widget is TRTextField && widget.label == label,
  ),
  matching: find.byType(EditableText),
);

Future<GoRouter> _pumpSkills(WidgetTester tester, FakeCoderApi api) async {
  final router = GoRouter(
    initialLocation: const SkillSettingsRoute(hostId: 'server').location,
    routes: $appRoutes,
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appServicesProvider.overrideWithValue(fakeAppServices(api)),
      ],
      child: MaterialApp.router(
        theme: testLightTheme,
        darkTheme: testDarkTheme,
        locale: testLocale,
        localizationsDelegates: testLocalizationsDelegates,
        supportedLocales: testSupportedLocales,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}
