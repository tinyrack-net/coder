import 'dart:async';

import 'package:alchemist/alchemist.dart';
// Alchemist's public golden API captures a subtree. This test needs its
// adapter hook so a root-overlay menu is included in the captured scene.
import 'package:alchemist/src/golden_test_adapter.dart' as alchemist_adapter;
import 'package:app/src/app/coder_app.dart';
import 'package:app/src/app/composition/app_providers.dart';
import 'package:app/src/app/router/app_router.dart';
import 'package:app/src/features/conversation/application/composer_suggestions.dart';
import 'package:app/src/features/conversation/presentation/composer_trigger.dart';
import 'package:app/src/features/conversation/presentation/widgets/composer_suggestions_overlay.dart';
import 'package:app/src/features/conversation/presentation/widgets/session_composer.dart';
import 'package:app/src/features/hosts/domain/host_models.dart';
import 'package:app/src/features/hosts/domain/host_ports.dart';
import 'package:app/src/features/terminals/presentation/coder_terminal_view.dart';
import 'package:app/src/shared/presentation/model_picker.dart';
import 'package:app/src/shared/presentation/permission_picker.dart';
import 'package:app/src/shared/presentation/settings_layout.dart';
import 'package:client/client.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:protocol/protocol.dart';
import 'package:termworld/termworld.dart';
// The focus source exposes test-only modality controls specifically so one
// widget test's pointer input cannot decide another test's focus visuals.
import 'package:tinyrack_ui/src/internal/focus_source.dart' as focus_source;
import 'package:tinyrack_ui/tinyrack_ui.dart';

import '../support/fake_coder_api.dart';
import '../support/fake_desktop_ports.dart';
import '../support/localization.dart';

