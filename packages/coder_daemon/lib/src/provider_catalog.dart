import 'package:coder_agent/coder_agent.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:dio/dio.dart';

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
}

/// Models.dev adapter. Provider endpoints and auth fields are never parsed.
final class ModelsDevCatalogMetadataSource
    implements ProviderCatalogMetadataSource {
  /// Creates the production Models.dev adapter.
  ModelsDevCatalogMetadataSource({Dio? dio})
    : _dio = dio ?? Dio(BaseOptions(baseUrl: 'https://models.dev'));

  final Dio _dio;

  @override
  Future<Map<String, List<ProviderCatalogMetadata>>> fetch(
    Set<String> providerIds,
  ) async {
    final response = await _dio.get<Map<String, dynamic>>('/api.json');
    final data = response.data;
    if (data == null) {
      throw const FormatException('Models.dev returned an empty catalog.');
    }
    return <String, List<ProviderCatalogMetadata>>{
      for (final providerId in providerIds)
        if (data[providerId] case final Map<String, dynamic> provider)
          providerId: _parseModels(provider, providerId),
    };
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
            reasoningEffort: reasoning
                ? CapabilitySupport.supported
                : CapabilitySupport.unsupported,
            supportedReasoningEfforts: _reasoningEfforts(model),
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

  BuiltInProviderCatalog._(this._clock, this._registry, this._metadataSource);

  final Clock _clock;
  final ProviderRegistry _registry;
  final ProviderCatalogMetadataSource _metadataSource;
  Map<String, List<ProviderCatalogMetadata>>? _refreshedModels;
  DateTime? _refreshedAt;

  /// Returns public provider metadata without endpoint or transport details.
  ProviderCatalogDto catalog() => ProviderCatalogDto(
    definitions: <ProviderDefinitionDto>[
      for (final plugin in _registry.plugins) plugin.definition,
    ],
    wireFormats: <ProviderWireFormatDto>[
      for (final wire in _registry.wireProtocols)
        ProviderWireFormatDto(id: wire.id, label: wire.label),
    ],
    source: _refreshedModels == null
        ? ProviderCatalogSource.bundled
        : ProviderCatalogSource.refreshed,
    updatedAt: _refreshedAt ?? _clock.nowUtc(),
  );

  /// Explicitly refreshes model metadata while retaining trusted runtime data.
  Future<ProviderCatalogDto> refresh() async {
    final providerIds = _registry.plugins.map((plugin) => plugin.id).toSet();
    final fetched = await _metadataSource.fetch(providerIds);
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
                  capabilities: plugin.refineRemoteCapabilities(
                    model.capabilities,
                  ),
                  pricing: model.pricing,
                  limits: model.limits,
                ),
            ],
          ),
    };
    _refreshedAt = _clock.nowUtc();
    return catalog();
  }

  /// Returns merged bundled and explicitly refreshed model metadata.
  List<ProviderCatalogMetadata> modelsFor(String definitionId) {
    final result = <String, ProviderCatalogMetadata>{
      for (final model
          in _registry.find(definitionId)?.models ??
              const <ProviderCatalogModel>[])
        model.id: ProviderCatalogMetadata(
          id: model.id,
          label: model.label,
          capabilities: model.capabilities,
          pricing: model.pricing,
          limits: model.limits,
        ),
    };
    for (final model
        in _refreshedModels?[definitionId] ??
            const <ProviderCatalogMetadata>[]) {
      result[model.id] = model;
    }
    return result.values.toList(growable: false);
  }

  /// Whether metadata for a model came from the explicit refresh.
  bool isRefreshedModel(String definitionId, String modelId) =>
      _refreshedModels?[definitionId]?.any((model) => model.id == modelId) ??
      false;
}
