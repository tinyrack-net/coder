import 'dart:convert';

import 'package:coder_agent/coder_agent.dart';
import 'package:coder_daemon/src/provider_adapters.dart';
import 'package:coder_daemon/src/provider_auth.dart';
import 'package:coder_daemon/src/provider_catalog.dart';
import 'package:coder_daemon/src/repositories.dart';
import 'package:coder_protocol/coder_protocol.dart';

/// Runtime provider selection resolved from one Markdown agent snapshot.
final class ResolvedAgentModel {
  /// Creates a resolved executable provider and model pair.
  const ResolvedAgentModel({
    required this.connectionId,
    required this.modelId,
    required this.provider,
    this.limits,
  });

  /// Selected provider connection.
  final String connectionId;

  /// Selected model identifier.
  final String modelId;

  /// Executable provider adapter.
  final ModelProvider provider;

  /// Advertised limits of the model, when the catalog knows them.
  final ModelLimitsDto? limits;
}

/// Stable provider connection failure translated to a protocol error code.
final class ProviderConnectionFailure implements Exception {
  /// Creates a provider connection failure.
  const ProviderConnectionFailure(this.code, this.message);

  /// Stable machine-readable error code.
  final String code;

  /// User-safe failure description.
  final String message;

  @override
  String toString() => 'ProviderConnectionFailure($code): $message';
}

/// Settings key holding the daemon-global default model selection.
///
/// An empty stored value means no explicit default, which makes the daemon
/// fall back to the first usable provider model instead.
const String defaultModelSettingKey = 'provider.defaultModel';

/// Owns provider connections while keeping runtime details out of the protocol.
final class ProviderService implements ProviderOAuthConnector {
  /// Creates the provider connection service.
  factory ProviderService({
    required ProviderRepository repository,
    required CredentialRepository credentials,
    required SettingsRepository settings,
    required Map<String, String> environment,
    required Clock clock,
    required ProviderRegistry registry,
    required BuiltInProviderCatalog catalog,
    ProviderModelDiscovery? modelDiscovery,
    ModelProviderFactory? providerFactory,
    ProviderCredentialRefresher? oauthRefresher,
    ModelProvider? fixedProvider,
  }) => ProviderService._(
    repository: repository,
    credentials: credentials,
    settings: settings,
    environment: environment,
    clock: clock,
    registry: registry,
    catalog: catalog,
    modelDiscovery: modelDiscovery,
    providerFactory: providerFactory,
    oauthRefresher: oauthRefresher,
    fixedProvider: fixedProvider,
  );

  ProviderService._({
    required this._repository,
    required this._credentials,
    required this._settings,
    required this._environment,
    required this._clock,
    required this._registry,
    required this._catalog,
    ProviderModelDiscovery? modelDiscovery,
    ModelProviderFactory? providerFactory,
    this._oauthRefresher,
    this._fixedProvider,
  }) : _discoveryOverride = modelDiscovery,
       _factoryOverride = providerFactory;

  final ProviderRepository _repository;
  final SettingsRepository _settings;
  final CredentialRepository _credentials;
  final Map<String, String> _environment;
  final Clock _clock;
  final ProviderRegistry _registry;
  final BuiltInProviderCatalog _catalog;
  final ProviderModelDiscovery? _discoveryOverride;
  final ModelProviderFactory? _factoryOverride;
  final ProviderCredentialRefresher? _oauthRefresher;
  final ModelProvider? _fixedProvider;

  /// The definition a fixed test provider connects under.
  ///
  /// A fixed provider replaces every transport, so which vendor lends its
  /// bundled models is arbitrary; the first registered one keeps embedded
  /// runs deterministic.
  String get _fixedProviderDefinitionId => _registry.plugins.first.id;

  /// Loads secrets and connects built-ins backed by daemon environment keys.
  Future<void> initialize() async {
    await _credentials.load();
    if (_fixedProvider != null &&
        await _repository.getConnection(_fixedProviderDefinitionId) == null) {
      await _initializeFixedProvider();
    }
    for (final plugin in _registry.plugins) {
      if (await _repository.getConnection(plugin.id) != null) {
        continue;
      }
      final environmentCredential = _environmentCredential(plugin);
      if (environmentCredential == null) continue;
      await _connectBuiltIn(
        plugin,
        ProviderAuthKind.apiKey,
        ProviderCredentialOrigin.environment,
        environmentCredential,
      );
    }
  }

