import 'package:coder_agent/coder_agent.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:coder_provider_openai/src/openai_oauth_gateway.dart';
import 'package:coder_provider_openai/src/wire.dart';
import 'package:dio/dio.dart';

/// A vendor served by an OpenAI-compatible endpoint.
///
/// Everything vendor-specific is data on this class, so a new compatible
/// vendor is a new instance rather than a new code path.
base class OpenAICompatiblePlugin extends ProviderPlugin {
  /// Creates one OpenAI-compatible vendor.
  const OpenAICompatiblePlugin({
    required this.definition,
    required this.baseUrl,
    required this._wire,
    this.environmentVariables = const <String>[],
    this.models = const <ProviderCatalogModel>[],
    this.strictToolSchema = false,
  });

  @override
  final ProviderDefinitionDto definition;

  /// Trusted endpoint compiled into the daemon.
  final String baseUrl;

  /// Whether strict JSON schemas are accepted by this vendor.
  final bool strictToolSchema;

  final OpenAICompatibleWire _wire;

  @override
  final List<String> environmentVariables;

  @override
  final List<ProviderCatalogModel> models;

  @override
  String get id => definition.id;

  @override
  ProviderEndpoint endpoint(ProviderAuthKind authKind) => ProviderEndpoint(
    baseUrl: baseUrl,
    strictToolSchema: strictToolSchema,
  );

  @override
  ModelProvider createProvider(ModelProviderRequest request) =>
      _wire.createProvider(request);

  @override
  Future<List<String>> discoverModels(
    ProviderEndpoint endpoint,
    ProviderCredential? credential,
  ) => _wire.discoverModels(endpoint, credential);
}

/// OpenAI itself: the platform API, plus the ChatGPT subscription backend.
final class OpenAIPlugin extends OpenAICompatiblePlugin {
  /// Creates the OpenAI vendor.
  ///
  /// [_oauth] must come from the composition root so tests can substitute the
  /// gateway while the plugin still owns which backend each credential uses.
  const OpenAIPlugin({
    required this._oauth,
    super.wire = const OpenAIResponsesWire(),
  }) : super(
         definition: openAIDefinition,
         baseUrl: 'https://api.openai.com/v1',
         environmentVariables: const <String>['OPENAI_API_KEY'],
         strictToolSchema: true,
         models: openAIBundledModels,
       );

  final ProviderOAuthGateway _oauth;

  @override
  ProviderOAuthGateway get oauth => _oauth;

  @override
  ProviderEndpoint endpoint(ProviderAuthKind authKind) =>
      authKind == ProviderAuthKind.oauth
      // The subscription backend serves only the Responses API and answers
      // 400 for `/models`, so model identifiers come from the bundled
      // catalog instead of a discovery request.
      ? const ProviderEndpoint(
          baseUrl: 'https://chatgpt.com/backend-api/codex',
          strictToolSchema: true,
          supportsModelDiscovery: false,
        )
      : super.endpoint(authKind);

  @override
  ModelProvider createProvider(ModelProviderRequest request) =>
      _wire.adapterFor(
        request,
        additionalHeaders: <String, String>{
          if (request.credential is OAuthCredential)
            'originator': 'tinyrack_coder',
          if (request.credential case OAuthCredential(:final accountId?))
            'ChatGPT-Account-ID': accountId,
        },
        // The subscription backend serves a narrower Responses surface and
        // answers 400 for the platform-only request fields.
        supportsPlatformRequestFields: request.credential is! OAuthCredential,
      );

  /// The API documents image and file inputs for every current model, which
  /// the public catalog does not record.
  @override
  ModelCapabilitiesDto refineRemoteCapabilities(
    ModelCapabilitiesDto capabilities,
  ) => capabilities.copyWith(
    imageInput: CapabilitySupport.supported,
    fileInput: CapabilitySupport.supported,
  );
}

/// The vendors this package compiles into the daemon, in advertised order.
List<ProviderPlugin> openAIFamilyPlugins({
  required Clock clock,
  ProviderOAuthGateway? openAIOAuth,
  Dio Function(ProviderEndpoint endpoint)? dioFactory,
}) {
  final responses = OpenAIResponsesWire(dioFactory: dioFactory);
  final chatCompletions = OpenAIChatCompletionsWire(dioFactory: dioFactory);
  return <ProviderPlugin>[
    OpenAIPlugin(
      oauth: openAIOAuth ?? OpenAIOAuthGateway(clock: clock),
      wire: responses,
    ),
    OpenAICompatiblePlugin(
      definition: deepseekDefinition,
      baseUrl: 'https://api.deepseek.com',
      wire: chatCompletions,
      environmentVariables: const <String>['DEEPSEEK_API_KEY'],
      models: deepseekBundledModels,
    ),
    OpenAICompatiblePlugin(
      definition: openRouterDefinition,
      baseUrl: 'https://openrouter.ai/api/v1',
      wire: chatCompletions,
      environmentVariables: const <String>['OPENROUTER_API_KEY'],
      models: openRouterBundledModels,
    ),
    OpenAICompatiblePlugin(
      definition: groqDefinition,
      baseUrl: 'https://api.groq.com/openai/v1',
      wire: chatCompletions,
      environmentVariables: const <String>['GROQ_API_KEY'],
      models: groqBundledModels,
    ),
    OpenAICompatiblePlugin(
      definition: xaiDefinition,
      baseUrl: 'https://api.x.ai/v1',
      wire: chatCompletions,
      environmentVariables: const <String>['XAI_API_KEY'],
      models: xaiBundledModels,
    ),
    OpenAICompatiblePlugin(
      definition: ollamaDefinition,
      baseUrl: 'http://127.0.0.1:11434/v1',
      wire: chatCompletions,
    ),
    OpenAICompatiblePlugin(
      definition: lmStudioDefinition,
      baseUrl: 'http://127.0.0.1:1234/v1',
      wire: chatCompletions,
    ),
    OpenAICompatiblePlugin(
      definition: vllmDefinition,
      baseUrl: 'http://127.0.0.1:8000/v1',
      wire: chatCompletions,
    ),
  ];
}

