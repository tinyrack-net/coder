import 'dart:convert';
import 'dart:typed_data';

import 'package:agent/agent.dart';
import 'package:daemon/src/features/providers/infrastructure/gemini/gemini_provider.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

void main() {
  test(
    'Interactions maps step events and preserves thought signatures',
    () async {
      final adapter = _RecordingAdapter(r'''
event: step.start
data: {"event_type":"step.start","index":0,"step":{"type":"thought"}}

event: step.delta
data: {"event_type":"step.delta","index":0,"delta":{"type":"thought_signature","signature":"signed"}}

event: step.stop
data: {"event_type":"step.stop","index":0}

event: step.start
data: {"event_type":"step.start","index":1,"step":{"type":"model_output"}}

event: step.delta
data: {"event_type":"step.delta","index":1,"delta":{"type":"text","text":"hello"}}

event: step.start
data: {"event_type":"step.start","index":2,"step":{"type":"function_call","id":"call-1","name":"read_file","arguments":{}}}

event: step.delta
data: {"event_type":"step.delta","index":2,"delta":{"type":"arguments_delta","arguments":"{\"path\":"}}

event: step.delta
data: {"event_type":"step.delta","index":2,"delta":{"type":"arguments_delta","arguments":"\"README.md\"}"}}

event: step.stop
data: {"event_type":"step.stop","index":2}

event: interaction.completed
data: {"event_type":"interaction.completed","interaction":{"usage":{"total_input_tokens":7,"total_output_tokens":5,"total_tokens":12}}}

event: done
data: [DONE]

''');
      final provider = GeminiInteractionsProvider(
        const GeminiProviderConfig(apiKey: 'secret'),
        dio: Dio()..httpClientAdapter = adapter,
      );
      final events = await provider
          .stream(
            const ModelRequest(
              model: 'gemini-3.6-flash',
              instructions: 'test',
              history: <ConversationItem>[
                UserConversationItem('hello'),
              ],
              tools: <ModelToolDefinition>[],
              safetyIdentifier: 'safe',
            ),
            CancellationToken(),
          )
          .toList();

      expect(events.whereType<ModelTextDelta>().single.delta, 'hello');
      expect(
        events.whereType<ModelFunctionCall>().single.arguments['path'],
        'README.md',
      );
      final completed = events.whereType<ModelResponseCompleted>().single;
      expect(completed.usage.totalTokens, 12);
      expect(completed.assistant.opaqueItems.single, <String, dynamic>{
        'provider': 'gemini',
        'step': <String, dynamic>{
          'type': 'thought',
          'signature': 'signed',
        },
      });
      final body = Map<String, dynamic>.from(adapter.options!.data as Map);
      expect(body['store'], isFalse);
      expect(body['stream'], isTrue);
    },
  );
}

final class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter(this.body);
  final String body;
  RequestOptions? options;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    this.options = options;
    return ResponseBody.fromBytes(
      utf8.encode(body),
      200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>['text/event-stream'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
