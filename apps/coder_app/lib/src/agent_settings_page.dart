import 'package:coder_app/l10n/gen/app_localizations.dart';
import 'package:coder_app/src/coder_icons.dart';
import 'package:coder_app/src/coder_list_row.dart';
import 'package:coder_app/src/coder_selection_row.dart';
import 'package:coder_app/src/controller.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

/// Markdown-backed agent manager for one connected daemon.
class AgentSettingsPage extends ConsumerStatefulWidget {
  /// Creates an agent settings page.
  const AgentSettingsPage({required this.hostId, super.key});

  /// App-local daemon profile identifier.
  final String hostId;

  @override
  ConsumerState<AgentSettingsPage> createState() => _AgentSettingsPageState();
}

class _AgentSettingsPageState extends ConsumerState<AgentSettingsPage> {
  String? _selectedId;

  @override
  void didUpdateWidget(AgentSettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hostId != widget.hostId) _selectedId = null;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(agentDefinitionsControllerProvider(widget.hostId));
    return state.when(
      loading: () => const Center(child: TRSpinner(uiSize: TRUiSize.md)),
      error: (error, _) => _AgentSettingsError(
        error: error,
        onRetry: () => ref.invalidate(
          agentDefinitionsControllerProvider(widget.hostId),
        ),
      ),
      data: (value) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 760;
            if (!compact &&
                !value.definitions.any(
                  (definition) => definition.id == _selectedId,
                )) {
              _selectedId = value.definitions.firstOrNull?.id;
            }
            final selected = value.definitions
                .where((definition) => definition.id == _selectedId)
                .firstOrNull;
            if (compact && selected != null) {
              return _AgentEditor(
                key: ValueKey<String>(selected.contentHash),
                hostId: widget.hostId,
                state: value,
                definition: selected,
                onBack: () => setState(() => _selectedId = null),
                onArchived: () => setState(() => _selectedId = null),
              );
            }
            final list = _AgentDefinitionList(
              state: value,
              selectedId: _selectedId,
              onSelected: (id) => setState(() => _selectedId = id),
              onCreate: () => _create(value),
            );
            if (compact) return list;
            return Row(
              children: <Widget>[
                SizedBox(width: 280, child: list),
                const VerticalDivider(width: 1),
                Expanded(
                  child: selected == null
                      ? Center(
                          child: Text(
                            AppLocalizations.of(
                              context,
                            ).agentSettingsSelectAgent,
                          ),
                        )
                      : _AgentEditor(
                          key: ValueKey<String>(selected.contentHash),
                          hostId: widget.hostId,
                          state: value,
                          definition: selected,
                          onArchived: () => setState(() => _selectedId = null),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _create(AgentDefinitionsState state) async {
    final created = await showTRDialog<AgentDefinitionDto>(
      context: context,
      builder: (context) => _CreateAgentDialog(
        existingIds: state.definitions
            .map((definition) => definition.id)
            .toSet(),
        onCreate: (input) {
          final template = state.definitions
              .where((definition) => definition.id == 'coder')
              .first;
          final definition = template.copyWith(
            id: input.id,
            name: input.name,
            description: '',
            mode: input.mode,
            systemPrompt: '',
            callableAgentIds: const <String>[],
            contentHash: '',
            sourcePath: '',
            isBuiltIn: false,
            isArchived: false,
            diagnostics: const <AgentDefinitionDiagnosticDto>[],
          );
          return ref
              .read(
                agentDefinitionsControllerProvider(widget.hostId).notifier,
              )
              .create(input.id, definition);
        },
      ),
    );
    if (created != null && mounted) {
      setState(() => _selectedId = created.id);
    }
  }
}

class _AgentDefinitionList extends StatelessWidget {
  const _AgentDefinitionList({
    required this.state,
    required this.selectedId,
    required this.onSelected,
    required this.onCreate,
  });

  final AgentDefinitionsState state;
  final String? selectedId;
  final ValueChanged<String> onSelected;
  final VoidCallback? onCreate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: <Widget>[
        CoderListRow(
          title: Text(l10n.agentSettingsHeading),
          subtitle: Text(l10n.agentSettingsCount(state.definitions.length)),
          trailing: TRIconButton(
            key: const ValueKey('agent-add-button'),
            appearance: TRAppearance.ghost,
            uiSize: TRUiSize.md,
            label: l10n.agentSettingsAdd,
            onPressed: onCreate,
            icon: const Icon(CoderIcons.add),
          ),
        ),
        const TRSeparator(),
        Expanded(
          child: ListView(
            children: <Widget>[
              for (final definition in state.definitions)
                CoderListRow(
                  selected: definition.id == selectedId,
                  leading: Icon(
                    definition.mode == AgentMode.primary
                        ? CoderIcons.agent
                        : CoderIcons.branch,
                  ),
                  title: Text(definition.name),
                  subtitle: Text(
                    definition.isStale
                        ? '${definition.mode.name} · stale'
                        : definition.mode.name,
                  ),
                  trailing: definition.diagnostics.isEmpty
                      ? null
                      : const Icon(CoderIcons.warning, size: 18),
                  onTap: () => onSelected(definition.id),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AgentEditor extends StatefulWidget {
  const _AgentEditor({
    required this.hostId,
    required this.state,
    required this.definition,
    required this.onArchived,
    this.onBack,
    super.key,
  });

  final String hostId;
  final AgentDefinitionsState state;
  final AgentDefinitionDto definition;
  final VoidCallback onArchived;
  final VoidCallback? onBack;

  @override
  State<_AgentEditor> createState() => _AgentEditorState();
}

class _AgentEditorState extends State<_AgentEditor> {
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _prompt;
  late final TextEditingController _providerConnectionId;
  late final TextEditingController _modelId;
  late bool _promptEnabled;
  late AgentModelSource _modelSource;
  late String _reasoningEffort;
  late PermissionMode _permissionMode;
  late Set<String> _tools;
  late Set<String> _callableAgents;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final definition = widget.definition;
    _name = TextEditingController(text: definition.name);
    _description = TextEditingController(text: definition.description);
    _prompt = TextEditingController(text: definition.systemPrompt);
    _providerConnectionId = TextEditingController(
      text: definition.model.providerConnectionId,
    );
    _modelId = TextEditingController(text: definition.model.modelId);
    _promptEnabled = definition.promptEnabled;
    _modelSource = definition.model.source;
    _reasoningEffort = definition.reasoningEffort;
    _permissionMode = definition.permissionMode;
    final alwaysOn = <String>{
      for (final tool in widget.state.tools)
        if (tool.alwaysOn) tool.id,
    };
    _tools = definition.toolIds.toSet()..removeAll(alwaysOn);
    _callableAgents = definition.callableAgentIds.toSet();
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _prompt.dispose();
    _providerConnectionId.dispose();
    _modelId.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final definition = widget.definition;
    final editable = !_saving;
    final subagents = widget.state.definitions.where(
      (candidate) =>
          candidate.mode == AgentMode.subagent &&
          !candidate.isArchived &&
          !candidate.isStale,
    );
    return Column(
      children: <Widget>[
        CoderListRow(
          leading: widget.onBack == null
              ? null
              : TRIconButton(
                  key: const ValueKey('agent-list-button'),
                  appearance: TRAppearance.ghost,
                  uiSize: TRUiSize.md,
                  label: l10n.agentSettingsList,
                  onPressed: widget.onBack,
                  icon: const Icon(CoderIcons.back),
                ),
          title: Text(definition.name),
          subtitle: Text(definition.sourcePath),
          trailing: Wrap(
            children: <Widget>[
              TRIconButton(
                key: const ValueKey('agent-copy-path-button'),
                appearance: TRAppearance.ghost,
                uiSize: TRUiSize.md,
                label: l10n.agentSettingsCopyPath,
                onPressed: () => Clipboard.setData(
                  ClipboardData(text: definition.sourcePath),
                ),
                icon: const Icon(CoderIcons.copy),
              ),
              if (definition.isBuiltIn)
                TRIconButton(
                  key: const ValueKey('agent-reset-button'),
                  appearance: TRAppearance.ghost,
                  uiSize: TRUiSize.md,
                  label: l10n.agentSettingsReset,
                  onPressed: editable ? _reset : null,
                  icon: const Icon(CoderIcons.restore),
                )
              else
                TRIconButton(
                  key: const ValueKey('agent-archive-button'),
                  appearance: TRAppearance.ghost,
                  uiSize: TRUiSize.md,
                  label: l10n.workspaceArchive,
                  onPressed: editable ? _archive : null,
                  icon: const Icon(CoderIcons.archive),
                ),
              TRButton(
                intent: TRIntent.primary,
                uiSize: TRUiSize.md,
                onPressed: editable ? () => _save(force: false) : null,
                child: Text(_saving ? l10n.commonSaving : l10n.commonSave),
              ),
            ],
          ),
        ),
        const TRSeparator(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: <Widget>[
              if (definition.diagnostics.isNotEmpty)
                ...definition.diagnostics.map(
                  (diagnostic) => TRCard(
                    padding: TRCardPadding.none,
                    variant: TRCardVariant.elevated,
                    child: CoderListRow(
                      leading: const Icon(CoderIcons.warning),
                      title: Text(diagnostic.code),
                      subtitle: Text(diagnostic.message),
                    ),
                  ),
                ),
              TRTextField(
                uiSize: TRUiSize.md,
                controller: _name,
                enabled: editable,
                label: l10n.commonName,
              ),
              const SizedBox(height: 12),
              TRTextField(
                uiSize: TRUiSize.md,
                controller: _description,
                enabled: editable,
                label: l10n.commonDescription,
              ),
              const SizedBox(height: 12),
              TRTextField(
                uiSize: TRUiSize.md,
                initialValue: definition.mode.name,
                enabled: false,
                label: l10n.commonKind,
              ),
              CoderSwitchRow(
                value: _promptEnabled,
                onChanged: editable
                    ? (value) => setState(() => _promptEnabled = value)
                    : null,
                title: Text(l10n.agentSettingsCustomPrompt),
              ),
              TRTextField(
                uiSize: TRUiSize.md,
                controller: _prompt,
                enabled: editable,
                minLines: 8,
                maxLines: 18,
                label: 'System prompt (Markdown)',
              ),
              const SizedBox(height: 20),
              Text('Model', style: Theme.of(context).textTheme.titleMedium),
              TRRadioGroup(
                value: _modelSource.name,
                disabled: !editable,
                onValueChange: (value) => setState(
                  () => _modelSource = AgentModelSource.values.byName(value),
                ),
                children: [
                  TRRadio(
                    value: AgentModelSource.session.name,
                    label: Text(l10n.agentSettingsSessionModel),
                    uiSize: TRUiSize.md,
                  ),
                  TRRadio(
                    value: AgentModelSource.fixed.name,
                    label: Text(l10n.agentSettingsPinnedModel),
                    uiSize: TRUiSize.md,
                  ),
                ],
              ),
              if (_modelSource == AgentModelSource.fixed) ...<Widget>[
                TRTextField(
                  uiSize: TRUiSize.md,
                  controller: _providerConnectionId,
                  enabled: editable,
                  label: 'Provider connection ID',
                ),
                const SizedBox(height: 12),
                TRTextField(
                  uiSize: TRUiSize.md,
                  controller: _modelId,
                  enabled: editable,
                  label: 'Model ID',
                ),
              ],
              const SizedBox(height: 12),
              TRSelectFormField<String>(
                initialValue: _reasoningEffort,
                label: 'Reasoning',
                uiSize: TRUiSize.md,
                items: const <String>['low', 'medium', 'high']
                    .map(
                      (value) => TRSelectItem<String>(
                        value: value,
                        label: value,
                      ),
                    )
                    .toList(growable: false),
                onValueChange: editable
                    ? (value) => setState(() => _reasoningEffort = value!)
                    : null,
              ),
              const SizedBox(height: 12),
              TRSelectFormField<PermissionMode>(
                initialValue: _permissionMode,
                label: 'Permission',
                uiSize: TRUiSize.md,
                items: PermissionMode.values
                    .map(
                      (value) => TRSelectItem<PermissionMode>(
                        value: value,
                        label: value.name,
                      ),
                    )
                    .toList(growable: false),
                onValueChange: editable
                    ? (value) => setState(() => _permissionMode = value!)
                    : null,
              ),
              const SizedBox(height: 20),
              Text(
                l10n.agentSettingsBuiltinTools,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              for (final tool in _sortedTools)
                CoderCheckboxRow(
                  key: ValueKey<String>('agent-tool-tile-${tool.id}'),
                  value: tool.alwaysOn || _tools.contains(tool.id),
                  // An always-on tool has no toggle to offer, so the tile is
                  // checked and inert rather than lying about being editable.
                  onChanged: editable && !tool.alwaysOn
                      ? (enabled) => setState(() {
                          enabled!
                              ? _tools.add(tool.id)
                              : _tools.remove(tool.id);
                        })
                      : null,
                  secondary: tool.alwaysOn
                      ? Icon(
                          CoderIcons.lock,
                          key: ValueKey<String>('agent-tool-lock-${tool.id}'),
                        )
                      : null,
                  title: Text(tool.name),
                  subtitle: Text(
                    tool.alwaysOn
                        ? '${tool.description} · '
                              '${l10n.agentSettingsToolAlwaysOn}'
                        : tool.description,
                  ),
                ),
              if (definition.mode == AgentMode.primary) ...<Widget>[
                const SizedBox(height: 20),
                Text(
                  l10n.agentSettingsSubagents,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (subagents.isEmpty)
                  CoderListRow(title: Text(l10n.agentSettingsNoSubagents)),
                for (final subagent in subagents)
                  CoderCheckboxRow(
                    value: _callableAgents.contains(subagent.id),
                    onChanged: editable
                        ? (enabled) => setState(() {
                            enabled!
                                ? _callableAgents.add(subagent.id)
                                : _callableAgents.remove(subagent.id);
                          })
                        : null,
                    title: Text(subagent.name),
                    subtitle: Text(subagent.description),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Always-on tools first, so the inert tiles do not interleave with the
  /// ones the user can actually change.
  List<AgentToolDefinitionDto> get _sortedTools =>
      widget.state.tools.toList()..sort((left, right) {
        if (left.alwaysOn != right.alwaysOn) return left.alwaysOn ? -1 : 1;
        return left.name.compareTo(right.name);
      });

  AgentDefinitionDto _editedDefinition() => widget.definition.copyWith(
    name: _name.text.trim(),
    description: _description.text.trim(),
    promptEnabled: _promptEnabled,
    systemPrompt: _prompt.text,
    model: AgentModelSelectionDto(
      source: _modelSource,
      providerConnectionId: _modelSource == AgentModelSource.fixed
          ? _providerConnectionId.text.trim()
          : null,
      modelId: _modelSource == AgentModelSource.fixed
          ? _modelId.text.trim()
          : null,
    ),
    reasoningEffort: _reasoningEffort,
    permissionMode: _permissionMode,
    // Always-on ids are never written back: the daemon supplies them, so
    // repeating them in the frontmatter would only go stale.
    toolIds: _tools.toList(growable: false)..sort(),
    callableAgentIds: _callableAgents.toList(growable: false)..sort(),
  );

  Future<void> _save({required bool force}) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _saving = true);
    try {
      await ProviderScope.containerOf(context)
          .read(agentDefinitionsControllerProvider(widget.hostId).notifier)
          .saveDefinition(
            _editedDefinition(),
            expectedContentHash: widget.definition.contentHash,
            force: force,
          );
    } on Exception catch (error) {
      if (!mounted) return;
      final retry = await showTRDialog<bool>(
        context: context,
        builder: (context) => TRAlertDialog(
          title: Text(l10n.agentSettingsSaveFailedTitle),
          content: Text('$error'),
          actions: <TRButton>[
            TRButton(
              appearance: TRAppearance.ghost,
              uiSize: TRUiSize.md,
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.agentSettingsReload),
            ),
            TRButton(
              intent: TRIntent.primary,
              uiSize: TRUiSize.md,
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.agentSettingsOverwrite),
            ),
          ],
        ),
      );
      if (retry == true && mounted) await _save(force: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _archive() async {
    await ProviderScope.containerOf(context)
        .read(agentDefinitionsControllerProvider(widget.hostId).notifier)
        .archive(widget.definition.id);
    widget.onArchived();
  }

  Future<void> _reset() async {
    await ProviderScope.containerOf(context)
        .read(agentDefinitionsControllerProvider(widget.hostId).notifier)
        .resetCoder();
  }
}

class _CreateAgentInput {
  const _CreateAgentInput({
    required this.id,
    required this.name,
    required this.mode,
  });

  final String id;
  final String name;
  final AgentMode mode;
}

class _CreateAgentDialog extends StatefulWidget {
  const _CreateAgentDialog({
    required this.existingIds,
    required this.onCreate,
  });

  final Set<String> existingIds;
  final Future<AgentDefinitionDto> Function(_CreateAgentInput input) onCreate;

  @override
  State<_CreateAgentDialog> createState() => _CreateAgentDialogState();
}

class _CreateAgentDialogState extends State<_CreateAgentDialog> {
  final _id = TextEditingController();
  final _name = TextEditingController();
  AgentMode _mode = AgentMode.primary;
  bool _saving = false;
  Object? _error;

  /// Whether the typed ID is well-formed and unused.
  bool get _idAccepted {
    final id = _id.text.trim();
    return RegExp(r'^[a-z0-9][a-z0-9_-]{0,63}$').hasMatch(id) &&
        !widget.existingIds.contains(id);
  }

  String? _idError(AppLocalizations l10n) {
    final id = _id.text.trim();
    if (id.isEmpty) return null;
    if (!RegExp(r'^[a-z0-9][a-z0-9_-]{0,63}$').hasMatch(id)) {
      return l10n.agentSettingsIdInvalid;
    }
    if (widget.existingIds.contains(id)) return l10n.agentSettingsIdTaken;
    return null;
  }

  bool get _valid => _name.text.trim().isNotEmpty && _idAccepted;

  @override
  void dispose() {
    _id.dispose();
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TRAlertDialog(
      title: Text(l10n.agentSettingsAddTitle),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TRTextField(
              uiSize: TRUiSize.md,
              controller: _id,
              autofocus: true,
              enabled: !_saving,
              onChanged: (_) => setState(() => _error = null),
              label: l10n.agentSettingsIdLabel,
              placeholder: 'reviewer',
              errorText: _idError(l10n),
            ),
            TRTextField(
              uiSize: TRUiSize.md,
              controller: _name,
              enabled: !_saving,
              onChanged: (_) => setState(() => _error = null),
              label: l10n.commonName,
              errorText: _name.text.isEmpty || _name.text.trim().isNotEmpty
                  ? null
                  : l10n.agentSettingsNameRequired,
            ),
            TRSelectFormField<AgentMode>(
              initialValue: _mode,
              label: l10n.commonKind,
              uiSize: TRUiSize.md,
              items: AgentMode.values
                  .map(
                    (value) => TRSelectItem<AgentMode>(
                      value: value,
                      label: value.name,
                    ),
                  )
                  .toList(growable: false),
              onValueChange: _saving
                  ? null
                  : (value) => setState(() => _mode = value!),
            ),
            if (_error case final error?) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                '$error',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: <TRButton>[
        TRButton(
          appearance: TRAppearance.ghost,
          uiSize: TRUiSize.md,
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        TRButton(
          intent: TRIntent.primary,
          uiSize: TRUiSize.md,
          onPressed: _valid && !_saving ? _submit : null,
          child: Text(_saving ? l10n.commonCreating : l10n.commonCreate),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final created = await widget.onCreate(
        _CreateAgentInput(
          id: _id.text.trim(),
          name: _name.text.trim(),
          mode: _mode,
        ),
      );
      if (mounted) Navigator.pop(context, created);
    } on Exception catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = error;
        });
      }
    }
  }
}

class _AgentSettingsError extends StatelessWidget {
  const _AgentSettingsError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text('$error'),
        const SizedBox(height: 12),
        TRButton(
          intent: TRIntent.primary,
          uiSize: TRUiSize.md,
          onPressed: onRetry,
          child: Text(AppLocalizations.of(context).commonRetry),
        ),
      ],
    ),
  );
}
