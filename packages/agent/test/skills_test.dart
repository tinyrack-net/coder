import 'dart:convert';
import 'dart:io';

import 'package:agent/agent.dart';
import 'package:test/test.dart';

void main() {
  late Directory skill;
  late Directory outside;

  setUp(() async {
    skill = await Directory.systemTemp.createTemp('coder-skill-');
    outside = await Directory.systemTemp.createTemp('coder-skill-outside-');
    await File('${outside.path}/secret.txt').writeAsString('secret');
    await Directory('${skill.path}/scripts').create();
    await File('${skill.path}/scripts/split.sh').writeAsString('echo split\n');
  });

  tearDown(() async {
    await skill.delete(recursive: true);
    await outside.delete(recursive: true);
  });

  ToolExecutionContext context() => ToolExecutionContext(
    workspaceRoot: skill.path,
    cancellation: CancellationToken(),
  );

  group('list_skills', () {
    Future<Map<String, dynamic>> page(
      SkillCatalog catalog,
      String? cursor,
    ) async =>
        jsonDecode(
              (await ListSkillsTool(catalog).execute(<String, dynamic>{
                'cursor': cursor,
              }, context())).output,
            )
            as Map<String, dynamic>;

    test('a short catalog comes back in one sorted page', () async {
      final result = await page(_CountedCatalog(3), null);

      expect(
        (result['skills']! as List)
            .map((skill) => (skill! as Map<String, dynamic>)['name'])
            .toList(),
        <String>['skill-000', 'skill-001', 'skill-002'],
      );
      expect(result['total'], 3);
      // The last page says so by omission, which is how the model stops.
      expect(result.containsKey('nextCursor'), isFalse);
    });

    test('a long catalog pages through a cursor', () async {
      final catalog = _CountedCatalog(skillPageSize + 2);

      final first = await page(catalog, null);
      expect(first['skills']! as List, hasLength(skillPageSize));
      expect(first['total'], skillPageSize + 2);
      expect(first['nextCursor'], '$skillPageSize');

      final second = await page(catalog, first['nextCursor'] as String);
      expect(second['skills']! as List, hasLength(2));
      expect(second.containsKey('nextCursor'), isFalse);
      // The two pages together are the whole catalog, with nothing repeated.
      expect(
        (second['skills']! as List).first,
        containsPair(
          'name',
          'skill-${skillPageSize.toString().padLeft(3, '0')}',
        ),
      );
    });

    test('an empty catalog is a page, not an error', () async {
      final result = await page(_CountedCatalog(0), null);

      expect(result['skills'], isEmpty);
      expect(result['total'], 0);
    });

    test('a cursor this tool never issued is correctable', () async {
      final tool = ListSkillsTool(_CountedCatalog(2));

      for (final cursor in <String>['nonsense', '-1', '99']) {
        final result = await tool.execute(<String, dynamic>{
          'cursor': cursor,
        }, context());
        expect(result.isError, isTrue, reason: cursor);
        expect(
          (jsonDecode(result.output) as Map<String, dynamic>)['error'],
          contains('cursor'),
          reason: cursor,
        );
      }
    });

    test('it advertises a read-risk strict schema', () {
      final tool = ListSkillsTool(_CountedCatalog(1));

      expect(tool.name, 'list_skills');
      expect(tool.risk, AgentToolRisk.read);
      expect(tool.strict, isTrue);
      expect(tool.strictJsonSchema['additionalProperties'], isFalse);
      expect(tool.strictJsonSchema['required'], <String>['cursor']);
    });
  });

  test(
    'skill tool advertises a read-risk strict schema',
    () {
      final tool = SkillTool(_FakeCatalog(directory: skill.path));
      expect(tool.name, 'skill');
      expect(tool.risk, AgentToolRisk.read);
      expect(tool.strictJsonSchema, <String, dynamic>{
        'type': 'object',
        'properties': <String, dynamic>{
          'name': <String, dynamic>{'type': 'string'},
          'resource': <String, dynamic>{
            'type': <String>['string', 'null'],
          },
        },
        'required': <String>['name', 'resource'],
        'additionalProperties': false,
      });
    },
    tags: const <String>['feature_test__skill_invocation__unit'],
  );

  test(
    'skill tool loads instructions and lists bundled resources',
    () async {
      final tool = SkillTool(_FakeCatalog(directory: skill.path));
      final result = await tool.execute(<String, dynamic>{
        'name': 'commit',
        'resource': null,
      }, context());

      expect(result.isError, isFalse);
      final decoded = jsonDecode(result.output) as Map<String, dynamic>;
      expect(decoded['name'], 'commit');
      expect(decoded['description'], 'Writes atomic commits.');
      expect(decoded['instructions'], 'Stage related changes together.');
      expect(decoded['directory'], skill.path);
      expect(decoded['resources'], <dynamic>[
        <String, dynamic>{'path': 'scripts/split.sh', 'bytes': 11},
      ]);
    },
    tags: const <String>['feature_test__skill_invocation__unit'],
  );

  test(
    'skill tool reads one bundled resource',
    () async {
      final tool = SkillTool(_FakeCatalog(directory: skill.path));
      final result = await tool.execute(<String, dynamic>{
        'name': 'commit',
        'resource': 'scripts/split.sh',
      }, context());

      expect(result.isError, isFalse);
      final decoded = jsonDecode(result.output) as Map<String, dynamic>;
      expect(decoded['resource'], 'scripts/split.sh');
      expect(decoded['content'], 'echo split\n');
    },
    tags: const <String>['feature_test__skill_invocation__unit'],
  );

  test(
    'skill tool reports unknown skills with the available names',
    () async {
      final tool = SkillTool(_FakeCatalog(directory: skill.path));
      final result = await tool.execute(<String, dynamic>{
        'name': 'missing',
        'resource': null,
      }, context());

      expect(result.isError, isTrue);
      final decoded = jsonDecode(result.output) as Map<String, dynamic>;
      expect(decoded['error'], contains('missing'));
      expect(decoded['available'], <String>['commit']);
    },
    tags: const <String>['feature_test__skill_invocation__unit'],
  );

  test(
    'skill tool reports a guard rejection instead of throwing',
    () async {
      final tool = SkillTool(_FakeCatalog(directory: skill.path));
      final result = await tool.execute(<String, dynamic>{
        'name': 'commit',
        'resource': '../secret.txt',
      }, context());

      expect(result.isError, isTrue);
      final decoded = jsonDecode(result.output) as Map<String, dynamic>;
      expect(decoded['error'], isNotEmpty);
    },
    tags: const <String>['feature_test__skill_invocation__unit'],
  );

  test(
    'built-in skills without a directory refuse resource requests',
    () async {
      final tool = SkillTool(_FakeCatalog());
      final listing = await tool.execute(<String, dynamic>{
        'name': 'commit',
        'resource': null,
      }, context());
      expect(
        (jsonDecode(listing.output) as Map<String, dynamic>)['directory'],
        isNull,
      );

      final result = await tool.execute(<String, dynamic>{
        'name': 'commit',
        'resource': 'scripts/split.sh',
      }, context());
      expect(result.isError, isTrue);
    },
    tags: const <String>['feature_test__skill_invocation__unit'],
  );

  test(
    'oversized skill output is truncated instead of flooding the turn',
    () async {
      final tool = SkillTool(
        _FakeCatalog(
          directory: skill.path,
          instructions: 'x' * (2 * 1024 * 1024),
        ),
      );
      final result = await tool.execute(<String, dynamic>{
        'name': 'commit',
        'resource': null,
      }, context());

      final decoded = jsonDecode(result.output) as Map<String, dynamic>;
      expect(result.output.length, lessThanOrEqualTo(1024 * 1024));
      expect(decoded['truncated'], isTrue);
      expect(
        (decoded['instructions']! as String).length,
        lessThan(1024 * 1024),
      );
    },
    tags: const <String>['feature_test__skill_invocation__unit'],
  );

  test(
    'skill path guard rejects escapes and resolves bundled files',
    () async {
      final guard = SkillPathGuard(skill.path);
      expect(
        guard.resolveExisting('scripts/split.sh'),
        endsWith('split.sh'),
      );
      expect(
        () => guard.resolveExisting('../secret.txt'),
        throwsA(isA<FileSystemException>()),
      );
      expect(
        () => guard.resolveExisting('${outside.path}/secret.txt'),
        throwsA(isA<FileSystemException>()),
      );
      if (!Platform.isWindows) {
        await Link('${skill.path}/escape').create(outside.path);
        expect(
          () => guard.resolveExisting('escape/secret.txt'),
          throwsA(isA<FileSystemException>()),
        );
      }
    },
    tags: const <String>['feature_test__skill_invocation__unit'],
  );

  test(
    'the skill prompt points at the tools instead of listing every skill',
    () {
      const provider = SkillToolProvider();

      final prompt = provider.promptFragment(_skillScope(_CountedCatalog(2)));

      expect(prompt, contains('## Available skills'));
      // The count is one number whatever the catalog size, and it is what
      // tells the agent whether looking is worth a call.
      expect(prompt, contains('2 skills are available'));
      expect(prompt, contains(listSkillsToolName));
      expect(prompt, contains(skillToolName));
      // No per-skill line survives, which is the whole point: the prompt cost
      // no longer grows with the catalog.
      expect(prompt, isNot(contains('Number 0.')));
      expect(prompt, isNot(contains('skill-000')));

      expect(
        provider.promptFragment(_skillScope(_CountedCatalog(1))),
        contains('1 skill is available'),
      );
    },
    tags: const <String>['feature_test__skill_invocation__unit'],
  );

  test(
    'a worktree without skills contributes no tools and no prompt',
    () {
      const provider = SkillToolProvider();
      final scope = _skillScope(_CountedCatalog(0));

      expect(provider.create(scope), isEmpty);
      expect(provider.promptFragment(scope), isNull);
      // Hidden rather than selectable: the skill tools appear because the
      // worktree has skills, not because anyone chose them in settings.
      expect(provider.catalogEntry, isNull);
    },
    tags: const <String>['feature_test__skill_invocation__unit'],
  );
}

