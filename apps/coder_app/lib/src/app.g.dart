// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [
  $hostRoute,
  $dashboardRoute,
  $settingsRoute,
  $workspaceRoute,
  $agentRoute,
];

RouteBase get $hostRoute => GoRouteData.$route(
  path: '/',
  hasOverriddenOnExit: false,
  factory: $HostRoute._fromState,
);

mixin $HostRoute on GoRouteData {
  static HostRoute _fromState(GoRouterState state) => const HostRoute();

  @override
  String get location => GoRouteData.$location('/');

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

RouteBase get $dashboardRoute => GoRouteData.$route(
  path: '/hosts/:hostId',
  hasOverriddenOnExit: false,
  factory: $DashboardRoute._fromState,
);

mixin $DashboardRoute on GoRouteData {
  static DashboardRoute _fromState(GoRouterState state) =>
      DashboardRoute(hostId: state.pathParameters['hostId']!);

  DashboardRoute get _self => this as DashboardRoute;

  @override
  String get location =>
      GoRouteData.$location('/hosts/${Uri.encodeComponent(_self.hostId)}');

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

RouteBase get $settingsRoute => GoRouteData.$route(
  path: '/hosts/:hostId/settings',
  hasOverriddenOnExit: false,
  factory: $SettingsRoute._fromState,
);

mixin $SettingsRoute on GoRouteData {
  static SettingsRoute _fromState(GoRouterState state) =>
      SettingsRoute(hostId: state.pathParameters['hostId']!);

  SettingsRoute get _self => this as SettingsRoute;

  @override
  String get location => GoRouteData.$location(
    '/hosts/${Uri.encodeComponent(_self.hostId)}/settings',
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

RouteBase get $workspaceRoute => GoRouteData.$route(
  path: '/hosts/:hostId/workspaces/:workspaceId',
  hasOverriddenOnExit: false,
  factory: $WorkspaceRoute._fromState,
);

mixin $WorkspaceRoute on GoRouteData {
  static WorkspaceRoute _fromState(GoRouterState state) => WorkspaceRoute(
    hostId: state.pathParameters['hostId']!,
    workspaceId: state.pathParameters['workspaceId']!,
  );

  WorkspaceRoute get _self => this as WorkspaceRoute;

  @override
  String get location => GoRouteData.$location(
    '/hosts/${Uri.encodeComponent(_self.hostId)}/workspaces/${Uri.encodeComponent(_self.workspaceId)}',
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

RouteBase get $agentRoute => GoRouteData.$route(
  path: '/hosts/:hostId/workspaces/:workspaceId/agents/:agentId',
  hasOverriddenOnExit: false,
  factory: $AgentRoute._fromState,
);

mixin $AgentRoute on GoRouteData {
  static AgentRoute _fromState(GoRouterState state) => AgentRoute(
    hostId: state.pathParameters['hostId']!,
    workspaceId: state.pathParameters['workspaceId']!,
    agentId: state.pathParameters['agentId']!,
  );

  AgentRoute get _self => this as AgentRoute;

  @override
  String get location => GoRouteData.$location(
    '/hosts/${Uri.encodeComponent(_self.hostId)}/workspaces/${Uri.encodeComponent(_self.workspaceId)}/agents/${Uri.encodeComponent(_self.agentId)}',
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
