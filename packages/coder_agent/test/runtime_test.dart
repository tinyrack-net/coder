import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:coder_agent/coder_agent.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:test/test.dart';

void main() {
  test('cancellation token notifies once and rejects later work', () {
    final token = CancellationToken();
    var notifications = 0;
    token.onCancel(() => notifications += 1);
    expect(token.isCancelled, isFalse);
    token
      ..cancel()
      ..cancel()
      ..onCancel(() => notifications += 1);

    expect(token.isCancelled, isTrue);
    expect(notifications, 2);
    expect(token.throwIfCancelled, throwsA(isA<AgentCancelledException>()));
  });

  test('canonical conversation items round-trip and reject unknown types', () {
    const call = ConversationToolCall(
      callId: 'call',
      name: 'echo',
      arguments: <String, dynamic>{'value': 'hello'},
    );
    const items = <ConversationItem>[
      UserConversationItem('hello'),
      AssistantConversationItem(
        text: 'thinking',
        toolCalls: <ConversationToolCall>[call],
        opaqueItems: <Map<String, dynamic>>[
          <String, dynamic>{'type': 'reasoning', 'encrypted': 'opaque'},
        ],
      ),
      ToolResultConversationItem(
        callId: 'call',
        output: 'hello',
        isError: true,
      ),
    ];

    final decoded = items
        .map((item) => ConversationItem.fromJson(item.toJson()))
        .toList(growable: false);
    expect((decoded[0] as UserConversationItem).text, 'hello');
    final assistant = decoded[1] as AssistantConversationItem;
    expect(assistant.toolCalls.single.toJson(), call.toJson());
    expect(assistant.opaqueItems.single['encrypted'], 'opaque');
    expect((decoded[2] as ToolResultConversationItem).isError, isTrue);
    expect(
      () => ConversationItem.fromJson(const <String, dynamic>{
        'type': 'future',
      }),
      throwsA(isA<FormatException>()),
    );
  });

  test('permission policy covers every mode and tool risk', () {
    expect(
      const DefaultApprovalPolicy(
        PermissionMode.ask,
      ).evaluateRisk(ToolRisk.read),
      ApprovalEvaluation.allow,
    );
    expect(
      const DefaultApprovalPolicy(
        PermissionMode.readOnly,
      ).evaluateRisk(ToolRisk.write),
      ApprovalEvaluation.deny,
    );
    expect(
      const DefaultApprovalPolicy(
        PermissionMode.workspaceWrite,
      ).evaluateRisk(ToolRisk.write),
      ApprovalEvaluation.allow,
    );
    expect(
      const DefaultApprovalPolicy(
        PermissionMode.workspaceWrite,
      ).evaluateRisk(ToolRisk.command),
      ApprovalEvaluation.ask,
    );
    expect(
      const DefaultApprovalPolicy(
        PermissionMode.workspaceWrite,
      ).evaluateRisk(ToolRisk.dangerous),
      ApprovalEvaluation.ask,
    );
    expect(
      const DefaultApprovalPolicy(
        PermissionMode.ask,
      ).evaluateRisk(ToolRisk.dangerous),
      ApprovalEvaluation.ask,
    );
    expect(
      const DefaultApprovalPolicy(
        PermissionMode.readOnly,
      ).evaluateRisk(ToolRisk.dangerous),
      ApprovalEvaluation.deny,
    );
  });

  test('queued turn input is drained before every model request', () async {
    final provider = _SnapshottingProvider(<List<ModelEvent>>[
      _toolResponseWith('echo', <String, dynamic>{'value': 'one'}),
      _textResponse('done'),
    ]);
    final source = _QueueInputSource()
      ..queue.add(const UserConversationItem('mail before the turn'));
    final harness = _RunnerHarness(
      provider,
      tools: <AgentTool>[
        _EnqueueOnExecuteTool(
          source,
          const UserConversationItem('mail during the tool round'),
        ),
      ],
      pendingTurnInput: source,
    );

    await harness.runner.startTurn(_request(), CancellationToken());

    // The pre-turn mail rides the first request; mail queued while the tool
    // ran is folded into the boundary before the second request.
    final first = provider.userTextsPerRequest[0];
    expect(first, contains('mail before the turn'));
    expect(first, isNot(contains('mail during the tool round')));
    expect(
      provider.userTextsPerRequest[1],
      contains('mail during the tool round'),
    );

    expect(
      harness.events.where((type) => type == 'agent.message.delivered').length,
      2,
    );
    expect(
      harness.items.whereType<UserConversationItem>().map((item) => item.text),
      containsAll(<String>[
        'mail before the turn',
        'mail during the tool round',
      ]),
    );
    expect(source.drains, greaterThanOrEqualTo(2));
  });

  test('input queued after the final response stays queued', () async {
    final provider = _FakeProvider(<List<ModelEvent>>[_textResponse('done')]);
    final source = _QueueInputSource();
    final harness = _RunnerHarness(provider, pendingTurnInput: source);

    await harness.runner.startTurn(_request(), CancellationToken());
    source.queue.add(const UserConversationItem('late mail'));

    expect(harness.events, isNot(contains('agent.message.delivered')));
    expect(
      harness.items.whereType<UserConversationItem>().map((item) => item.text),
      isNot(contains('late mail')),
    );
    expect(source.queue, hasLength(1));
  });

  test('an empty input source injects nothing and emits no event', () async {
    final provider = _FakeProvider(<List<ModelEvent>>[_textResponse('done')]);
    final harness = _RunnerHarness(
      provider,
      pendingTurnInput: _QueueInputSource(),
    );

    await harness.runner.startTurn(_request(), CancellationToken());

    expect(harness.events, isNot(contains('agent.message.delivered')));
  });

  test('the runner forwards each tool strict-schema opt-out', () async {
    final provider = _FakeProvider(<List<ModelEvent>>[_textResponse('done')]);
    final harness = _RunnerHarness(
      provider,
      tools: <AgentTool>[_EchoTool(), _LooseTool()],
    );

    await harness.runner.startTurn(_request(), CancellationToken());

    final tools = provider.requests.single.tools;
    expect(
      tools.firstWhere((tool) => tool.name == 'echo').strict,
      isTrue,
    );
    expect(
      tools.firstWhere((tool) => tool.name == 'loose').strict,
      isFalse,
    );
  });

  test('agent executes an approved tool loop and completes', () async {
    final provider = _FakeProvider(<List<ModelEvent>>[
      _toolResponse('echo'),
      _textResponse('done'),
    ]);
    final harness = _RunnerHarness(
      provider,
      tools: <AgentTool>[_EchoTool()],
    );

    final result = await harness.runner.startTurn(
      _request(permissionMode: PermissionMode.ask),
      CancellationToken(),
    );

    expect(result.toolRounds, 1);
    expect(result.conversationItems, hasLength(4));
    expect(
      harness.events,
      containsAllInOrder(<String>[
        'user.message',
        'tool.requested',
        'tool.completed',
        'assistant.delta',
        'turn.completed',
      ]),
    );
    expect(
      harness.statuses,
      <SessionStatus>[
        SessionStatus.running,
        SessionStatus.waitingForApproval,
        SessionStatus.running,
        SessionStatus.idle,
      ],
    );
    expect(provider.requests.first.tools.single.name, 'echo');
    expect(
      provider.requests.first.instructions,
      contains(Directory.current.path),
    );
    final customProvider = _FakeProvider(<List<ModelEvent>>[
      _textResponse('done'),
    ]);
    final customPromptHarness = _RunnerHarness(customProvider);
    await customPromptHarness.runner.startTurn(
      _request(customSystemPrompt: 'Review every security boundary.'),
      CancellationToken(),
    );
    expect(
      customProvider.requests.single.instructions,
      allOf(
        contains('Approval decisions are enforced by the host'),
        contains('Review every security boundary.'),
      ),
    );
  });

  test('plan mode adds planning instructions to the turn', () async {
    final planProvider = _FakeProvider(<List<ModelEvent>>[_textResponse('ok')]);
    await _RunnerHarness(planProvider).runner.startTurn(
      _request(
        sessionMode: SessionMode.plan,
        customSystemPrompt: 'Review every security boundary.',
      ),
      CancellationToken(),
    );
    expect(
      planProvider.requests.single.instructions,
      allOf(
        contains('You are in Plan Mode'),
        contains('update_plan'),
        isNot(contains('proposed_plan')),
        contains('Approval decisions are enforced by the host'),
        contains('Review every security boundary.'),
      ),
    );

    final normalProvider = _FakeProvider(<List<ModelEvent>>[
      _textResponse('ok'),
    ]);
    await _RunnerHarness(normalProvider).runner.startTurn(
      _request(),
      CancellationToken(),
    );
    expect(
      normalProvider.requests.single.instructions,
      isNot(contains('Plan Mode')),
    );
  });

  test(
    'the skill prompt points at the tools instead of listing every skill',
    () async {
      final provider = _FakeProvider(<List<ModelEvent>>[_textResponse('ok')]);
      await _RunnerHarness(provider).runner.startTurn(
        _request(
          customSystemPrompt: 'Review every security boundary.',
          skills: const <SkillSummary>[
            SkillSummary(name: 'commit', description: 'Writes commits.'),
            SkillSummary(name: 'dataviz', description: 'Draws charts.'),
          ],
        ),
        CancellationToken(),
      );

      final instructions = provider.requests.single.instructions;
      expect(instructions, contains('## Available skills'));
      // The count is one number whatever the catalog size, and it is what
      // tells the agent whether looking is worth a call.
      expect(instructions, contains('2 skills are available'));
      expect(instructions, contains(listSkillsToolName));
      // No per-skill line survives, which is the whole point: the prompt cost
      // no longer grows with the catalog.
      expect(instructions, isNot(contains('Writes commits.')));
      expect(instructions, isNot(contains('Draws charts.')));
      expect(
        instructions.indexOf('## Available skills'),
        lessThan(instructions.indexOf('Review every security boundary.')),
      );

      final single = _FakeProvider(<List<ModelEvent>>[_textResponse('ok')]);
      await _RunnerHarness(single).runner.startTurn(
        _request(
          skills: const <SkillSummary>[
            SkillSummary(name: 'commit', description: 'Writes commits.'),
          ],
        ),
        CancellationToken(),
      );
      expect(
        single.requests.single.instructions,
        contains('1 skill is available'),
      );
    },
    tags: const <String>['feature_test__skill_invocation__unit'],
  );

  test(
    'a turn without skills carries no catalog block',
    () async {
      final provider = _FakeProvider(<List<ModelEvent>>[_textResponse('ok')]);
      await _RunnerHarness(provider).runner.startTurn(
        _request(),
        CancellationToken(),
      );
      expect(
        provider.requests.single.instructions,
        isNot(contains('Available skills')),
      );
    },
    tags: const <String>['feature_test__skill_invocation__unit'],
  );

  test('read-only and denied approvals produce error tool results', () async {
    for (final scenario
        in <
          ({
            PermissionMode mode,
            ApprovalDecision decision,
          })
        >[
          (mode: PermissionMode.readOnly, decision: ApprovalDecision.approved),
          (mode: PermissionMode.ask, decision: ApprovalDecision.denied),
        ]) {
      final harness = _RunnerHarness(
        _FakeProvider(<List<ModelEvent>>[
          _toolResponse('echo'),
          _textResponse('done'),
        ]),
        tools: <AgentTool>[_EchoTool()],
        approvals: _Approval(scenario.decision),
      );
      final result = await harness.runner.startTurn(
        _request(permissionMode: scenario.mode),
        CancellationToken(),
      );
      final toolResult = result.conversationItems
          .whereType<ToolResultConversationItem>()
          .single;
      expect(toolResult.isError, isTrue);
      expect(toolResult.output, contains('denied'));
      expect(harness.events, contains('tool.denied'));
    }
  });

  test(
    'a tool can put an image into the model context',
    tags: const <String>['feature_test__tool_image_context__unit'],
    () async {
      final provider = _FakeProvider(<List<ModelEvent>>[
        _toolResponse('image'),
        _textResponse('I can see it.'),
      ]);
      final harness = _RunnerHarness(
        provider,
        tools: <AgentTool>[_ContextImageTool()],
      );

      final result = await harness.runner.startTurn(
        _request(),
        CancellationToken(),
      );

      // The image rides a follow-up user item: neither Responses nor Chat
      // Completions accepts image content inside a tool result.
      final injected = provider.requests.last.history
          .whereType<UserConversationItem>()
          .last;
      expect(injected.text, isEmpty);
      expect(injected.attachments.single.id, 'screenshot');
      expect(injected.attachments.single.imageDetail, 'high');

      // The same item is persisted and replayed, so a later turn still sees it.
      expect(
        result.conversationItems
            .whereType<UserConversationItem>()
            .last
            .attachments,
        hasLength(1),
      );
      expect(
        harness.items.whereType<UserConversationItem>().last.attachments,
        hasLength(1),
      );
      // It reuses the attachment event rather than inventing a new wire type.
      expect(harness.events, contains('assistant.attachment'));
      expect(harness.events, isNot(contains('user.message.injected')));
    },
  );

  test(
    'a context reset keeps the round it happened in well formed',
    tags: const <String>['feature_test__tool_context_budget__unit'],
    () async {
      // Both provider APIs reject a function_call_output whose function_call
      // is missing, so the reset has to keep the assistant item that issued
      // new_context together with every tool result of that same round.
      final provider = _FakeProvider(<List<ModelEvent>>[
        _twoToolResponse('new_context', 'echo'),
        _textResponse('done'),
      ]);
      final resets = <List<ConversationItem>>[];
      final harness = _RunnerHarness(
        provider,
        tools: <AgentTool>[_EchoTool(), _NewContextTool()],
        contextResets: resets.add,
      );

      await harness.runner.startTurn(
        _request(
          history: const <ConversationItem>[
            UserConversationItem('an old turn nobody needs'),
          ],
        ),
        CancellationToken(),
      );

      // The stale history is gone from the request that follows the reset.
      final after = provider.requests.last.history;
      expect(
        after.whereType<UserConversationItem>().map((item) => item.text),
        isNot(contains('an old turn nobody needs')),
      );

      // Every function_call in what survives still has its output.
      final calls = after
          .whereType<AssistantConversationItem>()
          .expand((item) => item.toolCalls)
          .map((call) => call.callId)
          .toSet();
      final outputs = after
          .whereType<ToolResultConversationItem>()
          .map((item) => item.callId)
          .toSet();
      expect(calls, isNotEmpty);
      expect(outputs, calls);

      // The coordinator is handed exactly what the live input kept, so the
      // database and the in-memory conversation cannot drift apart.
      expect(resets, hasLength(1));
      expect(
        resets.single.whereType<ToolResultConversationItem>().length,
        2,
      );
      expect(harness.events, contains('context.reset'));
    },
  );

  test(
    'a context reset happens once the whole round is done',
    tags: const <String>['feature_test__tool_context_budget__unit'],
    () async {
      // Resetting inside the loop would strand the tool call that follows.
      final provider = _FakeProvider(<List<ModelEvent>>[
        _twoToolResponse('new_context', 'echo'),
        _textResponse('done'),
      ]);
      final harness = _RunnerHarness(
        provider,
        tools: <AgentTool>[_EchoTool(), _NewContextTool()],
        contextResets: (_) {},
      );

      final result = await harness.runner.startTurn(
        _request(),
        CancellationToken(),
      );

      // Both tools ran, in order, before anything was discarded.
      expect(
        result.conversationItems.whereType<ToolResultConversationItem>().map(
          (item) => item.callId,
        ),
        <String>['call-new_context', 'call-echo'],
      );
    },
  );

  test(
    'the context budget reaches a tool from the turn request',
    tags: const <String>['feature_test__tool_context_budget__unit'],
    () async {
      final probe = _ContextProbeTool();
      final harness = _RunnerHarness(
        _FakeProvider(<List<ModelEvent>>[
          _toolResponse('probe'),
          _textResponse('done'),
        ]),
        tools: <AgentTool>[probe],
      );

      await harness.runner.startTurn(
        _request(contextWindowTokens: 200000),
        CancellationToken(),
      );

      expect(probe.seenWindow, 200000);
      // Usage from the round that requested the call is already visible.
      expect(probe.seenUsage.inputTokens, 10);
    },
  );

  test(
    'a deferred tool is withheld until a search surfaces it',
    tags: const <String>['feature_test__tool_search_deferred__unit'],
    () async {
      final provider = _FakeProvider(<List<ModelEvent>>[
        _toolResponseWith('tool_search', <String, dynamic>{
          'query': 'echo the value',
          'limit': null,
        }),
        _textResponse('done'),
      ]);
      final harness = _RunnerHarness(
        provider,
        tools: <AgentTool>[_EchoTool(), _DeferredTool()],
      );

      await harness.runner.startTurn(_request(), CancellationToken());

      // Round one advertises the always-on tool and the search tool, but not
      // the deferred one.
      final first = provider.requests.first.tools.map((tool) => tool.name);
      expect(first, containsAll(<String>['echo', 'tool_search']));
      expect(first, isNot(contains('hidden')));

      // Round two advertises what the search surfaced.
      final second = provider.requests.last.tools.map((tool) => tool.name);
      expect(second, contains('hidden'));

      expect(harness.events, contains('tools.deferred'));
    },
  );

  test(
    'a deferred tool called without searching still dispatches',
    tags: const <String>['feature_test__tool_search_deferred__unit'],
    () async {
      final harness = _RunnerHarness(
        _FakeProvider(<List<ModelEvent>>[
          _toolResponse('hidden'),
          _textResponse('done'),
        ]),
        tools: <AgentTool>[_DeferredTool()],
      );

      final result = await harness.runner.startTurn(
        _request(),
        CancellationToken(),
      );

      // Withholding changes advertisement, never dispatchability.
      final toolResult = result.conversationItems
          .whereType<ToolResultConversationItem>()
          .single;
      expect(toolResult.isError, isFalse);
      expect(toolResult.output, 'hello');
    },
  );

  test(
    'a session that already searched keeps its tools advertised',
    tags: const <String>['feature_test__tool_search_deferred__unit'],
    () async {
      // The specs live in history from the previous turn, but this provider
      // sends a tools array per request, so the runner has to restore them.
      final provider = _FakeProvider(<List<ModelEvent>>[
        _textResponse('done'),
      ]);
      final harness = _RunnerHarness(
        provider,
        tools: <AgentTool>[_DeferredTool()],
      );

      await harness.runner.startTurn(
        _request(
          history: <ConversationItem>[
            const AssistantConversationItem(
              text: '',
              toolCalls: <ConversationToolCall>[
                ConversationToolCall(
                  callId: 'call-search',
                  name: 'tool_search',
                  arguments: <String, dynamic>{'query': 'hidden'},
                ),
              ],
            ),
            const ToolResultConversationItem(
              callId: 'call-search',
              output: '{"tools":[{"name":"hidden"}],"remaining":0}',
            ),
          ],
        ),
        CancellationToken(),
      );

      expect(
        provider.requests.single.tools.map((tool) => tool.name),
        contains('hidden'),
      );
    },
  );

  test(
    'nothing deferred means no search tool and no notice',
    tags: const <String>['feature_test__tool_search_deferred__unit'],
    () async {
      final provider = _FakeProvider(<List<ModelEvent>>[_textResponse('ok')]);
      final harness = _RunnerHarness(provider, tools: <AgentTool>[_EchoTool()]);

      await harness.runner.startTurn(_request(), CancellationToken());

      expect(
        provider.requests.single.tools.map((tool) => tool.name),
        <String>['echo'],
      );
      expect(harness.events, isNot(contains('tools.deferred')));
    },
  );

  test(
    'unknown and failing tools are persisted without aborting the turn',
    () async {
      final unknown = _RunnerHarness(
        _FakeProvider(<List<ModelEvent>>[
          _toolResponse('missing'),
          _textResponse('done'),
        ]),
      );
      final unknownResult = await unknown.runner.startTurn(
        _request(),
        CancellationToken(),
      );
      expect(
        unknownResult.conversationItems
            .whereType<ToolResultConversationItem>()
            .single
            .output,
        contains('Unknown tool'),
      );

      final failing = _RunnerHarness(
        _FakeProvider(<List<ModelEvent>>[
          _toolResponse('failing'),
          _textResponse('done'),
        ]),
        tools: <AgentTool>[_FailingTool()],
      );
      final failedResult = await failing.runner.startTurn(
        _request(),
        CancellationToken(),
      );
      expect(
        failedResult.conversationItems
            .whereType<ToolResultConversationItem>()
            .single
            .isError,
        isTrue,
      );
      expect(failing.events, contains('tool.failed'));
    },
  );

  test('missing completion and tool round limit fail the turn', () async {
    final missingCompletion = _RunnerHarness(
      _FakeProvider(<List<ModelEvent>>[
        <ModelEvent>[const ModelTextDelta('partial')],
      ]),
    );
    await expectLater(
      missingCompletion.runner.startTurn(_request(), CancellationToken()),
      throwsA(isA<StateError>()),
    );
    expect(missingCompletion.statuses.last, SessionStatus.failed);
    expect(missingCompletion.events, contains('turn.failed'));

    final maxRounds = _RunnerHarness(
      _FakeProvider(<List<ModelEvent>>[_toolResponse('echo')]),
      tools: <AgentTool>[_EchoTool()],
    );
    await expectLater(
      maxRounds.runner.startTurn(
        _request(maxToolRounds: 0),
        CancellationToken(),
      ),
      throwsA(isA<StateError>()),
    );
    expect(maxRounds.statusErrors.single, contains('Tool round limit'));
  });

  test(
    'cancellation before and during a tool returns the agent to idle',
    () async {
      final before = _RunnerHarness(_FakeProvider(const <List<ModelEvent>>[]));
      final token = CancellationToken()..cancel();
      await expectLater(
        before.runner.startTurn(_request(), token),
        throwsA(isA<AgentCancelledException>()),
      );
      expect(before.events.last, 'turn.cancelled');
      expect(before.statuses.last, SessionStatus.idle);

      final during = _RunnerHarness(
        _FakeProvider(<List<ModelEvent>>[_toolResponse('cancel')]),
        tools: <AgentTool>[_CancellingTool()],
      );
      await expectLater(
        during.runner.startTurn(_request(), CancellationToken()),
        throwsA(isA<AgentCancelledException>()),
      );
      expect(during.events.last, 'turn.cancelled');
    },
  );

  test('model and tool value objects expose their complete contract', () async {
    const definition = ModelToolDefinition(
      name: 'echo',
      description: 'Echo',
      parameters: <String, dynamic>{'type': 'object'},
    );
    expect(definition.strict, isTrue);
    expect(
      const ModelToolDefinition(
        name: 'external',
        description: 'External',
        parameters: <String, dynamic>{'type': 'object'},
        strict: false,
      ).strict,
      isFalse,
    );
    const request = ModelRequest(
      model: 'model',
      reasoningEffort: 'high',
      instructions: 'instructions',
      history: <ConversationItem>[],
      tools: <ModelToolDefinition>[definition],
      safetyIdentifier: 'safe',
      forceToolName: 'echo',
    );
    const invocation = ToolInvocation(
      callId: 'call',
      name: 'echo',
      arguments: <String, dynamic>{},
      risk: ToolRisk.read,
      workspaceRoot: '/workspace',
      preview: 'preview',
    );
    const result = ToolResult(output: 'done', isError: true);
    final tool = _EchoTool();

    expect(request.model, 'model');
    expect(request.reasoningEffort, 'high');
    expect(request.instructions, 'instructions');
    expect(request.history, isEmpty);
    expect(request.tools.single.description, 'Echo');
    expect(request.safetyIdentifier, 'safe');
    expect(request.forceToolName, 'echo');
    expect(invocation.callId, 'call');
    expect(invocation.name, 'echo');
    expect(invocation.arguments, isEmpty);
    expect(invocation.risk, ToolRisk.read);
    expect(invocation.workspaceRoot, '/workspace');
    expect(invocation.preview, 'preview');
    expect(result.output, 'done');
    expect(result.isError, isTrue);
    expect(tool.strict, isTrue);
    expect(
      await tool.preview(
        const <String, dynamic>{},
        ToolExecutionContext(
          workspaceRoot: Directory.current.path,
          cancellation: CancellationToken(),
        ),
      ),
      isNull,
    );
  });
}

