import 'dart:convert';
import 'dart:io';

/// A minimal stdio MCP server used to prove real newline framing.
///
/// It answers `initialize`, `tools/list`, and `tools/call` for a single `echo`
/// tool, and writes one banner line to stdout plus one note to stderr so tests
/// can assert that non-JSON output is tolerated rather than fatal.
Future<void> main() async {
  stdout.writeln('echo-mcp-server starting');
  stderr.writeln('a stderr note');
  final lines = stdin.transform(utf8.decoder).transform(const LineSplitter());
  await for (final line in lines) {
    if (line.trim().isEmpty) continue;
    final message = jsonDecode(line) as Map<String, dynamic>;
    final id = message['id'];
    if (id == null) continue;
    final result = switch (message['method']) {
      'initialize' => <String, dynamic>{
        'protocolVersion': '2025-06-18',
        'serverInfo': <String, dynamic>{'name': 'echo', 'version': '1.0.0'},
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
      'tools/call' => <String, dynamic>{
        'content': <dynamic>[
          <String, dynamic>{
            'type': 'text',
            'text':
                ((message['params'] as Map?)?['arguments'] as Map?)?['value']
                    as String? ??
                '',
          },
        ],
      },
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
