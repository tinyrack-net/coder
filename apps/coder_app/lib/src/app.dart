import 'dart:async';
import 'dart:typed_data';

import 'package:coder_app/l10n/gen/app_localizations.dart';
import 'package:coder_app/src/agent_settings_page.dart';
import 'package:coder_app/src/app_services.dart';
import 'package:coder_app/src/app_settings_page.dart';
import 'package:coder_app/src/attachment_io.dart';
import 'package:coder_app/src/chat/chat_approval_card.dart';
import 'package:coder_app/src/chat/chat_plan_actions.dart';
import 'package:coder_app/src/chat/chat_timeline_model.dart';
import 'package:coder_app/src/chat/chat_timeline_view.dart';
import 'package:coder_app/src/coder_icons.dart';
import 'package:coder_app/src/coder_list_row.dart';
import 'package:coder_app/src/coder_page_shell.dart';
import 'package:coder_app/src/controller.dart';
import 'package:coder_app/src/desktop_shell.dart';
import 'package:coder_app/src/desktop_shell_scope.dart';
import 'package:coder_app/src/external_url_opener.dart';
import 'package:coder_app/src/general_settings_page.dart';
import 'package:coder_app/src/host_labels.dart';
import 'package:coder_app/src/host_models.dart';
import 'package:coder_app/src/mcp_settings_page.dart';
import 'package:coder_app/src/project_settings_page.dart';
import 'package:coder_app/src/session_composer.dart';
import 'package:coder_app/src/session_model_options.dart';
import 'package:coder_app/src/settings_page.dart';
import 'package:coder_app/src/skill_settings_page.dart';
import 'package:coder_app/src/workspace/new_workspace_pane.dart';
import 'package:coder_app/src/workspace/workspace_sidebar.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

part 'app.g.dart';

/// Tinyrack Coder application composition.
class CoderApp extends StatelessWidget {
  /// Creates the application.
  CoderApp({
    required this.services,
    this.attachmentInput,
    this.externalUrlOpener = const PlatformExternalUrlOpener(),
    this.desktopWindow,
    this.trayIcon,
    this.autostart,
    this.startHidden = false,
    super.key,
  });

  /// Platform services used by feature controllers.
  final AppServices services;

  /// Platform file picker, clipboard, and desktop drop adapter.
  final AttachmentInputPort? attachmentInput;

  /// Opens interactive provider authorization pages.
  final ExternalUrlOpener externalUrlOpener;

  /// Desktop window control, or null on platforms without a window to manage.
  final DesktopWindow? desktopWindow;

  /// Tray icon owner, or null on platforms without a tray.
  final TrayIcon? trayIcon;

  /// Login-item registration, or null where the app cannot register one.
  final AutostartRegistration? autostart;

  /// Whether this launch started without showing a window.
  final bool startHidden;

  late final GoRouter _router = GoRouter(routes: $appRoutes);

  @override
  Widget build(BuildContext context) => ProviderScope(
    overrides: [
      appServicesProvider.overrideWithValue(services),
      attachmentInputProvider.overrideWithValue(attachmentInput),
      externalUrlOpenerProvider.overrideWithValue(externalUrlOpener),
      desktopWindowProvider.overrideWithValue(desktopWindow),
      trayIconProvider.overrideWithValue(trayIcon),
      autostartProvider.overrideWithValue(autostart),
    ],
    child: _CoderAppView(
      router: _router,
      resident: desktopWindow != null || trayIcon != null,
      startHidden: startHidden,
    ),
  );
}

/// Builds the app shell below [ProviderScope] so it can watch settings.
class _CoderAppView extends ConsumerWidget {
  const _CoderAppView({
    required this.router,
    required this.resident,
    required this.startHidden,
  });

  final GoRouter router;

  /// Whether this build owns a tray and can survive a closed window.
  final bool resident;

  /// Whether this launch started without showing a window.
  final bool startHidden;

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
      // The shell sits below Localizations and the router so tray labels
      // follow the selected language and a tray row can navigate.
      builder: (context, child) => TRTooltipProvider(
        child: !resident
            ? child ?? const SizedBox.shrink()
            : DesktopShellScope(
                router: router,
                startHidden: startHidden,
                child: child ?? const SizedBox.shrink(),
              ),
      ),
    );
  }
}