AgentRunRequest _request({
  PermissionMode permissionMode = PermissionMode.workspaceWrite,
  int maxToolRounds = 64,
  SessionMode sessionMode = SessionMode.normal,
  String? customSystemPrompt,
  List<SkillSummary> skills = const <SkillSummary>[],
  List<ConversationItem> history = const <ConversationItem>[
    UserConversationItem('history'),
  ],
  int? contextWindowTokens,
}) => AgentRunRequest(
  contextWindowTokens: contextWindowTokens,
  sessionId: 'agent-1',
  turnId: 'turn-1',
  workspaceRoot: Directory.current.path,
  prompt: 'test',
  model: 'test-model',
  permissionMode: permissionMode,
  history: history,
  safetyIdentifier: 'safe-id',
  maxToolRounds: maxToolRounds,
  sessionMode: sessionMode,
  customSystemPrompt: customSystemPrompt,
  skills: skills,
);

List<ModelEvent> _toolResponse(String name) => <ModelEvent>[
  ModelFunctionCall(
    callId: 'call-$name',
    name: name,
    arguments: const <String, dynamic>{'value': 'hello'},
  ),
  ModelResponseCompleted(
    assistant: AssistantConversationItem(
      text: '',
      toolCalls: <ConversationToolCall>[
        ConversationToolCall(
          callId: 'call-$name',
          name: name,
          arguments: const <String, dynamic>{'value': 'hello'},
        ),
      ],
    ),
    usage: const ModelUsage(inputTokens: 10, totalTokens: 10),
  ),
];

