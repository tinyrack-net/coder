import 'dart:async';

import 'package:coder_app/l10n/gen/app_localizations.dart';
import 'package:coder_app/src/app/composition/app_providers.dart';
import 'package:coder_app/src/app/platform/external_url_opener.dart';
import 'package:coder_app/src/features/providers/application/model_picker_options.dart';
import 'package:coder_app/src/features/providers/application/provider_settings_controller.dart';
import 'package:coder_app/src/features/providers/application/session_model_options.dart';
import 'package:coder_app/src/shared/presentation/coder_icons.dart';
import 'package:coder_app/src/shared/presentation/coder_list_row.dart';
import 'package:coder_app/src/shared/presentation/coder_page_shell.dart';
import 'package:coder_app/src/shared/presentation/coder_selection_row.dart';
import 'package:coder_app/src/shared/presentation/model_picker.dart';
import 'package:coder_app/src/shared/presentation/settings_layout.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

/// Provider connection settings for one daemon host.
class SettingsPage extends ConsumerStatefulWidget {
  /// Creates a provider connection settings page.
  const SettingsPage({
    required this.hostId,
    this.embedded = false,
    super.key,
  });

  /// Route host identifier.
  final String hostId;

  /// Whether the unified settings shell supplies navigation chrome.
  final bool embedded;

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  Object? _catalogRefreshError;
  bool _refreshingCatalog = false;

