import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:coder_agent/coder_agent.dart';
import 'package:coder_provider_openai/src/openai_provider.dart';
import 'package:coder_provider_openai/src/sse.dart';
import 'package:dio/dio.dart';

/// OpenAIChatCompletionsProvider defines a public contract.
class OpenAIChatCompletionsProvider implements ModelProvider {
  /// Creates a [OpenAIChatCompletionsProvider].
  OpenAIChatCompletionsProvider(OpenAIProviderConfig config, {Dio? dio})
    : _config = config,
      _dio = dio ?? Dio(BaseOptions(baseUrl: config.baseUrl));

  final OpenAIProviderConfig _config;
  final Dio _dio;

  @override
  String get id => _config.id;

  @override
  Stream<ModelEvent> stream(
    ModelRequest request,
    CancellationToken cancellation,
  ) async* {
    if (_config.requiresApiKey && _config.apiKey.isEmpty) {
      throw const OpenAIProviderException(
        'Provider API key is not configured.',
      );
    }
    final cancelToken = CancelToken();
    cancellation.onCancel(() => cancelToken.cancel('Agent turn cancelled.'));
    try {
      final response = await _dio.post<ResponseBody>(
        '/chat/completions',
        data: _requestBody(request),
        cancelToken: cancelToken,
        options: Options(
          responseType: ResponseType.stream,
          headers: <String, String>{
            if (_config.apiKey.isNotEmpty)
              'Authorization': 'Bearer ${_config.apiKey}',
            'Accept': 'text/event-stream',
            'Content-Type': 'application/json',
          },
        ),
      );
      final stream = response.data?.stream;
      if (stream == null) {
        throw const OpenAIProviderException('No chat completion stream.');
      }
      yield* _modelEvents(stream, cancellation);
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) throw const AgentCancelledException();
      final body = error.response?.data;
      throw OpenAIProviderException(
        body == null ? error.message ?? '$error' : '$body',
        retryable: _isRetryable(error),
      );
    }
  }

  Map<String, dynamic> _requestBody(ModelRequest request) => <String, dynamic>{
    'model': request.model,
    'messages': <Map<String, dynamic>>[
      <String, dynamic>{'role': 'system', 'content': request.instructions},
      ..._messages(request.history),
    ],
    if (_config.supportsReasoningEffort)
      'reasoning_effort': request.reasoningEffort,
    'tools': request.tools
        .map(
          (tool) => <String, dynamic>{
            'type': 'function',
            'function': <String, dynamic>{
              'name': tool.name,
              'description': tool.description,
              'parameters': tool.parameters,
              if (_config.strictToolSchema) 'strict': true,
            },
          },
        )
        .toList(growable: false),
    'stream': true,
    if (request.forceToolName != null)
      'tool_choice': <String, dynamic>{
        'type': 'function',
        'function': <String, dynamic>{'name': request.forceToolName},
      },
    'stream_options': <String, dynamic>{'include_usage': true},
  };

  List<Map<String, dynamic>> _messages(List<ConversationItem> history) {
    final result = <Map<String, dynamic>>[];
    for (final item in history) {
      switch (item) {
        case UserConversationItem(:final text):
          result.add(<String, dynamic>{'role': 'user', 'content': text});
        case AssistantConversationItem(:final text, :final toolCalls):
          result.add(<String, dynamic>{
            'role': 'assistant',
            'content': text.isEmpty ? null : text,
            if (toolCalls.isNotEmpty)
              'tool_calls': toolCalls
                  .map(
                    (call) => <String, dynamic>{
                      'id': call.callId,
                      'type': 'function',
                      'function': <String, dynamic>{
                        'name': call.name,
                        'arguments': jsonEncode(call.arguments),
                      },
                    },
                  )
                  .toList(growable: false),
          });
        case ToolResultConversationItem(:final callId, :final output):
          result.add(<String, dynamic>{
            'role': 'tool',
            'tool_call_id': callId,
            'content': output,
          });
      }
    }
    return result;
  }

  Stream<ModelEvent> _modelEvents(
    Stream<Uint8List> bytes,
    CancellationToken cancellation,
  ) async* {
    final text = StringBuffer();
    final calls = <int, _ChatToolCallBuilder>{};
    var usage = const <String, int>{};
    var receivedDone = false;
    await for (final sse in decodeServerSentEvents(bytes)) {
      cancellation.throwIfCancelled();
      if (sse.data == '[DONE]') {
        receivedDone = true;
        continue;
      }
      final decoded = jsonDecode(sse.data);
      if (decoded is! Map) continue;
      final event = Map<String, dynamic>.from(decoded);
      usage = _usage(event['usage']).isEmpty ? usage : _usage(event['usage']);
      final choices = event['choices'];
      if (choices is! List) continue;
      for (final choice in choices.whereType<Map<dynamic, dynamic>>()) {
        final delta = choice['delta'];
        if (delta is! Map) continue;
        final content = delta['content'];
        if (content is String && content.isNotEmpty) {
          text.write(content);
          yield ModelTextDelta(content);
        }
        for (final raw in delta['tool_calls'] as List? ?? const <dynamic>[]) {
          if (raw is! Map) continue;
          final index = raw['index'];
          if (index is! int) continue;
          final builder = calls.putIfAbsent(index, _ChatToolCallBuilder.new);
          if (raw['id'] is String) builder.callId = raw['id'] as String;
          final function = raw['function'];
          if (function is Map) {
            if (function['name'] is String) {
              builder.name += function['name'] as String;
            }
            if (function['arguments'] is String) {
              builder.arguments.write(function['arguments'] as String);
            }
          }
        }
      }
    }
    if (!receivedDone) {
      throw const OpenAIProviderException(
        'Chat completion stream ended before [DONE].',
      );
    }
    final toolCalls = <ConversationToolCall>[];
    for (final entry
        in calls.entries.toList()..sort((a, b) => a.key.compareTo(b.key))) {
      final call = entry.value.build();
      toolCalls.add(call);
      yield ModelFunctionCall(
        callId: call.callId,
        name: call.name,
        arguments: call.arguments,
      );
    }
    yield ModelResponseCompleted(
      assistant: AssistantConversationItem(
        text: text.toString(),
        toolCalls: toolCalls,
      ),
      usage: usage,
    );
  }

  Map<String, int> _usage(Object? value) {
    if (value is! Map) return const <String, int>{};
    return <String, int>{
      for (final entry in value.entries)
        if (entry.value is int) '${entry.key}': entry.value as int,
    };
  }

  bool _isRetryable(DioException error) {
    final status = error.response?.statusCode;
    return status == 408 ||
        status == 429 ||
        (status != null && status >= 500) ||
        error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout;
  }
}

class _ChatToolCallBuilder {
  String callId = '';
  String name = '';
  final StringBuffer arguments = StringBuffer();

  ConversationToolCall build() {
    final decoded = jsonDecode(arguments.toString());
    if (callId.isEmpty || name.isEmpty || decoded is! Map) {
      throw const OpenAIProviderException('Invalid streamed tool call.');
    }
    return ConversationToolCall(
      callId: callId,
      name: name,
      arguments: Map<String, dynamic>.from(decoded),
    );
  }
}
