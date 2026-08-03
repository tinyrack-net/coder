import 'package:coder_app/src/chat/chat_plan.dart';
import 'package:coder_app/src/chat/chat_timeline_model.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:flutter_test/flutter_test.dart';

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

  setUp(() => sequence = 0);

  test(
    'proposed plan blocks are carved out of assistant prose',
    () {
      final none = extractProposedPlan('Just prose.');
      expect(none.plan, isNull);
      expect(none.markdown, 'Just prose.');
      expect(none.isComplete, isFalse);

      final complete = extractProposedPlan(
        'Here is what I found.\n'
        '$proposedPlanOpenTag\n'
        '1. Read the parser\n'
        '2. Fix the bug\n'
        '$proposedPlanCloseTag\n'
        'Ask me anything.',
      );
      expect(complete.plan, '1. Read the parser\n2. Fix the bug');
      expect(complete.markdown, 'Here is what I found.\nAsk me anything.');
      expect(complete.isComplete, isTrue);

      final streaming = extractProposedPlan(
        'Working.\n$proposedPlanOpenTag\n1. Read the',
      );
      expect(streaming.plan, '1. Read the');
      expect(streaming.markdown, 'Working.');
      expect(streaming.isComplete, isFalse);

      final planOnly = extractProposedPlan(
        '$proposedPlanOpenTag\nonly a plan\n$proposedPlanCloseTag',
      );
      expect(planOnly.markdown, isEmpty);
      expect(planOnly.plan, 'only a plan');
    },
    tags: const <String>['feature_test__session_lifecycle__unit'],
  );

  test(
    'the timeline renders a plan proposal instead of raw tags',
    () {
      final items = projectChatTimeline(<TimelineEventDto>[
        event('user.message', <String, dynamic>{'text': 'Plan the migration'}),
        event('assistant.delta', <String, dynamic>{
          'text': 'Explored the code.\n$proposedPlanOpenTag\n',
        }),
        event('assistant.delta', <String, dynamic>{
          'text': '1. Move the parser\n$proposedPlanCloseTag\n',
        }),
        event('turn.completed', <String, dynamic>{'toolRounds': 0}),
      ]);

      expect(items.map((item) => item.runtimeType.toString()), <String>[
        'ChatUserMessage',
        'ChatAssistantMessage',
        'ChatPlanProposal',
        'ChatNotice',
      ]);
      final assistant = items[1] as ChatAssistantMessage;
      expect(assistant.markdown, 'Explored the code.');
      expect(assistant.markdown, isNot(contains('proposed_plan')));
      final plan = items[2] as ChatPlanProposal;
      expect(plan.markdown, '1. Move the parser');
      expect(plan.isComplete, isTrue);
      expect(plan.key, startsWith('plan-'));
    },
    tags: const <String>['feature_test__session_lifecycle__unit'],
  );

  test(
    'a plan-only streaming turn drops the empty assistant bubble',
    () {
      final items = projectChatTimeline(<TimelineEventDto>[
        event('assistant.delta', <String, dynamic>{
          'text': '$proposedPlanOpenTag\n1. Start',
        }),
      ]);

      final plan = items.single as ChatPlanProposal;
      expect(plan.markdown, '1. Start');
      expect(plan.isComplete, isFalse);
    },
    tags: const <String>['feature_test__session_lifecycle__unit'],
  );
}
