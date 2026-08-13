import 'dart:async';

import 'package:app/l10n/gen/app_localizations.dart';
import 'package:app/src/app/router/app_router.dart';
import 'package:app/src/features/agents/presentation/pages/agent_settings_page.dart';
import 'package:app/src/features/hosts/application/host_controller.dart';
import 'package:app/src/features/hosts/domain/host_models.dart';
import 'package:app/src/features/hosts/presentation/host_labels.dart';
import 'package:app/src/features/hosts/presentation/pages/host_settings_page.dart';
import 'package:app/src/features/hosts/presentation/pages/relay_pairing_pages.dart';
import 'package:app/src/features/mcp/presentation/pages/mcp_settings_page.dart';
import 'package:app/src/features/models/presentation/pages/model_settings_page.dart';
import 'package:app/src/features/permissions/presentation/pages/permission_settings_page.dart';
import 'package:app/src/features/providers/presentation/pages/provider_settings_page.dart';
import 'package:app/src/features/settings/domain/settings_category.dart';
import 'package:app/src/features/settings/presentation/pages/advanced_settings_page.dart';
import 'package:app/src/features/settings/presentation/pages/general_settings_page.dart';
import 'package:app/src/features/skills/presentation/pages/skill_settings_page.dart';
import 'package:app/src/features/workspace/presentation/pages/project_settings_page.dart';
import 'package:app/src/shared/presentation/settings_layout.dart';
import 'package:app/src/shared/presentation/tinest_icons.dart';
import 'package:app/src/shared/presentation/tinest_layout_metrics.dart';
import 'package:app/src/shared/presentation/tinest_page_shell.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

/// The categories carried by one sidebar section, in display order.
List<SettingsCategory> _categoriesInScope(SettingsCategoryScope scope) =>
    SettingsCategory.values
        .where((category) => category.scope == scope)
        .toList(growable: false);

/// Shared responsive settings shell.
class UnifiedSettingsPage extends ConsumerStatefulWidget {
  /// Creates a unified settings page.
  const UnifiedSettingsPage({
    this.category,
    this.hostId,
    this.workspaceId,
    super.key,
  });

  /// Selected settings category, or null for a compact navigation pane.
  final SettingsCategory? category;

  /// Preferred provider daemon.
  final String? hostId;

  /// Project selected on the skill page.
  final String? workspaceId;

  @override
  ConsumerState<UnifiedSettingsPage> createState() =>
      _UnifiedSettingsPageState();
}

class _UnifiedSettingsPageState extends ConsumerState<UnifiedSettingsPage> {
  late final TRThreePaneNavigator<String> _adaptiveNavigation;
  late final ProjectSettingsPaneController _projectPanes;
  late final AgentSettingsPaneController _agentPanes;
  late final McpSettingsPaneController _mcpPanes;
  late final ProviderSettingsPaneController _providerPanes;
  late final Map<SettingsCategory, SettingsPaneCoordinator> _paneControllers;
  bool _adaptiveSyncScheduled = false;

  /// Daemon this page has already adopted from a route.
  ///
  /// Categories replace each other rather than pushing, so this state outlives
  /// a location change and cannot latch on "have I ever adopted one": it has to
  /// remember which daemon it adopted, or a later location naming a different
  /// daemon would be ignored.
  String? _adoptedRouteHost;

  @override
  void initState() {
    super.initState();
    _adaptiveNavigation = TRThreePaneNavigator<String>(
      initialDestination: _settingsDestination(widget),
    );
    _projectPanes = ProjectSettingsPaneController();
    _agentPanes = AgentSettingsPaneController();
    _mcpPanes = McpSettingsPaneController();
    _providerPanes = ProviderSettingsPaneController();
    _paneControllers = <SettingsCategory, SettingsPaneCoordinator>{
      SettingsCategory.project: _projectPanes,
      SettingsCategory.agent: _agentPanes,
      SettingsCategory.mcp: _mcpPanes,
      SettingsCategory.provider: _providerPanes,
    };
    _adaptiveNavigation.addListener(_adaptiveNavigationChanged);
    for (final MapEntry(key: category, value: controller)
        in _paneControllers.entries) {
      controller.addListener(
        () => _paneDestinationChanged(category, controller),
      );
    }
    // A deep link naming a daemon wins once, then the persisted selection
    // takes over so switching categories never resets it.
    WidgetsBinding.instance.addPostFrameCallback((_) => _adoptRouteHost());
  }

