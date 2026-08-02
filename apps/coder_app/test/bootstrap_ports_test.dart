import 'package:coder_app/src/bootstrap.dart';
import 'package:coder_app/src/desktop_bootstrap.dart';
import 'package:coder_app/src/ports.dart';
import 'package:coder_app/src/remote_bootstrap.dart';
import 'package:coder_client/coder_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_coder_api.dart';

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues(<String, String>{}));

  test(
    'remote bootstrap is remote-only and persists explicit connections',
    () async {
      final api = FakeCoderApi();
      final connector = _Connector(api);
      final bootstrap = RemoteBootstrap(
        ids: const _Ids(),
        connector: connector,
      );
      addTearDown(bootstrap.close);
      addTearDown(api.close);

      expect(bootstrap.canRegisterLocalWorkspace, isFalse);
      expect(await bootstrap.autoConnect(), isNull);
      final endpoint = HostEndpoint.parse(
        'ws://daemon.local:7337/ws',
        token: 'remote-token',
      );
      final connected = await bootstrap.connectRemote(endpoint);
      expect(connected.client, same(api));
      expect(connected.endpoint, endpoint);
      expect(connector.clientKind, 'mobile');
      expect(connector.clientId, 'fixed-id');

      final restored = await RemoteBootstrap(
        ids: const _Ids(),
        connector: connector,
      ).autoConnect();
      expect(restored!.endpoint.websocketUri, endpoint.websocketUri);
      expect(restored.endpoint.token, endpoint.token);
    },
  );

  test('desktop reuses a saved daemon without launching an isolate', () async {
    FlutterSecureStorage.setMockInitialValues(<String, String>{
      'tinyrack_coder.host_address': 'ws://127.0.0.1:7444/ws',
      'tinyrack_coder.host_token': 'saved-token',
    });
    final api = FakeCoderApi();
    final connector = _Connector(api);
    final launcher = _Launcher();
    final bootstrap = DesktopBootstrap(
      ids: const _Ids(),
      connector: connector,
      launcher: launcher,
    );
    addTearDown(bootstrap.close);
    addTearDown(api.close);

    final connection = await bootstrap.autoConnect();
    expect(connection!.endpoint.websocketUri.port, 7444);
    expect(bootstrap.canRegisterLocalWorkspace, isTrue);
    expect(connector.clientKind, 'desktop');
    expect(launcher.starts, 0);
  });

  test(
    'desktop falls back to embedded and stops it for a remote host',
    () async {
      FlutterSecureStorage.setMockInitialValues(<String, String>{
        'tinyrack_coder.host_address': 'ws://stale.local/ws',
        'tinyrack_coder.host_token': 'stale-token',
      });
      final api = FakeCoderApi();
      final connector = _Connector(api, failures: 1);
      final launcher = _Launcher();
      final bootstrap = DesktopBootstrap(
        ids: const _Ids(),
        connector: connector,
        launcher: launcher,
      );
      addTearDown(bootstrap.close);
      addTearDown(api.close);

      final embedded = await bootstrap.autoConnect();
      expect(launcher.starts, 1);
      expect(embedded!.endpoint.websocketUri.port, 7338);
      expect(connector.calls, 2);
      final remote = HostEndpoint.parse(
        'ws://remote.local:9000/ws',
        token: 'remote-token',
      );
      expect((await bootstrap.connectRemote(remote)).endpoint, remote);
      expect(launcher.session.stops, 1);
      await bootstrap.close();
      expect(launcher.session.stops, 1);
    },
  );
}

final class _Ids implements AppIdGenerator {
  const _Ids();

  @override
  String generate() => 'fixed-id';
}

final class _Connector implements AppClientConnector {
  _Connector(this.api, {this.failures = 0});

  final FakeCoderApi api;
  final int failures;
  int calls = 0;
  String? clientId;
  String? clientKind;

  @override
  Future<CoderApi> connect({
    required HostEndpoint endpoint,
    required String clientId,
    required String clientKind,
  }) async {
    calls += 1;
    this.clientId = clientId;
    this.clientKind = clientKind;
    if (calls <= failures) throw const FormatException('stale daemon');
    return api;
  }
}

final class _Launcher implements EmbeddedDaemonLauncher {
  final _Session session = _Session();
  int starts = 0;

  @override
  Future<EmbeddedDaemonSession> start() async {
    starts += 1;
    return session;
  }
}

final class _Session implements EmbeddedDaemonSession {
  int stops = 0;

  @override
  String get bearerToken => 'embedded-token';

  @override
  Uri get boundEndpoint => Uri.parse('ws://127.0.0.1:7338/ws');

  @override
  Future<void> stop() async {
    stops += 1;
  }
}
