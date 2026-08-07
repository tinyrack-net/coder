part of 'application_controllers_test.dart';

void _registerContractsControllerTests() {
  final now = DateTime.utc(2026, 8, 2);

  test(
    'feature state value objects and production ports are deterministic',
    () {
      final api = FakeCoderApi();
      final endpoint = HostEndpoint.parse('ws://localhost/ws');
      final snapshot = HostRuntimeSnapshot(
        id: 'host',
        label: 'Host',
        kind: HostKind.remote,
        status: HostRuntimeStatus.offline,
        api: api,
        endpoint: endpoint,
      );
      expect(snapshot.connected, isFalse);
      expect(
        snapshot.copyWith(status: HostRuntimeStatus.connecting).status,
        HostRuntimeStatus.connecting,
      );
      const conversation = ConversationState();
      expect(
        conversation.copyWith(timeline: <TimelineEventDto>[]).timeline,
        isEmpty,
      );
      final catalog = ProviderCatalogDto(
        definitions: const <ProviderDefinitionDto>[],
        source: ProviderCatalogSource.bundled,
        updatedAt: now,
      );
      final settings = ProviderSettingsState(
        catalog: catalog,
        connections: const <ProviderConnectionDto>[],
      );
      expect(
        settings
            .copyWith(models: const <String, List<ProviderModelDto>>{})
            .catalog,
        catalog,
      );
      expect(const SystemAppClock().nowUtc().isUtc, isTrue);
      expect(const UuidAppIdGenerator().generate(), isNotEmpty);
      expect(
        const HostConnectionFailure.network('offline').toString(),
        'offline',
      );
      unawaited(api.close());
    },
  );
}
