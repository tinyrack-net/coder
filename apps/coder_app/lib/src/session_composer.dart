import 'dart:async';

import 'package:coder_app/l10n/gen/app_localizations.dart';
import 'package:coder_app/src/chat/chat_plan_actions.dart';
import 'package:coder_app/src/composer_menu.dart';
import 'package:coder_app/src/controller.dart';
import 'package:coder_app/src/host_models.dart';
import 'package:coder_app/src/model_picker.dart';
import 'package:coder_app/src/session_model_options.dart';
import 'package:coder_app/src/session_title.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    required this.mode,
    required this.onModeChanged,
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

  /// Collaboration mode currently in effect.
  final SessionMode mode;

  /// Called with the mode to switch to.
  final ValueChanged<SessionMode> onModeChanged;

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
    final planning = widget.mode == SessionMode.plan;
    // Keep the loaded connections while the provider refreshes.
    final providers = ref
        .watch(providerSettingsControllerProvider(hostId))
        .value;
    final l10n = AppLocalizations.of(context);
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
          ComposerChip(
            valueKey: const ValueKey('session-composer-mode'),
            icon: Icons.checklist_rtl,
            label: planning ? l10n.composerPlan : l10n.composerRun,
            tooltip: planning
                ? l10n.composerPlanTooltip
                : l10n.composerRunTooltip,
            selected: planning,
            onPressed: enabled
                ? (_) => widget.onModeChanged(
                    planning ? SessionMode.normal : SessionMode.plan,
                  )
                : null,
          ),
          const SizedBox(width: 8),
          ComposerChip(
            valueKey: const ValueKey('session-composer-agent'),
            icon: Icons.smart_toy_outlined,
            label: agent?.name ?? 'Agent',
            tooltip: agentEnabled
                ? l10n.composerSelectAgent
                : l10n.composerAgentLocked,
            onPressed: enabled && agentEnabled && definitions.isNotEmpty
                ? _chooseAgent
                : null,
          ),
          const SizedBox(width: 8),
          ComposerChip(
            valueKey: const ValueKey('session-composer-provider'),
            icon: Icons.cloud_outlined,
            label: connection?.displayName ?? 'Provider',
            tooltip: l10n.composerSelectProvider,
            onPressed: enabled && connections.isNotEmpty
                ? (chipContext) => _chooseProvider(chipContext, connections)
                : null,
          ),
          const SizedBox(width: 8),
          ComposerChip(
            valueKey: const ValueKey('session-composer-model'),
            icon: Icons.memory_outlined,
            label: modelLabel ?? selection?.modelId ?? l10n.composerModel,
            tooltip: l10n.composerSelectModel,
            onPressed: enabled && connection != null
                ? (chipContext) => _chooseModel(chipContext, connection.id)
                : null,
          ),
        ],
      ),
    );
  }

  List<ProviderModelDto>? _loadedModels(String connectionId) => ref
      .read(providerSettingsControllerProvider(widget.hostId))
      .value
      ?.models[connectionId];

  Future<void> _ensureModelsLoaded(String connectionId) async {
    if (_loadedModels(connectionId) != null) return;
    await ref
        .read(providerSettingsControllerProvider(widget.hostId).notifier)
        .loadModels(connectionId);
  }

  Future<void> _chooseAgent(BuildContext context) async {
    final chosen = await showComposerMenu<String>(
      context,
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
    final chosen = await showComposerMenu<String>(
      context,
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
    await _chooseModel(context, chosen);
  }

  Future<void> _chooseModel(BuildContext context, String connectionId) async {
    final l10n = AppLocalizations.of(context);
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
      title: l10n.composerSelectModel,
      inheritLabel: _selectedAgent?.model.source == AgentModelSource.fixed
          ? l10n.composerInheritModel
          : null,
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

  AgentDefinitionDto? get _selectedAgent => widget.definitions
      .where((definition) => definition.id == widget.agentDefinitionId)
      .firstOrNull;
}

/// Compact selector chip shared by the composers.
class ComposerChip extends StatelessWidget {
  /// Creates a composer chip.
  const ComposerChip({
    required this.valueKey,
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.onPressed,
    this.selected = false,
    super.key,
  });

  /// Stable key used by tests and by the enclosing row.
  final ValueKey<String> valueKey;

  /// Leading glyph.
  final IconData icon;

  /// Chip label.
  final String label;

  /// Hover and long-press description.
  final String tooltip;

  /// Tap handler receiving the chip's own context; null disables the chip.
  final void Function(BuildContext chipContext)? onPressed;

  /// Whether the chip renders as active.
  final bool selected;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: ActionChip(
      key: valueKey,
      avatar: Icon(icon, size: 18),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      backgroundColor: selected
          ? Theme.of(context).colorScheme.primaryContainer
          : null,
      onPressed: onPressed == null ? null : () => onPressed!(context),
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
        .value;
    final providers = ref
        .watch(providerSettingsControllerProvider(selection.hostId))
        .value;
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
    final l10n = AppLocalizations.of(context);
    final connections =
        providers?.connections ?? const <ProviderConnectionDto>[];
    final effective =
        draft.model ??
        (agent == null ? null : agentSelectionFor(agent, connections));
    final notifier = ref.read(
      sessionComposerDraftControllerProvider(
        selection.hostId,
        selection.worktreeId,
      ).notifier,
    );
    return Column(
      children: <Widget>[
        Expanded(child: Center(child: Text(l10n.composerStartHint))),
        SessionComposer(
          enabled: agent != null && effective != null,
          hint: agent == null
              ? l10n.composerNoPrimaryAgent
              : (effective == null ? l10n.composerSelectProviderFirst : null),
          bar: SessionComposerBar(
            hostId: selection.hostId,
            definitions: definitions,
            agentDefinitionId: agent?.id,
            selection: effective,
            onAgentChanged: notifier.selectAgent,
            onModelChanged: notifier.selectModel,
            mode: draft.mode,
            onModeChanged: notifier.selectMode,
          ),
          onModeToggled: () => notifier.selectMode(
            draft.mode == SessionMode.plan
                ? SessionMode.normal
                : SessionMode.plan,
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
    onCreated(
      await startSessionWithPrompt(
        ref,
        selection: selection,
        agentDefinitionId: agent.id,
        title: deriveSessionTitle(prompt),
        prompt: prompt,
        mode: draft.mode,
        model: draft.model,
      ),
    );
  }
}

/// Chat input with the agent, provider, and model selectors above it.
class SessionComposer extends StatefulWidget {
  /// Creates a [SessionComposer].
  const SessionComposer({
    required this.bar,
    required this.onSubmit,
    required this.enabled,
    this.onModeToggled,
    this.header,
    this.hint,
    super.key,
  });

  /// Selector row rendered above the input.
  final SessionComposerBar bar;

  /// Receives the trimmed prompt text.
  final ValueChanged<String> onSubmit;

  /// Cycles the collaboration mode, mirroring the Shift+Tab shortcut.
  final VoidCallback? onModeToggled;

  /// Extra selectors rendered above [bar].
  final Widget? header;

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
          if (widget.header != null) ...<Widget>[
            widget.header!,
            const SizedBox(height: 8),
          ],
          widget.bar,
          if (widget.bar.mode == SessionMode.plan)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                AppLocalizations.of(context).composerPlanBanner,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                // Shift+Tab cycles the mode instead of moving focus.
                child: Focus(
                  onKeyEvent: _handleKey,
                  child: TextField(
                    key: const ValueKey('session-composer-input'),
                    controller: _controller,
                    minLines: 1,
                    maxLines: 8,
                    enabled: widget.enabled,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context).composerInputHint,
                      border: const OutlineInputBorder(),
                    ),
                    onSubmitted: widget.enabled ? (_) => _submit() : null,
                  ),
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

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    final toggle = widget.onModeToggled;
    if (toggle == null || event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey != LogicalKeyboardKey.tab) {
      return KeyEventResult.ignored;
    }
    final pressed = HardwareKeyboard.instance.logicalKeysPressed;
    if (!pressed.contains(LogicalKeyboardKey.shiftLeft) &&
        !pressed.contains(LogicalKeyboardKey.shiftRight)) {
      return KeyEventResult.ignored;
    }
    toggle();
    return KeyEventResult.handled;
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    widget.onSubmit(text);
  }
}
