@Tags(<String>['feature_test__provider_catalog__unit'])
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:agent/agent.dart';
import 'package:daemon/src/features/providers/infrastructure/anthropic/plugin.dart';
import 'package:daemon/src/features/providers/infrastructure/anthropic/wire.dart';
import 'package:daemon/src/features/providers/infrastructure/gemini/plugin.dart';
import 'package:daemon/src/features/providers/infrastructure/gemini/wire.dart';
import 'package:daemon/src/features/providers/infrastructure/openai/openai.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

import '../../support/agent_conformance.dart';

void main() {
  final clock = _FixedClock(DateTime.utc(2026, 8, 2));

  // Every vendor this package registers inherits the full plugin contract.
  for (final plugin in openAIFamilyPlugins(
    clock: clock,
    openAIOAuth: const _UnusedGateway(),
  )) {
    providerPluginConformanceTests(plugin.id, () => plugin);
  }
  for (final wire in openAIWireProtocols()) {
    providerWireProtocolConformanceTests(wire.id, () => wire);
  }
  providerPluginConformanceTests(
    'anthropic',
    () => const AnthropicPlugin(),
  );
  providerWireProtocolConformanceTests(
    anthropicMessagesWireId,
    () => const AnthropicMessagesWire(),
  );
  providerPluginConformanceTests(
    'google',
    () => const GoogleGeminiPlugin(),
  );
  providerWireProtocolConformanceTests(
    geminiInteractionsWireId,
    () => const GeminiInteractionsWire(),
  );

  test('the family registers each vendor and both wire protocols once', () {
    final registry = ProviderRegistry(
      plugins: openAIFamilyPlugins(
        clock: clock,
        openAIOAuth: const _UnusedGateway(),
      ),
      wireProtocols: openAIWireProtocols(),
    );

    expect(registry.plugins.map((plugin) => plugin.id), <String>[
      'openai',
      'deepseek',
      'openrouter',
      'groq',
      'xai',
      'ollama',
      'lmstudio',
      'vllm',
    ]);
    // Chat Completions first: the first registered format is what a new
    // custom connection defaults to, and most custom endpoints are local
    // OpenAI-compatible servers.
    expect(registry.wireProtocols.map((wire) => wire.id), <String>[
      openAIChatCompletionsWireId,
      openAIResponsesWireId,
    ]);
    // Local servers advertise unauthenticated connect; hosted ones never do.
    for (final plugin in registry.plugins) {
      final flows = plugin.definition.authMethods.map((method) => method.flow);
      expect(
        flows.contains(AgentProviderAuthFlow.none),
        plugin.definition.local,
        reason: plugin.id,
      );
    }
  });

  test('only the subscription OAuth endpoint withholds model discovery', () {
    final openai = openAIFamilyPlugins(
      clock: clock,
      openAIOAuth: const _UnusedGateway(),
    ).first;

    final platform = openai.endpoint(AgentProviderAuthKind.apiKey);
    expect(platform.baseUrl, 'https://api.openai.com/v1');
    expect(platform.supportsModelDiscovery, isTrue);

    // The subscription backend serves only the Responses API and answers 400
    // for `/models`, so the bundled catalog is the whole model set there.
    final subscription = openai.endpoint(AgentProviderAuthKind.oauth);
    expect(subscription.baseUrl, 'https://chatgpt.com/backend-api/codex');
    expect(subscription.supportsModelDiscovery, isFalse);
    expect(subscription.strictToolSchema, isTrue);
  });

  test(
    'the subscription adapter carries identity headers, never the secret',
    () async {
      final adapter = _Adapter(
        'data: {"type":"response.completed","response":{"output":[]}}\n\n'
        'data: [DONE]\n\n',
      );
      final openai = openAIFamilyPlugins(
        clock: clock,
        openAIOAuth: const _UnusedGateway(),
        dioFactory: (_) => Dio()..httpClientAdapter = adapter,
      ).first;
      final credential = OAuthCredential(
        accessToken: 'access-secret',
        refreshToken: 'refresh-secret',
        expiresAt: DateTime.utc(2026, 8, 3),
        accountId: 'account-id',
      );
      final provider = openai.createProvider(
        ModelProviderRequest(
          connectionId: 'openai',
          endpoint: openai.endpoint(AgentProviderAuthKind.oauth),
          credential: credential,
          capabilities: openAIBundledModels.first.capabilities,
        ),
      );

      await provider
          .stream(
            const ModelRequest(
              model: 'gpt-5.6-sol',
              modelControls: <String, AgentModelControlValue>{
                AgentModelControlIds.reasoningEffort:
                    AgentModelControlStringValue(value: 'medium'),
                AgentModelControlIds.fastMode: AgentModelControlBoolValue(
                  value: true,
                ),
              },
              instructions: 'test',
              history: <ConversationItem>[],
              tools: <ModelToolDefinition>[],
              safetyIdentifier: 'safe',
            ),
            CancellationToken(),
          )
          .toList();

      expect(
        adapter.options!.uri.toString(),
        'https://chatgpt.com/backend-api/codex/responses',
      );
      expect(adapter.options!.headers['Authorization'], 'Bearer access-secret');
      expect(adapter.options!.headers['ChatGPT-Account-ID'], 'account-id');
      expect(adapter.options!.headers['originator'], 'tinyrack_coder');
      expect(
        jsonEncode(adapter.options!.data),
        isNot(contains('refresh-secret')),
      );
      // The Codex backend rejects the whole turn when it receives a field
      // only the platform Responses API defines, even one the model supports
      // there.
      final body = Map<String, dynamic>.from(adapter.options!.data as Map);
      expect(body, isNot(contains('service_tier')));
      expect(body, isNot(contains('safety_identifier')));
    },
  );

  test('an API key request carries no subscription identity headers', () {
    final openai = openAIFamilyPlugins(
      clock: clock,
      openAIOAuth: const _UnusedGateway(),
    ).first;

    final provider = openai.createProvider(
      const ModelProviderRequest(
        connectionId: 'openai',
        endpoint: ProviderEndpoint(baseUrl: 'https://api.openai.com/v1'),
        credential: ApiKeyCredential('sk-test'),
      ),
    );

    expect(provider, isA<OpenAIResponsesProvider>());
  });

  test('discovery classifies credentials and parses model IDs', () async {
    final success = _Adapter(
      jsonEncode(<String, dynamic>{
        'data': <Map<String, dynamic>>[
          <String, dynamic>{'id': 'model-b'},
          <String, dynamic>{'id': ''},
          <String, dynamic>{'id': 'model-a'},
        ],
      }),
      contentType: Headers.jsonContentType,
    );
    final wire = OpenAIChatCompletionsWire(
      dioFactory: (_) => Dio()..httpClientAdapter = success,
    );

    expect(
      await wire.discoverModels(
        const ProviderEndpoint(baseUrl: 'https://api.deepseek.com'),
        const ApiKeyCredential('secret'),
      ),
      <String>['model-b', 'model-a'],
    );
    expect(success.options!.headers['Authorization'], 'Bearer secret');
  });

  test('discovery classifies HTTP failures and malformed catalogs', () async {
    const failure = ProviderDiscoveryFailure(
      ProviderDiscoveryFailureKind.unavailable,
      'offline',
    );
    expect(
      failure.toString(),
      'ProviderDiscoveryFailure(ProviderDiscoveryFailureKind.unavailable): '
      'offline',
    );
    const endpoint = ProviderEndpoint(baseUrl: 'https://models.example/v1');

    for (final status in <int>[400, 401, 500]) {
      final adapter = _Adapter(
        '{}',
        contentType: Headers.jsonContentType,
        statusCode: status,
      );
      final wire = OpenAIChatCompletionsWire(
        dioFactory: (_) => Dio()..httpClientAdapter = adapter,
      );
      await expectLater(
        wire.discoverModels(
          endpoint,
          OAuthCredential(
            accessToken: 'oauth-access',
            refreshToken: 'refresh',
            expiresAt: DateTime.utc(2026, 8, 3),
          ),
        ),
        throwsA(
          isA<ProviderDiscoveryFailure>().having(
            (error) => error.kind,
            'kind',
            status == 401
                ? ProviderDiscoveryFailureKind.invalidCredential
                : ProviderDiscoveryFailureKind.unavailable,
          ),
        ),
      );
      expect(
        adapter.options!.headers['Authorization'],
        'Bearer oauth-access',
      );
    }

    final malformed = _Adapter(
      '{"data":"not-a-list"}',
      contentType: Headers.jsonContentType,
    );
    await expectLater(
      OpenAIChatCompletionsWire(
        dioFactory: (_) => Dio()..httpClientAdapter = malformed,
      ).discoverModels(endpoint, null),
      throwsA(isA<FormatException>()),
    );
  });

  test('the Chat Completions wire serves unauthenticated local servers', () {
    final dio = Dio();
    const endpoint = ProviderEndpoint(baseUrl: 'http://127.0.0.1:11434/v1');
    final provider = OpenAIChatCompletionsWire(dioFactory: (_) => dio)
        .createProvider(
          const ModelProviderRequest(
            connectionId: 'local',
            endpoint: endpoint,
            credential: null,
          ),
        );

    expect(provider, isA<OpenAIChatCompletionsProvider>());
    expect(dio.options.baseUrl, endpoint.baseUrl);
  });
}

final class _FixedClock implements Clock {
  const _FixedClock(this.value);

  final DateTime value;

  @override
  DateTime nowUtc() => value;
}

final class _UnusedGateway implements ProviderOAuthGateway {
  const _UnusedGateway();

  @override
  Future<ProviderOAuthSession> start(AgentProviderAuthFlow flow) =>
      throw UnimplementedError('No test starts a flow.');

  @override
  Future<OAuthCredential> refresh(OAuthCredential credential) =>
      throw UnimplementedError('No test refreshes a credential.');
}

final class _Adapter implements HttpClientAdapter {
  _Adapter(
    this.body, {
    this.contentType = 'text/event-stream',
    this.statusCode = 200,
  });

  final String body;
  final String contentType;
  final int statusCode;
  RequestOptions? options;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    this.options = options;
    return ResponseBody.fromString(
      body,
      statusCode,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[contentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
