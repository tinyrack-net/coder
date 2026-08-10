import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:agent/agent.dart';
import 'package:daemon/src/features/providers/infrastructure/openai/error_body.dart';
import 'package:daemon/src/features/providers/infrastructure/openai/sse.dart';
import 'package:dio/dio.dart';

/// Runtime configuration for an Anthropic Messages endpoint.
final class AnthropicProviderConfig {
  /// Creates Anthropic endpoint configuration.
  const AnthropicProviderConfig({
    required this.apiKey,
    this.id = 'anthropic',
    this.baseUrl = 'https://api.anthropic.com/v1',
    this.apiVersion = '2023-06-01',
    this.maxOutputTokens = 8192,
  });

  /// Connection ID.
  final String id;

  /// Secret API key.
  final String apiKey;

  /// Trusted or user-selected base URL.
  final String baseUrl;

  /// Anthropic contract version sent on every request.
  final String apiVersion;

  /// Required Messages API output ceiling.
  final int maxOutputTokens;
}

/// Classified Anthropic transport or stream failure.
final class AnthropicProviderException implements Exception {
  /// Creates a provider failure.
  const AnthropicProviderException(this.message, {this.retryable = false});

  /// User-safe description.
  final String message;

  /// Whether retrying without changing the request may succeed.
  final bool retryable;

  @override
  String toString() => 'AnthropicProviderException: $message';
}

/// Stateless Anthropic Messages streaming adapter.
final class AnthropicMessagesProvider implements ModelProvider {
  /// Creates a Messages adapter.
  AnthropicMessagesProvider(AnthropicProviderConfig config, {Dio? dio})
    : _config = config,
      _dio = dio ?? Dio(BaseOptions(baseUrl: config.baseUrl));

  final AnthropicProviderConfig _config;
  final Dio _dio;

  @override
  String get id => _config.id;