List<ModelEvent> _twoToolResponse(String first, String second) => <ModelEvent>[
  ModelFunctionCall(
    callId: 'call-$first',
    name: first,
    arguments: const <String, dynamic>{'value': 'hello'},
  ),
  ModelFunctionCall(
    callId: 'call-$second',
    name: second,
    arguments: const <String, dynamic>{'value': 'hello'},
  ),
  ModelResponseCompleted(
    assistant: AssistantConversationItem(
      text: '',
      toolCalls: <ConversationToolCall>[
        ConversationToolCall(
          callId: 'call-$first',
          name: first,
          arguments: const <String, dynamic>{'value': 'hello'},
        ),
        ConversationToolCall(
          callId: 'call-$second',
          name: second,
          arguments: const <String, dynamic>{'value': 'hello'},
        ),
      ],
    ),
    usage: const ModelUsage(inputTokens: 10, totalTokens: 10),
  ),
];

List<ModelEvent> _toolResponseWith(
  String name,
  Map<String, dynamic> arguments,
) => <ModelEvent>[
  ModelFunctionCall(callId: 'call-$name', name: name, arguments: arguments),
  ModelResponseCompleted(
    assistant: AssistantConversationItem(
      text: '',
      toolCalls: <ConversationToolCall>[
        ConversationToolCall(
          callId: 'call-$name',
          name: name,
          arguments: arguments,
        ),
      ],
    ),
  ),
];

