import 'dart:async';
import 'dart:typed_data';

import 'package:app/src/app/composition/app_providers.dart';
import 'package:app/src/app/platform/external_url_opener.dart';
import 'package:app/src/features/conversation/application/attachment_ports.dart';
import 'package:app/src/features/conversation/application/chat_timeline_model.dart';
import 'package:app/src/features/conversation/presentation/chat_timeline_view.dart';
import 'package:app/src/features/conversation/presentation/widgets/session_composer.dart';
import 'package:app/src/shared/presentation/tinest_ui_density.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

import '../../support/fake_tinest_api.dart';
import '../../support/localization.dart';

const _geometryTolerance = 0.01;
const _hostId = 'host-scroll-contract';
final _createdAt = DateTime.utc(2026, 8, 13);

final class _NoopUrlOpener implements ExternalUrlOpener {
  const _NoopUrlOpener();

  @override
  Future<bool> open(Uri uri) => Future<bool>.value(false);
}

List<ChatItem> _messages(int count, {String prefix = 'message'}) => <ChatItem>[
  for (var index = 0; index < count; index += 1)
    ChatUserMessage(
      key: '$prefix-$index',
      turnId: 'turn-$prefix',
      createdAt: _createdAt.add(Duration(seconds: index)),
      text: index.isEven
          ? '$prefix $index'
          : '$prefix $index\nline two\nline three',
    ),
];

ChatAssistantMessage _streamingMessage(String markdown) => ChatAssistantMessage(
  key: 'streaming-response',
  turnId: 'turn-streaming',
  createdAt: _createdAt,
  markdown: markdown,
  isStreaming: true,
);

ChatToolActivity _disclosure() => ChatToolActivity(
  key: 'tool-disclosure',
  turnId: 'turn-tool',
  createdAt: _createdAt,
  callId: 'call-disclosure',
  toolName: 'read_file',
  arguments: const <String, dynamic>{'path': 'lib/large_file.dart'},
  status: ChatToolStatus.succeeded,
  output: List<String>.generate(18, (index) => 'output line $index').join('\n'),
);

Future<void> _useDesktopViewport(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(800, 600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

/// Stands in for the app's retained conversation reading positions.
typedef _PositionStore = Map<String, TRVirtualListSnapshot<String>>;

Future<void> _pumpTimeline(
  WidgetTester tester, {
  required List<ChatItem> items,
  required _PositionStore positions,
  required String sessionId,
  bool busy = false,
  ChatAttachmentLoader? loadAttachment,
}) {
  final sessionKey = 'conversation:$_hostId:$sessionId';
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        externalUrlOpenerProvider.overrideWithValue(const _NoopUrlOpener()),
      ],
      child: MaterialApp(
        theme: testLightTheme,
        darkTheme: testDarkTheme,
        locale: testLocale,
        localizationsDelegates: testLocalizationsDelegates,
        supportedLocales: testSupportedLocales,
        builder: (context, child) => TinestUiDensity(child: child!),
        home: Scaffold(
          body: ChatTimelineView(
            sessionKey: sessionKey,
            readingPosition: positions[sessionKey],
            onReadingPositionChanged: (key, position) => position == null
                ? positions.remove(key)
                : positions[key] = position,
            items: items,
            busy: busy,
            hostId: _hostId,
            loadAttachment: loadAttachment,
          ),
        ),
      ),
    ),
  );
}

Finder get _scrollable => find
    .descendant(
      of: find.byType(ChatTimelineView),
      matching: find.byType(Scrollable),
    )
    .first;

ScrollPosition _scrollPosition(WidgetTester tester) =>
    tester.state<ScrollableState>(_scrollable).position;

void _expectTrailingPinned(WidgetTester tester, {required String reason}) {
  expect(
    _scrollPosition(tester).extentAfter,
    closeTo(0, _geometryTolerance),
    reason: reason,
  );
}

Widget _streamingConversationHarness(
  GlobalKey<_StreamingConversationHarnessState> key,
) => ProviderScope(
  overrides: [
    appServicesProvider.overrideWithValue(fakeAppServices(FakeTinestApi())),
    externalUrlOpenerProvider.overrideWithValue(const _NoopUrlOpener()),
  ],
  child: MaterialApp(
    theme: testLightTheme,
    darkTheme: testDarkTheme,
    locale: testLocale,
    localizationsDelegates: testLocalizationsDelegates,
    supportedLocales: testSupportedLocales,
    builder: (context, child) => TinestUiDensity(child: child!),
    home: Scaffold(body: _StreamingConversationHarness(key: key)),
  ),
);

