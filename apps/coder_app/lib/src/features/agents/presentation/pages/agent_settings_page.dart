import 'dart:async';

import 'package:coder_app/l10n/gen/app_localizations.dart';
import 'package:coder_app/src/features/agents/application/agent_definitions_controller.dart';
import 'package:coder_app/src/shared/presentation/coder_icons.dart';
import 'package:coder_app/src/shared/presentation/coder_layout_metrics.dart';
import 'package:coder_app/src/shared/presentation/coder_selection_row.dart';
import 'package:coder_app/src/shared/presentation/permission_picker.dart';
import 'package:coder_app/src/shared/presentation/settings_layout.dart';
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
  SettingsPaneNavigationController? _paneNavigation;

  @override
  void dispose() {
    _paneNavigation?.clearBackHandler(this);
    super.dispose();
  }

  @override
  void didUpdateWidget(AgentSettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hostId != widget.hostId) _selectedId = null;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(agentDefinitionsControllerProvider(widget.hostId));
    return SettingsAsyncContent<AgentDefinitionsState>(
      state: state,
      loading: SettingsSkeletonLayout.listDetail(
        semanticLabel: AppLocalizations.of(context).settingsLoading,
      ),
      error: (error, _) => _AgentSettingsError(
        error: error,
        onRetry: () =>
            ref.invalidate(agentDefinitionsControllerProvider(widget.hostId)),
      ),
      data: (value) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final compact =
                constraints.maxWidth < CoderLayoutMetrics.compactBreakpoint;
            if (!compact &&
                !value.definitions.any(
                  (definition) => definition.id == _selectedId,
                )) {
              _selectedId = value.definitions.firstOrNull?.id;
            }
            final selected = value.definitions
                .where((definition) => definition.id == _selectedId)
                .firstOrNull;
            _paneNavigation = SettingsPaneNavigationScope.maybeOf(context);
            syncSettingsPaneBackHandler(
              context,
              owner: this,
              active: compact && selected != null,
              onBack: _showAgentList,
            );
            if (compact && selected != null) {
              return _AgentEditor(
                key: ValueKey<String>(selected.contentHash),
                hostId: widget.hostId,
                state: value,
                definition: selected,
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
                SizedBox(
                  width: CoderLayoutMetrics.settingsCollectionWidth,
                  child: list,
                ),
                const TRSeparator(
                  orientation: TRSeparatorOrientation.vertical,
                  variant: TRSeparatorVariant.muted,
                ),
                Expanded(
                  child: selected == null
                      ? SettingsEmptyState(
                          title: AppLocalizations.of(
                            context,
                          ).agentSettingsSelectAgent,
                          icon: const Icon(CoderIcons.agent),
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
              .read(agentDefinitionsControllerProvider(widget.hostId).notifier)
              .create(input.id, definition);
        },
      ),
    );
    if (created != null && mounted) {
      setState(() => _selectedId = created.id);
    }
  }

  void _showAgentList() => setState(() => _selectedId = null);
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
        SettingsPaneHeader.list(
          title: l10n.agentSettingsHeading,
          subtitle: l10n.agentSettingsCount(state.definitions.length),
          actions: <Widget>[
            TRIconButton(
              key: const ValueKey('agent-add-button'),
              appearance: TRAppearance.ghost,
              label: l10n.agentSettingsAdd,
              onPressed: onCreate,
              icon: const Icon(CoderIcons.add),
            ),
          ],
        ),
        Expanded(
          child: ListView(
            children: <Widget>[
              for (final definition in state.definitions)
                SettingsRow(
                  selected: definition.id == selectedId,
                  leading: Icon(
                    definition.mode == AgentMode.primary
                        ? CoderIcons.agent
                        : CoderIcons.branch,
                  ),
                  title: TRText.inherit(definition.name),
                  description: TRText.inherit(
                    definition.isStale
                        ? '${definition.mode.name} · stale'
                        : definition.mode.name,
                  ),
                  control: definition.diagnostics.isEmpty
                      ? null
                      : const Icon(CoderIcons.warning),
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
    super.key,
  });

  final String hostId;
  final AgentDefinitionsState state;
  final AgentDefinitionDto definition;
  final VoidCallback onArchived;

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
  PermissionMode? _permissionMode;
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
        SettingsPaneHeader.detail(
          title: definition.name,
          subtitle: definition.sourcePath,
          actions: <Widget>[
            TRIconButton(
              key: const ValueKey('agent-copy-path-button'),
              appearance: TRAppearance.ghost,
              label: l10n.agentSettingsCopyPath,
              onPressed: () =>
                  Clipboard.setData(ClipboardData(text: definition.sourcePath)),
              icon: const Icon(CoderIcons.copy),
            ),
            if (definition.isBuiltIn)
              TRIconButton(
                key: const ValueKey('agent-reset-button'),
                appearance: TRAppearance.ghost,
                label: l10n.agentSettingsReset,
                onPressed: editable ? _reset : null,
                icon: const Icon(CoderIcons.restore),
              )
            else
              TRIconButton(
                key: const ValueKey('agent-archive-button'),
                appearance: TRAppearance.ghost,
                label: l10n.workspaceArchive,
                onPressed: editable ? _archive : null,
                icon: const Icon(CoderIcons.archive),
              ),
            TRButton(
              intent: TRIntent.primary,
              onPressed: editable ? () => _save(force: false) : null,
              child: TRText.inherit(
                _saving ? l10n.commonSaving : l10n.commonSave,
              ),
            ),
          ],
        ),
        Expanded(
          child: SettingsScaffold(
            children: <Widget>[
              SettingsSection.form(
                title: l10n.agentSettingsDefinitionHeading,
                banner: definition.diagnostics.isEmpty
                    ? null
                    : TRAlert(
                        title: TRText.inherit(
                          definition.diagnostics.first.code,
                        ),
                        description: TRText.inherit(
                          definition.diagnostics
                              .map((diagnostic) => diagnostic.message)
                              .join('\n'),
                        ),
                        icon: const Icon(CoderIcons.warning),
                        variant: TRStatusVariant.warning,
                      ),
                children: <Widget>[
                  TRTextField(
                    controller: _name,
                    enabled: editable,
                    label: l10n.commonName,
                  ),
                  TRTextField(
                    controller: _description,
                    enabled: editable,
                    label: l10n.commonDescription,
                  ),
                  TRTextField(
                    initialValue: definition.mode.name,
                    enabled: false,
                    label: l10n.commonKind,
                  ),
                ],
              ),
              SettingsSection.form(
                title: l10n.agentSettingsPromptHeading,
                children: <Widget>[
                  // Whether there is a custom prompt and what it says are one
                  // decision, so they share a heading. The toggle goes flush
                  // to line up with the editor rather than sitting in a card
                  // that steps in from it.
                  CoderSwitchRow(
                    flush: true,
                    value: _promptEnabled,
                    onChanged: editable
                        ? (value) => setState(() => _promptEnabled = value)
                        : null,
                    title: TRText.inherit(l10n.agentSettingsCustomPrompt),
                  ),
                  TRTextField(
                    controller: _prompt,
                    enabled: editable,
                    minLines: 8,
                    maxLines: 18,
                    label: l10n.agentSettingsSystemPrompt,
                  ),
                ],
              ),
              SettingsSection.form(
                title: l10n.agentSettingsModelHeading,
                children: <Widget>[
                  TRRadioGroup(
                    value: _modelSource.name,
                    disabled: !editable,
                    onValueChange: (value) => setState(
                      () =>
                          _modelSource = AgentModelSource.values.byName(value),
                    ),
                    children: [
                      TRRadio(
                        value: AgentModelSource.session.name,
                        label: TRText.inherit(l10n.agentSettingsSessionModel),
                      ),
                      TRRadio(
                        value: AgentModelSource.fixed.name,
                        label: TRText.inherit(l10n.agentSettingsPinnedModel),
                      ),
                    ],
                  ),
                  if (_modelSource == AgentModelSource.fixed) ...<Widget>[
                    TRTextField(
                      controller: _providerConnectionId,
                      enabled: editable,
                      label: l10n.agentSettingsProviderConnectionId,
                    ),
                    TRTextField(
                      controller: _modelId,
                      enabled: editable,
                      label: l10n.agentSettingsModelId,
                    ),
                  ],
                ],
              ),
              SettingsSection(
                title: l10n.agentSettingsBehaviourHeading,
                children: <Widget>[
                  SettingsRow(
                    title: TRText.inherit(l10n.agentSettingsPermission),
                    description: TRText.inherit(
                      _permissionMode == null
                          ? l10n.permissionSettingsDaemonDefault
                          : permissionModeDescription(l10n, _permissionMode!),
                    ),
                    unboundedDescription: true,
                    control: TRButton(
                      key: const ValueKey<String>('agent-permission-change'),
                      appearance: TRAppearance.outline,
                      onPressed: editable
                          ? () => unawaited(_choosePermission())
                          : null,
                      child: TRText.inherit(
                        _permissionMode == null
                            ? l10n.permissionSettingsDaemonDefault
                            : permissionModeLabel(l10n, _permissionMode!),
                      ),
                    ),
                  ),
                ],
              ),
              SettingsSection(
                title: l10n.agentSettingsBuiltinTools,
                children: <Widget>[
                  for (final tool in _sortedTools)
                    CoderCheckboxRow(
                      key: ValueKey<String>('agent-tool-tile-${tool.id}'),
                      value: tool.alwaysOn || _tools.contains(tool.id),
                      // An always-on tool has no toggle to offer, so the tile
                      // is checked and inert rather than lying about being
                      // editable.
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
                              key: ValueKey<String>(
                                'agent-tool-lock-${tool.id}',
                              ),
                            )
                          : null,
                      title: TRText.inherit(tool.name),
                      subtitle: TRText.inherit(
                        tool.alwaysOn
                            ? '${tool.description} · '
                                  '${l10n.agentSettingsToolAlwaysOn}'
                            : tool.description,
                      ),
                    ),
                ],
              ),
              if (definition.mode == AgentMode.primary)
                SettingsSection(
                  title: l10n.agentSettingsSubagents,
                  children: <Widget>[
                    if (subagents.isEmpty)
                      SettingsRow(
                        title: TRText.inherit(l10n.agentSettingsNoSubagents),
                      ),
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
                        title: TRText.inherit(subagent.name),
                        subtitle: TRText.inherit(subagent.description),
                      ),
                  ],
                ),
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
    modelControls: _modelSource == AgentModelSource.fixed
        ? widget.definition.modelControls
        : const <String, ModelControlValueDto>{},
    permissionMode: _permissionMode,
    // Always-on ids are never written back: the daemon supplies them, so
    // repeating them in the frontmatter would only go stale.
    toolIds: _tools.toList(growable: false)..sort(),
    callableAgentIds: _callableAgents.toList(growable: false)..sort(),
  );

  Future<void> _choosePermission() async {
    final choice = await showPermissionPicker(
      context,
      currentMode: _permissionMode,
      inheritLabel: AppLocalizations.of(
        context,
      ).permissionSettingsDaemonDefault,
    );
    if (choice != null && mounted) {
      setState(() => _permissionMode = choice.mode);
    }
  }

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
          title: TRText.inherit(l10n.agentSettingsSaveFailedTitle),
          content: TRText.inherit('$error'),
          actions: <TRButton>[
            TRButton(
              appearance: TRAppearance.ghost,
              onPressed: () => Navigator.pop(context, false),
              child: TRText.inherit(l10n.agentSettingsReload),
            ),
            TRButton(
              intent: TRIntent.primary,
              onPressed: () => Navigator.pop(context, true),
              child: TRText.inherit(l10n.agentSettingsOverwrite),
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
  const _CreateAgentDialog({required this.existingIds, required this.onCreate});

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
      title: TRText.inherit(l10n.agentSettingsAddTitle),
      content: SettingsDialogForm(
        children: <Widget>[
          TRTextField(
            controller: _id,
            autofocus: true,
            enabled: !_saving,
            onChanged: (_) => setState(() => _error = null),
            label: l10n.agentSettingsIdLabel,
            placeholder: 'reviewer',
            errorText: _idError(l10n),
          ),
          TRTextField(
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
            width: TRMeasurements.overlayWidthMd,
            items: AgentMode.values
                .map(
                  (value) =>
                      TRSelectItem<AgentMode>(value: value, label: value.name),
                )
                .toList(growable: false),
            onValueChange: _saving
                ? null
                : (value) => setState(() => _mode = value!),
          ),
          if (_error case final error?)
            TRText('$error', color: TRTextColor.danger),
        ],
      ),
      actions: <TRButton>[
        TRButton(
          appearance: TRAppearance.ghost,
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: TRText.inherit(l10n.commonCancel),
        ),
        TRButton(
          intent: TRIntent.primary,
          onPressed: _valid && !_saving ? _submit : null,
          child: TRText.inherit(
            _saving ? l10n.commonCreating : l10n.commonCreate,
          ),
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
        TRText('$error'),
        const SizedBox(height: TRSpacing.medium),
        TRButton(
          intent: TRIntent.primary,
          onPressed: onRetry,
          child: TRText.inherit(AppLocalizations.of(context).commonRetry),
        ),
      ],
    ),
  );
}
