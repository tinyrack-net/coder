// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_router.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [
  $settingsShellRoute,
  $workspaceShellRoute,
  $connectDaemonRoute,
  $pairingLinkRoute,
  $pairingScanRoute,
  $pairOfferRoute,
  $advancedNewHostRoute,
  $editHostRoute,
];

RouteBase get $settingsShellRoute => ShellRouteData.$route(
  navigatorKey: SettingsShellRoute.$navigatorKey,
  factory: $SettingsShellRouteExtension._fromState,
  routes: [
    GoRouteData.$route(
      path: '/settings',
      hasOverriddenOnExit: false,
      factory: $SettingsHomeRoute._fromState,
    ),
    GoRouteData.$route(
      path: '/settings/daemons/:hostId/categories',
      hasOverriddenOnExit: false,
      factory: $DaemonCategoriesRoute._fromState,
    ),
    GoRouteData.$route(
      path: '/settings/general',
      hasOverriddenOnExit: false,
      factory: $GeneralSettingsRoute._fromState,
    ),
    GoRouteData.$route(
      path: '/settings/providers',
      hasOverriddenOnExit: false,
      factory: $ProviderSettingsRoute._fromState,
    ),
    GoRouteData.$route(
      path: '/settings/models',
      hasOverriddenOnExit: false,
      factory: $ModelSettingsRoute._fromState,
    ),
    GoRouteData.$route(
      path: '/settings/permissions',
      hasOverriddenOnExit: false,
      factory: $PermissionSettingsRoute._fromState,
    ),
    GoRouteData.$route(
      path: '/settings/projects',
      hasOverriddenOnExit: false,
      factory: $ProjectSettingsRoute._fromState,
    ),
    GoRouteData.$route(
      path: '/settings/agents',
      hasOverriddenOnExit: false,
      factory: $AgentSettingsRoute._fromState,
    ),
    GoRouteData.$route(
      path: '/settings/plugins',
      hasOverriddenOnExit: false,
      factory: $PluginSettingsRoute._fromState,
    ),
    GoRouteData.$route(
      path: '/settings/mcp',
      hasOverriddenOnExit: false,
      factory: $McpSettingsRoute._fromState,
    ),
    GoRouteData.$route(
      path: '/settings/skills',
      hasOverriddenOnExit: false,
      factory: $SkillSettingsRoute._fromState,
    ),
    GoRouteData.$route(
      path: '/settings/daemons',
      hasOverriddenOnExit: false,
      factory: $DaemonSettingsRoute._fromState,
    ),
    GoRouteData.$route(
      path: '/settings/advanced',
      hasOverriddenOnExit: false,
      factory: $AdvancedSettingsRoute._fromState,
    ),
    GoRouteData.$route(
      path: '/settings/daemons/:hostId/connections',
      hasOverriddenOnExit: false,
      factory: $DaemonConnectionsRoute._fromState,
    ),
  ],
);

extension $SettingsShellRouteExtension on SettingsShellRoute {
  static SettingsShellRoute _fromState(GoRouterState state) =>
      const SettingsShellRoute();
}