final class _StreamingConversationHarness extends StatefulWidget {
  const _StreamingConversationHarness({super.key});

  @override
  State<_StreamingConversationHarness> createState() =>
      _StreamingConversationHarnessState();
}

final class _StreamingConversationHarnessState
    extends State<_StreamingConversationHarness> {
  final List<ChatItem> _history = _messages(24, prefix: 'composer-history');
  String? submittedPrompt;
  String _assistantMarkdown = '';
  bool _busy = false;

  List<ChatItem> get _items => <ChatItem>[
    ..._history,
    if (submittedPrompt case final prompt?)
      ChatUserMessage(
        key: 'submitted-prompt',
        turnId: 'turn-composer-streaming',
        createdAt: _createdAt.add(const Duration(minutes: 1)),
        text: prompt,
      ),
    if (_busy) _streamingMessage(_assistantMarkdown),
  ];

  void _submit(ComposerSubmission submission) {
    setState(() {
      submittedPrompt = submission.text;
      _assistantMarkdown = '';
      _busy = true;
    });
  }

  void appendAssistantDelta(String delta) {
    setState(() => _assistantMarkdown += delta);
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Expanded(
        child: ChatTimelineView(
          sessionKey: 'conversation:$_hostId:composer-streaming-session',
          items: _items,
          busy: _busy,
          hostId: _hostId,
        ),
      ),
      SessionComposer(
        enabled: true,
        busy: _busy,
        onSubmit: _submit,
        bar: SessionComposerBar(
          hostId: _hostId,
          definitions: const [],
          agentDefinitionId: null,
          selection: null,
          onAgentChanged: (_) {},
          onModelChanged: (_, _) {},
        ),
      ),
    ],
  );
}

({String key, double top}) _visibleAnchor(
  WidgetTester tester,
  Iterable<ChatItem> candidates,
) {
  final viewport = tester.getRect(_scrollable);
  for (final item in candidates) {
    final row = find.byKey(ValueKey<String>(item.key));
    if (row.evaluate().isEmpty) continue;
    final rect = tester.getRect(row);
    if (rect.top >= viewport.top && rect.bottom <= viewport.bottom) {
      return (key: item.key, top: rect.top);
    }
  }
  throw StateError('No fully visible history row was available as an anchor.');
}

