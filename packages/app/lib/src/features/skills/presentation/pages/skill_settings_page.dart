import 'dart:async';

import 'package:app/l10n/gen/app_localizations.dart';
import 'package:app/src/features/skills/application/skills_controller.dart';
import 'package:app/src/features/workspace/application/workspace_controller.dart';
import 'package:app/src/shared/presentation/settings_layout.dart';
import 'package:app/src/shared/presentation/settings_navigation_row.dart';
import 'package:app/src/shared/presentation/tinest_icons.dart';
import 'package:app/src/shared/presentation/tinest_layout_metrics.dart';
import 'package:app/src/shared/presentation/tinest_selection_row.dart';
import 'package:app/src/shared/presentation/toast_messenger.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:protocol/protocol.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

/// Skill manager for one connected daemon, optionally scoped to a project.
class SkillSettingsPage extends ConsumerWidget {
  /// Creates a skill settings page.
  const SkillSettingsPage({
    required this.hostId,
    required this.paneController,
    required this.slot,
    this.workspaceId,
    this.onWorkspaceChanged,
    super.key,
  });

  /// App-local daemon profile identifier.
  final String hostId;

  /// Workspace whose `.agents/skills` layers on top of the global sources.
  final String? workspaceId;

  /// Called when the user picks a different project.
  final ValueChanged<String?>? onWorkspaceChanged;

  /// Selection shared by the collection and detail scaffold slots.
  final SkillSettingsPaneController paneController;

  /// Which scaffold slot this widget supplies.
  final SettingsPaneSlot slot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final widthClass = settingsAdaptiveWidthClassOf(context);
    final showsSplit =
        widthClass == TRAdaptiveWidthClass.large ||
        widthClass == TRAdaptiveWidthClass.extraLarge;
    final provider = skillsControllerProvider(
      hostId,
      workspaceId,
    );
    final state = ref.watch(provider);
    return ListenableBuilder(
      listenable: paneController,
      builder: (context, _) => SettingsAsyncContent<List<SkillDto>>(
        state: state,
        loading: _slotSurface(
          settingsPaneSkeleton(
            slot,
            semanticLabel: AppLocalizations.of(context).settingsLoading,
          ),
        ),
        error: (error, _) => slot == SettingsPaneSlot.collection
            ? _slotSurface(
                SettingsCollectionErrorState(
                  title: AppLocalizations.of(context).skillSettingsHeading,
                  error: error,
                  onRetry: () => ref.invalidate(provider),
                ),
              )
            : SettingsEmptyState(
                title: AppLocalizations.of(context).skillSettingsSelectSkill,
                icon: const Icon(TinestIcons.sparkle),
              ),
        data: (skills) => _buildCatalog(
          context,
          ref,
          skills,
          showsSplit: showsSplit,
        ),
      ),
    );
  }

  Widget _buildCatalog(
    BuildContext context,
    WidgetRef ref,
    List<SkillDto> skills, {
    required bool showsSplit,
  }) {
    final selected = skills
        .where((skill) => skill.id == paneController.selectedId)
        .firstOrNull;
    if (slot == SettingsPaneSlot.collection &&
        !paneController.creating &&
        showsSplit &&
        paneController.canAutoSelect &&
        selected == null &&
        skills.isNotEmpty) {
      _scheduleInitialSelection(skills.first.id);
    } else if (!paneController.creating &&
        paneController.hasDetail &&
        selected == null) {
      _scheduleCollection();
    }
    if (slot == SettingsPaneSlot.collection) {
      return _slotSurface(
        _SkillList(
          hostId: hostId,
          workspaceId: workspaceId,
          skills: skills,
          selectedId: paneController.selectedId,
          onSelected: paneController.select,
          onCreate: paneController.create,
        ),
      );
    }
    if (paneController.creating) {
      return _CreateSkillPane(
        existingIds: skills.map((skill) => skill.id).toSet(),
        allowProject: workspaceId != null,
        onCancel: paneController.showCollection,
        onCreate: (input) => ref
            .read(skillsControllerProvider(hostId, workspaceId).notifier)
            .create(
              id: input.id,
              source: input.source,
              name: input.name,
              description: input.description,
              body: '',
            ),
        onCreated: (created) => paneController.select(created.id),
      );
    }
    return selected == null
        ? SettingsEmptyState(
            title: AppLocalizations.of(context).skillSettingsSelectSkill,
            icon: const Icon(TinestIcons.sparkle),
          )
        : _SkillEditor(
            key: ValueKey<String>('${selected.id}:${selected.contentHash}'),
            hostId: hostId,
            workspaceId: workspaceId,
            skill: selected,
            onDeleted: paneController.showCollection,
          );
  }

  Widget _slotSurface(Widget child) {
    if (slot == SettingsPaneSlot.detail) return child;
    return Column(
      children: <Widget>[
        _ProjectSelector(
          hostId: hostId,
          workspaceId: workspaceId,
          onChanged: onWorkspaceChanged,
        ),
        const TRSeparator(variant: TRSeparatorVariant.muted),
        Expanded(child: child),
      ],
    );
  }

  void _scheduleInitialSelection(String skillId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      paneController.selectInitial(skillId);
    });
  }

  void _scheduleCollection() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      paneController.showCollection();
    });
  }
}

