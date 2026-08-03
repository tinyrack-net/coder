import 'dart:async';

import 'package:coder_app/src/controller.dart';
import 'package:coder_app/src/host_models.dart';
import 'package:coder_app/src/model_picker.dart';
import 'package:coder_app/src/session_model_options.dart';
import 'package:coder_app/src/session_title.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Agent, provider, and model selectors shown above the chat input.
class SessionComposerBar extends ConsumerStatefulWidget {
  /// Creates a [SessionComposerBar].
  const SessionComposerBar({
    required this.hostId,
    required this.definitions,
    required this.agentDefinitionId,
    required this.selection,
    required this.onAgentChanged,
    required this.onModelChanged,
    this.agentEnabled = true,
    this.enabled = true,
    super.key,
  });

  /// Daemon profile owning the provider connections.
  final String hostId;

  /// Agent definitions the user may choose from.
  final List<AgentDefinitionDto> definitions;

  /// Agent definition currently in effect.
  final String? agentDefinitionId;

  /// Provider and model currently in effect, if any resolve.
  final SessionModelSelectionDto? selection;

  /// Called with the newly chosen agent definition id.
  final ValueChanged<String> onAgentChanged;

  /// Called with the chosen override, or null to inherit the agent definition.
  final ValueChanged<SessionModelSelectionDto?> onModelChanged;

  /// Whether the agent can still be changed; false once a session exists.
  final bool agentEnabled;

  /// Whether any selector accepts input.
  final bool enabled;

  @override
  ConsumerState<SessionComposerBar> createState() => _SessionComposerBarState();
}

