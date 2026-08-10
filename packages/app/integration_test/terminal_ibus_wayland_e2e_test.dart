@TestOn('linux')
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:app/src/app/coder_app.dart';
import 'package:app/src/app/composition/app_services.dart';
import 'package:app/src/features/desktop/infrastructure/desktop_bootstrap.dart';
import 'package:app/src/features/hosts/domain/host_models.dart';
import 'package:app/src/features/hosts/domain/host_ports.dart';
import 'package:app/src/features/workspace/application/directory_picker_port.dart';
import 'package:client/client.dart';
import 'package:daemon/daemon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:termworld/termworld.dart';

import 'support/ephemeral_port.dart';
import 'support/pump_until.dart';

/// The native-Wayland sibling of terminal_ibus_e2e_test.dart.
///
/// The X11 test cannot cover the reorder reported on Ubuntu Wayland
/// ("안녕하세요." reaching the PTY as "안세녕하요."), because GTK's Wayland
/// input-method context batches preedit and commit differently from the X11
/// ibus module. This test drives real ibus-hangul on a Wayland compositor
/// through wtype's virtual keyboard instead of xdotool, and keeps only the
/// Hangul-ordering leg: the clipboard and native-menu legs stay X11-only.
///
/// Run through tool/run_linux_ibus_terminal_wayland_e2e.sh, which boots a
/// headless sway session and ibus-daemon before launching this test.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'real IBus Hangul on Wayland reaches the embedded PTY in typed order',
    (tester) async {
      final daemonHome = await Directory.systemTemp.createTemp(
        'coder-ibus-wl-daemon-',
      );
      final userHome = await Directory.systemTemp.createTemp(
        'coder-ibus-wl-user-',
      );
      final workspace = await Directory.systemTemp.createTemp(
        'coder-ibus-wl-workspace-',
      );
      await _initializeGitRepository(workspace.path);
      final port = await reserveEphemeralPort();
      const token = 'ibus-wayland-e2e-token-0123456789abcdef';
      final config = DaemonConfig(
        homeDirectory: daemonHome.path,
        userHomeDirectory: userHome.path,
        osHomeDirectory: userHome.path,
        port: port,
        bearerToken: token,
        useEnvironmentCredentials: false,
      );
      final launcher = IsolateEmbeddedDaemonLauncher(
        resolveConfig: () => config,
      );
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        for (final directory in <Directory>[daemonHome, userHome, workspace]) {
          if (directory.existsSync()) directory.deleteSync(recursive: true);
        }
      });

      const typed = '한글 abc 안녕 안녕하세요. ㅁㄴㅇㄻㄴㅇㄹ ';
      final expectedBytes = utf8.encode(typed);
      final artifactDirectory =
          Platform.environment['TINYRACK_IBUS_ARTIFACT_DIR'];
      if (artifactDirectory != null) {
        Directory(artifactDirectory).createSync(recursive: true);
      }
      final capture = File(
        artifactDirectory == null
            ? '${workspace.path}/ibus-input.bin'
            : '$artifactDirectory/pty-input.bin',
      );
      final modeProbe = File('${workspace.path}/ibus-mode.bin');
      final modeReady = File('${workspace.path}/ibus-mode-ready');
      final ready = File('${workspace.path}/ibus-ready');
      final store = MemoryAppStore(
        settings: AppSettings(embeddedDaemonPort: port),
      );
      await tester.pumpWidget(
        CoderApp(
          services: AppServices(
            settings: store,
            profiles: store,
            credentials: store,
            clients: const WebSocketHostClientFactory(),
            clientKind: 'ibus-wayland-desktop-integration-test',
            embeddedLauncher: launcher,
          ),
          directoryPicker: _FixedDirectoryPicker(workspace.path),
        ),
      );
      final setupClient = await _connectToDaemon(port, token);
      addTearDown(setupClient.close);
      final projectMenu = find.byKey(
        const ValueKey<String>('new-workspace-project'),
      );
      await pumpUntil(tester, projectMenu);
      await tester.tap(projectMenu);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('new-workspace-project-add')),
      );
      final sidebarCheckout = find.descendant(
        of: find.byKey(const ValueKey<String>('workspace-sidebar-tree')),
        matching: find.text('main'),
      );
      await _pumpUntilFinder(tester, sidebarCheckout, 'the Git checkout');
      await tester.ensureVisible(sidebarCheckout);
      await tester.pumpAndSettle();
      await tester.tap(sidebarCheckout);
      await tester.pumpAndSettle();
      final catalog = await setupClient.workspaces.getWorkspaceCatalog();
      final registered = catalog.workspaces.singleWhere(
        (item) => item.rootPath == workspace.path,
      );
      final checkout = catalog.worktrees.singleWhere(
        (item) => item.workspaceId == registered.id,
      );
      final newTabMenu = find.byKey(
        const ValueKey<String>('workspace-new-tab-menu'),
      );
      await pumpUntil(tester, newTabMenu);
      await tester.tap(newTabMenu);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('workspace-new-terminal')),
      );
      await _waitUntil(
        () async =>
            (await setupClient.terminals.listTerminals(checkout.id)).isNotEmpty,
        'Coder to create the terminal through its real daemon',
      );
      final terminal = (await setupClient.terminals.listTerminals(
        checkout.id,
      )).single;
      final terminalViewFinder = find
          .byKey(ValueKey<String>('terminal-view-${terminal.id}'))
          .hitTestable();
      await pumpUntil(tester, terminalViewFinder);
      await setupClient.terminals.writeTerminal(
        terminal.id,
        r"printf '\033[?2004l'; stty raw -echo; "
        ": > '${modeProbe.path}'; touch '${modeReady.path}'; "
        "dd bs=1 count=1 of='${modeProbe.path}' status=none; "
        ": > '${capture.path}'; touch '${ready.path}'; "
        "dd bs=1 count=${expectedBytes.length} of='${capture.path}' "
        'status=none; stty sane\r',
      );
      await _waitUntil(
        modeReady.existsSync,
        'the PTY mode probe to enter raw mode',
      );
      // Route replacement briefly leaves both pane surfaces mounted, so scope
      // the finder to the terminal created for this test.
      final terminalSurface = find
          .descendant(
            of: find.byKey(ValueKey<String>('terminal-view-${terminal.id}')),
            matching: find.byKey(
              const ValueKey<String>('tr-terminal-surface'),
            ),
          )
          .last;
      await tester.tap(terminalSurface);
      await tester.pumpAndSettle();
      await _waitForTerminalFocus(tester);
      await _activateHangulEngine();
      await tester.pumpAndSettle();
      await _ensureHangulMode(modeProbe);
      await _waitUntil(
        ready.existsSync,
        'the PTY byte recorder to follow the mode probe',
      );

      await _keys(<String>['g', 'k', ...'srmf'.split(''), 'space']);
      await _toggleLanguage();
      await _keys(<String>['a', 'b', 'c', 'space']);
      await _toggleLanguage();
      await _keys(<String>[...'dkssud'.split(''), 'space']);
      // ㅅ and ㅇ first land as the final consonant of the syllable in
      // progress and are redistributed into the next one. Each redistribution
      // settles a syllable and reopens the preedit in the same keystroke, so
      // the syllables must still reach the PTY in typed order. On the
      // reported Ubuntu Wayland setup this arrives as 안세녕하요. instead.
      await _keys(<String>[...'dkssudgktpdy'.split(''), 'period', 'space']);
      // Bare consonants cannot start a syllable, so IBus commits each one as
      // the next arrives while the last stays in preedit until Space — except
      // ㄹ followed by ㅁ, which compose the cluster ㄻ.
      await _keys(<String>[...'asdfasdf'.split(''), 'space']);
      await _toggleLanguage();

      // Waited for without failing on the wait itself, so a shortfall still
      // reaches the byte comparison below and its diagnostic hex dump.
      await _waitForOptional(
        () =>
            capture.existsSync() &&
            capture.lengthSync() == expectedBytes.length,
        const Duration(seconds: 15),
      );
      final actualBytes = capture.existsSync()
          ? capture.readAsBytesSync()
          : const <int>[];
      expect(
        actualBytes,
        expectedBytes,
        reason:
            'PTY bytes: ${actualBytes.map(_hex).join(' ')} '
            '(${utf8.decode(actualBytes, allowMalformed: true)})',
      );
    },
    tags: const <String>['feature_test__terminal_lifecycle__e2e'],
  );
}

