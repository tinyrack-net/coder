import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:coder_agent/coder_agent.dart';
import 'package:coder_protocol/coder_protocol.dart';
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
      expect(publisher.paths, <String>[await target.resolveSymbolicLinks()]);
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

  test(
    'every built-in tool publishes a strict, self-describing schema',
    () {
      final publisher = _RecordingAttachmentPublisher();
      final tools = <AgentTool>[
        ListDirectoryTool(),
        ReadFileTool(),
        SearchTextTool(),
        GlobTool(),
        ApplyPatchTool(),
        UpdatePlanTool(),
        AttachFileTool(publisher: publisher),
        ReadAttachmentTool(reader: _RecordingAttachmentReader()),
        ViewImageTool(publisher: publisher),
        AskUserTool(
          coordinator: _RecordingUserQuestionCoordinator(const <UserAnswer>[]),
        ),
      ];

      expect(tools.map((tool) => tool.name).toSet(), hasLength(tools.length));
      for (final tool in tools) {
        final schema = tool.strictJsonSchema;
        expect(tool.name, isNotEmpty, reason: '${tool.runtimeType}');
        expect(tool.description, isNotEmpty, reason: tool.name);
        expect(tool.strict, isTrue, reason: tool.name);
        expect(schema['type'], 'object', reason: tool.name);
        // A strict provider schema demands every property be required and no
        // extra ones be accepted, so an optional value is a nullable type.
        expect(schema['additionalProperties'], isFalse, reason: tool.name);
        final properties = schema['properties']! as Map<String, dynamic>;
        expect(
          schema['required'],
          properties.keys.toList(),
          reason: tool.name,
        );
      }
    },
  );

  test('a persisted attachment reference round-trips through JSON', () {
    final attachment = ConversationAttachment(
      id: 'shot',
      fileName: 'shot.png',
      mimeType: 'image/png',
      byteSize: 3,
      path: '/attachments/shot.blob',
      bytes: Uint8List.fromList(<int>[1, 2, 3]),
      kind: AttachmentKind.image,
      sha256: 'digest',
      createdAt: DateTime.utc(2026, 8, 3),
      imageDetail: 'high',
    );

    final decoded = ConversationAttachment.fromJson(attachment.toJson());
    expect(decoded.id, 'shot');
    expect(decoded.kind, AttachmentKind.image);
    expect(decoded.sha256, 'digest');
    expect(decoded.createdAt, DateTime.utc(2026, 8, 3));
    expect(decoded.imageDetail, 'high');
    // Bytes are hydrated per request and deliberately never serialized.
    expect(decoded.bytes, isNull);

    final bare = ConversationAttachment.fromJson(
      const ConversationAttachment(
        id: 'bare',
        fileName: 'notes.txt',
        mimeType: 'text/plain',
        byteSize: 1,
        path: '/attachments/bare.blob',
      ).toJson(),
    );
    expect(bare.kind, isNull);
    expect(bare.createdAt, isNull);
    expect(bare.imageDetail, isNull);

    // A user item carries its attachments across the same round trip.
    final item =
        ConversationItem.fromJson(
              UserConversationItem(
                'look',
                attachments: <ConversationAttachment>[attachment],
              ).toJson(),
            )
            as UserConversationItem;
    expect(item.attachments.single.imageDetail, 'high');
  });

  group('view_image', () {
    /// A one-pixel PNG, valid down to its magic bytes.
    final png = Uint8List.fromList(<int>[
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, //
      0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
    ]);

    late ToolExecutionContext context;

    setUp(() {
      context = ToolExecutionContext(
        workspaceRoot: workspace.path,
        cancellation: CancellationToken(),
      );
    });

    test(
      'loads a workspace image into the model context',
      tags: const <String>['feature_test__tool_image_context__unit'],
      () async {
        await File('${workspace.path}/shot.png').writeAsBytes(png);
        final publisher = _RecordingAttachmentPublisher();
        final tool = ViewImageTool(publisher: publisher);

        expect(tool.risk, ToolRisk.read);
        final result = await tool.execute(<String, dynamic>{
          'path': 'shot.png',
          'detail': 'high',
        }, context);

        expect(result.isError, isFalse);
        // The image reaches the model, and the same file is shown to the user.
        expect(result.contextImages.single.imageDetail, 'high');
        expect(result.attachments.single.id, result.contextImages.single.id);
        expect(jsonDecode(result.output), containsPair('detail', 'high'));
      },
    );

    test(
      'rejects non-images, bad detail, and workspace escapes',
      tags: const <String>['feature_test__tool_image_context__unit'],
      () async {
        final publisher = _RecordingAttachmentPublisher();
        final tool = ViewImageTool(publisher: publisher);

        // A .png extension does not make a file an image.
        await File('${workspace.path}/fake.png').writeAsString('not an image');
        expect(
          (await tool.execute(<String, dynamic>{
            'path': 'fake.png',
            'detail': null,
          }, context)).isError,
          isTrue,
        );

        // A real image whose type no provider accepts is refused too.
        await File(
          '${workspace.path}/scan.bmp',
        ).writeAsBytes(Uint8List.fromList(<int>[0x42, 0x4D, 0, 0]));
        expect(
          (await tool.execute(<String, dynamic>{
            'path': 'scan.bmp',
            'detail': null,
          }, context)).isError,
          isTrue,
        );

        await File('${workspace.path}/shot.png').writeAsBytes(png);
        expect(
          (await tool.execute(<String, dynamic>{
            'path': 'shot.png',
            'detail': 'ultra',
          }, context)).isError,
          isTrue,
        );

        expect(
          () => tool.execute(<String, dynamic>{
            'path': '${outside.path}/secret.txt',
            'detail': null,
          }, context),
          throwsA(isA<FileSystemException>()),
        );
        expect(publisher.paths, isEmpty);
      },
    );

    test(
      'bounds the images one turn may load',
      tags: const <String>['feature_test__tool_image_context__unit'],
      () async {
        await File('${workspace.path}/shot.png').writeAsBytes(png);
        final tool = ViewImageTool(
          publisher: _RecordingAttachmentPublisher(),
        );
        final arguments = <String, dynamic>{
          'path': 'shot.png',
          'detail': null,
        };
        for (var index = 0; index < maxContextImagesPerTurn; index += 1) {
          expect(
            (await tool.execute(arguments, context)).isError,
            isFalse,
            reason: 'image $index',
          );
        }
        expect((await tool.execute(arguments, context)).isError, isTrue);
      },
    );
  });

  group('ask_user', () {
    late ToolExecutionContext context;

    setUp(() {
      context = ToolExecutionContext(
        workspaceRoot: workspace.path,
        cancellation: CancellationToken(),
      );
    });

    List<Map<String, dynamic>> questions({
      int count = 1,
      int options = 2,
      String header = 'Storage',
    }) => <Map<String, dynamic>>[
      for (var index = 0; index < count; index += 1)
        <String, dynamic>{
          'id': 'q$index',
          'header': header,
          'question': 'Which store should the cache use?',
          'options': <Map<String, dynamic>>[
            for (var option = 0; option < options; option += 1)
              <String, dynamic>{
                'label': 'Option $option',
                'description': 'Description $option',
              },
          ],
        },
    ];

    test(
      'blocks on its port and returns the answers verbatim',
      tags: const <String>['feature_test__turn_question__unit'],
      () async {
        final coordinator = _RecordingUserQuestionCoordinator(
          <UserAnswer>[
            const UserAnswer(
              questionId: 'q0',
              answer: 'Postgres',
              isFreeForm: true,
            ),
          ],
        );
        final tool = AskUserTool(coordinator: coordinator);

        // Asking must never raise an approval dialog and must survive a
        // read-only session, which is where planning happens.
        expect(tool.risk, ToolRisk.read);
        expect(
          const DefaultApprovalPolicy(
            PermissionMode.readOnly,
          ).evaluateRisk(tool.risk),
          ApprovalEvaluation.allow,
        );

        final result = await tool.execute(<String, dynamic>{
          'questions': questions(),
        }, context);

        expect(result.isError, isFalse);
        expect(coordinator.asked.single.single.header, 'Storage');
        expect(coordinator.asked.single.single.options, hasLength(2));
        expect(jsonDecode(result.output), <Map<String, dynamic>>[
          <String, dynamic>{
            'questionId': 'q0',
            'answer': 'Postgres',
            'isFreeForm': true,
          },
        ]);
      },
    );

    test(
      'rejects out-of-bounds questions without reaching the user',
      tags: const <String>['feature_test__turn_question__unit'],
      () async {
        final coordinator = _RecordingUserQuestionCoordinator(
          const <UserAnswer>[],
        );
        final tool = AskUserTool(coordinator: coordinator);

        for (final invalid in <Map<String, dynamic>>[
          <String, dynamic>{'questions': <Map<String, dynamic>>[]},
          <String, dynamic>{'questions': questions(count: 4)},
          <String, dynamic>{'questions': questions(options: 1)},
          <String, dynamic>{'questions': questions(options: 4)},
          <String, dynamic>{
            'questions': questions(header: 'A much longer one'),
          },
          <String, dynamic>{'questions': 'not a list'},
        ]) {
          final result = await tool.execute(invalid, context);
          expect(result.isError, isTrue, reason: '$invalid');
        }
        expect(coordinator.asked, isEmpty);
      },
    );

    test(
      'a duplicate question id is refused before the user sees it',
      tags: const <String>['feature_test__turn_question__unit'],
      () async {
        final coordinator = _RecordingUserQuestionCoordinator(
          const <UserAnswer>[],
        );
        final result = await AskUserTool(coordinator: coordinator).execute(
          <String, dynamic>{
            'questions': <Map<String, dynamic>>[
              ...questions(),
              ...questions(),
            ],
          },
          context,
        );
        expect(result.isError, isTrue);
        expect(coordinator.asked, isEmpty);
      },
    );

    test(
      'cancellation propagates out of the tool',
      tags: const <String>['feature_test__turn_question__unit'],
      () async {
        final cancellation = CancellationToken();
        final tool = AskUserTool(
          coordinator: _CancellingUserQuestionCoordinator(cancellation),
        );
        await expectLater(
          tool.execute(
            <String, dynamic>{'questions': questions()},
            ToolExecutionContext(
              workspaceRoot: workspace.path,
              cancellation: cancellation,
            ),
          ),
          throwsA(isA<AgentCancelledException>()),
        );
      },
    );
  });

  group('update_plan', () {
    late ToolExecutionContext context;

    setUp(() {
      context = ToolExecutionContext(
        workspaceRoot: workspace.path,
        cancellation: CancellationToken(),
      );
    });

    test(
      'echoes a normalized plan and never asks for approval',
      tags: const <String>['feature_test__turn_execution__unit'],
      () async {
        final tool = UpdatePlanTool();
        expect(tool.risk, ToolRisk.read);
        for (final mode in PermissionMode.values) {
          expect(
            DefaultApprovalPolicy(mode).evaluateRisk(tool.risk),
            ApprovalEvaluation.allow,
          );
        }

        final result = await tool.execute(<String, dynamic>{
          'plan': <Map<String, dynamic>>[
            <String, dynamic>{'step': 'Read the parser', 'status': 'completed'},
            <String, dynamic>{'step': 'Move it', 'status': 'in_progress'},
            <String, dynamic>{'step': 'Add tests', 'status': 'pending'},
          ],
          'explanation': 'Parser first.',
        }, context);

        expect(result.isError, isFalse);
        final decoded = jsonDecode(result.output) as Map<String, dynamic>;
        expect(decoded['explanation'], 'Parser first.');
        expect(
          (decoded['plan']! as List<dynamic>).cast<Map<String, dynamic>>().map(
            (step) => step['status'],
          ),
          <String>['completed', 'in_progress', 'pending'],
        );
      },
    );

    test(
      'rejects an empty plan, duplicate steps, and two active steps',
      tags: const <String>['feature_test__turn_execution__unit'],
      () async {
        final tool = UpdatePlanTool();
        Future<ToolResult> run(List<Map<String, dynamic>> plan) =>
            tool.execute(<String, dynamic>{
              'plan': plan,
              'explanation': '',
            }, context);

        for (final plan in <List<Map<String, dynamic>>>[
          <Map<String, dynamic>>[],
          <Map<String, dynamic>>[
            <String, dynamic>{'step': 'Same', 'status': 'pending'},
            <String, dynamic>{'step': 'Same', 'status': 'pending'},
          ],
          <Map<String, dynamic>>[
            <String, dynamic>{'step': 'One', 'status': 'in_progress'},
            <String, dynamic>{'step': 'Two', 'status': 'in_progress'},
          ],
          <Map<String, dynamic>>[
            <String, dynamic>{'step': 'One', 'status': 'done'},
          ],
          <Map<String, dynamic>>[
            <String, dynamic>{'step': '   ', 'status': 'pending'},
          ],
        ]) {
          final result = await run(plan);
          expect(result.isError, isTrue, reason: '$plan');
          expect(jsonDecode(result.output), isA<Map<String, dynamic>>());
        }
      },
    );
  });
}

final class _RecordingUserQuestionCoordinator
    implements UserQuestionCoordinator {
  _RecordingUserQuestionCoordinator(this._answers);

  final List<UserAnswer> _answers;
  final List<List<UserQuestion>> asked = <List<UserQuestion>>[];
  final List<String> callIds = <String>[];

  @override
  Future<List<UserAnswer>> ask(
    String callId,
    List<UserQuestion> questions,
    CancellationToken cancellation,
  ) async {
    callIds.add(callId);
    asked.add(questions);
    return _answers;
  }
}

final class _CancellingUserQuestionCoordinator
    implements UserQuestionCoordinator {
  _CancellingUserQuestionCoordinator(this._cancellation);

  final CancellationToken _cancellation;

  @override
  Future<List<UserAnswer>> ask(
    String callId,
    List<UserQuestion> questions,
    CancellationToken cancellation,
  ) async {
    _cancellation.cancel();
    cancellation.throwIfCancelled();
    return const <UserAnswer>[];
  }
}

final class _RecordingAttachmentPublisher implements AttachmentPublisher {
  final List<String> paths = <String>[];

  @override
  Future<ConversationAttachment> publish(String path) async {
    paths.add(path);
    return ConversationAttachment(
      id: 'published-${paths.length}',
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
