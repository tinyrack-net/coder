import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:app/src/app/composition/app_providers.dart';
import 'package:app/src/app/composition/app_services.dart';
import 'package:app/src/app/platform/external_url_opener.dart';
import 'package:app/src/app/presentation/settings_page.dart';
import 'package:app/src/app/presentation/workspace_page.dart';
import 'package:app/src/features/conversation/application/attachment_ports.dart';
import 'package:app/src/features/conversation/application/chat_timeline_model.dart';
import 'package:app/src/features/conversation/application/composer_controller.dart';
import 'package:app/src/features/conversation/application/conversation_controller.dart';
import 'package:app/src/features/conversation/infrastructure/attachment_io.dart';
import 'package:app/src/features/conversation/presentation/chat_approval_card.dart';
import 'package:app/src/features/conversation/presentation/chat_plan.dart';
import 'package:app/src/features/conversation/presentation/chat_question_card.dart';
import 'package:app/src/features/conversation/presentation/chat_timeline_view.dart';
import 'package:app/src/features/conversation/presentation/widgets/session_composer.dart';
import 'package:app/src/features/desktop/infrastructure/desktop_shell.dart';
import 'package:app/src/features/desktop/presentation/desktop_title_bar.dart';
import 'package:app/src/features/hosts/domain/host_models.dart';
import 'package:app/src/features/hosts/domain/host_ports.dart';
import 'package:app/src/features/settings/domain/settings_category.dart';
import 'package:client/client.dart';
import 'package:dropwell/dropwell.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/protocol.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

import '../support/fake_coder_api.dart';
import '../support/fake_desktop_ports.dart';
import '../support/localization.dart';

