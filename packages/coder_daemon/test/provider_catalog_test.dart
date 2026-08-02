import 'dart:convert';
import 'dart:typed_data';

import 'package:coder_daemon/src/ports.dart';
import 'package:coder_daemon/src/provider_catalog.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime.utc(2026, 8, 2);

  test(
    'explicit refresh merges model metadata without runtime fields',
    () async {
      final source = _MetadataSource();
      final catalog = BuiltInProviderCatalog(
        clock: _Clock(now),
        metadataSource: source,
      );
      final trustedEndpoint = catalog.require('deepseek').baseUrl;

      final refreshed = await catalog.refresh();
      final model = catalog
          .modelsFor('deepseek')
          .singleWhere((item) => item.id == 'deepseek-new');

      expect(refreshed.source, ProviderCatalogSource.refreshed);
      expect(source.requested, contains('deepseek'));
      expect(model.label, 'DeepSeek New');
      expect(model.pricing!.input, 0.25);
      expect(model.limits!.context, 128000);
      expect(catalog.isRefreshedModel('deepseek', model.id), isTrue);
      expect(catalog.require('deepseek').baseUrl, trustedEndpoint);
      expect(catalog.find('attacker'), isNull);
    },
  );

  test('Models.dev parser accepts only requested model metadata', () async {
    final adapter = _JsonAdapter(<String, dynamic>{
      'deepseek': <String, dynamic>{
        'api': 'https://attacker.invalid',
        'env': <String>['STOLEN_KEY'],
        'models': <String, dynamic>{
          'deepseek-next': <String, dynamic>{
            'id': 'deepseek-next',
            'name': 'DeepSeek Next',
            'reasoning': true,
            'reasoning_options': <Map<String, dynamic>>[
              <String, dynamic>{
                'type': 'effort',
                'values': <String>['high', 'max'],
              },
            ],
            'tool_call': true,
            'cost': <String, dynamic>{
              'input': 0.4,
              'output': 1.2,
              'cache_read': 0.1,
            },
            'limit': <String, dynamic>{
              'context': 200000,
              'output': 32000,
            },
          },
        },
      },
      'attacker': <String, dynamic>{
        'models': <String, dynamic>{
          'bad': <String, dynamic>{'id': 'bad'},
        },
      },
    });
    final source = ModelsDevCatalogMetadataSource(
      dio: Dio()..httpClientAdapter = adapter,
    );

    final result = await source.fetch(<String>{'deepseek'});
    final model = result['deepseek']!.single;

    expect(result, isNot(contains('attacker')));
    expect(model.id, 'deepseek-next');
    expect(model.capabilities.toolCalling, CapabilitySupport.supported);
    expect(model.capabilities.supportedReasoningEfforts, <String>[
      'high',
      'max',
    ]);
    expect(model.pricing!.cacheRead, 0.1);
    expect(model.limits!.output, 32000);
    expect(adapter.path, '/api.json');
  });

  test('refresh failure retains the bundled snapshot', () async {
    final catalog = BuiltInProviderCatalog(
      clock: _Clock(now),
      metadataSource: const _FailingMetadataSource(),
    );

    await expectLater(catalog.refresh(), throwsA(isA<StateError>()));

    expect(catalog.catalog().source, ProviderCatalogSource.bundled);
    expect(catalog.modelsFor('openai'), isNotEmpty);
  });
}

final class _Clock implements Clock {
  const _Clock(this.now);

  final DateTime now;

  @override
  DateTime nowUtc() => now;
}

final class _MetadataSource implements ProviderCatalogMetadataSource {
  Set<String> requested = <String>{};

  @override
  Future<Map<String, List<ProviderCatalogMetadata>>> fetch(
    Set<String> providerIds,
  ) async {
    requested = providerIds;
    return const <String, List<ProviderCatalogMetadata>>{
      'deepseek': <ProviderCatalogMetadata>[
        ProviderCatalogMetadata(
          id: 'deepseek-new',
          label: 'DeepSeek New',
          capabilities: ModelCapabilitiesDto(
            streaming: CapabilitySupport.supported,
            toolCalling: CapabilitySupport.supported,
            source: CapabilitySource.refreshed,
          ),
          pricing: ModelPricingDto(input: 0.25, output: 1),
          limits: ModelLimitsDto(context: 128000, output: 16000),
        ),
      ],
      'attacker': <ProviderCatalogMetadata>[
        ProviderCatalogMetadata(
          id: 'bad',
          label: 'Bad',
          capabilities: ModelCapabilitiesDto(),
        ),
      ],
    };
  }
}

final class _FailingMetadataSource implements ProviderCatalogMetadataSource {
  const _FailingMetadataSource();

  @override
  Future<Map<String, List<ProviderCatalogMetadata>>> fetch(
    Set<String> providerIds,
  ) => Future<Map<String, List<ProviderCatalogMetadata>>>.error(
    StateError('offline'),
  );
}

final class _JsonAdapter implements HttpClientAdapter {
  _JsonAdapter(this.data);

  final Map<String, dynamic> data;
  String? path;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    path = options.path;
    return ResponseBody.fromString(
      jsonEncode(data),
      200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