  ProviderSettingsControllerProvider get _provider =>
      providerSettingsControllerProvider(widget.hostId);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final asyncState = ref.watch(_provider);
    final body = SettingsAsyncContent<ProviderSettingsState?>(
      state: asyncState,
      loading: SettingsSkeletonLayout.form(
        semanticLabel: l10n.settingsLoading,
      ),
      error: (error, stackTrace) => Center(child: TRText.inherit('$error')),
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
    final activeConnections = state.connections
        .where(
          (connection) =>
              connection.status != ProviderConnectionStatus.disconnected,
        )
        .toList(growable: false);
    return Column(
      children: <Widget>[
        Expanded(
          child: SettingsScaffold(
            children: <Widget>[
              _DefaultModel(
                selection: state.defaultModel,
                connections: state.connections,
                models: state.models,
                onChoose: () => unawaited(_chooseDefaultModel()),
              ),
              _ConnectedProviders(
                connections: activeConnections,
                onDisconnect: _disconnect,
                onEditCustom: _editCustom,
                onDeleteCustom: _deleteCustom,
              ),
              _ProviderCatalog(
                definitions: state.catalog.definitions
                    .where(
                      (definition) => !activeConnections.any(
                        (connection) =>
                            connection.definitionId == definition.id,
                      ),
                    )
                    .toList(growable: false),
                onAdd: _addDefinition,
                onAddCustom: _addCustom,
                // Refreshing the catalog is what fills this section, so the
                // control belongs to it rather than floating above the page.
                onRefresh: _refreshingCatalog
                    ? null
                    : () => unawaited(_refreshCatalog()),
                refreshError: _catalogRefreshError,
              ),
            ],
          ),
        ),
        for (final attempt in state.authAttempts.values)
          if (attempt.status == ProviderAuthAttemptStatus.awaitingUser ||
              attempt.status == ProviderAuthAttemptStatus.exchanging)
            _AuthAttemptBar(
              attempt: attempt,
              onCancel: () =>
                  ref.read(_provider.notifier).cancelAuth(attempt.id),
            ),
        for (final attempt in state.authAttempts.values)
          if (attempt.status == ProviderAuthAttemptStatus.failed ||
              attempt.status == ProviderAuthAttemptStatus.expired)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: TRSpacing.extraLarge,
              ),
              child: SettingsRow(
                key: ValueKey<String>('provider-auth-error-${attempt.id}'),
                leading: const Icon(CoderIcons.warning),
                title: TRText.inherit(attempt.error ?? attempt.status.name),
              ),
            ),
      ],
    );
  }

  Future<void> _chooseDefaultModel() async {
    final l10n = AppLocalizations.of(context);
    final chosen = await showModelPicker(
      context,
      loadOptions: () => loadModelPickerOptions(ref, widget.hostId),
      currentSelection: ref.read(_provider).value?.defaultModel,
      title: l10n.providerSettingsDefaultModelTitle,
      inheritLabel: l10n.providerSettingsDefaultModelAutomatic,
    );
    if (chosen == null) return;
    final notifier = ref.read(_provider.notifier);
    switch (chosen) {
      case SelectedModelPickerChoice(:final selection):
        await notifier.setDefaultModel(selection);
      case InheritModelPickerChoice():
        await notifier.setDefaultModel(null);
    }
  }

  Future<void> _refreshCatalog() async {
    setState(() {
      _refreshingCatalog = true;
      _catalogRefreshError = null;
    });
    try {
      await ref.read(_provider.notifier).refreshCatalog();
    } on Object catch (error) {
      if (mounted) setState(() => _catalogRefreshError = error);
    } finally {
      if (mounted) setState(() => _refreshingCatalog = false);
    }
  }

  Future<void> _addDefinition(ProviderDefinitionDto definition) async {
    // A definition with one way in connects directly; several raise a choice.
    // The methods themselves come from the catalog, so this page never has to
    // know which vendor offers what.
    if (definition.authMethods.length > 1) {
      await _showAuthMethods(definition);
      return;
    }
    final method = definition.authMethods.single;
    await _connectWith(definition, method);
  }

  Future<void> _connectWith(
    ProviderDefinitionDto definition,
    ProviderAuthMethodDto method,
  ) async {
    switch (method.flow) {
      case ProviderAuthFlow.none:
        await ref.read(_provider.notifier).connectNone(definition.id);
      case ProviderAuthFlow.apiKey:
        await _showApiKey(definition);
      case ProviderAuthFlow.oauthBrowser:
      case ProviderAuthFlow.oauthDevice:
        final attempt = await ref
            .read(_provider.notifier)
            .startAuth(definition.id, method.id);
        final authorizationUrl = attempt.authorizationUrl;
        if (method.flow == ProviderAuthFlow.oauthBrowser &&
            authorizationUrl != null) {
          await ref
              .read(externalUrlOpenerProvider)
              .open(Uri.parse(authorizationUrl));
        }
    }
  }

  Future<void> _showAuthMethods(ProviderDefinitionDto definition) async {
    final method = await showTRDrawer<ProviderAuthMethodDto>(
      context: context,
      builder: (context) => TRDrawer(
        title: TRText.inherit(
          AppLocalizations.of(
            context,
          ).providerSettingsAuthTitle(definition.name),
        ),
        description: TRText.inherit(definition.description),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            for (final method in definition.authMethods)
              CoderListRow(
                key: ValueKey('provider-auth-${method.id}'),
                leading: Icon(
                  method.kind == ProviderAuthKind.oauth
                      ? CoderIcons.user
                      : CoderIcons.key,
                ),
                title: TRText.inherit(method.label),
                subtitle: method.experimental
                    ? TRText(
                        AppLocalizations.of(
                          context,
                        ).providerSettingsExperimental,
                      )
                    : TRText(definition.name),
                onTap: () => Navigator.pop(context, method),
              ),
          ],
        ),
      ),
    );
    if (!mounted || method == null) return;
    await _connectWith(definition, method);
  }

  Future<void> _showApiKey(ProviderDefinitionDto definition) async {
    final apiKey = await showTRDialog<String>(
      context: context,
      builder: (context) => _ApiKeyDialog(providerName: definition.name),
    );
    if (apiKey == null || apiKey.isEmpty) return;
    await ref.read(_provider.notifier).connectApiKey(definition.id, apiKey);
  }

  Future<void> _addCustom() async {
    final wireFormats =
        ref.read(_provider).value?.catalog.wireFormats ??
        const <ProviderWireFormatDto>[];
    final draft = await showTRDialog<_CustomDraft>(
      context: context,
      builder: (context) => _CustomProviderDialog(wireFormats: wireFormats),
    );
    if (draft == null) return;
    final connection = await ref
        .read(_provider.notifier)
        .createCustom(
          ref.read(appIdGeneratorProvider).generate(),
          draft.config,
          apiKey: draft.apiKey,
        );
    await ref.read(_provider.notifier).loadModels(connection.id);
    final models = ref.read(_provider).value?.models[connection.id];
    if (!mounted || models == null || models.isNotEmpty) return;
    final manualModels = await showTRDialog<List<String>>(
      context: context,
      builder: (context) => const _ManualModelsDialog(),
    );
    if (!mounted || manualModels == null || manualModels.isEmpty) return;
    await ref
        .read(_provider.notifier)
        .updateCustom(
          connection.id,
          draft.config.copyWith(manualModelIds: manualModels),
        );
  }

  Future<void> _editCustom(ProviderConnectionDto connection) async {
    final wireFormats =
        ref.read(_provider).value?.catalog.wireFormats ??
        const <ProviderWireFormatDto>[];
    final draft = await showTRDialog<_CustomDraft>(
      context: context,
      builder: (context) => _CustomProviderDialog(
        initial: connection.customConfig,
        wireFormats: wireFormats,
      ),
    );
    if (draft == null) return;
    await ref
        .read(_provider.notifier)
        .updateCustom(connection.id, draft.config, apiKey: draft.apiKey);
  }

  Future<void> _deleteCustom(ProviderConnectionDto connection) async {
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
    await ref.read(_provider.notifier).deleteCustom(connection.id);
  }

  Future<void> _disconnect(ProviderConnectionDto connection) async {
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
    await ref.read(_provider.notifier).disconnect(connection.id);
  }
}

