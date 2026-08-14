import 'dart:async';

import 'package:app/l10n/gen/app_localizations.dart';
import 'package:app/src/features/agents/application/agent_definitions_controller.dart';
import 'package:app/src/features/agents/presentation/tool_groups.dart';
import 'package:app/src/features/providers/application/model_picker_options.dart';
import 'package:app/src/features/providers/application/provider_settings_controller.dart';
import 'package:app/src/features/providers/application/session_model_options.dart';
import 'package:app/src/shared/presentation/blocked_control.dart';
import 'package:app/src/shared/presentation/model_picker.dart';
import 'package:app/src/shared/presentation/permission_picker.dart';
import 'package:app/src/shared/presentation/settings_layout.dart';
import 'package:app/src/shared/presentation/tinest_icons.dart';
import 'package:app/src/shared/presentation/tinest_layout_metrics.dart';
import 'package:app/src/shared/presentation/tinest_select_presentation.dart';
import 'package:app/src/shared/presentation/tinest_selection_row.dart';
import 'package:app/src/shared/presentation/toast_messenger.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:protocol/protocol.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

/// Markdown-backed agent manager for one connected daemon.
class AgentSettingsPage extends ConsumerWidget {
  /// Creates an agent settings page.
  const AgentSettingsPage({
    required this.hostId,
    required this.paneController,
    required this.slot,
    super.key,
  });

  /// App-local daemon profile identifier.
  final String hostId;

  /// Selection shared by the collection and detail scaffold slots.
  final AgentSettingsPaneController paneController;

  /// Which scaffold slot this widget supplies.
  final SettingsPaneSlot slot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final widthClass = settingsAdaptiveWidthClassOf(context);
    final showsSplit =
        widthClass == TRAdaptiveWidthClass.large ||
        widthClass == TRAdaptiveWidthClass.extraLarge;
    final state = ref.watch(agentDefinitionsControllerProvider(hostId));
    return ListenableBuilder(
      listenable: paneController,
      builder: (context, _) => SettingsAsyncContent<AgentDefinitionsState>(
        state: state,
        loading: settingsPaneSkeleton(
          slot,
          semanticLabel: AppLocalizations.of(context).settingsLoading,
        ),
        error: (error, _) => slot == SettingsPaneSlot.collection
            ? SettingsCollectionErrorState(
                title: AppLocalizations.of(context).agentSettingsHeading,
                error: error,
                onRetry: () =>
                    ref.invalidate(agentDefinitionsControllerProvider(hostId)),
              )
            : SettingsEmptyState(
                title: AppLocalizations.of(context).agentSettingsSelectAgent,
                icon: const Icon(TinestIcons.agent),
              ),
        data: (value) =>
            _buildPane(context, ref, value, showsSplit: showsSplit),
      ),
    );
  }

  Widget _buildPane(
    BuildContext context,
    WidgetRef ref,
    AgentDefinitionsState value, {
    required bool showsSplit,
  }) {
    final selected = value.definitions
        .where((definition) => definition.id == paneController.selectedId)
        .firstOrNull;
    if (slot == SettingsPaneSlot.collection &&
        !paneController.creating &&
        showsSplit &&
        paneController.canAutoSelect &&
        selected == null &&
        value.definitions.isNotEmpty) {
      _scheduleInitialSelection(value.definitions.first.id);
    } else if (!paneController.creating &&
        paneController.hasDetail &&
        selected == null) {
      _scheduleCollection();
    }
    if (slot == SettingsPaneSlot.collection) {
      return _AgentDefinitionList(
        state: value,
        selectedId: paneController.selectedId,
        onSelected: paneController.select,
        onCreate: paneController.create,
      );
    }
    if (paneController.creating) {
      return _CreateAgentPane(
        existingIds: value.definitions
            .map((definition) => definition.id)
            .toSet(),
        onCancel: paneController.showCollection,
        onCreate: (input) {
          final template = value.definitions
              .where((definition) => definition.id == 'tinest')
              .first;
          final definition = template.copyWith(
            id: input.id,
            name: input.name,
            description: '',
            mode: input.mode,
            // A new agent starts without a prompt, so the override stays off
            // regardless of the template's own setting.
            promptEnabled: false,
            systemPrompt: '',
            callableAgentIds: const <String>[],
            contentHash: '',
            sourcePath: '',
            isBuiltIn: false,
            isArchived: false,
            diagnostics: const <AgentDefinitionDiagnosticDto>[],
          );
          return ref
              .read(agentDefinitionsControllerProvider(hostId).notifier)
              .create(input.id, definition);
        },
        onCreated: (created) => paneController.select(created.id),
      );
    }
    return selected == null
        ? SettingsEmptyState(
            title: AppLocalizations.of(context).agentSettingsSelectAgent,
            icon: const Icon(TinestIcons.agent),
          )
        : _AgentEditor(
            key: ValueKey<String>(selected.contentHash),
            hostId: hostId,
            state: value,
            definition: selected,
            onArchived: paneController.showCollection,
          );
  }

  void _scheduleInitialSelection(String agentId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      paneController.selectInitial(agentId);
    });
  }

  void _scheduleCollection() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      paneController.showCollection();
    });
  }
}

