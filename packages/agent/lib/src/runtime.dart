import 'dart:async';
import 'dart:convert';

import 'package:agent/src/clock.dart';
import 'package:agent/src/compaction.dart';
import 'package:agent/src/contracts.dart';
import 'package:agent/src/model.dart';
import 'package:agent/src/plan_mode_prompt.dart';
import 'package:agent/src/prompts/permissions_instructions.dart';
import 'package:agent/src/prompts/system_prompt.dart';
import 'package:agent/src/tools/tool_search.dart';
import 'package:agent/src/usage.dart';

/// Signature used by AgentEventCallback.
typedef AgentEventCallback = FutureOr<void> Function(
  String type,
  Map<String, dynamic> data,
);

/// Signature used by SessionStatusCallback.
typedef SessionStatusCallback = FutureOr<void> Function(
  AgentSessionStatus status, {
  String? error,
});

/// Signature used by ProviderItemsCallback.
typedef ProviderItemsCallback = FutureOr<void> Function(
  List<ConversationItem> items,
);

/// Supplies ephemeral daemon-owned instructions for the next model request.
///
/// These instructions are never persisted as conversation items or rendered
/// as user messages.
typedef InternalInstructionSource = Future<String?> Function();

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

/// Supplies the permission mode in effect at the next tool boundary.
abstract interface class PermissionModeSource {
  /// Returns the current effective permission mode.
  Future<AgentPermissionMode> currentMode();
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
    required this.history,
    required this.safetyIdentifier,
    this.attachments = const <ConversationAttachment>[],
    this.modelControls = const <String, AgentModelControlValue>{},
    this.maxToolRounds = 64,
    this.sessionMode = AgentSessionMode.normal,
    this.toolSurfaceMode = AgentToolSurfaceMode.direct,
    this.projectDoc,
    this.customSystemPrompt,
    this.toolPrompts = const <String>[],
    this.contextWindowTokens,
    this.priorUsage = const ModelUsage(),
    this.internal = false,
    this.internalInstructions,
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

  /// Whether this turn was started by a daemon workflow rather than a user.
  final bool internal;

  /// Ephemeral instructions refreshed before every model request.
  final InternalInstructionSource? internalInstructions;

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

  /// Model-specific values already validated by the provider boundary.
  final Map<String, AgentModelControlValue> modelControls;

  /// The history public API member.
  final List<ConversationItem> history;

  /// The safetyIdentifier public API member.
  final String safetyIdentifier;

  /// Ordered user attachments, hydrated for this provider invocation.
  final List<ConversationAttachment> attachments;

  /// The maxToolRounds public API member.
  final int maxToolRounds;

  /// Collaboration mode of the owning session.
  final AgentSessionMode sessionMode;

  /// Model-facing tool surface selected for this turn.
  final AgentToolSurfaceMode toolSurfaceMode;

  /// Workspace documentation the host collected, already marked as user data.
  final String? projectDoc;

  /// Optional Markdown agent prompt appended after immutable safety rules.
  final String? customSystemPrompt;