/// Stands in for every port the skill capability never touches.
final class _UnusedPorts
    implements
        AttachmentPublisher,
        AttachmentReader,
        AgentClock,
        UserQuestionCoordinator,
        ExecSessionHost {
  const _UnusedPorts();

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
    '${invocation.memberName} is not part of this test: the skill capability '
    'reads only the catalog.',
  );
}

AgentToolScope _skillScope(SkillCatalog skills) => AgentToolScope(
  session: const AgentSessionContext(id: 'session-1'),
  definition: const AgentDefinitionContext(id: 'coder'),
  selectedToolIds: const <String>{},
  workspaceRoot: '/workspace',
  turnId: 'turn-1',
  attachmentPublisher: const _UnusedPorts(),
  attachmentReader: const _UnusedPorts(),
  clock: const _UnusedPorts(),
  questions: const _UnusedPorts(),
  execHost: const _UnusedPorts(),
  skills: skills,
);

/// A catalog holding a fixed number of generated skills.
final class _CountedCatalog implements SkillCatalog {
  _CountedCatalog(this.count);

  final int count;

  @override
  List<SkillSummary> summaries() => <SkillSummary>[
    // Deliberately out of order, so sorting is the tool's job.
    for (var index = count - 1; index >= 0; index -= 1)
      SkillSummary(
        name: 'skill-${index.toString().padLeft(3, '0')}',
        description: 'Number $index.',
      ),
  ];