/// Owns Agent collection selection independently from either rendered slot.
class AgentSettingsPaneController extends SettingsPaneCoordinatorBase {
  String? _selectedId;
  bool _creating = false;

  /// Selected Agent ID, when an existing definition is active.
  String? get selectedId => _selectedId;

  /// Whether the create destination is active.
  bool get creating => _creating;

  @override
  bool get hasDetail => _creating || _selectedId != null;

  @override
  Object? get detailSelection => _creating
      ? (_AgentPaneDestination.create, null)
      : _selectedId == null
      ? null
      : (_AgentPaneDestination.existing, _selectedId);

  /// Shows the first Agent on initial desktop entry.
  void selectInitial(String id) {
    if (!consumeInitialSelection()) return;
    _selectedId = id;
    notifyListeners();
  }

  /// Shows an existing Agent definition.
  void select(String id) {
    consumeExplicitNavigation();
    if (!_creating && _selectedId == id) return;
    _creating = false;
    _selectedId = id;
    notifyListeners();
  }

  /// Shows the create Agent destination.
  void create() {
    consumeExplicitNavigation();
    if (_creating) return;
    _creating = true;
    _selectedId = null;
    notifyListeners();
  }

  @override
  void showCollection() {
    consumeExplicitNavigation();
    if (!hasDetail) return;
    _creating = false;
    _selectedId = null;
    notifyListeners();
  }

  @override
  void reset() {
    final hadDetail = hasDetail;
    resetInitialSelection();
    _creating = false;
    _selectedId = null;
    if (hadDetail) notifyListeners();
  }
}

