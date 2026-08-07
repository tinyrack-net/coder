import 'package:coder_app/src/app/coder_app.dart';
import 'package:coder_app/src/app/composition/app_providers.dart';
import 'package:coder_app/src/app/composition/app_services.dart';
import 'package:coder_app/src/app/router/app_router.dart';
import 'package:coder_app/src/features/hosts/domain/host_models.dart';
import 'package:coder_app/src/features/hosts/domain/host_ports.dart';
import 'package:coder_client/coder_client.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

import '../../support/fake_coder_api.dart';
import '../../support/fake_desktop_ports.dart';
import '../../support/localization.dart';

final _now = DateTime.utc(2026, 8, 3);
final _workspace = WorkspaceDto(
  id: 'workspace',
  name: 'Coder',
  rootPath: '/repos/coder',
  kind: WorkspaceKind.git,
  createdAt: _now,
);
final _worktree = WorktreeDto(
  id: 'checkout',
  workspaceId: 'workspace',
  name: 'main',
  path: '/repos/coder',
  branch: 'main',
  head: 'abc',
  kind: WorktreeKind.checkout,
  isCoderOwned: false,
  createdAt: _now,
);
const _terminal = TerminalDto(
  id: 'terminal-menu',
  worktreeId: 'checkout',
  title: 'Remote terminal',
  shell: ShellSpecDto(executable: '/bin/sh'),
  status: TerminalStatus.running,
  columns: 80,
  rows: 24,
  lastSequence: 0,
);

/// Records the menu it was asked to present instead of opening anything.
///
/// A menu the operating system draws lives outside the Flutter tree, so this is
/// the only way a test can see what was handed over.
final class _RecordingPresenter implements TRContextMenuPresenter {
  final openings = <List<TRMenuElement>>[];

  List<String> get lastIds => <String>[
    for (final element in openings.last)
      if (element case TRMenuActionElement(:final id)) id else '-',
  ];

  @override
  Widget buildHost({
    required Widget child,
    required TRMenuElementsBuilder itemsBuilder,
    required TRContextMenuController controller,
    required bool enabled,
    required bool useRootOverlay,
    VoidCallback? onOpen,
    VoidCallback? onClose,
  }) => _RecordingHost(
    presenter: this,
    controller: controller,
    itemsBuilder: itemsBuilder,
    child: child,
  );
}

final class _RecordingHost extends StatefulWidget {
  const _RecordingHost({
    required this.presenter,
    required this.controller,
    required this.itemsBuilder,
    required this.child,
  });

  final _RecordingPresenter presenter;
  final TRContextMenuController controller;
  final TRMenuElementsBuilder itemsBuilder;
  final Widget child;

  @override
  State<_RecordingHost> createState() => _RecordingHostState();
}

final class _RecordingHostState extends State<_RecordingHost>
    implements TRContextMenuHost {
  @override
  void initState() {
    super.initState();
    widget.controller.attach(this);
  }

  @override
  void dispose() {
    widget.controller.detach(this);
    super.dispose();
  }

  @override
  void openAt(Offset globalPosition) =>
      widget.presenter.openings.add(widget.itemsBuilder(context));

  @override
  void close() {}

  @override
  bool get isOpen => false;

  @override
  Widget build(BuildContext context) => widget.child;
}

Future<void> _openTerminalMenu(WidgetTester tester) async {
  final surface = find.byKey(const ValueKey<String>('tr-terminal-surface'));
  final gesture = await tester.startGesture(
    tester.getTopLeft(surface) + const Offset(24, 24),
    kind: PointerDeviceKind.mouse,
    buttons: kSecondaryButton,
  );
  await tester.pump(const Duration(milliseconds: 50));
  await gesture.up();
  await tester.pumpAndSettle();
}

