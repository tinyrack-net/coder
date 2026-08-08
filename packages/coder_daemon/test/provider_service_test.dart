import 'package:coder_agent/coder_agent.dart';
import 'package:coder_daemon/src/features/providers/infrastructure/openai/openai.dart';
import 'package:coder_daemon/src/features/providers/infrastructure/provider_adapters.dart';
import 'package:coder_daemon/src/features/providers/infrastructure/provider_auth.dart';
import 'package:coder_daemon/src/features/providers/infrastructure/provider_catalog.dart';
import 'package:coder_daemon/src/features/providers/infrastructure/provider_service.dart';
import 'package:coder_daemon/src/shared/infrastructure/persistence/repositories.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime.utc(2026, 8, 2);

  test(
    'catalog hides runtime configuration and exposes simple auth',
    () async {
      final fixture = _ServiceFixture(now);

      final catalog = await fixture.service.catalog();

      expect(catalog.source, ProviderCatalogSource.bundled);
      expect(
        catalog.definitions.map((definition) => definition.id),
        containsAll(<String>['openai', 'deepseek', 'ollama']),
      );
      expect(
        catalog.definitions
            .singleWhere((definition) => definition.id == 'openai')
            .authMethods
            .map((method) => method.flow),
        <ProviderAuthFlow>[
          ProviderAuthFlow.oauthBrowser,
          ProviderAuthFlow.oauthDevice,
          ProviderAuthFlow.apiKey,
        ],
      );
      expect(
        catalog.definitions
            .singleWhere((definition) => definition.id == 'deepseek')
            .authMethods
            .single
            .flow,
        ProviderAuthFlow.apiKey,
      );
      expect(
        catalog.wireFormats
            .singleWhere((wire) => wire.id == openAIResponsesWireId)
            .controls
            .map((control) => control.id),
        containsAll(<String>['reasoning_effort', 'fast_mode']),
      );
    },
    tags: const <String>['feature_test__provider_catalog__unit'],
  );

  test(
    'initialization ignores provider credential environment variables',
    () async {
      final fixture = _ServiceFixture(now);
      fixture.discovery.ids = <String>['deepseek-v4-pro'];

      await fixture.service.initialize();

      expect(await fixture.service.connections(), isEmpty);
      expect(fixture.credentials.values, isEmpty);
      expect(fixture.discovery.calls, 0);
    },
  );

  test(
    'same provider connects repeatedly with unique prefixes and credentials',
    () async {
      final fixture = _ServiceFixture(now);
      fixture.discovery.ids = <String>['gpt-5.6-sol'];

      final first = await fixture.service.connectApiKey('openai', 'first');
      final second = await fixture.service.connectApiKey('openai', 'second');
      await fixture.service.refreshCatalog(force: false);

      expect(first.id, isNot(second.id));
      expect(first.modelPrefix, 'openai');
      expect(second.modelPrefix, 'openai-2');
      expect(
        (await fixture.service.connections()).map(
          (connection) => connection.modelPrefix,
        ),
        <String>['openai', 'openai-2'],
      );
      expect(
        fixture.credentials.values[first.id],
        const TypeMatcher<ApiKeyCredential>(),
      );
      expect(
        fixture.credentials.values[second.id],
        const TypeMatcher<ApiKeyCredential>(),
      );
      expect(
        (await fixture.service.listModels(first.id)).map((model) => model.id),
        contains('openai/gpt-5.6-sol'),
      );
      expect(
        (await fixture.service.listModels(second.id)).map((model) => model.id),
        contains('openai-2/gpt-5.6-sol'),
      );
    },
    tags: const <String>[
      'feature_test__provider_connection_management__unit',
    ],
  );

  test(
    'reconnecting replaces credentials without duplicating the connection',
    () async {
      final fixture = _ServiceFixture(now);
      fixture.discovery.ids = <String>['deepseek-v4-pro'];
      final original = await fixture.service.connectApiKey(
        'deepseek',
        'old-secret',
        modelPrefix: 'primary',
      );
      await fixture.service.disconnect(original.id);

      final reconnected = await fixture.service.connectApiKey(
        'deepseek',
        'new-secret',
        connectionId: original.id,
        modelPrefix: 'primary',
      );

      expect(reconnected.id, original.id);
      expect(reconnected.createdAt, original.createdAt);
      expect(reconnected.modelPrefix, 'primary');
      expect(await fixture.service.connections(), hasLength(1));
      expect(
        (fixture.credentials.values[original.id]! as ApiKeyCredential).key,
        'new-secret',
      );
      await expectLater(
        fixture.service.connectNone(
          'ollama',
          connectionId: original.id,
        ),
        throwsA(isA<ProviderConnectionFailure>()),
      );
      await expectLater(
        fixture.service.connectApiKey(
          'deepseek',
          'secret',
          connectionId: 'missing-connection',
        ),
        throwsA(
          isA<ProviderConnectionFailure>().having(
            (error) => error.code,
            'code',
            'provider_not_connected',
          ),
        ),
      );
    },
    tags: const <String>[
      'feature_test__provider_connection_management__unit',
    ],
  );

  test(
    'an explicitly requested prefix conflicts instead of being renamed',
    () async {
      final fixture = _ServiceFixture(now);
      fixture.discovery.ids = <String>['gpt-5.6-sol'];
      await fixture.service.connectApiKey(
        'openai',
        'first',
        modelPrefix: 'openai-new',
      );

      await expectLater(
        fixture.service.connectApiKey(
          'openai',
          'second',
          modelPrefix: 'OPENAI-NEW',
        ),
        throwsA(
          isA<ProviderConnectionFailure>().having(
            (error) => error.code,
            'code',
            'model_prefix_conflict',
          ),
        ),
      );
      await expectLater(
        fixture.service.connectApiKey(
          'openai',
          'third',
          modelPrefix: 'openai/new',
        ),
        throwsA(isA<FormatException>()),
      );
      final second = await fixture.service.connectApiKey(
        'openai',
        'fourth',
      );
      await expectLater(
        fixture.service.updateModelPrefix(second.id, 'openai-new'),
        throwsA(isA<ProviderConnectionFailure>()),
      );
    },
  );

  test('OAuth attempts reserve unique prefixes until released', () async {
    final fixture = _ServiceFixture(now);

    final first = await fixture.service.reserveOAuthConnection('openai');
    final second = await fixture.service.reserveOAuthConnection('openai');

    expect(first.modelPrefix, 'openai');
    expect(second.modelPrefix, 'openai-2');
    await fixture.service.releaseOAuthConnection(first.connectionId);
    final replacement = await fixture.service.reserveOAuthConnection(
      'openai',
      modelPrefix: 'openai',
    );
    expect(replacement.modelPrefix, 'openai');
  });

  test('prefix rename cascades models, defaults, and references', () async {
    final updater = _ReferenceUpdater();
    final fixture = _ServiceFixture(now, referenceUpdater: updater);
    fixture.discovery.ids = <String>['deepseek-v4-pro'];
    final connection = await fixture.service.connectApiKey(
      'deepseek',
      'secret',
    );
    await fixture.service.setDefaultModel(
      const SessionModelSelectionDto(
        modelId: 'deepseek/deepseek-v4-pro',
      ),
    );

    final renamed = await fixture.service.updateModelPrefix(
      connection.id,
      'deepseek-new',
    );

    expect(renamed.modelPrefix, 'deepseek-new');
    expect(updater.calls, <String>['deepseek->deepseek-new']);
    expect(
      (await fixture.service.listModels(
        connection.id,
      )).singleWhere((model) => model.providerModelId == 'deepseek-v4-pro').id,
      'deepseek-new/deepseek-v4-pro',
    );
    expect(
      (await fixture.service.storedDefaultModel())!.modelId,
      'deepseek-new/deepseek-v4-pro',
    );
  });

  test(
    'model controls reject unknown IDs, types, values, and conflicts',
    () async {
      final fixture = _ServiceFixture(now);
      fixture.discovery.ids = <String>[];
      final connection = await fixture.service.connectApiKey(
        'openai',
        'secret',
      );

      for (final controls in <Map<String, ModelControlValueDto>>[
        const <String, ModelControlValueDto>{
          'request_body': ModelControlValueDto.stringValue(value: 'unsafe'),
        },
        const <String, ModelControlValueDto>{
          'reasoning_effort': ModelControlValueDto.boolValue(value: true),
        },
        const <String, ModelControlValueDto>{
          'reasoning_effort': ModelControlValueDto.stringValue(
            value: 'invalid',
          ),
        },
        const <String, ModelControlValueDto>{
          'reasoning_effort': ModelControlValueDto.stringValue(value: 'high'),
          'reasoning_mode': ModelControlValueDto.stringValue(value: 'none'),
        },
      ]) {
        await expectLater(
          fixture.service.validateModelControls(
            connection.id,
            'gpt-5.6-sol',
            controls,
          ),
          throwsA(isA<FormatException>()),
        );
      }

      final retained = await fixture.service.retainValidModelControls(
        connection.id,
        'gpt-5.6-sol',
        const <String, ModelControlValueDto>{
          'reasoning_effort': ModelControlValueDto.stringValue(value: 'high'),
          'request_body': ModelControlValueDto.stringValue(value: 'unsafe'),
        },
      );
      expect(retained.keys, <String>['reasoning_effort']);
    },
  );

  test('model resolver delegates every qualified model operation', () async {
    final fixture = _ServiceFixture(now);
    fixture.discovery.ids = <String>[];
    final connection = await fixture.service.connectApiKey(
      'deepseek',
      'secret',
    );
    final resolver = ProviderModelResolver(fixture.service);
    const modelId = 'deepseek/deepseek-chat';

    expect((await resolver.fallbackModel())!.modelId, modelId);
    expect(
      (await resolver.resolveAgentModel(
        const AgentModelSelectionDto(
          source: AgentModelSource.fixed,
          modelId: modelId,
        ),
      )).connectionId,
      connection.id,
    );
    expect(
      (await resolver.resolveQualifiedModel(modelId)).connectionId,
      connection.id,
    );
    expect(
      (await resolver.resolveExplicitModel(connection.id, modelId)).modelId,
      'deepseek-chat',
    );
    expect(
      (await resolver.validateAgentModel(connection.id, modelId)).id,
      modelId,
    );
    expect((await resolver.validateQualifiedModel(modelId)).id, modelId);
    await resolver.validateModelControls(connection.id, modelId, const {});
    await resolver.validateQualifiedModelControls(modelId, const {});
    expect(
      await resolver.retainValidModelControls(connection.id, modelId, const {}),
      isEmpty,
    );
    expect(
      await resolver.retainValidQualifiedModelControls(modelId, const {}),
      isEmpty,
    );
  });

  test(
    'fixed test provider creates a deterministic in-memory connection',
    () async {
      final fixed = _EventProvider();
      final fixture = _ServiceFixture(
        now,
        fixedProvider: fixed,
        metadataSource: const _OfflineMetadataSource(),
      );
      fixture.discovery.failure = const ProviderDiscoveryFailure(
        ProviderDiscoveryFailureKind.invalidCredential,
        'fixed providers must not discover remote models',
      );

      await fixture.service.initialize();
      await fixture.service.refreshCatalog();

      final connection = (await fixture.service.connections()).single;
      expect(connection.id, 'openai');
      expect(connection.status, ProviderConnectionStatus.connected);
      expect(connection.credentialOrigin, ProviderCredentialOrigin.none);
      expect(await fixture.service.listModels(connection.id), isNotEmpty);
      expect(
        await fixture.service.resolve('openai', modelId: 'gpt-5.6-sol'),
        same(fixed),
      );
      expect(fixture.discovery.lastSecret, isNull);
      expect(fixture.discovery.calls, 0);
    },
  );

  test(
    'API key and local providers connect without technical settings',
    () async {
      final fixture = _ServiceFixture(now);
      fixture.discovery.ids = <String>['deepseek-v4-flash'];

      final hosted = await fixture.service.connectApiKey(
        'deepseek',
        'stored-secret',
      );
      expect(hosted.status, ProviderConnectionStatus.connected);
      expect(hosted.authKind, ProviderAuthKind.apiKey);
      expect(hosted.credentialOrigin, ProviderCredentialOrigin.stored);
      expect(fixture.credentials.values[hosted.id], isA<ApiKeyCredential>());
      expect(
        (fixture.credentials.values[hosted.id]! as ApiKeyCredential).key,
        'stored-secret',
      );

      fixture.discovery.ids = <String>['qwen-local'];
      final local = await fixture.service.connectNone('ollama');
      expect(local.authKind, ProviderAuthKind.none);
      expect(local.credentialOrigin, ProviderCredentialOrigin.none);
      expect(local.status, ProviderConnectionStatus.connected);

      expect(await fixture.service.listModels(local.id), isNotEmpty);

      await fixture.service.disconnect(hosted.id);
      expect(
        (await fixture.service.get(hosted.id)).status,
        ProviderConnectionStatus.disconnected,
      );
      expect(fixture.credentials.values, isNot(contains('deepseek')));
    },
    tags: const <String>[
      'feature_test__provider_connection_management__unit',
    ],
  );

  test('discovery failures degrade but invalid credentials fail', () async {
    final degraded = _ServiceFixture(now);
    degraded.discovery.failure = const ProviderDiscoveryFailure(
      ProviderDiscoveryFailureKind.unavailable,
      'offline',
    );
    final degradedConnection = await degraded.service.connectApiKey(
      'deepseek',
      'secret',
    );
    expect(degradedConnection.status, ProviderConnectionStatus.degraded);
    expect(
      await degraded.service.listModels(degradedConnection.id),
      isNotEmpty,
    );

    final invalid = _ServiceFixture(now);
    invalid.discovery.failure = const ProviderDiscoveryFailure(
      ProviderDiscoveryFailureKind.invalidCredential,
      'unauthorized',
    );
    final invalidConnection = await invalid.service.connectApiKey(
      'deepseek',
      'bad-secret',
    );
    expect(invalidConnection.status, ProviderConnectionStatus.error);
    expect(invalidConnection.error, 'unauthorized');
    await expectLater(
      invalid.service.resolve(
        invalidConnection.id,
        modelId: 'deepseek-v4-pro',
      ),
      throwsA(isA<ProviderConnectionFailure>()),
    );
  });

  test(
    'custom connections validate URL and allow multiple instances',
    () async {
      final fixture = _ServiceFixture(now);
      fixture.discovery.ids = <String>['custom-model'];
      const config = CustomProviderConfigDto(
        name: 'Lab',
        baseUrl: 'http://127.0.0.1:9000/v1/',
        wireFormatId: openAIChatCompletionsWireId,
        authenticationRequired: true,
      );

      final first = await fixture.service.createCustom(
        'custom-one',
        config,
        apiKey: 'secret',
      );
      final second = await fixture.service.createCustom(
        'custom-two',
        config.copyWith(name: 'Lab 2'),
        apiKey: 'secret-2',
      );
      expect(first.customConfig!.baseUrl, 'http://127.0.0.1:9000/v1');
      expect(second.id, isNot(first.id));
      expect(await fixture.service.connections(), hasLength(2));

      await expectLater(
        fixture.service.createCustom(
          'bad',
          config.copyWith(baseUrl: 'file:///tmp/model'),
        ),
        throwsA(isA<FormatException>()),
      );
      await expectLater(
        fixture.service.connectApiKey('ollama', 'not-supported'),
        throwsA(isA<StateError>()),
      );
    },
  );

  test(
    'runtime resolution uses connection config and typed credential',
    () async {
      final fixture = _ServiceFixture(now);
      fixture.discovery.ids = <String>['deepseek-v4-pro'];
      final connection = await fixture.service.connectApiKey(
        'deepseek',
        'runtime-secret',
      );

      final provider = await fixture.service.resolve(
        connection.id,
        modelId: 'deepseek-v4-pro',
      );

      expect(provider.id, 'created');
      final request = fixture.factory.lastRequest!;
      expect(request.connectionId, connection.id);
      expect(request.endpoint.baseUrl, 'https://api.deepseek.com');
      expect(request.credential, isA<ApiKeyCredential>());
      expect(
        (request.credential! as ApiKeyCredential).key,
        'runtime-secret',
      );
      expect(
        request.capabilities.controls.map((control) => control.id),
        contains(AgentModelControlIds.reasoningEffort),
      );
      await fixture.service.validateAgentModel(
        connection.id,
        'deepseek-v4-pro',
      );
      await expectLater(
        fixture.service.validateAgentModel(connection.id, 'missing'),
        throwsA(isA<StateError>()),
      );
    },
  );

  test(
    'ChatGPT OAuth connects on the bundled catalog without model discovery',
    () async {
      final fixture = _ServiceFixture(now);
      // The Codex endpoint answers 400 for `/models`; discovery must not run.
      fixture.discovery.failure = const ProviderDiscoveryFailure(
        ProviderDiscoveryFailureKind.unavailable,
        'status code of 400',
      );

      await fixture.service.connectOAuth(
        'openai',
        OAuthCredential(
          accessToken: 'access',
          refreshToken: 'refresh',
          expiresAt: now.add(const Duration(hours: 1)),
          accountId: 'account',
        ),
      );
      final connection = (await fixture.service.connections()).single;

      expect(fixture.discovery.calls, 0);
      expect(connection.status, ProviderConnectionStatus.connected);
      expect(connection.error, isNull);
      expect(
        (await fixture.service.listModels(connection.id)).map(
          (model) => model.id,
        ),
        containsAll(<String>[
          'openai/gpt-5.6-sol',
          'openai/gpt-5.6-terra',
          'openai/gpt-5.6-luna',
        ]),
      );
    },
    tags: const <String>['feature_test__provider_oauth__unit'],
  );

  test(
    'API key connections still discover models and degrade on failure',
    () async {
      final fixture = _ServiceFixture(now);
      fixture.discovery.failure = const ProviderDiscoveryFailure(
        ProviderDiscoveryFailureKind.unavailable,
        'discovery unavailable',
      );

      final connection = await fixture.service.connectApiKey(
        'openai',
        'secret',
      );

      expect(fixture.discovery.calls, 1);
      expect(connection.status, ProviderConnectionStatus.degraded);
      expect(connection.error, 'discovery unavailable');
    },
  );

  test(
    'OAuth runtime refreshes once and persists rotated credentials',
    () async {
      final fixture = _ServiceFixture(now);
      fixture.discovery.ids = <String>['gpt-5.6-sol'];
      final expired = OAuthCredential(
        accessToken: 'expired',
        refreshToken: 'refresh-old',
        expiresAt: now.subtract(const Duration(minutes: 1)),
        accountId: 'account',
      );
      final rotated = OAuthCredential(
        accessToken: 'fresh',
        refreshToken: 'refresh-new',
        expiresAt: now.add(const Duration(hours: 1)),
        accountId: 'account',
      );
      fixture.refresher.result = rotated;
      await fixture.service.connectOAuth(
        'openai',
        expired,
      );
      final connection = (await fixture.service.connections()).single;
      await fixture.service.resolve(
        connection.id,
        modelId: 'gpt-5.6-sol',
      );

      expect(fixture.refresher.calls, 1);
      expect(fixture.factory.lastCredential, same(rotated));
      expect(fixture.credentials.values[connection.id], same(rotated));
      // The subscription backend answers 400 for the platform-only request
      // fields, so the narrower surface is resolved from the endpoint the
      // OAuth credential selects — not from the bundled model capabilities,
      // which still advertise the tier for the platform API.
      final request = fixture.factory.lastRequest!;
      expect(request.endpoint.baseUrl, 'https://chatgpt.com/backend-api/codex');
      expect(
        openAIBundledModels
            .singleWhere((model) => model.id == 'gpt-5.6-sol')
            .capabilities
            .controls
            .map((control) => control.id),
        contains(AgentModelControlIds.fastMode),
      );
    },
  );

  test(
    'invalid OAuth refresh marks the connection for reauthentication',
    () async {
      final fixture = _ServiceFixture(now);
      fixture.discovery.ids = <String>['gpt-5.6-sol'];
      fixture.refresher.error = const OAuthRefreshFailure(
        'refresh rejected',
        reauthRequired: true,
      );
      await fixture.service.connectOAuth(
        'openai',
        OAuthCredential(
          accessToken: 'expired',
          refreshToken: 'invalid',
          expiresAt: now,
        ),
      );
      final connection = (await fixture.service.connections()).single;

      await expectLater(
        fixture.service.resolve(connection.id, modelId: 'gpt-5.6-sol'),
        throwsA(
          isA<ProviderConnectionFailure>().having(
            (error) => error.code,
            'code',
            'provider_not_connected',
          ),
        ),
      );
      expect(
        (await fixture.service.get(connection.id)).status,
        ProviderConnectionStatus.reauthRequired,
      );
    },
  );

  test('connection validation returns stable failures', () async {
    final fixture = _ServiceFixture(now);
    const failure = ProviderConnectionFailure('code', 'message');
    expect(failure.toString(), 'ProviderConnectionFailure(code): message');

    await expectLater(
      fixture.service.get('missing'),
      throwsA(
        isA<ProviderConnectionFailure>().having(
          (error) => error.code,
          'code',
          'provider_not_connected',
        ),
      ),
    );
    await expectLater(
      fixture.service.resolveQualifiedModel('unqualified'),
      throwsA(isA<FormatException>()),
    );
    await expectLater(
      fixture.service.createCustom(
        'unknown-wire',
        const CustomProviderConfigDto(
          name: 'Unknown wire',
          baseUrl: 'https://example.com/v1',
          wireFormatId: 'missing-wire',
          authenticationRequired: false,
        ),
      ),
      throwsA(isA<FormatException>()),
    );
    await expectLater(
      fixture.service.connectApiKey('deepseek', '  '),
      throwsA(isA<FormatException>()),
    );
    await expectLater(
      fixture.service.connectNone('deepseek'),
      throwsA(isA<StateError>()),
    );
    await expectLater(
      fixture.service.connectOAuth(
        'deepseek',
        OAuthCredential(
          accessToken: 'access',
          refreshToken: 'refresh',
          expiresAt: now.add(const Duration(hours: 1)),
        ),
      ),
      throwsA(isA<StateError>()),
    );
  });

  test(
    'custom lifecycle normalizes, edits, and deletes connections',
    () async {
      final fixture = _ServiceFixture(now);
      fixture.discovery.ids = <String>['discovered'];
      const noAuth = CustomProviderConfigDto(
        name: '  Local Lab  ',
        baseUrl: 'http://127.0.0.1:9000/v1///',
        wireFormatId: openAIResponsesWireId,
        authenticationRequired: false,
        models: <ManualProviderModelDto>[
          ManualProviderModelDto(id: ' manual ', label: ' Manual '),
          ManualProviderModelDto(id: '', label: ''),
          ManualProviderModelDto(id: 'manual', label: 'manual'),
        ],
      );

      final created = await fixture.service.createCustom('lab', noAuth);
      expect(created.displayName, 'Local Lab');
      expect(created.customConfig!.baseUrl, 'http://127.0.0.1:9000/v1');
      expect(
        created.customConfig!.models.map((model) => model.id).toList(),
        <String>['manual'],
      );
      expect(created.authKind, ProviderAuthKind.none);
      expect(await fixture.service.listModels(created.id), hasLength(2));

      await expectLater(
        fixture.service.createCustom('', noAuth),
        throwsA(isA<FormatException>()),
      );
      expect(await fixture.service.createCustom('lab', noAuth), isNotNull);
      await expectLater(
        fixture.service.createCustom(
          'unsafe',
          noAuth.copyWith(
            models: const <ManualProviderModelDto>[
              ManualProviderModelDto(
                id: 'model',
                label: 'Model',
                controls: <ModelControlDescriptorDto>[
                  ModelControlDescriptorDto(
                    id: 'reasoning_effort',
                    label: 'Injected',
                    kind: ModelControlKind.toggle,
                    presentation: ModelControlPresentation.selectableChip,
                  ),
                ],
              ),
            ],
          ),
        ),
        throwsA(isA<FormatException>()),
      );
      await expectLater(
        fixture.service.createCustom(
          'key-required',
          noAuth.copyWith(authenticationRequired: true),
        ),
        throwsA(isA<FormatException>()),
      );

      final updated = await fixture.service.updateCustom(
        created.id,
        noAuth.copyWith(authenticationRequired: true),
        apiKey: 'new-secret',
      );
      expect(updated.credentialOrigin, ProviderCredentialOrigin.stored);
      expect(fixture.credentials.values[created.id], isA<ApiKeyCredential>());
      await fixture.service.updateCustom(
        created.id,
        noAuth,
        apiKey: '',
      );
      expect(fixture.credentials.values, isNot(contains(created.id)));

      final builtIn = await fixture.service.connectApiKey(
        'deepseek',
        'secret',
      );
      await expectLater(
        fixture.service.updateCustom(builtIn.id, noAuth),
        throwsA(isA<StateError>()),
      );
      await expectLater(
        fixture.service.deleteCustom(builtIn.id),
        throwsA(isA<StateError>()),
      );
      await fixture.service.deleteCustom(created.id);
      await expectLater(
        fixture.service.get(created.id),
        throwsA(isA<ProviderConnectionFailure>()),
      );
    },
    tags: const <String>['feature_test__provider_custom__unit'],
  );

  test(
    'default model round-trips and clears back to automatic',
    () async {
      final fixture = _ServiceFixture(now);
      const selection = SessionModelSelectionDto(
        modelId: 'deepseek/deepseek-v4-pro',
      );

      expect(await fixture.service.storedDefaultModel(), isNull);

      await fixture.service.setDefaultModel(selection);
      expect(await fixture.service.storedDefaultModel(), selection);

      await fixture.service.setDefaultModel(null);
      expect(await fixture.service.storedDefaultModel(), isNull);
    },
    tags: const <String>['feature_test__provider_default_model__unit'],
  );

  test(
    'fallback prefers the stored default and keeps it when unusable',
    () async {
      final fixture = _ServiceFixture(now);
      fixture.discovery.ids = <String>[];
      final deepseek = await fixture.service.connectApiKey(
        'deepseek',
        'secret',
      );
      const stored = SessionModelSelectionDto(
        modelId: 'deepseek/deepseek-v4-pro',
      );
      await fixture.service.setDefaultModel(stored);

      expect(await fixture.service.fallbackModel(), stored);

      // A model the catalog no longer offers must not block resolution.
      await fixture.service.setDefaultModel(
        const SessionModelSelectionDto(
          modelId: 'deepseek/retired-model',
        ),
      );
      expect(
        await fixture.service.fallbackModel(),
        const SessionModelSelectionDto(
          modelId: 'deepseek/deepseek-chat',
        ),
      );

      // Nor must a connection that can no longer run.
      await fixture.service.setDefaultModel(stored);
      await fixture.service.disconnect(deepseek.id);
      expect(await fixture.service.fallbackModel(), isNull);

      // The unusable default survives so the settings page can surface it.
      expect(await fixture.service.storedDefaultModel(), stored);
    },
    tags: const <String>['feature_test__provider_default_model__unit'],
  );

  test(
    'first usable model follows connection and model ordering',
    () async {
      final fixture = _ServiceFixture(now);
      fixture.discovery.ids = <String>[];
      final xai = await fixture.service.connectApiKey('xai', 'secret');

      expect(
        await fixture.service.firstUsableModel(),
        const SessionModelSelectionDto(
          modelId: 'xai/grok-4.3',
        ),
      );

      // "DeepSeek" sorts before "xAI", so connecting it moves the choice.
      final deepseek = await fixture.service.connectApiKey(
        'deepseek',
        'secret',
      );
      expect(
        await fixture.service.firstUsableModel(),
        const SessionModelSelectionDto(
          modelId: 'deepseek/deepseek-chat',
        ),
      );

      // A first-by-label model that cannot stream is skipped, not returned.
      await fixture.repository.upsertModel(
        ProviderModelDto(
          connectionId: deepseek.id,
          id: 'deepseek/deepseek-alpha',
          providerModelId: 'deepseek-alpha',
          label: 'DeepSeek Alpha',
          source: ProviderModelSource.manual,
          capabilities: const ModelCapabilitiesDto(
            streaming: CapabilitySupport.unsupported,
            toolCalling: CapabilitySupport.supported,
          ),
        ),
      );
      expect(
        await fixture.service.firstUsableModel(),
        const SessionModelSelectionDto(
          modelId: 'deepseek/deepseek-chat',
        ),
      );

      await fixture.service.disconnect(deepseek.id);
      await fixture.service.disconnect(xai.id);
      expect(await fixture.service.firstUsableModel(), isNull);
    },
    tags: const <String>['feature_test__provider_default_model__unit'],
  );

  test(
    'agent model resolution falls back for session and unusable pins',
    () async {
      final fixture = _ServiceFixture(now);
      fixture.discovery.ids = <String>[];
      final deepseek = await fixture.service.connectApiKey(
        'deepseek',
        'secret',
      );

      final sessionSourced = await fixture.service.resolveAgentModel(
        const AgentModelSelectionDto(source: AgentModelSource.session),
      );
      expect(sessionSourced.modelId, 'deepseek-chat');

      final pinnedToMissing = await fixture.service.resolveAgentModel(
        const AgentModelSelectionDto(
          source: AgentModelSource.fixed,
          modelId: 'xai/grok-4.5',
        ),
      );
      expect(pinnedToMissing.connectionId, deepseek.id);

      final pinned = await fixture.service.resolveAgentModel(
        const AgentModelSelectionDto(
          source: AgentModelSource.fixed,
          modelId: 'deepseek/deepseek-v4-pro',
        ),
      );
      expect(pinned.modelId, 'deepseek-v4-pro');

      await fixture.service.disconnect(deepseek.id);
      await expectLater(
        fixture.service.resolveAgentModel(
          const AgentModelSelectionDto(source: AgentModelSource.session),
        ),
        throwsA(
          isA<ProviderConnectionFailure>().having(
            (error) => error.code,
            'code',
            'model_required',
          ),
        ),
      );
    },
    tags: const <String>['feature_test__provider_default_model__unit'],
  );

  test('model validation rejects unusable selections', () async {
    final fixture = _ServiceFixture(now);
    fixture.discovery.ids = <String>['unknown-capabilities'];
    final connection = await fixture.service.connectApiKey(
      'deepseek',
      'secret',
    );

    await expectLater(
      fixture.service.validateAgentModel(connection.id, 'missing'),
      throwsA(isA<StateError>()),
    );
    await expectLater(
      fixture.service.validateAgentModel(
        connection.id,
        'unknown-capabilities',
      ),
      throwsA(isA<StateError>()),
    );
    await fixture.service.disconnect(connection.id);
    await expectLater(
      fixture.service.validateAgentModel(
        connection.id,
        'deepseek-v4-pro',
      ),
      throwsA(isA<ProviderConnectionFailure>()),
    );
  });

  test(
    'explicit session models resolve only for usable connections',
    () async {
      final fixture = _ServiceFixture(now);
      fixture.discovery.ids = <String>['deepseek-v4-pro'];
      final connection = await fixture.service.connectApiKey(
        'deepseek',
        'secret',
      );

      final resolved = await fixture.service.resolveExplicitModel(
        connection.id,
        'deepseek-v4-pro',
      );
      expect(resolved.connectionId, connection.id);
      expect(resolved.modelId, 'deepseek-v4-pro');

      await expectLater(
        fixture.service.resolveExplicitModel(connection.id, 'missing'),
        throwsA(isA<StateError>()),
      );
      await fixture.service.disconnect(connection.id);
      await expectLater(
        fixture.service.resolveExplicitModel(
          connection.id,
          'deepseek-v4-pro',
        ),
        throwsA(isA<ProviderConnectionFailure>()),
      );
    },
    tags: const <String>['feature_test__session_lifecycle__unit'],
  );

  test(
    'runtime rejects missing credentials and transient refresh failures',
    () async {
      final missing = _ServiceFixture(now);
      missing.discovery.ids = <String>['deepseek-v4-pro'];
      final missingConnection = await missing.service.connectApiKey(
        'deepseek',
        'secret',
      );
      missing.credentials.values.remove(missingConnection.id);
      await expectLater(
        missing.service.resolve(
          missingConnection.id,
          modelId: 'deepseek-v4-pro',
        ),
        throwsA(isA<ProviderConnectionFailure>()),
      );

      final transient = _ServiceFixture(now);
      transient.discovery.ids = <String>['gpt-5.6-sol'];
      transient.refresher.error = const OAuthRefreshFailure(
        'temporary refresh failure',
        reauthRequired: false,
      );
      await transient.service.connectOAuth(
        'openai',
        OAuthCredential(
          accessToken: 'expired',
          refreshToken: 'refresh',
          expiresAt: now,
        ),
      );
      final connection = (await transient.service.connections()).single;
      await expectLater(
        transient.service.resolve(connection.id, modelId: 'gpt-5.6-sol'),
        throwsA(
          isA<ProviderConnectionFailure>().having(
            (error) => error.code,
            'code',
            'provider_unavailable',
          ),
        ),
      );
      expect(
        (await transient.service.get(connection.id)).status,
        ProviderConnectionStatus.connected,
      );
    },
  );
}

