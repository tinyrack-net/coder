import 'package:coder_agent/coder_agent.dart';
import 'package:coder_daemon/src/repositories.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:coder_provider_openai/coder_provider_openai.dart';
import 'package:dio/dio.dart';

/// Trusted runtime configuration resolved inside the daemon.
final class ProviderRuntimeConfig {
  /// Creates provider runtime configuration.
  const ProviderRuntimeConfig({
    required this.id,
    required this.definitionId,
    required this.baseUrl,
    required this.apiFormat,
    required this.strictToolSchema,
    this.supportsModelDiscovery = true,
    this.supportsPlatformRequestFields = true,
  });

  /// Connection identifier exposed to the agent runtime.
  final String id;

  /// Catalog definition identifier, or `custom`.
  final String definitionId;

  /// Trusted endpoint used by the transport adapter.
  final String baseUrl;

  /// OpenAI-compatible API format.
  final ProviderApiFormat apiFormat;

  /// Whether the endpoint exposes an OpenAI-compatible `/models` listing.
  ///
  /// The ChatGPT subscription backend serves only the Responses API, so model
  /// identifiers come from the bundled catalog instead of a discovery request.
  final bool supportsModelDiscovery;

  /// Whether the endpoint supports strict tool schemas.
  final bool strictToolSchema;

  /// Whether the endpoint accepts the platform-only Responses request fields.
  ///
  /// `service_tier` and `safety_identifier` are documented for
  /// platform.openai.com. The ChatGPT subscription backend serves a narrower
  /// Responses surface and answers 400 for a request that carries either, so
  /// the model capability alone cannot decide whether to send them.
  final bool supportsPlatformRequestFields;
}

/// Classifies model discovery failures without leaking transport exceptions.
enum ProviderDiscoveryFailureKind {
  /// The supplied credential was rejected.
  invalidCredential,

  /// Discovery is temporarily or permanently unavailable.
  unavailable,
}

/// Typed failure returned by a provider model discovery adapter.
final class ProviderDiscoveryFailure implements Exception {
  /// Creates a discovery failure.
  const ProviderDiscoveryFailure(this.kind, this.message);

  /// Stable failure classification.
  final ProviderDiscoveryFailureKind kind;

  /// User-safe diagnostic message.
  final String message;

  @override
  String toString() => 'ProviderDiscoveryFailure($kind): $message';
}

/// Discovers model identifiers from an OpenAI-compatible endpoint.
abstract interface class ProviderModelDiscovery {
  /// Fetches model identifiers for one provider connection.
  Future<List<String>> fetchModelIds(
    ProviderRuntimeConfig config,
    ProviderCredential? credential,
  );
}

/// DioProviderModelDiscovery defines a public contract.
final class DioProviderModelDiscovery implements ProviderModelDiscovery {
  /// Creates a [DioProviderModelDiscovery].
  const DioProviderModelDiscovery({this.dioFactory});

  /// Injectable HTTP client factory used by deterministic contract tests.
  final Dio Function(ProviderRuntimeConfig config)? dioFactory;

  @override
  Future<List<String>> fetchModelIds(
    ProviderRuntimeConfig config,
    ProviderCredential? credential,
  ) async {
    final dio =
        dioFactory?.call(config) ?? Dio(BaseOptions(baseUrl: config.baseUrl));
    if (dio.options.baseUrl.isEmpty) dio.options.baseUrl = config.baseUrl;
    try {
      final response = await dio.get<Map<String, dynamic>>(
        '/models',
        options: Options(
          headers: <String, String>{
            if (credential case ApiKeyCredential(:final key))
              'Authorization': 'Bearer $key',
            if (credential case OAuthCredential(:final accessToken))
              'Authorization': 'Bearer $accessToken',
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
      final statusCode = error.response?.statusCode;
      final message = error.message ?? 'Provider model discovery failed.';
      if (statusCode == 401 || statusCode == 403) {
        throw ProviderDiscoveryFailure(
          ProviderDiscoveryFailureKind.invalidCredential,
          message,
        );
      }
      throw ProviderDiscoveryFailure(
        ProviderDiscoveryFailureKind.unavailable,
        message,
      );
    }
  }
}

/// Creates a model provider from trusted runtime data and secret credentials.
abstract interface class ModelProviderFactory {
  /// Creates a provider adapter for one connected provider.
  ModelProvider create({
    required ProviderRuntimeConfig config,
    required ProviderCredential? credential,
    required bool supportsReasoningEffort,
    required bool supportsImageInput,
    required bool supportsFileInput,
    required bool supportsServiceTier,
  });
}

/// OpenAICompatibleProviderFactory defines a public contract.
final class OpenAICompatibleProviderFactory implements ModelProviderFactory {
  /// Creates a [OpenAICompatibleProviderFactory].
  const OpenAICompatibleProviderFactory({this.dioFactory});

  /// Injectable HTTP client factory used by deterministic contract tests.
  final Dio Function(ProviderRuntimeConfig config)? dioFactory;

  @override
  ModelProvider create({
    required ProviderRuntimeConfig config,
    required ProviderCredential? credential,
    required bool supportsReasoningEffort,
    required bool supportsImageInput,
    required bool supportsFileInput,
    required bool supportsServiceTier,
  }) {
    final apiKey = switch (credential) {
      ApiKeyCredential(:final key) => key,
      OAuthCredential(:final accessToken) => accessToken,
      null => '',
    };
    final providerConfig = OpenAIProviderConfig(
      id: config.id,
      apiKey: apiKey,
      baseUrl: config.baseUrl,
      requiresApiKey: credential != null,
      supportsReasoningEffort: supportsReasoningEffort,
      supportsImageInput: supportsImageInput,
      supportsFileInput: supportsFileInput,
      supportsServiceTier:
          supportsServiceTier && config.supportsPlatformRequestFields,
      supportsSafetyIdentifier: config.supportsPlatformRequestFields,
      strictToolSchema: config.strictToolSchema,
      additionalHeaders: <String, String>{
        if (credential is OAuthCredential) 'originator': 'tinyrack_coder',
        if (credential case OAuthCredential(:final accountId?))
          'ChatGPT-Account-ID': accountId,
      },
    );
    final dio = dioFactory?.call(config);
    if (dio != null && dio.options.baseUrl.isEmpty) {
      dio.options.baseUrl = config.baseUrl;
    }
    return switch (config.apiFormat) {
      ProviderApiFormat.responses => OpenAIResponsesProvider(
        providerConfig,
        dio: dio,
      ),
      ProviderApiFormat.chatCompletions => OpenAIChatCompletionsProvider(
        providerConfig,
        dio: dio,
      ),
    };
  }
}