Future<CoderApi> _connectToDaemon(int port, String token) async {
  Object? lastError;
  final deadline = DateTime.now().add(const Duration(seconds: 30));
  while (DateTime.now().isBefore(deadline)) {
    try {
      return await CoderClient.connect(
        endpoint: HostEndpoint.parse('127.0.0.1:$port'),
        credentials: DaemonCredentials(bearerToken: token),
        clientId: 'ibus-wayland-e2e-setup',
        clientKind: 'integration-test',
      );
    } on Exception catch (error) {
      lastError = error;
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
  }
  throw TestFailure('Timed out connecting to embedded daemon: $lastError');
}

final class _FixedDirectoryPicker implements DirectoryPickerPort {
  const _FixedDirectoryPicker(this.path);

  final String path;

  @override
  Future<String?> pickDirectory({String? initialDirectory}) async => path;
}

Future<void> _waitForTerminalFocus(WidgetTester tester) async {
  bool terminalHasFocus() {
    final context = FocusManager.instance.primaryFocus?.context;
    return context != null &&
        context.findAncestorWidgetOfExactType<TerminalView>() != null;
  }

  final deadline = DateTime.now().add(const Duration(seconds: 10));
  while (!terminalHasFocus() && DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 20));
  }
  expect(terminalHasFocus(), isTrue);
}

