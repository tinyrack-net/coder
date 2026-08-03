import 'dart:async';
import 'dart:convert';

import 'package:coder_app/src/agent_settings_page.dart';
import 'package:coder_app/src/app_services.dart';
import 'package:coder_app/src/app_settings_page.dart';
import 'package:coder_app/src/controller.dart';
import 'package:coder_app/src/external_url_opener.dart';
import 'package:coder_app/src/host_models.dart';
import 'package:coder_app/src/settings_page.dart';
import 'package:coder_client/coder_client.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

part 'app.g.dart';

/// Tinyrack Coder application composition.
class CoderApp extends StatelessWidget {
  /// Creates the application.
  CoderApp({
    required this.services,
    this.externalUrlOpener = const PlatformExternalUrlOpener(),
    super.key,
  });

  /// Platform services used by feature controllers.
  final AppServices services;

  /// Opens interactive provider authorization pages.
  final ExternalUrlOpener externalUrlOpener;

  late final GoRouter _router = GoRouter(routes: $appRoutes);

  @override
  Widget build(BuildContext context) => ProviderScope(
    overrides: [
      appServicesProvider.overrideWithValue(services),
      externalUrlOpenerProvider.overrideWithValue(externalUrlOpener),
    ],
    child: MaterialApp.router(
      title: 'Tinyrack Coder',
      debugShowCheckedModeBanner: false,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      routerConfig: _router,
    ),
  );
}

ThemeData _theme(Brightness brightness) => ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: brightness == Brightness.light
        ? const Color(0xff625bff)
        : const Color(0xff948dff),
    brightness: brightness,
  ),
  useMaterial3: true,
  cardTheme: const CardThemeData(margin: EdgeInsets.zero),
);

@TypedGoRoute<WorkspaceHomeRoute>(path: '/')
/// Unified workspace home shown before daemon connections complete.
class WorkspaceHomeRoute extends GoRouteData with $WorkspaceHomeRoute {
  /// Creates the workspace home route.
  const WorkspaceHomeRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const WorkspacePage();
}

@TypedGoRoute<WorktreeRoute>(
  path: '/workspaces/:hostId/:workspaceId/:worktreeId',
)
/// Opens a checkout and its session tabs.
class WorktreeRoute extends GoRouteData with $WorktreeRoute {
  /// Creates a checkout route.
  const WorktreeRoute({
    required this.hostId,
    required this.workspaceId,
    required this.worktreeId,
  });

  /// App-local daemon ID.
  final String hostId;

  /// Daemon-local repository ID.
  final String workspaceId;

  /// Daemon-local checkout ID.
  final String worktreeId;

  @override
  Widget build(BuildContext context, GoRouterState state) => WorkspacePage(
    selection: WorkspaceSelection(
      hostId: hostId,
      workspaceId: workspaceId,
      worktreeId: worktreeId,
    ),
  );
}

@TypedGoRoute<SessionRoute>(
  path: '/workspaces/:hostId/:workspaceId/:worktreeId/sessions/:sessionId',
)
/// Opens one AI session in the checkout tab strip.
class SessionRoute extends GoRouteData with $SessionRoute {
  /// Creates a session route.
  const SessionRoute({
    required this.hostId,
    required this.workspaceId,
    required this.worktreeId,
    required this.sessionId,
  });

  /// App-local daemon ID.
  final String hostId;

  /// Daemon-local repository ID.
  final String workspaceId;

  /// Daemon-local checkout ID.
  final String worktreeId;

  /// Daemon-local AI session ID.
  final String sessionId;

  @override
  Widget build(BuildContext context, GoRouterState state) => WorkspacePage(
    selection: WorkspaceSelection(
      hostId: hostId,
      workspaceId: workspaceId,
      worktreeId: worktreeId,
    ),
    requestedAgentId: sessionId,
  );
}

@TypedGoRoute<ProviderSettingsRoute>(path: '/settings/providers')
/// Unified settings route with Provider selected.
class ProviderSettingsRoute extends GoRouteData with $ProviderSettingsRoute {
  /// Creates the provider settings route.
  const ProviderSettingsRoute({this.hostId});

  /// Preferred daemon in the provider selector.
  final String? hostId;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      UnifiedSettingsPage(category: SettingsCategory.provider, hostId: hostId);
}

@TypedGoRoute<AgentSettingsRoute>(path: '/settings/agents')
/// Unified settings route with Agent selected.
class AgentSettingsRoute extends GoRouteData with $AgentSettingsRoute {
  /// Creates the agent settings route.
  const AgentSettingsRoute({this.hostId});

  /// Preferred daemon in the agent selector.
  final String? hostId;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      UnifiedSettingsPage(category: SettingsCategory.agent, hostId: hostId);
}

@TypedGoRoute<DaemonSettingsRoute>(path: '/settings/daemons')
/// Unified settings route with Daemon selected.
class DaemonSettingsRoute extends GoRouteData with $DaemonSettingsRoute {
  /// Creates daemon settings route.
  const DaemonSettingsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const UnifiedSettingsPage(category: SettingsCategory.daemon);
}

