import 'dart:async';

import 'package:args/args.dart';
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
    String apiKey, {
    required bool makeDefault,
  });

  /// Connects a local provider without authentication.
  Future<ProviderConnectionDto> connectNone(
    String definitionId, {
    required bool makeDefault,
  });

  /// Starts an interactive OAuth authorization flow.
  Future<ProviderAuthAttemptDto> startAuth(
    String definitionId,
    String methodId, {
    required bool makeDefault,
  });

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
    String apiKey, {
    required bool makeDefault,
  }) => _api.connectProviderApiKey(
    definitionId,
    apiKey,
    makeDefault: makeDefault,
  );

  @override
  Future<ProviderConnectionDto> connectNone(
    String definitionId, {
    required bool makeDefault,
  }) => _api.connectProviderNone(definitionId, makeDefault: makeDefault);

  @override
  Future<ProviderAuthAttemptDto> startAuth(
    String definitionId,
    String methodId, {
    required bool makeDefault,
  }) => _api.startProviderAuth(
    definitionId,
    methodId,
    makeDefault: makeDefault,
  );

  @override
  Future<ProviderAuthAttemptDto> authStatus(String attemptId) =>
      _api.providerAuthStatus(attemptId);

  @override
  Future<void> disconnect(String connectionId) =>
      _api.disconnectProvider(connectionId);

  @override
  Future<ProviderCatalogDto> refreshCatalog() => _api.refreshProviderCatalog();
}

/// Executes one `coder_daemon provider` subcommand.
Future<int> runProviderCommand(
  List<String> arguments, {
  required ProviderCliBackend backend,
  required StringSink output,
  Future<String> Function()? readSecret,
  Duration pollInterval = const Duration(seconds: 1),
}) async {
  if (arguments.isEmpty || arguments.first == 'help') {
    output.writeln(_providerUsage);
    return 0;
  }
  switch (arguments.first) {
    case 'list':
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
            definitions[connection.definitionId]?.name ??
            connection.displayName;
        final defaultSuffix = connection.isDefault ? ' (default)' : '';
        final model = connection.defaultModelId ?? 'model not selected';
        output.writeln(
          '${connection.id}\t$name\t${connection.status.name}\t$model'
          '$defaultSuffix',
        );
      }
      return 0;
    case 'connect':
      return _connect(
        arguments.skip(1).toList(growable: false),
        backend: backend,
        output: output,
        readSecret: readSecret,
        pollInterval: pollInterval,
      );
    case 'disconnect':
      if (arguments.length != 2) {
        throw const FormatException(
          'provider disconnect requires a connection ID.',
        );
      }
      await backend.disconnect(arguments[1]);
      output.writeln('Disconnected ${arguments[1]}.');
      return 0;
    case 'catalog-refresh':
      await backend.refreshCatalog();
      output.writeln('Provider catalog refreshed.');
      return 0;
    default:
      throw FormatException('Unknown provider command: ${arguments.first}');
  }
}

Future<int> _connect(
  List<String> arguments, {
  required ProviderCliBackend backend,
  required StringSink output,
  required Future<String> Function()? readSecret,
  required Duration pollInterval,
}) async {
  final parser = ArgParser()
    ..addOption('method')
    ..addOption('api-key', hide: true)
    ..addFlag('default', negatable: false);
  final options = parser.parse(arguments);
  if (options.rest.length != 1) {
    throw const FormatException('provider connect requires a provider ID.');
  }
  final definitionId = options.rest.single;
  final catalog = await backend.catalog();
  final definition = catalog.definitions.singleWhere(
    (item) => item.id == definitionId,
    orElse: () => throw StateError('Unknown provider: $definitionId'),
  );
  final requestedMethod = options.option('method');
  final method = requestedMethod ?? (definition.local ? 'none' : 'api-key');
  final makeDefault = options.flag('default');
  switch (method) {
    case 'api-key':
      final inlineKey = options.option('api-key');
      final key = inlineKey ?? await (readSecret?.call() ?? _missingSecret());
      await backend.connectApiKey(
        definitionId,
        key,
        makeDefault: makeDefault,
      );
      output.writeln('Connected ${definition.name}.');
      return 0;
    case 'none':
      await backend.connectNone(definitionId, makeDefault: makeDefault);
      output.writeln('Connected ${definition.name}.');
      return 0;
    case 'chatgpt-browser':
    case 'chatgpt-device':
      final attempt = await backend.startAuth(
        definitionId,
        method,
        makeDefault: makeDefault,
      );
      output.writeln('Open ${attempt.authorizationUrl}');
      if (attempt.userCode case final code?) output.writeln('Code: $code');
      var current = attempt;
      while (!_terminal(current.status)) {
        current = await backend.authStatus(current.id);
        if (!_terminal(current.status)) {
          await Future<void>.delayed(pollInterval);
        }
      }
      if (current.status == ProviderAuthAttemptStatus.succeeded) {
        output.writeln('Connected ${definition.name}.');
        return 0;
      }
      output.writeln(current.error ?? 'Authorization did not complete.');
      return 1;
    default:
      throw FormatException('Unknown provider authentication method: $method');
  }
}

Future<String> _missingSecret() => Future<String>.error(
  StateError('API key input is required.'),
);

bool _terminal(ProviderAuthAttemptStatus status) =>
    status == ProviderAuthAttemptStatus.succeeded ||
    status == ProviderAuthAttemptStatus.failed ||
    status == ProviderAuthAttemptStatus.cancelled ||
    status == ProviderAuthAttemptStatus.expired;

const String _providerUsage = '''
provider list
provider connect <id> [--method api-key|chatgpt-browser|chatgpt-device]
provider disconnect <connection-id>
provider catalog-refresh''';
