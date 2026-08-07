import 'package:coder_agent/coder_agent.dart';

// Consumers of the daemon's provider ports need the request and endpoint
// shapes those ports exchange without importing the agent layer directly.
export 'package:coder_agent/coder_agent.dart'
    show
        ModelProviderRequest,
        ProviderDiscoveryFailure,
        ProviderDiscoveryFailureKind,
        ProviderEndpoint;

/// Overrides every plugin's own model discovery when provided.
///
/// The daemon normally asks the vendor plugin; tests and embedded runs
/// substitute one deterministic listing for all of them through this port.
abstract interface class ProviderModelDiscovery {
  /// Fetches model identifiers for one provider connection.
  Future<List<String>> fetchModelIds(
    ProviderEndpoint endpoint,
    ProviderCredential? credential,
  );
}

/// Overrides every plugin's own adapter construction when provided.
///
/// Same shape as [ProviderPlugin.createProvider]; a test that wants to see
/// exactly what the daemon resolved records the request here instead of
/// standing up a transport.
abstract interface class ModelProviderFactory {
  /// Creates a provider adapter for one connected provider.
  ModelProvider create(ModelProviderRequest request);
}
