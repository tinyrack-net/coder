import 'dart:async';

import 'package:coder_app/src/controller.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reactive_forms/reactive_forms.dart';

/// SettingsPage defines a public contract.
class SettingsPage extends ConsumerStatefulWidget {
  /// Creates a [SettingsPage].
  const SettingsPage({required this.hostId, super.key});

  /// The hostId public API member.
  final String hostId;

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  String? _selectedProviderId;

  Future<void> _select(String id) async {
    setState(() => _selectedProviderId = id);
    await ref.read(providerSettingsControllerProvider.notifier).loadModels(id);
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(providerSettingsControllerProvider);
    final state = asyncState.asData?.value;
    final catalog = state?.catalog;
    if (asyncState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (catalog == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: Center(
          child: Text(
            asyncState.hasError ? '${asyncState.error}' : 'Daemon 연결이 필요합니다.',
          ),
        ),
      );
    }
    if (_selectedProviderId == null) {
      final id = catalog.defaultProviderId ?? catalog.providers.firstOrNull?.id;
      if (id != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _selectedProviderId == null) unawaited(_select(id));
        });
      }
    }
    final selected = catalog.providers
        .where((item) => item.id == _selectedProviderId)
        .firstOrNull;
    final canManage = ref
        .read(providerSettingsControllerProvider.notifier)
        .canManage;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: context.pop,
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Settings'),
      ),
      body: Column(
        children: <Widget>[
          if (!canManage)
            const MaterialBanner(
              content: Text(
                '원격 연결에서는 provider 설정을 조회만 할 수 있습니다. '
                'daemon 호스트에서 설정을 변경하세요.',
              ),
              actions: <Widget>[SizedBox.shrink()],
            ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final list = _ProviderList(
                  catalog: catalog,
                  selectedId: _selectedProviderId,
                  canManage: canManage,
                  onSelected: _select,
                  onAdd: () => _addProvider(catalog),
                );
                final editor = selected == null
                    ? const Center(child: Text('Provider를 선택하세요.'))
                    : _ProviderEditor(
                        key: ValueKey('${selected.id}-${selected.updatedAt}'),
                        provider: selected,
                        presets: catalog.presets,
                        models:
                            state!.models[selected.id] ??
                            const <ProviderModelDto>[],
                        isDefault: catalog.defaultProviderId == selected.id,
                        canManage: canManage,
                      );
                if (constraints.maxWidth >= 900) {
                  return Row(
                    children: <Widget>[
                      SizedBox(width: 300, child: list),
                      const VerticalDivider(width: 1),
                      Expanded(child: editor),
                    ],
                  );
                }
                return Column(
                  children: <Widget>[
                    SizedBox(height: 220, child: list),
                    const Divider(height: 1),
                    Expanded(child: editor),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addProvider(ProviderCatalogDto catalog) async {
    final preset = catalog.presets
        .where((item) => item.id == 'custom')
        .firstOrNull;
    if (preset == null) return;
    final now = ref.read(appClockProvider).nowUtc();
    final provider = ApiProviderDto(
      id: ref.read(appIdGeneratorProvider).generate(),
      name: 'OpenAI Compatible',
      presetId: preset.id,
      baseUrl: preset.defaultBaseUrl,
      transport: preset.defaultTransport,
      credentialSource: preset.defaultCredentialSource,
      credentialConfigured: false,
      enabled: true,
      strictToolSchema: preset.strictToolSchema,
      createdAt: now,
      updatedAt: now,
    );
    await ref
        .read(providerSettingsControllerProvider.notifier)
        .saveProvider(provider);
    await _select(provider.id);
  }
}

class _ProviderList extends StatelessWidget {
  const _ProviderList({
    required this.catalog,
    required this.selectedId,
    required this.canManage,
    required this.onSelected,
    required this.onAdd,
  });

  final ProviderCatalogDto catalog;
  final String? selectedId;
  final bool canManage;
  final ValueChanged<String> onSelected;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Column(
    children: <Widget>[
      ListTile(
        title: const Text('API Providers'),
        trailing: canManage
            ? IconButton(
                tooltip: 'Provider 추가',
                onPressed: onAdd,
                icon: const Icon(Icons.add),
              )
            : null,
      ),
      Expanded(
        child: ListView.builder(
          itemCount: catalog.providers.length,
          itemBuilder: (context, index) {
            final provider = catalog.providers[index];
            final credentialLabel = provider.credentialConfigured
                ? 'configured'
                : 'credential needed';
            return ListTile(
              selected: provider.id == selectedId,
              leading: Icon(
                provider.enabled ? Icons.hub_outlined : Icons.pause_circle,
              ),
              title: Text(provider.name),
              subtitle: Text(
                '${provider.transport.name} · $credentialLabel',
              ),
              trailing: catalog.defaultProviderId == provider.id
                  ? const Icon(Icons.star, size: 18)
                  : null,
              onTap: () => onSelected(provider.id),
            );
          },
        ),
      ),
    ],
  );
}

class _ProviderEditor extends ConsumerStatefulWidget {
  const _ProviderEditor({
    required this.provider,
    required this.presets,
    required this.models,
    required this.isDefault,
    required this.canManage,
    super.key,
  });

  final ApiProviderDto provider;
  final List<ProviderPresetDto> presets;
  final List<ProviderModelDto> models;
  final bool isDefault;
  final bool canManage;

  @override
  ConsumerState<_ProviderEditor> createState() => _ProviderEditorState();
}

class _ProviderEditorState extends ConsumerState<_ProviderEditor> {
  late final FormGroup _form;
  late final TextEditingController _defaultModel;
  late String _presetId;
  late ApiTransport _transport;
  late CredentialSource _credentialSource;
  late bool _enabled;
  late bool _strictTools;
  late bool _makeDefault;

  @override
  void initState() {
    super.initState();
    final provider = widget.provider;
    _form = FormGroup(<String, AbstractControl<Object?>>{
      'name': FormControl<String>(
        value: provider.name,
        validators: <Validator<dynamic>>[Validators.required],
      ),
      'baseUrl': FormControl<String>(
        value: provider.baseUrl,
        validators: <Validator<dynamic>>[Validators.required],
      ),
      'environment': FormControl<String>(
        value: provider.environmentVariable ?? '',
      ),
      'visibleModels': FormControl<String>(
        value: provider.visibleModelIds.join(', '),
      ),
      'apiKey': FormControl<String>(),
    });
    _defaultModel = TextEditingController(text: provider.defaultModelId ?? '');
    _presetId = provider.presetId;
    _transport = provider.transport;
    _credentialSource = provider.credentialSource;
    _enabled = provider.enabled;
    _strictTools = provider.strictToolSchema;
    _makeDefault = widget.isDefault;
  }

  @override
  void dispose() {
    _form.dispose();
    _defaultModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final providerBusy = ref
        .watch(providerSettingsControllerProvider)
        .isLoading;
    return ReactiveForm(
      formGroup: _form,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        widget.provider.name,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    Chip(
                      avatar: Icon(
                        widget.provider.credentialConfigured
                            ? Icons.check_circle
                            : Icons.warning_amber,
                        size: 18,
                      ),
                      label: Text(
                        widget.provider.credentialConfigured
                            ? 'Credential configured'
                            : 'Credential required',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ReactiveTextField<String>(
                  formControlName: 'name',
                  readOnly: !widget.canManage,
                  decoration: const InputDecoration(labelText: '이름'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _presetId,
                  decoration: const InputDecoration(labelText: 'Preset'),
                  items: widget.presets
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.id,
                          child: Text(item.name),
                        ),
                      )
                      .toList(),
                  onChanged: widget.canManage ? _applyPreset : null,
                ),
                const SizedBox(height: 12),
                DropdownMenu<String>(
                  controller: _defaultModel,
                  enabled: widget.canManage,
                  enableFilter: true,
                  expandedInsets: EdgeInsets.zero,
                  label: const Text('기본 모델'),
                  dropdownMenuEntries: _availableModelIds
                      .map(
                        (modelId) => DropdownMenuEntry<String>(
                          value: modelId,
                          label: modelId,
                        ),
                      )
                      .toList(growable: false),
                ),
                const SizedBox(height: 4),
                Text(
                  '목록에서 선택하거나 OpenAI-compatible model ID를 직접 입력하세요.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                ReactiveTextField<String>(
                  formControlName: 'baseUrl',
                  readOnly: !widget.canManage,
                  decoration: const InputDecoration(labelText: 'Base URL'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<ApiTransport>(
                  initialValue: _transport,
                  decoration: const InputDecoration(labelText: 'API transport'),
                  items: ApiTransport.values
                      .map(
                        (item) => DropdownMenuItem(
                          value: item,
                          child: Text(item.name),
                        ),
                      )
                      .toList(),
                  onChanged: widget.canManage
                      ? (value) =>
                            setState(() => _transport = value ?? _transport)
                      : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<CredentialSource>(
                  initialValue: _credentialSource,
                  decoration: const InputDecoration(labelText: '인증 source'),
                  items: CredentialSource.values
                      .map(
                        (item) => DropdownMenuItem(
                          value: item,
                          child: Text(item.name),
                        ),
                      )
                      .toList(),
                  onChanged: widget.canManage
                      ? (value) => setState(
                          () => _credentialSource = value ?? _credentialSource,
                        )
                      : null,
                ),
                if (_credentialSource == CredentialSource.stored) ...<Widget>[
                  const SizedBox(height: 12),
                  ReactiveTextField<String>(
                    formControlName: 'apiKey',
                    readOnly: !widget.canManage,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'API key',
                      helperText: '비워 두면 기존 값을 유지합니다.',
                    ),
                  ),
                ],
                if (_credentialSource == CredentialSource.environment)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: ReactiveTextField<String>(
                      formControlName: 'environment',
                      readOnly: !widget.canManage,
                      decoration: const InputDecoration(labelText: '환경변수 이름'),
                    ),
                  ),
                const SizedBox(height: 12),
                ReactiveTextField<String>(
                  formControlName: 'visibleModels',
                  readOnly: !widget.canManage,
                  decoration: const InputDecoration(
                    labelText: '표시할 model ID',
                    helperText: '쉼표로 구분합니다. 비우면 전체를 표시합니다.',
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _enabled,
                  onChanged: widget.canManage
                      ? (value) => setState(() => _enabled = value)
                      : null,
                  title: const Text('Provider 활성화'),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _strictTools,
                  onChanged: widget.canManage
                      ? (value) => setState(() => _strictTools = value)
                      : null,
                  title: const Text('Strict tool schema'),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _makeDefault,
                  onChanged: widget.canManage
                      ? (value) => setState(() => _makeDefault = value)
                      : null,
                  title: const Text('기본 provider'),
                ),
                if (widget.canManage)
                  Row(
                    children: <Widget>[
                      FilledButton.icon(
                        onPressed: providerBusy ? null : _save,
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('저장'),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: providerBusy ? null : _delete,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('삭제'),
                      ),
                    ],
                  ),
                const SizedBox(height: 28),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'Models',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    if (widget.canManage)
                      IconButton(
                        tooltip: '/models 새로고침',
                        onPressed: providerBusy
                            ? null
                            : () => ref
                                  .read(
                                    providerSettingsControllerProvider.notifier,
                                  )
                                  .refreshModels(widget.provider.id),
                        icon: const Icon(Icons.refresh),
                      ),
                    if (widget.canManage)
                      IconButton(
                        tooltip: '수동 model 추가',
                        onPressed: _addManualModel,
                        icon: const Icon(Icons.add),
                      ),
                  ],
                ),
                const Divider(),
                if (widget.models.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('모델을 조회하거나 수동으로 추가하세요.'),
                  )
                else
                  ...widget.models.map(_modelTile),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _modelTile(ProviderModelDto model) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(model.label),
    subtitle: Text(
      '${model.source.name} · tools ${model.capabilities.toolCalling.name} · '
      'stream ${model.capabilities.streaming.name} · '
      '${model.diagnosticStatus.name}',
    ),
    trailing: widget.canManage
        ? Wrap(
            children: <Widget>[
              IconButton(
                tooltip: '기능 진단',
                onPressed: () => _diagnose(model),
                icon: const Icon(Icons.health_and_safety_outlined),
              ),
              if (model.source == ProviderModelSource.manual)
                IconButton(
                  tooltip: '수동 model 삭제',
                  onPressed: () => ref
                      .read(providerSettingsControllerProvider.notifier)
                      .deleteModel(model.providerId, model.id),
                  icon: const Icon(Icons.delete_outline),
                ),
            ],
          )
        : null,
  );

  void _applyPreset(String? id) {
    final preset = widget.presets.where((item) => item.id == id).firstOrNull;
    if (preset == null) return;
    setState(() {
      _presetId = preset.id;
      _form.patchValue(<String, Object?>{
        'baseUrl': preset.defaultBaseUrl,
        'environment': preset.defaultEnvironmentVariable ?? '',
      });
      _transport = preset.defaultTransport;
      _credentialSource = preset.defaultCredentialSource;
      _defaultModel.text = preset.defaultModelId ?? '';
      _strictTools = preset.strictToolSchema;
    });
  }

  List<String> get _availableModelIds {
    final ids = <String>{
      ...widget.presets
          .where((preset) => preset.id == _presetId)
          .expand((preset) => preset.modelIds),
      ...widget.models.map((model) => model.id),
    };
    final current = _defaultModel.text.trim();
    if (current.isNotEmpty) ids.add(current);
    return ids.toList(growable: false)..sort();
  }

  Future<void> _save() async {
    if (!_form.valid) {
      _form.markAllAsTouched();
      return;
    }
    final visibleModels =
        (_form.control('visibleModels').value as String? ?? '')
            .split(',')
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList(growable: false);
    await ref
        .read(providerSettingsControllerProvider.notifier)
        .saveProvider(
          widget.provider.copyWith(
            name: (_form.control('name').value as String).trim(),
            presetId: _presetId,
            baseUrl: (_form.control('baseUrl').value as String).trim(),
            transport: _transport,
            credentialSource: _credentialSource,
            environmentVariable:
                (_form.control('environment').value as String? ?? '')
                    .trim()
                    .isEmpty
                ? null
                : (_form.control('environment').value as String).trim(),
            defaultModelId: _defaultModel.text.trim().isEmpty
                ? null
                : _defaultModel.text.trim(),
            visibleModelIds: visibleModels,
            enabled: _enabled,
            strictToolSchema: _strictTools,
          ),
          apiKey:
              (_form.control('apiKey').value as String? ?? '').trim().isEmpty
              ? null
              : (_form.control('apiKey').value as String).trim(),
          makeDefault: _makeDefault,
        );
    _form.control('apiKey').reset();
  }

  Future<void> _delete() async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Provider 삭제'),
        content: Text('${widget.provider.name} provider를 삭제할까요?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (accepted == true) {
      await ref
          .read(providerSettingsControllerProvider.notifier)
          .deleteProvider(widget.provider.id);
    }
  }

  Future<void> _addManualModel() async {
    final draft = await showDialog<_ManualModelDraft>(
      context: context,
      builder: (context) => const _ManualModelDialog(),
    );
    if (draft == null) return;
    await ref
        .read(providerSettingsControllerProvider.notifier)
        .saveManualModel(
          ProviderModelDto(
            providerId: widget.provider.id,
            id: draft.id,
            label: draft.id,
            source: ProviderModelSource.manual,
            capabilities: ModelCapabilitiesDto(
              streaming: draft.streaming
                  ? CapabilitySupport.supported
                  : CapabilitySupport.unsupported,
              toolCalling: draft.toolCalling
                  ? CapabilitySupport.supported
                  : CapabilitySupport.unsupported,
              reasoningEffort: draft.reasoning
                  ? CapabilitySupport.supported
                  : CapabilitySupport.unsupported,
              supportedReasoningEfforts: draft.reasoning
                  ? const <String>['none', 'low', 'medium', 'high', 'xhigh']
                  : const <String>[],
              source: CapabilitySource.manual,
            ),
          ),
        );
  }

  Future<void> _diagnose(ProviderModelDto model) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('모델 기능 진단'),
        content: Text(
          '${model.id}에 최소 streaming/tool-call 요청을 전송합니다. '
          'Provider 과금이 발생할 수 있습니다.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('진단 실행'),
          ),
        ],
      ),
    );
    if (accepted != true) return;
    final result = await ref
        .read(providerSettingsControllerProvider.notifier)
        .diagnose(model.providerId, model.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.status == DiagnosticStatus.verified
              ? 'Streaming과 tool calling이 확인되었습니다.'
              : '진단 실패: ${result.error}',
        ),
      ),
    );
  }
}

