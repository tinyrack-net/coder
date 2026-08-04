import 'package:coder_app/src/app.dart';
import 'package:coder_app/src/app_services.dart';
import 'package:coder_app/src/coder_icons.dart';
import 'package:coder_app/src/coder_selection_row.dart';
import 'package:coder_app/src/desktop_shell.dart';
import 'package:coder_app/src/host_models.dart';
import 'package:coder_app/src/host_ports.dart';
import 'package:coder_client/coder_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_desktop_ports.dart';

void main() {
  testWidgets(
    'the language setting switches the whole app and persists the choice',
    (tester) async {
      final store = MemoryAppStore(
        settings: const AppSettings(embeddedDaemonEnabled: false),
      );
      await tester.pumpWidget(_app(store));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(CoderIcons.settings));
      await tester.pumpAndSettle();
      await tester.tap(find.text('General'));
      await tester.pumpAndSettle();

      // Nothing is stored yet, so the app follows the pinned platform locale.
      expect(store.settings.localeTag, isNull);
      expect(find.text('설정'), findsOneWidget);
      expect(find.text('시스템 설정 따름'), findsOneWidget);

      await tester.tap(_selectTrigger('general-settings-language'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('English').last);
      await tester.pumpAndSettle();

      expect(store.settings.localeTag, 'en');
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('DISPLAY LANGUAGE'), findsOneWidget);
      expect(find.text('설정'), findsNothing);

      // Returning to the system default clears the stored tag rather than
      // storing the resolved locale, so the app follows the platform again.
      await tester.tap(_selectTrigger('general-settings-language'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('System default').last);
      await tester.pumpAndSettle();

      expect(store.settings.localeTag, isNull);
      expect(find.text('설정'), findsOneWidget);
    },
    tags: const <String>['feature_test__settings_language__widget'],
  );

  testWidgets(
    'a stored language is applied on the next start',
    (tester) async {
      final store = MemoryAppStore(
        settings: const AppSettings(
          embeddedDaemonEnabled: false,
          localeTag: 'en',
        ),
      );
      await tester.pumpWidget(_app(store));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(CoderIcons.settings));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
    },
    tags: const <String>['feature_test__settings_language__widget'],
  );

  testWidgets(
    'the startup toggles persist and re-register the login item',
    (tester) async {
      final store = MemoryAppStore(
        settings: const AppSettings(embeddedDaemonEnabled: false),
      );
      final autostart = FakeAutostartRegistration(enabled: true);
      await tester.pumpWidget(_app(store, autostart: autostart));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(CoderIcons.settings));
      await tester.pumpAndSettle();
      await tester.tap(find.text('General'));
      await tester.pumpAndSettle();

      expect(store.settings.startAtBoot, isTrue);
      expect(store.settings.startMinimizedAtBoot, isTrue);

      // Turning off "start minimized" keeps the login item but has to rewrite
      // the arguments it records.
      await tester.tap(
        find.byKey(const ValueKey<String>('general-settings-start-minimized')),
      );
      await tester.pumpAndSettle();
      expect(store.settings.startMinimizedAtBoot, isFalse);
      expect(
        autostart.applications.last,
        (enabled: true, minimized: false),
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('general-settings-start-at-boot')),
      );
      await tester.pumpAndSettle();
      expect(store.settings.startAtBoot, isFalse);
      expect(autostart.enabled, isFalse);
      expect(
        autostart.applications.last,
        (enabled: false, minimized: false),
      );
    },
    tags: const <String>['feature_test__settings_startup__widget'],
  );

  testWidgets(
    'start minimized is disabled while the app does not start at login',
    (tester) async {
      final store = MemoryAppStore(
        settings: const AppSettings(
          embeddedDaemonEnabled: false,
          startAtBoot: false,
        ),
      );
      final autostart = FakeAutostartRegistration();
      await tester.pumpWidget(_app(store, autostart: autostart));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(CoderIcons.settings));
      await tester.pumpAndSettle();
      await tester.tap(find.text('General'));
      await tester.pumpAndSettle();

      // Starting minimized only describes a login launch, so it cannot be
      // chosen while there is no login launch to describe.
      expect(
        tester
            .widget<CoderSwitchRow>(
              find.byKey(
                const ValueKey<String>('general-settings-start-minimized'),
              ),
            )
            .onChanged,
        isNull,
      );

      // The stored choice is preserved rather than forced off, so turning
      // start-at-login back on restores it.
      expect(store.settings.startMinimizedAtBoot, isTrue);
      await tester.tap(
        find.byKey(const ValueKey<String>('general-settings-start-at-boot')),
      );
      await tester.pumpAndSettle();
      expect(
        autostart.applications.single,
        (enabled: true, minimized: true),
      );
    },
    tags: const <String>['feature_test__settings_startup__widget'],
  );

  testWidgets(
    'a build without login items hides the startup card entirely',
    (tester) async {
      final store = MemoryAppStore(
        settings: const AppSettings(embeddedDaemonEnabled: false),
      );
      await tester.pumpWidget(_app(store));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(CoderIcons.settings));
      await tester.pumpAndSettle();
      await tester.tap(find.text('General'));
      await tester.pumpAndSettle();

      expect(find.text('표시 언어'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('general-settings-start-at-boot')),
        findsNothing,
      );
    },
    tags: const <String>['feature_test__settings_startup__widget'],
  );
}

Finder _selectTrigger(String key) => find.descendant(
  of: find.byKey(ValueKey<String>(key)),
  matching: find.byType(TextButton),
);

Widget _app(MemoryAppStore store, {AutostartRegistration? autostart}) =>
    CoderApp(
      services: AppServices(
        settings: store,
        profiles: store,
        credentials: store,
        clients: const _OfflineClients(),
        clientKind: 'test',
      ),
      autostart: autostart,
    );

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
