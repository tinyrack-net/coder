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
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  final SettingsPaneNavigationController _paneNavigation =
      SettingsPaneNavigationController();

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
    _paneNavigation.addListener(_paneNavigationChanged);
    // A deep link naming a daemon wins once, then the persisted selection
    // takes over so switching categories never resets it.
    WidgetsBinding.instance.addPostFrameCallback((_) => _adoptRouteHost());
  }

  @override
  void dispose() {
    _paneNavigation
      ..removeListener(_paneNavigationChanged)
      ..dispose();
    super.dispose();
  }

  void _paneNavigationChanged() {
    if (mounted) setState(() {});
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
    final detail = switch (category) {
      SettingsCategory.general => const GeneralSettingsPage(embedded: true),
      SettingsCategory.project => _HostScopedDetail(
        host: host,
        loading: registryLoading,
        loadingChild: SettingsSkeletonLayout.listDetail(
          semanticLabel: AppLocalizations.of(context).settingsLoading,
        ),
        builder: (hostId) => ProjectSettingsPage(hostId: hostId),
      ),
      SettingsCategory.agent => _HostScopedDetail(
        host: host,
        loading: registryLoading,
        loadingChild: SettingsSkeletonLayout.listDetail(
          semanticLabel: AppLocalizations.of(context).settingsLoading,
        ),
        builder: (hostId) => AgentSettingsPage(hostId: hostId),
      ),
      SettingsCategory.mcp => _HostScopedDetail(
        host: host,
        loading: registryLoading,
        loadingChild: SettingsSkeletonLayout.listDetail(
          semanticLabel: AppLocalizations.of(context).settingsLoading,
        ),
        builder: (hostId) => McpSettingsPage(hostId: hostId),
      ),
      SettingsCategory.connection => _HostScopedDetail(
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
      SettingsCategory.skill => _HostScopedDetail(
        host: host,
        loading: registryLoading,
        loadingChild: SettingsSkeletonLayout.listDetail(
          semanticLabel: AppLocalizations.of(context).settingsLoading,
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
      SettingsCategory.provider => _HostScopedDetail(
        host: host,
        loading: registryLoading,
        loadingChild: SettingsSkeletonLayout.form(
          semanticLabel: AppLocalizations.of(context).settingsLoading,
        ),
        builder: (hostId) => SettingsPage(hostId: hostId, embedded: true),
      ),
      SettingsCategory.permission => _HostScopedDetail(
        host: host,
        loading: registryLoading,
        loadingChild: SettingsSkeletonLayout.form(
          semanticLabel: AppLocalizations.of(context).settingsLoading,
        ),
        builder: (hostId) => PermissionSettingsPage(hostId: hostId),
      ),
      SettingsCategory.daemon => const AppSettingsPage(embedded: true),
      SettingsCategory.advanced => const AdvancedSettingsPage(embedded: true),
    };
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxWidth < TinestLayoutMetrics.compactBreakpoint;
        final body = compact
            ? SettingsCompactPaneTransition(
                paneKey: _compactSettingsPaneKey(
                  category: widget.category,
                  hostId: widget.hostId,
                ),
                child: switch ((widget.category, widget.hostId)) {
                  (null, null) => _MobileSettingsHome(hosts: hosts),
                  (null, final String requestedHostId) =>
                    _MobileDaemonCategories(
                      host: registry?.runtimes[requestedHostId],
                    ),
                  _ => SettingsPaneNavigationScope(
                    controller: _paneNavigation,
                    child: detail,
                  ),
                },
              )
            : Row(
                children: <Widget>[
                  TRAppShellSidebar(
                    key: const ValueKey<String>('settings-sidebar-surface'),
                    scroll: false,
                    // The sidebar lays content out at the width it is given,
                    // so the width belongs here rather than on an outer box.
                    width: TinestLayoutMetrics.settingsSidebarWidth,
                    child: _SettingsSidebar(
                      selected: category,
                      hosts: hosts,
                      hostId: hostId,
                      loading: registryLoading,
                    ),
                  ),
                  Expanded(child: detail),
                ],
              );
        final hasLogicalParent =
            compact &&
            (_paneNavigation.canGoBack ||
                widget.category != null ||
                widget.hostId != null);
        return PopScope<Object?>(
          canPop: !hasLogicalParent && Navigator.of(context).canPop(),
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _goBack(compact: compact, hostId: hostId);
          },
          child: TinestPageShell(
            appBar: TinestPageHeader(
              leading: TRIconButton(
                key: const ValueKey<String>('settings-back-button'),
                appearance: TRAppearance.ghost,
                label: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: () => _goBack(compact: compact, hostId: hostId),
                icon: const Icon(TinestIcons.back),
              ),
              title: TRText.inherit(AppLocalizations.of(context).settingsTitle),
            ),
            body: body,
          ),
        );
      },
    );
  }

  void _goBack({required bool compact, required String? hostId}) {
    if (compact && _paneNavigation.canGoBack) {
      _paneNavigation.goBack();
      return;
    }
    if (compact) {
      final category = widget.category;
      if (category != null) {
        if (category.scope == SettingsCategoryScope.daemon && hostId != null) {
          DaemonCategoriesRoute(hostId: hostId).replace(context);
        } else {
          const SettingsHomeRoute().replace(context);
        }
        return;
      }
      if (widget.hostId != null) {
        const SettingsHomeRoute().replace(context);
        return;
      }
    }
    closeTask(context, () => const WorkspaceHomeRoute().go(context));
  }
}

