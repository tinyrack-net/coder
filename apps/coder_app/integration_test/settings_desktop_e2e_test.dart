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

import 'support/ephemeral_port.dart';
import 'support/pump_until.dart';
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
    'the appearance choice survives a restart and otherwise follows the system',
    (tester) async {
      // The shared harness pins the canonical dark desktop brightness and the
      // Korean locale, so the option labels below are Korean and the teardown
      // restores that brightness instead of clearing it to the real platform.
      addTearDown(
        () => tester.binding.platformDispatcher.platformBrightnessTestValue =
            Brightness.dark,
      );
      final fixture = await RealDaemonFixture.start(id: 'settings-appearance');
      addTearDown(fixture.dispose);

      await _pumpApp(tester, fixture);
      await _openGeneralSettings(tester);

      // Nothing is stored yet, so the pinned platform brightness decides.
      expect(fixture.store.settings.themeMode, AppThemeMode.system);
      expect(_renderedBrightness(tester), Brightness.dark);

      await tester.tap(_selectTrigger('general-settings-theme-mode'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('라이트').last);
      await tester.pumpAndSettle();

      expect(fixture.store.settings.themeMode, AppThemeMode.light);
      expect(_appThemeMode(tester), ThemeMode.light);
      // A light choice has to win against the dark platform brightness.
      expect(_renderedBrightness(tester), Brightness.light);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await _pumpApp(tester, fixture);

      expect(_appThemeMode(tester), ThemeMode.light);
      expect(_renderedBrightness(tester), Brightness.light);

      await _openGeneralSettings(tester);
      await tester.tap(_selectTrigger('general-settings-theme-mode'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('시스템 테마 따름').last);
      await tester.pumpAndSettle();

      expect(fixture.store.settings.themeMode, AppThemeMode.system);
      expect(_appThemeMode(tester), ThemeMode.system);

      // Following the system means tracking it live, not just at startup.
      tester.binding.platformDispatcher.platformBrightnessTestValue =
          Brightness.light;
      await tester.pumpAndSettle();
      expect(_renderedBrightness(tester), Brightness.light);

      tester.binding.platformDispatcher.platformBrightnessTestValue =
          Brightness.dark;
      await tester.pumpAndSettle();
      expect(_renderedBrightness(tester), Brightness.dark);
    },
    tags: const <String>[
      'feature_scenario__settings_appearance__restart_persistence__e2e',
      'feature_scenario__settings_appearance__system_brightness_follow__e2e',
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
    'a full reset erases real daemon data, keeps checkouts, and restarts',
    (tester) async {
      tester.binding.platformDispatcher.localeTestValue = const Locale('ko');
      addTearDown(tester.binding.platformDispatcher.clearLocaleTestValue);
      final home = await Directory.systemTemp.createTemp('coder-reset-e2e-');
      addTearDown(() {
        if (home.existsSync()) home.deleteSync(recursive: true);
      });
      // One shared resolution, exactly as the production composition root
      // wires the launcher and the eraser.
      final config = DaemonConfig(
        homeDirectory: home.path,
        port: 0,
        useEnvironmentCredentials: false,
      );
      final launcher = _IdentityRecordingLauncher(
        IsolateEmbeddedDaemonLauncher(resolveConfig: () => config),
      );
      // The reset restores the store's factory defaults and restarts the real
      // daemon on them, so the port after the reset has to be reserved too.
      final store = MemoryAppStore(
        settings: AppSettings(
          embeddedDaemonPort: await reserveEphemeralPort(),
          localeTag: 'ko',
          sidebarCollapsed: true,
        ),
        factoryDefaults: AppSettings(
          embeddedDaemonPort: await reserveEphemeralPort(),
        ),
      );
      await tester.pumpWidget(
        CoderApp(
          services: AppServices(
            settings: store,
            profiles: store,
            credentials: store,
            clients: const WebSocketHostClientFactory(),
            clientKind: 'reset-e2e',
            embeddedLauncher: launcher,
            embeddedDataEraser: IsolateEmbeddedDaemonDataEraser(
              resolveConfig: () => config,
            ),
          ),
          autostart: _RecordingAutostart(),
        ),
      );
      await pumpUntilCondition(
        tester,
        () => launcher.serverIds.isNotEmpty,
        'the embedded daemon to start',
      );
      await tester.pumpAndSettle();

      // Unpushed work in a managed checkout has to survive the reset.
      final checkout = File(
        _join(<String>[home.path, 'worktrees', 'repo', 'main.dart']),
      );
      await checkout.create(recursive: true);
      await checkout.writeAsString('void main() {}');
      expect(
        File(_join(<String>[home.path, 'coder.sqlite'])).existsSync(),
        isTrue,
      );
      expect(
        File(_join(<String>[home.path, 'credentials.json'])).existsSync(),
        isTrue,
      );

      await tester.tap(find.byIcon(CoderIcons.settings));
      await tester.pumpAndSettle();
      await tester.tap(find.text('고급'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('advanced-settings-reset-button')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('advanced-reset-confirm-accept')),
      );
      await pumpUntilCondition(
        tester,
        () => launcher.serverIds.length == 2,
        'the embedded daemon to restart',
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('advanced-settings-reset-error')),
        findsNothing,
      );
      expect(launcher.serverIds.last, isNot(launcher.serverIds.first));
      expect(launcher.tokens.last, isNot(launcher.tokens.first));
      expect(store.settings.localeTag, isNull);
      expect(store.settings.sidebarCollapsed, isFalse);
      // The daemon rebuilt its own state, so these exist again but hold
      // nothing from before the reset.
      expect(checkout.existsSync(), isTrue);
      expect(await checkout.readAsString(), 'void main() {}');
    },
    tags: const <String>[
      'feature_scenario__settings_reset__full_reset_restart__e2e',
      'feature_scenario__settings_reset__preserves_checkouts__e2e',
    ],
  );

  testWidgets(
    'tray quit stops the real embedded daemon before ending the process',
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
          resolveConfig: () => DaemonConfig(
            homeDirectory: home.path,
            port: 0,
            bearerToken: 'tray-quit-e2e-token-0123456789abcdef',
            useEnvironmentCredentials: false,
          ),
        ),
        calls,
      );
      final store = MemoryAppStore(
        settings: AppSettings(embeddedDaemonPort: await reserveEphemeralPort()),
      );
      final window = _RecordingWindow(calls);
      final tray = _RecordingTray(calls);
      final terminator = _RecordingTerminator(calls);
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
          terminator: terminator,
          autostart: _RecordingAutostart(),
        ),
      );
      await pumpUntilCondition(
        tester,
        () => launcher.session != null,
        'the embedded daemon session to exist',
      );
      await pumpUntilCondition(
        tester,
        () =>
            tray.menu?.entries.any((entry) => entry.key == trayItemQuit) ==
            true,
        'the tray menu to offer Quit',
      );

      tray
        ..select(trayItemQuit)
        ..select(trayItemQuit);
      await pumpUntilCondition(
        tester,
        () => terminator.terminations == 1,
        'the process to be ended exactly once',
      );

      expect(launcher.session!.stops, 1);
      expect(tray.destroys, 1);
      expect(terminator.terminations, 1);
      expect(
        calls,
        containsAllInOrder(<String>[
          'hide',
          'destroyTray',
          'releaseClose',
          'stopDaemon',
          'terminate',
        ]),
      );
    },
    tags: const <String>[
      'feature_scenario__desktop_residency__tray_quit__e2e',
    ],
  );
}

