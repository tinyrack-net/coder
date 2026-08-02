import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:coder_agent/coder_agent.dart';
import 'package:dio/dio.dart';

import 'sse.dart';

class OpenAIProviderConfig {
  const OpenAIProviderConfig({
    this.id = 'openai',
    this.apiKey = '',
    this.baseUrl = 'https://api.openai.com/v1',
    this.maxConnectAttempts = 3,
    this.requiresApiKey = true,
    this.supportsReasoningEffort = true,
    this.strictToolSchema = true,
  });

  final String id;
  final String apiKey;
  final String baseUrl;
  final int maxConnectAttempts;
  final bool requiresApiKey;
  final bool supportsReasoningEffort;
  final bool strictToolSchema;
}

class OpenAIProviderException implements Exception {
  const OpenAIProviderException(this.message, {this.retryable = false});

  final String message;
  final bool retryable;

  @override
  String toString() => 'OpenAIProviderException: $message';
}

class OpenAIResponsesProvider implements ModelProvider {
  OpenAIResponsesProvider(OpenAIProviderConfig config, {Dio? dio})
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
        'OpenAI API key is not configured. Set it in the desktop app or OPENAI_API_KEY.',
      );
    }
    final cancelToken = CancelToken();
    cancellation.onCancel(() => cancelToken.cancel('Agent turn cancelled.'));
    Response<ResponseBody>? response;
    Object? lastError;
    for (var attempt = 1; attempt <= _config.maxConnectAttempts; attempt += 1) {
      cancellation.throwIfCancelled();
      try {
        response = await _dio.post<ResponseBody>(
          '/responses',
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
        break;
      } on DioException catch (error) {
        if (CancelToken.isCancel(error)) throw const AgentCancelledException();
        lastError = error;
        if (!_isRetryable(error) || attempt == _config.maxConnectAttempts)
          rethrow;
        await Future<void>.delayed(
          Duration(milliseconds: 250 * (1 << (attempt - 1))),
        );
      }
    }
    if (response?.data == null) {
      throw OpenAIProviderException('No response stream: $lastError');
    }
    yield* _modelEvents(response!.data!.stream, cancellation);
  }

  Map<String, dynamic> _requestBody(ModelRequest request) => <String, dynamic>{
    'model': request.model,
    'instructions': request.instructions,
    'input': _responsesInput(request.history),
    if (_config.supportsReasoningEffort)
      'reasoning': <String, dynamic>{'effort': request.reasoningEffort},
    'tools': request.tools
        .map(
          (tool) => <String, dynamic>{
            'type': 'function',
            'name': tool.name,
            'description': tool.description,
            'parameters': tool.parameters,
            'strict': _config.strictToolSchema,
          },
        )
        .toList(growable: false),
    'parallel_tool_calls': false,
    if (request.forceToolName != null)
      'tool_choice': <String, dynamic>{
        'type': 'function',
        'name': request.forceToolName,
      },
    'stream': true,
    'store': false,
    'include': <String>['reasoning.encrypted_content'],
    'safety_identifier': request.safetyIdentifier,
  };

  List<Map<String, dynamic>> _responsesInput(List<ConversationItem> history) {
    final result = <Map<String, dynamic>>[];
    for (final item in history) {
      switch (item) {
        case UserConversationItem(:final text):
          result.add(<String, dynamic>{
            'role': 'user',
            'content': <Map<String, dynamic>>[
              <String, dynamic>{'type': 'input_text', 'text': text},
            ],
          });
        case AssistantConversationItem(
          :final text,
          :final toolCalls,
          :final opaqueItems,
        ):
          result.addAll(opaqueItems.map(Map<String, dynamic>.from));
          if (text.isNotEmpty) {
            result.add(<String, dynamic>{
              'type': 'message',
              'role': 'assistant',
              'content': <Map<String, dynamic>>[
                <String, dynamic>{
                  'type': 'output_text',
                  'text': text,
                  'annotations': <dynamic>[],
                },
              ],
            });
          }
          for (final call in toolCalls) {
            result.add(<String, dynamic>{
              'type': 'function_call',
              'call_id': call.callId,
              'name': call.name,
              'arguments': jsonEncode(call.arguments),
            });
          }
        case ToolResultConversationItem(:final callId, :final output):
          result.add(<String, dynamic>{
            'type': 'function_call_output',
            'call_id': callId,
            'output': output,
          });
      }
    }
    return result;
  }

  Stream<ModelEvent> _modelEvents(
    Stream<Uint8List> bytes,
    CancellationToken cancellation,
  ) async* {
    final emittedCalls = <String>{};
    await for (final sse in decodeServerSentEvents(bytes)) {
      cancellation.throwIfCancelled();
      if (sse.data == '[DONE]') continue;
      final decoded = jsonDecode(sse.data);
      if (decoded is! Map) continue;
      final event = Map<String, dynamic>.from(decoded);
      final type = event['type'] as String? ?? sse.event;
      switch (type) {
        case 'response.output_text.delta':
          final delta = event['delta'];
          if (delta is String && delta.isNotEmpty) yield ModelTextDelta(delta);
        case 'response.output_item.done':
          final item = event['item'];
          if (item is Map) {
            final call = _functionCall(Map<String, dynamic>.from(item));
            if (call != null && emittedCalls.add(call.callId)) yield call;
          }
        case 'response.completed':
          final response = event['response'];
          if (response is! Map) {
            throw const OpenAIProviderException(
              'response.completed has no response object.',
            );
          }
          final responseMap = Map<String, dynamic>.from(response);
          final output = (responseMap['output'] as List? ?? const <dynamic>[])
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList(growable: false);
          for (final item in output) {
            final call = _functionCall(item);
            if (call != null && emittedCalls.add(call.callId)) yield call;
          }
          final calls = output
              .map(_functionCall)
              .whereType<ModelFunctionCall>()
              .map(
                (call) => ConversationToolCall(
                  callId: call.callId,
                  name: call.name,
                  arguments: call.arguments,
                ),
              )
              .toList(growable: false);
          yield ModelResponseCompleted(
            assistant: AssistantConversationItem(
              text: _outputText(output),
              toolCalls: calls,
              opaqueItems: output
                  .where(
                    (item) =>
                        item['type'] != 'message' &&
                        item['type'] != 'function_call',
                  )
                  .map(Map<String, dynamic>.from)
                  .toList(growable: false),
            ),
            usage: _usage(responseMap['usage']),
          );
        case 'response.failed':
          throw OpenAIProviderException(_errorMessage(event), retryable: false);
        case 'error':
          throw OpenAIProviderException(_errorMessage(event), retryable: false);
      }
    }
  }

  String _outputText(List<Map<String, dynamic>> output) {
    final buffer = StringBuffer();
    for (final item in output) {
      if (item['type'] != 'message') continue;
      for (final content in item['content'] as List? ?? const <dynamic>[]) {
        if (content is Map && content['type'] == 'output_text') {
          final text = content['text'];
          if (text is String) buffer.write(text);
        }
      }
    }
    return buffer.toString();
  }

  ModelFunctionCall? _functionCall(Map<String, dynamic> item) {
    if (item['type'] != 'function_call') return null;
    final callId = item['call_id'];
    final name = item['name'];
    final arguments = item['arguments'];
    if (callId is! String || name is! String || arguments is! String)
      return null;
    final decoded = jsonDecode(arguments);
    if (decoded is! Map) {
      throw OpenAIProviderException(
        'Function $name returned non-object arguments.',
      );
    }
    return ModelFunctionCall(
      callId: callId,
      name: name,
      arguments: Map<String, dynamic>.from(decoded),
    );
  }

  Map<String, int> _usage(Object? value) {
    if (value is! Map) return const <String, int>{};
    final usage = Map<String, dynamic>.from(value);
    return <String, int>{
      for (final entry in usage.entries)
        if (entry.value is int) entry.key: entry.value as int,
    };
  }

  String _errorMessage(Map<String, dynamic> event) {
    final error = event['error'];
    if (error is Map && error['message'] is String)
      return error['message'] as String;
    return event['message'] as String? ??
        'OpenAI Responses API request failed.';
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
