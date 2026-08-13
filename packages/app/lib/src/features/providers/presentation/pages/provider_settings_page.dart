import 'dart:async';

import 'package:app/l10n/gen/app_localizations.dart';
import 'package:app/src/app/composition/app_providers.dart';
import 'package:app/src/app/platform/external_url_opener.dart';
import 'package:app/src/features/providers/application/provider_settings_controller.dart';
import 'package:app/src/shared/presentation/settings_layout.dart';
import 'package:app/src/shared/presentation/settings_navigation_row.dart';
import 'package:app/src/shared/presentation/tinest_icons.dart';
import 'package:app/src/shared/presentation/tinest_layout_metrics.dart';
import 'package:app/src/shared/presentation/tinest_page_shell.dart';
import 'package:app/src/shared/presentation/tinest_selection_row.dart';
import 'package:app/src/shared/presentation/toast_messenger.dart';
import 'package:client/client.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:protocol/protocol.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

/// Provider connection settings for one daemon host.
class SettingsPage extends StatefulWidget {
  /// Creates a provider connection settings page.
  const SettingsPage({
    required this.hostId,
    this.paneController,
    this.slot,
    this.embedded = false,
    super.key,
  }) : assert(
         (paneController == null) == (slot == null),
         'paneController and slot must be supplied together.',
       );

  /// Route host identifier.
  final String hostId;

  /// Selection shared by the collection and detail scaffold slots.
  final ProviderSettingsPaneController? paneController;

  /// Which scaffold slot this widget supplies.
  final SettingsPaneSlot? slot;

  /// Whether the unified settings shell supplies navigation chrome.
  final bool embedded;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final ProviderSettingsPaneController _paneController;
  TRThreePaneNavigator<String>? _standaloneNavigator;

  @override
  void initState() {
    super.initState();
    _paneController = widget.paneController ?? ProviderSettingsPaneController();
    if (widget.slot == null) {
      _standaloneNavigator = TRThreePaneNavigator<String>(
        initialDestination: const TRPaneDestination<String>(
          role: TRPaneRole.navigation,
          value: 'provider-collection',
        ),
      );
      _standaloneNavigator!.addListener(_standaloneNavigationChanged);
      _paneController.addListener(_syncStandaloneDestination);
    }
  }

  @override
  void dispose() {
    _paneController.removeListener(_syncStandaloneDestination);
    _standaloneNavigator?.dispose();
    if (widget.paneController == null) _paneController.dispose();
    super.dispose();
  }

  void _syncStandaloneDestination() {
    final navigator = _standaloneNavigator;
    if (navigator == null) return;
    final destinationId = _paneController.destinationId;
    if (destinationId == null) {
      navigator.pop();
      return;
    }
    final destination = TRPaneDestination<String>(
      role: TRPaneRole.primary,
      value: destinationId,
    );
    if (navigator.currentDestination.role == TRPaneRole.primary) {
      navigator.replace(destination);
    } else {
      navigator.push(destination);
    }
  }

  void _standaloneNavigationChanged() {
    final navigator = _standaloneNavigator;
    if (navigator?.lastChange?.operation != TRPaneNavigationOperation.pop) {
      return;
    }
    if (_paneController.hasDetail) _paneController.showCollection();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final slot = widget.slot;
    final embeddedBody = slot == null
        ? null
        : _ProviderSettingsSlot(
            hostId: widget.hostId,
            paneController: _paneController,
            slot: slot,
          );
    if (embeddedBody != null && widget.embedded) return embeddedBody;
    if (slot != null) {
      return TinestPageShell(
        appBar: TinestPageHeader(
          leading: TRIconButton(
            appearance: TRAppearance.ghost,
            label: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: context.pop,
            icon: Icon(TinestIcons.backFor(context)),
          ),
          title: TRText.inherit(l10n.providerSettingsTitle),
        ),
        body: embeddedBody!,
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final widthClass = TRAdaptiveWidthClass.fromWidth(constraints.maxWidth);
        final body = TRNavigableThreePaneScaffold<String>(
          navigator: _standaloneNavigator!,
          navigationPane: _ProviderSettingsSlot(
            hostId: widget.hostId,
            paneController: _paneController,
            slot: SettingsPaneSlot.collection,
          ),
          primaryPane: _ProviderSettingsSlot(
            hostId: widget.hostId,
            paneController: _paneController,
            slot: SettingsPaneSlot.detail,
          ),
        );
        return TinestPageShell(
          appBar: TinestPageHeader(
            leading: TRIconButton(
              appearance: TRAppearance.ghost,
              label: MaterialLocalizations.of(context).backButtonTooltip,
              onPressed: () {
                if (_standaloneNavigator!.popUntilScaffoldValueChange(
                  widthClass,
                  hasSecondaryPane: false,
                )) {
                  return;
                }
                context.pop();
              },
              icon: Icon(TinestIcons.backFor(context)),
            ),
            title: TRText.inherit(l10n.providerSettingsTitle),
          ),
          body: body,
        );
      },
    );
  }
}

class _ProviderSettingsSlot extends ConsumerWidget {
  const _ProviderSettingsSlot({
    required this.hostId,
    required this.paneController,
    required this.slot,
  });

