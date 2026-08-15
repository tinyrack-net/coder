import 'dart:async';
import 'dart:io';

import 'package:agent/agent.dart';
import 'package:app/testing/app/tinest_app.dart';
import 'package:app/testing/features/conversation/presentation/chat_timeline_view.dart';
import 'package:client/client.dart';
import 'package:daemon/daemon.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:protocol/protocol.dart';

import 'support/pump_until.dart';
import 'support/real_daemon_fixture.dart';

/// Deltas streamed per scripted answer.
///
/// One row is written per delta, so this is what makes a handful of turns
/// exceed a page and forces the reader onto the paging path the way a real
/// long conversation does.
const int _deltasPerAnswer = 60;
const int _turns = 5;
const double _geometryTolerance = 0.01;
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'a long conversation opens at its newest message, pages back through '
    'history, and returns where the reader left it',
    (tester) async {
      tester.binding.platformDispatcher.localeTestValue = const Locale('ko');
      addTearDown(tester.binding.platformDispatcher.clearLocaleTestValue);
      await tester.binding.setSurfaceSize(const Size(1400, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final fixture = await RealDaemonFixture.start(
        id: 'conversation-history',
        provider: _HistoryProvider(),
        modelDiscovery: const _HistoryModelDiscovery(),
      );
      addTearDown(fixture.dispose);
      final client = await fixture.connect(clientId: 'history-setup');
      addTearDown(client.close);
      final workspace = Directory('${fixture.home.path}/workspace')
        ..createSync();
      await client.workspaces.registerWorkspace(
        workspaceId: 'history-workspace',
        checkoutId: 'history-checkout',
        rootPath: workspace.path,
        name: 'History Workspace',
      );
      final registeredWorktree =
          (await client.workspaces.getWorkspaceCatalog()).worktrees.single;
      final connection = await client.providers.createCustomProvider(
        'history',
        const CustomProviderConfigDto(
          name: 'History provider',
          baseUrl: 'http://127.0.0.1:1/v1',
          wireFormatId: 'openai-chat-completions',
          authenticationRequired: false,
          models: <ManualProviderModelDto>[
            ManualProviderModelDto(id: 'test-model', label: 'Test model'),
          ],
        ),
      );
      final model = (await client.providers.listProviderModels(
        connection.id,
      )).singleWhere((candidate) => candidate.providerModelId == 'test-model');

      // A conversation the reader is coming back to, not one they are starting:
      // the history exists before the app is ever mounted.
      final long = await client.sessions.createSession(
        id: 'history-session',
        worktreeId: 'history-checkout',
        title: '긴 대화',
        agentDefinitionId: 'tinest',
        model: ModelSelectionDto(modelId: model.id),
      );
      for (var turn = 1; turn <= _turns; turn += 1) {
        await client.sessions.startTurn(
          sessionId: long.id,
          turnId: 'history-turn-$turn',
          prompt: '질문 $turn',
        );
        await _awaitIdle(client, long.id);
      }
      final other = await client.sessions.createSession(
        id: 'other-session',
        worktreeId: 'history-checkout',
        title: '다른 대화',
        agentDefinitionId: 'tinest',
        model: ModelSelectionDto(modelId: model.id),
      );
      await client.sessions.startTurn(
        sessionId: other.id,
        turnId: 'other-turn',
        prompt: '다른 질문',
      );
      await _awaitIdle(client, other.id);

      final events = await client.sessions.subscribeTimeline(long.id);
      expect(
        events.length,
        greaterThan(timelineHistoryPageSize),
        reason: 'the scripted history must exceed one page to be a test',
      );

      await _openSession(tester, fixture, registeredWorktree.id, '긴 대화');

      // 1. Entering shows the newest message, not the oldest.
      await pumpUntil(tester, _newest());
      _expectAtNewest(tester, phase: 'first entry');
      expect(
        _oldest(),
        findsNothing,
        reason: 'the oldest turn is beyond the page loaded on entry',
      );

      // 2. A reader who leaves with messages below them returns to their spot.
      //    The anchor is inside the page loaded on entry on purpose: a switch
      //    disposes the conversation and reloads that page, so an anchor from
      //    deeper history is deliberately not restorable (see 4).
      for (var drag = 0; drag < 3; drag += 1) {
        await tester.drag(_timeline, const Offset(0, 600));
        await tester.pump(const Duration(milliseconds: 100));
      }
      final leftAt = _position(tester).pixels;
      expect(
        _position(tester).extentAfter,
        greaterThan(1),
        reason: 'the reader must actually be away from the end to restore one',
      );
      await _activateSession(tester, '다른 대화');
      await _activateSession(tester, '긴 대화');
      // A restored reader is mid-history, so the end of the transcript is
      // below the viewport and never built; there is no newest row to wait on.
      await _settleTimeline(tester);
      expect(
        _position(tester).pixels,
        closeTo(leftAt, 2),
        reason: 'a reader who left with messages below them returns to them',
      );

      // 3. Leaving from the newest message returns to the newest message,
      //    which is what makes the restore in 2 conditional rather than sticky.
      await _dragToNewest(tester);
      _expectAtNewest(tester, phase: 'after returning to the end');
      await _activateSession(tester, '다른 대화');
      await _activateSession(tester, '긴 대화');
      await pumpUntil(tester, _newest());
      _expectAtNewest(tester, phase: 'reopened from the end');

      // 4. Scrolling back loads earlier turns that entry never fetched.
      await _dragUntil(
        tester,
        _oldest,
        'the oldest turn to arrive from an earlier page',
      );

      // 5. A cold start opens at the newest message too, which is the report
      //    this whole contract came from, and it is back to one page: paged
      //    history is a reading aid, not state the app carries around.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await _openSession(tester, fixture, registeredWorktree.id, '긴 대화');
      await pumpUntil(tester, _newest());
      _expectAtNewest(tester, phase: 'cold start');
      expect(_oldest(), findsNothing);
    },
    // Written inline and whole. The feature verifier reads evidence out of
    // source text and only counts a tag that follows its `testWidgets(`, so a
    // hoisted constant is a tag it cannot see.
    tags: const <String>[
      'feature_test__conversation_history_pagination__e2e',
      'feature_scenario__conversation_history_pagination__page_back__e2e',
    ],
  );
}