void main() {
  testWidgets(
    'timeline rows use shared horizontal, gap, and trailing padding tokens',
    tags: const <String>[
      'feature_test__turn_execution__widget',
    ],
    (tester) async {
      await _useDesktopViewport(tester);
      final history = _messages(2);
      await _pumpTimeline(
        tester,
        items: history,
        positions: _PositionStore(),
        sessionId: 'spacing-session',
      );
      await tester.pumpAndSettle();

      final first = find.byKey(const ValueKey<String>('message-0'));
      final last = find.byKey(const ValueKey<String>('message-1'));
      final viewport = tester.getRect(_scrollable);
      expect(
        tester.getTopLeft(last).dy - tester.getBottomLeft(first).dy,
        closeTo(TRSpacing.small, _geometryTolerance),
      );
      expect(
        viewport.bottom - tester.getBottomLeft(last).dy,
        closeTo(TRSpacing.large, _geometryTolerance),
      );

      final rowPadding = tester
          .widgetList<Padding>(
            find.ancestor(of: first, matching: find.byType(Padding)),
          )
          .map((widget) => widget.padding)
          .whereType<EdgeInsets>()
          .singleWhere(
            (padding) =>
                padding.left == TRSpacing.extraLarge &&
                padding.right == TRSpacing.extraLarge &&
                padding.top == TRSpacing.large &&
                padding.bottom == TRSpacing.small,
          );
      expect(rowPadding.left, TRSpacing.extraLarge);
      expect(rowPadding.right, TRSpacing.extraLarge);
    },
  );

  testWidgets(
    'streaming below scrolled-up history retains the visible anchor',
    tags: const <String>[
      'feature_test__turn_execution__widget',
      'ui_state__conversation_timeline__history_anchored__widget',
    ],
    (tester) async {
      await _useDesktopViewport(tester);
      final positions = _PositionStore();
      final history = _messages(64);
      await _pumpTimeline(
        tester,
        items: <ChatItem>[...history, _streamingMessage('Starting')],
        positions: positions,
        sessionId: 'anchor-session',
        busy: true,
      );
      await tester.pump();
      expect(
        find.byKey(const ValueKey<String>('chat-running')),
        findsOneWidget,
      );

      final position = _scrollPosition(tester);
      position.jumpTo(position.maxScrollExtent * 0.45);
      await tester.pump();
      final anchor = _visibleAnchor(tester, history);

      await _pumpTimeline(
        tester,
        items: <ChatItem>[
          ...history,
          _streamingMessage(
            List<String>.generate(
              16,
              (index) => 'Streamed paragraph $index.',
            ).join('\n\n'),
          ),
        ],
        positions: positions,
        sessionId: 'anchor-session',
        busy: true,
      );

      final anchorRow = find.byKey(ValueKey<String>(anchor.key));
      expect(anchorRow, findsOneWidget);
      expect(
        tester.getTopLeft(anchorRow).dy,
        closeTo(anchor.top, _geometryTolerance),
      );
      expect(
        find.byKey(const ValueKey<String>('streaming-response')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('chat-running')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'streaming growth follows the trailing edge while pinned',
    tags: const <String>[
      'feature_test__turn_execution__widget',
      'ui_state__conversation_timeline__history_anchored__widget',
    ],
    (tester) async {
      await _useDesktopViewport(tester);
      final positions = _PositionStore();
      final history = _messages(24);
      const responseKey = ValueKey<String>('streaming-response');
      await _pumpTimeline(
        tester,
        items: <ChatItem>[...history, _streamingMessage('Starting')],
        positions: positions,
        sessionId: 'pinned-session',
        busy: true,
      );
      await tester.pump();
      expect(
        find.byKey(const ValueKey<String>('chat-running')),
        findsOneWidget,
      );

      final viewport = tester.getRect(_scrollable);
      final initialGap =
          viewport.bottom - tester.getRect(find.byKey(responseKey)).bottom;

      await _pumpTimeline(
        tester,
        items: <ChatItem>[
          ...history,
          _streamingMessage(
            List<String>.generate(
              10,
              (index) => 'Growing response line $index.',
            ).join('\n\n'),
          ),
        ],
        positions: positions,
        sessionId: 'pinned-session',
        busy: true,
      );

      expect(
        viewport.bottom - tester.getRect(find.byKey(responseKey)).bottom,
        closeTo(initialGap, _geometryTolerance),
      );
      expect(
        find.byKey(const ValueKey<String>('chat-running')),
        findsOneWidget,
      );
    },
  );

  for (final testCase in <({String name, String prompt})>[
    (name: 'one-line input', prompt: 'Explain the change'),
    (
      name: 'multi-line input',
      prompt: 'Inspect the behavior\nPreserve the anchor\nVerify every chunk',
    ),
  ]) {
    testWidgets(
      'SessionComposer send and streaming deltas stay trailing for '
      '${testCase.name}',
      tags: const <String>[
        'feature_test__turn_execution__widget',
        'ui_state__conversation_timeline__history_anchored__widget',
      ],
      (tester) async {
        await _useDesktopViewport(tester);
        final harnessKey = GlobalKey<_StreamingConversationHarnessState>();
        await tester.pumpWidget(_streamingConversationHarness(harnessKey));
        await tester.pumpAndSettle();
        _expectTrailingPinned(tester, reason: 'initial history');

        const inputKey = ValueKey<String>('session-composer-input');
        await tester.enterText(find.byKey(inputKey), testCase.prompt);
        await tester.pump();
        _expectTrailingPinned(tester, reason: 'typed ${testCase.name}');

        await tester.tap(
          find.byKey(const ValueKey<String>('session-composer-send')),
        );
        await tester.pump();
        await tester.pump();
        expect(harnessKey.currentState!.submittedPrompt, testCase.prompt);
        expect(find.byKey(inputKey), findsOneWidget);
        expect(
          find.byKey(const ValueKey<String>('chat-running')),
          findsOneWidget,
        );
        _expectTrailingPinned(tester, reason: 'sent ${testCase.name}');

        final chunks = <String>[
          'Starting with a short response.',
          '\n\nThe second chunk expands the response.',
          '\n\n${List<String>.generate(
            8,
            (index) => 'Detail $index.',
          ).join('\n\n')}',
          '\n\nFinal streamed paragraph.',
        ];
        for (var index = 0; index < chunks.length; index += 1) {
          harnessKey.currentState!.appendAssistantDelta(chunks[index]);
          await tester.pump();
          await tester.pump();
          _expectTrailingPinned(
            tester,
            reason: '${testCase.name} assistant chunk $index',
          );
        }
      },
    );
  }

  testWidgets(
    'a disclosure keeps its header fixed in the expansion pump',
    tags: const <String>[
      'feature_test__turn_execution__widget',
      'ui_state__conversation_timeline__history_anchored__widget',
    ],
    (tester) async {
      await _useDesktopViewport(tester);
      final positions = _PositionStore();
      await _pumpTimeline(
        tester,
        items: <ChatItem>[..._messages(24), _disclosure()],
        positions: positions,
        sessionId: 'disclosure-session',
      );
      await tester.pumpAndSettle();

      final disclosure = find.byType(TRChatToolDisclosure);
      final before = tester.getTopLeft(disclosure).dy;
      await tester.tap(disclosure);
      await tester.pump();
      final afterExpansionPump = tester.getTopLeft(disclosure).dy;

      expect(afterExpansionPump, closeTo(before, _geometryTolerance));
      expect(find.textContaining('output line 10'), findsOneWidget);

      await tester.pump();
      expect(
        tester.getTopLeft(disclosure).dy,
        closeTo(afterExpansionPump, _geometryTolerance),
      );
    },
  );

  testWidgets(
    'an underfilled disclosure expands without losing its trailing anchor',
    tags: const <String>[
      'feature_test__turn_execution__widget',
      'ui_state__conversation_timeline__history_anchored__widget',
    ],
    (tester) async {
      await _useDesktopViewport(tester);
      await _pumpTimeline(
        tester,
        items: <ChatItem>[_disclosure()],
        positions: _PositionStore(),
        sessionId: 'underfilled-disclosure-session',
      );
      await tester.pumpAndSettle();

      final disclosure = find.byType(TRChatToolDisclosure);
      final before = tester.getTopLeft(disclosure).dy;
      await tester.tap(disclosure);
      await tester.pump();

      expect(
        tester.getTopLeft(disclosure).dy,
        closeTo(before, _geometryTolerance),
      );
      expect(find.textContaining('output line 10'), findsOneWidget);

      await tester.pump();
      expect(
        tester.getTopLeft(disclosure).dy,
        closeTo(before, _geometryTolerance),
      );
    },
  );

  testWidgets(
    'trailing follow resumes after the reader returns to the bottom',
    tags: const <String>[
      'feature_test__turn_execution__widget',
      'ui_state__conversation_timeline__history_anchored__widget',
    ],
    (tester) async {
      await _useDesktopViewport(tester);
      final positions = _PositionStore();
      final history = _messages(60);
      await _pumpTimeline(
        tester,
        items: history,
        positions: positions,
        sessionId: 'follow-session',
      );
      await tester.pumpAndSettle();

      var position = _scrollPosition(tester);
      position.jumpTo(position.maxScrollExtent * 0.45);
      await tester.pump();
      final anchor = _visibleAnchor(tester, history);
      final withFirstAppend = <ChatItem>[
        ...history,
        ..._messages(1, prefix: 'new'),
      ];

      await _pumpTimeline(
        tester,
        items: withFirstAppend,
        positions: positions,
        sessionId: 'follow-session',
      );

      expect(
        tester.getTopLeft(find.byKey(ValueKey<String>(anchor.key))).dy,
        closeTo(anchor.top, _geometryTolerance),
      );
      expect(find.byKey(const ValueKey<String>('new-0')), findsNothing);

      position = _scrollPosition(tester);
      position.jumpTo(position.maxScrollExtent);
      await tester.pump();
      final latest = ChatUserMessage(
        key: 'newest-after-return',
        turnId: 'turn-new',
        createdAt: _createdAt,
        text: 'newest after return',
      );
      await _pumpTimeline(
        tester,
        items: <ChatItem>[...withFirstAppend, latest],
        positions: positions,
        sessionId: 'follow-session',
      );

      final latestRow = find.byKey(ValueKey<String>(latest.key));
      expect(latestRow, findsOneWidget);
      final viewport = tester.getRect(_scrollable);
      position = _scrollPosition(tester);
      expect(
        position.pixels,
        closeTo(position.maxScrollExtent, _geometryTolerance),
      );
      expect(
        viewport.bottom - tester.getRect(latestRow).bottom,
        closeTo(TRSpacing.large, _geometryTolerance),
      );
    },
  );

  testWidgets(
    'switching sessions clears disclosure state retained by the timeline '
    'widget',
    tags: const <String>[
      'feature_test__turn_execution__widget',
    ],
    (tester) async {
      await _useDesktopViewport(tester);
      final positions = _PositionStore();
      await _pumpTimeline(
        tester,
        items: <ChatItem>[_disclosure()],
        positions: positions,
        sessionId: 'first-disclosure-session',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(TRChatToolDisclosure));
      await tester.pump();
      expect(find.textContaining('output line 10'), findsOneWidget);

      await _pumpTimeline(
        tester,
        items: <ChatItem>[_disclosure()],
        positions: positions,
        sessionId: 'second-disclosure-session',
      );
      await tester.pump();

      expect(find.textContaining('output line 10'), findsNothing);
    },
  );

  testWidgets(
    'switching sessions discards attachment state with colliding item IDs',
    tags: const <String>['feature_test__conversation_attachments__widget'],
    (tester) async {
      await _useDesktopViewport(tester);
      final positions = _PositionStore();
      final firstBytes = Completer<Uint8List>();
      final secondBytes = Completer<Uint8List>();
      var firstLoads = 0;
      var secondLoads = 0;
      final items = <ChatItem>[
        ChatAttachmentMessage(
          key: 'shared-attachment-row',
          turnId: 'turn',
          createdAt: _createdAt,
          attachment: const ChatAttachment(
            id: 'shared-attachment',
            fileName: 'preview.png',
            mimeType: 'image/png',
            byteSize: 1,
          ),
        ),
      ];

      await _pumpTimeline(
        tester,
        items: items,
        positions: positions,
        sessionId: 'first-attachment-session',
        loadAttachment: (_) {
          firstLoads += 1;
          return firstBytes.future;
        },
      );
      await tester.pump();
      expect(firstLoads, 1);

      await _pumpTimeline(
        tester,
        items: items,
        positions: positions,
        sessionId: 'second-attachment-session',
        loadAttachment: (_) {
          secondLoads += 1;
          return secondBytes.future;
        },
      );
      await tester.pump();

      expect(secondLoads, 1);
      expect(find.byType(TRSkeleton), findsOneWidget);
    },
  );

  testWidgets(
    'switching sessions restores the history anchor of a reader who left with '
    'messages below them',
    tags: const <String>[
      'feature_test__turn_execution__widget',
      'ui_state__conversation_timeline__history_anchored__widget',
    ],
    (tester) async {
      await _useDesktopViewport(tester);
      final positions = _PositionStore();
      final firstSession = _messages(60, prefix: 'first');
      await _pumpTimeline(
        tester,
        items: firstSession,
        positions: positions,
        sessionId: 'first-session',
      );
      await tester.pumpAndSettle();

      final firstPosition = _scrollPosition(tester);
      firstPosition.jumpTo(firstPosition.maxScrollExtent * 0.45);
      await tester.pumpAndSettle();
      final saved = _visibleAnchor(tester, firstSession);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      final secondSession = _messages(36, prefix: 'second');
      await _pumpTimeline(
        tester,
        items: secondSession,
        positions: positions,
        sessionId: 'second-session',
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey<String>('second-35')), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      await _pumpTimeline(
        tester,
        items: firstSession,
        positions: positions,
        sessionId: 'first-session',
      );
      await tester.pumpAndSettle();

      expect(
        tester.getTopLeft(find.byKey(ValueKey<String>(saved.key))).dy,
        closeTo(saved.top, _geometryTolerance),
      );
      expect(find.byKey(const ValueKey<String>('second-35')), findsNothing);
    },
  );

  testWidgets(
    'a session left at its newest message reopens there rather than on the '
    'row that happened to be under the reader',
    tags: const <String>[
      'feature_test__turn_execution__widget',
    ],
    (tester) async {
      await _useDesktopViewport(tester);
      final positions = _PositionStore();
      final history = _messages(60, prefix: 'latest');
      await _pumpTimeline(
        tester,
        items: history,
        positions: positions,
        sessionId: 'latest-session',
      );
      await tester.pumpAndSettle();
      _expectTrailingPinned(tester, reason: 'first entry');

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(
        positions,
        isEmpty,
        reason: 'a reader at the end has no position worth restoring',
      );

      // Messages that arrived while away must not be hidden behind a restored
      // anchor: the reader asked for the end, so the end is what they get.
      await _pumpTimeline(
        tester,
        items: <ChatItem>[
          ...history,
          ..._messages(4, prefix: 'arrived'),
        ],
        positions: positions,
        sessionId: 'latest-session',
      );
      await tester.pumpAndSettle();

      _expectTrailingPinned(tester, reason: 're-entry after new messages');
      expect(find.byKey(const ValueKey<String>('arrived-3')), findsOneWidget);
    },
  );
}
