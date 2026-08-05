import 'dart:async';

import 'package:coder_app/l10n/gen/app_localizations.dart';
import 'package:coder_app/src/coder_icons.dart';
import 'package:coder_app/src/coder_list_row.dart';
import 'package:coder_app/src/controller.dart';
import 'package:coder_client/coder_client.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

/// Splits a hook text field into one command per non-blank line.
List<String> parseHookCommands(String value) => <String>[
  for (final line in value.split('\n'))
    if (line.trim().isNotEmpty) line.trim(),
];

/// Renders configured hook commands as editable text.
String formatHookCommands(List<String> commands) => commands.join('\n');

/// Per-project settings manager for one connected daemon.
class ProjectSettingsPage extends ConsumerStatefulWidget {
  /// Creates a project settings page.
  const ProjectSettingsPage({required this.hostId, super.key});

  /// App-local daemon profile identifier.
  final String hostId;

  @override
  ConsumerState<ProjectSettingsPage> createState() =>
      _ProjectSettingsPageState();
}

class _ProjectSettingsPageState extends ConsumerState<ProjectSettingsPage> {
  String? _selectedId;

  @override
  void didUpdateWidget(ProjectSettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hostId != widget.hostId) _selectedId = null;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(workspaceCatalogControllerProvider);
    return state.when(
      loading: () => const Center(child: TRSpinner()),
      error: (error, _) => _ProjectSettingsError(
        error: error,
        onRetry: () => ref.invalidate(workspaceCatalogControllerProvider),
      ),
      data: (value) {
        final projects = _projects(value);
        if (projects.isEmpty) {
          return Center(
            child: Text(
              AppLocalizations.of(context).projectSettingsNoProjects,
            ),
          );
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 760;
            if (!compact &&
                !projects.any((project) => project.id == _selectedId)) {
              _selectedId = projects.first.id;
            }
            final selected = projects
                .where((project) => project.id == _selectedId)
                .firstOrNull;
            if (compact && selected != null) {
              return _ProjectEditor(
                key: ValueKey<String>('${widget.hostId} ${selected.id}'),
                hostId: widget.hostId,
                workspace: selected,
                onBack: () => setState(() => _selectedId = null),
              );
            }
            final list = _ProjectList(
              projects: projects,
              selectedId: _selectedId,
              onSelected: (id) => setState(() => _selectedId = id),
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
                            ).projectSettingsSelectProject,
                          ),
                        )
                      : _ProjectEditor(
                          key: ValueKey<String>(
                            '${widget.hostId} ${selected.id}',
                          ),
                          hostId: widget.hostId,
                          workspace: selected,
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  List<WorkspaceDto> _projects(UnifiedWorkspaceCatalogState state) =>
      <WorkspaceDto>[
        ...?state.catalogs[widget.hostId]?.workspaces,
      ]..sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
}

class _ProjectList extends StatelessWidget {
  const _ProjectList({
    required this.projects,
    required this.selectedId,
    required this.onSelected,
  });

  final List<WorkspaceDto> projects;
  final String? selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: <Widget>[
        CoderListRow(
          title: Text(l10n.projectSettingsHeading),
          subtitle: Text(l10n.projectSettingsCount(projects.length)),
        ),
        const TRSeparator(),
        Expanded(
          child: ListView(
            children: <Widget>[
              for (final project in projects)
                CoderListRow(
                  selected: project.id == selectedId,
                  leading: Icon(
                    project.kind == WorkspaceKind.git
                        ? CoderIcons.worktree
                        : CoderIcons.folder,
                  ),
                  title: Text(project.name),
                  subtitle: Text(
                    project.rootPath,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(CoderIcons.chevronRight),
                  onTap: () => onSelected(project.id),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProjectEditor extends ConsumerStatefulWidget {
  const _ProjectEditor({
    required this.hostId,
    required this.workspace,
    this.onBack,
    super.key,
  });

  final String hostId;
  final WorkspaceDto workspace;
  final VoidCallback? onBack;

  @override
  ConsumerState<_ProjectEditor> createState() => _ProjectEditorState();
}

class _ProjectEditorState extends ConsumerState<_ProjectEditor> {
  final TextEditingController _setup = TextEditingController();
  final TextEditingController _teardown = TextEditingController();
  final TextEditingController _shellExecutable = TextEditingController();
  final TextEditingController _shellArguments = TextEditingController();
  final TextEditingController _hostShellExecutable = TextEditingController();
  final TextEditingController _hostShellArguments = TextEditingController();
  bool _loaded = false;
  bool _saving = false;
  String? _error;
  bool _saved = false;

  @override
  void dispose() {
    _setup.dispose();
    _teardown.dispose();
    _shellExecutable.dispose();
    _shellArguments.dispose();
    _hostShellExecutable.dispose();
    _hostShellArguments.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final provider = projectSettingsControllerProvider(
      widget.hostId,
      widget.workspace.id,
    );
    final state = ref.watch(provider);
    return state.when(
      loading: () => const Center(child: TRSpinner()),
      error: (error, _) => _ProjectSettingsError(
        error: error,
        onRetry: () => ref.invalidate(provider),
      ),
      data: (value) {
        if (!_loaded) {
          _loaded = true;
          _setup.text = formatHookCommands(value.settings.setup);
          _teardown.text = formatHookCommands(value.settings.teardown);
          _shellExecutable.text = value.settings.shell?.executable ?? '';
          _shellArguments.text = formatHookCommands(
            value.settings.shell?.arguments ?? const <String>[],
          );
          unawaited(_loadHostShell());
        }
        return Column(
          children: <Widget>[
            CoderListRow(
              leading: widget.onBack == null
                  ? null
                  : TRIconButton(
                      appearance: TRAppearance.ghost,
                      label: l10n.projectSettingsProjectList,
                      onPressed: widget.onBack,
                      icon: const Icon(CoderIcons.back),
                    ),
              title: Text(widget.workspace.name),
              subtitle: Text(value.sourcePath),
              trailing: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  TRIconButton(
                    appearance: TRAppearance.ghost,
                    label: l10n.projectSettingsCopyPath,
                    onPressed: () => Clipboard.setData(
                      ClipboardData(text: value.sourcePath),
                    ),
                    icon: const Icon(CoderIcons.copy),
                  ),
                  TRButton(
                    intent: TRIntent.primary,
                    onPressed: _saving ? null : _save,
                    child: Text(
                      _saving ? l10n.commonSaving : l10n.commonSave,
                    ),
                  ),
                ],
              ),
            ),
            const TRSeparator(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: <Widget>[
                  if (_saved) ...[
                    TRAlert(
                      title: Text(l10n.commonSaved),
                      variant: TRStatusVariant.success,
                      icon: const Icon(CoderIcons.success),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_error case final error?)
                    TRCard(
                      padding: TRCardPadding.none,
                      variant: TRCardVariant.elevated,
                      child: CoderListRow(
                        leading: const Icon(CoderIcons.error),
                        title: Text(error),
                      ),
                    ),
                  Text(
                    'Worktree lifecycle hooks',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.projectSettingsHookHelp,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  TRTextField(
                    controller: _setup,
                    enabled: !_saving,
                    minLines: 3,
                    maxLines: 8,
                    label: l10n.projectSettingsSetup,
                    placeholder: 'npm install',
                  ),
                  const SizedBox(height: 16),
                  TRTextField(
                    controller: _teardown,
                    enabled: !_saving,
                    minLines: 3,
                    maxLines: 8,
                    label: l10n.projectSettingsTeardown,
                    placeholder: 'docker compose down',
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.projectSettingsShellHeading,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.projectSettingsShellHelp,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  TRTextField(
                    key: const ValueKey<String>('project-shell-executable'),
                    uiSize: TRUiSize.sm,
                    controller: _shellExecutable,
                    enabled: !_saving,
                    label: l10n.projectSettingsShellExecutable,
                    placeholder: '/bin/zsh',
                  ),
                  const SizedBox(height: 16),
                  TRTextField(
                    key: const ValueKey<String>('project-shell-arguments'),
                    uiSize: TRUiSize.sm,
                    controller: _shellArguments,
                    enabled: !_saving,
                    minLines: 2,
                    maxLines: 4,
                    label: l10n.projectSettingsShellArguments,
                    placeholder: '-l',
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.projectSettingsHostShellHeading,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.projectSettingsHostShellHelp,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  TRTextField(
                    key: const ValueKey<String>('host-shell-executable'),
                    uiSize: TRUiSize.sm,
                    controller: _hostShellExecutable,
                    enabled: !_saving,
                    label: l10n.projectSettingsShellExecutable,
                    placeholder: '/bin/zsh',
                  ),
                  const SizedBox(height: 16),
                  TRTextField(
                    key: const ValueKey<String>('host-shell-arguments'),
                    uiSize: TRUiSize.sm,
                    controller: _hostShellArguments,
                    enabled: !_saving,
                    minLines: 2,
                    maxLines: 4,
                    label: l10n.projectSettingsShellArguments,
                    placeholder: '-l',
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
      _saved = false;
    });
    try {
      final registry = await ref.read(hostRegistryControllerProvider.future);
      final hostShell = _hostShellExecutable.text.trim().isEmpty
          ? null
          : ShellSpecDto(
              executable: _hostShellExecutable.text.trim(),
              arguments: parseHookCommands(_hostShellArguments.text),
            );
      await registry.runtimes[widget.hostId]!.api!.setTerminalShell(hostShell);
      await ref
          .read(
            projectSettingsControllerProvider(
              widget.hostId,
              widget.workspace.id,
            ).notifier,
          )
          .save(
            ProjectSettingsDto(
              setup: parseHookCommands(_setup.text),
              teardown: parseHookCommands(_teardown.text),
              shell: _shellExecutable.text.trim().isEmpty
                  ? null
                  : ShellSpecDto(
                      executable: _shellExecutable.text.trim(),
                      arguments: parseHookCommands(_shellArguments.text),
                    ),
            ),
          );
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saved = true;
      });
    } on CoderClientException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _saving = false;
      });
    }
  }

  Future<void> _loadHostShell() async {
    try {
      final registry = await ref.read(hostRegistryControllerProvider.future);
      final shell = await registry.runtimes[widget.hostId]!.api!
          .getTerminalShell();
      if (!mounted) return;
      _hostShellExecutable.text = shell?.executable ?? '';
      _hostShellArguments.text = formatHookCommands(
        shell?.arguments ?? const <String>[],
      );
    } on Object catch (error) {
      if (mounted) setState(() => _error = '$error');
    }
  }
}

class _ProjectSettingsError extends StatelessWidget {
  const _ProjectSettingsError({required this.error, required this.onRetry});

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
          onPressed: onRetry,
          child: Text(AppLocalizations.of(context).commonRetry),
        ),
      ],
    ),
  );
}
