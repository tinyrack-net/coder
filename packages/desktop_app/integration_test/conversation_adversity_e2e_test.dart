import 'dart:async';
import 'dart:io';

import 'package:agent/agent.dart';
import 'package:app/testing/app/tinest_app.dart';
import 'package:app/testing/features/conversation/presentation/chat_approval_card.dart';
import 'package:client/client.dart';
import 'package:daemon/daemon.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:protocol/protocol.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

import 'support/pump_until.dart';
import 'support/real_daemon_fixture.dart';

final String _firstStreamChunk = List<String>.generate(
  36,
  (index) => '스트림 청크 1-$index',
).join('\n\n');
final String _secondStreamChunk =
    '\n\n${List<String>.generate(
      12,
      (index) => '스트림 청크 2-$index',
    ).join('\n\n')}';
final String _thirdStreamChunk =
    '\n\n${List<String>.generate(
      12,
      (index) => '스트림 청크 3-$index',
    ).join('\n\n')}';
const String _adversityModelId = 'openai/gpt-5.6-sol';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'queued input crosses question, reconnect, approval, and restore '
    'boundaries',
    (tester) async {
      tester.binding.platformDispatcher.localeTestValue = const Locale('ko');
      addTearDown(tester.binding.platformDispatcher.clearLocaleTestValue);
      await tester.binding.setSurfaceSize(const Size(1400, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final provider = _AdversityProvider();
      final fixture = await RealDaemonFixture.start(
        id: 'conversation-adversity',
        provider: provider,
        providerCatalogMetadataSource: const _AdversityCatalogMetadataSource(),
      );
      addTearDown(fixture.dispose);
      final client = await fixture.connect(clientId: 'adversity-setup');
      addTearDown(client.close);
      final workspace = Directory('${fixture.home.path}/workspace')
        ..createSync();
      await client.workspaces.registerWorkspace(
        workspaceId: 'adversity-workspace',
        checkoutId: 'adversity-checkout',
        rootPath: workspace.path,
        name: 'Adversity Workspace',
      );
      final registeredWorktree =
          (await client.workspaces.getWorkspaceCatalog()).worktrees.single;
      final worktreeLabel =
          registeredWorktree.branch ?? registeredWorktree.name;
      // Manual custom-provider models advertise function tools only. This
      // scenario later exercises the freeform apply_patch contribution, so it
      // must select an exact full-surface model before the injected gateway is
      // allowed to receive a request.
      final model = (await client.providers.listProviderModels('openai'))
          .singleWhere(
            (candidate) => candidate.id == _adversityModelId,
          );
      expect(model.capabilities.streaming, CapabilitySupport.supported);
      expect(model.capabilities.functionTools, CapabilitySupport.supported);
      expect(model.capabilities.freeformTools, CapabilitySupport.supported);
      final tinest = await client.agents.getAgentDefinition('tinest');
      await client.agents.updateAgentDefinition(
        tinest.copyWith(
          toolIds: <String>[
            ...tinest.toolIds,
            'tinest.interaction/request_user_input',
          ],
        ),
        expectedContentHash: tinest.contentHash,
      );
      final SessionDto session;
      try {
        session = await client.sessions.createSession(
          id: 'adversity-session',
          worktreeId: 'adversity-checkout',
          title: 'Adversity conversation',
          agentDefinitionId: 'tinest',
          model: ModelSelectionDto(modelId: model.id),
        );
      } on TinestClientException catch (error) {
        throw TestFailure('Session setup failed: ${error.details}');
      }

      await _pumpConversation(
        tester,
        fixture,
        registeredWorktree.id,
        worktreeLabel,
      );
      const composerKey = ValueKey<String>('session-composer-input');
      const sendKey = ValueKey<String>('session-composer-send');
      await _submit(tester, composerKey, sendKey, 'Stream first');
      await _waitForProviderStart(
        tester,
        provider,
        client,
        session.id,
        registeredWorktree.id,
      );
      await pumpUntil(
        tester,
        find.textContaining('스트림 청크 1-35', findRichText: true),
      );
      _expectTimelineTrailing(
        tester,
        find.textContaining('스트림 청크 1-35', findRichText: true),
        phase: 'first overflowing stream chunk',
      );

      await _submit(tester, composerKey, sendKey, 'Ask then patch');
      await pumpUntil(
        tester,
        find.byKey(const ValueKey<String>('queued-turn-0')),
      );
      expect(find.text('Ask then patch'), findsWidgets);
      provider.releaseFirstTurn.complete();

      await provider.secondStreamChunkStarted.future.timeout(
        const Duration(minutes: 1),
      );
      final secondChunk = find.textContaining(
        '스트림 청크 2-11',
        findRichText: true,
      );
      await pumpUntil(tester, secondChunk);
      _expectTimelineTrailing(
        tester,
        secondChunk,
        phase: 'second stream chunk',
      );
      provider.releaseSecondStreamChunk.complete();

      await provider.thirdStreamChunkStarted.future.timeout(
        const Duration(minutes: 1),
      );
      final thirdChunk = find.textContaining(
        '스트림 청크 3-11',
        findRichText: true,
      );
      await pumpUntil(tester, thirdChunk);
      _expectTimelineTrailing(
        tester,
        thirdChunk,
        phase: 'third stream chunk',
      );
      provider.releaseThirdStreamChunk.complete();

      await pumpUntil(tester, find.text('Storage'));
      expect(find.text('Which store should the cache use?'), findsOneWidget);
      await _remountConversation(
        tester,
        fixture,
        registeredWorktree.id,
        worktreeLabel,
      );
      expect(find.text('Which store should the cache use?'), findsOneWidget);

      await tester.tap(find.text('SQLite'));
      final questionSubmit = find.byKey(
        const ValueKey<String>('chat-question-submit'),
      );
      await pumpUntilCondition(
        tester,
        () => tester.widget<TRButton>(questionSubmit).onPressed != null,
        'the restored question to become submittable',
      );
      await tester.tap(questionSubmit);

      var approval = _patchApproval();
      await pumpUntil(tester, approval);
      await _remountConversation(
        tester,
        fixture,
        registeredWorktree.id,
        worktreeLabel,
      );
      approval = _patchApproval();
      await pumpUntil(tester, approval);
      await tester.tap(
        find.descendant(
          of: approval,
          matching: find.widgetWithText(TRButton, '승인'),
        ),
      );
      await pumpUntil(
        tester,
        find.text('복합 대화 완료', findRichText: true),
      );
      expect(
        await File('${workspace.path}/adversity.txt').readAsString(),
        'restored\n',
      );

      await pumpUntilCondition(
        tester,
        () async =>
            (await client.sessions.listSessions(
              worktreeId: 'adversity-checkout',
            )).single.status ==
            SessionStatus.idle,
        'the restored turn to become idle',
      );
      final timeline = await client.sessions.subscribeTimeline(session.id);
      final sequences = timeline.map((event) => event.sequence).toList();
      expect(sequences, orderedEquals(<int>[...sequences]..sort()));
      expect(sequences.toSet(), hasLength(sequences.length));
      expect(
        timeline.where((event) => event.type == 'turn.completed'),
        hasLength(2),
      );
      expect(
        timeline.where((event) => event.type == 'userQuestion.answered'),
        hasLength(1),
      );
      expect(
        timeline.where((event) => event.type == 'approval.resolved'),
        hasLength(1),
      );
    },
    tags: const <String>[
      'ui_journey__conversation_adversity__e2e',
    ],
  );
}

