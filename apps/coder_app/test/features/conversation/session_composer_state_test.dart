import 'package:coder_app/src/features/conversation/application/composer_controller.dart';
import 'package:coder_app/src/features/providers/application/session_model_options.dart';
import 'package:coder_app/src/features/sessions/domain/session_title.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.utc(2026, 8, 3);

  AgentDefinitionDto definition({
    String id = 'coder',
    AgentMode mode = AgentMode.primary,
    bool isArchived = false,
    bool isStale = false,
    AgentModelSelectionDto model = const AgentModelSelectionDto(
      source: AgentModelSource.session,
    ),
  }) => AgentDefinitionDto(
    id: id,
    name: id,
    description: 'description',
    mode: mode,
    promptEnabled: true,
    systemPrompt: 'prompt',
    model: model,
    reasoningEffort: 'medium',
    permissionMode: PermissionMode.ask,
    toolIds: const <String>['read_file'],
    callableAgentIds: const <String>[],
    contentHash: 'hash',
    sourcePath: '/config/agents/$id.md',
    isArchived: isArchived,
    isStale: isStale,
  );

  ProviderConnectionDto connection({
    String id = 'openai',
    ProviderConnectionStatus status = ProviderConnectionStatus.connected,
  }) => ProviderConnectionDto(
    id: id,
    definitionId: id,
    displayName: id,
    status: status,
    authKind: ProviderAuthKind.apiKey,
    credentialOrigin: ProviderCredentialOrigin.stored,
    createdAt: now,
    updatedAt: now,
  );

  test(
    'session titles come from the first readable prompt line',
    () {
      expect(deriveSessionTitle('Run the tests'), 'Run the tests');
      expect(
        deriveSessionTitle('\n\n  Fix   the   parser \nand ship it'),
        'Fix the parser',
      );
      expect(deriveSessionTitle('   \n \t '), defaultSessionTitle);
      final long = deriveSessionTitle('a' * 80);
      expect(long.length, maxSessionTitleLength);
      expect(long.endsWith('…'), isTrue);
    },
    tags: const <String>['feature_test__session_lifecycle__unit'],
  );

  test(
    'composer options keep agents whose own model cannot resolve',
    () {
      final definitions = <AgentDefinitionDto>[
        definition(),
        definition(id: 'reviewer', mode: AgentMode.subagent),
        definition(id: 'archived', isArchived: true),
        definition(id: 'stale', isStale: true),
        definition(
          id: 'broken',
          model: const AgentModelSelectionDto(
            source: AgentModelSource.fixed,
            providerConnectionId: 'missing',
            modelId: 'model',
          ),
        ),
      ];

      expect(
        selectableAgentDefinitions(definitions).map((item) => item.id),
        <String>['coder', 'broken'],
      );
      expect(
        usableConnections(<ProviderConnectionDto>[
          connection(),
          connection(id: 'degraded', status: ProviderConnectionStatus.degraded),
          connection(id: 'offline', status: ProviderConnectionStatus.error),
        ]).map((item) => item.id),
        <String>['openai', 'degraded'],
      );
    },
    tags: const <String>['feature_test__session_lifecycle__unit'],
  );

  test(
    'agent selections require a session choice or resolve a fixed model',
    () {
      final connections = <ProviderConnectionDto>[
        connection(),
        connection(id: 'deepseek'),
      ];

      expect(
        agentSelectionFor(definition(), connections),
        isNull,
      );
      expect(
        agentSelectionFor(
          definition(
            model: const AgentModelSelectionDto(
              source: AgentModelSource.fixed,
              providerConnectionId: 'deepseek',
              modelId: 'deepseek-v4',
            ),
          ),
          connections,
        ),
        const SessionModelSelectionDto(
          providerConnectionId: 'deepseek',
          modelId: 'deepseek-v4',
        ),
      );
      expect(
        agentSelectionFor(
          definition(
            model: const AgentModelSelectionDto(
              source: AgentModelSource.fixed,
              providerConnectionId: 'missing',
              modelId: 'model',
            ),
          ),
          connections,
        ),
        isNull,
      );
      expect(
        agentSelectionFor(
          definition(
            model: const AgentModelSelectionDto(
              source: AgentModelSource.fixed,
              providerConnectionId: 'deepseek',
            ),
          ),
          connections,
        ),
        isNull,
      );
      expect(
        agentSelectionFor(definition(), <ProviderConnectionDto>[connection()]),
        isNull,
      );
    },
    tags: const <String>['feature_test__session_lifecycle__unit'],
  );

  ProviderModelDto model({
    String connectionId = 'openai',
    String id = 'gpt-5',
    CapabilitySupport streaming = CapabilitySupport.supported,
  }) => ProviderModelDto(
    connectionId: connectionId,
    id: id,
    label: id,
    source: ProviderModelSource.bundled,
    capabilities: ModelCapabilitiesDto(
      streaming: streaming,
      toolCalling: CapabilitySupport.supported,
    ),
  );

  test(
    'the model chain prefers the agent pin, then the default, then the first',
    () {
      // Display-name order: the daemon returns "deepseek" before "openai".
      final connections = <ProviderConnectionDto>[
        connection(id: 'deepseek'),
        connection(),
      ];
      final models = <String, List<ProviderModelDto>>{
        'deepseek': <ProviderModelDto>[
          model(
            connectionId: 'deepseek',
            id: 'deepseek-alpha',
            streaming: CapabilitySupport.unsupported,
          ),
          model(connectionId: 'deepseek', id: 'deepseek-chat'),
        ],
        'openai': <ProviderModelDto>[model(), model(id: 'gpt-5-mini')],
      };
      SessionModelSelectionDto? resolve({
        AgentDefinitionDto? agent,
        SessionModelSelectionDto? defaultModel,
        List<ProviderConnectionDto>? only,
      }) => effectiveModelFor(
        definition: agent ?? definition(),
        connections: only ?? connections,
        models: models,
        defaultModel: defaultModel,
      );

      // Step 2 wins over everything below it.
      expect(
        resolve(
          agent: definition(
            model: const AgentModelSelectionDto(
              source: AgentModelSource.fixed,
              providerConnectionId: 'openai',
              modelId: 'gpt-5-mini',
            ),
          ),
          defaultModel: const SessionModelSelectionDto(
            providerConnectionId: 'deepseek',
            modelId: 'deepseek-chat',
          ),
        ),
        const SessionModelSelectionDto(
          providerConnectionId: 'openai',
          modelId: 'gpt-5-mini',
        ),
      );

      // Step 3 wins once the agent has no usable pin.
      expect(
        resolve(
          defaultModel: const SessionModelSelectionDto(
            providerConnectionId: 'openai',
            modelId: 'gpt-5-mini',
          ),
        ),
        const SessionModelSelectionDto(
          providerConnectionId: 'openai',
          modelId: 'gpt-5-mini',
        ),
      );

      // Step 4 skips the unusable default and the unusable first model.
      expect(
        resolve(
          defaultModel: const SessionModelSelectionDto(
            providerConnectionId: 'retired',
            modelId: 'gpt-5-mini',
          ),
        ),
        const SessionModelSelectionDto(
          providerConnectionId: 'deepseek',
          modelId: 'deepseek-chat',
        ),
      );
      expect(
        resolve(),
        const SessionModelSelectionDto(
          providerConnectionId: 'deepseek',
          modelId: 'deepseek-chat',
        ),
      );

      // A disconnected provider drops out of the chain entirely.
      expect(
        resolve(
          only: <ProviderConnectionDto>[
            connection(
              id: 'deepseek',
              status: ProviderConnectionStatus.disconnected,
            ),
          ],
        ),
        isNull,
      );
      expect(resolve(only: const <ProviderConnectionDto>[]), isNull);
    },
    tags: const <String>['feature_test__provider_default_model__unit'],
  );

  test(
    'composer draft drops the model when the agent changes',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final provider = sessionComposerDraftControllerProvider(
        'server',
        'worktree',
        'draft:test',
      );
      const model = SessionModelSelectionDto(
        providerConnectionId: 'openai',
        modelId: 'gpt-5.6-sol',
      );

      expect(container.read(provider).agentDefinitionId, isNull);
      container.read(provider.notifier).selectModel(model);
      expect(container.read(provider).model, model);
      expect(
        container
            .read(
              sessionComposerDraftControllerProvider(
                'server',
                'worktree',
                'draft:other-pane',
              ),
            )
            .model,
        isNull,
      );
      container.read(provider.notifier).selectAgent('planner');
      expect(container.read(provider).agentDefinitionId, 'planner');
      expect(container.read(provider).model, isNull);
      container.read(provider.notifier).selectModel(model);
      expect(container.read(provider).agentDefinitionId, 'planner');
      container.read(provider.notifier).selectModel(null);
      expect(container.read(provider).model, isNull);
    },
    tags: const <String>['feature_test__session_lifecycle__unit'],
  );
}
