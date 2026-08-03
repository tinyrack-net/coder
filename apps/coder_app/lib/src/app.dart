import 'dart:async';

import 'package:coder_app/l10n/gen/app_localizations.dart';
import 'package:coder_app/src/agent_settings_page.dart';
import 'package:coder_app/src/app_services.dart';
import 'package:coder_app/src/app_settings_page.dart';
import 'package:coder_app/src/chat/chat_approval_card.dart';
import 'package:coder_app/src/chat/chat_plan_actions.dart';
import 'package:coder_app/src/chat/chat_timeline_model.dart';
import 'package:coder_app/src/chat/chat_timeline_view.dart';
import 'package:coder_app/src/controller.dart';
import 'package:coder_app/src/external_url_opener.dart';
import 'package:coder_app/src/general_settings_page.dart';
import 'package:coder_app/src/host_labels.dart';
import 'package:coder_app/src/host_models.dart';
import 'package:coder_app/src/project_settings_page.dart';
import 'package:coder_app/src/session_composer.dart';
import 'package:coder_app/src/session_model_options.dart';
import 'package:coder_app/src/settings_page.dart';
import 'package:coder_app/src/workspace/new_workspace_pane.dart';
import 'package:coder_app/src/workspace/workspace_sidebar.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:flutter/material.dart';
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
    child: _CoderAppView(router: _router),
  );
}

/// Builds the app shell below [ProviderScope] so it can watch settings.
class _CoderAppView extends ConsumerWidget {
  const _CoderAppView({required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localeTag = ref
        .watch(hostRegistryControllerProvider)
        .asData
        ?.value
        .settings
        .localeTag;
    return MaterialApp.router(
      title: 'Tinyrack Coder',
      debugShowCheckedModeBanner: false,
      theme: coderTheme(Brightness.light),
      darkTheme: coderTheme(Brightness.dark),
      // A null locale lets Flutter resolve the system locale against
      // [AppLocalizations.supportedLocales], which falls back to English.
      locale: localeTag == null ? null : Locale(localeTag),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }
}

/// Width at which the workspace and settings shells show both panes.
const double wideLayoutBreakpoint = 760;

/// Builds the shared Material theme for one brightness.
ThemeData coderTheme(Brightness brightness) => ThemeData(
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
  const WorkspaceHomeRoute({this.compose = false});

  /// Whether the right pane opens the new-workspace composer directly.
  final bool compose;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      WorkspacePage(compose: compose);
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

@TypedGoRoute<GeneralSettingsRoute>(path: '/settings/general')
/// Unified settings route with General selected.
class GeneralSettingsRoute extends GoRouteData with $GeneralSettingsRoute {
  /// Creates the general settings route.
  const GeneralSettingsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const UnifiedSettingsPage(category: SettingsCategory.general);
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

@TypedGoRoute<ProjectSettingsRoute>(path: '/settings/projects')
/// Unified settings route with Projects selected.
class ProjectSettingsRoute extends GoRouteData with $ProjectSettingsRoute {
  /// Creates the project settings route.
  const ProjectSettingsRoute({this.hostId});

  /// Preferred daemon in the project selector.
  final String? hostId;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      UnifiedSettingsPage(category: SettingsCategory.project, hostId: hostId);
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
  /// App-wide preferences that do not belong to any single daemon.
  general,

  /// Worktree lifecycle hooks stored in each project's `coder.json`.
  project,

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
    void selectHost(String? value) => setState(() => _hostId = value);
    final detail = switch (widget.category) {
      SettingsCategory.general => const GeneralSettingsPage(embedded: true),
      SettingsCategory.project => _HostScopedDetail(
        hosts: online,
        hostId: _hostId,
        onChanged: selectHost,
        builder: (hostId) => ProjectSettingsPage(hostId: hostId),
      ),
      SettingsCategory.agent => _HostScopedDetail(
        hosts: online,
        hostId: _hostId,
        onChanged: selectHost,
        builder: (hostId) => AgentSettingsPage(hostId: hostId),
      ),
      SettingsCategory.provider => _HostScopedDetail(
        hosts: online,
        hostId: _hostId,
        onChanged: selectHost,
        builder: (hostId) => SettingsPage(hostId: hostId, embedded: true),
      ),
      SettingsCategory.daemon => const AppSettingsPage(embedded: true),
    };
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => const WorkspaceHomeRoute().go(context),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(AppLocalizations.of(context).settingsTitle),
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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(12),
      children: <Widget>[
        ListTile(
          selected: selected == SettingsCategory.general,
          leading: const Icon(Icons.tune),
          title: Text(l10n.settingsCategoryGeneral),
          onTap: () => const GeneralSettingsRoute().go(context),
        ),
        ListTile(
          selected: selected == SettingsCategory.project,
          leading: const Icon(Icons.folder_copy_outlined),
          title: Text(l10n.settingsCategoryProjects),
          onTap: () => const ProjectSettingsRoute().go(context),
        ),
        ListTile(
          selected: selected == SettingsCategory.agent,
          leading: const Icon(Icons.smart_toy_outlined),
          title: Text(l10n.settingsCategoryAgent),
          onTap: () => const AgentSettingsRoute().go(context),
        ),
        ListTile(
          selected: selected == SettingsCategory.provider,
          leading: const Icon(Icons.hub_outlined),
          title: Text(l10n.settingsCategoryProvider),
          onTap: () => const ProviderSettingsRoute().go(context),
        ),
        ListTile(
          selected: selected == SettingsCategory.daemon,
          leading: const Icon(Icons.dns_outlined),
          title: Text(l10n.settingsCategoryDaemon),
          onTap: () => const DaemonSettingsRoute().go(context),
        ),
      ],
    );
  }
}

class _HostScopedDetail extends StatelessWidget {
  const _HostScopedDetail({
    required this.hosts,
    required this.hostId,
    required this.onChanged,
    required this.builder,
  });

  final List<HostRuntimeSnapshot> hosts;
  final String? hostId;
  final ValueChanged<String?> onChanged;
  final Widget Function(String hostId) builder;

  @override
  Widget build(BuildContext context) {
    if (hosts.isEmpty || hostId == null) {
      return Center(
        child: Text(AppLocalizations.of(context).settingsRequiresOnlineDaemon),
      );
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
                    child: Text(hostLabel(AppLocalizations.of(context), host)),
                  ),
                )
                .toList(growable: false),
            onChanged: onChanged,
          ),
        ),
        Expanded(child: builder(hostId!)),
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
    this.compose = false,
    super.key,
  });

  /// Whether the right pane opens the new-workspace composer directly.
  final bool compose;

  /// Selected checkout, if any.
  final WorkspaceSelection? selection;

  /// Session requested by the route.
  final String? requestedAgentId;

  @override
  ConsumerState<WorkspacePage> createState() => _WorkspacePageState();
}