void main() {
  unawaited(
    goldenTest(
      'settings loading skeletons preserve responsive surface shapes',
      fileName: 'settings_loading_skeletons',
      constraints: const BoxConstraints.tightFor(width: 1500, height: 900),
      builder: () => GoldenTestGroup(
        columns: 2,
        children: <Widget>[
          GoldenTestScenario(
            name: 'desktop list detail light',
            child: SizedBox(
              width: 1000,
              height: 760,
              child: _settingsSkeleton(
                ThemeMode.light,
                const SettingsSkeletonLayout.listDetail(
                  semanticLabel: '설정 불러오는 중',
                ),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'mobile form dark',
            child: SizedBox(
              width: 390,
              height: 760,
              child: _settingsSkeleton(
                ThemeMode.dark,
                const SettingsSkeletonLayout.form(
                  semanticLabel: '설정 불러오는 중',
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  unawaited(
    goldenTest(
      'desktop title bar file menu is open',
      fileName: 'desktop_file_menu_open',
      constraints: const BoxConstraints.tightFor(width: 1000, height: 620),
      whilePerforming: (tester) async {
        await tester.pumpAndSettle();
        await tester.tap(find.text('파일'));
        await tester.pumpAndSettle();
        return () async {
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
          await tester.pumpAndSettle();
        };
      },
      builder: _desktopApp,
    ),
  );

  unawaited(
    goldenTest(
      'desktop about dialog uses the Tinyrack layer',
      fileName: 'desktop_about_dialog',
      constraints: const BoxConstraints.tightFor(width: 1000, height: 620),
      whilePerforming: (tester) async {
        await tester.pumpAndSettle();
        await tester.tap(find.text('도움말'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Tinyrack Coder 정보'));
        await tester.pumpAndSettle();
        return () async {
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
          await tester.pumpAndSettle();
        };
      },
      builder: _desktopApp,
    ),
  );

  unawaited(
    goldenTest(
      'composer chip menu is open without a tooltip',
      fileName: 'composer_chip_menu_without_tooltip',
      constraints: const BoxConstraints.tightFor(width: 720, height: 480),
      whilePerforming: (tester) async {
        tester
            .state<_ComposerChipGoldenAppState>(
              find.byType(_ComposerChipGoldenApp),
            )
            .stabilizeLayout();
        await tester.pumpAndSettle();
        focus_source.TRFocusSource.instance.debugSetKeyboardModality(true);
        await tester.tap(find.byKey(const ValueKey('golden-project-chip')));
        await tester.pumpAndSettle();
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        expect(find.text('프로젝트 선택'), findsNothing);
        expect(find.text('추가'), findsOneWidget);
        final defaultExpectation = alchemist_adapter.goldenFileExpectationFn;
        alchemist_adapter.goldenFileExpectationFn = (actual, golden) =>
            () async {
              try {
                await expectLater(find.byType(View), matchesGoldenFile(golden));
              } finally {
                alchemist_adapter.goldenFileExpectationFn = defaultExpectation;
                focus_source.TRFocusSource.instance.debugReset();
              }
            };
        return null;
      },
      builder: _composerChipApp,
    ),
  );

  for (final variant in <({String name, Size size, ThemeMode mode})>[
    (
      name: 'desktop_light',
      size: const Size(1000, 800),
      mode: ThemeMode.light,
    ),
    (
      name: 'mobile_dark',
      size: const Size(390, 760),
      mode: ThemeMode.dark,
    ),
  ]) {
    unawaited(
      goldenTest(
        'permission picker ${variant.name} layer',
        fileName: 'permission_picker_${variant.name}',
        constraints: BoxConstraints.tight(variant.size),
        builder: () => _PermissionPickerGoldenHost(mode: variant.mode),
      ),
    );
    unawaited(
      goldenTest(
        'settings dialog form ${variant.name} layer',
        fileName: 'settings_dialog_form_${variant.name}',
        constraints: BoxConstraints.tight(variant.size),
        builder: () => _SettingsDialogGoldenHost(mode: variant.mode),
      ),
    );
  }

  unawaited(
    goldenTest(
      'terminal context menu is open',
      fileName: 'terminal_context_menu_open',
      constraints: const BoxConstraints.tightFor(width: 1100, height: 760),
      whilePerforming: (tester) async {
        final terminalView = tester.widget<CoderTerminalView>(
          find.byType(CoderTerminalView),
        );
        await _waitForTerminalText(
          tester,
          terminalView.terminal,
          'selectable output',
        );
        final surface = find.byKey(
          const ValueKey<String>('tr-terminal-surface'),
        );
        final selection = await tester.startGesture(
          tester.getTopLeft(surface) + const Offset(12, 12),
          kind: PointerDeviceKind.mouse,
        );
        await tester.pump();
        await selection.moveBy(const Offset(120, 0));
        await tester.pump();
        await selection.up();
        await tester.pump();

        final gesture = await tester.startGesture(
          tester.getTopLeft(surface) + const Offset(24, 24),
          kind: PointerDeviceKind.mouse,
          buttons: kSecondaryButton,
        );
        await tester.pump(const Duration(milliseconds: 50));
        await gesture.up();
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey<String>('terminal-menu-copy')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey<String>('terminal-menu-clear-screen')),
          findsOneWidget,
        );
        return () async {
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
          await tester.pumpAndSettle();
        };
      },
      builder: _terminalApp,
    ),
  );

  unawaited(
    goldenTest(
      'terminal creation failure uses the workspace alert surface',
      fileName: 'terminal_creation_failure',
      constraints: const BoxConstraints.tightFor(width: 1100, height: 760),
      whilePerforming: (tester) async {
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey('workspace-new-tab-menu')),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey('workspace-new-terminal')),
        );
        await tester.pumpAndSettle();
        return null;
      },
      builder: _terminalFailureApp,
    ),
  );

  unawaited(
    goldenTest(
      'terminal IME preedit replaces its cursor with an underline',
      fileName: 'terminal_ime_preedit',
      constraints: const BoxConstraints.tightFor(width: 1100, height: 760),
      whilePerforming: (tester) async {
        final terminalView = tester.widget<CoderTerminalView>(
          find.byType(CoderTerminalView),
        );
        await _waitForTerminalText(tester, terminalView.terminal, 'input: ');
        final surface = find.byKey(
          const ValueKey<String>('tr-terminal-surface'),
        );
        final inputFocus = tester.widget<Focus>(
          find.descendant(of: surface, matching: find.byType(Focus)),
        );
        inputFocus.focusNode?.requestFocus();
        await tester.pump();
        expect(tester.testTextInput.hasAnyClients, isTrue);
        tester.testTextInput.updateEditingValue(
          const TextEditingValue(
            text: '한',
            selection: TextSelection.collapsed(offset: 1),
            composing: TextRange(start: 0, end: 1),
          ),
        );
        await tester.pump();
        final terminal = tester.widget<TerminalView>(
          find.byType(TerminalView),
        );
        final preedit = find.byKey(
          const ValueKey<String>('termworld-preedit'),
        );
        expect(preedit, findsOneWidget);
        expect(tester.widget<Text>(preedit).data, '한');
        final decoration =
            tester
                    .widget<DecoratedBox>(
                      find.ancestor(
                        of: preedit,
                        matching: find.byType(DecoratedBox),
                      ),
                    )
                    .decoration
                as BoxDecoration;
        expect(decoration.color, terminal.theme!.background);
        expect(
          (decoration.border! as Border).bottom.color,
          terminal.theme!.foreground,
        );
        return null;
      },
      builder: _terminalImeApp,
    ),
  );

  for (final variant in <({String name, ComposerTriggerKind kind})>[
    (name: 'command', kind: ComposerTriggerKind.command),
    (name: 'file', kind: ComposerTriggerKind.file),
  ]) {
    unawaited(
      goldenTest(
        'composer ${variant.name} suggestions layer',
        fileName: 'composer_${variant.name}_suggestions',
        constraints: const BoxConstraints.tightFor(width: 640, height: 420),
        builder: () => _ComposerSuggestionsGoldenHost(kind: variant.kind),
      ),
    );
  }

  for (final variant in <({String name, Size size, ThemeMode mode})>[
    (
      name: 'desktop_light',
      size: const Size(800, 700),
      mode: ThemeMode.light,
    ),
    (
      name: 'mobile_dark',
      size: const Size(390, 760),
      mode: ThemeMode.dark,
    ),
  ]) {
    unawaited(
      goldenTest(
        'model picker ${variant.name} layer',
        fileName: 'model_picker_${variant.name}',
        constraints: BoxConstraints.tight(variant.size),
        builder: () => _ModelPickerGoldenHost(
          mode: variant.mode,
          size: variant.size,
        ),
      ),
    );
  }

  unawaited(
    goldenTest(
      'compact composer settings sheet',
      fileName: 'composer_settings_sheet',
      constraints: const BoxConstraints.tightFor(width: 390, height: 760),
      whilePerforming: (tester) async {
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey<String>('session-composer-settings')),
        );
        await tester.pumpAndSettle();
        return () async {
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
          await tester.pumpAndSettle();
        };
      },
      builder: _ComposerSettingsGoldenHost.new,
    ),
  );

  unawaited(
    goldenTest(
      'compact composer nested agent sheet',
      fileName: 'composer_settings_agent_sheet',
      constraints: const BoxConstraints.tightFor(width: 390, height: 760),
      whilePerforming: (tester) async {
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey<String>('session-composer-settings')),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(
            const ValueKey<String>('session-composer-settings-agent'),
          ),
        );
        await tester.pumpAndSettle();
        return () async {
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
          await tester.pumpAndSettle();
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
          await tester.pumpAndSettle();
        };
      },
      builder: _ComposerSettingsGoldenHost.new,
    ),
  );

  unawaited(
    goldenTest(
      'compact composer settings locked agent',
      fileName: 'composer_settings_locked_agent',
      constraints: const BoxConstraints.tightFor(width: 390, height: 760),
      whilePerforming: (tester) async {
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey<String>('session-composer-settings')),
        );
        await tester.pumpAndSettle();
        return () async {
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
          await tester.pumpAndSettle();
        };
      },
      builder: () => const _ComposerSettingsGoldenHost(agentEnabled: false),
    ),
  );
}

class _ComposerSettingsGoldenHost extends StatelessWidget {
  const _ComposerSettingsGoldenHost({this.agentEnabled = true});

  final bool agentEnabled;

  @override
  Widget build(BuildContext context) => ProviderScope(
    overrides: [
      appServicesProvider.overrideWithValue(
        fakeAppServices(
          FakeCoderApi(agentDefinitions: _definitions),
        ),
      ),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: testLocale,
      localizationsDelegates: testLocalizationsDelegates,
      supportedLocales: testSupportedLocales,
      theme: testLightTheme,
      darkTheme: testDarkTheme,
      themeMode: ThemeMode.dark,
      builder: (context, child) {
        const padding = EdgeInsets.fromLTRB(0, 24, 0, 34);
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(padding: padding, viewPadding: padding),
          child: child!,
        );
      },
      home: Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: SessionComposer(
            enabled: true,
            contextTokens: 75000,
            contextWindow: 200000,
            onSubmit: (_) {},
            bar: SessionComposerBar(
              hostId: 'server',
              definitions: _definitions,
              agentDefinitionId: 'coder',
              selection: null,
              onAgentChanged: (_) {},
              onModelChanged: (_, _) {},
              mode: SessionMode.normal,
              onModeChanged: (_) {},
              permissionMode: PermissionMode.ask,
              onPermissionModeChanged: (_) {},
              agentEnabled: agentEnabled,
            ),
          ),
        ),
      ),
    ),
  );

  static const _definitions = <AgentDefinitionDto>[
    AgentDefinitionDto(
      id: 'coder',
      name: 'Coder',
      description: 'General-purpose coding agent',
      mode: AgentMode.primary,
      promptEnabled: true,
      systemPrompt: 'Code carefully.',
      model: AgentModelSelectionDto(source: AgentModelSource.session),
      toolIds: <String>[],
      callableAgentIds: <String>[],
      contentHash: 'coder-hash',
      sourcePath: '/agents/coder.md',
      isBuiltIn: true,
    ),
    AgentDefinitionDto(
      id: 'reviewer',
      name: 'Reviewer',
      description: 'Reviews changes',
      mode: AgentMode.primary,
      promptEnabled: true,
      systemPrompt: 'Review carefully.',
      model: AgentModelSelectionDto(source: AgentModelSource.session),
      toolIds: <String>[],
      callableAgentIds: <String>[],
      contentHash: 'reviewer-hash',
      sourcePath: '/agents/reviewer.md',
    ),
  ];
}

