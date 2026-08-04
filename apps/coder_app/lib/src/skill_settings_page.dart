import 'package:coder_app/l10n/gen/app_localizations.dart';
import 'package:coder_app/src/controller.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Skill manager for one connected daemon, optionally scoped to a project.
class SkillSettingsPage extends ConsumerStatefulWidget {
  /// Creates a skill settings page.
  const SkillSettingsPage({
    required this.hostId,
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

  @override
  ConsumerState<SkillSettingsPage> createState() => _SkillSettingsPageState();
}

class _SkillSettingsPageState extends ConsumerState<SkillSettingsPage> {
  String? _selectedId;

  @override
  void didUpdateWidget(SkillSettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hostId != widget.hostId ||
        oldWidget.workspaceId != widget.workspaceId) {
      _selectedId = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = skillsControllerProvider(
      widget.hostId,
      widget.workspaceId,
    );
    final state = ref.watch(provider);
    return Column(
      children: <Widget>[
        _ProjectSelector(
          hostId: widget.hostId,
          workspaceId: widget.workspaceId,
          onChanged: widget.onWorkspaceChanged,
        ),
        const Divider(height: 1),
        Expanded(
          child: state.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _SkillSettingsError(
              error: error,
              onRetry: () => ref.invalidate(provider),
            ),
            data: _buildCatalog,
          ),
        ),
      ],
    );
  }

  Widget _buildCatalog(List<SkillDto> skills) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 760;
      if (!compact && !skills.any((skill) => skill.id == _selectedId)) {
        _selectedId = skills.firstOrNull?.id;
      }
      final selected = skills
          .where((skill) => skill.id == _selectedId)
          .firstOrNull;
      if (compact && selected != null) {
        return _SkillEditor(
          key: ValueKey<String>('${selected.id}:${selected.contentHash}'),
          hostId: widget.hostId,
          workspaceId: widget.workspaceId,
          skill: selected,
          onBack: () => setState(() => _selectedId = null),
          onDeleted: () => setState(() => _selectedId = null),
        );
      }
      final list = _SkillList(
        hostId: widget.hostId,
        workspaceId: widget.workspaceId,
        skills: skills,
        selectedId: _selectedId,
        onSelected: (id) => setState(() => _selectedId = id),
        onCreate: () => _create(skills),
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
                      AppLocalizations.of(context).skillSettingsSelectSkill,
                    ),
                  )
                : _SkillEditor(
                    key: ValueKey<String>(
                      '${selected.id}:${selected.contentHash}',
                    ),
                    hostId: widget.hostId,
                    workspaceId: widget.workspaceId,
                    skill: selected,
                    onDeleted: () => setState(() => _selectedId = null),
                  ),
          ),
        ],
      );
    },
  );

  Future<void> _create(List<SkillDto> skills) async {
    final created = await showDialog<SkillDto>(
      context: context,
      builder: (context) => _CreateSkillDialog(
        existingIds: skills.map((skill) => skill.id).toSet(),
        allowProject: widget.workspaceId != null,
        onCreate: (input) => ref
            .read(
              skillsControllerProvider(
                widget.hostId,
                widget.workspaceId,
              ).notifier,
            )
            .create(
              id: input.id,
              source: input.source,
              name: input.name,
              description: input.description,
              body: '',
            ),
      ),
    );
    if (created != null && mounted) setState(() => _selectedId = created.id);
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: DropdownButtonFormField<String?>(
        initialValue: selected?.id,
        decoration: InputDecoration(
          labelText: l10n.skillSettingsProject,
          helperText: l10n.skillSettingsProjectHint,
        ),
        items: <DropdownMenuItem<String?>>[
          DropdownMenuItem<String?>(
            child: Text(l10n.skillSettingsProjectNone),
          ),
          for (final workspace in workspaces)
            DropdownMenuItem<String?>(
              value: workspace.id,
              child: Text(workspace.name),
            ),
        ],
        onChanged: onChanged,
      ),
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
        ListTile(
          title: Text(l10n.skillSettingsHeading),
          subtitle: Text(l10n.skillSettingsCount(skills.length)),
          trailing: IconButton(
            tooltip: l10n.skillSettingsAdd,
            onPressed: onCreate,
            icon: const Icon(Icons.add),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            children: <Widget>[
              for (final skill in skills)
                ListTile(
                  selected: skill.id == selectedId && !skill.isShadowed,
                  enabled: !skill.isShadowed,
                  title: Text(skill.name),
                  subtitle: Text(skillSourceLabel(l10n, skill.source)),
                  leading: skill.isShadowed || skill.isStale
                      ? Tooltip(
                          message: skill.isShadowed
                              ? l10n.skillSettingsShadowed
                              : l10n.skillSettingsStale,
                          child: const Icon(Icons.warning_amber, size: 18),
                        )
                      : null,
                  trailing: Switch(
                    value: skill.isEnabled,
                    onChanged: skill.isMandatory || skill.isShadowed
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
                  onTap: skill.isShadowed ? null : () => onSelected(skill.id),
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
    this.onBack,
    super.key,
  });

  final String hostId;
  final String? workspaceId;
  final SkillDto skill;
  final VoidCallback onDeleted;
  final VoidCallback? onBack;

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
        ListTile(
          leading: widget.onBack == null
              ? null
              : IconButton(
                  tooltip: l10n.skillSettingsList,
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back),
                ),
          title: Text(skill.name),
          subtitle: Text(
            skill.sourcePath.isEmpty
                ? skillSourceLabel(l10n, skill.source)
                : skill.sourcePath,
          ),
          trailing: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              if (skill.sourcePath.isNotEmpty)
                IconButton(
                  tooltip: l10n.skillSettingsCopyPath,
                  onPressed: () => Clipboard.setData(
                    ClipboardData(text: skill.sourcePath),
                  ),
                  icon: const Icon(Icons.copy),
                ),
              if (skill.isEditable)
                IconButton(
                  tooltip: l10n.skillSettingsDelete,
                  onPressed: editable ? _delete : null,
                  icon: const Icon(Icons.delete_outline),
                ),
              if (skill.isEditable)
                FilledButton(
                  onPressed: editable ? () => _save(force: false) : null,
                  child: Text(_saving ? l10n.commonSaving : l10n.commonSave),
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: <Widget>[
              if (!skill.isEditable)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.lock_outline),
                    title: Text(l10n.skillSettingsReadOnly),
                  ),
                ),
              for (final diagnostic in skill.diagnostics)
                Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: ListTile(
                    leading: const Icon(Icons.warning_amber),
                    title: Text(diagnostic.code),
                    subtitle: Text(diagnostic.message),
                  ),
                ),
              SwitchListTile(
                value: skill.isEnabled,
                onChanged: skill.isMandatory
                    ? null
                    : (enabled) => ref
                          .read(
                            skillsControllerProvider(
                              widget.hostId,
                              widget.workspaceId,
                            ).notifier,
                          )
                          .setEnabled(skill.id, enabled: enabled),
                title: Text(l10n.skillSettingsEnabled),
                subtitle: skill.isMandatory
                    ? Text(l10n.skillSettingsMandatory)
                    : null,
              ),
              TextFormField(
                initialValue: skillSourceLabel(l10n, skill.source),
                enabled: false,
                decoration: InputDecoration(
                  labelText: l10n.skillSettingsSource,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _name,
                enabled: editable,
                decoration: InputDecoration(labelText: l10n.commonName),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _description,
                enabled: editable,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: l10n.commonDescription,
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _body,
                enabled: editable,
                minLines: 8,
                maxLines: 18,
                decoration: InputDecoration(
                  labelText: l10n.skillSettingsInstructions,
                  alignLabelWithHint: true,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.skillSettingsResources,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (skill.resources.isEmpty)
                ListTile(title: Text(l10n.skillSettingsNoResources)),
              for (final resource in skill.resources)
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.insert_drive_file_outlined),
                  title: Text(resource.path),
                  trailing: Text('${resource.sizeBytes}'),
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
    } on Exception catch (error) {
      if (!mounted) return;
      final retry = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.skillSettingsSaveFailedTitle),
          content: Text('$error'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.skillSettingsReload),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.skillSettingsOverwrite),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.skillSettingsDeleteTitle(widget.skill.name)),
        content: Text(l10n.skillSettingsDeleteMessage),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref
        .read(
          skillsControllerProvider(widget.hostId, widget.workspaceId).notifier,
        )
        .delete(widget.skill.id);
    widget.onDeleted();
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

class _CreateSkillDialog extends StatefulWidget {
  const _CreateSkillDialog({
    required this.existingIds,
    required this.allowProject,
    required this.onCreate,
  });

  final Set<String> existingIds;
  final bool allowProject;
  final Future<SkillDto> Function(_CreateSkillInput input) onCreate;

  @override
  State<_CreateSkillDialog> createState() => _CreateSkillDialogState();
}

class _CreateSkillDialogState extends State<_CreateSkillDialog> {
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
    return AlertDialog(
      title: Text(l10n.skillSettingsAddTitle),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: _id,
              autofocus: true,
              enabled: !_saving,
              onChanged: (_) => setState(() => _error = null),
              decoration: InputDecoration(
                labelText: l10n.skillSettingsIdLabel,
                hintText: 'release-notes',
              ).copyWith(errorText: _idError(l10n)),
            ),
            TextField(
              controller: _name,
              enabled: !_saving,
              onChanged: (_) => setState(() => _error = null),
              decoration: InputDecoration(labelText: l10n.commonName),
            ),
            TextField(
              controller: _description,
              enabled: !_saving,
              onChanged: (_) => setState(() => _error = null),
              decoration: InputDecoration(labelText: l10n.commonDescription),
            ),
            DropdownButtonFormField<SkillSource>(
              initialValue: _source,
              decoration: InputDecoration(labelText: l10n.skillSettingsSource),
              items: sources
                  .map(
                    (value) => DropdownMenuItem<SkillSource>(
                      value: value,
                      child: Text(skillSourceLabel(l10n, value)),
                    ),
                  )
                  .toList(growable: false),
              onChanged: _saving
                  ? null
                  : (value) => setState(() => _source = value!),
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
      actions: <Widget>[
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
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
        _CreateSkillInput(
          id: _id.text.trim(),
          name: _name.text.trim(),
          description: _description.text.trim(),
          source: _source,
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

class _SkillSettingsError extends StatelessWidget {
  const _SkillSettingsError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text('$error'),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: onRetry,
          child: Text(AppLocalizations.of(context).commonRetry),
        ),
      ],
    ),
  );
}
