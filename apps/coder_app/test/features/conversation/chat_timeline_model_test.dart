import 'package:coder_app/src/features/conversation/application/chat_timeline_model.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.utc(2026, 8, 3);
  var sequence = 0;

  TimelineEventDto event(
    String type,
    Map<String, dynamic> data, {
    String? turnId = 'turn-1',
    int? at,
  }) => TimelineEventDto(
    sessionId: 'session',
    sequence: at ?? (sequence += 1),
    turnId: turnId,
    type: type,
    data: data,
    createdAt: now,
  );

  setUp(() => sequence = 0);

  test(
    'projects ordered user and assistant attachment timeline events',
    tags: const <String>['feature_test__conversation_attachments__unit'],
    () {
      final items = projectChatTimeline(<TimelineEventDto>[
        event('user.message', <String, dynamic>{
          'text': '',
          'attachments': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 'image-1',
              'fileName': 'fixture.png',
              'mimeType': 'image/png',
              'byteSize': 11,
              'path': '/daemon/image-1.blob',
            },
          ],
        }),
        event('assistant.attachment', <String, dynamic>{
          'id': 'file-1',
          'fileName': 'result.txt',
          'mimeType': 'text/plain',
          'byteSize': 5,
          'path': '/daemon/file-1.blob',
        }),
      ]);
      final user = items.first as ChatUserMessage;
      expect(user.text, isEmpty);
      expect(user.attachments.single.id, 'image-1');
      final assistant = items.last as ChatAttachmentMessage;
      expect(assistant.attachment.fileName, 'result.txt');
    },
  );

  test(
    'assistant deltas of one turn merge even when tools interleave',
    () {
      final items = projectChatTimeline(<TimelineEventDto>[
        event('user.message', <String, dynamic>{'text': 'Fix it'}),
        event('assistant.delta', <String, dynamic>{'text': 'Reading '}),
        event('tool.requested', <String, dynamic>{
          'callId': 'call-1',
          'name': 'read_file',
          'arguments': <String, dynamic>{'path': 'lib/main.dart'},
        }),
        event('tool.completed', <String, dynamic>{
          'callId': 'call-1',
          'name': 'read_file',
          'output': 'void main() {}',
          'isError': false,
        }),
        event('assistant.delta', <String, dynamic>{'text': 'the '}),
        event('assistant.delta', <String, dynamic>{'text': 'file.'}),
        event('turn.completed', <String, dynamic>{'toolRounds': 1}),
      ]);

      expect(items.map((item) => item.runtimeType.toString()), <String>[
        'ChatUserMessage',
        'ChatAssistantMessage',
        'ChatToolActivity',
        'ChatAssistantMessage',
        'ChatNotice',
      ]);
      expect((items[1] as ChatAssistantMessage).markdown, 'Reading ');
      expect((items[3] as ChatAssistantMessage).markdown, 'the file.');
      expect((items[3] as ChatAssistantMessage).isStreaming, isFalse);
      expect((items[4] as ChatNotice).kind, ChatNoticeKind.turnCompleted);
      expect((items[4] as ChatNotice).toolRounds, 1);
    },
    tags: const <String>['feature_test__turn_execution__unit'],
  );

  test(
    'tool requests and results merge into one activity per call',
    () {
      final items = projectChatTimeline(<TimelineEventDto>[
        event('tool.requested', <String, dynamic>{
          'callId': 'call-1',
          'name': 'exec_command',
          'arguments': <String, dynamic>{'command': 'dart test'},
        }),
        event('tool.completed', <String, dynamic>{
          'callId': 'call-1',
          'name': 'exec_command',
          'output': '{"exitCode":0,"output":"ok"}',
          'isError': false,
        }),
        event('tool.requested', <String, dynamic>{
          'callId': 'call-2',
          'name': 'apply_patch',
          'arguments': <String, dynamic>{'patch': 'diff'},
        }),
        event('tool.failed', <String, dynamic>{
          'callId': 'call-2',
          'name': 'apply_patch',
          'error': 'context mismatch',
        }),
        event('tool.requested', <String, dynamic>{
          'callId': 'call-3',
          'name': 'exec_command',
          'arguments': <String, dynamic>{'command': 'rm -rf /'},
        }),
        event('tool.denied', <String, dynamic>{
          'callId': 'call-3',
          'name': 'exec_command',
        }),
        event('tool.requested', <String, dynamic>{
          'callId': 'call-4',
          'name': 'read_file',
          'arguments': <String, dynamic>{'path': 'a.dart'},
        }),
      ]);

      final activities = items.cast<ChatToolActivity>();
      expect(activities, hasLength(4));
      expect(activities[0].status, ChatToolStatus.succeeded);
      expect(activities[0].output, '{"exitCode":0,"output":"ok"}');
      expect(activities[0].arguments['command'], 'dart test');
      expect(activities[1].status, ChatToolStatus.failed);
      expect(activities[1].error, 'context mismatch');
      expect(activities[2].status, ChatToolStatus.denied);
      expect(activities[3].status, ChatToolStatus.running);
    },
    tags: const <String>['feature_test__turn_execution__unit'],
  );

  test(
    'successful attach_file activity yields only its attachment card',
    () {
      final items = projectChatTimeline(<TimelineEventDto>[
        event('tool.requested', <String, dynamic>{
          'callId': 'attach-1',
          'name': 'attach_file',
          'arguments': <String, dynamic>{'path': 'result.txt'},
        }),
        event('tool.completed', <String, dynamic>{
          'callId': 'attach-1',
          'name': 'attach_file',
          'output': '{"attachmentId":"attachment-1"}',
          'isError': false,
        }),
        event('assistant.attachment', <String, dynamic>{
          'id': 'attachment-1',
          'fileName': 'result.txt',
          'mimeType': 'text/plain',
          'byteSize': 5,
        }),
      ]);

      expect(items.whereType<ChatToolActivity>(), isEmpty);
      expect(items.whereType<ChatAttachmentMessage>(), hasLength(1));
    },
    tags: const <String>['feature_test__conversation_attachments__unit'],
  );

  test(
    'truncated and repeated tool histories stay renderable',
    () {
      final orphan = projectChatTimeline(<TimelineEventDto>[
        event('tool.completed', <String, dynamic>{
          'callId': 'call-1',
          'name': 'read_file',
          'output': 'text',
          'isError': false,
        }),
        event('tool.requested', <String, dynamic>{
          'callId': 'call-1',
          'name': 'read_file',
          'arguments': <String, dynamic>{'path': 'a.dart'},
        }),
      ]).cast<ChatToolActivity>();
      expect(orphan, hasLength(1));
      expect(orphan.single.status, ChatToolStatus.succeeded);
      expect(orphan.single.arguments['path'], 'a.dart');

      final duplicateTerminal = projectChatTimeline(<TimelineEventDto>[
        event('tool.requested', <String, dynamic>{
          'callId': 'call-1',
          'name': 'read_file',
          'arguments': <String, dynamic>{'path': 'a.dart'},
        }),
        event('tool.completed', <String, dynamic>{
          'callId': 'call-1',
          'name': 'read_file',
          'output': 'first',
          'isError': false,
        }),
        event('tool.completed', <String, dynamic>{
          'callId': 'call-1',
          'name': 'read_file',
          'output': 'second',
          'isError': false,
        }),
      ]).cast<ChatToolActivity>();
      expect(duplicateTerminal, hasLength(1));
      expect(duplicateTerminal.single.output, 'first');

      final reinvoked = projectChatTimeline(<TimelineEventDto>[
        event('tool.requested', <String, dynamic>{
          'callId': 'call-1',
          'name': 'read_file',
          'arguments': <String, dynamic>{'path': 'a.dart'},
        }),
        event('tool.completed', <String, dynamic>{
          'callId': 'call-1',
          'name': 'read_file',
          'output': 'first',
          'isError': false,
        }),
        event('tool.requested', <String, dynamic>{
          'callId': 'call-1',
          'name': 'read_file',
          'arguments': <String, dynamic>{'path': 'b.dart'},
        }),
      ]).cast<ChatToolActivity>();
      expect(reinvoked, hasLength(2));
      expect(reinvoked.last.status, ChatToolStatus.running);
      expect(reinvoked.last.arguments['path'], 'b.dart');

      final duplicateRequest = projectChatTimeline(<TimelineEventDto>[
        event('tool.requested', <String, dynamic>{
          'callId': 'call-1',
          'name': 'read_file',
          'arguments': <String, dynamic>{'path': 'a.dart'},
        }),
        event('tool.requested', <String, dynamic>{
          'callId': 'call-1',
          'name': 'read_file',
          'arguments': <String, dynamic>{'path': 'a.dart'},
        }),
      ]);
      expect(duplicateRequest, hasLength(1));
    },
    tags: const <String>['feature_test__turn_execution__unit'],
  );

  test(
    'approvals, usage, failures, and unknown events are typed not dumped',
    () {
      final items = projectChatTimeline(<TimelineEventDto>[
        event('approval.requested', <String, dynamic>{
          'approval': ApprovalRequestDto(
            id: 'approval-1',
            sessionId: 'session',
            turnId: 'turn-1',
            toolCallId: 'call-approval',
            toolName: 'write_file',
            risk: ToolRisk.write,
            arguments: const <String, dynamic>{'path': 'a.dart'},
            status: ApprovalStatus.pending,
            createdAt: now,
          ).toJson(),
        }),
        event('approval.resolved', <String, dynamic>{
          'approvalId': 'approval-1',
          'status': 'approved',
        }),
        event('model.usage', <String, dynamic>{
          'inputTokens': 12,
          'cachedInputTokens': 8,
          'outputTokens': 3,
          'reasoningTokens': 1,
          'totalTokens': 15,
        }),
        event('turn.failed', <String, dynamic>{'error': 'provider down'}),
        event('turn.cancelled', const <String, dynamic>{}, turnId: 'turn-2'),
        event('surprise.event', <String, dynamic>{'a': 1}, turnId: 'turn-3'),
      ]);

      expect(items.whereType<ChatUsage>().single.tokens, <String, num>{
        'inputTokens': 12,
        'cachedInputTokens': 8,
        'outputTokens': 3,
        'reasoningTokens': 1,
        'totalTokens': 15,
      });
      final approval = items.whereType<ChatApprovalInteraction>().single;
      expect(approval.key, 'approval-approval-1');
      expect(approval.status, ChatInteractionStatus.resolved);
      expect(approval.approved, isTrue);
      final notices = items.whereType<ChatNotice>().toList(growable: false);
      expect(notices.map((notice) => notice.kind), <ChatNoticeKind>[
        ChatNoticeKind.turnFailed,
        ChatNoticeKind.turnCancelled,
      ]);
      expect(notices.first.message, 'provider down');
      expect(items.whereType<ChatUnknownEvent>().single.type, 'surprise.event');
      expect(items, hasLength(5));
    },
    tags: const <String>['feature_test__turn_execution__unit'],
  );

  test(
    'projection sorts by sequence and keeps keys stable as events arrive',
    () {
      final first = event('user.message', <String, dynamic>{
        'text': 'Fix it',
      }, at: 1);
      final second = event('assistant.delta', <String, dynamic>{
        'text': 'Working',
      }, at: 2);
      final third = event('tool.requested', <String, dynamic>{
        'callId': 'call-1',
        'name': 'read_file',
        'arguments': <String, dynamic>{'path': 'a.dart'},
      }, at: 3);

      final unsorted = projectChatTimeline(<TimelineEventDto>[
        third,
        first,
        second,
      ]);
      final sorted = projectChatTimeline(<TimelineEventDto>[
        first,
        second,
        third,
      ]);
      expect(
        unsorted.map((item) => item.key),
        sorted.map((item) => item.key),
      );

      final before = projectChatTimeline(<TimelineEventDto>[first, second]);
      expect(
        sorted.take(2).map((item) => item.key),
        before.map((item) => item.key),
      );
      expect(
        before.whereType<ChatAssistantMessage>().single.isStreaming,
        isTrue,
      );
    },
    tags: const <String>['feature_test__turn_execution__unit'],
  );

  testWidgets(
    'a pending question keeps its timeline key when its answer arrives',
    (tester) async {
      final tool = event('tool.requested', <String, dynamic>{
        'callId': 'call-ask',
        'name': 'ask_user',
        'arguments': <String, dynamic>{
          'questions': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 'storage',
              'header': 'Storage',
              'question': 'Which store?',
              'options': <Map<String, dynamic>>[
                <String, dynamic>{'label': 'SQLite', 'description': 'Local'},
              ],
            },
          ],
        },
      });
      final request = UserQuestionRequestDto(
        id: 'request-1',
        sessionId: 'session',
        turnId: 'turn-1',
        toolCallId: 'call-ask',
        questions: const <UserQuestionItemDto>[
          UserQuestionItemDto(
            id: 'storage',
            header: 'Storage',
            question: 'Which store?',
            options: <UserQuestionOptionDto>[
              UserQuestionOptionDto(label: 'SQLite', description: 'Local'),
            ],
          ),
        ],
        status: UserQuestionStatus.pending,
        createdAt: now,
      );

      final pending =
          projectChatTimeline(
                <TimelineEventDto>[tool],
                questions: <String, UserQuestionRequestDto>{
                  request.id: request,
                },
              ).single
              as ChatQuestionInteraction;
      final answered =
          projectChatTimeline(<TimelineEventDto>[
                tool,
                event('tool.completed', <String, dynamic>{
                  'callId': 'call-ask',
                  'name': 'ask_user',
                  'output':
                      '[{"questionId":"storage","answer":"SQLite",'
                      '"isFreeForm":false}]',
                  'isError': false,
                }),
              ]).single
              as ChatUserAnswer;

      expect(answered.key, pending.key);
      expect(answered.entries.single.answer, 'SQLite');
    },
    tags: const <String>['feature_test__turn_question__widget'],
  );

  test(
    'empty assistant text and empty input produce no items',
    () {
      expect(projectChatTimeline(const <TimelineEventDto>[]), isEmpty);
      expect(
        projectChatTimeline(<TimelineEventDto>[
          event('assistant.delta', <String, dynamic>{'text': ''}),
        ]),
        isEmpty,
      );
    },
    tags: const <String>['feature_test__turn_execution__unit'],
  );
}