/// The wire protocols this package offers to custom connections.
///
/// Chat Completions first: most custom endpoints are local OpenAI-compatible
/// servers, and the first registered format is what a new custom connection
/// defaults to.
List<ProviderWireProtocol> openAIWireProtocols({
  Dio Function(ProviderEndpoint endpoint)? dioFactory,
}) => <ProviderWireProtocol>[
  OpenAIChatCompletionsWire(dioFactory: dioFactory),
  OpenAIResponsesWire(dioFactory: dioFactory),
];

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

/// Public OpenAI metadata safe to send to clients.
const ProviderDefinitionDto openAIDefinition = ProviderDefinitionDto(
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
  recommendedModelIds: <String>['gpt-5.6-sol', 'gpt-5.6-terra', 'gpt-5.6-luna'],
  documentationUrl: 'https://platform.openai.com/docs',
);

/// Bundled OpenAI coding models.
const List<ProviderCatalogModel> openAIBundledModels = <ProviderCatalogModel>[
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
];

/// Public DeepSeek metadata safe to send to clients.
const ProviderDefinitionDto deepseekDefinition = ProviderDefinitionDto(
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
);

/// Bundled DeepSeek coding models.
const List<ProviderCatalogModel> deepseekBundledModels = <ProviderCatalogModel>[
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
];

/// Public OpenRouter metadata safe to send to clients.
const ProviderDefinitionDto openRouterDefinition = ProviderDefinitionDto(
  id: 'openrouter',
  name: 'OpenRouter',
  description: 'Multi-provider OpenAI-compatible model gateway.',
  authMethods: <ProviderAuthMethodDto>[_apiKey],
  recommendedModelIds: <String>[
    'deepseek/deepseek-v4-flash-0731',
    'qwen/qwen3.7-flash',
  ],
  documentationUrl: 'https://openrouter.ai/docs',
);

/// Bundled OpenRouter coding models.
const List<ProviderCatalogModel> openRouterBundledModels =
    <ProviderCatalogModel>[
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
    ];

/// Public Groq metadata safe to send to clients.
const ProviderDefinitionDto groqDefinition = ProviderDefinitionDto(
  id: 'groq',
  name: 'Groq',
  description: 'Low-latency hosted open models.',
  authMethods: <ProviderAuthMethodDto>[_apiKey],
  recommendedModelIds: <String>['openai/gpt-oss-120b', 'openai/gpt-oss-20b'],
  documentationUrl: 'https://console.groq.com/docs',
);

/// Bundled Groq coding models.
const List<ProviderCatalogModel> groqBundledModels = <ProviderCatalogModel>[
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
];

/// Public xAI metadata safe to send to clients.
const ProviderDefinitionDto xaiDefinition = ProviderDefinitionDto(
  id: 'xai',
  name: 'xAI',
  description: 'xAI Grok hosted models.',
  authMethods: <ProviderAuthMethodDto>[_apiKey],
  recommendedModelIds: <String>['grok-4.5', 'grok-4.3'],
  documentationUrl: 'https://docs.x.ai',
);

/// Bundled xAI coding models.
const List<ProviderCatalogModel> xaiBundledModels = <ProviderCatalogModel>[
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
];

/// Public Ollama metadata safe to send to clients.
const ProviderDefinitionDto ollamaDefinition = ProviderDefinitionDto(
  id: 'ollama',
  name: 'Ollama',
  description: 'Local Ollama server.',
  authMethods: <ProviderAuthMethodDto>[_none],
  local: true,
);

/// Public LM Studio metadata safe to send to clients.
const ProviderDefinitionDto lmStudioDefinition = ProviderDefinitionDto(
  id: 'lmstudio',
  name: 'LM Studio',
  description: 'Local LM Studio server.',
  authMethods: <ProviderAuthMethodDto>[_none],
  local: true,
);

/// Public vLLM metadata safe to send to clients.
const ProviderDefinitionDto vllmDefinition = ProviderDefinitionDto(
  id: 'vllm',
  name: 'vLLM',
  description: 'Local vLLM OpenAI-compatible server.',
  authMethods: <ProviderAuthMethodDto>[_none],
  local: true,
);
