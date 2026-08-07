import 'package:coder_agent/coder_agent.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:coder_provider_openai/src/chat_completions_provider.dart';
import 'package:coder_provider_openai/src/openai_provider.dart';
import 'package:dio/dio.dart';

/// Wire protocol identifier of the OpenAI Responses API.
const String openAIResponsesWireId = 'openai-responses';

/// Wire protocol identifier of the OpenAI Chat Completions API.
const String openAIChatCompletionsWireId = 'openai-chat-completions';

/// Shared transport behaviour of the two OpenAI-compatible wire protocols.
///
/// Both authenticate with a bearer token and list models on `/models`; they
/// differ only in the streaming endpoint the adapter speaks.
abstract base class OpenAICompatibleWire implements ProviderWireProtocol {
  /// Allows subclasses to be const.
  const OpenAICompatibleWire({this.dioFactory});

  /// Injectable HTTP client factory used by deterministic contract tests.
  final Dio Function(ProviderEndpoint endpoint)? dioFactory;

  @override
  ModelProvider createProvider(ModelProviderRequest request) =>
      adapterFor(request);

  /// Builds the adapter, letting a vendor add its own non-secret headers.
  ///
  /// [supportsPlatformRequestFields] gates `service_tier` and
  /// `safety_identifier`: they are documented for platform.openai.com, and a
  /// narrower compatible surface answers 400 for a request carrying either,
  /// so the model capability alone cannot decide whether to send them.
  ModelProvider adapterFor(
    ModelProviderRequest request, {
    Map<String, String> additionalHeaders = const <String, String>{},
    bool supportsPlatformRequestFields = true,
  }) {
    final credential = request.credential;
    final capabilities = request.capabilities;
    final config = OpenAIProviderConfig(
      id: request.connectionId,
      apiKey: switch (credential) {
        ApiKeyCredential(:final key) => key,
        OAuthCredential(:final accessToken) => accessToken,
        null => '',
      },
      baseUrl: request.endpoint.baseUrl,
      requiresApiKey: credential != null,
      supportsReasoningEffort:
          capabilities.reasoningEffort == CapabilitySupport.supported,
      supportsImageInput:
          capabilities.imageInput == CapabilitySupport.supported,
      supportsFileInput: capabilities.fileInput == CapabilitySupport.supported,
      supportsServiceTier:
          capabilities.serviceTier == CapabilitySupport.supported &&
          supportsPlatformRequestFields,
      supportsSafetyIdentifier: supportsPlatformRequestFields,
      strictToolSchema: request.endpoint.strictToolSchema,
      additionalHeaders: additionalHeaders,
    );
    final dio = dioFactory?.call(request.endpoint);
    if (dio != null && dio.options.baseUrl.isEmpty) {
      dio.options.baseUrl = request.endpoint.baseUrl;
    }
    return buildAdapter(config, dio);
  }

  /// Builds the concrete adapter of this wire protocol.
  ModelProvider buildAdapter(OpenAIProviderConfig config, Dio? dio);

  @override
  Future<List<String>> discoverModels(
    ProviderEndpoint endpoint,
    ProviderCredential? credential,
  ) async {
    final dio =
        dioFactory?.call(endpoint) ??
        Dio(BaseOptions(baseUrl: endpoint.baseUrl));
    if (dio.options.baseUrl.isEmpty) dio.options.baseUrl = endpoint.baseUrl;
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

/// The OpenAI Responses streaming API.
final class OpenAIResponsesWire extends OpenAICompatibleWire {
  /// Creates the Responses wire protocol.
  const OpenAIResponsesWire({super.dioFactory});

  @override
  String get id => openAIResponsesWireId;

  @override
  String get label => 'OpenAI Responses';

  @override
  ModelProvider buildAdapter(OpenAIProviderConfig config, Dio? dio) =>
      OpenAIResponsesProvider(config, dio: dio);
}

/// The OpenAI Chat Completions streaming API.
final class OpenAIChatCompletionsWire extends OpenAICompatibleWire {
  /// Creates the Chat Completions wire protocol.
  const OpenAIChatCompletionsWire({super.dioFactory});

  @override
  String get id => openAIChatCompletionsWireId;

  @override
  String get label => 'OpenAI Chat Completions';

  @override
  ModelProvider buildAdapter(OpenAIProviderConfig config, Dio? dio) =>
      OpenAIChatCompletionsProvider(config, dio: dio);
}
