import 'package:coder_protocol/coder_protocol.dart';
import 'package:coder_provider_openai/coder_provider_openai.dart';
import 'package:test/test.dart';

void main() {
  test('DeepSeek preset uses the official Chat Completions endpoint', () {
    final preset = openAICompatiblePresets.singleWhere(
      (item) => item.id == 'deepseek',
    );

    expect(preset.name, 'DeepSeek');
    expect(preset.defaultBaseUrl, 'https://api.deepseek.com');
    expect(preset.defaultTransport, ApiTransport.chatCompletions);
    expect(preset.defaultCredentialSource, CredentialSource.environment);
    expect(preset.defaultEnvironmentVariable, 'DEEPSEEK_API_KEY');
    expect(preset.defaultModelId, 'deepseek-v4-pro');
    expect(preset.modelIds, <String>['deepseek-v4-pro', 'deepseek-v4-flash']);
    expect(preset.strictToolSchema, isFalse);
  });

  test('DeepSeek V4 preset models support agent capabilities', () {
    for (final model in <String>['deepseek-v4-pro', 'deepseek-v4-flash']) {
      final capabilities = presetCapabilities('deepseek', model);
      expect(capabilities.streaming, CapabilitySupport.supported);
      expect(capabilities.toolCalling, CapabilitySupport.supported);
      expect(capabilities.reasoningEffort, CapabilitySupport.supported);
      expect(capabilities.source, CapabilitySource.preset);
    }
    expect(
      presetCapabilities('deepseek', 'unknown').source,
      CapabilitySource.unknown,
    );
  });
}