/// Width at which the workspace and settings shells show both panes.
const double wideLayoutBreakpoint = 760;

/// Width of the settings navigation pane.
const double settingsSidebarWidth = 230;

/// Builds the shared Material theme for one brightness.
ThemeData coderTheme(Brightness brightness) => brightness == Brightness.light
    ? TinyrackTheme.light()
    : TinyrackTheme.dark();

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

  /// External MCP servers owned by one daemon.
  mcp,

  /// Skills merged from built-in, user, config, and project sources.
  skill,

  /// API provider connections owned by one daemon.
  provider,

  /// Embedded and remote daemon connections.
  daemon,
}

/// Whether a settings category belongs to the app or to one daemon.
enum SettingsCategoryScope {
  /// Applies to the whole app regardless of which daemon is active.
  app,

  /// Reads and writes state owned by the selected daemon.
  daemon,
}

/// Groups settings categories into the sidebar sections that carry them.
extension SettingsCategoryScopeX on SettingsCategory {
  /// The sidebar section this category belongs to.
  ///
  /// Daemon connection management is app-wide even though it is about
  /// daemons, so it sits with General rather than under the daemon picker.
  SettingsCategoryScope get scope => switch (this) {
    SettingsCategory.general ||
    SettingsCategory.daemon => SettingsCategoryScope.app,
    SettingsCategory.project ||
    SettingsCategory.agent ||
    SettingsCategory.mcp ||
    SettingsCategory.skill ||
    SettingsCategory.provider => SettingsCategoryScope.daemon,
  };
}

/// The categories carried by one sidebar section, in display order.
List<SettingsCategory> _categoriesInScope(SettingsCategoryScope scope) =>
    SettingsCategory.values
        .where((category) => category.scope == scope)
        .toList(growable: false);

/// Shared two-pane settings shell.
class UnifiedSettingsPage extends ConsumerStatefulWidget {
  /// Creates a unified settings page.
  const UnifiedSettingsPage({
    required this.category,
    this.hostId,
    this.workspaceId,
    super.key,
  });

  /// Selected settings category.
  final SettingsCategory category;

  /// Preferred provider daemon.
  final String? hostId;

  /// Project selected on the skill page.
  final String? workspaceId;

  @override
  ConsumerState<UnifiedSettingsPage> createState() =>
      _UnifiedSettingsPageState();
}

class _UnifiedSettingsPageState extends ConsumerState<UnifiedSettingsPage> {
  bool _adoptedRouteHost = false;

  @override
  void initState() {
    super.initState();
    // A deep link naming a daemon wins once, then the persisted selection
    // takes over so switching categories never resets it.
    WidgetsBinding.instance.addPostFrameCallback((_) => _adoptRouteHost());
  }

