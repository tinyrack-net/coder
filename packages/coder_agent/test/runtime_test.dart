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
    'the skill catalog is injected in name order before the agent prompt',
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
      expect(instructions, contains('- commit: Writes commits.'));
      expect(instructions, contains('- dataviz: Draws charts.'));
      expect(
        instructions.indexOf('- commit:'),
        lessThan(instructions.indexOf('- dataviz:')),
      );
      expect(
        instructions.indexOf('## Available skills'),
        lessThan(instructions.indexOf('Review every security boundary.')),
      );

      final unsorted = _FakeProvider(<List<ModelEvent>>[_textResponse('ok')]);
      await _RunnerHarness(unsorted).runner.startTurn(
        _request(
          skills: const <SkillSummary>[
            SkillSummary(name: 'dataviz', description: 'Draws charts.'),
            SkillSummary(name: 'commit', description: 'Writes commits.'),
          ],
        ),
        CancellationToken(),
      );
      final sorted = unsorted.requests.single.instructions;
      expect(
        sorted.indexOf('- commit:'),
        lessThan(sorted.indexOf('- dataviz:')),
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
}) => AgentRunRequest(
  sessionId: 'agent-1',
  turnId: 'turn-1',
  workspaceRoot: Directory.current.path,
  prompt: 'test',
  model: 'test-model',
  permissionMode: permissionMode,
  history: const <ConversationItem>[UserConversationItem('history')],
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
  }) {
    runner = AgentRunner(
      provider: provider,
      tools: tools,
      approvals: approvals,
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
