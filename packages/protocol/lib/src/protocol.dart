import 'dart:convert';

/// Breaking wire protocol major.
const int tinestProtocolMajor = 5;

/// Exact revision supported by this implementation.
///
/// Revision 2 replaces mutable skill management with the read-only catalog
/// contract. An earlier peer cannot decode this catalog, so the handshake
/// rejects the pairing rather than letting it fail later at an arbitrary RPC.
const int tinestProtocolRevision = 2;

/// WebSocket subprotocol offered by v5 clients and servers.
const String tinestWebSocketProtocol = 'tinyrack.tinest.v5';

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
