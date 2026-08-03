import 'package:coder_app/l10n/gen/app_localizations.dart';
import 'package:coder_app/src/controller.dart';
import 'package:coder_client/coder_client.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      loading: () => const Center(child: CircularProgressIndicator()),
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
        ListTile(
          title: Text(l10n.projectSettingsHeading),
          subtitle: Text(l10n.projectSettingsCount(projects.length)),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            children: <Widget>[
              for (final project in projects)
                ListTile(
                  selected: project.id == selectedId,
                  leading: Icon(
                    project.kind == WorkspaceKind.git
                        ? Icons.account_tree_outlined
                        : Icons.folder_outlined,
                  ),
                  title: Text(project.name),
                  subtitle: Text(
                    project.rootPath,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.chevron_right),
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
  bool _loaded = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _setup.dispose();
    _teardown.dispose();
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
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ProjectSettingsError(
        error: error,
        onRetry: () => ref.invalidate(provider),
      ),
      data: (value) {
        if (!_loaded) {
          _loaded = true;
          _setup.text = formatHookCommands(value.settings.setup);
          _teardown.text = formatHookCommands(value.settings.teardown);
        }
        return Column(
          children: <Widget>[
            ListTile(
              leading: widget.onBack == null
                  ? null
                  : IconButton(
                      tooltip: l10n.projectSettingsProjectList,
                      onPressed: widget.onBack,
                      icon: const Icon(Icons.arrow_back),
                    ),
              title: Text(widget.workspace.name),
              subtitle: Text(value.sourcePath),
              trailing: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  IconButton(
                    tooltip: l10n.projectSettingsCopyPath,
                    onPressed: () => Clipboard.setData(
                      ClipboardData(text: value.sourcePath),
                    ),
                    icon: const Icon(Icons.copy),
                  ),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: Text(
                      _saving ? l10n.commonSaving : l10n.commonSave,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: <Widget>[
                  if (_error case final error?)
                    Card(
                      color: Theme.of(context).colorScheme.errorContainer,
                      child: ListTile(
                        leading: const Icon(Icons.error_outline),
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
                  TextField(
                    controller: _setup,
                    enabled: !_saving,
                    minLines: 3,
                    maxLines: 8,
                    decoration: InputDecoration(
                      labelText: l10n.projectSettingsSetup,
                      hintText: 'npm install',
                      alignLabelWithHint: true,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _teardown,
                    enabled: !_saving,
                    minLines: 3,
                    maxLines: 8,
                    decoration: InputDecoration(
                      labelText: l10n.projectSettingsTeardown,
                      hintText: 'docker compose down',
                      alignLabelWithHint: true,
                      border: const OutlineInputBorder(),
                    ),
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
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
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
            ),
          );
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.commonSaved)));
    } on CoderClientException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _saving = false;
      });
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
        FilledButton(
          onPressed: onRetry,
          child: Text(AppLocalizations.of(context).commonRetry),
        ),
      ],
    ),
  );
}
