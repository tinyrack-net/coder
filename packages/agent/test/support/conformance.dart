import 'package:agent/src/contracts.dart';

import 'package:agent/src/model.dart';
import 'package:agent/src/provider_adapter.dart';
import 'package:test/test.dart';

/// Structural invariants every [ProviderAdapter] must satisfy.
///
/// The daemon resolves flows, endpoints, and credentials purely from what the
/// adapter advertises, so an adapter whose advertisement disagrees with itself
/// fails here rather than as a runtime StateError in someone's session.
void providerAdapterConformanceTests(
  String description,
  ProviderAdapter Function() build,
) {
  group('$description conforms to ProviderAdapter', () {
    late ProviderAdapter adapter;

    setUp(() => adapter = build());

    test('identifies itself consistently', () {
      expect(adapter.id, isNotEmpty);
      expect(adapter.definition.id, adapter.id);
      expect(adapter.definition.name, isNotEmpty);
    });

    test('advertises at least one way to connect', () {
      expect(adapter.definition.authMethods, isNotEmpty);
      for (final method in adapter.definition.authMethods) {
        expect(method.id, isNotEmpty, reason: adapter.id);
        expect(method.label, isNotEmpty, reason: method.id);
      }
      final ids = adapter.definition.authMethods.map((method) => method.id);
      expect(ids.toSet(), hasLength(ids.length), reason: adapter.id);
    });

    test('backs every advertised OAuth method with a gateway', () {
      final hasOAuthMethod = adapter.definition.authMethods.any(
        (method) =>
            method.flow == AgentProviderAuthFlow.oauthBrowser ||
            method.flow == AgentProviderAuthFlow.oauthDevice,
      );
      // The daemon starts flows only for methods the definition advertises,
      // so a gateway without a method is dead and a method without a gateway
      // is a StateError waiting for a click.
      expect(adapter.oauth != null, hasOAuthMethod, reason: adapter.id);
    });

    test('serves an absolute endpoint for every auth kind', () {
      for (final kind in AgentProviderAuthKind.values) {
        final endpoint = adapter.endpoint(kind);
        final uri = Uri.tryParse(endpoint.baseUrl);
        expect(
          uri != null && uri.hasAuthority && uri.hasScheme,
          isTrue,
          reason: '${adapter.id} $kind: ${endpoint.baseUrl}',
        );
      }
    });

    test('bundles models a coding turn can actually run', () {
      final ids = adapter.models.map((model) => model.id);
      expect(ids.toSet(), hasLength(ids.length), reason: adapter.id);
      for (final model in adapter.models) {
        expect(model.id, isNotEmpty, reason: adapter.id);
        expect(model.label, isNotEmpty, reason: model.id);
        // A bundled model is a recommendation; recommending one the session
        // service would refuse to start is a contradiction.
        expect(
          model.capabilities.streaming,
          AgentCapabilitySupport.supported,
          reason: model.id,
        );
        expect(
          model.capabilities.toolCalling,
          AgentCapabilitySupport.supported,
          reason: model.id,
        );
      }
    });

    test('recommends only models it bundles', () {
      final bundled = adapter.models.map((model) => model.id).toSet();
      for (final id in adapter.definition.recommendedModelIds) {
        expect(bundled, contains(id), reason: adapter.id);
      }
    });

    test('refinement never invents a different model', () {
      const remote = AgentModelCapabilities(
        streaming: AgentCapabilitySupport.supported,
        toolCalling: AgentCapabilitySupport.supported,
        source: AgentCapabilitySource.refreshed,
      );
      final refined = adapter.refineRemoteCapabilities(remote);
      // Refinement adds what the vendor knows; contradicting what the remote
      // catalog measured would mean one of the two is lying to the user.
      expect(refined.streaming, remote.streaming, reason: adapter.id);
      expect(refined.toolCalling, remote.toolCalling, reason: adapter.id);
    });
  });
}

/// Structural invariants every [ProviderWireProtocol] must satisfy.
void providerWireProtocolConformanceTests(
  String description,
  ProviderWireProtocol Function() build, {
  ProviderCredential credential = const ApiKeyCredential('test-key'),
}) {
  group('$description conforms to ProviderWireProtocol', () {
    late ProviderWireProtocol wire;

    setUp(() => wire = build());

    test('identifies itself', () {
      expect(wire.id, isNotEmpty);
      expect(wire.label, isNotEmpty);
    });

    test('builds an adapter without touching the network', () {
      final provider = wire.createProvider(
        ModelGatewayRequest(
          connectionId: 'conformance',
          endpoint: const ProviderEndpoint(baseUrl: 'http://127.0.0.1:1'),
          credential: credential,
        ),
      );
      expect(provider, isA<ModelGateway>());
      expect(provider.id, isNotEmpty);
    });
  });
}