class _WorkspacePageState extends ConsumerState<WorkspacePage> {
  /// Whether this state already queued the saved-worktree restore.
  bool _restoreScheduled = false;

  @override
  Widget build(BuildContext context) {
    final registry = ref.watch(hostRegistryControllerProvider);
    final catalog = ref.watch(workspaceCatalogControllerProvider);
    final collapsed = registry.value?.settings.sidebarCollapsed ?? false;
    _restoreSelection(registry.value, catalog.value);
    return Scaffold(
      appBar: AppBar(
        // The toggle keeps one position in both states: the very top left.
        leading: MediaQuery.sizeOf(context).width < wideLayoutBreakpoint
            ? null
            : IconButton(
                key: const ValueKey('workspace-sidebar-toggle'),
                tooltip: collapsed
                    ? AppLocalizations.of(context).workspaceSidebarExpand
                    : AppLocalizations.of(context).workspaceSidebarCollapse,
                onPressed: () => unawaited(_setSidebarCollapsed(!collapsed)),
                icon: Icon(collapsed ? Icons.menu : Icons.menu_open),
              ),
        title: Text(AppLocalizations.of(context).workspacesTitle),
        actions: <Widget>[
          IconButton(
            tooltip: AppLocalizations.of(context).settingsTitle,
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
          final sidebar = WorkspaceSidebar(
            registry: registry.value,
            catalog: catalog,
            selected: widget.selection,
            onNewWorkspace: () =>
                const WorkspaceHomeRoute(compose: true).go(context),
            onSelect: (selection) => _goWorktree(context, selection),
            onOpenDaemonSettings: () => const DaemonSettingsRoute().go(context),
            onArchivedSelection: () => const WorkspaceHomeRoute().go(context),
          );
          final detail = widget.selection == null
              ? NewWorkspacePane(
                  showBack: constraints.maxWidth < wideLayoutBreakpoint,
                  onBack: () => const WorkspaceHomeRoute().go(context),
                  onStarted: (selection, session) =>
                      _goSession(context, selection, session.id),
                )
              : _SessionArea(
                  selection: widget.selection!,
                  requestedAgentId: widget.requestedAgentId,
                  showBack: constraints.maxWidth < wideLayoutBreakpoint,
                );
          if (constraints.maxWidth < wideLayoutBreakpoint) {
            return widget.selection == null && !widget.compose
                ? sidebar
                : detail;
          }
          return Row(
            children: <Widget>[
              if (!collapsed) ...<Widget>[
                SizedBox(width: 320, child: sidebar),
                const VerticalDivider(width: 1),
              ],
              Expanded(child: detail),
            ],
          );
        },
      ),
    );
  }

  Future<void> _setSidebarCollapsed(bool collapsed) => ref
      .read(hostRegistryControllerProvider.notifier)
      .setSidebarCollapsed(collapsed: collapsed);

  void _restoreSelection(
    HostRegistryState? registry,
    UnifiedWorkspaceCatalogState? catalog,
  ) {
    // Opening the composer is an explicit choice; never bounce out of it.
    if (widget.compose || widget.selection != null) return;
    if (_restoreScheduled) return;
    if (ref.read(selectionRestoreControllerProvider)) return;
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
    // This runs from build, where writing a provider is not allowed, so the
    // restore is both marked and navigated after the frame. The local flag
    // covers the frames in between, which the provider cannot yet reject.
    _restoreScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(selectionRestoreControllerProvider.notifier).markConsumed();
      _goWorktree(context, saved);
    });
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
                tooltip: AppLocalizations.of(context).workspaceNewSession,
                onPressed: state == null ? null : _startDraft,
                icon: const Icon(Icons.add),
              ),
              if (state != null)
                PopupMenuButton<String>(
                  tooltip: AppLocalizations.of(context).workspaceAllSessions,
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
              ? DraftSessionPane(
                  selection: widget.selection,
                  onCreated: (session) =>
                      _goSession(context, widget.selection, session.id),
                )
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

  Future<void> _startDraft() async {
    await ref
        .read(sessionTabsControllerProvider(widget.selection).notifier)
        .startDraft();
    if (mounted) _goWorktree(context, widget.selection);
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
              tooltip: AppLocalizations.of(context).workspaceCloseTab,
              onPressed: onClose,
              icon: const Icon(Icons.close, size: 16),
            ),
          ],
        ),
      ),
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
  final Set<String> _dismissedPlans = <String>{};

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
            .value
            ?.where((item) => item.id == widget.agent.id)
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
    final items = projectChatTimeline(
      value?.timeline ?? const <TimelineEventDto>[],
    );
    final agents = ref
        .watch(agentDefinitionsControllerProvider(widget.selection.hostId))
        .value;
    final definitions = selectableAgentDefinitions(
      agents?.definitions ?? const <AgentDefinitionDto>[],
    );
    final connections =
        ref
            .watch(providerSettingsControllerProvider(widget.selection.hostId))
            .value
            ?.connections ??
        const <ProviderConnectionDto>[];
    final definition = definitions
        .where((item) => item.id == current.agentDefinitionId)
        .firstOrNull;
    final effective =
        current.model ??
        (definition == null
            ? null
            : defaultSelectionFor(definition, connections));
    // Only the newest finished plan can still be acted on.
    final lastPlan = items.whereType<ChatPlanProposal>().lastOrNull;
    final pendingPlan =
        !busy &&
            lastPlan != null &&
            lastPlan.isComplete &&
            !_dismissedPlans.contains(lastPlan.key)
        ? lastPlan
        : null;
    return Column(
      children: <Widget>[
        ListTile(
          title: Text(current.title),
          subtitle: Text(
            '${current.agentDefinitionId} · ${current.origin.name}',
          ),
          trailing: busy
              ? IconButton(
                  tooltip: AppLocalizations.of(context).commonStop,
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
          child: ChatTimelineView(items: items, busy: busy),
        ),
        if (pendingPlan != null)
          ChatPlanActions(
            selection: widget.selection,
            session: current,
            proposal: pendingPlan,
            onDismiss: () =>
                setState(() => _dismissedPlans.add(pendingPlan.key)),
            onSessionCreated: (session) =>
                _goSession(context, widget.selection, session.id),
          ),
        for (final approval
            in value?.approvals.values ?? const <ApprovalRequestDto>[])
          ApprovalCard(
            hostId: widget.selection.hostId,
            approval: approval,
          ),
        SessionComposer(
          enabled: !busy && effective != null,
          hint: effective == null
              ? AppLocalizations.of(context).composerSelectProviderFirst
              : null,
          bar: SessionComposerBar(
            hostId: widget.selection.hostId,
            definitions: definitions,
            agentDefinitionId: current.agentDefinitionId,
            selection: effective,
            mode: current.mode,
            onModeChanged: (mode) => unawaited(
              ref
                  .read(
                    sessionsControllerProvider(
                      widget.selection.hostId,
                      widget.selection.worktreeId,
                    ).notifier,
                  )
                  .setMode(current.id, mode),
            ),
            agentEnabled: false,
            enabled: !busy,
            onAgentChanged: (_) {},
            onModelChanged: (model) => unawaited(
              ref
                  .read(
                    sessionsControllerProvider(
                      widget.selection.hostId,
                      widget.selection.worktreeId,
                    ).notifier,
                  )
                  .setModel(current.id, model),
            ),
          ),
          onModeToggled: busy
              ? null
              : () => unawaited(
                  ref
                      .read(
                        sessionsControllerProvider(
                          widget.selection.hostId,
                          widget.selection.worktreeId,
                        ).notifier,
                      )
                      .setMode(
                        current.id,
                        current.mode == SessionMode.plan
                            ? SessionMode.normal
                            : SessionMode.plan,
                      ),
                ),
          onSubmit: (prompt) => unawaited(_send(current.id, prompt)),
        ),
      ],
    );
  }

  Future<void> _send(String sessionId, String prompt) async {
    await ref
        .read(
          conversationControllerProvider(
            widget.selection.hostId,
            sessionId,
          ).notifier,
        )
        .startTurn(prompt);
  }
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