String _join(List<String> segments) => segments.join(Platform.pathSeparator);

Future<void> _waitForVisibility(
  DesktopWindow window, {
  required bool visible,
}) => awaitCondition(
  () async => await window.isVisible() == visible,
  'the window to become ${visible ? 'visible' : 'hidden'}',
);

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

ThemeMode? _appThemeMode(WidgetTester tester) =>
    tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode;

/// Brightness the running app actually resolved, not the one it was offered.
Brightness _renderedBrightness(WidgetTester tester) =>
    Theme.of(tester.element(find.byType(Navigator).last)).brightness;

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

/// Records the identity each real embedded daemon starts with.
final class _IdentityRecordingLauncher implements EmbeddedDaemonLauncher {
  _IdentityRecordingLauncher(this.delegate);

  final EmbeddedDaemonLauncher delegate;
  final List<String> serverIds = <String>[];
  final List<String> tokens = <String>[];

  @override
  Future<EmbeddedDaemonSession> start({
    required EmbeddedDaemonExposure exposure,
    required int port,
  }) async {
    final session = await delegate.start(exposure: exposure, port: port);
    serverIds.add(session.serverId);
    tokens.add(session.credentials.bearerToken);
    return session;
  }
}

final class _RecordingEmbeddedLauncher implements EmbeddedDaemonLauncher {
  _RecordingEmbeddedLauncher(this.delegate, this.calls);

  final EmbeddedDaemonLauncher delegate;
  final List<String> calls;
  _RecordingEmbeddedSession? session;

  @override
  Future<EmbeddedDaemonSession> start({
    required EmbeddedDaemonExposure exposure,
    required int port,
  }) async {
    final result = _RecordingEmbeddedSession(
      await delegate.start(exposure: exposure, port: port),
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

  @override
  ValueListenable<bool> get maximized => _maximized;

  @override
  bool get supportsCustomTitleBar => false;

  @override
  Future<void> hide() async => calls.add('hide');

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

final class _RecordingTerminator implements AppTerminator {
  _RecordingTerminator(this.calls);

  final List<String> calls;
  int terminations = 0;

  @override
  Future<void> terminate() async {
    terminations += 1;
    calls.add('terminate');
  }
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
