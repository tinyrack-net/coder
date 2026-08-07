import 'package:coder_cli/coder_cli.dart';
import 'package:coder_client/coder_client.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime.utc(2026, 8, 2);

  ProviderConnectionDto connection(String id) => ProviderConnectionDto(
    id: id,
    definitionId: id,
    displayName: id,
    status: ProviderConnectionStatus.connected,
    authKind: ProviderAuthKind.apiKey,
    credentialOrigin: ProviderCredentialOrigin.stored,
    createdAt: now,
    updatedAt: now,
  );

  ProviderAuthAttemptDto attempt(String id) => ProviderAuthAttemptDto(
    id: id,
    definitionId: 'openai',
    methodId: 'chatgpt-device',
    status: ProviderAuthAttemptStatus.awaitingUser,
  );

  ProviderCatalogDto catalog() => ProviderCatalogDto(
    definitions: const <ProviderDefinitionDto>[],
    source: ProviderCatalogSource.bundled,
    updatedAt: now,
  );

  AgentDefinitionDto definition(String id, {String contentHash = 'hash'}) =>
      AgentDefinitionDto(
        id: id,
        name: id,
        description: '',
        mode: AgentMode.primary,
        promptEnabled: true,
        systemPrompt: 'prompt',
        model: const AgentModelSelectionDto(source: AgentModelSource.session),
        modelControls: <String, ModelControlValueDto>{
          'reasoning_effort': const ModelControlValueDto.stringValue(
            value: 'medium',
          ),
        },
        permissionMode: PermissionMode.ask,
        toolIds: const <String>[],
        callableAgentIds: const <String>[],
        contentHash: contentHash,
        sourcePath: '/config/agents/$id.md',
      );

  group('CoderApiProviderCliBackend', () {
    test('forwards every command to the matching API method', () async {
      final api = _RecordingApi(<String, Future<Object?>>{
        'listProviderCatalog': Future<ProviderCatalogDto>.value(catalog()),
        'listProviderConnections': Future<List<ProviderConnectionDto>>.value(
          <ProviderConnectionDto>[connection('a')],
        ),
        'connectProviderApiKey': Future<ProviderConnectionDto>.value(
          connection('deepseek'),
        ),
        'connectProviderNone': Future<ProviderConnectionDto>.value(
          connection('ollama'),
        ),
        'startProviderAuth': Future<ProviderAuthAttemptDto>.value(
          attempt('attempt-1'),
        ),
        'providerAuthStatus': Future<ProviderAuthAttemptDto>.value(
          attempt('attempt-1'),
        ),
        'refreshProviderCatalog': Future<ProviderCatalogDto>.value(catalog()),
      });
      final backend = CoderApiProviderCliBackend(api);

      expect((await backend.catalog()).definitions, isEmpty);
      expect(await backend.connections(), hasLength(1));
      expect((await backend.connectApiKey('deepseek', 'key')).id, 'deepseek');
      expect((await backend.connectNone('ollama')).id, 'ollama');
      expect(
        (await backend.startAuth('openai', 'chatgpt-device')).id,
        'attempt-1',
      );
      expect((await backend.authStatus('attempt-1')).id, 'attempt-1');
      await backend.disconnect('deepseek');
      expect((await backend.refreshCatalog()).definitions, isEmpty);

      expect(api.calls, <String>[
        'listProviderCatalog',
        'listProviderConnections',
        'connectProviderApiKey',
        'connectProviderNone',
        'startProviderAuth',
        'providerAuthStatus',
        'disconnectProvider',
        'refreshProviderCatalog',
      ]);
      expect(api.positional['connectProviderApiKey'], <Object?>[
        'deepseek',
        'key',
      ]);
      expect(api.positional['startProviderAuth'], <Object?>[
        'openai',
        'chatgpt-device',
      ]);
      expect(api.positional['disconnectProvider'], <Object?>['deepseek']);
    });
  });

  group('CoderApiAgentCliBackend', () {
    test('forwards list, validate, archive, and reset', () async {
      final api = _RecordingApi(<String, Future<Object?>>{
        'listAgentDefinitions': Future<List<AgentDefinitionDto>>.value(
          <AgentDefinitionDto>[definition('coder')],
        ),
        'validateAgentDefinition': Future<AgentDefinitionDto>.value(
          definition('draft'),
        ),
        'resetAgentDefinition': Future<AgentDefinitionDto>.value(
          definition('coder'),
        ),
      });
      final backend = CoderApiAgentCliBackend(api);

      expect(await backend.list(), hasLength(1));
      expect((await backend.validate('draft', '# Draft')).id, 'draft');
      await backend.archive('old');
      expect((await backend.reset('coder')).id, 'coder');

      expect(api.calls, <String>[
        'listAgentDefinitions',
        'validateAgentDefinition',
        'archiveAgentDefinition',
        'resetAgentDefinition',
      ]);
      expect(api.positional['validateAgentDefinition'], <Object?>[
        'draft',
        '# Draft',
      ]);
      expect(api.positional['archiveAgentDefinition'], <Object?>['old']);
    });

    test('apply creates a definition that does not exist yet', () async {
      final api = _RecordingApi(<String, Future<Object?>>{
        'listAgentDefinitions': Future<List<AgentDefinitionDto>>.value(
          <AgentDefinitionDto>[definition('other')],
        ),
        'createAgentDefinition': Future<AgentDefinitionDto>.value(
          definition('fresh'),
        ),
      });
      final backend = CoderApiAgentCliBackend(api);

      expect((await backend.apply('fresh', definition('fresh'))).id, 'fresh');
      expect(api.calls, <String>[
        'listAgentDefinitions',
        'createAgentDefinition',
      ]);
    });

    test(
      'apply updates an existing definition against its stored hash',
      () async {
        final api = _RecordingApi(<String, Future<Object?>>{
          'listAgentDefinitions': Future<List<AgentDefinitionDto>>.value(
            <AgentDefinitionDto>[
              definition('coder', contentHash: 'stored-hash'),
            ],
          ),
          'updateAgentDefinition': Future<AgentDefinitionDto>.value(
            definition('coder'),
          ),
        });
        final backend = CoderApiAgentCliBackend(api);

        // The daemon rejects a blind write, so the adapter has to carry the
        // stored hash across from the listing rather than the local file.
        await backend.apply('coder', definition('coder', contentHash: 'local'));

        expect(api.calls, <String>[
          'listAgentDefinitions',
          'updateAgentDefinition',
        ]);
        expect(
          api.named['updateAgentDefinition'],
          containsPair(#expectedContentHash, 'stored-hash'),
        );
        final written = api.positional['updateAgentDefinition']!.single;
        expect((written! as AgentDefinitionDto).contentHash, 'stored-hash');
      },
    );
  });
}

