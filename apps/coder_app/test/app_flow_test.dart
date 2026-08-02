import 'package:coder_app/src/app.dart';
import 'package:coder_app/src/controller.dart';
import 'package:coder_client/coder_client.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'support/fake_coder_api.dart';

void main() {
  final now = DateTime.utc(2026, 8, 2);
  final workspace = WorkspaceDto(
    id: 'workspace',
    name: 'Workspace',
    rootPath: '/workspace',
    createdAt: now,
  );
  AgentDto agent(
    String id,
    AgentStatus status, {
    String model = 'gpt-5.6-sol',
  }) => AgentDto(
    id: id,
    workspaceId: workspace.id,
    title: 'Agent $id',
    providerId: 'openai',
    model: model,
    status: status,
    permissionMode: PermissionMode.ask,
    createdAt: now,
    updatedAt: now,
  );
  final selected = agent('selected', AgentStatus.idle);
  final approval = ApprovalRequestDto(
    id: 'approval',
    agentId: selected.id,
    turnId: 'turn',
    toolCallId: 'call',
    toolName: 'apply_patch',
    risk: ToolRisk.write,
    arguments: const <String, dynamic>{'patch': 'diff'},
    status: ApprovalStatus.pending,
    createdAt: now,
  );
  final timeline = <TimelineEventDto>[
    TimelineEventDto(
      agentId: selected.id,
      sequence: 1,
      turnId: 'turn',
      type: 'user.message',
      data: const <String, dynamic>{'text': 'Please inspect'},
      createdAt: now,
    ),
    TimelineEventDto(
      agentId: selected.id,
      sequence: 2,
      turnId: 'turn',
      type: 'assistant.delta',
      data: const <String, dynamic>{'text': 'Hello '},
      createdAt: now,
    ),
    TimelineEventDto(
      agentId: selected.id,
      sequence: 3,
      turnId: 'turn',
      type: 'assistant.delta',
      data: const <String, dynamic>{'text': 'world'},
      createdAt: now,
    ),
    TimelineEventDto(
      agentId: selected.id,
      sequence: 4,
      turnId: 'turn',
      type: 'tool.completed',
      data: const <String, dynamic>{'name': 'read_file', 'isError': false},
      createdAt: now,
    ),
    TimelineEventDto(
      agentId: selected.id,
      sequence: 5,
      turnId: 'turn',
      type: 'approval.requested',
      data: <String, dynamic>{'approval': approval.toJson()},
      createdAt: now,
    ),
  ];

  testWidgets('desktop dashboard renders all panes and conversation commands', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final api = FakeCoderApi(
      workspaces: <WorkspaceDto>[workspace],
      agents: <AgentDto>[
        selected,
        agent('running', AgentStatus.running),
        agent('approval', AgentStatus.waitingForApproval),
        agent('failed', AgentStatus.failed),
      ],
      timelines: <String, List<TimelineEventDto>>{selected.id: timeline},
    );
    final router = await _pumpRoute(
      tester,
      api,
      AgentRoute(
        hostId: 'server',
        workspaceId: workspace.id,
        agentId: selected.id,
      ).location,
    );
    addTearDown(router.dispose);

    expect(find.text('Workspaces'), findsOneWidget);
    expect(find.text('Agents'), findsOneWidget);
    expect(
      find.text('Agent selected'),
      findsWidgets,
      reason: _visibleText(tester),
    );
    await tester.drag(find.byType(ListView).last, const Offset(0, 500));
    await tester.pumpAndSettle();
    expect(find.text('Hello world', findRichText: true), findsOneWidget);
    expect(find.text('승인 필요 · apply_patch'), findsOneWidget);

    await tester.enterText(
      find.byType(TextField).last,
      '  run tests  ',
    );
    await tester.tap(find.byIcon(Icons.arrow_upward));
    await tester.pump();
    expect(api.startedPrompts, <String>['run tests']);
    await tester.tap(find.text('승인'));
    await tester.pump();
    expect(api.approvalDecisions.single.approved, isTrue);

    api.emit(
      AgentUpdatedClientEvent(selected.copyWith(status: AgentStatus.running)),
    );
    await tester.pump();
    expect(find.text('중지'), findsOneWidget);
    await tester.tap(find.text('중지'));
    await tester.pump();
    expect(api.cancelledAgents, <String>[selected.id]);
  });

  testWidgets('responsive agent creation and pre-turn configuration work', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(700, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final customProvider = ApiProviderDto(
      id: 'custom',
      name: 'Custom API',
      presetId: 'custom',
      baseUrl: 'http://localhost:8080/v1',
      transport: ApiTransport.chatCompletions,
      credentialSource: CredentialSource.stored,
      credentialConfigured: true,
      enabled: true,
      strictToolSchema: false,
      defaultModelId: 'custom-model',
      createdAt: now,
      updatedAt: now,
    );
    final api = FakeCoderApi(
      workspaces: <WorkspaceDto>[workspace],
      catalog: ProviderCatalogDto(
        defaultProviderId: 'openai',
        presets: const <ProviderPresetDto>[
          ProviderPresetDto(
            id: 'openai',
            name: 'OpenAI',
            defaultBaseUrl: 'https://api.openai.com/v1',
            defaultTransport: ApiTransport.responses,
            defaultCredentialSource: CredentialSource.environment,
            strictToolSchema: true,
            defaultModelId: 'gpt-5.6-sol',
          ),
          ProviderPresetDto(
            id: 'custom',
            name: 'Custom',
            defaultBaseUrl: 'http://localhost:8080/v1',
            defaultTransport: ApiTransport.chatCompletions,
            defaultCredentialSource: CredentialSource.stored,
            strictToolSchema: false,
            defaultModelId: 'custom-model',
          ),
        ],
        providers: <ApiProviderDto>[
          ApiProviderDto(
            id: 'openai',
            name: 'OpenAI',
            presetId: 'openai',
            baseUrl: 'https://api.openai.com/v1',
            transport: ApiTransport.responses,
            credentialSource: CredentialSource.environment,
            credentialConfigured: false,
            enabled: true,
            strictToolSchema: true,
            defaultModelId: 'gpt-5.6-sol',
            createdAt: now,
            updatedAt: now,
          ),
          customProvider,
        ],
      ),
      models: const <String, List<ProviderModelDto>>{
        'custom': <ProviderModelDto>[
          ProviderModelDto(
            providerId: 'custom',
            id: 'custom-model',
            label: 'custom-model',
            source: ProviderModelSource.manual,
            capabilities: ModelCapabilitiesDto(
              streaming: CapabilitySupport.supported,
              toolCalling: CapabilitySupport.supported,
              source: CapabilitySource.manual,
            ),
          ),
        ],
      },
    );
    final router = await _pumpRoute(
      tester,
      api,
      WorkspaceRoute(hostId: 'server', workspaceId: workspace.id).location,
    );
    addTearDown(router.dispose);

    expect(
      find.text('새 agent를 만들어 시작하세요.'),
      findsOneWidget,
      reason: _visibleText(tester),
    );
    await tester.tap(find.byTooltip('Agent 생성'));
    await tester.pumpAndSettle();
    expect(find.text('새 agent'), findsOneWidget);
    expect(find.text('gpt-5.6-sol'), findsWidgets);
    await tester.tap(_dropdown('API provider'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Custom API').last);
    await tester.pumpAndSettle();
    expect(find.text('custom-model'), findsWidgets);
    await tester.enterText(_field('이름'), '');
    await tester.tap(_dropdown('Reasoning effort'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('high').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(_dropdown('Permission mode'));
    await tester.tap(_dropdown('Permission mode'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('workspaceWrite').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('생성'));
    await tester.pumpAndSettle();
    expect(find.text('요청을 입력해 coding agent를 시작하세요.'), findsOneWidget);
    expect((await api.listAgents()).single.providerId, customProvider.id);
    expect((await api.listAgents()).single.title, 'Coding session');

    await tester.tap(find.byTooltip('Agent 모델 설정'));
    await tester.pumpAndSettle();
    expect(find.text('Agent 모델 설정'), findsOneWidget);
    await tester.tap(_dropdown('API provider'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OpenAI').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(find.text('요청을 입력해 coding agent를 시작하세요.'), findsOneWidget);
    expect((await api.listAgents()).single.providerId, 'openai');
  });

  testWidgets('host page validates and connects an explicit endpoint', (
    tester,
  ) async {
    final api = FakeCoderApi();
    await tester.pumpWidget(
      CoderApp(
        bootstrap: FakeAppBootstrap(
          api: api,
          autoConnectEnabled: false,
          connectFailures: 1,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('로컬 daemon을 시작하거나 원격 host에 연결합니다.'), findsOneWidget);

    await tester.enterText(_field('Daemon WebSocket 주소'), '127.0.0.1:7444');
    await tester.tap(find.text('연결'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Invalid'), findsOneWidget);

    await tester.enterText(
      _field('Daemon WebSocket 주소'),
      '127.0.0.1:7444',
    );
    await tester.enterText(_field('Bearer token'), 'token');
    await tester.tap(find.text('연결'));
    await tester.pumpAndSettle();
    expect(find.text('등록된 workspace가 없습니다.'), findsOneWidget);
  });

  testWidgets('dashboard fallbacks cover disconnected and empty selections', (
    tester,
  ) async {
    final disconnectedApi = FakeCoderApi();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bootstrapProvider.overrideWithValue(
            FakeAppBootstrap(
              api: disconnectedApi,
              autoConnectEnabled: false,
            ),
          ),
        ],
        child: const MaterialApp(
          home: DashboardPage(hostId: 'server'),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Host 연결로 돌아가기'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await disconnectedApi.close();

    final api = FakeCoderApi();
    final router = await _pumpRoute(
      tester,
      api,
      const DashboardRoute(hostId: 'server').location,
    );
    addTearDown(router.dispose);
    expect(find.text('등록된 workspace가 없습니다.'), findsOneWidget);
  });

  testWidgets(
    'timeline and approval cards render text and argument fallbacks',
    (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final api = FakeCoderApi(
        timelines: <String, List<TimelineEventDto>>{
          selected.id: <TimelineEventDto>[],
        },
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bootstrapProvider.overrideWithValue(FakeAppBootstrap(api: api)),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ListView(
                children: <Widget>[
                  TimelineCard(event: timeline.first),
                  TimelineCard(event: timeline[1]),
                  TimelineCard(event: timeline[3]),
                  ApprovalCard(approval: approval.copyWith(preview: null)),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('You'), findsOneWidget);
      expect(find.text('Assistant'), findsOneWidget);
      expect(find.text('tool.completed'), findsOneWidget);
      expect(find.textContaining('"patch": "diff"'), findsOneWidget);
      await tester.ensureVisible(find.text('거부'));
      await tester.tap(find.text('거부'));
      await tester.pump();
      expect(api.approvalDecisions.single.approved, isFalse);
    },
  );
}

String _visibleText(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((widget) => widget.data)
    .whereType<String>()
    .join(' | ');

Finder _field(String label) => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.labelText == label,
);

Finder _dropdown(String label) => find.byWidgetPredicate(
  (widget) =>
      widget is DropdownButtonFormField<dynamic> &&
      widget.decoration.labelText == label,
);

Future<GoRouter> _pumpRoute(
  WidgetTester tester,
  FakeCoderApi api,
  String location,
) async {
  final router = GoRouter(initialLocation: location, routes: $appRoutes);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        bootstrapProvider.overrideWithValue(FakeAppBootstrap(api: api)),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}
