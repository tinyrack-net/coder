@Tags(<String>['feature_test__tool_search__unit'])
library;

import 'dart:convert';
import 'dart:io' show FileSystemException;

import 'package:agent/agent.dart';
import 'package:file/memory.dart';
import 'package:platform/platform.dart';
import 'package:test/test.dart';

/// Fills in every `search_text` argument, since a strict schema has no
/// optional keys — only nullable ones.
Map<String, dynamic> _search(Map<String, dynamic> overrides) =>
    <String, dynamic>{
      'query': overrides['query'],
      'path': overrides['path'],
      'regex': overrides['regex'],
      'case_sensitive': overrides['case_sensitive'],
      'context_lines': overrides['context_lines'],
      'include_ignored': overrides['include_ignored'],
      'max_results': overrides['max_results'],
    };

void main() {
  late MemoryFileSystem fileSystem;
  late FakePlatform platform;
  late ToolExecutionContext context;

  setUp(() {
    fileSystem = MemoryFileSystem.test();
    // An explicit empty environment keeps the gitignore loader from finding
    // whatever global excludes the machine running the tests happens to have.
    platform = FakePlatform(
      operatingSystem: 'linux',
      environment: const <String, String>{},
    );
    fileSystem.directory('/workspace').createSync(recursive: true);
    context = ToolExecutionContext(
      workspaceRoot: '/workspace',
      cancellation: CancellationToken(),
    );
  });

  test(
    'memory filesystem tools list, read, and search deterministically',
    () async {
      fileSystem
        ..directory('/workspace/lib').createSync()
        ..directory('/workspace/.git').createSync()
        ..file('/workspace/a.txt').writeAsStringSync('one\ntwo needle\nthree\n')
        ..file('/workspace/lib/b.txt').writeAsStringSync('needle in lib\n')
        ..file('/workspace/.git/ignored').writeAsStringSync('needle\n')
        ..link('/workspace/link').createSync('/workspace/a.txt');
      final list = ListDirectoryTool(
        fileSystem: fileSystem,
        platform: platform,
      );
      final listed =
          jsonDecode(
                (await list.execute(const <String, dynamic>{
                  'path': '.',
                }, context)).output,
              )
              as List<dynamic>;
      expect(
        listed.map((item) => (item as Map<String, dynamic>)['name']),
        <String>['.git', 'a.txt', 'lib', 'link'],
      );
      expect(list.name, 'list_directory');
      expect(list.description, contains('List'));
      expect(list.risk, AgentToolRisk.read);
      expect(list.strictJsonSchema['additionalProperties'], isFalse);

      final read = ReadFileTool(fileSystem: fileSystem, platform: platform);
      expect(
        (await read.execute(const <String, dynamic>{
          'path': 'a.txt',
          'offset': 1,
          'limit': 1,
        }, context)).output,
        'two needle',
      );
      expect(
        (await read.execute(const <String, dynamic>{
          'path': 'a.txt',
          'offset': 99,
          'limit': null,
        }, context)).output,
        isEmpty,
      );
      expect(
        () => read.execute(const <String, dynamic>{
          'path': 'a.txt',
          'offset': -1,
          'limit': 0,
        }, context),
        throwsA(isA<FormatException>()),
      );
      expect(read.name, 'read_file');
      expect(read.description, contains('UTF-8'));
      expect(read.risk, AgentToolRisk.read);
      expect(read.strictJsonSchema['required'], hasLength(3));

      final search = SearchTextTool(fileSystem: fileSystem, platform: platform);
      final found = jsonDecode(
        (await search.execute(
          _search(<String, dynamic>{
            'query': 'needle',
            'max_results': 1,
          }),
          context,
        )).output,
      );
      final matches = (found as Map<String, dynamic>)['matches'] as List;
      expect(matches, hasLength(1));
      expect(
        (matches.single as Map<String, dynamic>)['path'],
        anyOf('a.txt', 'lib/b.txt'),
      );
      // Hitting the cap is reported, or the model would read one match as
      // "there is exactly one".
      expect(found['truncated'], isTrue);
      // `.git` is never walked, so its copy of the needle cannot show up.
      expect(
        matches.map((match) => (match! as Map<String, dynamic>)['path']),
        isNot(contains('.git/ignored')),
      );
      expect(
        () => search.execute(_search(<String, dynamic>{'query': ''}), context),
        throwsA(isA<FormatException>()),
      );
      expect(search.name, 'search_text');
      expect(search.description, contains('Search'));
      expect(search.risk, AgentToolRisk.read);
      expect(search.strictJsonSchema['required'], hasLength(7));
    },
  );

  test(
    'search observes cancellation and truncates long matching lines',
    () async {
      final longLine = '${List<String>.filled(550, 'x').join()}needle';
      fileSystem.file('/workspace/long.txt').writeAsStringSync(longLine);
      final tool = SearchTextTool(fileSystem: fileSystem, platform: platform);
      final result =
          jsonDecode(
                (await tool.execute(
                  _search(<String, dynamic>{
                    'query': 'needle',
                    'max_results': 20,
                  }),
                  context,
                )).output,
              )
              as Map<String, dynamic>;
      final matches = result['matches']! as List;
      expect(
        (matches.single! as Map<String, dynamic>)['text'],
        hasLength(maxSearchLineLength),
      );
      expect(result['truncated'], isFalse);
      expect(result['filesSearched'], 1);

      context.cancellation.cancel();
      await expectLater(
        tool.execute(_search(<String, dynamic>{'query': 'needle'}), context),
        throwsA(isA<AgentCancelledException>()),
      );
    },
  );

  group('search options', () {
    setUp(() {
      fileSystem
        ..file('/workspace/.gitignore').writeAsStringSync('generated/\n*.log\n')
        ..directory('/workspace/generated').createSync()
        ..file('/workspace/generated/out.dart').writeAsStringSync('Needle\n')
        ..file('/workspace/notes.log').writeAsStringSync('Needle\n')
        ..file('/workspace/main.dart').writeAsStringSync(
          'one\ntwo\nNeedle here\nfour\nfive\n',
        );
    });

    Future<Map<String, dynamic>> run(Map<String, dynamic> overrides) async =>
        jsonDecode(
              (await SearchTextTool(
                fileSystem: fileSystem,
                platform: platform,
              ).execute(_search(overrides), context)).output,
            )
            as Map<String, dynamic>;

    List<String> pathsOf(Map<String, dynamic> result) =>
        (result['matches']! as List)
            .map((match) => (match! as Map<String, dynamic>)['path']! as String)
            .toList();

    test('gitignored files are skipped by default', () async {
      final result = await run(<String, dynamic>{'query': 'Needle'});

      expect(pathsOf(result), <String>['main.dart']);
    });

    test('include_ignored reaches the files git hides', () async {
      final result = await run(<String, dynamic>{
        'query': 'Needle',
        'include_ignored': true,
      });

      expect(
        pathsOf(result),
        containsAll(<String>['generated/out.dart', 'notes.log']),
      );
    });

    test('a case-insensitive search matches either casing', () async {
      expect(pathsOf(await run(<String, dynamic>{'query': 'needle'})), isEmpty);
      expect(
        pathsOf(
          await run(<String, dynamic>{
            'query': 'needle',
            'case_sensitive': false,
          }),
        ),
        <String>['main.dart'],
      );
    });

    test('a regular expression is only honoured when regex is set', () async {
      expect(
        pathsOf(await run(<String, dynamic>{'query': 'N..dle'})),
        isEmpty,
      );
      expect(
        pathsOf(
          await run(<String, dynamic>{'query': 'N..dle', 'regex': true}),
        ),
        <String>['main.dart'],
      );
    });

    test('an invalid expression is correctable, not a failed turn', () async {
      final tool = SearchTextTool(fileSystem: fileSystem, platform: platform);

      final result = await tool.execute(
        _search(<String, dynamic>{'query': '([unclosed', 'regex': true}),
        context,
      );

      expect(result.isError, isTrue);
      expect(
        (jsonDecode(result.output) as Map<String, dynamic>)['error'],
        contains('regular expression'),
      );
    });

    test('context lines stop at the file boundary', () async {
      final result = await run(<String, dynamic>{
        'query': 'Needle',
        // Deliberately more context than the file has above the match.
        'context_lines': 5,
      });
      final match =
          (result['matches']! as List).single! as Map<String, dynamic>;

      expect(match['before'], <String>['one', 'two']);
      expect(match['after'], <String>['four', 'five']);
    });

    test('no context lines are reported when none were asked for', () async {
      final result = await run(<String, dynamic>{'query': 'Needle'});
      final match =
          (result['matches']! as List).single! as Map<String, dynamic>;

      expect(match.containsKey('before'), isFalse);
      expect(match.containsKey('after'), isFalse);
    });
  });

  group('glob', () {
    setUp(() {
      fileSystem
        ..file('/workspace/.gitignore').writeAsStringSync('build/\n')
        ..directory('/workspace/build').createSync()
        ..directory('/workspace/lib/src').createSync(recursive: true)
        ..file('/workspace/build/gen.dart').writeAsStringSync('')
        ..file('/workspace/lib/a.dart').writeAsStringSync('')
        ..file('/workspace/lib/src/b.dart').writeAsStringSync('')
        ..file('/workspace/lib/src/b_test.dart').writeAsStringSync('')
        ..file('/workspace/readme.md').writeAsStringSync('');
    });

    Future<Map<String, dynamic>> run(Map<String, dynamic> overrides) async =>
        jsonDecode(
              (await GlobTool(
                    fileSystem: fileSystem,
                    platform: platform,
                  ).execute(<String, dynamic>{
                    'pattern': overrides['pattern'],
                    'path': overrides['path'],
                    'include_ignored': overrides['include_ignored'],
                    'max_results': overrides['max_results'],
                  }, context))
                  .output,
            )
            as Map<String, dynamic>;

    test('a recursive pattern finds files at any depth, sorted', () async {
      final result = await run(<String, dynamic>{'pattern': '**/*.dart'});

      expect(result['paths'], <String>[
        'lib/a.dart',
        'lib/src/b.dart',
        'lib/src/b_test.dart',
      ]);
      expect(result['truncated'], isFalse);
    });

    test('a leading double star also matches top-level files', () async {
      fileSystem.file('/workspace/main.dart').writeAsStringSync('');

      // package:glob reads `**/` as one-or-more directories, which would drop
      // every file at the root of the search.
      final result = await run(<String, dynamic>{'pattern': '**/*.dart'});

      expect(result['paths'], contains('main.dart'));
    });

    test('gitignored files are skipped unless asked for', () async {
      expect(
        await run(<String, dynamic>{'pattern': '**/gen.dart'}),
        containsPair('paths', isEmpty),
      );
      expect(
        (await run(<String, dynamic>{
          'pattern': '**/gen.dart',
          'include_ignored': true,
        }))['paths'],
        <String>['build/gen.dart'],
      );
    });

    test('a pattern is matched relative to the searched directory', () async {
      final result = await run(<String, dynamic>{
        'pattern': 'src/*.dart',
        'path': 'lib',
      });

      // The pattern speaks in `lib`'s terms; the result still names the file
      // from the workspace root, because that is what every other tool takes.
      expect(result['paths'], <String>[
        'lib/src/b.dart',
        'lib/src/b_test.dart',
      ]);
    });

    test('the cap is reported rather than silently applied', () async {
      final result = await run(<String, dynamic>{
        'pattern': '**/*.dart',
        'max_results': 1,
      });

      expect(result['paths'], hasLength(1));
      expect(result['truncated'], isTrue);
    });

    test('an empty pattern is rejected', () async {
      expect(
        () => run(<String, dynamic>{'pattern': ''}),
        throwsA(isA<FormatException>()),
      );
    });

    test('the tool describes itself strictly', () {
      final tool = GlobTool(fileSystem: fileSystem, platform: platform);

      expect(tool.name, 'glob');
      expect(tool.risk, AgentToolRisk.read);
      expect(tool.strictJsonSchema['additionalProperties'], isFalse);
      expect(tool.strictJsonSchema['required'], <String>[
        'pattern',
        'path',
        'include_ignored',
        'max_results',
      ]);
    });
  });

  test('workspace guard handles writable paths and escape attempts', () {
    final guard = WorkspacePathGuard(
      '/workspace',
      fileSystem: fileSystem,
      platform: platform,
    );
    expect(
      guard.resolveWritable('nested/new.txt'),
      '/workspace/nested/new.txt',
    );
    expect(guard.resolveExisting('.'), '/workspace');
    expect(
      () => guard.resolveWritable('../escape.txt'),
      throwsA(isA<FileSystemException>()),
    );
    expect(
      () => guard.resolveExisting('/missing'),
      throwsA(isA<FileSystemException>()),
    );
  });

  test('workspace guard joins with the filesystem it was given', () {
    // The guard used to join with the host separator while resolving against
    // an injected filesystem, so a Windows host could not address a POSIX
    // workspace. Driving a Windows-style filesystem from any host proves the
    // separator now follows the filesystem rather than the runner.
    final windowsFileSystem = MemoryFileSystem.test(
      style: FileSystemStyle.windows,
    );
    windowsFileSystem
        .directory(r'C:\workspace\nested')
        .createSync(
          recursive: true,
        );
    final guard = WorkspacePathGuard(
      r'C:\workspace',
      fileSystem: windowsFileSystem,
      platform: FakePlatform(
        operatingSystem: Platform.windows,
        environment: const <String, String>{},
      ),
    );

    expect(
      guard.resolveWritable('nested/new.txt'),
      r'C:\workspace\nested\new.txt',
    );
    expect(guard.resolveExisting('.'), r'C:\workspace');
    expect(
      () => guard.resolveWritable(r'..\escape.txt'),
      throwsA(isA<FileSystemException>()),
    );
  });

  test(
    'patch tool updates, creates, deletes, and previews atomically',
    () async {
      fileSystem
        ..file('/workspace/update.txt').writeAsStringSync('before\n')
        ..file('/workspace/delete.txt').writeAsStringSync('delete me\n');
      var suffix = 0;
      final tool = ApplyPatchTool(
        fileSystem: fileSystem,
        platform: platform,
        temporarySuffix: () => 'test-${suffix++}',
      );
      const patch =
          '*** Begin Patch\n'
          '*** Update File: update.txt\n'
          '@@\n'
          '-before\n'
          '+after\n'
          '*** Add File: new.txt\n'
          '+created\n'
          '*** Delete File: delete.txt\n'
          '*** End Patch';
      expect(
        await tool.previewFreeform(patch, context),
        patch,
      );
      final output =
          jsonDecode((await tool.executeFreeform(patch, context)).output)
              as Map<String, dynamic>;
      expect(output['changed_files'], 3);
      expect(
        fileSystem.file('/workspace/update.txt').readAsStringSync(),
        'after\n',
      );
      expect(
        fileSystem.file('/workspace/new.txt').readAsStringSync(),
        'created\n',
      );
      expect(fileSystem.file('/workspace/delete.txt').existsSync(), isFalse);
      expect(tool.name, 'apply_patch');
      expect(tool.description, contains('*** Begin Patch'));
      expect(tool.risk, AgentToolRisk.write);
      expect(tool.modelSpec, isA<ModelFreeformToolDefinition>());

      await expectLater(
        tool.executeFreeform(
          '*** Begin Patch\n'
          '*** Delete File: missing.txt\n'
          '*** End Patch',
          context,
        ),
        throwsA(isA<FormatException>()),
      );
    },
  );

  group('patch moves', () {
    late ApplyPatchTool tool;

    setUp(() {
      var suffix = 0;
      tool = ApplyPatchTool(
        fileSystem: fileSystem,
        platform: platform,
        temporarySuffix: () => 'move-${suffix++}',
      );
    });

    Future<Map<String, dynamic>> apply(String patch) async =>
        jsonDecode((await tool.executeFreeform(patch, context)).output)
            as Map<String, dynamic>;

    test('differing headers move the file and edit it in one step', () async {
      fileSystem.file('/workspace/old.txt').writeAsStringSync('before\n');

      final output = await apply(
        '*** Begin Patch\n'
        '*** Update File: old.txt\n'
        '*** Move to: lib/new.txt\n'
        '@@\n'
        '-before\n'
        '+after\n'
        '*** End Patch',
      );

      expect(output['changed_files'], 1);
      expect(fileSystem.file('/workspace/old.txt').existsSync(), isFalse);
      expect(
        fileSystem.file('/workspace/lib/new.txt').readAsStringSync(),
        'after\n',
      );
    });

    test('a move with no hunks still relocates the contents', () async {
      fileSystem.file('/workspace/old.txt').writeAsStringSync('kept\n');

      await apply(
        '*** Begin Patch\n'
        '*** Update File: old.txt\n'
        '*** Move to: renamed.txt\n'
        '*** End Patch',
      );

      expect(fileSystem.file('/workspace/old.txt').existsSync(), isFalse);
      expect(
        fileSystem.file('/workspace/renamed.txt').readAsStringSync(),
        'kept\n',
      );
    });

    test('moving a missing file is refused', () async {
      await expectLater(
        apply(
          '*** Begin Patch\n'
          '*** Update File: gone.txt\n'
          '*** Move to: new.txt\n'
          '*** End Patch',
        ),
        throwsA(isA<FormatException>()),
      );
      expect(fileSystem.file('/workspace/new.txt').existsSync(), isFalse);
    });

    test('a move never clobbers a file the patch did not mention', () async {
      fileSystem
        ..file('/workspace/old.txt').writeAsStringSync('source\n')
        ..file('/workspace/taken.txt').writeAsStringSync('precious\n');

      await expectLater(
        apply(
          '*** Begin Patch\n'
          '*** Update File: old.txt\n'
          '*** Move to: taken.txt\n'
          '*** End Patch',
        ),
        throwsA(isA<FormatException>()),
      );

      // Both files survive untouched: the refusal happens during planning.
      expect(
        fileSystem.file('/workspace/taken.txt').readAsStringSync(),
        'precious\n',
      );
      expect(
        fileSystem.file('/workspace/old.txt').readAsStringSync(),
        'source\n',
      );
    });

    test('a later failure puts a completed move back', () async {
      fileSystem
        ..file('/workspace/old.txt').writeAsStringSync('moved\n')
        ..file('/workspace/second.txt').writeAsStringSync('second\n');
      // The second file's context does not match, so applying it throws after
      // the move has already been written to disk.
      await expectLater(
        apply(
          '*** Begin Patch\n'
          '*** Update File: old.txt\n'
          '*** Move to: new.txt\n'
          '*** Update File: second.txt\n'
          '@@\n'
          '-wrong context\n'
          '+replacement\n'
          '*** End Patch',
        ),
        throwsA(isA<FormatException>()),
      );

      expect(
        fileSystem.file('/workspace/old.txt').readAsStringSync(),
        'moved\n',
      );
      expect(fileSystem.file('/workspace/new.txt').existsSync(), isFalse);
      expect(
        fileSystem.file('/workspace/second.txt').readAsStringSync(),
        'second\n',
      );
    });

    test('an empty patch is rejected', () async {
      await expectLater(
        apply('*** Begin Patch\n*** End Patch'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  test('modern patch parser rejects malformed and conflicting chunks', () {
    expect(
      () => CodexPatch.parse('not a patch'),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => CodexPatch.parse(
        '*** Begin Patch\n*** Add File: f\nnot-added\n*** End Patch',
      ),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => CodexPatch.parse(
        '*** Begin Patch\n*** Update File: f\ninvalid\n*** End Patch',
      ),
      throwsA(isA<FormatException>()),
    );
    final mismatch = CodexPatch.parse(
      '*** Begin Patch\n'
      '*** Update File: f\n'
      '@@\n'
      '-other\n'
      '+new\n'
      '*** End Patch',
    );
    expect(
      () => (mismatch.operations.single as CodexUpdateFile).apply('old\n'),
      throwsA(isA<FormatException>()),
    );
  });

  test('tool output truncation is bounded by one shared limit', () {
    expect(maxToolOutputBytes, 1024 * 1024);
    expect(truncateToolOutput('short'), 'short');
    expect(truncateToolOutput(''), isEmpty);

    final oversized = 'a' * (maxToolOutputBytes + 10);
    expect(
      utf8.encode(truncateToolOutput(oversized)).length,
      lessThanOrEqualTo(maxToolOutputBytes),
    );
    expect(truncateToolOutput(oversized), startsWith('aaa'));

    // A multi-byte character straddling the limit must not become a
    // replacement character.
    final multiByte = '가' * maxToolOutputBytes;
    final truncated = truncateToolOutput(multiByte);
    expect(
      utf8.encode(truncated).length,
      lessThanOrEqualTo(maxToolOutputBytes),
    );
    expect(truncated, isNot(contains('�')));
  });
}