final class _ManualModelDraft {
  const _ManualModelDraft({
    required this.id,
    required this.streaming,
    required this.toolCalling,
    required this.reasoning,
  });

  final String id;
  final bool streaming;
  final bool toolCalling;
  final bool reasoning;
}

class _ManualModelDialog extends StatefulWidget {
  const _ManualModelDialog();

  @override
  State<_ManualModelDialog> createState() => _ManualModelDialogState();
}

class _ManualModelDialogState extends State<_ManualModelDialog> {
  final TextEditingController _id = TextEditingController();
  bool _streaming = true;
  bool _toolCalling = true;
  bool _reasoning = false;

  @override
  void dispose() {
    _id.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('수동 model 추가'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        TextField(
          controller: _id,
          decoration: const InputDecoration(labelText: 'Model ID'),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _streaming,
          onChanged: (value) => setState(() => _streaming = value),
          title: const Text('Streaming 지원'),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _toolCalling,
          onChanged: (value) => setState(() => _toolCalling = value),
          title: const Text('Tool calling 지원'),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _reasoning,
          onChanged: (value) => setState(() => _reasoning = value),
          title: const Text('Reasoning effort 지원'),
        ),
        const Text('Coding agent에는 streaming과 tool calling이 필요합니다.'),
      ],
    ),
    actions: <Widget>[
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('취소'),
      ),
      FilledButton(onPressed: _submit, child: const Text('추가')),
    ],
  );

  void _submit() {
    final id = _id.text.trim();
    if (id.isEmpty) return;
    Navigator.pop(
      context,
      _ManualModelDraft(
        id: id,
        streaming: _streaming,
        toolCalling: _toolCalling,
        reasoning: _reasoning,
      ),
    );
  }
}
