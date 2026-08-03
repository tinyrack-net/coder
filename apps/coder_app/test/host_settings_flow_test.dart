import 'dart:async';

import 'package:coder_app/src/app.dart';
import 'package:coder_app/src/app_services.dart';
import 'package:coder_app/src/host_models.dart';
import 'package:coder_app/src/host_ports.dart';
import 'package:coder_client/coder_client.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_coder_api.dart';

void main() {
  testWidgets('restores the last selected host even while it is offline', (
    tester,
  ) async {
    final now = DateTime.utc(2026, 8, 3);
    final store = MemoryAppStore(
      settings: const AppSettings(
        embeddedDaemonEnabled: false,
        lastActiveHostId: 'offline',
      ),
      profiles: <RemoteDaemonProfile>[
        RemoteDaemonProfile(
          id: 'offline',
          label: 'Offline daemon',
          websocketUri: Uri.parse('wss://offline.example/ws'),
          autoConnect: false,
          createdAt: now,
          updatedAt: now,
        ),
      ],
      tokens: const <String, String>{'offline': 'token'},
    );
    await tester.pumpWidget(
      CoderApp(
        services: AppServices(
          settings: store,
          profiles: store,
          credentials: store,
          clients: const _OfflineClients(),
          clientKind: 'mobile',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Offline daemon'), findsWidgets);
    expect(find.text('자동 연결 꺼짐'), findsOneWidget);
  });

  testWidgets('remote-only app renders and opens settings without a daemon', (
    tester,
  ) async {
    final store = MemoryAppStore(
      settings: const AppSettings(embeddedDaemonEnabled: false),
    );
    await tester.pumpWidget(
      CoderApp(
        services: AppServices(
          settings: store,
          profiles: store,
          credentials: store,
          clients: const _OfflineClients(),
          clientKind: 'mobile',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('설정된 daemon이 없습니다.'), findsOneWidget);
    await tester.tap(find.byTooltip('설정'));
    await tester.pumpAndSettle();
    expect(find.text('설정'), findsOneWidget);
    expect(find.text('내장 daemon'), findsNothing);
    expect(find.text('원격 daemon 추가'), findsOneWidget);
  });

  testWidgets(
    'remote profiles can be saved offline, edited, and deleted',
    (
      tester,
    ) async {
      final store = MemoryAppStore(
        settings: const AppSettings(embeddedDaemonEnabled: false),
      );
      await tester.pumpWidget(
        CoderApp(
          services: AppServices(
            settings: store,
            profiles: store,
            credentials: store,
            clients: const _OfflineClients(),
            clientKind: 'mobile',
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('설정'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, '원격 daemon 추가'));
      await tester.pumpAndSettle();

      await tester.enterText(_field('이름'), 'Production');
      await tester.enterText(
        _field('WebSocket 주소'),
        'ws://daemon.example/ws',
      );
      await tester.enterText(_field('Bearer token'), 'secret-token');
      await tester.pump();
      expect(
        tester.widget<TextField>(_field('WebSocket 주소')).controller?.text,
        'ws://daemon.example/ws',
      );
      expect(
        find.textContaining('암호화되지 않습니다'),
        findsOneWidget,
        reason: tester
            .widgetList<Text>(find.byType(Text))
            .map((widget) => widget.data)
            .whereType<String>()
            .join(' | '),
      );
      await tester.tap(find.byType(Switch));
      await tester.tap(find.widgetWithText(FilledButton, '저장'));
      await tester.pumpAndSettle();

      expect(store.profiles.single.label, 'Production');
      expect(store.profiles.single.autoConnect, isFalse);
      expect(store.tokens[store.profiles.single.id], 'secret-token');
      await tester.tap(find.byTooltip('연결 편집'));
      await tester.pumpAndSettle();
      await tester.enterText(_field('이름'), 'Renamed');
      await tester.tap(find.widgetWithText(FilledButton, '저장'));
      await tester.pumpAndSettle();
      expect(store.profiles.single.label, 'Renamed');

      await tester.tap(find.byTooltip('연결 편집'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, '삭제'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, '삭제'));
      await tester.pumpAndSettle();
      expect(store.profiles, isEmpty);
      expect(store.tokens, isEmpty);
      expect(find.text('설정된 daemon이 없습니다.'), findsOneWidget);
    },
    tags: const <String>['feature_test__daemon_management__widget'],
  );

  testWidgets('desktop settings toggles the embedded daemon independently', (
    tester,
  ) async {
    final store = MemoryAppStore();
    final launcher = _FailingLauncher();
    await tester.pumpWidget(
      CoderApp(
        services: AppServices(
          settings: store,
          profiles: store,
          credentials: store,
          clients: const _OfflineClients(),
          clientKind: 'desktop',
          embeddedLauncher: launcher,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('설정'));
    await tester.pumpAndSettle();

    expect(find.text('내장 daemon'), findsOneWidget);
    final toggle = tester.widget<Switch>(find.byType(Switch));
    expect(toggle.value, isTrue);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(store.settings.embeddedDaemonEnabled, isTrue);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.tap(find.text('중지'));
    await tester.pumpAndSettle();
    expect(store.settings.embeddedDaemonEnabled, isFalse);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(store.settings.embeddedDaemonEnabled, isTrue);
  });

  testWidgets('host home and settings render independent runtime statuses', (
    tester,
  ) async {
    final now = DateTime.utc(2026, 8, 3);
    RemoteDaemonProfile profile(String id, {bool autoConnect = true}) =>
        RemoteDaemonProfile(
          id: id,
          label: '$id daemon',
          websocketUri: Uri.parse('wss://$id.test/ws'),
          autoConnect: autoConnect,
          createdAt: now,
          updatedAt: now,
        );
    final onlineApi = FakeCoderApi(
      serverInfo: _serverInfo('shared-server'),
    );
    final duplicateApi = FakeCoderApi(
      serverInfo: _serverInfo('shared-server'),
    );
    final pending = Completer<CoderApi>();
    final store = MemoryAppStore(
      settings: const AppSettings(embeddedDaemonEnabled: false),
      profiles: <RemoteDaemonProfile>[
        profile('online'),
        profile('duplicate'),
        profile('error'),
        profile('pending'),
        profile('idle', autoConnect: false),
      ],
      tokens: const <String, String>{
        'online': 'token',
        'duplicate': 'token',
        'error': 'token',
        'pending': 'token',
        'idle': 'token',
      },
    );
    await tester.pumpWidget(
      CoderApp(
        services: AppServices(
          settings: store,
          profiles: store,
          credentials: store,
          clients: _ProfileClients(<String, Future<CoderApi> Function()>{
            'online.test': () async => onlineApi,
            'duplicate.test': () async => duplicateApi,
            'error.test': () => Future<CoderApi>.error(
              const HostConnectionFailure.authentication('bad token'),
            ),
            'pending.test': () => pending.future,
          }),
          clientKind: 'test',
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('온라인'), findsOneWidget);
    expect(find.textContaining('중복 daemon'), findsOneWidget);
    expect(find.textContaining('오류'), findsOneWidget);
    expect(find.textContaining('연결 중'), findsOneWidget);
    expect(find.textContaining('자동 연결 꺼짐'), findsOneWidget);

    onlineApi.emitState(ClientConnectionState.reconnecting);
    await tester.pump();
    expect(find.textContaining('재연결 중'), findsOneWidget);
    await tester.tap(find.byTooltip('설정'));
    await tester.pumpAndSettle();
    expect(find.textContaining('재연결 중'), findsOneWidget);
    expect(find.textContaining('bad token'), findsOneWidget);
    await tester.drag(find.byType(ListView).last, const Offset(0, -1000));
    await tester.pumpAndSettle();
    expect(find.textContaining('자동 연결 꺼짐'), findsWidgets);

    pending.complete(
      FakeCoderApi(serverInfo: _serverInfo('pending-server')),
    );
  });
}

ServerInfoDto _serverInfo(String id) => ServerInfoDto(
  serverId: id,
  version: 'test',
  protocolVersion: coderProtocolVersion,
  features: const <String, bool>{},
);

final class _OfflineClients implements HostClientFactory {
  const _OfflineClients();

  @override
  Future<CoderApi> connect({
    required HostEndpoint endpoint,
    required DaemonCredentials credentials,
    required String clientId,
    required String clientKind,
  }) => Future<CoderApi>.error(
    const HostConnectionFailure.network('offline'),
  );
}

final class _FailingLauncher implements EmbeddedDaemonLauncher {
  @override
  Future<EmbeddedDaemonSession> start() => Future<EmbeddedDaemonSession>.error(
    const HostConnectionFailure.network('not running'),
  );
}

final class _ProfileClients implements HostClientFactory {
  const _ProfileClients(this.connections);

  final Map<String, Future<CoderApi> Function()> connections;

  @override
  Future<CoderApi> connect({
    required HostEndpoint endpoint,
    required DaemonCredentials credentials,
    required String clientId,
    required String clientKind,
  }) => connections[endpoint.websocketUri.host]!();
}

Finder _field(String label) => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.labelText == label,
);
