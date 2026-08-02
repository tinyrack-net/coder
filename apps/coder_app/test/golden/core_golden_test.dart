import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:coder_app/src/app.dart';
import 'package:coder_app/src/app_services.dart';
import 'package:coder_app/src/controller.dart';
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
    agentId: 'agent-1',
    turnId: 'turn-1',
    toolCallId: 'call-1',
    toolName: 'apply_patch',
    risk: ToolRisk.write,
    arguments: const <String, dynamic>{'patch': '--- a/file\n+++ b/file'},
    status: ApprovalStatus.pending,
    createdAt: now,
    preview: '--- a/lib/main.dart\n+++ b/lib/main.dart\n+safe change',
  );
  final toolEvent = TimelineEventDto(
    agentId: 'agent-1',
    sequence: 2,
    turnId: 'turn-1',
    type: 'tool.completed',
    data: const <String, dynamic>{
      'name': 'read_file',
      'output': 'lib/main.dart',
      'isError': false,
    },
    createdAt: now,
  );

  unawaited(
    goldenTest(
      'approval and tool cards render in light and dark themes',
      fileName: 'core_cards',
      constraints: const BoxConstraints.tightFor(width: 900, height: 1000),
      builder: () => GoldenTestGroup(
        columns: 2,
        children: <Widget>[
          GoldenTestScenario(
            name: 'approval light',
            child: SizedBox(
              width: 400,
              height: 400,
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
              width: 400,
              height: 400,
              child: _material(
                ThemeMode.dark,
                ProviderScope(
                  child: ApprovalCard(hostId: 'server', approval: approval),
                ),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'tool light',
            child: SizedBox(
              width: 400,
              height: 200,
              child: _material(
                ThemeMode.light,
                TimelineCard(event: toolEvent),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'tool dark',
            child: SizedBox(
              width: 400,
              height: 200,
              child: _material(
                ThemeMode.dark,
                TimelineCard(event: toolEvent),
              ),
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
      'daemon-independent shell renders offline and global settings states',
      fileName: 'daemon_hosts',
      constraints: const BoxConstraints.tightFor(width: 1500, height: 900),
      builder: () => GoldenTestGroup(
        columns: 2,
        children: <Widget>[
          GoldenTestScenario(
            name: 'offline dashboard desktop',
            child: SizedBox(
              width: 800,
              height: 700,
              child: _offlineDashboard(ThemeMode.light),
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
}

Widget _settings(ThemeMode mode) {
  final api = FakeCoderApi(
    models: const <String, List<ProviderModelDto>>{
      'openai': <ProviderModelDto>[
        ProviderModelDto(
          connectionId: 'openai',
          id: 'gpt-5.6-sol',
          label: 'gpt-5.6-sol',
          source: ProviderModelSource.bundled,
          capabilities: ModelCapabilitiesDto(
            streaming: CapabilitySupport.supported,
            toolCalling: CapabilitySupport.supported,
            reasoningEffort: CapabilitySupport.supported,
            source: CapabilitySource.bundled,
          ),
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

Widget _material(ThemeMode mode, Widget child) => MaterialApp(
  theme: ThemeData(colorSchemeSeed: const Color(0xff625bff)),
  darkTheme: ThemeData(
    brightness: Brightness.dark,
    colorSchemeSeed: const Color(0xff948dff),
  ),
  themeMode: mode,
  home: Scaffold(body: child),
);

Widget _offlineDashboard(ThemeMode mode) {
  final api = FakeCoderApi();
  return ProviderScope(
    overrides: [
      appServicesProvider.overrideWithValue(
        fakeAppServices(api, connected: false),
      ),
    ],
    child: _material(
      mode,
      const WorkspacePage(),
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
