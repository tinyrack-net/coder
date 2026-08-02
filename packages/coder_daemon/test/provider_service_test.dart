import 'dart:async';

import 'package:coder_agent/coder_agent.dart';
import 'package:coder_daemon/src/ports.dart';
import 'package:coder_daemon/src/provider_adapters.dart';
import 'package:coder_daemon/src/provider_service.dart';
import 'package:coder_daemon/src/repositories.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime.utc(2026, 8, 2);

  test('initialization and provider CRUD keep credentials separated', () async {
    final fixture = _ServiceFixture(now: now);
    await fixture.service.initialize(legacyOpenAIKey: 'legacy-key');
    await fixture.service.initialize();

    final catalog = await fixture.service.catalog();
    expect(catalog.defaultProviderId, 'openai');
    expect(catalog.presets.map((preset) => preset.id), contains('deepseek'));
    expect(catalog.providers.single.credentialConfigured, isTrue);
    expect(fixture.credentials.keys['openai'], 'legacy-key');
    expect(await fixture.repository.listModels('openai'), hasLength(3));
    expect(fixture.credentials.loads, 2);

    await expectLater(
      fixture.service.get('missing'),
      throwsA(isA<StateError>()),
    );
    for (final url in <String>['not-a-url', 'ftp://example.com/v1']) {
      await expectLater(
        fixture.service.upsert(_provider(now, id: 'bad', baseUrl: url)),
        throwsA(isA<FormatException>()),
      );
    }
    await expectLater(
      fixture.service.upsert(
        _provider(
          now,
          id: 'environment',
          source: CredentialSource.environment,
        ),
      ),
      throwsA(isA<FormatException>()),
    );

    final stored = await fixture.service.upsert(
      _provider(
        now,
        id: 'stored',
        source: CredentialSource.stored,
        baseUrl: 'http://localhost:11434/v1///',
      ),
      makeDefault: true,
    );
    expect(stored.baseUrl, 'http://localhost:11434/v1');
    expect(stored.credentialConfigured, isFalse);
    expect(fixture.settings.values['provider.defaultId'], 'stored');
    await fixture.service.setCredential('stored', 'stored-key');
    expect((await fixture.service.get('stored')).credentialConfigured, isTrue);
    await fixture.repository.upsertProvider(_provider(now, id: 'no-key'));
    await expectLater(
      fixture.service.setCredential('no-key', 'wrong-source'),
      throwsA(isA<StateError>()),
    );

    await fixture.service.delete('stored');
    expect(fixture.credentials.keys, isNot(contains('stored')));
    expect(fixture.settings.values['provider.defaultId'], isEmpty);
    await fixture.service.delete('missing');
  });

  test(
    'model catalog merges discovery, manual overrides, and allowlist',
    () async {
      final fixture = _ServiceFixture(now: now);
      final provider = _provider(
        now,
        id: 'custom',
        visibleModelIds: const <String>['visible'],
      );
      await fixture.repository.upsertProvider(provider);
      await fixture.repository.upsertModel(
        _model('custom', 'visible', ProviderModelSource.preset),
      );
      await fixture.repository.upsertModel(
        _model('custom', 'hidden', ProviderModelSource.discovered),
      );
      await fixture.service.upsertManualModel(
        _model('custom', 'manual', ProviderModelSource.discovered),
      );

      expect(
        (await fixture.service.listModels('custom')).map((model) => model.id),
        <String>['manual', 'visible'],
      );
      fixture.discovery.ids = <String>['visible', 'new-hidden'];
      expect(
        (await fixture.service.refreshModels(
          'custom',
        )).map((model) => model.id),
        <String>['manual', 'visible'],
      );
      expect(fixture.discovery.lastApiKey, isEmpty);

      final manual = await fixture.repository.getModel('custom', 'manual');
      expect(manual!.source, ProviderModelSource.manual);
      expect(manual.capabilities.source, CapabilitySource.manual);
      await fixture.service.deleteModel('custom', 'manual');
      expect(await fixture.repository.getModel('custom', 'manual'), isNull);
      await fixture.service.deleteModel('custom', 'absent');
      await expectLater(
        fixture.service.deleteModel('custom', 'visible'),
        throwsA(isA<StateError>()),
      );

      fixture.discovery.error = const FormatException('invalid catalog');
      await expectLater(
        fixture.service.refreshModels('custom'),
        throwsA(isA<StateError>()),
      );
    },
  );

  test(
    'provider resolution and model validation enforce capabilities',
    () async {
      final fixture = _ServiceFixture(
        now: now,
        environment: const <String, String>{'ENV_KEY': 'environment-key'},
      );
      await fixture.repository.upsertProvider(
        _provider(
          now,
          id: 'environment',
          source: CredentialSource.environment,
          environmentVariable: 'ENV_KEY',
          defaultModelId: 'verified',
        ),
      );
      await fixture.repository.upsertModel(
        _model(
          'environment',
          'verified',
          ProviderModelSource.manual,
          capabilities: const ModelCapabilitiesDto(
            streaming: CapabilitySupport.supported,
            toolCalling: CapabilitySupport.supported,
            reasoningEffort: CapabilitySupport.supported,
            source: CapabilitySource.manual,
          ),
        ),
      );

      expect((await fixture.service.resolve('environment')).id, 'created');
      expect(fixture.factory.lastApiKey, 'environment-key');
      expect(fixture.factory.lastSupportsReasoning, isTrue);
      await fixture.service.validateAgentModel('environment', 'verified');

      await fixture.repository.upsertProvider(
        _provider(now, id: 'disabled', enabled: false),
      );
      await expectLater(
        fixture.service.resolve('disabled'),
        throwsA(isA<StateError>()),
      );
      await expectLater(
        fixture.service.validateAgentModel('disabled', 'anything'),
        throwsA(isA<StateError>()),
      );

      await fixture.repository.upsertProvider(
        _provider(
          now,
          id: 'missing-key',
          source: CredentialSource.stored,
        ),
      );
      await expectLater(
        fixture.service.resolve('missing-key'),
        throwsA(isA<StateError>()),
      );
      await expectLater(
        fixture.service.validateAgentModel('environment', 'unknown'),
        throwsA(isA<StateError>()),
      );
      await fixture.repository.upsertModel(
        _model('environment', 'unknown-capability', ProviderModelSource.manual),
      );
      await expectLater(
        fixture.service.validateAgentModel(
          'environment',
          'unknown-capability',
        ),
        throwsA(isA<StateError>()),
      );

      final fixed = _EventProvider(const <ModelEvent>[]);
      final fixedFixture = _ServiceFixture(now: now, fixedProvider: fixed);
      expect(await fixedFixture.service.resolve('does-not-exist'), same(fixed));
    },
  );

  test(
    'diagnostics persist verified, incomplete, and failed results',
    () async {
      final verifiedProvider = _EventProvider(const <ModelEvent>[
        ModelFunctionCall(
          callId: 'call',
          name: 'capability_probe',
          arguments: <String, dynamic>{'value': 'ok'},
        ),
        ModelResponseCompleted(assistant: AssistantConversationItem(text: '')),
      ]);
      final verified = _ServiceFixture(
        now: now,
        fixedProvider: verifiedProvider,
      );
      final result = await verified.service.diagnose('provider', 'model');
      expect(result.status, DiagnosticStatus.verified);
      expect(result.endpointReachable, isTrue);
      expect(result.toolCalling, isTrue);
      expect(
        (await verified.repository.getModel(
          'provider',
          'model',
        ))!.capabilities.source,
        CapabilitySource.diagnostic,
      );
      expect(verifiedProvider.lastRequest!.forceToolName, 'capability_probe');

      final incomplete = _ServiceFixture(
        now: now,
        fixedProvider: _EventProvider(const <ModelEvent>[
          ModelResponseCompleted(
            assistant: AssistantConversationItem(text: ''),
          ),
        ]),
      );
      final incompleteResult = await incomplete.service.diagnose(
        'provider',
        'model',
      );
      expect(incompleteResult.status, DiagnosticStatus.failed);
      expect(incompleteResult.endpointReachable, isTrue);
      expect(incompleteResult.error, contains('streamed tool call'));

      final failing = _ServiceFixture(
        now: now,
        fixedProvider: _EventProvider(
          const <ModelEvent>[],
          error: const FormatException('network failed'),
        ),
      );
      final failedResult = await failing.service.diagnose('provider', 'model');
      expect(failedResult.status, DiagnosticStatus.failed);
      expect(failedResult.endpointReachable, isFalse);
      expect(failedResult.error, contains('network failed'));

      await verified.repository.upsertModel(
        _model(
          'provider',
          'manual-priority',
          ProviderModelSource.manual,
          capabilities: const ModelCapabilitiesDto(
            streaming: CapabilitySupport.supported,
            toolCalling: CapabilitySupport.supported,
            source: CapabilitySource.manual,
          ),
        ),
      );
      await verified.service.diagnose('provider', 'manual-priority');
      expect(
        (await verified.repository.getModel(
          'provider',
          'manual-priority',
        ))!.capabilities.source,
        CapabilitySource.manual,
      );
    },
  );
}

