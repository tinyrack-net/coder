import 'dart:convert';
import 'dart:io';

/// A stdio MCP server the daemon integration test launches for real.
///
/// It publishes one `echo` tool so a turn can call something end to end, and
/// reflects `MCP_ECHO_PREFIX` from its environment so the test can prove that
/// configured environment and secret references reached the child.
Future<void> main() async {
  final prefix = Platform.environment['MCP_ECHO_PREFIX'] ?? '';
  final lines = stdin.transform(utf8.decoder).transform(const LineSplitter());
  await for (final line in lines) {
    if (line.trim().isEmpty) continue;
    final message = jsonDecode(line) as Map<String, dynamic>;
    final id = message['id'];
    if (id == null) continue;
    final result = switch (message['method']) {
      'initialize' => <String, dynamic>{
        'protocolVersion': '2025-06-18',
        'serverInfo': <String, dynamic>{'name': 'fake', 'version': '1.0.0'},
        'capabilities': <String, dynamic>{'tools': <String, dynamic>{}},
      },
      'tools/list' => <String, dynamic>{
        'tools': <dynamic>[
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
      },
      'tools/call' => () {
        final arguments = (message['params'] as Map?)?['arguments'] as Map?;
        return <String, dynamic>{
          'content': <dynamic>[
            <String, dynamic>{
              'type': 'text',
              'text': '$prefix${arguments?['value'] ?? ''}',
            },
          ],
        };
      }(),
      _ => <String, dynamic>{},
    };
    stdout.writeln(
      jsonEncode(<String, dynamic>{
        'jsonrpc': '2.0',
        'id': id,
        'result': result,
      }),
    );
  }
}
