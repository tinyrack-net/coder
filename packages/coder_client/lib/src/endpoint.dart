/// HostEndpoint defines a public contract.
class HostEndpoint {
  /// Creates a [HostEndpoint].
  const HostEndpoint({required this.websocketUri});

  /// Creates a [HostEndpoint].
  factory HostEndpoint.parse(String address) {
    final normalized = address.trim();
    if (normalized.isEmpty) {
      throw const FormatException('Endpoint address must not be empty.');
    }
    final entered = Uri.tryParse(normalized);
    if (entered?.hasScheme == true &&
        entered!.scheme != 'ws' &&
        entered.scheme != 'wss') {
      throw FormatException('Endpoint must use ws:// or wss://.', address);
    }
    final hasWebSocketScheme = RegExp(
      '^wss?://',
      caseSensitive: false,
    ).hasMatch(normalized);
    var uri = Uri.parse(
      hasWebSocketScheme ? normalized : 'ws://$normalized',
    );
    if (uri.path.isEmpty || uri.path == '/') uri = uri.replace(path: '/ws');
    if (uri.scheme != 'ws' && uri.scheme != 'wss') {
      throw FormatException('Endpoint must use ws:// or wss://.', address);
    }
    if (uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.fragment.isNotEmpty) {
      throw FormatException(
        'Endpoint must contain a host and no credentials or fragment.',
        address,
      );
    }
    return HostEndpoint(websocketUri: uri);
  }

  /// The websocketUri public API member.
  final Uri websocketUri;
}

/// Secret credentials sent while opening a daemon transport.
final class DaemonCredentials {
  /// Creates daemon connection credentials.
  const DaemonCredentials({required this.bearerToken});

  /// Token authenticating full daemon API access.
  final String bearerToken;

  @override
  String toString() => 'DaemonCredentials(<redacted>)';
}