enum _AgentPaneDestination { create, existing }

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
        TRPaneHeader(
          title: TRText.inherit(l10n.agentSettingsHeading),
          description: TRText.inherit(
            l10n.agentSettingsCount(state.definitions.length),
          ),
          actions: <Widget>[
            TRIconButton(
              key: const ValueKey('agent-add-button'),
              appearance: TRAppearance.ghost,
              label: l10n.agentSettingsAdd,
              onPressed: onCreate,
              icon: const Icon(TinestIcons.add),
            ),
          ],
        ),
        Expanded(
          child: state.definitions.isEmpty
              ? SettingsEmptyState(
                  title: l10n.agentSettingsEmpty,
                  icon: const Icon(TinestIcons.agent),
                )
              : SettingsCollectionList(
                  children: <Widget>[
                    TRTreeNav<String>.controlled(
                      value: selectedId,
                      itemSpacing: TRSpacing.extraSmall,
                      onValueChange: (definitionId) {
                        if (definitionId != null) onSelected(definitionId);
                      },
                      items: <TRTreeNavItem<String>>[
                        for (final definition in state.definitions)
                          TRTreeNavLeaf<String>(
                            value: definition.id,
                            showDisclosureIndicator: true,
                            leading: Icon(
                              definition.mode == AgentMode.primary
                                  ? TinestIcons.agent
                                  : TinestIcons.branch,
                            ),
                            label: TRText.inherit(definition.name),
                            description: TRText.inherit(
                              definition.isStale
                                  ? l10n.agentSettingsModeStale(
                                      definition.mode.name,
                                    )
                                  : definition.mode.name,
                            ),
                            trailing: definition.diagnostics.isEmpty
                                ? null
                                : const Icon(TinestIcons.warning),
                          ),
                      ],
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _AgentEditor extends ConsumerStatefulWidget {
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
  ConsumerState<_AgentEditor> createState() => _AgentEditorState();
}

class _AgentEditorState extends ConsumerState<_AgentEditor> {
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _prompt;
  late final TextEditingController _modelId;
  late bool _promptEnabled;
  late bool _usesModel;
  PermissionMode? _permissionMode;
  late Set<String> _tools;
  late Set<String> _callableAgents;
  // Every group starts closed. The header carries the count, so a closed list
  // still says what is on, and seventeen tools fit on screen as seven rows.
  final Set<ToolGroup> _expandedGroups = <ToolGroup>{};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final definition = widget.definition;
    _name = TextEditingController(text: definition.name);
    _description = TextEditingController(text: definition.description);
    _prompt = TextEditingController(text: definition.systemPrompt);
    _modelId = TextEditingController(text: definition.model?.modelId ?? '');
    _promptEnabled = definition.promptEnabled;
    _usesModel = definition.model != null;
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
    _modelId.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final definition = widget.definition;
    final editable = !_saving;
    final canSave =
        editable && (!_usesModel || _modelId.text.trim().isNotEmpty);
    final providersState = ref.watch(
      providerSettingsControllerProvider(widget.hostId),
    );
    final providers = providersState.value;
    final providersResolved = providersState.hasValue && providers != null;
    final firstModel = providers == null
        ? null
        : firstUsableModel(providers.connections, providers.models);
    final modelBlocked = editable && providersResolved && firstModel == null;
    final modelSelectionEnabled =
        editable && providersResolved && firstModel != null;
    final storedModel = _modelId.text.isEmpty
        ? null
        : ModelSelectionDto(modelId: _modelId.text);
    final modelUnavailable =
        _usesModel &&
        providers != null &&
        storedModel != null &&
        !isRunnableSelection(
          storedModel,
          providers.connections,
          providers.models,
        );
    final subagents = widget.state.definitions.where(
      (candidate) =>
          candidate.mode == AgentMode.subagent &&
          !candidate.isArchived &&
          !candidate.isStale,
    );
    return Column(
      children: <Widget>[
        TRPaneHeader(
          title: TRText.inherit(definition.name),
          description: TRText.inherit(definition.sourcePath),
          contentMaxWidth: TinestLayoutMetrics.settingsContentMaxWidth,
          actions: <Widget>[
            TRIconButton(
              key: const ValueKey('agent-copy-path-button'),
              appearance: TRAppearance.ghost,
              label: l10n.agentSettingsCopyPath,
              onPressed: () =>
                  Clipboard.setData(ClipboardData(text: definition.sourcePath)),
              icon: const Icon(TinestIcons.copy),
            ),
            TRButton(
              intent: TRIntent.primary,
              onPressed: canSave ? () => _save(force: false) : null,
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
                        icon: const Icon(TinestIcons.warning),
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
                  TinestSwitchRow(
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
                banner: modelUnavailable
                    ? TRAlert(
                        key: const ValueKey<String>(
                          'agent-settings-model-unavailable',
                        ),
                        title: TRText.inherit(
                          l10n.modelSettingsUnavailableTitle,
                        ),
                        description: TRText.inherit(
                          l10n.modelSettingsUnavailableDescription(
                            _modelId.text,
                          ),
                        ),
                        icon: const Icon(TinestIcons.warning),
                        variant: TRStatusVariant.warning,
                      )
                    : null,
                children: <Widget>[
                  TinestSwitchRow(
                    key: const ValueKey<String>('agent-settings-use-model'),
                    flush: true,
                    value: _usesModel,
                    onChanged: editable
                        ? (value) => setState(() {
                            _usesModel = value;
                            if (value && _modelId.text.isEmpty) {
                              _modelId.text = firstModel?.modelId ?? '';
                            }
                          })
                        : null,
                    title: TRText.inherit(l10n.agentSettingsUseModel),
                    subtitle: TRText.inherit(
                      l10n.agentSettingsUseModelDescription,
                    ),
                    wrapsSubtitle: true,
                  ),
                  if (_usesModel) ...<Widget>[
                    Semantics(
                      key: const ValueKey<String>(
                        'agent-settings-model-selector',
                      ),
                      hint: modelBlocked
                          ? l10n.composerConnectProviderFirst
                          : null,
                      child: SettingsRow(
                        flush: true,
                        // A providerless selector remains actionable so the
                        // product wrapper can explain how to unlock it.
                        enabled: modelSelectionEnabled || modelBlocked,
                        title: TRText.inherit(
                          l10n.agentSettingsModelId,
                          color: modelBlocked ? TRTextColor.muted : null,
                        ),
                        controlLayout: SettingsControlLayout.responsive,
                        controlOwnsFocus: true,
                        control: _agentModelSelect(
                          l10n,
                          enabled: modelSelectionEnabled,
                          blocked: modelBlocked,
                        ),
                      ),
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
                    controlLayout: SettingsControlLayout.responsive,
                    controlOwnsFocus: true,
                    control: PermissionSelect(
                      key: const ValueKey<String>('agent-permission-change'),
                      currentMode: _permissionMode,
                      inheritLabel: l10n.permissionSettingsDaemonDefault,
                      enabled: editable,
                      onValueChange: (mode) => setState(
                        () => _permissionMode = mode,
                      ),
                    ),
                  ),
                ],
              ),
              SettingsSection(
                title: l10n.agentSettingsBuiltinTools,
                children: <Widget>[
                  for (final view in groupAgentTools(widget.state.tools)) ...[
                    _toolGroupHeader(l10n, view, editable: editable),
                    if (_expandedGroups.contains(view.group))
                      for (final tool in view.tools)
                        TinestCheckboxRow(
                          key: ValueKey<String>('agent-tool-tile-${tool.id}'),
                          value: tool.alwaysOn || _tools.contains(tool.id),
                          // An always-on tool has no toggle to offer, so the
                          // tile is checked and inert rather than lying about
                          // being editable.
                          onChanged: editable && !tool.alwaysOn
                              ? (enabled) => setState(() {
                                  enabled!
                                      ? _tools.add(tool.id)
                                      : _tools.remove(tool.id);
                                })
                              : null,
                          secondary: tool.alwaysOn
                              ? Icon(
                                  TinestIcons.lock,
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
                      TinestCheckboxRow(
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
              SettingsSection(
                title: definition.isBuiltIn
                    ? l10n.agentSettingsReset
                    : l10n.workspaceArchive,
                children: <Widget>[
                  SettingsRow(
                    title: TRText.inherit(
                      definition.isBuiltIn
                          ? l10n.agentSettingsResetBody
                          : l10n.agentSettingsArchiveBody,
                    ),
                    control: TRButton(
                      key: ValueKey<String>(
                        definition.isBuiltIn
                            ? 'agent-reset-button'
                            : 'agent-archive-button',
                      ),
                      appearance: TRAppearance.ghost,
                      intent: TRIntent.danger,
                      onPressed: editable
                          ? definition.isBuiltIn
                                ? _reset
                                : _archive
                          : null,
                      child: TRText.inherit(
                        definition.isBuiltIn
                            ? l10n.agentSettingsReset
                            : l10n.workspaceArchive,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// The row standing for one group: its state, and the whole-group toggle.
  ///
  /// The checkbox and the row do different things — one turns the group on and
  /// off, the other opens it — so each is its own tab stop rather than the row
  /// repeating the control the way a plain setting does.
  Widget _toolGroupHeader(
    AppLocalizations l10n,
    AgentToolGroupView view, {
    required bool editable,
  }) {
    final expanded = _expandedGroups.contains(view.group);
    final enabled = view.enabledCount(_tools);
    return TinestCheckboxRow(
      key: ValueKey<String>('agent-tool-group-${view.group.name}'),
      value: view.allEnabled(_tools),
      indeterminate: view.partiallyEnabled(_tools),
      // A group of nothing but always-on tools has no toggle to offer, so its
      // checkbox is locked for the same reason each of its tools is.
      onChanged: editable && !view.locked
          ? (checked) => setState(() {
              checked!
                  ? _tools.addAll(view.toggleableIds)
                  : _tools.removeAll(view.toggleableIds);
            })
          : null,
      onRowTap: () => setState(() {
        expanded
            ? _expandedGroups.remove(view.group)
            : _expandedGroups.add(view.group);
      }),
      // The chevron, even on a locked group: the row opens either way, and a
      // lock here would say it does not. That a group is always on is already
      // said by its disabled checkbox and its subtitle, and each tool inside
      // still carries its own lock.
      secondary: Icon(expanded ? TinestIcons.collapse : TinestIcons.expand),
      title: TRText.inherit(toolGroupLabel(l10n, view.group)),
      subtitle: TRText.inherit(
        view.locked
            ? l10n.agentSettingsToolGroupAlwaysOn
            : l10n.agentSettingsToolGroupSummary(enabled, view.tools.length),
      ),
    );
  }

  AgentDefinitionDto _editedDefinition() => widget.definition.copyWith(
    name: _name.text.trim(),
    description: _description.text.trim(),
    promptEnabled: _promptEnabled,
    systemPrompt: _prompt.text,
    model: _usesModel ? ModelSelectionDto(modelId: _modelId.text.trim()) : null,
    modelControls: _usesModel
        ? widget.definition.modelControls
        : const <String, ModelControlValueDto>{},
    permissionMode: _permissionMode,
    // Always-on ids are never written back: the daemon supplies them, so
    // repeating them in the frontmatter would only go stale.
    toolIds: _tools.toList(growable: false)..sort(),
    callableAgentIds: _callableAgents.toList(growable: false)..sort(),
  );

  void _showProviderRequiredToast(AppLocalizations l10n) {
    ref
        .read(toastMessengerProvider)
        .info(
          l10n.composerConnectProviderFirst,
          id: 'model-selector-provider-required',
        );
  }

  Widget _agentModelSelect(
    AppLocalizations l10n, {
    required bool enabled,
    required bool blocked,
  }) {
    final select = AsyncModelSelect(
      loadKey: widget.hostId,
      loadOptions: ref.read(modelPickerOptionsLoaderProvider(widget.hostId)),
      currentSelection: _modelId.text.isEmpty
          ? null
          : ModelSelectionDto(modelId: _modelId.text),
      placeholder: _modelId.text.isEmpty ? l10n.composerModel : _modelId.text,
      enabled: enabled,
      leading: Icon(blocked ? TinestIcons.lock : TinestIcons.memory),
      onValueChange: (option) => setState(
        () => _modelId.text = option.model.id,
      ),
    );
    if (!blocked) return select;
    return BlockedControl(
      label: l10n.agentSettingsModelId,
      hint: l10n.composerConnectProviderFirst,
      onTap: () => _showProviderRequiredToast(l10n),
      child: select,
    );
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

  /// Asks before a destructive change, the way every other one here does.
  ///
  /// Archiving and resetting used to run straight off a single click, which
  /// made them the only two irreversible actions in the application without a
  /// step between the pointer and the consequence.
  Future<bool> _confirm({
    required String title,
    required String body,
    required String accept,
    required String confirmKey,
  }) async {
    final confirmed = await showTRDialog<bool>(
      context: context,
      builder: (context) => TRAlertDialog(
        title: TRText.inherit(title),
        content: TRText.inherit(body),
        actions: <TRButton>[
          TRButton(
            appearance: TRAppearance.ghost,
            onPressed: () => Navigator.pop(context, false),
            child: TRText.inherit(AppLocalizations.of(context).commonCancel),
          ),
          TRButton(
            key: ValueKey<String>(confirmKey),
            intent: TRIntent.danger,
            onPressed: () => Navigator.pop(context, true),
            child: TRText.inherit(accept),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _archive() async {
    final l10n = AppLocalizations.of(context);
    if (!await _confirm(
      title: l10n.agentSettingsArchiveTitle(widget.definition.name),
      body: l10n.agentSettingsArchiveBody,
      accept: l10n.workspaceArchive,
      confirmKey: 'agent-archive-confirm',
    )) {
      return;
    }
    if (!mounted) return;
    final container = ProviderScope.containerOf(context);
    final archived = await container
        .read(toastMessengerProvider)
        .run(
          () => container
              .read(agentDefinitionsControllerProvider(widget.hostId).notifier)
              .archive(widget.definition.id),
          failure: l10n.agentSettingsArchiveFailed,
          success: l10n.agentSettingsArchived,
          id: 'agent-archive',
        );
    if (archived) widget.onArchived();
  }

  Future<void> _reset() async {
    final l10n = AppLocalizations.of(context);
    if (!await _confirm(
      title: l10n.agentSettingsResetTitle(widget.definition.name),
      body: l10n.agentSettingsResetBody,
      accept: l10n.agentSettingsReset,
      confirmKey: 'agent-reset-confirm',
    )) {
      return;
    }
    if (!mounted) return;
    final container = ProviderScope.containerOf(context);
    await container
        .read(toastMessengerProvider)
        .run(
          () => container
              .read(agentDefinitionsControllerProvider(widget.hostId).notifier)
              .resetTinest(),
          failure: l10n.agentSettingsResetFailed,
          success: l10n.agentSettingsResetDone,
          id: 'agent-reset',
        );
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

class _CreateAgentPane extends StatefulWidget {
  const _CreateAgentPane({
    required this.existingIds,
    required this.onCreate,
    required this.onCreated,
    required this.onCancel,
  });

  final Set<String> existingIds;
  final Future<AgentDefinitionDto> Function(_CreateAgentInput input) onCreate;
  final ValueChanged<AgentDefinitionDto> onCreated;
  final VoidCallback onCancel;

  @override
  State<_CreateAgentPane> createState() => _CreateAgentPaneState();
}

class _CreateAgentPaneState extends State<_CreateAgentPane> {
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
    return Column(
      children: <Widget>[
        TRPaneHeader(
          title: TRText.inherit(l10n.agentSettingsAddTitle),
          contentMaxWidth: TinestLayoutMetrics.settingsContentMaxWidth,
          actions: <Widget>[
            TRButton(
              appearance: TRAppearance.ghost,
              onPressed: _saving ? null : widget.onCancel,
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
        ),
        Expanded(
          child: SettingsScaffold(
            children: <Widget>[
              SettingsSection.form(
                children: <Widget>[
                  TRTextField(
                    controller: _id,
                    autofocus: true,
                    enabled: !_saving,
                    onChanged: (_) => setState(() => _error = null),
                    label: l10n.agentSettingsIdLabel,
                    // An ID becomes a file name, so the example stays a
                    // literal identifier in every language.
                    placeholder: 'reviewer',
                    errorText: _idError(l10n),
                  ),
                  TRTextField(
                    controller: _name,
                    enabled: !_saving,
                    onChanged: (_) => setState(() => _error = null),
                    label: l10n.commonName,
                    errorText:
                        _name.text.isEmpty || _name.text.trim().isNotEmpty
                        ? null
                        : l10n.agentSettingsNameRequired,
                  ),
                  TRSelectFormField<AgentMode>(
                    initialValue: _mode,
                    searchable: true,
                    searchPlaceholder: l10n.selectSearchPlaceholder,
                    noResultsText: l10n.selectNoResults,
                    presentation: TinestSelectPresentation.resolve(context),
                    label: l10n.commonKind,
                    width: TinestLayoutMetrics.settingsContentMaxWidth,
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
                  if (_error case final error?)
                    TRAlert(
                      variant: TRStatusVariant.danger,
                      title: TRText.inherit('$error'),
                    ),
                ],
              ),
            ],
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
      if (mounted) widget.onCreated(created);
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
