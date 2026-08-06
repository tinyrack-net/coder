import 'dart:async';

import 'package:coder_app/src/app.dart';
import 'package:coder_app/src/app_services.dart';
import 'package:coder_app/src/chat/chat_approval_card.dart';
import 'package:coder_app/src/chat/chat_question_card.dart';
import 'package:coder_app/src/chat/chat_timeline_model.dart';
import 'package:coder_app/src/chat/chat_timeline_view.dart';
import 'package:coder_app/src/coder_icons.dart';
import 'package:coder_app/src/coder_selection_row.dart';
import 'package:coder_app/src/controller.dart';
import 'package:coder_app/src/host_models.dart';
import 'package:coder_app/src/host_ports.dart';
import 'package:coder_app/src/model_picker.dart';
import 'package:coder_client/coder_client.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

import 'support/fake_coder_api.dart';
import 'support/localization.dart';

const liveTerminal = TerminalDto(
  id: 'terminal-deep-link',
  worktreeId: 'checkout',
  title: 'Remote terminal',
  shell: ShellSpecDto(executable: '/bin/sh'),
  status: TerminalStatus.running,
  columns: 80,
  rows: 24,
  lastSequence: 0,
);

/// Arguments of an `update_plan` call, as the model sends them.
const Map<String, dynamic> _planArguments = <String, dynamic>{
  'plan': <Map<String, dynamic>>[
    <String, dynamic>{'step': 'Move the parser', 'status': 'pending'},
    <String, dynamic>{'step': 'Add tests', 'status': 'pending'},
  ],
  'explanation': 'Parser first.',
};

