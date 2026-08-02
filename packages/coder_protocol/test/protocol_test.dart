import 'dart:convert';

import 'package:coder_protocol/coder_protocol.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime.utc(2026, 8, 2);
  final workspace = WorkspaceDto(
    id: 'workspace',
    name: 'Coder',
    rootPath: '/workspace',
    createdAt: now,
  );
  const capabilities = ModelCapabilitiesDto(
    streaming: CapabilitySupport.supported,
    toolCalling: CapabilitySupport.supported,
    reasoningEffort: CapabilitySupport.unsupported,
    supportedReasoningEfforts: <String>['low', 'medium'],
    source: CapabilitySource.manual,
  );
  final provider = ApiProviderDto(
    id: 'provider',
    name: 'Provider',
    presetId: 'custom',
    baseUrl: 'http://localhost:11434/v1',
    transport: ApiTransport.chatCompletions,
    credentialSource: CredentialSource.stored,
    credentialConfigured: true,
    environmentVariable: 'PROVIDER_KEY',
    enabled: true,
    strictToolSchema: false,
    defaultModelId: 'model',
    visibleModelIds: const <String>['model'],
    createdAt: now,
    updatedAt: now,
  );
  const preset = ProviderPresetDto(
    id: 'custom',
    name: 'Custom',
    defaultBaseUrl: 'http://localhost/v1',
    defaultTransport: ApiTransport.chatCompletions,
    defaultCredentialSource: CredentialSource.none,
    strictToolSchema: false,
    defaultEnvironmentVariable: 'CUSTOM_KEY',
    defaultModelId: 'model',
    modelIds: <String>['model'],
  );
  final model = ProviderModelDto(
    providerId: provider.id,
    id: 'model',
    label: 'Model',
    source: ProviderModelSource.manual,
    capabilities: capabilities,
    diagnosticStatus: DiagnosticStatus.verified,
    verifiedAt: now,
    diagnosticError: 'previous error',
  );
  final catalog = ProviderCatalogDto(
    providers: <ApiProviderDto>[provider],
    presets: <ProviderPresetDto>[preset],
    defaultProviderId: provider.id,
  );
  final agent = AgentDto(
    id: 'agent',
    workspaceId: workspace.id,
    title: 'Agent',
    providerId: provider.id,
    model: model.id,
    status: AgentStatus.waitingForApproval,
    permissionMode: PermissionMode.ask,
    createdAt: now,
    updatedAt: now,
    activeTurnId: 'turn',
    lastError: 'none',
  );
  final timeline = TimelineEventDto(
    agentId: agent.id,
    sequence: 4,
    turnId: 'turn',
    type: 'approval.requested',
    data: const <String, dynamic>{'value': true},
    createdAt: now,
  );
  final approval = ApprovalRequestDto(
    id: 'approval',
    agentId: agent.id,
    turnId: 'turn',
    toolCallId: 'call',
    toolName: 'apply_patch',
    risk: ToolRisk.write,
    arguments: const <String, dynamic>{'patch': 'diff'},
    status: ApprovalStatus.pending,
    createdAt: now,
    preview: 'diff',
  );
  final diagnostic = ProviderDiagnosticDto(
    providerId: provider.id,
    model: model.id,
    status: DiagnosticStatus.verified,
    endpointReachable: true,
    streaming: true,
    toolCalling: true,
    checkedAt: now,
    error: 'none',
  );

  test('protocol version and direct JSON-RPC names are stable', () {
    expect(coderProtocolVersion, 2);
    expect(RpcMethod.workspaceList, 'workspace.list');
    expect(RpcMethod.agentCreate, 'agent.create');
    expect(RpcMethod.turnStart, 'turn.start');
    expect(RpcNotification.timelineEvent, 'timeline.event');
  });

  test('all domain DTOs round-trip with additive fields', () {
    _roundTrip(workspace, (value) => value.toJson(), WorkspaceDto.fromJson);
    _roundTrip(agent, (value) => value.toJson(), AgentDto.fromJson);
    _roundTrip(
      capabilities,
      (value) => value.toJson(),
      ModelCapabilitiesDto.fromJson,
    );
    _roundTrip(provider, (value) => value.toJson(), ApiProviderDto.fromJson);
    _roundTrip(preset, (value) => value.toJson(), ProviderPresetDto.fromJson);
    _roundTrip(model, (value) => value.toJson(), ProviderModelDto.fromJson);
    _roundTrip(catalog, (value) => value.toJson(), ProviderCatalogDto.fromJson);
    _roundTrip(
      diagnostic,
      (value) => value.toJson(),
      ProviderDiagnosticDto.fromJson,
    );
    _roundTrip(timeline, (value) => value.toJson(), TimelineEventDto.fromJson);
    _roundTrip(
      approval,
      (value) => value.toJson(),
      ApprovalRequestDto.fromJson,
    );
    _roundTrip(
      const ServerInfoDto(
        serverId: 'server',
        version: '1.0.0',
        protocolVersion: coderProtocolVersion,
        features: <String, bool>{'providerAdmin': true},
      ),
      (value) => value.toJson(),
      ServerInfoDto.fromJson,
    );
    _roundTrip(
      const RpcErrorDto(
        code: 'invalid',
        message: 'Invalid request',
        retryable: false,
        details: <String, dynamic>{'field': 'model'},
      ),
      (value) => value.toJson(),
      RpcErrorDto.fromJson,
    );
  });

  test('all request DTOs round-trip', () {
    _roundTrip(
      const HelloParamsDto(
        clientId: 'client',
        clientKind: 'desktop',
        protocolVersion: coderProtocolVersion,
        capabilities: <String, bool>{'timelineCatchup': true},
      ),
      (value) => value.toJson(),
      HelloParamsDto.fromJson,
    );
    _roundTrip(
      const WorkspaceRegisterParamsDto(
        id: 'workspace',
        rootPath: '/workspace',
        name: 'Workspace',
      ),
      (value) => value.toJson(),
      WorkspaceRegisterParamsDto.fromJson,
    );
    _roundTrip(
      const AgentListParamsDto(workspaceId: 'workspace'),
      (value) => value.toJson(),
      AgentListParamsDto.fromJson,
    );
    _roundTrip(
      const AgentCreateParamsDto(
        id: 'agent',
        workspaceId: 'workspace',
        title: 'Agent',
        providerId: 'provider',
        model: 'model',
        reasoningEffort: 'medium',
        permissionMode: PermissionMode.workspaceWrite,
      ),
      (value) => value.toJson(),
      AgentCreateParamsDto.fromJson,
    );
    _roundTrip(
      const AgentConfigurationUpdateParamsDto(
        agentId: 'agent',
        providerId: 'provider',
        model: 'model',
        reasoningEffort: 'high',
      ),
      (value) => value.toJson(),
      AgentConfigurationUpdateParamsDto.fromJson,
    );
    _roundTrip(
      ProviderUpsertParamsDto(provider: provider, makeDefault: true),
      (value) => value.toJson(),
      ProviderUpsertParamsDto.fromJson,
    );
    _roundTrip(
      const ProviderIdParamsDto(providerId: 'provider'),
      (value) => value.toJson(),
      ProviderIdParamsDto.fromJson,
    );
    _roundTrip(
      const ProviderModelParamsDto(
        providerId: 'provider',
        modelId: 'model',
      ),
      (value) => value.toJson(),
      ProviderModelParamsDto.fromJson,
    );
    _roundTrip(
      ProviderModelUpsertParamsDto(model: model),
      (value) => value.toJson(),
      ProviderModelUpsertParamsDto.fromJson,
    );
    _roundTrip(
      const ProviderCredentialSetParamsDto(
        providerId: 'provider',
        apiKey: 'secret',
      ),
      (value) => value.toJson(),
      ProviderCredentialSetParamsDto.fromJson,
    );
    _roundTrip(
      const TurnStartParamsDto(
        agentId: 'agent',
        turnId: 'turn',
        prompt: 'hello',
      ),
      (value) => value.toJson(),
      TurnStartParamsDto.fromJson,
    );
    _roundTrip(
      const AgentIdParamsDto(agentId: 'agent'),
      (value) => value.toJson(),
      AgentIdParamsDto.fromJson,
    );
    _roundTrip(
      const ApprovalResolveParamsDto(
        approvalId: 'approval',
        approved: true,
      ),
      (value) => value.toJson(),
      ApprovalResolveParamsDto.fromJson,
    );
    _roundTrip(
      const TimelineSubscribeParamsDto(
        agentId: 'agent',
        afterSequence: 12,
      ),
      (value) => value.toJson(),
      TimelineSubscribeParamsDto.fromJson,
    );
  });

  test('all result DTOs round-trip', () {
    _roundTrip(
      WorkspaceListResultDto(workspaces: <WorkspaceDto>[workspace]),
      (value) => value.toJson(),
      WorkspaceListResultDto.fromJson,
    );
    _roundTrip(
      WorkspaceResultDto(workspace: workspace),
      (value) => value.toJson(),
      WorkspaceResultDto.fromJson,
    );
    _roundTrip(
      AgentListResultDto(agents: <AgentDto>[agent]),
      (value) => value.toJson(),
      AgentListResultDto.fromJson,
    );
    _roundTrip(
      AgentResultDto(agent: agent),
      (value) => value.toJson(),
      AgentResultDto.fromJson,
    );
    _roundTrip(
      ProviderCatalogResultDto(catalog: catalog),
      (value) => value.toJson(),
      ProviderCatalogResultDto.fromJson,
    );
    _roundTrip(
      ProviderResultDto(provider: provider),
      (value) => value.toJson(),
      ProviderResultDto.fromJson,
    );
    _roundTrip(
      ProviderModelsResultDto(models: <ProviderModelDto>[model]),
      (value) => value.toJson(),
      ProviderModelsResultDto.fromJson,
    );
    _roundTrip(
      ProviderModelResultDto(model: model),
      (value) => value.toJson(),
      ProviderModelResultDto.fromJson,
    );
    _roundTrip(
      ProviderDiagnosticResultDto(diagnostic: diagnostic),
      (value) => value.toJson(),
      ProviderDiagnosticResultDto.fromJson,
    );
    _roundTrip(
      const TurnStartResultDto(created: true),
      (value) => value.toJson(),
      TurnStartResultDto.fromJson,
    );
    _roundTrip(
      ApprovalResultDto(approval: approval),
      (value) => value.toJson(),
      ApprovalResultDto.fromJson,
    );
    _roundTrip(
      TimelineResultDto(events: <TimelineEventDto>[timeline]),
      (value) => value.toJson(),
      TimelineResultDto.fromJson,
    );
  });

  test('malformed required values and protocol envelopes are rejected', () {
    expect(
      () => WorkspaceDto.fromJson(const <String, dynamic>{'id': 'missing'}),
      throwsA(isA<TypeError>()),
    );
    expect(
      () => WireEnvelope.decode('[]'),
      throwsA(isA<ProtocolException>()),
    );
    expect(
      () => WireEnvelope.fromJson(const <String, dynamic>{
        'version': coderProtocolVersion,
        'type': 'notification',
        'payload': <String, dynamic>{},
        'requestId': 12,
      }),
      throwsA(isA<ProtocolException>()),
    );
  });

  test('wire envelope round-trips and ignores additive fields', () {
    final envelope = WireEnvelope.fromJson(const <String, dynamic>{
      'version': coderProtocolVersion,
      'type': 'future.event',
      'requestId': 'request-1',
      'payload': <String, dynamic>{'value': 42, 'futureField': true},
      'unknownEnvelopeField': 'ignored',
    });

    expect(envelope.payload['futureField'], isTrue);
    expect(WireEnvelope.decode(envelope.encode()).requestId, 'request-1');
  });

  test('every enum value has a stable JSON name', () {
    final values = <Enum>[
      ...AgentStatus.values,
      ...TurnStatus.values,
      ...PermissionMode.values,
      ...ApprovalStatus.values,
      ...ToolRisk.values,
      ...ApiTransport.values,
      ...CredentialSource.values,
      ...ProviderModelSource.values,
      ...CapabilitySupport.values,
      ...CapabilitySource.values,
      ...DiagnosticStatus.values,
    ];
    expect(values.map((value) => value.name).toSet(), isNotEmpty);
  });
}

void _roundTrip<T>(
  T value,
  Map<String, dynamic> Function(T value) encoder,
  T Function(Map<String, dynamic> json) decoder,
) {
  final encoded = jsonEncode(<String, dynamic>{
    ...encoder(value),
    'futureField': true,
  });
  final json = Map<String, dynamic>.from(jsonDecode(encoded) as Map);
  expect(decoder(json), value);
}
