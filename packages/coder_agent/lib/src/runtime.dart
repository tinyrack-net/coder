import 'dart:async';
import 'dart:convert';

import 'package:coder_agent/src/model.dart';
import 'package:coder_agent/src/plan_mode_prompt.dart';
import 'package:coder_agent/src/skills.dart';
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
  });

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
    ApprovalPolicy Function(PermissionMode mode)? policyFactory,
  }) : _tools = <String, AgentTool>{for (final tool in tools) tool.name: tool},
       _policyFactory = policyFactory ?? DefaultApprovalPolicy.new;

  final ModelProvider _provider;
  final Map<String, AgentTool> _tools;
  final ApprovalCoordinator _approvals;
  final AgentEventCallback _onEvent;
  final SessionStatusCallback _onStatus;
  final ProviderItemsCallback _onProviderItems;

  /// Builds the approval policy for a turn's permission mode.
  final ApprovalPolicy Function(PermissionMode mode) _policyFactory;

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
    await _onStatus(SessionStatus.running);
    await _onEvent('user.message', <String, dynamic>{
      'text': request.prompt,
      'attachments': request.attachments
          .map(_attachmentSnapshot)
          .toList(growable: false),
    });
    await _onProviderItems(<ConversationItem>[userItem]);

    try {
      while (true) {
        cancellation.throwIfCancelled();

        final functionCalls = <ModelFunctionCall>[];
        ModelResponseCompleted? completed;
        final modelRequest = ModelRequest(
          model: request.model,
          reasoningEffort: request.reasoningEffort,
          serviceTier: request.serviceTier,
          instructions: _instructions(request),
          history: input,
          safetyIdentifier: request.safetyIdentifier,
          tools: _tools.values
              .map(
                (tool) => ModelToolDefinition(
                  name: tool.name,
                  description: tool.description,
                  parameters: tool.strictJsonSchema,
                  strict: tool.strict,
                ),
              )
              .toList(growable: false),
        );

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

        if (completed == null) {
          throw StateError('Model stream ended without response.completed.');
        }
        final assistant = completed.assistant;
        input.add(assistant);
        persisted.add(assistant);
        await _onProviderItems(<ConversationItem>[assistant]);
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

  String _skillCatalog(List<SkillSummary> skills) {
    if (skills.isEmpty) return '';
    final sorted = skills.toList(growable: false)
      ..sort((left, right) => left.name.compareTo(right.name));
    final entries = sorted
        .map((skill) => '- ${skill.name}: ${skill.description}')
        .join('\n');
    return '''

## Available skills
Call the `skill` tool with a skill name to load its full instructions before acting on it.
Treat a skill's bundled scripts as ordinary workspace code: read them before running them.
$entries
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
