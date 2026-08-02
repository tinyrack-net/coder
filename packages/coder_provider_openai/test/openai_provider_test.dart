import 'dart:typed_data';

import 'package:coder_agent/coder_agent.dart';
import 'package:coder_provider_openai/coder_provider_openai.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

void main() {
  test(
    'Responses request is stateless, strict, sequential, and preserves output items',
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

  test('an empty API key fails before opening a connection', () async {
    final provider = OpenAIResponsesProvider(
      const OpenAIProviderConfig(apiKey: ''),
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
    final adapter = _RecordingAdapter('''
data: {"choices":[{"index":0,"delta":{"content":"hello "}}]}

data: {"choices":[{"index":0,"delta":{"tool_calls":[{"index":0,"id":"call-1","function":{"name":"read_","arguments":"{\\"path\\":"}}]}}]}

data: {"choices":[{"index":0,"delta":{"tool_calls":[{"index":0,"function":{"name":"file","arguments":"\\"README.md\\"}"}}]},"finish_reason":"tool_calls"}]}

data: {"choices":[],"usage":{"prompt_tokens":4,"completion_tokens":3,"total_tokens":7}}

data: [DONE]

''');
    final dio = Dio()..httpClientAdapter = adapter;
    final provider = OpenAIChatCompletionsProvider(
      const OpenAIProviderConfig(
        id: 'compatible',
        apiKey: '',
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
}

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