final class _ServiceFixture {
  _ServiceFixture(
    DateTime now, {
    ModelProvider? fixedProvider,
    ProviderCatalogMetadataSource? metadataSource,
    ProviderModelReferenceUpdater? referenceUpdater,
  }) : clock = _Clock(now),
       registry = ProviderRegistry(
         plugins: openAIFamilyPlugins(clock: _Clock(now)),
         wireProtocols: openAIWireProtocols(),
       ) {
    service = ProviderConnectionService(
      repository: repository,
      credentials: credentials,
      settings: settings,
      clock: clock,
      registry: registry,
      catalog: BuiltInProviderCatalog(
        clock: clock,
        registry: registry,
        metadataSource: metadataSource,
      ),
      modelDiscovery: discovery,
      providerFactory: factory,
      fixedProvider: fixedProvider,
      oauthRefresher: refresher,
      referenceUpdater: referenceUpdater,
    );
  }

  final _ProviderRepository repository = _ProviderRepository();
  final _Settings settings = _Settings();
  final _Credentials credentials = _Credentials();
  final _Discovery discovery = _Discovery();
  final _Factory factory = _Factory();
  final _Refresher refresher = _Refresher();
  final _Clock clock;
  final ProviderRegistry registry;
  late final ProviderConnectionService service;
}

