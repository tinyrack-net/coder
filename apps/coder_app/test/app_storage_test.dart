import 'dart:convert';

import 'package:coder_app/src/app_storage.dart';
import 'package:coder_app/src/host_models.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  test(
    'persists typed settings and profiles without bearer tokens',
    () async {
      final preferences = await SharedPreferences.getInstance();
      final store = SharedPreferencesAppStore(preferences);
      const secureStorage = FlutterSecureStorage();
      const credentials = SecureRemoteHostCredentialStore(secureStorage);
      final now = DateTime.utc(2026, 8, 3);
      final profile = RemoteDaemonProfile(
        id: 'host-id',
        label: 'Production',
        websocketUri: Uri.parse('wss://coder.example.com/ws'),
        autoConnect: true,
        serverId: 'server-id',
        createdAt: now,
        updatedAt: now,
        lastConnectedAt: now,
      );

      const selection = WorkspaceSelection(
        hostId: 'host-id',
        workspaceId: 'workspace-id',
        worktreeId: 'worktree-id',
      );
      await store.saveSettings(
        AppSettings(
          embeddedDaemonEnabled: false,
          embeddedDaemonExposure: EmbeddedDaemonExposure.allInterfaces,
          lastActiveHostId: 'host-id',
          lastWorktree: selection,
          sessionTabs: <String, SessionTabPreference>{
            selection.storageKey: const SessionTabPreference(
              openAgentIds: <String>['agent-1', 'agent-2'],
              selectedAgentId: 'agent-2',
            ),
          },
          sidebarCollapsed: true,
          localeTag: 'en',
        ),
      );
      await store.upsertProfile(profile);
      await credentials.writeBearerToken('host-id', 'bearer-secret');

      final restored = await store.loadSettings();
      expect(
        restored.embeddedDaemonExposure,
        EmbeddedDaemonExposure.allInterfaces,
      );
      expect(restored.lastWorktree, selection);
      expect(restored.sidebarCollapsed, isTrue);
      expect(restored.localeTag, 'en');
      expect(
        restored.sessionTabs[selection.storageKey]?.openAgentIds,
        <String>['agent-1', 'agent-2'],
      );
      expect(
        (await store.listProfiles()).single.websocketUri,
        profile.websocketUri,
      );
      expect(await credentials.readBearerToken('host-id'), 'bearer-secret');
      final document = preferences.getString(
        SharedPreferencesAppStore.documentKey,
      );
      expect(document, isNot(contains('bearer-secret')));
    },
    tags: const <String>['feature_test__daemon_exposure__contract'],
  );

  test('fresh storage ignores legacy singleton host keys', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'tinyrack_coder.host_address': 'ws://legacy.test/ws',
      'tinyrack_coder.host_token': 'legacy-token',
    });
    final store = SharedPreferencesAppStore(
      await SharedPreferences.getInstance(),
    );

    expect(await store.listProfiles(), isEmpty);
    expect((await store.loadSettings()).embeddedDaemonEnabled, isTrue);
    expect(
      (await store.loadSettings()).embeddedDaemonExposure,
      EmbeddedDaemonExposure.loopback,
    );
  });

  test('updates and removes profiles and their secure credentials', () async {
    final preferences = await SharedPreferences.getInstance();
    final store = SharedPreferencesAppStore(preferences);
    const credentials = SecureRemoteHostCredentialStore(
      FlutterSecureStorage(),
    );
    final createdAt = DateTime.utc(2026, 8, 3);
    final original = RemoteDaemonProfile(
      id: 'host-id',
      label: 'Original',
      websocketUri: Uri.parse('ws://127.0.0.1:7337/ws'),
      autoConnect: true,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
    final updated = RemoteDaemonProfile(
      id: original.id,
      label: 'Updated',
      websocketUri: original.websocketUri,
      autoConnect: false,
      createdAt: original.createdAt,
      updatedAt: createdAt.add(const Duration(minutes: 1)),
    );

    await store.upsertProfile(original);
    await store.upsertProfile(updated);
    await credentials.writeBearerToken(original.id, 'secret');

    expect((await store.listProfiles()).single.label, 'Updated');

    await store.deleteProfile(original.id);
    await credentials.deleteBearerToken(original.id);

    expect(await store.listProfiles(), isEmpty);
    expect(await credentials.readBearerToken(original.id), isNull);
  });

  test(
    'documents written before the language setting load as the system default',
    () async {
      // The key is simply absent in v3 documents written by earlier builds,
      // which must keep loading rather than resetting every stored setting.
      SharedPreferences.setMockInitialValues(<String, Object>{
        SharedPreferencesAppStore.documentKey: jsonEncode(<String, Object?>{
          'version': 3,
          'settings': <String, Object?>{
            'embeddedDaemonEnabled': true,
            'embeddedDaemonExposure': 'allInterfaces',
            'lastActiveHostId': 'host-id',
            'lastWorktree': null,
            'sessionTabs': <Object>[],
            'sidebarCollapsed': true,
          },
          'profiles': <Object>[],
        }),
      });
      final store = SharedPreferencesAppStore(
        await SharedPreferences.getInstance(),
      );

      final restored = await store.loadSettings();
      expect(restored.localeTag, isNull);
      expect(restored.lastActiveHostId, 'host-id');
      expect(restored.sidebarCollapsed, isTrue);
    },
    tags: const <String>['feature_test__settings_language__unit'],
  );

  test('rejects incompatible and malformed settings documents', () async {
    final preferences = await SharedPreferences.getInstance();
    final store = SharedPreferencesAppStore(preferences);
    final invalidDocuments = <Object>[
      <Object>[],
      <String, Object?>{
        'version': 3,
        'settings': <String, Object?>{
          'embeddedDaemonEnabled': true,
          'embeddedDaemonExposure': 'invalid',
          'lastActiveHostId': null,
          'lastWorktree': null,
          'sessionTabs': <Object>[],
        },
        'profiles': <Object>[],
      },
      <String, Object?>{
        'version': 3,
        'settings': <String, Object?>{},
        'profiles': <Object>[],
      },
      <String, Object?>{
        'version': 3,
        'settings': <String, Object?>{
          'embeddedDaemonEnabled': true,
          'embeddedDaemonExposure': 'loopback',
          'lastActiveHostId': null,
          'lastWorktree': null,
          'localeTag': 7,
          'sessionTabs': <Object>[],
          'sidebarCollapsed': false,
        },
        'profiles': <Object>[],
      },
      <String, Object?>{
        'version': 1,
        'settings': 'invalid',
        'profiles': <Object>[],
      },
      <String, Object?>{
        'version': 1,
        'settings': <String, Object?>{
          'embeddedDaemonEnabled': true,
          'lastActiveHostId': null,
        },
        'profiles': <Object>['invalid'],
      },
      <String, Object?>{
        'version': 1,
        'settings': <String, Object?>{
          'embeddedDaemonEnabled': 'invalid',
          'lastActiveHostId': null,
        },
        'profiles': <Object>[],
      },
      <String, Object?>{
        'version': 1,
        'settings': <String, Object?>{
          'embeddedDaemonEnabled': true,
          'lastActiveHostId': null,
        },
        'profiles': <Object>[
          <String, Object?>{
            'id': 7,
            'label': 'Invalid',
            'websocketUri': 'wss://coder.example.com/ws',
            'autoConnect': true,
            'serverId': null,
            'createdAt': '2026-08-03T00:00:00.000Z',
            'updatedAt': '2026-08-03T00:00:00.000Z',
            'lastConnectedAt': null,
          },
        ],
      },
    ];

    for (final document in invalidDocuments) {
      await preferences.setString(
        SharedPreferencesAppStore.documentKey,
        jsonEncode(document),
      );
      await expectLater(store.loadSettings(), throwsFormatException);
    }
  });
}
