import 'dart:convert';
import 'dart:io';

import 'package:coder_agent/coder_agent.dart';
import 'package:coder_client/coder_client.dart';
import 'package:coder_daemon/coder_daemon.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:test/test.dart';

void main() {
  test(
    'standalone application serves authenticated workspace and agent RPCs',
    () async {
      final home = await Directory.systemTemp.createTemp('coder-daemon-home-');
      final workspace = await Directory.systemTemp.createTemp(
        'coder-workspace-',
      );
      final modelServer = await HttpServer.bind(
        InternetAddress.loopbackIPv4,
        0,
      );
      modelServer.listen((request) async {
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          jsonEncode(<String, dynamic>{
            'object': 'list',
            'data': <Map<String, dynamic>>[
              <String, dynamic>{'id': 'test-model', 'owned_by': 'test'},
              <String, dynamic>{'id': 'discovered-model', 'owned_by': 'test'},
            ],
          }),
        );
        await request.response.close();
      });
      final handle = await DaemonApplication.start(
        DaemonConfig(
          homeDirectory: home.path,
          port: 0,
          bearerToken: 'test-token-0123456789abcdef0123456789',
          useEnvironmentCredentials: false,
        ),
        provider: _PatchProvider(),
      );
      addTearDown(() async {
        await handle.stop();
        await home.delete(recursive: true);
        await workspace.delete(recursive: true);
        await modelServer.close(force: true);
      });

      final client = await CoderClient.connect(
        endpoint: HostEndpoint(
          websocketUri: handle.boundEndpoint,
          token: 'test-token-0123456789abcdef0123456789',
        ),
        clientId: 'integration-test',
        clientKind: 'test',
      );
      addTearDown(client.close);

      expect(client.serverInfo.serverId, handle.serverId);
      expect(client.serverInfo.features['providerAdmin'], isTrue);
      expect(client.serverInfo.features['jsonRpc2'], isTrue);
      final initialCatalog = await client.listProviderCatalog();
      expect(
        initialCatalog.definitions.map((item) => item.id),
        containsAll(<String>['openai', 'deepseek', 'ollama']),
      );
      expect(
        initialCatalog.toJson().toString(),
        isNot(anyOf(contains('baseUrl'), contains('transport'))),
      );
      final custom = await client.createCustomProvider(
        'local-test',
        CustomProviderConfigDto(
          name: 'Local test',
          baseUrl: 'http://127.0.0.1:${modelServer.port}/v1',
          apiFormat: ProviderApiFormat.chatCompletions,
          authenticationRequired: false,
          manualModelIds: const <String>['test-model'],
        ),
        makeDefault: true,
      );
      expect(custom.status, ProviderConnectionStatus.connected);
      expect(custom.authKind, ProviderAuthKind.none);
      expect(
        (await client.listProviderConnections())
            .singleWhere((connection) => connection.id == 'local-test')
            .id,
        'local-test',
      );
      expect(
        (await client.listProviderModels('local-test')).map((item) => item.id),
        containsAll(<String>['test-model', 'discovered-model']),
      );
      final updatedCustom = await client.updateCustomProvider(
        'local-test',
        CustomProviderConfigDto(
          name: 'Updated local test',
          baseUrl: 'http://127.0.0.1:${modelServer.port}/v1',
          apiFormat: ProviderApiFormat.chatCompletions,
          authenticationRequired: false,
          manualModelIds: const <String>['test-model'],
        ),
      );
      expect(updatedCustom.displayName, 'Updated local test');
      await client.setDefaultProviderModel('local-test', 'discovered-model');
      expect(
        (await client.listProviderConnections())
            .singleWhere((connection) => connection.id == 'local-test')
            .defaultModelId,
        'discovered-model',
      );
      await client.setDefaultProvider('local-test');
      final temporary = await client.createCustomProvider(
        'temporary',
        CustomProviderConfigDto(
          name: 'Temporary',
          baseUrl: 'http://127.0.0.1:${modelServer.port}/v1',
          apiFormat: ProviderApiFormat.responses,
          authenticationRequired: false,
          manualModelIds: const <String>['test-model'],
        ),
      );
      expect(temporary.id, 'temporary');
      await client.deleteCustomProvider(temporary.id);
      expect(
        (await client.listProviderConnections()).map((item) => item.id),
        isNot(contains('temporary')),
      );
      final registered = await client.registerWorkspace(
        id: 'workspace-1',
        rootPath: workspace.path,
        name: 'Workspace',
      );
      expect(registered.rootPath, workspace.resolveSymbolicLinksSync());
      expect(await client.listWorkspaces(), hasLength(1));

      final agent = await client.createAgent(
        id: 'agent-1',
        workspaceId: registered.id,
        title: 'Session',
        providerConnectionId: 'local-test',
        model: 'test-model',
        permissionMode: PermissionMode.ask,
      );
      expect(agent.status, AgentStatus.idle);
      final configuredAgent = await client.updateAgentConfiguration(
        agentId: agent.id,
        providerConnectionId: 'local-test',
        model: 'test-model',
        reasoningEffort: 'high',
      );
      expect(configuredAgent.reasoningEffort, 'high');
      expect(await client.listAgents(workspaceId: registered.id), hasLength(1));
      expect(await client.subscribeTimeline(agent.id), isEmpty);

      final approvalFuture = client.events
          .where((event) => event is ApprovalRequestedClientEvent)
          .cast<ApprovalRequestedClientEvent>()
          .map((event) => event.approval)
          .first
          .timeout(const Duration(seconds: 5));
      final completedFuture = client.events
          .where((event) => event is TimelineClientEvent)
          .cast<TimelineClientEvent>()
          .map((event) => event.event)
          .firstWhere((event) => event.type == 'turn.completed')
          .timeout(const Duration(seconds: 5));
      await client.startTurn(
        agentId: agent.id,
        turnId: 'turn-1',
        prompt: 'Create result.txt',
      );
      final approval = await approvalFuture;
      expect(approval.toolName, 'apply_patch');
      expect(approval.preview, contains('result.txt'));
      await client.resolveApproval(approvalId: approval.id, approved: true);
      await completedFuture;
      expect(
        client.updateAgentConfiguration(
          agentId: agent.id,
          providerConnectionId: 'local-test',
          model: 'discovered-model',
        ),
        throwsA(isA<CoderClientException>()),
      );

      expect(
        await File('${workspace.path}/result.txt').readAsString(),
        'done\n',
      );
      final timeline = await client.subscribeTimeline(agent.id);
      expect(
        timeline.map((event) => event.sequence),
        orderedEquals(
          List<int>.generate(timeline.length, (index) => index + 1),
        ),
      );
      expect(timeline.map((event) => event.type), contains('tool.completed'));
      expect(timeline.map((event) => event.type), contains('turn.completed'));
      await client.disconnectProvider('local-test');
      await expectLater(
        client.startTurn(
          agentId: agent.id,
          turnId: 'turn-stale-provider',
          prompt: 'This must not run.',
        ),
        throwsA(
          isA<CoderClientException>().having(
            (error) => error.code,
            'code',
            'provider_not_connected',
          ),
        ),
      );
      expect(
        (await client.listAgents(workspaceId: registered.id)).single.status,
        AgentStatus.idle,
      );
    },
  );

  test('non-loopback clients cannot mutate provider settings', () async {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
    );
    final address = interfaces
        .expand((item) => item.addresses)
        .where((item) => !item.isLoopback)
        .firstOrNull;
    if (address == null) return;
    final home = await Directory.systemTemp.createTemp('coder-remote-home-');
    final handle = await DaemonApplication.start(
      DaemonConfig(
        homeDirectory: home.path,
        host: '0.0.0.0',
        port: 0,
        bearerToken: 'remote-token-0123456789abcdef0123456789',
        useEnvironmentCredentials: false,
      ),
      provider: _PatchProvider(),
    );
    addTearDown(() async {
      await handle.stop();
      await home.delete(recursive: true);
    });
    final client = await CoderClient.connect(
      endpoint: HostEndpoint(
        websocketUri: handle.boundEndpoint.replace(host: address.address),
        token: 'remote-token-0123456789abcdef0123456789',
      ),
      clientId: 'remote-test',
      clientKind: 'mobile',
    );
    addTearDown(client.close);
    expect(client.serverInfo.features['providerAdmin'], isFalse);
    expect(
      client.createCustomProvider(
        'denied',
        const CustomProviderConfigDto(
          name: 'Denied',
          baseUrl: 'http://127.0.0.1:9999/v1',
          apiFormat: ProviderApiFormat.chatCompletions,
          authenticationRequired: false,
        ),
      ),
      throwsA(
        isA<CoderClientException>().having(
          (error) => error.code,
          'code',
          'local_admin_required',
        ),
      ),
    );
  });

  test('secrets are not persisted in daemon files', () async {
    final home = await Directory.systemTemp.createTemp('coder-secret-home-');
    final config = await Directory.systemTemp.createTemp(
      'coder-secret-config-',
    );
    const token = 'plaintext-token-that-must-not-be-stored';
    const apiKey = 'plaintext-api-key-that-must-not-be-stored';
    final handle = await DaemonApplication.start(
      DaemonConfig(
        homeDirectory: home.path,
        configDirectory: config.path,
        port: 0,
        bearerToken: token,
        useEnvironmentCredentials: false,
        apiKey: apiKey,
      ),
      modelDiscovery: const _StaticDiscovery(<String>['gpt-5.6-sol']),
    );
    await handle.stop();
    final persisted = StringBuffer();
    await for (final entity in home.list()) {
      if (entity is File) {
        persisted.write(String.fromCharCodes(await entity.readAsBytes()));
      }
    }
    expect(persisted.toString(), isNot(contains(token)));
    expect(persisted.toString(), isNot(contains(apiKey)));
    expect(
      await File('${config.path}/auth.json').readAsString(),
      contains(token),
    );
    expect(
      await File('${config.path}/credentials.json').readAsString(),
      contains(apiKey),
    );
    if (!Platform.isWindows) {
      expect(
        File('${config.path}/auth.json').statSync().mode & 0x1ff,
        0x180,
      );
      expect(
        File('${config.path}/credentials.json').statSync().mode & 0x1ff,
        0x180,
      );
    }
    await home.delete(recursive: true);
    await config.delete(recursive: true);
  });

  test('embedded daemon starts in an isolate and shuts down cleanly', () async {
    final home = await Directory.systemTemp.createTemp('coder-embedded-home-');
    final handle = await EmbeddedDaemonHandle.start(
      DaemonConfig(
        homeDirectory: home.path,
        port: 0,
        bearerToken: 'embedded-token-0123456789abcdef012345',
        useEnvironmentCredentials: false,
      ),
    );
    expect(handle.boundEndpoint.port, greaterThan(0));
    await handle.stop();
    await home.delete(recursive: true);
  });
}

