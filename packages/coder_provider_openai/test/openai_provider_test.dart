import 'dart:typed_data';

import 'package:coder_agent/coder_agent.dart';
import 'package:coder_provider_openai/coder_provider_openai.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

void main() {
  test(
    'Responses maps hydrated image and document attachments to content parts',
    tags: const <String>['feature_test__conversation_attachments__unit'],
    () async {
      final adapter = _RecordingAdapter('''
data: {"type":"response.completed","response":{"output":[{"type":"message","role":"assistant","content":[{"type":"output_text","text":"ok"}]}],"usage":{}}}

data: [DONE]

''');
      final dio = Dio()..httpClientAdapter = adapter;
      final provider = OpenAIResponsesProvider(
        const OpenAIProviderConfig(apiKey: 'secret-test-key'),
        dio: dio,
      );
      await provider
          .stream(
            ModelRequest(
              model: 'gpt-5.6-sol',
              reasoningEffort: 'medium',
              instructions: 'test',
              history: <ConversationItem>[
                UserConversationItem(
                  'inspect these',
                  attachments: <ConversationAttachment>[
                    ConversationAttachment(
                      id: 'image',
                      fileName: 'diagram.png',
                      mimeType: 'image/png',
                      byteSize: 3,
                      path: '/attachments/image.blob',
                      bytes: Uint8List.fromList(<int>[1, 2, 3]),
                    ),
                    ConversationAttachment(
                      id: 'document',
                      fileName: 'notes.txt',
                      mimeType: 'text/plain',
                      byteSize: 2,
                      path: '/attachments/document.blob',
                      bytes: Uint8List.fromList(<int>[4, 5]),
                    ),
                    const ConversationAttachment(
                      id: 'archive',
                      fileName: 'source.zip',
                      mimeType: 'application/zip',
                      byteSize: 12,
                      path: '/attachments/archive.blob',
                    ),
                  ],
                ),
              ],
              tools: const <ModelToolDefinition>[],
              safetyIdentifier: 'safe-user',
            ),
            CancellationToken(),
          )
          .toList();

      final body = Map<String, dynamic>.from(adapter.options!.data as Map);
      final input = (body['input'] as List).single as Map;
      final content = input['content']! as List;
      expect(
        content,
        contains(
          equals(<String, dynamic>{
            'type': 'input_image',
            'image_url': 'data:image/png;base64,AQID',
            'detail': 'auto',
          }),
        ),
      );
      expect(
        content,
        contains(
          equals(<String, dynamic>{
            'type': 'input_text',
            'text':
                '[Attachment id=archive, file=source.zip, '
                'mime=application/zip, bytes=12, '
                'path=/attachments/archive.blob. '
                'Use read_attachment with the attachment id.]',
          }),
        ),
      );
      expect(
        content,
        contains(
          equals(<String, dynamic>{
            'type': 'input_file',
            'filename': 'notes.txt',
            'file_data': 'data:text/plain;base64,BAU=',
          }),
        ),
      );
    },
  );

  test(
    'Responses request is stateless, strict, sequential, '
    'and preserves output items',
    () async {
      final adapter = _RecordingAdapter('''
data: {"type":"response.output_text.delta","delta":"hello"}

data: {"type":"response.completed","response":{"output":[{"type":"reasoning","encrypted_content":"opaque"},{"type":"message","role":"assistant","content":[{"type":"output_text","text":"hello"}]}],"usage":{"input_tokens":2,"output_tokens":1}}}

data: [DONE]

''');
      final dio = Dio()..httpClientAdapter = adapter;
      final provider = OpenAIResponsesProvider(
        const OpenAIProviderConfig(apiKey: 'secret-test-key'),
        dio: dio,
      );
      final events = await provider
          .stream(
            const ModelRequest(
              model: 'gpt-5.6-sol',
              reasoningEffort: 'medium',
              instructions: 'test',
              history: <ConversationItem>[],
              tools: <ModelToolDefinition>[
                ModelToolDefinition(
                  name: 'read_file',
                  description: 'read',
                  parameters: <String, dynamic>{
                    'type': 'object',
                    'properties': <String, dynamic>{
                      'path': <String, dynamic>{'type': 'string'},
                    },
                    'required': <String>['path'],
                    'additionalProperties': false,
                  },
                ),
              ],
              safetyIdentifier: 'safe-user',
            ),
            CancellationToken(),
          )
          .toList();

      final body = Map<String, dynamic>.from(adapter.options!.data as Map);
      expect(body['store'], isFalse);
      expect(body['stream'], isTrue);
      expect(body['parallel_tool_calls'], isFalse);
      expect(body['model'], 'gpt-5.6-sol');
      expect(body['reasoning'], <String, dynamic>{'effort': 'medium'});
      expect(body['include'], contains('reasoning.encrypted_content'));
      expect((body['tools'] as List).single, containsPair('strict', true));
      expect(
        adapter.options!.headers['Authorization'],
        'Bearer secret-test-key',
      );
      expect(events.whereType<ModelTextDelta>().single.delta, 'hello');
      final completed = events.whereType<ModelResponseCompleted>().single;
      expect(
        completed.assistant.opaqueItems.first['encrypted_content'],
        'opaque',
      );
      expect(completed.usage['output_tokens'], 1);
    },
  );

  test('the service tier is sent only when the model supports it', () async {
    Future<Map<String, dynamic>> body({
      required bool supportsServiceTier,
      required String? serviceTier,
    }) async {
      final adapter = _RecordingAdapter('''
data: {"type":"response.completed","response":{"output":[],"usage":{}}}

data: [DONE]

''');
      final provider = OpenAIResponsesProvider(
        OpenAIProviderConfig(
          apiKey: 'secret-test-key',
          supportsServiceTier: supportsServiceTier,
        ),
        dio: Dio()..httpClientAdapter = adapter,
      );
      await provider
          .stream(
            ModelRequest(
              model: 'gpt-5.6-sol',
              reasoningEffort: 'medium',
              serviceTier: serviceTier,
              instructions: 'test',
              history: const <ConversationItem>[],
              tools: const <ModelToolDefinition>[],
              safetyIdentifier: 'safe-user',
            ),
            CancellationToken(),
          )
          .toList();
      return Map<String, dynamic>.from(adapter.options!.data as Map);
    }

    expect(
      await body(supportsServiceTier: true, serviceTier: 'priority'),
      containsPair('service_tier', 'priority'),
    );
    // An unsupported model must never receive the field, because endpoints
    // that do not know it reject the whole request.
    expect(
      await body(supportsServiceTier: false, serviceTier: 'priority'),
      isNot(contains('service_tier')),
    );
    expect(
      await body(supportsServiceTier: true, serviceTier: null),
      isNot(contains('service_tier')),
    );
  });

  test('an empty API key fails before opening a connection', () async {
    final provider = OpenAIResponsesProvider(
      const OpenAIProviderConfig(),
    );
    expect(
      provider
          .stream(
            const ModelRequest(
              model: 'gpt-5.6-sol',
              reasoningEffort: 'medium',
              instructions: 'test',
              history: <ConversationItem>[],
              tools: <ModelToolDefinition>[],
              safetyIdentifier: 'safe-user',
            ),
            CancellationToken(),
          )
          .toList(),
      throwsA(isA<OpenAIProviderException>()),
    );
  });

  test('Chat Completions assembles text and fragmented tool calls', () async {
    final adapter = _RecordingAdapter(r'''
data: {"choices":[{"index":0,"delta":{"content":"hello "}}]}

data: {"choices":[{"index":0,"delta":{"tool_calls":[{"index":0,"id":"call-1","function":{"name":"read_","arguments":"{\"path\":"}}]}}]}

data: {"choices":[{"index":0,"delta":{"tool_calls":[{"index":0,"function":{"name":"file","arguments":"\"README.md\"}"}}]},"finish_reason":"tool_calls"}]}

data: {"choices":[],"usage":{"prompt_tokens":4,"completion_tokens":3,"total_tokens":7}}

data: [DONE]

''');
    final dio = Dio()..httpClientAdapter = adapter;
    final provider = OpenAIChatCompletionsProvider(
      const OpenAIProviderConfig(
        id: 'compatible',
        requiresApiKey: false,
        supportsReasoningEffort: false,
        strictToolSchema: false,
      ),
      dio: dio,
    );
    final events = await provider
        .stream(
          const ModelRequest(
            model: 'local-model',
            reasoningEffort: 'medium',
            instructions: 'test',
            history: <ConversationItem>[
              UserConversationItem('inspect'),
              AssistantConversationItem(text: 'earlier'),
            ],
            tools: <ModelToolDefinition>[
              ModelToolDefinition(
                name: 'read_file',
                description: 'read',
                parameters: <String, dynamic>{
                  'type': 'object',
                  'properties': <String, dynamic>{
                    'path': <String, dynamic>{'type': 'string'},
                  },
                  'required': <String>['path'],
                  'additionalProperties': false,
                },
              ),
            ],
            safetyIdentifier: 'safe-user',
          ),
          CancellationToken(),
        )
        .toList();

    final body = Map<String, dynamic>.from(adapter.options!.data as Map);
    expect(body['stream'], isTrue);
    expect(body, isNot(contains('reasoning_effort')));
    expect((body['messages'] as List)[1], <String, dynamic>{
      'role': 'user',
      'content': 'inspect',
    });
    expect(events.whereType<ModelTextDelta>().single.delta, 'hello ');
    final call = events.whereType<ModelFunctionCall>().single;
    expect(call.name, 'read_file');
    expect(call.arguments, <String, dynamic>{'path': 'README.md'});
    final completed = events.whereType<ModelResponseCompleted>().single;
    expect(completed.assistant.toolCalls.single.callId, 'call-1');
    expect(completed.usage['total_tokens'], 7);
  });

  test('a tool opting out of strict schemas is never sent as strict', () async {
    const tools = <ModelToolDefinition>[
      ModelToolDefinition(
        name: 'read_file',
        description: 'read',
        parameters: <String, dynamic>{
          'type': 'object',
          'properties': <String, dynamic>{},
          'required': <String>[],
          'additionalProperties': false,
        },
      ),
      ModelToolDefinition(
        name: 'mcp__github__create_issue',
        description: 'create an issue',
        parameters: <String, dynamic>{
          'type': 'object',
          'properties': <String, dynamic>{
            'title': <String, dynamic>{'type': 'string'},
            'body': <String, dynamic>{'type': 'string'},
          },
          'required': <String>['title'],
        },
        strict: false,
      ),
    ];
    const responsesFixture = '''
data: {"type":"response.completed","response":{"output":[],"usage":{}}}

data: [DONE]

''';

    final responsesAdapter = _RecordingAdapter(responsesFixture);
    await OpenAIResponsesProvider(
      const OpenAIProviderConfig(apiKey: 'secret-test-key'),
      dio: Dio()..httpClientAdapter = responsesAdapter,
    ).stream(_request(tools: tools), CancellationToken()).toList();
    final responsesBody = Map<String, dynamic>.from(
      responsesAdapter.options!.data as Map,
    );
    final responsesTools = responsesBody['tools']! as List;
    expect(responsesTools.first, containsPair('strict', true));
    expect(responsesTools.last, containsPair('strict', false));

    final chatAdapter = _RecordingAdapter('''
data: {"choices":[{"index":0,"delta":{"content":"hi"},"finish_reason":"stop"}]}

data: {"choices":[],"usage":{"total_tokens":1}}

data: [DONE]

''');
    await OpenAIChatCompletionsProvider(
      const OpenAIProviderConfig(apiKey: 'secret-test-key'),
      dio: Dio()..httpClientAdapter = chatAdapter,
    ).stream(_request(tools: tools), CancellationToken()).toList();
    final chatBody = Map<String, dynamic>.from(
      chatAdapter.options!.data as Map,
    );
    final chatTools = chatBody['tools']! as List;
    expect((chatTools.first as Map)['function'], containsPair('strict', true));
    expect((chatTools.last as Map)['function'], isNot(contains('strict')));
  });

  test('Chat Completions rejects a truncated SSE response', () async {
    final adapter = _RecordingAdapter('''
data: {"choices":[{"index":0,"delta":{"content":"partial"}}]}

''');
    final dio = Dio()..httpClientAdapter = adapter;
    final provider = OpenAIChatCompletionsProvider(
      const OpenAIProviderConfig(requiresApiKey: false),
      dio: dio,
    );
    expect(
      provider
          .stream(
            const ModelRequest(
              model: 'local-model',
              reasoningEffort: 'medium',
              instructions: 'test',
              history: <ConversationItem>[],
              tools: <ModelToolDefinition>[],
              safetyIdentifier: 'safe-user',
            ),
            CancellationToken(),
          )
          .toList(),
      throwsA(isA<OpenAIProviderException>()),
    );
  });

  test(
    'Responses maps canonical history, forced tools, and function calls',
    () async {
      final adapter = _RecordingAdapter(r'''
event: response.output_item.done
data: {"item":{"type":"function_call","call_id":"call-2","name":"write_file","arguments":"{\"path\":\"a.txt\"}"}}

data: {"type":"response.completed","response":{"output":[{"type":"function_call","call_id":"call-2","name":"write_file","arguments":"{\"path\":\"a.txt\"}"},{"type":"message","content":[{"type":"refusal","text":"ignored"},{"type":"output_text","text":"done"}]},{"type":"future_state","opaque":"value"}],"usage":{"input_tokens":3,"label":"ignored"}}}

data: [DONE]

''');
      final dio = Dio()..httpClientAdapter = adapter;
      final provider = OpenAIResponsesProvider(
        const OpenAIProviderConfig(
          id: 'compatible-responses',
          requiresApiKey: false,
          supportsReasoningEffort: false,
          strictToolSchema: false,
        ),
        dio: dio,
      );
      final events = await provider
          .stream(
            _request(
              forceToolName: 'write_file',
              history: const <ConversationItem>[
                UserConversationItem('inspect'),
                AssistantConversationItem(
                  text: 'earlier',
                  toolCalls: <ConversationToolCall>[
                    ConversationToolCall(
                      callId: 'call-1',
                      name: 'read_file',
                      arguments: <String, dynamic>{'path': 'a.txt'},
                    ),
                  ],
                  opaqueItems: <Map<String, dynamic>>[
                    <String, dynamic>{'type': 'reasoning', 'opaque': true},
                  ],
                ),
                ToolResultConversationItem(callId: 'call-1', output: 'content'),
              ],
            ),
            CancellationToken(),
          )
          .toList();

      final body = Map<String, dynamic>.from(adapter.options!.data as Map);
      expect(body, isNot(contains('reasoning')));
      expect(body['tool_choice'], <String, dynamic>{
        'type': 'function',
        'name': 'write_file',
      });
      expect(adapter.options!.headers, isNot(contains('Authorization')));
      final input = body['input']! as List<dynamic>;
      expect(
        input.map((item) => (item as Map<String, dynamic>)['type']),
        <Object?>[
          null,
          'reasoning',
          'message',
          'function_call',
          'function_call_output',
        ],
      );
      expect(events.whereType<ModelFunctionCall>(), hasLength(1));
      final completed = events.whereType<ModelResponseCompleted>().single;
      expect(completed.assistant.text, 'done');
      expect(completed.assistant.toolCalls.single.name, 'write_file');
      expect(completed.assistant.opaqueItems.single['opaque'], 'value');
      expect(completed.usage, <String, int>{'input_tokens': 3});
      expect(provider.id, 'compatible-responses');
    },
  );

  test('Responses normalizes semantic failures and malformed calls', () async {
    for (final fixture in <String>[
      'data: {"type":"response.completed"}\n\n',
      'data: {"type":"response.failed","error":{"message":"failed"}}\n\n',
      'data: {"type":"error","message":"top-level"}\n\n',
      <String>[
        'data: {"type":"response.output_item.done","item":',
        '{"type":"function_call","call_id":"call","name":"tool",',
        '"arguments":"[]"}}\n\n',
      ].join(),
    ]) {
      final dio = Dio()..httpClientAdapter = _RecordingAdapter(fixture);
      final provider = OpenAIResponsesProvider(
        const OpenAIProviderConfig(requiresApiKey: false),
        dio: dio,
      );
      await expectLater(
        provider.stream(_request(), CancellationToken()).toList(),
        throwsA(isA<OpenAIProviderException>()),
      );
    }
  });

  test('Responses retries only transient connection setup failures', () async {
    final retrying = _SequenceAdapter(
      failures: 1,
      type: DioExceptionType.connectionError,
      statusCode: 429,
      fixture:
          'data: {"type":"response.completed","response":{"output":[]}}\n\n',
    );
    final retryDio = Dio()..httpClientAdapter = retrying;
    final provider = OpenAIResponsesProvider(
      const OpenAIProviderConfig(requiresApiKey: false),
      dio: retryDio,
    );
    expect(
      await provider.stream(_request(), CancellationToken()).toList(),
      hasLength(1),
    );
    expect(retrying.calls, 2);

    final failing = _SequenceAdapter(
      failures: 1,
      type: DioExceptionType.badResponse,
      statusCode: 400,
      fixture: '',
    );
    final failingDio = Dio()..httpClientAdapter = failing;
    await expectLater(
      OpenAIResponsesProvider(
        const OpenAIProviderConfig(
          requiresApiKey: false,
          maxConnectAttempts: 1,
        ),
        dio: failingDio,
      ).stream(_request(), CancellationToken()).toList(),
      throwsA(isA<DioException>()),
    );
  });

  test('both adapters translate transport cancellation', () async {
    for (final providerFactory in <ModelProvider Function(Dio)>[
      (dio) => OpenAIResponsesProvider(
        const OpenAIProviderConfig(requiresApiKey: false),
        dio: dio,
      ),
      (dio) => OpenAIChatCompletionsProvider(
        const OpenAIProviderConfig(requiresApiKey: false),
        dio: dio,
      ),
    ]) {
      final dio = Dio()..httpClientAdapter = _CancelAdapter();
      final token = CancellationToken();
      final events = providerFactory(dio).stream(_request(), token).toList();
      await Future<void>.delayed(Duration.zero);
      token.cancel();
      await expectLater(events, throwsA(isA<AgentCancelledException>()));
    }
  });

  test(
    'Chat Completions maps all canonical messages and forced tools',
    () async {
      final adapter = _RecordingAdapter(
        'data: {"choices":[]}\n\ndata: [DONE]\n\n',
      );
      final dio = Dio()..httpClientAdapter = adapter;
      final provider = OpenAIChatCompletionsProvider(
        const OpenAIProviderConfig(apiKey: 'key'),
        dio: dio,
      );
      final events = await provider
          .stream(
            _request(
              forceToolName: 'read_file',
              history: const <ConversationItem>[
                UserConversationItem('user'),
                AssistantConversationItem(
                  text: '',
                  toolCalls: <ConversationToolCall>[
                    ConversationToolCall(
                      callId: 'call',
                      name: 'read_file',
                      arguments: <String, dynamic>{'path': 'a'},
                    ),
                  ],
                ),
                ToolResultConversationItem(callId: 'call', output: 'value'),
              ],
            ),
            CancellationToken(),
          )
          .toList();
      final body = Map<String, dynamic>.from(adapter.options!.data as Map);
      expect(body['reasoning_effort'], 'medium');
      expect(body['tool_choice'], isA<Map<String, dynamic>>());
      expect(body['messages'], hasLength(4));
      expect((body['tools'] as List<dynamic>).single, contains('function'));
      expect(events.single, isA<ModelResponseCompleted>());
      expect(provider.id, 'openai');
    },
  );

  test(
    'Chat Completions validates credentials, calls, and Dio errors',
    () async {
      await expectLater(
        OpenAIChatCompletionsProvider(
          const OpenAIProviderConfig(),
        ).stream(_request(), CancellationToken()).toList(),
        throwsA(isA<OpenAIProviderException>()),
      );

      final malformed = Dio()
        ..httpClientAdapter = _RecordingAdapter('''
data: {"choices":[{"delta":{"tool_calls":[{"index":0,"id":"","function":{"name":"","arguments":"[]"}}]}}]}

data: [DONE]

''');
      await expectLater(
        OpenAIChatCompletionsProvider(
          const OpenAIProviderConfig(requiresApiKey: false),
          dio: malformed,
        ).stream(_request(), CancellationToken()).toList(),
        throwsA(isA<OpenAIProviderException>()),
      );

      final errorAdapter = _SequenceAdapter(
        failures: 1,
        type: DioExceptionType.connectionTimeout,
        statusCode: 503,
        fixture: '',
      );
      final errorDio = Dio()..httpClientAdapter = errorAdapter;
      await expectLater(
        OpenAIChatCompletionsProvider(
          const OpenAIProviderConfig(requiresApiKey: false),
          dio: errorDio,
        ).stream(_request(), CancellationToken()).toList(),
        throwsA(
          isA<OpenAIProviderException>().having(
            (error) => error.retryable,
            'retryable',
            isTrue,
          ),
        ),
      );
    },
  );
}

