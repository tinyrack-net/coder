import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:coder_app/src/app.dart';
import 'package:coder_app/src/app_services.dart';
import 'package:coder_app/src/chat/chat_approval_card.dart';
import 'package:coder_app/src/chat/chat_timeline_model.dart';
import 'package:coder_app/src/chat/chat_timeline_view.dart';
import 'package:coder_app/src/controller.dart';
import 'package:coder_app/src/external_url_opener.dart';
import 'package:coder_app/src/host_models.dart';
import 'package:coder_app/src/host_ports.dart';
import 'package:coder_client/coder_client.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../support/fake_coder_api.dart';

void main() {
  final now = DateTime.utc(2026);
  final approval = ApprovalRequestDto(
    id: 'approval-1',
    sessionId: 'agent-1',
    turnId: 'turn-1',
    toolCallId: 'call-1',
    toolName: 'apply_patch',
    risk: ToolRisk.write,
    arguments: const <String, dynamic>{'patch': '--- a/file\n+++ b/file'},
    status: ApprovalStatus.pending,
    createdAt: now,
    preview: '--- a/lib/main.dart\n+++ b/lib/main.dart\n+safe change',
  );
  final chatEvents = <TimelineEventDto>[
    TimelineEventDto(
      sessionId: 'agent-1',
      sequence: 1,
      turnId: 'turn-1',
      type: 'user.message',
      data: const <String, dynamic>{'text': 'Fix the failing parser test'},
      createdAt: now,
    ),
    TimelineEventDto(
      sessionId: 'agent-1',
      sequence: 2,
      turnId: 'turn-1',
      type: 'assistant.delta',
      data: const <String, dynamic>{
        'text':
            'Reading the parser and running the suite.\n\n'
            '```dart\nfinal parser = Parser();\n```\n',
      },
      createdAt: now,
    ),
    TimelineEventDto(
      sessionId: 'agent-1',
      sequence: 3,
      turnId: 'turn-1',
      type: 'tool.requested',
      data: const <String, dynamic>{
        'callId': 'call-1',
        'name': 'read_file',
        'arguments': <String, dynamic>{'path': 'lib/parser.dart'},
      },
      createdAt: now,
    ),
    TimelineEventDto(
      sessionId: 'agent-1',
      sequence: 4,
      turnId: 'turn-1',
      type: 'tool.completed',
      data: const <String, dynamic>{
        'callId': 'call-1',
        'name': 'read_file',
        'output': 'line 1\nline 2\nline 3',
        'isError': false,
      },
      createdAt: now,
    ),
    TimelineEventDto(
      sessionId: 'agent-1',
      sequence: 5,
      turnId: 'turn-1',
      type: 'tool.requested',
      data: const <String, dynamic>{
        'callId': 'call-2',
        'name': 'run_command',
        'arguments': <String, dynamic>{'command': 'dart test'},
      },
      createdAt: now,
    ),
    TimelineEventDto(
      sessionId: 'agent-1',
      sequence: 6,
      turnId: 'turn-1',
      type: 'tool.completed',
      data: const <String, dynamic>{
        'callId': 'call-2',
        'name': 'run_command',
        'output': '{"exitCode":1,"output":"1 test failed"}',
        'isError': true,
      },
      createdAt: now,
    ),
    TimelineEventDto(
      sessionId: 'agent-1',
      sequence: 7,
      turnId: 'turn-1',
      type: 'turn.completed',
      data: const <String, dynamic>{'toolRounds': 2},
      createdAt: now,
    ),
  ];
  final planEvents = <TimelineEventDto>[
    TimelineEventDto(
      sessionId: 'agent-1',
      sequence: 1,
      turnId: 'turn-1',
      type: 'user.message',
      data: const <String, dynamic>{'text': 'Plan the parser migration'},
      createdAt: now,
    ),
    TimelineEventDto(
      sessionId: 'agent-1',
      sequence: 2,
      turnId: 'turn-1',
      type: 'assistant.delta',
      data: const <String, dynamic>{
        'text':
            'Explored the parser and its tests.\n'
            '<proposed_plan>\n'
            '## Plan\n\n'
            '1. Extract the tokenizer\n'
            '2. Move the parser tests\n'
            '3. Run `dart test`\n'
            '</proposed_plan>\n',
      },
      createdAt: now,
    ),
    TimelineEventDto(
      sessionId: 'agent-1',
      sequence: 3,
      turnId: 'turn-1',
      type: 'turn.completed',
      data: const <String, dynamic>{'toolRounds': 0},
      createdAt: now,
    ),
  ];
  final diffActivity = projectChatTimeline(<TimelineEventDto>[
    TimelineEventDto(
      sessionId: 'agent-1',
      sequence: 1,
      turnId: 'turn-1',
      type: 'tool.requested',
      data: const <String, dynamic>{
        'callId': 'call-1',
        'name': 'apply_patch',
        'arguments': <String, dynamic>{
          'patch':
              '--- a/lib/main.dart\n'
              '+++ b/lib/main.dart\n'
              '@@ -1,2 +1,3 @@\n'
              ' final a = 1;\n'
              '-final b = 2;\n'
              '+final b = 3;\n'
              '+final c = 4;\n',
        },
      },
      createdAt: now,
    ),
    TimelineEventDto(
      sessionId: 'agent-1',
      sequence: 2,
      turnId: 'turn-1',
      type: 'tool.completed',
      data: const <String, dynamic>{
        'callId': 'call-1',
        'name': 'apply_patch',
        'output': '{"changedFiles":1}',
        'isError': false,
      },
      createdAt: now,
    ),
  ]).single;

  unawaited(
    goldenTest(
      'chat timeline and approval cards render in light and dark themes',
      fileName: 'core_cards',
      constraints: const BoxConstraints.tightFor(width: 1000, height: 1560),
      builder: () => GoldenTestGroup(
        columns: 2,
        children: <Widget>[
          GoldenTestScenario(
            name: 'timeline light',
            child: SizedBox(
              width: 460,
              height: 420,
              child: _chat(ThemeMode.light, chatEvents),
            ),
          ),
          GoldenTestScenario(
            name: 'timeline dark',
            child: SizedBox(
              width: 460,
              height: 420,
              child: _chat(ThemeMode.dark, chatEvents),
            ),
          ),
          GoldenTestScenario(
            name: 'diff light',
            child: SizedBox(
              width: 460,
              height: 260,
              child: _chatItem(ThemeMode.light, diffActivity),
            ),
          ),
          GoldenTestScenario(
            name: 'diff dark',
            child: SizedBox(
              width: 460,
              height: 260,
              child: _chatItem(ThemeMode.dark, diffActivity),
            ),
          ),
          GoldenTestScenario(
            name: 'approval light',
            child: SizedBox(
              width: 460,
              height: 300,
              child: _material(
                ThemeMode.light,
                ProviderScope(
                  child: ApprovalCard(hostId: 'server', approval: approval),
                ),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'approval dark',
            child: SizedBox(
              width: 460,
              height: 300,
              child: _material(
                ThemeMode.dark,
                ProviderScope(
                  child: ApprovalCard(hostId: 'server', approval: approval),
                ),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'plan light',
            child: SizedBox(
              width: 460,
              height: 340,
              child: _chat(ThemeMode.light, planEvents),
            ),
          ),
          GoldenTestScenario(
            name: 'plan dark',
            child: SizedBox(
              width: 460,
              height: 340,
              child: _chat(ThemeMode.dark, planEvents),
            ),
          ),
          GoldenTestScenario(
            name: 'empty light',
            child: SizedBox(
              width: 460,
              height: 220,
              child: _chat(ThemeMode.light, const <TimelineEventDto>[]),
            ),
          ),
          GoldenTestScenario(
            name: 'empty dark',
            child: SizedBox(
              width: 460,
              height: 220,
              child: _chat(ThemeMode.dark, const <TimelineEventDto>[]),
            ),
          ),
        ],
      ),
    ),
  );

  unawaited(
    goldenTest(
      'provider settings adapts to desktop and mobile widths',
      fileName: 'provider_settings',
      constraints: const BoxConstraints.tightFor(width: 1500, height: 900),
      builder: () => GoldenTestGroup(
        columns: 2,
        children: <Widget>[
          GoldenTestScenario(
            name: 'desktop light',
            child: SizedBox(
              width: 1100,
              height: 760,
              child: _settings(ThemeMode.light),
            ),
          ),
          GoldenTestScenario(
            name: 'mobile dark',
            child: SizedBox(
              width: 390,
              height: 760,
              child: _settings(ThemeMode.dark),
            ),
          ),
        ],
      ),
    ),
  );

  unawaited(
    goldenTest(
      'Markdown agent settings adapts to desktop and mobile widths',
      fileName: 'agent_settings',
      constraints: const BoxConstraints.tightFor(width: 1500, height: 900),
      builder: () => GoldenTestGroup(
        columns: 2,
        children: <Widget>[
          GoldenTestScenario(
            name: 'desktop light',
            child: SizedBox(
              width: 1100,
              height: 760,
              child: _agentSettings(ThemeMode.light),
            ),
          ),
          GoldenTestScenario(
            name: 'mobile dark',
            child: SizedBox(
              width: 390,
              height: 760,
              child: _agentSettings(ThemeMode.dark),
            ),
          ),
        ],
      ),
    ),
  );

  unawaited(
    goldenTest(
      'daemon settings render embedded exposure and remote-only states',
      fileName: 'daemon_hosts',
      constraints: const BoxConstraints.tightFor(width: 1500, height: 900),
      builder: () => GoldenTestGroup(
        columns: 2,
        children: <Widget>[
          GoldenTestScenario(
            name: 'embedded exposure desktop',
            child: SizedBox(
              width: 800,
              height: 700,
              child: _localSettings(ThemeMode.light),
            ),
          ),
          GoldenTestScenario(
            name: 'remote settings mobile',
            child: SizedBox(
              width: 390,
              height: 700,
              child: _globalSettings(ThemeMode.dark),
            ),
          ),
        ],
      ),
    ),
  );

  unawaited(
    goldenTest(
      'session composer adapts to desktop and mobile widths',
      fileName: 'session_composer',
      constraints: const BoxConstraints.tightFor(width: 1500, height: 900),
      builder: () => GoldenTestGroup(
        columns: 2,
        children: <Widget>[
          GoldenTestScenario(
            name: 'desktop light',
            child: SizedBox(
              width: 1100,
              height: 760,
              child: _sessionComposer(ThemeMode.light),
            ),
          ),
          GoldenTestScenario(
            name: 'mobile dark',
            child: SizedBox(
              width: 390,
              height: 760,
              child: _sessionComposer(ThemeMode.dark),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _sessionComposer(ThemeMode mode) {
  final now = DateTime.utc(2026);
  final workspace = WorkspaceDto(
    id: 'workspace',
    name: 'Coder',
    rootPath: '/repos/coder',
    kind: WorkspaceKind.git,
    createdAt: now,
  );
  final checkout = WorktreeDto(
    id: 'checkout',
    workspaceId: workspace.id,
    name: 'main',
    path: workspace.rootPath,
    branch: 'main',
    head: 'abc',
    kind: WorktreeKind.checkout,
    isCoderOwned: false,
    createdAt: now,
  );
  final api = FakeCoderApi(
    workspaces: <WorkspaceDto>[workspace],
    worktrees: <WorktreeDto>[checkout],
  );
  return ProviderScope(
    overrides: [
      appServicesProvider.overrideWithValue(fakeAppServices(api)),
    ],
    child: _material(
      mode,
      const WorkspacePage(
        selection: WorkspaceSelection(
          hostId: 'server',
          workspaceId: 'workspace',
          worktreeId: 'checkout',
        ),
      ),
    ),
  );
}

Widget _settings(ThemeMode mode) {
  final now = DateTime.utc(2026);
  const longModelId =
      'vendor/reasoning-model-with-an-extremely-long-identifier';
  final api = FakeCoderApi(
    connections: <ProviderConnectionDto>[
      ProviderConnectionDto(
        id: 'openai',
        definitionId: 'openai',
        displayName: 'OpenAI',
        status: ProviderConnectionStatus.connected,
        authKind: ProviderAuthKind.apiKey,
        credentialOrigin: ProviderCredentialOrigin.stored,
        isDefault: true,
        defaultModelId: longModelId,
        createdAt: now,
        updatedAt: now,
      ),
      ProviderConnectionDto(
        id: 'lab',
        definitionId: 'custom',
        displayName: 'Lab compatible provider',
        status: ProviderConnectionStatus.degraded,
        authKind: ProviderAuthKind.none,
        credentialOrigin: ProviderCredentialOrigin.none,
        isDefault: false,
        defaultModelId: 'retired-model',
        error: 'Live model discovery is unavailable.',
        createdAt: now,
        updatedAt: now,
      ),
    ],
    models: const <String, List<ProviderModelDto>>{
      'openai': <ProviderModelDto>[
        ProviderModelDto(
          connectionId: 'openai',
          id: longModelId,
          label: 'Long reasoning model display name for coding workflows',
          source: ProviderModelSource.bundled,
          capabilities: ModelCapabilitiesDto(
            streaming: CapabilitySupport.supported,
            toolCalling: CapabilitySupport.supported,
            reasoningEffort: CapabilitySupport.supported,
            source: CapabilitySource.bundled,
          ),
        ),
      ],
      'lab': <ProviderModelDto>[
        ProviderModelDto(
          connectionId: 'lab',
          id: 'available-model',
          label: 'Available model',
          source: ProviderModelSource.discovered,
          capabilities: ModelCapabilitiesDto(),
        ),
      ],
    },
  );
  return ProviderScope(
    overrides: [
      appServicesProvider.overrideWithValue(fakeAppServices(api)),
    ],
    child: _material(
      mode,
      const UnifiedSettingsPage(
        category: SettingsCategory.provider,
        hostId: 'server',
      ),
    ),
  );
}

Widget _agentSettings(ThemeMode mode) {
  final api = FakeCoderApi();
  return ProviderScope(
    overrides: [
      appServicesProvider.overrideWithValue(fakeAppServices(api)),
    ],
    child: _material(
      mode,
      const UnifiedSettingsPage(
        category: SettingsCategory.agent,
        hostId: 'server',
      ),
    ),
  );
}

Widget _chat(ThemeMode mode, List<TimelineEventDto> events) => ProviderScope(
  overrides: [
    externalUrlOpenerProvider.overrideWithValue(const _NoopUrlOpener()),
  ],
  child: _material(
    mode,
    ChatTimelineView(items: projectChatTimeline(events), busy: false),
  ),
);

Widget _chatItem(ThemeMode mode, ChatItem item) => ProviderScope(
  overrides: [
    externalUrlOpenerProvider.overrideWithValue(const _NoopUrlOpener()),
  ],
  child: _material(
    mode,
    SingleChildScrollView(
      child: ChatItemView(item: item, expanded: true),
    ),
  ),
);

final class _NoopUrlOpener implements ExternalUrlOpener {
  const _NoopUrlOpener();

  @override
  Future<bool> open(Uri uri) async => true;
}

Widget _material(ThemeMode mode, Widget child) => MaterialApp(
  theme: ThemeData(colorSchemeSeed: const Color(0xff625bff)),
  darkTheme: ThemeData(
    brightness: Brightness.dark,
    colorSchemeSeed: const Color(0xff948dff),
  ),
  themeMode: mode,
  home: Scaffold(body: child),
);

Widget _localSettings(ThemeMode mode) {
  final store = MemoryAppStore(
    settings: const AppSettings(
      embeddedDaemonExposure: EmbeddedDaemonExposure.allInterfaces,
    ),
  );
  return ProviderScope(
    overrides: [
      appServicesProvider.overrideWithValue(
        AppServices(
          settings: store,
          profiles: store,
          credentials: store,
          clients: const _UnusedClients(),
          clientKind: 'golden',
          embeddedLauncher: const _GoldenEmbeddedLauncher(),
        ),
      ),
    ],
    child: _material(
      mode,
      const UnifiedSettingsPage(category: SettingsCategory.daemon),
    ),
  );
}

Widget _globalSettings(ThemeMode mode) {
  final now = DateTime.utc(2026, 8, 3);
  final store = MemoryAppStore(
    settings: const AppSettings(embeddedDaemonEnabled: false),
    profiles: <RemoteDaemonProfile>[
      RemoteDaemonProfile(
        id: 'production',
        label: 'Production daemon',
        websocketUri: Uri.parse('wss://coder.example.com/ws'),
        autoConnect: false,
        createdAt: now,
        updatedAt: now,
      ),
    ],
    tokens: const <String, String>{'production': 'secret'},
  );
  return ProviderScope(
    overrides: [
      appServicesProvider.overrideWithValue(
        AppServices(
          settings: store,
          profiles: store,
          credentials: store,
          clients: const _UnusedClients(),
          clientKind: 'golden',
        ),
      ),
    ],
    child: _material(
      mode,
      const UnifiedSettingsPage(category: SettingsCategory.daemon),
    ),
  );
}

final class _UnusedClients implements HostClientFactory {
  const _UnusedClients();

  @override
  Future<CoderApi> connect({
    required HostEndpoint endpoint,
    required DaemonCredentials credentials,
    required String clientId,
    required String clientKind,
  }) => throw StateError('Golden profiles do not auto-connect.');
}

final class _GoldenEmbeddedLauncher implements EmbeddedDaemonLauncher {
  const _GoldenEmbeddedLauncher();

  @override
  Future<EmbeddedDaemonSession> start({
    required EmbeddedDaemonExposure exposure,
  }) => Future<EmbeddedDaemonSession>.error(
    const HostConnectionFailure.network('Golden daemon is offline.'),
  );
}
