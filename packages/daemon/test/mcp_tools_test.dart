@Tags(<String>['feature_test__mcp_tool_execution__unit'])
library;

import 'dart:convert';

import 'package:agent/agent.dart';
import 'package:daemon/src/features/mcp/infrastructure/mcp.dart';
import 'package:daemon/src/features/mcp/infrastructure/mcp_tools.dart';
import 'package:daemon/src/features/mcp/infrastructure/testing.dart';
import 'package:test/test.dart';

void main() {
  group('risk grading', () {
    McpAgentTool toolFor(Map<String, dynamic>? annotations) => McpAgentTool(
      serverId: 'github',
      descriptor: McpToolDescriptor.fromJson(<String, dynamic>{
        'name': 'lookup',
        'annotations': ?annotations,
      }),
      lookup: (_) => null,
    );

    test('server annotations never relax the external-call boundary', () {
      expect(
        toolFor(<String, dynamic>{'readOnlyHint': true}).risk,
        AgentToolRisk.dangerous,
      );
    });

    test('anything else stays dangerous', () {
      // No annotations at all is the common case, and says nothing.
      expect(toolFor(null).risk, AgentToolRisk.dangerous);
      expect(
        toolFor(<String, dynamic>{'readOnlyHint': false}).risk,
        AgentToolRisk.dangerous,
      );
      // "Not destructive" is still a change the user should get to see.
      expect(
        toolFor(<String, dynamic>{'destructiveHint': false}).risk,
        AgentToolRisk.dangerous,
      );
    });

    test('every external MCP call is denied under a read-only policy', () {
      const policy = DefaultApprovalPolicy(AgentPermissionMode.readOnly);

      expect(
        policy.evaluate(
          ToolInvocation(
            callId: 'call',
            name: 'mcp__github__lookup',
            arguments: const <String, dynamic>{},
            risk: toolFor(<String, dynamic>{'readOnlyHint': true}).risk,
            workspaceRoot: '/workspace',
          ),
        ),
        ApprovalEvaluation.deny,
      );
      expect(
        policy.evaluate(
          ToolInvocation(
            callId: 'call',
            name: 'mcp__github__lookup',
            arguments: const <String, dynamic>{},
            risk: toolFor(null).risk,
            workspaceRoot: '/workspace',
          ),
        ),
        ApprovalEvaluation.deny,
      );
    });
  });
  final context = ToolExecutionContext(
    workspaceRoot: '/workspace',
    cancellation: CancellationToken(),
  );

  group('tool ids', () {
    test('namespacing round-trips through parsing', () {
      expect(mcpToolId('github', 'create_issue'), 'mcp__github__create_issue');
      expect(
        parseMcpToolId('mcp__github__create_issue'),
        (server: 'github', tool: 'create_issue'),
      );
      // A tool name may itself contain the separator; the server may not.
      expect(
        parseMcpToolId('mcp__github__a__b'),
        (server: 'github', tool: 'a__b'),
      );
    });

    test('an id that is not namespaced parses to null', () {
      expect(parseMcpToolId('read_file'), isNull);
      expect(parseMcpToolId('mcp__github'), isNull);
      expect(parseMcpToolId('mcp____tool'), isNull);
      expect(parseMcpToolId('mcp__server__'), isNull);
    });
  });

  group('schema normalization', () {
    test('a missing or empty schema becomes an empty object schema', () {
      const expected = <String, dynamic>{
        'type': 'object',
        'properties': <String, dynamic>{},
        'additionalProperties': false,
      };
      expect(normalizeMcpInputSchema(null), expected);
      expect(normalizeMcpInputSchema(<String, dynamic>{}), expected);
    });

    test('a declared schema passes through untouched', () {
      final schema = <String, dynamic>{
        'type': 'object',
        'properties': <String, dynamic>{
          'title': <String, dynamic>{'type': 'string', 'default': 'x'},
        },
        // Optional properties and loose objects are exactly what strict mode
        // rejects, so they must survive rather than be rewritten.
        'required': <String>['title'],
      };

      expect(normalizeMcpInputSchema(schema), schema);
    });

    test('an implied object type is filled in', () {
      expect(
        normalizeMcpInputSchema(<String, dynamic>{
          'properties': <String, dynamic>{
            'x': <String, dynamic>{'type': 'string'},
          },
        }),
        <String, dynamic>{
          'type': 'object',
          'properties': <String, dynamic>{
            'x': <String, dynamic>{'type': 'string'},
          },
        },
      );
      expect(
        normalizeMcpInputSchema(<String, dynamic>{'type': 'object'}),
        <String, dynamic>{
          'type': 'object',
          'properties': <String, dynamic>{},
        },
      );
    });

    test('a non-object schema is rejected', () {
      expect(
        () => normalizeMcpInputSchema(<String, dynamic>{'type': 'string'}),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('output rendering', () {
    String render(Map<String, dynamic> json) =>
        renderMcpToolOutput(McpCallToolResult.fromJson(json));

    test('structured content wins over the rendered blocks', () {
      expect(
        render(<String, dynamic>{
          'content': <dynamic>[
            <String, dynamic>{'type': 'text', 'text': 'ignored'},
          ],
          'structuredContent': <String, dynamic>{'count': 2},
        }),
        '{"count":2}',
      );
    });

    test('every block kind renders to a readable line', () {
      expect(
        render(<String, dynamic>{
          'content': <dynamic>[
            <String, dynamic>{'type': 'text', 'text': 'first'},
            <String, dynamic>{
              'type': 'resource',
              'resource': <String, dynamic>{
                'uri': 'file:///a.txt',
                'text': 'body',
              },
            },
            <String, dynamic>{
              'type': 'resource',
              'resource': <String, dynamic>{
                'uri': 'file:///a.bin',
                'mimeType': 'application/zip',
                'blob': 'AAAA',
              },
            },
            <String, dynamic>{
              'type': 'resource_link',
              'uri': 'https://example.test/d',
              'name': 'doc',
            },
            <String, dynamic>{
              'type': 'image',
              'mimeType': 'image/png',
              'data': 'AAAA',
            },
            <String, dynamic>{
              'type': 'audio',
              'mimeType': 'audio/wav',
              'data': 'AAAA',
            },
            <String, dynamic>{'type': 'future_block'},
          ],
        }),
        'first\n\n'
        'file:///a.txt\nbody\n\n'
        '[resource uri=file:///a.bin mimeType=application/zip bytes=3]\n\n'
        '[resource_link uri=https://example.test/d name=doc]\n\n'
        '[image mimeType=image/png bytes=3]\n\n'
        '[audio mimeType=audio/wav bytes=3]\n\n'
        '[unsupported content type=future_block]',
      );
    });

    test('an empty result renders as empty output', () {
      expect(render(<String, dynamic>{}), isEmpty);
      expect(render(<String, dynamic>{'content': <dynamic>[]}), isEmpty);
    });

    test('oversized output is truncated to the shared limit', () {
      final rendered = render(<String, dynamic>{
        'content': <dynamic>[
          <String, dynamic>{
            'type': 'text',
            'text': 'x' * (maxToolOutputBytes + 100),
          },
        ],
      });

      expect(utf8.encode(rendered).length, maxToolOutputBytes);
    });
  });

  group('as an agent tool', () {
    late ScriptedMcpServer server;
    late McpClient client;

    Future<McpAgentTool> connect({
      Map<String, dynamic>? callResult,
      Map<String, dynamic>? callError,
      Map<String, dynamic>? inputSchema,
    }) async {
      server = ScriptedMcpServer(
        callResult: callResult,
        callError: callError,
        toolPages: <List<Map<String, dynamic>>>[
          <Map<String, dynamic>>[
            <String, dynamic>{
              'name': 'create_issue',
              'title': 'Create issue',
              'description': 'Opens an issue.',
              'inputSchema': ?inputSchema,
            },
          ],
        ],
      );
      client = McpClient(transport: server.transport);
      addTearDown(client.close);
      await client.connect();
      return McpAgentTool(
        serverId: 'github',
        descriptor: client.tools.single,
        lookup: (id) => id == 'github' ? client : null,
      );
    }

    test('the contract a provider sees is namespaced and non-strict', () async {
      final tool = await connect(
        inputSchema: <String, dynamic>{
          'type': 'object',
          'properties': <String, dynamic>{
            'title': <String, dynamic>{'type': 'string'},
          },
        },
      );

      expect(tool.name, 'mcp__github__create_issue');
      expect(tool.description, 'Opens an issue.');
      expect(tool.risk, AgentToolRisk.dangerous);
      expect(tool.strict, isFalse);
      expect(tool.strictJsonSchema['properties'], contains('title'));
      expect(
        await tool.preview(const <String, dynamic>{}, context),
        'github.Create issue',
      );
    });

    test('a tool without a description falls back to its name', () async {
      server = ScriptedMcpServer(
        toolPages: <List<Map<String, dynamic>>>[
          <Map<String, dynamic>>[
            <String, dynamic>{'name': 'bare'},
          ],
        ],
      );
      client = McpClient(transport: server.transport);
      addTearDown(client.close);
      await client.connect();
      final tool = McpAgentTool(
        serverId: 'github',
        descriptor: client.tools.single,
        lookup: (_) => client,
      );

      expect(tool.description, 'bare');
      expect(
        await tool.preview(const <String, dynamic>{}, context),
        'github.bare',
      );
    });

    test('a call forwards its arguments and renders the result', () async {
      final tool = await connect(
        callResult: <String, dynamic>{
          'content': <dynamic>[
            <String, dynamic>{'type': 'text', 'text': 'opened #7'},
          ],
        },
      );

      final result = await tool.execute(
        <String, dynamic>{'title': 'Bug'},
        context,
      );

      expect(result.output, 'opened #7');
      expect(result.isError, isFalse);
      final call = server.requests.last['params']! as Map<String, dynamic>;
      expect(call['name'], 'create_issue');
      expect(call['arguments'], <String, dynamic>{'title': 'Bug'});
    });

    test('a call preserves every MCP content block and metadata', () async {
      final tool = await connect(
        callResult: <String, dynamic>{
          'content': <dynamic>[
            <String, dynamic>{
              'type': 'text',
              'text': 'text',
              'annotations': <String, dynamic>{'priority': 1},
              '_meta': <String, dynamic>{'source': 'server'},
            },
            <String, dynamic>{
              'type': 'image',
              'mimeType': 'image/png',
              'data': 'AA==',
            },
            <String, dynamic>{
              'type': 'audio',
              'mimeType': 'audio/wav',
              'data': 'AA==',
            },
            <String, dynamic>{
              'type': 'resource',
              'resource': <String, dynamic>{
                'uri': 'file:///schema',
                'mimeType': 'application/json',
                'text': '{}',
                '_meta': <String, dynamic>{'etag': 'one'},
              },
            },
            <String, dynamic>{
              'type': 'resource_link',
              'uri': 'file:///schema',
              'name': 'schema',
              'title': 'Schema',
              'description': 'JSON schema.',
              'mimeType': 'application/json',
              'size': 2,
            },
            <String, dynamic>{
              'type': 'future',
              'value': 1,
              '_meta': <String, dynamic>{'future': true},
            },
          ],
          'structuredContent': <String, dynamic>{'ok': true},
          '_meta': <String, dynamic>{'trace': 'one'},
        },
      );

      final result = await tool.execute(const <String, dynamic>{}, context);

      expect(result.value, <String, dynamic>{'ok': true});
      expect(result.content, hasLength(6));
      expect(result.content[0], isA<ToolTextContent>());
      expect(result.content[1], isA<ToolImageContent>());
      expect(result.content[2], isA<ToolAudioContent>());
      expect(result.content[3], isA<ToolEmbeddedResourceContent>());
      expect(result.content[4], isA<ToolResourceLinkContent>());
      expect(result.content[5], isA<ToolTextContent>());
      expect(result.meta, <String, dynamic>{'trace': 'one'});
    });

    test('a tool-reported failure keeps its output and error flag', () async {
      final tool = await connect(
        callResult: <String, dynamic>{
          'content': <dynamic>[
            <String, dynamic>{'type': 'text', 'text': 'not found'},
          ],
          'isError': true,
        },
      );

      final result = await tool.execute(const <String, dynamic>{}, context);

      expect(result.output, 'not found');
      expect(result.isError, isTrue);
    });

    test('a protocol error becomes tool output, never an exception', () async {
      final tool = await connect(
        callError: <String, dynamic>{'code': -32602, 'message': 'bad args'},
      );

      final result = await tool.execute(const <String, dynamic>{}, context);

      expect(result.isError, isTrue);
      expect(
        jsonDecode(result.output),
        <String, dynamic>{
          'error': 'McpServerException(-32602): bad args',
        },
      );
    });

    test('an offline server reports itself instead of throwing', () async {
      final tool = await connect();
      await client.close();

      final result = await tool.execute(const <String, dynamic>{}, context);

      expect(result.isError, isTrue);
      expect(
        (jsonDecode(result.output) as Map<String, dynamic>)['error'],
        contains('is not connected'),
      );
    });

    test('an unknown server reports itself instead of throwing', () async {
      final tool = await connect();
      final orphan = McpAgentTool(
        serverId: 'absent',
        descriptor: tool.descriptor,
        lookup: (_) => null,
      );

      final result = await orphan.execute(const <String, dynamic>{}, context);

      expect(result.isError, isTrue);
      expect(
        (jsonDecode(result.output) as Map<String, dynamic>)['error'],
        contains('"absent" is not connected'),
      );
    });
  });
}
