import 'dart:async';

import 'package:coder_app/src/features/hosts/application/host_controller.dart';
import 'package:coder_app/src/features/providers/application/session_model_options.dart';
import 'package:coder_client/coder_client.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'provider_settings_controller.g.dart';

/// ProviderSettingsState defines a public contract.
final class ProviderSettingsState {
  /// Creates a [ProviderSettingsState].
  const ProviderSettingsState({
    required this.catalog,
    required this.connections,
    this.defaultModel,
    this.models = const <String, List<ProviderModelDto>>{},
    this.authAttempts = const <String, ProviderAuthAttemptDto>{},
  });

  /// The catalog public API member.
  final ProviderCatalogDto catalog;

  /// User-owned provider connections.
  final List<ProviderConnectionDto> connections;

  /// Daemon-global default model, or null when the daemon picks the first one.
  final SessionModelSelectionDto? defaultModel;

  /// The models public API member.
  final Map<String, List<ProviderModelDto>> models;

  /// Transient interactive authorization attempts.
  final Map<String, ProviderAuthAttemptDto> authAttempts;

  /// The copyWith public API member.
  ProviderSettingsState copyWith({
    ProviderCatalogDto? catalog,
    List<ProviderConnectionDto>? connections,
    SessionModelSelectionDto? defaultModel,
    Map<String, List<ProviderModelDto>>? models,
    Map<String, ProviderAuthAttemptDto>? authAttempts,
    bool clearDefaultModel = false,
  }) => ProviderSettingsState(
    catalog: catalog ?? this.catalog,
    connections: connections ?? this.connections,
    defaultModel: clearDefaultModel ? null : defaultModel ?? this.defaultModel,
    models: models ?? this.models,
    authAttempts: authAttempts ?? this.authAttempts,
  );
}

@Riverpod(keepAlive: true)
/// ProviderSettingsController defines a public contract.
class ProviderSettingsController extends _$ProviderSettingsController {
  StreamSubscription<ProviderAuthAttemptDto>? _events;
  StreamSubscription<ProviderCatalogDto>? _catalogEvents;

  @override
  Future<ProviderSettingsState?> build(String hostId) async {
    final runtime = (await ref.watch(
      hostRegistryControllerProvider.future,
    )).runtimes[hostId];
    if (runtime?.connected != true) return null;
    final api = runtime!.api!;
    _events = api.providers.authUpdates.listen(_handleEvent);
    _catalogEvents = api.providers.catalogUpdates.listen(_handleCatalogEvent);
    ref.onDispose(() {
      unawaited(_events?.cancel());
      unawaited(_catalogEvents?.cancel());
    });
    final connections = await api.providers.listProviderConnections();
    final defaultModel = await api.providers.getDefaultModel();
    return ProviderSettingsState(
      catalog: await api.providers.listProviderCatalog(),
      connections: connections,
      defaultModel: defaultModel,
      models: await _resolutionModels(api, connections, defaultModel),
    );
  }

  /// Loads the model lists the composer needs to resolve a model eagerly.
  ///
  /// Only the stored default's connection and the first usable connection can
  /// win the fallback chain, so this stays two requests regardless of how many
  /// providers are connected. Awaiting it inside [build] means the composer
  /// never observes a frame where connections are known but models are not.
  Future<Map<String, List<ProviderModelDto>>> _resolutionModels(
    CoderApi api,
    List<ProviderConnectionDto> connections,
    SessionModelSelectionDto? defaultModel,
  ) async {
    final usable = usableConnections(connections);
    final wanted = <String>{
      if (defaultModel != null &&
          usable.any(
            (connection) => connection.id == defaultModel.providerConnectionId,
          ))
        defaultModel.providerConnectionId,
      if (usable.isNotEmpty) usable.first.id,
    };
    final loaded = <String, List<ProviderModelDto>>{};
    for (final connectionId in wanted) {
      loaded[connectionId] = await api.providers.listProviderModels(
        connectionId,
      );
    }
    return loaded;
  }

  /// Replaces or clears the daemon-global default model.
  Future<void> setDefaultModel(SessionModelSelectionDto? model) async {
    final api = await _requireConnection();
    await api.providers.setDefaultModel(model);
    await _reload(api);
  }

  /// The loadModels public API member.
  Future<void> loadModels(String connectionId) async {
    final runtime = (await ref.read(
      hostRegistryControllerProvider.future,
    )).runtimes[hostId];
    if (runtime?.connected != true || state.asData?.value == null) return;
    final models = await runtime!.api!.providers.listProviderModels(
      connectionId,
    );
    final current = state.asData?.value;
    if (current == null) return;
    state = AsyncData<ProviderSettingsState?>(
      current.copyWith(
        models: <String, List<ProviderModelDto>>{
          ...current.models,
          connectionId: models,
        },
      ),
    );
  }

  /// Connects a hosted built-in provider with an API key.
  Future<ProviderConnectionDto> connectApiKey(
    String definitionId,
    String apiKey,
  ) async {
    final api = await _requireConnection();
    final result = await api.providers.connectProviderApiKey(
      definitionId,
      apiKey,
    );
    await _reload(api);
    return result;
  }

