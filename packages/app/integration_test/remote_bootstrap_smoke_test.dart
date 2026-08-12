import 'package:app/src/app/composition/app_services.dart';
import 'package:app/src/app/tinest_app.dart';
import 'package:app/src/features/hosts/domain/host_models.dart';
import 'package:app/src/features/hosts/domain/host_ports.dart';
import 'package:client/client.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'mobile bootstrap remains remote-only',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final store = MemoryAppStore(
        settings: const AppSettings(embeddedDaemonEnabled: false),
      );
      await tester.pumpWidget(
        TinestApp(
          services: AppServices(
            settings: store,
            profiles: store,
            credentials: store,
            clients: const _UnusedClients(),
            clientKind: 'mobile-integration-test',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('설정된 daemon이 없습니다.'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey<String>('workspace-settings-button')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('settings-category-select')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('settings-daemon-select')),
        findsNothing,
      );
      await tester.tap(find.text('Daemons'));
      await tester.pumpAndSettle();
      expect(find.text('내장 daemon'), findsNothing);
      expect(find.text('기기 연결'), findsOneWidget);

      await tester.tap(find.text('기기 연결'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('connect-daemon-paste')),
      );
      await tester.pumpAndSettle();

      final field = find.byKey(const ValueKey<String>('relay-pair-link'));
      final action = find.byKey(const ValueKey<String>('relay-pair-review'));
      await tester.tap(field);
      await tester.showKeyboard(field);
      await tester.pumpAndSettle();

      final mediaQuery = MediaQuery.of(tester.element(field));
      expect(mediaQuery.viewInsets.bottom, greaterThan(0));
      final keyboardTop = mediaQuery.size.height - mediaQuery.viewInsets.bottom;
      expect(tester.getRect(field).bottom, lessThanOrEqualTo(keyboardTop));
      expect(tester.getRect(action).bottom, lessThanOrEqualTo(keyboardTop));
    },
    tags: const <String>[
      'feature_test__daemon_management__platformSmoke',
      'feature_test__daemon_relay__platformSmoke',
      'feature_test__soft_keyboard_visibility__platformSmoke',
    ],
  );
}

final class _UnusedClients implements HostClientFactory {
  const _UnusedClients();

  @override
  Future<TinestApi> connect({
    required HostConnection connection,
    required HostConnectionCredential credential,
    required String clientId,
    required String clientKind,
  }) => throw StateError('No host should connect in a remote-only smoke test.');
}