/// Owns Skill collection selection independently from either rendered slot.
class SkillSettingsPaneController extends SettingsPaneCoordinatorBase {
  String? _selectedId;
  bool _creating = false;

  /// Selected Skill ID, when an existing skill is active.
  String? get selectedId => _selectedId;

  /// Whether the create destination is active.
  bool get creating => _creating;

  @override
  bool get hasDetail => _creating || _selectedId != null;

  @override
  String? get destinationId => _creating
      ? 'skill-create'
      : _selectedId == null
      ? null
      : 'skill-$_selectedId';

  /// Shows the first Skill on initial desktop entry.
  void selectInitial(String id) {
    if (!consumeInitialSelection()) return;
    _selectedId = id;
    notifyListeners();
  }

  /// Shows an existing Skill.
  void select(String id) {
    consumeExplicitNavigation();
    if (!_creating && _selectedId == id) return;
    _creating = false;
    _selectedId = id;
    notifyListeners();
  }

  /// Shows the create Skill destination.
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

/// Chooses which project's skills layer on top of the global sources.
class _ProjectSelector extends ConsumerWidget {
  const _ProjectSelector({
    required this.hostId,
    required this.workspaceId,
    required this.onChanged,
  });

  final String hostId;
  final String? workspaceId;
  final ValueChanged<String?>? onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final catalog = ref
        .watch(workspaceCatalogControllerProvider)
        .asData
        ?.value
        .catalogs[hostId];
    final workspaces = catalog?.workspaces ?? const <WorkspaceDto>[];
    final selected = workspaces
        .where((workspace) => workspace.id == workspaceId)
        .firstOrNull;
    return SettingsCompactToolbar(
      builder: (width) => <Widget>[
        TRSelectFormField<String?>(
          initialValue: selected?.id,
          // Explicit so the production Select policy can audit adaptation.
          // ignore: avoid_redundant_argument_values
          surface: TRSelectSurface.auto,
          label: l10n.skillSettingsProject,
          width: width,
          helperText: l10n.skillSettingsProjectHint,
          // The project list is however many workspaces the user has paired,
          // which is the only select on this screen that a filter earns.
          searchable: true,
          searchPlaceholder: l10n.skillSettingsProjectSearch,
          noResultsText: l10n.skillSettingsProjectNoMatch,
          items: <TRSelectItem<String?>>[
            TRSelectItem<String?>(
              value: null,
              label: l10n.skillSettingsProjectNone,
            ),
            for (final workspace in workspaces)
              TRSelectItem<String?>(value: workspace.id, label: workspace.name),
          ],
          onValueChange: onChanged,
        ),
      ],
    );
  }
}

class _SkillList extends ConsumerWidget {
  const _SkillList({
    required this.hostId,
    required this.workspaceId,
    required this.skills,
    required this.selectedId,
    required this.onSelected,
    required this.onCreate,
  });