List<ModelEvent> _textResponse(String text) => <ModelEvent>[
  ModelTextDelta(text),
  ModelResponseCompleted(assistant: AssistantConversationItem(text: text)),
];

final class _RunnerHarness {
  _RunnerHarness(
    ModelProvider provider, {
    Iterable<AgentTool> tools = const <AgentTool>[],
    ApprovalCoordinator approvals = const _Approval(
      ApprovalDecision.approved,
    ),
    void Function(List<ConversationItem> retain)? contextResets,
    TurnInputSource? pendingTurnInput,
  }) {
    runner = AgentRunner(
      provider: provider,
      tools: tools,
      approvals: approvals,
      contextResets: contextResets == null
          ? null
          : _RecordingContextReset(contextResets),
      pendingTurnInput: pendingTurnInput,
      onEvent: (type, _) => events.add(type),
      onStatus: (status, {error}) {
        statuses.add(status);
        if (error != null) statusErrors.add(error);
      },
      onProviderItems: items.addAll,
    );
  }

  late AgentRunner runner;
  final List<String> events = <String>[];
  final List<SessionStatus> statuses = <SessionStatus>[];
  final List<String> statusErrors = <String>[];
  final List<ConversationItem> items = <ConversationItem>[];
}

final class _SnapshottingProvider extends _FakeProvider {
  _SnapshottingProvider(super.responses);

