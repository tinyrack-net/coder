import 'dart:convert';
import 'dart:io';

import 'package:agent/agent.dart';
import 'package:daemon/src/features/prompts/infrastructure/skills.dart';
import 'package:daemon/src/shared/infrastructure/persistence/repositories.dart';
import 'package:path/path.dart' as p;
import 'package:protocol/protocol.dart';
import 'package:test/test.dart';

void main() {
  late Directory root;
  late Directory configHome;
  late Directory userHome;
  late Directory project;
  late _FakeSettings settings;

  Future<void> writeSkill(
    Directory skillsRoot,
    String id, {
    String? name,
    String description = 'Does something useful.',
    String body = 'Do the thing.',
    String? rawSource,
  }) async {
    final directory = Directory(p.join(skillsRoot.path, id));
    await directory.create(recursive: true);
    await File(p.join(directory.path, 'SKILL.md')).writeAsString(
      rawSource ??
          '---\n'
              'name: ${name ?? id}\n'
              'description: $description\n'
              '---\n\n'
              '$body\n',
    );
  }

  SkillCatalogService buildService() => SkillCatalogService(
    store: FileSkillStore(
      roots: <SkillFiles>[
        NativeSkillFiles(
          p.join(userHome.path, '.agents', 'skills'),
          source: SkillSource.userHome,
        ),
        NativeSkillFiles(
          p.join(configHome.path, 'skills'),
          source: SkillSource.config,
          createIfMissing: true,
        ),
      ],
      settings: settings,
      watchDebounce: const Duration(milliseconds: 20),
    ),
  );

  SkillScope projectScope() =>
      SkillScope(workspaceId: 'workspace', projectRoot: project.path);

  setUp(() async {
    root = await Directory.systemTemp.createTemp('tinest-skills-');
    configHome = Directory(p.join(root.path, 'config'))..createSync();
    userHome = Directory(p.join(root.path, 'home'))..createSync();
    project = Directory(p.join(root.path, 'project'))..createSync();
    settings = _FakeSettings();
  });

  tearDown(() async => root.delete(recursive: true));

  test(
    'built-in skills are listed and mandatory ones cannot be disabled',
    () async {
      final service = buildService();
      addTearDown(service.close);

      final skills = await service.list();
      final mandatory = skills.firstWhere((skill) => skill.isMandatory);
      final toggleable = skills.firstWhere((skill) => !skill.isMandatory);

      expect(mandatory.source, SkillSource.builtIn);
      expect(mandatory.isEditable, isFalse);
      expect(mandatory.isEnabled, isTrue);
      expect(mandatory.sourcePath, isEmpty);
      expect(toggleable.isEnabled, isTrue);

      await service.setEnabled(toggleable.id, enabled: false);
      expect(
        (await service.get(toggleable.id)).isEnabled,
        isFalse,
      );
      expect(
        () => service.setEnabled(mandatory.id, enabled: false),
        throwsA(isA<StateError>()),
      );
    },
    tags: const <String>['feature_test__skill_management__unit'],
  );

  test(
    'sources merge with project winning over config over user home',
    () async {
      await writeSkill(
        Directory(p.join(userHome.path, '.agents', 'skills')),
        'shared',
        description: 'From the user home.',
      );
      final service = buildService();
      addTearDown(service.close);

      expect(
        (await service.get('shared')).description,
        'From the user home.',
      );

      await writeSkill(
        Directory(p.join(configHome.path, 'skills')),
        'shared',
        description: 'From the daemon config.',
      );
      await service.reload();
      expect(
        (await service.get('shared')).description,
        'From the daemon config.',
      );

      await writeSkill(
        Directory(p.join(project.path, '.agents', 'skills')),
        'shared',
        description: 'From the project.',
      );
      final scoped = await service.get('shared', scope: projectScope());
      expect(scoped.description, 'From the project.');
      expect(scoped.source, SkillSource.project);

      // The global scope keeps the config skill.
      expect(
        (await service.get('shared')).description,
        'From the daemon config.',
      );
    },
    tags: const <String>['feature_test__skill_management__unit'],
  );

  test(
    'a mandatory built-in cannot be shadowed by a user skill',
    () async {
      await writeSkill(
        Directory(p.join(configHome.path, 'skills')),
        'coding-conventions',
        description: 'Hijacked.',
      );
      final service = buildService();
      addTearDown(service.close);

      final skills = await service.list();
      final winner = skills.firstWhere(
        (skill) => skill.id == 'coding-conventions' && !skill.isShadowed,
      );
      final loser = skills.firstWhere(
        (skill) => skill.id == 'coding-conventions' && skill.isShadowed,
      );

      expect(winner.source, SkillSource.builtIn);
      expect(loser.source, SkillSource.config);
      expect(
        loser.diagnostics.single.code,
        'shadowed_builtin',
      );
    },
    tags: const <String>['feature_test__skill_management__unit'],
  );

  test(
    'skills are created, updated with a content hash, and archived',
    () async {
      final service = buildService();
      addTearDown(service.close);

      final created = await service.create(
        id: 'release',
        source: SkillSource.config,
        name: 'release',
        description: 'Ships a release.',
        body: 'Tag, build, publish.',
      );
      expect(created.source, SkillSource.config);
      expect(created.isEditable, isTrue);
      expect(created.body, 'Tag, build, publish.');
      expect(
        File(created.sourcePath).readAsStringSync(),
        contains('description: Ships a release.'),
      );

      final updated = await service.update(
        created.copyWith(description: 'Ships a signed release.'),
        expectedContentHash: created.contentHash,
      );
      expect(updated.description, 'Ships a signed release.');
      expect(updated.contentHash, isNot(created.contentHash));

      expect(
        () => service.update(
          updated.copyWith(description: 'Stale write.'),
          expectedContentHash: created.contentHash,
        ),
        throwsA(isA<SkillFileConflict>()),
      );
      final forced = await service.update(
        updated.copyWith(description: 'Forced write.'),
        expectedContentHash: created.contentHash,
        force: true,
      );
      expect(forced.description, 'Forced write.');

      await service.delete('release');
      expect(
        (await service.list()).where((skill) => skill.id == 'release'),
        isEmpty,
      );
      expect(File(created.sourcePath).existsSync(), isFalse);
      expect(
        File(
          p.join(configHome.path, 'skills', '.archive', 'release', 'SKILL.md'),
        ).existsSync(),
        isTrue,
      );
    },
    tags: const <String>['feature_test__skill_management__unit'],
  );

  test(
    'unknown frontmatter keys and comments survive an update',
    () async {
      await writeSkill(
        Directory(p.join(configHome.path, 'skills')),
        'annotated',
        rawSource:
            '---\n'
            '# keep this comment\n'
            'name: annotated\n'
            'description: Original.\n'
            'license: MIT\n'
            '---\n\n'
            'Original body.\n',
      );
      final service = buildService();
      addTearDown(service.close);

      final skill = await service.get('annotated');
      await service.update(
        skill.copyWith(description: 'Rewritten.'),
        expectedContentHash: skill.contentHash,
      );

      final source = File(skill.sourcePath).readAsStringSync();
      expect(source, contains('# keep this comment'));
      expect(source, contains('license: MIT'));
      expect(source, contains('description: Rewritten.'));
    },
    tags: const <String>['feature_test__skill_management__unit'],
  );

  test(
    'built-in skills reject edits and deletes',
    () async {
      final service = buildService();
      addTearDown(service.close);

      final builtIn = await service.get('commit');
      expect(
        () => service.update(
          builtIn.copyWith(description: 'Rewritten.'),
          expectedContentHash: builtIn.contentHash,
        ),
        throwsA(isA<StateError>()),
      );
      expect(
        () => service.delete('commit'),
        throwsA(isA<StateError>()),
      );
      expect(
        () => service.create(
          id: 'commit',
          source: SkillSource.config,
          name: 'commit',
          description: 'Duplicate.',
          body: 'Duplicate.',
        ),
        throwsA(isA<StateError>()),
      );
      expect(
        () => service.create(
          id: 'Not Valid',
          source: SkillSource.config,
          name: 'invalid',
          description: 'Invalid.',
          body: 'Invalid.',
        ),
        throwsA(isA<FormatException>()),
      );
    },
    tags: const <String>['feature_test__skill_management__unit'],
  );

  test(
    'project skills are created, toggled per workspace, and deleted',
    () async {
      final service = buildService();
      addTearDown(service.close);

      final created = await service.create(
        id: 'migrate',
        source: SkillSource.project,
        name: 'migrate',
        description: 'Runs the migration.',
        body: 'Run the migration script.',
        scope: projectScope(),
      );
      expect(created.source, SkillSource.project);
      expect(
        created.sourcePath,
        p.join(project.path, '.agents', 'skills', 'migrate', 'SKILL.md'),
      );

      await service.setEnabled(
        'migrate',
        enabled: false,
        scope: projectScope(),
      );
      expect(
        (await service.get('migrate', scope: projectScope())).isEnabled,
        isFalse,
      );
      expect(settings.values.keys, contains('skills.enablement.workspace'));
      expect(settings.values.containsKey('skills.enablement'), isFalse);

      await service.delete('migrate', scope: projectScope());
      expect(
        (await service.list(scope: projectScope())).where(
          (skill) => skill.id == 'migrate',
        ),
        isEmpty,
      );
    },
    tags: const <String>['feature_test__skill_management__unit'],
  );

  test(
    'invalid documents keep the previous parse and report a diagnostic',
    () async {
      final skills = Directory(p.join(configHome.path, 'skills'));
      await writeSkill(skills, 'fragile', description: 'Valid.');
      final service = buildService();
      addTearDown(service.close);
      expect((await service.get('fragile')).description, 'Valid.');

      await File(
        p.join(skills.path, 'fragile', 'SKILL.md'),
      ).writeAsString('no frontmatter here');
      await service.reload();

      final stale = await service.get('fragile');
      expect(stale.isStale, isTrue);
      expect(stale.description, 'Valid.');
      expect(stale.diagnostics.single.code, 'invalid_skill_markdown');
    },
    tags: const <String>['feature_test__skill_management__unit'],
  );

  test(
    'a document that never parsed is reported instead of dropped',
    () async {
      final skills = Directory(p.join(configHome.path, 'skills'));
      await writeSkill(skills, 'broken', rawSource: 'no frontmatter here');
      final service = buildService();
      addTearDown(service.close);

      final broken = await service.get('broken');
      expect(broken.isStale, isTrue);
      expect(broken.contentHash, isEmpty);
      expect(broken.diagnostics.single.code, 'invalid_skill_markdown');
    },
    tags: const <String>['feature_test__skill_management__unit'],
  );

  test(
    'missing user-home and project directories are not an error',
    () async {
      final service = buildService();
      addTearDown(service.close);

      expect(
        Directory(p.join(userHome.path, '.agents')).existsSync(),
        isFalse,
      );
      expect(await service.list(scope: projectScope()), isNotEmpty);
      expect(Directory(p.join(project.path, '.agents')).existsSync(), isFalse);
      expect(
        Directory(p.join(configHome.path, 'skills')).existsSync(),
        isTrue,
      );
    },
    tags: const <String>['feature_test__skill_management__unit'],
  );

  test(
    'external edits reach subscribers through the debounced watcher',
    () async {
      final service = buildService();
      addTearDown(service.close);
      await service.list();

      final changed = service.changes.first;
      await writeSkill(
        Directory(p.join(configHome.path, 'skills')),
        'watched',
        description: 'Watched.',
      );
      await changed.timeout(const Duration(seconds: 10));

      expect((await service.get('watched')).description, 'Watched.');
    },
    tags: const <String>['feature_test__skill_management__unit'],
  );

  test(
    'the turn catalog exposes enabled skills and reads bundled files',
    () async {
      final skills = Directory(p.join(configHome.path, 'skills'));
      await writeSkill(skills, 'bundled', body: 'Load the helper.');
      await File(
        p.join(skills.path, 'bundled', 'helper.txt'),
      ).writeAsString('helper contents');
      await writeSkill(skills, 'disabled-skill');
      final service = buildService();
      addTearDown(service.close);
      await service.setEnabled('disabled-skill', enabled: false);

      final catalog = await service.viewFor(project.path);
      final names = catalog
          .summaries()
          .map((summary) => summary.name)
          .toList(growable: false);
      expect(names, contains('bundled'));
      expect(names, isNot(contains('disabled-skill')));
      expect(names, orderedEquals(<String>[...names]..sort()));

      final content = await catalog.read('bundled');
      expect(content.instructions, 'Load the helper.');
      expect(content.directory, p.join(skills.path, 'bundled'));
      expect(
        content.resources.map((resource) => resource.path),
        contains('helper.txt'),
      );
      expect(
        await catalog.readResource('bundled', 'helper.txt'),
        'helper contents',
      );

      expect(
        () => catalog.read('disabled-skill'),
        throwsA(isA<SkillLookupException>()),
      );
      expect(
        () => catalog.read('nope'),
        throwsA(isA<SkillLookupException>()),
      );
      expect(
        () => catalog.readResource('bundled', '../secret'),
        throwsA(isA<FileSystemException>()),
      );

      final builtIn = await catalog.read('commit');
      expect(builtIn.directory, isNull);
      expect(
        () => catalog.readResource('commit', 'anything'),
        throwsA(isA<SkillLookupException>()),
      );
    },
    tags: const <String>[
      'feature_test__skill_management__unit',
      'feature_test__skill_invocation__unit',
    ],
  );

  test(
    'the project root cache evicts the oldest watcher past its limit',
    () async {
      final service = SkillCatalogService(
        store: FileSkillStore(
          roots: <SkillFiles>[
            NativeSkillFiles(
              p.join(configHome.path, 'skills'),
              source: SkillSource.config,
              createIfMissing: true,
            ),
          ],
          settings: settings,
          maxProjectRoots: 2,
        ),
      );
      addTearDown(service.close);

      for (var index = 0; index < 3; index += 1) {
        final directory = Directory(p.join(root.path, 'project-$index'))
          ..createSync();
        await writeSkill(
          Directory(p.join(directory.path, '.agents', 'skills')),
          'local-$index',
        );
        expect(
          (await service.list(
            scope: SkillScope(
              workspaceId: 'workspace-$index',
              projectRoot: directory.path,
            ),
          )).map((skill) => skill.id),
          contains('local-$index'),
        );
      }

      expect(service.trackedProjectRoots, 2);
    },
    tags: const <String>['feature_test__skill_management__unit'],
  );

  test(
    'a closed store rejects further work',
    () async {
      final service = buildService();
      await service.list();
      await service.close();
      await service.close();

      expect(service.list, throwsA(isA<StateError>()));
    },
    tags: const <String>['feature_test__skill_management__unit'],
  );
}

final class _FakeSettings implements SettingsRepository {
  final Map<String, String> values = <String, String>{};

  @override
  Future<String?> getValue(String key) async => values[key];

  @override
  Future<void> setValue(String key, String value) async {
    // Decoding here keeps the fake honest about storing JSON documents.
    jsonDecode(value);
    values[key] = value;
  }
}
