import 'package:coder_app/src/app.dart';
import 'package:coder_app/src/app_services.dart';
import 'package:coder_app/src/host_models.dart';
import 'package:coder_app/src/host_ports.dart';
import 'package:coder_client/coder_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'the language setting switches the whole app and persists the choice',
    (tester) async {
      final store = MemoryAppStore(
        settings: const AppSettings(embeddedDaemonEnabled: false),
      );
      await tester.pumpWidget(_app(store));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text('General'));
      await tester.pumpAndSettle();

      // Nothing is stored yet, so the app follows the pinned platform locale.
      expect(store.settings.localeTag, isNull);
      expect(find.text('설정'), findsOneWidget);
      expect(find.text('시스템 설정 따름'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey<String>('general-settings-language')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('English').last);
      await tester.pumpAndSettle();

      expect(store.settings.localeTag, 'en');
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Display language'), findsOneWidget);
      expect(find.text('설정'), findsNothing);

      // Returning to the system default clears the stored tag rather than
      // storing the resolved locale, so the app follows the platform again.
      await tester.tap(
        find.byKey(const ValueKey<String>('general-settings-language')),
      );
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

      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
    },
    tags: const <String>['feature_test__settings_language__widget'],
  );
}

Widget _app(MemoryAppStore store) => CoderApp(
  services: AppServices(
    settings: store,
    profiles: store,
    credentials: store,
    clients: const _OfflineClients(),
    clientKind: 'test',
  ),
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