  /// Connects a local built-in provider without authentication.
  Future<ProviderConnectionDto> connectNone(String definitionId) async {
    final api = await _requireConnection();
    final result = await api.providers.connectProviderNone(definitionId);
    await _reload(api);
    return result;
  }

  /// Starts one provider's browser or device-code authorization.
  Future<ProviderAuthAttemptDto> startAuth(
    String definitionId,
    String methodId,
  ) async {
    final api = await _requireConnection();
    final attempt = await api.providers.startProviderAuth(
      definitionId,
      methodId,
    );
    final current = state.asData?.value;
    if (current != null) {
      state = AsyncData<ProviderSettingsState?>(
        current.copyWith(
          authAttempts: <String, ProviderAuthAttemptDto>{
            ...current.authAttempts,
            attempt.id: attempt,
          },
        ),
      );
    }
    return attempt;
  }

  /// Cancels an interactive authorization attempt.
  Future<void> cancelAuth(String attemptId) async {
    final api = await _requireConnection();
    await api.providers.cancelProviderAuth(attemptId);
  }

  /// Disconnects a provider connection while retaining history.
  Future<void> disconnect(String connectionId) async {
    final api = await _requireConnection();
    await api.providers.disconnectProvider(connectionId);
    await _reload(api);
  }

  /// Explicitly refreshes catalog metadata.
  Future<void> refreshCatalog() async {
    final api = await _requireConnection();
    final catalog = await api.providers.refreshProviderCatalog();
    final current = state.asData?.value;
    if (current != null) {
      state = AsyncData<ProviderSettingsState?>(
        current.copyWith(catalog: catalog),
      );
    }
  }

  /// Creates an advanced custom provider speaking a registered wire format.
  Future<ProviderConnectionDto> createCustom(
    String id,
    CustomProviderConfigDto config, {
    String? apiKey,
  }) async {
    final api = await _requireConnection();
    final result = await api.providers.createCustomProvider(
      id,
      config,
      apiKey: apiKey,
    );
    await _reload(api);
    return result;
  }

  /// Updates an advanced custom provider.
  Future<ProviderConnectionDto> updateCustom(
    String connectionId,
    CustomProviderConfigDto config, {
    String? apiKey,
  }) async {
    final api = await _requireConnection();
    final result = await api.providers.updateCustomProvider(
      connectionId,
      config,
      apiKey: apiKey,
    );
    await _reload(api);
    return result;
  }

  /// Deletes an advanced custom connection.
  Future<void> deleteCustom(String connectionId) async {
    final api = await _requireConnection();
    await api.providers.deleteCustomProvider(connectionId);
    await _reload(api);
  }

  Future<CoderApi> _requireConnection() => requireHostApi(ref, hostId);

  Future<void> _reload(CoderApi api) async {
    final current = state.asData?.value;
    final ProviderCatalogDto catalog;
    final List<ProviderConnectionDto> connections;
    final SessionModelSelectionDto? defaultModel;
    final Map<String, List<ProviderModelDto>> resolutionModels;
    try {
      catalog = await api.providers.listProviderCatalog();
      connections = await api.providers.listProviderConnections();
      defaultModel = await api.providers.getDefaultModel();
      // Connecting or disconnecting changes which connection resolves first.
      resolutionModels = await _resolutionModels(
        api,
        connections,
        defaultModel,
      );
    } on CoderClientException catch (error, stackTrace) {
      // A refresh that loses its daemon must not escape as an unhandled error.
      if (ref.mounted) {
        state = AsyncError<ProviderSettingsState?>(error, stackTrace);
      }
      return;
    }
    if (!ref.mounted) return;
    state = AsyncData<ProviderSettingsState?>(
      ProviderSettingsState(
        catalog: catalog,
        connections: connections,
        defaultModel: defaultModel,
        models: <String, List<ProviderModelDto>>{
          ...?current?.models,
          ...resolutionModels,
        },
        authAttempts:
            current?.authAttempts ?? const <String, ProviderAuthAttemptDto>{},
      ),
    );
  }

  void _handleEvent(ProviderAuthAttemptDto attempt) {
    if (!ref.mounted) return;
    final current = state.asData?.value;
    if (current == null) return;
    state = AsyncData<ProviderSettingsState?>(
      current.copyWith(
        authAttempts: <String, ProviderAuthAttemptDto>{
          ...current.authAttempts,
          attempt.id: attempt,
        },
      ),
    );
    if (attempt.status == ProviderAuthAttemptStatus.succeeded) {
      unawaited(_requireConnection().then(_reload));
    }
  }

  void _handleCatalogEvent(ProviderCatalogDto catalog) {
    if (!ref.mounted) return;
    final current = state.asData?.value;
    if (current == null) return;
    state = AsyncData<ProviderSettingsState?>(
      current.copyWith(catalog: catalog),
    );
  }
}
