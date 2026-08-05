import 'package:coder_protocol/coder_protocol.dart';

/// Internal immutable runtime configuration for one built-in provider.
final class ProviderRuntimePreset {
  /// Creates an immutable built-in provider preset.
  const ProviderRuntimePreset({
    required this.definition,
    required this.baseUrl,
    required this.apiFormat,
    required this.environmentVariables,
    required this.strictToolSchema,
    required this.models,
  });

  /// Public provider metadata safe to send to clients.
  final ProviderDefinitionDto definition;

  /// Trusted endpoint compiled into the daemon.
  final String baseUrl;

  /// API format used by this provider.
  final ProviderApiFormat apiFormat;

  /// Credential environment variables recognized by the daemon.
  final List<String> environmentVariables;

  /// Whether strict JSON schemas are accepted by this provider.
  final bool strictToolSchema;

  /// Bundled, validated coding model metadata.
  final List<ProviderCatalogModel> models;
}

/// Immutable metadata for a coding-capable provider model.
final class ProviderCatalogModel {
  /// Creates bundled model metadata.
  const ProviderCatalogModel({
    required this.id,
    required this.label,
    required this.capabilities,
    this.pricing,
    this.limits,
  });

  /// Provider model identifier.
  final String id;

  /// Human-readable model label.
  final String label;

  /// Capabilities sourced from the bundled catalog.
  final ModelCapabilitiesDto capabilities;

  /// Optional catalog pricing metadata.
  final ModelPricingDto? pricing;

  /// Optional catalog token limits.
  final ModelLimitsDto? limits;
}

const ProviderAuthMethodDto _apiKey = ProviderAuthMethodDto(
  id: 'api-key',
  label: 'API key',
  kind: ProviderAuthKind.apiKey,
  flow: ProviderAuthFlow.apiKey,
);

const ProviderAuthMethodDto _none = ProviderAuthMethodDto(
  id: 'none',
  label: 'Connect',
  kind: ProviderAuthKind.none,
  flow: ProviderAuthFlow.none,
);

const ModelCapabilitiesDto _reasoning = ModelCapabilitiesDto(
  streaming: CapabilitySupport.supported,
  toolCalling: CapabilitySupport.supported,
  reasoningEffort: CapabilitySupport.supported,
  supportedReasoningEfforts: <String>[
    'none',
    'low',
    'medium',
    'high',
    'xhigh',
    'max',
  ],
  source: CapabilitySource.bundled,
);

// Only the OpenAI Responses endpoint documents the `service_tier` field, so
// other reasoning providers keep the unknown default and hide the control.
const ModelCapabilitiesDto _openAiReasoning = ModelCapabilitiesDto(
  streaming: CapabilitySupport.supported,
  toolCalling: CapabilitySupport.supported,
  reasoningEffort: CapabilitySupport.supported,
  imageInput: CapabilitySupport.supported,
  fileInput: CapabilitySupport.supported,
  serviceTier: CapabilitySupport.supported,
  supportedReasoningEfforts: <String>[
    'none',
    'low',
    'medium',
    'high',
    'xhigh',
    'max',
  ],
  supportedServiceTiers: <String>['default', 'flex', 'priority'],
  source: CapabilitySource.bundled,
);

const ModelCapabilitiesDto _tools = ModelCapabilitiesDto(
  streaming: CapabilitySupport.supported,
  toolCalling: CapabilitySupport.supported,
  reasoningEffort: CapabilitySupport.unsupported,
  source: CapabilitySource.bundled,
);

