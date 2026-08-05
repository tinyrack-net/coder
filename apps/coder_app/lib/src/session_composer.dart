import 'dart:async';
import 'dart:typed_data';

import 'package:coder_app/l10n/gen/app_localizations.dart';
import 'package:coder_app/src/attachment_ports.dart';
import 'package:coder_app/src/chat/chat_plan_actions.dart';
import 'package:coder_app/src/coder_icons.dart';
import 'package:coder_app/src/controller.dart';
import 'package:coder_app/src/host_models.dart';
import 'package:coder_app/src/model_picker.dart';
import 'package:coder_app/src/session_model_options.dart';
import 'package:coder_app/src/session_title.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

/// Agent and model selectors shown above the chat input.
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

  /// Provider-qualified model currently in effect, if any resolves.
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
            icon: CoderIcons.checklist,
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
            icon: CoderIcons.agent,
            label: agent?.name ?? 'Agent',
            tooltip: agentEnabled
                ? l10n.composerSelectAgent
                : l10n.composerAgentLocked,
            menuChildren: enabled && agentEnabled && definitions.isNotEmpty
                ? <Widget>[
                    for (final definition in definitions)
                      TRMenuItem(
                        key: ValueKey(
                          'session-composer-agent-${definition.id}',
                        ),
                        onPressed: () => widget.onAgentChanged(definition.id),
                        child: Text(definition.name),
                      ),
                  ]
                : null,
          ),
          const SizedBox(width: 8),
          ComposerChip(
            valueKey: const ValueKey('session-composer-model'),
            icon: CoderIcons.memory,
            label: modelLabel ?? selection?.modelId ?? l10n.composerModel,
            tooltip: l10n.composerSelectModel,
            onPressed: enabled && connections.isNotEmpty ? _chooseModel : null,
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

  Future<void> _chooseModel(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final state = ref
        .read(providerSettingsControllerProvider(widget.hostId))
        .value;
    final connections = usableConnections(
      state?.connections ?? const <ProviderConnectionDto>[],
    );
    await Future.wait<void>(
      connections.map((connection) => _ensureModelsLoaded(connection.id)),
    );
    if (!context.mounted) return;
    final loaded = ref
        .read(providerSettingsControllerProvider(widget.hostId))
        .value;
    final options = <ModelPickerOption>[
      for (final connection in connections)
        for (final model
            in loaded?.models[connection.id] ?? const <ProviderModelDto>[])
          ModelPickerOption(
            providerName: connection.displayName,
            model: model,
          ),
    ];
    final chosen = await showModelPicker(
      context,
      options: options,
      currentSelection: widget.selection,
      title: l10n.composerSelectModel,
      inheritLabel: _selectedAgent?.model.source == AgentModelSource.fixed
          ? l10n.composerInheritModel
          : null,
    );
    if (chosen == null) return;
    switch (chosen) {
      case SelectedModelPickerChoice(:final selection):
        widget.onModelChanged(selection);
      case InheritModelPickerChoice():
        widget.onModelChanged(null);
    }
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
    this.menuChildren,
    this.onPressed,
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

  /// Tap handler receiving the chip's own context.
  final void Function(BuildContext chipContext)? onPressed;

  /// Anchored menu entries. When supplied, the chip is a [TRMenu] trigger.
  final List<Widget>? menuChildren;

  /// Whether the chip renders as active.
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 18),
        const SizedBox(width: TRSpacing.extraSmall),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
    final control = menuChildren == null
        ? TRButton(
            key: valueKey,
            appearance: selected ? TRAppearance.solid : TRAppearance.outline,
            intent: selected ? TRIntent.primary : TRIntent.neutral,
            onPressed: onPressed == null ? null : () => onPressed!(context),
            child: content,
          )
        : TRMenu(
            key: valueKey,
            enabled: menuChildren!.isNotEmpty,
            trigger: content,
            menuChildren: menuChildren!,
          );
    return TRTooltip(message: tooltip, child: control);
  }
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
              : (effective == null ? l10n.composerSelectModelFirst : null),
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
          attachmentInput: ref.read(attachmentInputProvider),
          onSubmit: (submission) => _start(ref, submission, agent!, draft),
        ),
      ],
    );
  }

  Future<void> _start(
    WidgetRef ref,
    ComposerSubmission submission,
    AgentDefinitionDto agent,
    SessionComposerDraft draft,
  ) async {
    onCreated(
      await startSessionWithPrompt(
        ref,
        selection: selection,
        agentDefinitionId: agent.id,
        title: deriveSessionTitle(
          submission.text.isEmpty
              ? submission.attachments.first.fileName
              : submission.text,
        ),
        prompt: submission.text,
        attachments: submission.attachments,
        mode: draft.mode,
        model: draft.model,
      ),
    );
  }
}

