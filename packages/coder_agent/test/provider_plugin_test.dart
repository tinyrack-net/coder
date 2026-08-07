@Tags(<String>['feature_test__provider_catalog__unit'])
library;

import 'package:coder_agent/coder_agent.dart';
import 'package:coder_agent/testing.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:test/test.dart';

void main() {
  providerPluginConformanceTests('a well-formed plugin', _FakePlugin.new);

  providerWireProtocolConformanceTests('a well-formed wire', _FakeWire.new);

  agentToolProviderConformanceTests(
    'a selectable capability',
    ListDirectoryToolProvider.new,
  );

  test('the registry rejects two plugins claiming one id', () {
    expect(
      () => ProviderRegistry(
        plugins: <ProviderPlugin>[_FakePlugin(), _FakePlugin()],
        wireProtocols: const <ProviderWireProtocol>[],
      ),
      throwsStateError,
    );
  });

  test('the registry rejects a plugin advertising a different id', () {
    expect(
      () => ProviderRegistry(
        plugins: <ProviderPlugin>[_MislabelledPlugin()],
        wireProtocols: const <ProviderWireProtocol>[],
      ),
      throwsStateError,
    );
  });

  test('the registry rejects two wires claiming one id', () {
    expect(
      () => ProviderRegistry(
        plugins: const <ProviderPlugin>[],
        wireProtocols: <ProviderWireProtocol>[_FakeWire(), _FakeWire()],
      ),
      throwsStateError,
    );
  });

  test('lookups distinguish absence from a wrong id', () {
    final registry = ProviderRegistry(
      plugins: <ProviderPlugin>[_FakePlugin()],
      wireProtocols: <ProviderWireProtocol>[_FakeWire()],
    );

    expect(registry.find('fake'), isNotNull);
    expect(registry.find('missing'), isNull);
    expect(() => registry.require('missing'), throwsStateError);
    expect(registry.require('fake').id, 'fake');
    expect(registry.findWire('fake-wire'), isNotNull);
    expect(registry.findWire('missing'), isNull);
    expect(() => registry.requireWire('missing'), throwsStateError);
    expect(registry.requireWire('fake-wire').id, 'fake-wire');
  });

  test('plugin defaults advertise nothing they do not implement', () {
    final plugin = _FakePlugin();
    expect(plugin.environmentVariables, isEmpty);
    expect(plugin.oauth, isNull);
    const remote = ModelCapabilitiesDto(
      streaming: CapabilitySupport.supported,
      toolCalling: CapabilitySupport.supported,
    );
    expect(identical(plugin.refineRemoteCapabilities(remote), remote), isTrue);
  });
}

final class _FakeWire implements ProviderWireProtocol {
  @override
  String get id => 'fake-wire';

  @override
  String get label => 'Fake wire';

  @override
  ModelProvider createProvider(ModelProviderRequest request) =>
      _FakeModelProvider(request.connectionId);

  @override
  Future<List<String>> discoverModels(
    ProviderEndpoint endpoint,
    ProviderCredential? credential,
  ) async => const <String>['fake-model'];
}

final class _FakePlugin extends ProviderPlugin {
  @override
  String get id => 'fake';

  @override
  ProviderDefinitionDto get definition => const ProviderDefinitionDto(
    id: 'fake',
    name: 'Fake',
    description: 'A vendor used by the conformance suite.',
    authMethods: <ProviderAuthMethodDto>[
      ProviderAuthMethodDto(
        id: 'api-key',
        label: 'API key',
        kind: ProviderAuthKind.apiKey,
        flow: ProviderAuthFlow.apiKey,
      ),
    ],
    recommendedModelIds: <String>['fake-model'],
  );

  @override
  List<ProviderCatalogModel> get models => const <ProviderCatalogModel>[
    ProviderCatalogModel(
      id: 'fake-model',
      label: 'Fake Model',
      capabilities: ModelCapabilitiesDto(
        streaming: CapabilitySupport.supported,
        toolCalling: CapabilitySupport.supported,
      ),
    ),
  ];

  @override
  ProviderEndpoint endpoint(ProviderAuthKind authKind) =>
      const ProviderEndpoint(baseUrl: 'https://fake.example/v1');

  @override
  ModelProvider createProvider(ModelProviderRequest request) =>
      _FakeModelProvider(request.connectionId);

  @override
  Future<List<String>> discoverModels(
    ProviderEndpoint endpoint,
    ProviderCredential? credential,
  ) async => const <String>['fake-model'];
}

final class _MislabelledPlugin extends _FakePlugin {
  @override
  String get id => 'someone-else';
}

final class _FakeModelProvider implements ModelProvider {
  const _FakeModelProvider(this.id);

  @override
  final String id;

  @override
  Stream<ModelEvent> stream(ModelRequest request, CancellationToken token) =>
      const Stream<ModelEvent>.empty();
}
