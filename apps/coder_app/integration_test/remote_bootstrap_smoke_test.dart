import 'package:coder_app/src/app/coder_app.dart';
import 'package:coder_app/src/app/composition/app_services.dart';
import 'package:coder_app/src/features/hosts/domain/host_models.dart';
import 'package:coder_app/src/features/hosts/domain/host_ports.dart';
import 'package:coder_client/coder_client.dart';
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
        CoderApp(
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
      await tester.tap(
        find.byKey(const ValueKey<String>('settings-category-select')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Daemons').last);
      await tester.pumpAndSettle();
      expect(find.text('내장 daemon'), findsNothing);
      expect(find.text('원격 daemon 추가'), findsOneWidget);
    },
    tags: const <String>['feature_test__daemon_management__platformSmoke'],
  );
}

final class _UnusedClients implements HostClientFactory {
  const _UnusedClients();

  @override
  Future<CoderApi> connect({
    required HostEndpoint endpoint,
    required DaemonCredentials credentials,
    required String clientId,
    required String clientKind,
  }) => throw StateError('No host should connect in a remote-only smoke test.');
}