Widget _settingsSkeleton(ThemeMode mode, Widget child) => MaterialApp(
  theme: testLightTheme,
  darkTheme: testDarkTheme,
  themeMode: mode,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: true),
    child: child!,
  ),
  home: Scaffold(body: child),
);

Widget _desktopApp() => CoderApp(
  services: fakeAppServices(
    FakeCoderApi(),
    connected: false,
    store: MemoryAppStore(
      settings: const AppSettings(
        embeddedDaemonEnabled: false,
        localeTag: 'ko',
      ),
    ),
  ),
  desktopWindow: FakeDesktopWindow(supportsCustomTitleBar: true),
  trayIcon: FakeTrayIcon(),
  autostart: FakeAutostartRegistration(),
);

/// Pins the terminal's own context menu, which no other golden reaches.
///
/// The menu is built by Coder's token-backed termworld composite, because the
/// terminal owns secondary taps, so only a real right-click on the terminal
/// surface opens it.
Widget _terminalApp() {
  final now = DateTime.utc(2026, 8, 3);
  final workspace = WorkspaceDto(
    id: 'workspace',
    name: 'Coder',
    rootPath: '/repos/coder',
    kind: WorkspaceKind.git,
    createdAt: now,
  );
  final worktree = WorktreeDto(
    id: 'checkout',
    workspaceId: workspace.id,
    name: 'main',
    path: workspace.rootPath,
    branch: 'main',
    head: 'abc',
    kind: WorktreeKind.checkout,
    isCoderOwned: false,
    createdAt: now,
  );
  const terminal = TerminalDto(
    id: 'terminal-golden',
    worktreeId: 'checkout',
    title: 'Remote terminal',
    shell: ShellSpecDto(executable: '/bin/sh'),
    status: TerminalStatus.running,
    columns: 80,
    rows: 24,
    lastSequence: 0,
  );
  return _TerminalGoldenHost(
    api: FakeCoderApi(
      workspaces: <WorkspaceDto>[workspace],
      worktrees: <WorktreeDto>[worktree],
      terminals: const <TerminalDto>[terminal],
      terminalReplay: const <TerminalOutputDto>[
        TerminalOutputDto(
          terminalId: 'terminal-golden',
          sequence: 1,
          data: 'selectable output',
        ),
      ],
    ),
    location: TerminalRoute(
      hostId: 'server',
      workspaceId: workspace.id,
      worktreeId: worktree.id,
      terminalId: terminal.id,
    ).location,
  );
}