class _SessionComposerBarState extends ConsumerState<SessionComposerBar> {
  @override
  Widget build(BuildContext context) {
    final hostId = widget.hostId;
    final definitions = widget.definitions;
    final selection = widget.selection;
    final agentEnabled = widget.agentEnabled;
    final enabled = widget.enabled;
    final providers = ref
        .watch(providerSettingsControllerProvider(hostId))
        .asData
        ?.value;
    final connections = usableConnections(
      providers?.connections ?? const <ProviderConnectionDto>[],
    );
    final agent = definitions
        .where((definition) => definition.id == widget.agentDefinitionId)
        .firstOrNull;
    final connection = connections
        .where((item) => item.id == selection?.providerConnectionId)
        .firstOrNull;
    final models =
        providers?.models[connection?.id] ?? const <ProviderModelDto>[];
    final modelLabel = models
        .where((model) => model.id == selection?.modelId)
        .firstOrNull
        ?.label;
    // Labels come from the model catalog, so load it once per connection
    // instead of showing a raw model id.
    if (connection != null && _loadedModels(connection.id) == null) {
      unawaited(_ensureModelsLoaded(connection.id));
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          _ComposerChip(
            valueKey: const ValueKey('session-composer-agent'),
            icon: Icons.smart_toy_outlined,
            label: agent?.name ?? 'Agent',
            tooltip: agentEnabled ? 'Agent 선택' : '세션 생성 후에는 Agent를 바꿀 수 없습니다.',
            onPressed: enabled && agentEnabled && definitions.isNotEmpty
                ? () => _chooseAgent(context)
                : null,
          ),
          const SizedBox(width: 8),
          _ComposerChip(
            valueKey: const ValueKey('session-composer-provider'),
            icon: Icons.cloud_outlined,
            label: connection?.displayName ?? 'Provider',
            tooltip: 'Provider 선택',
            onPressed: enabled && connections.isNotEmpty
                ? () => _chooseProvider(context, connections)
                : null,
          ),
          const SizedBox(width: 8),
          _ComposerChip(
            valueKey: const ValueKey('session-composer-model'),
            icon: Icons.memory_outlined,
            label: modelLabel ?? selection?.modelId ?? '모델',
            tooltip: '모델 선택',
            onPressed: enabled && connection != null
                ? () => _chooseModel(context, connection.id)
                : null,
          ),
        ],
      ),
    );
  }

  List<ProviderModelDto>? _loadedModels(String connectionId) => ref
      .read(providerSettingsControllerProvider(widget.hostId))
      .asData
      ?.value
      ?.models[connectionId];

  Future<void> _ensureModelsLoaded(String connectionId) async {
    if (_loadedModels(connectionId) != null) return;
    await ref
        .read(providerSettingsControllerProvider(widget.hostId).notifier)
        .loadModels(connectionId);
  }

  Future<void> _chooseAgent(BuildContext context) async {
    final chosen = await showMenu<String>(
      context: context,
      position: _anchorAt(context),
      items: <PopupMenuEntry<String>>[
        for (final definition in widget.definitions)
          PopupMenuItem<String>(
            key: ValueKey('session-composer-agent-${definition.id}'),
            value: definition.id,
            child: Text(definition.name),
          ),
      ],
    );
    if (chosen != null) widget.onAgentChanged(chosen);
  }

  Future<void> _chooseProvider(
    BuildContext context,
    List<ProviderConnectionDto> connections,
  ) async {
    final chosen = await showMenu<String>(
      context: context,
      position: _anchorAt(context),
      items: <PopupMenuEntry<String>>[
        for (final connection in connections)
          PopupMenuItem<String>(
            key: ValueKey('session-composer-provider-${connection.id}'),
            value: connection.id,
            child: Text(connection.displayName),
          ),
      ],
    );
    if (chosen == null || !context.mounted) return;
    final connection = connections.singleWhere((item) => item.id == chosen);
    final defaultModelId = connection.defaultModelId;
    if (defaultModelId != null) {
      widget.onModelChanged(
        SessionModelSelectionDto(
          providerConnectionId: chosen,
          modelId: defaultModelId,
        ),
      );
      return;
    }
    // Without a default model the provider alone cannot run a turn, so the
    // user has to pick one right away.
    await _chooseModel(context, chosen);
  }

  Future<void> _chooseModel(BuildContext context, String connectionId) async {
    await _ensureModelsLoaded(connectionId);
    if (!context.mounted) return;
    final models = _loadedModels(connectionId) ?? const <ProviderModelDto>[];
    if (models.isEmpty) return;
    final chosen = await showModelPicker(
      context,
      connectionId: connectionId,
      models: models,
      currentModelId: connectionId == widget.selection?.providerConnectionId
          ? widget.selection?.modelId
          : null,
      title: '모델 선택',
      inheritLabel: 'Agent 기본값 사용',
    );
    if (chosen == null) return;
    widget.onModelChanged(
      chosen == inheritModelSentinel
          ? null
          : SessionModelSelectionDto(
              providerConnectionId: connectionId,
              modelId: chosen,
            ),
    );
  }

  RelativeRect _anchorAt(BuildContext context) {
    final box = context.findRenderObject()! as RenderBox;
    final origin = box.localToGlobal(Offset.zero);
    return RelativeRect.fromLTRB(
      origin.dx,
      origin.dy,
      origin.dx + box.size.width,
      origin.dy + box.size.height,
    );
  }
}

class _ComposerChip extends StatelessWidget {
  const _ComposerChip({
    required this.valueKey,
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.onPressed,
  });

  final ValueKey<String> valueKey;
  final IconData icon;
  final String label;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: ActionChip(
      key: valueKey,
      avatar: Icon(icon, size: 18),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      onPressed: onPressed,
    ),
  );
}

/// Composer shown when no session is selected; the first prompt creates one.
class DraftSessionPane extends ConsumerWidget {
  /// Creates a [DraftSessionPane].
  const DraftSessionPane({
    required this.selection,
    required this.onCreated,
    super.key,
  });

  /// Worktree the new session belongs to.
  final WorkspaceSelection selection;

