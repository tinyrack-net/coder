import 'package:coder_protocol/coder_protocol.dart';

const List<ProviderPresetDto> openAICompatiblePresets = <ProviderPresetDto>[
  ProviderPresetDto(
    id: 'openai',
    name: 'OpenAI',
    defaultBaseUrl: 'https://api.openai.com/v1',
    defaultTransport: ApiTransport.responses,
    defaultCredentialSource: CredentialSource.environment,
    defaultEnvironmentVariable: 'OPENAI_API_KEY',
    strictToolSchema: true,
    defaultModelId: 'gpt-5.6-sol',
    modelIds: <String>['gpt-5.6-sol', 'gpt-5.6-terra', 'gpt-5.6-luna'],
  ),
  ProviderPresetDto(
    id: 'openrouter',
    name: 'OpenRouter',
    defaultBaseUrl: 'https://openrouter.ai/api/v1',
    defaultTransport: ApiTransport.chatCompletions,
    defaultCredentialSource: CredentialSource.stored,
    strictToolSchema: false,
  ),
  ProviderPresetDto(
    id: 'groq',
    name: 'Groq',
    defaultBaseUrl: 'https://api.groq.com/openai/v1',
    defaultTransport: ApiTransport.chatCompletions,
    defaultCredentialSource: CredentialSource.stored,
    strictToolSchema: false,
  ),
  ProviderPresetDto(
    id: 'deepseek',
    name: 'DeepSeek',
    defaultBaseUrl: 'https://api.deepseek.com',
    defaultTransport: ApiTransport.chatCompletions,
    defaultCredentialSource: CredentialSource.environment,
    defaultEnvironmentVariable: 'DEEPSEEK_API_KEY',
    strictToolSchema: false,
    defaultModelId: 'deepseek-v4-pro',
    modelIds: <String>['deepseek-v4-pro', 'deepseek-v4-flash'],
  ),
  ProviderPresetDto(
    id: 'ollama',
    name: 'Ollama',
    defaultBaseUrl: 'http://127.0.0.1:11434/v1',
    defaultTransport: ApiTransport.chatCompletions,
    defaultCredentialSource: CredentialSource.none,
    strictToolSchema: false,
  ),
  ProviderPresetDto(
    id: 'lmstudio',
    name: 'LM Studio',
    defaultBaseUrl: 'http://127.0.0.1:1234/v1',
    defaultTransport: ApiTransport.chatCompletions,
    defaultCredentialSource: CredentialSource.none,
    strictToolSchema: false,
  ),
  ProviderPresetDto(
    id: 'vllm',
    name: 'vLLM',
    defaultBaseUrl: 'http://127.0.0.1:8000/v1',
    defaultTransport: ApiTransport.chatCompletions,
    defaultCredentialSource: CredentialSource.none,
    strictToolSchema: false,
  ),
  ProviderPresetDto(
    id: 'custom',
    name: 'Custom OpenAI Compatible',
    defaultBaseUrl: 'http://127.0.0.1:8000/v1',
    defaultTransport: ApiTransport.chatCompletions,
    defaultCredentialSource: CredentialSource.stored,
    strictToolSchema: false,
  ),
];

ModelCapabilitiesDto presetCapabilities(String presetId, String model) {
  if (presetId == 'openai') {
    final reasoning = model.startsWith('gpt-5') || model.startsWith('o');
    return ModelCapabilitiesDto(
      streaming: CapabilitySupport.supported,
      toolCalling: CapabilitySupport.supported,
      reasoningEffort: reasoning
          ? CapabilitySupport.supported
          : CapabilitySupport.unsupported,
      supportedReasoningEfforts: reasoning
          ? const <String>['none', 'low', 'medium', 'high', 'xhigh']
          : const <String>[],
      source: CapabilitySource.preset,
    );
  }
  if (presetId == 'deepseek' &&
      (model == 'deepseek-v4-pro' || model == 'deepseek-v4-flash')) {
    return const ModelCapabilitiesDto(
      streaming: CapabilitySupport.supported,
      toolCalling: CapabilitySupport.supported,
      reasoningEffort: CapabilitySupport.supported,
      supportedReasoningEfforts: <String>['high', 'max'],
      source: CapabilitySource.preset,
    );
  }
  return const ModelCapabilitiesDto();
}
