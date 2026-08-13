import 'package:app/src/app/platform/external_url_opener.dart';
import 'package:app/src/features/conversation/application/chat_timeline_model.dart';
import 'package:app/src/features/conversation/presentation/chat_timeline_view.dart';
import 'package:app/src/shared/presentation/tinest_ui_density.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

import '../../support/localization.dart';

const _geometryTolerance = 0.01;
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

Future<void> _pumpTimeline(
  WidgetTester tester, {
  required List<ChatItem> items,
  required PageStorageBucket bucket,
  required String sessionId,
}) => tester.pumpWidget(
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
        body: PageStorage(
          bucket: bucket,
          child: ChatTimelineView(
            pageStorageId: sessionId,
            items: items,
            busy: false,
          ),
        ),
      ),
    ),
  ),
);

Finder get _scrollable => find
    .descendant(
      of: find.byType(ChatTimelineView),
      matching: find.byType(Scrollable),
    )
    .first;

ScrollPosition _scrollPosition(WidgetTester tester) =>
    tester.state<ScrollableState>(_scrollable).position;

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
      'ui_state__conversation_timeline__history_anchored__widget',
    ],
    (tester) async {
      await _useDesktopViewport(tester);
      final history = _messages(2);
      await _pumpTimeline(
        tester,
        items: history,
        bucket: PageStorageBucket(),
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
      final bucket = PageStorageBucket();
      final history = _messages(64);
      await _pumpTimeline(
        tester,
        items: <ChatItem>[...history, _streamingMessage('Starting')],
        bucket: bucket,
        sessionId: 'anchor-session',
      );
      await tester.pumpAndSettle();

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
        bucket: bucket,
        sessionId: 'anchor-session',
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
      final bucket = PageStorageBucket();
      final history = _messages(24);
      const responseKey = ValueKey<String>('streaming-response');
      await _pumpTimeline(
        tester,
        items: <ChatItem>[...history, _streamingMessage('Starting')],
        bucket: bucket,
        sessionId: 'pinned-session',
      );
      await tester.pumpAndSettle();

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
        bucket: bucket,
        sessionId: 'pinned-session',
      );

      expect(
        viewport.bottom - tester.getRect(find.byKey(responseKey)).bottom,
        closeTo(initialGap, _geometryTolerance),
      );
    },
  );

  testWidgets(
    'a disclosure keeps its header fixed in the expansion pump',
    tags: const <String>[
      'feature_test__turn_execution__widget',
      'ui_state__conversation_timeline__history_anchored__widget',
    ],
    (tester) async {
      await _useDesktopViewport(tester);
      final bucket = PageStorageBucket();
      await _pumpTimeline(
        tester,
        items: <ChatItem>[..._messages(24), _disclosure()],
        bucket: bucket,
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
    'trailing follow resumes after the reader returns to the bottom',
    tags: const <String>[
      'feature_test__turn_execution__widget',
      'ui_state__conversation_timeline__history_anchored__widget',
    ],
    (tester) async {
      await _useDesktopViewport(tester);
      final bucket = PageStorageBucket();
      final history = _messages(60);
      await _pumpTimeline(
        tester,
        items: history,
        bucket: bucket,
        sessionId: 'follow-session',
      );
      await tester.pumpAndSettle();

      var position = _scrollPosition(tester);
      position.jumpTo(position.maxScrollExtent * 0.45);
      await tester.pump();
      final withFirstAppend = <ChatItem>[
        ...history,
        ..._messages(1, prefix: 'new'),
      ];

      await _pumpTimeline(
        tester,
        items: withFirstAppend,
        bucket: bucket,
        sessionId: 'follow-session',
      );

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
        bucket: bucket,
        sessionId: 'follow-session',
      );

      final latestRow = find.byKey(ValueKey<String>(latest.key));
      expect(latestRow, findsOneWidget);
      final viewport = tester.getRect(_scrollable);
      expect(tester.getRect(latestRow).bottom, lessThan(viewport.bottom));
      expect(tester.getRect(latestRow).bottom, greaterThan(viewport.center.dy));
    },
  );

  testWidgets(
    'switching sessions clears disclosure state retained by the timeline widget',
    tags: const <String>[
      'feature_test__turn_execution__widget',
      'ui_state__conversation_timeline__history_anchored__widget',
    ],
    (tester) async {
      await _useDesktopViewport(tester);
      final bucket = PageStorageBucket();
      await _pumpTimeline(
        tester,
        items: <ChatItem>[_disclosure()],
        bucket: bucket,
        sessionId: 'first-disclosure-session',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(TRChatToolDisclosure));
      await tester.pump();
      expect(find.textContaining('output line 10'), findsOneWidget);

      await _pumpTimeline(
        tester,
        items: <ChatItem>[_disclosure()],
        bucket: bucket,
        sessionId: 'second-disclosure-session',
      );
      await tester.pump();

      expect(find.textContaining('output line 10'), findsNothing);
    },
  );

  testWidgets(
    'switching sessions restores each PageStorage history anchor',
    tags: const <String>[
      'feature_test__turn_execution__widget',
      'ui_state__conversation_timeline__history_anchored__widget',
    ],
    (tester) async {
      await _useDesktopViewport(tester);
      final bucket = PageStorageBucket();
      final firstSession = _messages(60, prefix: 'first');
      await _pumpTimeline(
        tester,
        items: firstSession,
        bucket: bucket,
        sessionId: 'first-session',
      );
      await tester.pumpAndSettle();

      final firstPosition = _scrollPosition(tester);
      firstPosition.jumpTo(firstPosition.maxScrollExtent * 0.45);
      await tester.pumpAndSettle();
      final saved = _visibleAnchor(tester, firstSession);

      final secondSession = _messages(36, prefix: 'second');
      await _pumpTimeline(
        tester,
        items: secondSession,
        bucket: bucket,
        sessionId: 'second-session',
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey<String>('second-35')), findsOneWidget);

      await _pumpTimeline(
        tester,
        items: firstSession,
        bucket: bucket,
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
}
