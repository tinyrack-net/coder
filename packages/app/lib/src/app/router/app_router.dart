import 'dart:async';

import 'package:app/src/app/presentation/settings_page.dart';
import 'package:app/src/app/presentation/workspace_page.dart';
import 'package:app/src/features/hosts/domain/host_models.dart';
import 'package:app/src/features/hosts/presentation/pages/host_settings_page.dart';
import 'package:app/src/features/hosts/presentation/pages/relay_pairing_pages.dart';
import 'package:app/src/features/settings/domain/settings_category.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

part 'app_router.g.dart';

// The app moves in three different ways and each needs its own router verb.
//
// A modal task such as settings or daemon editing is pushed, so closing it can
// pop back to whatever the user was doing and the exit transition is the
// entry transition played in reverse. A lateral move inside one surface —
// settings categories, workspace and session selection — uses `replace`, which
// keeps the page key so no transition plays at all and the push depth beneath
// it survives. `go` is reserved for entering a root destination or for
// deliberately clearing the stack.

/// Whether [uri] addresses any settings surface.
bool _isSettingsLocation(Uri uri) => uri.path.startsWith('/settings');

/// Page identity shared by every route that paints the workspace shell.
///
/// go_router keys a page by the matched path pattern, so the home, checkout,
/// session, and terminal routes would each own a separate Navigator page even
/// though they build one screen. Naming the page keeps a single page across
/// those lateral moves, so the sidebar's tree expansion, its scroll offset,
/// and the page state behind them survive switching between tab kinds.
NoTransitionPage<void> _workspaceShellPage(Widget child) =>
    NoTransitionPage<void>(
      key: const ValueKey<String>('workspace-shell'),
      name: 'workspace-shell',
      restorationId: 'workspace-shell',
      child: child,
    );

/// Closes a pushed task and returns to the screen it was opened from.
///
/// A task can also be entered directly, by deep link or by a tray activation
/// into a hidden window, and then has nothing beneath it to return to.
/// [fallback] names the destination for that case.
void closeTask(BuildContext context, VoidCallback fallback) {
  if (context.canPop()) {
    context.pop();
    return;
  }
  fallback();
}

/// Opens settings from outside the widget tree, such as the tray or menu bar.
///
/// Those entry points can fire repeatedly while settings is already open, and
/// stacking a second copy would make the first Back press look like it did
/// nothing, so an open settings task is replaced instead of pushed.
void openSettingsTask(GoRouter router) {
  const target = SettingsHomeRoute();
  // `state` is the top-most match; the route information provider only reports
  // the base configuration, which a pushed task never moves.
  if (_isSettingsLocation(router.state.uri)) {
    unawaited(router.replace<void>(target.location));
    return;
  }
  unawaited(router.push<void>(target.location));
}

@TypedGoRoute<SettingsHomeRoute>(path: '/settings')
/// Responsive settings entry: navigation home on compact widths, General on
/// wider layouts.
class SettingsHomeRoute extends GoRouteData with $SettingsHomeRoute {
  /// Creates the settings entry route.
  const SettingsHomeRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const UnifiedSettingsPage();
}

@TypedGoRoute<DaemonCategoriesRoute>(
  path: '/settings/daemons/:hostId/categories',
)
/// Compact daemon category pane, with Provider selected on wider layouts.
class DaemonCategoriesRoute extends GoRouteData with $DaemonCategoriesRoute {
  /// Creates a daemon category route.
  const DaemonCategoriesRoute({required this.hostId});

  /// App-local daemon profile identifier.
  final String hostId;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      UnifiedSettingsPage(hostId: hostId);
}

@TypedGoRoute<WorkspaceHomeRoute>(path: '/')
/// Unified workspace home shown before daemon connections complete.
class WorkspaceHomeRoute extends GoRouteData with $WorkspaceHomeRoute {
  /// Creates the workspace home route.
  const WorkspaceHomeRoute({this.compose = false});