Key _compactSettingsPaneKey({
  required SettingsCategory? category,
  required String? hostId,
}) {
  if (category != null) {
    return ValueKey<String>('settings-category-pane-${category.name}');
  }
  if (hostId != null) {
    return const ValueKey<String>('settings-daemon-categories-pane');
  }
  return const ValueKey<String>('settings-home-pane');
}

class _MobileSettingsHome extends StatelessWidget {
  const _MobileSettingsHome({required this.hosts});

  final List<HostRuntimeSnapshot> hosts;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(TRSpacing.medium),
      children: <Widget>[
        _SettingsSectionLabel(text: l10n.settingsSectionApp),
        TRTreeNav<SettingsCategory>.controlled(
          value: null,
          semanticLabel: l10n.settingsSectionApp,
          itemSpacing: TRSpacing.extraSmall,
          items: <TRTreeNavItem<SettingsCategory>>[
            for (final category in _categoriesInScope(
              SettingsCategoryScope.app,
            ))
              TRTreeNavLeaf<SettingsCategory>(
                value: category,
                leading: Icon(_settingsCategoryIcon(category)),
                label: TRText.inherit(_settingsCategoryLabel(l10n, category)),
                trailing: const Icon(TinestIcons.chevronRight),
              ),
          ],
          onValueChange: (category) {
            if (category == null) return;
            _goToSettingsCategory(context, category);
          },
        ),
        const SizedBox(height: TRSpacing.large),
        _SettingsSectionLabel(text: l10n.settingsSectionDaemon),
        TRTreeNav<String>.controlled(
          value: null,
          semanticLabel: l10n.settingsSectionDaemon,
          itemSpacing: TRSpacing.extraSmall,
          items: <TRTreeNavItem<String>>[
            for (final host in hosts)
              TRTreeNavLeaf<String>(
                key: ValueKey<String>('settings-daemon-row-${host.id}'),
                value: host.id,
                leading: Icon(hostStatusIcon(host.status)),
                label: TRText.inherit(hostLabel(l10n, host)),
                description: TRText.inherit(hostStatusText(l10n, host)),
                trailing: const Icon(TinestIcons.chevronRight),
              ),
          ],
          onValueChange: (hostId) {
            if (hostId == null) return;
            unawaited(_openDaemonCategories(context, hostId));
          },
        ),
      ],
    );
  }

  Future<void> _openDaemonCategories(
    BuildContext context,
    String hostId,
  ) async {
    final container = ProviderScope.containerOf(context);
    await container
        .read(hostRegistryControllerProvider.notifier)
        .selectHost(hostId);
    if (context.mounted) {
      DaemonCategoriesRoute(hostId: hostId).replace(context);
    }
  }
}

class _MobileDaemonCategories extends StatelessWidget {
  const _MobileDaemonCategories({required this.host});

  final HostRuntimeSnapshot? host;

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
        SettingsPaneHeader.list(
          title: hostLabel(l10n, host),
          subtitle: hostStatusText(l10n, host),
        ),
        Expanded(
          child: ListView(
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
                      value: category,
                      leading: Icon(_settingsCategoryIcon(category)),
                      label: TRText.inherit(
                        _settingsCategoryLabel(l10n, category),
                      ),
                      trailing: const Icon(TinestIcons.chevronRight),
                    ),
                ],
                onValueChange: (category) {
                  if (category == null) return;
                  _goToSettingsCategory(
                    context,
                    category,
                    hostId: host.id,
                  );
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
  });

  final SettingsCategory selected;
  final List<HostRuntimeSnapshot> hosts;
  final String? hostId;
  final bool loading;

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
          child: _DaemonSelect(
            hosts: hosts,
            hostId: hostId,
            loading: loading,
          ),
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
      itemSpacing: TRSpacing.extraSmall,
      items: <TRTreeNavItem<SettingsCategory>>[
        for (final category in _categoriesInScope(scope))
          TRTreeNavLeaf<SettingsCategory>(
            value: category,
            leading: Icon(_settingsCategoryIcon(category)),
            label: TRText.inherit(_settingsCategoryLabel(l10n, category)),
          ),
      ],
      onValueChange: (category) {
        if (category == null) return;
        _goToSettingsCategory(
          context,
          category,
          hostId: category == SettingsCategory.connection ? hostId : null,
        );
      },
    );
  }
}

class _SettingsSectionLabel extends StatelessWidget {
  const _SettingsSectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    // The nav rows below sit a single extraSmall step apart, so the label
    // needs a wider step beneath it to read as their header rather than as
    // another row.
    padding: const EdgeInsets.fromLTRB(
      TRSpacing.small,
      TRSpacing.small,
      TRSpacing.small,
      TRSpacing.medium,
    ),
    child: TRText(text, variant: TRTextVariant.label, color: TRTextColor.muted),
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
  SettingsCategory.general => TinestIcons.tune,
  SettingsCategory.project => TinestIcons.projects,
  SettingsCategory.agent => TinestIcons.agent,
  SettingsCategory.mcp => TinestIcons.extension,
  SettingsCategory.connection => TinestIcons.link,
  SettingsCategory.skill => TinestIcons.sparkle,
  SettingsCategory.provider => TinestIcons.network,
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
      return Center(child: TRText.inherit(l10n.settingsRequiresOnlineDaemon));
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
              title: TRText.inherit(
                l10n.settingsDaemonOffline(hostLabel(l10n, host)),
              ),
              description: TRText.inherit(hostStatusText(l10n, host)),
            ),
          ),
        ),
      );
    }
    return builder(host.id);
  }
}