  /// User texts per request, copied because the runner mutates the live
  /// history list between rounds.
  final List<List<String>> userTextsPerRequest = <List<String>>[];

  @override
  Stream<ModelEvent> stream(
    ModelRequest request,
    CancellationToken cancellation,
  ) {
    userTextsPerRequest.add(
      request.history
          .whereType<UserConversationItem>()
          .map((item) => item.text)
          .toList(growable: false),
    );
    return super.stream(request, cancellation);
  }
}

final class _QueueInputSource implements TurnInputSource {
  final List<ConversationItem> queue = <ConversationItem>[];
  int drains = 0;

  @override
  Future<List<ConversationItem>> drainPending() async {
    drains += 1;
    final drained = List<ConversationItem>.unmodifiable(queue);
    queue.clear();
    return drained;
  }
}

final class _EnqueueOnExecuteTool extends _EchoTool {
  _EnqueueOnExecuteTool(this._source, this._item);

  final _QueueInputSource _source;
  final ConversationItem _item;

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolExecutionContext context,
  ) async {
    _source.queue.add(_item);
    return const ToolResult(output: '{"queued":true}');
  }
}

final class _RecordingContextReset implements ContextResetCoordinator {
  const _RecordingContextReset(this._onReset);

  final void Function(List<ConversationItem> retain) _onReset;

