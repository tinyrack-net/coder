import 'dart:async';

import 'package:coder_app/l10n/gen/app_localizations.dart';
import 'package:coder_app/src/app/router/app_router.dart';
import 'package:coder_app/src/features/agents/presentation/pages/agent_settings_page.dart';
import 'package:coder_app/src/features/hosts/application/host_controller.dart';
import 'package:coder_app/src/features/hosts/domain/host_models.dart';
import 'package:coder_app/src/features/hosts/presentation/host_labels.dart';
import 'package:coder_app/src/features/hosts/presentation/pages/host_settings_page.dart';
import 'package:coder_app/src/features/mcp/presentation/pages/mcp_settings_page.dart';
import 'package:coder_app/src/features/permissions/presentation/pages/permission_settings_page.dart';
import 'package:coder_app/src/features/providers/presentation/pages/provider_settings_page.dart';
import 'package:coder_app/src/features/settings/domain/settings_category.dart';
import 'package:coder_app/src/features/settings/presentation/pages/advanced_settings_page.dart';
import 'package:coder_app/src/features/settings/presentation/pages/general_settings_page.dart';
import 'package:coder_app/src/features/skills/presentation/pages/skill_settings_page.dart';
import 'package:coder_app/src/features/workspace/presentation/pages/project_settings_page.dart';
import 'package:coder_app/src/shared/presentation/coder_icons.dart';
import 'package:coder_app/src/shared/presentation/coder_page_shell.dart';
import 'package:coder_app/src/shared/presentation/settings_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

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
    // A deep link naming a daemon wins once, then the persisted selection
    // takes over so switching categories never resets it.
    WidgetsBinding.instance.addPostFrameCallback((_) => _adoptRouteHost());
  }

  void _adoptRouteHost() {
    if (!mounted) return;
    final requested = widget.hostId;
    if (requested == null || requested == _adoptedRouteHost) return;
    final registry = ref.read(hostRegistryControllerProvider).asData?.value;
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
              SkillSettingsRoute(workspaceId: value).replace(context),
        ),
      ),
      SettingsCategory.provider => _HostScopedDetail(
        host: host,
        builder: (hostId) => SettingsPage(hostId: hostId, embedded: true),
      ),
      SettingsCategory.permission => _HostScopedDetail(
        host: host,
        builder: (hostId) => PermissionSettingsPage(hostId: hostId),
      ),
      SettingsCategory.daemon => const AppSettingsPage(embedded: true),
      SettingsCategory.advanced => const AdvancedSettingsPage(embedded: true),
    };
    return CoderPageShell(
      appBar: CoderPageHeader(
        leading: TRIconButton(
          key: const ValueKey<String>('settings-back-button'),
          appearance: TRAppearance.ghost,
          label: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () =>
              closeTask(context, () => const WorkspaceHomeRoute().go(context)),
          icon: const Icon(CoderIcons.back),
        ),
        title: TRText.inherit(AppLocalizations.of(context).settingsTitle),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < TRBreakpoints.medium) {
            final l10n = AppLocalizations.of(context);
            return Column(
              children: <Widget>[
                SettingsCompactToolbar(
                  builder: (width) => <Widget>[
                    TRSelectFormField<SettingsCategory>(
                      key: const ValueKey<String>('settings-category-select'),
                      initialValue: widget.category,
                      label: l10n.settingsTitle,
                      width: width,
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
                    if (widget.category.scope == SettingsCategoryScope.daemon)
                      _DaemonSelect(
                        hosts: hosts,
                        hostId: hostId,
                        showLabel: true,
                      ),
                  ],
                ),
                Expanded(child: detail),
              ],
            );
          }
          return Row(
            children: <Widget>[
              TRAppShellSidebar(
                key: const ValueKey<String>('settings-sidebar-surface'),
                scroll: false,
                // The sidebar lays its content out at the width it is given,
                // so the width belongs to it rather than to an outer box.
                width: TRMeasurements.paneSm,
                child: _SettingsSidebar(
                  selected: widget.category,
                  hosts: hosts,
                  hostId: hostId,
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
    // The nav rows below sit a single extraSmall step apart, so the label
    // needs a wider step beneath it to read as their header rather than as
    // another row.
    padding: const EdgeInsets.fromLTRB(
      TRSpacing.small,
      TRSpacing.small,
      TRSpacing.small,
      TRSpacing.medium,
    ),
    child: TRText(
      text,
      variant: TRTextVariant.label,
      color: TRTextColor.muted,
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
          // The sidebar is a flat list of borderless nav rows, so the trigger
          // takes its frame from the sidebar rather than drawing its own.
          appearance: showLabel
              ? TRFieldAppearance.solid
              : TRFieldAppearance.ghost,
          label: showLabel ? l10n.settingsDaemonSelectLabel : null,
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
  SettingsCategory.general => CoderIcons.tune,
  SettingsCategory.project => CoderIcons.projects,
  SettingsCategory.agent => CoderIcons.agent,
  SettingsCategory.mcp => CoderIcons.extension,
  SettingsCategory.skill => CoderIcons.sparkle,
  SettingsCategory.provider => CoderIcons.network,
  SettingsCategory.permission => CoderIcons.permission,
  SettingsCategory.daemon => CoderIcons.daemon,
  SettingsCategory.advanced => CoderIcons.tool,
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
  SettingsCategory.permission => l10n.settingsCategoryPermission,
  SettingsCategory.daemon => l10n.settingsCategoryDaemon,
  SettingsCategory.advanced => l10n.settingsCategoryAdvanced,
};

/// Navigates to one settings category, keeping the persisted daemon choice.
///
/// Categories are siblings within the open settings task, so this replaces the
/// current page instead of pushing: the screen settings was opened from stays
/// beneath it however many categories the user visits.
void _goToSettingsCategory(BuildContext context, SettingsCategory category) {
  switch (category) {
    case SettingsCategory.general:
      const GeneralSettingsRoute().replace(context);
    case SettingsCategory.project:
      const ProjectSettingsRoute().replace(context);
    case SettingsCategory.agent:
      const AgentSettingsRoute().replace(context);
    case SettingsCategory.mcp:
      const McpSettingsRoute().replace(context);
    case SettingsCategory.skill:
      const SkillSettingsRoute().replace(context);
    case SettingsCategory.provider:
      const ProviderSettingsRoute().replace(context);
    case SettingsCategory.permission:
      const PermissionSettingsRoute().replace(context);
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
  const _HostScopedDetail({required this.host, required this.builder});

  final HostRuntimeSnapshot? host;
  final Widget Function(String hostId) builder;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
