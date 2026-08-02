import 'dart:async';

import 'package:coder_app/src/controller.dart';
import 'package:coder_app/src/external_url_opener.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// External authorization URL adapter supplied by the app composition root.
final externalUrlOpenerProvider = Provider<ExternalUrlOpener>(
  (ref) => throw StateError('ExternalUrlOpener must be overridden.'),
);

/// Provider connection settings for one daemon host.
class SettingsPage extends ConsumerStatefulWidget {
  /// Creates a provider connection settings page.
  const SettingsPage({required this.hostId, super.key});

  /// Route host identifier.
  final String hostId;

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final Set<String> _loadingModels = <String>{};

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(providerSettingsControllerProvider);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: context.pop,
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Provider 설정'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Catalog 갱신',
            onPressed: asyncState.asData?.value == null
                ? null
                : () => ref
                      .read(providerSettingsControllerProvider.notifier)
                      .refreshCatalog(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('$error')),
        data: (state) => state == null
            ? const Center(child: Text('Daemon 연결이 필요합니다.'))
            : _body(state),
      ),
    );
  }

  Widget _body(ProviderSettingsState state) {
    final canManage = ref
        .read(providerSettingsControllerProvider.notifier)
        .canManage;
    final activeConnections = state.connections
        .where(
          (connection) =>
              connection.status != ProviderConnectionStatus.disconnected,
        )
        .toList(growable: false);
    for (final connection in activeConnections) {
      if (!_loadingModels.add(connection.id)) continue;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(
          ref
              .read(providerSettingsControllerProvider.notifier)
              .loadModels(connection.id),
        );
      });
    }
    final connected = _ConnectedProviders(
      connections: activeConnections,
      models: state.models,
      canManage: canManage,
      onDisconnect: _disconnect,
      onSetDefault: (id) =>
          ref.read(providerSettingsControllerProvider.notifier).setDefault(id),
      onSetDefaultModel: (id, model) => ref
          .read(providerSettingsControllerProvider.notifier)
          .setDefaultModel(id, model),
      onEditCustom: _editCustom,
    );
    final catalog = _ProviderCatalog(
      definitions: state.catalog.definitions,
      connectedDefinitionIds: activeConnections
          .where((connection) => connection.definitionId != 'custom')
          .map((connection) => connection.definitionId)
          .toSet(),
      canManage: canManage,
      onAdd: _addDefinition,
      onAddCustom: _addCustom,
    );
    return Column(
      children: <Widget>[
        if (!canManage)
          const MaterialBanner(
            content: Text(
              '원격 연결에서는 Provider 설정을 조회만 할 수 있습니다. '
              'daemon 호스트에서 연결을 변경하세요.',
            ),
            actions: <Widget>[SizedBox.shrink()],
          ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 900) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(child: connected),
                    const VerticalDivider(width: 1),
                    Expanded(child: catalog),
                  ],
                );
              }
              return ListView(
                children: <Widget>[
                  SizedBox(height: 340, child: connected),
                  const Divider(height: 1),
                  SizedBox(height: 420, child: catalog),
                ],
              );
            },
          ),
        ),
        for (final attempt in state.authAttempts.values)
          if (attempt.status == ProviderAuthAttemptStatus.awaitingUser ||
              attempt.status == ProviderAuthAttemptStatus.exchanging)
            _AuthAttemptBar(
              attempt: attempt,
              onCancel: () => ref
                  .read(providerSettingsControllerProvider.notifier)
                  .cancelAuth(attempt.id),
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
      await ref
          .read(providerSettingsControllerProvider.notifier)
          .connectNone(definition.id);
      return;
    }
    await _showApiKey(definition);
  }

  Future<void> _showOpenAIAuth(ProviderDefinitionDto definition) async {
    final methodId = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text('OpenAI 연결', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              const Text('ChatGPT 로그인은 공개 Codex 인증 흐름에 의존하는 실험적 기능입니다.'),
              const SizedBox(height: 16),
              for (final method in definition.authMethods)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    key: ValueKey('openai-auth-${method.id}'),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: Theme.of(context).dividerColor),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    leading: Icon(
                      method.kind == ProviderAuthKind.oauth
                          ? Icons.account_circle_outlined
                          : Icons.key_outlined,
                    ),
                    title: Text(method.label),
                    subtitle: method.experimental
                        ? const Text('실험적')
                        : const Text('OpenAI Platform'),
                    onTap: () => Navigator.pop(context, method.id),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || methodId == null) return;
    if (methodId == 'api-key') {
      await _showApiKey(definition);
      return;
    }
    final attempt = await ref
        .read(providerSettingsControllerProvider.notifier)
        .startAuth(definition.id, methodId);
    final authorizationUrl = attempt.authorizationUrl;
    if (methodId == 'chatgpt-browser' && authorizationUrl != null) {
      await ref
          .read(externalUrlOpenerProvider)
          .open(Uri.parse(authorizationUrl));
    }
  }

  Future<void> _showApiKey(ProviderDefinitionDto definition) async {
    final apiKey = await showDialog<String>(
      context: context,
      builder: (context) => _ApiKeyDialog(providerName: definition.name),
    );
    if (apiKey == null || apiKey.isEmpty) return;
    await ref
        .read(providerSettingsControllerProvider.notifier)
        .connectApiKey(definition.id, apiKey);
  }

  Future<void> _addCustom() async {
    final draft = await showDialog<_CustomDraft>(
      context: context,
      builder: (context) => const _CustomProviderDialog(),
    );
    if (draft == null) return;
    final connection = await ref
        .read(providerSettingsControllerProvider.notifier)
        .createCustom(
          ref.read(appIdGeneratorProvider).generate(),
          draft.config,
          apiKey: draft.apiKey,
        );
    if (!mounted || connection.defaultModelId != null) return;
    final manualModels = await showDialog<List<String>>(
      context: context,
      builder: (context) => const _ManualModelsDialog(),
    );
    if (!mounted || manualModels == null || manualModels.isEmpty) return;
    await ref
        .read(providerSettingsControllerProvider.notifier)
        .updateCustom(
          connection.id,
          draft.config.copyWith(manualModelIds: manualModels),
        );
  }

  Future<void> _editCustom(ProviderConnectionDto connection) async {
    final draft = await showDialog<_CustomDraft>(
      context: context,
      builder: (context) =>
          _CustomProviderDialog(initial: connection.customConfig),
    );
    if (draft == null) return;
    await ref
        .read(providerSettingsControllerProvider.notifier)
        .updateCustom(connection.id, draft.config, apiKey: draft.apiKey);
  }

  Future<void> _disconnect(ProviderConnectionDto connection) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Provider 연결 해제'),
        content: Text(
          '${connection.displayName} 연결을 해제할까요? 기존 agent 이력은 유지됩니다.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('연결 해제'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref
        .read(providerSettingsControllerProvider.notifier)
        .disconnect(connection.id);
  }
}