final class _ReferenceUpdater implements ProviderModelReferenceUpdater {
  final List<String> calls = <String>[];

  @override
  Future<void> rewrite(String oldPrefix, String newPrefix) async {
    calls.add('$oldPrefix->$newPrefix');
  }
}

final class _OfflineMetadataSource implements ProviderCatalogMetadataSource {
  const _OfflineMetadataSource();

  @override
  Future<Map<String, List<ProviderCatalogMetadata>>> fetch(
    Set<String> providerIds,
  ) => Future<Map<String, List<ProviderCatalogMetadata>>>.error(
    StateError('offline'),
  );

  @override
  Future<void> close() async {}
}

final class _Refresher implements ProviderCredentialRefresher {
  OAuthCredential? result;
  OAuthRefreshFailure? error;
  int calls = 0;

  @override
  Future<OAuthCredential> refresh(
    String connectionId,
    String definitionId,
    OAuthCredential credential,
  ) async {
    calls += 1;
    final failure = error;
    if (failure != null) throw failure;
    return result ?? credential;
  }
}

final class _Clock implements Clock {
  const _Clock(this.value);

  final DateTime value;

  @override
  DateTime nowUtc() => value;
}

final class _Settings implements SettingsRepository {
  final Map<String, String> values = <String, String>{};