  @override
  void dispose() {
    _adaptiveNavigation.dispose();
    _projectPanes.dispose();
    _agentPanes.dispose();
    _mcpPanes.dispose();
    _providerPanes.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(UnifiedSettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.category != widget.category ||
        oldWidget.hostId != widget.hostId ||
        oldWidget.workspaceId != widget.workspaceId) {
      for (final controller in _paneControllers.values) {
        controller.reset();
      }
    }
    _scheduleAdaptiveDestinationReset();
  }

  void _scheduleAdaptiveDestinationReset() {
    if (_adaptiveSyncScheduled) return;
    _adaptiveSyncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _adaptiveSyncScheduled = false;
      if (!mounted) return;
      final destination = _settingsDestination(widget);
      final current = _adaptiveNavigation.currentDestination;
      if (current.value != destination.value ||
          current.role != destination.role) {
        _adaptiveNavigation.reset(destination);
      }
    });
  }

  void _adaptiveNavigationChanged() {
    if (!mounted ||
        _adaptiveNavigation.lastChange?.operation !=
            TRPaneNavigationOperation.pop) {
      return;
    }
    final destination = _adaptiveNavigation.currentDestination;
    if (destination.role == TRPaneRole.secondary) return;
    if (destination.value == 'settings-daemon-categories-pane') {
      final hostId = widget.hostId;
      if (hostId != null) {
        DaemonCategoriesRoute(hostId: hostId).replace(context);
      }
      return;
    }
    if (destination.role == TRPaneRole.primary) {
      final paneController = _paneControllers[widget.category];
      if (paneController?.hasDetail ?? false) {
        paneController!.showCollection();
      }
      return;
    }
    const SettingsHomeRoute().replace(context);
  }

  void _paneDestinationChanged(
    SettingsCategory category,
    SettingsPaneCoordinator controller,
  ) {
    if (!mounted || widget.category != category) return;
    final destinationId = controller.destinationId;
    final current = _adaptiveNavigation.currentDestination;
    if (destinationId == null) {
      if (current.role == TRPaneRole.secondary && !_adaptiveNavigation.pop()) {
        _adaptiveNavigation.reset(_settingsDestination(widget));
      }
      return;
    }
    final destination = TRPaneDestination<String>(
      role: TRPaneRole.secondary,
      value: 'settings-${category.name}-$destinationId',
    );
    if (current.role == TRPaneRole.secondary) {
      _adaptiveNavigation.replace(destination);
    } else {
      _adaptiveNavigation.push(destination);
    }
  }

  void _adoptRouteHost() {
    if (!mounted) return;
    final requested = widget.hostId;
    if (requested == null || requested == _adoptedRouteHost) return;
    final registry = ref.read(hostRegistryControllerProvider).value;
    if (registry == null) return;
    _adoptedRouteHost = requested;
    if (!registry.runtimes.containsKey(requested)) return;
    if (registry.settings.lastActiveHostId == requested) return;
    unawaited(
      ref.read(hostRegistryControllerProvider.notifier).selectHost(requested),
    );
  }

  @override
  Widget build(BuildContext context) {
    _adoptRouteHost();
    final registryState = ref.watch(hostRegistryControllerProvider);
    final registry = registryState.value;
    final registryLoading = registryState.isLoading && !registryState.hasValue;
    final hosts =
        registry?.runtimes.values.toList(growable: false) ??
        const <HostRuntimeSnapshot>[];
    final hostId = ref.watch(activeHostIdProvider);
    final host = hostId == null ? null : registry?.runtimes[hostId];
    final category =
        widget.category ??
        (widget.hostId == null
            ? SettingsCategory.general
            : SettingsCategory.provider);
    final l10n = AppLocalizations.of(context);
    final panes = switch (category) {
      SettingsCategory.general => _SettingsPanePair(
        primary: _SettingsSimplePane(
          title: _settingsCategoryLabel(l10n, SettingsCategory.general),
          child: const GeneralSettingsPage(embedded: true),
        ),
      ),
      SettingsCategory.project => _hostListDetailPanes(
        host: host,
        loading: registryLoading,
        semanticLabel: l10n.settingsLoading,
        builder: (hostId, slot) => ProjectSettingsPage(
          hostId: hostId,
          paneController: _projectPanes,
          slot: slot,
        ),
      ),
      SettingsCategory.agent => _hostListDetailPanes(
        host: host,
        loading: registryLoading,
        semanticLabel: l10n.settingsLoading,
        builder: (hostId, slot) => AgentSettingsPage(
          hostId: hostId,
          paneController: _agentPanes,
          slot: slot,
        ),
      ),
      SettingsCategory.mcp => _hostListDetailPanes(
        host: host,
        loading: registryLoading,
        semanticLabel: l10n.settingsLoading,
        builder: (hostId, slot) => McpSettingsPage(
          hostId: hostId,
          paneController: _mcpPanes,
          slot: slot,
        ),
      ),
      SettingsCategory.connection => _SettingsPanePair(
        primary: _SettingsSimplePane(
          title: _settingsCategoryLabel(
            l10n,
            SettingsCategory.connection,
          ),
          child: _HostScopedDetail(
            host: host,
            loading: registryLoading,
            loadingChild: SettingsSkeletonLayout.form(
              semanticLabel: AppLocalizations.of(context).settingsLoading,
            ),
            builder: (hostId) => DaemonConnectionsPage(
              hostId: hostId,
              embedded: true,
            ),
          ),
        ),
      ),
      SettingsCategory.skill => _SettingsPanePair(
        primary: _SettingsSimplePane(
          title: _settingsCategoryLabel(l10n, SettingsCategory.skill),
          child: _HostScopedDetail(
            host: host,
            loading: registryLoading,
            loadingChild: SettingsSkeletonLayout.form(
              semanticLabel: l10n.settingsLoading,
            ),
            builder: (hostId) => SkillSettingsPage(
              hostId: hostId,
              workspaceId: widget.workspaceId,
              onWorkspaceChanged: (value) => SkillSettingsRoute(
                hostId: hostId,
                workspaceId: value,
              ).replace(context),
            ),
          ),
        ),
      ),
      SettingsCategory.provider => _hostListDetailPanes(
        host: host,
        loading: registryLoading,
        semanticLabel: l10n.settingsLoading,
        builder: (hostId, slot) => SettingsPage(
          hostId: hostId,
          paneController: _providerPanes,
          slot: slot,
          embedded: true,
        ),
      ),
      SettingsCategory.model => _SettingsPanePair(
        primary: _SettingsSimplePane(
          title: _settingsCategoryLabel(l10n, SettingsCategory.model),
          child: _HostScopedDetail(
            host: host,
            loading: registryLoading,
            loadingChild: SettingsSkeletonLayout.form(
              semanticLabel: AppLocalizations.of(context).settingsLoading,
            ),
            builder: (hostId) => ModelSettingsPage(hostId: hostId),
          ),
        ),
      ),
      SettingsCategory.permission => _SettingsPanePair(
        primary: _SettingsSimplePane(
          title: _settingsCategoryLabel(
            l10n,
            SettingsCategory.permission,
          ),
          child: _HostScopedDetail(
            host: host,
            loading: registryLoading,
            loadingChild: SettingsSkeletonLayout.form(
              semanticLabel: AppLocalizations.of(context).settingsLoading,
            ),
            builder: (hostId) => PermissionSettingsPage(hostId: hostId),
          ),
        ),
      ),
      SettingsCategory.daemon => _SettingsPanePair(
        primary: _SettingsSimplePane(
          title: _settingsCategoryLabel(
            l10n,
            SettingsCategory.daemon,
          ),
          child: const AppSettingsPage(embedded: true),
        ),
      ),
      SettingsCategory.advanced => _SettingsPanePair(
        primary: _SettingsSimplePane(
          title: _settingsCategoryLabel(
            l10n,
            SettingsCategory.advanced,
          ),
          child: const AdvancedSettingsPage(embedded: true),
        ),
      ),
    };
    final primary = switch ((widget.category, widget.hostId)) {
      (null, final String requestedHostId) => _MobileDaemonCategories(
        host: registry?.runtimes[requestedHostId],
        onCategorySelected: _selectCategory,
      ),
      _ => panes.primary,
    };
    return LayoutBuilder(
      builder: (context, constraints) {
        final widthClass = TRAdaptiveWidthClass.fromWidth(
          constraints.maxWidth,
        );
        final compact = widthClass == TRAdaptiveWidthClass.compact;
        final hasSecondaryPane =
            widget.category != null && panes.secondary != null;
        final body = TRNavigableThreePaneScaffold<String>(
          navigator: _adaptiveNavigation,
          navigationPaneWidth: TinestLayoutMetrics.settingsSidebarWidth,
          navigationPane: compact
              ? _MobileSettingsHome(
                  hosts: hosts,
                  onCategorySelected: _selectCategory,
                  onDaemonSelected: _selectDaemon,
                )
              : KeyedSubtree(
                  key: const ValueKey<String>('settings-sidebar-surface'),
                  child: _SettingsSidebar(
                    selected: category,
                    hosts: hosts,
                    hostId: hostId,
                    loading: registryLoading,
                    onCategorySelected: _selectCategory,
                  ),
                ),
          primaryPane: primary,
          secondaryPane: hasSecondaryPane ? panes.secondary : null,
        );
        return TinestPageShell(
          appBar: TinestPageHeader(
            leading: TRIconButton(
              key: const ValueKey<String>('settings-back-button'),
              appearance: TRAppearance.ghost,
              label: MaterialLocalizations.of(context).backButtonTooltip,
              onPressed: () => _goBack(
                widthClass: widthClass,
                hasSecondaryPane: hasSecondaryPane,
              ),
              icon: Icon(TinestIcons.backFor(context)),
            ),
            title: TRText.inherit(
              AppLocalizations.of(context).settingsTitle,
            ),
          ),
          body: body,
        );
      },
    );
  }

  _SettingsPanePair _hostListDetailPanes({
    required HostRuntimeSnapshot? host,
    required bool loading,
    required String semanticLabel,
    required Widget Function(String hostId, SettingsPaneSlot slot) builder,
  }) => _SettingsPanePair(
    primary: _HostScopedDetail(
      host: host,
      loading: loading,
      loadingChild: SettingsSkeletonLayout.collection(
        semanticLabel: semanticLabel,
      ),
      builder: (hostId) => builder(hostId, SettingsPaneSlot.collection),
    ),
    secondary: _HostScopedDetail(
      host: host,
      loading: loading,
      loadingChild: SettingsSkeletonLayout.detail(
        semanticLabel: semanticLabel,
      ),
      builder: (hostId) => builder(hostId, SettingsPaneSlot.detail),
    ),
  );

  void _goBack({
    required TRAdaptiveWidthClass widthClass,
    required bool hasSecondaryPane,
  }) {
    if (_adaptiveNavigation.popUntilScaffoldValueChange(
      widthClass,
      hasSecondaryPane: hasSecondaryPane,
    )) {
      return;
    }
    closeTask(context, () => const WorkspaceHomeRoute().go(context));
  }

  void _selectCategory(SettingsCategory category, {String? hostId}) {
    final destination = TRPaneDestination<String>(
      role: TRPaneRole.primary,
      value: 'settings-category-pane-${category.name}',
    );
    final current = _adaptiveNavigation.currentDestination;
    if (current.role == TRPaneRole.navigation ||
        current.value == 'settings-daemon-categories-pane') {
      _adaptiveNavigation.push(destination);
    } else {
      _adaptiveNavigation.replace(destination);
    }
    _goToSettingsCategory(context, category, hostId: hostId);
  }

  Future<void> _selectDaemon(String hostId) async {
    await ref.read(hostRegistryControllerProvider.notifier).selectHost(hostId);
    if (!mounted) return;
    _adaptiveNavigation.push(
      const TRPaneDestination<String>(
        role: TRPaneRole.primary,
        value: 'settings-daemon-categories-pane',
      ),
    );
    DaemonCategoriesRoute(hostId: hostId).replace(context);
  }
}

