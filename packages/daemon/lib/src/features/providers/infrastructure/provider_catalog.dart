import 'package:agent/agent.dart';
import 'package:daemon/src/features/providers/infrastructure/bundled_models_dev.dart';
import 'package:daemon/src/shared/ports/agent_protocol_mapping.dart';
import 'package:dio/dio.dart';
import 'package:protocol/protocol.dart';

/// Safe model metadata returned by an external catalog.
final class ProviderCatalogMetadata {
  /// Creates safe model metadata without provider runtime configuration.
  const ProviderCatalogMetadata({
    required this.id,
    required this.label,
    required this.capabilities,
    this.pricing,
    this.limits,
  });

  /// Provider-local model identifier.
  final String id;

  /// Human-readable model label.
  final String label;

  /// Streaming, tool, and reasoning capability metadata.
  final ModelCapabilitiesDto capabilities;

  /// Optional USD prices per million tokens.
  final ModelPricingDto? pricing;

  /// Optional token limits.
  final ModelLimitsDto? limits;
}

/// Fetches model-only metadata for an explicit catalog refresh.
abstract interface class ProviderCatalogMetadataSource {
  /// Fetches metadata only for trusted built-in provider IDs.
  Future<Map<String, List<ProviderCatalogMetadata>>> fetch(
    Set<String> providerIds,
  );

  /// Cancels owned requests and releases transport resources.
  Future<void> close();
}

/// Models.dev adapter. Provider endpoints and auth fields are never parsed.
final class ModelsDevCatalogMetadataSource
    implements ProviderCatalogMetadataSource {
  /// Creates the production Models.dev adapter.
  ModelsDevCatalogMetadataSource({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: 'https://models.dev',
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ),
          );

  final Dio _dio;
  String? _etag;
  Map<String, List<ProviderCatalogMetadata>>? _lastFetched;

  @override
  Future<void> close() async => _dio.close(force: true);

  @override
  Future<Map<String, List<ProviderCatalogMetadata>>> fetch(
    Set<String> providerIds,
  ) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api.json',
      options: Options(
        headers: <String, String>{'If-None-Match': ?_etag},
        validateStatus: (status) =>
            status != null &&
            ((status >= 200 && status < 300) || status == 304),
      ),
    );
    if (response.statusCode == 304) {
      final cached = _lastFetched;
      if (cached == null) {
        throw const FormatException('Models.dev returned 304 without a cache.');
      }
      return cached;
    }
    final data = response.data;
    if (data == null) {
      throw const FormatException('Models.dev returned an empty catalog.');
    }
    final parsed = <String, List<ProviderCatalogMetadata>>{
      for (final providerId in providerIds)
        if (data[providerId] case final Map<String, dynamic> provider)
          providerId: _parseModels(provider, providerId),
    };
    _etag = response.headers.value('etag');
    _lastFetched = parsed;
    return parsed;
  }

  static List<ProviderCatalogMetadata> _parseModels(
    Map<String, dynamic> provider,
    String providerId,
  ) {
    final models = provider['models'];
    if (models is! Map<String, dynamic>) {
      return const <ProviderCatalogMetadata>[];
    }
    final result = <ProviderCatalogMetadata>[];
    for (final entry in models.entries) {
      if (entry.value is! Map<String, dynamic>) continue;
      final model = entry.value! as Map<String, dynamic>;
      final id = model['id'];
      if (id is! String || id.isEmpty) continue;
      final reasoning = model['reasoning'] == true;
      final toolCalling = model['tool_call'] == true;
      result.add(
        ProviderCatalogMetadata(
          id: id,
          label: model['name'] is String ? model['name']! as String : id,
          capabilities: ModelCapabilitiesDto(
            streaming: CapabilitySupport.supported,
            toolCalling: toolCalling
                ? CapabilitySupport.supported
                : CapabilitySupport.unsupported,
            functionTools: toolCalling
                ? CapabilitySupport.supported
                : CapabilitySupport.unsupported,
            controls: reasoning
                ? <ModelControlDescriptorDto>[
                    ModelControlDescriptorDto(
                      id: AgentModelControlIds.reasoningEffort,
                      label: 'Reasoning effort',
                      kind: ModelControlKind.choice,
                      presentation: ModelControlPresentation.menuChip,
                      choices: <ModelControlChoiceDto>[
                        for (final effort in _reasoningEfforts(model))
                          ModelControlChoiceDto(
                            id: effort,
                            label: _controlLabel(effort),
                          ),
                      ],
                    ),
                  ]
                : const <ModelControlDescriptorDto>[],
            source: CapabilitySource.refreshed,
          ),
          pricing: _pricing(model['cost']),
          limits: _limits(model['limit']),
        ),
      );
    }
    result.sort((left, right) => left.id.compareTo(right.id));
    return result;
  }

  static List<String> _reasoningEfforts(Map<String, dynamic> model) {
    final options = model['reasoning_options'];
    if (options is! List<dynamic>) return const <String>[];
    final efforts = <String>[];
    for (final option in options) {
      if (option is! Map<String, dynamic> || option['type'] != 'effort') {
        continue;
      }
      final values = option['values'];
      if (values is! List<dynamic>) continue;
      efforts.addAll(values.whereType<String>());
    }
    return efforts.toSet().toList(growable: false);
  }

  static String _controlLabel(String value) => value
      .split('_')
      .map(
        (word) => word.isEmpty
            ? word
            : '${word.substring(0, 1).toUpperCase()}${word.substring(1)}',
      )
      .join(' ');

  static ModelPricingDto? _pricing(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    return ModelPricingDto(
      input: _double(value['input']),
      output: _double(value['output']),
      cacheRead: _double(value['cache_read']),
      cacheWrite: _double(value['cache_write']),
    );
  }

  static ModelLimitsDto? _limits(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    return ModelLimitsDto(
      context: _int(value['context']),
      input: _int(value['input']),
      output: _int(value['output']),
    );
  }

  static double? _double(Object? value) =>
      value is num ? value.toDouble() : null;

  static int? _int(Object? value) => value is num ? value.toInt() : null;
}

