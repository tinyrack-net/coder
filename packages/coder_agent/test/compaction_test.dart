import 'package:coder_agent/coder_agent.dart';
import 'package:test/test.dart';

void main() {
  group('shouldCompact', () {
    test(
      'never fires without a known context window',
      tags: const <String>['feature_test__context_compaction__unit'],
      () {
        final compactor = ConversationCompactor(_ScriptedProvider());
        expect(
          compactor.shouldCompact(
            usage: const ModelUsage(totalTokens: 999999),
            contextWindowTokens: null,
          ),
          isFalse,
        );
      },
    );

    test(
      'fires only once the window is spent past the ratio',
      tags: const <String>['feature_test__context_compaction__unit'],
      () {
        final compactor = ConversationCompactor(_ScriptedProvider());
        // 0.9 of 1000 is 900, so 899 is still inside the budget.
        expect(
          compactor.shouldCompact(
            usage: const ModelUsage(totalTokens: 899),
            contextWindowTokens: 1000,
          ),
          isFalse,
        );
        expect(
          compactor.shouldCompact(
            usage: const ModelUsage(totalTokens: 900),
            contextWindowTokens: 1000,
          ),
          isTrue,
        );
      },
    );

    test(
      'an empty usage report leaves the window alone',
      tags: const <String>['feature_test__context_compaction__unit'],
      () {
        final compactor = ConversationCompactor(_ScriptedProvider());
        expect(
          compactor.shouldCompact(
            usage: const ModelUsage(),
            contextWindowTokens: 1000,
          ),
          isFalse,
        );
      },
    );
  });

  group('compact', () {
    test(
      'asks for a summary without offering any tool',
      tags: const <String>['feature_test__context_compaction__unit'],
      () async {
        final provider = _ScriptedProvider(<_Reply>[_Reply.text('summary')]);
        final compactor = ConversationCompactor(provider);
        await compactor.compact(
          history: <ConversationItem>[const UserConversationItem('build it')],
          target: _target(),
          cancellation: CancellationToken(),
        );

        final request = provider.requests.single;
        expect(request.tools, isEmpty);
        expect(request.model, 'gpt-test');
        expect(
          (request.history.last as UserConversationItem).text,
          CompactionPolicy.summarizationPrompt,
        );
        expect(
          (request.history.first as UserConversationItem).text,
          'build it',
        );
      },
    );

    test(
      'keeps every user message and appends the prefixed summary',
      tags: const <String>['feature_test__context_compaction__unit'],
      () async {
        final provider = _ScriptedProvider(<_Reply>[_Reply.text('handoff')]);
        final compacted = await ConversationCompactor(provider).compact(
          history: <ConversationItem>[
            const UserConversationItem('first ask'),
            const AssistantConversationItem(
              text: 'thinking',
              toolCalls: <ConversationToolCall>[
                ConversationToolCall(
                  callId: 'call-1',
                  name: 'echo',
                  arguments: <String, dynamic>{},
                ),
              ],
            ),
            const ToolResultConversationItem(callId: 'call-1', output: '{}'),
            const UserConversationItem('second ask'),
          ],
          target: _target(),
          cancellation: CancellationToken(),
        );

        expect(
          compacted.map((item) => (item as UserConversationItem).text),
          <String>[
            'first ask',
            'second ask',
            '${CompactionPolicy.summaryPrefix}\nhandoff',
          ],
        );
        // Nothing that could orphan a `function_call_output` survives.
        expect(compacted.whereType<AssistantConversationItem>(), isEmpty);
        expect(compacted.whereType<ToolResultConversationItem>(), isEmpty);
      },
    );

    test(
      'does not carry an earlier summary into the next one',
      tags: const <String>['feature_test__context_compaction__unit'],
      () async {
        final provider = _ScriptedProvider(<_Reply>[_Reply.text('second')]);
        final compacted = await ConversationCompactor(provider).compact(
          history: <ConversationItem>[
            const UserConversationItem(
              '${CompactionPolicy.summaryPrefix}\nfirst',
            ),
            const UserConversationItem('keep me'),
          ],
          target: _target(),
          cancellation: CancellationToken(),
        );

        expect(
          compacted.map((item) => (item as UserConversationItem).text),
          <String>['keep me', '${CompactionPolicy.summaryPrefix}\nsecond'],
        );
      },
    );

    test(
      'drops the oldest user messages once the retention budget is spent',
      tags: const <String>['feature_test__context_compaction__unit'],
      () async {
        // Two messages that each fill the whole budget: only the newest can
        // survive whole, and the older one has to go entirely.
        final wide = 'x' * (CompactionPolicy.retainedUserMessageTokens * 4);
        final provider = _ScriptedProvider(<_Reply>[_Reply.text('done')]);
        final compacted = await ConversationCompactor(provider).compact(
          history: <ConversationItem>[
            UserConversationItem('$wide oldest'),
            UserConversationItem('$wide newest'),
          ],
          target: _target(),
          cancellation: CancellationToken(),
        );

        final texts = compacted
            .map((item) => (item as UserConversationItem).text)
            .toList();
        expect(texts, hasLength(2));
        expect(texts.first, endsWith('newest'));
        expect(texts.first, isNot(contains('oldest')));
        expect(texts.last, endsWith('done'));
      },
    );

    test(
      'truncates the message that crosses the retention budget',
      tags: const <String>['feature_test__context_compaction__unit'],
      () async {
        final wide = 'y' * (CompactionPolicy.retainedUserMessageTokens * 4);
        final provider = _ScriptedProvider(<_Reply>[_Reply.text('done')]);
        final compacted = await ConversationCompactor(provider).compact(
          history: <ConversationItem>[
            UserConversationItem('oldest $wide'),
            const UserConversationItem('newest'),
          ],
          target: _target(),
          cancellation: CancellationToken(),
        );

        final texts = compacted
            .map((item) => (item as UserConversationItem).text)
            .toList();
        expect(texts, hasLength(3));
        expect(texts.first, startsWith('[…'));
        expect(texts[1], 'newest');
      },
    );

    test(
      'retries a summary that itself overflows by dropping the oldest item',
      tags: const <String>['feature_test__context_compaction__unit'],
      () async {
        final provider = _ScriptedProvider(<_Reply>[
          _Reply.overflow(),
          _Reply.text('shorter summary'),
        ]);
        final compacted = await ConversationCompactor(provider).compact(
          history: <ConversationItem>[
            const UserConversationItem('oldest'),
            const UserConversationItem('newest'),
          ],
          target: _target(),
          cancellation: CancellationToken(),
        );

        expect(provider.requests, hasLength(2));
        // The retry re-sends one fewer item, trimmed from the front so the
        // cached prefix of the remaining history stays intact.
        expect(provider.requests[0].history, hasLength(3));
        expect(provider.requests[1].history, hasLength(2));
        expect(
          (provider.requests[1].history.first as UserConversationItem).text,
          'newest',
        );
        expect(
          (compacted.last as UserConversationItem).text,
          endsWith('shorter summary'),
        );
      },
    );

    test(
      'gives up when a single item still overflows',
      tags: const <String>['feature_test__context_compaction__unit'],
      () async {
        final provider = _ScriptedProvider(<_Reply>[
          _Reply.overflow(),
          _Reply.overflow(),
        ]);
        await expectLater(
          ConversationCompactor(provider).compact(
            history: <ConversationItem>[const UserConversationItem('only')],
            target: _target(),
            cancellation: CancellationToken(),
          ),
          throwsA(isA<ModelContextOverflowException>()),
        );
      },
    );

    test(
      'attachments are left behind with the window they filled',
      tags: const <String>['feature_test__context_compaction__unit'],
      () async {
        // Their real cost is image and file bytes the retention budget cannot
        // measure, so carrying them over would free nothing.
        final provider = _ScriptedProvider(<_Reply>[_Reply.text('done')]);
        final compacted = await ConversationCompactor(provider).compact(
          history: <ConversationItem>[
            const UserConversationItem(
              'look at this',
              attachments: <ConversationAttachment>[
                ConversationAttachment(
                  id: 'shot',
                  fileName: 'shot.png',
                  mimeType: 'image/png',
                  byteSize: 3,
                  path: '/attachments/shot.blob',
                ),
              ],
            ),
          ],
          target: _target(),
          cancellation: CancellationToken(),
        );

        final first = compacted.first as UserConversationItem;
        expect(first.text, 'look at this');
        expect(first.attachments, isEmpty);
      },
    );

    test(
      'a model that returns nothing still yields a usable summary item',
      tags: const <String>['feature_test__context_compaction__unit'],
      () async {
        final provider = _ScriptedProvider(<_Reply>[_Reply.text('   ')]);
        final compacted = await ConversationCompactor(provider).compact(
          history: <ConversationItem>[const UserConversationItem('ask')],
          target: _target(),
          cancellation: CancellationToken(),
        );

        expect(
          (compacted.last as UserConversationItem).text,
          '${CompactionPolicy.summaryPrefix}\n'
          '${CompactionPolicy.missingSummaryPlaceholder}',
        );
      },
    );
  });
}

CompactionTarget _target() => const CompactionTarget(
  model: 'gpt-test',
  modelControls: <String, AgentModelControlValue>{
    AgentModelControlIds.reasoningEffort: AgentModelControlStringValue(
      value: 'medium',
    ),
  },
  safetyIdentifier: 'tester',
);

final class _Reply {
  _Reply.text(this.text) : overflows = false;
  _Reply.overflow() : text = '', overflows = true;

  final String text;
  final bool overflows;
}

final class _ScriptedProvider implements ModelProvider {
  _ScriptedProvider([this.replies = const <_Reply>[]]);

  final List<_Reply> replies;
  final List<ModelRequest> requests = <ModelRequest>[];
  int _index = 0;

  @override
  String get id => 'scripted';

  @override
  Stream<ModelEvent> stream(
    ModelRequest request,
    CancellationToken cancellation,
  ) async* {
    requests.add(request);
    final reply = replies[_index++];
    if (reply.overflows) {
      throw const ModelContextOverflowException('too long');
    }
    yield ModelTextDelta(reply.text);
    yield ModelResponseCompleted(
      assistant: AssistantConversationItem(text: reply.text),
    );
  }
}