/// Chat input with the agent and model selectors above it.
class SessionComposer extends StatefulWidget {
  /// Creates a [SessionComposer].
  const SessionComposer({
    required this.bar,
    required this.onSubmit,
    required this.enabled,
    this.onModeToggled,
    this.header,
    this.hint,
    this.attachmentInput,
    super.key,
  });

  /// Selector row rendered above the input.
  final SessionComposerBar bar;

  /// Receives the trimmed prompt text.
  final FutureOr<void> Function(ComposerSubmission submission) onSubmit;

  /// Native input boundary; null disables picker, paste, and drop.
  final AttachmentInputPort? attachmentInput;

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
  final List<PendingAttachment> _attachments = <PendingAttachment>[];
  bool _submitting = false;
  bool _dragging = false;
  String? _attachmentError;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = SafeArea(
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
            if (_attachments.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: <Widget>[
                  for (var index = 0; index < _attachments.length; index += 1)
                    _PendingAttachmentPill(
                      key: ValueKey('pending-attachment-$index'),
                      attachment: _attachments[index],
                      uploading: _submitting,
                      onRemove: _submitting
                          ? null
                          : () => setState(() => _attachments.removeAt(index)),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                TRIconButton(
                  key: const ValueKey('session-composer-attach'),
                  appearance: TRAppearance.ghost,
                  onPressed:
                      widget.enabled &&
                          !_submitting &&
                          widget.attachmentInput != null
                      ? _pickFiles
                      : null,
                  icon: const Icon(CoderIcons.paperclip),
                  label: 'Attach files',
                ),
                const SizedBox(width: 8),
                Expanded(
                  // Shift+Tab cycles the mode instead of moving focus.
                  child: Focus(
                    onKeyEvent: _handleKey,
                    child: TRTextField(
                      key: const ValueKey('session-composer-input'),
                      controller: _controller,
                      minLines: 1,
                      maxLines: 8,
                      enabled: widget.enabled && !_submitting,
                      placeholder: AppLocalizations.of(
                        context,
                      ).composerInputHint,
                      onSubmitted: widget.enabled && !_submitting
                          ? (_) => unawaited(_submit())
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TRIconButton(
                  key: const ValueKey('session-composer-send'),
                  intent: TRIntent.primary,
                  onPressed: widget.enabled && !_submitting
                      ? () => unawaited(_submit())
                      : null,
                  icon: const Icon(CoderIcons.send),
                  label: AppLocalizations.of(context).composerSendLabel,
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
            if (_attachmentError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _attachmentError!,
                  key: const ValueKey('session-composer-attachment-error'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
    final input = widget.attachmentInput;
    if (input == null || !input.supportsDrop) return content;
    return DropRegion(
      formats: Formats.standardFormats,
      onDropOver: (_) => widget.enabled && !_submitting
          ? DropOperation.copy
          : DropOperation.none,
      onDropEnter: (_) => setState(() => _dragging = true),
      onDropLeave: (_) => setState(() => _dragging = false),
      onPerformDrop: (event) async {
        setState(() => _dragging = false);
        await _addFiles(input.droppedFiles(event));
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: _dragging
              ? Border.all(color: Theme.of(context).colorScheme.primary)
              : null,
        ),
        child: content,
      ),
    );
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.keyV &&
        (HardwareKeyboard.instance.logicalKeysPressed.contains(
              LogicalKeyboardKey.controlLeft,
            ) ||
            HardwareKeyboard.instance.logicalKeysPressed.contains(
              LogicalKeyboardKey.controlRight,
            ) ||
            HardwareKeyboard.instance.logicalKeysPressed.contains(
              LogicalKeyboardKey.metaLeft,
            ) ||
            HardwareKeyboard.instance.logicalKeysPressed.contains(
              LogicalKeyboardKey.metaRight,
            ))) {
      final input = widget.attachmentInput;
      if (input != null) unawaited(_addFiles(input.pasteFiles()));
      return KeyEventResult.ignored;
    }
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

  Future<void> _pickFiles() async {
    final input = widget.attachmentInput;
    if (input != null) await _addFiles(input.pickFiles());
  }

  Future<void> _addFiles(Future<List<PendingAttachment>> pending) async {
    try {
      final files = await pending;
      if (_attachments.length + files.length > maxPendingAttachmentCount) {
        throw const FormatException('A turn accepts at most 10 attachments.');
      }
      if (!mounted) return;
      setState(() {
        _attachmentError = null;
        _attachments.addAll(files);
      });
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() => _attachmentError = '$error');
    }
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty && _attachments.isEmpty) return;
    final submission = ComposerSubmission(
      text: text,
      attachments: List<PendingAttachment>.unmodifiable(_attachments),
    );
    setState(() {
      _submitting = true;
      _attachmentError = null;
    });
    try {
      await widget.onSubmit(submission);
      if (!mounted) return;
      _controller.clear();
      setState(_attachments.clear);
    } on Exception catch (error) {
      if (mounted) setState(() => _attachmentError = '$error');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

class _PendingAttachmentPill extends StatelessWidget {
  const _PendingAttachmentPill({
    required this.attachment,
    required this.uploading,
    required this.onRemove,
    super.key,
  });

  final PendingAttachment attachment;
  final bool uploading;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(maxWidth: 260),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (uploading)
          const SizedBox.square(
            dimension: 24,
            child: Center(child: TRSpinner()),
          )
        else
          _PendingAttachmentPreview(attachment: attachment),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            '${attachment.fileName} · ${_formatBytes(attachment.byteSize)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 4),
        TRIconButton(
          key: ValueKey('remove-${attachment.fileName}'),
          appearance: TRAppearance.ghost,
          onPressed: onRemove,
          icon: const Icon(CoderIcons.close),
          label: 'Remove ${attachment.fileName}',
        ),
      ],
    ),
  );
}

class _PendingAttachmentPreview extends StatefulWidget {
  const _PendingAttachmentPreview({required this.attachment});

  final PendingAttachment attachment;

  @override
  State<_PendingAttachmentPreview> createState() =>
      _PendingAttachmentPreviewState();
}

class _PendingAttachmentPreviewState extends State<_PendingAttachmentPreview> {
  Future<Uint8List>? _bytes;

  @override
  void initState() {
    super.initState();
    if (widget.attachment.isImage) _bytes = _read();
  }

  Future<Uint8List> _read() async {
    final builder = BytesBuilder(copy: false);
    await widget.attachment.openRead().forEach(builder.add);
    return builder.takeBytes();
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _bytes;
    if (bytes == null) return const Icon(CoderIcons.file, size: 16);
    return FutureBuilder<Uint8List>(
      future: bytes,
      builder: (context, snapshot) => snapshot.hasData
          ? ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: Image.memory(
                snapshot.data!,
                width: 24,
                height: 24,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Icon(
                  CoderIcons.image,
                  size: 16,
                ),
              ),
            )
          : const SizedBox.square(
              dimension: 24,
              child: Center(child: TRSpinner()),
            ),
    );
  }
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
