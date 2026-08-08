import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:coder_app/src/app/composition/app_providers.dart';
import 'package:coder_app/src/app/composition/app_services.dart';
import 'package:coder_app/src/app/platform/external_url_opener.dart';
import 'package:coder_app/src/app/presentation/settings_page.dart';
import 'package:coder_app/src/app/presentation/workspace_page.dart';
import 'package:coder_app/src/features/conversation/application/attachment_ports.dart';
import 'package:coder_app/src/features/conversation/application/chat_timeline_model.dart';
import 'package:coder_app/src/features/conversation/application/composer_controller.dart';
import 'package:coder_app/src/features/conversation/application/conversation_controller.dart';
import 'package:coder_app/src/features/conversation/infrastructure/attachment_io.dart';
import 'package:coder_app/src/features/conversation/presentation/chat_approval_card.dart';
import 'package:coder_app/src/features/conversation/presentation/chat_question_card.dart';
import 'package:coder_app/src/features/conversation/presentation/chat_timeline_view.dart';
import 'package:coder_app/src/features/conversation/presentation/widgets/session_composer.dart';
import 'package:coder_app/src/features/desktop/presentation/desktop_title_bar.dart';
import 'package:coder_app/src/features/hosts/domain/host_models.dart';
import 'package:coder_app/src/features/hosts/domain/host_ports.dart';
import 'package:coder_app/src/features/settings/domain/settings_category.dart';
import 'package:coder_client/coder_client.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:dropwell/dropwell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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

  unawaited(
    goldenTest(
      'workspace shell adapts to sidebar state and width',
      fileName: 'workspace_shell',
      constraints: const BoxConstraints.tightFor(width: 1060, height: 1400),
      builder: () => GoldenTestGroup(
        columns: 1,
        children: <Widget>[
          GoldenTestScenario(
            name: 'desktop light',
            child: SizedBox(
              width: 1000,
              height: 620,
              child: _shell(ThemeMode.light),
            ),
          ),
          GoldenTestScenario(
            name: 'desktop collapsed dark',
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
      'desktop workspace renders a nested pane tree',
      fileName: 'workspace_multi_pane',
      constraints: const BoxConstraints.tightFor(width: 1100, height: 760),
      builder: () => SizedBox(
        width: 1100,
        height: 760,
        child: _sessionComposer(ThemeMode.dark, split: true),
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
      constraints: const BoxConstraints.tightFor(width: 960, height: 1670),
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
            name: 'queued during a turn dark',
            child: SizedBox(
              width: 900,
              height: 260,
              child: _composerState(
                ThemeMode.dark,
                busy: true,
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
  List<QueuedTurn> queued = const <QueuedTurn>[],
  int contextTokens = 0,
  int? contextWindow,
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
        onQueue: (_) {},
        onQueuedEdit: (_) => null,
        onQueuedSendNow: (_) {},
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

Widget _sessionComposer(ThemeMode mode, {bool split = false}) {
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
  final api = FakeCoderApi(
    workspaces: <WorkspaceDto>[workspace],
    worktrees: <WorktreeDto>[checkout],
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
              selection.storageKey: const SessionTabPreference(
                tabs: <WorkspaceTabPreference>[
                  WorkspaceTabPreference(
                    id: 'draft:left',
                    kind: WorkspaceTabTargetKind.draft,
                  ),
                  WorkspaceTabPreference(
                    id: 'draft:right',
                    kind: WorkspaceTabTargetKind.draft,
                  ),
                ],
                root: WorkspaceSplitPreference(
                  id: 'split:root',
                  axis: WorkspaceSplitAxis.horizontal,
                  ratio: 0.5,
                  first: WorkspacePanePreference(
                    id: 'pane:left',
                    tabIds: <String>['draft:left'],
                    activeTabId: 'draft:left',
                  ),
                  second: WorkspacePanePreference(
                    id: 'pane:right',
                    tabIds: <String>['draft:right'],
                    activeTabId: 'draft:right',
                  ),
                ),
                focusedPaneId: 'pane:right',
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
      const WorkspacePage(selection: selection),
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

Widget _shell(ThemeMode mode, {bool collapsed = false}) {
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
          DesktopTitleBar(
            window: FakeDesktopWindow(supportsCustomTitleBar: true),
            sidebarCollapsed: collapsed,
            onNewWorkspace: () {},
            onOpenSettings: () {},
            onToggleSidebar: () {},
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
        websocketUri: Uri.parse('wss://coder.example.com/ws'),
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
    required HostEndpoint endpoint,
    required DaemonCredentials credentials,
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
