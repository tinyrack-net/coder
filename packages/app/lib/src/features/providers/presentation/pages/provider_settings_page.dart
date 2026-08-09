import 'dart:async';

import 'package:app/l10n/gen/app_localizations.dart';
import 'package:app/src/app/composition/app_providers.dart';
import 'package:app/src/app/platform/external_url_opener.dart';
import 'package:app/src/features/providers/application/provider_settings_controller.dart';
import 'package:app/src/shared/presentation/coder_icons.dart';
import 'package:app/src/shared/presentation/coder_layout_metrics.dart';
import 'package:app/src/shared/presentation/coder_page_shell.dart';
import 'package:app/src/shared/presentation/coder_selection_row.dart';
import 'package:app/src/shared/presentation/settings_layout.dart';
import 'package:client/client.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:protocol/protocol.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

/// Provider connection settings for one daemon host.
class SettingsPage extends ConsumerStatefulWidget {
  /// Creates a provider connection settings page.
  const SettingsPage({required this.hostId, this.embedded = false, super.key});

  /// Route host identifier.
  final String hostId;

  /// Whether the unified settings shell supplies navigation chrome.
  final bool embedded;

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

enum _ProviderPane { empty, catalog, preset, custom, connection }

class _SettingsPageState extends ConsumerState<SettingsPage> {
  String? _selectedId;
  String? _reauthConnectionId;
  ProviderDefinitionDto? _draftDefinition;
  _ProviderPane _pane = _ProviderPane.empty;

  ProviderSettingsControllerProvider get _provider =>
      providerSettingsControllerProvider(widget.hostId);

  @override
  void didUpdateWidget(SettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hostId != widget.hostId) _showList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final body = SettingsAsyncContent<ProviderSettingsState?>(
      state: ref.watch(_provider),
      loading: SettingsSkeletonLayout.listDetail(
        semanticLabel: l10n.settingsLoading,
      ),
      error: (error, _) => Center(child: TRText.inherit('$error')),
      data: (state) => state == null
          ? Center(child: TRText.inherit(l10n.providerSettingsRequiresDaemon))
          : _body(state),
    );
    if (widget.embedded) return body;
    return CoderPageShell(
      appBar: CoderPageHeader(
        leading: TRIconButton(
          appearance: TRAppearance.ghost,
          label: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: context.pop,
          icon: const Icon(CoderIcons.back),
        ),
        title: TRText.inherit(l10n.providerSettingsTitle),
      ),
      body: body,
    );
  }

  Widget _body(ProviderSettingsState state) {
    final selected = state.connections
        .where((connection) => connection.id == _selectedId)
        .firstOrNull;
    final reauthConnection = state.connections
        .where((connection) => connection.id == _reauthConnectionId)
        .firstOrNull;
    if (_pane == _ProviderPane.connection && selected == null) {
      _pane = _ProviderPane.empty;
      _selectedId = null;
    }
    final collection = _ProviderCollection(
      connections: state.connections,
      selectedId: _pane == _ProviderPane.connection ? _selectedId : null,
      onSelected: (id) => setState(() {
        _selectedId = id;
        _draftDefinition = null;
        _reauthConnectionId = null;
        _pane = _ProviderPane.connection;
      }),
      onAdd: () => setState(() {
        _selectedId = null;
        _draftDefinition = null;
        _reauthConnectionId = null;
        _pane = _ProviderPane.catalog;
      }),
    );
    final detail = switch (_pane) {
      _ProviderPane.empty => SettingsEmptyState(
        title: AppLocalizations.of(context).providerSettingsSelectConnection,
        icon: const Icon(CoderIcons.network),
      ),
      _ProviderPane.catalog => _ProviderCatalogPane(
        hostId: widget.hostId,
        state: state,
        onPreset: (definition) => setState(() {
          _draftDefinition = definition;
          _pane = _ProviderPane.preset;
        }),
        onCustom: () => setState(() => _pane = _ProviderPane.custom),
      ),
      _ProviderPane.preset => _PresetProviderPane(
        key: ValueKey<String>('provider-preset-${_draftDefinition!.id}'),
        hostId: widget.hostId,
        state: state,
        definition: _draftDefinition!,
        existing: reauthConnection,
        onCancel: reauthConnection == null
            ? () => setState(() => _pane = _ProviderPane.catalog)
            : () => _selectConnection(reauthConnection),
        onConnected: _selectConnection,
      ),
      _ProviderPane.custom => _CustomProviderPane(
        hostId: widget.hostId,
        state: state,
        onCancel: () => setState(() => _pane = _ProviderPane.catalog),
        onSaved: _selectConnection,
      ),
      _ProviderPane.connection =>
        selected!.customConfig == null
            ? _ProviderConnectionPane(
                key: ValueKey<String>('provider-detail-${selected.id}'),
                hostId: widget.hostId,
                state: state,
                connection: selected,
                onChanged: _selectConnection,
                onRemoved: _showList,
                onReauth: (definition) => setState(() {
                  _reauthConnectionId = selected.id;
                  _draftDefinition = definition;
                  _pane = _ProviderPane.preset;
                }),
              )
            : _CustomProviderPane(
                key: ValueKey<String>('provider-detail-${selected.id}'),
                hostId: widget.hostId,
                state: state,
                existing: selected,
                onCancel: _showList,
                onSaved: _selectConnection,
                onRemoved: _showList,
              ),
    };
    return SettingsListDetailLayout(
      key: const ValueKey<String>('provider-settings-list-detail'),
      collection: collection,
      detail: detail,
      detailVisible: _pane != _ProviderPane.empty,
      onBack: _showList,
    );
  }