  final String hostId;
  final ProviderSettingsPaneController paneController;
  final SettingsPaneSlot slot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final provider = providerSettingsControllerProvider(hostId);
    final state = ref.watch(provider);
    return ListenableBuilder(
      listenable: paneController,
      builder: (context, _) => SettingsAsyncContent<ProviderSettingsState?>(
        state: state,
        loading: settingsPaneSkeleton(
          slot,
          semanticLabel: l10n.settingsLoading,
        ),
        error: (error, _) => slot == SettingsPaneSlot.collection
            ? SettingsCollectionErrorState(
                key: const ValueKey<String>('provider-settings-error'),
                title: l10n.providerSettingsConnected,
                error: error,
                onRetry: () => ref.invalidate(provider),
              )
            : SettingsEmptyState(
                title: l10n.providerSettingsSelectConnection,
                icon: const Icon(TinestIcons.network),
              ),
        data: (state) => state == null
            ? SettingsEmptyState(
                title: slot == SettingsPaneSlot.collection
                    ? l10n.providerSettingsRequiresDaemon
                    : l10n.providerSettingsSelectConnection,
                icon: Icon(
                  slot == SettingsPaneSlot.collection
                      ? TinestIcons.daemon
                      : TinestIcons.network,
                ),
              )
            : _body(context, state),
      ),
    );
  }

  Widget _body(BuildContext context, ProviderSettingsState state) {
    final widthClass = settingsAdaptiveWidthClassOf(context);
    final showsSplit =
        widthClass == TRAdaptiveWidthClass.large ||
        widthClass == TRAdaptiveWidthClass.extraLarge;
    if (slot == SettingsPaneSlot.collection &&
        paneController._pane == _ProviderPane.empty &&
        showsSplit &&
        paneController.canAutoSelect &&
        state.connections.isNotEmpty) {
      _scheduleInitialSelection(state.connections.first.id);
    }
    final selected = state.connections
        .where((connection) => connection.id == paneController.selectedId)
        .firstOrNull;
    final reauthConnection = state.connections
        .where(
          (connection) => connection.id == paneController.reauthConnectionId,
        )
        .firstOrNull;
    if (paneController._pane == _ProviderPane.connection && selected == null) {
      _scheduleCollection();
    }
    if (slot == SettingsPaneSlot.collection) {
      return _ProviderCollection(
        connections: state.connections,
        selectedId: paneController._pane == _ProviderPane.connection
            ? paneController.selectedId
            : null,
        onSelected: paneController.selectConnectionId,
        onAdd: paneController.showCatalog,
      );
    }
    return switch (paneController._pane) {
      _ProviderPane.empty => SettingsEmptyState(
        title: AppLocalizations.of(context).providerSettingsSelectConnection,
        icon: const Icon(TinestIcons.network),
      ),
      _ProviderPane.catalog => _ProviderCatalogPane(
        hostId: hostId,
        state: state,
        onPreset: paneController.showPreset,
        onCustom: paneController.showCustom,
      ),
      _ProviderPane.preset => _PresetProviderPane(
        key: ValueKey<String>(
          'provider-preset-${paneController.draftDefinition!.id}',
        ),
        hostId: hostId,
        state: state,
        definition: paneController.draftDefinition!,
        existing: reauthConnection,
        onCancel: reauthConnection == null
            ? paneController.showCatalog
            : () => paneController.selectConnection(reauthConnection),
        onConnected: paneController.selectConnection,
      ),
      _ProviderPane.custom => _CustomProviderPane(
        hostId: hostId,
        state: state,
        onCancel: paneController.showCatalog,
        onSaved: paneController.selectConnection,
      ),
      _ProviderPane.connection =>
        selected!.customConfig == null
            ? _ProviderConnectionPane(
                key: ValueKey<String>('provider-detail-${selected.id}'),
                hostId: hostId,
                state: state,
                connection: selected,
                onChanged: paneController.selectConnection,
                onRemoved: paneController.showCollection,
                onReauth: (definition) => paneController.showReauthentication(
                  selected.id,
                  definition,
                ),
              )
            : _CustomProviderPane(
                key: ValueKey<String>('provider-detail-${selected.id}'),
                hostId: hostId,
                state: state,
                existing: selected,
                onCancel: paneController.showCollection,
                onSaved: paneController.selectConnection,
                onRemoved: paneController.showCollection,
              ),
    };
  }

  void _scheduleInitialSelection(String connectionId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      paneController.selectInitialConnectionId(connectionId);
    });
  }

  void _scheduleCollection() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      paneController.showCollection();
    });
  }
}

enum _ProviderPane { empty, catalog, preset, custom, connection }

/// Owns Provider selection and creation flow independently from pane slots.
class ProviderSettingsPaneController extends SettingsPaneCoordinatorBase {
  String? _selectedId;
  String? _reauthConnectionId;
  ProviderDefinitionDto? _draftDefinition;
  _ProviderPane _pane = _ProviderPane.empty;

  /// Selected provider connection ID, when an existing connection is active.
  String? get selectedId => _selectedId;

  /// Connection being reauthenticated, when the preset flow is a retry.
  String? get reauthConnectionId => _reauthConnectionId;

  /// Provider definition selected from the catalog.
  ProviderDefinitionDto? get draftDefinition => _draftDefinition;

  @override
  bool get hasDetail => _pane != _ProviderPane.empty;

  @override
  String? get destinationId => switch (_pane) {
    _ProviderPane.empty => null,
    _ProviderPane.catalog => 'provider-catalog',
    _ProviderPane.preset =>
      'provider-preset-${_draftDefinition!.id}-${_reauthConnectionId ?? 'new'}',
    _ProviderPane.custom => 'provider-custom-new',
    _ProviderPane.connection => 'provider-connection-$_selectedId',
  };

  /// Shows the first connection on initial desktop entry.
  void selectInitialConnectionId(String id) {
    if (!consumeInitialSelection()) return;
    _selectedId = id;
    _pane = _ProviderPane.connection;
    notifyListeners();
  }

  /// Shows an existing provider connection.
  void selectConnection(ProviderConnectionDto connection) =>
      selectConnectionId(connection.id);

  /// Shows an existing provider connection by ID.
  void selectConnectionId(String id) {
    consumeExplicitNavigation();
    if (_pane == _ProviderPane.connection && _selectedId == id) return;
    _selectedId = id;
    _draftDefinition = null;
    _reauthConnectionId = null;
    _pane = _ProviderPane.connection;
    notifyListeners();
  }

  /// Shows the provider catalog.
  void showCatalog() {
    consumeExplicitNavigation();
    if (_pane == _ProviderPane.catalog) return;
    _selectedId = null;
    _draftDefinition = null;
    _reauthConnectionId = null;
    _pane = _ProviderPane.catalog;
    notifyListeners();
  }

  /// Shows the connection flow for a catalog definition.
  void showPreset(ProviderDefinitionDto definition) {
    consumeExplicitNavigation();
    _selectedId = null;
    _draftDefinition = definition;
    _reauthConnectionId = null;
    _pane = _ProviderPane.preset;
    notifyListeners();
  }

  /// Shows the preset flow for an existing connection retry.
  void showReauthentication(
    String connectionId,
    ProviderDefinitionDto definition,
  ) {
    consumeExplicitNavigation();
    _selectedId = null;
    _reauthConnectionId = connectionId;
    _draftDefinition = definition;
    _pane = _ProviderPane.preset;
    notifyListeners();
  }

  /// Shows the custom provider creator.
  void showCustom() {
    consumeExplicitNavigation();
    if (_pane == _ProviderPane.custom) return;
    _selectedId = null;
    _draftDefinition = null;
    _reauthConnectionId = null;
    _pane = _ProviderPane.custom;
    notifyListeners();
  }

  @override
  void showCollection() {
    consumeExplicitNavigation();
    if (!hasDetail) return;
    _selectedId = null;
    _draftDefinition = null;
    _reauthConnectionId = null;
    _pane = _ProviderPane.empty;
    notifyListeners();
  }

  @override
  void reset() {
    final hadDetail = hasDetail;
    resetInitialSelection();
    _selectedId = null;
    _draftDefinition = null;
    _reauthConnectionId = null;
    _pane = _ProviderPane.empty;
    if (hadDetail) notifyListeners();
  }
}