/// Daemon-wide default model used when nothing more specific applies.
class _DefaultModel extends StatelessWidget {
  const _DefaultModel({
    required this.selection,
    required this.connections,
    required this.models,
    required this.onChoose,
  });

  final SessionModelSelectionDto? selection;
  final List<ProviderConnectionDto> connections;
  final Map<String, List<ProviderModelDto>> models;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final stored = selection;
    final stale =
        stored != null && !isRunnableSelection(stored, connections, models);
    final shown = stale
        ? null
        : stored ?? firstUsableModel(connections, models);
    return SettingsSection(
      key: const ValueKey('provider-settings-default-model'),
      title: l10n.providerSettingsDefaultModelTitle,
      children: <Widget>[
        SettingsRow(
          key: const ValueKey('provider-default-model-row'),
          title: TRText.inherit(
            stored == null
                ? l10n.providerSettingsDefaultModelAutomatic
                : _label(stored),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          description: stale
              ? TRText(
                  l10n.providerSettingsDefaultModelUnavailable,
                  key: const ValueKey('provider-default-model-stale'),
                  color: TRTextColor.danger,
                  maxLines: 1,
                  truncate: true,
                )
              : TRText.inherit(
                  stored != null
                      ? l10n.providerSettingsDefaultModelDescription
                      : shown == null
                      ? l10n.providerSettingsDefaultModelNone
                      : _label(shown),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
          control: TRButton(
            key: const ValueKey('provider-default-model-choose'),
            appearance: TRAppearance.outline,
            onPressed: onChoose,
            child: TRText.inherit(l10n.providerSettingsDefaultModelChoose),
          ),
        ),
      ],
    );
  }

  /// Renders "Provider · Model", falling back to raw ids when unresolvable.
  String _label(SessionModelSelectionDto model) {
    final connection = connections
        .where((item) => item.id == model.providerConnectionId)
        .firstOrNull;
    final label =
        (models[model.providerConnectionId] ?? const <ProviderModelDto>[])
            .where((item) => item.id == model.modelId)
            .firstOrNull
            ?.label;
    return '${connection?.displayName ?? model.providerConnectionId}'
        ' · ${label ?? model.modelId}';
  }
}

class _ConnectedProviders extends StatelessWidget {
  const _ConnectedProviders({
    required this.connections,
    required this.onDisconnect,
    required this.onEditCustom,
    required this.onDeleteCustom,
  });

  final List<ProviderConnectionDto> connections;
  final ValueChanged<ProviderConnectionDto> onDisconnect;
  final ValueChanged<ProviderConnectionDto> onEditCustom;
  final ValueChanged<ProviderConnectionDto> onDeleteCustom;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SettingsSection(
      key: const ValueKey('provider-settings-connected'),
      title: l10n.providerSettingsConnected,
      children: <Widget>[
        if (connections.isEmpty)
          SettingsRow(
            title: TRText.inherit(l10n.providerSettingsNoConnections),
          ),
        for (final connection in connections)
          _ProviderConnectionRow(
            connection: connection,
            onDisconnect: onDisconnect,
            onEditCustom: onEditCustom,
            onDeleteCustom: onDeleteCustom,
          ),
      ],
    );
  }
}

