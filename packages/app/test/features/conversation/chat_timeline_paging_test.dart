import 'package:app/l10n/gen/app_localizations.dart';
import 'package:app/src/app/platform/external_url_opener.dart';
import 'package:app/src/features/conversation/application/chat_timeline_model.dart';
import 'package:app/src/features/conversation/presentation/chat_timeline_view.dart';
import 'package:app/src/shared/presentation/tinest_ui_density.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

import '../../support/localization.dart';

const _geometryTolerance = 0.01;
const _hostId = 'host-paging';
final _createdAt = DateTime.utc(2026, 8, 15);

final class _NoopUrlOpener implements ExternalUrlOpener {
  const _NoopUrlOpener();

  @override
  Future<bool> open(Uri uri) => Future<bool>.value(false);
}

List<ChatItem> _messages(int first, int last) => <ChatItem>[
  for (var index = first; index <= last; index += 1)
    ChatUserMessage(
      key: 'history-$index',
      turnId: 'turn-$index',
      createdAt: _createdAt.add(Duration(seconds: index)),
      text: 'history $index',
    ),
];

Finder get _scrollable => find
    .descendant(
      of: find.byType(ChatTimelineView),
      matching: find.byType(Scrollable),
    )
    .first;

ScrollPosition _scrollPosition(WidgetTester tester) =>
    tester.state<ScrollableState>(_scrollable).position;

/// Pumps fixed frames instead of settling.
///
/// The in-flight status row animates for as long as it is shown, so a list
/// displaying one never reaches a quiescent state.
Future<void> _pumpFrames(WidgetTester tester) async {
  for (var frame = 0; frame < 8; frame += 1) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// The label of the single leading status row, or null when there is none.
String? _statusLabel(WidgetTester tester) {
  final rows = tester.widgetList<TRChatStatusRow>(
    find.byType(TRChatStatusRow),
  );
  return rows.isEmpty ? null : rows.single.label;
}

AppLocalizations _l10n(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(ChatTimelineView)));

Future<void> _pump(
  WidgetTester tester, {
  required List<ChatItem> items,
  required VoidCallback onLoadOlder,
  Object? olderPageKey,
  bool loadingOlder = false,
  bool olderFailed = false,
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
        body: ChatTimelineView(
          sessionKey: 'conversation:$_hostId:paging-session',
          items: items,
          busy: false,
          hostId: _hostId,
          olderPageKey: olderPageKey,
          loadingOlder: loadingOlder,
          olderFailed: olderFailed,
          onLoadOlder: onLoadOlder,
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets(
    'a short conversation with no older history never asks for a page',
    tags: const <String>[
      'feature_test__conversation_history_pagination__widget',
    ],
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var requests = 0;
      await _pump(
        tester,
        items: _messages(1, 3),
        onLoadOlder: () => requests += 1,
      );
      await tester.pumpAndSettle();

      // An underfilled list is already at its leading edge, so a request that
      // merely exists is a request that fires.
      expect(requests, 0);
      expect(_statusLabel(tester), isNull);
    },
  );

  testWidgets(
    'reaching the oldest loaded message asks for each page exactly once',
    tags: const <String>[
      'feature_test__conversation_history_pagination__widget',
      'ui_state__conversation_timeline__history_paging__widget',
    ],
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var requests = 0;
      await _pump(
        tester,
        items: _messages(40, 120),
        olderPageKey: 'older:40:0',
        onLoadOlder: () => requests += 1,
      );
      await tester.pumpAndSettle();
      expect(requests, 0, reason: 'the reader opens at the newest message');

      final position = _scrollPosition(tester)..jumpTo(0);
      await tester.pumpAndSettle();
      expect(requests, 1);

      // The same cursor must not be asked for again, however much the reader
      // moves around at the top.
      position
        ..jumpTo(position.maxScrollExtent * 0.2)
        ..jumpTo(0);
      await tester.pumpAndSettle();
      expect(requests, 1);
    },
  );

  testWidgets(
    'a page in flight shows one status row and prepending keeps the reader '
    'where they were',
    tags: const <String>[
      'feature_test__conversation_history_pagination__widget',
    ],
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _pump(
        tester,
        items: _messages(40, 120),
        olderPageKey: 'older:40:0',
        loadingOlder: true,
        onLoadOlder: () {},
      );
      await _pumpFrames(tester);
      _scrollPosition(tester).jumpTo(0);
      await _pumpFrames(tester);
      expect(_statusLabel(tester), _l10n(tester).conversationLoadingOlder);

      final anchor = find.byKey(const ValueKey<String>('history-42'));
      final before = tester.getTopLeft(anchor).dy;

      await _pump(
        tester,
        items: _messages(1, 120),
        olderPageKey: 'older:1:0',
        onLoadOlder: () {},
      );
      await tester.pumpAndSettle();

      expect(
        tester.getTopLeft(anchor).dy,
        // The row that was first loses its extra top padding to the page that
        // arrived above it. That token is the entire budget: anything larger
        // means the viewport followed the new content instead of the reader.
        closeTo(before, TRSpacing.large + _geometryTolerance),
        reason: 'older messages arrive above the reader, not under them',
      );
      expect(_statusLabel(tester), isNull);
    },
  );

  testWidgets(
    'a failed page reports itself and can be asked for again',
    tags: const <String>[
      'feature_test__conversation_history_pagination__widget',
    ],
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var requests = 0;
      await _pump(
        tester,
        items: _messages(40, 120),
        olderPageKey: 'older:40:0',
        onLoadOlder: () => requests += 1,
      );
      await tester.pumpAndSettle();
      _scrollPosition(tester).jumpTo(0);
      await tester.pumpAndSettle();
      expect(requests, 1);

      await _pump(
        tester,
        items: _messages(40, 120),
        olderPageKey: 'older:40:1',
        olderFailed: true,
        onLoadOlder: () => requests += 1,
      );
      _scrollPosition(tester).jumpTo(0);
      await _pumpFrames(tester);

      expect(_statusLabel(tester), _l10n(tester).conversationLoadOlderFailed);
      expect(
        requests,
        2,
        reason: 'the retry identity makes the same page requestable again',
      );
    },
  );

  testWidgets(
    'the status row is announced in the reader locale',
    tags: const <String>[
      'feature_test__conversation_history_pagination__widget',
    ],
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _pump(
        tester,
        items: _messages(40, 120),
        olderPageKey: 'older:40:0',
        loadingOlder: true,
        onLoadOlder: () {},
      );
      await _pumpFrames(tester);
      _scrollPosition(tester).jumpTo(0);
      await _pumpFrames(tester);

      final l10n = AppLocalizations.of(
        tester.element(find.byType(ChatTimelineView)),
      );
      expect(_statusLabel(tester), l10n.conversationLoadingOlder);
      expect(find.bySemanticsLabel(l10n.conversationLoadingOlder), findsOne);
    },
  );
}