  @override
  Future<String?> getValue(String key) async => values[key];

  @override
  Future<void> setValue(String key, String value) async => values[key] = value;
}

final class _ProviderRepository implements ProviderRepository {
  final Map<String, ProviderConnectionDto> connections =
      <String, ProviderConnectionDto>{};
  final Map<String, ProviderModelDto> models = <String, ProviderModelDto>{};

  String _modelKey(String connectionId, String modelId) =>
      '$connectionId/$modelId';

  @override
  Future<void> deleteConnection(String id) async {
    connections.remove(id);
    models.removeWhere((_, model) => model.connectionId == id);
  }

  @override
  Future<void> deleteModel(String connectionId, String modelId) async {
    models.remove(_modelKey(connectionId, modelId));
  }

  @override
  Future<ProviderConnectionDto?> getConnection(String id) async =>
      connections[id];

  @override
  Future<ProviderModelDto?> getModel(
    String connectionId,
    String modelId,
  ) async => models[_modelKey(connectionId, modelId)];

  @override
  Future<List<ProviderConnectionDto>> listConnections() async =>
      connections.values.toList(growable: false);

  @override
  Future<List<ProviderModelDto>> listModels(String connectionId) async =>
      (models.values
              .where((model) => model.connectionId == connectionId)
              .toList()
            ..sort((a, b) => a.id.compareTo(b.id)))
          .toList(growable: false);

