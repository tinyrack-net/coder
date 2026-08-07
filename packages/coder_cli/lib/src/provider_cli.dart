import 'dart:async';

import 'package:coder_cli/src/progress.dart';
import 'package:coder_client/coder_client.dart';
import 'package:coder_protocol/coder_protocol.dart';

/// Narrow provider administration surface used by the standalone CLI.
abstract interface class ProviderCliBackend {
  /// Returns the safe provider catalog.
  Future<ProviderCatalogDto> catalog();

  /// Returns configured provider connections.
  Future<List<ProviderConnectionDto>> connections();

  /// Connects a hosted provider with an API key.
  Future<ProviderConnectionDto> connectApiKey(
    String definitionId,
    String apiKey,
  );

  /// Connects a local provider without authentication.
  Future<ProviderConnectionDto> connectNone(String definitionId);

  /// Starts an interactive OAuth authorization flow.
  Future<ProviderAuthAttemptDto> startAuth(
    String definitionId,
    String methodId,
  );

  /// Returns the latest OAuth attempt state.
  Future<ProviderAuthAttemptDto> authStatus(String attemptId);

  /// Disconnects one connection.
  Future<void> disconnect(String connectionId);

  /// Explicitly refreshes public model metadata.
  Future<ProviderCatalogDto> refreshCatalog();
}

/// Adapts the full daemon client to the CLI's narrow administration port.
final class CoderApiProviderCliBackend implements ProviderCliBackend {
  /// Creates a provider CLI adapter.
  const CoderApiProviderCliBackend(this._api);

  final CoderApi _api;

  @override
  Future<ProviderCatalogDto> catalog() => _api.providers.listProviderCatalog();

  @override
  Future<List<ProviderConnectionDto>> connections() =>
      _api.providers.listProviderConnections();

  @override
  Future<ProviderConnectionDto> connectApiKey(
    String definitionId,
    String apiKey,
  ) => _api.providers.connectProviderApiKey(definitionId, apiKey);

  @override
  Future<ProviderConnectionDto> connectNone(String definitionId) =>
      _api.providers.connectProviderNone(definitionId);

  @override
  Future<ProviderAuthAttemptDto> startAuth(
    String definitionId,
    String methodId,
  ) => _api.providers.startProviderAuth(definitionId, methodId);

  @override
  Future<ProviderAuthAttemptDto> authStatus(String attemptId) =>
      _api.providers.providerAuthStatus(attemptId);

  @override
  Future<void> disconnect(String connectionId) =>
      _api.providers.disconnectProvider(connectionId);

  @override
  Future<ProviderCatalogDto> refreshCatalog() =>
      _api.providers.refreshProviderCatalog();
}

/// Lists configured provider connections with their catalog names.
Future<int> providerList({
  required ProviderCliBackend backend,
  required StringSink output,
}) async {
  final catalog = await backend.catalog();
  final definitions = <String, ProviderDefinitionDto>{
    for (final definition in catalog.definitions) definition.id: definition,
  };
  final connections = await backend.connections();
  if (connections.isEmpty) {
    output.writeln('No provider connections.');
  }
  for (final connection in connections) {
    final name =
        definitions[connection.definitionId]?.name ?? connection.displayName;
    output.writeln(
      '${connection.id}\t$name\t${connection.status.name}',
    );
  }
  return 0;
}

/// Connects the provider [definitionId] using the method named [methodId].
///
/// The valid method ids are whatever the provider's catalog entry advertises,
/// so the CLI accepts a new vendor's flows without a release. When [methodId]
/// is omitted the entry decides: a local provider needs no credential, a
/// hosted one takes an API key.
Future<int> providerConnect({
  required ProviderCliBackend backend,
  required StringSink output,
  required String definitionId,
  String? methodId,
  String? apiKey,
  Future<String> Function()? readSecret,
  CliProgress progress = const SilentCliProgress(),
  Duration pollInterval = const Duration(seconds: 1),
}) async {
  final catalog = await backend.catalog();
  final definition = catalog.definitions.singleWhere(
    (item) => item.id == definitionId,
    orElse: () => throw StateError('Unknown provider: $definitionId'),
  );
  final ProviderAuthMethodDto method;
  if (methodId == null) {
    final fallbackFlow = definition.local
        ? ProviderAuthFlow.none
        : ProviderAuthFlow.apiKey;
    method = definition.authMethods.singleWhere(
      (item) => item.flow == fallbackFlow,
      orElse: () => throw StateError(
        '$definitionId needs an explicit --method: '
        '${definition.authMethods.map((item) => item.id).join(', ')}',
      ),
    );
  } else {
    method = definition.authMethods.singleWhere(
      (item) => item.id == methodId,
      orElse: () => throw StateError(
        'Unknown method for $definitionId: $methodId. Valid methods: '
        '${definition.authMethods.map((item) => item.id).join(', ')}',
      ),
    );
  }
  switch (method.flow) {
    case ProviderAuthFlow.apiKey:
      final key = apiKey ?? await (readSecret?.call() ?? _missingSecret());
      await backend.connectApiKey(definitionId, key);
      output.writeln('Connected ${definition.name}.');
      return 0;
    case ProviderAuthFlow.none:
      await backend.connectNone(definitionId);
      output.writeln('Connected ${definition.name}.');
      return 0;
    case ProviderAuthFlow.oauthBrowser:
    case ProviderAuthFlow.oauthDevice:
      final attempt = await backend.startAuth(definitionId, method.id);
      output.writeln('Open ${attempt.authorizationUrl}');
      if (attempt.userCode case final code?) output.writeln('Code: $code');
      progress.start('Waiting for authorization');
      var current = attempt;
      while (!_terminal(current.status)) {
        current = await backend.authStatus(current.id);
        if (!_terminal(current.status)) {
          await Future<void>.delayed(pollInterval);
        }
      }
      if (current.status == ProviderAuthAttemptStatus.succeeded) {
        progress.succeed('Authorized');
        output.writeln('Connected ${definition.name}.');
        return 0;
      }
      final failure = current.error ?? 'Authorization did not complete.';
      progress.fail(failure);
      output.writeln(failure);
      return 1;
  }
}

/// Removes the provider connection [connectionId].
Future<int> providerDisconnect({
  required ProviderCliBackend backend,
  required StringSink output,
  required String connectionId,
}) async {
  await backend.disconnect(connectionId);
  output.writeln('Disconnected $connectionId.');
  return 0;
}

/// Refreshes public model metadata for every known provider.
Future<int> providerCatalogRefresh({
  required ProviderCliBackend backend,
  required StringSink output,
  CliProgress progress = const SilentCliProgress(),
}) async {
  progress.start('Refreshing the provider catalog');
  await backend.refreshCatalog();
  progress.succeed('Provider catalog refreshed');
  output.writeln('Provider catalog refreshed.');
  return 0;
}

Future<String> _missingSecret() => Future<String>.error(
  StateError('API key input is required.'),
);

bool _terminal(ProviderAuthAttemptStatus status) =>
    status == ProviderAuthAttemptStatus.succeeded ||
    status == ProviderAuthAttemptStatus.failed ||
    status == ProviderAuthAttemptStatus.cancelled ||
    status == ProviderAuthAttemptStatus.expired;
