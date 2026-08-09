@Tags(<String>['feature_test__mcp_resource_access__unit'])
library;

import 'dart:convert';

import 'package:agent/agent.dart';
import 'package:daemon/src/features/mcp/infrastructure/mcp.dart';
import 'package:daemon/src/features/mcp/infrastructure/mcp_resource_tools.dart';
import 'package:daemon/src/features/mcp/infrastructure/mcp_service.dart';
import 'package:test/test.dart';

void main() {
  late _FakeResourceHost host;
  late ToolExecutionContext context;

  setUp(() {
    host = _FakeResourceHost();
    context = ToolExecutionContext(
      workspaceRoot: '/workspace',
      cancellation: CancellationToken(),
    );
  });

  Map<String, dynamic> decode(ToolResult result) =>
      jsonDecode(result.output) as Map<String, dynamic>;

  test('every resource tool reads without asking for approval', () {
    for (final tool in <AgentTool>[
      ListMcpResourcesTool(host: host),
      ListMcpResourceTemplatesTool(host: host),
      ReadMcpResourceTool(host: host),
    ]) {
      expect(tool.risk, AgentToolRisk.read, reason: tool.name);
      expect(
        const DefaultApprovalPolicy(
          AgentPermissionMode.readOnly,
        ).evaluateRisk(tool.risk),
        ApprovalEvaluation.allow,
        reason: tool.name,
      );
    }
  });

  test('omitting the server fans out sorted by server name', () async {
    host
      ..add('zeta', 'file:///z1.txt')
      ..add('alpha', 'file:///a1.txt')
      ..add('alpha', 'file:///a2.txt');

    final result = await ListMcpResourcesTool(host: host).execute(
      <String, dynamic>{'server': null, 'cursor': null},
      context,
    );

    final resources = (decode(result)['resources']! as List<dynamic>)
        .cast<Map<String, dynamic>>();
    // Every entry is flattened with the server that owns it.
    expect(
      resources.map((item) => '${item['server']}:${item['uri']}'),
      <String>[
        'alpha:file:///a1.txt',
        'alpha:file:///a2.txt',
        'zeta:file:///z1.txt',
      ],
    );
    // Fan-out is unpaginated, so it never offers a cursor.
    expect(decode(result).containsKey('nextCursor'), isFalse);
    expect(decode(result)['truncated'], isFalse);
  });

  test('a blank server or cursor is treated as absent', () async {
    host.add('alpha', 'file:///a.txt');

    final result = await ListMcpResourcesTool(host: host).execute(
      <String, dynamic>{'server': '   ', 'cursor': ''},
      context,
    );

    expect(result.isError, isFalse);
    expect(decode(result)['resources']! as List<dynamic>, hasLength(1));
  });

  test('a cursor without a server is refused', () async {
    final result = await ListMcpResourcesTool(host: host).execute(
      <String, dynamic>{'server': null, 'cursor': '1'},
      context,
    );

    expect(result.isError, isTrue);
    expect(decode(result)['error'], contains('server'));
  });

  test('a named server pages its resources with an offset cursor', () async {
    for (var index = 0; index < mcpResourcePageSize + 2; index += 1) {
      host.add('alpha', 'file:///a$index.txt');
    }

    final first = await ListMcpResourcesTool(host: host).execute(
      <String, dynamic>{'server': 'alpha', 'cursor': null},
      context,
    );
    expect(
      decode(first)['resources']! as List<dynamic>,
      hasLength(mcpResourcePageSize),
    );
    expect(decode(first)['truncated'], isTrue);
    final cursor = decode(first)['nextCursor'];
    expect(cursor, isNotNull);

    final second = await ListMcpResourcesTool(host: host).execute(
      <String, dynamic>{'server': 'alpha', 'cursor': cursor},
      context,
    );
    expect(decode(second)['resources']! as List<dynamic>, hasLength(2));
    expect(decode(second)['truncated'], isFalse);
    expect(decode(second).containsKey('nextCursor'), isFalse);
  });

  test('an unusable cursor is refused rather than silently reset', () async {
    host.add('alpha', 'file:///a.txt');

    for (final cursor in <String>['abc', '-1']) {
      final result = await ListMcpResourcesTool(host: host).execute(
        <String, dynamic>{'server': 'alpha', 'cursor': cursor},
        context,
      );
      expect(result.isError, isTrue, reason: cursor);
    }
  });

  test('templates list through the same rules', () async {
    host
      ..addTemplate('zeta', 'file:///z/{p}')
      ..addTemplate('alpha', 'file:///a/{p}');

    final result = await ListMcpResourceTemplatesTool(host: host).execute(
      <String, dynamic>{'server': null, 'cursor': null},
      context,
    );

    final templates = (decode(result)['resourceTemplates']! as List<dynamic>)
        .cast<Map<String, dynamic>>();
    expect(templates.map((item) => item['server']), <String>['alpha', 'zeta']);
    expect(templates.first['uriTemplate'], 'file:///a/{p}');
  });

  test('reading returns text and blob contents separately', () async {
    host.add('alpha', 'file:///a.txt');

    final result = await ReadMcpResourceTool(host: host).execute(
      <String, dynamic>{'server': 'alpha', 'uri': 'file:///a.txt'},
      context,
    );

    expect(result.isError, isFalse);
    final decoded = decode(result);
    expect(decoded['server'], 'alpha');
    expect(decoded['uri'], 'file:///a.txt');
    final contents = (decoded['contents']! as List<dynamic>)
        .cast<Map<String, dynamic>>();
    expect(contents.first['text'], 'body of file:///a.txt');
    expect(contents.last['byteLength'], 3);
    expect(contents.last.containsKey('text'), isFalse);
  });

  test('an offline server is a correctable error, not a failed turn', () async {
    final result = await ReadMcpResourceTool(host: host).execute(
      <String, dynamic>{'server': 'missing', 'uri': 'file:///a.txt'},
      context,
    );

    expect(result.isError, isTrue);
    expect(decode(result)['error'], contains('missing'));
  });

  test('a read needs both a server and a uri', () async {
    for (final arguments in <Map<String, dynamic>>[
      <String, dynamic>{'server': '', 'uri': 'file:///a.txt'},
      <String, dynamic>{'server': 'alpha', 'uri': ''},
    ]) {
      final result = await ReadMcpResourceTool(
        host: host,
      ).execute(arguments, context);
      expect(result.isError, isTrue, reason: '$arguments');
    }
  });
}

