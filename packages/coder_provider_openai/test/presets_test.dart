import 'package:coder_protocol/coder_protocol.dart';
import 'package:coder_provider_openai/coder_provider_openai.dart';
import 'package:test/test.dart';

void main() {
  test('built-in catalog exposes every supported service', () {
    expect(
      builtInProviderPresets.map((preset) => preset.definition.id),
      <String>[
        'openai',
        'deepseek',
        'openrouter',
        'groq',
        'xai',
        'ollama',
        'lmstudio',
        'vllm',
      ],
    );
  });

  test(
    'DeepSeek keeps endpoint details internal and needs only an API key',
    () {
      final preset = builtInProviderPresets.singleWhere(
        (item) => item.definition.id == 'deepseek',
      );

      expect(preset.definition.name, 'DeepSeek');
      expect(preset.definition.authMethods, const <ProviderAuthMethodDto>[
        ProviderAuthMethodDto(
          id: 'api-key',
          label: 'API key',
          kind: ProviderAuthKind.apiKey,
          flow: ProviderAuthFlow.apiKey,
        ),
      ]);
      expect(preset.baseUrl, 'https://api.deepseek.com');
      expect(preset.apiFormat, ProviderApiFormat.chatCompletions);
      expect(preset.environmentVariables, <String>['DEEPSEEK_API_KEY']);
      expect(preset.strictToolSchema, isFalse);
      expect(
        preset.models.map((model) => model.id),
        containsAll(<String>['deepseek-v4-pro', 'deepseek-v4-flash']),
      );
    },
  );

  test('public definitions never serialize runtime endpoint configuration', () {
    final definition = builtInProviderPresets.first.definition.toJson();

    expect(definition, isNot(contains('baseUrl')));
    expect(definition, isNot(contains('apiFormat')));
    expect(definition, isNot(contains('environmentVariables')));
    expect(definition, isNot(contains('strictToolSchema')));
  });

  test('OpenAI offers experimental ChatGPT auth and platform API key', () {
    final definition = builtInProviderPresets.first.definition;

    expect(
      definition.authMethods.map((method) => method.flow),
      <ProviderAuthFlow>[
        ProviderAuthFlow.oauthBrowser,
        ProviderAuthFlow.oauthDevice,
        ProviderAuthFlow.apiKey,
      ],
    );
    expect(
      definition.authMethods.take(2).every((method) => method.experimental),
      isTrue,
    );
    expect(definition.authMethods.last.experimental, isFalse);
    expect(
      builtInProviderPresets.first.models.first.capabilities,
      const ModelCapabilitiesDto(
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
      ),
    );
  });
}