class _ProviderCollection extends StatelessWidget {
  const _ProviderCollection({
    required this.connections,
    required this.selectedId,
    required this.onSelected,
    required this.onAdd,
  });

  final List<ProviderConnectionDto> connections;
  final String? selectedId;
  final ValueChanged<String> onSelected;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: <Widget>[
        TRPaneHeader(
          title: TRText.inherit(l10n.providerSettingsConnected),
          description: TRText.inherit('${connections.length}'),
          actions: <Widget>[
            TRIconButton(
              key: const ValueKey<String>('provider-add-button'),
              appearance: TRAppearance.ghost,
              label: l10n.providerSettingsAdd,
              onPressed: onAdd,
              icon: const Icon(TinestIcons.add),
            ),
          ],
        ),
        Expanded(
          child: connections.isEmpty
              ? SettingsEmptyState(
                  key: const ValueKey<String>('provider-list-empty'),
                  title: l10n.providerSettingsNoConnections,
                  icon: const Icon(TinestIcons.network),
                )
              : SettingsCollectionList(
                  children: <Widget>[
                    for (final connection in connections)
                      SettingsNavigationRow(
                        key: ValueKey<String>(
                          'provider-connection-${connection.id}',
                        ),
                        selected: connection.id == selectedId,
                        leading: Icon(_statusIcon(connection.status)),
                        title: TRText.inherit(connection.displayName),
                        description: TRText.inherit(
                          '${connection.modelPrefix} · '
                          '${_statusLabel(l10n, connection.status)}',
                        ),
                        onPressed: () => onSelected(connection.id),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _ProviderCatalogPane extends ConsumerStatefulWidget {
  const _ProviderCatalogPane({
    required this.hostId,
    required this.state,
    required this.onPreset,
    required this.onCustom,
  });

  final ProviderSettingsState state;
  final String hostId;
  final ValueChanged<ProviderDefinitionDto> onPreset;
  final VoidCallback onCustom;

  @override
  ConsumerState<_ProviderCatalogPane> createState() =>
      _ProviderCatalogPaneState();
}

class _ProviderCatalogPaneState extends ConsumerState<_ProviderCatalogPane> {
  bool _refreshing = false;
  Object? _error;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final catalog = widget.state.catalog;
    return Column(
      children: <Widget>[
        TRPaneHeader(
          title: TRText.inherit(l10n.providerSettingsAdd),
          contentMaxWidth: TinestLayoutMetrics.settingsContentMaxWidth,
          actions: <Widget>[
            TRButton(
              key: const ValueKey<String>('provider-catalog-refresh'),
              appearance: TRAppearance.outline,
              onPressed: _refreshing ? null : _refresh,
              child: TRText.inherit(l10n.providerSettingsRefreshCatalog),
            ),
          ],
        ),
        Expanded(
          child: SettingsScaffold(
            children: <Widget>[
              SettingsSection(
                title: l10n.providerSettingsCatalogStatus,
                banner: _error == null && catalog.refreshError == null
                    ? null
                    : TRAlert(
                        variant: TRStatusVariant.danger,
                        title: TRText.inherit(
                          l10n.providerSettingsRefreshFailed,
                        ),
                        description: TRText.inherit(
                          '${_error ?? catalog.refreshError}',
                        ),
                      ),
                children: <Widget>[
                  SettingsRow(
                    title: TRText.inherit(
                      _catalogLabel(l10n, catalog.freshness),
                    ),
                  ),
                  for (final definition in catalog.definitions)
                    SettingsNavigationRow(
                      key: ValueKey<String>('provider-add-${definition.id}'),
                      leading: const Icon(TinestIcons.network),
                      title: TRText.inherit(definition.name),
                      description: TRText.inherit(definition.description),
                      onPressed: () => widget.onPreset(definition),
                    ),
                  SettingsNavigationRow(
                    key: const ValueKey<String>('provider-add-custom'),
                    leading: const Icon(TinestIcons.tune),
                    title: TRText.inherit(l10n.providerSettingsCustomName),
                    description: TRText.inherit(
                      l10n.providerSettingsCustomSubtitle,
                    ),
                    onPressed: widget.onCustom,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _refreshing = true;
      _error = null;
    });
    try {
      await ref
          .read(providerSettingsControllerProvider(widget.hostId).notifier)
          .refreshCatalog();
    } on Object catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }
}

class _PresetProviderPane extends ConsumerStatefulWidget {
  const _PresetProviderPane({
    required this.hostId,
    required this.state,
    required this.definition,
    required this.onCancel,
    required this.onConnected,
    this.existing,
    super.key,
  });

  final String hostId;
  final ProviderSettingsState state;
  final ProviderDefinitionDto definition;
  final ProviderConnectionDto? existing;
  final VoidCallback onCancel;
  final ValueChanged<ProviderConnectionDto> onConnected;

  @override
  ConsumerState<_PresetProviderPane> createState() =>
      _PresetProviderPaneState();
}

class _PresetProviderPaneState extends ConsumerState<_PresetProviderPane> {
  late final TextEditingController _prefix;
  final TextEditingController _apiKey = TextEditingController();
  late ProviderAuthMethodDto _method;
  bool _busy = false;
  Object? _error;
  String? _attemptId;
  String? _retryConnectionId;
  Object? _openError;
  final Set<String> _rejectedPrefixes = <String>{};

  @override
  void initState() {
    super.initState();
    _prefix = TextEditingController(
      text: widget.existing?.modelPrefix ?? _suggestPrefix(),
    );
    _method = _initialMethod();
  }

  @override
  void dispose() {
    _prefix.dispose();
    _apiKey.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final attempt = widget.state.authAttempts[_attemptId];
    if (attempt?.status == ProviderAuthAttemptStatus.succeeded) {
      final connection = widget.state.connections
          .where((item) => item.id == attempt!.connectionId)
          .firstOrNull;
      if (connection != null) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => widget.onConnected(connection),
        );
      }
    }
    if (attempt != null) return _oauthPane(attempt);
    final l10n = AppLocalizations.of(context);
    return Column(
      children: <Widget>[
        TRPaneHeader(
          title: TRText.inherit(
            widget.existing == null
                ? l10n.providerSettingsConnectTitle(widget.definition.name)
                : widget.definition.name,
          ),
          contentMaxWidth: TinestLayoutMetrics.settingsContentMaxWidth,
          actions: <Widget>[
            TRButton(
              appearance: TRAppearance.ghost,
              onPressed: _busy ? null : widget.onCancel,
              child: TRText.inherit(l10n.commonCancel),
            ),
            TRButton(
              key: const ValueKey<String>('provider-connect-submit'),
              intent: TRIntent.primary,
              onPressed: _canSubmit ? _submit : null,
              child: TRText.inherit(l10n.providerSettingsConnect),
            ),
          ],
        ),
        Expanded(
          child: SettingsScaffold(
            children: <Widget>[
              SettingsSection.form(
                title: l10n.providerSettingsAuthTitle(widget.definition.name),
                description: widget.definition.description,
                children: <Widget>[
                  TRTextField(
                    key: const ValueKey<String>('provider-model-prefix'),
                    controller: _prefix,
                    enabled: !_busy,
                    label: l10n.providerSettingsModelPrefix,
                    helperText: l10n.providerSettingsModelPrefixHelp,
                    errorText: _prefixError(l10n),
                    onChanged: (_) => setState(() => _error = null),
                  ),
                  if (widget.definition.authMethods.length > 1)
                    TRSelectFormField<String>(
                      key: const ValueKey<String>('provider-auth-method'),
                      initialValue: _method.id,
                      searchable: true,
                      searchPlaceholder: l10n.selectSearchPlaceholder,
                      noResultsText: l10n.selectNoResults,
                      // Explicit for the auditable adaptive Select contract.
                      // ignore: avoid_redundant_argument_values
                      surface: TRSelectSurface.auto,
                      label: l10n.providerSettingsActions,
                      width: TinestLayoutMetrics.settingsContentMaxWidth,
                      items: <TRSelectItem<String>>[
                        for (final method in widget.definition.authMethods)
                          TRSelectItem<String>(
                            key: ValueKey<String>(
                              'provider-auth-method-${method.id}',
                            ),
                            value: method.id,
                            label: method.label,
                          ),
                      ],
                      onValueChange: _busy
                          ? null
                          : (id) => setState(() {
                              _method = widget.definition.authMethods
                                  .singleWhere((method) => method.id == id);
                              _error = null;
                            }),
                    ),
                  if (_method.flow == ProviderAuthFlow.apiKey)
                    TRTextField(
                      key: const ValueKey<String>('provider-api-key'),
                      controller: _apiKey,
                      enabled: !_busy,
                      obscureText: true,
                      label: l10n.providerSettingsApiKey,
                      onChanged: (_) => setState(() => _error = null),
                    ),
                  if (_method.experimental)
                    TRAlert(
                      variant: TRStatusVariant.warning,
                      title: TRText.inherit(
                        l10n.providerSettingsExperimental,
                      ),
                    ),
                  if (_unexpectedError case final error?)
                    TRAlert(
                      variant: TRStatusVariant.danger,
                      title: TRText.inherit('$error'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _oauthPane(ProviderAuthAttemptDto attempt) {
    final l10n = AppLocalizations.of(context);
    final terminal =
        attempt.status == ProviderAuthAttemptStatus.failed ||
        attempt.status == ProviderAuthAttemptStatus.expired ||
        attempt.status == ProviderAuthAttemptStatus.cancelled;
    return Column(
      children: <Widget>[
        TRPaneHeader(
          title: TRText.inherit(l10n.providerSettingsOAuthPending),
          contentMaxWidth: TinestLayoutMetrics.settingsContentMaxWidth,
          actions: <Widget>[
            if (!terminal)
              TRButton(
                key: ValueKey<String>('provider-auth-cancel-${attempt.id}'),
                appearance: TRAppearance.ghost,
                onPressed: () => ref
                    .read(
                      providerSettingsControllerProvider(
                        widget.hostId,
                      ).notifier,
                    )
                    .cancelAuth(attempt.id),
                child: TRText.inherit(l10n.commonCancel),
              )
            else
              TRButton(
                key: const ValueKey<String>('provider-auth-retry'),
                intent: TRIntent.primary,
                onPressed: () => setState(() {
                  _attemptId = null;
                  _error = null;
                }),
                child: TRText.inherit(l10n.commonRetry),
              ),
          ],
        ),
        Expanded(
          child: SettingsScaffold(
            children: <Widget>[
              SettingsSection(
                title: _authStatusLabel(l10n, attempt.status),
                banner: _oauthErrorBanner(attempt),
                children: <Widget>[
                  if (attempt.instructions != null)
                    SettingsRow(
                      title: TRText.inherit(attempt.instructions!),
                    ),
                  if (attempt.authorizationUrl case final url?)
                    SettingsRow(
                      title: SelectionArea(child: TRText.inherit(url)),
                      controlLayout: SettingsControlLayout.responsive,
                      control: Wrap(
                        spacing: TRSpacing.small,
                        children: <Widget>[
                          TRIconButton(
                            appearance: TRAppearance.ghost,
                            label: l10n.commonCopy,
                            onPressed: () => Clipboard.setData(
                              ClipboardData(text: url),
                            ),
                            icon: const Icon(TinestIcons.copy),
                          ),
                          TRIconButton(
                            key: const ValueKey<String>(
                              'provider-oauth-open-browser',
                            ),
                            appearance: TRAppearance.ghost,
                            label: l10n.providerSettingsOpenBrowser,
                            onPressed: () => _openUrl(url),
                            icon: const Icon(TinestIcons.network),
                          ),
                        ],
                      ),
                    ),
                  if (attempt.userCode case final code?)
                    SettingsRow(
                      title: SelectionArea(child: TRText.inherit(code)),
                      control: TRIconButton(
                        appearance: TRAppearance.ghost,
                        label: l10n.commonCopy,
                        onPressed: () => Clipboard.setData(
                          ClipboardData(text: code),
                        ),
                        icon: const Icon(TinestIcons.copy),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget? _oauthErrorBanner(ProviderAuthAttemptDto attempt) {
    final authError = attempt.error;
    final openError = _openError;
    if (authError == null && openError == null) return null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (authError != null)
          TRAlert(
            variant: TRStatusVariant.danger,
            title: TRText.inherit(authError),
          ),
        if (authError != null && openError != null)
          const SizedBox(height: TRSpacing.medium),
        if (openError != null)
          TRAlert(
            key: const ValueKey<String>('provider-oauth-open-error'),
            variant: TRStatusVariant.danger,
            title: TRText.inherit('$openError'),
          ),
      ],
    );
  }

  bool get _canSubmit =>
      !_busy &&
      _validPrefix &&
      (_method.flow != ProviderAuthFlow.apiKey ||
          _apiKey.text.trim().isNotEmpty);

  bool get _validPrefix => RegExp(
    r'^[a-z0-9][a-z0-9_-]{0,63}$',
  ).hasMatch(_prefix.text.trim());

  String? _prefixError(AppLocalizations l10n) {
    if (_prefix.text.isEmpty || _validPrefix) {
      return _error is TinestClientException &&
              (_error! as TinestClientException).code == 'model_prefix_conflict'
          ? l10n.providerSettingsModelPrefixConflict
          : null;
    }
    return l10n.providerSettingsModelPrefixInvalid;
  }

  Object? get _unexpectedError => _isPrefixConflict(_error) ? null : _error;

  ProviderAuthMethodDto _initialMethod() {
    final existing = widget.existing;
    if (existing != null) {
      final matching = widget.definition.authMethods.where(
        (method) => method.kind == existing.authKind,
      );
      if (matching.isNotEmpty) return matching.first;
    }
    return widget.definition.authMethods.first;
  }

  String _suggestPrefix() {
    final used = <String>{
      for (final connection in widget.state.connections)
        connection.modelPrefix.toLowerCase(),
      for (final attempt in widget.state.authAttempts.values)
        attempt.modelPrefix.toLowerCase(),
      ..._rejectedPrefixes,
    };
    var candidate = widget.definition.id;
    var suffix = 2;
    while (used.contains(candidate)) {
      candidate = '${widget.definition.id}-$suffix';
      suffix += 1;
    }
    return candidate;
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final notifier = ref.read(
      providerSettingsControllerProvider(widget.hostId).notifier,
    );
    try {
      switch (_method.flow) {
        case ProviderAuthFlow.apiKey:
          final connection = await notifier.connectApiKey(
            widget.definition.id,
            _apiKey.text.trim(),
            connectionId: widget.existing?.id ?? _retryConnectionId,
            modelPrefix: _prefix.text.trim(),
          );
          _handleConnection(connection);
        case ProviderAuthFlow.none:
          final connection = await notifier.connectNone(
            widget.definition.id,
            connectionId: widget.existing?.id ?? _retryConnectionId,
            modelPrefix: _prefix.text.trim(),
          );
          _handleConnection(connection);
        case ProviderAuthFlow.oauthBrowser:
        case ProviderAuthFlow.oauthDevice:
          final attempt = await notifier.startAuth(
            widget.definition.id,
            _method.id,
            connectionId: widget.existing?.id,
            modelPrefix: _prefix.text.trim(),
          );
          if (!mounted) return;
          setState(() => _attemptId = attempt.id);
          if (_method.flow == ProviderAuthFlow.oauthBrowser &&
              attempt.authorizationUrl != null) {
            await _openUrl(attempt.authorizationUrl!);
          }
      }
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _error = error;
          if (error is TinestClientException &&
              error.code == 'model_prefix_conflict') {
            _rejectedPrefixes.add(_prefix.text.trim().toLowerCase());
            _prefix.text = _suggestPrefix();
          }
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openUrl(String value) async {
    final l10n = AppLocalizations.of(context);
    try {
      final opened = await ref
          .read(externalUrlOpenerProvider)
          .open(Uri.parse(value));
      if (!mounted) return;
      // A false result is not a failure the opener can describe: no handler
      // accepted the URL. Only this layer knows the reader's language, so the
      // explanation is written here rather than thrown from below.
      setState(
        () => _openError = opened ? null : l10n.providerSettingsAuthUrlFailed,
      );
    } on Object catch (error) {
      if (mounted) setState(() => _openError = error);
    }
  }

  void _handleConnection(ProviderConnectionDto connection) {
    if (connection.status == ProviderConnectionStatus.error) {
      setState(() {
        _retryConnectionId = connection.id;
        _error =
            connection.error ??
            AppLocalizations.of(context).providerSettingsConnectionFailed;
      });
      return;
    }
    widget.onConnected(connection);
  }
}

class _ProviderConnectionPane extends ConsumerStatefulWidget {
  const _ProviderConnectionPane({
    required this.hostId,
    required this.state,
    required this.connection,
    required this.onChanged,
    required this.onRemoved,
    required this.onReauth,
    super.key,
  });

  final String hostId;
  final ProviderSettingsState state;
  final ProviderConnectionDto connection;
  final ValueChanged<ProviderConnectionDto> onChanged;
  final VoidCallback onRemoved;
  final ValueChanged<ProviderDefinitionDto> onReauth;

  @override
  ConsumerState<_ProviderConnectionPane> createState() =>
      _ProviderConnectionPaneState();
}

class _ProviderConnectionPaneState
    extends ConsumerState<_ProviderConnectionPane> {
  late final TextEditingController _prefix = TextEditingController(
    text: widget.connection.modelPrefix,
  );
  Object? _error;

  @override
  void initState() {
    super.initState();
    if (!widget.state.models.containsKey(widget.connection.id)) {
      unawaited(_loadModels());
    }
  }

  @override
  void dispose() {
    _prefix.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final definition = widget.state.catalog.definitions
        .where((item) => item.id == widget.connection.definitionId)
        .firstOrNull;
    final models =
        widget.state.models[widget.connection.id] ?? const <ProviderModelDto>[];
    return Column(
      children: <Widget>[
        TRPaneHeader(
          title: TRText.inherit(widget.connection.displayName),
          description: TRText.inherit(
            _statusLabel(l10n, widget.connection.status),
          ),
          contentMaxWidth: TinestLayoutMetrics.settingsContentMaxWidth,
          actions: <Widget>[
            if (definition != null)
              TRButton(
                appearance: TRAppearance.outline,
                onPressed: () => widget.onReauth(definition),
                child: TRText.inherit(l10n.providerSettingsReconnect),
              ),
            TRButton(
              key: const ValueKey<String>('provider-prefix-save'),
              intent: TRIntent.primary,
              onPressed: _savePrefix,
              child: TRText.inherit(l10n.commonSave),
            ),
          ],
        ),
        Expanded(
          child: SettingsScaffold(
            children: <Widget>[
              SettingsSection.form(
                title: l10n.providerSettingsModelPrefix,
                banner: _error == null || _isPrefixConflict(_error)
                    ? null
                    : TRAlert(
                        variant: TRStatusVariant.danger,
                        title: TRText.inherit('$_error'),
                      ),
                children: <Widget>[
                  TRTextField(
                    key: const ValueKey<String>('provider-model-prefix'),
                    controller: _prefix,
                    label: l10n.providerSettingsModelPrefix,
                    helperText: l10n.providerSettingsModelPrefixHelp,
                    errorText: _isPrefixConflict(_error)
                        ? l10n.providerSettingsModelPrefixConflict
                        : null,
                    onChanged: (_) => setState(() => _error = null),
                  ),
                ],
              ),
              SettingsSection.form(
                title: l10n.providerSettingsDefaultModelTitle,
                children: <Widget>[
                  TRSelect<String?>.controlled(
                    key: const ValueKey<String>('provider-default-model'),
                    value: widget.state.defaultModel?.qualifiedModelId,
                    searchable: true,
                    searchPlaceholder: l10n.selectSearchPlaceholder,
                    noResultsText: l10n.selectNoResults,
                    // Explicit for the auditable adaptive Select contract.
                    // ignore: avoid_redundant_argument_values
                    surface: TRSelectSurface.auto,
                    items: <TRSelectItem<String?>>[
                      TRSelectItem<String?>(
                        value: null,
                        label: l10n.providerSettingsDefaultModelAutomatic,
                      ),
                      for (final model in models)
                        TRSelectItem<String?>(
                          key: ValueKey<String>(
                            'provider-model-${model.id}',
                          ),
                          value: model.id,
                          label: model.label,
                          description:
                              '${widget.connection.displayName} · ${model.id}',
                        ),
                    ],
                    onValueChange: (modelId) => unawaited(
                      ref
                          .read(
                            providerSettingsControllerProvider(
                              widget.hostId,
                            ).notifier,
                          )
                          .setDefaultModel(
                            modelId == null
                                ? null
                                : SessionModelSelectionDto(modelId: modelId),
                          ),
                    ),
                  ),
                ],
              ),
              SettingsSection(
                title: l10n.providerSettingsDisconnectTitle,
                children: <Widget>[
                  SettingsRow(
                    title: TRText.inherit(
                      l10n.providerSettingsDisconnectBody(
                        widget.connection.displayName,
                      ),
                    ),
                    control: TRButton(
                      key: const ValueKey<String>(
                        'provider-connection-disconnect',
                      ),
                      appearance: TRAppearance.ghost,
                      intent: TRIntent.danger,
                      onPressed: _disconnect,
                      child: TRText.inherit(
                        l10n.providerSettingsDisconnect,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _savePrefix() async {
    try {
      await ref
          .read(
            providerSettingsControllerProvider(widget.hostId).notifier,
          )
          .updateModelPrefix(widget.connection.id, _prefix.text.trim());
      final changed = ref
          .read(providerSettingsControllerProvider(widget.hostId))
          .value
          ?.connections
          .where((item) => item.id == widget.connection.id)
          .firstOrNull;
      if (changed != null) widget.onChanged(changed);
    } on Object catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  Future<void> _loadModels() async {
    setState(() => _error = null);
    try {
      await ref
          .read(
            providerSettingsControllerProvider(widget.hostId).notifier,
          )
          .loadModels(widget.connection.id);
    } on Object catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  Future<void> _disconnect() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showTRDialog<bool>(
      context: context,
      builder: (context) => TRAlertDialog(
        title: TRText.inherit(l10n.providerSettingsDisconnectTitle),
        content: TRText.inherit(
          l10n.providerSettingsDisconnectBody(widget.connection.displayName),
        ),
        actions: <TRButton>[
          TRButton(
            appearance: TRAppearance.ghost,
            onPressed: () => Navigator.pop(context, false),
            child: TRText.inherit(l10n.commonCancel),
          ),
          TRButton(
            intent: TRIntent.danger,
            onPressed: () => Navigator.pop(context, true),
            child: TRText.inherit(l10n.providerSettingsDisconnect),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final disconnected = await ref
        .read(toastMessengerProvider)
        .run(
          () => ref
              .read(providerSettingsControllerProvider(widget.hostId).notifier)
              .disconnect(widget.connection.id),
          failure: l10n.providerSettingsDisconnectFailed,
          success: l10n.providerSettingsDisconnected,
          id: 'provider-disconnect',
        );
    if (disconnected) widget.onRemoved();
  }
}

bool _isPrefixConflict(Object? error) =>
    error is TinestClientException && error.code == 'model_prefix_conflict';

class _CustomProviderPane extends ConsumerStatefulWidget {
  const _CustomProviderPane({
    required this.hostId,
    required this.state,
    required this.onCancel,
    required this.onSaved,
    this.existing,
    this.onRemoved,
    super.key,
  });

  final String hostId;
  final ProviderSettingsState state;
  final ProviderConnectionDto? existing;
  final VoidCallback onCancel;
  final ValueChanged<ProviderConnectionDto> onSaved;
  final VoidCallback? onRemoved;

  @override
  ConsumerState<_CustomProviderPane> createState() =>
      _CustomProviderPaneState();
}

class _CustomProviderPaneState extends ConsumerState<_CustomProviderPane> {
  late final TextEditingController _name;
  late final TextEditingController _baseUrl;
  late final TextEditingController _apiKey;
  late final TextEditingController _models;
  late final TextEditingController _prefix;
  late String _wireFormatId;
  late bool _authenticationRequired;
  late Set<String> _controlIds;
  bool _busy = false;
  bool _namePrefilled = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    final connection = widget.existing;
    final initial = connection?.customConfig;
    _name = TextEditingController(text: initial?.name);
    _baseUrl = TextEditingController(
      text: initial?.baseUrl ?? 'http://127.0.0.1:8080/v1',
    );
    _apiKey = TextEditingController();
    _models = TextEditingController(
      text: initial?.models.map((model) => model.id).join(', ') ?? '',
    );
    _prefix = TextEditingController(
      text: connection?.modelPrefix ?? _suggestCustomPrefix(),
    );
    _wireFormatId =
        initial?.wireFormatId ??
        widget.state.catalog.wireFormats.firstOrNull?.id ??
        '';
    _authenticationRequired = initial?.authenticationRequired ?? true;
    _controlIds = <String>{
      for (final model in initial?.models ?? const <ManualProviderModelDto>[])
        for (final control in model.controls) control.id,
    };
    if (connection != null && !widget.state.models.containsKey(connection.id)) {
      unawaited(
        ref
            .read(
              providerSettingsControllerProvider(widget.hostId).notifier,
            )
            .loadModels(connection.id),
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Localizations are not in scope during initState, so the default name for
    // a brand-new provider is filled in here. The flag keeps a later locale
    // change from overwriting a name the user has since typed or cleared.
    if (_namePrefilled) return;
    _namePrefilled = true;
    if (widget.existing == null) {
      _name.text = AppLocalizations.of(context).providerSettingsCustomName;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _baseUrl.dispose();
    _apiKey.dispose();
    _models.dispose();
    _prefix.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: <Widget>[
        TRPaneHeader(
          title: TRText.inherit(
            widget.existing == null
                ? l10n.providerSettingsCustomTitle
                : widget.existing!.displayName,
          ),
          contentMaxWidth: TinestLayoutMetrics.settingsContentMaxWidth,
          actions: <Widget>[
            TRButton(
              appearance: TRAppearance.ghost,
              onPressed: _busy ? null : widget.onCancel,
              child: TRText.inherit(l10n.commonCancel),
            ),
            TRButton(
              key: const ValueKey<String>('provider-custom-save'),
              intent: TRIntent.primary,
              onPressed: _busy ? null : _save,
              child: TRText.inherit(
                widget.existing == null
                    ? _busy
                          ? l10n.commonCreating
                          : l10n.commonCreate
                    : _busy
                    ? l10n.commonSaving
                    : l10n.commonSave,
              ),
            ),
          ],
        ),
        Expanded(
          child: SettingsScaffold(
            children: <Widget>[
              SettingsSection.form(
                banner: _error == null
                    ? null
                    : TRAlert(
                        variant: TRStatusVariant.danger,
                        title: TRText.inherit('$_error'),
                      ),
                children: <Widget>[
                  TRTextField(controller: _name, label: l10n.commonName),
                  TRTextField(
                    controller: _baseUrl,
                    label: l10n.providerSettingsBaseUrl,
                  ),
                  TRTextField(
                    key: const ValueKey<String>('provider-model-prefix'),
                    controller: _prefix,
                    label: l10n.providerSettingsModelPrefix,
                    helperText: l10n.providerSettingsModelPrefixHelp,
                  ),
                  TRSelectFormField<String>(
                    initialValue: _wireFormatId,
                    searchable: true,
                    searchPlaceholder: l10n.selectSearchPlaceholder,
                    noResultsText: l10n.selectNoResults,
                    // Explicit for the auditable adaptive Select contract.
                    // ignore: avoid_redundant_argument_values
                    surface: TRSelectSurface.auto,
                    label: l10n.providerSettingsApiFormat,
                    width: TinestLayoutMetrics.settingsContentMaxWidth,
                    items: <TRSelectItem<String>>[
                      for (final format in widget.state.catalog.wireFormats)
                        TRSelectItem<String>(
                          value: format.id,
                          label: format.label,
                        ),
                    ],
                    onValueChange: (value) {
                      if (value == null) return;
                      setState(() {
                        _wireFormatId = value;
                        _controlIds.retainAll(
                          _selectedWire.controls.map((control) => control.id),
                        );
                      });
                    },
                  ),
                  TinestSwitchRow(
                    flush: true,
                    title: TRText.inherit(
                      l10n.providerSettingsRequiresApiKey,
                    ),
                    value: _authenticationRequired,
                    onChanged: (value) =>
                        setState(() => _authenticationRequired = value),
                  ),
                  if (_authenticationRequired)
                    TRTextField(
                      key: const ValueKey<String>('provider-api-key'),
                      controller: _apiKey,
                      obscureText: true,
                      label: l10n.providerSettingsApiKey,
                    ),
                  TRTextField(
                    controller: _models,
                    label: l10n.providerSettingsManualModels,
                    // Demonstrates the comma-separated syntax with stand-in
                    // model IDs, which providers never localize.
                    placeholder: 'model-a, model-b',
                  ),
                  for (final control in _selectedWire.controls)
                    TinestCheckboxRow(
                      value: _controlIds.contains(control.id),
                      onChanged: (selected) => setState(() {
                        selected == true
                            ? _controlIds.add(control.id)
                            : _controlIds.remove(control.id);
                      }),
                      title: TRText.inherit(control.label),
                      subtitle: control.description == null
                          ? null
                          : TRText.inherit(control.description!),
                    ),
                ],
              ),
              if (widget.existing case final existing?)
                SettingsSection.form(
                  title: l10n.providerSettingsDefaultModelTitle,
                  children: <Widget>[
                    TRSelect<String?>.controlled(
                      key: const ValueKey<String>('provider-default-model'),
                      value: widget.state.defaultModel?.qualifiedModelId,
                      searchable: true,
                      searchPlaceholder: l10n.selectSearchPlaceholder,
                      noResultsText: l10n.selectNoResults,
                      // Explicit for the auditable adaptive Select contract.
                      // ignore: avoid_redundant_argument_values
                      surface: TRSelectSurface.auto,
                      items: <TRSelectItem<String?>>[
                        TRSelectItem<String?>(
                          value: null,
                          label: l10n.providerSettingsDefaultModelAutomatic,
                        ),
                        for (final model
                            in widget.state.models[existing.id] ??
                                const <ProviderModelDto>[])
                          TRSelectItem<String?>(
                            key: ValueKey<String>(
                              'provider-model-${model.id}',
                            ),
                            value: model.id,
                            label: model.label,
                            description:
                                '${existing.displayName} · ${model.id}',
                          ),
                      ],
                      onValueChange: (modelId) => unawaited(
                        _setDefault(
                          modelId == null
                              ? null
                              : SessionModelSelectionDto(modelId: modelId),
                        ),
                      ),
                    ),
                  ],
                ),
              if (widget.existing case final existing?)
                SettingsSection(
                  title: l10n.providerSettingsActions,
                  children: <Widget>[
                    SettingsRow(
                      title: TRText.inherit(
                        l10n.providerSettingsDisconnectBody(
                          existing.displayName,
                        ),
                      ),
                      control: TRButton(
                        key: const ValueKey<String>(
                          'provider-custom-disconnect',
                        ),
                        appearance: TRAppearance.ghost,
                        intent: TRIntent.danger,
                        onPressed: _busy ? null : _disconnect,
                        child: TRText.inherit(
                          l10n.providerSettingsDisconnect,
                        ),
                      ),
                    ),
                    SettingsRow(
                      title: TRText.inherit(
                        l10n.providerSettingsDeleteCustomBody(
                          existing.displayName,
                        ),
                      ),
                      control: TRButton(
                        key: const ValueKey<String>(
                          'provider-custom-delete',
                        ),
                        appearance: TRAppearance.ghost,
                        intent: TRIntent.danger,
                        onPressed: _busy ? null : _delete,
                        child: TRText.inherit(l10n.commonDelete),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  ProviderWireFormatDto get _selectedWire =>
      widget.state.catalog.wireFormats.firstWhere(
        (format) => format.id == _wireFormatId,
        orElse: () => const ProviderWireFormatDto(id: '', label: ''),
      );

  String _suggestCustomPrefix() {
    final used = widget.state.connections
        .map((connection) => connection.modelPrefix)
        .toSet();
    var candidate = 'custom';
    var suffix = 2;
    while (used.contains(candidate)) {
      candidate = 'custom-$suffix';
      suffix += 1;
    }
    return candidate;
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final name = _name.text.trim();
    final baseUrl = _baseUrl.text.trim();
    final apiKey = _apiKey.text.trim();
    if (name.isEmpty || baseUrl.isEmpty) {
      setState(() => _error = l10n.providerSettingsRequiredFields);
      return;
    }
    if (_authenticationRequired && widget.existing == null && apiKey.isEmpty) {
      setState(() => _error = l10n.providerSettingsApiKeyRequired);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final config = CustomProviderConfigDto(
      name: name,
      baseUrl: baseUrl,
      wireFormatId: _wireFormatId,
      authenticationRequired: _authenticationRequired,
      models: <ManualProviderModelDto>[
        for (final id
            in _models.text
                .split(',')
                .map((value) => value.trim())
                .where((value) => value.isNotEmpty)
                .toSet())
          ManualProviderModelDto(
            id: id,
            label: id,
            controls: <ModelControlDescriptorDto>[
              for (final control in _selectedWire.controls)
                if (_controlIds.contains(control.id)) control,
            ],
          ),
      ],
    );
    final notifier = ref.read(
      providerSettingsControllerProvider(widget.hostId).notifier,
    );
    try {
      late final ProviderConnectionDto saved;
      if (widget.existing case final existing?) {
        if (_prefix.text.trim() != existing.modelPrefix) {
          await notifier.updateModelPrefix(
            existing.id,
            _prefix.text.trim(),
          );
        }
        saved = await notifier.updateCustom(
          existing.id,
          config,
          apiKey: apiKey.isEmpty ? null : apiKey,
        );
      } else {
        saved = await notifier.createCustom(
          ref.read(appIdGeneratorProvider).generate(),
          config,
          apiKey: apiKey.isEmpty ? null : apiKey,
          modelPrefix: _prefix.text.trim(),
        );
      }
      widget.onSaved(saved);
    } on Object catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final connection = widget.existing!;
    final l10n = AppLocalizations.of(context);
    final confirmed = await showTRDialog<bool>(
      context: context,
      builder: (context) => TRAlertDialog(
        title: TRText.inherit(l10n.providerSettingsDeleteCustomTitle),
        content: TRText.inherit(
          l10n.providerSettingsDeleteCustomBody(connection.displayName),
        ),
        actions: <TRButton>[
          TRButton(
            appearance: TRAppearance.ghost,
            onPressed: () => Navigator.pop(context, false),
            child: TRText.inherit(l10n.commonCancel),
          ),
          TRButton(
            intent: TRIntent.danger,
            onPressed: () => Navigator.pop(context, true),
            child: TRText.inherit(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final deleted = await ref
        .read(toastMessengerProvider)
        .run(
          () => ref
              .read(providerSettingsControllerProvider(widget.hostId).notifier)
              .deleteCustom(connection.id),
          failure: l10n.providerSettingsDeleteFailed,
          success: l10n.commonDeleted,
          id: 'provider-delete',
        );
    if (deleted) widget.onRemoved?.call();
  }

  /// Stores [model] as the default, reporting a refusal.
  ///
  /// The row that triggers this ignores the future it returns, so without a
  /// report a rejected write left the previous default selected and
  /// unexplained.
  Future<void> _setDefault(SessionModelSelectionDto? model) async {
    final l10n = AppLocalizations.of(context);
    await ref
        .read(toastMessengerProvider)
        .run(
          () => ref
              .read(providerSettingsControllerProvider(widget.hostId).notifier)
              .setDefaultModel(model),
          failure: l10n.providerSettingsDefaultModelFailed,
          id: 'provider-default-model',
        );
  }

  Future<void> _disconnect() async {
    final connection = widget.existing!;
    final l10n = AppLocalizations.of(context);
    final confirmed = await showTRDialog<bool>(
      context: context,
      builder: (context) => TRAlertDialog(
        title: TRText.inherit(l10n.providerSettingsDisconnectTitle),
        content: TRText.inherit(
          l10n.providerSettingsDisconnectBody(connection.displayName),
        ),
        actions: <TRButton>[
          TRButton(
            appearance: TRAppearance.ghost,
            onPressed: () => Navigator.pop(context, false),
            child: TRText.inherit(l10n.commonCancel),
          ),
          TRButton(
            intent: TRIntent.danger,
            onPressed: () => Navigator.pop(context, true),
            child: TRText.inherit(l10n.providerSettingsDisconnect),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final disconnected = await ref
        .read(toastMessengerProvider)
        .run(
          () => ref
              .read(providerSettingsControllerProvider(widget.hostId).notifier)
              .disconnect(connection.id),
          failure: l10n.providerSettingsDisconnectFailed,
          success: l10n.providerSettingsDisconnected,
          id: 'provider-disconnect',
        );
    if (disconnected) widget.onRemoved?.call();
  }
}

IconData _statusIcon(ProviderConnectionStatus status) => switch (status) {
  ProviderConnectionStatus.connected => TinestIcons.status,
  ProviderConnectionStatus.connecting => TinestIcons.refresh,
  ProviderConnectionStatus.degraded ||
  ProviderConnectionStatus.reauthRequired => TinestIcons.warning,
  ProviderConnectionStatus.error => TinestIcons.error,
  ProviderConnectionStatus.disconnected => TinestIcons.stop,
};

String _statusLabel(
  AppLocalizations l10n,
  ProviderConnectionStatus status,
) => switch (status) {
  ProviderConnectionStatus.connecting => l10n.providerStatusConnecting,
  ProviderConnectionStatus.connected => l10n.providerStatusConnected,
  ProviderConnectionStatus.degraded => l10n.providerStatusDegraded,
  ProviderConnectionStatus.error => l10n.providerStatusError,
  ProviderConnectionStatus.reauthRequired => l10n.providerStatusReauthRequired,
  ProviderConnectionStatus.disconnected => l10n.providerStatusDisconnected,
};

String _catalogLabel(
  AppLocalizations l10n,
  ProviderCatalogFreshness freshness,
) => switch (freshness) {
  ProviderCatalogFreshness.bundled => l10n.providerSettingsCatalogBundled,
  ProviderCatalogFreshness.cached => l10n.providerSettingsCatalogCached,
  ProviderCatalogFreshness.fresh => l10n.providerSettingsCatalogFresh,
  ProviderCatalogFreshness.stale => l10n.providerSettingsCatalogStale,
};

String _authStatusLabel(
  AppLocalizations l10n,
  ProviderAuthAttemptStatus status,
) => switch (status) {
  ProviderAuthAttemptStatus.pending ||
  ProviderAuthAttemptStatus.awaitingUser => l10n.providerSettingsOAuthPending,
  ProviderAuthAttemptStatus.exchanging => l10n.providerStatusConnecting,
  ProviderAuthAttemptStatus.succeeded => l10n.providerStatusConnected,
  ProviderAuthAttemptStatus.failed ||
  ProviderAuthAttemptStatus.expired => l10n.providerStatusError,
  ProviderAuthAttemptStatus.cancelled => l10n.providerStatusDisconnected,
};
