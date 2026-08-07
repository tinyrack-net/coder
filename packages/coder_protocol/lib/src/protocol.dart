import 'dart:convert';

/// Breaking wire protocol major.
const int coderProtocolMajor = 4;

/// Exact revision supported by this implementation.
const int coderProtocolRevision = 0;

/// WebSocket subprotocol offered by v4 clients and servers.
const String coderWebSocketProtocol = 'tinyrack.coder.v4';

/// Prefix for browser-compatible bearer-token subprotocols.
const String coderWebSocketTokenPrefix = 'tinyrack.coder.token.';

/// Encodes a bearer token into a WebSocket subprotocol value.
String encodeWebSocketTokenProtocol(String token) =>
    '$coderWebSocketTokenPrefix'
    '${base64Url.encode(utf8.encode(token)).replaceAll('=', '')}';

/// Decodes a bearer token subprotocol, returning null for malformed input.
String? decodeWebSocketTokenProtocol(String protocol) {
  if (!protocol.startsWith(coderWebSocketTokenPrefix)) return null;
  final encoded = protocol.substring(coderWebSocketTokenPrefix.length);
  if (encoded.isEmpty) return null;
  try {
    return utf8.decode(base64Url.decode(base64Url.normalize(encoded)));
  } on FormatException {
    return null;
  }
}

/// Raised when a protocol payload cannot be decoded.
class ProtocolException implements Exception {
  /// Creates a protocol failure.
  const ProtocolException(this.message);

  /// Human-readable protocol failure detail.
  final String message;
  @override
  String toString() => 'ProtocolException: $message';
}