/// Built-in provider catalog. Runtime endpoints never come from remote data.
const List<ProviderRuntimePreset> builtInProviderPresets =
    <ProviderRuntimePreset>[
      ProviderRuntimePreset(
        definition: ProviderDefinitionDto(
          id: 'openai',
          name: 'OpenAI',
          description: 'OpenAI Platform API or ChatGPT subscription.',
          authMethods: <ProviderAuthMethodDto>[
            ProviderAuthMethodDto(
              id: 'chatgpt-browser',
              label: 'Sign in with ChatGPT',
              kind: ProviderAuthKind.oauth,
              flow: ProviderAuthFlow.oauthBrowser,
              experimental: true,
            ),
            ProviderAuthMethodDto(
              id: 'chatgpt-device',
              label: 'Sign in with device code',
              kind: ProviderAuthKind.oauth,
              flow: ProviderAuthFlow.oauthDevice,
              experimental: true,
            ),
            _apiKey,
          ],
          recommendedModelIds: <String>[
            'gpt-5.6-sol',
            'gpt-5.6-terra',
            'gpt-5.6-luna',
          ],
          documentationUrl: 'https://platform.openai.com/docs',
        ),
        baseUrl: 'https://api.openai.com/v1',
        apiFormat: ProviderApiFormat.responses,
        environmentVariables: <String>['OPENAI_API_KEY'],
        strictToolSchema: true,
        models: <ProviderCatalogModel>[
          ProviderCatalogModel(
            id: 'gpt-5.6-sol',
            label: 'GPT-5.6 Sol',
            capabilities: _openAiReasoning,
          ),
          ProviderCatalogModel(
            id: 'gpt-5.6-terra',
            label: 'GPT-5.6 Terra',
            capabilities: _openAiReasoning,
          ),
          ProviderCatalogModel(
            id: 'gpt-5.6-luna',
            label: 'GPT-5.6 Luna',
            capabilities: _openAiReasoning,
          ),
        ],
      ),
      ProviderRuntimePreset(
        definition: ProviderDefinitionDto(
          id: 'deepseek',
          name: 'DeepSeek',
          description: 'DeepSeek hosted coding and reasoning models.',
          authMethods: <ProviderAuthMethodDto>[_apiKey],
          recommendedModelIds: <String>[
            'deepseek-v4-pro',
            'deepseek-v4-flash',
            'deepseek-chat',
          ],
          documentationUrl: 'https://api-docs.deepseek.com',
        ),
        baseUrl: 'https://api.deepseek.com',
        apiFormat: ProviderApiFormat.chatCompletions,
        environmentVariables: <String>['DEEPSEEK_API_KEY'],
        strictToolSchema: false,
        models: <ProviderCatalogModel>[
          ProviderCatalogModel(
            id: 'deepseek-v4-pro',
            label: 'DeepSeek V4 Pro',
            capabilities: _reasoning,
          ),
          ProviderCatalogModel(
            id: 'deepseek-v4-flash',
            label: 'DeepSeek V4 Flash',
            capabilities: _reasoning,
          ),
          ProviderCatalogModel(
            id: 'deepseek-chat',
            label: 'DeepSeek Chat',
            capabilities: _tools,
          ),
          ProviderCatalogModel(
            id: 'deepseek-reasoner',
            label: 'DeepSeek Reasoner',
            capabilities: _reasoning,
          ),
        ],
      ),
      ProviderRuntimePreset(
        definition: ProviderDefinitionDto(
          id: 'openrouter',
          name: 'OpenRouter',
          description: 'Multi-provider OpenAI-compatible model gateway.',
          authMethods: <ProviderAuthMethodDto>[_apiKey],
          recommendedModelIds: <String>[
            'deepseek/deepseek-v4-flash-0731',
            'qwen/qwen3.7-flash',
          ],
          documentationUrl: 'https://openrouter.ai/docs',
        ),
        baseUrl: 'https://openrouter.ai/api/v1',
        apiFormat: ProviderApiFormat.chatCompletions,
        environmentVariables: <String>['OPENROUTER_API_KEY'],
        strictToolSchema: false,
        models: <ProviderCatalogModel>[
          ProviderCatalogModel(
            id: 'deepseek/deepseek-v4-flash-0731',
            label: 'DeepSeek V4 Flash',
            capabilities: _reasoning,
          ),
          ProviderCatalogModel(
            id: 'qwen/qwen3.7-flash',
            label: 'Qwen 3.7 Flash',
            capabilities: _reasoning,
          ),
        ],
      ),
      ProviderRuntimePreset(
        definition: ProviderDefinitionDto(
          id: 'groq',
          name: 'Groq',
          description: 'Low-latency hosted open models.',
          authMethods: <ProviderAuthMethodDto>[_apiKey],
          recommendedModelIds: <String>[
            'openai/gpt-oss-120b',
            'openai/gpt-oss-20b',
          ],
          documentationUrl: 'https://console.groq.com/docs',
        ),
        baseUrl: 'https://api.groq.com/openai/v1',
        apiFormat: ProviderApiFormat.chatCompletions,
        environmentVariables: <String>['GROQ_API_KEY'],
        strictToolSchema: false,
        models: <ProviderCatalogModel>[
          ProviderCatalogModel(
            id: 'openai/gpt-oss-120b',
            label: 'GPT OSS 120B',
            capabilities: _reasoning,
          ),
          ProviderCatalogModel(
            id: 'openai/gpt-oss-20b',
            label: 'GPT OSS 20B',
            capabilities: _reasoning,
          ),
        ],
      ),
      ProviderRuntimePreset(
        definition: ProviderDefinitionDto(
          id: 'xai',
          name: 'xAI',
          description: 'xAI Grok hosted models.',
          authMethods: <ProviderAuthMethodDto>[_apiKey],
          recommendedModelIds: <String>['grok-4.5', 'grok-4.3'],
          documentationUrl: 'https://docs.x.ai',
        ),
        baseUrl: 'https://api.x.ai/v1',
        apiFormat: ProviderApiFormat.chatCompletions,
        environmentVariables: <String>['XAI_API_KEY'],
        strictToolSchema: false,
        models: <ProviderCatalogModel>[
          ProviderCatalogModel(
            id: 'grok-4.5',
            label: 'Grok 4.5',
            capabilities: _reasoning,
          ),
          ProviderCatalogModel(
            id: 'grok-4.3',
            label: 'Grok 4.3',
            capabilities: _reasoning,
          ),
        ],
      ),
      ProviderRuntimePreset(
        definition: ProviderDefinitionDto(
          id: 'ollama',
          name: 'Ollama',
          description: 'Local Ollama server.',
          authMethods: <ProviderAuthMethodDto>[_none],
          local: true,
        ),
        baseUrl: 'http://127.0.0.1:11434/v1',
        apiFormat: ProviderApiFormat.chatCompletions,
        environmentVariables: <String>[],
        strictToolSchema: false,
        models: <ProviderCatalogModel>[],
      ),
      ProviderRuntimePreset(
        definition: ProviderDefinitionDto(
          id: 'lmstudio',
          name: 'LM Studio',
          description: 'Local LM Studio server.',
          authMethods: <ProviderAuthMethodDto>[_none],
          local: true,
        ),
        baseUrl: 'http://127.0.0.1:1234/v1',
        apiFormat: ProviderApiFormat.chatCompletions,
        environmentVariables: <String>[],
        strictToolSchema: false,
        models: <ProviderCatalogModel>[],
      ),
      ProviderRuntimePreset(
        definition: ProviderDefinitionDto(
          id: 'vllm',
          name: 'vLLM',
          description: 'Local vLLM OpenAI-compatible server.',
          authMethods: <ProviderAuthMethodDto>[_none],
          local: true,
        ),
        baseUrl: 'http://127.0.0.1:8000/v1',
        apiFormat: ProviderApiFormat.chatCompletions,
        environmentVariables: <String>[],
        strictToolSchema: false,
        models: <ProviderCatalogModel>[],
      ),
    ];

/// Returns bundled capability metadata for one provider model.
ModelCapabilitiesDto catalogCapabilities(String definitionId, String modelId) {
  final preset = builtInProviderPresets
      .where((candidate) => candidate.definition.id == definitionId)
      .firstOrNull;
  return preset?.models
          .where((model) => model.id == modelId)
          .firstOrNull
          ?.capabilities ??
      const ModelCapabilitiesDto();
}
