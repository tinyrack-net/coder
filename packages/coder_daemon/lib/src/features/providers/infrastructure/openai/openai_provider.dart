import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:coder_agent/coder_agent.dart';
import 'package:coder_daemon/src/features/providers/infrastructure/openai/error_body.dart';
import 'package:coder_daemon/src/features/providers/infrastructure/openai/sse.dart';
import 'package:dio/dio.dart';

/// OpenAIProviderConfig defines a public contract.
class OpenAIProviderConfig {
  /// Creates a [OpenAIProviderConfig].
  const OpenAIProviderConfig({
    this.id = 'openai',
    this.apiKey = '',
    this.baseUrl = 'https://api.openai.com/v1',
    this.maxConnectAttempts = 3,
    this.requiresApiKey = true,
    this.supportsReasoningEffort = true,
    this.supportsImageInput = true,
    this.supportsFileInput = true,
    this.supportsServiceTier = false,
    this.supportsSafetyIdentifier = true,
    this.strictToolSchema = true,
    this.additionalHeaders = const <String, String>{},
  });

  /// The id public API member.
  final String id;

  /// The apiKey public API member.
  final String apiKey;

  /// The baseUrl public API member.
  final String baseUrl;

  /// The maxConnectAttempts public API member.
  final int maxConnectAttempts;

  /// The requiresApiKey public API member.
  final bool requiresApiKey;

  /// The supportsReasoningEffort public API member.
  final bool supportsReasoningEffort;

  /// Whether hydrated images may be sent as Responses content parts.
  final bool supportsImageInput;

  /// Whether hydrated documents may be sent as Responses content parts.
  final bool supportsFileInput;

  /// Whether the endpoint accepts a `service_tier` request field.
  final bool supportsServiceTier;

  /// Whether the endpoint accepts a `safety_identifier` request field.
  ///
  /// The field belongs to the platform Responses API. The ChatGPT subscription
  /// backend serves a narrower surface and rejects the whole request when it
  /// carries a parameter that surface does not define.
  final bool supportsSafetyIdentifier;

  /// The strictToolSchema public API member.
  final bool strictToolSchema;

  /// Additional non-secret headers required by a provider runtime.
  final Map<String, String> additionalHeaders;
}

/// OpenAIProviderException defines a public contract.
class OpenAIProviderException implements Exception {
  /// Creates a [OpenAIProviderException].
  const OpenAIProviderException(this.message, {this.retryable = false});

  /// The message public API member.
  final String message;

  /// The retryable public API member.
  final bool retryable;

  @override
  String toString() => 'OpenAIProviderException: $message';
}

/// Error codes every OpenAI-compatible API uses for an oversized prompt.
const Set<String> _contextOverflowCodes = <String>{
  'context_length_exceeded',
  'string_above_max_length',
};

/// Wordings used by servers that report the overflow without a code.
const List<String> _contextOverflowPhrases = <String>[
  'maximum context length',
  'context window',
  'too many tokens',
];

/// Decides whether a provider failure means the history no longer fits.
///
/// Both adapters share this so a compaction retry is triggered by the same
/// signal regardless of which API the provider speaks. Matching is broader than
/// the code alone because self-hosted runtimes report the same condition in
/// prose only.
bool isContextOverflowFailure(String? code, String message) {
  if (code != null && _contextOverflowCodes.contains(code)) return true;
  final lowered = message.toLowerCase();
  return _contextOverflowPhrases.any(lowered.contains);
}

/// Reads the `error.code` out of an OpenAI error envelope.
String? contextOverflowCode(Object? body) {
  if (body is! Map) return null;
  final error = body['error'];
  if (error is! Map) return null;
  final code = error['code'];
  return code is String ? code : null;
}