Finder _patchApproval() => find.byWidgetPredicate(
  (widget) =>
      widget is ApprovalCard &&
      (widget.interaction?.approval ?? widget.approval)?.toolCallId ==
          'adversity-patch',
  description: 'approval for the adversity patch',
);

Future<void> _pumpConversation(
  WidgetTester tester,
  RealDaemonFixture fixture,
  String worktreeId,
  String worktreeLabel,
) async {
  await tester.pumpWidget(TinestApp(services: fixture.services));
  await pumpUntil(tester, find.text('Adversity Workspace'));
  // The catalog can render behind the startup transition before that layer
  // stops absorbing pointers on a slower Debug runner. Text presence alone is
  // therefore not sufficient evidence that navigation is interactive.
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
  final conversation = find.text('Adversity conversation').hitTestable();
  await pumpUntil(tester, conversation);
  await tester.tap(conversation.last);
  await pumpUntil(
    tester,
    find.byKey(const ValueKey<String>('session-composer-input')),
  );
}

Future<void> _remountConversation(
  WidgetTester tester,
  RealDaemonFixture fixture,
  String worktreeId,
  String worktreeLabel,
) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();
  await _pumpConversation(tester, fixture, worktreeId, worktreeLabel);
}

Future<void> _submit(
  WidgetTester tester,
  ValueKey<String> composerKey,
  ValueKey<String> sendKey,
  String prompt,
) async {
  final composer = find.byKey(composerKey);
  final input = find.descendant(
    of: composer,
    matching: find.byType(EditableText),
  );
  await tester.tap(input);
  await tester.enterText(composer, prompt);
  await tester.pump();
  await pumpUntilCondition(
    tester,
    () =>
        find.byKey(sendKey).evaluate().isNotEmpty &&
        tester.widget<TRIconButton>(find.byKey(sendKey)).onPressed != null,
    'the composer to accept $prompt',
  );
  await tester.tap(find.byKey(sendKey));
  await tester.pump();
}