void main() {
  final now = DateTime.utc(2026);
  final approval = ApprovalRequestDto(
    id: 'approval-1',
    sessionId: 'agent-1',
    turnId: 'turn-1',
    toolCallId: 'call-1',
    toolName: 'apply_patch',
    risk: ToolRisk.write,
    arguments: const <String, dynamic>{'patch': '--- a/file\n+++ b/file'},
    status: ApprovalStatus.pending,
    createdAt: now,
    preview: '--- a/lib/main.dart\n+++ b/lib/main.dart\n+safe change',
  );
  final chatEvents = <TimelineEventDto>[
    TimelineEventDto(
      sessionId: 'agent-1',
      sequence: 1,
      turnId: 'turn-1',
      type: 'user.message',
      data: const <String, dynamic>{
        'text': 'Fix the failing parser test',
        'attachments': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'fixture-image',
            'fileName': 'failure.png',
            'mimeType': 'image/png',
            'byteSize': 28412,
          },
        ],
      },
      createdAt: now,
    ),
    TimelineEventDto(
      sessionId: 'agent-1',
      sequence: 2,
      turnId: 'turn-1',
      type: 'assistant.delta',
      data: const <String, dynamic>{
        'text':
            'Reading the parser and running the suite.\n\n'
            '```dart\nfinal parser = Parser();\n```\n',
      },
      createdAt: now,
    ),
    TimelineEventDto(
      sessionId: 'agent-1',
      sequence: 3,
      turnId: 'turn-1',
      type: 'tool.requested',
      data: const <String, dynamic>{
        'callId': 'call-1',
        'name': 'read_file',
        'arguments': <String, dynamic>{'path': 'lib/parser.dart'},
      },
      createdAt: now,
    ),
    TimelineEventDto(
      sessionId: 'agent-1',
      sequence: 4,
      turnId: 'turn-1',
      type: 'tool.completed',
      data: const <String, dynamic>{
        'callId': 'call-1',
        'name': 'read_file',
        'output': 'line 1\nline 2\nline 3',
        'isError': false,
      },
      createdAt: now,
    ),
    TimelineEventDto(
      sessionId: 'agent-1',
      sequence: 5,
      turnId: 'turn-1',
      type: 'tool.requested',
      data: const <String, dynamic>{
        'callId': 'call-2',
        'name': 'exec_command',
        'arguments': <String, dynamic>{'command': 'dart test'},
      },
      createdAt: now,
    ),
    TimelineEventDto(
      sessionId: 'agent-1',
      sequence: 6,
      turnId: 'turn-1',
      type: 'tool.completed',
      data: const <String, dynamic>{
        'callId': 'call-2',
        'name': 'exec_command',
        'output': '{"exitCode":1,"output":"1 test failed"}',
        'isError': true,
      },
      createdAt: now,
    ),
    TimelineEventDto(
      sessionId: 'agent-1',
      sequence: 7,
      turnId: 'turn-1',
      type: 'assistant.attachment',
      data: const <String, dynamic>{
        'id': 'result-file',
        'fileName': 'test-report.txt',
        'mimeType': 'text/plain',
        'byteSize': 1280,
      },
      createdAt: now,
    ),
    TimelineEventDto(
      sessionId: 'agent-1',
      sequence: 8,
      turnId: 'turn-1',
      type: 'turn.completed',
      data: const <String, dynamic>{'toolRounds': 2},
      createdAt: now,
    ),
  ];
  final longChatEvents = <TimelineEventDto>[
    for (var index = 0; index < 80; index += 1)
      TimelineEventDto(
        sessionId: 'agent-1',
        sequence: index + 1,
        turnId: 'turn-$index',
        type: 'user.message',
        data: <String, dynamic>{
          'text': index < 65
              ? 'Long message $index\nSecond line\nThird line\nFourth line'
              : 'Short message $index',
        },
        createdAt: now,
      ),
  ];
  final question = UserQuestionRequestDto(
    id: 'question',
    sessionId: 'agent-1',
    turnId: 'turn-1',
    toolCallId: 'ask-call',
    questions: const <UserQuestionItemDto>[
      UserQuestionItemDto(
        id: 'store',
        header: 'Storage',
        question: 'Which store should the cache use?',
        options: <UserQuestionOptionDto>[
          UserQuestionOptionDto(
            label: 'SQLite',
            description: 'Durable and already a dependency.',
          ),
          UserQuestionOptionDto(
            label: 'In memory',
            description: 'Fastest, lost on restart.',
          ),
        ],
      ),
      UserQuestionItemDto(
        id: 'theme',
        header: 'Theme',
        question: 'Which theme should the editor use?',
        options: <UserQuestionOptionDto>[
          UserQuestionOptionDto(
            label: 'System',
            description: 'Follow the operating system.',
          ),
          UserQuestionOptionDto(
            label: 'Dark',
            description: 'Always use the dark theme.',
          ),
        ],
      ),
      UserQuestionItemDto(
        id: 'review',
        header: 'Review',
        question: 'How should changes be reviewed?',
        options: <UserQuestionOptionDto>[
          UserQuestionOptionDto(
            label: 'Pull request',
            description: 'Require review before merging.',
          ),
          UserQuestionOptionDto(
            label: 'Direct',
            description: 'Merge directly after checks pass.',
          ),
        ],
      ),
    ],
    status: UserQuestionStatus.pending,
    createdAt: now,
  );
  final planEvents = <TimelineEventDto>[
    TimelineEventDto(
      sessionId: 'agent-1',
      sequence: 1,
      turnId: 'turn-1',
      type: 'user.message',
      data: const <String, dynamic>{'text': 'Plan the parser migration'},
      createdAt: now,
    ),
    TimelineEventDto(
      sessionId: 'agent-1',
      sequence: 2,
      turnId: 'turn-1',
      type: 'assistant.delta',
      data: const <String, dynamic>{
        'text': 'Explored the parser and its tests.',
      },
      createdAt: now,
    ),
    TimelineEventDto(
      sessionId: 'agent-1',
      sequence: 3,
      turnId: 'turn-1',
      type: 'tool.requested',
      data: const <String, dynamic>{
        'callId': 'call-plan',
        'name': 'update_plan',
        'arguments': <String, dynamic>{
          'plan': <Map<String, dynamic>>[
            <String, dynamic>{
              'step': 'Extract the tokenizer',
              'status': 'completed',
            },
            <String, dynamic>{
              'step': 'Move the parser tests',
              'status': 'in_progress',
            },
            <String, dynamic>{'step': 'Run dart test', 'status': 'pending'},
          ],
          'explanation': 'The tokenizer has no dependants, so it moves first.',
        },
      },
      createdAt: now,
    ),
    TimelineEventDto(
      sessionId: 'agent-1',
      sequence: 4,
      turnId: 'turn-1',
      type: 'tool.completed',
      data: const <String, dynamic>{
        'callId': 'call-plan',
        'name': 'update_plan',
        'output': '{}',
      },
      createdAt: now,
    ),
    TimelineEventDto(
      sessionId: 'agent-1',
      sequence: 5,
      turnId: 'turn-1',
      type: 'turn.completed',
      data: const <String, dynamic>{'toolRounds': 1},
      createdAt: now,
    ),
  ];
  final diffActivity = projectChatTimeline(<TimelineEventDto>[
    TimelineEventDto(
      sessionId: 'agent-1',
      sequence: 1,
      turnId: 'turn-1',
      type: 'tool.requested',
      data: const <String, dynamic>{
        'callId': 'call-1',
        'name': 'apply_patch',
        'arguments': <String, dynamic>{
          'patch':
              '--- a/lib/main.dart\n'
              '+++ b/lib/main.dart\n'
              '@@ -1,2 +1,3 @@\n'
              ' final a = 1;\n'
              '-final b = 2;\n'
              '+final b = 3;\n'
              '+final c = 4;\n',
        },
      },
      createdAt: now,
    ),
    TimelineEventDto(
      sessionId: 'agent-1',
      sequence: 2,
      turnId: 'turn-1',
      type: 'tool.completed',
      data: const <String, dynamic>{
        'callId': 'call-1',
        'name': 'apply_patch',
        'output': '{"changedFiles":1}',
        'isError': false,
      },
      createdAt: now,
    ),
  ]).single;

  // The budget row, the divider that replaces a successful reset, and the
  // ordinary row a refused one still draws.
  final contextEvents = <TimelineEventDto>[
    TimelineEventDto(
      sessionId: 'agent-1',
      sequence: 1,
      turnId: 'turn-1',
      type: 'tool.requested',
      data: const <String, dynamic>{
        'callId': 'call-budget',
        'name': 'get_context_remaining',
        'arguments': <String, dynamic>{},
      },
      createdAt: now,
    ),
    TimelineEventDto(
      sessionId: 'agent-1',
      sequence: 2,
      turnId: 'turn-1',
      type: 'tool.completed',
      data: const <String, dynamic>{
        'callId': 'call-budget',
        'name': 'get_context_remaining',
        'output':
            '{"usedTokens":191000,"contextWindowTokens":200000,'
            '"remainingTokens":9000}',
      },
      createdAt: now,
    ),
    TimelineEventDto(
      sessionId: 'agent-1',
      sequence: 3,
      turnId: 'turn-1',
      type: 'context.reset',
      data: const <String, dynamic>{'retained': 2},
      createdAt: now,
    ),
    TimelineEventDto(
      sessionId: 'agent-1',
      sequence: 4,
      turnId: 'turn-1',
      type: 'assistant.delta',
      data: const <String, dynamic>{'text': '이어서 진행할게요.'},
      createdAt: now,
    ),
  ];
  final allChatItems = <ChatItem>[
    ChatUserMessage(
      key: 'user',
      turnId: 'turn-all',
      createdAt: now,
      text: '사용자 메시지는 읽기 방향의 끝에 정렬됩니다.',
      attachments: const <ChatAttachment>[
        ChatAttachment(
          id: 'user-file',
          fileName: 'requirements.md',
          mimeType: 'text/markdown',
          byteSize: 2048,
        ),
      ],
    ),
    ChatAssistantMessage(
      key: 'assistant',
      turnId: 'turn-all',
      createdAt: now,
      markdown: 'Assistant prose shares one leading rail with tools.',
    ),
    // A growing answer carries no caret and no copy action; the busy row at the
    // bottom of the timeline is the only sign that it is still being written.
    ChatAssistantMessage(
      key: 'assistant-streaming',
      turnId: 'turn-all',
      createdAt: now,
      markdown: 'A streaming answer stops mid-',
      isStreaming: true,
    ),
    ChatAttachmentMessage(
      key: 'assistant-attachment',
      turnId: 'turn-all',
      createdAt: now,
      attachment: const ChatAttachment(
        id: 'assistant-file',
        fileName: 'report.txt',
        mimeType: 'text/plain',
        byteSize: 1280,
      ),
    ),
    ChatToolActivity(
      key: 'tool-running',
      turnId: 'turn-all',
      createdAt: now,
      callId: 'call-running',
      toolName: 'read_file',
      arguments: const <String, dynamic>{'path': '/repo/lib/parser.dart'},
      status: ChatToolStatus.running,
    ),
    ChatToolActivity(
      key: 'tool-complete',
      turnId: 'turn-all',
      createdAt: now,
      callId: 'call-complete',
      toolName: 'exec_command',
      arguments: const <String, dynamic>{'command': 'dart test'},
      status: ChatToolStatus.succeeded,
      output: 'All tests passed',
    ),
    ChatToolActivity(
      key: 'tool-failed',
      turnId: 'turn-all',
      createdAt: now,
      callId: 'call-failed',
      toolName: 'mcp__files__read',
      arguments: const <String, dynamic>{'uri': 'file:///private/result'},
      status: ChatToolStatus.failed,
      error: 'Connection closed',
    ),
    ChatToolActivity(
      key: 'tool-denied',
      turnId: 'turn-all',
      createdAt: now,
      callId: 'call-denied',
      toolName: 'apply_patch',
      arguments: const <String, dynamic>{'patch': 'private patch details'},
      status: ChatToolStatus.denied,
      error: 'Denied by user',
    ),
    ChatPlanProposal(
      key: 'plan',
      turnId: 'turn-all',
      createdAt: now,
      steps: const <ChatPlanStep>[
        ChatPlanStep(
          step: 'Align the timeline',
          status: ChatPlanStepStatus.completed,
        ),
        ChatPlanStep(
          step: 'Verify every message type',
          status: ChatPlanStepStatus.inProgress,
        ),
      ],
      explanation: 'All cards use the same content gutter.',
    ),
    ChatApprovalInteraction(
      key: 'approval',
      turnId: 'turn-all',
      createdAt: now,
      approval: approval,
      status: ChatInteractionStatus.resolved,
      approved: true,
    ),
    ChatQuestionInteraction(
      key: 'question',
      turnId: 'turn-all',
      createdAt: now,
      request: UserQuestionRequestDto(
        id: 'fixture-question',
        sessionId: 'agent-1',
        turnId: 'turn-all',
        toolCallId: 'question-call',
        questions: const <UserQuestionItemDto>[
          UserQuestionItemDto(
            id: 'density',
            header: 'Density',
            question: 'Which timeline density should be used?',
            options: <UserQuestionOptionDto>[
              UserQuestionOptionDto(
                label: 'Compact',
                description: 'Keep status rows easy to scan.',
              ),
            ],
          ),
        ],
        status: UserQuestionStatus.pending,
        createdAt: now,
      ),
    ),
    ChatUserAnswer(
      key: 'answer',
      turnId: 'turn-all',
      createdAt: now,
      entries: const <ChatQuestionAnswer>[
        ChatQuestionAnswer(
          header: 'Density',
          question: 'Which timeline density should be used?',
          answer: 'Compact',
          isFreeForm: false,
        ),
      ],
    ),
    ChatSleep(
      key: 'clock__sleep',
      turnId: 'turn-all',
      createdAt: now,
      duration: const Duration(minutes: 2),
      startedAt: now,
      isRunning: false,
      reason: 'Waiting for checks',
    ),
    ChatNotice(
      key: 'notice',
      turnId: 'turn-all',
      createdAt: now,
      kind: ChatNoticeKind.turnCompleted,
      toolRounds: 4,
    ),
    ChatDeferredTools(
      key: 'deferred',
      turnId: 'turn-all',
      createdAt: now,
      count: 3,
    ),
    ChatUsage(
      key: 'usage',
      turnId: 'turn-all',
      createdAt: now,
      tokens: const <String, num>{'input': 1234, 'output': 456},
    ),
    ChatContextReset(
      key: 'reset',
      turnId: 'turn-all',
      createdAt: now,
    ),
    ChatContextCompacted(
      key: 'compacted',
      turnId: 'turn-all',
      createdAt: now,
    ),
    ChatUnknownEvent(
      key: 'unknown',
      turnId: 'turn-all',
      createdAt: now,
      type: 'provider.future_event',
      data: const <String, dynamic>{'uid': 'hidden-until-expanded'},
    ),
  ];

  unawaited(
    goldenTest(
      'every chat item uses the unified desktop and mobile timeline',
      fileName: 'chat_message_types',
      constraints: const BoxConstraints.tightFor(width: 1100, height: 5100),
      builder: () => GoldenTestGroup(
        columns: 2,
        children: <Widget>[
          for (final scenario
              in <({String name, ThemeMode mode, double width})>[
                (name: 'desktop light', mode: ThemeMode.light, width: 640),
                (name: 'desktop dark', mode: ThemeMode.dark, width: 640),
                (name: 'mobile light', mode: ThemeMode.light, width: 360),
                (name: 'mobile dark', mode: ThemeMode.dark, width: 360),
              ])
            GoldenTestScenario(
              name: scenario.name,
              child: SizedBox(
                width: scenario.width,
                height: 2400,
                child: _chatItems(scenario.mode, allChatItems, busy: true),
              ),
            ),
        ],
      ),
    ),
  );

  for (final variant in <({String name, ThemeMode mode})>[
    (name: 'light', mode: ThemeMode.light),
    (name: 'dark', mode: ThemeMode.dark),
  ]) {
    unawaited(
      goldenTest(
        'Markdown selection stays continuous through inline code '
        '${variant.name}',
        fileName: 'chat_markdown_selection_${variant.name}',
        constraints: const BoxConstraints.tightFor(width: 560, height: 260),
        whilePerforming: (tester) async {
          final first = find.textContaining(
            'Drag from prose',
            findRichText: true,
          );
          final last = find.textContaining(
            'highlight continuous.',
            findRichText: true,
          );
          final selection = await tester.startGesture(
            tester.getTopLeft(first) + const Offset(1, 1),
            kind: PointerDeviceKind.mouse,
          );
          await tester.pump();
          await selection.moveTo(
            tester.getBottomRight(last) - const Offset(1, 1),
          );
          await tester.pump();
          await selection.up();
          await tester.pumpAndSettle();
          return null;
        },
        builder: () => SizedBox(
          width: 500,
          height: 180,
          child: _chatItem(
            variant.mode,
            ChatAssistantMessage(
              key: 'selection-${variant.name}',
              turnId: 'turn-selection',
              createdAt: now,
              markdown:
                  'Drag from prose through `inline_code` and keep the '
                  'highlight continuous.',
              isStreaming: true,
            ),
          ),
        ),
      ),
    );
  }

  unawaited(
    goldenTest(
      'chat timeline and approval cards render in light and dark themes',
      fileName: 'core_cards',
      constraints: const BoxConstraints.tightFor(width: 1000, height: 2560),
      builder: () => GoldenTestGroup(
        columns: 2,
        children: <Widget>[
          GoldenTestScenario(
            name: 'timeline light',
            child: SizedBox(
              width: 460,
              height: 420,
              child: _chat(ThemeMode.light, chatEvents),
            ),
          ),
          GoldenTestScenario(
            name: 'timeline dark',
            child: SizedBox(
              width: 460,
              height: 420,
              child: _chat(ThemeMode.dark, chatEvents),
            ),
          ),
          GoldenTestScenario(
            name: 'diff light',
            child: SizedBox(
              width: 460,
              height: 260,
              child: _chatItem(ThemeMode.light, diffActivity),
            ),
          ),
          GoldenTestScenario(
            name: 'diff dark',
            child: SizedBox(
              width: 460,
              height: 260,
              child: _chatItem(ThemeMode.dark, diffActivity),
            ),
          ),
          GoldenTestScenario(
            name: 'approval light',
            child: SizedBox(
              width: 460,
              height: 300,
              child: _material(
                ThemeMode.light,
                ProviderScope(
                  child: ApprovalCard(hostId: 'server', approval: approval),
                ),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'approval dark',
            child: SizedBox(
              width: 460,
              height: 300,
              child: _material(
                ThemeMode.dark,
                ProviderScope(
                  child: ApprovalCard(hostId: 'server', approval: approval),
                ),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'resolved approval light',
            child: SizedBox(
              width: 460,
              height: 300,
              child: _material(
                ThemeMode.light,
                ProviderScope(
                  child: ApprovalCard(
                    interaction: ChatApprovalInteraction(
                      key: 'approval-${approval.id}',
                      turnId: approval.turnId,
                      createdAt: approval.createdAt,
                      approval: approval,
                      status: ChatInteractionStatus.resolved,
                      approved: true,
                    ),
                  ),
                ),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'resolved approval dark',
            child: SizedBox(
              width: 460,
              height: 300,
              child: _material(
                ThemeMode.dark,
                ProviderScope(
                  child: ApprovalCard(
                    interaction: ChatApprovalInteraction(
                      key: 'approval-${approval.id}',
                      turnId: approval.turnId,
                      createdAt: approval.createdAt,
                      approval: approval,
                      status: ChatInteractionStatus.resolved,
                      approved: true,
                    ),
                  ),
                ),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'plan light',
            child: SizedBox(
              width: 460,
              height: 340,
              child: _chat(ThemeMode.light, planEvents),
            ),
          ),
          GoldenTestScenario(
            name: 'plan dark',
            child: SizedBox(
              width: 460,
              height: 340,
              child: _chat(ThemeMode.dark, planEvents),
            ),
          ),
          GoldenTestScenario(
            name: 'question light',
            child: SizedBox(
              width: 460,
              height: 400,
              child: _material(
                ThemeMode.light,
                ProviderScope(
                  child: ChatQuestionCard(hostId: 'server', request: question),
                ),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'question dark',
            child: SizedBox(
              width: 460,
              height: 400,
              child: _material(
                ThemeMode.dark,
                ProviderScope(
                  child: ChatQuestionCard(hostId: 'server', request: question),
                ),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'context light',
            child: SizedBox(
              width: 460,
              height: 260,
              child: _chat(ThemeMode.light, contextEvents),
            ),
          ),
          GoldenTestScenario(
            name: 'context dark',
            child: SizedBox(
              width: 460,
              height: 260,
              child: _chat(ThemeMode.dark, contextEvents),
            ),
          ),
          GoldenTestScenario(
            name: 'empty light',
            child: SizedBox(
              width: 460,
              height: 220,
              child: _chat(ThemeMode.light, const <TimelineEventDto>[]),
            ),
          ),
          GoldenTestScenario(
            name: 'empty dark',
            child: SizedBox(
              width: 460,
              height: 220,
              child: _chat(ThemeMode.dark, const <TimelineEventDto>[]),
            ),
          ),
        ],
      ),
    ),
  );

  unawaited(
    goldenTest(
      'long mixed-height chat keeps its scrollbar stable',
      fileName: 'chat_scrollbar',
      constraints: const BoxConstraints.tightFor(width: 1000, height: 620),
      whilePerforming: (tester) async {
        for (final element in find.byType(Scrollable).evaluate()) {
          final state = (element as StatefulElement).state as ScrollableState;
          state.position.jumpTo(420);
        }
        await tester.pump();
        await tester.pump(TRMotion.fast);
        return null;
      },
      builder: () => GoldenTestGroup(
        columns: 2,
        children: <Widget>[
          GoldenTestScenario(
            name: 'long timeline light',
            child: SizedBox(
              width: 460,
              height: 420,
              child: _chat(ThemeMode.light, longChatEvents),
            ),
          ),
          GoldenTestScenario(
            name: 'long timeline dark',
            child: SizedBox(
              width: 460,
              height: 420,
              child: _chat(ThemeMode.dark, longChatEvents),
            ),
          ),
        ],
      ),
    ),
  );

  unawaited(
    goldenTest(
      'provider settings adapts to desktop and mobile widths',
      fileName: 'provider_settings',
      constraints: const BoxConstraints.tightFor(width: 1500, height: 900),
      builder: () => GoldenTestGroup(
        columns: 2,
        children: <Widget>[
          GoldenTestScenario(
            name: 'desktop light',
            child: SizedBox(
              width: 1100,
              height: 760,
              child: _settings(ThemeMode.light),
            ),
          ),
          GoldenTestScenario(
            name: 'mobile dark',
            child: SizedBox(
              width: 390,
              height: 760,
              child: _settings(ThemeMode.dark),
            ),
          ),
        ],
      ),
    ),
  );

  unawaited(
    goldenTest(
      'project settings adapts to desktop and mobile widths',
      fileName: 'project_settings',
      constraints: const BoxConstraints.tightFor(width: 1500, height: 900),
      builder: () => GoldenTestGroup(
        columns: 2,
        children: <Widget>[
          GoldenTestScenario(
            name: 'desktop light',
            child: SizedBox(
              width: 1100,
              height: 760,
              child: _projectSettings(ThemeMode.light),
            ),
          ),
          GoldenTestScenario(
            name: 'mobile dark',
            child: SizedBox(
              width: 390,
              height: 760,
              child: _projectSettings(ThemeMode.dark),
            ),
          ),
        ],
      ),
    ),
  );

  unawaited(
    goldenTest(
      'Markdown agent settings adapts to desktop and mobile widths',
      fileName: 'agent_settings',
      constraints: const BoxConstraints.tightFor(width: 1500, height: 900),
      builder: () => GoldenTestGroup(
        columns: 2,
        children: <Widget>[
          GoldenTestScenario(
            name: 'desktop light',
            child: SizedBox(
              width: 1100,
              height: 760,
              child: _agentSettings(ThemeMode.light),
            ),
          ),
          GoldenTestScenario(
            name: 'mobile dark',
            child: SizedBox(
              width: 390,
              height: 760,
              child: _agentSettings(ThemeMode.dark),
            ),
          ),
        ],
      ),
    ),
  );

  // The tool list is far below the fold of the agent_settings golden, so the
  // group rows need a frame of their own. All three states are in it: a locked
  // group of always-on tools, a closed group nothing is on in, and an open one
  // where the header reads partial because only some of its tools are on.
  // One theme per file: the interaction has to scroll, and a scroll needs a
  // single scrollable rather than one per scenario in a shared tree.
  for (final (fileName, mode) in <(String, ThemeMode)>[
    ('agent_tool_groups_light', ThemeMode.light),
    ('agent_tool_groups_dark', ThemeMode.dark),
  ]) {
    unawaited(
      goldenTest(
        'agent tool groups collapse, lock, and report a partial selection '
        '($fileName)',
        fileName: fileName,
        constraints: const BoxConstraints.tightFor(width: 1160, height: 860),
        pumpBeforeTest: _revealAgentToolGroups,
        builder: () => GoldenTestGroup(
          children: <Widget>[
            // The desktop width on purpose: below the list-detail breakpoint
            // the page shows its agent list instead of the editor the tool
            // groups live in.
            GoldenTestScenario(
              name: 'desktop',
              child: SizedBox(
                width: 1100,
                height: 760,
                child: _agentSettings(mode),
              ),
            ),
          ],
        ),
      ),
    );
  }

  unawaited(
    goldenTest(
      'MCP settings shows user and project servers with their status',
      fileName: 'mcp_settings',
      constraints: const BoxConstraints.tightFor(width: 1500, height: 900),
      builder: () => GoldenTestGroup(
        columns: 2,
        children: <Widget>[
          GoldenTestScenario(
            name: 'desktop light',
            child: SizedBox(
              width: 1100,
              height: 760,
              child: _mcpSettings(ThemeMode.light),
            ),
          ),
          GoldenTestScenario(
            name: 'mobile dark',
            child: SizedBox(
              width: 390,
              height: 760,
              child: _mcpSettings(ThemeMode.dark),
            ),
          ),
        ],
      ),
    ),
  );

  unawaited(
    goldenTest(
      'skill settings adapts to desktop and mobile widths',
      fileName: 'skill_settings',
      constraints: const BoxConstraints.tightFor(width: 1500, height: 900),
      builder: () => GoldenTestGroup(
        columns: 2,
        children: <Widget>[
          GoldenTestScenario(
            name: 'desktop light',
            child: SizedBox(
              width: 1100,
              height: 760,
              child: _skillSettings(ThemeMode.light),
            ),
          ),
          GoldenTestScenario(
            name: 'mobile dark',
            child: SizedBox(
              width: 390,
              height: 760,
              child: _skillSettings(ThemeMode.dark),
            ),
          ),
        ],
      ),
    ),
  );

  unawaited(
    goldenTest(
      'daemon settings render embedded exposure and remote-only states',
      fileName: 'daemon_hosts',
      constraints: const BoxConstraints.tightFor(width: 1500, height: 1700),
      builder: () => GoldenTestGroup(
        columns: 2,
        children: <Widget>[
          GoldenTestScenario(
            name: 'embedded exposure desktop',
            child: SizedBox(
              width: 800,
              height: 700,
              child: _localSettings(ThemeMode.light),
            ),
          ),
          GoldenTestScenario(
            name: 'remote settings mobile',
            child: SizedBox(
              width: 390,
              height: 700,
              child: _globalSettings(ThemeMode.dark),
            ),
          ),
          // The alert has to stay readable with the longest guidance the app
          // can produce alongside both of its actions.
          GoldenTestScenario(
            name: 'embedded already running desktop',
            child: SizedBox(
              width: 800,
              height: 700,
              child: _localSettings(
                ThemeMode.dark,
                launcher: const _GoldenEmbeddedLauncher(
                  failure: HostConnectionFailure.network(
                    'lock failed',
                    reason: HostFailureReason.embeddedAlreadyRunning,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  // A rejected port has to read as an ordinary form error: the control carries
  // the invalid frame and the message, so the row description stays the
  // setting's explanation rather than doubling as its error channel.
  unawaited(
    goldenTest(
      'a rejected embedded port marks the control invalid',
      fileName: 'daemon_port_invalid',
      constraints: const BoxConstraints.tightFor(width: 1300, height: 800),
      pumpBeforeTest: (tester) async {
        await tester.pumpAndSettle();
        final ports = find.descendant(
          of: find.byKey(const ValueKey<String>('embedded-daemon-port')),
          matching: find.byType(EditableText),
        );
        for (var index = 0; index < ports.evaluate().length; index++) {
          await tester.enterText(ports.at(index), '70000');
        }
        await tester.pumpAndSettle();
      },
      builder: () => GoldenTestGroup(
        columns: 2,
        children: <Widget>[
          GoldenTestScenario(
            name: 'embedded invalid port desktop',
            child: SizedBox(
              width: 800,
              height: 700,
              child: _localSettings(ThemeMode.light),
            ),
          ),
          // The narrowest window the row has to hold: its control rail is a
          // field and a button, so the title has the least room here.
          GoldenTestScenario(
            name: 'embedded invalid port mobile',
            child: SizedBox(
              width: 390,
              height: 700,
              child: _localSettings(ThemeMode.dark),
            ),
          ),
        ],
      ),
    ),
  );

  unawaited(
    goldenTest(
      'workspace shell adapts to sidebar state and width',
      fileName: 'workspace_shell',
      constraints: const BoxConstraints.tightFor(width: 1060, height: 1400),
      builder: () => GoldenTestGroup(
        columns: 1,
        children: <Widget>[
          GoldenTestScenario(
            name: 'Windows custom chrome light',
            child: SizedBox(
              width: 1000,
              height: 620,
              child: _shell(ThemeMode.light),
            ),
          ),
          GoldenTestScenario(
            name: 'Linux native chrome menu light',
            child: SizedBox(
              width: 1000,
              height: 620,
              child: _shell(
                ThemeMode.light,
                chrome: DesktopWindowChrome.nativeWithMenuBar,
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Windows custom chrome collapsed dark',
            child: SizedBox(
              width: 1000,
              height: 620,
              child: _shell(ThemeMode.dark, collapsed: true),
            ),
          ),
        ],
      ),
    ),
  );

  unawaited(
    goldenTest(
      'session composer adapts to desktop and mobile widths',
      fileName: 'session_composer',
      constraints: const BoxConstraints.tightFor(width: 1500, height: 900),
      builder: () => GoldenTestGroup(
        columns: 2,
        children: <Widget>[
          GoldenTestScenario(
            name: 'desktop light',
            child: SizedBox(
              width: 1100,
              height: 760,
              child: _sessionComposer(ThemeMode.light),
            ),
          ),
          GoldenTestScenario(
            name: 'mobile dark',
            child: SizedBox(
              width: 390,
              height: 760,
              child: _sessionComposer(ThemeMode.dark),
            ),
          ),
        ],
      ),
    ),
  );

  unawaited(
    goldenTest(
      'wide conversation keeps its content on one centered column',
      fileName: 'conversation_content_width',
      constraints: const BoxConstraints.tightFor(width: 1500, height: 900),
      builder: () => SizedBox(
        width: 1500,
        height: 900,
        child: _sessionComposer(ThemeMode.dark, conversation: true),
      ),
    ),
  );

  unawaited(
    goldenTest(
      'desktop workspace renders a nested pane tree',
      fileName: 'workspace_multi_pane',
      constraints: const BoxConstraints.tightFor(width: 1100, height: 760),
      builder: () => SizedBox(
        width: 1100,
        height: 760,
        child: _sessionComposer(
          ThemeMode.dark,
          split: true,
          nestedSplit: true,
        ),
      ),
    ),
  );

  unawaited(
    goldenTest(
      'mobile workspace presents all pane tabs in a sheet',
      fileName: 'workspace_mobile_tab_sheet',
      constraints: const BoxConstraints.tightFor(width: 390, height: 760),
      builder: () => SizedBox(
        width: 390,
        height: 760,
        child: _sessionComposer(ThemeMode.dark, split: true),
      ),
      whilePerforming: (tester) async {
        await tester.tap(
          find.byKey(const ValueKey<String>('workspace-mobile-tab-trigger')),
        );
        await tester.pumpAndSettle();
        return null;
      },
    ),
  );

  unawaited(
    goldenTest(
      'directory new workspace hides Git targets',
      fileName: 'new_workspace_directory',
      constraints: const BoxConstraints.tightFor(width: 1100, height: 760),
      // The composer starts in no project, so the directory project has to be
      // chosen for this golden to show what it is named after.
      pumpBeforeTest: (tester) async {
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('new-workspace-project')));
        await tester.pumpAndSettle();
        await tester.tap(find.textContaining('Plain folder ·').last);
        await tester.pumpAndSettle();
      },
      builder: () => SizedBox(
        width: 1100,
        height: 760,
        child: _directoryNewWorkspace(ThemeMode.light),
      ),
    ),
  );

  unawaited(
    goldenTest(
      'session composer exposes ready invalid and loading states',
      fileName: 'composer_states',
      constraints: const BoxConstraints.tightFor(width: 960, height: 1910),
      builder: () => GoldenTestGroup(
        columns: 1,
        children: <Widget>[
          GoldenTestScenario(
            name: 'ready light',
            child: SizedBox(
              width: 900,
              height: 200,
              child: _composerState(ThemeMode.light),
            ),
          ),
          GoldenTestScenario(
            name: 'invalid light',
            child: SizedBox(
              width: 900,
              height: 220,
              child: _composerState(
                ThemeMode.light,
                enabled: false,
                hint: '사용할 모델을 먼저 선택하세요.',
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'loading dark',
            child: SizedBox(
              width: 900,
              height: 200,
              child: _composerState(ThemeMode.dark, enabled: false),
            ),
          ),
          GoldenTestScenario(
            name: 'context nearly full light',
            child: SizedBox(
              width: 900,
              height: 240,
              child: _composerState(
                ThemeMode.light,
                contextTokens: 196000,
                contextWindow: 200000,
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'context nearly full dark',
            child: SizedBox(
              width: 900,
              height: 240,
              child: _composerState(
                ThemeMode.dark,
                contextTokens: 196000,
                contextWindow: 200000,
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'stoppable during a turn light',
            child: SizedBox(
              width: 900,
              height: 200,
              child: _composerState(
                ThemeMode.light,
                busy: true,
                stoppable: true,
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'queued during a turn dark',
            child: SizedBox(
              width: 900,
              height: 260,
              child: _composerState(
                ThemeMode.dark,
                busy: true,
                stoppable: true,
                queued: const <QueuedTurn>[
                  QueuedTurn(
                    id: 'queued',
                    text: '테스트도 함께 고쳐줘',
                    attachments: <PendingAttachment>[],
                  ),
                ],
              ),
            ),
          ),
          GoldenTestScenario(
            // A prompt that stopped retrying has to read differently from one
            // that is merely waiting its turn, which is a pixel contract.
            name: 'queued send failed light',
            child: SizedBox(
              width: 900,
              height: 260,
              child: _composerState(
                ThemeMode.light,
                busy: true,
                queued: const <QueuedTurn>[
                  QueuedTurn(
                    id: 'queued',
                    text: '테스트도 함께 고쳐줘',
                    attachments: <PendingAttachment>[],
                    attempts: conversationDrainMaxAttempts,
                    error: 'Exception: offline',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );

  for (final mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
    unawaited(
      goldenTest(
        'context usage details ${mode.name}',
        fileName: 'context_usage_details_${mode.name}',
        constraints: const BoxConstraints.tightFor(width: 960, height: 520),
        builder: () => _composerState(
          mode,
          contextTokens: 150000,
          contextWindow: 200000,
          totalCostUsd: 1.25,
          providerConnectionId: 'openai',
          onLoadProviderUsage: () async => <ProviderUsageDto>[
            ProviderUsageDto(
              connectionId: 'openai',
              status: ProviderUsageStatus.available,
              fetchedAt: DateTime.utc(2026),
              provider: 'OpenAI',
              plan: 'plus',
              windows: const <ProviderUsageWindowDto>[
                ProviderUsageWindowDto(
                  kind: ProviderUsageWindowKind.session,
                  usedPercent: 40,
                ),
                ProviderUsageWindowDto(
                  kind: ProviderUsageWindowKind.weekly,
                  usedPercent: 72,
                ),
              ],
              creditBalance: 3.5,
            ),
          ],
        ),
        whilePerforming: (tester) async {
          final mouse = await tester.createGesture(
            kind: PointerDeviceKind.mouse,
          );
          await mouse.addPointer(location: Offset.zero);
          addTearDown(mouse.removePointer);
          await mouse.moveTo(
            tester.getCenter(
              find.byKey(
                const ValueKey<String>('session-composer-context-meter'),
              ),
            ),
          );
          await tester.pump(const Duration(seconds: 1));
          await tester.pumpAndSettle();
          return null;
        },
      ),
    );
  }

  unawaited(
    goldenTest(
      'pane file drop overlay covers the complete composer surface',
      fileName: 'composer_drop_overlay',
      constraints: const BoxConstraints.tightFor(width: 1880, height: 600),
      pumpBeforeTest: (tester) async {
        await tester.pumpAndSettle();
        for (final region in tester.widgetList<DropwellRegion>(
          find.byType(DropwellRegion),
        )) {
          region.onHoverChanged?.call(true);
        }
        await tester.pumpAndSettle();
      },
      builder: () => GoldenTestGroup(
        columns: 2,
        children: <Widget>[
          GoldenTestScenario(
            name: 'light',
            child: const SizedBox(
              width: 900,
              height: 500,
              child: _ComposerDropOverlayGolden(mode: ThemeMode.light),
            ),
          ),
          GoldenTestScenario(
            name: 'dark',
            child: const SizedBox(
              width: 900,
              height: 500,
              child: _ComposerDropOverlayGolden(mode: ThemeMode.dark),
            ),
          ),
        ],
      ),
    ),
  );
}

class _ComposerDropOverlayGolden extends StatefulWidget {
  const _ComposerDropOverlayGolden({required this.mode});

  final ThemeMode mode;

  @override
  State<_ComposerDropOverlayGolden> createState() =>
      _ComposerDropOverlayGoldenState();
}

class _ComposerDropOverlayGoldenState
    extends State<_ComposerDropOverlayGolden> {
  final SessionComposerController _controller = SessionComposerController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ProviderScope(
    overrides: [
      appServicesProvider.overrideWithValue(fakeAppServices(FakeCoderApi())),
    ],
    child: _material(
      widget.mode,
      ComposerDropPane(
        controller: _controller,
        child: Column(
          children: <Widget>[
            const Expanded(child: Center(child: Text('Conversation'))),
            SessionComposer(
              controller: _controller,
              enabled: true,
              attachmentInput: const _GoldenDropInput(),
              onSubmit: (_) {},
              bar: _goldenComposerBar(),
            ),
          ],
        ),
      ),
    ),
  );
}

SessionComposerBar _goldenComposerBar() => SessionComposerBar(
  hostId: 'server',
  definitions: const <AgentDefinitionDto>[],
  agentDefinitionId: null,
  selection: null,
  onAgentChanged: (_) {},
  onModelChanged: (_, _) {},
  mode: SessionMode.normal,
  onModeChanged: (_) {},
);

final class _GoldenDropInput implements AttachmentInputPort {
  const _GoldenDropInput();

  @override
  bool get supportsDrop => true;

  @override
  Future<List<PendingAttachment>> droppedFiles(
    List<DropwellFile> files,
  ) async => const <PendingAttachment>[];

  @override
  Future<List<PendingAttachment>> pasteFiles() async =>
      const <PendingAttachment>[];

  @override
  Future<List<PendingAttachment>> pickFiles() async =>
      const <PendingAttachment>[];
}

Widget _composerState(
  ThemeMode mode, {
  bool enabled = true,
  String? hint,
  bool busy = false,
  bool stoppable = false,
  List<QueuedTurn> queued = const <QueuedTurn>[],
  int contextTokens = 0,
  int? contextWindow,
  double? totalCostUsd,
  String? providerConnectionId,
  Future<List<ProviderUsageDto>> Function()? onLoadProviderUsage,
}) => ProviderScope(
  overrides: [
    appServicesProvider.overrideWithValue(fakeAppServices(FakeCoderApi())),
    attachmentInputProvider.overrideWithValue(null),
  ],
  child: _material(
    mode,
    Align(
      alignment: Alignment.bottomCenter,
      child: SessionComposer(
        enabled: enabled,
        hint: hint,
        busy: busy,
        queued: queued,
        contextTokens: contextTokens,
        contextWindow: contextWindow,
        totalCostUsd: totalCostUsd,
        providerConnectionId: providerConnectionId,
        onLoadProviderUsage: onLoadProviderUsage,
        onQueue: (_) {},
        onQueuedEdit: (_) => null,
        onQueuedSendNow: (_) {},
        onStop: stoppable ? () {} : null,
        onSubmit: (_) {},
        bar: SessionComposerBar(
          hostId: 'server',
          definitions: const <AgentDefinitionDto>[
            AgentDefinitionDto(
              id: 'coder',
              name: 'Coder',
              description: 'General-purpose coding agent',
              mode: AgentMode.primary,
              promptEnabled: true,
              systemPrompt: 'Code carefully.',
              model: AgentModelSelectionDto(
                source: AgentModelSource.session,
              ),
              modelControls: <String, ModelControlValueDto>{
                'reasoning_effort': ModelControlValueDto.stringValue(
                  value: 'medium',
                ),
              },
              permissionMode: PermissionMode.ask,
              toolIds: <String>[],
              callableAgentIds: <String>[],
              contentHash: 'coder-hash',
              sourcePath: '/config/agents/coder.md',
              isBuiltIn: true,
            ),
          ],
          agentDefinitionId: 'coder',
          selection: const SessionModelSelectionDto(
            modelId: 'openai/gpt-5.6-sol',
          ),
          onAgentChanged: (_) {},
          onModelChanged: (_, _) {},
          mode: SessionMode.normal,
          onModeChanged: (_) {},
          enabled: enabled,
        ),
      ),
    ),
  ),
);

Widget _sessionComposer(
  ThemeMode mode, {
  bool split = false,
  bool nestedSplit = false,
  bool conversation = false,
}) {
  final now = DateTime.utc(2026);
  final workspace = WorkspaceDto(
    id: 'workspace',
    name: 'Coder',
    rootPath: '/repos/coder',
    kind: WorkspaceKind.git,
    createdAt: now,
  );
  final checkout = WorktreeDto(
    id: 'checkout',
    workspaceId: workspace.id,
    name: 'main',
    path: workspace.rootPath,
    branch: 'main',
    head: 'abc',
    kind: WorktreeKind.checkout,
    isCoderOwned: false,
    createdAt: now,
  );
  final rootSession = SessionDto(
    id: 'golden-session',
    worktreeId: checkout.id,
    title: 'Centered conversation',
    agentDefinitionId: 'coder',
    origin: SessionOrigin.manual,
    status: SessionStatus.idle,
    createdAt: now,
    updatedAt: now,
  );
  final childSession = SessionDto(
    id: 'golden-child',
    worktreeId: checkout.id,
    title: 'Inspect responsive layout',
    agentDefinitionId: 'coder',
    origin: SessionOrigin.delegated,
    status: SessionStatus.running,
    parentSessionId: rootSession.id,
    taskName: 'Inspect responsive layout',
    lifecycle: AgentLifecycle.running,
    createdAt: now,
    updatedAt: now,
  );
  final api = FakeCoderApi(
    workspaces: <WorkspaceDto>[workspace],
    worktrees: <WorktreeDto>[checkout],
    agents: conversation
        ? <SessionDto>[rootSession, childSession]
        : const <SessionDto>[],
    timelines: conversation
        ? <String, List<TimelineEventDto>>{
            rootSession.id: <TimelineEventDto>[
              TimelineEventDto(
                sessionId: rootSession.id,
                sequence: 1,
                turnId: 'golden-turn',
                type: 'user.message',
                data: const <String, dynamic>{
                  'text': 'Center the conversation content like Paseo.',
                },
                createdAt: now,
              ),
              TimelineEventDto(
                sessionId: rootSession.id,
                sequence: 2,
                turnId: 'golden-turn',
                type: 'assistant.delta',
                data: const <String, dynamic>{
                  'text':
                      'The timeline, goal, subagent track, and composer now '
                      'share one readable centerline.',
                },
                createdAt: now,
              ),
              TimelineEventDto(
                sessionId: rootSession.id,
                sequence: 3,
                turnId: 'golden-turn',
                type: 'turn.completed',
                data: const <String, dynamic>{'toolRounds': 0},
                createdAt: now,
              ),
            ],
          }
        : const <String, List<TimelineEventDto>>{},
    goals: conversation
        ? <String, GoalDto>{
            rootSession.id: GoalDto(
              sessionId: rootSession.id,
              goalId: 'golden-goal',
              objective: 'Keep the conversation column aligned',
              status: GoalStatus.active,
              tokensUsed: 4200,
              timeUsedSeconds: 30,
              createdAt: now,
              updatedAt: now,
            ),
          }
        : const <String, GoalDto>{},
  );
  const selection = WorkspaceSelection(
    hostId: 'server',
    workspaceId: 'workspace',
    worktreeId: 'checkout',
  );
  final store = MemoryAppStore(
    settings: AppSettings(
      sessionTabs: split
          ? <String, SessionTabPreference>{
              selection.storageKey: SessionTabPreference(
                tabs: <WorkspaceTabPreference>[
                  const WorkspaceTabPreference(
                    id: 'draft:left',
                    kind: WorkspaceTabTargetKind.draft,
                  ),
                  const WorkspaceTabPreference(
                    id: 'draft:right',
                    kind: WorkspaceTabTargetKind.draft,
                  ),
                  if (nestedSplit)
                    const WorkspaceTabPreference(
                      id: 'draft:bottom',
                      kind: WorkspaceTabTargetKind.draft,
                    ),
                ],
                root: WorkspaceSplitPreference(
                  id: 'split:root',
                  axis: WorkspaceSplitAxis.horizontal,
                  ratio: 0.5,
                  first: const WorkspacePanePreference(
                    id: 'pane:left',
                    tabIds: <String>['draft:left'],
                    activeTabId: 'draft:left',
                  ),
                  second: nestedSplit
                      ? const WorkspaceSplitPreference(
                          id: 'split:right',
                          axis: WorkspaceSplitAxis.vertical,
                          ratio: 0.5,
                          first: WorkspacePanePreference(
                            id: 'pane:right',
                            tabIds: <String>['draft:right'],
                            activeTabId: 'draft:right',
                          ),
                          second: WorkspacePanePreference(
                            id: 'pane:bottom',
                            tabIds: <String>['draft:bottom'],
                            activeTabId: 'draft:bottom',
                          ),
                        )
                      : const WorkspacePanePreference(
                          id: 'pane:right',
                          tabIds: <String>['draft:right'],
                          activeTabId: 'draft:right',
                        ),
                ),
                focusedPaneId: nestedSplit ? 'pane:bottom' : 'pane:right',
              ),
            }
          : const <String, SessionTabPreference>{},
    ),
  );
  return ProviderScope(
    overrides: [
      appServicesProvider.overrideWithValue(fakeAppServices(api, store: store)),
      attachmentInputProvider.overrideWithValue(null),
    ],
    child: _material(
      mode,
      WorkspacePage(
        selection: selection,
        requestedAgentId: conversation ? rootSession.id : null,
      ),
    ),
  );
}

Widget _directoryNewWorkspace(ThemeMode mode) {
  final now = DateTime.utc(2026);
  final workspace = WorkspaceDto(
    id: 'directory',
    name: 'Plain folder',
    rootPath: '/repos/plain',
    kind: WorkspaceKind.directory,
    createdAt: now,
  );
  final checkout = WorktreeDto(
    id: 'directory-checkout',
    workspaceId: workspace.id,
    name: workspace.name,
    path: workspace.rootPath,
    kind: WorktreeKind.directory,
    isCoderOwned: false,
    createdAt: now,
  );
  return ProviderScope(
    overrides: [
      appServicesProvider.overrideWithValue(
        fakeAppServices(
          FakeCoderApi(
            workspaces: <WorkspaceDto>[workspace],
            worktrees: <WorktreeDto>[checkout],
          ),
        ),
      ),
    ],
    child: _material(mode, const WorkspacePage(compose: true)),
  );
}

Widget _settings(ThemeMode mode) {
  final now = DateTime.utc(2026);
  const longModelId =
      'vendor/reasoning-model-with-an-extremely-long-identifier';
  final api = FakeCoderApi(
    connections: <ProviderConnectionDto>[
      ProviderConnectionDto(
        id: 'openai',
        definitionId: 'openai',
        displayName: 'OpenAI',
        status: ProviderConnectionStatus.connected,
        authKind: ProviderAuthKind.apiKey,
        credentialOrigin: ProviderCredentialOrigin.stored,
        createdAt: now,
        updatedAt: now,
      ),
      ProviderConnectionDto(
        id: 'lab',
        definitionId: 'custom',
        displayName: 'Lab compatible provider',
        status: ProviderConnectionStatus.degraded,
        authKind: ProviderAuthKind.none,
        credentialOrigin: ProviderCredentialOrigin.none,
        error: 'Live model discovery is unavailable.',
        createdAt: now,
        updatedAt: now,
      ),
    ],
    models: const <String, List<ProviderModelDto>>{
      'openai': <ProviderModelDto>[
        ProviderModelDto(
          connectionId: 'openai',
          id: longModelId,
          label: 'Long reasoning model display name for coding workflows',
          source: ProviderModelSource.bundled,
          capabilities: ModelCapabilitiesDto(
            streaming: CapabilitySupport.supported,
            toolCalling: CapabilitySupport.supported,
            controls: <ModelControlDescriptorDto>[
              ModelControlDescriptorDto(
                id: 'reasoning_effort',
                label: 'Reasoning effort',
                kind: ModelControlKind.choice,
                presentation: ModelControlPresentation.menuChip,
              ),
            ],
            source: CapabilitySource.bundled,
          ),
        ),
      ],
      'lab': <ProviderModelDto>[
        ProviderModelDto(
          connectionId: 'lab',
          id: 'available-model',
          label: 'Available model',
          source: ProviderModelSource.discovered,
          capabilities: ModelCapabilitiesDto(),
        ),
      ],
    },
  );
  return ProviderScope(
    overrides: [
      appServicesProvider.overrideWithValue(fakeAppServices(api)),
    ],
    child: _material(
      mode,
      const UnifiedSettingsPage(
        category: SettingsCategory.provider,
        hostId: 'server',
      ),
    ),
  );
}

Widget _projectSettings(ThemeMode mode) {
  final api =
      FakeCoderApi(
          workspaces: <WorkspaceDto>[
            WorkspaceDto(
              id: 'workspace',
              name: 'coder',
              rootPath: '/repos/coder',
              kind: WorkspaceKind.git,
              createdAt: DateTime.utc(2026, 8, 3),
            ),
            WorkspaceDto(
              id: 'design',
              name: 'design',
              rootPath: '/repos/design',
              kind: WorkspaceKind.directory,
              createdAt: DateTime.utc(2026, 8, 3),
            ),
          ],
        )
        ..projectSettings['workspace'] = const ProjectSettingsDto(
          setup: <String>['npm install'],
          teardown: <String>['docker compose down'],
        );
  return ProviderScope(
    overrides: [
      appServicesProvider.overrideWithValue(fakeAppServices(api)),
    ],
    child: _material(
      mode,
      const UnifiedSettingsPage(
        category: SettingsCategory.project,
        hostId: 'server',
      ),
    ),
  );
}

/// Scrolls the agent editor to its tool groups and puts one in a partial state.
///
/// scrollUntilVisible stops as soon as a row is built, which a list does before
/// the row is on screen, so ensureVisible has to finish the job.
Future<void> _revealAgentToolGroups(WidgetTester tester) async {
  await tester.pumpAndSettle();
  // The editor's own list, not the agent collection beside it.
  final scrollable = find
      .descendant(
        of: find.byType(ListView).last,
        matching: find.byType(Scrollable),
      )
      .first;
  Future<void> reveal(Finder finder) async {
    await tester.scrollUntilVisible(finder, 200, scrollable: scrollable);
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
  }

  const mcp = ValueKey<String>('agent-tool-group-mcp');
  await reveal(find.byKey(mcp));
  // Check the whole group, then clear one tool, so the header has a partial
  // state to draw rather than a plain on or off.
  await tester.tap(
    find.descendant(of: find.byKey(mcp), matching: find.byType(TRCheckbox)),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(mcp));
  await tester.pumpAndSettle();
  const member = ValueKey<String>('agent-tool-tile-read_mcp_resource');
  await reveal(find.byKey(member));
  await tester.tap(find.byKey(member));
  await tester.pumpAndSettle();
  await reveal(find.byKey(mcp));
}

Widget _agentSettings(ThemeMode mode) {
  final api = FakeCoderApi();
  return ProviderScope(
    overrides: [
      appServicesProvider.overrideWithValue(fakeAppServices(api)),
    ],
    child: _material(
      mode,
      const UnifiedSettingsPage(
        category: SettingsCategory.agent,
        hostId: 'server',
      ),
    ),
  );
}

Widget _mcpSettings(ThemeMode mode) {
  const stdio = McpServerConfigDto(
    id: 'github',
    transport: McpTransportKind.stdio,
    command: 'npx',
    args: <String>['-y', 'server-github'],
  );
  const remote = McpServerConfigDto(
    id: 'linear',
    transport: McpTransportKind.http,
    url: 'https://mcp.linear.test/mcp',
  );
  const project = McpServerConfigDto(
    id: 'repo',
    transport: McpTransportKind.stdio,
    command: './tools/mcp',
  );
  final api = FakeCoderApi()
    ..mcpServers['github'] = const McpServerStateDto(
      config: stdio,
      status: McpServerStatus.ready,
      scope: McpConfigScope.user,
      sourcePath: '/config/mcp.json',
      serverName: 'github',
      tools: <McpToolSummaryDto>[
        McpToolSummaryDto(
          toolId: 'mcp__github__create_issue',
          name: 'create_issue',
          description: 'Opens an issue.',
        ),
      ],
    )
    ..mcpServers['linear'] = const McpServerStateDto(
      config: remote,
      status: McpServerStatus.failed,
      scope: McpConfigScope.user,
      sourcePath: '/config/mcp.json',
      error: 'the server did not answer within 15s',
    )
    ..mcpServers['repo'] = const McpServerStateDto(
      config: project,
      status: McpServerStatus.ready,
      scope: McpConfigScope.project,
      sourcePath: '/repos/coder/.mcp.json',
      serverName: 'repo',
    );
  return ProviderScope(
    overrides: [
      appServicesProvider.overrideWithValue(fakeAppServices(api)),
    ],
    child: _material(
      mode,
      const UnifiedSettingsPage(
        category: SettingsCategory.mcp,
        hostId: 'server',
      ),
    ),
  );
}

Widget _skillSettings(ThemeMode mode) {
  final api = FakeCoderApi();
  return ProviderScope(
    overrides: [
      appServicesProvider.overrideWithValue(fakeAppServices(api)),
    ],
    child: _material(
      mode,
      const UnifiedSettingsPage(
        category: SettingsCategory.skill,
        hostId: 'server',
      ),
    ),
  );
}

Widget _chat(ThemeMode mode, List<TimelineEventDto> events) => ProviderScope(
  overrides: [
    externalUrlOpenerProvider.overrideWithValue(const _NoopUrlOpener()),
  ],
  child: _material(
    mode,
    ChatTimelineView(items: projectChatTimeline(events), busy: false),
  ),
);

Widget _chatItems(
  ThemeMode mode,
  List<ChatItem> items, {
  required bool busy,
}) => ProviderScope(
  overrides: [
    externalUrlOpenerProvider.overrideWithValue(const _NoopUrlOpener()),
  ],
  child: _material(
    mode,
    TickerMode(
      enabled: false,
      child: ChatTimelineView(items: items, busy: busy),
    ),
  ),
);

Widget _chatItem(ThemeMode mode, ChatItem item) => ProviderScope(
  overrides: [
    externalUrlOpenerProvider.overrideWithValue(const _NoopUrlOpener()),
  ],
  child: _material(
    mode,
    SingleChildScrollView(
      child: ChatItemView(item: item, expanded: true),
    ),
  ),
);

final class _NoopUrlOpener implements ExternalUrlOpener {
  const _NoopUrlOpener();

  @override
  Future<bool> open(Uri uri) async => true;
}

Widget _shell(
  ThemeMode mode, {
  bool collapsed = false,
  DesktopWindowChrome chrome = DesktopWindowChrome.custom,
}) {
  final now = DateTime.utc(2026);
  final workspace = WorkspaceDto(
    id: 'workspace',
    name: 'Coder',
    rootPath: '/repos/coder',
    kind: WorkspaceKind.git,
    createdAt: now,
  );
  final checkout = WorktreeDto(
    id: 'checkout',
    workspaceId: workspace.id,
    name: 'main',
    path: workspace.rootPath,
    branch: 'main',
    kind: WorktreeKind.checkout,
    isCoderOwned: false,
    createdAt: now,
  );
  final api = FakeCoderApi(
    workspaces: <WorkspaceDto>[workspace],
    worktrees: <WorktreeDto>[checkout],
  );
  final store = MemoryAppStore(
    settings: AppSettings(
      embeddedDaemonEnabled: false,
      sidebarCollapsed: collapsed,
    ),
  );
  return ProviderScope(
    overrides: [
      appServicesProvider.overrideWithValue(
        fakeAppServices(api, store: store),
      ),
      attachmentInputProvider.overrideWithValue(null),
    ],
    child: _material(
      mode,
      Column(
        children: <Widget>[
          DesktopMenuBar(
            window: FakeDesktopWindow(chrome: chrome),
            sidebarCollapsed: collapsed,
            onNewWorkspace: () {},
            onOpenSettings: () {},
            onSidebarVisibilityChanged: (_) {},
            onShowAbout: () {},
            onClose: () {},
            onQuit: () {},
          ),
          const Expanded(child: WorkspacePage(compose: true)),
        ],
      ),
    ),
  );
}

Widget _material(ThemeMode mode, Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  locale: testLocale,
  localizationsDelegates: testLocalizationsDelegates,
  supportedLocales: testSupportedLocales,
  theme: testLightTheme,
  darkTheme: testDarkTheme,
  themeMode: mode,
  home: Scaffold(body: child),
);

Widget _localSettings(
  ThemeMode mode, {
  _GoldenEmbeddedLauncher launcher = const _GoldenEmbeddedLauncher(),
}) {
  final store = MemoryAppStore(
    settings: const AppSettings(
      embeddedDaemonExposure: EmbeddedDaemonExposure.allInterfaces,
    ),
  );
  return ProviderScope(
    overrides: [
      appServicesProvider.overrideWithValue(
        AppServices(
          settings: store,
          profiles: store,
          credentials: store,
          clients: const _UnusedClients(),
          clientKind: 'golden',
          embeddedLauncher: launcher,
        ),
      ),
    ],
    child: _material(
      mode,
      const UnifiedSettingsPage(category: SettingsCategory.daemon),
    ),
  );
}

Widget _globalSettings(ThemeMode mode) {
  final now = DateTime.utc(2026, 8, 3);
  final store = MemoryAppStore(
    settings: const AppSettings(embeddedDaemonEnabled: false),
    profiles: <RemoteDaemonProfile>[
      RemoteDaemonProfile(
        id: 'production',
        label: 'Production daemon',
        connections: directHostConnections(
          Uri.parse('wss://coder.example.com/ws'),
        ),
        autoConnect: false,
        createdAt: now,
        updatedAt: now,
      ),
    ],
    tokens: const <String, String>{'production': 'secret'},
  );
  return ProviderScope(
    overrides: [
      appServicesProvider.overrideWithValue(
        AppServices(
          settings: store,
          profiles: store,
          credentials: store,
          clients: const _UnusedClients(),
          clientKind: 'golden',
        ),
      ),
    ],
    child: _material(
      mode,
      const UnifiedSettingsPage(category: SettingsCategory.daemon),
    ),
  );
}

final class _UnusedClients implements HostClientFactory {
  const _UnusedClients();

  @override
  Future<CoderApi> connect({
    required HostConnection connection,
    required HostConnectionCredential credential,
    required String clientId,
    required String clientKind,
  }) => throw StateError('Golden profiles do not auto-connect.');
}

final class _GoldenEmbeddedLauncher implements EmbeddedDaemonLauncher {
  const _GoldenEmbeddedLauncher({
    this.failure = const HostConnectionFailure.network(
      'Golden daemon is offline.',
    ),
  });

  final HostConnectionFailure failure;

  @override
  Future<EmbeddedDaemonSession> start({
    required EmbeddedDaemonExposure exposure,
    required int port,
  }) => Future<EmbeddedDaemonSession>.error(failure);
}
