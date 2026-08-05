import 'dart:io';

import 'package:coder_app/src/app.dart';
import 'package:coder_app/src/app_services.dart';
import 'package:coder_app/src/coder_icons.dart';
import 'package:coder_app/src/desktop_bootstrap.dart';
import 'package:coder_app/src/desktop_shell.dart';
import 'package:coder_app/src/host_models.dart';
import 'package:coder_app/src/host_ports.dart';
import 'package:coder_app/src/tray_menu_model.dart';
import 'package:coder_client/coder_client.dart';
import 'package:coder_daemon/coder_daemon.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/real_daemon_fixture.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'language selection and restart persistence use the real app',
    (tester) async {
      tester.binding.platformDispatcher.localeTestValue = const Locale('ko');
      addTearDown(tester.binding.platformDispatcher.clearLocaleTestValue);
      final fixture = await RealDaemonFixture.start(id: 'settings');
      addTearDown(fixture.dispose);

      await _pumpApp(tester, fixture);
      await _openGeneralSettings(tester);
      expect(find.text('시스템 설정 따름'), findsOneWidget);

      await tester.tap(_selectTrigger('general-settings-language'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('English').last);
      await tester.pumpAndSettle();
      expect(fixture.store.settings.localeTag, 'en');
      expect(find.text('Settings'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await _pumpApp(tester, fixture);
      await tester.tap(find.byIcon(CoderIcons.settings));
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsOneWidget);

      await tester.tap(find.text('General'));
      await tester.pumpAndSettle();
      await tester.tap(_selectTrigger('general-settings-language'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('System default').last);
      await tester.pumpAndSettle();
      expect(fixture.store.settings.localeTag, isNull);
      expect(find.text('설정'), findsOneWidget);
    },
    tags: const <String>[
      'feature_scenario__settings_language__selection_restart_persistence__e2e',
      'feature_scenario__settings_language__system_locale_fallback__e2e',
    ],
  );

  testWidgets(
    'startup preferences persist and rewrite the typed login-item port',
    (tester) async {
      final fixture = await RealDaemonFixture.start(id: 'settings-startup');
      addTearDown(fixture.dispose);
      final autostart = _RecordingAutostart();

      await _pumpApp(tester, fixture, autostart: autostart);
      await _openGeneralSettings(tester);

      await tester.tap(
        find.byKey(const ValueKey<String>('general-settings-start-minimized')),
      );
      await tester.pumpAndSettle();
      expect(fixture.store.settings.startMinimizedAtBoot, isFalse);
      expect(autostart.applications.last, (enabled: true, minimized: false));

      await tester.tap(
        find.byKey(const ValueKey<String>('general-settings-start-at-boot')),
      );
      await tester.pumpAndSettle();
      expect(fixture.store.settings.startAtBoot, isFalse);
      expect(autostart.applications.last, (enabled: false, minimized: false));
    },
    tags: const <String>[
      'feature_scenario__settings_startup__registration_toggle__e2e',
    ],
  );

  testWidgets(
    'a login-time launch prepares the real desktop window hidden',
    (tester) async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      final window = PluginDesktopWindow();
      addTearDown(() async {
        await window.show();
        await window.releaseClose();
      });
      await window.prepare(startHidden: true);

      expect(await window.isVisible(), isFalse);
      await window.show();
      await _waitForVisibility(window, visible: true);
      expect(await window.isVisible(), isTrue);
    },
    tags: const <String>[
      'feature_scenario__settings_startup__hidden_login_launch__e2e',
    ],
  );

  testWidgets(
    'tray quit stops the real embedded daemon before destroying the window',
    (tester) async {
      final home = await Directory.systemTemp.createTemp(
        'coder-tray-quit-e2e-',
      );
      addTearDown(() {
        if (home.existsSync()) home.deleteSync(recursive: true);
      });
      final calls = <String>[];
      final launcher = _RecordingEmbeddedLauncher(
        IsolateEmbeddedDaemonLauncher(
          config: DaemonConfig(
            homeDirectory: home.path,
            port: 0,
            bearerToken: 'tray-quit-e2e-token-0123456789abcdef',
            useEnvironmentCredentials: false,
          ),
        ),
        calls,
      );
      final store = MemoryAppStore();
      final window = _RecordingWindow(calls);
      final tray = _RecordingTray(calls);
      final services = AppServices(
        settings: store,
        profiles: store,
        credentials: store,
        clients: const WebSocketHostClientFactory(),
        clientKind: 'tray-quit-e2e',
        embeddedLauncher: launcher,
      );

      await tester.pumpWidget(
        CoderApp(
          services: services,
          desktopWindow: window,
          trayIcon: tray,
          autostart: _RecordingAutostart(),
        ),
      );
      await _pumpUntil(tester, () => launcher.session != null);
      await _pumpUntil(
        tester,
        () =>
            tray.menu?.entries.any((entry) => entry.key == trayItemQuit) ==
            true,
      );

      tray
        ..select(trayItemQuit)
        ..select(trayItemQuit);
      await _pumpUntil(tester, () => window.destroys == 1);

      expect(launcher.session!.stops, 1);
      expect(tray.destroys, 1);
      expect(window.destroys, 1);
      expect(
        calls,
        containsAllInOrder(<String>[
          'destroyTray',
          'releaseClose',
          'stopDaemon',
          'destroyWindow',
        ]),
      );
    },
    tags: const <String>[
      'feature_scenario__desktop_residency__tray_quit__e2e',
    ],
  );
}

