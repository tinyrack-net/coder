import 'dart:io';

import 'package:coder_agent/coder_agent.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:coder_provider_openai/coder_provider_openai.dart';
import 'package:dio/dio.dart';

import 'credential_store.dart';
import 'database.dart';

class ProviderService {
  ProviderService({
    required CoderDatabase database,
    required CredentialStore credentials,
    Map<String, String>? environment,
    ModelProvider? fixedProvider,
  }) : _database = database,
       _credentials = credentials,
       _environment = environment ?? Platform.environment,
       _fixedProvider = fixedProvider;

  final CoderDatabase _database;
  final CredentialStore _credentials;
  final Map<String, String> _environment;
  final ModelProvider? _fixedProvider;

  Future<void> initialize({String? legacyOpenAIKey}) async {
    await _credentials.load();
    final existing = await _database.getProviderDto('openai');
    if (existing == null) {
      final now = DateTime.now().toUtc();
      await _database.upsertProvider(
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
      await _database.setSetting('provider.defaultId', 'openai');
    }
    if (legacyOpenAIKey?.isNotEmpty == true) {
      await _credentials.setProviderApiKey('openai', legacyOpenAIKey!);
    }
    for (final model in const <String>[
      'gpt-5.6-sol',
      'gpt-5.6-terra',
      'gpt-5.6-luna',
    ]) {
      if (await _database.getProviderModelDto('openai', model) == null) {
        await _database.upsertProviderModel(
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

  Future<ProviderCatalogDto> catalog() async {
    final providers = await _database.listProviderDtos();
    return ProviderCatalogDto(
      providers: await Future.wait(providers.map(_withCredentialStatus)),
      presets: openAICompatiblePresets,
      defaultProviderId: await _database.getSetting('provider.defaultId'),
    );
  }

  Future<ApiProviderDto> get(String id) async {
    final provider = await _database.getProviderDto(id);
    if (provider == null) throw StateError('Provider not found: $id');
    return _withCredentialStatus(provider);
  }

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
    final stored = await _database.upsertProvider(
      provider.copyWith(
        credentialConfigured: false,
        baseUrl: provider.baseUrl.replaceAll(RegExp(r'/+$'), ''),
        updatedAt: DateTime.now().toUtc(),
      ),
    );
    await _ensurePresetModels(stored);
    if (makeDefault) {
      await _database.setSetting('provider.defaultId', provider.id);
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
      if (await _database.getProviderModelDto(provider.id, modelId) != null) {
        continue;
      }
      await _database.upsertProviderModel(
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

  Future<void> delete(String id) async {
    await _database.deleteProvider(id);
    await _credentials.removeProvider(id);
    if (await _database.getSetting('provider.defaultId') == id) {
      await _database.setSetting('provider.defaultId', '');
    }
  }

  Future<void> setCredential(String providerId, String value) async {
    final provider = await get(providerId);
    if (provider.credentialSource != CredentialSource.stored) {
      throw StateError('Provider does not use stored credentials.');
    }
    await _credentials.setProviderApiKey(providerId, value);
  }

  Future<List<ProviderModelDto>> listModels(String providerId) async {
    final provider = await get(providerId);
    final models = await _database.listProviderModelDtos(providerId);
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

  Future<List<ProviderModelDto>> refreshModels(String providerId) async {
    final provider = await get(providerId);
    final apiKey = _apiKey(provider);
    try {
      final dio = Dio(BaseOptions(baseUrl: provider.baseUrl));
      final response = await dio.get<Map<String, dynamic>>(
        '/models',
        options: Options(
          headers: <String, String>{
            if (apiKey.isNotEmpty) 'Authorization': 'Bearer $apiKey',
          },
        ),
      );
      final data = response.data?['data'];
      if (data is! List) {
        throw const FormatException('The /models response has no data list.');
      }
      final models = <ProviderModelDto>[];
      for (final raw in data.whereType<Map>()) {
        final id = raw['id'];
        if (id is! String || id.trim().isEmpty) continue;
        models.add(
          ProviderModelDto(
            providerId: providerId,
            id: id,
            label: id,
            source: ProviderModelSource.discovered,
            capabilities: presetCapabilities(provider.presetId, id),
          ),
        );
      }
      await _database.replaceDiscoveredModels(providerId, models);
      return listModels(providerId);
    } on DioException catch (error) {
      final message = error.response?.data ?? error.message ?? '$error';
      throw StateError('Model discovery failed: $message');
    }
  }

  Future<ProviderModelDto> upsertManualModel(ProviderModelDto model) {
    return _database.upsertProviderModel(
      model.copyWith(
        source: ProviderModelSource.manual,
        capabilities: model.capabilities.copyWith(
          source: CapabilitySource.manual,
        ),
      ),
    );
  }

  Future<void> deleteModel(String providerId, String modelId) async {
    final model = await _database.getProviderModelDto(providerId, modelId);
    if (model == null) return;
    if (model.source != ProviderModelSource.manual) {
      throw StateError('Only manually configured models can be deleted.');
    }
    await _database.deleteProviderModel(providerId, modelId);
  }

  Future<ProviderDiagnosticDto> diagnose(
    String providerId,
    String model,
  ) async {
    final checkedAt = DateTime.now().toUtc();
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
    } catch (error) {
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
  }

  Future<ModelProvider> resolve(String providerId, {String? modelId}) async {
    if (_fixedProvider != null) return _fixedProvider;
    final provider = await get(providerId);
    if (!provider.enabled)
      throw StateError('Provider is disabled: $providerId');
    final key = _apiKey(provider);
    if (provider.credentialSource != CredentialSource.none && key.isEmpty) {
      throw StateError('Provider credential is not configured: $providerId');
    }
    final effectiveModel = modelId ?? provider.defaultModelId;
    final model = effectiveModel == null
        ? null
        : await _database.getProviderModelDto(provider.id, effectiveModel);
    final supportsReasoning =
        model?.capabilities.reasoningEffort == CapabilitySupport.supported;
    final config = OpenAIProviderConfig(
      id: provider.id,
      apiKey: key,
      baseUrl: provider.baseUrl,
      requiresApiKey: provider.credentialSource != CredentialSource.none,
      supportsReasoningEffort: supportsReasoning,
      strictToolSchema: provider.strictToolSchema,
    );
    return switch (provider.transport) {
      ApiTransport.responses => OpenAIResponsesProvider(config),
      ApiTransport.chatCompletions => OpenAIChatCompletionsProvider(config),
    };
  }

  Future<void> validateAgentModel(String providerId, String modelId) async {
    final provider = await get(providerId);
    if (!provider.enabled)
      throw StateError('Provider is disabled: $providerId');
    final model = await _database.getProviderModelDto(providerId, modelId);
    if (model == null) throw StateError('Unknown provider model: $modelId');
    if (model.capabilities.streaming != CapabilitySupport.supported ||
        model.capabilities.toolCalling != CapabilitySupport.supported) {
      throw StateError(
        'Model streaming and tool calling capabilities must be verified or configured.',
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
    final existing = await _database.getProviderModelDto(
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
    await _database.upsertProviderModel(
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
