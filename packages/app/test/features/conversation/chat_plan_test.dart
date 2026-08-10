import 'dart:convert';

import 'package:app/src/features/conversation/application/chat_timeline_model.dart';
import 'package:app/src/features/conversation/presentation/chat_plan.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/protocol.dart';

void main() {
  final now = DateTime.utc(2026, 8, 3);
  var sequence = 0;

  TimelineEventDto event(String type, Map<String, dynamic> data) =>
      TimelineEventDto(
        sessionId: 'session',
        sequence: sequence += 1,
        turnId: 'turn-1',
        type: type,
        data: data,
        createdAt: now,
      );

  Map<String, dynamic> planArguments(
    List<List<String>> steps, {
    String explanation = '',
  }) => <String, dynamic>{
    'plan': <Map<String, dynamic>>[
      for (final step in steps)
        <String, dynamic>{'step': step[0], 'status': step[1]},
    ],
    'explanation': explanation,
  };

  setUp(() => sequence = 0);

  test(
    'update_plan arguments parse into typed steps',
    () {
      final update = parseUpdatePlanArguments(
        planArguments(<List<String>>[
          <String>['Read the parser', 'completed'],
          <String>['Move the parser', 'in_progress'],
          <String>['Add tests', 'pending'],
        ], explanation: 'Parser first.'),
      );

      expect(update, isNotNull);
      expect(update!.explanation, 'Parser first.');
      expect(update.steps.map((step) => step.step), <String>[
        'Read the parser',
        'Move the parser',
        'Add tests',
      ]);
      expect(update.steps.map((step) => step.status), <ChatPlanStepStatus>[
        ChatPlanStepStatus.completed,
        ChatPlanStepStatus.inProgress,
        ChatPlanStepStatus.pending,
      ]);
    },
    tags: const <String>['feature_test__session_lifecycle__unit'],
  );

  test(
    'a model-authored plan degrades instead of throwing',
    () {
      expect(parseUpdatePlanArguments(const <String, dynamic>{}), isNull);
      expect(
        parseUpdatePlanArguments(<String, dynamic>{
          'plan': <Map<String, dynamic>>[],
        }),
        isNull,
      );

      final update = parseUpdatePlanArguments(<String, dynamic>{
        'plan': <dynamic>[
          <String, dynamic>{'step': 'Kept', 'status': 'not_a_status'},
          <String, dynamic>{'step': 42, 'status': 'pending'},
          'not an object',
        ],
        'explanation': 7,
      });

      expect(update, isNotNull);
      expect(update!.steps.single.step, 'Kept');
      expect(update.steps.single.status, ChatPlanStepStatus.pending);
      expect(update.explanation, isEmpty);
    },
    tags: const <String>['feature_test__session_lifecycle__unit'],
  );

  test(
    'the timeline renders an update_plan call as a plan proposal',
    () {
      final arguments = planArguments(<List<String>>[
        <String>['Move the parser', 'in_progress'],
        <String>['Add tests', 'pending'],
      ], explanation: 'Parser first.');
      final items = projectChatTimeline(<TimelineEventDto>[
        event('user.message', <String, dynamic>{'text': 'Plan the migration'}),
        event('assistant.delta', <String, dynamic>{
          'text': 'Explored the code.',
        }),
        event('tool.requested', <String, dynamic>{
          'callId': 'call-1',
          'name': 'update_plan',
          'arguments': arguments,
        }),
        event('tool.completed', <String, dynamic>{
          'callId': 'call-1',
          'name': 'update_plan',
          'output': jsonEncode(arguments),
        }),
        event('turn.completed', <String, dynamic>{'toolRounds': 1}),
      ]);

      expect(items.map((item) => item.runtimeType.toString()), <String>[
        'ChatUserMessage',
        'ChatAssistantMessage',
        'ChatPlanProposal',
        'ChatNotice',
      ]);
      expect((items[1] as ChatAssistantMessage).markdown, 'Explored the code.');
      final plan = items[2] as ChatPlanProposal;
      expect(plan.explanation, 'Parser first.');
      expect(plan.steps.map((step) => step.step), <String>[
        'Move the parser',
        'Add tests',
      ]);
      expect(plan.key, startsWith('plan-'));
      expect(items.whereType<ChatToolActivity>(), isEmpty);
    },
    tags: const <String>['feature_test__session_lifecycle__unit'],
  );

  test(
    'a rejected update_plan call stays visible as a failed tool activity',
    () {
      final items = projectChatTimeline(<TimelineEventDto>[
        event('tool.requested', <String, dynamic>{
          'callId': 'call-1',
          'name': 'update_plan',
          'arguments': planArguments(<List<String>>[
            <String>['Only step', 'pending'],
          ]),
        }),
        event('tool.completed', <String, dynamic>{
          'callId': 'call-1',
          'name': 'update_plan',
          'output': '{"error":"Duplicate step"}',
          'isError': true,
        }),
      ]);

      expect(items.whereType<ChatPlanProposal>(), isEmpty);
      final activity = items.single as ChatToolActivity;
      expect(activity.toolName, 'update_plan');
      expect(activity.isError, isTrue);
    },
    tags: const <String>['feature_test__session_lifecycle__unit'],
  );

  test(
    'an answered question reads as a conversation, not a tool row',
    () {
      const arguments = <String, dynamic>{
        'questions': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'store',
            'header': 'Storage',
            'question': 'Which store should the cache use?',
            'options': <Map<String, dynamic>>[
              <String, dynamic>{'label': 'SQLite', 'description': 'Durable.'},
              <String, dynamic>{'label': 'Memory', 'description': 'Fast.'},
            ],
          },
          <String, dynamic>{
            'id': 'ttl',
            'header': 'TTL',
            'question': 'How long should entries live?',
            'options': <Map<String, dynamic>>[
              <String, dynamic>{'label': 'An hour', 'description': 'Short.'},
              <String, dynamic>{'label': 'A day', 'description': 'Long.'},
            ],
          },
        ],
      };
      final items = projectChatTimeline(<TimelineEventDto>[
        event('tool.requested', <String, dynamic>{
          'callId': 'call-ask',
          'name': 'request_user_input',
          'arguments': arguments,
        }),
        event('tool.completed', <String, dynamic>{
          'callId': 'call-ask',
          'name': 'request_user_input',
          'output':
              '[{"questionId":"store","answer":"SQLite","isFreeForm":false},'
              '{"questionId":"ttl","answer":"Evicted","isFreeForm":true}]',
        }),
      ]);

      final answer = items.single as ChatUserAnswer;
      expect(answer.entries.map((entry) => entry.header), <String>[
        'Storage',
        'TTL',
      ]);
      expect(
        answer.entries.first.question,
        'Which store should the cache use?',
      );
      expect(answer.entries.first.answer, 'SQLite');
      expect(answer.entries.first.isFreeForm, isFalse);
      // A typed answer is marked so the transcript shows it was not offered.
      expect(answer.entries.last.answer, 'Evicted');
      expect(answer.entries.last.isFreeForm, isTrue);
      expect(items.whereType<ChatToolActivity>(), isEmpty);
    },
    tags: const <String>['feature_test__turn_question__widget'],
  );

  test(
    'a pending question shows nothing until it is answered',
    () {
      final items = projectChatTimeline(<TimelineEventDto>[
        event('tool.requested', <String, dynamic>{
          'callId': 'call-ask',
          'name': 'request_user_input',
          'arguments': <String, dynamic>{
            'questions': <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 'store',
                'header': 'Storage',
                'question': 'Which store?',
                'options': <Map<String, dynamic>>[],
              },
            ],
          },
        }),
      ]);

      // The question card renders from conversation state while it is
      // pending, so a spinning tool row beside it would only duplicate it.
      expect(items, isEmpty);
    },
    tags: const <String>['feature_test__turn_question__widget'],
  );

  test(
    'a rejected question stays visible as a failed tool activity',
    () {
      final items = projectChatTimeline(<TimelineEventDto>[
        event('tool.requested', <String, dynamic>{
          'callId': 'call-ask',
          'name': 'request_user_input',
          'arguments': <String, dynamic>{'questions': <Map<String, dynamic>>[]},
        }),
        event('tool.completed', <String, dynamic>{
          'callId': 'call-ask',
          'name': 'request_user_input',
          'output': '{"error":"Ask between 1 and 3 questions."}',
          'isError': true,
        }),
      ]);

      expect(items.whereType<ChatUserAnswer>(), isEmpty);
      expect((items.single as ChatToolActivity).isError, isTrue);
    },
    tags: const <String>['feature_test__turn_question__widget'],
  );

  test(
    'only the newest plan of a turn survives repeated update_plan calls',
    () {
      final items = projectChatTimeline(<TimelineEventDto>[
        event('tool.requested', <String, dynamic>{
          'callId': 'call-1',
          'name': 'update_plan',
          'arguments': planArguments(<List<String>>[
            <String>['Step one', 'in_progress'],
            <String>['Step two', 'pending'],
          ]),
        }),
        event('tool.completed', <String, dynamic>{
          'callId': 'call-1',
          'name': 'update_plan',
          'output': '{}',
        }),
        event('tool.requested', <String, dynamic>{
          'callId': 'call-2',
          'name': 'update_plan',
          'arguments': planArguments(<List<String>>[
            <String>['Step one', 'completed'],
            <String>['Step two', 'in_progress'],
          ]),
        }),
        event('tool.completed', <String, dynamic>{
          'callId': 'call-2',
          'name': 'update_plan',
          'output': '{}',
        }),
      ]);

      final plan = items.whereType<ChatPlanProposal>().single;
      expect(plan.steps.map((step) => step.status), <ChatPlanStepStatus>[
        ChatPlanStepStatus.completed,
        ChatPlanStepStatus.inProgress,
      ]);
    },
    tags: const <String>['feature_test__session_lifecycle__unit'],
  );
}
