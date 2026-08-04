import 'package:coder_mcp/coder_mcp.dart';

/// A scriptable MCP server that answers requests over a loopback transport.
///
/// Tests drive it by declaring what `initialize` and `tools/list` return, then
/// asserting on [requests] and pushing server-originated notifications.
final class ScriptedMcpServer {
  /// Creates a server that answers with the supplied script.
  ScriptedMcpServer({
    this.protocolVersion = preferredMcpProtocolVersion,
    this.serverName = 'fake',
    this.serverVersion = '1.0.0',
    this.publishesTools = true,
    this.emitsToolListChanged = true,
    List<List<Map<String, dynamic>>>? toolPages,
    this.callResult,
    this.callError,
    this.answerPing = true,
    this.answerToolsList = true,
  }) : toolPages =
           toolPages ??
           <List<Map<String, dynamic>>>[
             <Map<String, dynamic>>[
               <String, dynamic>{
                 'name': 'echo',
                 'description': 'Echoes its argument.',
                 'inputSchema': <String, dynamic>{
                   'type': 'object',
                   'properties': <String, dynamic>{
                     'value': <String, dynamic>{'type': 'string'},
                   },
                 },
               },
             ],
           ];

  /// The revision reported from `initialize`.
  String protocolVersion;

  /// The `serverInfo.name` reported from `initialize`.
  final String serverName;

  /// The `serverInfo.version` reported from `initialize`.
  final String serverVersion;

  /// Whether `initialize` advertises the `tools` capability.
  bool publishesTools;

  /// Whether `initialize` advertises `tools.listChanged`.
  bool emitsToolListChanged;

  /// Pages returned from successive `tools/list` calls.
  List<List<Map<String, dynamic>>> toolPages;

  /// The `tools/call` result, when the call succeeds.
  Map<String, dynamic>? callResult;

  /// The JSON-RPC error returned instead of [callResult].
  Map<String, dynamic>? callError;

  /// Whether inbound `ping` requests get an answer.
  bool answerPing;

  /// Whether `tools/list` requests get an answer.
  bool answerToolsList;

  /// Every message the client sent, in order.
  final List<Map<String, dynamic>> requests = <Map<String, dynamic>>[];

  late final LoopbackMcpTransport _transport = LoopbackMcpTransport(_handle);

  /// The transport the client should be given.
  LoopbackMcpTransport get transport => _transport;

  /// Method names of the requests and notifications received so far.
  List<String> get methods => requests
      .map((request) => request['method'] as String)
      .toList(growable: false);

  /// Pushes a `notifications/tools/list_changed` to the client.
  void announceToolListChanged() => _transport.deliver(<String, dynamic>{
    'jsonrpc': '2.0',
    'method': McpMethod.toolsListChanged,
  });

  /// Sends a server-originated request the client is expected to answer.
  void sendRequest(int id, String method) => _transport.deliver(
    <String, dynamic>{'jsonrpc': '2.0', 'id': id, 'method': method},
  );

  void _handle(Map<String, dynamic> message) {
    requests.add(message);
    final id = message['id'];
    if (id == null) return;
    switch (message['method']) {
      case McpMethod.initialize:
        _respond(id, <String, dynamic>{
          'protocolVersion': protocolVersion,
          'serverInfo': <String, dynamic>{
            'name': serverName,
            'version': serverVersion,
          },
          'capabilities': <String, dynamic>{
            if (publishesTools)
              'tools': <String, dynamic>{'listChanged': emitsToolListChanged},
          },
        });
      case McpMethod.toolsList:
        if (!answerToolsList) return;
        final cursor = (message['params'] as Map?)?['cursor'];
        final index = cursor is String ? int.parse(cursor) : 0;
        final page = index < toolPages.length
            ? toolPages[index]
            : <Map<String, dynamic>>[];
        _respond(id, <String, dynamic>{
          'tools': page,
          if (index + 1 < toolPages.length) 'nextCursor': '${index + 1}',
        });
      case McpMethod.toolsCall:
        if (callError != null) {
          _transport.deliver(<String, dynamic>{
            'jsonrpc': '2.0',
            'id': id,
            'error': callError,
          });
          return;
        }
        _respond(
          id,
          callResult ??
              <String, dynamic>{
                'content': <dynamic>[
                  <String, dynamic>{'type': 'text', 'text': 'ok'},
                ],
              },
        );
      case McpMethod.ping:
        if (answerPing) _respond(id, <String, dynamic>{});
    }
  }

  void _respond(Object? id, Map<String, dynamic> result) => _transport.deliver(
    <String, dynamic>{'jsonrpc': '2.0', 'id': id, 'result': result},
  );
}