Future<void> _pumpTerminal(
  WidgetTester tester, {
  required TRContextMenuPresenter presenter,
}) async {
  final api = FakeCoderApi(
    workspaces: <WorkspaceDto>[_workspace],
    worktrees: <WorktreeDto>[_worktree],
    terminals: const <TerminalDto>[_terminal],
    terminalReplay: const <TerminalOutputDto>[
      TerminalOutputDto(
        terminalId: 'terminal-menu',
        sequence: 1,
        data: 'selectable output',
      ),
    ],
  );
  final router = GoRouter(
    initialLocation: TerminalRoute(
      hostId: 'server',
      workspaceId: _workspace.id,
      worktreeId: _worktree.id,
      terminalId: _terminal.id,
    ).location,
    routes: $appRoutes,
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [appServicesProvider.overrideWithValue(fakeAppServices(api))],
      child: TRContextMenuPresenterScope(
        presenter: presenter,
        child: MaterialApp.router(
          theme: testLightTheme,
          darkTheme: testDarkTheme,
          locale: testLocale,
          localizationsDelegates: testLocalizationsDelegates,
          supportedLocales: testSupportedLocales,
          routerConfig: router,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'the composition root installs the system-menu presenter',
    (tester) async {
      final store = MemoryAppStore(
        settings: const AppSettings(embeddedDaemonEnabled: false),
      );
      late TRContextMenuPresenter resolved;
      await tester.pumpWidget(
        CoderApp(
          services: AppServices(
            settings: store,
            profiles: store,
            credentials: store,
            clients: const _OfflineClients(),
            clientKind: 'test',
          ),
          autostart: FakeAutostartRegistration(),
        ),
      );
      await tester.pumpAndSettle();

      // Reading it from inside the running app is what proves the scope really
      // wraps the router, rather than that the constant exists.
      resolved = TRContextMenuPresenterScope.of(
        tester.element(find.byType(Router<Object>)),
      );

      expect(resolved, isA<TRNativeContextMenuPresenter>());
    },
    tags: const <String>['feature_test__terminal_lifecycle__widget'],
  );

  for (final (name, size) in <(String, Size)>[
    ('desktop', const Size(1100, 760)),
    ('mobile', const Size(390, 780)),
  ]) {
    testWidgets(
      'the terminal describes its menu to the installed presenter on $name',
      (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final presenter = _RecordingPresenter();

        await _pumpTerminal(tester, presenter: presenter);
        await _openTerminalMenu(tester);

        expect(presenter.openings, hasLength(1));
        expect(presenter.lastIds, <String>[
          'terminal-menu-copy',
          'terminal-menu-paste',
          '-',
          'terminal-menu-select-all',
          'terminal-menu-clear-selection',
          '-',
          'terminal-menu-clear-screen',
        ]);
        expect(
          find.byType(TRMenuItem),
          findsNothing,
          reason: 'the presenter took the menu, so Flutter drew none',
        );
      },
      tags: const <String>['feature_test__terminal_lifecycle__widget'],
    );
  }

  testWidgets(
    'copy and clear-selection follow the selection the terminal reports',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 760));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final presenter = _RecordingPresenter();

      await _pumpTerminal(tester, presenter: presenter);
      await _openTerminalMenu(tester);

      bool enabled(List<TRMenuElement> menu, String id) => menu
          .whereType<TRMenuActionElement>()
          .firstWhere((e) => e.id == id)
          .enabled;

      expect(enabled(presenter.openings.last, 'terminal-menu-copy'), isFalse);
      expect(
        enabled(presenter.openings.last, 'terminal-menu-clear-selection'),
        isFalse,
      );
      expect(enabled(presenter.openings.last, 'terminal-menu-paste'), isTrue);

      // Selecting through the described entry is what a system menu reports
      // back, so drive it the same way rather than through the controller.
      presenter.openings.last
          .whereType<TRMenuActionElement>()
          .firstWhere((e) => e.id == 'terminal-menu-select-all')
          .onPressed();
      await tester.pumpAndSettle();
      await _openTerminalMenu(tester);

      expect(enabled(presenter.openings.last, 'terminal-menu-copy'), isTrue);
      expect(
        enabled(presenter.openings.last, 'terminal-menu-clear-selection'),
        isTrue,
      );
    },
    tags: const <String>['feature_test__terminal_lifecycle__widget'],
  );
}

final class _OfflineClients implements HostClientFactory {
  const _OfflineClients();

  @override
  Future<CoderApi> connect({
    required HostEndpoint endpoint,
    required DaemonCredentials credentials,
    required String clientId,
    required String clientKind,
  }) => Future<CoderApi>.error(const HostConnectionFailure.network('offline'));
}
