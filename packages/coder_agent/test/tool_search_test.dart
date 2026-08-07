@Tags(<String>['feature_test__tool_search_deferred__unit'])
library;

import 'dart:convert';

import 'package:coder_agent/coder_agent.dart';
import 'package:test/test.dart';

void main() {
  ToolExecutionContext context() => ToolExecutionContext(
    workspaceRoot: '/workspace',
    cancellation: CancellationToken(),
  );

  group('tokenizer', () {
    test('splits on separators and camelCase, and drops stopwords', () {
      expect(tokenizeToolSearch('create_pull_request'), <String>[
        'create',
        'pull',
        'request',
      ]);
      // An MCP id carries its server and tool name in one token.
      expect(tokenizeToolSearch('mcp__github__createIssue'), <String>[
        'mcp',
        'github',
        'create',
        'issue',
      ]);
      expect(tokenizeToolSearch('Open a PR for the branch'), <String>[
        'open',
        'pr',
        'branch',
      ]);
      expect(tokenizeToolSearch('   '), isEmpty);
    });
  });

  group('document', () {
    test('collects the name, description, and every schema label', () {
      final terms = buildToolSearchDocument(
        _FakeTool(
          name: 'create_issue',
          description: 'Opens a tracker ticket.',
          schema: <String, dynamic>{
            'type': 'object',
            'properties': <String, dynamic>{
              'title': <String, dynamic>{
                'type': 'string',
                'description': 'Headline of the ticket.',
              },
              'labels': <String, dynamic>{
                'type': 'array',
                'items': <String, dynamic>{
                  'type': 'object',
                  'properties': <String, dynamic>{
                    'colour': <String, dynamic>{'type': 'string'},
                  },
                },
              },
            },
          },
        ),
      );

      expect(terms, containsAll(<String>['create', 'issue']));
      expect(terms, containsAll(<String>['opens', 'tracker', 'ticket']));
      // Property names are searchable even without a description.
      expect(terms, contains('title'));
      expect(terms, contains('headline'));
      expect(terms, contains('labels'));
      // Nested schemas are walked through items.
      expect(terms, contains('colour'));
    });

    test('a hostile schema cannot blow up the index', () {
      Map<String, dynamic> nest(int depth) => depth == 0
          ? <String, dynamic>{'type': 'string', 'description': 'deepest'}
          : <String, dynamic>{
              'type': 'object',
              'properties': <String, dynamic>{'level$depth': nest(depth - 1)},
            };

      final deep = buildToolSearchDocument(
        _FakeTool(name: 'deep', description: '', schema: nest(40)),
      );
      expect(deep, isNot(contains('deepest')));
      expect(deep.length, lessThanOrEqualTo(maxToolSearchTerms));

      final wide = buildToolSearchDocument(
        _FakeTool(
          name: 'wide',
          description: '',
          schema: <String, dynamic>{
            'type': 'object',
            'properties': <String, dynamic>{
              for (var index = 0; index < 5000; index += 1)
                'property$index': <String, dynamic>{'type': 'string'},
            },
          },
        ),
      );
      expect(wide.length, lessThanOrEqualTo(maxToolSearchTerms));
    });
  });

  group('index', () {
    final tools = <AgentTool>[
      _FakeTool(
        name: 'mcp__github__create_pull_request',
        description: 'Opens a pull request against a branch.',
      ),
      _FakeTool(
        name: 'mcp__github__list_issues',
        description: 'Lists tracker issues.',
      ),
      _FakeTool(
        name: 'mcp__calendar__create_event',
        description: 'Adds an event to a calendar.',
      ),
    ];

    test('a prose query finds the tool a substring match would miss', () {
      final index = ToolSearchIndex(tools);

      final hits = index.search('open a pull request', limit: 2);

      expect(hits.first.name, 'mcp__github__create_pull_request');
    });

    test('ranking is stable when scores tie', () {
      // Two tools that share every term must not reorder between runs.
      final index = ToolSearchIndex(<AgentTool>[
        _FakeTool(name: 'beta_tool', description: 'shared words here'),
        _FakeTool(name: 'alpha_tool', description: 'shared words here'),
      ]);

      for (var run = 0; run < 5; run += 1) {
        expect(
          index.search('shared words', limit: 2).map((t) => t.name),
          <String>[
            'alpha_tool',
            'beta_tool',
          ],
        );
      }
    });

    test('the limit bounds the result and a miss returns nothing', () {
      final index = ToolSearchIndex(tools);

      expect(index.search('create', limit: 1), hasLength(1));
      expect(index.search('quantum chromodynamics', limit: 8), isEmpty);
      expect(index.search('   ', limit: 8), isEmpty);
    });
  });

  group('tool_search', () {
    test('surfaces matches and reports what is still hidden', () async {
      final deferred = <AgentTool>[
        _FakeTool(name: 'mcp__a__alpha', description: 'Alpha things.'),
        _FakeTool(name: 'mcp__a__beta', description: 'Beta things.'),
        _FakeTool(name: 'mcp__a__gamma', description: 'Gamma things.'),
      ];
      final surfaced = <String>{};
      final tool = ToolSearchTool(
        deferred: deferred,
        onSurfaced: surfaced.addAll,
      );

      expect(tool.risk, AgentToolRisk.read);
      expect(tool.name, toolSearchToolName);

      final result = await tool.execute(<String, dynamic>{
        'query': 'alpha',
        'limit': 1,
      }, context());

      final decoded = jsonDecode(result.output) as Map<String, dynamic>;
      final found = (decoded['tools']! as List<dynamic>)
          .cast<Map<String, dynamic>>();
      expect(found.single['name'], 'mcp__a__alpha');
      // The full schema goes back so the model can call it immediately.
      expect(found.single['parameters'], isA<Map<String, dynamic>>());
      expect(decoded['remaining'], 2);
      expect(surfaced, <String>{'mcp__a__alpha'});
    });

    test('an empty query is corrected rather than searched', () async {
      var surfacedCalls = 0;
      final tool = ToolSearchTool(
        deferred: <AgentTool>[_FakeTool(name: 'a', description: 'a')],
        onSurfaced: (_) => surfacedCalls += 1,
      );

      final result = await tool.execute(
        <String, dynamic>{'query': '  ', 'limit': null},
        context(),
      );

      expect(result.isError, isTrue);
      expect(surfacedCalls, 0);
    });

    test('the limit is clamped and defaults when absent', () async {
      final deferred = <AgentTool>[
        for (var index = 0; index < 40; index += 1)
          _FakeTool(name: 'tool_$index', description: 'shared thing'),
      ];
      final tool = ToolSearchTool(deferred: deferred, onSurfaced: (_) {});

      Future<int> count(Object? limit) async {
        final result = await tool.execute(
          <String, dynamic>{'query': 'shared thing', 'limit': limit},
          context(),
        );
        final decoded = jsonDecode(result.output) as Map<String, dynamic>;
        return (decoded['tools']! as List<dynamic>).length;
      }

      expect(await count(null), defaultToolSearchLimit);
      expect(await count(1000), maxToolSearchLimit);
      expect(await count(0), 1);
    });
  });
}

final class _FakeTool extends AgentTool {
  _FakeTool({
    required this.name,
    required this.description,
    Map<String, dynamic>? schema,
  }) : strictJsonSchema =
           schema ??
           <String, dynamic>{
             'type': 'object',
             'properties': <String, dynamic>{},
             'required': <String>[],
             'additionalProperties': false,
           };

  @override
  final String name;

  @override
  final String description;

  @override
  final Map<String, dynamic> strictJsonSchema;

  @override
  AgentToolRisk get risk => AgentToolRisk.dangerous;

  @override
  ToolExposure get exposure => ToolExposure.deferred;

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolExecutionContext context,
  ) async => const ToolResult(output: '{}');
}