/// Forwards through [noSuchMethod] so the adapters can be checked without
/// hand-writing the whole [CoderApi] surface.
final class _RecordingApi
    implements
        CoderApi,
        WorkspacesApi,
        SessionsApi,
        AgentsApi,
        PromptsApi,
        ProvidersApi,
        McpApi,
        TerminalsApi,
        AttachmentsApi {
  _RecordingApi(this._results);

  /// Pre-typed futures, because [noSuchMethod] cannot infer the return type
  /// each member declares.
  final Map<String, Future<Object?>> _results;

  /// Invoked member names in call order.
  final List<String> calls = <String>[];

  /// Positional arguments per member name.
  final Map<String, List<Object?>> positional = <String, List<Object?>>{};

  /// Named arguments per member name.
  final Map<String, Map<Symbol, Object?>> named =
      <String, Map<Symbol, Object?>>{};

  @override
  WorkspacesApi get workspaces => this;

  @override
  SessionsApi get sessions => this;

  @override
  AgentsApi get agents => this;

  @override
  PromptsApi get prompts => this;

  @override
  ProvidersApi get providers => this;

  @override
  McpApi get mcp => this;

  @override
  TerminalsApi get terminals => this;

  @override
  AttachmentsApi get attachments => this;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final name = _name(invocation.memberName);
    calls.add(name);
    positional[name] = invocation.positionalArguments;
    named[name] = invocation.namedArguments;
    return _results[name] ?? Future<void>.value();
  }

  static String _name(Symbol symbol) {
    final text = symbol.toString();
    return text.substring('Symbol("'.length, text.length - '")'.length);
  }
}
