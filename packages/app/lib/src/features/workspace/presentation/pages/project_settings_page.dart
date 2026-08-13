import 'dart:async';

import 'package:app/l10n/gen/app_localizations.dart';
import 'package:app/src/features/terminals/application/terminals_controller.dart';
import 'package:app/src/features/workspace/application/workspace_controller.dart';
import 'package:app/src/shared/presentation/settings_layout.dart';
import 'package:app/src/shared/presentation/tinest_icons.dart';
import 'package:app/src/shared/presentation/tinest_layout_metrics.dart';
import 'package:app/src/shared/presentation/toast_messenger.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:protocol/protocol.dart';
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
    // Catalogs merge per host, so this host's section can still be on its way
    // even though the unified state already has a value. An empty project
    // list must not render for a catalog that has simply not arrived.
    if (state.value?.isHostPending(widget.hostId) ?? false) {
      return SettingsSkeletonLayout.listDetail(
        semanticLabel: AppLocalizations.of(context).settingsLoading,
      );
    }
    return SettingsAsyncContent<UnifiedWorkspaceCatalogState>(
      state: state,
      loading: SettingsSkeletonLayout.listDetail(
        semanticLabel: AppLocalizations.of(context).settingsLoading,
      ),
      error: (error, _) => _ProjectSettingsError(
        error: error,
        onRetry: () => ref.invalidate(workspaceCatalogControllerProvider),
      ),
      data: (value) {
        final projects = _projects(value);
        if (projects.isEmpty) {
          return SettingsEmptyState(
            title: AppLocalizations.of(context).projectSettingsNoProjects,
            icon: const Icon(TinestIcons.folder),
          );
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            final compact =
                constraints.maxWidth < TinestLayoutMetrics.compactBreakpoint;
            if (!compact &&
                !projects.any((project) => project.id == _selectedId)) {
              _selectedId = projects.first.id;
            }
            final selected = projects
                .where((project) => project.id == _selectedId)
                .firstOrNull;
            final list = _ProjectList(
              projects: projects,
              selectedId: _selectedId,
              onSelected: (id) => setState(() => _selectedId = id),
            );
            final detail = selected == null
                ? SettingsEmptyState(
                    title: AppLocalizations.of(
                      context,
                    ).projectSettingsSelectProject,
                    icon: const Icon(TinestIcons.folder),
                  )
                : _ProjectEditor(
                    key: ValueKey<String>(
                      '${widget.hostId} ${selected.id}',
                    ),
                    hostId: widget.hostId,
                    workspace: selected,
                  );
            return SettingsListDetailLayout(
              collection: list,
              detail: detail,
              detailVisible: selected != null,
              onBack: _showProjectList,
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
        SettingsPaneHeader.collection(
          title: l10n.projectSettingsHeading,
          subtitle: l10n.projectSettingsCount(projects.length),
        ),
        Expanded(
          child: SettingsCollectionList(
            children: <Widget>[
              for (final project in projects)
                SettingsRow.collection(
                  selected: project.id == selectedId,
                  leading: Icon(
                    project.kind == WorkspaceKind.git
                        ? TinestIcons.worktree
                        : TinestIcons.folder,
                  ),
                  title: TRText.inherit(project.name),
                  // The row already caps and ellipsizes its description.
                  description: TRText.inherit(project.rootPath),
                  control: const Icon(TinestIcons.chevronRight),
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
  bool _hostShellLoaded = false;
  bool _saving = false;

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
    final hostShellProvider = hostShellSettingsControllerProvider(
      widget.hostId,
    );
    final hostShellState = ref.watch(hostShellProvider);
    return SettingsAsyncContent<ProjectSettingsResultDto>(
      state: state,
      loading: SettingsSkeletonLayout.form(
        semanticLabel: l10n.settingsLoading,
      ),
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
        }
        if (!_hostShellLoaded && hostShellState.hasValue) {
          _hostShellLoaded = true;
          final shell = hostShellState.requireValue;
          _hostShellExecutable.text = shell?.executable ?? '';
          _hostShellArguments.text = formatHookCommands(
            shell?.arguments ?? const <String>[],
          );
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
                  onPressed: () => unawaited(
                    ref
                        .read(toastMessengerProvider)
                        .run(
                          () => Clipboard.setData(
                            ClipboardData(text: value.sourcePath),
                          ),
                          failure: l10n.commonActionFailed,
                          success: l10n.commonCopied,
                          id: 'project-settings-copy-path',
                        ),
                  ),
                  icon: const Icon(TinestIcons.copy),
                ),
                TRButton(
                  intent: TRIntent.primary,
                  onPressed: _saving || !hostShellState.hasValue ? null : _save,
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
                    children: <Widget>[
                      TRTextField(
                        controller: _setup,
                        enabled: !_saving,
                        minLines: 3,
                        maxLines: 8,
                        label: l10n.projectSettingsSetup,
                        // Hook placeholders are shell commands, not prose: the
                        // example has to stay something a shell would accept.
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
                    banner: hostShellState.hasError
                        ? TRAlert(
                            title: TRText.inherit(
                              l10n.settingsRefreshFailed(
                                '${hostShellState.error}',
                              ),
                            ),
                            variant: TRStatusVariant.danger,
                          )
                        : null,
                    children: hostShellState.hasValue
                        ? <Widget>[
                            TRTextField(
                              key: const ValueKey<String>(
                                'host-shell-executable',
                              ),
                              controller: _hostShellExecutable,
                              enabled: !_saving,
                              label: l10n.projectSettingsShellExecutable,
                              placeholder: '/bin/zsh',
                            ),
                            TRTextField(
                              key: const ValueKey<String>(
                                'host-shell-arguments',
                              ),
                              controller: _hostShellArguments,
                              enabled: !_saving,
                              minLines: 2,
                              maxLines: 4,
                              label: l10n.projectSettingsShellArguments,
                              placeholder: '-l',
                            ),
                          ]
                        : <Widget>[
                            SettingsSkeletonLayout.overlay(
                              semanticLabel: l10n.settingsLoading,
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
    final l10n = AppLocalizations.of(context);
    setState(() => _saving = true);
    // Every outcome runs through here, so the button cannot be left disabled by
    // a failure the previous catch clause did not name.
    await ref
        .read(toastMessengerProvider)
        .run(
          _write,
          failure: l10n.projectSettingsSaveFailed,
          success: l10n.commonSaved,
          id: 'project-settings-save',
        );
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _write() async {
    {
      final hostShell = _hostShellExecutable.text.trim().isEmpty
          ? null
          : ShellSpecDto(
              executable: _hostShellExecutable.text.trim(),
              arguments: parseHookCommands(_hostShellArguments.text),
            );
      await ref
          .read(
            hostShellSettingsControllerProvider(widget.hostId).notifier,
          )
          .save(hostShell);
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
