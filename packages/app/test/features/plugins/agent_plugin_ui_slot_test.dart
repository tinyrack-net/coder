import 'package:app/src/app/composition/app_providers.dart';
import 'package:app/src/features/plugins/presentation/agent_plugin_session_controls.dart';
import 'package:app/src/features/plugins/presentation/agent_plugin_ui_slot.dart';
import 'package:app/src/features/plugins/presentation/plugin_ui_document_view.dart';
import 'package:client/client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:protocol/protocol.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

import '../../support/fake_tinest_api.dart';
import '../../support/localization.dart';

void main() {
  testWidgets(
    'renders only Agent-referenced contributions for the requested slot',
    (tester) async {
      const contribution = PluginContributionDto(
        pluginId: 'example.controls',
        id: 'composer',
        kind: PluginContributionKind.ui,
        metadata: <String, dynamic>{
          'slots': <String>['composerControl'],
        },
      );
      const document = PluginUiDocumentDto(
        id: 'composer-document',
        pluginId: 'example.controls',
        revisionHash: 'revision',
        slot: PluginUiSlot.composerControl,
        root: <String, dynamic>{
          'type': 'button',
          'label': 'Continue goal',
          'actionId': 'continue',
        },
      );
      const agent = AgentDefinitionDto(
        version: 5,
        id: 'custom-agent',
        name: 'Custom Agent',
        description: 'Plugin controlled',
        mode: AgentMode.primary,
        model: AgentModelSelectionDto(source: AgentModelSource.session),
        driverId: 'tinest.standard/driver',
        extensionIds: <String>['example.controls'],
        toolIds: <String>[],
        pluginSettings: <String, Map<String, dynamic>>{},
        callableAgentIds: <String>[],
        prompt: '',
        contentHash: 'agent-hash',
        sourcePath: '/config/v5/agents/custom-agent.md',
      );
      final api = FakeTinestApi(
        agentDefinitions: const <AgentDefinitionDto>[agent],
        plugins: const <PluginDescriptorDto>[
          PluginDescriptorDto(
            apiMajor: 5,
            id: 'example.controls',
            version: '1.0.0',
            name: 'Controls',
            entrypoint: 'main.lua',
            source: PluginSource.user,
            sourcePath: '/config/v5/plugins/example.controls',
            requestedCapabilities: <String>[],
            contributions: <PluginContributionDto>[contribution],
          ),
          PluginDescriptorDto(
            apiMajor: 5,
            id: 'example.unreferenced',
            version: '1.0.0',
            name: 'Unreferenced',
            entrypoint: 'main.lua',
            source: PluginSource.user,
            sourcePath: '/config/v5/plugins/example.unreferenced',
            requestedCapabilities: <String>[],
            contributions: <PluginContributionDto>[
              PluginContributionDto(
                pluginId: 'example.unreferenced',
                id: 'composer',
                kind: PluginContributionKind.ui,
                metadata: <String, dynamic>{
                  'slots': <String>['composerControl'],
                },
              ),
            ],
          ),
        ],
        pluginUiDocuments: const <String, PluginUiDocumentDto>{
          'example.controls/composer/custom-agent': document,
        },
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appServicesProvider.overrideWithValue(fakeAppServices(api)),
          ],
          child: MaterialApp(
            theme: testLightTheme,
            locale: testLocale,
            localizationsDelegates: testLocalizationsDelegates,
            supportedLocales: testSupportedLocales,
            home: const Scaffold(
              body: AgentPluginUiSlot(
                hostId: 'server',
                agent: agent,
                slot: PluginUiSlot.composerControl,
                context: <String, dynamic>{'sessionId': 'session-1'},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TRButton, 'Continue goal'), findsOneWidget);
      expect(api.pluginUiRenders, hasLength(1));
      expect(api.pluginUiRenders.single.slot, PluginUiSlot.composerControl);
      expect(
        api.pluginUiRenders.single.context,
        <String, dynamic>{'sessionId': 'session-1'},
      );

      await tester.tap(find.widgetWithText(TRButton, 'Continue goal'));
      await tester.pumpAndSettle();
      expect(api.pluginUiActions.single.actionId, 'continue');
    },
    tags: const <String>['feature_test__plugin_ui__widget'],
  );

  testWidgets(
    'does not invoke a contribution registered for a different slot',
    (tester) async {
      const agent = AgentDefinitionDto(
        version: 5,
        id: 'custom-agent',
        name: 'Custom Agent',
        description: 'Plugin controlled',
        mode: AgentMode.primary,
        model: AgentModelSelectionDto(source: AgentModelSource.session),
        driverId: 'example.controls/driver',
        extensionIds: <String>[],
        toolIds: <String>[],
        pluginSettings: <String, Map<String, dynamic>>{},
        callableAgentIds: <String>[],
        prompt: '',
        contentHash: 'agent-hash',
        sourcePath: '/config/v5/agents/custom-agent.md',
      );
      final api = FakeTinestApi(
        agentDefinitions: const <AgentDefinitionDto>[agent],
        plugins: const <PluginDescriptorDto>[
          PluginDescriptorDto(
            apiMajor: 5,
            id: 'example.controls',
            version: '1.0.0',
            name: 'Controls',
            entrypoint: 'main.lua',
            source: PluginSource.user,
            sourcePath: '/config/v5/plugins/example.controls',
            requestedCapabilities: <String>[],
            contributions: <PluginContributionDto>[
              PluginContributionDto(
                pluginId: 'example.controls',
                id: 'settings',
                kind: PluginContributionKind.ui,
                metadata: <String, dynamic>{
                  'slots': <String>['agentSettings'],
                },
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appServicesProvider.overrideWithValue(fakeAppServices(api)),
          ],
          child: MaterialApp(
            theme: testLightTheme,
            locale: testLocale,
            localizationsDelegates: testLocalizationsDelegates,
            supportedLocales: testSupportedLocales,
            home: const Scaffold(
              body: AgentPluginUiSlot(
                hostId: 'server',
                agent: agent,
                slot: PluginUiSlot.conversationStatus,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(api.pluginUiRenders, isEmpty);
      expect(find.byType(PluginUiDocumentView), findsNothing);
    },
    tags: const <String>['feature_test__plugin_ui__widget'],
  );

  testWidgets(
    'a rejected render is translated and keeps its trace id',
    (tester) async {
      const contribution = PluginContributionDto(
        pluginId: 'example.controls',
        id: 'status',
        kind: PluginContributionKind.ui,
        metadata: <String, dynamic>{
          'slots': <String>['conversationStatus'],
        },
      );
      const agent = AgentDefinitionDto(
        version: 5,
        id: 'custom-agent',
        name: 'Custom Agent',
        description: 'Plugin controlled',
        mode: AgentMode.primary,
        model: AgentModelSelectionDto(source: AgentModelSource.session),
        driverId: 'tinest.standard/driver',
        extensionIds: <String>['example.controls'],
        toolIds: <String>[],
        pluginSettings: <String, Map<String, dynamic>>{},
        callableAgentIds: <String>[],
        prompt: '',
        contentHash: 'agent-hash',
        sourcePath: '/config/v5/agents/custom-agent.md',
      );
      final api =
          FakeTinestApi(
              agentDefinitions: const <AgentDefinitionDto>[agent],
              plugins: const <PluginDescriptorDto>[
                PluginDescriptorDto(
                  apiMajor: 5,
                  id: 'example.controls',
                  version: '1.0.0',
                  name: 'Controls',
                  entrypoint: 'main.lua',
                  source: PluginSource.user,
                  sourcePath: '/config/v5/plugins/example.controls',
                  requestedCapabilities: <String>[],
                  contributions: <PluginContributionDto>[contribution],
                ),
              ],
            )
            ..pluginUiRenderFailure = const TinestClientException(
              'Plugin UI callback failed.',
              code: RpcErrorCodes.pluginUiRejected,
              details: <String, dynamic>{'traceId': 'trace-42'},
            );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appServicesProvider.overrideWithValue(fakeAppServices(api)),
          ],
          child: MaterialApp(
            theme: testLightTheme,
            locale: testLocale,
            localizationsDelegates: testLocalizationsDelegates,
            supportedLocales: testSupportedLocales,
            home: const Scaffold(
              body: AgentPluginUiSlot(
                hostId: 'server',
                agent: agent,
                slot: PluginUiSlot.conversationStatus,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The user reads the translated reason, never the raw exception; the
      // trace id stays so a bug report still points at the daemon log record.
      expect(find.text(testL10n.pluginUiLoadFailed), findsOneWidget);
      expect(find.text(testL10n.errorPluginUiRejected), findsOneWidget);
      expect(find.textContaining('traceId: trace-42'), findsOneWidget);
      expect(find.textContaining('TinestClientException'), findsNothing);
      expect(
        find.widgetWithText(TRButton, testL10n.commonRetry),
        findsOneWidget,
      );
    },
    tags: const <String>['feature_test__plugin_ui__widget'],
  );

  testWidgets(
    'a session that has never run shows no slot rather than an error',
    (tester) async {
      const contribution = PluginContributionDto(
        pluginId: 'example.controls',
        id: 'status',
        kind: PluginContributionKind.ui,
        metadata: <String, dynamic>{
          'slots': <String>['conversationStatus'],
        },
      );
      const agent = AgentDefinitionDto(
        version: 5,
        id: 'custom-agent',
        name: 'Custom Agent',
        description: 'Plugin controlled',
        mode: AgentMode.primary,
        model: AgentModelSelectionDto(source: AgentModelSource.session),
        driverId: 'tinest.standard/driver',
        extensionIds: <String>['example.controls'],
        toolIds: <String>[],
        pluginSettings: <String, Map<String, dynamic>>{},
        callableAgentIds: <String>[],
        prompt: '',
        contentHash: 'agent-hash',
        sourcePath: '/config/v5/agents/custom-agent.md',
      );
      final api =
          FakeTinestApi(
              agentDefinitions: const <AgentDefinitionDto>[agent],
              plugins: const <PluginDescriptorDto>[
                PluginDescriptorDto(
                  apiMajor: 5,
                  id: 'example.controls',
                  version: '1.0.0',
                  name: 'Controls',
                  entrypoint: 'main.lua',
                  source: PluginSource.user,
                  sourcePath: '/config/v5/plugins/example.controls',
                  requestedCapabilities: <String>[],
                  contributions: <PluginContributionDto>[contribution],
                ),
              ],
            )
            ..pluginUiRenderFailure = const TinestClientException(
              'Agent custom-agent has no active revision for plugin '
              'example.controls.',
              code: RpcErrorCodes.pluginRevisionUnavailable,
            );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appServicesProvider.overrideWithValue(fakeAppServices(api)),
          ],
          child: MaterialApp(
            theme: testLightTheme,
            locale: testLocale,
            localizationsDelegates: testLocalizationsDelegates,
            supportedLocales: testSupportedLocales,
            home: const Scaffold(
              body: AgentPluginUiSlot(
                hostId: 'server',
                agent: agent,
                slot: PluginUiSlot.conversationStatus,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // An Agent pins its plugin revisions when a turn starts, so this is the
      // ordinary state of a conversation before its first message. Reporting
      // it would put a red panel beside every new session's composer.
      expect(find.text(testL10n.pluginUiLoadFailed), findsNothing);
      expect(find.byType(TRAlert), findsNothing);
    },
    tags: const <String>['feature_test__plugin_ui__widget'],
  );

  testWidgets(
    'Agent extension session control toggles through the typed plugin RPC',
    (tester) async {
      const agent = AgentDefinitionDto(
        version: 5,
        id: 'plan-agent',
        name: 'Plan Agent',
        description: '',
        mode: AgentMode.primary,
        model: AgentModelSelectionDto(source: AgentModelSource.session),
        driverId: 'tinest.standard/driver',
        extensionIds: <String>['tinest.plan'],
        toolIds: <String>[],
        pluginSettings: <String, Map<String, dynamic>>{},
        callableAgentIds: <String>[],
        prompt: '',
        contentHash: 'agent-hash',
        sourcePath: '/config/v5/agents/plan-agent.md',
      );
      const plugin = PluginDescriptorDto(
        apiMajor: 5,
        id: 'tinest.plan',
        version: '1.0.0',
        name: 'Plan',
        entrypoint: 'main.lua',
        source: PluginSource.builtIn,
        sourcePath: '/built-in/tinest.plan',
        requestedCapabilities: <String>[],
        contributions: <PluginContributionDto>[
          PluginContributionDto(
            pluginId: 'tinest.plan',
            id: 'tinest.plan/mode',
            kind: PluginContributionKind.sessionControl,
            metadata: <String, dynamic>{
              'label': 'Plan',
              'schema': <String, dynamic>{'type': 'boolean'},
            },
          ),
        ],
      );
      const control = PluginSessionControlValueDto(
        sessionId: 'session-1',
        agentId: 'plan-agent',
        pluginId: 'tinest.plan',
        contributionId: 'tinest.plan/mode',
        revisionHash: 'plan-revision',
        schema: <String, dynamic>{'type': 'boolean'},
        defaultValue: false,
        value: false,
        isDefault: true,
        metadata: <String, dynamic>{'label': 'Plan'},
      );
      final api = FakeTinestApi(
        agentDefinitions: const <AgentDefinitionDto>[agent],
        plugins: const <PluginDescriptorDto>[plugin],
        pluginSessionControls: const <String, PluginSessionControlValueDto>{
          'session-1/tinest.plan/tinest.plan/mode': control,
        },
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appServicesProvider.overrideWithValue(fakeAppServices(api)),
          ],
          child: MaterialApp(
            theme: testLightTheme,
            locale: testLocale,
            localizationsDelegates: testLocalizationsDelegates,
            supportedLocales: testSupportedLocales,
            home: const Scaffold(
              body: AgentPluginSessionControls(
                hostId: 'server',
                sessionId: 'session-1',
                agent: agent,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final finder = find.byKey(
        const ValueKey<String>(
          'plugin-session-control-tinest.plan/mode',
        ),
      );
      expect(tester.widget<TRSwitch>(finder).checked, isFalse);
      await tester.tap(finder);
      await tester.pumpAndSettle();

      expect(api.pluginSessionControlSets, hasLength(1));
      expect(api.pluginSessionControlSets.single.value, isTrue);
      expect(tester.widget<TRSwitch>(finder).checked, isTrue);
    },
    tags: const <String>[
      'feature_test__agent_harness__widget',
      'feature_test__plugin_runtime__widget',
      'feature_test__session_plan__widget',
    ],
  );

  testWidgets(
    'session controls render enum choices and explain unsupported schemas',
    (tester) async {
      const agent = AgentDefinitionDto(
        version: 5,
        id: 'controls-agent',
        name: 'Controls Agent',
        description: '',
        mode: AgentMode.primary,
        model: AgentModelSelectionDto(source: AgentModelSource.session),
        driverId: 'tinest.standard/driver',
        extensionIds: <String>['example.controls'],
        toolIds: <String>[],
        pluginSettings: <String, Map<String, dynamic>>{},
        callableAgentIds: <String>[],
        prompt: '',
        contentHash: 'controls-agent-hash',
        sourcePath: '/config/v5/agents/controls-agent.md',
      );
      const plugin = PluginDescriptorDto(
        apiMajor: 5,
        id: 'example.controls',
        version: '1.0.0',
        name: 'Controls',
        entrypoint: 'main.lua',
        source: PluginSource.user,
        sourcePath: '/config/v5/plugins/example.controls',
        requestedCapabilities: <String>[],
        contributions: <PluginContributionDto>[
          PluginContributionDto(
            pluginId: 'example.controls',
            id: 'example.controls/style',
            kind: PluginContributionKind.sessionControl,
            metadata: <String, dynamic>{
              'label': 'Response style',
              'description': 'Choose how detailed responses should be.',
            },
          ),
          PluginContributionDto(
            pluginId: 'example.controls',
            id: 'example.controls/unsupported',
            kind: PluginContributionKind.sessionControl,
          ),
        ],
      );
      const style = PluginSessionControlValueDto(
        sessionId: 'session-1',
        agentId: 'controls-agent',
        pluginId: 'example.controls',
        contributionId: 'example.controls/style',
        revisionHash: 'controls-revision',
        schema: <String, dynamic>{
          'type': 'string',
          'enum': <Object?>['concise', 7, 'detailed'],
        },
        defaultValue: 'concise',
        value: 'concise',
        isDefault: true,
      );
      const unsupported = PluginSessionControlValueDto(
        sessionId: 'session-1',
        agentId: 'controls-agent',
        pluginId: 'example.controls',
        contributionId: 'example.controls/unsupported',
        revisionHash: 'controls-revision',
        schema: <String, dynamic>{'type': 'integer'},
        defaultValue: 1,
        value: 1,
        isDefault: true,
      );
      final api = FakeTinestApi(
        agentDefinitions: const <AgentDefinitionDto>[agent],
        plugins: const <PluginDescriptorDto>[plugin],
        pluginSessionControls: const <String, PluginSessionControlValueDto>{
          'session-1/example.controls/example.controls/style': style,
          'session-1/example.controls/example.controls/unsupported':
              unsupported,
        },
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appServicesProvider.overrideWithValue(fakeAppServices(api)),
          ],
          child: MaterialApp(
            theme: testLightTheme,
            locale: testLocale,
            localizationsDelegates: testLocalizationsDelegates,
            supportedLocales: testSupportedLocales,
            home: const Scaffold(
              body: AgentPluginSessionControls(
                hostId: 'server',
                sessionId: 'session-1',
                agent: agent,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final selectFinder = find.byKey(
        const ValueKey<String>(
          'plugin-session-control-example.controls/style',
        ),
      );
      final select = tester.widget<TRSelect<String>>(selectFinder);
      expect(select.value, 'concise');
      expect(select.presentation, isA<TRSelectLayerPresentation>());
      expect(
        select.items.map((item) => item.value),
        <String>['concise', 'detailed'],
      );
      final field = tester.widget<TRField>(find.byType(TRField));
      expect(field.label, 'Response style');
      expect(field.description, 'Choose how detailed responses should be.');
      expect(find.text('example.controls/unsupported'), findsOneWidget);

      select.onValueChange?.call(null);
      select.onValueChange?.call('detailed');
      await tester.pumpAndSettle();

      expect(api.pluginSessionControlSets, hasLength(1));
      expect(api.pluginSessionControlSets.single.value, 'detailed');
      expect(tester.widget<TRSelect<String>>(selectFinder).value, 'detailed');
    },
    tags: const <String>[
      'feature_test__agent_harness__widget',
      'feature_test__plugin_runtime__widget',
    ],
  );
}
