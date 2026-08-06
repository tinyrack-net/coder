import 'dart:async';
import 'dart:convert';

import 'package:coder_agent/src/compaction.dart';
import 'package:coder_agent/src/model.dart';
import 'package:coder_agent/src/plan_mode_prompt.dart';
import 'package:coder_agent/src/skills.dart';
import 'package:coder_agent/src/tool_search.dart';
import 'package:coder_agent/src/usage.dart';
import 'package:coder_protocol/coder_protocol.dart';

/// Signature used by AgentEventCallback.
typedef AgentEventCallback =
    FutureOr<void> Function(String type, Map<String, dynamic> data);

/// Signature used by SessionStatusCallback.
typedef SessionStatusCallback =
    FutureOr<void> Function(SessionStatus status, {String? error});

/// Signature used by ProviderItemsCallback.
typedef ProviderItemsCallback =
    FutureOr<void> Function(List<ConversationItem> items);

/// Supplies externally queued conversation input at message boundaries.
///
/// The runner drains this source immediately before every model request, so
/// input queued while the model streams or a tool runs is folded into the
/// next round rather than interrupting the current one. Input queued after
/// the final response of a turn stays queued for the next turn.
abstract interface class TurnInputSource {
  /// Returns and consumes items queued for this session; empty when none.
  Future<List<ConversationItem>> drainPending();
}

/// AgentRunRequest defines a public contract.
class AgentRunRequest {
  /// Creates a [AgentRunRequest].
  const AgentRunRequest({
    required this.sessionId,
    required this.turnId,
    required this.workspaceRoot,
    required this.prompt,
    required this.model,
    required this.permissionMode,
    required this.history,
    required this.safetyIdentifier,
    this.attachments = const <ConversationAttachment>[],
    this.reasoningEffort = 'medium',
    this.serviceTier,
    this.maxToolRounds = 64,
    this.sessionMode = SessionMode.normal,
    this.customSystemPrompt,
    this.skills = const <SkillSummary>[],
    this.contextWindowTokens,
    this.priorUsage = const ModelUsage(),
  });

  /// Tokens this model's context window holds, when the catalog knows one.
  ///
  /// A plain int rather than the provider DTO, so this package never learns
  /// about provider catalogs.
  final int? contextWindowTokens;

  /// What the window already held when this turn started.
  ///
  /// A turn can begin on a window an earlier turn already filled, so the first
  /// request has to be checked against the carried-over usage rather than
  /// waiting for a response this turn may never get.
  final ModelUsage priorUsage;

  /// The sessionId public API member.
  final String sessionId;

  /// The turnId public API member.
  final String turnId;

  /// The workspaceRoot public API member.
  final String workspaceRoot;

  /// The prompt public API member.
  final String prompt;

  /// The model public API member.
  final String model;

  /// The reasoningEffort public API member.
  final String reasoningEffort;

  /// Provider service tier for this turn; null uses the provider default.
  final String? serviceTier;

  /// The permissionMode public API member.
  final PermissionMode permissionMode;

  /// The history public API member.
  final List<ConversationItem> history;

  /// The safetyIdentifier public API member.
  final String safetyIdentifier;

  /// Ordered user attachments, hydrated for this provider invocation.
  final List<ConversationAttachment> attachments;

  /// The maxToolRounds public API member.
  final int maxToolRounds;

  /// Collaboration mode of the owning session.
  final SessionMode sessionMode;

  /// Optional Markdown agent prompt appended after immutable safety rules.
  final String? customSystemPrompt;

  /// Skills the turn may load through the `skill` tool.
  final List<SkillSummary> skills;
}

/// Stands in for "no compaction has happened yet" in a token comparison.
const int _unbounded = 1 << 62;

/// AgentRunResult defines a public contract.
class AgentRunResult {
  /// Creates a [AgentRunResult].
  const AgentRunResult({
    required this.conversationItems,
    required this.toolRounds,
  });

  /// The conversationItems public API member.
  final List<ConversationItem> conversationItems;

  /// The toolRounds public API member.
  final int toolRounds;
}

