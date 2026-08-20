import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Reads the error payload Dio leaves undecoded on a streaming response.
///
/// Both adapters ask for [ResponseType.stream], and Dio hands the raw
/// [ResponseBody] back untouched no matter what the status code was. Without
/// draining it here the server's own explanation of a rejection is discarded
/// and the turn fails with nothing but a status code.
///
/// Returns the parsed JSON envelope when the body is JSON, the raw text when it
/// is not, and `null` when there is no body at all.
Future<Object?> decodeProviderErrorBody(Object? data) async {
  final raw = switch (data) {
    final ResponseBody body => await _drain(body.stream),
    final String text => text,
    null => null,
    final Object other => other,
  };
  if (raw is! String) return raw;
  final text = raw.trim();
  if (text.isEmpty) return null;
  try {
    return jsonDecode(text);
  } on FormatException {
    return text;
  }
}

/// Renders a provider error envelope as a single user-facing sentence.
///
/// OpenAI-compatible servers nest the explanation under `error.message`, but
/// gateways in front of them answer with `detail` or bare text, so every shape
/// has to survive rather than collapse into a generic failure.
String? providerErrorMessage(Object? body) {
  if (body == null) return null;
  if (body is String) return body.isEmpty ? null : body;
  if (body is Map) {
    final error = body['error'];
    if (error is Map && error['message'] is String) {
      return error['message'] as String;
    }
    if (error is String && error.isNotEmpty) return error;
    for (final key in const <String>['message', 'detail']) {
      final value = body[key];
      if (value is String && value.isNotEmpty) return value;
    }
  }
  // An envelope in a shape nobody anticipated is still better diagnostics than
  // a bare status code, so it is restated verbatim. `toEncodable` keeps this
  // total for the already-decoded bodies Dio hands back on non-stream requests.
  return jsonEncode(body, toEncodable: (value) => '$value');
}

/// Prefixes a provider failure with the status code that carried it.
String describeProviderFailure(int? statusCode, String message) =>
    statusCode == null
    ? 'OpenAI request failed: $message'
    : 'OpenAI request failed ($statusCode): $message';

Future<String> _drain(Stream<Uint8List> stream) async {
  final buffer = StringBuffer();
  await for (final chunk in stream) {
    buffer.write(utf8.decode(chunk, allowMalformed: true));
  }
  return buffer.toString();
}