  Future<void> _initializeFixedProvider() async {
    final plugin = _registry.require(_fixedProviderDefinitionId);
    final now = _clock.nowUtc();
    final connection = ProviderConnectionDto(
      id: plugin.id,
      definitionId: plugin.id,
      displayName: plugin.definition.name,
      status: ProviderConnectionStatus.connected,
      authKind: ProviderAuthKind.none,
      credentialOrigin: ProviderCredentialOrigin.none,
      createdAt: now,
      updatedAt: now,
    );
    await _repository.upsertConnection(connection);
    await _repository.replaceModels(
      connection.id,
      _seedModels(connection).values,
    );
  }

  /// Returns the safe public provider catalog.
  Future<ProviderCatalogDto> catalog() async => _catalog.catalog();

  /// Marks an explicit catalog refresh while retaining trusted runtime data.
  Future<ProviderCatalogDto> refreshCatalog() async {
    final refreshed = await _catalog.refresh();
    for (final connection in await _repository.listConnections()) {
      if (connection.definitionId == 'custom') continue;
      final models = <String, ProviderModelDto>{
        for (final model in await _repository.listModels(connection.id))
          model.id: model,
      };
      for (final metadata in _catalog.modelsFor(connection.definitionId)) {
        models[metadata.id] = ProviderModelDto(
          connectionId: connection.id,
          id: metadata.id,
          label: metadata.label,
          source:
              _catalog.isRefreshedModel(
                connection.definitionId,
                metadata.id,
              )
              ? ProviderModelSource.refreshed
              : ProviderModelSource.bundled,
          capabilities: metadata.capabilities,
          pricing: metadata.pricing,
          limits: metadata.limits,
        );
      }
      await _repository.replaceModels(connection.id, models.values);
    }
    return refreshed;
  }

  /// Returns all user-owned connections with deterministic ordering.
  Future<List<ProviderConnectionDto>> connections() async {
    final result = await _repository.listConnections();
    result.sort((left, right) => left.displayName.compareTo(right.displayName));
    return result;
  }

  /// Reads the stored daemon-global default model without validating it.
  ///
  /// A stored selection that no longer runs is kept on disk so the settings
  /// page can show it as unavailable instead of silently forgetting it.
  Future<SessionModelSelectionDto?> storedDefaultModel() async {
    final raw = await _settings.getValue(defaultModelSettingKey);
    if (raw == null || raw.isEmpty) return null;
    return SessionModelSelectionDto.fromJson(
      Map<String, dynamic>.from(jsonDecode(raw) as Map),
    );
  }

  /// Replaces or clears the daemon-global default model.
  Future<void> setDefaultModel(SessionModelSelectionDto? model) =>
      _settings.setValue(
        defaultModelSettingKey,
        model == null ? '' : jsonEncode(model.toJson()),
      );

  /// Resolves the model to use when no session or agent selection applies.
  ///
  /// Prefers the stored daemon default and falls through to
  /// [firstUsableModel] when that default no longer runs.
  Future<SessionModelSelectionDto?> fallbackModel() async {
    final stored = await storedDefaultModel();
    if (stored != null && await _isRunnableSelection(stored)) return stored;
    return firstUsableModel();
  }

  /// Returns the first runnable model of the first usable connection.
  ///
  /// Connections arrive sorted by display name and models by label, so the
  /// choice is deterministic and matches what the app shows.
  Future<SessionModelSelectionDto?> firstUsableModel() async {
    for (final connection in await connections()) {
      if (!_canRun(connection.status)) continue;
      for (final model in await _repository.listModels(connection.id)) {
        if (!_isRunnableModel(model)) continue;
        return SessionModelSelectionDto(
          providerConnectionId: connection.id,
          modelId: model.id,
        );
      }
    }
    return null;
  }

  /// Resolves daemon-default or fixed Markdown agent model configuration.
  ///
  /// A fixed selection whose provider or model can no longer run falls back to
  /// the daemon default so a disconnected provider never blocks a turn.
  Future<ResolvedAgentModel> resolveAgentModel(
    AgentModelSelectionDto selection,
  ) async {
    switch (selection.source) {
      case AgentModelSource.session:
        return _resolveFallback();
      case AgentModelSource.fixed:
        final fixedConnection = selection.providerConnectionId;
        final fixedModel = selection.modelId;
        if (fixedConnection == null || fixedModel == null) {
          throw const FormatException(
            'Fixed agent models require a provider and model.',
          );
        }
        final pinned = SessionModelSelectionDto(
          providerConnectionId: fixedConnection,
          modelId: fixedModel,
        );
        if (!await _isRunnableSelection(pinned)) return _resolveFallback();
        return resolveExplicitModel(fixedConnection, fixedModel);
    }
  }