  @override
  Future<void> reset(List<ConversationItem> retain) async => _onReset(retain);
}

final class _FakeProvider implements ModelProvider {
  _FakeProvider(this.responses);

  final List<List<ModelEvent>> responses;
  final List<ModelRequest> requests = <ModelRequest>[];
  int index = 0;

  @override
  String get id => 'fake';

  @override
  Stream<ModelEvent> stream(
    ModelRequest request,
    CancellationToken cancellation,
  ) async* {
    requests.add(request);
    yield* Stream<ModelEvent>.fromIterable(responses[index++]);
  }
}

class _EchoTool extends AgentTool {
  @override
  String get name => 'echo';

  @override
  String get description => 'echo';

  @override
  ToolRisk get risk => ToolRisk.write;

  @override
  Map<String, dynamic> get strictJsonSchema => <String, dynamic>{
    'type': 'object',
    'properties': <String, dynamic>{
      'value': <String, dynamic>{'type': 'string'},
    },
    'required': <String>['value'],
    'additionalProperties': false,
  };

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolExecutionContext context,
  ) async => ToolResult(output: arguments['value'] as String);
}

final class _LooseTool extends _EchoTool {
  @override
  String get name => 'loose';

  @override
  bool get strict => false;
}

final class _ContextImageTool extends _EchoTool {
  @override
  String get name => 'image';