  @override
  Stream<ModelEvent> stream(
    ModelRequest request,
    CancellationToken cancellation,
  ) async* {
    if (_config.apiKey.isEmpty) {
      throw const AnthropicProviderException(
        'Anthropic API key is not configured.',
      );
    }
    final cancelToken = CancelToken();
    cancellation.onCancel(() => cancelToken.cancel('Agent turn cancelled.'));
    try {
      final response = await _dio.post<ResponseBody>(
        '/messages',
        data: _requestBody(request),
        cancelToken: cancelToken,
        options: Options(
          responseType: ResponseType.stream,
          headers: <String, String>{
            'x-api-key': _config.apiKey,
            'anthropic-version': _config.apiVersion,
            'accept': 'text/event-stream',
            'content-type': 'application/json',
          },
        ),
      );
      final bytes = response.data?.stream;
      if (bytes == null) {
        throw const AnthropicProviderException('No Messages response stream.');
      }
      yield* _events(bytes, cancellation);
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) throw const AgentCancelledException();
      final body = await decodeProviderErrorBody(error.response?.data);
      final message = providerErrorMessage(body) ?? error.message ?? '$error';
      if (_isContextOverflow(message)) {
        throw ModelContextOverflowException(message);
      }
      final status = error.response?.statusCode;
      throw AnthropicProviderException(
        describeProviderFailure(status, message),
        retryable: status == 429 || status == 529 || (status ?? 0) >= 500,
      );
    }
  }

  Map<String, dynamic> _requestBody(ModelRequest request) {
    final effort = _stringControl(
      request,
      AgentModelControlIds.reasoningEffort,
    );
    final reasoningMode = _stringControl(
      request,
      AgentModelControlIds.reasoningMode,
    );
    final budget = _intControl(request, AgentModelControlIds.thinkingBudget);
    final fast = _boolControl(request, AgentModelControlIds.fastMode);
    return <String, dynamic>{
      'model': request.model,
      'system': request.instructions,
      'messages': _messages(request.history),
      'max_tokens': _config.maxOutputTokens,
      'stream': true,
      if (effort != null) 'output_config': <String, dynamic>{'effort': effort},
      if (reasoningMode == 'adaptive')
        'thinking': <String, dynamic>{'type': 'adaptive'},
      if (budget != null)
        'thinking': <String, dynamic>{
          'type': 'enabled',
          'budget_tokens': budget,
        },
      if (fast == true) 'speed': 'fast',
      'tools': <Map<String, dynamic>>[
        for (final tool
            in request.tools.whereType<ModelFunctionToolDefinition>())
          <String, dynamic>{
            'name': tool.name,
            'description': tool.description,
            'input_schema': tool.parameters,
            if (tool.strict) 'strict': true,
          },
      ],
      if (request.forceToolName != null)
        'tool_choice': <String, dynamic>{
          'type': 'tool',
          'name': request.forceToolName,
        },
    };
  }

  List<Map<String, dynamic>> _messages(List<ConversationItem> history) =>
      <Map<String, dynamic>>[
        for (final item in history)
          switch (item) {
            UserConversationItem(:final text, :final attachments) =>
              <String, dynamic>{
                'role': 'user',
                'content': <Map<String, dynamic>>[
                  if (text.isNotEmpty)
                    <String, dynamic>{'type': 'text', 'text': text},
                  for (final attachment in attachments)
                    if (attachment.bytes != null &&
                        attachment.mimeType.startsWith('image/'))
                      <String, dynamic>{
                        'type': 'image',
                        'source': <String, dynamic>{
                          'type': 'base64',
                          'media_type': attachment.mimeType,
                          'data': base64Encode(attachment.bytes!),
                        },
                      }
                    else
                      <String, dynamic>{
                        'type': 'text',
                        'text':
                            '[Attachment ${attachment.fileName} at '
                            '${attachment.path}]',
                      },
                ],
              },
            AssistantConversationItem(
              :final text,
              :final toolCalls,
              :final opaqueItems,
            ) =>
              <String, dynamic>{
                'role': 'assistant',
                'content': <Map<String, dynamic>>[
                  for (final item in opaqueItems)
                    if (item['provider'] == 'anthropic' && item['block'] is Map)
                      Map<String, dynamic>.from(item['block']! as Map),
                  if (text.isNotEmpty)
                    <String, dynamic>{'type': 'text', 'text': text},
                  for (final call in toolCalls)
                    <String, dynamic>{
                      'type': 'tool_use',
                      'id': call.callId,
                      'name': call.name,
                      'input': switch (call.input) {
                        JsonToolCallInput(:final value) => value,
                        FreeformToolCallInput() => throw StateError(
                          'Anthropic Messages does not support freeform tools.',
                        ),
                      },
                    },
                ],
              },
            ToolResultConversationItem(
              :final callId,
              :final output,
              :final isError,
            ) =>
              <String, dynamic>{
                'role': 'user',
                'content': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'type': 'tool_result',
                    'tool_use_id': callId,
                    'content': output,
                    if (isError) 'is_error': true,
                  },
                ],
              },
          },
      ];

  Stream<ModelEvent> _events(
    Stream<Uint8List> bytes,
    CancellationToken cancellation,
  ) async* {
    var text = '';
    var usage = const ModelUsage();
    final blocks = <int, _AnthropicBlock>{};
    final calls = <ConversationToolCall>[];
    final opaque = <Map<String, dynamic>>[];
    await for (final sse in decodeServerSentEvents(bytes)) {
      cancellation.throwIfCancelled();
      if (sse.data == '[DONE]') break;
      final event = Map<String, dynamic>.from(jsonDecode(sse.data) as Map);
      switch (event['type']) {
        case 'message_start':
          final message = event['message'];
          final initial = message is Map ? message['usage'] : null;
          if (initial is Map) usage = _usage(initial, usage);
        case 'content_block_start':
          final index = event['index'];
          final raw = event['content_block'];
          if (index is int && raw is Map) {
            blocks[index] = _AnthropicBlock(Map<String, dynamic>.from(raw));
          }
        case 'content_block_delta':
          final index = event['index'];
          final delta = event['delta'];
          if (index is! int || delta is! Map || blocks[index] == null) continue;
          final block = blocks[index]!;
          switch (delta['type']) {
            case 'text_delta':
              final value = delta['text'];
              if (value is String) {
                text += value;
                yield ModelTextDelta(value);
              }
            case 'input_json_delta':
              final value = delta['partial_json'];
              if (value is String) block.arguments.write(value);
            case 'thinking_delta':
              final value = delta['thinking'];
              if (value is String) block.thinking.write(value);
            case 'signature_delta':
              final value = delta['signature'];
              if (value is String) block.signature.write(value);
          }
        case 'content_block_stop':
          final index = event['index'];
          final block = index is int ? blocks[index] : null;
          if (block == null) continue;
          if (block.raw['type'] == 'tool_use') {
            final call = ConversationToolCall.function(
              callId: block.raw['id']! as String,
              name: block.raw['name']! as String,
              arguments: _jsonObject(block.arguments.toString()),
            );
            calls.add(call);
            yield ModelFunctionCall(
              callId: call.callId,
              name: call.name,
              arguments: switch (call.input) {
                JsonToolCallInput(:final value) => value,
                FreeformToolCallInput() => throw StateError(
                  'Anthropic Messages emitted a freeform call.',
                ),
              },
            );
          } else if (block.raw['type'] == 'thinking' ||
              block.raw['type'] == 'redacted_thinking') {
            final raw = <String, dynamic>{...block.raw};
            if (block.thinking.isNotEmpty) {
              raw['thinking'] = '${block.thinking}';
            }
            if (block.signature.isNotEmpty) {
              raw['signature'] = '${block.signature}';
            }
            opaque.add(<String, dynamic>{
              'provider': 'anthropic',
              'block': raw,
            });
          }
        case 'message_delta':
          final deltaUsage = event['usage'];
          if (deltaUsage is Map) usage = _usage(deltaUsage, usage);
        case 'error':
          final error = event['error'];
          final type = error is Map ? error['type'] : null;
          final message = error is Map ? error['message'] : null;
          throw AnthropicProviderException(
            message is String ? message : 'Anthropic stream failed.',
            retryable: type == 'overloaded_error' || type == 'api_error',
          );
        case 'message_stop':
          yield ModelResponseCompleted(
            assistant: AssistantConversationItem(
              text: text,
              toolCalls: calls,
              opaqueItems: opaque,
            ),
            usage: usage,
          );
      }
    }
  }
}