ModelRequest _request({
  List<ConversationItem> history = const <ConversationItem>[],
  String? forceToolName,
  List<ModelToolDefinition> tools = const <ModelToolDefinition>[
    ModelToolDefinition(
      name: 'read_file',
      description: 'Read',
      parameters: <String, dynamic>{
        'type': 'object',
        'properties': <String, dynamic>{},
        'required': <String>[],
        'additionalProperties': false,
      },
    ),
  ],
}) => ModelRequest(
  model: 'model',
  reasoningEffort: 'medium',
  instructions: 'instructions',
  history: history,
  tools: tools,
  safetyIdentifier: 'safe',
  forceToolName: forceToolName,
);

class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter(this.fixture);

  final String fixture;
  RequestOptions? options;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    this.options = options;
    return ResponseBody.fromString(
      fixture,
      200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>['text/event-stream'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

final class _SequenceAdapter implements HttpClientAdapter {
  _SequenceAdapter({
    required this.failures,
    required this.type,
    required this.statusCode,
    required this.fixture,
  });

  final int failures;
  final DioExceptionType type;
  final int statusCode;
  final String fixture;
  int calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls += 1;
    if (calls <= failures) {
      throw DioException(
        requestOptions: options,
        type: type,
        response: Response<Object?>(
          requestOptions: options,
          statusCode: statusCode,
          data: <String, dynamic>{'error': 'failure'},
        ),
      );
    }
    return ResponseBody.fromString(fixture, 200);
  }

  @override
  void close({bool force = false}) {}
}

final class _CancelAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    await cancelFuture;
    throw DioException.requestCancelled(
      requestOptions: options,
      reason: 'cancelled',
    );
  }

  @override
  void close({bool force = false}) {}
}