  @override
  Future<void> replaceModels(
    String connectionId,
    Iterable<ProviderModelDto> replacement,
  ) async {
    models.removeWhere((_, model) => model.connectionId == connectionId);
    for (final model in replacement) {
      models[_modelKey(connectionId, model.id)] = model;
    }
  }

  @override
  Future<ProviderConnectionDto> upsertConnection(
    ProviderConnectionDto connection,
  ) async {
    connections[connection.id] = connection;
    return connection;
  }

  @override
  Future<ProviderModelDto> upsertModel(ProviderModelDto model) async {
    models[_modelKey(model.connectionId, model.id)] = model;
    return model;
  }
}

final class _Credentials implements CredentialRepository {
  final Map<String, ProviderCredential> values = <String, ProviderCredential>{};
  @override
  final Map<String, String> mcpSecrets = <String, String>{};
  String? token;

  @override
  String? get bearerToken => token;

  @override
  ProviderCredential? credential(String connectionId) => values[connectionId];

  @override
  Future<void> load() async {}

  @override
  Future<void> removeCredential(String connectionId) async {
    values.remove(connectionId);
  }

  @override
  Future<void> setDaemonToken(String bearerToken) async {
    token = bearerToken;
  }

  @override
  Future<void> setCredential(
    String connectionId,
    ProviderCredential credential,
  ) async {
    values[connectionId] = credential;
  }