class _ConnectedProviders extends StatelessWidget {
  const _ConnectedProviders({
    required this.connections,
    required this.models,
    required this.canManage,
    required this.onDisconnect,
    required this.onSetDefault,
    required this.onSetDefaultModel,
    required this.onEditCustom,
  });

  final List<ProviderConnectionDto> connections;
  final Map<String, List<ProviderModelDto>> models;
  final bool canManage;
  final ValueChanged<ProviderConnectionDto> onDisconnect;
  final ValueChanged<String> onSetDefault;
  final void Function(String, String) onSetDefaultModel;
  final ValueChanged<ProviderConnectionDto> onEditCustom;

  @override
  Widget build(BuildContext context) => ListView(
    key: const ValueKey('provider-settings-connected'),
    padding: const EdgeInsets.all(20),
    children: <Widget>[
      Text('연결됨', style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 12),
      if (connections.isEmpty)
        const Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text('연결된 Provider가 없습니다.'),
          ),
        ),
      for (final connection in connections)
        Card(
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
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    if (connection.isDefault) const Chip(label: Text('기본')),
                    if (canManage)
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          switch (value) {
                            case 'default':
                              onSetDefault(connection.id);
                            case 'edit':
                              onEditCustom(connection);
                            case 'disconnect':
                              onDisconnect(connection);
                          }
                        },
                        itemBuilder: (context) => <PopupMenuEntry<String>>[
                          if (!connection.isDefault)
                            const PopupMenuItem(
                              value: 'default',
                              child: Text('기본 Provider로 설정'),
                            ),
                          if (connection.definitionId == 'custom')
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('고급 설정 편집'),
                            ),
                          const PopupMenuItem(
                            value: 'disconnect',
                            child: Text('연결 해제'),
                          ),
                        ],
                      ),
                  ],
                ),
                Text(
                  '${_statusLabel(connection.status)} · '
                  '${_authLabel(connection.credentialOrigin)}',
                ),
                if (connection.error != null)
                  Text(
                    connection.error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                if ((models[connection.id] ?? const <ProviderModelDto>[])
                    .isNotEmpty) ...<Widget>[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    key: ValueKey('default-model-${connection.id}'),
                    initialValue: connection.defaultModelId,
                    decoration: const InputDecoration(labelText: '기본 모델'),
                    items: (models[connection.id] ?? const <ProviderModelDto>[])
                        .map(
                          (model) => DropdownMenuItem(
                            value: model.id,
                            child: Text(model.label),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: canManage
                        ? (model) {
                            if (model != null) {
                              onSetDefaultModel(connection.id, model);
                            }
                          }
                        : null,
                  ),
                ],
              ],
            ),
          ),
        ),
    ],
  );
}

class _ProviderCatalog extends StatelessWidget {
  const _ProviderCatalog({
    required this.definitions,
    required this.connectedDefinitionIds,
    required this.canManage,
    required this.onAdd,
    required this.onAddCustom,
  });

