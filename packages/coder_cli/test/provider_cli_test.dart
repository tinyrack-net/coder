import 'package:coder_cli/coder_cli.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime.utc(2026, 8, 2);

  test('list prints safe connection metadata', () async {
    final backend = _Backend(now);
    final output = StringBuffer();

    final exitCode = await runProviderCommand(
      <String>['list'],
      backend: backend,
      output: output,
    );

    expect(exitCode, 0);
    expect(output.toString(), contains('OpenAI'));
    expect(output.toString(), contains('connected'));
    expect(output.toString(), isNot(contains('https://')));
  });

  test('connect supports API key, local, and OAuth service flows', () async {
    final backend = _Backend(now);
    final output = StringBuffer();

    expect(
      await runProviderCommand(
        <String>['connect', 'deepseek', '--method', 'api-key'],
        backend: backend,
        output: output,
        readSecret: () async => 'secret',
      ),
      0,
    );
    expect(backend.apiKeys['deepseek'], 'secret');

    expect(
      await runProviderCommand(
        <String>['connect', 'ollama'],
        backend: backend,
        output: output,
      ),
      0,
    );
    expect(backend.noneConnections, contains('ollama'));

    expect(
      await runProviderCommand(
        <String>['connect', 'openai', '--method', 'chatgpt-device'],
        backend: backend,
        output: output,
      ),
      0,
    );
    expect(output.toString(), contains('CODE-1234'));
    expect(backend.statusCalls, 1);
  });

  test('disconnect and explicit catalog refresh are routed', () async {
    final backend = _Backend(now);
    final output = StringBuffer();

    expect(
      await runProviderCommand(
        <String>['disconnect', 'openai'],
        backend: backend,
        output: output,
      ),
      0,
    );
    expect(backend.disconnected, <String>['openai']);
    expect(
      await runProviderCommand(
        <String>['catalog-refresh'],
        backend: backend,
        output: output,
      ),
      0,
    );
    expect(backend.refreshes, 1);
  });

  test('help and empty list produce actionable output', () async {
    final backend = _Backend(now)..emptyConnections = true;
    final output = StringBuffer();

    expect(
      await runProviderCommand(
        const <String>[],
        backend: backend,
        output: output,
      ),
      0,
    );
    expect(output.toString(), contains('provider connect'));
    output.clear();
    expect(
      await runProviderCommand(
        const <String>['list'],
        backend: backend,
        output: output,
      ),
      0,
    );
    expect(output.toString(), contains('No provider connections.'));
  });

  test('invalid command shapes fail before mutating the backend', () async {
    final backend = _Backend(now);
    final output = StringBuffer();

    await expectLater(
      runProviderCommand(
        const <String>['disconnect'],
        backend: backend,
        output: output,
      ),
      throwsA(isA<FormatException>()),
    );
    await expectLater(
      runProviderCommand(
        const <String>['unknown'],
        backend: backend,
        output: output,
      ),
      throwsA(isA<FormatException>()),
    );
    await expectLater(
      runProviderCommand(
        const <String>['connect'],
        backend: backend,
        output: output,
      ),
      throwsA(isA<FormatException>()),
    );
    await expectLater(
      runProviderCommand(
        const <String>['connect', 'missing'],
        backend: backend,
        output: output,
      ),
      throwsA(isA<StateError>()),
    );
    await expectLater(
      runProviderCommand(
        const <String>['connect', 'openai', '--method', 'unknown'],
        backend: backend,
        output: output,
      ),
      throwsA(isA<FormatException>()),
    );
    await expectLater(
      runProviderCommand(
        const <String>['connect', 'deepseek'],
        backend: backend,
        output: output,
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('OAuth terminal failures return a non-zero result', () async {
    final backend = _Backend(now)
      ..authResult = ProviderAuthAttemptStatus.failed
      ..authError = 'authorization rejected';
    final output = StringBuffer();

    expect(
      await runProviderCommand(
        const <String>[
          'connect',
          'openai',
          '--method',
          'chatgpt-browser',
        ],
        backend: backend,
        output: output,
        pollInterval: Duration.zero,
      ),
      1,
    );
    expect(output.toString(), contains('authorization rejected'));
  });
}

final class _Backend implements ProviderCliBackend {
  _Backend(this.now);

  final DateTime now;
  final Map<String, String> apiKeys = <String, String>{};
  final List<String> noneConnections = <String>[];
  final List<String> disconnected = <String>[];
  int refreshes = 0;
  int statusCalls = 0;
  bool emptyConnections = false;
  ProviderAuthAttemptStatus authResult = ProviderAuthAttemptStatus.succeeded;
  String? authError;

  ProviderConnectionDto connection(String id, String name) =>
      ProviderConnectionDto(
        id: id,
        definitionId: id,
        displayName: name,
        status: ProviderConnectionStatus.connected,
        authKind: ProviderAuthKind.apiKey,
        credentialOrigin: ProviderCredentialOrigin.stored,
        createdAt: now,
        updatedAt: now,
      );

  @override
  Future<ProviderConnectionDto> connectApiKey(
    String definitionId,
    String apiKey,
  ) async {
    apiKeys[definitionId] = apiKey;
    return connection(definitionId, definitionId);
  }

  @override
  Future<ProviderConnectionDto> connectNone(String definitionId) async {
    noneConnections.add(definitionId);
    return connection(definitionId, definitionId);
  }

  @override
  Future<void> disconnect(String connectionId) async {
    disconnected.add(connectionId);
  }

  @override
  Future<ProviderCatalogDto> catalog() async => ProviderCatalogDto(
    definitions: const <ProviderDefinitionDto>[
      ProviderDefinitionDto(
        id: 'openai',
        name: 'OpenAI',
        description: 'OpenAI',
        authMethods: <ProviderAuthMethodDto>[],
      ),
      ProviderDefinitionDto(
        id: 'deepseek',
        name: 'DeepSeek',
        description: 'Hosted',
        authMethods: <ProviderAuthMethodDto>[],
      ),
      ProviderDefinitionDto(
        id: 'ollama',
        name: 'Ollama',
        description: 'Local',
        local: true,
        authMethods: <ProviderAuthMethodDto>[
          ProviderAuthMethodDto(
            id: 'none',
            label: 'Connect',
            kind: ProviderAuthKind.none,
            flow: ProviderAuthFlow.none,
          ),
        ],
      ),
    ],
    source: ProviderCatalogSource.bundled,
    updatedAt: now,
  );

  @override
  Future<List<ProviderConnectionDto>> connections() async => emptyConnections
      ? <ProviderConnectionDto>[]
      : <ProviderConnectionDto>[connection('openai', 'OpenAI')];

  @override
  Future<ProviderCatalogDto> refreshCatalog() async {
    refreshes += 1;
    return catalog();
  }

  @override
  Future<ProviderAuthAttemptDto> startAuth(
    String definitionId,
    String methodId,
  ) async {
    return ProviderAuthAttemptDto(
      id: 'attempt',
      definitionId: definitionId,
      methodId: methodId,
      status: ProviderAuthAttemptStatus.awaitingUser,
      authorizationUrl: 'https://auth.example/device',
      userCode: 'CODE-1234',
    );
  }

  @override
  Future<ProviderAuthAttemptDto> authStatus(String attemptId) async {
    statusCalls += 1;
    return ProviderAuthAttemptDto(
      id: 'attempt',
      definitionId: 'openai',
      methodId: 'chatgpt-device',
      status: authResult,
      error: authError,
    );
  }
}
