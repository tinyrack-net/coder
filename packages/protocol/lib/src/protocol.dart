import 'dart:convert';

/// Breaking wire protocol major.
const int tinestProtocolMajor = 4;

/// Exact revision supported by this implementation.
///
/// Revision 1 added the required `group` on `AgentToolDefinitionDto`. A
/// revision-0 peer cannot decode the tool catalog, so the handshake rejects the
/// pairing rather than letting it fail later at an arbitrary RPC.
const int tinestProtocolRevision = 1;

/// WebSocket subprotocol offered by v4 clients and servers.
const String tinestWebSocketProtocol = 'tinyrack.tinest.v4';

/// Prefix for browser-compatible bearer-token subprotocols.
const String tinestWebSocketTokenPrefix = 'tinyrack.tinest.token.';

/// Encodes a bearer token into a WebSocket subprotocol value.
String encodeWebSocketTokenProtocol(String token) =>
    '$tinestWebSocketTokenPrefix'
    '${base64Url.encode(utf8.encode(token)).replaceAll('=', '')}';

/// Decodes a bearer token subprotocol, returning null for malformed input.
String? decodeWebSocketTokenProtocol(String protocol) {
  if (!protocol.startsWith(tinestWebSocketTokenPrefix)) return null;
  final encoded = protocol.substring(tinestWebSocketTokenPrefix.length);
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
