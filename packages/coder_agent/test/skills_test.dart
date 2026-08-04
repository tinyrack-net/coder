import 'dart:convert';
import 'dart:io';

import 'package:coder_agent/coder_agent.dart';
import 'package:coder_protocol/coder_protocol.dart';
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

  test(
    'skill tool advertises a read-risk strict schema',
    () {
      final tool = SkillTool(_FakeCatalog(directory: skill.path));
      expect(tool.name, 'skill');
      expect(tool.risk, ToolRisk.read);
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
