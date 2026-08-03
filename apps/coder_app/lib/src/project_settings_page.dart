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
          return const Center(child: Text('등록된 project가 없습니다.'));
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
                      ? const Center(child: Text('Project를 선택하세요.'))
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
  Widget build(BuildContext context) => Column(
    children: <Widget>[
      ListTile(
        title: const Text('Projects'),
        subtitle: Text('${projects.length} projects'),
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
                      tooltip: 'Project 목록',
                      onPressed: widget.onBack,
                      icon: const Icon(Icons.arrow_back),
                    ),
              title: Text(widget.workspace.name),
              subtitle: Text(value.sourcePath),
              trailing: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  IconButton(
                    tooltip: '파일 위치 복사',
                    onPressed: () => Clipboard.setData(
                      ClipboardData(text: value.sourcePath),
                    ),
                    icon: const Icon(Icons.copy),
                  ),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: Text(_saving ? '저장 중…' : '저장'),
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
                    '한 줄에 명령 하나를 적으면 daemon 호스트의 shell에서 순서대로 '
                    '실행됩니다. CODER_WORKTREE_PATH, CODER_PROJECT_PATH, '
                    'CODER_BRANCH 환경변수를 사용할 수 있습니다.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _setup,
                    enabled: !_saving,
                    minLines: 3,
                    maxLines: 8,
                    decoration: const InputDecoration(
                      labelText: 'Setup (worktree 생성 후)',
                      hintText: 'npm install',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _teardown,
                    enabled: !_saving,
                    minLines: 3,
                    maxLines: 8,
                    decoration: const InputDecoration(
                      labelText: 'Teardown (worktree 제거 전)',
                      hintText: 'docker compose down',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
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
      ).showSnackBar(const SnackBar(content: Text('저장했습니다.')));
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
        FilledButton(onPressed: onRetry, child: const Text('다시 시도')),
      ],
    ),
  );
}
