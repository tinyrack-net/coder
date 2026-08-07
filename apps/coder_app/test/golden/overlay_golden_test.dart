import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:coder_app/src/app/coder_app.dart';
import 'package:coder_app/src/app/composition/app_providers.dart';
import 'package:coder_app/src/app/router/app_router.dart';
import 'package:coder_app/src/features/conversation/application/composer_suggestions.dart';
import 'package:coder_app/src/features/conversation/presentation/composer_trigger.dart';
import 'package:coder_app/src/features/conversation/presentation/widgets/composer_suggestions_overlay.dart';
import 'package:coder_app/src/features/conversation/presentation/widgets/session_composer.dart';
import 'package:coder_app/src/features/hosts/domain/host_models.dart';
import 'package:coder_app/src/features/hosts/domain/host_ports.dart';
import 'package:coder_app/src/shared/presentation/model_picker.dart';
import 'package:coder_app/src/shared/presentation/permission_picker.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

import '../support/fake_coder_api.dart';
import '../support/fake_desktop_ports.dart';
import '../support/localization.dart';

void main() {
  unawaited(
    goldenTest(
      'desktop title bar file menu is open',
      fileName: 'desktop_file_menu_open',
      constraints: const BoxConstraints.tightFor(width: 1000, height: 620),
      pumpBeforeTest: (tester) async {
        await tester.pumpAndSettle();
        await tester.tap(find.text('파일'));
        await tester.pumpAndSettle();
      },
      builder: _desktopApp,
    ),
  );

  unawaited(
    goldenTest(
      'desktop about dialog uses the Tinyrack layer',
      fileName: 'desktop_about_dialog',
      constraints: const BoxConstraints.tightFor(width: 1000, height: 620),
      pumpBeforeTest: (tester) async {
        await tester.pumpAndSettle();
        await tester.tap(find.text('도움말'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Tinyrack Coder 정보'));
        await tester.pumpAndSettle();
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
        final chip = find.byKey(const ValueKey('golden-project-chip'));
        await tester.tap(chip);
        await tester.pumpAndSettle();
        expect(find.text('프로젝트 선택'), findsNothing);
        expect(find.text('추가'), findsOneWidget);
        return null;
      },
      builder: _composerChipApp,
    ),
  );

  unawaited(
    goldenTest(
      'permission picker fits its content in a tall window',
      fileName: 'permission_picker_content_sized',
      constraints: const BoxConstraints.tightFor(width: 1000, height: 800),
      builder: _PermissionPickerGoldenHost.new,
    ),
  );

  unawaited(
    goldenTest(
      'terminal context menu is open',
      fileName: 'terminal_context_menu_open',
      constraints: const BoxConstraints.tightFor(width: 1100, height: 760),
      whilePerforming: (tester) async {
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
        return null;
      },
      builder: _terminalApp,
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
}

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

Widget _composerChipApp() => MaterialApp(
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

class _PermissionPickerGoldenHost extends StatelessWidget {
  const _PermissionPickerGoldenHost();

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: testLocale,
    localizationsDelegates: testLocalizationsDelegates,
    supportedLocales: testSupportedLocales,
    theme: testLightTheme,
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
        providerConnectionId: 'openai',
        modelId: 'gpt-5.6',
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
              onModelChanged: (_) {},
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