void main() {
  final now = DateTime.utc(2026, 8, 3);
  final workspace = WorkspaceDto(
    id: 'workspace',
    name: 'Coder',
    rootPath: '/repos/coder',
    kind: WorkspaceKind.git,
    createdAt: now,
  );
  final checkout = WorktreeDto(
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
  SessionDto session(String id) => SessionDto(
    id: id,
    worktreeId: checkout.id,
    title: 'Session $id',
    agentDefinitionId: 'coder',
    origin: SessionOrigin.manual,
    status: SessionStatus.idle,
    createdAt: now,
    updatedAt: now,
  );

  testWidgets(
    'model picker relies on the dialog for content margins',
    (tester) async {
      const hostKey = ValueKey('model-picker-host');
      await tester.pumpWidget(
        MaterialApp(
          locale: testLocale,
          localizationsDelegates: testLocalizationsDelegates,
          supportedLocales: testSupportedLocales,
          theme: testLightTheme,
          home: const Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                key: hostKey,
                width: 560,
                height: 600,
                child: ModelPicker(
                  options: <ModelPickerOption>[],
                  currentSelection: null,
                  title: 'Model picker',
                ),
              ),
            ),
          ),
        ),
      );

      final host = find.byKey(hostKey);
      final title = find.text('Model picker');
      final search = find.byKey(const ValueKey('model-search-field'));
      expect(tester.getTopLeft(title).dx, tester.getTopLeft(host).dx);
      expect(tester.getSize(search).width, tester.getSize(host).width);
    },
    tags: const <String>['feature_test__session_lifecycle__widget'],
  );

  testWidgets(
    'desktop workspace uses a flat workspace tree and session tabs',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final first = session('one');
      final second = session('two');
      final api = FakeCoderApi(
        workspaces: <WorkspaceDto>[workspace],
        worktrees: <WorktreeDto>[checkout],
        agents: <SessionDto>[first, second],
      );
      final router = await _pumpRoute(
        tester,
        api,
        SessionRoute(
          hostId: 'server',
          workspaceId: workspace.id,
          worktreeId: checkout.id,
          sessionId: first.id,
        ).location,
      );
      addTearDown(router.dispose);

      expect(find.text('Workspaces'), findsOneWidget);
      expect(find.byKey(const ValueKey('workspace-new-button')), findsOne);
      expect(
        find.byKey(const ValueKey<String>('workspace-sidebar-surface')),
        findsOneWidget,
      );
      // The daemon has no tree level of its own; it names the workspace row.
      expect(
        find.text('Test daemon · ${workspace.rootPath}'),
        findsOneWidget,
      );
      expect(find.text('main'), findsOneWidget);
      expect(find.text('Agents'), findsNothing);
      expect(find.text('Session one'), findsWidgets);

      await tester.tap(
        find.byKey(const ValueKey('workspace-all-sessions-menu')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Session two'), findsOneWidget);
      await tester.tap(find.text('Session two'));
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, contains('two'));
    },
    tags: const <String>['feature_test__workspace_catalog__widget'],
  );

  testWidgets(
    'host-scoped settings keep the selected daemon across categories',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final first = FakeCoderApi(
        serverInfo: const ServerInfoDto(
          serverId: 'first-server',
          version: 'test',
          protocolVersion: coderProtocolVersion,
          features: <String, bool>{},
        ),
      );
      final second = FakeCoderApi(
        serverInfo: const ServerInfoDto(
          serverId: 'second-server',
          version: 'test',
          protocolVersion: coderProtocolVersion,
          features: <String, bool>{},
        ),
      );
      addTearDown(first.close);
      addTearDown(second.close);
      final store = MemoryAppStore(
        settings: const AppSettings(embeddedDaemonEnabled: false),
        profiles: <RemoteDaemonProfile>[
          RemoteDaemonProfile(
            id: 'first',
            label: 'First daemon',
            websocketUri: Uri.parse('ws://first.test/ws'),
            autoConnect: true,
            createdAt: now,
            updatedAt: now,
          ),
          RemoteDaemonProfile(
            id: 'second',
            label: 'Second daemon',
            websocketUri: Uri.parse('ws://second.test/ws'),
            autoConnect: true,
            createdAt: now,
            updatedAt: now,
          ),
        ],
        tokens: const <String, String>{
          'first': 'first-token',
          'second': 'second-token',
        },
      );
      await tester.pumpWidget(
        CoderApp(
          services: AppServices(
            settings: store,
            profiles: store,
            credentials: store,
            clients: _MappedClients(<String, CoderApi>{
              'first.test': first,
              'second.test': second,
            }),
            clientKind: 'settings-host-test',
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(CoderIcons.settings));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Agent'));
      await tester.pumpAndSettle();

      final daemonSelect = find.byKey(
        const ValueKey<String>('settings-daemon-select'),
      );
      await tester.tap(daemonSelect);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Second daemon').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('MCP'));
      await tester.pumpAndSettle();

      expect(tester.widget<TRSelect<String>>(daemonSelect).value, 'second');
      expect(store.settings.lastActiveHostId, 'second');

      // App-wide categories carry no daemon, so passing through one used to
      // drop the selection back to the first online daemon.
      await tester.tap(find.text('General'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Projects'));
      await tester.pumpAndSettle();
      expect(tester.widget<TRSelect<String>>(daemonSelect).value, 'second');

      // A daemon card's provider shortcut names its host in the location and
      // replaces the settings page rather than pushing another one, so the
      // page outlives the change and has to adopt each daemon a later location
      // names, not only the first.
      Future<void> openProviderShortcut(String address) async {
        await tester.tap(find.text('Daemons'));
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(
            of: find
                .ancestor(
                  of: find.textContaining(address),
                  matching: find.byType(TRCard),
                )
                .first,
            matching: find.widgetWithText(TRButton, 'Provider 설정'),
          ),
        );
        await tester.pumpAndSettle();
      }

      await openProviderShortcut('ws://first.test/ws');
      expect(tester.widget<TRSelect<String>>(daemonSelect).value, 'first');
      await openProviderShortcut('ws://second.test/ws');
      expect(tester.widget<TRSelect<String>>(daemonSelect).value, 'second');
    },
    tags: const <String>['feature_test__daemon_management__widget'],
  );

  testWidgets(
    'the settings sidebar daemon select is framed by the sidebar, not itself',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final api = FakeCoderApi(
        serverInfo: const ServerInfoDto(
          serverId: 'sidebar-server',
          version: 'test',
          protocolVersion: coderProtocolVersion,
          features: <String, bool>{},
        ),
      );
      addTearDown(api.close);
      final store = MemoryAppStore(
        settings: const AppSettings(embeddedDaemonEnabled: false),
        profiles: <RemoteDaemonProfile>[
          RemoteDaemonProfile(
            id: 'only',
            label: 'Only daemon',
            websocketUri: Uri.parse('ws://only.test/ws'),
            autoConnect: true,
            createdAt: now,
            updatedAt: now,
          ),
        ],
        tokens: const <String, String>{'only': 'only-token'},
      );
      await tester.pumpWidget(
        CoderApp(
          services: AppServices(
            settings: store,
            profiles: store,
            credentials: store,
            clients: _MappedClients(<String, CoderApi>{'only.test': api}),
            clientKind: 'sidebar-daemon-select-test',
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(CoderIcons.settings));
      await tester.pumpAndSettle();

      // The sidebar is a flat list of borderless nav rows, so a boxed select
      // trigger sitting among them reads as a foreign control.
      final daemonSelect = find.byKey(
        const ValueKey<String>('settings-daemon-select'),
      );
      expect(
        tester.widget<TRSelect<String>>(daemonSelect).appearance,
        TRFieldAppearance.ghost,
      );
    },
    tags: const <String>['feature_test__daemon_management__widget'],
  );

  testWidgets(
    'the draft composer stays quiet while agent discovery is still loading',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 760));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final gate = Completer<void>();
      final api = FakeCoderApi(
        workspaces: <WorkspaceDto>[workspace],
        worktrees: <WorktreeDto>[checkout],
        agentDefinitions: const <AgentDefinitionDto>[],
        agentDefinitionsGate: gate.future,
      );
      final router = await _pumpRoute(
        tester,
        api,
        WorktreeRoute(
          hostId: 'server',
          workspaceId: workspace.id,
          worktreeId: checkout.id,
        ).location,
        settle: false,
      );
      addTearDown(router.dispose);
      await tester.pump();
      await tester.pump();

      expect(find.text('사용 가능한 primary Agent가 없습니다.'), findsNothing);

      gate.complete();
      await tester.pumpAndSettle();

      expect(find.text('사용 가능한 primary Agent가 없습니다.'), findsOneWidget);
    },
    tags: const <String>['feature_test__workspace_catalog__widget'],
  );

  testWidgets(
    'session tab strip is one control tall and its commands are square',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 760));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final first = session('one');
      final api = FakeCoderApi(
        workspaces: <WorkspaceDto>[workspace],
        worktrees: <WorktreeDto>[checkout],
        agents: <SessionDto>[first],
      );
      final router = await _pumpRoute(
        tester,
        api,
        SessionRoute(
          hostId: 'server',
          workspaceId: workspace.id,
          worktreeId: checkout.id,
          sessionId: first.id,
        ).location,
      );
      addTearDown(router.dispose);

      expect(
        tester.getSize(find.byKey(const ValueKey('session-tab-strip'))).height,
        sessionTabBarHeight,
      );

      // The two menu commands sit beside the square close buttons on each tab,
      // so a wide trigger would read as a stray pill in that row.
      final square = Size.square(TRControlMetrics.heightOf(TRUiSize.md));
      for (final key in const <String>[
        'workspace-new-tab-menu',
        'workspace-all-sessions-menu',
      ]) {
        expect(
          tester.getSize(find.byKey(ValueKey<String>(key))),
          square,
          reason: key,
        );
      }
    },
    tags: const <String>['feature_test__session_tabs__widget'],
  );

  testWidgets(
    'session tabs close locally and reopen from the picker',
    (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1100, 760));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final first = session('one');
      final api = FakeCoderApi(
        workspaces: <WorkspaceDto>[workspace],
        worktrees: <WorktreeDto>[checkout],
        agents: <SessionDto>[first],
      );
      final router = await _pumpRoute(
        tester,
        api,
        SessionRoute(
          hostId: 'server',
          workspaceId: workspace.id,
          worktreeId: checkout.id,
          sessionId: first.id,
        ).location,
      );
      addTearDown(router.dispose);

      await tester.tap(
        find.byKey(const ValueKey('session-tab-close-one')),
      );
      await tester.pumpAndSettle();
      expect(find.text('코딩 요청으로 새 session을 시작하세요.'), findsOneWidget);
      expect(await api.listSessions(worktreeId: checkout.id), <SessionDto>[
        first,
      ]);

      await tester.tap(
        find.byKey(const ValueKey('workspace-all-sessions-menu')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Session one'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('session-tab-close-one')),
        findsOneWidget,
      );
    },
    tags: const <String>['feature_test__session_tabs__widget'],
  );

  testWidgets(
    'new-tab menu creates a terminal and confirms termination on close',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 760));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final api = FakeCoderApi(
        workspaces: <WorkspaceDto>[workspace],
        worktrees: <WorktreeDto>[checkout],
      );
      final router = await _pumpRoute(
        tester,
        api,
        WorktreeRoute(
          hostId: 'server',
          workspaceId: workspace.id,
          worktreeId: checkout.id,
        ).location,
      );
      addTearDown(router.dispose);

      await tester.tap(find.byKey(const ValueKey('workspace-new-tab-menu')));
      await tester.pumpAndSettle();
      expect(find.text('새 session'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('workspace-new-terminal')));
      await tester.pumpAndSettle();

      expect(find.byType(TRTerminalView), findsOneWidget);
      expect(find.text('Terminal 1'), findsOneWidget);
      final terminal = (await api.listTerminals(checkout.id)).single;
      await tester.tap(
        find.byKey(ValueKey<String>('terminal-tab-close-${terminal.id}')),
      );
      await tester.pumpAndSettle();
      expect(find.text('터미널을 종료할까요?'), findsOneWidget);
      await tester.tap(find.widgetWithText(TRButton, '취소'));
      await tester.pumpAndSettle();
      expect(find.byType(TRTerminalView), findsOneWidget);
      await tester.tap(
        find.byKey(ValueKey<String>('terminal-tab-close-${terminal.id}')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('terminal-close-confirm')));
      await tester.pumpAndSettle();
      expect(
        (await api.listTerminals(checkout.id)).single.status,
        TerminalStatus.exited,
      );
      expect(find.byType(TRTerminalView), findsNothing);
    },
    tags: const <String>['feature_test__terminal_lifecycle__widget'],
  );

  testWidgets('terminal tab shows attach failures and closes exited shells', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1100, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const terminal = TerminalDto(
      id: 'terminal-failed-attach',
      worktreeId: 'checkout',
      title: 'Exited terminal',
      shell: ShellSpecDto(executable: '/bin/sh'),
      status: TerminalStatus.exited,
      columns: 80,
      rows: 24,
      lastSequence: 0,
      exitCode: 0,
    );
    final router = await _pumpRoute(
      tester,
      FakeCoderApi(
        workspaces: <WorkspaceDto>[workspace],
        worktrees: <WorktreeDto>[checkout],
        terminals: const <TerminalDto>[terminal],
        terminalAttachError: Exception('host disconnected'),
      ),
      TerminalRoute(
        hostId: 'server',
        workspaceId: workspace.id,
        worktreeId: checkout.id,
        terminalId: terminal.id,
      ).location,
    );
    addTearDown(router.dispose);

    expect(find.text('터미널 연결에 실패했어요'), findsOneWidget);
    expect(find.textContaining('host disconnected'), findsOneWidget);
    await tester.tap(
      find.byKey(ValueKey<String>('terminal-tab-close-${terminal.id}')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('terminal-close-dialog')), findsNothing);
  });

  testWidgets(
    'terminal deep link restores the requested live terminal',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 760));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      const terminal = TerminalDto(
        id: 'terminal-deep-link',
        worktreeId: 'checkout',
        title: 'Remote terminal',
        shell: ShellSpecDto(executable: '/bin/sh'),
        status: TerminalStatus.running,
        columns: 80,
        rows: 24,
        lastSequence: 0,
      );
      final router = await _pumpRoute(
        tester,
        FakeCoderApi(
          workspaces: <WorkspaceDto>[workspace],
          worktrees: <WorktreeDto>[checkout],
          terminals: const <TerminalDto>[terminal],
          terminalReplay: const <TerminalOutputDto>[
            TerminalOutputDto(
              terminalId: 'terminal-deep-link',
              sequence: 1,
              data: 'ready\r\n',
            ),
            TerminalOutputDto(
              terminalId: 'terminal-deep-link',
              sequence: 1,
              data: 'duplicate',
            ),
          ],
        ),
        TerminalRoute(
          hostId: 'server',
          workspaceId: workspace.id,
          worktreeId: checkout.id,
          terminalId: terminal.id,
        ).location,
      );
      addTearDown(router.dispose);

      expect(find.byType(TRTerminalView), findsOneWidget);
      expect(find.text('Remote terminal'), findsOneWidget);
    },
    tags: const <String>[
      'feature_test__terminal_lifecycle__widget',
      'route_test__terminal_route__widget',
    ],
  );

  testWidgets(
    'terminal sends a Hangul word the input method composes exactly once',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 760));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final api = FakeCoderApi(
        workspaces: <WorkspaceDto>[workspace],
        worktrees: <WorktreeDto>[checkout],
        terminals: const <TerminalDto>[liveTerminal],
      );
      final router = await _pumpRoute(
        tester,
        api,
        TerminalRoute(
          hostId: 'server',
          workspaceId: workspace.id,
          worktreeId: checkout.id,
          terminalId: liveTerminal.id,
        ).location,
      );
      addTearDown(router.dispose);

      // A Hangul input method keeps its committed text in the platform editing
      // buffer for the whole composition session instead of letting the
      // terminal reset it between syllables.
      for (final value in const <TextEditingValue>[
        TextEditingValue(
          text: 'ㅂ',
          selection: TextSelection.collapsed(offset: 1),
          composing: TextRange(start: 0, end: 1),
        ),
        TextEditingValue(
          text: '반',
          selection: TextSelection.collapsed(offset: 1),
          composing: TextRange(start: 0, end: 1),
        ),
        TextEditingValue(
          text: '반',
          selection: TextSelection.collapsed(offset: 1),
        ),
        TextEditingValue(
          text: '반갑',
          selection: TextSelection.collapsed(offset: 2),
          composing: TextRange(start: 1, end: 2),
        ),
        TextEditingValue(
          text: '반갑',
          selection: TextSelection.collapsed(offset: 2),
        ),
        TextEditingValue(
          text: '반갑다',
          selection: TextSelection.collapsed(offset: 3),
          composing: TextRange(start: 2, end: 3),
        ),
        TextEditingValue(
          text: '반갑다',
          selection: TextSelection.collapsed(offset: 3),
        ),
      ]) {
        tester.testTextInput.updateEditingValue(value);
        await tester.pump();
      }

      expect(
        api.terminalWrites.map((write) => write.data).join(),
        '반갑다',
      );
      expect(
        api.terminalWrites.map((write) => write.terminalId).toSet(),
        <String>{liveTerminal.id},
      );
    },
    tags: const <String>['feature_test__terminal_lifecycle__widget'],
  );

  testWidgets(
    'terminal ignores the duplicate commit a sticky input method repeats',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 760));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final api = FakeCoderApi(
        workspaces: <WorkspaceDto>[workspace],
        worktrees: <WorktreeDto>[checkout],
        terminals: const <TerminalDto>[liveTerminal],
      );
      final router = await _pumpRoute(
        tester,
        api,
        TerminalRoute(
          hostId: 'server',
          workspaceId: workspace.id,
          worktreeId: checkout.id,
          terminalId: liveTerminal.id,
        ).location,
      );
      addTearDown(router.dispose);

      // A sticky input method ends its composition session by reporting the
      // unchanged committed buffer one more time, without a new character.
      for (final value in const <TextEditingValue>[
        TextEditingValue(
          text: '한',
          selection: TextSelection.collapsed(offset: 1),
          composing: TextRange(start: 0, end: 1),
        ),
        TextEditingValue(
          text: '한',
          selection: TextSelection.collapsed(offset: 1),
        ),
        TextEditingValue(
          text: '한솔',
          selection: TextSelection.collapsed(offset: 2),
          composing: TextRange(start: 1, end: 2),
        ),
        TextEditingValue(
          text: '한솔',
          selection: TextSelection.collapsed(offset: 2),
        ),
        TextEditingValue(
          text: '한솔',
          selection: TextSelection.collapsed(offset: 2),
        ),
      ]) {
        tester.testTextInput.updateEditingValue(value);
        await tester.pump();
      }

      expect(
        api.terminalWrites.map((write) => write.data).join(),
        '한솔',
      );
    },
    tags: const <String>['feature_test__terminal_lifecycle__widget'],
  );

  testWidgets(
    'terminal context menu closes on a terminal click and on Escape',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 760));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final api = FakeCoderApi(
        workspaces: <WorkspaceDto>[workspace],
        worktrees: <WorktreeDto>[checkout],
        terminals: const <TerminalDto>[liveTerminal],
      );
      final router = await _pumpRoute(
        tester,
        api,
        TerminalRoute(
          hostId: 'server',
          workspaceId: workspace.id,
          worktreeId: checkout.id,
          terminalId: liveTerminal.id,
        ).location,
      );
      addTearDown(router.dispose);

      final copy = find.byKey(const ValueKey<String>('terminal-menu-copy'));
      final surface = find.byKey(const ValueKey<String>('tr-terminal-surface'));

      Future<void> openMenu() async {
        final gesture = await tester.startGesture(
          tester.getTopLeft(surface) + const Offset(24, 24),
          kind: PointerDeviceKind.mouse,
          buttons: kSecondaryButton,
        );
        await tester.pump(const Duration(milliseconds: 50));
        await gesture.up();
        await tester.pumpAndSettle();
      }

      await openMenu();
      expect(copy, findsOneWidget);

      // The terminal anchors its own menu, so a click on the terminal is not
      // an outside tap for the menu's tap region and must still close it.
      await tester.tapAt(tester.getBottomRight(surface) - const Offset(48, 48));
      await tester.pumpAndSettle();
      expect(copy, findsNothing);
      // Let the terminal's double-tap recognition window expire.
      await tester.pump(const Duration(milliseconds: 350));

      await openMenu();
      expect(copy, findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(copy, findsNothing);

      // Closing the menu consumed Escape instead of sending it to the shell.
      expect(
        api.terminalWrites.map((write) => write.data).join(),
        isNot(contains('\x1b')),
      );
    },
    tags: const <String>['feature_test__terminal_lifecycle__widget'],
  );

  testWidgets(
    'terminal context menu copies the selection and pastes the clipboard',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 760));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      String? clipboard;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          switch (call.method) {
            case 'Clipboard.setData':
              final arguments = call.arguments as Map<Object?, Object?>;
              clipboard = arguments['text'] as String?;
              return null;
            case 'Clipboard.getData':
              return <String, Object?>{'text': clipboard};
            default:
              return null;
          }
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      final api = FakeCoderApi(
        workspaces: <WorkspaceDto>[workspace],
        worktrees: <WorktreeDto>[checkout],
        terminals: const <TerminalDto>[liveTerminal],
        terminalReplay: const <TerminalOutputDto>[
          TerminalOutputDto(
            terminalId: 'terminal-deep-link',
            sequence: 1,
            data: 'selectable output',
          ),
        ],
      );
      final router = await _pumpRoute(
        tester,
        api,
        TerminalRoute(
          hostId: 'server',
          workspaceId: workspace.id,
          worktreeId: checkout.id,
          terminalId: liveTerminal.id,
        ).location,
      );
      addTearDown(router.dispose);

      final copy = find.byKey(const ValueKey<String>('terminal-menu-copy'));
      expect(copy, findsNothing);

      Future<void> openMenu() async {
        final surface = find.byKey(
          const ValueKey<String>('tr-terminal-surface'),
        );
        final gesture = await tester.startGesture(
          tester.getTopLeft(surface) + const Offset(24, 24),
          kind: PointerDeviceKind.mouse,
          buttons: kSecondaryButton,
        );
        await tester.pump(const Duration(milliseconds: 50));
        await gesture.up();
        await tester.pumpAndSettle();
      }

      await openMenu();
      expect(copy, findsOneWidget);
      expect(find.text('붙여넣기'), findsOneWidget);

      // Copy stays unavailable until something is selected.
      expect(tester.widget<TRMenuItem>(copy).onPressed, isNull);
      await tester.tap(
        find.byKey(const ValueKey<String>('terminal-menu-select-all')),
      );
      await tester.pumpAndSettle();

      await openMenu();
      await tester.tap(copy);
      await tester.pumpAndSettle();
      expect(clipboard, contains('selectable output'));

      await openMenu();
      await tester.tap(
        find.byKey(const ValueKey<String>('terminal-menu-paste')),
      );
      await tester.pumpAndSettle();
      expect(
        api.terminalWrites.map((write) => write.data).join(),
        contains('selectable output'),
      );

      await openMenu();
      await tester.tap(
        find.byKey(const ValueKey<String>('terminal-menu-clear-screen')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(TRTerminalView), findsOneWidget);
    },
    tags: const <String>['feature_test__terminal_lifecycle__widget'],
  );

  testWidgets(
    'archives a managed worktree from the sidebar',
    (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1100, 760));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final managed = WorktreeDto(
        id: 'managed',
        workspaceId: workspace.id,
        name: 'feature/settings',
        path: '/worktrees/feature-settings',
        branch: 'feature/settings',
        kind: WorktreeKind.managed,
        isCoderOwned: true,
        createdAt: now,
      );
      final api =
          FakeCoderApi(
              workspaces: <WorkspaceDto>[workspace],
              worktrees: <WorktreeDto>[checkout, managed],
            )
            ..archiveWorktreeHookRuns = const <WorktreeHookRunDto>[
              WorktreeHookRunDto(
                phase: WorktreeHookPhase.teardown,
                command: 'docker compose down',
                exitCode: 1,
                stdout: '',
                stderr: 'no such service',
              ),
            ];
      final router = await _pumpRoute(
        tester,
        api,
        WorktreeRoute(
          hostId: 'server',
          workspaceId: workspace.id,
          worktreeId: managed.id,
        ).location,
      );
      addTearDown(router.dispose);
      await tester.pumpAndSettle();

      expect(findAccessibleAction('새 worktree'), findsNothing);
      expect(find.text('feature/settings'), findsWidgets);

      final menus = findAccessibleAction('Worktree 메뉴');
      await tester.tap(menus.last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Archive'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Archive할까요?'), findsOneWidget);
      await tester.tap(find.widgetWithText(TRButton, 'Archive'));
      await tester.pumpAndSettle();
      expect(find.text('feature/settings'), findsNothing);
      expect(router.routeInformationProvider.value.uri.path, '/');
      // Teardown never blocks the archive, so the failure is only reported.
      expect(
        find.text('Teardown 실패 (exit 1): docker compose down'),
        findsOneWidget,
      );
      expect(find.textContaining('no such service'), findsOneWidget);
    },
    tags: const <String>['feature_test__worktree_lifecycle__widget'],
  );

  testWidgets(
    'an archive that outlives its sidebar finishes without throwing',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 760));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final managed = WorktreeDto(
        id: 'managed',
        workspaceId: workspace.id,
        name: 'feature/settings',
        path: '/worktrees/feature-settings',
        branch: 'feature/settings',
        kind: WorktreeKind.managed,
        isCoderOwned: true,
        createdAt: now,
      );
      final gate = Completer<void>();
      final api = FakeCoderApi(
        workspaces: <WorkspaceDto>[workspace],
        worktrees: <WorktreeDto>[checkout, managed],
      )..archiveWorktreeGate = gate;
      final router = await _pumpRoute(
        tester,
        api,
        WorktreeRoute(
          hostId: 'server',
          workspaceId: workspace.id,
          worktreeId: managed.id,
        ).location,
      );
      addTearDown(router.dispose);
      await tester.pumpAndSettle();

      await tester.tap(findAccessibleAction('Worktree 메뉴').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Archive'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TRButton, 'Archive'));
      await tester.pump();

      // Archiving the selected worktree tears the sidebar down, so the call
      // finishes with nothing left to read a provider from.
      await tester.pumpWidget(const SizedBox.shrink());
      gate.complete();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    },
    tags: const <String>['feature_test__worktree_lifecycle__widget'],
  );

  testWidgets(
    'the project select registers a project through the daemon browser',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final api = FakeCoderApi(
        directories: const <String, List<String>>{
          '/': <String>['/srv'],
          '/srv': <String>['/srv/repositories'],
          '/srv/repositories': <String>['/srv/repositories/project'],
        },
      );
      final router = await _pumpRoute(
        tester,
        api,
        const WorkspaceHomeRoute().location,
      );
      addTearDown(router.dispose);
      await tester.pumpAndSettle();

      expect(find.text('폴더 추가'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('new-workspace-project')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('new-workspace-project-add')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Daemon의 폴더 선택'), findsOneWidget);
      await tester.tap(find.text('srv'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('repositories'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('project'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TRButton, '이 폴더 선택'));
      await tester.pumpAndSettle();

      expect(api.registeredPaths, <String>['/srv/repositories/project']);
      expect(find.text('project'), findsWidgets);
    },
    tags: const <String>['feature_test__workspace_registration__widget'],
  );

  testWidgets(
    'the sidebar collapses and restores from persisted settings',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final api = FakeCoderApi(
        workspaces: <WorkspaceDto>[workspace],
        worktrees: <WorktreeDto>[checkout],
      );
      final store = MemoryAppStore();
      final router = await _pumpRoute(
        tester,
        api,
        const WorkspaceHomeRoute().location,
        store: store,
      );
      addTearDown(router.dispose);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('workspace-new-button')), findsOne);
      await tester.tap(find.byKey(const ValueKey('workspace-sidebar-toggle')));
      // Toggling refreshes the host registry; the composer must keep its
      // loaded state instead of flashing an empty-state error.
      await tester.pump();
      expect(find.text('먼저 프로젝트를 추가하세요.'), findsNothing);
      expect(find.byKey(const ValueKey('session-composer-model')), findsOne);
      expect(find.text('사용 가능한 primary Agent가 없습니다.'), findsNothing);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('workspace-new-button')), findsNothing);
      expect(store.settings.sidebarCollapsed, isTrue);

      await tester.tap(find.byKey(const ValueKey('workspace-sidebar-toggle')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('workspace-new-button')), findsOne);
      expect(store.settings.sidebarCollapsed, isFalse);
    },
    tags: const <String>['feature_test__workspace_catalog__widget'],
  );

  testWidgets(
    'the sidebar animates between its expanded and collapsed widths',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final api = FakeCoderApi(
        workspaces: <WorkspaceDto>[workspace],
        worktrees: <WorktreeDto>[checkout],
      );
      final router = await _pumpRoute(
        tester,
        api,
        const WorkspaceHomeRoute().location,
        store: MemoryAppStore(),
      );
      addTearDown(router.dispose);
      await tester.pumpAndSettle();

      final surface = find.byKey(const ValueKey('workspace-sidebar-surface'));
      final expanded = tester.getSize(surface).width;
      expect(expanded, greaterThan(0));

      await tester.tap(find.byKey(const ValueKey('workspace-sidebar-toggle')));
      await tester.pump();
      await tester.pump(TRMotion.normal ~/ 2);
      final collapsing = tester.getSize(surface).width;
      expect(collapsing, greaterThan(0));
      expect(collapsing, lessThan(expanded));

      await tester.pumpAndSettle();
      expect(tester.getSize(surface).width, 0);

      await tester.tap(find.byKey(const ValueKey('workspace-sidebar-toggle')));
      await tester.pump();
      await tester.pump(TRMotion.normal ~/ 2);
      final expanding = tester.getSize(surface).width;
      expect(expanding, greaterThan(0));
      expect(expanding, lessThan(expanded));

      await tester.pumpAndSettle();
      expect(tester.getSize(surface).width, expanded);
    },
    tags: const <String>['feature_test__workspace_catalog__widget'],
  );

  testWidgets(
    'reduced motion collapses the sidebar without animating',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final api = FakeCoderApi(
        workspaces: <WorkspaceDto>[workspace],
        worktrees: <WorktreeDto>[checkout],
      );
      final router = await _pumpRoute(
        tester,
        api,
        const WorkspaceHomeRoute().location,
        store: MemoryAppStore(),
        disableAnimations: true,
      );
      addTearDown(router.dispose);
      await tester.pumpAndSettle();

      final surface = find.byKey(const ValueKey('workspace-sidebar-surface'));
      expect(tester.getSize(surface).width, greaterThan(0));

      await tester.tap(find.byKey(const ValueKey('workspace-sidebar-toggle')));
      // One frame settles the persisted flag and the collapse together.
      await tester.pump();
      expect(tester.getSize(surface).width, 0);
    },
    tags: const <String>['feature_test__workspace_catalog__widget'],
  );

  testWidgets(
    'a collapsed sidebar is unreachable by pointer, semantics, and keyboard',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final semantics = tester.ensureSemantics();
      final api = FakeCoderApi(
        workspaces: <WorkspaceDto>[workspace],
        worktrees: <WorktreeDto>[checkout],
      );
      final router = await _pumpRoute(
        tester,
        api,
        const WorkspaceHomeRoute().location,
        store: MemoryAppStore(),
      );
      addTearDown(router.dispose);
      await tester.pumpAndSettle();

      final newWorkspace = find.byKey(const ValueKey('workspace-new-button'));
      expect(newWorkspace.hitTestable(), findsOne);

      await tester.tap(find.byKey(const ValueKey('workspace-sidebar-toggle')));
      await tester.pump();
      expect(newWorkspace.hitTestable(), findsNothing);

      await tester.pumpAndSettle();
      expect(newWorkspace, findsNothing);
      final surface = find.byKey(const ValueKey('workspace-sidebar-surface'));
      // The detail pane keeps its own "New workspace" heading, so scope the
      // semantics check to the sidebar the toggle collapsed.
      expect(
        find.descendant(
          of: surface,
          matching: find.bySemanticsLabel('New workspace'),
        ),
        findsNothing,
      );
      for (var press = 0; press < 6; press++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        final focused = FocusManager.instance.primaryFocus?.context;
        if (focused == null) continue;
        expect(
          find
              .ancestor(of: find.byWidget(focused.widget), matching: surface)
              .evaluate(),
          isEmpty,
        );
      }
      semantics.dispose();
    },
    tags: const <String>['feature_test__workspace_catalog__widget'],
  );

  testWidgets('mobile opens selected worktree as a session-only detail', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 780));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final api = FakeCoderApi(
      workspaces: <WorkspaceDto>[workspace],
      worktrees: <WorktreeDto>[checkout],
    );
    final router = await _pumpRoute(
      tester,
      api,
      WorktreeRoute(
        hostId: 'server',
        workspaceId: workspace.id,
        worktreeId: checkout.id,
      ).location,
    );
    addTearDown(router.dispose);

    expect(find.byKey(const ValueKey('workspace-new-button')), findsNothing);
    expect(find.text('코딩 요청으로 새 session을 시작하세요.'), findsOneWidget);
    await tester.tap(find.byIcon(CoderIcons.back));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('workspace-new-button')), findsOne);
  });

  testWidgets(
    'creates a session and sends a coding request',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 760));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      const planner = AgentDefinitionDto(
        id: 'planner',
        name: 'Planner',
        description: 'Plans changes',
        mode: AgentMode.primary,
        promptEnabled: true,
        systemPrompt: 'Plan first.',
        model: AgentModelSelectionDto(
          source: AgentModelSource.session,
        ),
        reasoningEffort: 'medium',
        permissionMode: PermissionMode.readOnly,
        toolIds: <String>['read_file'],
        callableAgentIds: <String>[],
        contentHash: 'planner-hash',
        sourcePath: '/config/agents/planner.md',
      );
      final api = FakeCoderApi(
        workspaces: <WorkspaceDto>[workspace],
        worktrees: <WorktreeDto>[checkout],
        agentDefinitions: const <AgentDefinitionDto>[planner],
        connections: <ProviderConnectionDto>[
          ProviderConnectionDto(
            id: 'openai',
            definitionId: 'openai',
            displayName: 'OpenAI',
            status: ProviderConnectionStatus.connected,
            authKind: ProviderAuthKind.apiKey,
            credentialOrigin: ProviderCredentialOrigin.stored,
            createdAt: now,
            updatedAt: now,
          ),
          ProviderConnectionDto(
            id: 'deepseek',
            definitionId: 'deepseek',
            displayName: 'DeepSeek',
            status: ProviderConnectionStatus.connected,
            authKind: ProviderAuthKind.apiKey,
            credentialOrigin: ProviderCredentialOrigin.stored,
            createdAt: now,
            updatedAt: now,
          ),
        ],
        models: const <String, List<ProviderModelDto>>{
          'deepseek': <ProviderModelDto>[
            ProviderModelDto(
              connectionId: 'deepseek',
              id: 'gpt-5.6-sol',
              label: 'Shared Model',
              source: ProviderModelSource.bundled,
              capabilities: ModelCapabilitiesDto(
                streaming: CapabilitySupport.supported,
                toolCalling: CapabilitySupport.supported,
              ),
            ),
          ],
        },
      );
      final router = await _pumpRoute(
        tester,
        api,
        WorktreeRoute(
          hostId: 'server',
          workspaceId: workspace.id,
          worktreeId: checkout.id,
        ).location,
      );
      addTearDown(router.dispose);

      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('session-composer-agent')), findsOne);
      expect(find.text('Planner'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('session-composer-provider')),
        findsNothing,
      );
      await tester.tap(find.byKey(const ValueKey('session-composer-model')));
      await tester.pumpAndSettle();
      expect(find.textContaining('OpenAI · gpt-5.6-sol'), findsOneWidget);
      expect(find.text('DeepSeek · gpt-5.6-sol'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('model-search-field')),
        'DeepSeek',
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('OpenAI · gpt-5.6-sol'), findsNothing);
      expect(find.text('DeepSeek · gpt-5.6-sol'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('model-option-deepseek-gpt-5.6-sol')),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('session-composer-input')),
        'Run the tests',
      );
      await tester.tap(find.byKey(const ValueKey('session-composer-send')));
      await tester.pumpAndSettle();

      final created = api.createdSessions.single;
      expect(created.agentDefinitionId, 'planner');
      expect(created.title, 'Run the tests');
      expect(
        created.model,
        const SessionModelSelectionDto(
          providerConnectionId: 'deepseek',
          modelId: 'gpt-5.6-sol',
        ),
      );
      expect(api.startedPrompts, <String>['Run the tests']);
    },
    tags: const <String>['feature_test__session_lifecycle__widget'],
  );

  testWidgets(
    'composer pins a model at creation and clears it mid-session',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 760));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      const fast = ProviderModelDto(
        connectionId: 'openai',
        id: 'gpt-5.6-fast',
        label: 'GPT-5.6 Fast',
        source: ProviderModelSource.bundled,
        capabilities: ModelCapabilitiesDto(
          streaming: CapabilitySupport.supported,
          toolCalling: CapabilitySupport.supported,
        ),
      );
      final api = FakeCoderApi(
        workspaces: <WorkspaceDto>[workspace],
        worktrees: <WorktreeDto>[checkout],
        connections: <ProviderConnectionDto>[
          ProviderConnectionDto(
            id: 'openai',
            definitionId: 'openai',
            displayName: 'OpenAI',
            status: ProviderConnectionStatus.connected,
            authKind: ProviderAuthKind.apiKey,
            credentialOrigin: ProviderCredentialOrigin.stored,
            createdAt: now,
            updatedAt: now,
          ),
          ProviderConnectionDto(
            id: 'deepseek',
            definitionId: 'deepseek',
            displayName: 'DeepSeek',
            status: ProviderConnectionStatus.degraded,
            authKind: ProviderAuthKind.apiKey,
            credentialOrigin: ProviderCredentialOrigin.stored,
            createdAt: now,
            updatedAt: now,
          ),
        ],
        agentDefinitions: const <AgentDefinitionDto>[
          AgentDefinitionDto(
            id: 'coder',
            name: 'Coder',
            description: 'Coding agent',
            mode: AgentMode.primary,
            promptEnabled: true,
            systemPrompt: 'Code carefully.',
            model: AgentModelSelectionDto(
              source: AgentModelSource.fixed,
              providerConnectionId: 'openai',
              modelId: 'gpt-5.6-sol',
            ),
            reasoningEffort: 'medium',
            permissionMode: PermissionMode.ask,
            toolIds: <String>['read_file'],
            callableAgentIds: <String>[],
            contentHash: 'coder-hash',
            sourcePath: '/config/agents/coder.md',
            isBuiltIn: true,
          ),
        ],
        models: <String, List<ProviderModelDto>>{
          'openai': <ProviderModelDto>[
            const ProviderModelDto(
              connectionId: 'openai',
              id: 'gpt-5.6-sol',
              label: 'GPT-5.6 Sol',
              source: ProviderModelSource.bundled,
              capabilities: ModelCapabilitiesDto(
                streaming: CapabilitySupport.supported,
                toolCalling: CapabilitySupport.supported,
              ),
            ),
            fast,
          ],
          'deepseek': <ProviderModelDto>[
            const ProviderModelDto(
              connectionId: 'deepseek',
              id: 'deepseek-v4',
              label: 'DeepSeek V4',
              source: ProviderModelSource.bundled,
              capabilities: ModelCapabilitiesDto(
                streaming: CapabilitySupport.supported,
                toolCalling: CapabilitySupport.supported,
              ),
            ),
          ],
        },
      );
      final router = await _pumpRoute(
        tester,
        api,
        WorktreeRoute(
          hostId: 'server',
          workspaceId: workspace.id,
          worktreeId: checkout.id,
        ).location,
      );
      addTearDown(router.dispose);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('session-composer-model')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('model-option-openai-gpt-5.6-fast')),
      );
      await tester.pumpAndSettle();
      expect(find.text('GPT-5.6 Fast'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('session-composer-input')),
        'Speed up the build',
      );
      await tester.tap(find.byKey(const ValueKey('session-composer-send')));
      await tester.pumpAndSettle();
      expect(
        api.createdSessions.single.model,
        const SessionModelSelectionDto(
          providerConnectionId: 'openai',
          modelId: 'gpt-5.6-fast',
        ),
      );

      await tester.tap(find.byKey(const ValueKey('session-composer-model')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('model-option-deepseek-deepseek-v4')),
      );
      await tester.pumpAndSettle();
      expect(
        api.updatedSessionModels.single.model,
        const SessionModelSelectionDto(
          providerConnectionId: 'deepseek',
          modelId: 'deepseek-v4',
        ),
      );

      await tester.tap(find.byKey(const ValueKey('session-composer-model')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('model-option-inherit')));
      await tester.pumpAndSettle();
      expect(api.updatedSessionModels.last.model, isNull);
      expect((await api.listSessions()).single.model, isNull);
    },
    tags: const <String>['feature_test__session_lifecycle__widget'],
  );

  testWidgets(
    'composer turn settings follow model capabilities and return to inherit',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 760));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final api = FakeCoderApi(
        workspaces: <WorkspaceDto>[workspace],
        worktrees: <WorktreeDto>[checkout],
        connections: <ProviderConnectionDto>[
          ProviderConnectionDto(
            id: 'openai',
            definitionId: 'openai',
            displayName: 'OpenAI',
            status: ProviderConnectionStatus.connected,
            authKind: ProviderAuthKind.apiKey,
            credentialOrigin: ProviderCredentialOrigin.stored,
            createdAt: now,
            updatedAt: now,
          ),
        ],
        models: const <String, List<ProviderModelDto>>{
          'openai': <ProviderModelDto>[
            ProviderModelDto(
              connectionId: 'openai',
              id: 'gpt-5.6-sol',
              label: 'GPT-5.6 Sol',
              source: ProviderModelSource.bundled,
              capabilities: ModelCapabilitiesDto(
                streaming: CapabilitySupport.supported,
                toolCalling: CapabilitySupport.supported,
                reasoningEffort: CapabilitySupport.supported,
                serviceTier: CapabilitySupport.supported,
                supportedReasoningEfforts: <String>['low', 'high'],
                supportedServiceTiers: <String>['default', 'priority'],
              ),
            ),
            // A model the catalog says cannot honour either setting.
            ProviderModelDto(
              connectionId: 'openai',
              id: 'gpt-5.6-plain',
              label: 'GPT-5.6 Plain',
              source: ProviderModelSource.bundled,
              capabilities: ModelCapabilitiesDto(
                streaming: CapabilitySupport.supported,
                toolCalling: CapabilitySupport.supported,
                reasoningEffort: CapabilitySupport.unsupported,
                serviceTier: CapabilitySupport.unsupported,
              ),
            ),
          ],
        },
      );
      final router = await _pumpRoute(
        tester,
        api,
        WorktreeRoute(
          hostId: 'server',
          workspaceId: workspace.id,
          worktreeId: checkout.id,
        ).location,
      );
      addTearDown(router.dispose);
      await tester.pumpAndSettle();

      // Permissions never depend on the model, so the chip is always offered.
      expect(
        find.byKey(const ValueKey('session-composer-permission')),
        findsOne,
      );

      await tester.tap(find.byKey(const ValueKey('session-composer-model')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('model-option-openai-gpt-5.6-sol')),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('session-composer-effort')), findsOne);
      expect(find.byKey(const ValueKey('session-composer-fast')), findsOne);

      await tester.tap(find.byKey(const ValueKey('session-composer-effort')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('session-composer-effort-high')),
      );
      await tester.pumpAndSettle();
      expect(find.text('high'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('session-composer-permission')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('session-composer-permission-readOnly')),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('session-composer-fast')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('session-composer-input')),
        'Audit the parser',
      );
      await tester.tap(find.byKey(const ValueKey('session-composer-send')));
      await tester.pumpAndSettle();

      final created = api.createdSessions.single;
      expect(created.reasoningEffort, 'high');
      expect(created.permissionMode, PermissionMode.readOnly);
      expect(created.serviceTier, 'priority');

      // Toggling fast mode off restores the provider default tier.
      await tester.tap(find.byKey(const ValueKey('session-composer-fast')));
      await tester.pumpAndSettle();
      expect(api.updatedSessionServiceTiers.single.serviceTier, isNull);

      await tester.tap(find.byKey(const ValueKey('session-composer-effort')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('session-composer-effort-inherit')),
      );
      await tester.pumpAndSettle();
      expect(api.updatedSessionReasoningEfforts.single.reasoningEffort, isNull);

      await tester.tap(
        find.byKey(const ValueKey('session-composer-permission')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('session-composer-permission-inherit')),
      );
      await tester.pumpAndSettle();
      expect(api.updatedSessionPermissionModes.single.permissionMode, isNull);

      // A model without the capability hides both controls again.
      await tester.tap(find.byKey(const ValueKey('session-composer-model')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('model-option-openai-gpt-5.6-plain')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('session-composer-effort')),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('session-composer-fast')), findsNothing);
      expect(
        find.byKey(const ValueKey('session-composer-permission')),
        findsOne,
      );
    },
    tags: const <String>['feature_test__session_lifecycle__widget'],
  );

  testWidgets(
    'plan mode starts a planning session and implements the proposal',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final api = FakeCoderApi(
        workspaces: <WorkspaceDto>[workspace],
        worktrees: <WorktreeDto>[checkout],
      );
      final router = await _pumpRoute(
        tester,
        api,
        WorktreeRoute(
          hostId: 'server',
          workspaceId: workspace.id,
          worktreeId: checkout.id,
        ).location,
      );
      addTearDown(router.dispose);
      await tester.pumpAndSettle();

      expect(find.text('실행'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('session-composer-model')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('model-option-openai-gpt-5.6-sol')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('session-composer-mode')));
      await tester.pumpAndSettle();
      // The chip label is the whole mode indicator, so the run label is gone.
      expect(find.text('Plan'), findsOneWidget);
      expect(find.text('실행'), findsNothing);

      await tester.enterText(
        find.byKey(const ValueKey('session-composer-input')),
        'Migrate the parser',
      );
      await tester.tap(find.byKey(const ValueKey('session-composer-send')));
      await tester.pumpAndSettle();

      final created = api.createdSessions.single;
      expect(created.mode, SessionMode.plan);
      // Sending a prompt keeps the session in plan mode.
      expect(find.text('Plan'), findsOneWidget);
      expect(find.text('실행'), findsNothing);

      api
        ..emitTimeline(
          created.id,
          'assistant.delta',
          <String, dynamic>{'text': 'Explored it.'},
        )
        ..emitTimeline(created.id, 'tool.requested', <String, dynamic>{
          'callId': 'call-plan',
          'name': 'update_plan',
          'arguments': _planArguments,
        })
        ..emitTimeline(created.id, 'tool.completed', <String, dynamic>{
          'callId': 'call-plan',
          'name': 'update_plan',
          'output': '{}',
        })
        ..emitTimeline(
          created.id,
          'turn.completed',
          <String, dynamic>{'toolRounds': 1},
        );
      await tester.pumpAndSettle();

      expect(find.text('계획'), findsOneWidget);
      expect(
        find.textContaining('Move the parser', findRichText: true),
        findsWidgets,
      );
      expect(find.text('이 계획대로 진행할까요?'), findsOneWidget);

      await tester.tap(find.widgetWithText(TRButton, '계획대로 실행'));
      await tester.pumpAndSettle();
      expect(api.updatedSessionModes.single.mode, SessionMode.normal);
      expect(api.startedPrompts.last, '계획을 실행해줘.');
      expect(find.text('이 계획대로 진행할까요?'), findsNothing);
    },
    tags: const <String>['feature_test__session_lifecycle__widget'],
  );

  testWidgets(
    'a plan can be handed to a fresh session or postponed',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final planning = session('planning').copyWith(mode: SessionMode.plan);
      final api = FakeCoderApi(
        workspaces: <WorkspaceDto>[workspace],
        worktrees: <WorktreeDto>[checkout],
        agents: <SessionDto>[planning],
        timelines: <String, List<TimelineEventDto>>{
          planning.id: <TimelineEventDto>[
            TimelineEventDto(
              sessionId: planning.id,
              sequence: 1,
              turnId: 'turn-1',
              type: 'tool.requested',
              data: <String, dynamic>{
                'callId': 'call-plan',
                'name': 'update_plan',
                'arguments': _planArguments,
              },
              createdAt: now,
            ),
            TimelineEventDto(
              sessionId: planning.id,
              sequence: 2,
              turnId: 'turn-1',
              type: 'tool.completed',
              data: const <String, dynamic>{
                'callId': 'call-plan',
                'name': 'update_plan',
                'output': '{}',
              },
              createdAt: now,
            ),
            TimelineEventDto(
              sessionId: planning.id,
              sequence: 3,
              turnId: 'turn-1',
              type: 'turn.completed',
              data: const <String, dynamic>{'toolRounds': 1},
              createdAt: now,
            ),
          ],
        },
      );
      final router = await _pumpRoute(
        tester,
        api,
        SessionRoute(
          hostId: 'server',
          workspaceId: workspace.id,
          worktreeId: checkout.id,
          sessionId: planning.id,
        ).location,
      );
      addTearDown(router.dispose);
      await tester.pumpAndSettle();

      expect(find.text('Plan'), findsOneWidget);
      await tester.tap(find.widgetWithText(TRButton, '계속 계획'));
      await tester.pumpAndSettle();
      expect(find.text('이 계획대로 진행할까요?'), findsNothing);
      expect(api.startedPrompts, isEmpty);

      await tester.tap(find.byKey(const ValueKey('session-composer-mode')));
      await tester.pumpAndSettle();
      expect(api.updatedSessionModes.single.mode, SessionMode.normal);
    },
    tags: const <String>['feature_test__session_lifecycle__widget'],
  );

  testWidgets('workspace shell is visible before any daemon exists', (
    tester,
  ) async {
    final api = FakeCoderApi();
    final router = GoRouter(
      initialLocation: const WorkspaceHomeRoute().location,
      routes: $appRoutes,
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appServicesProvider.overrideWithValue(
            fakeAppServices(api, connected: false),
          ),
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
    await tester.pump();
    expect(find.text('Workspaces'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('workspace-settings-button')),
      findsOneWidget,
    );
  });

  testWidgets('settings combines Projects, Agent, Provider, and Daemon', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1100, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final api = FakeCoderApi();
    final router = await _pumpRoute(
      tester,
      api,
      const ProviderSettingsRoute(hostId: 'server').location,
    );
    addTearDown(router.dispose);
    expect(
      find.byKey(const ValueKey<String>('settings-sidebar-surface')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('settings-sidebar-tree-app')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('settings-sidebar-tree-daemon')),
      findsOneWidget,
    );
    expect(find.text('Projects'), findsOneWidget);
    expect(find.text('Agent'), findsOneWidget);
    expect(find.text('Provider'), findsOneWidget);
    expect(find.text('Daemons'), findsOneWidget);
    expect(find.text('Test daemon'), findsWidgets);
    await tester.tap(find.text('Projects'));
    await tester.pumpAndSettle();
    expect(
      router.routeInformationProvider.value.uri.toString(),
      const ProjectSettingsRoute().location,
    );
    await tester.tap(find.text('Daemons'));
    await tester.pumpAndSettle();
    expect(find.text('원격 daemons'), findsOneWidget);
  });

  testWidgets('mobile settings can switch between every typed category', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final router = await _pumpRoute(
      tester,
      FakeCoderApi(),
      const GeneralSettingsRoute().location,
    );
    addTearDown(router.dispose);

    final selector = find.byKey(
      const ValueKey<String>('settings-category-select'),
    );
    expect(selector, findsOneWidget);
    await tester.tap(selector);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Daemons').last);
    await tester.pumpAndSettle();

    expect(find.text('원격 daemons'), findsOneWidget);
    expect(router.routeInformationProvider.value.uri.path, '/settings/daemons');
  });

  testWidgets(
    'agent settings edits Markdown definitions and creates subagents',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final api = FakeCoderApi();
      final router = await _pumpRoute(
        tester,
        api,
        const AgentSettingsRoute(hostId: 'server').location,
      );
      addTearDown(router.dispose);

      expect(find.text('Agents'), findsOneWidget);
      expect(find.text('Coder'), findsWidgets);
      final prompt = _textInput('System prompt (Markdown)');
      await tester.enterText(prompt, 'Always run focused tests.');
      await tester.tap(find.widgetWithText(TRButton, '저장'));
      await tester.pumpAndSettle();
      expect(
        (await api.getAgentDefinition('coder')).systemPrompt,
        'Always run focused tests.',
      );
      await tester.scrollUntilVisible(
        find.text('내장 도구'),
        400,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('내장 도구'), findsOneWidget);

      // An always-on tool is shown checked and locked, sorted above the
      // tools the user can actually turn off.
      final alwaysOn = tester.widget<CoderCheckboxRow>(
        find.byKey(const ValueKey<String>('agent-tool-tile-read_file')),
      );
      expect(alwaysOn.value, isTrue);
      expect(alwaysOn.onChanged, isNull);
      expect(
        find.byKey(const ValueKey<String>('agent-tool-lock-read_file')),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey<String>('agent-tool-tile-exec_command')),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      final toggleable = tester.widget<CoderCheckboxRow>(
        find.byKey(const ValueKey<String>('agent-tool-tile-exec_command')),
      );
      expect(toggleable.onChanged, isNotNull);

      await tester.tap(find.byKey(const ValueKey('agent-add-button')));
      await tester.pumpAndSettle();
      await tester.enterText(
        _textInput('ID (파일명)'),
        'reviewer',
      );
      await tester.enterText(
        _textInput('이름').last,
        'Reviewer',
      );
      await tester.tap(
        find.byType(TRSelectFormField<AgentMode>),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('subagent').last);
      tester.testTextInput.hide();
      final createButton = find.widgetWithText(TRButton, '생성');
      await tester.ensureVisible(createButton);
      await tester.pumpAndSettle();
      await tester.tap(createButton);
      await tester.pumpAndSettle();
      expect(find.text('Reviewer'), findsWidgets);
      expect(
        (await api.getAgentDefinition('reviewer')).mode,
        AgentMode.subagent,
      );
    },
    tags: const <String>[
      'feature_test__agent_definition_management__widget',
    ],
  );

  testWidgets(
    'agent create validates input and keeps daemon failures in the dialog',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final api = FakeCoderApi(failNextAgentCreate: true);
      final router = await _pumpRoute(
        tester,
        api,
        const AgentSettingsRoute(hostId: 'server').location,
      );
      addTearDown(router.dispose);

      await tester.tap(find.byKey(const ValueKey('agent-add-button')));
      await tester.pumpAndSettle();
      var create = tester.widget<TRButton>(
        find.widgetWithText(TRButton, '생성'),
      );
      expect(create.onPressed, isNull);

      await tester.enterText(
        _textInput('ID (파일명)'),
        'Invalid ID',
      );
      await tester.enterText(
        _textInput('이름').last,
        'Reviewer',
      );
      await tester.pumpAndSettle();
      expect(find.text('영문 소문자, 숫자, -, _만 사용할 수 있습니다.'), findsOneWidget);

      await tester.enterText(
        _textInput('ID (파일명)'),
        'coder',
      );
      await tester.pumpAndSettle();
      expect(find.text('이미 존재하는 Agent ID입니다.'), findsOneWidget);

      await tester.enterText(
        _textInput('ID (파일명)'),
        'reviewer',
      );
      await tester.pumpAndSettle();
      create = tester.widget<TRButton>(
        find.widgetWithText(TRButton, '생성'),
      );
      expect(create.onPressed, isNotNull);
      await tester.tap(find.widgetWithText(TRButton, '생성'));
      await tester.pumpAndSettle();
      expect(find.textContaining('agent_create_failed'), findsOneWidget);
      expect(find.text('Agent 추가'), findsOneWidget);

      await tester.tap(find.widgetWithText(TRButton, '생성'));
      await tester.pumpAndSettle();
      expect(find.text('Agent 추가'), findsNothing);
      expect(find.text('Reviewer'), findsWidgets);
    },
  );

  testWidgets('mobile agent settings navigates from list to Markdown detail', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 780));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final api = FakeCoderApi();
    final router = await _pumpRoute(
      tester,
      api,
      const AgentSettingsRoute(hostId: 'server').location,
    );
    addTearDown(router.dispose);

    expect(find.text('Agents'), findsOneWidget);
    expect(_textField('System prompt (Markdown)'), findsNothing);
    await tester.tap(find.text('Coder').first);
    await tester.pumpAndSettle();
    expect(_textField('System prompt (Markdown)'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('agent-list-button')));
    await tester.pumpAndSettle();
    expect(find.text('Agents'), findsOneWidget);
  });

  testWidgets(
    'agent editor handles conflicts, policy controls, reset, and archive',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      const coder = AgentDefinitionDto(
        id: 'coder',
        name: 'Coder',
        description: 'General coding',
        mode: AgentMode.primary,
        promptEnabled: true,
        systemPrompt: 'Code carefully.',
        model: AgentModelSelectionDto(
          source: AgentModelSource.session,
        ),
        reasoningEffort: 'medium',
        permissionMode: PermissionMode.ask,
        toolIds: <String>['read_file'],
        callableAgentIds: <String>[],
        contentHash: 'coder-hash',
        sourcePath: '/config/agents/coder.md',
        isBuiltIn: true,
        diagnostics: <AgentDefinitionDiagnosticDto>[
          AgentDefinitionDiagnosticDto(
            code: 'unavailable_tool',
            message: 'A future tool is unavailable.',
          ),
        ],
      );
      const reviewer = AgentDefinitionDto(
        id: 'reviewer',
        name: 'Reviewer',
        description: 'Reviews changes',
        mode: AgentMode.subagent,
        promptEnabled: true,
        systemPrompt: 'Review.',
        model: AgentModelSelectionDto(
          source: AgentModelSource.session,
        ),
        reasoningEffort: 'medium',
        permissionMode: PermissionMode.readOnly,
        toolIds: <String>['read_file'],
        callableAgentIds: <String>[],
        contentHash: 'reviewer-hash',
        sourcePath: '/config/agents/reviewer.md',
      );
      final api = FakeCoderApi(
        agentDefinitions: const <AgentDefinitionDto>[coder, reviewer],
        failNextAgentUpdate: true,
      );
      final router = await _pumpRoute(
        tester,
        api,
        const AgentSettingsRoute(hostId: 'server').location,
      );
      addTearDown(router.dispose);

      expect(find.text('unavailable_tool'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('agent-copy-path-button')));
      await tester.tap(find.text('Custom system prompt 사용'));
      final editorList = find.byType(ListView).last;
      await tester.drag(editorList, const Offset(0, -500));
      await tester.pumpAndSettle();
      await tester.tap(find.text('고정 provider/model'));
      await tester.pumpAndSettle();
      await tester.enterText(
        _textInput('Provider connection ID'),
        'openai',
      );
      await tester.enterText(
        _textInput('Model ID'),
        'gpt-test',
      );
      await tester.drag(editorList, const Offset(0, -600));
      await tester.pumpAndSettle();
      await tester.tap(find.text('read_file').last);
      await tester.tap(find.text('Reviewer').last);
      await tester.tap(find.widgetWithText(TRButton, '저장'));
      await tester.pumpAndSettle();
      expect(find.text('Agent 저장 실패'), findsOneWidget);
      await tester.tap(find.widgetWithText(TRButton, 'Overwrite'));
      await tester.pumpAndSettle();

      final updated = await api.getAgentDefinition('coder');
      expect(updated.promptEnabled, isFalse);
      expect(updated.model.providerConnectionId, 'openai');
      expect(updated.model.modelId, 'gpt-test');
      expect(updated.toolIds, isEmpty);
      expect(updated.callableAgentIds, <String>['reviewer']);

      await tester.tap(find.byKey(const ValueKey('agent-reset-button')));
      await tester.pumpAndSettle();
      expect(
        (await api.getAgentDefinition('coder')).systemPrompt,
        'Code carefully.',
      );
      await tester.tap(find.text('Reviewer').first);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('agent-archive-button')));
      await tester.pumpAndSettle();
      expect(
        (await api.listAgentDefinitions()).map((definition) => definition.id),
        isNot(contains('reviewer')),
      );
    },
    tags: const <String>['feature_test__agent_collaboration__widget'],
  );

  testWidgets('remote agent settings stays editable and exposes load errors', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1100, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const remoteInfo = ServerInfoDto(
      serverId: 'server',
      version: 'test',
      protocolVersion: coderProtocolVersion,
      features: <String, bool>{},
    );
    final remoteRouter = await _pumpRoute(
      tester,
      FakeCoderApi(serverInfo: remoteInfo),
      const AgentSettingsRoute(hostId: 'server').location,
    );
    expect(find.textContaining('읽기만'), findsNothing);
    expect(
      tester
          .widget<TRIconButton>(
            find.widgetWithIcon(TRIconButton, CoderIcons.add),
          )
          .onPressed,
      isNotNull,
    );
    remoteRouter.dispose();

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    final errorRouter = await _pumpRoute(
      tester,
      FakeCoderApi(agentListError: Exception('definition load failed')),
      const AgentSettingsRoute(hostId: 'server').location,
    );
    addTearDown(errorRouter.dispose);
    expect(find.textContaining('definition load failed'), findsOneWidget);
    await tester.tap(find.widgetWithText(TRButton, '다시 시도'));
    await tester.pumpAndSettle();
    expect(find.textContaining('definition load failed'), findsOneWidget);
  });

  testWidgets(
    'timeline and approval cards render typed event content',
    (
      tester,
    ) async {
      final agent = session('approval');
      final approval = ApprovalRequestDto(
        id: 'approval',
        sessionId: agent.id,
        turnId: 'turn',
        toolCallId: 'call',
        toolName: 'apply_patch',
        risk: ToolRisk.write,
        arguments: const <String, dynamic>{'patch': 'diff'},
        status: ApprovalStatus.pending,
        createdAt: now,
      );
      final event = TimelineEventDto(
        sessionId: agent.id,
        sequence: 1,
        type: 'user.message',
        data: const <String, dynamic>{'text': 'Inspect this'},
        createdAt: now,
      );
      final api = FakeCoderApi(agents: <SessionDto>[agent]);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appServicesProvider.overrideWithValue(fakeAppServices(api)),
          ],
          child: MaterialApp(
            theme: testLightTheme,
            darkTheme: testDarkTheme,
            locale: testLocale,
            localizationsDelegates: testLocalizationsDelegates,
            supportedLocales: testSupportedLocales,
            home: Scaffold(
              body: ListView(
                children: <Widget>[
                  Consumer(
                    builder: (context, ref, child) => Text(
                      ref
                                  .watch(hostRegistryControllerProvider)
                                  .asData
                                  ?.value
                                  .runtimes['server']
                                  ?.connected ==
                              true
                          ? 'ready'
                          : 'waiting',
                    ),
                  ),
                  ChatItemView(
                    item: projectChatTimeline(
                      <TimelineEventDto>[event],
                    ).single,
                  ),
                  ApprovalCard(hostId: 'server', approval: approval),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('ready'), findsOneWidget);
      expect(find.text('>'), findsOneWidget);
      expect(find.text('Inspect this', findRichText: true), findsOneWidget);
      expect(find.text('승인 필요 · apply_patch'), findsOneWidget);
      await tester.tap(find.widgetWithText(TRButton, '거부'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TRButton, '승인'));
      await tester.pumpAndSettle();
      expect(
        api.approvalDecisions,
        <({bool approved, String id})>[
          (id: 'approval', approved: false),
          (id: 'approval', approved: true),
        ],
      );
    },
    tags: const <String>['feature_test__turn_execution__widget'],
  );

  testWidgets(
    'a question card answers with an option or with free-form text',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final agent = session('asking');
      final request = UserQuestionRequestDto(
        id: 'question',
        sessionId: agent.id,
        turnId: 'turn',
        toolCallId: 'ask-call',
        questions: const <UserQuestionItemDto>[
          UserQuestionItemDto(
            id: 'store',
            header: 'Storage',
            question: 'Which store should the cache use?',
            options: <UserQuestionOptionDto>[
              UserQuestionOptionDto(
                label: 'SQLite',
                description: 'Durable and already a dependency.',
              ),
              UserQuestionOptionDto(
                label: 'In memory',
                description: 'Fastest, lost on restart.',
              ),
            ],
          ),
        ],
        status: UserQuestionStatus.pending,
        createdAt: now,
      );
      final api = FakeCoderApi(agents: <SessionDto>[agent]);
      Future<void> pump() => tester.pumpWidget(
        ProviderScope(
          overrides: [
            appServicesProvider.overrideWithValue(fakeAppServices(api)),
          ],
          child: MaterialApp(
            theme: testLightTheme,
            locale: testLocale,
            localizationsDelegates: testLocalizationsDelegates,
            supportedLocales: testSupportedLocales,
            home: Scaffold(
              body: ListView(
                children: <Widget>[
                  Consumer(
                    builder: (context, ref, child) => Text(
                      ref
                                  .watch(hostRegistryControllerProvider)
                                  .asData
                                  ?.value
                                  .runtimes['server']
                                  ?.connected ==
                              true
                          ? 'ready'
                          : 'waiting',
                    ),
                  ),
                  ChatQuestionCard(hostId: 'server', request: request),
                ],
              ),
            ),
          ),
        ),
      );

      await pump();
      await tester.pumpAndSettle();
      expect(find.text('ready'), findsOneWidget);
      expect(find.text('Storage'), findsOneWidget);
      expect(find.text('Which store should the cache use?'), findsOneWidget);
      expect(find.text('Durable and already a dependency.'), findsOneWidget);
      // The client offers the free-form choice; the agent never authors it.
      expect(find.text('직접 입력'), findsOneWidget);

      final submit = find.byKey(const ValueKey<String>('chat-question-submit'));
      expect(tester.widget<TRButton>(submit).onPressed, isNull);

      await tester.tap(find.text('SQLite'));
      await tester.pumpAndSettle();
      expect(tester.widget<TRButton>(submit).onPressed, isNotNull);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(api.questionAnswers.single.id, 'question');
      expect(api.questionAnswers.single.answers, <UserQuestionAnswerDto>[
        const UserQuestionAnswerDto(
          questionId: 'store',
          answer: 'SQLite',
          isFreeForm: false,
        ),
      ]);

      await pump();
      await tester.pumpAndSettle();
      await tester.tap(find.text('직접 입력'));
      await tester.pumpAndSettle();
      final field = find.byKey(
        const ValueKey<String>('chat-question-other-store'),
      );
      expect(field, findsOneWidget);
      // Blank free-form text is not an answer.
      expect(tester.widget<TRButton>(submit).onPressed, isNull);
      await tester.enterText(field, '  Postgres  ');
      await tester.pumpAndSettle();
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(api.questionAnswers.last.answers, <UserQuestionAnswerDto>[
        const UserQuestionAnswerDto(
          questionId: 'store',
          answer: 'Postgres',
          isFreeForm: true,
        ),
      ]);
    },
    tags: const <String>['feature_test__turn_question__widget'],
  );

  testWidgets(
    'the draft composer runs a client command instead of sending it',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 760));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final api = FakeCoderApi(
        workspaces: <WorkspaceDto>[workspace],
        worktrees: <WorktreeDto>[checkout],
      );
      final router = await _pumpRoute(
        tester,
        api,
        WorktreeRoute(
          hostId: 'server',
          workspaceId: workspace.id,
          worktreeId: checkout.id,
        ).location,
      );
      addTearDown(router.dispose);

      // The draft pane creates its session from the first prompt, so `/new`
      // has no session to be new relative to.
      await tester.enterText(
        find.byKey(const ValueKey('session-composer-input')),
        '/',
      );
      await tester.pumpAndSettle();
      expect(find.text('mode'), findsOneWidget);
      expect(find.text('new'), findsNothing);

      expect(find.text('Plan'), findsNothing);
      await tester.enterText(
        find.byKey(const ValueKey('session-composer-input')),
        '/mode',
      );
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('session-composer-send')));
      await tester.pumpAndSettle();

      expect(find.text('Plan'), findsOneWidget);
      expect(api.createdSessions, isEmpty);
      expect(api.startedPrompts, isEmpty);
    },
    tags: const <String>['feature_test__composer_slash_command__widget'],
  );
}