  void _selectConnection(ProviderConnectionDto connection) => setState(() {
    _selectedId = connection.id;
    _draftDefinition = null;
    _reauthConnectionId = null;
    _pane = _ProviderPane.connection;
  });

  void _showList() => setState(() {
    _selectedId = null;
    _draftDefinition = null;
    _reauthConnectionId = null;
    _pane = _ProviderPane.empty;
  });
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
        SettingsPaneHeader.collection(
          title: l10n.providerSettingsConnected,
          subtitle: '${connections.length}',
          actions: <Widget>[
            TRIconButton(
              key: const ValueKey<String>('provider-add-button'),
              appearance: TRAppearance.ghost,
              label: l10n.providerSettingsAdd,
              onPressed: onAdd,
              icon: const Icon(CoderIcons.add),
            ),
          ],
        ),
        Expanded(
          child: SettingsCollectionList(
            children: <Widget>[
              if (connections.isEmpty)
                SettingsRow.collection(
                  key: const ValueKey<String>('provider-list-empty'),
                  title: TRText.inherit(l10n.providerSettingsNoConnections),
                ),
              for (final connection in connections)
                SettingsRow.collection(
                  key: ValueKey<String>('provider-connection-${connection.id}'),
                  selected: connection.id == selectedId,
                  leading: Icon(_statusIcon(connection.status)),
                  title: TRText.inherit(connection.displayName),
                  description: TRText.inherit(
                    '${connection.modelPrefix} · '
                    '${_statusLabel(l10n, connection.status)}',
                  ),
                  onTap: () => onSelected(connection.id),
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
        SettingsPaneHeader.detail(
          title: l10n.providerSettingsAdd,
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
                    SettingsRow(
                      key: ValueKey<String>('provider-add-${definition.id}'),
                      leading: const Icon(CoderIcons.network),
                      title: TRText.inherit(definition.name),
                      description: TRText.inherit(definition.description),
                      control: const Icon(CoderIcons.chevronRight),
                      onTap: () => widget.onPreset(definition),
                    ),
                  SettingsRow(
                    key: const ValueKey<String>('provider-add-custom'),
                    leading: const Icon(CoderIcons.tune),
                    title: TRText.inherit(l10n.providerSettingsCustomName),
                    description: TRText.inherit(
                      l10n.providerSettingsCustomSubtitle,
                    ),
                    control: const Icon(CoderIcons.chevronRight),
                    onTap: widget.onCustom,
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
        SettingsPaneHeader.detail(
          title: widget.existing == null
              ? l10n.providerSettingsConnectTitle(widget.definition.name)
              : widget.definition.name,
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
                      label: l10n.providerSettingsActions,
                      width: CoderLayoutMetrics.settingsContentMaxWidth,
                      items: <TRSelectItem<String>>[
                        for (final method in widget.definition.authMethods)
                          TRSelectItem<String>(
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
                      label: 'API key',
                      onChanged: (_) => setState(() => _error = null),
                    ),
                  if (_method.experimental)
                    TRAlert(
                      variant: TRStatusVariant.warning,
                      title: TRText.inherit(
                        l10n.providerSettingsExperimental,
                      ),
                    ),
                  if (_error case final error?)
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
        SettingsPaneHeader.detail(
          title: l10n.providerSettingsOAuthPending,
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
                banner: attempt.error == null
                    ? null
                    : TRAlert(
                        variant: TRStatusVariant.danger,
                        title: TRText.inherit(attempt.error!),
                      ),
                children: <Widget>[
                  if (attempt.instructions != null)
                    SettingsRow(
                      title: TRText.inherit(attempt.instructions!),
                    ),
                  if (attempt.authorizationUrl case final url?)
                    SettingsRow(
                      title: SelectionArea(child: TRText.inherit(url)),
                      control: Wrap(
                        spacing: TRSpacing.small,
                        children: <Widget>[
                          TRIconButton(
                            appearance: TRAppearance.ghost,
                            label: l10n.commonCopy,
                            onPressed: () => Clipboard.setData(
                              ClipboardData(text: url),
                            ),
                            icon: const Icon(CoderIcons.copy),
                          ),
                          TRIconButton(
                            key: const ValueKey<String>(
                              'provider-oauth-open-browser',
                            ),
                            appearance: TRAppearance.ghost,
                            label: l10n.providerSettingsOpenBrowser,
                            onPressed: () => _openUrl(url),
                            icon: const Icon(CoderIcons.network),
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
                        icon: const Icon(CoderIcons.copy),
                      ),
                    ),
                  if (_openError case final error?)
                    SettingsRow(
                      leading: const Icon(CoderIcons.warning),
                      title: TRText('$error', color: TRTextColor.danger),
                    ),
                ],
              ),
            ],
          ),
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
      return _error is CoderClientException &&
              (_error! as CoderClientException).code == 'model_prefix_conflict'
          ? l10n.providerSettingsModelPrefixConflict
          : null;
    }
    return l10n.providerSettingsModelPrefixInvalid;
  }

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
          if (error is CoderClientException &&
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
    try {
      final opened = await ref
          .read(externalUrlOpenerProvider)
          .open(Uri.parse(value));
      if (!opened) throw StateError('Unable to open authorization URL.');
      if (mounted) setState(() => _openError = null);
    } on Object catch (error) {
      if (mounted) setState(() => _openError = error);
    }
  }

  void _handleConnection(ProviderConnectionDto connection) {
    if (connection.status == ProviderConnectionStatus.error) {
      setState(() {
        _retryConnectionId = connection.id;
        _error = connection.error ?? 'Provider connection failed.';
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
  bool _loadingModels = false;
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
        SettingsPaneHeader.detail(
          title: widget.connection.displayName,
          subtitle: _statusLabel(l10n, widget.connection.status),
          actions: <Widget>[
            if (definition != null)
              TRButton(
                appearance: TRAppearance.outline,
                onPressed: () => widget.onReauth(definition),
                child: TRText.inherit(l10n.providerSettingsReconnect),
              ),
            TRButton(
              appearance: TRAppearance.ghost,
              onPressed: _disconnect,
              child: TRText.inherit(l10n.providerSettingsDisconnect),
            ),
          ],
        ),
        Expanded(
          child: SettingsScaffold(
            children: <Widget>[
              SettingsSection.form(
                title: l10n.providerSettingsModelPrefix,
                banner: _error == null
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
                  ),
                  TRButton(
                    onPressed: _savePrefix,
                    child: TRText.inherit(l10n.commonSave),
                  ),
                ],
              ),
              SettingsSection(
                title: l10n.providerSettingsDefaultModelTitle,
                action: _loadingModels
                    ? null
                    : TRButton(
                        appearance: TRAppearance.outline,
                        onPressed: _loadModels,
                        child: TRText.inherit(l10n.commonRetry),
                      ),
                children: <Widget>[
                  SettingsRow(
                    selected: widget.state.defaultModel == null,
                    title: TRText.inherit(
                      l10n.providerSettingsDefaultModelAutomatic,
                    ),
                    onTap: () => ref
                        .read(
                          providerSettingsControllerProvider(
                            widget.hostId,
                          ).notifier,
                        )
                        .setDefaultModel(null),
                  ),
                  for (final model in models)
                    SettingsRow(
                      key: ValueKey<String>('provider-model-${model.id}'),
                      selected:
                          widget.state.defaultModel?.qualifiedModelId ==
                          model.id,
                      title: TRText.inherit(model.label),
                      description: TRText.inherit(model.id),
                      onTap: () => ref
                          .read(
                            providerSettingsControllerProvider(
                              widget.hostId,
                            ).notifier,
                          )
                          .setDefaultModel(
                            SessionModelSelectionDto(
                              modelId: model.id,
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
    setState(() {
      _loadingModels = true;
      _error = null;
    });
    try {
      await ref
          .read(
            providerSettingsControllerProvider(widget.hostId).notifier,
          )
          .loadModels(widget.connection.id);
    } on Object catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loadingModels = false);
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
            intent: TRIntent.primary,
            onPressed: () => Navigator.pop(context, true),
            child: TRText.inherit(l10n.providerSettingsDisconnect),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref
        .read(providerSettingsControllerProvider(widget.hostId).notifier)
        .disconnect(widget.connection.id);
    widget.onRemoved();
  }
}

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
  Object? _error;

  @override
  void initState() {
    super.initState();
    final connection = widget.existing;
    final initial = connection?.customConfig;
    _name = TextEditingController(text: initial?.name ?? 'Custom Provider');
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
        SettingsPaneHeader.detail(
          title: widget.existing == null
              ? l10n.providerSettingsCustomTitle
              : widget.existing!.displayName,
          actions: <Widget>[
            TRButton(
              appearance: TRAppearance.ghost,
              onPressed: _busy ? null : widget.onCancel,
              child: TRText.inherit(l10n.commonCancel),
            ),
            if (widget.existing != null)
              TRButton(
                appearance: TRAppearance.ghost,
                onPressed: _busy ? null : _disconnect,
                child: TRText.inherit(l10n.providerSettingsDisconnect),
              ),
            if (widget.existing != null)
              TRButton(
                key: const ValueKey<String>('provider-custom-delete'),
                appearance: TRAppearance.ghost,
                onPressed: _busy ? null : _delete,
                child: TRText.inherit(l10n.commonDelete),
              ),
            TRButton(
              key: const ValueKey<String>('provider-custom-save'),
              intent: TRIntent.primary,
              onPressed: _busy ? null : _save,
              child: TRText.inherit(
                _busy ? l10n.commonSaving : l10n.commonSave,
              ),
            ),
          ],
        ),
        Expanded(
          child: SettingsScaffold(
            children: <Widget>[
              SettingsSection.form(
                title: l10n.providerSettingsCustomTitle,
                banner: _error == null
                    ? null
                    : TRAlert(
                        variant: TRStatusVariant.danger,
                        title: TRText.inherit('$_error'),
                      ),
                children: <Widget>[
                  TRTextField(controller: _name, label: l10n.commonName),
                  TRTextField(controller: _baseUrl, label: 'Base URL'),
                  TRTextField(
                    key: const ValueKey<String>('provider-model-prefix'),
                    controller: _prefix,
                    label: l10n.providerSettingsModelPrefix,
                    helperText: l10n.providerSettingsModelPrefixHelp,
                  ),
                  TRSelectFormField<String>(
                    initialValue: _wireFormatId,
                    label: l10n.providerSettingsApiFormat,
                    width: CoderLayoutMetrics.settingsContentMaxWidth,
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
                  CoderSwitchRow(
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
                      label: 'API key',
                    ),
                  TRTextField(
                    controller: _models,
                    label: l10n.providerSettingsManualModels,
                    placeholder: 'model-a, model-b',
                  ),
                  for (final control in _selectedWire.controls)
                    CoderCheckboxRow(
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
                SettingsSection(
                  title: l10n.providerSettingsDefaultModelTitle,
                  children: <Widget>[
                    SettingsRow(
                      selected: widget.state.defaultModel == null,
                      title: TRText.inherit(
                        l10n.providerSettingsDefaultModelAutomatic,
                      ),
                      onTap: () => _setDefault(null),
                    ),
                    for (final model
                        in widget.state.models[existing.id] ??
                            const <ProviderModelDto>[])
                      SettingsRow(
                        key: ValueKey<String>('provider-model-${model.id}'),
                        selected:
                            widget.state.defaultModel?.qualifiedModelId ==
                            model.id,
                        title: TRText.inherit(model.label),
                        description: TRText.inherit(model.id),
                        onTap: () => _setDefault(
                          SessionModelSelectionDto(modelId: model.id),
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
            intent: TRIntent.primary,
            onPressed: () => Navigator.pop(context, true),
            child: TRText.inherit(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref
        .read(providerSettingsControllerProvider(widget.hostId).notifier)
        .deleteCustom(connection.id);
    widget.onRemoved?.call();
  }

  Future<void> _setDefault(SessionModelSelectionDto? model) => ref
      .read(providerSettingsControllerProvider(widget.hostId).notifier)
      .setDefaultModel(model);

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
            intent: TRIntent.primary,
            onPressed: () => Navigator.pop(context, true),
            child: TRText.inherit(l10n.providerSettingsDisconnect),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref
        .read(providerSettingsControllerProvider(widget.hostId).notifier)
        .disconnect(connection.id);
    widget.onRemoved?.call();
  }
}

IconData _statusIcon(ProviderConnectionStatus status) => switch (status) {
  ProviderConnectionStatus.connected => CoderIcons.status,
  ProviderConnectionStatus.connecting => CoderIcons.refresh,
  ProviderConnectionStatus.degraded ||
  ProviderConnectionStatus.reauthRequired => CoderIcons.warning,
  ProviderConnectionStatus.error => CoderIcons.error,
  ProviderConnectionStatus.disconnected => CoderIcons.stop,
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