/// Built fresh per use: a Finder caches its matches, and stringifying one that
/// cached elements from a torn-down tree throws before any assertion runs.
Finder _newest() => find.textContaining('질문 5 응답 59', findRichText: true);

Finder _oldest() => find.textContaining('질문 1 응답 0', findRichText: true);

Future<void> _awaitIdle(TinestApi client, String sessionId) => awaitCondition(
  () async => (await client.sessions.listSessions())
      .where((session) => session.id == sessionId)
      .any((session) => session.status == SessionStatus.idle),
  'session $sessionId to finish its turn',
  budget: e2eTurnBudget,
);

Finder get _timeline => find
    .descendant(
      of: find.byType(ChatTimelineView),
      matching: find.byType(Scrollable),
    )
    .first;

ScrollPosition _position(WidgetTester tester) =>
    tester.state<ScrollableState>(_timeline).position;

/// Waits for a freshly mounted transcript to finish measuring its history.
Future<void> _settleTimeline(WidgetTester tester) async {
  await pumpUntil(tester, _timeline);
  await pumpUntilCondition(
    tester,
    () => _position(tester).maxScrollExtent > 0,
    'the transcript to measure more than one screen of history',
  );
  await tester.pump(const Duration(milliseconds: 300));
}

/// Asserts the reader is resting on the newest message.
///
/// `extentAfter` alone would pass while parked at the top of a list shorter
/// than its viewport, so the scroll extent is checked for meaning first.
void _expectAtNewest(WidgetTester tester, {required String phase}) {
  final position = _position(tester);
  expect(
    position.maxScrollExtent,
    greaterThan(0),
    reason: 'timeline overfills its viewport at $phase',
  );
  expect(
    position.extentAfter,
    closeTo(0, _geometryTolerance),
    reason: 'timeline rests on its newest message at $phase',
  );
}