/// AgentRunner defines a public contract.
class AgentRunner {
  /// Creates a [AgentRunner].
  AgentRunner({
    required this._provider,
    required Iterable<AgentTool> tools,
    required this._approvals,
    required this._onEvent,
    required this._onStatus,
    required this._onProviderItems,
    this._contextResets,
    this._pendingTurnInput,
    this._compactor,
    ApprovalPolicy Function(PermissionMode mode)? policyFactory,
  }) : _tools = <String, AgentTool>{for (final tool in tools) tool.name: tool},
       _policyFactory = policyFactory ?? DefaultApprovalPolicy.new {
    final deferred = _tools.values
        .where((tool) => tool.exposure == ToolExposure.deferred)
        .toList(growable: false);
    if (deferred.isEmpty) return;
    // The runner owns the search tool because it owns both the registry and
    // the advertised list. Nothing is built when nothing is deferred.
    final search = ToolSearchTool(
      deferred: deferred,
      onSurfaced: _surfaced.addAll,
    );
    _tools[search.name] = search;
    _deferredCount = deferred.length;
  }

  final ModelProvider _provider;
  final Map<String, AgentTool> _tools;
  final ApprovalCoordinator _approvals;
  final AgentEventCallback _onEvent;
  final SessionStatusCallback _onStatus;
  final ProviderItemsCallback _onProviderItems;

  /// Discards persisted history when a tool asks for a fresh window.
  final ContextResetCoordinator? _contextResets;

  /// Summarizes the conversation when the window runs out; null disables it.
  final ConversationCompactor? _compactor;

  /// Externally queued input drained at every message boundary.
  final TurnInputSource? _pendingTurnInput;

  /// Builds the approval policy for a turn's permission mode.
  final ApprovalPolicy Function(PermissionMode mode) _policyFactory;

  /// Deferred tools a search has made visible to the model.
  final Set<String> _surfaced = <String>{};

  /// How many tools were withheld from the initial advertisement.
  int _deferredCount = 0;

  /// Tools the model is told about: everything advertised, plus what a search
  /// surfaced.
  List<ModelToolDefinition> _advertisedTools() => <ModelToolDefinition>[
    for (final tool in _tools.values)
      if (tool.exposure == ToolExposure.advertised ||
          _surfaced.contains(tool.name))
        ModelToolDefinition(
          name: tool.name,
          description: tool.description,
          parameters: tool.strictJsonSchema,
          strict: tool.strict,
        ),
  ];

  /// Restores the tools an earlier turn in this session already surfaced.
  ///
  /// Unlike the Responses API, the providers here take a tools array per
  /// request, so a tool that only lives in a past `tool_search` result would
  /// silently stop being callable. The names are read back out of history so
  /// no extra state has to be stored or kept in sync.
  void _restoreSurfaced(List<ConversationItem> history) {
    if (_deferredCount == 0) return;
    for (final item in history) {
      if (item is! ToolResultConversationItem) continue;
      final Object? decoded;
      try {
        decoded = jsonDecode(item.output);
      } on FormatException {
        continue;
      }
      if (decoded is! Map) continue;
      final tools = decoded['tools'];
      if (tools is! List) continue;
      for (final entry in tools.whereType<Map<dynamic, dynamic>>()) {
        final name = entry['name'];
        if (name is String && _tools.containsKey(name)) _surfaced.add(name);
      }
    }
  }