Widget _terminalFailureApp() {
  final now = DateTime.utc(2026, 8, 3);
  final workspace = WorkspaceDto(
    id: 'workspace',
    name: 'Coder',
    rootPath: '/repos/coder',
    kind: WorkspaceKind.git,
    createdAt: now,
  );
  final worktree = WorktreeDto(
    id: 'checkout',
    workspaceId: workspace.id,
    name: 'main',
    path: workspace.rootPath,
    branch: 'main',
    head: 'abc',
    kind: WorktreeKind.checkout,
    isCoderOwned: false,
    createdAt: now,
  );
  return _TerminalGoldenHost(
    api: FakeCoderApi(
      workspaces: <WorkspaceDto>[workspace],
      worktrees: <WorktreeDto>[worktree],
      terminalCreateError: const CoderClientException(
        'The worktree directory is no longer available.',
        code: 'worktree_unavailable',
      ),
    ),
    location: WorktreeRoute(
      hostId: 'server',
      workspaceId: workspace.id,
      worktreeId: worktree.id,
    ).location,
  );
}

class _TerminalGoldenHost extends StatefulWidget {
  const _TerminalGoldenHost({required this.api, required this.location});

  final FakeCoderApi api;
  final String location;

  @override
  State<_TerminalGoldenHost> createState() => _TerminalGoldenHostState();
}

