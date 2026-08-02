import 'package:coder_agent/coder_agent.dart';
import 'package:coder_daemon/src/ports.dart';
import 'package:coder_daemon/src/provider_adapters.dart';
import 'package:coder_daemon/src/repositories.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:coder_provider_openai/coder_provider_openai.dart';

/// ProviderService defines a public contract.
class ProviderService {
  /// Creates a [ProviderService].
  ProviderService({
    required this._repository,
    required this._settings,
    required this._credentials,
    required this._environment,
    required this._clock,
    required this._modelDiscovery,
    required this._providerFactory,
    this._fixedProvider,
  });

  final ProviderRepository _repository;
  final SettingsRepository _settings;
  final CredentialRepository _credentials;
  final Map<String, String> _environment;
  final Clock _clock;
  final ProviderModelDiscovery _modelDiscovery;
  final ModelProviderFactory _providerFactory;
  final ModelProvider? _fixedProvider;

  /// The initialize public API member.
  Future<void> initialize({String? legacyOpenAIKey}) async {
    await _credentials.load();
    final existing = await _repository.getProvider('openai');
    if (existing == null) {
      final now = _clock.nowUtc();
      await _repository.upsertProvider(
        ApiProviderDto(
          id: 'openai',
          name: 'OpenAI',
          presetId: 'openai',
          baseUrl: 'https://api.openai.com/v1',
          transport: ApiTransport.responses,
          credentialSource: legacyOpenAIKey?.isNotEmpty == true
              ? CredentialSource.stored
              : CredentialSource.environment,
          credentialConfigured: false,
          environmentVariable: 'OPENAI_API_KEY',
          enabled: true,
          strictToolSchema: true,
          defaultModelId: 'gpt-5.6-sol',
          createdAt: now,
          updatedAt: now,
        ),
      );
      await _settings.setValue('provider.defaultId', 'openai');
    }
    if (legacyOpenAIKey?.isNotEmpty == true) {
      await _credentials.setProviderApiKey('openai', legacyOpenAIKey!);
    }
    for (final model in const <String>[
      'gpt-5.6-sol',
      'gpt-5.6-terra',
      'gpt-5.6-luna',
    ]) {
      if (await _repository.getModel('openai', model) == null) {
        await _repository.upsertModel(
          ProviderModelDto(
            providerId: 'openai',
            id: model,
            label: model,
            source: ProviderModelSource.preset,
            capabilities: presetCapabilities('openai', model),
          ),
        );
      }
    }
  }

  /// The catalog public API member.
  Future<ProviderCatalogDto> catalog() async {
    final providers = await _repository.listProviders();
    return ProviderCatalogDto(
      providers: await Future.wait(providers.map(_withCredentialStatus)),
      presets: openAICompatiblePresets,
      defaultProviderId: await _settings.getValue('provider.defaultId'),
    );
  }

  /// The get public API member.
  Future<ApiProviderDto> get(String id) async {
    final provider = await _repository.getProvider(id);
    if (provider == null) throw StateError('Provider not found: $id');
    return _withCredentialStatus(provider);
  }