@TypedGoRoute<NewHostRoute>(path: '/settings/daemons/new')
/// Adds a remote daemon profile.
class NewHostRoute extends GoRouteData with $NewHostRoute {
  /// Creates the route.
  const NewHostRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const RemoteHostEditPage();
}

@TypedGoRoute<EditHostRoute>(path: '/settings/daemons/:hostId')
/// Edits a remote daemon profile.
class EditHostRoute extends GoRouteData with $EditHostRoute {
  /// Creates the route.
  const EditHostRoute({required this.hostId});

  /// App-local daemon profile ID.
  final String hostId;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      RemoteHostEditPage(hostId: hostId);
}

/// Top-level settings categories.
enum SettingsCategory {
  /// Markdown-backed agent definitions owned by one daemon.
  agent,

  /// API provider connections owned by one daemon.
  provider,

  /// Embedded and remote daemon connections.
  daemon,
}

/// Shared two-pane settings shell.
class UnifiedSettingsPage extends ConsumerStatefulWidget {
  /// Creates a unified settings page.
  const UnifiedSettingsPage({
    required this.category,
    this.hostId,
    super.key,
  });

  /// Selected settings category.
  final SettingsCategory category;

  /// Preferred provider daemon.
  final String? hostId;

  @override
  ConsumerState<UnifiedSettingsPage> createState() =>
      _UnifiedSettingsPageState();
}

class _UnifiedSettingsPageState extends ConsumerState<UnifiedSettingsPage> {
  String? _hostId;

  @override
  Widget build(BuildContext context) {
    final registry = ref.watch(hostRegistryControllerProvider).asData?.value;
    final online =
        registry?.runtimes.values
            .where((item) => item.connected)
            .toList(growable: false) ??
        const <HostRuntimeSnapshot>[];
    _hostId ??= online.any((item) => item.id == widget.hostId)
        ? widget.hostId
        : online.firstOrNull?.id;
    final detail = switch (widget.category) {
      SettingsCategory.agent => _AgentSettingsDetail(
        hosts: online,
        hostId: _hostId,
        onChanged: (value) => setState(() => _hostId = value),
      ),
      SettingsCategory.provider => _ProviderSettingsDetail(
        hosts: online,
        hostId: _hostId,
        onChanged: (value) => setState(() => _hostId = value),
      ),
      SettingsCategory.daemon => const AppSettingsPage(embedded: true),
    };
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => const WorkspaceHomeRoute().go(context),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('설정'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 760) return detail;
          return Row(
            children: <Widget>[
              SizedBox(
                width: 230,
                child: _SettingsSidebar(selected: widget.category),
              ),
              const VerticalDivider(width: 1),
              Expanded(child: detail),
            ],
          );
        },
      ),
    );
  }
}

class _SettingsSidebar extends StatelessWidget {
  const _SettingsSidebar({required this.selected});

  final SettingsCategory selected;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(12),
    children: <Widget>[
      ListTile(
        selected: selected == SettingsCategory.agent,
        leading: const Icon(Icons.smart_toy_outlined),
        title: const Text('Agent'),
        onTap: () => const AgentSettingsRoute().go(context),
      ),
      ListTile(
        selected: selected == SettingsCategory.provider,
        leading: const Icon(Icons.hub_outlined),
        title: const Text('Provider'),
        onTap: () => const ProviderSettingsRoute().go(context),
      ),
      ListTile(
        selected: selected == SettingsCategory.daemon,
        leading: const Icon(Icons.dns_outlined),
        title: const Text('Daemon'),
        onTap: () => const DaemonSettingsRoute().go(context),
      ),
    ],
  );
}

class _AgentSettingsDetail extends StatelessWidget {
  const _AgentSettingsDetail({
    required this.hosts,
    required this.hostId,
    required this.onChanged,
  });

  final List<HostRuntimeSnapshot> hosts;
  final String? hostId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    if (hosts.isEmpty || hostId == null) {
      return const Center(child: Text('온라인 daemon 연결이 필요합니다.'));
    }
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: DropdownButtonFormField<String>(
            initialValue: hostId,
            decoration: const InputDecoration(labelText: 'Daemon'),
            items: hosts
                .map(
                  (host) => DropdownMenuItem<String>(
                    value: host.id,
                    child: Text(host.label),
                  ),
                )
                .toList(growable: false),
            onChanged: onChanged,
          ),
        ),
        Expanded(child: AgentSettingsPage(hostId: hostId!)),
      ],
    );
  }
}

class _ProviderSettingsDetail extends StatelessWidget {
  const _ProviderSettingsDetail({
    required this.hosts,
    required this.hostId,
    required this.onChanged,
  });

  final List<HostRuntimeSnapshot> hosts;
  final String? hostId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    if (hosts.isEmpty || hostId == null) {
      return const Center(child: Text('온라인 daemon 연결이 필요합니다.'));
    }
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: DropdownButtonFormField<String>(
            initialValue: hostId,
            decoration: const InputDecoration(labelText: 'Daemon'),
            items: hosts
                .map(
                  (host) => DropdownMenuItem<String>(
                    value: host.id,
                    child: Text(host.label),
                  ),
                )
                .toList(growable: false),
            onChanged: onChanged,
          ),
        ),
        Expanded(child: SettingsPage(hostId: hostId!, embedded: true)),
      ],
    );
  }
}

