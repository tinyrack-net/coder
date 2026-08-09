import 'dart:convert';

import 'package:daemon/src/features/providers/infrastructure/generated/models_dev_snapshot.g.dart';
import 'package:daemon/src/features/providers/infrastructure/provider_catalog.dart';
import 'package:protocol/protocol.dart';

/// Decodes the pinned, normalized models.dev advisory snapshot.
Map<String, List<ProviderCatalogMetadata>> bundledModelsDevMetadata() {
  final decoded = jsonDecode(
    utf8.decode(base64Decode(modelsDevSnapshotBase64)),
  );
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('Bundled model catalog is invalid.');
  }
  return <String, List<ProviderCatalogMetadata>>{
    for (final entry in decoded.entries)
      if (entry.value is List<dynamic>)
        entry.key: <ProviderCatalogMetadata>[
          for (final value in entry.value! as List<dynamic>)
            if (value is Map<String, dynamic>) _model(value),
        ],
  };
}

ProviderCatalogMetadata _model(Map<String, dynamic> value) {
  final id = value['id'];
  final label = value['label'];
  if (id is! String || label is! String) {
    throw const FormatException('Bundled model entry is invalid.');
  }
  return ProviderCatalogMetadata(
    id: id,
    label: label,
    capabilities: ModelCapabilitiesDto(
      streaming: CapabilitySupport.supported,
      toolCalling: _support(value['toolCalling']),
      imageInput: _support(value['imageInput']),
      fileInput: _support(value['fileInput']),
      source: CapabilitySource.bundled,
    ),
    pricing: _pricing(value['cost']),
    limits: _limits(value['limits']),
  );
}

CapabilitySupport _support(Object? value) =>
    value == true ? CapabilitySupport.supported : CapabilitySupport.unsupported;

ModelPricingDto? _pricing(Object? value) {
  if (value is! Map<String, dynamic>) return null;
  return ModelPricingDto(
    input: _double(value['input']),
    output: _double(value['output']),
    cacheRead: _double(value['cache_read']),
    cacheWrite: _double(value['cache_write']),
  );
}

ModelLimitsDto? _limits(Object? value) {
  if (value is! Map<String, dynamic>) return null;
  return ModelLimitsDto(
    context: _integer(value['context']),
    input: _integer(value['input']),
    output: _integer(value['output']),
  );
}

double? _double(Object? value) => value is num ? value.toDouble() : null;

int? _integer(Object? value) => value is num ? value.toInt() : null;
