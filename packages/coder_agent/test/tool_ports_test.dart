import 'dart:convert';
import 'dart:io' show FileSystemException;

import 'package:coder_agent/coder_agent.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:file/memory.dart';
import 'package:platform/platform.dart';
import 'package:test/test.dart';

void main() {
  late MemoryFileSystem fileSystem;
  late FakePlatform platform;
  late ToolExecutionContext context;

  setUp(() {
    fileSystem = MemoryFileSystem.test();
    platform = FakePlatform(operatingSystem: 'linux');
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
      expect(list.risk, ToolRisk.read);
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
      expect(read.risk, ToolRisk.read);
      expect(read.strictJsonSchema['required'], hasLength(3));

      final search = SearchTextTool(fileSystem: fileSystem, platform: platform);
      final matches =
          jsonDecode(
                (await search.execute(const <String, dynamic>{
                  'query': 'needle',
                  'path': null,
                  'max_results': 1,
                }, context)).output,
              )
              as List<dynamic>;
      expect(matches, hasLength(1));
      expect(
        (matches.single as Map<String, dynamic>)['path'],
        anyOf('a.txt', 'lib/b.txt'),
      );
      expect(
        () => search.execute(const <String, dynamic>{
          'query': '',
          'path': null,
          'max_results': null,
        }, context),
        throwsA(isA<FormatException>()),
      );
      expect(search.name, 'search_text');
      expect(search.description, contains('Search'));
      expect(search.risk, ToolRisk.read);
      expect(search.strictJsonSchema['required'], hasLength(3));
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
                (await tool.execute(const <String, dynamic>{
                  'query': 'needle',
                  'path': '.',
                  'max_results': 20,
                }, context)).output,
              )
              as List<dynamic>;
      expect((result.single as Map<String, dynamic>)['text'], hasLength(500));

      context.cancellation.cancel();
      await expectLater(
        tool.execute(const <String, dynamic>{
          'query': 'needle',
          'path': '.',
          'max_results': null,
        }, context),
        throwsA(isA<AgentCancelledException>()),
      );
    },
  );

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
      platform: FakePlatform(operatingSystem: Platform.windows),
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
      const patch = '''
--- a/update.txt
+++ b/update.txt
@@ -1,1 +1,1 @@
-before
+after
--- /dev/null
+++ b/new.txt
@@ -0,0 +1,1 @@
+created
--- a/delete.txt
+++ /dev/null
@@ -1,1 +0,0 @@
-delete me
''';
      expect(
        await tool.preview(const <String, dynamic>{'patch': patch}, context),
        patch,
      );
      final output =
          jsonDecode(
                (await tool.execute(const <String, dynamic>{
                  'patch': patch,
                }, context)).output,
              )
              as Map<String, dynamic>;
      expect(output['changedFiles'], 3);
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
      expect(tool.description, contains('unified diff'));
      expect(tool.risk, ToolRisk.write);
      expect(tool.strictJsonSchema['required'], <String>['patch']);

      await expectLater(
        tool.execute(const <String, dynamic>{
          'patch': '--- a/missing.txt\n+++ /dev/null\n@@ -1,1 +0,0 @@\n-x\n',
        }, context),
        throwsA(isA<FormatException>()),
      );
    },
  );

  test('unified patch parser rejects malformed and conflicting hunks', () {
    expect(
      () => UnifiedPatch.parse('not a patch'),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => UnifiedPatch.parse('--- a/file\nmissing\n'),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => UnifiedPatch.parse('--- a/f\n+++ b/f\n@@ invalid\n text\n'),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => UnifiedPatch.parse('--- a/f\n+++ b/f\n@@ -1 +1 @@\n?bad\n'),
      throwsA(isA<FormatException>()),
    );
    final outside = UnifiedPatch.parse(
      '--- a/f\n+++ b/f\n@@ -9,1 +9,1 @@\n-old\n+new\n',
    );
    expect(
      () => outside.files.single.apply('old\n'),
      throwsA(isA<FormatException>()),
    );
    final mismatch = UnifiedPatch.parse(
      '--- a/f\n+++ b/f\n@@ -1,1 +1,1 @@\n-other\n+new\n',
    );
    expect(
      () => mismatch.files.single.apply('old\n'),
      throwsA(isA<FormatException>()),
    );
    const direct = UnifiedPatch(<FilePatch>[
      FilePatch(
        oldPath: 'a/f',
        newPath: 'b/f',
        hunks: <PatchHunk>[
          PatchHunk(oldStart: 0, lines: <String>['+first']),
        ],
      ),
    ]);
    expect(direct.files.single.apply(''), 'first\n');
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