class _SettingsPanePair {
  const _SettingsPanePair({required this.primary, this.secondary});

  final Widget primary;
  final Widget? secondary;
}

class _SettingsSimplePane extends StatelessWidget {
  const _SettingsSimplePane({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      TRPaneHeader(
        title: TRText.inherit(title),
        contentMaxWidth: TinestLayoutMetrics.settingsContentMaxWidth,
      ),
      Expanded(child: child),
    ],
  );
}

TRPaneDestination<String> _settingsDestination(UnifiedSettingsPage page) {
  final category = page.category;
  if (category != null) {
    return TRPaneDestination<String>(
      role: TRPaneRole.primary,
      value: 'settings-category-pane-${category.name}',
    );
  }
  if (page.hostId != null) {
    return const TRPaneDestination<String>(
      role: TRPaneRole.primary,
      value: 'settings-daemon-categories-pane',
    );
  }
  return const TRPaneDestination<String>(
    role: TRPaneRole.navigation,
    value: 'settings-home-pane',
  );
}

class _MobileSettingsHome extends StatelessWidget {
  const _MobileSettingsHome({
    required this.hosts,
    required this.onCategorySelected,
    required this.onDaemonSelected,
  });

  final List<HostRuntimeSnapshot> hosts;
  final void Function(SettingsCategory category, {String? hostId})
  onCategorySelected;
  final Future<void> Function(String hostId) onDaemonSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TRNavigationPane(
      children: <Widget>[
        TRNavigationSection(
          label: Text(l10n.settingsSectionApp),
          child: TRTreeNav<SettingsCategory>.controlled(
            value: null,
            semanticLabel: l10n.settingsSectionApp,
            itemSpacing: TRSpacing.extraSmall,
            items: <TRTreeNavItem<SettingsCategory>>[
              for (final category in _categoriesInScope(
                SettingsCategoryScope.app,
              ))
                TRTreeNavLeaf<SettingsCategory>(
                  key: ValueKey<String>(
                    'settings-category-row-${category.name}',
                  ),
                  value: category,
                  leading: Icon(_settingsCategoryIcon(category)),
                  label: TRText.inherit(
                    _settingsCategoryLabel(l10n, category),
                  ),
                  trailing: Icon(TinestIcons.forwardFor(context)),
                ),
            ],
            onValueChange: (category) {
              if (category == null) return;
              onCategorySelected(category);
            },
          ),
        ),
        TRNavigationSection(
          label: Text(l10n.settingsSectionDaemon),
          child: hosts.isEmpty
              ? TRNavigationRow(
                  key: const ValueKey<String>('settings-daemon-empty-row'),
                  enabled: false,
                  leading: const Icon(TinestIcons.daemon),
                  label: TRText.inherit(l10n.settingsDaemonSelectEmpty),
                )
              : TRTreeNav<String>.controlled(
                  value: null,
                  semanticLabel: l10n.settingsSectionDaemon,
                  itemSpacing: TRSpacing.extraSmall,
                  items: <TRTreeNavItem<String>>[
                    for (final host in hosts)
                      TRTreeNavLeaf<String>(
                        key: ValueKey<String>(
                          'settings-daemon-row-${host.id}',
                        ),
                        value: host.id,
                        leading: Icon(hostStatusIcon(host.status)),
                        label: TRText.inherit(hostLabel(l10n, host)),
                        description: TRText.inherit(
                          hostStatusText(l10n, host),
                        ),
                        trailing: Icon(TinestIcons.forwardFor(context)),
                      ),
                  ],
                  onValueChange: (hostId) {
                    if (hostId == null) return;
                    unawaited(onDaemonSelected(hostId));
                  },
                ),
        ),
      ],
    );
  }
}