/// A host that answers from in-memory descriptors instead of live servers.
final class _FakeResourceHost implements McpResourceHost {
  final Map<String, List<McpResourceDescriptor>> _resources =
      <String, List<McpResourceDescriptor>>{};
  final Map<String, List<McpResourceTemplateDescriptor>> _templates =
      <String, List<McpResourceTemplateDescriptor>>{};

  void add(String server, String uri) => _resources
      .putIfAbsent(server, () => <McpResourceDescriptor>[])
      .add(McpResourceDescriptor(uri: uri));

  void addTemplate(String server, String uriTemplate) => _templates
      .putIfAbsent(server, () => <McpResourceTemplateDescriptor>[])
      .add(McpResourceTemplateDescriptor(uriTemplate: uriTemplate));

  @override
  List<McpServerResource> resources({String? server}) => <McpServerResource>[
    for (final name in _names(server, _resources.keys))
      for (final descriptor in _resources[name]!)
        McpServerResource(server: name, descriptor: descriptor),
  ];

  @override
  List<McpServerResourceTemplate> resourceTemplates({String? server}) =>
      <McpServerResourceTemplate>[
        for (final name in _names(server, _templates.keys))
          for (final descriptor in _templates[name]!)
            McpServerResourceTemplate(server: name, descriptor: descriptor),
      ];

  @override
  Future<McpReadResourceResult> readResource({
    required String server,
    required String uri,
  }) async {
    if (!_resources.containsKey(server)) {
      throw McpServerUnavailable(server);
    }
    return McpReadResourceResult(
      contents: <McpResourceContents>[
        McpTextResourceContents(
          uri: uri,
          mimeType: 'text/plain',
          text: 'body of $uri',
        ),
        McpBlobResourceContents(
          uri: uri,
          mimeType: 'image/png',
          byteLength: 3,
        ),
      ],
    );
  }

  List<String> _names(String? server, Iterable<String> all) => server == null
      ? (all.toList()..sort())
      : <String>[if (all.contains(server)) server];
}
