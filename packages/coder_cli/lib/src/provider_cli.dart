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
  Future<ProviderCatalogDto> catalog() => _api.listProviderCatalog();

  @override
  Future<List<ProviderConnectionDto>> connections() =>
      _api.listProviderConnections();

  @override
  Future<ProviderConnectionDto> connectApiKey(
    String definitionId,
    String apiKey,
  ) => _api.connectProviderApiKey(definitionId, apiKey);

  @override
  Future<ProviderConnectionDto> connectNone(String definitionId) =>
      _api.connectProviderNone(definitionId);

  @override
  Future<ProviderAuthAttemptDto> startAuth(
    String definitionId,
    String methodId,
  ) => _api.startProviderAuth(definitionId, methodId);

  @override
  Future<ProviderAuthAttemptDto> authStatus(String attemptId) =>
      _api.providerAuthStatus(attemptId);

  @override
  Future<void> disconnect(String connectionId) =>
      _api.disconnectProvider(connectionId);

  @override
  Future<ProviderCatalogDto> refreshCatalog() => _api.refreshProviderCatalog();
}

/// The authentication methods `provider connect` accepts.
///
/// The CLI surfaces these as a closed choice so that an unknown value is
/// rejected by the argument scanner instead of by the daemon.
enum ProviderConnectMethod {
  /// Sends a secret the operator supplies.
  apiKey('api-key'),

  /// Connects a local provider that needs no credential.
  none('none'),

  /// Authorizes ChatGPT through a browser redirect.
  chatgptBrowser('chatgpt-browser'),

  /// Authorizes ChatGPT through a device code.
  chatgptDevice('chatgpt-device');

  const ProviderConnectMethod(this.id);

  /// The wire identifier the daemon expects.
  final String id;
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

/// Connects the provider [definitionId] using [method].
///
/// When [method] is omitted the provider's own catalog entry decides: a local
/// provider needs no credential, a hosted one takes an API key.
Future<int> providerConnect({
  required ProviderCliBackend backend,
  required StringSink output,
  required String definitionId,
  ProviderConnectMethod? method,
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
  final resolved =
      method ??
      (definition.local
          ? ProviderConnectMethod.none
          : ProviderConnectMethod.apiKey);
  switch (resolved) {
    case ProviderConnectMethod.apiKey:
      final key = apiKey ?? await (readSecret?.call() ?? _missingSecret());
      await backend.connectApiKey(definitionId, key);
      output.writeln('Connected ${definition.name}.');
      return 0;
    case ProviderConnectMethod.none:
      await backend.connectNone(definitionId);
      output.writeln('Connected ${definition.name}.');
      return 0;
    case ProviderConnectMethod.chatgptBrowser:
    case ProviderConnectMethod.chatgptDevice:
      final attempt = await backend.startAuth(definitionId, resolved.id);
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