class _MobileDaemonCategories extends StatelessWidget {
  const _MobileDaemonCategories({
    required this.host,
    required this.onCategorySelected,
  });

  final HostRuntimeSnapshot? host;
  final void Function(SettingsCategory category, {String? hostId})
  onCategorySelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final host = this.host;
    if (host == null) {
      return SettingsEmptyState(
        title: l10n.settingsDaemonSelectEmpty,
        icon: const Icon(TinestIcons.daemon),
      );
    }
    return Column(
      children: <Widget>[
        TRPaneHeader(
          title: TRText.inherit(hostLabel(l10n, host)),
          description: TRText.inherit(hostStatusText(l10n, host)),
        ),
        Expanded(
          child: TRNavigationPane(
            children: <Widget>[
              TRTreeNav<SettingsCategory>.controlled(
                value: null,
                semanticLabel: l10n.settingsSectionDaemon,
                itemSpacing: TRSpacing.extraSmall,
                items: <TRTreeNavItem<SettingsCategory>>[
                  for (final category in _categoriesInScope(
                    SettingsCategoryScope.daemon,
                  ))
                    TRTreeNavLeaf<SettingsCategory>(
                      key: ValueKey<String>(
                        'settings-category-row-${category.name}',
                      ),
                      value: category,
                      leading: Icon(_settingsCategoryIcon(category)),
                      label: TRText.inherit(
                        _settingsCategoryLabel(l10n, category),
                      ),
                      trailing: Icon(TinestIcons.forwardFor(context)),
                    ),
                ],
                onValueChange: (category) {
                  if (category == null) return;
                  onCategorySelected(category, hostId: host.id);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsSidebar extends StatelessWidget {
  const _SettingsSidebar({
    required this.selected,
    required this.hosts,
    required this.hostId,
    required this.loading,
    required this.onCategorySelected,
  });

  final SettingsCategory selected;
  final List<HostRuntimeSnapshot> hosts;
  final String? hostId;
  final bool loading;
  final void Function(SettingsCategory category, {String? hostId})
  onCategorySelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TRNavigationPane(
      children: <Widget>[
        TRNavigationSection(
          label: Text(l10n.settingsSectionApp),
          child: _scopeNav(context, l10n, SettingsCategoryScope.app),
        ),
        TRNavigationSection(
          label: Text(l10n.settingsSectionDaemon),
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: TRSpacing.extraSmall,
                ),
                child: _DaemonSelect(
                  hosts: hosts,
                  hostId: hostId,
                  loading: loading,
                ),
              ),
              _scopeNav(context, l10n, SettingsCategoryScope.daemon),
            ],
          ),
        ),
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
      itemSpacing: TRSpacing.extraSmall,
      items: <TRTreeNavItem<SettingsCategory>>[
        for (final category in _categoriesInScope(scope))
          TRTreeNavLeaf<SettingsCategory>(
            key: ValueKey<String>(
              'settings-category-row-${category.name}',
            ),
            value: category,
            leading: Icon(_settingsCategoryIcon(category)),
            label: TRText.inherit(_settingsCategoryLabel(l10n, category)),
          ),
      ],
      onValueChange: (category) {
        if (category == null) return;
        onCategorySelected(
          category,
          hostId: category == SettingsCategory.connection ? hostId : null,
        );
      },
    );
  }
}

/// Picks the daemon that every host-scoped settings page edits.
///
/// Offline daemons stay listed so their settings can be reached as soon as
/// they reconnect, and so a saved selection does not silently jump elsewhere.
class _DaemonSelect extends ConsumerWidget {
  const _DaemonSelect({
    required this.hosts,
    required this.hostId,
    required this.loading,
  });

  final List<HostRuntimeSnapshot> hosts;
  final String? hostId;
  final bool loading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    if (loading) {
      return Semantics(
        label: l10n.settingsLoading,
        container: true,
        child: const ExcludeSemantics(
          child: TRSkeleton(
            key: ValueKey<String>('settings-daemon-select-loading'),
            shape: TRSkeletonShape.rectangle,
          ),
        ),
      );
    }
    // Where a section heading already names this control the field label is
    // dropped, so the screen-reader name is carried here instead.
    // The pane is narrower than a daemon label, so the trigger takes the
    // full width and lets the label ellipsize instead of overflowing.
    final selected = hosts.where((host) => host.id == hostId).firstOrNull;
    return Semantics(
      label: l10n.settingsDaemonSelectLabel,
      container: true,
      child: LayoutBuilder(
        builder: (context, constraints) => TRSelect<String>.controlled(
          key: const ValueKey<String>('settings-daemon-select'),
          searchable: true,
          searchPlaceholder: l10n.selectSearchPlaceholder,
          noResultsText: l10n.selectNoResults,
          // Explicit so the production Select policy can audit adaptation.
          // ignore: avoid_redundant_argument_values
          surface: TRSelectSurface.auto,
          value: hostId,
          // The sidebar is a flat list of borderless nav rows, so the trigger
          // takes its frame from the sidebar rather than drawing its own.
          appearance: TRFieldAppearance.ghost,
          placeholder: l10n.settingsDaemonSelectEmpty,
          helperText: selected == null ? null : hostStatusText(l10n, selected),
          leading: selected == null
              ? null
              : Icon(hostStatusIcon(selected.status)),
          enabled: hosts.isNotEmpty,
          width: constraints.maxWidth,
          items: hosts
              .map(
                (host) => TRSelectItem<String>(
                  key: ValueKey<String>('settings-daemon-option-${host.id}'),
                  value: host.id,
                  label: hostLabel(l10n, host),
                  description: hostStatusText(l10n, host),
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
  SettingsCategory.general => TinestIcons.tune,
  SettingsCategory.project => TinestIcons.projects,
  SettingsCategory.agent => TinestIcons.agent,
  SettingsCategory.mcp => TinestIcons.extension,
  SettingsCategory.connection => TinestIcons.link,
  SettingsCategory.skill => TinestIcons.sparkle,
  SettingsCategory.provider => TinestIcons.network,
  SettingsCategory.model => TinestIcons.memory,
  SettingsCategory.permission => TinestIcons.permission,
  SettingsCategory.daemon => TinestIcons.daemon,
  SettingsCategory.advanced => TinestIcons.tool,
};

String _settingsCategoryLabel(
  AppLocalizations l10n,
  SettingsCategory category,
) => switch (category) {
  SettingsCategory.general => l10n.settingsCategoryGeneral,
  SettingsCategory.project => l10n.settingsCategoryProjects,
  SettingsCategory.agent => l10n.settingsCategoryAgent,
  SettingsCategory.mcp => l10n.settingsCategoryMcp,
  SettingsCategory.connection => l10n.settingsCategoryConnection,
  SettingsCategory.skill => l10n.settingsCategorySkill,
  SettingsCategory.provider => l10n.settingsCategoryProvider,
  SettingsCategory.model => l10n.settingsCategoryModel,
  SettingsCategory.permission => l10n.settingsCategoryPermission,
  SettingsCategory.daemon => l10n.settingsCategoryDaemon,
  SettingsCategory.advanced => l10n.settingsCategoryAdvanced,
};

/// Navigates to one settings category, keeping the persisted daemon choice.
///
/// Categories are siblings within the open settings task, so this replaces the
/// current page instead of pushing: the screen settings was opened from stays
/// beneath it however many categories the user visits.
void _goToSettingsCategory(
  BuildContext context,
  SettingsCategory category, {
  String? hostId,
}) {
  switch (category) {
    case SettingsCategory.general:
      const GeneralSettingsRoute().replace(context);
    case SettingsCategory.project:
      ProjectSettingsRoute(hostId: hostId).replace(context);
    case SettingsCategory.agent:
      AgentSettingsRoute(hostId: hostId).replace(context);
    case SettingsCategory.mcp:
      McpSettingsRoute(hostId: hostId).replace(context);
    case SettingsCategory.connection:
      if (hostId != null) {
        DaemonConnectionsRoute(hostId: hostId).replace(context);
      }
    case SettingsCategory.skill:
      SkillSettingsRoute(hostId: hostId).replace(context);
    case SettingsCategory.provider:
      ProviderSettingsRoute(hostId: hostId).replace(context);
    case SettingsCategory.model:
      ModelSettingsRoute(hostId: hostId).replace(context);
    case SettingsCategory.permission:
      PermissionSettingsRoute(hostId: hostId).replace(context);
    case SettingsCategory.daemon:
      const DaemonSettingsRoute().replace(context);
    case SettingsCategory.advanced:
      const AdvancedSettingsRoute().replace(context);
  }
}

/// Guards a host-scoped settings page behind a usable daemon connection.
///
/// The daemon itself is chosen in the sidebar, so this only explains why a
/// page cannot render yet.
class _HostScopedDetail extends StatelessWidget {
  const _HostScopedDetail({
    required this.host,
    required this.loading,
    required this.loadingChild,
    required this.builder,
  });

  final HostRuntimeSnapshot? host;
  final bool loading;
  final Widget loadingChild;
  final Widget Function(String hostId) builder;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (loading) return loadingChild;
    final host = this.host;
    if (host == null) {
      return SettingsEmptyState(
        title: l10n.settingsRequiresOnlineDaemon,
        icon: const Icon(TinestIcons.daemon),
      );
    }
    if (!host.connected) {
      return SettingsEmptyState(
        key: const ValueKey<String>('settings-daemon-offline'),
        title: l10n.settingsDaemonOffline(hostLabel(l10n, host)),
        description: hostStatusText(l10n, host),
        icon: Icon(hostStatusIcon(host.status)),
      );
    }
    return builder(host.id);
  }
}