class _ProviderConnectionRow extends StatelessWidget {
  const _ProviderConnectionRow({
    required this.connection,
    required this.onDisconnect,
    required this.onEditCustom,
    required this.onDeleteCustom,
  });

  final ProviderConnectionDto connection;
  final ValueChanged<ProviderConnectionDto> onDisconnect;
  final ValueChanged<ProviderConnectionDto> onEditCustom;
  final ValueChanged<ProviderConnectionDto> onDeleteCustom;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final error = connection.error;
    return SettingsRow(
      title: TRText.inherit(connection.displayName, truncate: true),
      // The status line and the failure reason are separate facts, so the
      // reason keeps its own line and its own colour rather than being
      // concatenated into the status string.
      description: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TRText.inherit(
            '${_statusLabel(l10n, connection.status)} · '
            '${_authLabel(l10n, connection.credentialOrigin)}',
          ),
          if (error != null) TRText(error, color: TRTextColor.danger),
        ],
      ),
      wrapsDescription: error != null,
      control: TRMenu.icon(
        key: ValueKey<String>(
          'provider-actions-${connection.definitionId}',
        ),
        icon: const Icon(CoderIcons.more),
        label: l10n.providerSettingsActions,
        menuChildren: <Widget>[
          if (connection.customConfig != null)
            TRMenuItem(
              onPressed: () => onEditCustom(connection),
              child: TRText.inherit(l10n.providerSettingsEditAdvanced),
            ),
          if (connection.customConfig != null)
            TRMenuItem(
              onPressed: () => onDeleteCustom(connection),
              child: TRText.inherit(l10n.commonDelete),
            ),
          TRMenuItem(
            onPressed: () => onDisconnect(connection),
            child: TRText.inherit(l10n.providerSettingsDisconnect),
          ),
        ],
      ),
    );
  }
}

class _ProviderCatalog extends StatelessWidget {
  const _ProviderCatalog({
    required this.definitions,
    required this.onAdd,
    required this.onAddCustom,
    required this.onRefresh,
    required this.refreshError,
  });

  final List<ProviderDefinitionDto> definitions;
  final ValueChanged<ProviderDefinitionDto> onAdd;
  final VoidCallback onAddCustom;
  final VoidCallback? onRefresh;
  final Object? refreshError;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SettingsSection(
      key: const ValueKey('provider-settings-add'),
      title: l10n.providerSettingsAdd,
      action: TRButton(
        key: const ValueKey<String>('provider-catalog-refresh'),
        appearance: TRAppearance.outline,
        onPressed: onRefresh,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(CoderIcons.refresh),
            const SizedBox(width: TRSpacing.extraSmall),
            TRText(l10n.providerSettingsRefreshCatalog),
          ],
        ),
      ),
      banner: refreshError == null
          ? null
          : TRAlert(
              key: const ValueKey<String>('provider-catalog-refresh-error'),
              title: TRText.inherit(l10n.providerSettingsRefreshFailed),
              description: TRText.inherit('$refreshError'),
              icon: const Icon(CoderIcons.error),
              variant: TRStatusVariant.danger,
            ),
      children: <Widget>[
        if (definitions.isEmpty)
          SettingsRow(title: TRText.inherit(l10n.providerSettingsNoPresets)),
        for (final definition in definitions)
          SettingsRow(
            key: ValueKey('provider-add-${definition.id}'),
            leading: const Icon(CoderIcons.network),
            title: TRText.inherit(definition.name),
            description: TRText.inherit(definition.description),
            control: const Icon(CoderIcons.addCircle),
            onTap: () => onAdd(definition),
          ),
        SettingsRow(
          key: const ValueKey('provider-add-custom'),
          leading: const Icon(CoderIcons.tune),
          title: TRText.inherit(l10n.providerSettingsCustomName),
          description: TRText.inherit(l10n.providerSettingsCustomSubtitle),
          control: const Icon(CoderIcons.chevronRight),
          onTap: onAddCustom,
        ),
      ],
    );
  }
}

class _AuthAttemptBar extends StatelessWidget {
  const _AuthAttemptBar({required this.attempt, required this.onCancel});

