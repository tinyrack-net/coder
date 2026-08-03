import 'package:coder_app/src/controller.dart';
import 'package:coder_app/src/session_model_options.dart';
import 'package:coder_app/src/session_title.dart';
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
      source: AgentModelSource.daemonDefault,
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
    bool isDefault = true,
    String? defaultModelId = 'gpt-5.6-sol',
  }) => ProviderConnectionDto(
    id: id,
    definitionId: id,
    displayName: id,
    status: status,
    authKind: ProviderAuthKind.apiKey,
    credentialOrigin: ProviderCredentialOrigin.stored,
    isDefault: isDefault,
    defaultModelId: defaultModelId,
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
    'default selections resolve daemon defaults and fixed agent models',
    () {
      final connections = <ProviderConnectionDto>[
        connection(),
        connection(id: 'deepseek', isDefault: false, defaultModelId: null),
      ];

      expect(
        defaultSelectionFor(definition(), connections),
        const SessionModelSelectionDto(
          providerConnectionId: 'openai',
          modelId: 'gpt-5.6-sol',
        ),
      );
      expect(
        defaultSelectionFor(
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
        defaultSelectionFor(
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
        defaultSelectionFor(
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
        defaultSelectionFor(definition(), <ProviderConnectionDto>[
          connection(defaultModelId: null),
        ]),
        isNull,
      );
    },
    tags: const <String>['feature_test__session_lifecycle__unit'],
  );

  test(
    'composer draft drops the model when the agent changes',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final provider = sessionComposerDraftControllerProvider(
        'server',
        'worktree',
      );
      const model = SessionModelSelectionDto(
        providerConnectionId: 'openai',
        modelId: 'gpt-5.6-sol',
      );

      expect(container.read(provider).agentDefinitionId, isNull);
      container.read(provider.notifier).selectModel(model);
      expect(container.read(provider).model, model);
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