  Future<ResolvedAgentModel> _resolveFallback() async {
    final fallback = await fallbackModel();
    if (fallback == null) {
      throw const ProviderConnectionFailure(
        'model_required',
        'No connected provider offers a usable model.',
      );
    }
    return resolveExplicitModel(
      fallback.providerConnectionId,
      fallback.modelId,
    );
  }

  Future<bool> _isRunnableSelection(SessionModelSelectionDto selection) async {
    final connection = await _repository.getConnection(
      selection.providerConnectionId,
    );
    if (connection == null || !_canRun(connection.status)) return false;
    final model = await _repository.getModel(
      selection.providerConnectionId,
      selection.modelId,
    );
    return model != null && _isRunnableModel(model);
  }

  /// Validates and resolves one explicitly chosen connection and model.
  Future<ResolvedAgentModel> resolveExplicitModel(
    String connectionId,
    String modelId,
  ) async {
    final model = await validateAgentModel(connectionId, modelId);
    return ResolvedAgentModel(
      connectionId: connectionId,
      modelId: modelId,
      provider: await resolve(connectionId, modelId: modelId),
      limits: model.limits,
    );
  }

  /// Returns one connection or fails when it does not exist.
  Future<ProviderConnectionDto> get(String id) async {
    final connection = await _repository.getConnection(id);
    if (connection == null) {
      throw ProviderConnectionFailure(
        'provider_not_connected',
        'Provider connection not found: $id',
      );
    }
    return connection;
  }

  /// Connects a hosted built-in provider with one API key.
  Future<ProviderConnectionDto> connectApiKey(
    String definitionId,
    String apiKey,
  ) async {
    if (apiKey.trim().isEmpty) {
      throw const FormatException('API key must not be empty.');
    }
    final plugin = _registry.require(definitionId);
    if (!_supportsFlow(plugin, ProviderAuthFlow.apiKey)) {
      throw StateError(
        '$definitionId does not support API key authentication.',
      );
    }
    final credential = ApiKeyCredential(apiKey);
    await _credentials.setCredential(definitionId, credential);
    return _connectBuiltIn(
      plugin,
      ProviderAuthKind.apiKey,
      ProviderCredentialOrigin.stored,
      credential,
    );
  }

  /// Connects a local built-in provider without authentication.
  Future<ProviderConnectionDto> connectNone(String definitionId) async {
    final plugin = _registry.require(definitionId);
    if (!_supportsFlow(plugin, ProviderAuthFlow.none)) {
      throw StateError('$definitionId requires authentication.');
    }
    await _credentials.removeCredential(definitionId);
    return _connectBuiltIn(
      plugin,
      ProviderAuthKind.none,
      ProviderCredentialOrigin.none,
      null,
    );
  }

  @override
  Future<void> connectOAuth(
    String definitionId,
    OAuthCredential credential,
  ) async {
    final plugin = _registry.require(definitionId);
    if (!_supportsFlow(plugin, ProviderAuthFlow.oauthBrowser) &&
        !_supportsFlow(plugin, ProviderAuthFlow.oauthDevice)) {
      throw StateError('$definitionId does not support OAuth.');
    }
    await _credentials.setCredential(definitionId, credential);
    await _connectBuiltIn(
      plugin,
      ProviderAuthKind.oauth,
      ProviderCredentialOrigin.oauth,
      credential,
    );
  }

  /// Creates an advanced custom OpenAI-compatible connection.
  Future<ProviderConnectionDto> createCustom(
    String id,
    CustomProviderConfigDto config, {
    String? apiKey,
  }) async {
    if (id.trim().isEmpty) {
      throw const FormatException('Custom provider ID must not be empty.');
    }
    if (await _repository.getConnection(id) != null) {
      throw StateError('Provider connection already exists: $id');
    }
    final normalized = _validateCustom(config);
    final credential = _customCredential(normalized, apiKey);
    if (credential != null) {
      await _credentials.setCredential(id, credential);
    }
    final now = _clock.nowUtc();
    final connection = ProviderConnectionDto(
      id: id,
      definitionId: 'custom',
      displayName: normalized.name,
      status: ProviderConnectionStatus.connecting,
      authKind: normalized.authenticationRequired
          ? ProviderAuthKind.apiKey
          : ProviderAuthKind.none,
      credentialOrigin: credential == null
          ? ProviderCredentialOrigin.none
          : ProviderCredentialOrigin.stored,
      createdAt: now,
      updatedAt: now,
      customConfig: normalized,
    );
    return _discoverAndSave(connection, credential);
  }