/// Drags the transcript backwards until [target] appears.
///
/// Real drags rather than a programmatic jump: the edge request fires from
/// scroll notifications, so a jump would prove the fetch works without proving
/// a reader can ever provoke it.
Future<void> _dragUntil(
  WidgetTester tester,
  Finder Function() target,
  String description,
) async {
  for (var attempt = 0; attempt < 120; attempt += 1) {
    if (target().evaluate().isNotEmpty) return;
    await tester.drag(_timeline, const Offset(0, 600));
    await tester.pump(const Duration(milliseconds: 100));
  }
  throw TestFailure('Timed out dragging back to $description.');
}

/// Drags the transcript forwards until it rests on the newest message.
Future<void> _dragToNewest(WidgetTester tester) async {
  for (var attempt = 0; attempt < 200; attempt += 1) {
    if (_position(tester).extentAfter <= _geometryTolerance) return;
    await tester.drag(_timeline, const Offset(0, -900));
    await tester.pump(const Duration(milliseconds: 100));
  }
  throw TestFailure('Timed out dragging forward to the newest message.');
}

/// Moves to [title] the way a reader does, through the sessions menu.
///
/// Used in both directions on purpose: the menu opens a conversation that has
/// no tab yet and re-activates one that does, so a single path covers leaving
/// a conversation and coming back to it.
Future<void> _activateSession(WidgetTester tester, String title) async {
  final menu = find.byKey(
    const ValueKey<String>('workspace-all-sessions-menu'),
  );
  await pumpUntil(tester, menu);
  await tester.tap(menu);
  final conversation = find.text(title).hitTestable();
  await pumpUntil(tester, conversation);
  await tester.tap(conversation.last);
  await pumpUntil(
    tester,
    find.byKey(const ValueKey<String>('session-composer-input')),
  );
  await tester.pump(const Duration(milliseconds: 200));
}

Future<void> _openSession(
  WidgetTester tester,
  RealDaemonFixture fixture,
  String worktreeId,
  String title,
) async {
  await tester.pumpWidget(TinestApp(services: fixture.services));
  await pumpUntil(tester, find.text('History Workspace'));
  final worktree = find
      .byKey(ValueKey<String>('workspace-worktree-$worktreeId'))
      .hitTestable();
  await pumpUntil(tester, worktree);
  await tester.tap(worktree.last);
  await pumpUntil(
    tester,
    find.byKey(const ValueKey<String>('workspace-all-sessions-menu')),
  );
  await tester.tap(
    find.byKey(const ValueKey<String>('workspace-all-sessions-menu')),
  );
  final conversation = find.text(title).hitTestable();
  await pumpUntil(tester, conversation);
  await tester.tap(conversation.last);
  await pumpUntil(
    tester,
    find.byKey(const ValueKey<String>('session-composer-input')),
  );
}

final class _HistoryModelDiscovery implements ProviderModelDiscovery {
  const _HistoryModelDiscovery();

  @override
  Future<List<String>> fetchModelIds(
    ProviderEndpoint endpoint,
    ProviderCredential? credential,
  ) async => const <String>['test-model'];
}

/// Answers every prompt with enough deltas to outgrow a single page.
final class _HistoryProvider implements ModelProvider {
  @override
  String get id => 'conversation-history';

  @override
  Stream<ModelEvent> stream(
    ModelRequest request,
    CancellationToken cancellation,
  ) async* {
    final prompt = request.history.whereType<UserConversationItem>().last.text;
    final buffer = StringBuffer();
    for (var index = 0; index < _deltasPerAnswer; index += 1) {
      cancellation.throwIfCancelled();
      final delta = '$prompt 응답 $index\n\n';
      buffer.write(delta);
      yield ModelTextDelta(delta);
    }
    yield ModelResponseCompleted(
      assistant: AssistantConversationItem(text: buffer.toString()),
    );
  }
}