class _TerminalGoldenHostState extends State<_TerminalGoldenHost> {
  late final GoRouter _router = GoRouter(
    initialLocation: widget.location,
    routes: $appRoutes,
  );

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ProviderScope(
    overrides: [
      appServicesProvider.overrideWithValue(fakeAppServices(widget.api)),
    ],
    child: MaterialApp.router(
      debugShowCheckedModeBanner: false,
      locale: testLocale,
      localizationsDelegates: testLocalizationsDelegates,
      supportedLocales: testSupportedLocales,
      theme: testLightTheme,
      darkTheme: testDarkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: _router,
    ),
  );
}

Widget _terminalImeApp() => const _TerminalImeGoldenApp();

Future<void> _waitForTerminalText(
  WidgetTester tester,
  Terminal terminal,
  String expected,
) async {
  while (terminal.buffer.active
          .getLine(0)
          ?.translateToString(trimRight: true) !=
      expected) {
    await tester.pump();
  }
}

class _TerminalImeGoldenApp extends StatefulWidget {
  const _TerminalImeGoldenApp();

  @override
  State<_TerminalImeGoldenApp> createState() => _TerminalImeGoldenAppState();
}

class _TerminalImeGoldenAppState extends State<_TerminalImeGoldenApp> {
  late final Terminal _terminal = Terminal()..write('input: ');
  late final TerminalViewController _controller = TerminalViewController();

  @override
  void dispose() {
    _controller.dispose();
    _terminal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: testLightTheme,
    darkTheme: testDarkTheme,
    themeMode: ThemeMode.dark,
    home: Scaffold(
      body: CoderTerminalView(
        terminal: _terminal,
        controller: _controller,
        autofocus: true,
      ),
    ),
  );
}

Widget _composerChipApp() => const _ComposerChipGoldenApp();

class _ComposerChipGoldenApp extends StatefulWidget {
  const _ComposerChipGoldenApp();

  @override
  State<_ComposerChipGoldenApp> createState() => _ComposerChipGoldenAppState();
}

class _ComposerChipGoldenAppState extends State<_ComposerChipGoldenApp> {
  int _layoutGeneration = 0;