  /// Updates advanced settings for an existing custom connection.
  Future<ProviderConnectionDto> updateCustom(
    String id,
    CustomProviderConfigDto config, {
    String? apiKey,
  }) async {
    final current = await get(id);
    if (current.definitionId != 'custom') {
      throw StateError('Built-in provider configuration is immutable.');
    }
    final normalized = _validateCustom(config);
    var credential = _credentials.credential(id);
    if (apiKey != null) {
      credential = _customCredential(normalized, apiKey);
      if (credential == null) {
        await _credentials.removeCredential(id);
      } else {
        await _credentials.setCredential(id, credential);
      }
    }
    final updated = current.copyWith(
      displayName: normalized.name,
      status: ProviderConnectionStatus.connecting,
      authKind: normalized.authenticationRequired
          ? ProviderAuthKind.apiKey
          : ProviderAuthKind.none,
      credentialOrigin: credential == null
          ? ProviderCredentialOrigin.none
          : ProviderCredentialOrigin.stored,
      updatedAt: _clock.nowUtc(),
      customConfig: normalized,
      error: null,
    );
    return _discoverAndSave(updated, credential);
  }

  /// Disconnects a provider but preserves agents and historical metadata.
  Future<void> disconnect(String id) async {
    final connection = await get(id);
    await _credentials.removeCredential(id);
    await _repository.upsertConnection(
      connection.copyWith(
        status: ProviderConnectionStatus.disconnected,
        credentialOrigin: ProviderCredentialOrigin.none,
        updatedAt: _clock.nowUtc(),
        error: null,
      ),
    );
  }

  /// Permanently removes a custom provider connection.
  Future<void> deleteCustom(String id) async {
    final connection = await get(id);
    if (connection.definitionId != 'custom') {
      throw StateError('Built-in provider connections cannot be deleted.');
    }
    await _credentials.removeCredential(id);
    await _repository.deleteConnection(id);
  }

  /// Returns cached and discovered models for a connection.
  Future<List<ProviderModelDto>> listModels(String connectionId) =>
      _repository.listModels(connectionId);

  /// Creates an executable provider without exposing secrets or endpoints.
  Future<ModelProvider> resolve(
    String connectionId, {
    required String modelId,
  }) async {
    if (_fixedProvider != null) return _fixedProvider;
    final connection = await get(connectionId);
    if (!_canRun(connection.status)) {
      throw ProviderConnectionFailure(
        'provider_not_connected',
        'Provider is not connected: $connectionId',
      );
    }
    var credential = _credentialFor(connection);
    if (connection.authKind != ProviderAuthKind.none && credential == null) {
      throw ProviderConnectionFailure(
        'provider_not_connected',
        'Provider credential is not configured: $connectionId',
      );
    }
    if (credential case final OAuthCredential oauthCredential
        when !oauthCredential.expiresAt.isAfter(
          _clock.nowUtc().add(const Duration(minutes: 5)),
        )) {
      credential = await _refreshOAuth(connection, oauthCredential);
    }
    final model = await _repository.getModel(connectionId, modelId);
    final request = ModelProviderRequest(
      connectionId: connection.id,
      endpoint: _endpointFor(connection),
      credential: credential,
      capabilities: model?.capabilities ?? const ModelCapabilitiesDto(),
    );
    final override = _factoryOverride;
    if (override != null) return override.create(request);
    return _adapterSourceFor(connection).createProvider(request);
  }

  Future<OAuthCredential> _refreshOAuth(
    ProviderConnectionDto connection,
    OAuthCredential credential,
  ) async {
    final refresher = _oauthRefresher;
    if (refresher == null) {
      throw StateError('OAuth credential refresh is not configured.');
    }
    try {
      final refreshed = await refresher.refresh(connection.id, credential);
      await _credentials.setCredential(connection.id, refreshed);
      return refreshed;
    } on OAuthRefreshFailure catch (failure) {
      if (failure.reauthRequired) {
        await _repository.upsertConnection(
          connection.copyWith(
            status: ProviderConnectionStatus.reauthRequired,
            updatedAt: _clock.nowUtc(),
            error: failure.message,
          ),
        );
      }
      throw ProviderConnectionFailure(
        failure.reauthRequired
            ? 'provider_not_connected'
            : 'provider_unavailable',
        failure.message,
      );
    }
  }