Future<void> _waitForVisibility(
  DesktopWindow window, {
  required bool visible,
}) async {
  for (var attempt = 0; attempt < 100; attempt += 1) {
    if (await window.isVisible() == visible) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  throw TestFailure('Window visibility did not become $visible.');
}

Future<void> _pumpApp(
  WidgetTester tester,
  RealDaemonFixture fixture, {
  AutostartRegistration? autostart,
}) async {
  await tester.pumpWidget(
    CoderApp(
      services: fixture.services,
      autostart: autostart,
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openGeneralSettings(WidgetTester tester) async {
  await tester.tap(find.byIcon(CoderIcons.settings));
  await tester.pumpAndSettle();
  await tester.tap(find.text('General'));
  await tester.pumpAndSettle();
}

Finder _selectTrigger(String key) => find.descendant(
  of: find.byKey(ValueKey<String>(key)),
  matching: find.byType(TextButton),
);

Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() condition,
) async {
  for (var attempt = 0; attempt < 200; attempt += 1) {
    if (condition()) return;
    await tester.pump(const Duration(milliseconds: 20));
  }
  throw TestFailure('Timed out waiting for the desktop E2E condition.');
}

final class _RecordingAutostart implements AutostartRegistration {
  final List<({bool enabled, bool minimized})> applications =
      <({bool enabled, bool minimized})>[];

  @override
  Future<void> apply({required bool enabled, required bool minimized}) async {
    applications.add((enabled: enabled, minimized: minimized));
  }

  @override
  Future<bool> isEnabled() async => true;
}

final class _RecordingEmbeddedLauncher implements EmbeddedDaemonLauncher {
  _RecordingEmbeddedLauncher(this.delegate, this.calls);

  final EmbeddedDaemonLauncher delegate;
  final List<String> calls;
  _RecordingEmbeddedSession? session;

  @override
  Future<EmbeddedDaemonSession> start({
    required EmbeddedDaemonExposure exposure,
  }) async {
    final result = _RecordingEmbeddedSession(
      await delegate.start(exposure: exposure),
      calls,
    );
    session = result;
    return result;
  }
}

final class _RecordingEmbeddedSession implements EmbeddedDaemonSession {
  _RecordingEmbeddedSession(this.delegate, this.calls);

  final EmbeddedDaemonSession delegate;
  final List<String> calls;
  int stops = 0;

  @override
  DaemonCredentials get credentials => delegate.credentials;

  @override
  HostEndpoint get endpoint => delegate.endpoint;

  @override
  String get serverId => delegate.serverId;

  @override
  Future<void> stop() async {
    stops += 1;
    calls.add('stopDaemon');
    await delegate.stop();
  }
}

final class _RecordingWindow implements DesktopWindow {
  _RecordingWindow(this.calls);

  final List<String> calls;
  final ValueNotifier<bool> _maximized = ValueNotifier<bool>(false);
  int destroys = 0;

  @override
  ValueListenable<bool> get maximized => _maximized;

  @override
  bool get supportsCustomTitleBar => false;

  @override
  Future<void> destroy() async {
    destroys += 1;
    calls.add('destroyWindow');
  }

  @override
  Future<void> hide() async {}

  @override
  Future<void> interceptClose(void Function() onClose) async {}

  @override
  Future<bool> isVisible() async => true;

  @override
  Future<void> minimize() async {}

  @override
  Future<void> prepare({required bool startHidden}) async {}

  @override
  Future<void> releaseClose() async => calls.add('releaseClose');

  @override
  Future<void> show() async {}

  @override
  Future<void> startDragging() async {}

  @override
  Future<void> toggleMaximized() async {}
}

final class _RecordingTray implements TrayIcon {
  _RecordingTray(this.calls);

  final List<String> calls;
  TrayMenuModel? menu;
  void Function(String itemKey)? _onSelected;
  int destroys = 0;

  void select(String itemKey) => _onSelected?.call(itemKey);

  @override
  Future<void> destroy() async {
    destroys += 1;
    calls.add('destroyTray');
  }

  @override
  Future<void> install({
    required TrayMenuModel menu,
    required void Function(String itemKey) onSelected,
  }) async {
    this.menu = menu;
    _onSelected = onSelected;
  }

  @override
  Future<void> update(TrayMenuModel menu) async {
    this.menu = menu;
  }
}
