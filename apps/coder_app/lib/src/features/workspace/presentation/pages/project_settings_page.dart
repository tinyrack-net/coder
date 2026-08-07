import 'dart:async';

import 'package:coder_app/l10n/gen/app_localizations.dart';
import 'package:coder_app/src/features/hosts/application/host_controller.dart';
import 'package:coder_app/src/features/workspace/application/workspace_controller.dart';
import 'package:coder_app/src/shared/presentation/coder_icons.dart';
import 'package:coder_app/src/shared/presentation/coder_layout_metrics.dart';
import 'package:coder_app/src/shared/presentation/settings_layout.dart';
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
  SettingsPaneNavigationController? _paneNavigation;

  @override
  void dispose() {
    _paneNavigation?.clearBackHandler(this);
    super.dispose();
  }

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
          return SettingsEmptyState(
            title: AppLocalizations.of(context).projectSettingsNoProjects,
            icon: const Icon(CoderIcons.folder),
          );
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            final compact =
                constraints.maxWidth < CoderLayoutMetrics.compactBreakpoint;
            if (!compact &&
                !projects.any((project) => project.id == _selectedId)) {
              _selectedId = projects.first.id;
            }
            final selected = projects
                .where((project) => project.id == _selectedId)
                .firstOrNull;
            _paneNavigation = SettingsPaneNavigationScope.maybeOf(context);
            syncSettingsPaneBackHandler(
              context,
              owner: this,
              active: compact && selected != null,
              onBack: _showProjectList,
            );
            if (compact && selected != null) {
              return _ProjectEditor(
                key: ValueKey<String>('${widget.hostId} ${selected.id}'),
                hostId: widget.hostId,
                workspace: selected,
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
                          ).projectSettingsSelectProject,
                          icon: const Icon(CoderIcons.folder),
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

  void _showProjectList() => setState(() => _selectedId = null);
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
        SettingsPaneHeader.list(
          title: l10n.projectSettingsHeading,
          subtitle: l10n.projectSettingsCount(projects.length),
        ),
        Expanded(
          child: ListView(
            children: <Widget>[
              for (final project in projects)
                SettingsRow(
                  selected: project.id == selectedId,
                  leading: Icon(
                    project.kind == WorkspaceKind.git
                        ? CoderIcons.worktree
                        : CoderIcons.folder,
                  ),
                  title: TRText.inherit(project.name),
                  // The row already caps and ellipsizes its description.
                  description: TRText.inherit(project.rootPath),
                  control: const Icon(CoderIcons.chevronRight),
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
    super.key,
  });

  final String hostId;
  final WorkspaceDto workspace;

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
            SettingsPaneHeader.detail(
              title: widget.workspace.name,
              subtitle: value.sourcePath,
              actions: <Widget>[
                TRIconButton(
                  appearance: TRAppearance.ghost,
                  label: l10n.projectSettingsCopyPath,
                  onPressed: () =>
                      Clipboard.setData(ClipboardData(text: value.sourcePath)),
                  icon: const Icon(CoderIcons.copy),
                ),
                TRButton(
                  intent: TRIntent.primary,
                  onPressed: _saving ? null : _save,
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
                    title: l10n.projectSettingsHookHeading,
                    description: l10n.projectSettingsHookHelp,
                    banner: switch ((_saved, _error)) {
                      (_, final String error) => TRAlert(
                        title: TRText.inherit(error),
                        variant: TRStatusVariant.danger,
                        icon: const Icon(CoderIcons.error),
                      ),
                      (true, _) => TRAlert(
                        title: TRText.inherit(l10n.commonSaved),
                        variant: TRStatusVariant.success,
                        icon: const Icon(CoderIcons.success),
                      ),
                      _ => null,
                    },
                    children: <Widget>[
                      TRTextField(
                        controller: _setup,
                        enabled: !_saving,
                        minLines: 3,
                        maxLines: 8,
                        label: l10n.projectSettingsSetup,
                        placeholder: 'npm install',
                      ),
                      TRTextField(
                        controller: _teardown,
                        enabled: !_saving,
                        minLines: 3,
                        maxLines: 8,
                        label: l10n.projectSettingsTeardown,
                        placeholder: 'docker compose down',
                      ),
                    ],
                  ),
                  SettingsSection.form(
                    title: l10n.projectSettingsShellHeading,
                    description: l10n.projectSettingsShellHelp,
                    children: <Widget>[
                      TRTextField(
                        key: const ValueKey<String>('project-shell-executable'),
                        controller: _shellExecutable,
                        enabled: !_saving,
                        label: l10n.projectSettingsShellExecutable,
                        placeholder: '/bin/zsh',
                      ),
                      TRTextField(
                        key: const ValueKey<String>('project-shell-arguments'),
                        controller: _shellArguments,
                        enabled: !_saving,
                        minLines: 2,
                        maxLines: 4,
                        label: l10n.projectSettingsShellArguments,
                        placeholder: '-l',
                      ),
                    ],
                  ),
                  SettingsSection.form(
                    title: l10n.projectSettingsHostShellHeading,
                    description: l10n.projectSettingsHostShellHelp,
                    children: <Widget>[
                      TRTextField(
                        key: const ValueKey<String>('host-shell-executable'),
                        controller: _hostShellExecutable,
                        enabled: !_saving,
                        label: l10n.projectSettingsShellExecutable,
                        placeholder: '/bin/zsh',
                      ),
                      TRTextField(
                        key: const ValueKey<String>('host-shell-arguments'),
                        controller: _hostShellArguments,
                        enabled: !_saving,
                        minLines: 2,
                        maxLines: 4,
                        label: l10n.projectSettingsShellArguments,
                        placeholder: '-l',
                      ),
                    ],
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
      await registry.runtimes[widget.hostId]!.api!.terminals.setTerminalShell(
        hostShell,
      );
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
      final shell = await registry.runtimes[widget.hostId]!.api!.terminals
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
