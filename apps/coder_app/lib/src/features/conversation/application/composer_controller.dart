import 'dart:async';

import 'package:coder_app/src/features/conversation/application/composer_suggestions.dart';
import 'package:coder_app/src/features/hosts/application/host_controller.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'composer_controller.g.dart';

/// How long an `@` query rests before the daemon index is asked.
const Duration composerFileSearchDebounce = Duration(milliseconds: 120);

/// How long an idle empty-query result stays warm so reopening `@` is instant.
const Duration composerFileSearchKeepAlive = Duration(seconds: 30);

/// How long a failed queue release rests before it is tried again.
const Duration conversationDrainRetryDelay = Duration(milliseconds: 250);

/// Releases one queued prompt may be charged before it waits for the user.
///
/// The queue is released by session events, and the event that would have
/// released a prompt is often the last one coming. A bounded retry is what
/// keeps a prompt from waiting on an event that will never arrive, so the
/// bound has to be small enough to stay invisible and finite by construction.
const int conversationDrainMaxAttempts = 3;

@riverpod
/// Searches one worktree for the files an `@` query could mention.
///
/// The query is part of the provider key, so each keystroke creates a new
/// provider and disposes the previous one. Cancelling the timer on dispose is
/// therefore the debounce itself, with no controller state to keep in sync.
Future<List<FileMatchDto>> composerFileSearch(
  Ref ref,
  String hostId,
  String worktreeId,
  String query,
) async {
  await _debounce(ref, composerFileSearchDebounce);
  if (query.isEmpty) {
    final link = ref.keepAlive();
    final timer = Timer(composerFileSearchKeepAlive, link.close);
    ref.onDispose(timer.cancel);
  }
  final api = await requireHostApi(ref, hostId);
  final result = await api.workspaces.searchFiles(
    worktreeId: worktreeId,
    query: query,
  );
  return rankFileMatches(result.matches, query);
}

/// Waits [delay], or never completes when the provider is disposed first.
Future<void> _debounce(Ref ref, Duration delay) {
  final completer = Completer<void>();
  final timer = Timer(delay, () {
    if (!completer.isCompleted) completer.complete();
  });
  ref.onDispose(timer.cancel);
  return completer.future;
}

/// Agent and model chosen in the composer before a session exists.
final class SessionComposerDraft {
  /// Creates a composer draft.
  const SessionComposerDraft({
    this.agentDefinitionId,
    this.model,
    this.mode = SessionMode.normal,
    this.reasoningEffort,
    this.permissionMode,
    this.serviceTier,
  });

  /// Explicitly chosen agent definition; null falls back to the first usable.
  final String? agentDefinitionId;

  /// Explicitly chosen provider and model; null inherits the agent definition.
  final SessionModelSelectionDto? model;

  /// Collaboration mode the next session starts in.
  final SessionMode mode;

  /// Explicitly chosen reasoning effort; null inherits the agent definition.
  final String? reasoningEffort;

  /// Explicitly chosen permission mode; null inherits the agent definition.
  final PermissionMode? permissionMode;

  /// Explicitly chosen provider service tier; null uses the provider default.
  final String? serviceTier;

  /// Returns a copy with the given fields replaced.
  ///
  /// Every nullable field takes a wrapper so passing an explicit null clears
  /// the override instead of being read as "leave unchanged".
  SessionComposerDraft copyWith({
    SessionMode? mode,
    ({String? value})? agentDefinitionId,
    ({SessionModelSelectionDto? value})? model,
    ({String? value})? reasoningEffort,
    ({PermissionMode? value})? permissionMode,
    ({String? value})? serviceTier,
  }) => SessionComposerDraft(
    agentDefinitionId: agentDefinitionId == null
        ? this.agentDefinitionId
        : agentDefinitionId.value,
    model: model == null ? this.model : model.value,
    mode: mode ?? this.mode,
    reasoningEffort: reasoningEffort == null
        ? this.reasoningEffort
        : reasoningEffort.value,
    permissionMode: permissionMode == null
        ? this.permissionMode
        : permissionMode.value,
    serviceTier: serviceTier == null ? this.serviceTier : serviceTier.value,
  );
}

@Riverpod(keepAlive: true)
/// Holds the composer selection used to create the next session.
class SessionComposerDraftController extends _$SessionComposerDraftController {
  @override
  SessionComposerDraft build(
    String hostId,
    String? worktreeId,
    String draftId,
  ) => const SessionComposerDraft();

  /// Chooses the agent definition and drops every override bound to the old
  /// agent, so the new definition supplies its own defaults.
  void selectAgent(String agentDefinitionId) => state = SessionComposerDraft(
    agentDefinitionId: agentDefinitionId,
    mode: state.mode,
  );

  /// Chooses the provider and model override, or clears it when null.
  void selectModel(SessionModelSelectionDto? model) => state = state.copyWith(
    model: (value: model),
    // A different model may not support the previous tier or effort.
    reasoningEffort: const (value: null),
    serviceTier: const (value: null),
  );

  /// Chooses the collaboration mode the next session starts in.
  void selectMode(SessionMode mode) => state = state.copyWith(mode: mode);

  /// Chooses the reasoning effort override, or clears it when null.
  void selectReasoningEffort(String? reasoningEffort) =>
      state = state.copyWith(reasoningEffort: (value: reasoningEffort));

  /// Chooses the permission mode override, or clears it when null.
  void selectPermissionMode(PermissionMode? permissionMode) =>
      state = state.copyWith(permissionMode: (value: permissionMode));

  /// Chooses the provider service tier, or clears it when null.
  void selectServiceTier(String? serviceTier) =>
      state = state.copyWith(serviceTier: (value: serviceTier));
}