/// Read-only catalog of provider definitions trusted by the daemon.
final class BuiltInProviderCatalog {
  /// Creates a catalog over the registered vendors and a refresh port.
  factory BuiltInProviderCatalog({
    required Clock clock,
    required ProviderRegistry registry,
    ProviderCatalogMetadataSource? metadataSource,
  }) => BuiltInProviderCatalog._(
    clock,
    registry,
    metadataSource ?? ModelsDevCatalogMetadataSource(),
  );

  BuiltInProviderCatalog._(this._clock, this._registry, this._metadataSource)
    : _bundledAdvisory = bundledModelsDevMetadata();

  final Clock _clock;
  final ProviderRegistry _registry;
  final ProviderCatalogMetadataSource _metadataSource;
  final Map<String, List<ProviderCatalogMetadata>> _bundledAdvisory;
  Map<String, List<ProviderCatalogMetadata>>? _refreshedModels;
  DateTime? _refreshedAt;
  DateTime? _lastAttemptAt;
  String? _refreshError;

  /// Cancels refresh work owned by the metadata source.
  Future<void> close() => _metadataSource.close();

  /// Returns public provider metadata without endpoint or transport details.
  ProviderCatalogDto catalog() => ProviderCatalogDto(
    definitions: <ProviderDefinitionDto>[
      for (final plugin in _registry.adapters)
        protocolProviderDefinition(plugin.definition),
    ],
    wireFormats: <ProviderWireFormatDto>[
      for (final wire in _registry.wireProtocols)
        ProviderWireFormatDto(
          id: wire.id,
          label: wire.label,
          controls: wire.controlDescriptors
              .map(protocolControlDescriptor)
              .toList(),
        ),
    ],
    source: _refreshedModels == null
        ? ProviderCatalogSource.bundled
        : ProviderCatalogSource.refreshed,
    updatedAt: _refreshedAt ?? _clock.nowUtc(),
    freshness: _freshness,
    lastSuccessAt: _refreshedAt,
    lastAttemptAt: _lastAttemptAt,
    refreshError: _refreshError,
  );

  ProviderCatalogFreshness get _freshness {
    if (_refreshedModels == null) return ProviderCatalogFreshness.bundled;
    if (_refreshError != null) return ProviderCatalogFreshness.cached;
    final refreshedAt = _refreshedAt;
    if (refreshedAt == null ||
        _clock.nowUtc().difference(refreshedAt) >= const Duration(hours: 24)) {
      return ProviderCatalogFreshness.stale;
    }
    return ProviderCatalogFreshness.fresh;
  }