ApiProviderDto _provider(
  DateTime now, {
  required String id,
  String baseUrl = 'http://localhost:11434/v1',
  CredentialSource source = CredentialSource.none,
  String? environmentVariable,
  String? defaultModelId,
  bool enabled = true,
  List<String> visibleModelIds = const <String>[],
}) => ApiProviderDto(
  id: id,
  name: id,
  presetId: 'custom',
  baseUrl: baseUrl,
  transport: ApiTransport.chatCompletions,
  credentialSource: source,
  credentialConfigured: false,
  environmentVariable: environmentVariable,
  enabled: enabled,
  strictToolSchema: false,
  defaultModelId: defaultModelId,
  visibleModelIds: visibleModelIds,
  createdAt: now,
  updatedAt: now,
);

ProviderModelDto _model(
  String providerId,
  String id,
  ProviderModelSource source, {
  ModelCapabilitiesDto capabilities = const ModelCapabilitiesDto(),
}) => ProviderModelDto(
  providerId: providerId,
  id: id,
  label: id,
  source: source,
  capabilities: capabilities,
);

final class _ServiceFixture {
  _ServiceFixture({
    required DateTime now,
    Map<String, String> environment = const <String, String>{},
    ModelProvider? fixedProvider,
  }) : clock = _Clock(now) {
    service = ProviderService(
      repository: repository,
      settings: settings,
      credentials: credentials,
      environment: environment,
      clock: clock,
      modelDiscovery: discovery,
      providerFactory: factory,
      fixedProvider: fixedProvider,
    );
  }