Future<GoRouter> _pumpRoute(
  WidgetTester tester,
  FakeCoderApi api,
  String location, {
  MemoryAppStore? store,
  bool disableAnimations = false,
  bool settle = true,
}) async {
  final router = GoRouter(initialLocation: location, routes: $appRoutes);
  final app = MaterialApp.router(
    theme: testLightTheme,
    darkTheme: testDarkTheme,
    locale: testLocale,
    localizationsDelegates: testLocalizationsDelegates,
    supportedLocales: testSupportedLocales,
    routerConfig: router,
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appServicesProvider.overrideWithValue(
          fakeAppServices(api, store: store),
        ),
      ],
      child: disableAnimations
          ? MediaQuery(
              data: MediaQueryData(
                disableAnimations: true,
                size: tester.view.physicalSize / tester.view.devicePixelRatio,
              ),
              child: app,
            )
          : app,
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
  return router;
}

Finder _textField(String label) => find.byWidgetPredicate(
  (widget) => widget is TRTextField && widget.label == label,
  description: 'TRTextField labelled "$label"',
);

Finder _textInput(String label) => find.descendant(
  of: _textField(label),
  matching: find.byType(EditableText),
);

final class _MappedClients implements HostClientFactory {
  const _MappedClients(this.apis);

  final Map<String, CoderApi> apis;

  @override
  Future<CoderApi> connect({
    required HostEndpoint endpoint,
    required DaemonCredentials credentials,
    required String clientId,
    required String clientKind,
  }) async => apis[endpoint.websocketUri.host]!;
}