  void _adoptRouteHost() {
    if (!mounted || _adoptedRouteHost) return;
    final requested = widget.hostId;
    if (requested == null) return;
    final registry = ref.read(hostRegistryControllerProvider).asData?.value;
    if (registry == null) return;
    _adoptedRouteHost = true;
    if (!registry.runtimes.containsKey(requested)) return;
    if (registry.settings.lastActiveHostId == requested) return;
    unawaited(
      ref.read(hostRegistryControllerProvider.notifier).selectHost(requested),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_adoptedRouteHost) _adoptRouteHost();
    final registry = ref.watch(hostRegistryControllerProvider).asData?.value;
    final hosts =
        registry?.runtimes.values.toList(growable: false) ??
        const <HostRuntimeSnapshot>[];
    final hostId = ref.watch(activeHostIdProvider);
    final host = hostId == null ? null : registry?.runtimes[hostId];
    final detail = switch (widget.category) {
      SettingsCategory.general => const GeneralSettingsPage(embedded: true),
      SettingsCategory.project => _HostScopedDetail(
        host: host,
        builder: (hostId) => ProjectSettingsPage(hostId: hostId),
      ),
      SettingsCategory.agent => _HostScopedDetail(
        host: host,
        builder: (hostId) => AgentSettingsPage(hostId: hostId),
      ),
      SettingsCategory.mcp => _HostScopedDetail(
        host: host,
        builder: (hostId) => McpSettingsPage(hostId: hostId),
      ),
      SettingsCategory.skill => _HostScopedDetail(
        host: host,
        builder: (hostId) => SkillSettingsPage(
          hostId: hostId,
          workspaceId: widget.workspaceId,
          onWorkspaceChanged: (value) =>
              SkillSettingsRoute(workspaceId: value).go(context),
        ),
      ),
      SettingsCategory.provider => _HostScopedDetail(
        host: host,
        builder: (hostId) => SettingsPage(hostId: hostId, embedded: true),
      ),
      SettingsCategory.daemon => const AppSettingsPage(embedded: true),
    };
    return CoderPageShell(
      appBar: CoderPageHeader(
        leading: TRIconButton(
          appearance: TRAppearance.ghost,
          uiSize: TRUiSize.sm,
          label: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => const WorkspaceHomeRoute().go(context),
          icon: const Icon(CoderIcons.back),
        ),
        title: Text(AppLocalizations.of(context).settingsTitle),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < wideLayoutBreakpoint) {
            final l10n = AppLocalizations.of(context);
            return Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    TRSpacing.large,
                    TRSpacing.medium,
                    TRSpacing.large,
                    TRSpacing.extraSmall,
                  ),
                  child: TRSelectFormField<SettingsCategory>(
                    key: const ValueKey<String>('settings-category-select'),
                    initialValue: widget.category,
                    label: l10n.settingsTitle,
                    uiSize: TRUiSize.sm,
                    items: <TRSelectItem<SettingsCategory>>[
                      for (final category in SettingsCategory.values)
                        TRSelectItem<SettingsCategory>(
                          value: category,
                          label: _settingsCategoryLabel(l10n, category),
                        ),
                    ],
                    onValueChange: (category) {
                      if (category == null) return;
                      _goToSettingsCategory(context, category);
                    },
                  ),
                ),
                if (widget.category.scope == SettingsCategoryScope.daemon)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      TRSpacing.large,
                      TRSpacing.extraSmall,
                      TRSpacing.large,
                      TRSpacing.extraSmall,
                    ),
                    child: _DaemonSelect(
                      hosts: hosts,
                      hostId: hostId,
                      showLabel: true,
                    ),
                  ),
                Expanded(child: detail),
              ],
            );
          }
          return Row(
            children: <Widget>[
              SizedBox(
                width: settingsSidebarWidth,
                child: TRAppShellSidebar(
                  key: const ValueKey<String>('settings-sidebar-surface'),
                  scroll: false,
                  child: _SettingsSidebar(
                    selected: widget.category,
                    hosts: hosts,
                    hostId: hostId,
                  ),
                ),
              ),
              Expanded(child: detail),
            ],
          );
        },
      ),
    );
  }
}

class _SettingsSidebar extends StatelessWidget {
  const _SettingsSidebar({
    required this.selected,
    required this.hosts,
    required this.hostId,
  });

  final SettingsCategory selected;
  final List<HostRuntimeSnapshot> hosts;
  final String? hostId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(TRSpacing.medium),
      children: <Widget>[
        _SettingsSectionLabel(text: l10n.settingsSectionApp),
        _scopeNav(context, l10n, SettingsCategoryScope.app),
        const SizedBox(height: TRSpacing.large),
        _SettingsSectionLabel(text: l10n.settingsSectionDaemon),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: TRSpacing.extraSmall,
            vertical: TRSpacing.extraSmall,
          ),
          child: _DaemonSelect(hosts: hosts, hostId: hostId),
        ),
        _scopeNav(context, l10n, SettingsCategoryScope.daemon),
      ],
    );
  }

  /// One nav per section, since [TRTreeNav] has no non-selectable header item.
  ///
  /// Only the nav owning the selected category carries a value, so exactly
  /// one row stays highlighted across both sections.
  Widget _scopeNav(
    BuildContext context,
    AppLocalizations l10n,
    SettingsCategoryScope scope,
  ) {
    final storageId = 'settings-sidebar-tree-${scope.name}';
    return TRTreeNav<SettingsCategory>.controlled(
      key: ValueKey<String>(storageId),
      pageStorageId: storageId,
      semanticLabel: scope == SettingsCategoryScope.app
          ? l10n.settingsSectionApp
          : l10n.settingsSectionDaemon,
      value: selected.scope == scope ? selected : null,
      items: <TRTreeNavItem<SettingsCategory>>[
        for (final category in _categoriesInScope(scope))
          TRTreeNavLeaf<SettingsCategory>(
            value: category,
            leading: Icon(_settingsCategoryIcon(category)),
            label: Text(_settingsCategoryLabel(l10n, category)),
          ),
      ],
      onValueChange: (category) {
        if (category == null) return;
        _goToSettingsCategory(context, category);
      },
    );
  }
}

