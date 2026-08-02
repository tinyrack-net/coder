import 'package:coder_agent/coder_agent.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:coder_provider_openai/coder_provider_openai.dart';
import 'package:dio/dio.dart';

/// Public API exposed by this library.
abstract interface class ProviderModelDiscovery {
  /// The fetchModelIds public API member.
  Future<List<String>> fetchModelIds(ApiProviderDto provider, String apiKey);
}

/// DioProviderModelDiscovery defines a public contract.
final class DioProviderModelDiscovery implements ProviderModelDiscovery {
  /// Creates a [DioProviderModelDiscovery].
  const DioProviderModelDiscovery();

  @override
  Future<List<String>> fetchModelIds(
    ApiProviderDto provider,
    String apiKey,
  ) async {
    final dio = Dio(BaseOptions(baseUrl: provider.baseUrl));
    try {
      final response = await dio.get<Map<String, dynamic>>(
        '/models',
        options: Options(
          headers: <String, String>{
            if (apiKey.isNotEmpty) 'Authorization': 'Bearer $apiKey',
          },
        ),
      );
      final data = response.data?['data'];
      if (data is! List<dynamic>) {
        throw const FormatException('The /models response has no data list.');
      }
      final ids = <String>[];
      for (final item in data) {
        if (item is! Map<dynamic, dynamic>) continue;
        final id = item['id'];
        if (id is String && id.trim().isNotEmpty) ids.add(id);
      }
      return ids;
    } on DioException catch (error) {
      final message = error.response?.data ?? error.message ?? '$error';
      throw StateError('Model discovery failed: $message');
    }
  }
}

/// Public API exposed by this library.
abstract interface class ModelProviderFactory {
  /// The create public API member.
  ModelProvider create({
    required ApiProviderDto provider,
    required String apiKey,
    required bool supportsReasoningEffort,
  });
}

/// OpenAICompatibleProviderFactory defines a public contract.
final class OpenAICompatibleProviderFactory implements ModelProviderFactory {
  /// Creates a [OpenAICompatibleProviderFactory].
  const OpenAICompatibleProviderFactory();

  @override
  ModelProvider create({
    required ApiProviderDto provider,
    required String apiKey,
    required bool supportsReasoningEffort,
  }) {
    final config = OpenAIProviderConfig(
      id: provider.id,
      apiKey: apiKey,
      baseUrl: provider.baseUrl,
      requiresApiKey: provider.credentialSource != CredentialSource.none,
      supportsReasoningEffort: supportsReasoningEffort,
      strictToolSchema: provider.strictToolSchema,
    );
    return switch (provider.transport) {
      ApiTransport.responses => OpenAIResponsesProvider(config),
      ApiTransport.chatCompletions => OpenAIChatCompletionsProvider(config),
    };
  }
}
