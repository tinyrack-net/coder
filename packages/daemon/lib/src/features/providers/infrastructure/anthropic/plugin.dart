import 'package:agent/agent.dart';
import 'package:daemon/src/features/providers/infrastructure/anthropic/wire.dart';

const AgentProviderAuthMethod _apiKey = AgentProviderAuthMethod(
  id: 'api-key',
  label: 'API key',
  kind: AgentProviderAuthKind.apiKey,
  flow: AgentProviderAuthFlow.apiKey,
);

/// Public Anthropic API provider metadata.
const AgentProviderDefinition anthropicDefinition = AgentProviderDefinition(
  id: 'anthropic',
  name: 'Anthropic',
  description: 'Claude models through the public Anthropic API.',
  authMethods: <AgentProviderAuthMethod>[_apiKey],
  recommendedModelIds: <String>['claude-sonnet-5', 'claude-opus-5'],
  documentationUrl: 'https://platform.claude.com/docs',
);

const AgentModelControlDescriptor _effort = AgentModelControlDescriptor(
  id: AgentModelControlIds.reasoningEffort,
  label: 'Effort',
  kind: AgentModelControlKind.choice,
  presentation: AgentModelControlPresentation.menuChip,
  choices: <AgentModelControlChoice>[
    AgentModelControlChoice(id: 'low', label: 'Low'),
    AgentModelControlChoice(id: 'medium', label: 'Medium'),
    AgentModelControlChoice(id: 'high', label: 'High'),
  ],
);

const AgentModelControlDescriptor _adaptive = AgentModelControlDescriptor(
  id: AgentModelControlIds.reasoningMode,
  label: 'Thinking',
  kind: AgentModelControlKind.choice,
  presentation: AgentModelControlPresentation.menuChip,
  choices: <AgentModelControlChoice>[
    AgentModelControlChoice(id: 'adaptive', label: 'Adaptive'),
  ],
  conflictsWith: <String>[AgentModelControlIds.thinkingBudget],
);

const AgentModelControlDescriptor _fast = AgentModelControlDescriptor(
  id: AgentModelControlIds.fastMode,
  label: 'Fast mode',
  kind: AgentModelControlKind.toggle,
  presentation: AgentModelControlPresentation.selectableChip,
);

const AgentModelControlDescriptor _budget = AgentModelControlDescriptor(
  id: AgentModelControlIds.thinkingBudget,
  label: 'Thinking budget',
  kind: AgentModelControlKind.integer,
  presentation: AgentModelControlPresentation.numberDialog,
  minimum: 1024,
  maximum: 32768,
  step: 1024,
  conflictsWith: <String>[AgentModelControlIds.reasoningMode],
);

const AgentModelCapabilities _adaptiveCapabilities = AgentModelCapabilities(
  streaming: AgentCapabilitySupport.supported,
  toolCalling: AgentCapabilitySupport.supported,
  functionTools: AgentCapabilitySupport.supported,
  deferredTools: AgentCapabilitySupport.unsupported,
  imageInput: AgentCapabilitySupport.supported,
  fileInput: AgentCapabilitySupport.supported,
  controls: <AgentModelControlDescriptor>[_effort, _adaptive, _fast],
  source: AgentCapabilitySource.bundled,
);

/// Coding-capable Anthropic API models bundled with the daemon.
const List<ProviderCatalogModel> anthropicBundledModels =
    <ProviderCatalogModel>[
      ProviderCatalogModel(
        id: 'claude-sonnet-5',
        label: 'Claude Sonnet 5',
        capabilities: _adaptiveCapabilities,
      ),
      ProviderCatalogModel(
        id: 'claude-opus-5',
        label: 'Claude Opus 5',
        capabilities: _adaptiveCapabilities,
      ),
      ProviderCatalogModel(
        id: 'claude-opus-4-5',
        label: 'Claude Opus 4.5',
        capabilities: AgentModelCapabilities(
          streaming: AgentCapabilitySupport.supported,
          toolCalling: AgentCapabilitySupport.supported,
          functionTools: AgentCapabilitySupport.supported,
          deferredTools: AgentCapabilitySupport.unsupported,
          imageInput: AgentCapabilitySupport.supported,
          fileInput: AgentCapabilitySupport.supported,
          controls: <AgentModelControlDescriptor>[_effort, _budget],
          source: AgentCapabilitySource.bundled,
        ),
      ),
    ];

/// Built-in Anthropic public API adapter.
final class AnthropicAdapter extends ProviderAdapter {
  /// Creates the adapter.
  const AnthropicAdapter({this.wire = const AnthropicMessagesWire()});

  /// Messages wire shared with custom connections.
  final AnthropicMessagesWire wire;

  @override
  String get id => anthropicDefinition.id;

  @override
  AgentProviderDefinition get definition => anthropicDefinition;

  @override
  List<ProviderCatalogModel> get models => anthropicBundledModels;

  @override
  ProviderEndpoint endpoint(AgentProviderAuthKind authKind) =>
      const ProviderEndpoint(
        baseUrl: 'https://api.anthropic.com/v1',
        strictToolSchema: true,
      );

  @override
  ModelGateway createProvider(ModelGatewayRequest request) =>
      wire.createProvider(request);

  @override
  Future<List<String>> discoverModels(
    ProviderEndpoint endpoint,
    ProviderCredential? credential,
  ) => wire.discoverModels(endpoint, credential);
}
