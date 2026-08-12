import 'dart:async';
import 'dart:io';

import 'package:agent/agent.dart';
import 'package:app/testing/app/tinest_app.dart';
import 'package:app/testing/features/conversation/presentation/chat_approval_card.dart';
import 'package:client/client.dart';
import 'package:daemon/daemon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:protocol/protocol.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

import 'support/pump_until.dart';
import 'support/real_daemon_fixture.dart';

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
        modelDiscovery: const _AdversityModelDiscovery(),
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
      final connection = await client.providers.createCustomProvider(
        'adversity',
        const CustomProviderConfigDto(
          name: 'Adversity provider',
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
      final SessionDto session;
      try {
        session = await client.sessions.createSession(
          id: 'adversity-session',
          worktreeId: 'adversity-checkout',
          title: 'Adversity conversation',
          agentDefinitionId: 'tinest',
          model: SessionModelSelectionDto(modelId: model.id),
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
      await provider.firstTurnStarted.future.timeout(
        const Duration(minutes: 1),
      );
      await pumpUntil(
        tester,
        find.textContaining('첫 번째 청크', findRichText: true),
      );

      await _submit(tester, composerKey, sendKey, 'Ask then patch');
      await pumpUntil(
        tester,
        find.byKey(const ValueKey<String>('queued-turn-0')),
      );
      expect(find.text('Ask then patch'), findsWidgets);
      provider.releaseFirstTurn.complete();

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

final class _AdversityModelDiscovery implements ProviderModelDiscovery {
  const _AdversityModelDiscovery();

  @override
  Future<List<String>> fetchModelIds(
    ProviderEndpoint endpoint,
    ProviderCredential? credential,
  ) async => const <String>['test-model'];
}

final class _AdversityProvider implements ModelProvider {
  final Completer<void> firstTurnStarted = Completer<void>();
  final Completer<void> releaseFirstTurn = Completer<void>();

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
      yield const ModelTextDelta('첫 번째 청크');
      if (!firstTurnStarted.isCompleted) firstTurnStarted.complete();
      await releaseFirstTurn.future;
      cancellation.throwIfCancelled();
      yield const ModelReasoningDelta('두 번째 추론 청크');
      yield const ModelTextDelta(' 스트림 완료');
      yield const ModelResponseCompleted(
        assistant: AssistantConversationItem(text: '첫 번째 청크 스트림 완료'),
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