class _SettingsSectionLabel extends StatelessWidget {
  const _SettingsSectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      TRSpacing.small,
      TRSpacing.small,
      TRSpacing.small,
      TRSpacing.extraSmall,
    ),
    child: Text(
      text,
      style: TRTypography.label.copyWith(
        color: context.tinyrackTheme.textMuted,
      ),
    ),
  );
}

/// Picks the daemon that every host-scoped settings page edits.
///
/// Offline daemons stay listed so their settings can be reached as soon as
/// they reconnect, and so a saved selection does not silently jump elsewhere.
class _DaemonSelect extends ConsumerWidget {
  const _DaemonSelect({
    required this.hosts,
    required this.hostId,
    this.showLabel = false,
  });

  final List<HostRuntimeSnapshot> hosts;
  final String? hostId;

  /// Whether to draw the field label, for layouts without a section heading.
  final bool showLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    // Where a section heading already names this control the field label is
    // dropped, so the screen-reader name is carried here instead.
    // The pane is narrower than a daemon label, so the trigger takes the
    // full width and lets the label ellipsize instead of overflowing.
    return Semantics(
      label: showLabel ? null : l10n.settingsDaemonSelectLabel,
      container: !showLabel,
      child: LayoutBuilder(
        builder: (context, constraints) => TRSelect<String>.controlled(
          key: const ValueKey<String>('settings-daemon-select'),
          value: hostId,
          label: showLabel ? l10n.settingsDaemonSelectLabel : null,
          placeholder: l10n.settingsDaemonSelectEmpty,
          uiSize: TRUiSize.sm,
          enabled: hosts.isNotEmpty,
          width: constraints.maxWidth,
          items: hosts
              .map(
                (host) => TRSelectItem<String>(
                  value: host.id,
                  label: hostLabel(l10n, host),
                  leading: Icon(hostStatusIcon(host.status)),
                ),
              )
              .toList(growable: false),
          onValueChange: (value) {
            if (value == null) return;
            unawaited(
              ref
                  .read(hostRegistryControllerProvider.notifier)
                  .selectHost(value),
            );
          },
        ),
      ),
    );
  }
}

IconData _settingsCategoryIcon(SettingsCategory category) => switch (category) {
  SettingsCategory.general => CoderIcons.tune,
  SettingsCategory.project => CoderIcons.projects,
  SettingsCategory.agent => CoderIcons.agent,
  SettingsCategory.mcp => CoderIcons.extension,
  SettingsCategory.skill => CoderIcons.sparkle,
  SettingsCategory.provider => CoderIcons.network,
  SettingsCategory.daemon => CoderIcons.daemon,
};

String _settingsCategoryLabel(
  AppLocalizations l10n,
  SettingsCategory category,
) => switch (category) {
  SettingsCategory.general => l10n.settingsCategoryGeneral,
  SettingsCategory.project => l10n.settingsCategoryProjects,
  SettingsCategory.agent => l10n.settingsCategoryAgent,
  SettingsCategory.mcp => l10n.settingsCategoryMcp,
  SettingsCategory.skill => l10n.settingsCategorySkill,
  SettingsCategory.provider => l10n.settingsCategoryProvider,
  SettingsCategory.daemon => l10n.settingsCategoryDaemon,
};