/// Unified host/repository/worktree tree and session-tab workspace.
class WorkspacePage extends ConsumerStatefulWidget {
  /// Creates a workspace page.
  const WorkspacePage({
    this.selection,
    this.requestedAgentId,
    super.key,
  });

  /// Selected checkout, if any.
  final WorkspaceSelection? selection;

  /// Session requested by the route.
  final String? requestedAgentId;

  @override
  ConsumerState<WorkspacePage> createState() => _WorkspacePageState();
}

class _WorkspacePageState extends ConsumerState<WorkspacePage> {
  bool _restoreScheduled = false;

  @override
  Widget build(BuildContext context) {
    final registry = ref.watch(hostRegistryControllerProvider);
    final catalog = ref.watch(workspaceCatalogControllerProvider);
    _restoreSelection(registry.asData?.value, catalog.asData?.value);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workspaces'),
        actions: <Widget>[
          IconButton(
            tooltip: '폴더 추가',
            onPressed:
                registry.asData?.value.runtimes.values.any(
                      (item) => item.connected,
                    ) ==
                    true
                ? () => _addFolder(registry.requireValue)
                : null,
            icon: const Icon(Icons.create_new_folder_outlined),
          ),
          IconButton(
            tooltip: '설정',
            onPressed: () {
              final hostId = widget.selection?.hostId;
              if (hostId == null) {
                const DaemonSettingsRoute().go(context);
              } else {
                ProviderSettingsRoute(hostId: hostId).go(context);
              }
            },
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final tree = _WorkspaceTree(
            registry: registry.asData?.value,
            catalog: catalog,
            selected: widget.selection,
            onAddFolder: registry.asData == null
                ? null
                : () => _addFolder(registry.requireValue),
          );
          if (constraints.maxWidth < 760) {
            return widget.selection == null
                ? tree
                : _SessionArea(
                    selection: widget.selection!,
                    requestedAgentId: widget.requestedAgentId,
                    showBack: true,
                  );
          }
          return Row(
            children: <Widget>[
              SizedBox(width: 320, child: tree),
              const VerticalDivider(width: 1),
              Expanded(
                child: widget.selection == null
                    ? const _EmptyWorkspaceDetail()
                    : _SessionArea(
                        selection: widget.selection!,
                        requestedAgentId: widget.requestedAgentId,
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _restoreSelection(
    HostRegistryState? registry,
    UnifiedWorkspaceCatalogState? catalog,
  ) {
    if (_restoreScheduled || widget.selection != null) return;
    final saved = registry?.settings.lastWorktree;
    if (saved == null || catalog == null) return;
    final exists =
        catalog.catalogs[saved.hostId]?.worktrees.any(
          (item) =>
              item.id == saved.worktreeId &&
              item.workspaceId == saved.workspaceId,
        ) ??
        false;
    if (!exists) return;
    _restoreScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _goWorktree(context, saved);
    });
  }

  Future<void> _addFolder(HostRegistryState registry) async {
    final online = registry.runtimes.values
        .where((item) => item.connected)
        .toList(growable: false);
    final hostId = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('폴더를 추가할 daemon'),
        children: <Widget>[
          for (final host in online)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, host.id),
              child: ListTile(
                leading: Icon(
                  host.kind == HostKind.embedded
                      ? Icons.computer_outlined
                      : Icons.cloud_outlined,
                ),
                title: Text(host.label),
              ),
            ),
        ],
      ),
    );
    if (hostId == null || !mounted) return;
    final host = registry.runtimes[hostId]!;
    final path =
        host.kind == HostKind.embedded &&
            ref.read(appServicesProvider).supportsEmbeddedDaemon
        ? await getDirectoryPath(confirmButtonText: 'Workspace 선택')
        : await showDialog<String>(
            context: context,
            builder: (context) => _RemoteDirectoryDialog(api: host.api!),
          );
    if (path == null || !mounted) return;
    final result = await ref
        .read(workspaceCatalogControllerProvider.notifier)
        .register(hostId, path);
    if (!mounted || result.worktrees.isEmpty) return;
    _goWorktree(
      context,
      WorkspaceSelection(
        hostId: hostId,
        workspaceId: result.workspace.id,
        worktreeId: result.worktrees.first.id,
      ),
    );
  }
}

class _WorkspaceTree extends StatelessWidget {
  const _WorkspaceTree({
    required this.registry,
    required this.catalog,
    required this.selected,
    required this.onAddFolder,
  });

  final HostRegistryState? registry;
  final AsyncValue<UnifiedWorkspaceCatalogState> catalog;
  final WorkspaceSelection? selected;
  final VoidCallback? onAddFolder;