  @override
  ToolRisk get risk => ToolRisk.read;

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolExecutionContext context,
  ) async {
    final attachment = ConversationAttachment(
      id: 'screenshot',
      fileName: 'screenshot.png',
      mimeType: 'image/png',
      byteSize: 3,
      path: '/daemon/screenshot.png',
      bytes: Uint8List.fromList(<int>[1, 2, 3]),
      imageDetail: 'high',
    );
    return ToolResult(
      output: '{"attachmentId":"screenshot"}',
      attachments: <ConversationAttachment>[attachment],
      contextImages: <ConversationAttachment>[attachment],
    );
  }
}

final class _NewContextTool extends _EchoTool {
  @override
  String get name => 'new_context';

  @override
  ToolRisk get risk => ToolRisk.read;

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolExecutionContext context,
  ) async {
    context.requestContextReset();
    return const ToolResult(output: '{"started":true}');
  }
}

final class _ContextProbeTool extends _EchoTool {
  int? seenWindow;
  ModelUsage seenUsage = const ModelUsage();

  @override
  String get name => 'probe';

  @override
  ToolRisk get risk => ToolRisk.read;

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolExecutionContext context,
  ) async {
    seenWindow = context.contextWindowTokens;
    seenUsage = context.turnUsage;
    return const ToolResult(output: '{}');
  }
}

final class _DeferredTool extends _EchoTool {
  @override
  String get name => 'hidden';

  @override
  String get description => 'Echoes the value it is given.';

  @override
  ToolRisk get risk => ToolRisk.read;

  @override
  ToolExposure get exposure => ToolExposure.deferred;
}

final class _FailingTool extends _EchoTool {
  @override
  String get name => 'failing';

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolExecutionContext context,
  ) => throw const FormatException('bad arguments');
}

final class _CancellingTool extends _EchoTool {
  @override
  String get name => 'cancel';

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolExecutionContext context,
  ) {
    context.cancellation.cancel();
    context.cancellation.throwIfCancelled();
    throw StateError('unreachable');
  }
}

final class _Approval implements ApprovalCoordinator {
  const _Approval(this.decision);

  final ApprovalDecision decision;

  @override
  Future<ApprovalDecision> request(
    ToolInvocation invocation,
    CancellationToken cancellation,
  ) async => decision;
}