  void stabilizeLayout() => setState(() => _layoutGeneration++);

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: testLocale,
    localizationsDelegates: testLocalizationsDelegates,
    supportedLocales: testSupportedLocales,
    theme: testLightTheme,
    darkTheme: testDarkTheme,
    themeMode: ThemeMode.dark,
    home: Scaffold(
      body: Center(
        child: TRTooltipProvider(
          child: ComposerChip(
            key: ValueKey<int>(_layoutGeneration),
            valueKey: const ValueKey('golden-project-chip'),
            icon: Icons.folder_outlined,
            label: 'Coder',
            tooltip: '프로젝트 선택',
            menuChildren: <Widget>[
              TRMenuItem(onPressed: () {}, child: const Text('Coder · test')),
              TRMenuItem(onPressed: () {}, child: const Text('추가')),
            ],
          ),
        ),
      ),
    ),
  );
}

class _PermissionPickerGoldenHost extends StatelessWidget {
  const _PermissionPickerGoldenHost({required this.mode});

  final ThemeMode mode;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: testLocale,
    localizationsDelegates: testLocalizationsDelegates,
    supportedLocales: testSupportedLocales,
    theme: testLightTheme,
    darkTheme: testDarkTheme,
    themeMode: mode,
    home: const Scaffold(
      body: Align(
        alignment: Alignment.bottomCenter,
        child: PermissionPickerDrawer(
          currentMode: PermissionMode.workspaceWrite,
        ),
      ),
    ),
  );
}

/// Captures the shared field rhythm used by every settings form dialog.
class _SettingsDialogGoldenHost extends StatelessWidget {
  const _SettingsDialogGoldenHost({required this.mode});