  @override
  Widget build(BuildContext context) {
    final runtimes =
        registry?.runtimes.values.toList(growable: false) ??
        const <HostRuntimeSnapshot>[];
    final catalogs =
        catalog.asData?.value.catalogs ?? const <String, WorkspaceCatalogDto>{};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ListTile(
          title: const Text('Repositories'),
          trailing: IconButton(
            tooltip: '폴더 추가',
            onPressed: onAddFolder,
            icon: const Icon(Icons.add),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: runtimes.isEmpty
              ? _NoDaemonState(
                  onSettings: () {
                    const DaemonSettingsRoute().go(context);
                  },
                )
              : ListView(
                  children: <Widget>[
                    for (final host in runtimes)
                      _HostTreeNode(
                        host: host,
                        catalog: catalogs[host.id],
                        selected: selected,
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _HostTreeNode extends StatelessWidget {
  const _HostTreeNode({
    required this.host,
    required this.catalog,
    required this.selected,
  });

  final HostRuntimeSnapshot host;
  final WorkspaceCatalogDto? catalog;
  final WorkspaceSelection? selected;

  @override
  Widget build(BuildContext context) {
    final workspaces = catalog?.workspaces ?? const <WorkspaceDto>[];
    if (!host.connected) {
      return ListTile(
        leading: const Icon(Icons.cloud_off_outlined),
        title: Text(host.label),
        subtitle: Text(
          '${_hostStatusLabel(host.status)}'
          '${host.error == null ? '' : ' · ${host.error}'}',
        ),
      );
    }
    return ExpansionTile(
      initiallyExpanded: true,
      leading: const Icon(Icons.dns_outlined),
      title: Text(host.label),
      subtitle: Text(_hostStatusLabel(host.status)),
      children: <Widget>[
        for (final workspace in workspaces)
          _RepositoryTreeNode(
            hostId: host.id,
            workspace: workspace,
            worktrees: catalog!.worktrees
                .where((item) => item.workspaceId == workspace.id)
                .toList(growable: false),
            selected: selected,
          ),
      ],
    );
  }
}

class _RepositoryTreeNode extends ConsumerWidget {
  const _RepositoryTreeNode({
    required this.hostId,
    required this.workspace,
    required this.worktrees,
    required this.selected,
  });

  final String hostId;
  final WorkspaceDto workspace;
  final List<WorktreeDto> worktrees;
  final WorkspaceSelection? selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Padding(
    padding: const EdgeInsets.only(left: 16),
    child: ExpansionTile(
      initiallyExpanded: selected?.workspaceId == workspace.id,
      leading: Icon(
        workspace.kind == WorkspaceKind.git
            ? Icons.account_tree_outlined
            : Icons.folder_outlined,
      ),
      title: Row(
        children: <Widget>[
          Expanded(child: Text(workspace.name)),
          if (workspace.kind == WorkspaceKind.git)
            IconButton(
              tooltip: '새 worktree',
              visualDensity: VisualDensity.compact,
              onPressed: () => _createWorktree(context, ref),
              icon: const Icon(Icons.add, size: 18),
            ),
        ],
      ),
      subtitle: Text(
        workspace.rootPath,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      children: <Widget>[
        for (final worktree in worktrees)
          ListTile(
            contentPadding: const EdgeInsets.only(left: 48, right: 12),
            selected:
                selected?.hostId == hostId &&
                selected?.worktreeId == worktree.id,
            leading: Icon(
              worktree.kind == WorktreeKind.checkout
                  ? Icons.home_work_outlined
                  : Icons.call_split_outlined,
              size: 20,
            ),
            title: Text(worktree.branch ?? worktree.name),
            subtitle: Text(
              worktree.path,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: PopupMenuButton<String>(
              tooltip: 'Worktree 메뉴',
              onSelected: (action) {
                if (action == 'archive') {
                  unawaited(_archiveWorktree(context, ref, worktree));
                }
              },
              itemBuilder: (context) => const <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: 'archive',
                  child: Text('Archive'),
                ),
              ],
            ),
            onTap: () => _goWorktree(
              context,
              WorkspaceSelection(
                hostId: hostId,
                workspaceId: workspace.id,
                worktreeId: worktree.id,
              ),
            ),
          ),
      ],
    ),
  );

  Future<void> _createWorktree(BuildContext context, WidgetRef ref) async {
    final api = await _api(ref);
    final branches = await api.listGitBranches(workspace.id);
    if (!context.mounted) return;
    final draft = await showDialog<_WorktreeDraft>(
      context: context,
      builder: (context) => _CreateWorktreeDialog(branches: branches),
    );
    if (draft == null || !context.mounted) return;
    final worktree = await api.createWorktree(
      id: ref.read(appIdGeneratorProvider).generate(),
      workspaceId: workspace.id,
      mode: draft.mode,
      branchName: draft.branchName,
      baseBranch: draft.baseBranch,
    );
    await ref
        .read(workspaceCatalogControllerProvider.notifier)
        .refreshHost(hostId);
    if (!context.mounted) return;
    _goWorktree(
      context,
      WorkspaceSelection(
        hostId: hostId,
        workspaceId: workspace.id,
        worktreeId: worktree.id,
      ),
    );
  }

  Future<void> _archiveWorktree(
    BuildContext context,
    WidgetRef ref,
    WorktreeDto worktree,
  ) async {
    final api = await _api(ref);
    final preview = await api.previewWorktreeArchive(worktree.id);
    if (!context.mounted) return;
    if (preview.runningSessionCount > 0) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Archive할 수 없습니다'),
          content: Text(
            '실행 중인 session ${preview.runningSessionCount}개를 먼저 '
            '중지하세요.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('확인'),
            ),
          ],
        ),
      );
      return;
    }
    final risky = preview.dirty || preview.unpushedCommitCount > 0;
    final dirtyWarning = preview.dirty ? '커밋하지 않은 변경이 있습니다.\n' : '';
    final unpushedWarning = preview.unpushedCommitCount > 0
        ? '${preview.unpushedCommitCount}개의 push하지 않은 commit이 있습니다.\n'
        : '';
    final removalWarning = preview.removesDirectory
        ? 'Coder가 만든 checkout 디렉터리가 제거됩니다.'
        : '등록만 숨기고 디스크의 checkout은 유지합니다.';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${worktree.name}을 Archive할까요?'),
        content: Text('$dirtyWarning$unpushedWarning$removalWarning'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(risky ? '위험을 확인하고 Archive' : 'Archive'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await api.archiveWorktree(worktree.id, force: risky);
    await ref
        .read(workspaceCatalogControllerProvider.notifier)
        .refreshHost(hostId);
    if (context.mounted && selected?.worktreeId == worktree.id) {
      const WorkspaceHomeRoute().go(context);
    }
  }

  Future<CoderApi> _api(WidgetRef ref) async {
    final runtime = (await ref.read(
      hostRegistryControllerProvider.future,
    )).runtimes[hostId];
    return runtime?.api ??
        (throw StateError('Online daemon connection required.'));
  }
}

final class _WorktreeDraft {
  const _WorktreeDraft({
    required this.mode,
    required this.branchName,
    this.baseBranch,
  });

  final WorktreeCreateMode mode;
  final String branchName;
  final String? baseBranch;
}

class _CreateWorktreeDialog extends StatefulWidget {
  const _CreateWorktreeDialog({required this.branches});

  final List<GitBranchDto> branches;

  @override
  State<_CreateWorktreeDialog> createState() => _CreateWorktreeDialogState();
}

class _CreateWorktreeDialogState extends State<_CreateWorktreeDialog> {
  final _branch = TextEditingController();
  WorktreeCreateMode _mode = WorktreeCreateMode.newBranch;
  String? _baseBranch;

  @override
  void initState() {
    super.initState();
    _baseBranch = widget.branches
        .where((item) => item.current)
        .firstOrNull
        ?.name;
  }

  @override
  void dispose() {
    _branch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('새 worktree'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SegmentedButton<WorktreeCreateMode>(
          segments: const <ButtonSegment<WorktreeCreateMode>>[
            ButtonSegment<WorktreeCreateMode>(
              value: WorktreeCreateMode.newBranch,
              label: Text('새 branch'),
            ),
            ButtonSegment<WorktreeCreateMode>(
              value: WorktreeCreateMode.existingBranch,
              label: Text('기존 branch'),
            ),
          ],
          selected: <WorktreeCreateMode>{_mode},
          onSelectionChanged: (value) => setState(() {
            _mode = value.single;
            _branch.clear();
          }),
        ),
        const SizedBox(height: 16),
        if (_mode == WorktreeCreateMode.newBranch) ...<Widget>[
          TextField(
            controller: _branch,
            decoration: const InputDecoration(labelText: '새 branch 이름'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _baseBranch,
            decoration: const InputDecoration(labelText: 'Base branch'),
            items: widget.branches
                .map(
                  (branch) => DropdownMenuItem<String>(
                    value: branch.name,
                    child: Text(branch.name),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) => _baseBranch = value,
          ),
        ] else
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Local branch'),
            items: widget.branches
                .where((branch) => !branch.checkedOut)
                .map(
                  (branch) => DropdownMenuItem<String>(
                    value: branch.name,
                    child: Text(branch.name),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) => _branch.text = value ?? '',
          ),
      ],
    ),
    actions: <Widget>[
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('취소'),
      ),
      FilledButton(
        onPressed: () {
          final branch = _branch.text.trim();
          if (branch.isEmpty) return;
          Navigator.pop(
            context,
            _WorktreeDraft(
              mode: _mode,
              branchName: branch,
              baseBranch: _mode == WorktreeCreateMode.newBranch
                  ? _baseBranch
                  : null,
            ),
          );
        },
        child: const Text('생성'),
      ),
    ],
  );
}

class _NoDaemonState extends StatelessWidget {
  const _NoDaemonState({required this.onSettings});

  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text('설정된 daemon이 없습니다.'),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onSettings,
            child: const Text('Daemon 설정'),
          ),
        ],
      ),
    ),
  );
}

class _EmptyWorkspaceDetail extends StatelessWidget {
  const _EmptyWorkspaceDetail();

