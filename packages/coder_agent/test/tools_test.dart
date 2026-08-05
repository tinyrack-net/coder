import 'dart:convert';
import 'dart:io';

import 'package:coder_agent/coder_agent.dart';
import 'package:test/test.dart';

void main() {
  late Directory workspace;
  late Directory outside;

  setUp(() async {
    workspace = await Directory.systemTemp.createTemp('coder-tools-workspace-');
    outside = await Directory.systemTemp.createTemp('coder-tools-outside-');
    await File(
      '${outside.path}${Platform.pathSeparator}secret.txt',
    ).writeAsString('secret');
  });

  tearDown(() async {
    await workspace.delete(recursive: true);
    await outside.delete(recursive: true);
  });

  test('file tools reject lexical and symlink workspace escapes', () async {
    final context = ToolExecutionContext(
      workspaceRoot: workspace.path,
      cancellation: CancellationToken(),
    );
    final tool = ReadFileTool();
    expect(
      () => tool.execute(<String, dynamic>{
        'path':
            '../${outside.path.split(Platform.pathSeparator).last}/secret.txt',
        'offset': null,
        'limit': null,
      }, context),
      throwsA(isA<FileSystemException>()),
    );
    if (!Platform.isWindows) {
      await Link('${workspace.path}/escape').create(outside.path);
      expect(
        () => tool.execute(<String, dynamic>{
          'path': 'escape/secret.txt',
          'offset': null,
          'limit': null,
        }, context),
        throwsA(isA<FileSystemException>()),
      );
    }
  });

  test('apply_patch validates context before replacing the file', () async {
    final target = File('${workspace.path}/sample.txt');
    await target.writeAsString('one\ntwo\n');
    final context = ToolExecutionContext(
      workspaceRoot: workspace.path,
      cancellation: CancellationToken(),
    );
    final tool = ApplyPatchTool();
    await tool.execute(<String, dynamic>{
      'patch':
          '--- a/sample.txt\n+++ b/sample.txt\n@@ -1,2 +1,2 @@\n one\n-two\n+three\n',
    }, context);
    expect(await target.readAsString(), 'one\nthree\n');
    await tool.execute(<String, dynamic>{
      'patch':
          '--- /dev/null\n+++ b/nested/new.txt\n@@ -0,0 +1,1 @@\n+created\n',
    }, context);
    expect(
      await File('${workspace.path}/nested/new.txt').readAsString(),
      'created\n',
    );
    expect(
      () => tool.execute(<String, dynamic>{
        'patch':
            '--- a/sample.txt\n+++ b/sample.txt\n@@ -1,1 +1,1 @@\n-missing\n+changed\n',
      }, context),
      throwsA(isA<FormatException>()),
    );
    expect(await target.readAsString(), 'one\nthree\n');
  });

  test(
    'attach_file publishes only regular workspace files',
    tags: const <String>['feature_test__conversation_attachments__unit'],
    () async {
      final target = File('${workspace.path}/result.png');
      await target.writeAsBytes(<int>[1, 2, 3]);
      final publisher = _RecordingAttachmentPublisher();
      final tool = AttachFileTool(publisher: publisher);
      final result = await tool.execute(
        <String, dynamic>{'path': 'result.png'},
        ToolExecutionContext(
          workspaceRoot: workspace.path,
          cancellation: CancellationToken(),
        ),
      );
      expect(publisher.paths, <String>[target.path]);
      expect(result.attachments.single.fileName, 'result.png');
      expect(
        () => tool.execute(
          <String, dynamic>{'path': outside.path},
          ToolExecutionContext(
            workspaceRoot: workspace.path,
            cancellation: CancellationToken(),
          ),
        ),
        throwsA(isA<FileSystemException>()),
      );
    },
  );

  test(
    'read_attachment resolves only opaque IDs through its typed port',
    tags: const <String>['feature_test__conversation_attachments__unit'],
    () async {
      final reader = _RecordingAttachmentReader();
      final result = await ReadAttachmentTool(reader: reader).execute(
        <String, dynamic>{'id': 'attachment-1'},
        ToolExecutionContext(
          workspaceRoot: workspace.path,
          cancellation: CancellationToken(),
        ),
      );
      expect(reader.ids, <String>['attachment-1']);
      expect(jsonDecode(result.output), containsPair('fileName', 'notes.txt'));
    },
  );
}

final class _RecordingAttachmentPublisher implements AttachmentPublisher {
  final List<String> paths = <String>[];

  @override
  Future<ConversationAttachment> publish(String path) async {
    paths.add(path);
    return ConversationAttachment(
      id: 'published',
      fileName: 'result.png',
      mimeType: 'image/png',
      byteSize: 3,
      path: path,
    );
  }
}

final class _RecordingAttachmentReader implements AttachmentReader {
  final List<String> ids = <String>[];

  @override
  Future<ConversationAttachment> read(String id) async {
    ids.add(id);
    return const ConversationAttachment(
      id: 'attachment-1',
      fileName: 'notes.txt',
      mimeType: 'text/plain',
      byteSize: 5,
      path: '/daemon/attachment-1.blob',
    );
  }
}
