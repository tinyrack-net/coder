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
      expect(tool.description, isNotEmpty, reason: tool.name);
      expect(tool.strictJsonSchema['type'], 'object', reason: tool.name);
      expect(
        tool.strictJsonSchema['additionalProperties'],
        isFalse,
        reason: tool.name,
      );
    }
  });

  test('list contracts preserve every resource and template field', () async {
    host
      ..addDescriptor(
        'alpha',
        const McpResourceDescriptor(
          uri: 'file:///schema.json',
          name: 'schema',
          title: 'Schema',
          description: 'A JSON schema.',
          mimeType: 'application/json',
          sizeBytes: 2,
          annotations: <String, dynamic>{'priority': 1},
          meta: <String, dynamic>{'etag': 'one'},
        ),
      )
      ..addTemplateDescriptor(
        'alpha',
        const McpResourceTemplateDescriptor(
          uriTemplate: 'file:///schema/{name}.json',
          name: 'schema-template',
          title: 'Schema template',
          description: 'Parameterized schema.',
          mimeType: 'application/json',
          annotations: <String, dynamic>{'priority': 1},
          meta: <String, dynamic>{'etag': 'two'},
        ),
      );

    final resourceResult = await ListMcpResourcesTool(host: host).execute(
      const <String, dynamic>{},
      context,
    );
    final resource =
        (decode(resourceResult)['resources']! as List).single
            as Map<String, dynamic>;
    expect(resource, containsPair('name', 'schema'));
    expect(resource, containsPair('title', 'Schema'));
    expect(resource, containsPair('description', 'A JSON schema.'));
    expect(resource, containsPair('mimeType', 'application/json'));
    expect(resource, containsPair('sizeBytes', 2));
    expect(resource, contains('annotations'));
    expect(resource, contains('_meta'));

    final templateResult = await ListMcpResourceTemplatesTool(
      host: host,
    ).execute(const <String, dynamic>{}, context);
    final template =
        (decode(templateResult)['resourceTemplates']! as List).single
            as Map<String, dynamic>;
    expect(template, containsPair('name', 'schema-template'));
    expect(template, containsPair('title', 'Schema template'));
    expect(template, containsPair('description', 'Parameterized schema.'));
    expect(template, containsPair('mimeType', 'application/json'));
    expect(template, contains('annotations'));
    expect(template, contains('_meta'));
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
    final resourceResult = await ListMcpResourcesTool(host: host).execute(
      <String, dynamic>{'server': null, 'cursor': '1'},
      context,
    );

    expect(resourceResult.isError, isTrue);
    expect(decode(resourceResult)['error'], contains('server'));

    final templateResult = await ListMcpResourceTemplatesTool(
      host: host,
    ).execute(<String, dynamic>{'server': null, 'cursor': '1'}, context);
    expect(templateResult.isError, isTrue);
    expect(decode(templateResult)['error'], contains('server'));
  });

  test('a named server preserves its opaque resource cursor', () async {
    for (var index = 0; index < 4; index += 1) {
      host.add('alpha', 'file:///a$index.txt');
    }

    final first = await ListMcpResourcesTool(host: host).execute(
      <String, dynamic>{'server': 'alpha', 'cursor': null},
      context,
    );
    expect(
      decode(first)['resources']! as List<dynamic>,
      hasLength(2),
    );
    final cursor = decode(first)['nextCursor'];
    expect(cursor, 'opaque:2');

    final second = await ListMcpResourcesTool(host: host).execute(
      <String, dynamic>{'server': 'alpha', 'cursor': cursor},
      context,
    );
    expect(decode(second)['resources']! as List<dynamic>, hasLength(2));
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

  test('a server list failure is correctable tool output', () async {
    host.listError = const McpServerException(code: -32000, message: 'down');

    final result = await ListMcpResourcesTool(host: host).execute(
      <String, dynamic>{'server': 'alpha'},
      context,
    );

    expect(result.isError, isTrue);
    expect(decode(result)['error'], contains('down'));
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
    expect(contents.first['_meta'], <String, dynamic>{'kind': 'text'});
    expect(contents.last['blob'], 'AQID');
    expect(contents.last['_meta'], <String, dynamic>{'kind': 'blob'});
    expect(contents.last.containsKey('text'), isFalse);
    expect(result.content.last, isA<ToolEmbeddedResourceContent>());
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
  Exception? listError;

  final Map<String, List<McpResourceDescriptor>> _resources =
      <String, List<McpResourceDescriptor>>{};
  final Map<String, List<McpResourceTemplateDescriptor>> _templates =
      <String, List<McpResourceTemplateDescriptor>>{};

  void add(String server, String uri) => _resources
      .putIfAbsent(server, () => <McpResourceDescriptor>[])
      .add(McpResourceDescriptor(uri: uri));

  void addDescriptor(String server, McpResourceDescriptor descriptor) =>
      _resources
          .putIfAbsent(server, () => <McpResourceDescriptor>[])
          .add(descriptor);

  void addTemplate(String server, String uriTemplate) => _templates
      .putIfAbsent(server, () => <McpResourceTemplateDescriptor>[])
      .add(McpResourceTemplateDescriptor(uriTemplate: uriTemplate));

  void addTemplateDescriptor(
    String server,
    McpResourceTemplateDescriptor descriptor,
  ) => _templates
      .putIfAbsent(server, () => <McpResourceTemplateDescriptor>[])
      .add(descriptor);

  @override
  Future<McpListPage<McpServerResource>> resources({
    String? server,
    String? cursor,
  }) async {
    if (listError case final error?) throw error;
    final all = <McpServerResource>[
      for (final name in _names(server, _resources.keys))
        for (final descriptor in _resources[name]!)
          McpServerResource(server: name, descriptor: descriptor),
    ];
    if (server == null) return McpListPage<McpServerResource>(items: all);
    final offset = cursor == null
        ? 0
        : cursor.startsWith('opaque:')
        ? int.tryParse(cursor.substring('opaque:'.length))
        : null;
    if (offset == null || offset < 0 || offset > all.length) {
      throw const McpProtocolException('Unknown cursor.');
    }
    final end = (offset + 2).clamp(0, all.length);
    return McpListPage<McpServerResource>(
      items: all.sublist(offset, end),
      nextCursor: end < all.length ? 'opaque:$end' : null,
    );
  }

  @override
  Future<McpListPage<McpServerResourceTemplate>> resourceTemplates({
    String? server,
    String? cursor,
  }) async => McpListPage<McpServerResourceTemplate>(
    items: <McpServerResourceTemplate>[
      for (final name in _names(server, _templates.keys))
        for (final descriptor in _templates[name]!)
          McpServerResourceTemplate(server: name, descriptor: descriptor),
    ],
  );

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
          meta: const <String, dynamic>{'kind': 'text'},
        ),
        McpBlobResourceContents(
          uri: uri,
          mimeType: 'image/png',
          blob: 'AQID',
          meta: const <String, dynamic>{'kind': 'blob'},
        ),
      ],
    );
  }

  List<String> _names(String? server, Iterable<String> all) => server == null
      ? (all.toList()..sort())
      : <String>[if (all.contains(server)) server];
}
