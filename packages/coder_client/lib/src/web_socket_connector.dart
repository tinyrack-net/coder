import 'dart:convert';

import 'package:coder_client/src/web_socket_connector_io.dart'
    if (dart.library.js_interop) 'package:coder_client/src/web_socket_connector_web.dart'
    as platform;
import 'package:web_socket_channel/web_socket_channel.dart';

/// Subprotocol that identifies a Tinyrack Coder client.
const String coderWebSocketProtocol = 'tinyrack.coder.v3';

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

/// Code carried by the failure raised when a browser cannot reach a daemon
/// on the user's own machine or network.
///
/// A browser refuses to say why such a connection failed, so this reports the
/// address that was attempted rather than a diagnosis. See
/// `docs/remote-daemon.md`.
const String localNetworkUnreachableCode = 'local_network_unreachable';

/// Whether [uri] addresses the machine or private network of its client.
///
/// A page served from a public origin needs the browser's Local Network
/// Access permission to reach any of these, so a failure against one has a
/// cause that a failure against a public address does not.
bool targetsLocalNetwork(Uri uri) {
  final host = uri.host.toLowerCase();
  if (host.isEmpty) return false;
  if (host == 'localhost' || host.endsWith('.localhost')) return true;
  // mDNS names resolve to the local link by definition.
  if (host.endsWith('.local')) return true;
  final octets = _parseIpv4(host);
  if (octets != null) return _isPrivateIpv4(octets);
  return _isLocalIpv6(host);
}

/// Returns the four octets of [host], or null when it is not dotted-quad IPv4.
List<int>? _parseIpv4(String host) {
  final parts = host.split('.');
  if (parts.length != 4) return null;
  final octets = <int>[];
  for (final part in parts) {
    // `int.tryParse` accepts a leading sign and would let `+10.0.0.1` through.
    if (part.isEmpty || part.length > 3 || !_isDigits(part)) return null;
    final value = int.parse(part);
    if (value > 255) return null;
    octets.add(value);
  }
  return octets;
}

bool _isDigits(String value) {
  for (final unit in value.codeUnits) {
    if (unit < 0x30 || unit > 0x39) return false;
  }
  return true;
}

bool _isPrivateIpv4(List<int> octets) {
  final [first, second, ...] = octets;
  if (first == 127) return true; // 127.0.0.0/8 loopback
  if (first == 10) return true; // 10.0.0.0/8
  if (first == 172 && second >= 16 && second <= 31) return true; // 172.16/12
  if (first == 192 && second == 168) return true; // 192.168.0.0/16
  if (first == 169 && second == 254) return true; // 169.254.0.0/16 link-local
  return false;
}

bool _isLocalIpv6(String host) {
  // Only an address can be one of these prefixes; `fdsomething.com` is an
  // ordinary name that merely starts like a unique-local address.
  if (!host.contains(':')) return false;
  if (host == '::1') return true; // loopback
  // fc00::/7 unique local, then fe80::/10 link-local.
  if (host.startsWith('fc') || host.startsWith('fd')) return true;
  return RegExp('^fe[89ab]').hasMatch(host);
}

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