  final List<ProviderDefinitionDto> definitions;
  final Set<String> connectedDefinitionIds;
  final bool canManage;
  final ValueChanged<ProviderDefinitionDto> onAdd;
  final VoidCallback onAddCustom;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: <Widget>[
      Text('Provider 추가', style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 12),
      for (final definition in definitions)
        Card(
          child: ListTile(
            key: ValueKey('provider-add-${definition.id}'),
            leading: const Icon(Icons.hub_outlined),
            title: Text(definition.name),
            subtitle: Text(definition.description),
            trailing: connectedDefinitionIds.contains(definition.id)
                ? const Icon(Icons.check_circle, semanticLabel: '연결됨')
                : canManage
                ? const Icon(Icons.add_circle_outline)
                : null,
            onTap: canManage && !connectedDefinitionIds.contains(definition.id)
                ? () => onAdd(definition)
                : null,
          ),
        ),
      Card(
        child: ListTile(
          key: const ValueKey('provider-add-custom'),
          leading: const Icon(Icons.tune),
          title: const Text('Custom OpenAI Compatible'),
          subtitle: const Text('고급 설정: 자체 endpoint 연결'),
          trailing: canManage ? const Icon(Icons.chevron_right) : null,
          onTap: canManage ? onAddCustom : null,
        ),
      ),
    ],
  );
}

class _AuthAttemptBar extends StatelessWidget {
  const _AuthAttemptBar({required this.attempt, required this.onCancel});

  final ProviderAuthAttemptDto attempt;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.secondaryContainer,
    child: ListTile(
      leading: const CircularProgressIndicator(),
      title: const Text('ChatGPT 로그인 대기 중'),
      subtitle: SelectableText(
        <String?>[
          attempt.authorizationUrl,
          attempt.userCode,
        ].whereType<String>().join(' · '),
      ),
      trailing: TextButton(onPressed: onCancel, child: const Text('취소')),
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
  Widget build(BuildContext context) => AlertDialog(
    title: Text('${widget.providerName} 연결'),
    content: TextField(
      key: const ValueKey('provider-api-key'),
      controller: _controller,
      obscureText: true,
      autofocus: true,
      decoration: const InputDecoration(labelText: 'API key'),
    ),
    actions: <Widget>[
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('취소'),
      ),
      FilledButton(
        onPressed: () {
          final value = _controller.text.trim();
          if (value.isNotEmpty) Navigator.pop(context, value);
        },
        child: const Text('연결'),
      ),
    ],
  );
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
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Custom Provider 고급 설정'),
    content: SizedBox(
      width: 520,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: '이름'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _baseUrl,
              decoration: const InputDecoration(labelText: 'Base URL'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ProviderApiFormat>(
              initialValue: _apiFormat,
              decoration: const InputDecoration(labelText: 'API 형식'),
              items: ProviderApiFormat.values
                  .map(
                    (format) => DropdownMenuItem(
                      value: format,
                      child: Text(format.name),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                if (value != null) setState(() => _apiFormat = value);
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('API key 필요'),
              value: _authenticationRequired,
              onChanged: (value) =>
                  setState(() => _authenticationRequired = value),
            ),
            if (_authenticationRequired)
              TextField(
                controller: _apiKey,
                obscureText: true,
                decoration: _TextInputDecorationM3.apiKey,
              ),
            const SizedBox(height: 12),
            if (widget.initial?.manualModelIds.isNotEmpty ?? false)
              TextField(
                controller: _models,
                decoration: const InputDecoration(
                  labelText: '수동 model ID',
                  hintText: 'model-a, model-b',
                ),
              ),
          ],
        ),
      ),
    ),
    actions: <Widget>[
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('취소'),
      ),
      FilledButton(onPressed: _submit, child: const Text('저장')),
    ],
  );

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
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Model 자동 조회 실패'),
    content: SizedBox(
      width: 480,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text('Provider가 model 목록을 제공하지 않았습니다. 사용할 model ID를 입력하세요.'),
          const SizedBox(height: 12),
          TextField(
            controller: _models,
            decoration: const InputDecoration(
              labelText: '수동 model ID',
              hintText: 'model-a, model-b',
            ),
          ),
        ],
      ),
    ),
    actions: <Widget>[
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('나중에'),
      ),
      FilledButton(
        onPressed: () {
          final models = _models.text
              .split(',')
              .map((value) => value.trim())
              .where((value) => value.isNotEmpty)
              .toSet()
              .toList(growable: false);
          if (models.isNotEmpty) Navigator.pop(context, models);
        },
        child: const Text('저장'),
      ),
    ],
  );
}

abstract final class _TextInputDecorationM3 {
  static const InputDecoration apiKey = InputDecoration(labelText: 'API key');
}

String _statusLabel(ProviderConnectionStatus status) => switch (status) {
  ProviderConnectionStatus.connecting => '연결 중',
  ProviderConnectionStatus.connected => '연결됨',
  ProviderConnectionStatus.degraded => '제한된 연결',
  ProviderConnectionStatus.error => '오류',
  ProviderConnectionStatus.reauthRequired => '재로그인 필요',
  ProviderConnectionStatus.disconnected => '연결 해제됨',
};

String _authLabel(ProviderCredentialOrigin origin) => switch (origin) {
  ProviderCredentialOrigin.stored => '저장된 credential',
  ProviderCredentialOrigin.environment => 'Environment credential',
  ProviderCredentialOrigin.oauth => 'ChatGPT OAuth',
  ProviderCredentialOrigin.none => '인증 없음',
};