  @override
  Future<void> setMcpSecret(String key, String value) async {
    mcpSecrets[key] = value;
  }

  @override
  Future<void> removeMcpSecret(String key) async {
    mcpSecrets.remove(key);
  }
}

final class _Discovery implements ProviderModelDiscovery {
  List<String> ids = <String>[];
  ProviderDiscoveryFailure? failure;
  String? lastSecret;
  int calls = 0;

  @override
  Future<List<String>> fetchModelIds(
    ProviderEndpoint endpoint,
    ProviderCredential? credential,
  ) async {
    calls += 1;
    lastSecret = switch (credential) {
      ApiKeyCredential(:final key) => key,
      OAuthCredential(:final accessToken) => accessToken,
      null => '',
    };
    final error = failure;
    if (error != null) throw error;
    return ids;
  }
}

final class _Factory implements ModelProviderFactory {
  ModelProviderRequest? lastRequest;

  ProviderCredential? get lastCredential => lastRequest?.credential;

  @override
  ModelProvider create(ModelProviderRequest request) {
    lastRequest = request;
    return _EventProvider();
  }
}

final class _EventProvider implements ModelProvider {
  @override
  String get id => 'created';

  @override
  Stream<ModelEvent> stream(
    ModelRequest request,
    CancellationToken cancellation,
  ) => const Stream<ModelEvent>.empty();
}