  /// The upsert public API member.
  Future<ApiProviderDto> upsert(
    ApiProviderDto provider, {
    bool makeDefault = false,
  }) async {
    final uri = Uri.tryParse(provider.baseUrl);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      throw const FormatException('Provider baseUrl must be an absolute URL.');
    }
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      throw const FormatException('Provider baseUrl must use http or https.');
    }
    if (provider.credentialSource == CredentialSource.environment &&
        (provider.environmentVariable?.trim().isEmpty ?? true)) {
      throw const FormatException(
        'environmentVariable is required for environment credentials.',
      );
    }
    final stored = await _repository.upsertProvider(
      provider.copyWith(
        credentialConfigured: false,
        baseUrl: provider.baseUrl.replaceAll(RegExp(r'/+$'), ''),
        updatedAt: _clock.nowUtc(),
      ),
    );
    await _ensurePresetModels(stored);
    if (makeDefault) {
      await _settings.setValue('provider.defaultId', provider.id);
    }
    if (provider.credentialSource != CredentialSource.stored) {
      await _credentials.removeProvider(provider.id);
    }
    return _withCredentialStatus(stored);
  }

  Future<void> _ensurePresetModels(ApiProviderDto provider) async {
    final preset = openAICompatiblePresets
        .where((item) => item.id == provider.presetId)
        .firstOrNull;
    if (preset == null) return;
    for (final modelId in preset.modelIds) {
      if (await _repository.getModel(provider.id, modelId) != null) {
        continue;
      }
      await _repository.upsertModel(
        ProviderModelDto(
          providerId: provider.id,
          id: modelId,
          label: modelId,
          source: ProviderModelSource.preset,
          capabilities: presetCapabilities(provider.presetId, modelId),
        ),
      );
    }
  }

  /// The delete public API member.
  Future<void> delete(String id) async {
    await _repository.deleteProvider(id);
    await _credentials.removeProvider(id);
    if (await _settings.getValue('provider.defaultId') == id) {
      await _settings.setValue('provider.defaultId', '');
    }
  }

  /// The setCredential public API member.
  Future<void> setCredential(String providerId, String value) async {
    final provider = await get(providerId);
    if (provider.credentialSource != CredentialSource.stored) {
      throw StateError('Provider does not use stored credentials.');
    }
    await _credentials.setProviderApiKey(providerId, value);
  }

  /// The listModels public API member.
  Future<List<ProviderModelDto>> listModels(String providerId) async {
    final provider = await get(providerId);
    final models = await _repository.listModels(providerId);
    if (provider.visibleModelIds.isEmpty) return models;
    final visible = provider.visibleModelIds.toSet();
    return models
        .where(
          (model) =>
              model.source == ProviderModelSource.manual ||
              visible.contains(model.id),
        )
        .toList();
  }

  /// The refreshModels public API member.
  Future<List<ProviderModelDto>> refreshModels(String providerId) async {
    final provider = await get(providerId);
    final apiKey = _apiKey(provider);
    try {
      final modelIds = await _modelDiscovery.fetchModelIds(provider, apiKey);
      final models = <ProviderModelDto>[
        for (final id in modelIds)
          ProviderModelDto(
            providerId: providerId,
            id: id,
            label: id,
            source: ProviderModelSource.discovered,
            capabilities: presetCapabilities(provider.presetId, id),
          ),
      ];
      await _repository.replaceDiscoveredModels(providerId, models);
      return listModels(providerId);
    } on Exception catch (error) {
      throw StateError('Model discovery failed: $error');
    }
  }

  /// The upsertManualModel public API member.
  Future<ProviderModelDto> upsertManualModel(ProviderModelDto model) {
    return _repository.upsertModel(
      model.copyWith(
        source: ProviderModelSource.manual,
        capabilities: model.capabilities.copyWith(
          source: CapabilitySource.manual,
        ),
      ),
    );
  }

  /// The deleteModel public API member.
  Future<void> deleteModel(String providerId, String modelId) async {
    final model = await _repository.getModel(providerId, modelId);
    if (model == null) return;
    if (model.source != ProviderModelSource.manual) {
      throw StateError('Only manually configured models can be deleted.');
    }
    await _repository.deleteModel(providerId, modelId);
  }

  /// The diagnose public API member.
  Future<ProviderDiagnosticDto> diagnose(
    String providerId,
    String model,
  ) async {
    final checkedAt = _clock.nowUtc();
    try {
      final provider = await resolve(providerId, modelId: model);
      var completed = false;
      var toolCalling = false;
      await for (final event in provider.stream(
        ModelRequest(
          model: model,
          reasoningEffort: 'medium',
          instructions: 'Call the capability_probe tool exactly once.',
          history: const <ConversationItem>[
            UserConversationItem('Run the capability probe.'),
          ],
          tools: const <ModelToolDefinition>[
            ModelToolDefinition(
              name: 'capability_probe',
              description: 'Returns a fixed diagnostic value.',
              parameters: <String, dynamic>{
                'type': 'object',
                'properties': <String, dynamic>{
                  'value': <String, dynamic>{
                    'type': 'string',
                    'enum': <String>['ok'],
                  },
                },
                'required': <String>['value'],
                'additionalProperties': false,
              },
            ),
          ],
          safetyIdentifier: 'provider-diagnostic',
          forceToolName: 'capability_probe',
        ),
        CancellationToken(),
      )) {
        if (event is ModelFunctionCall && event.name == 'capability_probe') {
          toolCalling = true;
        }
        if (event is ModelResponseCompleted) completed = true;
      }
      final status = completed && toolCalling
          ? DiagnosticStatus.verified
          : DiagnosticStatus.failed;
      final result = ProviderDiagnosticDto(
        providerId: providerId,
        model: model,
        status: status,
        endpointReachable: completed,
        streaming: completed,
        toolCalling: toolCalling,
        checkedAt: checkedAt,
        error: status == DiagnosticStatus.failed
            ? 'The provider did not return a streamed tool call.'
            : null,
      );
      await _saveDiagnostic(result);
      return result;
    } on Exception catch (error) {
      return _failedDiagnostic(providerId, model, checkedAt, error);
    }
  }

  Future<ProviderDiagnosticDto> _failedDiagnostic(
    String providerId,
    String model,
    DateTime checkedAt,
    Object error,
  ) async {
    final result = ProviderDiagnosticDto(
      providerId: providerId,
      model: model,
      status: DiagnosticStatus.failed,
      endpointReachable: false,
      streaming: false,
      toolCalling: false,
      checkedAt: checkedAt,
      error: '$error',
    );
    await _saveDiagnostic(result);
    return result;
  }

  /// The resolve public API member.
  Future<ModelProvider> resolve(String providerId, {String? modelId}) async {
    if (_fixedProvider != null) return _fixedProvider;
    final provider = await get(providerId);
    if (!provider.enabled) {
      throw StateError('Provider is disabled: $providerId');
    }
    final key = _apiKey(provider);
    if (provider.credentialSource != CredentialSource.none && key.isEmpty) {
      throw StateError('Provider credential is not configured: $providerId');
    }
    final effectiveModel = modelId ?? provider.defaultModelId;
    final model = effectiveModel == null
        ? null
        : await _repository.getModel(provider.id, effectiveModel);
    final supportsReasoning =
        model?.capabilities.reasoningEffort == CapabilitySupport.supported;
    return _providerFactory.create(
      provider: provider,
      apiKey: key,
      supportsReasoningEffort: supportsReasoning,
    );
  }

  /// The validateAgentModel public API member.
  Future<void> validateAgentModel(String providerId, String modelId) async {
    final provider = await get(providerId);
    if (!provider.enabled) {
      throw StateError('Provider is disabled: $providerId');
    }
    final model = await _repository.getModel(providerId, modelId);
    if (model == null) throw StateError('Unknown provider model: $modelId');
    if (model.capabilities.streaming != CapabilitySupport.supported ||
        model.capabilities.toolCalling != CapabilitySupport.supported) {
      throw StateError(
        'Model streaming and tool calling capabilities must be verified or '
        'configured.',
      );
    }
  }

  Future<ApiProviderDto> _withCredentialStatus(ApiProviderDto provider) async {
    final configured = switch (provider.credentialSource) {
      CredentialSource.none => true,
      CredentialSource.stored =>
        _credentials.providerApiKey(provider.id)?.isNotEmpty == true,
      CredentialSource.environment =>
        _environment[provider.environmentVariable]?.isNotEmpty == true,
    };
    return provider.copyWith(credentialConfigured: configured);
  }

  String _apiKey(ApiProviderDto provider) =>
      switch (provider.credentialSource) {
        CredentialSource.none => '',
        CredentialSource.stored =>
          _credentials.providerApiKey(provider.id) ?? '',
        CredentialSource.environment =>
          _environment[provider.environmentVariable] ?? '',
      };

  Future<void> _saveDiagnostic(ProviderDiagnosticDto result) async {
    final existing = await _repository.getModel(
      result.providerId,
      result.model,
    );
    final base =
        existing ??
        ProviderModelDto(
          providerId: result.providerId,
          id: result.model,
          label: result.model,
          source: ProviderModelSource.manual,
          capabilities: const ModelCapabilitiesDto(),
        );
    await _repository.upsertModel(
      base.copyWith(
        diagnosticStatus: result.status,
        verifiedAt: result.checkedAt,
        diagnosticError: result.error,
        capabilities: base.capabilities.source == CapabilitySource.manual
            ? base.capabilities
            : base.capabilities.copyWith(
                streaming: result.streaming
                    ? CapabilitySupport.supported
                    : CapabilitySupport.unsupported,
                toolCalling: result.toolCalling
                    ? CapabilitySupport.supported
                    : CapabilitySupport.unsupported,
                source: CapabilitySource.diagnostic,
              ),
      ),
    );
  }
}
