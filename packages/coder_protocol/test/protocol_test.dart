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
  const authMethod = ProviderAuthMethodDto(
    id: 'api-key',
    label: 'API key',
    kind: ProviderAuthKind.apiKey,
    flow: ProviderAuthFlow.apiKey,
  );
  const definition = ProviderDefinitionDto(
    id: 'provider',
    name: 'Provider',
    description: 'A hosted provider.',
    authMethods: <ProviderAuthMethodDto>[authMethod],
    recommendedModelIds: <String>['model'],
  );
  const customConfig = CustomProviderConfigDto(
    name: 'Custom',
    baseUrl: 'http://localhost:11434/v1',
    apiFormat: ProviderApiFormat.chatCompletions,
    authenticationRequired: true,
    manualModelIds: <String>['model'],
  );
  final connection = ProviderConnectionDto(
    id: 'provider',
    definitionId: definition.id,
    displayName: definition.name,
    status: ProviderConnectionStatus.connected,
    authKind: ProviderAuthKind.apiKey,
    credentialOrigin: ProviderCredentialOrigin.stored,
    isDefault: true,
    defaultModelId: 'model',
    createdAt: now,
    updatedAt: now,
  );
  final model = ProviderModelDto(
    connectionId: connection.id,
    id: 'model',
    label: 'Model',
    source: ProviderModelSource.manual,
    capabilities: capabilities,
    diagnosticStatus: DiagnosticStatus.verified,
    verifiedAt: now,
    diagnosticError: 'previous error',
    pricing: const ModelPricingDto(
      input: 1.25,
      output: 2.5,
      cacheRead: 0.25,
      cacheWrite: 0.5,
    ),
    limits: const ModelLimitsDto(
      context: 128000,
      input: 120000,
      output: 8000,
    ),
  );
  final catalog = ProviderCatalogDto(
    definitions: const <ProviderDefinitionDto>[definition],
    source: ProviderCatalogSource.bundled,
    updatedAt: now,
  );
  final authAttempt = ProviderAuthAttemptDto(
    id: 'attempt',
    definitionId: definition.id,
    methodId: 'chatgpt-device',
    status: ProviderAuthAttemptStatus.awaitingUser,
    authorizationUrl: 'https://auth.openai.com/codex/device',
    userCode: 'ABCD-EFGH',
    instructions: 'Enter the code.',
    expiresAt: now.add(const Duration(minutes: 15)),
  );
  final agent = AgentDto(
    id: 'agent',
    workspaceId: workspace.id,
    title: 'Agent',
    providerConnectionId: connection.id,
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
    connectionId: connection.id,
    model: model.id,
    status: DiagnosticStatus.verified,
    endpointReachable: true,
    streaming: true,
    toolCalling: true,
    checkedAt: now,
    error: 'none',
  );

  test('protocol version and direct JSON-RPC names are stable', () {
    expect(coderProtocolVersion, 3);
    expect(RpcMethod.workspaceList, 'workspace.list');
    expect(RpcMethod.agentCreate, 'agent.create');
    expect(RpcMethod.providerCatalog, 'provider.catalog');
    expect(RpcMethod.providerAuthStart, 'provider.auth.start');
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
    _roundTrip(
      model.pricing!,
      (value) => value.toJson(),
      ModelPricingDto.fromJson,
    );
    _roundTrip(
      model.limits!,
      (value) => value.toJson(),
      ModelLimitsDto.fromJson,
    );
    _roundTrip(
      authMethod,
      (value) => value.toJson(),
      ProviderAuthMethodDto.fromJson,
    );
    _roundTrip(
      definition,
      (value) => value.toJson(),
      ProviderDefinitionDto.fromJson,
    );
    _roundTrip(
      connection,
      (value) => value.toJson(),
      ProviderConnectionDto.fromJson,
    );
    _roundTrip(
      customConfig,
      (value) => value.toJson(),
      CustomProviderConfigDto.fromJson,
    );
    _roundTrip(
      authAttempt,
      (value) => value.toJson(),
      ProviderAuthAttemptDto.fromJson,
    );
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
        providerConnectionId: 'provider',
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
        providerConnectionId: 'provider',
        model: 'model',
        reasoningEffort: 'high',
      ),
      (value) => value.toJson(),
      AgentConfigurationUpdateParamsDto.fromJson,
    );
    _roundTrip(
      const ProviderConnectApiKeyParamsDto(
        definitionId: 'provider',
        apiKey: 'secret',
        makeDefault: true,
      ),
      (value) => value.toJson(),
      ProviderConnectApiKeyParamsDto.fromJson,
    );
    _roundTrip(
      const ProviderConnectNoneParamsDto(
        definitionId: 'ollama',
        makeDefault: false,
      ),
      (value) => value.toJson(),
      ProviderConnectNoneParamsDto.fromJson,
    );
    _roundTrip(
      const ProviderConnectionIdParamsDto(connectionId: 'provider'),
      (value) => value.toJson(),
      ProviderConnectionIdParamsDto.fromJson,
    );
    _roundTrip(
      const ProviderModelParamsDto(
        connectionId: 'provider',
        modelId: 'model',
      ),
      (value) => value.toJson(),
      ProviderModelParamsDto.fromJson,
    );
    _roundTrip(
      const ProviderAuthStartParamsDto(
        definitionId: 'openai',
        methodId: 'chatgpt-device',
        makeDefault: false,
      ),
      (value) => value.toJson(),
      ProviderAuthStartParamsDto.fromJson,
    );
    _roundTrip(
      const ProviderAuthAttemptParamsDto(attemptId: 'attempt'),
      (value) => value.toJson(),
      ProviderAuthAttemptParamsDto.fromJson,
    );
    _roundTrip(
      const ProviderDefaultSetParamsDto(connectionId: 'provider'),
      (value) => value.toJson(),
      ProviderDefaultSetParamsDto.fromJson,
    );
    _roundTrip(
      const ProviderDefaultModelSetParamsDto(
        connectionId: 'provider',
        modelId: 'model',
      ),
      (value) => value.toJson(),
      ProviderDefaultModelSetParamsDto.fromJson,
    );
    _roundTrip(
      const ProviderCustomCreateParamsDto(
        id: 'custom-id',
        config: customConfig,
        apiKey: 'secret',
        makeDefault: false,
      ),
      (value) => value.toJson(),
      ProviderCustomCreateParamsDto.fromJson,
    );
    _roundTrip(
      const ProviderCustomUpdateParamsDto(
        connectionId: 'custom-id',
        config: customConfig,
        apiKey: 'replacement-secret',
      ),
      (value) => value.toJson(),
      ProviderCustomUpdateParamsDto.fromJson,
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
      ProviderConnectionsResultDto(
        connections: <ProviderConnectionDto>[connection],
      ),
      (value) => value.toJson(),
      ProviderConnectionsResultDto.fromJson,
    );
    _roundTrip(
      ProviderConnectionResultDto(connection: connection),
      (value) => value.toJson(),
      ProviderConnectionResultDto.fromJson,
    );
    _roundTrip(
      ProviderModelsResultDto(models: <ProviderModelDto>[model]),
      (value) => value.toJson(),
      ProviderModelsResultDto.fromJson,
    );
    _roundTrip(
      ProviderAuthAttemptResultDto(attempt: authAttempt),
      (value) => value.toJson(),
      ProviderAuthAttemptResultDto.fromJson,
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

  test('protocol exceptions expose a stable diagnostic message', () {
    expect(
      const ProtocolException('bad envelope').toString(),
      'ProtocolException: bad envelope',
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
      ...ProviderApiFormat.values,
      ...ProviderAuthKind.values,
      ...ProviderAuthFlow.values,
      ...ProviderCredentialOrigin.values,
      ...ProviderConnectionStatus.values,
      ...ProviderAuthAttemptStatus.values,
      ...ProviderCatalogSource.values,
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