  final ProviderAuthAttemptDto attempt;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: TRSpacing.extraLarge),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: context.tinyrackTheme.surfaceSelected,
        borderRadius: const BorderRadius.all(TRRadii.medium),
      ),
      child: SettingsRow(
        leading: const TRSpinner(),
        title: TRText.inherit(
          AppLocalizations.of(context).providerSettingsOAuthPending,
        ),
        // The device code has to be copyable for the user to complete it.
        description: SelectionArea(
          child: TRText.inherit(
            <String?>[
              attempt.authorizationUrl,
              attempt.userCode,
            ].whereType<String>().join(' · '),
          ),
        ),
        control: TRButton(
          key: ValueKey<String>('provider-auth-cancel-${attempt.id}'),
          appearance: TRAppearance.ghost,
          onPressed: onCancel,
          child: TRText.inherit(AppLocalizations.of(context).commonCancel),
        ),
      ),
    ),
  );
}

class _ApiKeyDialog extends StatefulWidget {
  const _ApiKeyDialog({required this.providerName});

  final String providerName;

  @override
  State<_ApiKeyDialog> createState() => _ApiKeyDialogState();
}

class _ApiKeyDialogState extends State<_ApiKeyDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TRAlertDialog(
      title: TRText.inherit(
        l10n.providerSettingsConnectTitle(widget.providerName),
      ),
      content: SettingsDialogForm(
        children: <Widget>[
          TRTextField(
            key: const ValueKey('provider-api-key'),
            controller: _controller,
            obscureText: true,
            autofocus: true,
            label: 'API key',
          ),
        ],
      ),
      actions: <TRButton>[
        TRButton(
          appearance: TRAppearance.ghost,
          onPressed: () => Navigator.pop(context),
          child: TRText.inherit(l10n.commonCancel),
        ),
        TRButton(
          intent: TRIntent.primary,
          onPressed: () {
            final value = _controller.text.trim();
            if (value.isNotEmpty) Navigator.pop(context, value);
          },
          child: TRText.inherit(l10n.providerSettingsConnect),
        ),
      ],
    );
  }
}

final class _CustomDraft {
  const _CustomDraft({required this.config, this.apiKey});

  final CustomProviderConfigDto config;
  final String? apiKey;
}

class _CustomProviderDialog extends StatefulWidget {
  const _CustomProviderDialog({required this.wireFormats, this.initial});

  final CustomProviderConfigDto? initial;

  /// The wire protocols this daemon serves; the first one is the default.
  final List<ProviderWireFormatDto> wireFormats;

  @override
  State<_CustomProviderDialog> createState() => _CustomProviderDialogState();
}

