import 'package:coder_app/src/app/platform/external_url_opener.dart';
import 'package:coder_app/src/features/conversation/application/chat_timeline_model.dart';
import 'package:coder_app/src/features/conversation/presentation/chat_diff_view.dart';
import 'package:coder_app/src/features/conversation/presentation/chat_markdown.dart';
import 'package:coder_app/src/features/conversation/presentation/chat_timeline_view.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

import '../../support/localization.dart';

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

  Future<void> pump(
    WidgetTester tester,
    List<TimelineEventDto> events, {
    bool busy = false,
    _RecordingUrlOpener? opener,
  }) => tester.pumpWidget(
    ProviderScope(
      overrides: [
        externalUrlOpenerProvider.overrideWithValue(
          opener ?? _RecordingUrlOpener(),
        ),
      ],
      child: MaterialApp(
        theme: testLightTheme,
        darkTheme: testDarkTheme,
        locale: testLocale,
        localizationsDelegates: testLocalizationsDelegates,
        supportedLocales: testSupportedLocales,
        home: Scaffold(
          body: ChatTimelineView(
            items: projectChatTimeline(events),
            busy: busy,
          ),
        ),
      ),
    ),
  );

  testWidgets(
    'tool calls collapse to a CLI line instead of raw JSON',
    (tester) async {
      await pump(tester, <TimelineEventDto>[
        event('tool.requested', <String, dynamic>{
          'callId': 'call-1',
          'name': 'read_file',
          'arguments': <String, dynamic>{'path': 'lib/main.dart'},
        }),
        event('tool.completed', <String, dynamic>{
          'callId': 'call-1',
          'name': 'read_file',
          'output': 'a\nb\nc',
          'isError': false,
        }),
        event('turn.completed', <String, dynamic>{'toolRounds': 1}),
      ]);
      await tester.pumpAndSettle();

      expect(find.text('Read(lib/main.dart)'), findsOneWidget);
      expect(find.text('3줄 읽음'), findsOneWidget);
      expect(find.textContaining('{'), findsNothing);
      expect(find.textContaining('isError'), findsNothing);
    },
    tags: const <String>['feature_test__turn_execution__widget'],
  );

  testWidgets(
    'expanding a command shows its output without the JSON wrapper',
    (tester) async {
      final clipboard = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method == 'Clipboard.setData') {
              clipboard.add(
                (call.arguments as Map<Object?, Object?>)['text']! as String,
              );
            }
            return null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null),
      );

      await pump(tester, <TimelineEventDto>[
        event('tool.requested', <String, dynamic>{
          'callId': 'call-1',
          'name': 'exec_command',
          'arguments': <String, dynamic>{'command': 'flutter test'},
        }),
        event('tool.completed', <String, dynamic>{
          'callId': 'call-1',
          'name': 'exec_command',
          'output': r'{"exitCode":0,"output":"All tests passed!\ndone"}',
          'isError': false,
        }),
        event('turn.completed', <String, dynamic>{'toolRounds': 1}),
      ]);
      await tester.pumpAndSettle();

      expect(find.text('Bash(flutter test)'), findsOneWidget);
      expect(find.text('종료 코드 0 · 2줄'), findsOneWidget);
      expect(find.textContaining('exitCode'), findsNothing);

      await tester.tap(find.text('Bash(flutter test)'));
      await tester.pumpAndSettle();
      expect(find.textContaining('All tests passed!'), findsOneWidget);
      expect(find.text(r'$ flutter test'), findsOneWidget);
      expect(find.textContaining('exitCode'), findsNothing);

      await tester.tap(findAccessibleAction('복사').last);
      await tester.pumpAndSettle();
      expect(clipboard, <String>['All tests passed!\ndone']);

      await tester.tap(find.text('Bash(flutter test)'));
      await tester.pumpAndSettle();
      expect(find.textContaining('All tests passed!'), findsNothing);
    },
    tags: const <String>['feature_test__turn_execution__widget'],
  );

  testWidgets(
    'patches expand into a colored diff',
    (tester) async {
      await pump(tester, <TimelineEventDto>[
        event('tool.requested', <String, dynamic>{
          'callId': 'call-1',
          'name': 'apply_patch',
          'arguments': <String, dynamic>{
            'patch':
                '--- a/lib/main.dart\n'
                '+++ b/lib/main.dart\n'
                '@@ -1,1 +1,2 @@\n'
                '-old line\n'
                '+new line\n'
                '+extra line\n',
          },
        }),
        event('tool.completed', <String, dynamic>{
          'callId': 'call-1',
          'name': 'apply_patch',
          'output': '{"changedFiles":1}',
          'isError': false,
        }),
        event('turn.completed', <String, dynamic>{'toolRounds': 1}),
      ]);
      await tester.pumpAndSettle();

      expect(find.text('Edit(lib/main.dart)'), findsOneWidget);
      expect(find.text('+2 -1 · 1개 파일'), findsOneWidget);

      await tester.tap(find.text('Edit(lib/main.dart)'));
      await tester.pumpAndSettle();
      expect(find.byType(ChatDiffView), findsOneWidget);
      expect(find.text('+new line'), findsOneWidget);
      expect(find.text('+extra line'), findsOneWidget);
      expect(find.text('-old line'), findsOneWidget);
      expect(find.textContaining('changedFiles'), findsNothing);
    },
    tags: const <String>['feature_test__turn_execution__widget'],
  );

  testWidgets(
    'running turns show progress and the empty state explains itself',
    (tester) async {
      await pump(
        tester,
        <TimelineEventDto>[
          event('user.message', <String, dynamic>{'text': 'Run it'}),
          event('tool.requested', <String, dynamic>{
            'callId': 'call-1',
            'name': 'exec_command',
            'arguments': <String, dynamic>{'command': 'sleep 5'},
          }),
        ],
        busy: true,
      );
      await tester.pump();

      expect(find.text('실행 중'), findsWidgets);
      expect(find.byType(TRSpinner), findsWidgets);
      expect(find.text('>'), findsOneWidget);

      await pump(tester, const <TimelineEventDto>[]);
      await tester.pumpAndSettle();
      expect(find.text('코딩 요청을 입력하세요.'), findsOneWidget);
    },
    tags: const <String>['feature_test__turn_execution__widget'],
  );

  testWidgets(
    'assistant links open only browser-safe schemes',
    (tester) async {
      final opener = _RecordingUrlOpener();
      await pump(
        tester,
        <TimelineEventDto>[
          event('assistant.delta', <String, dynamic>{
            'text':
                'See [docs](https://example.com) and '
                '[bad](javascript:alert(1)).',
          }),
          event('turn.completed', <String, dynamic>{'toolRounds': 0}),
        ],
        opener: opener,
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('docs', findRichText: true), findsWidgets);
      await openChatLink(opener, 'https://example.com');
      await openChatLink(opener, 'mailto:dev@example.com');
      await openChatLink(opener, 'javascript:alert(1)');
      await openChatLink(opener, 'file:///etc/passwd');
      await openChatLink(opener, '');
      await openChatLink(opener, null);
      expect(opener.opened, <Uri>[
        Uri.parse('https://example.com'),
        Uri.parse('mailto:dev@example.com'),
      ]);
    },
    tags: const <String>['feature_test__turn_execution__widget'],
  );

  testWidgets(
    'expanded cards keep their state when a new event arrives',
    (tester) async {
      final first = <TimelineEventDto>[
        event('tool.requested', <String, dynamic>{
          'callId': 'call-1',
          'name': 'read_file',
          'arguments': <String, dynamic>{'path': 'a.dart'},
        }),
        event('tool.completed', <String, dynamic>{
          'callId': 'call-1',
          'name': 'read_file',
          'output': 'first file body',
          'isError': false,
        }),
      ];
      await pump(tester, first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Read(a.dart)'));
      await tester.pumpAndSettle();
      expect(find.textContaining('first file body'), findsOneWidget);

      await pump(tester, <TimelineEventDto>[
        ...first,
        event('tool.requested', <String, dynamic>{
          'callId': 'call-2',
          'name': 'read_file',
          'arguments': <String, dynamic>{'path': 'b.dart'},
        }),
        event('tool.completed', <String, dynamic>{
          'callId': 'call-2',
          'name': 'read_file',
          'output': 'second file body',
          'isError': false,
        }),
      ]);
      await tester.pumpAndSettle();

      expect(find.text('Read(a.dart)'), findsOneWidget);
      expect(find.text('Read(b.dart)'), findsOneWidget);
      expect(find.textContaining('first file body'), findsOneWidget);
      expect(find.textContaining('second file body'), findsNothing);
    },
    tags: const <String>['feature_test__turn_execution__widget'],
  );

  testWidgets(
    'an answered question renders as prose, marking typed answers',
    (tester) async {
      await pump(tester, <TimelineEventDto>[
        event('tool.requested', <String, dynamic>{
          'callId': 'call-ask',
          'name': 'ask_user',
          'arguments': <String, dynamic>{
            'questions': <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 'store',
                'header': 'Storage',
                'question': 'Which store should the cache use?',
                'options': <Map<String, dynamic>>[],
              },
              <String, dynamic>{
                'id': 'ttl',
                'header': 'TTL',
                'question': 'How long should entries live?',
                'options': <Map<String, dynamic>>[],
              },
            ],
          },
        }),
        event('tool.completed', <String, dynamic>{
          'callId': 'call-ask',
          'name': 'ask_user',
          'output':
              '[{"questionId":"store","answer":"SQLite","isFreeForm":false},'
              '{"questionId":"ttl","answer":"A week","isFreeForm":true}]',
        }),
      ]);
      await tester.pumpAndSettle();

      expect(find.text('Which store should the cache use?'), findsOneWidget);
      expect(find.text('SQLite'), findsOneWidget);
      // A typed answer is marked so it is not mistaken for an offered option.
      expect(find.text('A week (직접 입력)'), findsOneWidget);
      // No JSON tool row duplicates it.
      expect(find.textContaining('questionId'), findsNothing);
    },
    tags: const <String>['feature_test__turn_question__widget'],
  );

  testWidgets(
    'a running sleep counts down and settles when it ends',
    (tester) async {
      // A sleep is projected from its request, which carries createdAt, so
      // the countdown is recomputed rather than counted — correct on replay.
      final started = event('tool.requested', <String, dynamic>{
        'callId': 'call-sleep',
        'name': 'sleep',
        'arguments': <String, dynamic>{
          'duration_ms': 4000,
          'reason': 'waiting for CI',
        },
      });
      await pump(tester, <TimelineEventDto>[started]);
      await tester.pump();

      expect(find.byKey(const ValueKey<String>('chat-sleep-card')), findsOne);
      expect(find.text('waiting for CI'), findsOneWidget);
      // No generic tool row duplicates the card.
      expect(find.text('sleep'), findsNothing);

      // The card animates, so the tree never settles while it runs.
      await tester.pump(const Duration(seconds: 1));
      expect(
        tester
            .widget<TRText>(
              find.byKey(const ValueKey<String>('chat-sleep-status')),
            )
            .data,
        contains('초'),
      );

      await pump(tester, <TimelineEventDto>[
        started,
        event('tool.completed', <String, dynamic>{
          'callId': 'call-sleep',
          'name': 'sleep',
          'output': '{"sleptMs":4000,"outcome":"elapsed"}',
        }),
      ]);
      // Finished, so the ticker stops and the tree can settle.
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TRText>(
              find.byKey(const ValueKey<String>('chat-sleep-status')),
            )
            .data,
        '4초 대기함',
      );
    },
    tags: const <String>['feature_test__tool_clock__widget'],
  );

  testWidgets(
    'a sleep without a usable duration stays an ordinary tool row',
    (tester) async {
      await pump(tester, <TimelineEventDto>[
        event('tool.requested', <String, dynamic>{
          'callId': 'call-sleep',
          'name': 'sleep',
          'arguments': <String, dynamic>{'duration_ms': 'soon'},
        }),
      ]);
      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('chat-sleep-card')),
        findsNothing,
      );
      // It falls back to the ordinary tool row so the mistake stays visible.
      expect(find.text('Sleep()'), findsOneWidget);
    },
    tags: const <String>['feature_test__tool_clock__widget'],
  );

  testWidgets(
    'a context reset draws a divider instead of a tool row',
    (tester) async {
      await pump(tester, <TimelineEventDto>[
        event('tool.requested', <String, dynamic>{
          'callId': 'call-reset',
          'name': 'new_context',
          'arguments': <String, dynamic>{},
        }),
        event('tool.completed', <String, dynamic>{
          'callId': 'call-reset',
          'name': 'new_context',
          'output': '{"started":true}',
        }),
        event('context.reset', <String, dynamic>{'retained': 2}),
      ]);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('chat-context-reset')),
        findsOne,
      );
      // The divider already says it, so no tool row repeats it.
      expect(find.text('NewContext()'), findsNothing);
    },
    tags: const <String>['feature_test__tool_context_budget__widget'],
  );

  testWidgets(
    'a compaction draws its own divider',
    (tester) async {
      // It reads differently from a reset: the work above was carried forward
      // as a summary rather than dropped.
      await pump(tester, <TimelineEventDto>[
        event('context.compacted', <String, dynamic>{
          'retained': 3,
          'trigger': 'auto',
        }),
      ]);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('chat-context-compacted')),
        findsOne,
      );
      expect(
        find.byKey(const ValueKey<String>('chat-context-reset')),
        findsNothing,
      );
    },
    tags: const <String>['feature_test__context_compaction__widget'],
  );

  testWidgets(
    'a rejected context reset stays visible as a tool row',
    (tester) async {
      await pump(tester, <TimelineEventDto>[
        event('tool.requested', <String, dynamic>{
          'callId': 'call-reset',
          'name': 'new_context',
          'arguments': <String, dynamic>{},
        }),
        event('tool.denied', <String, dynamic>{
          'callId': 'call-reset',
          'name': 'new_context',
          'error': 'Denied.',
        }),
      ]);
      await tester.pumpAndSettle();

      expect(find.text('NewContext()'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('chat-context-reset')),
        findsNothing,
      );
    },
    tags: const <String>['feature_test__tool_context_budget__widget'],
  );

  testWidgets(
    'withheld tools are announced so the user knows they exist',
    (tester) async {
      await pump(tester, <TimelineEventDto>[
        event('tools.deferred', <String, dynamic>{
          'count': 12,
          'surfaced': 0,
        }),
      ]);
      await tester.pumpAndSettle();

      final line = tester.widget<TRText>(
        find.byKey(const ValueKey<String>('chat-deferred-tools')),
      );
      expect(line.data, contains('12'));
    },
    tags: const <String>['feature_test__tool_search_deferred__widget'],
  );

  testWidgets(
    'nothing withheld shows no notice',
    (tester) async {
      await pump(tester, <TimelineEventDto>[
        event('tools.deferred', <String, dynamic>{'count': 0}),
      ]);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('chat-deferred-tools')),
        findsNothing,
      );
    },
    tags: const <String>['feature_test__tool_search_deferred__widget'],
  );

  testWidgets(
    'token usage reads as labelled counters, not raw provider keys',
    (tester) async {
      await pump(tester, <TimelineEventDto>[
        event('model.usage', <String, dynamic>{
          'inputTokens': 1200,
          'cachedInputTokens': 800,
          'outputTokens': 340,
          'reasoningTokens': 120,
          'totalTokens': 1540,
        }),
      ]);
      await tester.pumpAndSettle();

      final line = tester.widget<TRText>(
        find.byKey(const ValueKey<String>('chat-usage-line')),
      );
      // Cached and reasoning are subsets, so they read as qualifiers.
      expect(line.data, contains('1200'));
      expect(line.data, contains('800'));
      expect(line.data, contains('340'));
      expect(line.data, contains('120'));
      expect(line.data, contains('1540'));
      expect(line.data, isNot(contains('inputTokens')));
    },
    tags: const <String>['feature_test__tool_context_budget__widget'],
  );

  testWidgets(
    'a usage event with nothing to report renders nothing',
    (tester) async {
      await pump(tester, <TimelineEventDto>[
        event('model.usage', const <String, dynamic>{}),
      ]);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('chat-usage-line')),
        findsNothing,
      );
    },
    tags: const <String>['feature_test__tool_context_budget__widget'],
  );
}

final class _RecordingUrlOpener implements ExternalUrlOpener {
  final List<Uri> opened = <Uri>[];

  @override
  Future<bool> open(Uri uri) async {
    opened.add(uri);
    return true;
  }
}