  /// Called after the session exists and its first turn has started.
  final ValueChanged<SessionDto> onCreated;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agents = ref
        .watch(agentDefinitionsControllerProvider(selection.hostId))
        .asData
        ?.value;
    final providers = ref
        .watch(providerSettingsControllerProvider(selection.hostId))
        .asData
        ?.value;
    final draft = ref.watch(
      sessionComposerDraftControllerProvider(
        selection.hostId,
        selection.worktreeId,
      ),
    );
    final definitions = selectableAgentDefinitions(
      agents?.definitions ?? const <AgentDefinitionDto>[],
    );
    final agent =
        definitions
            .where((definition) => definition.id == draft.agentDefinitionId)
            .firstOrNull ??
        definitions.firstOrNull;
    final connections =
        providers?.connections ?? const <ProviderConnectionDto>[];
    final effective =
        draft.model ??
        (agent == null ? null : defaultSelectionFor(agent, connections));
    final notifier = ref.read(
      sessionComposerDraftControllerProvider(
        selection.hostId,
        selection.worktreeId,
      ).notifier,
    );
    return Column(
      children: <Widget>[
        const Expanded(child: Center(child: Text('코딩 요청으로 새 session을 시작하세요.'))),
        SessionComposer(
          enabled: agent != null && effective != null,
          hint: agent == null
              ? '사용 가능한 primary Agent가 없습니다.'
              : (effective == null ? '사용할 Provider와 모델을 먼저 선택하세요.' : null),
          bar: SessionComposerBar(
            hostId: selection.hostId,
            definitions: definitions,
            agentDefinitionId: agent?.id,
            selection: effective,
            onAgentChanged: notifier.selectAgent,
            onModelChanged: notifier.selectModel,
          ),
          onSubmit: (prompt) => unawaited(_start(ref, prompt, agent!, draft)),
        ),
      ],
    );
  }

  Future<void> _start(
    WidgetRef ref,
    String prompt,
    AgentDefinitionDto agent,
    SessionComposerDraft draft,
  ) async {
    final session = await ref
        .read(
          sessionsControllerProvider(
            selection.hostId,
            selection.worktreeId,
          ).notifier,
        )
        .create(
          title: deriveSessionTitle(prompt),
          agentDefinitionId: agent.id,
          model: draft.model,
        );
    await ref
        .read(sessionTabsControllerProvider(selection).notifier)
        .add(session);
    // Started before navigation because this pane unmounts on route change;
    // the timeline subscription replays persisted events afterwards.
    await ref
        .read(
          conversationControllerProvider(selection.hostId, session.id).notifier,
        )
        .startTurn(prompt);
    onCreated(session);
  }
}

/// Chat input with the agent, provider, and model selectors above it.
class SessionComposer extends StatefulWidget {
  /// Creates a [SessionComposer].
  const SessionComposer({
    required this.bar,
    required this.onSubmit,
    required this.enabled,
    this.hint,
    super.key,
  });

  /// Selector row rendered above the input.
  final SessionComposerBar bar;

  /// Receives the trimmed prompt text.
  final ValueChanged<String> onSubmit;

  /// Whether the prompt can be typed and sent.
  final bool enabled;

  /// Reason shown below the input when sending is unavailable.
  final String? hint;

  @override
  State<SessionComposer> createState() => _SessionComposerState();
}

class _SessionComposerState extends State<SessionComposer> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          widget.bar,
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  key: const ValueKey('session-composer-input'),
                  controller: _controller,
                  minLines: 1,
                  maxLines: 8,
                  enabled: widget.enabled,
                  decoration: const InputDecoration(
                    hintText: '코딩 요청을 입력하세요…',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: widget.enabled ? (_) => _submit() : null,
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                key: const ValueKey('session-composer-send'),
                onPressed: widget.enabled ? _submit : null,
                icon: const Icon(Icons.arrow_upward),
              ),
            ],
          ),
          if (widget.hint != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                widget.hint!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
        ],
      ),
    ),
  );

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    widget.onSubmit(text);
  }
}