  final _ProviderRepository repository = _ProviderRepository();
  final _SettingsRepository settings = _SettingsRepository();
  final _Credentials credentials = _Credentials();
  final _Discovery discovery = _Discovery();
  final _Factory factory = _Factory();
  final _Clock clock;
  late final ProviderService service;
}

final class _Clock implements Clock {
  const _Clock(this.value);

  final DateTime value;

  @override
  DateTime nowUtc() => value;
}

final class _SettingsRepository implements SettingsRepository {
  final Map<String, String> values = <String, String>{};

  @override
  Future<String?> getValue(String key) async => values[key];

  @override
  Future<void> setValue(String key, String value) async {
    values[key] = value;
  }
}

final class _ProviderRepository implements ProviderRepository {
  final Map<String, ApiProviderDto> providers = <String, ApiProviderDto>{};
  final Map<String, ProviderModelDto> models = <String, ProviderModelDto>{};

  String _modelKey(String providerId, String modelId) => '$providerId/$modelId';

  @override
  Future<void> deleteModel(String providerId, String modelId) async {
    models.remove(_modelKey(providerId, modelId));
  }

  @override
  Future<void> deleteProvider(String id) async {
    providers.remove(id);
    models.removeWhere((_, model) => model.providerId == id);
  }

  @override
  Future<ProviderModelDto?> getModel(String providerId, String modelId) async =>
      models[_modelKey(providerId, modelId)];

  @override
  Future<ApiProviderDto?> getProvider(String id) async => providers[id];

  @override
  Future<List<ProviderModelDto>> listModels(String providerId) async =>
      (models.values.where((model) => model.providerId == providerId).toList()
            ..sort((a, b) => a.id.compareTo(b.id)))
          .toList(growable: false);

  @override
  Future<List<ApiProviderDto>> listProviders() async =>
      providers.values.toList(growable: false);

  @override
  Future<void> replaceDiscoveredModels(
    String providerId,
    Iterable<ProviderModelDto> replacement,
  ) async {
    models.removeWhere(
      (_, model) =>
          model.providerId == providerId &&
          model.source == ProviderModelSource.discovered,
    );
    for (final model in replacement) {
      models[_modelKey(providerId, model.id)] = model;
    }
  }

  @override
  Future<ProviderModelDto> upsertModel(ProviderModelDto model) async {
    models[_modelKey(model.providerId, model.id)] = model;
    return model;
  }

  @override
  Future<ApiProviderDto> upsertProvider(ApiProviderDto provider) async {
    providers[provider.id] = provider;
    return provider;
  }
}

final class _Credentials implements CredentialRepository {
  final Map<String, String> keys = <String, String>{};
  int loads = 0;
  String? token;

  @override
  String? get bearerToken => token;

  @override
  Future<void> load() async {
    loads += 1;
  }

  @override
  String? providerApiKey(String providerId) => keys[providerId];

  @override
  Future<void> removeProvider(String providerId) async {
    keys.remove(providerId);
  }

  @override
  Future<void> setBearerToken(String token) async {
    this.token = token;
  }

  @override
  Future<void> setProviderApiKey(String providerId, String value) async {
    keys[providerId] = value;
  }
}

final class _Discovery implements ProviderModelDiscovery {
  List<String> ids = <String>[];
  Exception? error;
  String? lastApiKey;

  @override
  Future<List<String>> fetchModelIds(
    ApiProviderDto provider,
    String apiKey,
  ) async {
    lastApiKey = apiKey;
    final failure = error;
    if (failure != null) throw failure;
    return ids;
  }
}

final class _Factory implements ModelProviderFactory {
  String? lastApiKey;
  bool? lastSupportsReasoning;

  @override
  ModelProvider create({
    required ApiProviderDto provider,
    required String apiKey,
    required bool supportsReasoningEffort,
  }) {
    lastApiKey = apiKey;
    lastSupportsReasoning = supportsReasoningEffort;
    return _EventProvider(const <ModelEvent>[], id: 'created');
  }
}

final class _EventProvider implements ModelProvider {
  _EventProvider(this.events, {this.error, this.id = 'event'});

  final List<ModelEvent> events;
  final Exception? error;
  @override
  final String id;
  ModelRequest? lastRequest;

  @override
  Stream<ModelEvent> stream(
    ModelRequest request,
    CancellationToken cancellation,
  ) async* {
    lastRequest = request;
    final failure = error;
    if (failure != null) throw failure;
    yield* Stream<ModelEvent>.fromIterable(events);
  }
}