  final ThemeMode mode;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: testLocale,
    localizationsDelegates: testLocalizationsDelegates,
    supportedLocales: testSupportedLocales,
    theme: testLightTheme,
    darkTheme: testDarkTheme,
    themeMode: mode,
    home: Scaffold(
      body: Center(
        child: TRAlertDialog(
          title: const TRText.inherit('커스텀 Provider'),
          content: SettingsDialogForm(
            children: <Widget>[
              const TRTextField(label: '이름', initialValue: 'Local model'),
              const TRTextField(
                label: 'Base URL',
                initialValue: 'http://127.0.0.1:8080/v1',
              ),
              TRSelectFormField<String>(
                initialValue: 'responses',
                label: 'API 형식',
                width: TRMeasurements.overlayWidthMd,
                items: const <TRSelectItem<String>>[
                  TRSelectItem<String>(
                    value: 'responses',
                    label: 'Responses API',
                  ),
                ],
                onValueChange: (_) {},
              ),
              const TRTextField(label: 'API key', obscureText: true),
            ],
          ),
          actions: <TRButton>[
            TRButton(
              appearance: TRAppearance.ghost,
              onPressed: () {},
              child: const TRText.inherit('취소'),
            ),
            TRButton(
              intent: TRIntent.primary,
              onPressed: () {},
              child: const TRText.inherit('저장'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ModelPickerGoldenHost extends StatelessWidget {
  const _ModelPickerGoldenHost({required this.mode, required this.size});

  final ThemeMode mode;
  final Size size;

  @override
  Widget build(BuildContext context) => SizedBox.fromSize(
    size: size,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: testLocale,
      localizationsDelegates: testLocalizationsDelegates,
      supportedLocales: testSupportedLocales,
      theme: testLightTheme,
      darkTheme: testDarkTheme,
      themeMode: mode,
      builder: (context, child) {
        final padding = size.width < 760
            ? const EdgeInsets.fromLTRB(0, 24, 0, 34)
            : EdgeInsets.zero;
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(padding: padding, viewPadding: padding),
          child: child!,
        );
      },
      home: const TRTooltipProvider(child: _OpenModelPicker()),
    ),
  );
}

class _OpenModelPicker extends StatelessWidget {
  const _OpenModelPicker();

  @override
  Widget build(BuildContext context) {
    const picker = ModelPicker(
      currentSelection: SessionModelSelectionDto(
        modelId: 'openai/gpt-5.6',
      ),
      title: '모델 선택',
      inheritLabel: '프로젝트 설정 사용',
      options: <ModelPickerOption>[
        ModelPickerOption(
          providerName: 'OpenAI',
          model: ProviderModelDto(
            connectionId: 'openai',
            id: 'gpt-5.6',
            label: 'GPT-5.6',
            source: ProviderModelSource.bundled,
            capabilities: ModelCapabilitiesDto(),
          ),
        ),
        ModelPickerOption(
          providerName: 'DeepSeek',
          model: ProviderModelDto(
            connectionId: 'deepseek',
            id: 'gpt-5.6-mini',
            label: 'GPT-5.6 mini',
            source: ProviderModelSource.bundled,
            capabilities: ModelCapabilitiesDto(),
          ),
        ),
      ],
    );
    final isMobile = MediaQuery.sizeOf(context).width < 760;
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: isMobile
          ? Align(
              alignment: Alignment.bottomCenter,
              child: TRDrawer(
                semanticLabel: '모델 선택',
                snapPoints: const <double>[0.8, 1],
                content: const SizedBox(height: 520, child: picker),
              ),
            )
          : const Center(
              child: TRDialog(
                semanticLabel: '모델 선택',
                content: SizedBox(width: 560, height: 600, child: picker),
              ),
            ),
    );
  }
}

/// Pins the completion layer for both trigger kinds at once, so the two rows
/// that only a command list shows — a badge and an argument hint — stay in
/// the golden alongside the plain path rows.
class _ComposerSuggestionsGoldenHost extends StatelessWidget {
  const _ComposerSuggestionsGoldenHost({required this.kind});

  final ComposerTriggerKind kind;

  @override
  Widget build(BuildContext context) => ProviderScope(
    overrides: [
      appServicesProvider.overrideWithValue(fakeAppServices(FakeCoderApi())),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: testLocale,
      localizationsDelegates: testLocalizationsDelegates,
      supportedLocales: testSupportedLocales,
      theme: testLightTheme,
      darkTheme: testDarkTheme,
      themeMode: kind == ComposerTriggerKind.command
          ? ThemeMode.light
          : ThemeMode.dark,
      home: Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: SessionComposer(
            enabled: true,
            onSubmit: (_) {},
            suggestions: _state(kind),
            bar: SessionComposerBar(
              hostId: 'server',
              definitions: const <AgentDefinitionDto>[],
              agentDefinitionId: null,
              selection: null,
              onAgentChanged: (_) {},
              onModelChanged: (_, _) {},
              mode: SessionMode.normal,
              onModeChanged: (_) {},
            ),
          ),
        ),
      ),
    ),
  );

  static ComposerSuggestionsState _state(ComposerTriggerKind kind) =>
      switch (kind) {
        ComposerTriggerKind.command => const ComposerSuggestionsState(
          trigger: ComposerTrigger(
            kind: ComposerTriggerKind.command,
            start: 0,
            end: 4,
            query: 'rev',
          ),
          items: <ComposerSuggestion>[
            ComposerSuggestion(
              id: 'agent:review',
              label: 'review',
              replacement: '/review',
              description: 'Reviews the working diff.',
              hint: '<path>',
              badge: 'command',
              matchedIndices: <int>[0, 1, 2],
            ),
            ComposerSuggestion(
              id: 'skill:commit',
              label: 'commit',
              replacement: '/commit',
              description: 'Writes atomic commits.',
              badge: 'skill',
              matchedIndices: <int>[3],
            ),
            ComposerSuggestion(
              id: 'client:clear',
              label: 'clear',
              replacement: '/clear',
              description: 'Clear the composer.',
              badge: 'app',
              matchedIndices: <int>[2],
            ),
          ],
        ),
        ComposerTriggerKind.file => const ComposerSuggestionsState(
          trigger: ComposerTrigger(
            kind: ComposerTriggerKind.file,
            start: 5,
            end: 9,
            query: 'com',
          ),
          items: <ComposerSuggestion>[
            ComposerSuggestion(
              id: 'lib/src/composer.dart',
              label: 'lib/src/composer.dart',
              replacement: '@lib/src/composer.dart',
              description: 'composer.dart',
              matchedIndices: <int>[8, 9, 10],
            ),
            ComposerSuggestion(
              id: 'docs/commands.md',
              label: 'docs/commands.md',
              replacement: '@docs/commands.md',
              description: 'commands.md',
              matchedIndices: <int>[5, 6, 7],
            ),
          ],
        ),
      };
}
