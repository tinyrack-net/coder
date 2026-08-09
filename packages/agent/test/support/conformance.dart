import 'package:agent/src/contracts.dart';

import 'package:agent/src/model.dart';
import 'package:agent/src/provider_plugin.dart';
import 'package:agent/src/tools/tool_registry.dart';
import 'package:test/test.dart';

/// Structural invariants every [ProviderPlugin] must satisfy.
///
/// The daemon resolves flows, endpoints, and credentials purely from what the
/// plugin advertises, so a plugin whose advertisement disagrees with itself
/// fails here rather than as a runtime StateError in someone's session.
void providerPluginConformanceTests(
  String description,
  ProviderPlugin Function() build,
) {
  group('$description conforms to ProviderPlugin', () {
    late ProviderPlugin plugin;

    setUp(() => plugin = build());

    test('identifies itself consistently', () {
      expect(plugin.id, isNotEmpty);
      expect(plugin.definition.id, plugin.id);
      expect(plugin.definition.name, isNotEmpty);
    });

    test('advertises at least one way to connect', () {
      expect(plugin.definition.authMethods, isNotEmpty);
      for (final method in plugin.definition.authMethods) {
        expect(method.id, isNotEmpty, reason: plugin.id);
        expect(method.label, isNotEmpty, reason: method.id);
      }
      final ids = plugin.definition.authMethods.map((method) => method.id);
      expect(ids.toSet(), hasLength(ids.length), reason: plugin.id);
    });

    test('backs every advertised OAuth method with a gateway', () {
      final hasOAuthMethod = plugin.definition.authMethods.any(
        (method) =>
            method.flow == AgentProviderAuthFlow.oauthBrowser ||
            method.flow == AgentProviderAuthFlow.oauthDevice,
      );
      // The daemon starts flows only for methods the definition advertises,
      // so a gateway without a method is dead and a method without a gateway
      // is a StateError waiting for a click.
      expect(plugin.oauth != null, hasOAuthMethod, reason: plugin.id);
    });

    test('serves an absolute endpoint for every auth kind', () {
      for (final kind in AgentProviderAuthKind.values) {
        final endpoint = plugin.endpoint(kind);
        final uri = Uri.tryParse(endpoint.baseUrl);
        expect(
          uri != null && uri.hasAuthority && uri.hasScheme,
          isTrue,
          reason: '${plugin.id} $kind: ${endpoint.baseUrl}',
        );
      }
    });

    test('bundles models a coding turn can actually run', () {
      final ids = plugin.models.map((model) => model.id);
      expect(ids.toSet(), hasLength(ids.length), reason: plugin.id);
      for (final model in plugin.models) {
        expect(model.id, isNotEmpty, reason: plugin.id);
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
      final bundled = plugin.models.map((model) => model.id).toSet();
      for (final id in plugin.definition.recommendedModelIds) {
        expect(bundled, contains(id), reason: plugin.id);
      }
    });

    test('refinement never invents a different model', () {
      const remote = AgentModelCapabilities(
        streaming: AgentCapabilitySupport.supported,
        toolCalling: AgentCapabilitySupport.supported,
        source: AgentCapabilitySource.refreshed,
      );
      final refined = plugin.refineRemoteCapabilities(remote);
      // Refinement adds what the vendor knows; contradicting what the remote
      // catalog measured would mean one of the two is lying to the user.
      expect(refined.streaming, remote.streaming, reason: plugin.id);
      expect(refined.toolCalling, remote.toolCalling, reason: plugin.id);
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
        ModelProviderRequest(
          connectionId: 'conformance',
          endpoint: const ProviderEndpoint(baseUrl: 'http://127.0.0.1:1'),
          credential: credential,
        ),
      );
      expect(provider, isA<ModelProvider>());
      expect(provider.id, isNotEmpty);
    });
  });
}

/// Structural invariants every [AgentToolProvider] must satisfy.
///
/// The daemon advertises exactly what the provider's catalog entry says and
/// dispatches on its id, so an entry that disagrees with its provider breaks
/// tool selection for every agent that lists it.
void agentToolProviderConformanceTests(
  String description,
  AgentToolProvider Function() build,
) {
  group('$description conforms to AgentToolProvider', () {
    late AgentToolProvider provider;

    setUp(() => provider = build());

    test('identifies itself consistently', () {
      expect(provider.id, isNotEmpty);
      final entry = provider.catalogEntry;
      if (entry != null) {
        expect(entry.id, provider.id);
        expect(entry.name, entry.id);
        expect(entry.description, isNotEmpty);
      }
    });
  });
}