  /// The startTurn public API member.
  Future<AgentRunResult> startTurn(
    AgentRunRequest request,
    CancellationToken cancellation,
  ) async {
    final userItem = UserConversationItem(
      request.prompt,
      attachments: request.attachments,
    );
    final input = <ConversationItem>[...request.history, userItem];
    final persisted = <ConversationItem>[userItem];
    var toolRounds = 0;
    var turnUsage = const ModelUsage();
    var resetRequested = false;
    // What the window held when it was last compacted, so a compaction that
    // failed to shrink it is not repeated every round.
    var lastCompactionTokens = _unbounded;
    _restoreSurfaced(request.history);
    await _onStatus(SessionStatus.running);
    if (_deferredCount > 0) {
      await _onEvent('tools.deferred', <String, dynamic>{
        'count': _deferredCount,
        'surfaced': _surfaced.length,
      });
    }
    await _onEvent('user.message', <String, dynamic>{
      'text': request.prompt,
      'attachments': request.attachments
          .map(_attachmentSnapshot)
          .toList(growable: false),
    });
    await _onProviderItems(<ConversationItem>[userItem]);

    try {
      // An earlier turn can have left the window full, in which case this turn
      // would overflow on its very first request.
      if (_shouldCompact(request.priorUsage, request)) {
        await _compactWindow(input, persisted, request, cancellation, 'auto');
      }
      while (true) {
        cancellation.throwIfCancelled();

        final injected =
            await _pendingTurnInput?.drainPending() ??
            const <ConversationItem>[];
        if (injected.isNotEmpty) {
          input.addAll(injected);
          persisted.addAll(injected);
          await _onProviderItems(injected);
          await _onEvent('agent.message.delivered', <String, dynamic>{
            'count': injected.length,
          });
        }

        var functionCalls = <ModelFunctionCall>[];
        ModelResponseCompleted? completed;
        // One recovery per round: a second refusal means compacting is not
        // what is oversized, and retrying would only spend another summary.
        var overflowRetried = false;
        while (completed == null) {
          functionCalls = <ModelFunctionCall>[];
          var recovered = false;
          final modelRequest = ModelRequest(
            model: request.model,
            reasoningEffort: request.reasoningEffort,
            serviceTier: request.serviceTier,
            instructions: _instructions(request),
            history: List<ConversationItem>.unmodifiable(input),
            safetyIdentifier: request.safetyIdentifier,
            tools: _advertisedTools(),
          );

          try {
            await for (final event in _provider.stream(
              modelRequest,
              cancellation,
            )) {
              switch (event) {
                case ModelTextDelta(:final delta):
                  await _onEvent('assistant.delta', <String, dynamic>{
                    'text': delta,
                  });
                case ModelFunctionCall():
                  functionCalls.add(event);
                  await _onEvent('tool.requested', <String, dynamic>{
                    'callId': event.callId,
                    'name': event.name,
                    'arguments': event.arguments,
                  });
                case ModelResponseCompleted():
                  completed = event;
              }
            }
          } on ModelContextOverflowException {
            // The catalog window can be absent or wrong, so the provider's own
            // refusal is the only reliable signal for some models.
            if (overflowRetried || _compactor == null) rethrow;
            overflowRetried = true;
            recovered = true;
            await _compactWindow(
              input,
              persisted,
              request,
              cancellation,
              'overflow',
            );
          }

          if (completed == null && !recovered) {
            throw StateError('Model stream ended without response.completed.');
          }
        }
        final assistant = completed.assistant;
        input.add(assistant);
        persisted.add(assistant);
        await _onProviderItems(<ConversationItem>[assistant]);
        turnUsage = completed.usage;
        await _onEvent('model.usage', completed.usage.toJson());

        if (functionCalls.isEmpty) {
          await _onEvent('turn.completed', <String, dynamic>{
            'toolRounds': toolRounds,
          });
          await _onStatus(SessionStatus.idle);
          return AgentRunResult(
            conversationItems: persisted,
            toolRounds: toolRounds,
          );
        }

        if (toolRounds >= request.maxToolRounds) {
          throw StateError(
            'Tool round limit (${request.maxToolRounds}) exceeded.',
          );
        }
        toolRounds += 1;
        for (final call in functionCalls) {
          cancellation.throwIfCancelled();
          final tool = _tools[call.name];
          if (tool == null) {
            final output = <String, dynamic>{
              'error': 'Unknown tool: ${call.name}',
            };
            final item = ToolResultConversationItem(
              callId: call.callId,
              output: jsonEncode(output),
              isError: true,
            );
            input.add(item);
            persisted.add(item);
            await _onProviderItems(<ConversationItem>[item]);
            continue;
          }

          try {
            final context = ToolExecutionContext(
              workspaceRoot: request.workspaceRoot,
              cancellation: cancellation,
              callId: call.callId,
              contextWindowTokens: request.contextWindowTokens,
              turnUsage: turnUsage,
              requestContextReset: () => resetRequested = true,
            );
            final preview = await tool.preview(call.arguments, context);
            final invocation = ToolInvocation(
              callId: call.callId,
              name: call.name,
              arguments: call.arguments,
              risk: tool.risk,
              workspaceRoot: request.workspaceRoot,
              preview: preview,
            );
            final policy = _policyFactory(
              request.permissionMode,
            ).evaluate(invocation);
            var approved = policy == ApprovalEvaluation.allow;
            if (policy == ApprovalEvaluation.ask) {
              await _onStatus(SessionStatus.waitingForApproval);
              approved =
                  await _approvals.request(invocation, cancellation) ==
                  ApprovalDecision.approved;
              await _onStatus(SessionStatus.running);
            }
            if (policy == ApprovalEvaluation.deny || !approved) {
              final item = ToolResultConversationItem(
                callId: call.callId,
                output: jsonEncode(<String, dynamic>{
                  'error': 'Tool execution was denied.',
                }),
                isError: true,
              );
              input.add(item);
              persisted.add(item);
              await _onProviderItems(<ConversationItem>[item]);
              await _onEvent('tool.denied', <String, dynamic>{
                'callId': call.callId,
                'name': call.name,
              });
              continue;
            }

            final result = await tool.execute(call.arguments, context);
            final item = ToolResultConversationItem(
              callId: call.callId,
              output: result.output,
              isError: result.isError,
            );
            input.add(item);
            persisted.add(item);
            await _onProviderItems(<ConversationItem>[item]);
            await _onEvent('tool.completed', <String, dynamic>{
              'callId': call.callId,
              'name': call.name,
              'output': result.output,
              'isError': result.isError,
            });
            if (result.contextImages.isNotEmpty) {
              // Images cannot ride inside a tool result on either provider
              // API, so they arrive as the next user item instead.
              final images = UserConversationItem(
                '',
                attachments: result.contextImages,
              );
              input.add(images);
              persisted.add(images);
              await _onProviderItems(<ConversationItem>[images]);
            }
            for (final attachment in result.attachments) {
              await _onEvent(
                'assistant.attachment',
                _attachmentSnapshot(attachment),
              );
            }
          } on AgentCancelledException {
            rethrow;
          } on Exception catch (error) {
            final item = ToolResultConversationItem(
              callId: call.callId,
              output: jsonEncode(<String, dynamic>{'error': '$error'}),
              isError: true,
            );
            input.add(item);
            persisted.add(item);
            await _onProviderItems(<ConversationItem>[item]);
            await _onEvent('tool.failed', <String, dynamic>{
              'callId': call.callId,
              'name': call.name,
              'error': '$error',
            });
          }
        }

        if (resetRequested) {
          resetRequested = false;
          await _startNewContextWindow(input, persisted, request);
        } else if (_shouldCompact(turnUsage, request) &&
            turnUsage.contextTokens < lastCompactionTokens) {
          // Like the reset above, this waits for the whole round: compacting
          // between a tool call and its output would strand the output.
          //
          // A window still over budget after being compacted cannot be helped
          // by compacting it again, so the comparison stops a long turn from
          // buying one summary per round for no gain.
          lastCompactionTokens = turnUsage.contextTokens;
          await _compactWindow(input, persisted, request, cancellation, 'auto');
        }
      }
    } on AgentCancelledException {
      await _onEvent('turn.cancelled', const <String, dynamic>{});
      await _onStatus(SessionStatus.idle);
      rethrow;
    } catch (error) {
      await _onEvent('turn.failed', <String, dynamic>{'error': '$error'});
      await _onStatus(SessionStatus.failed, error: '$error');
      rethrow;
    }
  }

