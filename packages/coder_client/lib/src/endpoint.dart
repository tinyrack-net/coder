/// HostEndpoint defines a public contract.
class HostEndpoint {
  /// Creates a [HostEndpoint].
  const HostEndpoint({required this.websocketUri, required this.token});

  /// Creates a [HostEndpoint].
  factory HostEndpoint.parse(String address, {required String token}) {
    final hasWebSocketScheme = RegExp(
      '^wss?://',
      caseSensitive: false,
    ).hasMatch(address);
    var uri = Uri.parse(hasWebSocketScheme ? address : 'ws://$address');
    if (uri.path.isEmpty || uri.path == '/') uri = uri.replace(path: '/ws');
    if (uri.scheme != 'ws' && uri.scheme != 'wss') {
      throw FormatException('Endpoint must use ws:// or wss://.', address);
    }
    return HostEndpoint(websocketUri: uri, token: token);
  }

  /// The websocketUri public API member.
  final Uri websocketUri;

  /// The token public API member.
  final String token;
}