  @override
  Widget build(BuildContext context) => const Center(
    child: Text('왼쪽 트리에서 checkout 또는 worktree를 선택하세요.'),
  );
}

class _RemoteDirectoryDialog extends StatefulWidget {
  const _RemoteDirectoryDialog({required this.api});

  final CoderApi api;

  @override
  State<_RemoteDirectoryDialog> createState() => _RemoteDirectoryDialogState();
}

class _RemoteDirectoryDialogState extends State<_RemoteDirectoryDialog> {
  final _path = TextEditingController();
  List<DirectorySuggestionDto> _suggestions = const <DirectorySuggestionDto>[];

  @override
  void dispose() {
    _path.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Daemon의 폴더 선택'),
    content: SizedBox(
      width: 520,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextField(
            controller: _path,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Daemon 경로',
              hintText: '/srv/repositories/project',
            ),
            onChanged: _search,
          ),
          for (final suggestion in _suggestions)
            ListTile(
              dense: true,
              leading: const Icon(Icons.folder_outlined),
              title: Text(suggestion.name),
              subtitle: Text(suggestion.path),
              onTap: () => setState(() => _path.text = suggestion.path),
            ),
        ],
      ),
    ),
    actions: <Widget>[
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('취소'),
      ),
      FilledButton(
        onPressed: () {
          final value = _path.text.trim();
          if (value.isNotEmpty) Navigator.pop(context, value);
        },
        child: const Text('등록'),
      ),
    ],
  );

  Future<void> _search(String query) async {
    final suggestions = await widget.api.suggestDirectories(query);
    if (mounted) setState(() => _suggestions = suggestions);
  }
}