  final String hostId;
  final String? workspaceId;
  final List<SkillDto> skills;
  final String? selectedId;
  final ValueChanged<String> onSelected;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: <Widget>[
        TRPaneHeader(
          title: TRText.inherit(l10n.skillSettingsHeading),
          description: TRText.inherit(l10n.skillSettingsCount(skills.length)),
          actions: <Widget>[
            TRIconButton(
              key: const ValueKey<String>('skill-add-button'),
              appearance: TRAppearance.ghost,
              label: l10n.skillSettingsAdd,
              onPressed: onCreate,
              icon: const Icon(TinestIcons.add),
            ),
          ],
        ),
        Expanded(
          child: skills.isEmpty
              ? SettingsEmptyState(
                  title: l10n.skillSettingsEmpty,
                  icon: const Icon(TinestIcons.sparkle),
                )
              : SettingsCollectionList(
                  children: <Widget>[
                    for (final skill in skills)
                      SettingsNavigationRow(
                        selected: skill.id == selectedId && !skill.isShadowed,
                        enabled: !skill.isShadowed,
                        title: TRText.inherit(skill.name),
                        description: TRText.inherit(
                          skillSourceLabel(l10n, skill.source),
                        ),
                        leading: skill.isShadowed || skill.isStale
                            ? TRTooltip(
                                message: skill.isShadowed
                                    ? l10n.skillSettingsShadowed
                                    : l10n.skillSettingsStale,
                                child: const Icon(TinestIcons.warning),
                              )
                            : null,
                        trailing: TRSwitch(
                          checked: skill.isEnabled,
                          onCheckedChange: skill.isMandatory || skill.isShadowed
                              ? null
                              : (enabled) => ref
                                    .read(
                                      skillsControllerProvider(
                                        hostId,
                                        workspaceId,
                                      ).notifier,
                                    )
                                    .setEnabled(skill.id, enabled: enabled),
                        ),
                        onPressed: skill.isShadowed
                            ? null
                            : () => onSelected(skill.id),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

/// Maps one skill source onto its localized badge.
String skillSourceLabel(AppLocalizations l10n, SkillSource source) =>
    switch (source) {
      SkillSource.builtIn => l10n.skillSettingsSourceBuiltIn,
      SkillSource.userHome => l10n.skillSettingsSourceUserHome,
      SkillSource.config => l10n.skillSettingsSourceConfig,
      SkillSource.project => l10n.skillSettingsSourceProject,
    };

class _SkillEditor extends ConsumerStatefulWidget {
  const _SkillEditor({
    required this.hostId,
    required this.workspaceId,
    required this.skill,
    required this.onDeleted,
    super.key,
  });

  final String hostId;
  final String? workspaceId;
  final SkillDto skill;
  final VoidCallback onDeleted;

  @override
  ConsumerState<_SkillEditor> createState() => _SkillEditorState();
}

class _SkillEditorState extends ConsumerState<_SkillEditor> {
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _body;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.skill.name);
    _description = TextEditingController(text: widget.skill.description);
    _body = TextEditingController(text: widget.skill.body);
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final skill = widget.skill;
    final editable = skill.isEditable && !_saving;
    return Column(
      children: <Widget>[
        TRPaneHeader(
          title: TRText.inherit(skill.name),
          contentMaxWidth: TinestLayoutMetrics.settingsContentMaxWidth,
          description: TRText.inherit(
            skill.sourcePath.isEmpty
                ? skillSourceLabel(l10n, skill.source)
                : skill.sourcePath,
          ),
          actions: <Widget>[
            if (skill.sourcePath.isNotEmpty)
              TRIconButton(
                appearance: TRAppearance.ghost,
                label: l10n.skillSettingsCopyPath,
                onPressed: () => unawaited(
                  // A copy leaves nothing on screen, so without this the
                  // button is indistinguishable from one that did nothing.
                  ref
                      .read(toastMessengerProvider)
                      .run(
                        () => Clipboard.setData(
                          ClipboardData(text: skill.sourcePath),
                        ),
                        failure: l10n.commonActionFailed,
                        success: l10n.commonCopied,
                        id: 'skill-copy-path',
                      ),
                ),
                icon: const Icon(TinestIcons.copy),
              ),
            if (skill.isEditable)
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
              SettingsSection(
                title: l10n.skillSettingsStateHeading,
                // Being built in and having a parse diagnostic are independent
                // facts, so neither hides the other.
                banner: skill.isEditable && skill.diagnostics.isEmpty
                    ? null
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          if (!skill.isEditable)
                            TRAlert(
                              title: TRText.inherit(l10n.skillSettingsReadOnly),
                              icon: const Icon(TinestIcons.lock),
                            ),
                          if (!skill.isEditable && skill.diagnostics.isNotEmpty)
                            const SizedBox(height: TRSpacing.small),
                          if (skill.diagnostics.isNotEmpty)
                            TRAlert(
                              title: TRText.inherit(
                                skill.diagnostics.first.code,
                              ),
                              description: TRText.inherit(
                                skill.diagnostics
                                    .map((diagnostic) => diagnostic.message)
                                    .join('\n'),
                              ),
                              icon: const Icon(TinestIcons.warning),
                              variant: TRStatusVariant.warning,
                            ),
                        ],
                      ),
                children: <Widget>[
                  TinestSwitchRow(
                    key: ValueKey<String>('skill-enabled-${skill.id}'),
                    value: skill.isEnabled,
                    onChanged: skill.isMandatory
                        ? null
                        : (enabled) => unawaited(
                            ref
                                .read(toastMessengerProvider)
                                .run(
                                  () => ref
                                      .read(
                                        skillsControllerProvider(
                                          widget.hostId,
                                          widget.workspaceId,
                                        ).notifier,
                                      )
                                      .setEnabled(skill.id, enabled: enabled),
                                  failure: l10n.skillSettingsToggleFailed,
                                  id: 'skill-enabled-${skill.id}',
                                ),
                          ),
                    title: TRText.inherit(l10n.skillSettingsEnabled),
                    subtitle: skill.isMandatory
                        ? TRText(l10n.skillSettingsMandatory)
                        : null,
                  ),
                ],
              ),
              SettingsSection.form(
                title: l10n.skillSettingsDefinitionHeading,
                children: <Widget>[
                  TRTextField(
                    initialValue: skillSourceLabel(l10n, skill.source),
                    enabled: false,
                    label: l10n.skillSettingsSource,
                  ),
                  TRTextField(
                    controller: _name,
                    enabled: editable,
                    label: l10n.commonName,
                  ),
                  TRTextField(
                    controller: _description,
                    enabled: editable,
                    minLines: 2,
                    maxLines: 4,
                    label: l10n.commonDescription,
                  ),
                  TRTextField(
                    key: const ValueKey<String>('skill-instructions-field'),
                    controller: _body,
                    enabled: editable,
                    minLines: 8,
                    maxLines: 18,
                    label: l10n.skillSettingsInstructions,
                  ),
                ],
              ),
              SettingsSection(
                title: l10n.skillSettingsResources,
                children: <Widget>[
                  if (skill.resources.isEmpty)
                    SettingsRow(
                      title: TRText.inherit(l10n.skillSettingsNoResources),
                    ),
                  for (final resource in skill.resources)
                    SettingsRow(
                      leading: const Icon(TinestIcons.file),
                      title: TRText.inherit(resource.path),
                      control: TRText.inherit('${resource.sizeBytes}'),
                    ),
                ],
              ),
              if (skill.isEditable)
                SettingsSection(
                  title: l10n.skillSettingsDelete,
                  children: <Widget>[
                    SettingsRow(
                      title: TRText.inherit(
                        l10n.skillSettingsDeleteMessage,
                      ),
                      control: TRButton(
                        key: const ValueKey<String>('skill-delete-button'),
                        appearance: TRAppearance.ghost,
                        intent: TRIntent.danger,
                        onPressed: editable ? _delete : null,
                        child: TRText.inherit(l10n.skillSettingsDelete),
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

  Future<void> _save({required bool force}) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _saving = true);
    try {
      await ref
          .read(
            skillsControllerProvider(
              widget.hostId,
              widget.workspaceId,
            ).notifier,
          )
          .save(
            widget.skill.copyWith(
              name: _name.text.trim(),
              description: _description.text.trim(),
              body: _body.text,
            ),
            expectedContentHash: widget.skill.contentHash,
            force: force,
          );
      ref
          .read(toastMessengerProvider)
          .success(l10n.commonSaved, id: 'skill-save');
    } on Exception catch (error) {
      if (!mounted) return;
      final retry = await showTRDialog<bool>(
        context: context,
        builder: (context) => TRAlertDialog(
          title: TRText.inherit(l10n.skillSettingsSaveFailedTitle),
          content: TRText.inherit('$error'),
          actions: <TRButton>[
            TRButton(
              appearance: TRAppearance.ghost,
              onPressed: () => Navigator.pop(context, false),
              child: TRText.inherit(l10n.skillSettingsReload),
            ),
            TRButton(
              intent: TRIntent.primary,
              onPressed: () => Navigator.pop(context, true),
              child: TRText.inherit(l10n.skillSettingsOverwrite),
            ),
          ],
        ),
      );
      if (retry == true && mounted) await _save(force: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showTRDialog<bool>(
      context: context,
      builder: (context) => TRAlertDialog(
        title: TRText.inherit(l10n.skillSettingsDeleteTitle(widget.skill.name)),
        content: TRText.inherit(l10n.skillSettingsDeleteMessage),
        actions: <TRButton>[
          TRButton(
            appearance: TRAppearance.ghost,
            onPressed: () => Navigator.pop(context, false),
            child: TRText.inherit(l10n.commonCancel),
          ),
          TRButton(
            intent: TRIntent.danger,
            onPressed: () => Navigator.pop(context, true),
            child: TRText.inherit(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final deleted = await ref
        .read(toastMessengerProvider)
        .run(
          () => ref
              .read(
                skillsControllerProvider(
                  widget.hostId,
                  widget.workspaceId,
                ).notifier,
              )
              .delete(widget.skill.id),
          failure: l10n.skillSettingsDeleteFailed,
          success: l10n.commonDeleted,
          id: 'skill-delete',
        );
    if (deleted) widget.onDeleted();
  }
}

class _CreateSkillInput {
  const _CreateSkillInput({
    required this.id,
    required this.name,
    required this.description,
    required this.source,
  });

  final String id;
  final String name;
  final String description;
  final SkillSource source;
}

class _CreateSkillPane extends StatefulWidget {
  const _CreateSkillPane({
    required this.existingIds,
    required this.allowProject,
    required this.onCreate,
    required this.onCreated,
    required this.onCancel,
  });

  final Set<String> existingIds;
  final bool allowProject;
  final Future<SkillDto> Function(_CreateSkillInput input) onCreate;
  final ValueChanged<SkillDto> onCreated;
  final VoidCallback onCancel;

  @override
  State<_CreateSkillPane> createState() => _CreateSkillPaneState();
}

class _CreateSkillPaneState extends State<_CreateSkillPane> {
  static final RegExp _idPattern = RegExp(r'^[a-z0-9][a-z0-9_-]{0,63}$');

  final TextEditingController _id = TextEditingController();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _description = TextEditingController();
  SkillSource _source = SkillSource.config;
  bool _saving = false;
  Object? _error;

  bool get _idAccepted {
    final id = _id.text.trim();
    return _idPattern.hasMatch(id) && !widget.existingIds.contains(id);
  }

  bool get _valid =>
      _idAccepted &&
      _name.text.trim().isNotEmpty &&
      _description.text.trim().isNotEmpty;

  String? _idError(AppLocalizations l10n) {
    final id = _id.text.trim();
    if (id.isEmpty) return null;
    if (!_idPattern.hasMatch(id)) return l10n.skillSettingsIdInvalid;
    if (widget.existingIds.contains(id)) return l10n.skillSettingsIdTaken;
    return null;
  }

  @override
  void dispose() {
    _id.dispose();
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sources = <SkillSource>[
      SkillSource.config,
      SkillSource.userHome,
      if (widget.allowProject) SkillSource.project,
    ];
    return Column(
      children: <Widget>[
        TRPaneHeader(
          title: TRText.inherit(l10n.skillSettingsAddTitle),
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
                    label: l10n.skillSettingsIdLabel,
                    // An ID becomes a directory name, so the example stays a
                    // literal identifier in every language.
                    placeholder: 'release-notes',
                    errorText: _idError(l10n),
                  ),
                  TRTextField(
                    controller: _name,
                    enabled: !_saving,
                    onChanged: (_) => setState(() => _error = null),
                    label: l10n.commonName,
                  ),
                  TRTextField(
                    controller: _description,
                    enabled: !_saving,
                    onChanged: (_) => setState(() => _error = null),
                    label: l10n.commonDescription,
                  ),
                  TRSelectFormField<SkillSource>(
                    initialValue: _source,
                    searchable: true,
                    searchPlaceholder: l10n.selectSearchPlaceholder,
                    noResultsText: l10n.selectNoResults,
                    // Explicit for the auditable adaptive Select contract.
                    // ignore: avoid_redundant_argument_values
                    surface: TRSelectSurface.auto,
                    label: l10n.skillSettingsSource,
                    width: TinestLayoutMetrics.settingsContentMaxWidth,
                    items: sources
                        .map(
                          (value) => TRSelectItem<SkillSource>(
                            value: value,
                            label: skillSourceLabel(l10n, value),
                          ),
                        )
                        .toList(growable: false),
                    onValueChange: _saving
                        ? null
                        : (value) => setState(() => _source = value!),
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
        _CreateSkillInput(
          id: _id.text.trim(),
          name: _name.text.trim(),
          description: _description.text.trim(),
          source: _source,
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
