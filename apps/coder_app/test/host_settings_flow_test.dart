import 'dart:async';

import 'package:coder_app/src/app.dart';
import 'package:coder_app/src/app_services.dart';
import 'package:coder_app/src/coder_selection_row.dart';
import 'package:coder_app/src/host_models.dart';
import 'package:coder_app/src/host_ports.dart';
import 'package:coder_client/coder_client.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

import 'support/fake_coder_api.dart';
import 'support/localization.dart';

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

    // The sidebar lists workspaces, not daemons, so an unreachable daemon
    // surfaces as an empty state instead of a status row.
    expect(find.text('연결된 daemon이 없습니다.'), findsOneWidget);
    await tester.tap(find.text('Daemon 설정'));
    await tester.pumpAndSettle();
    expect(find.text('Offline daemon'), findsWidgets);
    expect(find.textContaining('자동 연결 꺼짐'), findsWidgets);

    // A daemon-scoped category explains the missing connection rather than
    // failing to build its page.
    await tester.tap(find.text('Agent'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('settings-daemon-offline')),
      findsOneWidget,
    );
    expect(
      find.text('Offline daemon이(가) 연결되어 있지 않습니다.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'remote-only app renders and opens settings without a daemon',
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

      expect(find.text('설정된 daemon이 없습니다.'), findsOneWidget);
      await tester.tap(findAccessibleAction('설정'));
      await tester.pumpAndSettle();
      expect(find.text('설정'), findsOneWidget);
      expect(find.text('내장 daemon'), findsNothing);
      expect(find.text('네트워크 접근 허용'), findsNothing);
      expect(find.text('원격 daemon 추가'), findsOneWidget);
    },
    tags: const <String>['feature_test__daemon_exposure__widget'],
  );

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
      await tester.tap(findAccessibleAction('설정'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TRButton, '원격 daemon 추가'));
      await tester.pumpAndSettle();

      await tester.enterText(_field('이름'), 'Production');
      await tester.enterText(
        _field('WebSocket 주소'),
        'ws://daemon.example/ws',
      );
      await tester.enterText(_field('Bearer token'), 'secret-token');
      await tester.pump();
      expect(
        tester.widget<EditableText>(_field('WebSocket 주소')).controller.text,
        'ws://daemon.example/ws',
      );
      expect(find.textContaining('암호화되지 않습니다'), findsNothing);
      await tester.tap(find.byType(TRSwitch));
      await tester.tap(find.widgetWithText(TRButton, '저장'));
      await tester.pumpAndSettle();

      expect(store.profiles.single.label, 'Production');
      expect(store.profiles.single.autoConnect, isFalse);
      expect(store.tokens[store.profiles.single.id], 'secret-token');
      await tester.tap(findAccessibleAction('연결 편집'));
      await tester.pumpAndSettle();
      await tester.enterText(_field('이름'), 'Renamed');
      await tester.tap(find.widgetWithText(TRButton, '저장'));
      await tester.pumpAndSettle();
      expect(store.profiles.single.label, 'Renamed');

      await tester.tap(findAccessibleAction('연결 편집'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TRButton, '삭제').last);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TRButton, '삭제').last);
      await tester.pumpAndSettle();
      expect(store.profiles, isEmpty);
      expect(store.tokens, isEmpty);
      expect(find.text('설정된 daemon이 없습니다.'), findsOneWidget);
    },
    tags: const <String>['feature_test__daemon_management__widget'],
  );

  testWidgets(
    'desktop settings toggles the embedded daemon independently',
    (tester) async {
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
      await tester.tap(findAccessibleAction('설정'));
      await tester.pumpAndSettle();

      // The sidebar daemon picker names it too, so this is not unique.
      expect(find.text('내장 daemon'), findsWidgets);
      expect(find.text('네트워크 접근 허용'), findsOneWidget);
      expect(find.textContaining('not running'), findsOneWidget);
      final embeddedToggle = find.widgetWithText(
        CoderSwitchRow,
        '내장 daemon',
      );
      final exposureToggle = find.widgetWithText(
        CoderSwitchRow,
        '네트워크 접근 허용',
      );
      final toggle = tester.widget<CoderSwitchRow>(embeddedToggle);
      expect(toggle.value, isTrue);
      expect(tester.widget<CoderSwitchRow>(exposureToggle).value, isFalse);

      await tester.enterText(_embeddedPortField(), '70000');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.text('1~65535 사이의 정수를 입력하세요.'), findsOneWidget);
      expect(
        tester
            .widget<TRButton>(
              find.byKey(
                const ValueKey<String>('embedded-daemon-port-apply'),
              ),
            )
            .onPressed,
        isNull,
      );

      await tester.enterText(_embeddedPortField(), '8123');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('embedded-daemon-port-apply')),
      );
      await tester.pumpAndSettle();
      expect(store.settings.embeddedDaemonPort, 8123);
      expect(launcher.ports.last, 8123);

      await tester.tap(exposureToggle);
      await tester.pumpAndSettle();
      expect(
        store.settings.embeddedDaemonExposure,
        EmbeddedDaemonExposure.allInterfaces,
      );

      await tester.tap(embeddedToggle);
      await tester.pumpAndSettle();
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();
      expect(store.settings.embeddedDaemonEnabled, isTrue);
      await tester.tap(embeddedToggle);
      await tester.pumpAndSettle();
      await tester.tap(find.text('중지'));
      await tester.pumpAndSettle();
      expect(store.settings.embeddedDaemonEnabled, isFalse);
      await tester.tap(embeddedToggle);
      await tester.pumpAndSettle();
      expect(store.settings.embeddedDaemonEnabled, isTrue);
    },
    tags: const <String>['feature_test__daemon_exposure__widget'],
  );

  testWidgets(
    'an embedded port conflict shows guidance and can be retried',
    (tester) async {
      final store = MemoryAppStore();
      final launcher = _FailingLauncher(
        failure: const HostConnectionFailure.network(
          'socket bind failed',
          reason: HostFailureReason.embeddedPortInUse,
        ),
      );
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
      await tester.tap(findAccessibleAction('설정'));
      await tester.pumpAndSettle();

      expect(find.text('내장 daemon을 시작할 수 없습니다'), findsOneWidget);
      expect(find.textContaining('포트 7337'), findsOneWidget);
      expect(find.textContaining('다른 포트를 입력'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('embedded-daemon-error')),
        findsOneWidget,
      );

      await tester.tap(find.widgetWithText(TRButton, '다시 시도'));
      await tester.pumpAndSettle();
      expect(launcher.starts, 2);
    },
    tags: const <String>['feature_test__daemon_exposure__widget'],
  );

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

    onlineApi.emitState(ClientConnectionState.reconnecting);
    await tester.pump();
    // Runtime status lives in daemon settings; the sidebar shows workspaces.
    await tester.tap(findAccessibleAction('설정'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('같은 daemon이 이미 등록되어 있습니다.'),
      findsOneWidget,
    );
    // A failed daemon reports its own message in place of the generic status.
    expect(find.textContaining('연결 중'), findsOneWidget);
    expect(find.textContaining('재연결 중'), findsOneWidget);
    expect(find.textContaining('bad token'), findsOneWidget);
    // The idle daemon sits below the fold of the settings list.
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
  _FailingLauncher({
    this.failure = const HostConnectionFailure.network('not running'),
  });

  final HostConnectionFailure failure;
  final List<int> ports = <int>[];
  int starts = 0;

  @override
  Future<EmbeddedDaemonSession> start({
    required EmbeddedDaemonExposure exposure,
    required int port,
  }) {
    starts += 1;
    ports.add(port);
    return Future<EmbeddedDaemonSession>.error(failure);
  }
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

Finder _field(String label) => find.descendant(
  of: find.byWidgetPredicate(
    (widget) => widget is TRTextField && widget.label == label,
  ),
  matching: find.byType(EditableText),
);

Finder _embeddedPortField() => find.descendant(
  of: find.byKey(const ValueKey<String>('embedded-daemon-port')),
  matching: find.byType(EditableText),
);