  /// Explicitly refreshes model metadata while retaining trusted runtime data.
  Future<ProviderCatalogDto> refresh({bool force = true}) async {
    if (!force && _freshness == ProviderCatalogFreshness.fresh) {
      return catalog();
    }
    _lastAttemptAt = _clock.nowUtc();
    final providerIds = _registry.adapters
        .where((adapter) => adapter.usesRemoteCatalog)
        .map((adapter) => adapter.id)
        .toSet();
    final Map<String, List<ProviderCatalogMetadata>> fetched;
    try {
      fetched = await _metadataSource.fetch(providerIds);
    } on Object {
      _refreshError = 'Catalog refresh failed; using local metadata.';
      return catalog();
    }
    _refreshedModels = <String, List<ProviderCatalogMetadata>>{
      for (final entry in fetched.entries)
        if (_registry.find(entry.key) case final plugin?)
          // The public catalog reports what it measured; the vendor may know
          // more, such as inputs its API accepts for every model.
          entry.key: List<ProviderCatalogMetadata>.unmodifiable(
            <ProviderCatalogMetadata>[
              for (final model in entry.value)
                ProviderCatalogMetadata(
                  id: model.id,
                  label: model.label,
                  capabilities: protocolCapabilities(
                    plugin
                        .refineRemoteCapabilities(
                          agentCapabilities(model.capabilities),
                        )
                        .copyWith(
                          controls: <AgentModelControlDescriptor>[
                            for (final control in agentCapabilities(
                              model.capabilities,
                            ).controls)
                              if (plugin.models
                                  .expand(
                                    (known) => known.capabilities.controls,
                                  )
                                  .any((known) => known.id == control.id))
                                control,
                          ],
                        ),
                  ),
                  pricing: model.pricing,
                  limits: model.limits,
                ),
            ],
          ),
    };
    _refreshedAt = _clock.nowUtc();
    _refreshError = null;
    return catalog();
  }

  /// Returns merged bundled and explicitly refreshed model metadata.
  List<ProviderCatalogMetadata> modelsFor(String definitionId) {
    final result = <String, ProviderCatalogMetadata>{
      for (final model
          in _bundledAdvisory[definitionId] ??
              const <ProviderCatalogMetadata>[])
        model.id: model,
      for (final model
          in _registry.find(definitionId)?.models ??
              const <ProviderCatalogModel>[])
        model.id: ProviderCatalogMetadata(
          id: model.id,
          label: model.label,
          capabilities: protocolCapabilities(model.capabilities),
          pricing: protocolPricing(model.pricing),
          limits: protocolLimits(model.limits),
        ),
    };
    for (final model
        in _refreshedModels?[definitionId] ??
            const <ProviderCatalogMetadata>[]) {
      final bundled = result[model.id];
      result[model.id] = bundled == null
          ? model
          : ProviderCatalogMetadata(
              id: model.id,
              label: model.label,
              capabilities: model.capabilities.copyWith(
                streaming:
                    bundled.capabilities.streaming == CapabilitySupport.unknown
                    ? model.capabilities.streaming
                    : bundled.capabilities.streaming,
                toolCalling:
                    bundled.capabilities.toolCalling ==
                        CapabilitySupport.unknown
                    ? model.capabilities.toolCalling
                    : bundled.capabilities.toolCalling,
                functionTools:
                    bundled.capabilities.functionTools ==
                        CapabilitySupport.unknown
                    ? model.capabilities.functionTools
                    : bundled.capabilities.functionTools,
                deferredTools:
                    bundled.capabilities.deferredTools ==
                        CapabilitySupport.unknown
                    ? model.capabilities.deferredTools
                    : bundled.capabilities.deferredTools,
                imageInput:
                    bundled.capabilities.imageInput == CapabilitySupport.unknown
                    ? model.capabilities.imageInput
                    : bundled.capabilities.imageInput,
                fileInput:
                    bundled.capabilities.fileInput == CapabilitySupport.unknown
                    ? model.capabilities.fileInput
                    : bundled.capabilities.fileInput,
                controls: bundled.capabilities.controls,
              ),
              pricing: model.pricing ?? bundled.pricing,
              limits: model.limits ?? bundled.limits,
            );
    }
    return result.values.toList(growable: false);
  }

  /// Whether metadata for a model came from the explicit refresh.
  bool isRefreshedModel(String definitionId, String modelId) =>
      _refreshedModels?[definitionId]?.any((model) => model.id == modelId) ??
      false;
}