void _expectTimelineTrailing(
  WidgetTester tester,
  Finder streamedContent, {
  required String phase,
}) {
  final scrollable = find
      .ancestor(of: streamedContent, matching: find.byType(Scrollable))
      .first;
  final position = tester.state<ScrollableState>(scrollable).position;
  expect(
    position.extentAfter,
    closeTo(0, 0.01),
    reason: 'conversation timeline after $phase',
  );
}

Future<void> _waitForProviderStart(
  WidgetTester tester,
  _AdversityProvider provider,
  TinestApi client,
  String sessionId,
  String worktreeId,
) async {
  try {
    await pumpUntilCondition(
      tester,
      () async {
        if (provider.firstTurnStarted.isCompleted) return true;
        final current = (await client.sessions.listSessions(
          worktreeId: worktreeId,
        )).singleWhere((candidate) => candidate.id == sessionId);
        if (current.status == SessionStatus.failed) {
          throw TestFailure(
            'The first adversity turn failed before reaching the provider: '
            '${current.lastError ?? 'unknown error'}.',
          );
        }
        return false;
      },
      'the adversity provider to receive the first turn',
    );
  } on TestFailure catch (error) {
    final session = (await client.sessions.listSessions(
      worktreeId: worktreeId,
    )).singleWhere((candidate) => candidate.id == sessionId);
    final timeline = await client.sessions.subscribeTimeline(sessionId);
    final events = timeline
        .map((event) => '${event.sequence}:${event.type}:${event.data}')
        .join(', ');
    throw TestFailure(
      '$error Session status: ${session.status.name}; '
      'lastError: ${session.lastError}; '
      'timeline: [$events].',
    );
  }
}

final class _AdversityCatalogMetadataSource
    implements ProviderCatalogMetadataSource {
  const _AdversityCatalogMetadataSource();

  @override
  Future<Map<String, List<ProviderCatalogMetadata>>> fetch(
    Set<String> providerIds,
  ) async => <String, List<ProviderCatalogMetadata>>{
    if (providerIds.contains('openai'))
      'openai': const <ProviderCatalogMetadata>[
        ProviderCatalogMetadata(
          id: 'gpt-5.6-sol',
          label: 'Adversity model',
          capabilities: ModelCapabilitiesDto(
            streaming: CapabilitySupport.supported,
            toolCalling: CapabilitySupport.supported,
            functionTools: CapabilitySupport.supported,
            freeformTools: CapabilitySupport.supported,
            deferredTools: CapabilitySupport.supported,
            source: CapabilitySource.refreshed,
          ),
        ),
      ],
  };

  @override
  Future<void> close() async {}
}

