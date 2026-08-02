import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Public API exposed by this library.
abstract interface class WebSocketConnector {
  /// The connect public API member.
  Future<WebSocketChannel> connect(
    Uri uri, {
    required Map<String, String> headers,
  });
}

/// IoWebSocketConnector defines a public contract.
final class IoWebSocketConnector implements WebSocketConnector {
  /// Creates a [IoWebSocketConnector].
  const IoWebSocketConnector({
    this.connectTimeout = const Duration(seconds: 10),
    this.pingInterval = const Duration(seconds: 10),
  });

  /// The connectTimeout public API member.
  final Duration connectTimeout;

  /// The pingInterval public API member.
  final Duration pingInterval;

  @override
  Future<WebSocketChannel> connect(
    Uri uri, {
    required Map<String, String> headers,
  }) async {
    final channel = IOWebSocketChannel.connect(
      uri,
      headers: headers,
      connectTimeout: connectTimeout,
      pingInterval: pingInterval,
    );
    await channel.ready;
    return channel;
  }
}