final class _StaticDiscovery implements ProviderModelDiscovery {
  const _StaticDiscovery(this.modelIds);

  final List<String> modelIds;

  @override
  Future<List<String>> fetchModelIds(
    ProviderRuntimeConfig config,
    ProviderCredential? credential,
  ) async => modelIds;
}

class _PatchProvider implements ModelProvider {
  var _round = 0;

  @override
  String get id => 'fake';

  @override
  Stream<ModelEvent> stream(
    ModelRequest request,
    CancellationToken cancellation,
  ) async* {
    if (_round++ == 0) {
      const arguments = <String, dynamic>{
        'patch': '--- /dev/null\n+++ b/result.txt\n@@ -0,0 +1,1 @@\n+done\n',
      };
      yield const ModelFunctionCall(
        callId: 'patch-call',
        name: 'apply_patch',
        arguments: arguments,
      );
      yield const ModelResponseCompleted(
        assistant: AssistantConversationItem(
          text: '',
          toolCalls: <ConversationToolCall>[
            ConversationToolCall(
              callId: 'patch-call',
              name: 'apply_patch',
              arguments: arguments,
            ),
          ],
        ),
      );
      return;
    }
    yield const ModelTextDelta('Created result.txt');
    yield const ModelResponseCompleted(
      assistant: AssistantConversationItem(text: 'Created result.txt'),
    );
  }
}