final class _AdversityProvider implements ModelGateway {
  final Completer<void> firstTurnStarted = Completer<void>();
  final Completer<void> releaseFirstTurn = Completer<void>();
  final Completer<void> secondStreamChunkStarted = Completer<void>();
  final Completer<void> releaseSecondStreamChunk = Completer<void>();
  final Completer<void> thirdStreamChunkStarted = Completer<void>();
  final Completer<void> releaseThirdStreamChunk = Completer<void>();

  @override
  String get id => 'conversation-adversity';

  @override
  Stream<ModelEvent> stream(
    ModelRequest request,
    CancellationToken cancellation,
  ) async* {
    cancellation.throwIfCancelled();
    final latestUser = request.history.whereType<UserConversationItem>().last;
    if (latestUser.text == 'Stream first') {
      yield const ModelReasoningDelta('첫 번째 추론 청크');
      yield ModelTextDelta(_firstStreamChunk);
      if (!firstTurnStarted.isCompleted) firstTurnStarted.complete();
      await releaseFirstTurn.future;
      cancellation.throwIfCancelled();
      yield const ModelReasoningDelta('두 번째 추론 청크');
      yield ModelTextDelta(_secondStreamChunk);
      if (!secondStreamChunkStarted.isCompleted) {
        secondStreamChunkStarted.complete();
      }
      await releaseSecondStreamChunk.future;
      cancellation.throwIfCancelled();
      yield ModelTextDelta(_thirdStreamChunk);
      if (!thirdStreamChunkStarted.isCompleted) {
        thirdStreamChunkStarted.complete();
      }
      await releaseThirdStreamChunk.future;
      cancellation.throwIfCancelled();
      yield ModelResponseCompleted(
        assistant: AssistantConversationItem(
          text: '$_firstStreamChunk$_secondStreamChunk$_thirdStreamChunk',
        ),
      );
      return;
    }

    final questionResult = request.history
        .whereType<ToolResultConversationItem>()
        .where((item) => item.callId == 'adversity-question')
        .firstOrNull;
    if (questionResult == null) {
      const arguments = <String, dynamic>{
        'questions': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'store',
            'header': 'Storage',
            'question': 'Which store should the cache use?',
            'options': <Map<String, dynamic>>[
              <String, dynamic>{
                'label': 'SQLite',
                'description': 'Durable and local.',
              },
              <String, dynamic>{
                'label': 'Memory',
                'description': 'Ephemeral and fast.',
              },
            ],
          },
        ],
      };
      yield const ModelFunctionCall(
        callId: 'adversity-question',
        name: 'request_user_input',
        arguments: arguments,
      );
      yield const ModelResponseCompleted(
        assistant: AssistantConversationItem(
          text: '',
          toolCalls: <ConversationToolCall>[
            ConversationToolCall.function(
              callId: 'adversity-question',
              name: 'request_user_input',
              arguments: arguments,
            ),
          ],
        ),
      );
      return;
    }

    final patchResult = request.history
        .whereType<ToolResultConversationItem>()
        .where((item) => item.callId == 'adversity-patch')
        .firstOrNull;
    if (patchResult == null) {
      const patch =
          '*** Begin Patch\n'
          '*** Add File: adversity.txt\n'
          '+restored\n'
          '*** End Patch';
      yield const ModelFreeformCall(
        callId: 'adversity-patch',
        name: 'apply_patch',
        rawInput: patch,
      );
      yield const ModelResponseCompleted(
        assistant: AssistantConversationItem(
          text: '',
          toolCalls: <ConversationToolCall>[
            ConversationToolCall.freeform(
              callId: 'adversity-patch',
              name: 'apply_patch',
              input: patch,
            ),
          ],
        ),
      );
      return;
    }

    yield const ModelTextDelta('복합 대화 완료');
    yield const ModelResponseCompleted(
      assistant: AssistantConversationItem(text: '복합 대화 완료'),
    );
  }
}
