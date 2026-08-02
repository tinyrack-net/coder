import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:coder_app/src/app.dart';
import 'package:coder_app/src/controller.dart';
import 'package:coder_app/src/settings_page.dart';
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
                ProviderScope(child: ApprovalCard(approval: approval)),
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
                ProviderScope(child: ApprovalCard(approval: approval)),
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
}

Widget _settings(ThemeMode mode) {
  final api = FakeCoderApi(
    models: const <String, List<ProviderModelDto>>{
      'openai': <ProviderModelDto>[
        ProviderModelDto(
          providerId: 'openai',
          id: 'gpt-5.6-sol',
          label: 'gpt-5.6-sol',
          source: ProviderModelSource.preset,
          capabilities: ModelCapabilitiesDto(
            streaming: CapabilitySupport.supported,
            toolCalling: CapabilitySupport.supported,
            reasoningEffort: CapabilitySupport.supported,
            source: CapabilitySource.preset,
          ),
        ),
      ],
    },
  );
  return ProviderScope(
    overrides: [
      bootstrapProvider.overrideWithValue(FakeAppBootstrap(api: api)),
    ],
    child: _material(mode, const SettingsPage(hostId: 'server')),
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