class _SessionArea extends ConsumerStatefulWidget {
  const _SessionArea({
    required this.selection,
    this.requestedAgentId,
    this.showBack = false,
  });

  final WorkspaceSelection selection;
  final String? requestedAgentId;
  final bool showBack;

  @override
  ConsumerState<_SessionArea> createState() => _SessionAreaState();
}

class _SessionAreaState extends ConsumerState<_SessionArea> {
  bool _requestedOpened = false;

  @override
  Widget build(BuildContext context) {
    final provider = sessionTabsControllerProvider(widget.selection);
    final tabs = ref.watch(provider);
    final state = tabs.asData?.value;
    if (!_requestedOpened &&
        widget.requestedAgentId != null &&
        state != null &&
        state.sessions.any((item) => item.id == widget.requestedAgentId)) {
      _requestedOpened = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(
            ref.read(provider.notifier).open(widget.requestedAgentId!),
          );
        }
      });
    }
    return Column(
      children: <Widget>[
        SizedBox(
          height: 48,
          child: Row(
            children: <Widget>[
              if (widget.showBack)
                IconButton(
                  onPressed: () => const WorkspaceHomeRoute().go(context),
                  icon: const Icon(Icons.arrow_back),
                ),
              Expanded(
                child: state == null
                    ? const LinearProgressIndicator()
                    : ListView(
                        scrollDirection: Axis.horizontal,
                        children: <Widget>[
                          for (final id in state.openAgentIds)
                            _SessionTab(
                              agent: state.sessions
                                  .where((item) => item.id == id)
                                  .first,
                              selected: state.selectedAgentId == id,
                              onSelect: () => _select(id),
                              onClose: () => _close(id),
                            ),
                        ],
                      ),
              ),
              IconButton(
                tooltip: '새 session',
                onPressed: state == null ? null : _createSession,
                icon: const Icon(Icons.add),
              ),
              if (state != null)
                PopupMenuButton<String>(
                  tooltip: '모든 session',
                  icon: const Icon(Icons.more_horiz),
                  onSelected: _open,
                  itemBuilder: (context) => <PopupMenuEntry<String>>[
                    for (final agent in state.sessions)
                      PopupMenuItem<String>(
                        value: agent.id,
                        child: Text(agent.title),
                      ),
                  ],
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: state?.selectedAgentId == null
              ? _NoSession(onCreate: _createSession)
              : _ConversationPane(
                  selection: widget.selection,
                  agent: state!.sessions
                      .where((item) => item.id == state.selectedAgentId)
                      .first,
                ),
        ),
      ],
    );
  }

  Future<void> _select(String id) async {
    await ref
        .read(sessionTabsControllerProvider(widget.selection).notifier)
        .select(id);
    if (mounted) _goSession(context, widget.selection, id);
  }

  Future<void> _open(String id) async {
    await ref
        .read(sessionTabsControllerProvider(widget.selection).notifier)
        .open(id);
    if (mounted) _goSession(context, widget.selection, id);
  }

  Future<void> _close(String id) async {
    final notifier = ref.read(
      sessionTabsControllerProvider(widget.selection).notifier,
    );
    await notifier.close(id);
    if (!mounted) return;
    final selected = ref
        .read(sessionTabsControllerProvider(widget.selection))
        .requireValue
        .selectedAgentId;
    if (selected == null) {
      _goWorktree(context, widget.selection);
    } else {
      _goSession(context, widget.selection, selected);
    }
  }

  Future<void> _createSession() async {
    final agentState = await ref.read(
      agentDefinitionsControllerProvider(widget.selection.hostId).future,
    );
    final providerState = await ref.read(
      providerSettingsControllerProvider(widget.selection.hostId).future,
    );
    if (providerState == null) return;
    final connections = providerState.connections
        .where(
          (item) =>
              item.status == ProviderConnectionStatus.connected ||
              item.status == ProviderConnectionStatus.degraded,
        )
        .toList(growable: false);
    final availableDefinitions = agentState.definitions
        .where((definition) {
          if (definition.mode != AgentMode.primary ||
              definition.isArchived ||
              definition.isStale) {
            return false;
          }
          return switch (definition.model.source) {
            AgentModelSource.daemonDefault => connections.any(
              (connection) =>
                  connection.isDefault && connection.defaultModelId != null,
            ),
            AgentModelSource.fixed => connections.any(
              (connection) =>
                  connection.id == definition.model.providerConnectionId &&
                  definition.model.modelId != null,
            ),
          };
        })
        .toList(growable: false);
    if (availableDefinitions.isEmpty || !mounted) return;
    final input = await showDialog<_NewSessionInput>(
      context: context,
      builder: (context) => _SessionNameDialog(
        definitions: availableDefinitions,
      ),
    );
    if (input == null || !mounted) return;
    final session = await ref
        .read(
          sessionsControllerProvider(
            widget.selection.hostId,
            widget.selection.worktreeId,
          ).notifier,
        )
        .create(
          title: input.title,
          agentDefinitionId: input.agentDefinitionId,
        );
    await ref
        .read(sessionTabsControllerProvider(widget.selection).notifier)
        .add(session);
    if (mounted) _goSession(context, widget.selection, session.id);
  }
}

class _SessionTab extends StatelessWidget {
  const _SessionTab({
    required this.agent,
    required this.selected,
    required this.onSelect,
    required this.onClose,
  });

  final SessionDto agent;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Material(
    color: selected
        ? Theme.of(context).colorScheme.secondaryContainer
        : Colors.transparent,
    child: InkWell(
      onTap: onSelect,
      child: Padding(
        padding: const EdgeInsets.only(left: 14),
        child: Row(
          children: <Widget>[
            Text(agent.title),
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: '탭 닫기',
              onPressed: onClose,
              icon: const Icon(Icons.close, size: 16),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SessionNameDialog extends StatefulWidget {
  const _SessionNameDialog({required this.definitions});

  final List<AgentDefinitionDto> definitions;

  @override
  State<_SessionNameDialog> createState() => _SessionNameDialogState();
}

class _SessionNameDialogState extends State<_SessionNameDialog> {
  final _title = TextEditingController(text: 'Coding session');
  late String _agentDefinitionId = widget.definitions.first.id;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('새 session'),
    content: SizedBox(
      width: 420,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextField(
            controller: _title,
            autofocus: true,
            decoration: const InputDecoration(labelText: '이름'),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _agentDefinitionId,
            decoration: const InputDecoration(labelText: 'Agent'),
            items: widget.definitions
                .map(
                  (definition) => DropdownMenuItem<String>(
                    value: definition.id,
                    child: Text(definition.name),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) {
              if (value != null) setState(() => _agentDefinitionId = value);
            },
          ),
        ],
      ),
    ),
    actions: <Widget>[
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('취소'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(
          context,
          _NewSessionInput(
            title: _title.text.trim(),
            agentDefinitionId: _agentDefinitionId,
          ),
        ),
        child: const Text('생성'),
      ),
    ],
  );
}

final class _NewSessionInput {
  const _NewSessionInput({
    required this.title,
    required this.agentDefinitionId,
  });

  final String title;
  final String agentDefinitionId;
}

class _NoSession extends StatelessWidget {
  const _NoSession({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => Center(
    child: FilledButton.icon(
      onPressed: onCreate,
      icon: const Icon(Icons.add),
      label: const Text('새 session 시작'),
    ),
  );
}

class _ConversationPane extends ConsumerStatefulWidget {
  const _ConversationPane({required this.selection, required this.agent});

  final WorkspaceSelection selection;
  final SessionDto agent;

  @override
  ConsumerState<_ConversationPane> createState() => _ConversationPaneState();
}

class _ConversationPaneState extends ConsumerState<_ConversationPane> {
  final _composer = TextEditingController();

  @override
  void dispose() {
    _composer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current =
        ref
            .watch(
              sessionsControllerProvider(
                widget.selection.hostId,
                widget.selection.worktreeId,
              ),
            )
            .asData
            ?.value
            .where((item) => item.id == widget.agent.id)
            .firstOrNull ??
        widget.agent;
    final busy =
        current.status == SessionStatus.running ||
        current.status == SessionStatus.waitingForApproval ||
        current.status == SessionStatus.waitingForSubagent;
    final conversation = ref.watch(
      conversationControllerProvider(widget.selection.hostId, current.id),
    );
    final value = conversation.asData?.value;
    final timeline = _coalesceAssistantDeltas(
      value?.timeline ?? const <TimelineEventDto>[],
    );
    return Column(
      children: <Widget>[
        ListTile(
          title: Text(current.title),
          subtitle: Text(
            '${current.agentDefinitionId} · ${current.origin.name}',
          ),
          trailing: busy
              ? IconButton(
                  tooltip: '중지',
                  onPressed: () => ref
                      .read(
                        conversationControllerProvider(
                          widget.selection.hostId,
                          current.id,
                        ).notifier,
                      )
                      .cancelTurn(),
                  icon: const Icon(Icons.stop_circle_outlined),
                )
              : null,
        ),
        Expanded(
          child: timeline.isEmpty
              ? const Center(child: Text('코딩 요청을 입력하세요.'))
              : ListView.separated(
                  reverse: true,
                  padding: const EdgeInsets.all(20),
                  itemCount: timeline.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => TimelineCard(
                    event: timeline[timeline.length - index - 1],
                  ),
                ),
        ),
        for (final approval
            in value?.approvals.values ?? const <ApprovalRequestDto>[])
          ApprovalCard(
            hostId: widget.selection.hostId,
            approval: approval,
          ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _composer,
                    minLines: 1,
                    maxLines: 8,
                    enabled: !busy,
                    decoration: const InputDecoration(
                      hintText: '코딩 요청을 입력하세요…',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: busy ? null : (_) => _send(current.id),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: busy ? null : () => _send(current.id),
                  icon: const Icon(Icons.arrow_upward),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _send(String sessionId) async {
    final text = _composer.text.trim();
    if (text.isEmpty) return;
    _composer.clear();
    await ref
        .read(
          conversationControllerProvider(
            widget.selection.hostId,
            sessionId,
          ).notifier,
        )
        .startTurn(text);
  }
}

List<TimelineEventDto> _coalesceAssistantDeltas(
  List<TimelineEventDto> events,
) {
  final result = <TimelineEventDto>[];
  for (final event in events) {
    if (event.type == 'assistant.delta' &&
        result.isNotEmpty &&
        result.last.type == 'assistant.delta' &&
        result.last.turnId == event.turnId) {
      final previous = result.removeLast();
      result.add(
        previous.copyWith(
          data: <String, dynamic>{
            'text':
                '${previous.data['text'] as String? ?? ''}'
                '${event.data['text'] as String? ?? ''}',
          },
        ),
      );
    } else {
      result.add(event);
    }
  }
  return result;
}

void _goWorktree(BuildContext context, WorkspaceSelection selection) {
  WorktreeRoute(
    hostId: selection.hostId,
    workspaceId: selection.workspaceId,
    worktreeId: selection.worktreeId,
  ).go(context);
}

void _goSession(
  BuildContext context,
  WorkspaceSelection selection,
  String sessionId,
) {
  SessionRoute(
    hostId: selection.hostId,
    workspaceId: selection.workspaceId,
    worktreeId: selection.worktreeId,
    sessionId: sessionId,
  ).go(context);
}

String _hostStatusLabel(HostRuntimeStatus status) => switch (status) {
  HostRuntimeStatus.online => '온라인',
  HostRuntimeStatus.connecting => '연결 중',
  HostRuntimeStatus.reconnecting => '재연결 중',
  HostRuntimeStatus.offline => '오프라인',
  HostRuntimeStatus.error => '오류',
  HostRuntimeStatus.conflict => '중복 daemon',
  HostRuntimeStatus.idle => '자동 연결 꺼짐',
};

/// Renders one persisted timeline event.
class TimelineCard extends StatelessWidget {
  /// Creates a [TimelineCard].
  const TimelineCard({required this.event, super.key});

  /// The event rendered by this card.
  final TimelineEventDto event;

  @override
  Widget build(BuildContext context) {
    final isUser = event.type == 'user.message';
    final isAssistant = event.type == 'assistant.delta';
    final text = event.data['text'] as String?;
    final display =
        text ?? const JsonEncoder.withIndent('  ').convert(event.data);
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Card(
          color: isUser ? Theme.of(context).colorScheme.primaryContainer : null,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  isUser
                      ? 'You'
                      : isAssistant
                      ? 'Assistant'
                      : event.type,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 5),
                if (isUser || isAssistant)
                  MarkdownBody(data: display)
                else
                  SelectableText(display),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Renders an actionable tool approval request.
class ApprovalCard extends ConsumerWidget {
  /// Creates an [ApprovalCard].
  const ApprovalCard({required this.hostId, required this.approval, super.key});

  /// Stable host profile containing the approval's agent.
  final String hostId;

  /// The pending approval rendered by this card.
  final ApprovalRequestDto approval;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
    child: Card(
      color: Theme.of(context).colorScheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              '승인 필요 · ${approval.toolName}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            SelectableText(
              approval.preview ??
                  const JsonEncoder.withIndent(
                    '  ',
                  ).convert(approval.arguments),
              maxLines: 12,
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                TextButton(
                  onPressed: () => ref
                      .read(
                        conversationControllerProvider(
                          hostId,
                          approval.sessionId,
                        ).notifier,
                      )
                      .resolveApproval(approval.id, approved: false),
                  child: const Text('거부'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => ref
                      .read(
                        conversationControllerProvider(
                          hostId,
                          approval.sessionId,
                        ).notifier,
                      )
                      .resolveApproval(approval.id, approved: true),
                  child: const Text('승인'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