/// Navigates to one settings category, keeping the persisted daemon choice.
void _goToSettingsCategory(BuildContext context, SettingsCategory category) {
  switch (category) {
    case SettingsCategory.general:
      const GeneralSettingsRoute().go(context);
    case SettingsCategory.project:
      const ProjectSettingsRoute().go(context);
    case SettingsCategory.agent:
      const AgentSettingsRoute().go(context);
    case SettingsCategory.mcp:
      const McpSettingsRoute().go(context);
    case SettingsCategory.skill:
      const SkillSettingsRoute().go(context);
    case SettingsCategory.provider:
      const ProviderSettingsRoute().go(context);
    case SettingsCategory.daemon:
      const DaemonSettingsRoute().go(context);
  }
}

/// Guards a host-scoped settings page behind a usable daemon connection.
///
/// The daemon itself is chosen in the sidebar, so this only explains why a
/// page cannot render yet.
class _HostScopedDetail extends StatelessWidget {
  const _HostScopedDetail({required this.host, required this.builder});

  final HostRuntimeSnapshot? host;
  final Widget Function(String hostId) builder;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final host = this.host;
    if (host == null) {
      return Center(child: Text(l10n.settingsRequiresOnlineDaemon));
    }
    if (!host.connected) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(TRSpacing.extraLarge),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: TRMeasurements.measureMd,
            ),
            child: TRAlert(
              key: const ValueKey<String>('settings-daemon-offline'),
              variant: TRStatusVariant.warning,
              icon: Icon(hostStatusIcon(host.status)),
              title: Text(l10n.settingsDaemonOffline(hostLabel(l10n, host))),
              description: Text(hostStatusText(l10n, host)),
            ),
          ),
        ),
      );
    }
    return builder(host.id);
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
    return CoderPageShell(
      appBar: CoderPageHeader(
        // The toggle keeps one position in both states: the very top left.
        leading: MediaQuery.sizeOf(context).width < wideLayoutBreakpoint
            ? null
            : TRIconButton(
                appearance: TRAppearance.ghost,
                uiSize: TRUiSize.sm,
                key: const ValueKey('workspace-sidebar-toggle'),
                label: collapsed
                    ? AppLocalizations.of(context).workspaceSidebarExpand
                    : AppLocalizations.of(context).workspaceSidebarCollapse,
                onPressed: () => unawaited(_setSidebarCollapsed(!collapsed)),
                icon: Icon(collapsed ? CoderIcons.menu : CoderIcons.menuOpen),
              ),
        title: Text(AppLocalizations.of(context).workspacesTitle),
        actions: <Widget>[
          TRIconButton(
            key: const ValueKey('workspace-settings-button'),
            appearance: TRAppearance.ghost,
            uiSize: TRUiSize.sm,
            label: AppLocalizations.of(context).settingsTitle,
            onPressed: () {
              final hostId = widget.selection?.hostId;
              if (hostId == null) {
                const DaemonSettingsRoute().go(context);
              } else {
                ProviderSettingsRoute(hostId: hostId).go(context);
              }
            },
            icon: const Icon(CoderIcons.settings),
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
                SizedBox(
                  width: 320,
                  child: TRAppShellSidebar(
                    key: const ValueKey<String>('workspace-sidebar-surface'),
                    scroll: false,
                    child: sidebar,
                  ),
                ),
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
                TRIconButton(
                  appearance: TRAppearance.ghost,
                  uiSize: TRUiSize.sm,
                  label: MaterialLocalizations.of(context).backButtonTooltip,
                  onPressed: () => const WorkspaceHomeRoute().go(context),
                  icon: const Icon(CoderIcons.back),
                ),
              Expanded(
                child: state == null
                    ? const TRProgress(uiSize: TRUiSize.sm)
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
              TRIconButton(
                appearance: TRAppearance.ghost,
                uiSize: TRUiSize.sm,
                label: AppLocalizations.of(context).workspaceNewSession,
                onPressed: state == null ? null : _startDraft,
                icon: const Icon(CoderIcons.add),
              ),
              if (state != null)
                TRMenu(
                  key: const ValueKey('workspace-all-sessions-menu'),
                  trigger: Icon(
                    CoderIcons.more,
                    semanticLabel: AppLocalizations.of(
                      context,
                    ).workspaceAllSessions,
                  ),
                  menuChildren: <Widget>[
                    for (final agent in state.sessions)
                      TRMenuItem(
                        onPressed: () => _open(agent.id),
                        child: Text(agent.title),
                      ),
                  ],
                ),
            ],
          ),
        ),
        const TRSeparator(),
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
  Widget build(BuildContext context) => SizedBox(
    width: 180,
    child: CoderListRow(
      dense: true,
      selected: selected,
      onTap: onSelect,
      title: Text(agent.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: TRIconButton(
        key: ValueKey('session-tab-close-${agent.id}'),
        appearance: TRAppearance.ghost,
        uiSize: TRUiSize.sm,
        label: AppLocalizations.of(context).workspaceCloseTab,
        onPressed: onClose,
        icon: const Icon(CoderIcons.close, size: 16),
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
            : agentSelectionFor(definition, connections));
    // Only the newest finished plan can still be acted on.
    final lastPlan = items.whereType<ChatPlanProposal>().lastOrNull;
    final pendingPlan =
        !busy &&
            lastPlan != null &&
            lastPlan.isComplete &&
            !_dismissedPlans.contains(lastPlan.key)
        ? lastPlan
        : null;
    return LayoutBuilder(
      builder: (context, constraints) => Column(
        children: <Widget>[
          CoderListRow(
            title: Text(current.title),
            subtitle: Text(
              '${current.agentDefinitionId} · ${current.origin.name}',
            ),
            trailing: busy
                ? TRIconButton(
                    appearance: TRAppearance.ghost,
                    uiSize: TRUiSize.sm,
                    label: AppLocalizations.of(context).commonStop,
                    onPressed: () => ref
                        .read(
                          conversationControllerProvider(
                            widget.selection.hostId,
                            current.id,
                          ).notifier,
                        )
                        .cancelTurn(),
                    icon: const Icon(CoderIcons.stop),
                  )
                : null,
          ),
          Expanded(
            child: ChatTimelineView(
              items: items,
              busy: busy,
              loadAttachment: _loadAttachment,
              exportAttachment: _exportAttachment,
            ),
          ),
          // A plan and any number of approvals sit between the timeline and
          // the composer, and each grows with the content it previews. The
          // bottom group is capped so the composer always keeps its natural
          // size and only the cards scroll; whatever the group leaves over
          // goes back to the timeline above.
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: constraints.maxHeight / 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        if (pendingPlan != null)
                          ChatPlanActions(
                            selection: widget.selection,
                            session: current,
                            proposal: pendingPlan,
                            onDismiss: () => setState(
                              () => _dismissedPlans.add(pendingPlan.key),
                            ),
                            onSessionCreated: (session) => _goSession(
                              context,
                              widget.selection,
                              session.id,
                            ),
                          ),
                        for (final approval
                            in value?.approvals.values ??
                                const <ApprovalRequestDto>[])
                          ApprovalCard(
                            hostId: widget.selection.hostId,
                            approval: approval,
                          ),
                      ],
                    ),
                  ),
                ),
                SessionComposer(
                  enabled: !busy && effective != null,
                  hint: effective == null
                      ? AppLocalizations.of(context).composerSelectModelFirst
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
                  attachmentInput: ref.read(attachmentInputProvider),
                  onSubmit: (submission) => _send(current.id, submission),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _send(
    String sessionId,
    ComposerSubmission submission,
  ) async {
    await ref
        .read(
          conversationControllerProvider(
            widget.selection.hostId,
            sessionId,
          ).notifier,
        )
        .startTurn(
          submission.text,
          attachments: submission.attachments,
        );
  }

  Future<Uint8List> _loadAttachment(ChatAttachment attachment) async {
    final registry = await ref.read(hostRegistryControllerProvider.future);
    final api = registry.runtimes[widget.selection.hostId]?.api;
    if (api == null) throw StateError('Daemon is not connected.');
    return readAttachmentDownload(await api.downloadAttachment(attachment.id));
  }

  Future<void> _exportAttachment(ChatAttachment attachment) async {
    final bytes = await _loadAttachment(attachment);
    await ref
        .read(attachmentExportProvider)
        .export(
          fileName: attachment.fileName,
          mimeType: attachment.mimeType,
          bytes: bytes,
        );
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