  /// Skills the turn may load through the `skill` tool.
  /// System-prompt paragraphs contributed by the turn's own capabilities.
  ///
  /// A tool that needs the model told how to use it supplies its own text, so
  /// this package never names a tool it does not define.
  final List<String> toolPrompts;
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
    required this._permissions,
    required this._clock,
    Iterable<AgentTool> nestedTools = const <AgentTool>[],
    this._contextResets,
    this._pendingTurnInput,
    this._compactor,
    ApprovalPolicy Function(AgentPermissionMode mode)? policyFactory,
  }) : _tools = <String, AgentTool>{for (final tool in tools) tool.name: tool},
       _nestedTools = <String, AgentTool>{
         for (final tool in nestedTools) tool.name: tool,
       },
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
  final Map<String, AgentTool> _nestedTools;
  final ApprovalCoordinator _approvals;
  final AgentEventCallback _onEvent;
  final SessionStatusCallback _onStatus;
  final ProviderItemsCallback _onProviderItems;
  final PermissionModeSource _permissions;

  /// Times the generation span each model response is measured over.
  final Clock _clock;

  /// Discards persisted history when a tool asks for a fresh window.
  final ContextResetCoordinator? _contextResets;

  /// Summarizes the conversation when the window runs out; null disables it.
  final ConversationCompactor? _compactor;

  /// Externally queued input drained at every message boundary.
  final TurnInputSource? _pendingTurnInput;

  /// Builds the approval policy for a turn's permission mode.
  final ApprovalPolicy Function(AgentPermissionMode mode) _policyFactory;

  /// Deferred tools a search has made visible to the model.
  final Set<String> _surfaced = <String>{};

  /// How many tools were withheld from the initial advertisement.
  int _deferredCount = 0;
  int _nextNestedCallId = 0;
  Future<void> _approvalQueue = Future<void>.value();

  /// Tools the model is told about: everything advertised, plus what a search
  /// surfaced.
  List<ModelToolDefinition> _advertisedTools() {
    final direct = <ModelToolDefinition>[];
    final namespaces = <String, ModelNamespaceToolDefinition>{};
    for (final tool in _tools.values) {
      if (tool.exposure != ToolExposure.advertised &&
          !_surfaced.contains(tool.name)) {
        continue;
      }
      final spec = tool.modelSpec;
      if (spec is! ModelNamespaceToolDefinition) {
        direct.add(spec);
        continue;
      }
      final previous = namespaces[spec.name];
      namespaces[spec.name] = ModelNamespaceToolDefinition(
        name: spec.name,
        description: spec.description,
        tools: <ModelFunctionToolDefinition>[
          ...?previous?.tools,
          ...spec.tools,
        ],
      );
    }
    return <ModelToolDefinition>[...direct, ...namespaces.values];
  }

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
        final name = entry['canonical_name'] ?? entry['name'];
        if (name is String && _tools.containsKey(name)) _surfaced.add(name);
      }
    }
  }

  /// The startTurn public API member.
  Future<AgentRunResult> startTurn(
    AgentRunRequest request,
    CancellationToken cancellation,
  ) async {
    final userItem = request.internal
        ? null
        : UserConversationItem(
            request.prompt,
            attachments: request.attachments,
          );
    final input = <ConversationItem>[...request.history, ?userItem];
    final persisted = <ConversationItem>[?userItem];
    var toolRounds = 0;
    var turnUsage = const ModelUsage();
    var resetRequested = false;
    // What the window held when it was last compacted, so a compaction that
    // failed to shrink it is not repeated every round.
    var lastCompactionTokens = _unbounded;
    _restoreSurfaced(request.history);
    await _onStatus(AgentSessionStatus.running);
    if (_deferredCount > 0) {
      await _onEvent('tools.deferred', <String, dynamic>{
        'count': _deferredCount,
        'surfaced': _surfaced.length,
      });
    }
    if (userItem != null) {
      await _onEvent('user.message', <String, dynamic>{
        'text': request.prompt,
        'attachments': request.attachments
            .map(_attachmentSnapshot)
            .toList(growable: false),
      });
      await _onProviderItems(<ConversationItem>[userItem]);
    }

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

        var toolCalls = <ModelToolCall>[];
        ModelResponseCompleted? completed;
        // How long the model spent producing the response that completed, so
        // the client can report a generation rate. Null until a stream both
        // produced a token and completed.
        int? generationMs;
        // One recovery per round: a second refusal means compacting is not
        // what is oversized, and retrying would only spend another summary.
        var overflowRetried = false;
        while (completed == null) {
          toolCalls = <ModelToolCall>[];
          var recovered = false;
          // Reset per attempt: a stream the provider refused as too long is
          // not part of the generation that eventually answered.
          DateTime? firstTokenAt;
          final modelRequest = ModelRequest(
            model: request.model,
            modelControls: request.modelControls,
            instructions: _instructions(
              request,
              await request.internalInstructions?.call(),
              await _permissions.currentMode(),
            ),
            history: List<ConversationItem>.unmodifiable(input),
            safetyIdentifier: request.safetyIdentifier,
            tools: _advertisedTools(),
          );

          var reasoningOpen = true;
          await _onEvent(
            'assistant.reasoning.started',
            const <String, dynamic>{},
          );
          Future<void> closeReasoning() async {
            if (!reasoningOpen) return;
            reasoningOpen = false;
            await _onEvent(
              'assistant.reasoning.completed',
              const <String, dynamic>{},
            );
          }

          try {
            await for (final event in _provider.stream(
              modelRequest,
              cancellation,
            )) {
              switch (event) {
                case ModelReasoningDelta(:final delta):
                  firstTokenAt ??= _clock.nowUtc();
                  await _onEvent(
                    'assistant.reasoning.delta',
                    <String, dynamic>{'text': delta},
                  );
                case ModelTextDelta(:final delta):
                  await closeReasoning();
                  firstTokenAt ??= _clock.nowUtc();
                  await _onEvent('assistant.delta', <String, dynamic>{
                    'text': delta,
                  });
                case ModelToolCall():
                  await closeReasoning();
                  firstTokenAt ??= _clock.nowUtc();
                  toolCalls.add(event);
                  await _onEvent('tool.requested', <String, dynamic>{
                    'callId': event.callId,
                    'name': event.name,
                    'input': event.input.toJson(),
                  });
                case ModelResponseCompleted():
                  await closeReasoning();
                  completed = event;
                  // Measured from the first token rather than the request, so
                  // the rate reports generation speed and not the wait for it.
                  final startedAt = firstTokenAt;
                  generationMs = startedAt == null
                      ? null
                      : _clock.nowUtc().difference(startedAt).inMilliseconds;
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
          } finally {
            await closeReasoning();
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
        await _onEvent('model.usage', <String, dynamic>{
          ...completed.usage.toJson(),
          'generationMs': ?generationMs,
        });

        if (toolCalls.isEmpty) {
          await _onEvent('turn.completed', <String, dynamic>{
            'toolRounds': toolRounds,
          });
          await _onStatus(AgentSessionStatus.idle);
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
        Future<({ModelToolCall call, ToolResult result})> executeCall(
          ModelToolCall call,
        ) async {
          final tool = _tools[call.name];
          if (tool == null) {
            return (
              call: call,
              result: ToolResult(
                value: <String, dynamic>{
                  'error': 'Unknown tool: ${call.name}',
                },
                isError: true,
              ),
            );
          }
          try {
            final result = await _executeTool(
              tool: tool,
              name: call.name,
              input: call.input,
              callId: call.callId,
              request: request,
              cancellation: cancellation,
              turnUsage: turnUsage,
              requestContextReset: () => resetRequested = true,
            );
            return (call: call, result: result);
          } on AgentCancelledException {
            rethrow;
          } on Exception catch (error) {
            await _onEvent('tool.failed', <String, dynamic>{
              'callId': call.callId,
              'name': call.name,
              'error': '$error',
            });
            return (
              call: call,
              result: ToolResult(
                value: <String, dynamic>{'error': '$error'},
                isError: true,
              ),
            );
          }
        }

        var callIndex = 0;
        while (callIndex < toolCalls.length) {
          cancellation.throwIfCancelled();
          final first = toolCalls[callIndex];
          final parallel =
              _tools[first.name]?.modelSpec.supportsParallelToolCalls ?? false;
          final group = <ModelToolCall>[first];
          callIndex += 1;
          if (parallel) {
            while (callIndex < toolCalls.length) {
              final candidate = toolCalls[callIndex];
              final candidateParallel =
                  _tools[candidate.name]?.modelSpec.supportsParallelToolCalls ??
                  false;
              if (!candidateParallel) break;
              group.add(candidate);
              callIndex += 1;
            }
          }
          final executions = parallel && group.length > 1
              ? await Future.wait(group.map(executeCall))
              : <({ModelToolCall call, ToolResult result})>[
                  await executeCall(first),
                ];
          for (final execution in executions) {
            final call = execution.call;
            final result = execution.result;
            final item = ToolResultConversationItem(
              callId: call.callId,
              output: result.output,
              toolKind: call is ModelDeferredSearchCall
                  ? ModelToolKind.deferredSearch
                  : call.input is FreeformToolCallInput
                  ? ModelToolKind.freeform
                  : ModelToolKind.function,
              isError: result.isError,
              content: result.content,
              structuredContent: result.structuredContent,
              meta: result.meta,
            );
            for (final notification in result.notifications) {
              await _onEvent('tool.notification', <String, dynamic>{
                'callId': call.callId,
                'name': call.name,
                'value': notification,
              });
            }
            input.add(item);
            persisted.add(item);
            await _onProviderItems(<ConversationItem>[item]);
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
      await _onStatus(AgentSessionStatus.idle);
      rethrow;
    } catch (error) {
      await _onEvent('turn.failed', <String, dynamic>{'error': '$error'});
      await _onStatus(AgentSessionStatus.failed, error: '$error');
      rethrow;
    }
  }

  Future<ToolResult> _executeTool({
    required AgentTool tool,
    required String name,
    required ToolCallInput input,
    required String callId,
    required AgentRunRequest request,
    required CancellationToken cancellation,
    required ModelUsage turnUsage,
    required void Function() requestContextReset,
    String? parentCallId,
  }) async {
    cancellation.throwIfCancelled();
    if (parentCallId != null) {
      await _onEvent('tool.requested', <String, dynamic>{
        'callId': callId,
        'parentCallId': parentCallId,
        'name': name,
        'input': input.toJson(),
      });
    }
    final context = ToolExecutionContext(
      workspaceRoot: request.workspaceRoot,
      cancellation: cancellation,
      callId: callId,
      contextWindowTokens: request.contextWindowTokens,
      turnUsage: turnUsage,
      requestContextReset: requestContextReset,
      nestedTools: _nestedTools.isEmpty
          ? null
          : _CallbackNestedToolInvoker((nestedName, nestedArguments) async {
              final nested = _nestedTools[nestedName];
              if (nested == null) {
                return ToolResult(
                  value: jsonEncode(<String, dynamic>{
                    'error': 'Unknown nested tool: $nestedName',
                  }),
                  isError: true,
                );
              }
              final nestedCallId = '$callId:nested-${_nextNestedCallId += 1}';
              try {
                return await _executeTool(
                  tool: nested,
                  name: nestedName,
                  input: JsonToolCallInput(nestedArguments),
                  callId: nestedCallId,
                  request: request,
                  cancellation: cancellation,
                  turnUsage: turnUsage,
                  requestContextReset: requestContextReset,
                  parentCallId: callId,
                );
              } on AgentCancelledException {
                rethrow;
              } on Exception catch (error) {
                await _onEvent('tool.failed', <String, dynamic>{
                  'callId': nestedCallId,
                  'parentCallId': callId,
                  'name': nestedName,
                  'error': '$error',
                });
                return ToolResult(
                  value: jsonEncode(<String, dynamic>{'error': '$error'}),
                  isError: true,
                );
              }
            }),
      sessionMode: request.sessionMode,
      toolSurfaceMode: request.toolSurfaceMode,
    );
    final approvalArguments = switch (input) {
      JsonToolCallInput(:final value) => value,
      FreeformToolCallInput(:final value) => <String, dynamic>{'input': value},
    };
    final preview = await switch (input) {
      JsonToolCallInput(:final value) => tool.preview(value, context),
      FreeformToolCallInput(:final value) => tool.previewFreeform(
        value,
        context,
      ),
    };
    final invocation = ToolInvocation(
      callId: callId,
      name: name,
      arguments: approvalArguments,
      risk: tool.risk,
      workspaceRoot: request.workspaceRoot,
      preview: preview,
    );
    final policy = _policyFactory(
      await _permissions.currentMode(),
    ).evaluate(invocation);
    var approved = policy == ApprovalEvaluation.allow;
    if (policy == ApprovalEvaluation.ask) {
      approved =
          await _requestApproval(invocation, cancellation) ==
          ApprovalDecision.approved;
    }
    if (policy == ApprovalEvaluation.deny || !approved) {
      await _onEvent('tool.denied', <String, dynamic>{
        'callId': callId,
        'parentCallId': ?parentCallId,
        'name': name,
      });
      return ToolResult(
        value: jsonEncode(<String, dynamic>{
          'error': 'Tool execution was denied.',
        }),
        isError: true,
      );
    }
    final result = await switch (input) {
      JsonToolCallInput(:final value) => tool.execute(value, context),
      FreeformToolCallInput(:final value) => tool.executeFreeform(
        value,
        context,
      ),
    };
    await _onEvent('tool.completed', <String, dynamic>{
      'callId': callId,
      'parentCallId': ?parentCallId,
      'name': name,
      'output': result.output,
      'isError': result.isError,
    });
    return result;
  }

  Future<ApprovalDecision> _requestApproval(
    ToolInvocation invocation,
    CancellationToken cancellation,
  ) {
    final result = Completer<ApprovalDecision>();
    _approvalQueue = _approvalQueue.then((_) async {
      try {
        cancellation.throwIfCancelled();
        await _onStatus(AgentSessionStatus.waitingForApproval);
        result.complete(await _approvals.request(invocation, cancellation));
      } on Object catch (error, stackTrace) {
        result.completeError(error, stackTrace);
      } finally {
        await _onStatus(AgentSessionStatus.running);
      }
    });
    return result.future;
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
        modelControls: request.modelControls,
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
    _surfaced.clear();
    await _contextResets?.reset(retain);
    await _onEvent('context.reset', <String, dynamic>{
      'retained': retain.length,
    });
  }

  String _instructions(
    AgentRunRequest request,
    String? internal,
    AgentPermissionMode permissions,
  ) => buildSystemPrompt(
    SystemPromptInputs(
      workspaceRoot: request.workspaceRoot,
      permissionsInstructions: permissionsInstructions(
        mode: permissions,
        workspaceRoot: request.workspaceRoot,
      ),
      environmentContext: environmentContext(
        workspaceRoot: request.workspaceRoot,
      ),
      projectDoc: request.projectDoc,
      toolPrompts: request.toolPrompts,
      modeInstructions: request.sessionMode == AgentSessionMode.plan
          ? planModeInstructions()
          : null,
      customInstructions: request.customSystemPrompt,
      internalInstructions: internal,
    ),
  );
}

final class _CallbackNestedToolInvoker implements NestedToolInvoker {
  const _CallbackNestedToolInvoker(this._invoke);

  final Future<ToolResult> Function(
    String name,
    Map<String, dynamic> arguments,
  )
  _invoke;

  @override
  Future<ToolResult> invoke(
    String name,
    Map<String, dynamic> arguments,
  ) => _invoke(name, arguments);
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