/// OpenAIResponsesProvider defines a public contract.
class OpenAIResponsesProvider implements ModelProvider {
  /// Creates a [OpenAIResponsesProvider].
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
        'OpenAI API key is not configured. Set it in the desktop app or '
        'OPENAI_API_KEY.',
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
              ..._config.additionalHeaders,
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
        final body = await decodeProviderErrorBody(error.response?.data);
        final message = providerErrorMessage(body) ?? error.message ?? '$error';
        // An oversized prompt is rejected before the stream opens, so it has to
        // be classified here rather than among the SSE events.
        if (isContextOverflowFailure(contextOverflowCode(body), message)) {
          throw ModelContextOverflowException(message);
        }
        final retryable = _isRetryable(error);
        // A raw DioException stringifies to its status code alone, so the
        // rejection is restated here or the reason never reaches the turn.
        final failure = OpenAIProviderException(
          describeProviderFailure(error.response?.statusCode, message),
          retryable: retryable,
        );
        lastError = failure;
        if (!retryable || attempt == _config.maxConnectAttempts) throw failure;
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
    if (_config.supportsServiceTier && request.serviceTier != null)
      'service_tier': request.serviceTier,
    'tools': request.tools
        .map(
          (tool) => <String, dynamic>{
            'type': 'function',
            'name': tool.name,
            'description': tool.description,
            'parameters': tool.parameters,
            'strict': tool.strict && _config.strictToolSchema,
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
    if (_config.supportsSafetyIdentifier)
      'safety_identifier': request.safetyIdentifier,
  };

  List<Map<String, dynamic>> _responsesInput(List<ConversationItem> history) {
    final result = <Map<String, dynamic>>[];
    var directFileBytes = 0;
    for (final item in history) {
      switch (item) {
        case UserConversationItem(:final text, :final attachments):
          final content = <Map<String, dynamic>>[
            if (text.isNotEmpty)
              <String, dynamic>{'type': 'input_text', 'text': text},
          ];
          for (final attachment in attachments) {
            final bytes = attachment.bytes;
            if (_config.supportsImageInput &&
                bytes != null &&
                _supportedImageTypes.contains(attachment.mimeType)) {
              content.add(<String, dynamic>{
                'type': 'input_image',
                'image_url':
                    'data:${attachment.mimeType};base64,${base64Encode(bytes)}',
                'detail': attachment.imageDetail ?? 'auto',
              });
            } else if (_config.supportsFileInput &&
                bytes != null &&
                _isSupportedFile(attachment) &&
                directFileBytes + bytes.length <= _maxDirectFileBytes) {
              directFileBytes += bytes.length;
              content.add(<String, dynamic>{
                'type': 'input_file',
                'filename': attachment.fileName,
                'file_data':
                    'data:${attachment.mimeType};base64,${base64Encode(bytes)}',
              });
            } else {
              content.add(<String, dynamic>{
                'type': 'input_text',
                'text': _attachmentFallback(attachment),
              });
            }
          }
          result.add(<String, dynamic>{
            'role': 'user',
            'content': content,
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

  static const Set<String> _supportedImageTypes = supportedContextImageTypes;

  static const int _maxDirectFileBytes = 50 * 1024 * 1024;

  static const Set<String> _supportedFileTypes = <String>{
    'application/pdf',
    'application/json',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'application/vnd.ms-powerpoint',
    'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'text/plain',
    'text/markdown',
    'text/csv',
    'text/html',
    'text/xml',
  };

  static bool _isSupportedFile(ConversationAttachment attachment) =>
      _supportedFileTypes.contains(attachment.mimeType) ||
      <String>{
        '.c',
        '.cpp',
        '.css',
        '.dart',
        '.go',
        '.java',
        '.js',
        '.kt',
        '.py',
        '.rb',
        '.rs',
        '.sh',
        '.ts',
        '.yaml',
        '.yml',
      }.any(attachment.fileName.toLowerCase().endsWith);

  static String _attachmentFallback(ConversationAttachment attachment) =>
      '[Attachment id=${attachment.id}, file=${attachment.fileName}, '
      'mime=${attachment.mimeType}, bytes=${attachment.byteSize}, '
      'path=${attachment.path}. Use read_attachment with the attachment id.]';

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
              .whereType<Map<dynamic, dynamic>>()
              .map(Map<String, dynamic>.from)
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
        case 'error':
          throw _streamFailure(event);
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
    if (callId is! String || name is! String || arguments is! String) {
      return null;
    }
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

  ModelUsage _usage(Object? value) {
    if (value is! Map) return const ModelUsage();
    final usage = Map<String, dynamic>.from(value);
    return ModelUsage(
      inputTokens: _count(usage['input_tokens']),
      cachedInputTokens: _nestedCount(
        usage['input_tokens_details'],
        'cached_tokens',
      ),
      outputTokens: _count(usage['output_tokens']),
      reasoningTokens: _nestedCount(
        usage['output_tokens_details'],
        'reasoning_tokens',
      ),
      totalTokens: _count(usage['total_tokens']),
    );
  }

  static int _count(Object? value) => value is int ? value : 0;

  static int _nestedCount(Object? details, String key) =>
      details is Map ? _count(details[key]) : 0;

  String _errorMessage(Map<String, dynamic> event) {
    final error = _errorEnvelope(event);
    if (error is Map && error['message'] is String) {
      return error['message'] as String;
    }
    return event['message'] as String? ??
        'OpenAI Responses API request failed.';
  }

  /// A failure the model context can no longer hold, or a plain adapter error.
  ///
  /// `response.failed` nests the envelope under `response`, while a bare
  /// `error` event carries it at the top level.
  Exception _streamFailure(Map<String, dynamic> event) {
    final message = _errorMessage(event);
    final envelope = _errorEnvelope(event);
    final code = envelope is Map && envelope['code'] is String
        ? envelope['code'] as String
        : null;
    if (isContextOverflowFailure(code, message)) {
      return ModelContextOverflowException(message);
    }
    return OpenAIProviderException(message);
  }

  Object? _errorEnvelope(Map<String, dynamic> event) {
    final direct = event['error'];
    if (direct is Map) return direct;
    final response = event['response'];
    if (response is Map && response['error'] is Map) return response['error'];
    return direct;
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
