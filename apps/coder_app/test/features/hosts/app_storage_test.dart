import 'dart:convert';

import 'package:coder_app/src/features/hosts/domain/host_models.dart';
import 'package:coder_app/src/features/hosts/infrastructure/app_storage.dart';
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
          embeddedDaemonPort: 8123,
          lastActiveHostId: 'host-id',
          lastWorktree: selection,
          sessionTabs: <String, SessionTabPreference>{
            selection.storageKey: const SessionTabPreference(
              tabs: <WorkspaceTabPreference>[
                WorkspaceTabPreference(
                  id: 'session:agent-1',
                  kind: WorkspaceTabTargetKind.session,
                  targetId: 'agent-1',
                ),
                WorkspaceTabPreference(
                  id: 'session:agent-2',
                  kind: WorkspaceTabTargetKind.session,
                  targetId: 'agent-2',
                ),
              ],
              root: WorkspacePanePreference(
                id: 'pane:one',
                tabIds: <String>['session:agent-1', 'session:agent-2'],
                activeTabId: 'session:agent-2',
              ),
              focusedPaneId: 'pane:one',
            ),
          },
          sidebarCollapsed: true,
          localeTag: 'en',
          startAtBoot: false,
          startMinimizedAtBoot: false,
          themeMode: AppThemeMode.dark,
        ),
      );
      await store.upsertProfile(profile);
      await credentials.writeBearerToken('host-id', 'bearer-secret');

      final restored = await store.loadSettings();
      expect(
        restored.embeddedDaemonExposure,
        EmbeddedDaemonExposure.allInterfaces,
      );
      expect(restored.embeddedDaemonPort, 8123);
      expect(restored.lastWorktree, selection);
      expect(restored.sidebarCollapsed, isTrue);
      expect(restored.localeTag, 'en');
      expect(restored.startAtBoot, isFalse);
      expect(restored.startMinimizedAtBoot, isFalse);
      expect(restored.themeMode, AppThemeMode.dark);
      expect(
        restored.sessionTabs[selection.storageKey]?.tabs.map((tab) => tab.id),
        <String>['session:agent-1', 'session:agent-2'],
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

  test(
    'clearing drops the document after every queued write settles',
    () async {
      final preferences = await SharedPreferences.getInstance();
      final store = SharedPreferencesAppStore(preferences);
      final now = DateTime.utc(2026, 8, 3);

      await store.saveSettings(const AppSettings(embeddedDaemonPort: 8123));
      // Queued behind the clear, so it must not resurrect the document.
      final queued = store.upsertProfile(
        RemoteDaemonProfile(
          id: 'host-id',
          label: 'Production',
          websocketUri: Uri.parse('wss://coder.example.com/ws'),
          autoConnect: true,
          createdAt: now,
          updatedAt: now,
        ),
      );
      final cleared = store.clear();
      await queued;
      await cleared;

      expect(
        preferences.getString(SharedPreferencesAppStore.documentKey),
        isNull,
      );
      expect(await store.listProfiles(), isEmpty);
      expect((await store.loadSettings()).embeddedDaemonPort, 7337);
    },
    tags: const <String>['feature_test__settings_reset__unit'],
  );

  test(
    'clearing bearer tokens removes only remote host entries',
    () async {
      FlutterSecureStorage.setMockInitialValues(<String, String>{
        'unrelated.plugin.key': 'keep-me',
      });
      const credentials = SecureRemoteHostCredentialStore(
        FlutterSecureStorage(),
      );
      await credentials.writeBearerToken('first', 'one');
      await credentials.writeBearerToken('second', 'two');

      await credentials.deleteAllBearerTokens();

      expect(await credentials.readBearerToken('first'), isNull);
      expect(await credentials.readBearerToken('second'), isNull);
      expect(
        await const FlutterSecureStorage().read(key: 'unrelated.plugin.key'),
        'keep-me',
      );
    },
    tags: const <String>['feature_test__settings_reset__unit'],
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
    expect((await store.loadSettings()).embeddedDaemonPort, 7337);
  });

  test(
    'flat development tab entries reset without dropping other settings',
    () async {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        SharedPreferencesAppStore.documentKey,
        jsonEncode(<String, dynamic>{
          'version': 3,
          'settings': <String, dynamic>{
            'embeddedDaemonEnabled': false,
            'lastActiveHostId': 'server',
            'sessionTabs': <Object>[
              <String, dynamic>{
                'key': 'server\u0000workspace\u0000worktree',
                'openAgentIds': <String>['agent'],
                'selectedAgentId': 'agent',
              },
            ],
            'sidebarCollapsed': true,
          },
          'profiles': <Object>[],
        }),
      );

      final restored = await SharedPreferencesAppStore(
        preferences,
      ).loadSettings();
      expect(restored.lastActiveHostId, 'server');
      expect(restored.sidebarCollapsed, isTrue);
      expect(restored.sessionTabs, isEmpty);
    },
  );

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
    'documents written before the language and startup settings load '
    'with their defaults',
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
      // Startup registration is opt-out, so an upgraded install keeps the
      // same enabled defaults a fresh install gets.
      expect(restored.startAtBoot, isTrue);
      expect(restored.startMinimizedAtBoot, isTrue);
      expect(restored.embeddedDaemonPort, defaultEmbeddedDaemonPort);
      // No stored appearance means the platform still decides the brightness.
      expect(restored.themeMode, AppThemeMode.system);
    },
    tags: const <String>[
      'feature_test__settings_appearance__unit',
      'feature_test__settings_language__unit',
      'feature_test__settings_startup__unit',
    ],
  );

  test(
    'every appearance choice is written by name and read back',
    () async {
      final preferences = await SharedPreferences.getInstance();
      final store = SharedPreferencesAppStore(preferences);

      for (final mode in AppThemeMode.values) {
        await store.saveSettings(AppSettings(themeMode: mode));
        expect(
          preferences.getString(SharedPreferencesAppStore.documentKey),
          contains('"themeMode":"${mode.name}"'),
        );
        expect((await store.loadSettings()).themeMode, mode);
      }
    },
    tags: const <String>['feature_test__settings_appearance__unit'],
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
          'embeddedDaemonPort': 0,
          'lastActiveHostId': null,
          'lastWorktree': null,
          'sessionTabs': <Object>[],
          'sidebarCollapsed': false,
        },
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
        'version': 3,
        'settings': <String, Object?>{
          'embeddedDaemonEnabled': true,
          'embeddedDaemonExposure': 'loopback',
          'lastActiveHostId': null,
          'lastWorktree': null,
          'sessionTabs': <Object>[],
          'sidebarCollapsed': false,
          'startAtBoot': 7,
        },
        'profiles': <Object>[],
      },
      <String, Object?>{
        'version': 3,
        'settings': <String, Object?>{
          'embeddedDaemonEnabled': true,
          'embeddedDaemonExposure': 'loopback',
          'lastActiveHostId': null,
          'lastWorktree': null,
          'sessionTabs': <Object>[],
          'sidebarCollapsed': false,
          'startMinimizedAtBoot': 'yes',
        },
        'profiles': <Object>[],
      },
      <String, Object?>{
        'version': 3,
        'settings': <String, Object?>{
          'embeddedDaemonEnabled': true,
          'embeddedDaemonExposure': 'loopback',
          'lastActiveHostId': null,
          'lastWorktree': null,
          'sessionTabs': <Object>[],
          'sidebarCollapsed': false,
          'themeMode': 7,
        },
        'profiles': <Object>[],
      },
      <String, Object?>{
        'version': 3,
        'settings': <String, Object?>{
          'embeddedDaemonEnabled': true,
          'embeddedDaemonExposure': 'loopback',
          'lastActiveHostId': null,
          'lastWorktree': null,
          'sessionTabs': <Object>[],
          'sidebarCollapsed': false,
          'themeMode': 'sepia',
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
