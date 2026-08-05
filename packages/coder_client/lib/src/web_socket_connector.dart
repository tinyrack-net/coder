import 'dart:convert';

import 'package:coder_client/src/web_socket_connector_io.dart'
    if (dart.library.js_interop) 'package:coder_client/src/web_socket_connector_web.dart'
    as platform;
import 'package:web_socket_channel/web_socket_channel.dart';

/// Subprotocol that identifies a Tinyrack Coder client.
const String coderWebSocketProtocol = 'tinyrack.coder.v2';

/// Prefix of the subprotocol that carries the bearer token.
const String coderWebSocketTokenPrefix = 'tinyrack.coder.token.';

/// Public API exposed by this library.
abstract interface class WebSocketConnector {
  /// The connect public API member.
  Future<WebSocketChannel> connect(
    Uri uri, {
    required Map<String, String> headers,
  });
}

/// The connector for the platform this program runs on.
///
/// Browsers cannot set request headers on a WebSocket, so the web connector
/// carries the bearer token in a subprotocol instead.
WebSocketConnector createWebSocketConnector() => platform.createConnector();

/// Encodes [token] into the subprotocol that stands in for the bearer header.
///
/// A subprotocol may only contain RFC 7230 token characters, so the value is
/// base64url encoded rather than sent verbatim: an operator-supplied token is
/// an arbitrary string and would otherwise produce an invalid handshake.
String encodeWebSocketTokenProtocol(String token) =>
    '$coderWebSocketTokenPrefix'
    '${base64Url.encode(utf8.encode(token)).replaceAll('=', '')}';

/// Recovers the bearer token from [protocol], or null when it carries none.
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
