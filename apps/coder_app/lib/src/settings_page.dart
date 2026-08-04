import 'dart:async';

import 'package:coder_app/l10n/gen/app_localizations.dart';
import 'package:coder_app/src/coder_icons.dart';
import 'package:coder_app/src/coder_list_row.dart';
import 'package:coder_app/src/coder_page_shell.dart';
import 'package:coder_app/src/coder_selection_row.dart';
import 'package:coder_app/src/controller.dart';
import 'package:coder_app/src/external_url_opener.dart';
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
  ProviderSettingsControllerProvider get _provider =>
      providerSettingsControllerProvider(widget.hostId);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final asyncState = ref.watch(_provider);
    final body = asyncState.when(
      loading: () => const Center(child: TRSpinner(uiSize: TRUiSize.sm)),
      error: (error, stackTrace) => Center(child: Text('$error')),
      data: (state) => state == null
          ? Center(child: Text(l10n.providerSettingsRequiresDaemon))
          : _body(state),
    );
    if (widget.embedded) return body;
    return CoderPageShell(
      appBar: CoderPageHeader(
        leading: TRIconButton(
          appearance: TRAppearance.ghost,
          uiSize: TRUiSize.sm,
          label: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: context.pop,
          icon: const Icon(CoderIcons.back),
        ),
        title: Text(l10n.providerSettingsTitle),
        actions: <Widget>[
          TRIconButton(
            appearance: TRAppearance.ghost,
            uiSize: TRUiSize.sm,
            label: l10n.providerSettingsRefreshCatalog,
            onPressed: asyncState.asData?.value == null
                ? null
                : () => ref.read(_provider.notifier).refreshCatalog(),
            icon: const Icon(CoderIcons.refresh),
          ),
        ],
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
    final connected = _ConnectedProviders(
      connections: activeConnections,
      onDisconnect: _disconnect,
      onEditCustom: _editCustom,
    );
    final catalog = _ProviderCatalog(
      definitions: state.catalog.definitions
          .where(
            (definition) => !activeConnections.any(
              (connection) => connection.definitionId == definition.id,
            ),
          )
          .toList(growable: false),
      onAdd: _addDefinition,
      onAddCustom: _addCustom,
    );
    return Column(
      children: <Widget>[
        Expanded(
          child: CustomScrollView(
            slivers: <Widget>[
              SliverToBoxAdapter(child: connected),
              const SliverToBoxAdapter(child: TRSeparator()),
              SliverToBoxAdapter(child: catalog),
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
      ],
    );
  }

  Future<void> _addDefinition(ProviderDefinitionDto definition) async {
    if (definition.id == 'openai') {
      await _showOpenAIAuth(definition);
      return;
    }
    final method = definition.authMethods.single;
    if (method.flow == ProviderAuthFlow.none) {
      await ref.read(_provider.notifier).connectNone(definition.id);
      return;
    }
    await _showApiKey(definition);
  }

  Future<void> _showOpenAIAuth(ProviderDefinitionDto definition) async {
    final methodId = await showTRDrawer<String>(
      context: context,
      builder: (context) => TRDrawer(
        title: Text(
          AppLocalizations.of(context).providerSettingsOpenAiTitle,
        ),
        description: Text(
          AppLocalizations.of(context).providerSettingsOpenAiSubtitle,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            for (final method in definition.authMethods)
              CoderListRow(
                key: ValueKey('openai-auth-${method.id}'),
                leading: Icon(
                  method.kind == ProviderAuthKind.oauth
                      ? CoderIcons.user
                      : CoderIcons.key,
                ),
                title: Text(method.label),
                subtitle: method.experimental
                    ? Text(
                        AppLocalizations.of(
                          context,
                        ).providerSettingsExperimental,
                      )
                    : const Text('OpenAI Platform'),
                onTap: () => Navigator.pop(context, method.id),
              ),
          ],
        ),
      ),
    );
    if (!mounted || methodId == null) return;
    if (methodId == 'api-key') {
      await _showApiKey(definition);
      return;
    }
    final attempt = await ref
        .read(_provider.notifier)
        .startAuth(definition.id, methodId);
    final authorizationUrl = attempt.authorizationUrl;
    if (methodId == 'chatgpt-browser' && authorizationUrl != null) {
      await ref
          .read(externalUrlOpenerProvider)
          .open(Uri.parse(authorizationUrl));
    }
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
    final draft = await showTRDialog<_CustomDraft>(
      context: context,
      builder: (context) => const _CustomProviderDialog(),
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
    final draft = await showTRDialog<_CustomDraft>(
      context: context,
      builder: (context) =>
          _CustomProviderDialog(initial: connection.customConfig),
    );
    if (draft == null) return;
    await ref
        .read(_provider.notifier)
        .updateCustom(connection.id, draft.config, apiKey: draft.apiKey);
  }

  Future<void> _disconnect(ProviderConnectionDto connection) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showTRDialog<bool>(
      context: context,
      builder: (context) => TRAlertDialog(
        title: Text(l10n.providerSettingsDisconnectTitle),
        content: Text(
          l10n.providerSettingsDisconnectBody(connection.displayName),
        ),
        actions: <TRButton>[
          TRButton(
            appearance: TRAppearance.ghost,
            uiSize: TRUiSize.sm,
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          TRButton(
            intent: TRIntent.primary,
            uiSize: TRUiSize.sm,
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.providerSettingsDisconnect),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(_provider.notifier).disconnect(connection.id);
  }
}

class _ConnectedProviders extends StatelessWidget {
  const _ConnectedProviders({
    required this.connections,
    required this.onDisconnect,
    required this.onEditCustom,
  });

  final List<ProviderConnectionDto> connections;
  final ValueChanged<ProviderConnectionDto> onDisconnect;
  final ValueChanged<ProviderConnectionDto> onEditCustom;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      key: const ValueKey('provider-settings-connected'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            l10n.providerSettingsConnected,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          if (connections.isEmpty)
            TRCard(
              padding: TRCardPadding.none,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(l10n.providerSettingsNoConnections),
              ),
            ),
          for (final connection in connections)
            _ProviderConnectionCard(
              connection: connection,
              onDisconnect: onDisconnect,
              onEditCustom: onEditCustom,
            ),
        ],
      ),
    );
  }
}

class _ProviderConnectionCard extends StatelessWidget {
  const _ProviderConnectionCard({
    required this.connection,
    required this.onDisconnect,
    required this.onEditCustom,
  });

  final ProviderConnectionDto connection;
  final ValueChanged<ProviderConnectionDto> onDisconnect;
  final ValueChanged<ProviderConnectionDto> onEditCustom;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TRCard(
      padding: TRCardPadding.none,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    connection.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TRMenu(
                  trigger: Icon(
                    CoderIcons.more,
                    semanticLabel: l10n.providerSettingsActions,
                  ),
                  menuChildren: <Widget>[
                    if (connection.definitionId == 'custom')
                      TRMenuItem(
                        onPressed: () => onEditCustom(connection),
                        child: Text(l10n.providerSettingsEditAdvanced),
                      ),
                    TRMenuItem(
                      onPressed: () => onDisconnect(connection),
                      child: Text(l10n.providerSettingsDisconnect),
                    ),
                  ],
                ),
              ],
            ),
            Text(
              '${_statusLabel(l10n, connection.status)} · '
              '${_authLabel(l10n, connection.credentialOrigin)}',
            ),
            if (connection.error != null)
              Text(
                connection.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProviderCatalog extends StatelessWidget {
  const _ProviderCatalog({
    required this.definitions,
    required this.onAdd,
    required this.onAddCustom,
  });

  final List<ProviderDefinitionDto> definitions;
  final ValueChanged<ProviderDefinitionDto> onAdd;
  final VoidCallback onAddCustom;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      key: const ValueKey('provider-settings-add'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            l10n.providerSettingsAdd,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          if (definitions.isEmpty)
            TRCard(
              padding: TRCardPadding.none,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(l10n.providerSettingsNoPresets),
              ),
            ),
          for (final definition in definitions)
            TRCard(
              padding: TRCardPadding.none,
              child: CoderListRow(
                key: ValueKey('provider-add-${definition.id}'),
                leading: const Icon(CoderIcons.network),
                title: Text(definition.name),
                subtitle: Text(definition.description),
                trailing: const Icon(CoderIcons.addCircle),
                onTap: () => onAdd(definition),
              ),
            ),
          TRCard(
            padding: TRCardPadding.none,
            child: CoderListRow(
              key: const ValueKey('provider-add-custom'),
              leading: const Icon(CoderIcons.tune),
              title: const Text('Custom OpenAI Compatible'),
              subtitle: Text(l10n.providerSettingsCustomSubtitle),
              trailing: const Icon(CoderIcons.chevronRight),
              onTap: onAddCustom,
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthAttemptBar extends StatelessWidget {
  const _AuthAttemptBar({required this.attempt, required this.onCancel});

  final ProviderAuthAttemptDto attempt;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: context.tinyrackTheme.surfaceSelected,
      borderRadius: const BorderRadius.all(TRRadii.medium),
    ),
    child: CoderListRow(
      leading: const TRSpinner(uiSize: TRUiSize.sm),
      title: Text(AppLocalizations.of(context).providerSettingsOAuthPending),
      subtitle: SelectableText(
        <String?>[
          attempt.authorizationUrl,
          attempt.userCode,
        ].whereType<String>().join(' · '),
      ),
      trailing: TRButton(
        appearance: TRAppearance.ghost,
        uiSize: TRUiSize.sm,
        onPressed: onCancel,
        child: Text(AppLocalizations.of(context).commonCancel),
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
      title: Text(l10n.providerSettingsConnectTitle(widget.providerName)),
      content: TRTextField(
        uiSize: TRUiSize.sm,
        key: const ValueKey('provider-api-key'),
        controller: _controller,
        obscureText: true,
        autofocus: true,
        label: 'API key',
      ),
      actions: <TRButton>[
        TRButton(
          appearance: TRAppearance.ghost,
          uiSize: TRUiSize.sm,
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        TRButton(
          intent: TRIntent.primary,
          uiSize: TRUiSize.sm,
          onPressed: () {
            final value = _controller.text.trim();
            if (value.isNotEmpty) Navigator.pop(context, value);
          },
          child: Text(l10n.providerSettingsConnect),
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
  const _CustomProviderDialog({this.initial});

  final CustomProviderConfigDto? initial;

  @override
  State<_CustomProviderDialog> createState() => _CustomProviderDialogState();
}

class _CustomProviderDialogState extends State<_CustomProviderDialog> {
  late final TextEditingController _name;
  late final TextEditingController _baseUrl;
  late final TextEditingController _apiKey;
  late final TextEditingController _models;
  late ProviderApiFormat _apiFormat;
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
    _apiFormat = initial?.apiFormat ?? ProviderApiFormat.chatCompletions;
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
      title: Text(l10n.providerSettingsCustomTitle),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TRTextField(
                uiSize: TRUiSize.sm,
                controller: _name,
                label: l10n.commonName,
              ),
              const SizedBox(height: 12),
              TRTextField(
                uiSize: TRUiSize.sm,
                controller: _baseUrl,
                label: 'Base URL',
              ),
              const SizedBox(height: 12),
              TRSelectFormField<ProviderApiFormat>(
                initialValue: _apiFormat,
                label: l10n.providerSettingsApiFormat,
                uiSize: TRUiSize.sm,
                items: ProviderApiFormat.values
                    .map(
                      (format) => TRSelectItem<ProviderApiFormat>(
                        value: format,
                        label: format.name,
                      ),
                    )
                    .toList(growable: false),
                onValueChange: (value) {
                  if (value != null) setState(() => _apiFormat = value);
                },
              ),
              CoderSwitchRow(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.providerSettingsRequiresApiKey),
                value: _authenticationRequired,
                onChanged: (value) =>
                    setState(() => _authenticationRequired = value),
              ),
              if (_authenticationRequired)
                TRTextField(
                  uiSize: TRUiSize.sm,
                  controller: _apiKey,
                  obscureText: true,
                  label: 'API key',
                ),
              const SizedBox(height: 12),
              if (widget.initial?.manualModelIds.isNotEmpty ?? false)
                TRTextField(
                  uiSize: TRUiSize.sm,
                  controller: _models,
                  label: l10n.providerSettingsManualModels,
                  placeholder: 'model-a, model-b',
                ),
            ],
          ),
        ),
      ),
      actions: <TRButton>[
        TRButton(
          appearance: TRAppearance.ghost,
          uiSize: TRUiSize.sm,
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        TRButton(
          intent: TRIntent.primary,
          uiSize: TRUiSize.sm,
          onPressed: _submit,
          child: Text(l10n.commonSave),
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
          apiFormat: _apiFormat,
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
      title: Text(l10n.providerSettingsModelLookupFailedTitle),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(l10n.providerSettingsModelLookupFailedBody),
            const SizedBox(height: 12),
            TRTextField(
              uiSize: TRUiSize.sm,
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
          uiSize: TRUiSize.sm,
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.providerSettingsLater),
        ),
        TRButton(
          intent: TRIntent.primary,
          uiSize: TRUiSize.sm,
          onPressed: () {
            final models = _models.text
                .split(',')
                .map((value) => value.trim())
                .where((value) => value.isNotEmpty)
                .toSet()
                .toList(growable: false);
            if (models.isNotEmpty) Navigator.pop(context, models);
          },
          child: Text(l10n.commonSave),
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
      ProviderCredentialOrigin.oauth => 'ChatGPT OAuth',
      ProviderCredentialOrigin.none => l10n.providerAuthNone,
    };
