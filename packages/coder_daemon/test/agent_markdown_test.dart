import 'dart:io';

import 'package:coder_daemon/src/agent_definitions.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:test/test.dart';

void main() {
  const source = '''
---
# User comment must survive GUI edits.
version: 1
name: Reviewer
description: Reviews code
mode: subagent
promptEnabled: true
model:
  source: daemonDefault
reasoningEffort: medium
permissionMode: readOnly
tools:
  - read_file
  - future_tool
callableAgents: []
customField: preserved
---

Review the requested code without modifying it.
''';

  test('parses frontmatter and markdown body into a typed definition', () {
    final parsed = const AgentMarkdownCodec().decode(
      id: 'reviewer',
      sourcePath: '/config/agents/reviewer.md',
      source: source,
    );

    expect(parsed.id, 'reviewer');
    expect(parsed.mode, AgentMode.subagent);
    expect(parsed.model.source, AgentModelSource.daemonDefault);
    expect(parsed.toolIds, <String>['read_file', 'future_tool']);
    expect(parsed.systemPrompt, contains('Review the requested code'));
    expect(parsed.contentHash, isNotEmpty);
    expect(
      const AgentMarkdownCodec()
          .decode(
            id: 'reviewer',
            sourcePath: '/config/agents/reviewer.md',
            source: '\n\n$source',
          )
          .name,
      'Reviewer',
    );
    expect(
      const AgentFileConflict('current-hash').toString(),
      'agent_file_conflict: current-hash',
    );
  });

  test('updates known fields while preserving comments and unknown fields', () {
    const codec = AgentMarkdownCodec();
    final parsed = codec.decode(
      id: 'reviewer',
      sourcePath: '/config/agents/reviewer.md',
      source: source,
    );
    final updated = codec.encodeUpdate(
      originalSource: source,
      definition: parsed.copyWith(
        name: 'Security Reviewer',
        systemPrompt: 'Audit security boundaries.',
      ),
    );

    expect(updated, contains('# User comment must survive GUI edits.'));
    expect(updated, contains('customField: preserved'));
    expect(updated, contains('name: Security Reviewer'));
    expect(updated, endsWith('Audit security boundaries.\n'));
  });

  test('rejects fixed model settings without provider and model IDs', () {
    expect(
      () => const AgentMarkdownCodec().decode(
        id: 'broken',
        sourcePath: '/config/agents/broken.md',
        source: source.replaceFirst('daemonDefault', 'fixed'),
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test(
    'accepts an intentionally empty agent description',
    () {
      final parsed = const AgentMarkdownCodec().decode(
        id: 'reviewer',
        sourcePath: '/config/agents/reviewer.md',
        source: source.replaceFirst(
          'description: Reviews code',
          'description: ""',
        ),
      );

      expect(parsed.description, isEmpty);
    },
    tags: const <String>[
      'feature_test__agent_definition_management__unit',
    ],
  );

  test('rejects every malformed Markdown boundary with typed diagnostics', () {
    const codec = AgentMarkdownCodec();
    final malformed = <String>[
      'name: no-frontmatter',
      '---\nname: unclosed',
      '---\n- not\n- a-map\n---\n',
      source.replaceFirst('version: 1', 'version: 2'),
      source.replaceFirst('mode: subagent', 'mode: unknown'),
      source
          .replaceFirst('mode: subagent', 'mode: subagent')
          .replaceFirst('callableAgents: []', 'callableAgents: [coder]'),
      source.replaceFirst(
        'model:\n  source: daemonDefault',
        'model: invalid',
      ),
      source.replaceFirst('name: Reviewer', 'name: ""'),
      source.replaceFirst('name: Reviewer\n', ''),
      source.replaceFirst('promptEnabled: true', 'promptEnabled: yes'),
      source.replaceFirst('tools:\n  - read_file\n  - future_tool', 'tools: 4'),
      source.replaceFirst('version: 1', 'version: one'),
      source.replaceFirst('reasoningEffort: medium', 'reasoningEffort: []'),
      source.replaceFirst('permissionMode: readOnly', 'permissionMode: root'),
      source.replaceFirst('name: Reviewer', '1: invalid-key'),
    ];

    for (final markdown in malformed) {
      expect(
        () => codec.decode(
          id: 'reviewer',
          sourcePath: '/config/agents/reviewer.md',
          source: markdown,
        ),
        throwsA(isA<FormatException>()),
      );
    }
    expect(
      () => codec.decode(
        id: '../escape',
        sourcePath: '/config/agents/escape.md',
        source: source,
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test(
    'file store creates coder, detects conflicts, and archives custom agents',
    () async {
      final directory = await Directory.systemTemp.createTemp('coder-agents-');
      addTearDown(() => directory.delete(recursive: true));
      final store = FileAgentDefinitionStore(directory.path);
      addTearDown(store.close);

      await store.initialize();
      final coder = await store.get('coder');
      expect(coder, isNotNull);
      expect(coder!.isBuiltIn, isTrue);

      final reviewer = coder.copyWith(
        id: 'reviewer',
        name: 'Reviewer',
        mode: AgentMode.subagent,
        callableAgentIds: const <String>[],
        sourcePath: '',
        isBuiltIn: false,
      );
      final created = await store.create('reviewer', reviewer);
      expect(created.sourcePath, endsWith('reviewer.md'));
      await expectLater(
        store.update(
          created.copyWith(name: 'Changed'),
          expectedContentHash: 'stale-hash',
        ),
        throwsA(isA<AgentFileConflict>()),
      );

      await store.archive('reviewer');
      expect(await store.get('reviewer'), isNull);
      expect(await store.resolve('reviewer'), isNotNull);
      expect((await store.resolve('reviewer'))!.isArchived, isTrue);

      await expectLater(
        store.create(
          'invalid',
          reviewer.copyWith(
            id: 'invalid',
            name: '',
            sourcePath: '',
            contentHash: '',
          ),
        ),
        throwsA(isA<FormatException>()),
      );
      expect(
        File('${directory.path}/agents/invalid.md').existsSync(),
        isFalse,
      );
    },
  );

  test(
    'reload retains the last valid definition after malformed external edit',
    () async {
      final directory = await Directory.systemTemp.createTemp('coder-agents-');
      addTearDown(() => directory.delete(recursive: true));
      final store = FileAgentDefinitionStore(directory.path);
      addTearDown(store.close);
      await store.initialize();
      final coder = (await store.get('coder'))!;

      await File(coder.sourcePath).writeAsString('---\ninvalid: [\n---\n');
      await store.reload();

      final stale = (await store.get('coder'))!;
      expect(stale.isStale, isTrue);
      expect(stale.diagnostics, isNotEmpty);
      expect(stale.diagnostics.single.line, isNotNull);
      expect(stale.diagnostics.single.column, isNotNull);
      expect(stale.name, coder.name);
    },
  );

  test(
    'valid external edits reload while symlinked definitions are ignored',
    () async {
      final directory = await Directory.systemTemp.createTemp('coder-agents-');
      final outside = await Directory.systemTemp.createTemp('coder-outside-');
      addTearDown(() async {
        await directory.delete(recursive: true);
        await outside.delete(recursive: true);
      });
      final store = FileAgentDefinitionStore(directory.path);
      addTearDown(store.close);
      await store.initialize();
      final coder = (await store.get('coder'))!;
      final sourceFile = File(coder.sourcePath);
      await sourceFile.writeAsString(
        (await sourceFile.readAsString()).replaceFirst(
          'name: Coder',
          'name: Dev',
        ),
      );
      if (!Platform.isWindows) {
        final outsideFile = File('${outside.path}/evil.md')
          ..writeAsStringSync(source);
        Link(
          '${directory.path}/agents/evil.md',
        ).createSync(outsideFile.path);
      }

      await store.reload();

      expect((await store.get('coder'))!.name, 'Dev');
      expect(await store.get('evil'), isNull);
      if (!Platform.isWindows) {
        expect(
          Directory('${directory.path}/agents').statSync().mode & 0x1ff,
          0x1c0,
        );
        expect(sourceFile.statSync().mode & 0x1ff, 0x180);
      }
    },
  );

  test(
    'domain service validates callable subagents and decorates unknown tools',
    () async {
      final directory = await Directory.systemTemp.createTemp('coder-agents-');
      addTearDown(() => directory.delete(recursive: true));
      final store = FileAgentDefinitionStore(directory.path);
      final service = AgentDefinitionService(
        store: store,
        tools: const <AgentToolDefinitionDto>[
          AgentToolDefinitionDto(
            id: 'read_file',
            name: 'read_file',
            description: 'Read files.',
            risk: ToolRisk.read,
          ),
        ],
      );
      addTearDown(service.close);
      await service.initialize();
      final coder = await service.get('coder');
      final reviewer = await service.create(
        'reviewer',
        coder.copyWith(
          id: 'reviewer',
          name: 'Reviewer',
          mode: AgentMode.subagent,
          toolIds: const <String>['read_file', 'future_tool'],
          callableAgentIds: const <String>[],
          contentHash: '',
          sourcePath: '',
          isBuiltIn: false,
        ),
      );
      expect(
        reviewer.diagnostics.map((diagnostic) => diagnostic.code),
        contains('unavailable_tool'),
      );
      final callable = await service.update(
        coder.copyWith(callableAgentIds: const <String>['reviewer']),
        expectedContentHash: coder.contentHash,
      );
      expect(callable.callableAgentIds, const <String>['reviewer']);
      await expectLater(
        service.update(
          callable.copyWith(callableAgentIds: const <String>['missing']),
          expectedContentHash: callable.contentHash,
        ),
        throwsA(isA<FormatException>()),
      );

      await service.archive('reviewer');
      expect((await service.get('coder')).callableAgentIds, isEmpty);
      await expectLater(service.archive('coder'), throwsA(isA<StateError>()));
    },
    tags: const <String>['feature_test__agent_delegation__unit'],
  );

  test(
    'file store protects immutable IDs, supports force, and restores coder',
    () async {
      final directory = await Directory.systemTemp.createTemp('coder-agents-');
      addTearDown(() => directory.delete(recursive: true));
      final store = FileAgentDefinitionStore(directory.path);
      addTearDown(store.close);
      await store.initialize();
      await store.initialize();
      final coder = (await store.get('coder'))!;

      await expectLater(
        store.create('other', coder),
        throwsA(isA<FormatException>()),
      );
      await expectLater(
        store.create('coder', coder),
        throwsA(isA<StateError>()),
      );
      final reviewer = await store.create(
        'reviewer',
        coder.copyWith(
          id: 'reviewer',
          name: 'Reviewer',
          mode: AgentMode.subagent,
          contentHash: '',
          sourcePath: '',
          isBuiltIn: false,
        ),
      );
      await expectLater(
        store.update(
          reviewer.copyWith(mode: AgentMode.primary),
          expectedContentHash: reviewer.contentHash,
        ),
        throwsA(isA<FormatException>()),
      );
      final forced = await store.update(
        reviewer.copyWith(name: 'Forced Reviewer'),
        expectedContentHash: 'outdated',
        force: true,
      );
      expect(forced.name, 'Forced Reviewer');
      await store.create(
        'auditor',
        reviewer.copyWith(
          id: 'auditor',
          name: 'Auditor',
          contentHash: '',
          sourcePath: '',
        ),
      );
      expect(
        (await store.list()).map((definition) => definition.id),
        <String>['coder', 'auditor', 'reviewer'],
      );
      await expectLater(store.archive('missing'), throwsA(isA<StateError>()));

      await File(coder.sourcePath).delete();
      await store.reload();
      expect((await store.get('coder'))!.name, 'Coder');
      expect(await store.list(), hasLength(3));
      await store.archive('reviewer');
      expect(await store.listArchived(), hasLength(1));
      await File((await store.resolve('reviewer'))!.sourcePath).delete();
      await store.reload();
      expect(await store.listArchived(), isEmpty);
      final reset = await store.resetCoder();
      expect(reset.systemPrompt, contains('Read relevant code'));
    },
  );

  test(
    'domain service covers lookup, validation, catalog, and fixed refs',
    () async {
      final directory = await Directory.systemTemp.createTemp('coder-agents-');
      addTearDown(() => directory.delete(recursive: true));
      final store = FileAgentDefinitionStore(directory.path);
      final service = AgentDefinitionService(
        store: store,
        tools: const <AgentToolDefinitionDto>[
          AgentToolDefinitionDto(
            id: 'z_tool',
            name: 'Zulu',
            description: 'Last.',
            risk: ToolRisk.read,
          ),
          AgentToolDefinitionDto(
            id: 'a_tool',
            name: 'Alpha',
            description: 'First.',
            risk: ToolRisk.read,
          ),
        ],
      );
      addTearDown(service.close);
      await service.initialize();
      expect(service.toolCatalog().map((tool) => tool.name), <String>[
        'Alpha',
        'Zulu',
      ]);
      await expectLater(service.get('missing'), throwsA(isA<StateError>()));
      await expectLater(service.resolve('missing'), throwsA(isA<StateError>()));
      await expectLater(service.reset('reviewer'), throwsA(isA<StateError>()));

      final coder = await service.get('coder');
      final fixed = await service.create(
        'fixed',
        coder.copyWith(
          id: 'fixed',
          name: 'Fixed',
          mode: AgentMode.subagent,
          model: const AgentModelSelectionDto(
            source: AgentModelSource.fixed,
            providerConnectionId: 'connection',
            modelId: 'model',
          ),
          toolIds: const <String>['a_tool'],
          contentHash: '',
          sourcePath: '',
          isBuiltIn: false,
        ),
      );
      expect(await service.referencesProvider('connection'), isTrue);
      expect(await service.referencesProvider('other'), isFalse);
      expect((await service.resolve(fixed.id)).id, fixed.id);
      await service.archive(fixed.id);
      expect(await service.referencesProvider('connection'), isTrue);

      final validated = await service.validate(
        'candidate',
        source
            .replaceFirst('mode: subagent', 'mode: primary')
            .replaceFirst('future_tool', 'a_tool'),
      );
      expect(validated.id, 'candidate');
      await expectLater(
        service.create(
          'invalid-subagent',
          coder.copyWith(
            id: 'invalid-subagent',
            mode: AgentMode.subagent,
            callableAgentIds: const <String>['fixed'],
            contentHash: '',
            sourcePath: '',
            isBuiltIn: false,
          ),
        ),
        throwsA(isA<FormatException>()),
      );
      expect((await service.reset('coder')).isBuiltIn, isTrue);
    },
  );
}
