import 'dart:io';

import 'package:app/src/app/composition/app_services.dart';
import 'package:app/src/features/desktop/infrastructure/desktop_bootstrap.dart';
import 'package:app/src/features/hosts/domain/host_models.dart';
import 'package:app/src/features/hosts/domain/host_ports.dart';
import 'package:app/src/features/hosts/infrastructure/remote_bootstrap.dart';
import 'package:client/client.dart';
import 'package:daemon/daemon.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_coder_api.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  test(
    'desktop and mobile service factories expose platform capabilities',
    () async {
      const clients = _UnusedClients();
      const launcher = _UnusedLauncher();
      final desktop = await createDesktopServices(
        embeddedLauncher: launcher,
        clients: clients,
      );
      final mobile = await createRemoteServices(clients: clients);

      expect(desktop.supportsEmbeddedDaemon, isTrue);
      expect(desktop.embeddedLauncher, same(launcher));
      expect(desktop.clients, same(clients));
      expect(desktop.clientKind, 'desktop');
      expect(mobile.supportsEmbeddedDaemon, isFalse);
      expect(mobile.embeddedLauncher, isNull);
      expect(mobile.clients, same(clients));
      expect(mobile.clientKind, 'mobile');
    },
  );

  test(
    'isolate launcher returns endpoint, identity, credentials, and stop',
    () async {
      final handle = _DaemonHandle();
      DaemonConfig? startedConfig;
      const config = DaemonConfig(
        homeDirectory: '/test-home',
        port: 0,
        bearerToken: 'launcher-token-0123456789abcdef012345',
        useEnvironmentCredentials: false,
      );
      final launcher = IsolateEmbeddedDaemonLauncher(
        resolveConfig: () => config,
        startDaemon: (value) async {
          startedConfig = value;
          return handle;
        },
      );

      final session = await launcher.start(
        exposure: EmbeddedDaemonExposure.allInterfaces,
        port: 8123,
      );
      expect(startedConfig?.host, '0.0.0.0');
      expect(startedConfig?.port, 8123);
      expect(startedConfig?.homeDirectory, config.homeDirectory);
      expect(startedConfig?.bearerToken, config.bearerToken);
      expect(session.endpoint.websocketUri.scheme, 'ws');
      expect(session.serverId, isNotEmpty);
      expect(
        session.credentials.bearerToken,
        'launcher-token-0123456789abcdef012345',
      );
      await session.stop();
      expect(handle.stops, 1);
    },
  );

  test('isolate launcher preserves a typed port conflict', () async {
    final launcher = IsolateEmbeddedDaemonLauncher(
      resolveConfig: () => const DaemonConfig(homeDirectory: '/test-home'),
      startDaemon: (value) => Future<DaemonHandle>.error(
        const EmbeddedDaemonStartupException(
          'address already in use',
          reason: EmbeddedDaemonStartupFailureReason.portInUse,
        ),
      ),
    );

    await expectLater(
      launcher.start(exposure: EmbeddedDaemonExposure.loopback, port: 7337),
      throwsA(
        isA<HostConnectionFailure>().having(
          (error) => error.reason,
          'reason',
          HostFailureReason.embeddedPortInUse,
        ),
      ),
    );
  });

  test(
    'isolate launcher preserves a typed already-running conflict',
    () async {
      final launcher = IsolateEmbeddedDaemonLauncher(
        resolveConfig: () => const DaemonConfig(homeDirectory: '/test-home'),
        startDaemon: (value) => Future<DaemonHandle>.error(
          const EmbeddedDaemonStartupException(
            'A daemon is already running on /test-home.',
            reason: EmbeddedDaemonStartupFailureReason.alreadyRunning,
          ),
        ),
      );

      await expectLater(
        launcher.start(exposure: EmbeddedDaemonExposure.loopback, port: 7337),
        throwsA(
          isA<HostConnectionFailure>()
              .having(
                (error) => error.reason,
                'reason',
                HostFailureReason.embeddedAlreadyRunning,
              )
              // The raw diagnostic survives the mapping so the settings
              // page can offer it for a bug report.
              .having(
                (error) => error.message,
                'message',
                contains('/test-home'),
              ),
        ),
      );
    },
    tags: const <String>['feature_test__daemon_management__unit'],
  );

  test(
    'real embedded launcher starts in loopback and all-interface modes',
    () async {
      final home = await Directory.systemTemp.createTemp(
        'coder-exposure-vertical-slice-',
      );
      addTearDown(() {
        if (home.existsSync()) home.deleteSync(recursive: true);
      });
      final launcher = IsolateEmbeddedDaemonLauncher(
        resolveConfig: () => DaemonConfig(
          homeDirectory: home.path,
          port: 0,
          bearerToken: 'exposure-token-0123456789abcdef012345',
          useEnvironmentCredentials: false,
        ),
      );

      for (final exposure in EmbeddedDaemonExposure.values) {
        final session = await launcher.start(exposure: exposure, port: 0);
        final client = await CoderClient.connect(
          endpoint: session.endpoint,
          credentials: session.credentials,
          clientId: 'exposure-${exposure.name}',
          clientKind: 'vertical-slice',
        );
        expect(client.serverInfo.serverId, session.serverId);
        await client.close();
        await session.stop();
      }
    },
    tags: const <String>[
      'feature_test__daemon_exposure__verticalSlice',
      'feature_test__daemon_exposure__platformSmoke',
    ],
  );

  test('WebSocket factory classifies typed connection failures', () async {
    final api = FakeCoderApi();
    final endpoint = HostEndpoint.parse('wss://daemon.example/ws');
    const credentials = DaemonCredentials(bearerToken: 'token');
    final success = WebSocketHostClientFactory(
      openClient:
          ({
            required endpoint,
            required credentials,
            required clientId,
            required clientKind,
          }) async => api,
    );
    expect(
      await success.connect(
        endpoint: endpoint,
        credentials: credentials,
        clientId: 'client',
        clientKind: 'test',
      ),
      same(api),
    );

    Future<CoderApi> connectWith(Object error) =>
        WebSocketHostClientFactory(
          openClient:
              ({
                required endpoint,
                required credentials,
                required clientId,
                required clientKind,
              }) => Future<CoderApi>.error(error),
        ).connect(
          endpoint: endpoint,
          credentials: credentials,
          clientId: 'client',
          clientKind: 'test',
        );

    await expectLater(
      connectWith(
        const CoderClientException(
          'wrong protocol',
          code: 'protocol_mismatch',
        ),
      ),
      throwsA(
        isA<HostConnectionFailure>().having(
          (failure) => failure.kind,
          'kind',
          HostConnectionFailureKind.protocolMismatch,
        ),
      ),
    );
    await expectLater(
      connectWith(Exception('HTTP 401')),
      throwsA(
        isA<HostConnectionFailure>().having(
          (failure) => failure.kind,
          'kind',
          HostConnectionFailureKind.authentication,
        ),
      ),
    );
    await expectLater(
      connectWith(Exception('offline')),
      throwsA(
        isA<HostConnectionFailure>().having(
          (failure) => failure.kind,
          'kind',
          HostConnectionFailureKind.network,
        ),
      ),
    );
  });
}

final class _UnusedClients implements HostClientFactory {
  const _UnusedClients();

  @override
  Future<CoderApi> connect({
    required HostEndpoint endpoint,
    required DaemonCredentials credentials,
    required String clientId,
    required String clientKind,
  }) => throw StateError('No connection is expected in a factory test.');
}

final class _UnusedLauncher implements EmbeddedDaemonLauncher {
  const _UnusedLauncher();

  @override
  Future<EmbeddedDaemonSession> start({
    required EmbeddedDaemonExposure exposure,
    required int port,
  }) => throw StateError('No daemon is expected in a factory test.');
}

final class _DaemonHandle implements DaemonHandle {
  int stops = 0;

  @override
  String get bearerToken => 'launcher-token-0123456789abcdef012345';

  @override
  Uri get boundEndpoint => Uri.parse('ws://127.0.0.1:4321/ws');

  @override
  Future<void> get ready async {}

  @override
  String get serverId => 'launcher-server';

  @override
  Future<void> stop() async {
    stops += 1;
  }
}
