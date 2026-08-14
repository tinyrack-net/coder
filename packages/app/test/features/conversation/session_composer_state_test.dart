import 'package:app/src/features/conversation/application/composer_controller.dart';
import 'package:app/src/features/providers/application/session_model_options.dart';
import 'package:app/src/features/sessions/domain/session_title.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/protocol.dart';

void main() {
  final now = DateTime.utc(2026, 8, 3);

  AgentDefinitionDto definition({
    String id = 'tinest',
    AgentMode mode = AgentMode.primary,
    bool isArchived = false,
    bool isStale = false,
    ModelSelectionDto? model,
  }) => AgentDefinitionDto(
    id: id,
    name: id,
    description: 'description',
    mode: mode,
    promptEnabled: true,
    systemPrompt: 'prompt',
    model: model,
    modelControls: model == null
        ? const <String, ModelControlValueDto>{}
        : const <String, ModelControlValueDto>{
            'reasoning_effort': ModelControlValueDto.stringValue(
              value: 'medium',
            ),
          },
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
    modelPrefix: id,
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
      const fallback = 'Coding session';
      expect(
        deriveSessionTitle('Run the tests', fallback: fallback),
        'Run the tests',
      );
      expect(
        deriveSessionTitle(
          '\n\n  Fix   the   parser \nand ship it',
          fallback: fallback,
        ),
        'Fix the parser',
      );
      expect(deriveSessionTitle('   \n \t ', fallback: fallback), fallback);
      final long = deriveSessionTitle('a' * 80, fallback: fallback);
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
          model: const ModelSelectionDto(
            modelId: 'missing/model',
          ),
        ),
      ];

      expect(
        selectableAgentDefinitions(definitions).map((item) => item.id),
        <String>['tinest', 'broken'],
      );
      expect(
        usableConnections(<ProviderConnectionDto>[
          connection(),
          connection(id: 'degraded', status: ProviderConnectionStatus.degraded),
          connection(id: 'offline', status: ProviderConnectionStatus.error),
        ]).map((item) => item.id),
        <String>['degraded', 'openai'],
      );
    },
    tags: const <String>['feature_test__session_lifecycle__unit'],
  );

  test(
    'agent selections preserve concrete IDs including unavailable ones',
    () {
      expect(
        agentSelectionFor(definition()),
        isNull,
      );
      expect(
        agentSelectionFor(
          definition(
            model: const ModelSelectionDto(
              modelId: 'deepseek/deepseek-v4',
            ),
          ),
        ),
        const ModelSelectionDto(
          modelId: 'deepseek/deepseek-v4',
        ),
      );
      expect(
        agentSelectionFor(
          definition(
            model: const ModelSelectionDto(
              modelId: 'missing/model',
            ),
          ),
        ),
        const ModelSelectionDto(modelId: 'missing/model'),
      );
      expect(
        agentSelectionFor(
          definition(),
        ),
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
    id: '$connectionId/$id',
    providerModelId: id,
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
      ModelSelectionDto? resolve({
        AgentDefinitionDto? agent,
        ModelSelectionDto? defaultModel,
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
            model: const ModelSelectionDto(
              modelId: 'openai/gpt-5-mini',
            ),
          ),
          defaultModel: const ModelSelectionDto(
            modelId: 'deepseek/deepseek-chat',
          ),
        ),
        const ModelSelectionDto(
          modelId: 'openai/gpt-5-mini',
        ),
      );

      // Step 3 wins once the agent has no usable pin.
      expect(
        resolve(
          defaultModel: const ModelSelectionDto(
            modelId: 'openai/gpt-5-mini',
          ),
        ),
        const ModelSelectionDto(
          modelId: 'openai/gpt-5-mini',
        ),
      );

      // An explicit unavailable default blocks instead of falling through.
      expect(
        resolve(
          defaultModel: const ModelSelectionDto(
            modelId: 'retired/gpt-5-mini',
          ),
        ),
        const ModelSelectionDto(modelId: 'retired/gpt-5-mini'),
      );
      expect(
        resolve(),
        const ModelSelectionDto(
          modelId: 'deepseek/deepseek-chat',
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
    tags: const <String>['feature_test__model_settings__unit'],
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
      const model = ModelSelectionDto(
        modelId: 'openai/gpt-5.6-sol',
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
    },
    tags: const <String>['feature_test__session_lifecycle__unit'],
  );
}