mixin $SettingsHomeRoute on GoRouteData {
  static SettingsHomeRoute _fromState(GoRouterState state) =>
      const SettingsHomeRoute();

  @override
  String get location => GoRouteData.$location('/settings');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $DaemonCategoriesRoute on GoRouteData {
  static DaemonCategoriesRoute _fromState(GoRouterState state) =>
      DaemonCategoriesRoute(hostId: state.pathParameters['hostId']!);

  DaemonCategoriesRoute get _self => this as DaemonCategoriesRoute;

  @override
  String get location => GoRouteData.$location(
    '/settings/daemons/${Uri.encodeComponent(_self.hostId)}/categories',
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $GeneralSettingsRoute on GoRouteData {
  static GeneralSettingsRoute _fromState(GoRouterState state) =>
      const GeneralSettingsRoute();

  @override
  String get location => GoRouteData.$location('/settings/general');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $ProviderSettingsRoute on GoRouteData {
  static ProviderSettingsRoute _fromState(GoRouterState state) =>
      ProviderSettingsRoute(hostId: state.uri.queryParameters['host-id']);

  ProviderSettingsRoute get _self => this as ProviderSettingsRoute;

  @override
  String get location => GoRouteData.$location(
    '/settings/providers',
    queryParams: {if (_self.hostId != null) 'host-id': _self.hostId},
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $ModelSettingsRoute on GoRouteData {
  static ModelSettingsRoute _fromState(GoRouterState state) =>
      ModelSettingsRoute(hostId: state.uri.queryParameters['host-id']);

  ModelSettingsRoute get _self => this as ModelSettingsRoute;

  @override
  String get location => GoRouteData.$location(
    '/settings/models',
    queryParams: {if (_self.hostId != null) 'host-id': _self.hostId},
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $PermissionSettingsRoute on GoRouteData {
  static PermissionSettingsRoute _fromState(GoRouterState state) =>
      PermissionSettingsRoute(hostId: state.uri.queryParameters['host-id']);

  PermissionSettingsRoute get _self => this as PermissionSettingsRoute;

  @override
  String get location => GoRouteData.$location(
    '/settings/permissions',
    queryParams: {if (_self.hostId != null) 'host-id': _self.hostId},
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $ProjectSettingsRoute on GoRouteData {
  static ProjectSettingsRoute _fromState(GoRouterState state) =>
      ProjectSettingsRoute(hostId: state.uri.queryParameters['host-id']);

  ProjectSettingsRoute get _self => this as ProjectSettingsRoute;

  @override
  String get location => GoRouteData.$location(
    '/settings/projects',
    queryParams: {if (_self.hostId != null) 'host-id': _self.hostId},
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $AgentSettingsRoute on GoRouteData {
  static AgentSettingsRoute _fromState(GoRouterState state) =>
      AgentSettingsRoute(hostId: state.uri.queryParameters['host-id']);

  AgentSettingsRoute get _self => this as AgentSettingsRoute;

  @override
  String get location => GoRouteData.$location(
    '/settings/agents',
    queryParams: {if (_self.hostId != null) 'host-id': _self.hostId},
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $PluginSettingsRoute on GoRouteData {
  static PluginSettingsRoute _fromState(GoRouterState state) =>
      PluginSettingsRoute(hostId: state.uri.queryParameters['host-id']);

  PluginSettingsRoute get _self => this as PluginSettingsRoute;

  @override
  String get location => GoRouteData.$location(
    '/settings/plugins',
    queryParams: {if (_self.hostId != null) 'host-id': _self.hostId},
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $McpSettingsRoute on GoRouteData {
  static McpSettingsRoute _fromState(GoRouterState state) =>
      McpSettingsRoute(hostId: state.uri.queryParameters['host-id']);

  McpSettingsRoute get _self => this as McpSettingsRoute;

  @override
  String get location => GoRouteData.$location(
    '/settings/mcp',
    queryParams: {if (_self.hostId != null) 'host-id': _self.hostId},
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $SkillSettingsRoute on GoRouteData {
  static SkillSettingsRoute _fromState(GoRouterState state) =>
      SkillSettingsRoute(
        hostId: state.uri.queryParameters['host-id'],
        workspaceId: state.uri.queryParameters['workspace-id'],
      );

  SkillSettingsRoute get _self => this as SkillSettingsRoute;

  @override
  String get location => GoRouteData.$location(
    '/settings/skills',
    queryParams: {
      if (_self.hostId != null) 'host-id': _self.hostId,
      if (_self.workspaceId != null) 'workspace-id': _self.workspaceId,
    },
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $DaemonSettingsRoute on GoRouteData {
  static DaemonSettingsRoute _fromState(GoRouterState state) =>
      const DaemonSettingsRoute();

  @override
  String get location => GoRouteData.$location('/settings/daemons');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $AdvancedSettingsRoute on GoRouteData {
  static AdvancedSettingsRoute _fromState(GoRouterState state) =>
      const AdvancedSettingsRoute();

  @override
  String get location => GoRouteData.$location('/settings/advanced');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $DaemonConnectionsRoute on GoRouteData {
  static DaemonConnectionsRoute _fromState(GoRouterState state) =>
      DaemonConnectionsRoute(hostId: state.pathParameters['hostId']!);

  DaemonConnectionsRoute get _self => this as DaemonConnectionsRoute;

  @override
  String get location => GoRouteData.$location(
    '/settings/daemons/${Uri.encodeComponent(_self.hostId)}/connections',
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $workspaceShellRoute => ShellRouteData.$route(
  navigatorKey: WorkspaceShellRoute.$navigatorKey,
  factory: $WorkspaceShellRouteExtension._fromState,
  routes: [
    GoRouteData.$route(
      path: '/',
      hasOverriddenOnExit: false,
      factory: $WorkspaceHomeRoute._fromState,
      routes: [
        GoRouteData.$route(
          path: 'workspaces/:hostId/:workspaceId/:worktreeId',
          hasOverriddenOnExit: false,
          factory: $WorktreeRoute._fromState,
        ),
        GoRouteData.$route(
          path:
              'workspaces/:hostId/:workspaceId/:worktreeId/sessions/:sessionId',
          hasOverriddenOnExit: false,
          factory: $SessionRoute._fromState,
        ),
        GoRouteData.$route(
          path: 'workspaces/:hostId/:workspaceId/:worktreeId/terminals/:terminalId',
          hasOverriddenOnExit: false,
          factory: $TerminalRoute._fromState,
        ),
      ],
    ),
  ],
);

extension $WorkspaceShellRouteExtension on WorkspaceShellRoute {
  static WorkspaceShellRoute _fromState(GoRouterState state) =>
      const WorkspaceShellRoute();
}

mixin $WorkspaceHomeRoute on GoRouteData {
  static WorkspaceHomeRoute _fromState(GoRouterState state) =>
      WorkspaceHomeRoute(
        compose:
            _$convertMapValue(
              'compose',
              state.uri.queryParameters,
              _$boolConverter,
            ) ??
            false,
      );

  WorkspaceHomeRoute get _self => this as WorkspaceHomeRoute;

  @override
  String get location => GoRouteData.$location(
    '/',
    queryParams: {
      if (_self.compose != false) 'compose': _self.compose.toString(),
    },
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $WorktreeRoute on GoRouteData {
  static WorktreeRoute _fromState(GoRouterState state) => WorktreeRoute(
    hostId: state.pathParameters['hostId']!,
    workspaceId: state.pathParameters['workspaceId']!,
    worktreeId: state.pathParameters['worktreeId']!,
  );

  WorktreeRoute get _self => this as WorktreeRoute;

  @override
  String get location => GoRouteData.$location(
    '/workspaces/${Uri.encodeComponent(_self.hostId)}/${Uri.encodeComponent(_self.workspaceId)}/${Uri.encodeComponent(_self.worktreeId)}',
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $SessionRoute on GoRouteData {
  static SessionRoute _fromState(GoRouterState state) => SessionRoute(
    hostId: state.pathParameters['hostId']!,
    workspaceId: state.pathParameters['workspaceId']!,
    worktreeId: state.pathParameters['worktreeId']!,
    sessionId: state.pathParameters['sessionId']!,
  );

  SessionRoute get _self => this as SessionRoute;

  @override
  String get location => GoRouteData.$location(
    '/workspaces/${Uri.encodeComponent(_self.hostId)}/${Uri.encodeComponent(_self.workspaceId)}/${Uri.encodeComponent(_self.worktreeId)}/sessions/${Uri.encodeComponent(_self.sessionId)}',
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $TerminalRoute on GoRouteData {
  static TerminalRoute _fromState(GoRouterState state) => TerminalRoute(
    hostId: state.pathParameters['hostId']!,
    workspaceId: state.pathParameters['workspaceId']!,
    worktreeId: state.pathParameters['worktreeId']!,
    terminalId: state.pathParameters['terminalId']!,
  );

  TerminalRoute get _self => this as TerminalRoute;

  @override
  String get location => GoRouteData.$location(
    '/workspaces/${Uri.encodeComponent(_self.hostId)}/${Uri.encodeComponent(_self.workspaceId)}/${Uri.encodeComponent(_self.worktreeId)}/terminals/${Uri.encodeComponent(_self.terminalId)}',
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

T? _$convertMapValue<T>(
  String key,
  Map<String, String> map,
  T? Function(String) converter,
) {
  final value = map[key];
  return value == null ? null : converter(value);
}

bool _$boolConverter(String value) {
  switch (value) {
    case 'true':
      return true;
    case 'false':
      return false;
    default:
      throw UnsupportedError('Cannot convert "$value" into a bool.');
  }
}

RouteBase get $connectDaemonRoute => GoRouteData.$route(
  path: '/connect',
  hasOverriddenOnExit: false,
  factory: $ConnectDaemonRoute._fromState,
);

mixin $ConnectDaemonRoute on GoRouteData {
  static ConnectDaemonRoute _fromState(GoRouterState state) =>
      const ConnectDaemonRoute();

  @override
  String get location => GoRouteData.$location('/connect');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $pairingLinkRoute => GoRouteData.$route(
  path: '/connect/link',
  hasOverriddenOnExit: false,
  factory: $PairingLinkRoute._fromState,
);

mixin $PairingLinkRoute on GoRouteData {
  static PairingLinkRoute _fromState(GoRouterState state) =>
      const PairingLinkRoute();

  @override
  String get location => GoRouteData.$location('/connect/link');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $pairingScanRoute => GoRouteData.$route(
  path: '/connect/scan',
  hasOverriddenOnExit: false,
  factory: $PairingScanRoute._fromState,
);

mixin $PairingScanRoute on GoRouteData {
  static PairingScanRoute _fromState(GoRouterState state) =>
      const PairingScanRoute();

  @override
  String get location => GoRouteData.$location('/connect/scan');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $pairOfferRoute => GoRouteData.$route(
  path: '/pair',
  hasOverriddenOnExit: false,
  factory: $PairOfferRoute._fromState,
);

mixin $PairOfferRoute on GoRouteData {
  static PairOfferRoute _fromState(GoRouterState state) =>
      const PairOfferRoute();

  @override
  String get location => GoRouteData.$location('/pair');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $advancedNewHostRoute => GoRouteData.$route(
  path: '/connect/direct',
  hasOverriddenOnExit: false,
  factory: $AdvancedNewHostRoute._fromState,
);

mixin $AdvancedNewHostRoute on GoRouteData {
  static AdvancedNewHostRoute _fromState(GoRouterState state) =>
      const AdvancedNewHostRoute();

  @override
  String get location => GoRouteData.$location('/connect/direct');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $editHostRoute => GoRouteData.$route(
  path: '/settings/daemons/:hostId',
  hasOverriddenOnExit: false,
  factory: $EditHostRoute._fromState,
);

mixin $EditHostRoute on GoRouteData {
  static EditHostRoute _fromState(GoRouterState state) =>
      EditHostRoute(hostId: state.pathParameters['hostId']!);

  EditHostRoute get _self => this as EditHostRoute;

  @override
  String get location => GoRouteData.$location(
    '/settings/daemons/${Uri.encodeComponent(_self.hostId)}',
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}