  /// Whether [usage] has spent enough of this turn's window to compact.
  bool _shouldCompact(ModelUsage usage, AgentRunRequest request) =>
      _compactor?.shouldCompact(
        usage: usage,
        contextWindowTokens: request.contextWindowTokens,
      ) ??
      false;

  /// Replaces the live conversation with a summary of itself.
  ///
  /// Unlike `new_context`, nothing of the round survives verbatim, so there is
  /// no `function_call` left whose output could be orphaned. The coordinator is
  /// handed exactly what the live input kept, so the database and the in-memory
  /// history cannot drift apart.
  Future<void> _compactWindow(
    List<ConversationItem> input,
    List<ConversationItem> persisted,
    AgentRunRequest request,
    CancellationToken cancellation,
    String trigger,
  ) async {
    final compactor = _compactor;
    if (compactor == null) return;
    final compacted = await compactor.compact(
      history: List<ConversationItem>.unmodifiable(input),
      target: CompactionTarget(
        model: request.model,
        reasoningEffort: request.reasoningEffort,
        serviceTier: request.serviceTier,
        safetyIdentifier: request.safetyIdentifier,
      ),
      cancellation: cancellation,
    );
    input
      ..clear()
      ..addAll(compacted);
    persisted
      ..clear()
      ..addAll(compacted);
    await _contextResets?.reset(compacted);
    await _onEvent('context.compacted', <String, dynamic>{
      'retained': compacted.length,
      'trigger': trigger,
    });
  }

