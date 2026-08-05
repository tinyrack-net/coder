import 'dart:convert';
import 'dart:typed_data';

import 'package:coder_agent/coder_agent.dart';
import 'package:coder_daemon/src/provider_adapters.dart';
import 'package:coder_daemon/src/repositories.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:coder_provider_openai/coder_provider_openai.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

void main() {
  test(
    'ChatGPT runtime targets Codex Responses with required identity headers',
    () async {
      final adapter = _Adapter(
        'data: {"type":"response.completed","response":{"output":[]}}\n\n'
        'data: [DONE]\n\n',
      );
      final factory = OpenAICompatibleProviderFactory(
        dioFactory: (_) => Dio()..httpClientAdapter = adapter,
      );
      final provider = factory.create(
        config: const ProviderRuntimeConfig(
          id: 'openai',
          definitionId: 'openai',
          baseUrl: 'https://chatgpt.com/backend-api/codex',
          apiFormat: ProviderApiFormat.responses,
          strictToolSchema: true,
        ),
        credential: OAuthCredential(
          accessToken: 'access-secret',
          refreshToken: 'refresh-secret',
          expiresAt: DateTime.utc(2026, 8, 3),
          accountId: 'account-id',
        ),
        supportsReasoningEffort: true,
        supportsImageInput: true,
        supportsFileInput: true,
      );

      await provider
          .stream(
            const ModelRequest(
              model: 'gpt-5.6-sol',
              reasoningEffort: 'medium',
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
    },
  );

  test('model discovery classifies credentials and parses model IDs', () async {
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
    final discovery = DioProviderModelDiscovery(
      dioFactory: (_) => Dio()..httpClientAdapter = success,
    );

    expect(
      await discovery.fetchModelIds(
        const ProviderRuntimeConfig(
          id: 'deepseek',
          definitionId: 'deepseek',
          baseUrl: 'https://api.deepseek.com',
          apiFormat: ProviderApiFormat.chatCompletions,
          strictToolSchema: false,
        ),
        const ApiKeyCredential('secret'),
      ),
      <String>['model-b', 'model-a'],
    );
    expect(success.options!.headers['Authorization'], 'Bearer secret');
  });

  test(
    'model discovery classifies HTTP failures and malformed catalogs',
    () async {
      const failure = ProviderDiscoveryFailure(
        ProviderDiscoveryFailureKind.unavailable,
        'offline',
      );
      expect(
        failure.toString(),
        'ProviderDiscoveryFailure(ProviderDiscoveryFailureKind.unavailable): '
        'offline',
      );
      const config = ProviderRuntimeConfig(
        id: 'custom',
        definitionId: 'custom',
        baseUrl: 'https://models.example/v1',
        apiFormat: ProviderApiFormat.chatCompletions,
        strictToolSchema: false,
      );

      for (final status in <int>[401, 500]) {
        final adapter = _Adapter(
          '{}',
          contentType: Headers.jsonContentType,
          statusCode: status,
        );
        final discovery = DioProviderModelDiscovery(
          dioFactory: (_) => Dio()..httpClientAdapter = adapter,
        );
        await expectLater(
          discovery.fetchModelIds(
            config,
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
        DioProviderModelDiscovery(
          dioFactory: (_) => Dio()..httpClientAdapter = malformed,
        ).fetchModelIds(config, null),
        throwsA(isA<FormatException>()),
      );
    },
  );

  test('provider factory selects Chat Completions without credentials', () {
    const config = ProviderRuntimeConfig(
      id: 'local',
      definitionId: 'ollama',
      baseUrl: 'http://127.0.0.1:11434/v1',
      apiFormat: ProviderApiFormat.chatCompletions,
      strictToolSchema: false,
    );
    final dio = Dio();
    final provider =
        OpenAICompatibleProviderFactory(
          dioFactory: (_) => dio,
        ).create(
          config: config,
          credential: null,
          supportsReasoningEffort: false,
          supportsImageInput: false,
          supportsFileInput: false,
        );

    expect(provider, isA<OpenAIChatCompletionsProvider>());
    expect(dio.options.baseUrl, config.baseUrl);
  });
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