  @override
  Future<SkillContent> read(String name) async =>
      throw SkillLookupException('Unknown skill: $name');

  @override
  Future<String> readResource(String name, String relativePath) async =>
      throw SkillLookupException('Unknown skill: $name');
}

final class _FakeCatalog implements SkillCatalog {
  _FakeCatalog({
    this.directory,
    this.instructions = 'Stage related changes together.',
  });

  final String? directory;
  final String instructions;

  @override
  List<SkillSummary> summaries() => const <SkillSummary>[
    SkillSummary(name: 'commit', description: 'Writes atomic commits.'),
  ];

  @override
  Future<SkillContent> read(String name) async {
    if (name != 'commit') {
      throw SkillLookupException('Unknown skill: $name');
    }
    return SkillContent(
      name: 'commit',
      description: 'Writes atomic commits.',
      instructions: instructions,
      directory: directory,
      resources: const <SkillResourceRef>[
        SkillResourceRef(path: 'scripts/split.sh', sizeBytes: 11),
      ],
    );
  }

  @override
  Future<String> readResource(String name, String relativePath) async {
    final root = directory;
    if (root == null) {
      throw SkillLookupException('Skill has no bundled files: $name');
    }
    return File(
      SkillPathGuard(root).resolveExisting(relativePath),
    ).readAsString();
  }
}