  /// Discards the conversation, keeping only the round that asked for it.
  ///
  /// Both provider APIs reject a `function_call_output` whose `function_call`
  /// is missing, so the assistant item that issued the reset and every tool
  /// result of that same round have to survive together. The coordinator is
  /// given exactly what the live conversation kept, so the database and the
  /// in-memory history cannot drift apart.
  Future<void> _startNewContextWindow(
    List<ConversationItem> input,
    List<ConversationItem> persisted,
    AgentRunRequest request,
  ) async {
    final lastAssistant = input.lastIndexWhere(
      (item) => item is AssistantConversationItem,
    );
    if (lastAssistant < 0) return;
    final retain = List<ConversationItem>.unmodifiable(
      input.sublist(lastAssistant),
    );
    input
      ..clear()
      ..addAll(retain);
    persisted
      ..clear()
      ..addAll(retain);
    await _contextResets?.reset(retain);
    await _onEvent('context.reset', <String, dynamic>{
      'retained': retain.length,
    });
  }

  String _instructions(AgentRunRequest request) {
    final customPrompt = request.customSystemPrompt?.trim();
    final planning = request.sessionMode == SessionMode.plan
        ? '\n${planModeInstructions()}'
        : '';
    return '''
You are a coding agent operating in ${request.workspaceRoot}.
Use only the supplied tools. Read before editing, keep changes scoped to the request,
and validate relevant behavior before finishing. Never attempt to access paths outside
the workspace. Approval decisions are enforced by the host; do not work around them.
${_skillCatalog(request.skills)}$planning${customPrompt == null || customPrompt.isEmpty ? '' : '\n$customPrompt'}
''';
  }

  /// Points at the skill tools instead of listing every skill.
  ///
  /// Naming each skill here charged every turn for the whole catalog, whether
  /// or not it used one. The count is kept because it is one number and it is
  /// what tells the agent whether looking is worth a call at all.
  String _skillCatalog(List<SkillSummary> skills) {
    if (skills.isEmpty) return '';
    final plural = skills.length == 1 ? 'skill is' : 'skills are';
    return '''

## Available skills
${skills.length} $plural available in this workspace.
Call the `$listSkillsToolName` tool to see their names and descriptions, then the
`skill` tool with a name to load its full instructions before acting on it.
Treat a skill's bundled scripts as ordinary workspace code: read them before running them.
''';
  }
}

Map<String, dynamic> _attachmentSnapshot(ConversationAttachment attachment) =>
    <String, dynamic>{
      'id': attachment.id,
      'fileName': attachment.fileName,
      'mimeType': attachment.mimeType,
      'byteSize': attachment.byteSize,
      if (attachment.kind != null) 'kind': attachment.kind!.name,
      if (attachment.sha256 != null) 'sha256': attachment.sha256,
      if (attachment.createdAt != null)
        'createdAt': attachment.createdAt!.toIso8601String(),
    };
