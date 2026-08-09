import 'package:app/src/app/coder_app.dart';
import 'package:app/src/app/composition/app_services.dart';
import 'package:app/src/features/desktop/infrastructure/desktop_shell.dart';
import 'package:app/src/features/hosts/domain/host_models.dart';
import 'package:app/src/features/hosts/domain/host_ports.dart';
import 'package:app/src/shared/presentation/coder_icons.dart';
import 'package:client/client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_desktop_ports.dart';

void main() {
  final now = DateTime.utc(2026, 8, 5);

  Future<void> openAdvanced(WidgetTester tester) async {
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(CoderIcons.settings));
    await tester.pumpAndSettle();
    await tester.tap(find.text('고급'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'cancelling the confirmation keeps every stored value',
    (tester) async {
      final store = _store(now);
      final eraser = _Eraser();
      await tester.pumpWidget(_app(store, eraser: eraser));
      await openAdvanced(tester);

      await tester.tap(_resetButton);
      await tester.pumpAndSettle();
      expect(_confirmDialog, findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey<String>('advanced-reset-confirm-cancel')),
      );
      await tester.pumpAndSettle();

      expect(eraser.erases, 0);
      expect(store.profiles, hasLength(1));
      expect(store.tokens, hasLength(1));
    },
    tags: const <String>['feature_test__settings_reset__widget'],
  );

  testWidgets(
    'confirming erases stored data, restores the login item, and leaves '
    'settings',
    (tester) async {
      final store = _store(now);
      final eraser = _Eraser();
      final autostart = FakeAutostartRegistration();
      await tester.pumpWidget(
        _app(store, eraser: eraser, autostart: autostart),
      );
      await openAdvanced(tester);

      await tester.tap(_resetButton);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('advanced-reset-confirm-accept')),
      );
      await tester.pumpAndSettle();

      expect(eraser.erases, 1);
      expect(store.profiles, isEmpty);
      expect(store.tokens, isEmpty);
      expect(autostart.applications.last, (enabled: true, minimized: true));
      // The reset navigates home rather than leaving a settings pane bound to
      // hosts and workspaces that no longer exist.
      expect(_resetButton, findsNothing);
    },
    tags: const <String>['feature_test__settings_reset__widget'],
  );

  testWidgets(
    'a locked data directory is reported inline and keeps the page open',
    (tester) async {
      final store = _store(now);
      final eraser = _Eraser(
        failure: const FactoryResetFailure(
          'locked',
          reason: FactoryResetFailureReason.daemonStillRunning,
        ),
      );
      await tester.pumpWidget(_app(store, eraser: eraser));
      await openAdvanced(tester);

      await tester.tap(_resetButton);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('advanced-reset-confirm-accept')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('advanced-settings-reset-error')),
        findsOneWidget,
      );
      expect(_resetButton, findsOneWidget);
      expect(store.profiles, hasLength(1));
      expect(store.tokens, hasLength(1));
    },
    tags: const <String>['feature_test__settings_reset__widget'],
  );

  testWidgets(
    'a surface without an embedded daemon describes the narrower scope',
    (tester) async {
      final store = _store(now);
      await tester.pumpWidget(_app(store));
      await openAdvanced(tester);

      expect(find.textContaining('임베디드 daemon의 데이터베이스'), findsNothing);
      expect(find.textContaining('이 기기의 모든 앱 설정'), findsOneWidget);
    },
    tags: const <String>['feature_test__settings_reset__widget'],
  );
}

final Finder _resetButton = find.byKey(
  const ValueKey<String>('advanced-settings-reset-button'),
);

final Finder _confirmDialog = find.byKey(
  const ValueKey<String>('advanced-reset-confirm-dialog'),
);

MemoryAppStore _store(DateTime now) => MemoryAppStore(
  settings: const AppSettings(
    embeddedDaemonEnabled: false,
    embeddedDaemonPort: 9100,
  ),
  profiles: <RemoteDaemonProfile>[
    RemoteDaemonProfile(
      id: 'remote',
      label: 'Remote',
      websocketUri: Uri.parse('ws://remote.test/ws'),
      autoConnect: false,
      createdAt: now,
      updatedAt: now,
    ),
  ],
  tokens: const <String, String>{'remote': 'token'},
);

Widget _app(
  MemoryAppStore store, {
  EmbeddedDaemonDataEraser? eraser,
  AutostartRegistration? autostart,
}) => CoderApp(
  services: AppServices(
    settings: store,
    profiles: store,
    credentials: store,
    clients: const _OfflineClients(),
    clientKind: 'test',
    embeddedDataEraser: eraser,
  ),
  autostart: autostart,
);

final class _Eraser implements EmbeddedDaemonDataEraser {
  _Eraser({this.failure});

  final FactoryResetFailure? failure;
  int erases = 0;

  @override
  Future<void> eraseAll() async {
    erases += 1;
    final error = failure;
    if (error != null) throw error;
  }
}

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