  /// Whether the right pane opens the new-workspace composer directly.
  final bool compose;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      _workspaceShellPage(WorkspacePage(compose: compose));
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
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      _workspaceShellPage(
        WorkspacePage(
          selection: WorkspaceSelection(
            hostId: hostId,
            workspaceId: workspaceId,
            worktreeId: worktreeId,
          ),
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
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      _workspaceShellPage(
        WorkspacePage(
          selection: WorkspaceSelection(
            hostId: hostId,
            workspaceId: workspaceId,
            worktreeId: worktreeId,
          ),
          requestedAgentId: sessionId,
        ),
      );
}

@TypedGoRoute<TerminalRoute>(
  path: '/workspaces/:hostId/:workspaceId/:worktreeId/terminals/:terminalId',
)
/// Opens one daemon terminal in the checkout tab strip.
class TerminalRoute extends GoRouteData with $TerminalRoute {
  /// Creates a terminal route.
  const TerminalRoute({
    required this.hostId,
    required this.workspaceId,
    required this.worktreeId,
    required this.terminalId,
  });

  /// App-local daemon ID.
  final String hostId;

  /// Daemon-local repository ID.
  final String workspaceId;

  /// Daemon-local checkout ID.
  final String worktreeId;

  /// Daemon-local terminal ID.
  final String terminalId;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      _workspaceShellPage(
        WorkspacePage(
          selection: WorkspaceSelection(
            hostId: hostId,
            workspaceId: workspaceId,
            worktreeId: worktreeId,
          ),
          requestedTerminalId: terminalId,
        ),
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

@TypedGoRoute<PermissionSettingsRoute>(path: '/settings/permissions')
/// Unified settings route with Permissions selected.
class PermissionSettingsRoute extends GoRouteData
    with $PermissionSettingsRoute {
  /// Creates the permission settings route.
  const PermissionSettingsRoute({this.hostId});

  /// Preferred daemon in the permission selector.
  final String? hostId;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      UnifiedSettingsPage(
        category: SettingsCategory.permission,
        hostId: hostId,
      );
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

@TypedGoRoute<McpSettingsRoute>(path: '/settings/mcp')
/// Unified settings route with MCP selected.
class McpSettingsRoute extends GoRouteData with $McpSettingsRoute {
  /// Creates the MCP settings route.
  const McpSettingsRoute({this.hostId});

  /// Preferred daemon in the MCP selector.
  final String? hostId;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      UnifiedSettingsPage(category: SettingsCategory.mcp, hostId: hostId);
}

@TypedGoRoute<SkillSettingsRoute>(path: '/settings/skills')
/// Unified settings route with Skill selected.
class SkillSettingsRoute extends GoRouteData with $SkillSettingsRoute {
  /// Creates the skill settings route.
  const SkillSettingsRoute({this.hostId, this.workspaceId});

  /// Preferred daemon in the skill selector.
  final String? hostId;

  /// Project whose skills layer on top of the global sources.
  final String? workspaceId;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      UnifiedSettingsPage(
        category: SettingsCategory.skill,
        hostId: hostId,
        workspaceId: workspaceId,
      );
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

@TypedGoRoute<AdvancedSettingsRoute>(path: '/settings/advanced')
/// Unified settings route with Advanced selected.
class AdvancedSettingsRoute extends GoRouteData with $AdvancedSettingsRoute {
  /// Creates the advanced settings route.
  const AdvancedSettingsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const UnifiedSettingsPage(category: SettingsCategory.advanced);
}

@TypedGoRoute<NewHostRoute>(path: '/settings/daemons/new')
/// Pairs a remote daemon through its one-time relay link.
class NewHostRoute extends GoRouteData with $NewHostRoute {
  /// Creates the route.
  const NewHostRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const RemoteHostPairPage();
}

@TypedGoRoute<AdvancedNewHostRoute>(path: '/settings/daemons/new/direct')
/// Adds a direct WebSocket connection for advanced users.
class AdvancedNewHostRoute extends GoRouteData with $AdvancedNewHostRoute {
  /// Creates the route.
  const AdvancedNewHostRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const RemoteHostEditPage();
}

@TypedGoRoute<DaemonDevicesRoute>(path: '/settings/daemons/:hostId/devices')
/// Creates pairing links and manages devices approved by one daemon.
class DaemonDevicesRoute extends GoRouteData with $DaemonDevicesRoute {
  /// Creates the route.
  const DaemonDevicesRoute({required this.hostId});

  /// App-local daemon profile identifier.
  final String hostId;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      DaemonDevicesPage(hostId: hostId);
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