final class _AnthropicBlock {
  _AnthropicBlock(this.raw);
  final Map<String, dynamic> raw;
  final StringBuffer arguments = StringBuffer();
  final StringBuffer thinking = StringBuffer();
  final StringBuffer signature = StringBuffer();
}

Map<String, dynamic> _jsonObject(String value) {
  if (value.isEmpty) return <String, dynamic>{};
  final decoded = jsonDecode(value);
  if (decoded is! Map) throw const FormatException('Tool input must be JSON.');
  return Map<String, dynamic>.from(decoded);
}

ModelUsage _usage(Map<dynamic, dynamic> value, ModelUsage previous) {
  final input = value['input_tokens'];
  final output = value['output_tokens'];
  final cacheRead = value['cache_read_input_tokens'];
  final inputTokens = input is int ? input : previous.inputTokens;
  final outputTokens = output is int ? output : previous.outputTokens;
  return ModelUsage(
    inputTokens: inputTokens,
    cachedInputTokens: cacheRead is int
        ? cacheRead
        : previous.cachedInputTokens,
    outputTokens: outputTokens,
    totalTokens: inputTokens + outputTokens,
  );
}

String? _stringControl(ModelRequest request, String id) =>
    switch (request.modelControls[id]) {
      AgentModelControlStringValue(:final value) => value,
      _ => null,
    };

int? _intControl(ModelRequest request, String id) =>
    switch (request.modelControls[id]) {
      AgentModelControlIntValue(:final value) => value,
      _ => null,
    };

bool? _boolControl(ModelRequest request, String id) =>
    switch (request.modelControls[id]) {
      AgentModelControlBoolValue(:final value) => value,
      _ => null,
    };

bool _isContextOverflow(String message) {
  final lowered = message.toLowerCase();
  return lowered.contains('prompt is too long') ||
      lowered.contains('context window') ||
      lowered.contains('too many tokens');
}