Future<void> _pumpUntilFinder(
  WidgetTester tester,
  Finder finder,
  String description,
) async {
  final deadline = DateTime.now().add(const Duration(seconds: 15));
  while (finder.evaluate().isEmpty && DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 20));
  }
  final visibleText = tester
      .widgetList<Text>(find.byType(Text))
      .map((item) => item.data);
  expect(
    finder,
    findsWidgets,
    reason:
        'Timed out waiting for $description. Visible text: '
        '$visibleText',
  );
}

/// Path to the wlkey injector built by the harness script.
///
/// wlkey uploads the standard kr layout and sends true evdev keycodes
/// through virtual-keyboard-v1. wtype cannot drive ibus-hangul: the engine
/// re-derives the keysym from the KEYCODE against a built-in US keymap
/// (Korean input is position-based), and wtype's compact synthetic
/// keycodes decode as garbage there, so every key passes through.
final String _wlkey = Platform.environment['TINYRACK_WLKEY'] ?? 'wlkey';

/// Injects one press-and-release per key. Names use xkb keysym spelling,
/// matching the xdotool names in the X11 sibling ('a', 'period', 'space',
/// 'BackSpace').
Future<void> _keys(List<String> keys) async {
  await _run(_wlkey, <String>['-g', '80', ...keys]);
  await Future<void>.delayed(const Duration(milliseconds: 80));
}

Future<void> _toggleLanguage() async {
  // The harness configures ibus-hangul with switch-keys Shift+space.
  await _run(_wlkey, <String>['-g', '80', 'shift+space']);
  await Future<void>.delayed(const Duration(milliseconds: 80));
}

Future<void> _ensureHangulMode(File probe) async {
  await _keys(<String>['g']);
  final latin = await _waitForOptional(
    () => probe.existsSync() && probe.lengthSync() == 1,
    const Duration(seconds: 2),
  );
  if (latin) {
    expect(probe.readAsBytesSync(), utf8.encode('g'));
    // A newly-created GTK input context can start in the engine's Latin mode
    // even though `ibus engine` already reports `hangul`. Use the configured
    // physical switch chord, matching the X11 sibling.
    await _toggleLanguage();
    return;
  }

  await _keys(<String>['BackSpace']);
  await _toggleLanguage();
  await _keys(<String>['x']);
  await _waitUntil(
    () => probe.existsSync() && probe.lengthSync() == 1,
    'the Latin mode probe byte to reach the PTY',
  );
  expect(probe.readAsBytesSync(), utf8.encode('x'));
  await _toggleLanguage();
}

Future<void> _activateHangulEngine() async {
  final engines = await _run('ibus', <String>['list-engine']);
  const latinEngine = 'xkb:us::eng';
  expect(
    engines.stdout.toString(),
    contains(latinEngine),
    reason: 'The deterministic IBus Latin engine is unavailable',
  );
  await _run('ibus', <String>['engine', latinEngine]);

  await _waitUntil(() async {
    final selected = await Process.run('ibus', <String>['engine', 'hangul']);
    final current = await Process.run('ibus', <String>['engine']);
    return selected.exitCode == 0 &&
        current.exitCode == 0 &&
        current.stdout.toString().trim() == 'hangul';
  }, 'the focused GTK input context to activate IBus Hangul');
}

Future<void> _waitUntil(
  FutureOr<bool> Function() predicate,
  String description,
) async {
  final deadline = DateTime.now().add(const Duration(seconds: 15));
  while (!await predicate() && DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  expect(
    await predicate(),
    isTrue,
    reason: 'Timed out waiting for $description',
  );
}

Future<bool> _waitForOptional(
  bool Function() predicate,
  Duration timeout,
) async {
  final deadline = DateTime.now().add(timeout);
  while (!predicate() && DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  return predicate();
}

String _hex(int value) => value.toRadixString(16).padLeft(2, '0');

Future<void> _initializeGitRepository(String path) async {
  await _run('git', <String>['-C', path, 'init', '-b', 'main']);
  await File('$path/README.md').writeAsString('# IBus Wayland E2E fixture\n');
  await _run('git', <String>['-C', path, 'add', 'README.md']);
  await _run('git', <String>[
    '-C',
    path,
    '-c',
    'user.name=Coder IBus Wayland E2E',
    '-c',
    'user.email=coder-ibus-wayland-e2e@example.invalid',
    'commit',
    '-m',
    'Initial fixture',
  ]);
}

Future<ProcessResult> _run(String executable, List<String> arguments) async {
  final result = await Process.run(executable, arguments);
  if (result.exitCode != 0) {
    throw ProcessException(
      executable,
      arguments,
      '${result.stdout}\n${result.stderr}',
      result.exitCode,
    );
  }
  return result;
}