class _CustomProviderDialogState extends State<_CustomProviderDialog> {
  late final TextEditingController _name;
  late final TextEditingController _baseUrl;
  late final TextEditingController _apiKey;
  late final TextEditingController _models;
  late String _wireFormatId;
  late bool _authenticationRequired;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _name = TextEditingController(text: initial?.name ?? 'Custom Provider');
    _baseUrl = TextEditingController(
      text: initial?.baseUrl ?? 'http://127.0.0.1:8080/v1',
    );
    _apiKey = TextEditingController();
    _models = TextEditingController(
      text: initial?.manualModelIds.join(', ') ?? '',
    );
    _wireFormatId =
        initial?.wireFormatId ?? widget.wireFormats.firstOrNull?.id ?? '';
    _authenticationRequired = initial?.authenticationRequired ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _baseUrl.dispose();
    _apiKey.dispose();
    _models.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TRAlertDialog(
      title: TRText.inherit(l10n.providerSettingsCustomTitle),
      content: SingleChildScrollView(
        child: SettingsDialogForm(
          children: <Widget>[
            TRTextField(
              controller: _name,
              label: l10n.commonName,
            ),
            TRTextField(
              controller: _baseUrl,
              label: 'Base URL',
            ),
            TRSelectFormField<String>(
              initialValue: _wireFormatId,
              label: l10n.providerSettingsApiFormat,
              width: TRMeasurements.overlayWidthMd,
              items: widget.wireFormats
                  .map(
                    (format) => TRSelectItem<String>(
                      value: format.id,
                      label: format.label,
                    ),
                  )
                  .toList(growable: false),
              onValueChange: (value) {
                if (value != null) setState(() => _wireFormatId = value);
              },
            ),
            CoderSwitchRow(
              flush: true,
              title: TRText.inherit(l10n.providerSettingsRequiresApiKey),
              value: _authenticationRequired,
              onChanged: (value) =>
                  setState(() => _authenticationRequired = value),
            ),
            if (_authenticationRequired)
              TRTextField(
                controller: _apiKey,
                obscureText: true,
                label: 'API key',
              ),
            if (widget.initial?.manualModelIds.isNotEmpty ?? false)
              TRTextField(
                controller: _models,
                label: l10n.providerSettingsManualModels,
                placeholder: 'model-a, model-b',
              ),
          ],
        ),
      ),
      actions: <TRButton>[
        TRButton(
          appearance: TRAppearance.ghost,
          onPressed: () => Navigator.pop(context),
          child: TRText.inherit(l10n.commonCancel),
        ),
        TRButton(
          intent: TRIntent.primary,
          onPressed: _submit,
          child: TRText.inherit(l10n.commonSave),
        ),
      ],
    );
  }

  void _submit() {
    final name = _name.text.trim();
    final baseUrl = _baseUrl.text.trim();
    if (name.isEmpty || baseUrl.isEmpty) return;
    final apiKey = _apiKey.text.trim();
    if (_authenticationRequired && widget.initial == null && apiKey.isEmpty) {
      return;
    }
    Navigator.pop(
      context,
      _CustomDraft(
        config: CustomProviderConfigDto(
          name: name,
          baseUrl: baseUrl,
          wireFormatId: _wireFormatId,
          authenticationRequired: _authenticationRequired,
          manualModelIds: _models.text
              .split(',')
              .map((value) => value.trim())
              .where((value) => value.isNotEmpty)
              .toSet()
              .toList(growable: false),
        ),
        apiKey: apiKey.isEmpty ? null : apiKey,
      ),
    );
  }
}

class _ManualModelsDialog extends StatefulWidget {
  const _ManualModelsDialog();

  @override
  State<_ManualModelsDialog> createState() => _ManualModelsDialogState();
}

class _ManualModelsDialogState extends State<_ManualModelsDialog> {
  final TextEditingController _models = TextEditingController();

  @override
  void dispose() {
    _models.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TRAlertDialog(
      title: TRText.inherit(l10n.providerSettingsModelLookupFailedTitle),
      content: SettingsDialogForm(
        children: <Widget>[
          TRText(l10n.providerSettingsModelLookupFailedBody),
          TRTextField(
            controller: _models,
            label: l10n.providerSettingsManualModels,
            placeholder: 'model-a, model-b',
          ),
        ],
      ),
      actions: <TRButton>[
        TRButton(
          appearance: TRAppearance.ghost,
          onPressed: () => Navigator.pop(context),
          child: TRText.inherit(l10n.providerSettingsLater),
        ),
        TRButton(
          intent: TRIntent.primary,
          onPressed: () {
            final models = _models.text
                .split(',')
                .map((value) => value.trim())
                .where((value) => value.isNotEmpty)
                .toSet()
                .toList(growable: false);
            if (models.isNotEmpty) Navigator.pop(context, models);
          },
          child: TRText.inherit(l10n.commonSave),
        ),
      ],
    );
  }
}

String _statusLabel(AppLocalizations l10n, ProviderConnectionStatus status) =>
    switch (status) {
      ProviderConnectionStatus.connecting => l10n.providerStatusConnecting,
      ProviderConnectionStatus.connected => l10n.providerStatusConnected,
      ProviderConnectionStatus.degraded => l10n.providerStatusDegraded,
      ProviderConnectionStatus.error => l10n.providerStatusError,
      ProviderConnectionStatus.reauthRequired =>
        l10n.providerStatusReauthRequired,
      ProviderConnectionStatus.disconnected => l10n.providerStatusDisconnected,
    };

String _authLabel(AppLocalizations l10n, ProviderCredentialOrigin origin) =>
    switch (origin) {
      ProviderCredentialOrigin.stored => l10n.providerAuthStored,
      ProviderCredentialOrigin.environment => 'Environment credential',
      ProviderCredentialOrigin.oauth => l10n.providerAuthOAuth,
      ProviderCredentialOrigin.none => l10n.providerAuthNone,
    };
