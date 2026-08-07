part of '../../app/app_flows_test.dart';

void _registerSettingsAppFlows() {
  final now = DateTime.utc(2026, 8, 3);
  testWidgets(
    'host-scoped settings keep the selected daemon across categories',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final first = FakeCoderApi(
        serverInfo: const ServerInfoDto(
          serverId: 'first-server',
          version: 'test',
          protocolVersion: coderProtocolMajor,
          features: <String, bool>{},
        ),
      );
      final second = FakeCoderApi(
        serverInfo: const ServerInfoDto(
          serverId: 'second-server',
          version: 'test',
          protocolVersion: coderProtocolMajor,
          features: <String, bool>{},
        ),
      );
      addTearDown(first.close);
      addTearDown(second.close);
      final store = MemoryAppStore(
        settings: const AppSettings(embeddedDaemonEnabled: false),
        profiles: <RemoteDaemonProfile>[
          RemoteDaemonProfile(
            id: 'first',
            label: 'First daemon',
            websocketUri: Uri.parse('ws://first.test/ws'),
            autoConnect: true,
            createdAt: now,
            updatedAt: now,
          ),
          RemoteDaemonProfile(
            id: 'second',
            label: 'Second daemon',
            websocketUri: Uri.parse('ws://second.test/ws'),
            autoConnect: true,
            createdAt: now,
            updatedAt: now,
          ),
        ],
        tokens: const <String, String>{
          'first': 'first-token',
          'second': 'second-token',
        },
      );
      await tester.pumpWidget(
        CoderApp(
          services: AppServices(
            settings: store,
            profiles: store,
            credentials: store,
            clients: _MappedClients(<String, CoderApi>{
              'first.test': first,
              'second.test': second,
            }),
            clientKind: 'settings-host-test',
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(CoderIcons.settings));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Agent'));
      await tester.pumpAndSettle();

      final daemonSelect = find.byKey(
        const ValueKey<String>('settings-daemon-select'),
      );
      await tester.tap(daemonSelect);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Second daemon').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('MCP'));
      await tester.pumpAndSettle();

      expect(tester.widget<TRSelect<String>>(daemonSelect).value, 'second');
      expect(store.settings.lastActiveHostId, 'second');

      // App-wide categories carry no daemon, so passing through one used to
      // drop the selection back to the first online daemon.
      await tester.tap(find.text('General'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Projects'));
      await tester.pumpAndSettle();
      expect(tester.widget<TRSelect<String>>(daemonSelect).value, 'second');

      // A daemon card's provider shortcut names its host in the location and
      // replaces the settings page rather than pushing another one, so the
      // page outlives the change and has to adopt each daemon a later location
      // names, not only the first.
      Future<void> openProviderShortcut(String address) async {
        await tester.tap(find.text('Daemons'));
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(
            of: find
                .ancestor(
                  of: find.textContaining(address),
                  matching: find.byType(TRCard),
                )
                .first,
            matching: find.widgetWithText(TRButton, 'Provider 설정'),
          ),
        );
        await tester.pumpAndSettle();
      }

      await openProviderShortcut('ws://first.test/ws');
      expect(tester.widget<TRSelect<String>>(daemonSelect).value, 'first');
      await openProviderShortcut('ws://second.test/ws');
      expect(tester.widget<TRSelect<String>>(daemonSelect).value, 'second');
    },
    tags: const <String>['feature_test__daemon_management__widget'],
  );

  testWidgets(
    'the settings sidebar daemon select is framed by the sidebar, not itself',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final api = FakeCoderApi(
        serverInfo: const ServerInfoDto(
          serverId: 'sidebar-server',
          version: 'test',
          protocolVersion: coderProtocolMajor,
          features: <String, bool>{},
        ),
      );
      addTearDown(api.close);
      final store = MemoryAppStore(
        settings: const AppSettings(embeddedDaemonEnabled: false),
        profiles: <RemoteDaemonProfile>[
          RemoteDaemonProfile(
            id: 'only',
            label: 'Only daemon',
            websocketUri: Uri.parse('ws://only.test/ws'),
            autoConnect: true,
            createdAt: now,
            updatedAt: now,
          ),
        ],
        tokens: const <String, String>{'only': 'only-token'},
      );
      await tester.pumpWidget(
        CoderApp(
          services: AppServices(
            settings: store,
            profiles: store,
            credentials: store,
            clients: _MappedClients(<String, CoderApi>{'only.test': api}),
            clientKind: 'sidebar-daemon-select-test',
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(CoderIcons.settings));
      await tester.pumpAndSettle();

      // The sidebar is a flat list of borderless nav rows, so a boxed select
      // trigger sitting among them reads as a foreign control.
      final daemonSelect = find.byKey(
        const ValueKey<String>('settings-daemon-select'),
      );
      expect(
        tester.widget<TRSelect<String>>(daemonSelect).appearance,
        TRFieldAppearance.ghost,
      );
    },
    tags: const <String>['feature_test__daemon_management__widget'],
  );

  testWidgets('settings combines Projects, Agent, Provider, and Daemon', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1100, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final api = FakeCoderApi();
    final router = await _pumpRoute(
      tester,
      api,
      const ProviderSettingsRoute(hostId: 'server').location,
    );
    addTearDown(router.dispose);
    expect(
      find.byKey(const ValueKey<String>('settings-sidebar-surface')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('settings-sidebar-tree-app')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('settings-sidebar-tree-daemon')),
      findsOneWidget,
    );
    expect(find.text('Projects'), findsOneWidget);
    expect(find.text('Agent'), findsOneWidget);
    expect(find.text('Provider'), findsOneWidget);
    expect(find.text('Daemons'), findsOneWidget);
    expect(find.text('Test daemon'), findsWidgets);
    await tester.tap(find.text('Projects'));
    await tester.pumpAndSettle();
    expect(
      router.routeInformationProvider.value.uri.toString(),
      const ProjectSettingsRoute().location,
    );
    await tester.tap(find.text('Daemons'));
    await tester.pumpAndSettle();
    expect(find.text('원격 daemons'), findsOneWidget);
  });

  testWidgets(
    'mobile settings drills from home into daemon MCP settings',
    (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final router = await _pumpRoute(
        tester,
        FakeCoderApi(),
        const SettingsHomeRoute().location,
      );
      addTearDown(router.dispose);

      expect(
        find.byKey(const ValueKey<String>('settings-category-select')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('settings-daemon-select')),
        findsNothing,
      );
      expect(find.text('General'), findsOneWidget);
      expect(find.text('Test daemon'), findsOneWidget);

      await tester.tap(find.text('Test daemon'));
      await tester.pumpAndSettle();
      expect(
        router.routeInformationProvider.value.uri.path,
        '/settings/daemons/server/categories',
      );
      expect(find.text('MCP'), findsOneWidget);

      await tester.tap(find.text('MCP'));
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/settings/mcp');
      expect(find.byKey(const ValueKey<String>('mcp-server-list')), findsOne);

      await tester.tap(
        find.byKey(const ValueKey<String>('mcp-server-add')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('mcp-server-editor-new')),
        findsOne,
      );
      expect(find.text('MCP 서버'), findsNothing);

      final back = find.byKey(
        const ValueKey<String>('settings-back-button'),
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey<String>('mcp-server-list')), findsOne);
      expect(find.byKey(const ValueKey<String>('mcp-field-id')), findsNothing);

      await tester.tap(back);
      await tester.pumpAndSettle();
      expect(find.text('MCP'), findsOneWidget);
      expect(
        router.routeInformationProvider.value.uri.path,
        '/settings/daemons/server/categories',
      );

      await tester.tap(back);
      await tester.pumpAndSettle();
      expect(find.text('General'), findsOneWidget);
      expect(router.routeInformationProvider.value.uri.path, '/settings');
    },
    tags: const <String>['feature_test__app_navigation__widget'],
  );
}