  /// Verifies that a connected model can stream and call coding tools.
  ///
  /// Returns the validated model so a caller that needs its metadata, such as
  /// the context window, does not have to read it a second time.
  Future<ProviderModelDto> validateAgentModel(
    String connectionId,
    String modelId,
  ) async {
    final connection = await get(connectionId);
    if (!_canRun(connection.status)) {
      throw ProviderConnectionFailure(
        'provider_not_connected',
        'Provider is not connected: $connectionId',
      );
    }
    final model = await _repository.getModel(connectionId, modelId);
    if (model == null) throw StateError('Unknown provider model: $modelId');
    if (!_isRunnableModel(model)) {
      throw StateError(
        'Model streaming and tool calling capabilities must be supported.',
      );
    }
    return model;
  }

  Future<ProviderConnectionDto> _connectBuiltIn(
    ProviderPlugin plugin,
    ProviderAuthKind authKind,
    ProviderCredentialOrigin origin,
    ProviderCredential? credential,
  ) async {
    final existing = await _repository.getConnection(plugin.id);
    final now = _clock.nowUtc();
    final connection = ProviderConnectionDto(
      id: plugin.id,
      definitionId: plugin.id,
      displayName: plugin.definition.name,
      status: ProviderConnectionStatus.connecting,
      authKind: authKind,
      credentialOrigin: origin,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    return _discoverAndSave(connection, credential);
  }

  Future<ProviderConnectionDto> _discoverAndSave(
    ProviderConnectionDto connection,
    ProviderCredential? credential,
  ) async {
    await _repository.upsertConnection(connection);
    final endpoint = _endpointFor(connection);
    final models = _seedModels(connection);
    ProviderConnectionStatus status;
    String? error;
    if (!endpoint.supportsModelDiscovery) {
      // The bundled catalog is already the complete model set for endpoints
      // without a `/models` listing, so a discovery request would only fail.
      status = ProviderConnectionStatus.connected;
    } else {
      try {
        final discovered = await _discoverModels(
          connection,
          endpoint,
          credential,
        );
        for (final modelId in discovered) {
          models.putIfAbsent(
            modelId,
            () => ProviderModelDto(
              connectionId: connection.id,
              id: modelId,
              label: modelId,
              source: ProviderModelSource.discovered,
              capabilities: _catalogCapabilities(
                connection.definitionId,
                modelId,
              ),
            ),
          );
        }
        status = ProviderConnectionStatus.connected;
      } on ProviderDiscoveryFailure catch (failure) {
        error = failure.message;
        status = switch (failure.kind) {
          ProviderDiscoveryFailureKind.invalidCredential =>
            ProviderConnectionStatus.error,
          ProviderDiscoveryFailureKind.unavailable =>
            ProviderConnectionStatus.degraded,
        };
      }
    }
    await _repository.replaceModels(connection.id, models.values);
    final saved = connection.copyWith(
      status: status,
      updatedAt: _clock.nowUtc(),
      error: error,
    );
    await _repository.upsertConnection(saved);
    return (await _repository.getConnection(saved.id)) ?? saved;
  }

  Map<String, ProviderModelDto> _seedModels(
    ProviderConnectionDto connection,
  ) {
    final result = <String, ProviderModelDto>{};
    for (final model in _catalog.modelsFor(connection.definitionId)) {
      result[model.id] = ProviderModelDto(
        connectionId: connection.id,
        id: model.id,
        label: model.label,
        source: _catalog.isRefreshedModel(connection.definitionId, model.id)
            ? ProviderModelSource.refreshed
            : ProviderModelSource.bundled,
        capabilities: model.capabilities,
        pricing: model.pricing,
        limits: model.limits,
      );
    }
    for (final modelId
        in connection.customConfig?.manualModelIds ?? const <String>[]) {
      result[modelId] = ProviderModelDto(
        connectionId: connection.id,
        id: modelId,
        label: modelId,
        source: ProviderModelSource.manual,
        capabilities: const ModelCapabilitiesDto(
          streaming: CapabilitySupport.supported,
          toolCalling: CapabilitySupport.supported,
          source: CapabilitySource.manual,
        ),
      );
    }
    return result;
  }

  ModelCapabilitiesDto _catalogCapabilities(
    String definitionId,
    String modelId,
  ) =>
      _catalog
          .modelsFor(definitionId)
          .where((model) => model.id == modelId)
          .map((model) => model.capabilities)
          .firstOrNull ??
      const ModelCapabilitiesDto();

  ProviderEndpoint _endpointFor(ProviderConnectionDto connection) {
    final custom = connection.customConfig;
    if (custom != null) {
      return ProviderEndpoint(
        baseUrl: custom.baseUrl,
        strictToolSchema: custom.strictToolSchema,
      );
    }
    return _registry
        .require(connection.definitionId)
        .endpoint(connection.authKind);
  }

  /// The plugin or wire protocol that builds and discovers for [connection].
  ///
  /// A built-in connection asks its vendor; a custom connection asks the wire
  /// protocol its configuration names.
  ({
    ModelProvider Function(ModelProviderRequest request) createProvider,
    Future<List<String>> Function(
      ProviderEndpoint endpoint,
      ProviderCredential? credential,
    )
    discoverModels,
  })
  _adapterSourceFor(ProviderConnectionDto connection) {
    final custom = connection.customConfig;
    if (custom != null) {
      final wire = _registry.requireWire(_wireIdFor(custom));
      return (
        createProvider: wire.createProvider,
        discoverModels: wire.discoverModels,
      );
    }
    final plugin = _registry.require(connection.definitionId);
    return (
      createProvider: plugin.createProvider,
      discoverModels: plugin.discoverModels,
    );
  }

  Future<List<String>> _discoverModels(
    ProviderConnectionDto connection,
    ProviderEndpoint endpoint,
    ProviderCredential? credential,
  ) {
    final override = _discoveryOverride;
    if (override != null) return override.fetchModelIds(endpoint, credential);
    return _adapterSourceFor(
      connection,
    ).discoverModels(endpoint, credential);
  }

  // TODO(wire-format): the protocol still stores an enum named after the two
  // OpenAI APIs; once it stores the wire id itself this mapping disappears.
  static String _wireIdFor(CustomProviderConfigDto config) =>
      switch (config.apiFormat) {
        ProviderApiFormat.responses => 'openai-responses',
        ProviderApiFormat.chatCompletions => 'openai-chat-completions',
      };

  ProviderCredential? _credentialFor(ProviderConnectionDto connection) =>
      switch (connection.credentialOrigin) {
        ProviderCredentialOrigin.stored || ProviderCredentialOrigin.oauth =>
          _credentials.credential(connection.id),
        ProviderCredentialOrigin.environment => _environmentCredential(
          _registry.require(connection.definitionId),
        ),
        ProviderCredentialOrigin.none => null,
      };

  ApiKeyCredential? _environmentCredential(ProviderPlugin plugin) {
    for (final name in plugin.environmentVariables) {
      final value = _environment[name];
      if (value != null && value.isNotEmpty) return ApiKeyCredential(value);
    }
    return null;
  }

  static bool _supportsFlow(
    ProviderPlugin plugin,
    ProviderAuthFlow flow,
  ) => plugin.definition.authMethods.any((method) => method.flow == flow);

  static bool _canRun(ProviderConnectionStatus status) =>
      status == ProviderConnectionStatus.connected ||
      status == ProviderConnectionStatus.degraded;

  /// Whether a model advertises everything a coding turn needs.
  ///
  /// [validateAgentModel] and the fallback chain share this predicate so the
  /// chain never hands back a model the validator would reject.
  static bool _isRunnableModel(ProviderModelDto model) =>
      model.capabilities.streaming == CapabilitySupport.supported &&
      model.capabilities.toolCalling == CapabilitySupport.supported;

  static ApiKeyCredential? _customCredential(
    CustomProviderConfigDto config,
    String? apiKey,
  ) {
    if (!config.authenticationRequired) return null;
    if (apiKey == null || apiKey.trim().isEmpty) {
      throw const FormatException('This custom provider requires an API key.');
    }
    return ApiKeyCredential(apiKey);
  }

  static CustomProviderConfigDto _validateCustom(
    CustomProviderConfigDto config,
  ) {
    final uri = Uri.tryParse(config.baseUrl);
    if (uri == null ||
        !uri.hasAuthority ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw const FormatException(
        'Custom provider base URL must be an absolute HTTP(S) URL.',
      );
    }
    return config.copyWith(
      name: config.name.trim(),
      baseUrl: config.baseUrl.replaceAll(RegExp(r'/+$'), ''),
      manualModelIds: config.manualModelIds
          .map((id) => id.trim())
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList(growable: false),
    );
  }
}
