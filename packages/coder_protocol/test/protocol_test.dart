import 'dart:convert';

import 'package:coder_protocol/coder_protocol.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime.utc(2026, 8, 2);

  test('protocol v18 exposes terminals and existing typed contracts', () {
    expect(coderProtocolVersion, 19);
    expect(RpcMethod.workspaceCatalog, 'workspace.catalog');
    expect(RpcMethod.workspaceRefresh, 'workspace.refresh');
    expect(RpcMethod.workspaceUnregister, 'workspace.unregister');
    expect(RpcMethod.directorySuggest, 'directory.suggest');
    expect(RpcMethod.gitBranchesList, 'git.branches.list');
    expect(RpcMethod.worktreeCreate, 'worktree.create');
    expect(RpcMethod.worktreeArchivePreview, 'worktree.archive.preview');
    expect(RpcMethod.worktreeArchive, 'worktree.archive');
    expect(RpcMethod.projectSettingsGet, 'project.settings.get');
    expect(RpcMethod.projectSettingsSave, 'project.settings.save');
    expect(RpcMethod.agentDefinitionList, 'agentDefinition.list');
    expect(RpcMethod.agentDefinitionUpdate, 'agentDefinition.update');
    expect(RpcMethod.agentToolCatalog, 'agentTool.catalog');
    expect(RpcMethod.skillList, 'skill.list');
    expect(RpcMethod.skillGet, 'skill.get');
    expect(RpcMethod.skillCreate, 'skill.create');
    expect(RpcMethod.skillUpdate, 'skill.update');
    expect(RpcMethod.skillDelete, 'skill.delete');
    expect(RpcMethod.skillSetEnabled, 'skill.setEnabled');
    expect(RpcNotification.skillsChanged, 'skills.changed');
    expect(RpcMethod.fileSearch, 'file.search');
    expect(RpcMethod.commandList, 'command.list');
    expect(RpcNotification.commandsChanged, 'commands.changed');
    expect(RpcMethod.sessionList, 'session.list');
    expect(RpcMethod.sessionCreate, 'session.create');
    expect(RpcMethod.sessionModelSet, 'session.model.set');
    expect(RpcMethod.sessionModeSet, 'session.mode.set');
    expect(
      RpcMethod.sessionReasoningEffortSet,
      'session.reasoningEffort.set',
    );
    expect(RpcMethod.sessionPermissionModeSet, 'session.permissionMode.set');
    expect(RpcMethod.sessionServiceTierSet, 'session.serviceTier.set');
  });

  test('session collaboration modes round-trip', () {
    final planning = SessionDto(
      id: 'session',
      worktreeId: 'worktree',
      title: 'Plan the migration',
      agentDefinitionId: 'coder',
      origin: SessionOrigin.manual,
      status: SessionStatus.idle,
      createdAt: now,
      updatedAt: now,
      mode: SessionMode.plan,
    );

    expect(
      SessionDto(
        id: 'session',
        worktreeId: 'worktree',
        title: 'Default',
        agentDefinitionId: 'coder',
        origin: SessionOrigin.manual,
        status: SessionStatus.idle,
        createdAt: now,
        updatedAt: now,
      ).mode,
      SessionMode.normal,
    );
    _roundTrip(planning, (value) => value.toJson(), SessionDto.fromJson);
    _roundTrip(
      const SessionCreateParamsDto(
        id: 'session',
        worktreeId: 'worktree',
        title: 'Plan the migration',
        agentDefinitionId: 'coder',
        mode: SessionMode.plan,
      ),
      (value) => value.toJson(),
      SessionCreateParamsDto.fromJson,
    );
    _roundTrip(
      const SessionModeSetParamsDto(
        sessionId: 'session',
        mode: SessionMode.normal,
      ),
      (value) => value.toJson(),
      SessionModeSetParamsDto.fromJson,
    );
    expect(
      SessionDto.fromJson(
        json.decode(json.encode(planning.toJson())) as Map<String, dynamic>,
      ).mode,
      SessionMode.plan,
    );
  });

  test('session model overrides round-trip', () {
    const selection = SessionModelSelectionDto(
      providerConnectionId: 'provider',
      modelId: 'model',
    );
    final overridden = SessionDto(
      id: 'session',
      worktreeId: 'worktree',
      title: 'Run the tests',
      agentDefinitionId: 'coder',
      origin: SessionOrigin.manual,
      status: SessionStatus.idle,
      createdAt: now,
      updatedAt: now,
      model: selection,
    );

    _roundTrip(
      selection,
      (value) => value.toJson(),
      SessionModelSelectionDto.fromJson,
    );
    _roundTrip(overridden, (value) => value.toJson(), SessionDto.fromJson);
    _roundTrip(
      const SessionCreateParamsDto(
        id: 'session',
        worktreeId: 'worktree',
        title: 'Run the tests',
        agentDefinitionId: 'coder',
        model: selection,
      ),
      (value) => value.toJson(),
      SessionCreateParamsDto.fromJson,
    );
    _roundTrip(
      const SessionModelSetParamsDto(sessionId: 'session', model: selection),
      (value) => value.toJson(),
      SessionModelSetParamsDto.fromJson,
    );
    _roundTrip(
      const SessionModelSetParamsDto(sessionId: 'session'),
      (value) => value.toJson(),
      SessionModelSetParamsDto.fromJson,
    );
    expect(
      SessionDto.fromJson(
        json.decode(json.encode(overridden.toJson())) as Map<String, dynamic>,
      ).model,
      selection,
    );
    expect(
      const SessionModelSetParamsDto(sessionId: 'session').model,
      isNull,
    );
  });

  test('agent definition and session contracts round-trip', () {
    const definition = AgentDefinitionDto(
      id: 'reviewer',
      name: 'Reviewer',
      description: 'Reviews code without editing it.',
      mode: AgentMode.subagent,
      promptEnabled: true,
      systemPrompt: 'Review the requested code.',
      model: AgentModelSelectionDto(source: AgentModelSource.session),
      reasoningEffort: 'medium',
      permissionMode: PermissionMode.readOnly,
      toolIds: <String>['read_file', 'search_text'],
      callableAgentIds: <String>[],
      contentHash: 'hash',
      sourcePath: '/config/agents/reviewer.md',
    );
    final session = SessionDto(
      id: 'session',
      worktreeId: 'worktree',
      title: 'Review',
      agentDefinitionId: definition.id,
      origin: SessionOrigin.manual,
      status: SessionStatus.idle,
      createdAt: now,
      updatedAt: now,
    );

    _roundTrip(
      definition,
      (value) => value.toJson(),
      AgentDefinitionDto.fromJson,
    );
    _roundTrip(session, (value) => value.toJson(), SessionDto.fromJson);
  });

  test(
    'skill contracts round-trip and default to an enabled read-only skill',
    () {
      const skill = SkillDto(
        id: 'commit',
        name: 'commit',
        description: 'Writes atomic commits.',
        source: SkillSource.config,
        sourcePath: '/config/skills/commit/SKILL.md',
        contentHash: 'hash',
        body: 'Stage related changes together.',
        resources: <SkillResourceDto>[
          SkillResourceDto(path: 'scripts/split.sh', sizeBytes: 42),
        ],
        isEditable: true,
      );

      expect(skill.isEnabled, isTrue);
      expect(skill.isMandatory, isFalse);
      expect(skill.isShadowed, isFalse);
      expect(skill.isStale, isFalse);
      expect(skill.diagnostics, isEmpty);

      _roundTrip(skill, (value) => value.toJson(), SkillDto.fromJson);
      _roundTrip(
        const SkillDiagnosticDto(
          code: 'shadowed_builtin',
          message: 'A mandatory built-in skill owns this id.',
        ),
        (value) => value.toJson(),
        SkillDiagnosticDto.fromJson,
      );
      _roundTrip(
        const SkillScopeParamsDto(workspaceId: 'workspace'),
        (value) => value.toJson(),
        SkillScopeParamsDto.fromJson,
      );
      _roundTrip(
        const SkillIdParamsDto(id: 'commit', workspaceId: 'workspace'),
        (value) => value.toJson(),
        SkillIdParamsDto.fromJson,
      );
      _roundTrip(
        const SkillCreateParamsDto(
          id: 'commit',
          source: SkillSource.project,
          name: 'commit',
          description: 'Writes atomic commits.',
          body: 'Stage related changes together.',
          workspaceId: 'workspace',
        ),
        (value) => value.toJson(),
        SkillCreateParamsDto.fromJson,
      );
      _roundTrip(
        const SkillUpdateParamsDto(
          skill: skill,
          expectedContentHash: 'hash',
          workspaceId: 'workspace',
          force: true,
        ),
        (value) => value.toJson(),
        SkillUpdateParamsDto.fromJson,
      );
      _roundTrip(
        const SkillSetEnabledParamsDto(id: 'commit', enabled: false),
        (value) => value.toJson(),
        SkillSetEnabledParamsDto.fromJson,
      );
      _roundTrip(
        const SkillListResultDto(skills: <SkillDto>[skill]),
        (value) => value.toJson(),
        SkillListResultDto.fromJson,
      );
      _roundTrip(
        const SkillResultDto(skill: skill),
        (value) => value.toJson(),
        SkillResultDto.fromJson,
      );

      expect(const SkillScopeParamsDto().workspaceId, isNull);
      expect(
        const SkillUpdateParamsDto(
          skill: skill,
          expectedContentHash: 'hash',
        ).force,
        isFalse,
      );
    },
    tags: const <String>['feature_test__skill_management__contract'],
  );

  test('workspace and worktree contracts round-trip', () {
    final workspace = WorkspaceDto(
      id: 'workspace',
      name: 'Coder',
      rootPath: '/workspace',
      kind: WorkspaceKind.git,
      createdAt: now,
    );
    final worktree = WorktreeDto(
      id: 'worktree',
      workspaceId: workspace.id,
      name: 'feature/settings',
      path: '/daemon/worktrees/feature-settings',
      kind: WorktreeKind.managed,
      branch: 'feature/settings',
      head: 'abc123',
      isCoderOwned: true,
      createdAt: now,
    );
    final catalog = WorkspaceCatalogDto(
      workspaces: <WorkspaceDto>[workspace],
      worktrees: <WorktreeDto>[worktree],
    );

    _roundTrip(workspace, (value) => value.toJson(), WorkspaceDto.fromJson);
    _roundTrip(worktree, (value) => value.toJson(), WorktreeDto.fromJson);
    _roundTrip(
      catalog,
      (value) => value.toJson(),
      WorkspaceCatalogDto.fromJson,
    );
    _roundTrip(
      const WorktreeArchivePreviewDto(
        worktreeId: 'worktree',
        dirty: true,
        unpushedCommitCount: 2,
        runningSessionCount: 0,
        removesDirectory: true,
      ),
      (value) => value.toJson(),
      WorktreeArchivePreviewDto.fromJson,
    );
    _roundTrip(
      const DirectorySuggestionDto(
        path: '/workspace',
        name: 'workspace',
      ),
      (value) => value.toJson(),
      DirectorySuggestionDto.fromJson,
    );
    _roundTrip(
      const GitBranchDto(
        name: 'main',
        current: true,
        checkedOut: true,
      ),
      (value) => value.toJson(),
      GitBranchDto.fromJson,
    );
    _roundTrip(
      const GitBranchDto(
        name: 'origin/main',
        current: false,
        checkedOut: false,
        isRemote: true,
        isDefault: true,
      ),
      (value) => value.toJson(),
      GitBranchDto.fromJson,
    );
    expect(
      const GitBranchDto(
        name: 'main',
        current: true,
        checkedOut: true,
      ).isRemote,
      isFalse,
    );
  });

  test(
    'the home workspace kind round-trips under a stable JSON name',
    () {
      final home = WorkspaceDto(
        id: 'home',
        name: 'Home',
        rootPath: '/home/user',
        kind: WorkspaceKind.home,
        createdAt: now,
      );
      expect(home.toJson()['kind'], 'home');
      _roundTrip(home, (value) => value.toJson(), WorkspaceDto.fromJson);
      // The home checkout is an ordinary directory worktree, so nothing
      // downstream of the session needs a second special case.
      final checkout = WorktreeDto(
        id: 'home-checkout',
        workspaceId: home.id,
        name: 'Home',
        path: home.rootPath,
        kind: WorktreeKind.directory,
        isCoderOwned: false,
        createdAt: now,
      );
      _roundTrip(checkout, (value) => value.toJson(), WorktreeDto.fromJson);
    },
    tags: const <String>['feature_test__session_home__contract'],
  );

  final workspace = WorkspaceDto(
    id: 'workspace',
    name: 'Coder',
    rootPath: '/workspace',
    kind: WorkspaceKind.git,
    createdAt: now,
  );
  final worktree = WorktreeDto(
    id: 'worktree',
    workspaceId: workspace.id,
    name: 'main',
    path: workspace.rootPath,
    kind: WorktreeKind.checkout,
    branch: 'main',
    head: 'abc123',
    isCoderOwned: false,
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
    createdAt: now,
    updatedAt: now,
  );
  test('provider connections expose no implicit default state', () {
    expect(connection.toJson(), isNot(contains('isDefault')));
    expect(connection.toJson(), isNot(contains('defaultModelId')));
  });
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
  final agent = SessionDto(
    id: 'agent',
    worktreeId: worktree.id,
    title: 'Agent',
    agentDefinitionId: 'coder',
    origin: SessionOrigin.manual,
    status: SessionStatus.waitingForApproval,
    createdAt: now,
    updatedAt: now,
    activeTurnId: 'turn',
    lastError: 'none',
  );
  final timeline = TimelineEventDto(
    sessionId: agent.id,
    sequence: 4,
    turnId: 'turn',
    type: 'approval.requested',
    data: const <String, dynamic>{'value': true},
    createdAt: now,
  );
  final approval = ApprovalRequestDto(
    id: 'approval',
    sessionId: agent.id,
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

  test('project settings and worktree hook contracts round-trip', () {
    const settings = ProjectSettingsDto(
      setup: <String>['npm ci', 'npm run build'],
      teardown: <String>['docker compose down'],
    );
    const hookRun = WorktreeHookRunDto(
      phase: WorktreeHookPhase.setup,
      command: 'npm ci',
      exitCode: 1,
      stdout: 'installing',
      stderr: 'boom',
    );

    _roundTrip(
      settings,
      (value) => value.toJson(),
      ProjectSettingsDto.fromJson,
    );
    _roundTrip(hookRun, (value) => value.toJson(), WorktreeHookRunDto.fromJson);
    _roundTrip(
      const ProjectSettingsGetParamsDto(workspaceId: 'workspace'),
      (value) => value.toJson(),
      ProjectSettingsGetParamsDto.fromJson,
    );
    _roundTrip(
      const ProjectSettingsSaveParamsDto(
        workspaceId: 'workspace',
        settings: settings,
      ),
      (value) => value.toJson(),
      ProjectSettingsSaveParamsDto.fromJson,
    );
    _roundTrip(
      const ProjectSettingsResultDto(
        settings: settings,
        sourcePath: '/workspace/coder.json',
      ),
      (value) => value.toJson(),
      ProjectSettingsResultDto.fromJson,
    );
    expect(
      const ProjectSettingsDto(),
      ProjectSettingsDto.fromJson(<String, dynamic>{}),
    );
    expect(
      WorktreeResultDto.fromJson(<String, dynamic>{
        'worktree': WorktreeDto(
          id: 'worktree',
          workspaceId: 'workspace',
          name: 'main',
          path: '/workspace',
          kind: WorktreeKind.checkout,
          isCoderOwned: false,
          createdAt: now,
        ).toJson(),
      }).hookRuns,
      isEmpty,
    );
  });

  test('protocol version and direct JSON-RPC names are stable', () {
    expect(coderProtocolVersion, 19);
    expect(RpcMethod.workspaceCatalog, 'workspace.catalog');
    expect(RpcMethod.sessionCreate, 'session.create');
    expect(RpcMethod.sessionModelSet, 'session.model.set');
    expect(RpcMethod.sessionModeSet, 'session.mode.set');
    expect(
      RpcMethod.sessionReasoningEffortSet,
      'session.reasoningEffort.set',
    );
    expect(RpcMethod.sessionPermissionModeSet, 'session.permissionMode.set');
    expect(RpcMethod.sessionServiceTierSet, 'session.serviceTier.set');
    expect(RpcMethod.providerCatalog, 'provider.catalog');
    expect(RpcMethod.providerAuthStart, 'provider.auth.start');
    expect(RpcMethod.turnStart, 'turn.start');
    expect(RpcNotification.timelineEvent, 'timeline.event');
  });

  test('MCP contracts round-trip and expose their defaults', () {
    const stdio = McpServerConfigDto(
      id: 'github',
      transport: McpTransportKind.stdio,
      command: 'npx',
      args: <String>['-y', 'server-github'],
      env: <String, String>{'TOKEN': r'${secret:github.token}'},
      cwd: '/repo',
    );
    const remote = McpServerConfigDto(
      id: 'linear',
      transport: McpTransportKind.http,
      enabled: false,
      url: 'https://mcp.linear.test/mcp',
      headers: <String, String>{'authorization': r'${env:LINEAR}'},
    );
    // Everything optional defaults to the empty, enabled, unshadowed case.
    const bare = McpServerConfigDto(
      id: 'bare',
      transport: McpTransportKind.stdio,
    );
    expect(bare.enabled, isTrue);
    expect(bare.args, isEmpty);
    expect(bare.env, isEmpty);
    expect(bare.headers, isEmpty);
    expect(bare.command, isNull);
    expect(bare.url, isNull);
    expect(bare.cwd, isNull);

    const summary = McpToolSummaryDto(
      toolId: 'mcp__github__create_issue',
      name: 'create_issue',
      title: 'Create issue',
      description: 'Opens an issue.',
    );
    final state = McpServerStateDto(
      config: stdio,
      status: McpServerStatus.ready,
      scope: McpConfigScope.user,
      sourcePath: '/config/mcp.json',
      protocolVersion: '2025-06-18',
      serverName: 'github',
      serverVersion: '1.0.0',
      tools: const <McpToolSummaryDto>[summary],
      diagnostics: const <String>['started'],
      lastConnectedAt: now,
    );
    const failed = McpServerStateDto(
      config: remote,
      status: McpServerStatus.failed,
      scope: McpConfigScope.project,
      sourcePath: '/repo/.mcp.json',
      shadowed: true,
      error: 'the server did not answer',
      attempt: 3,
    );
    expect(state.shadowed, isFalse);
    expect(state.attempt, 0);
    expect(failed.tools, isEmpty);
    expect(failed.diagnostics, isEmpty);
    expect(failed.nextRetryAt, isNull);

    for (final config in <McpServerConfigDto>[stdio, remote, bare]) {
      _roundTrip(
        config,
        (value) => value.toJson(),
        McpServerConfigDto.fromJson,
      );
    }
    _roundTrip(summary, (value) => value.toJson(), McpToolSummaryDto.fromJson);
    for (final entry in <McpServerStateDto>[state, failed]) {
      _roundTrip(entry, (value) => value.toJson(), McpServerStateDto.fromJson);
    }

    _roundTrip(
      const McpServersParamsDto(worktreeId: 'worktree'),
      (value) => value.toJson(),
      McpServersParamsDto.fromJson,
    );
    _roundTrip(
      McpServersResultDto(servers: <McpServerStateDto>[state, failed]),
      (value) => value.toJson(),
      McpServersResultDto.fromJson,
    );
    _roundTrip(
      const McpServerParamsDto(server: stdio),
      (value) => value.toJson(),
      McpServerParamsDto.fromJson,
    );
    _roundTrip(
      const McpServerIdParamsDto(id: 'github'),
      (value) => value.toJson(),
      McpServerIdParamsDto.fromJson,
    );
    _roundTrip(
      McpServerStateResultDto(state: state),
      (value) => value.toJson(),
      McpServerStateResultDto.fromJson,
    );
    _roundTrip(
      const McpSecretParamsDto(key: 'github.token', value: 'secret'),
      (value) => value.toJson(),
      McpSecretParamsDto.fromJson,
    );
    _roundTrip(
      const AgentToolCatalogParamsDto(worktreeId: 'worktree'),
      (value) => value.toJson(),
      AgentToolCatalogParamsDto.fromJson,
    );
    expect(const AgentToolCatalogParamsDto().worktreeId, isNull);
    expect(const McpServersParamsDto().worktreeId, isNull);
  });

  test('all domain DTOs round-trip with additive fields', () {
    _roundTrip(workspace, (value) => value.toJson(), WorkspaceDto.fromJson);
    _roundTrip(agent, (value) => value.toJson(), SessionDto.fromJson);
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
        features: <String, bool>{},
        homeDirectory: '/home/test',
      ),
      (value) => value.toJson(),
      ServerInfoDto.fromJson,
    );
    // A daemon configured without a home reports none, and the client has to
    // read that back as null rather than inventing a path.
    _roundTrip(
      const ServerInfoDto(
        serverId: 'server',
        version: '1.0.0',
        protocolVersion: coderProtocolVersion,
        features: <String, bool>{},
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
        workspaceId: 'workspace',
        checkoutId: 'checkout',
        rootPath: '/workspace',
        name: 'Workspace',
      ),
      (value) => value.toJson(),
      WorkspaceRegisterParamsDto.fromJson,
    );
    _roundTrip(
      const WorkspaceIdParamsDto(workspaceId: 'workspace'),
      (value) => value.toJson(),
      WorkspaceIdParamsDto.fromJson,
    );
    _roundTrip(
      const DirectorySuggestParamsDto(query: '~/Workspaces', limit: 20),
      (value) => value.toJson(),
      DirectorySuggestParamsDto.fromJson,
    );
    _roundTrip(
      const GitBranchesListParamsDto(workspaceId: 'workspace'),
      (value) => value.toJson(),
      GitBranchesListParamsDto.fromJson,
    );
    _roundTrip(
      const WorktreeCreateParamsDto(
        id: 'worktree',
        workspaceId: 'workspace',
        mode: WorktreeCreateMode.newBranch,
        branchName: 'feature/settings',
        baseBranch: 'main',
      ),
      (value) => value.toJson(),
      WorktreeCreateParamsDto.fromJson,
    );
    _roundTrip(
      const WorktreeIdParamsDto(worktreeId: 'worktree'),
      (value) => value.toJson(),
      WorktreeIdParamsDto.fromJson,
    );
    _roundTrip(
      const WorktreeArchiveParamsDto(worktreeId: 'worktree', force: true),
      (value) => value.toJson(),
      WorktreeArchiveParamsDto.fromJson,
    );
    _roundTrip(
      const SessionListParamsDto(worktreeId: 'worktree'),
      (value) => value.toJson(),
      SessionListParamsDto.fromJson,
    );
    _roundTrip(
      const SessionCreateParamsDto(
        id: 'agent',
        worktreeId: 'worktree',
        title: 'Agent',
        agentDefinitionId: 'coder',
      ),
      (value) => value.toJson(),
      SessionCreateParamsDto.fromJson,
    );
    _roundTrip(
      const AgentDefinitionUpdateParamsDto(
        definition: AgentDefinitionDto(
          id: 'reviewer',
          name: 'Reviewer',
          description: 'Reviews code.',
          mode: AgentMode.subagent,
          promptEnabled: true,
          systemPrompt: 'Review code.',
          model: AgentModelSelectionDto(
            source: AgentModelSource.session,
          ),
          reasoningEffort: 'medium',
          permissionMode: PermissionMode.readOnly,
          toolIds: <String>['read_file'],
          callableAgentIds: <String>[],
          contentHash: 'hash',
          sourcePath: '/config/agents/reviewer.md',
        ),
        expectedContentHash: 'hash',
      ),
      (value) => value.toJson(),
      AgentDefinitionUpdateParamsDto.fromJson,
    );
    _roundTrip(
      const ProviderConnectApiKeyParamsDto(
        definitionId: 'provider',
        apiKey: 'secret',
      ),
      (value) => value.toJson(),
      ProviderConnectApiKeyParamsDto.fromJson,
    );
    _roundTrip(
      const ProviderConnectNoneParamsDto(definitionId: 'ollama'),
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
      const ProviderCustomCreateParamsDto(
        id: 'custom-id',
        config: customConfig,
        apiKey: 'secret',
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
        sessionId: 'agent',
        turnId: 'turn',
        prompt: 'hello',
        attachmentIds: <String>['attachment-1'],
      ),
      (value) => value.toJson(),
      TurnStartParamsDto.fromJson,
    );
    _roundTrip(
      const SessionIdParamsDto(sessionId: 'agent'),
      (value) => value.toJson(),
      SessionIdParamsDto.fromJson,
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
        sessionId: 'agent',
        afterSequence: 12,
      ),
      (value) => value.toJson(),
      TimelineSubscribeParamsDto.fromJson,
    );
  });

  test(
    'attachment contracts round-trip',
    tags: const <String>['feature_test__conversation_attachments__contract'],
    () {
      final attachment = AttachmentDto(
        id: 'attachment-1',
        fileName: 'diagram.png',
        mimeType: 'image/png',
        byteSize: 4,
        kind: AttachmentKind.image,
        sha256: 'hash',
        createdAt: now,
      );
      _roundTrip(
        attachment,
        (value) => value.toJson(),
        AttachmentDto.fromJson,
      );
      expect(
        TurnStartParamsDto.fromJson(<String, dynamic>{
          'sessionId': 'agent',
          'turnId': 'turn',
          'prompt': '',
        }).attachmentIds,
        isEmpty,
      );
    },
  );

  test('all result DTOs round-trip', () {
    _roundTrip(
      WorkspaceCatalogResultDto(
        catalog: WorkspaceCatalogDto(
          workspaces: <WorkspaceDto>[workspace],
          worktrees: <WorktreeDto>[worktree],
        ),
      ),
      (value) => value.toJson(),
      WorkspaceCatalogResultDto.fromJson,
    );
    _roundTrip(
      WorkspaceRegisterResultDto(
        workspace: workspace,
        worktrees: <WorktreeDto>[worktree],
      ),
      (value) => value.toJson(),
      WorkspaceRegisterResultDto.fromJson,
    );
    _roundTrip(
      const WorkspaceUnregisterResultDto(unregistered: true),
      (value) => value.toJson(),
      WorkspaceUnregisterResultDto.fromJson,
    );
    _roundTrip(
      const DirectorySuggestResultDto(
        suggestions: <DirectorySuggestionDto>[
          DirectorySuggestionDto(path: '/workspace', name: 'workspace'),
        ],
      ),
      (value) => value.toJson(),
      DirectorySuggestResultDto.fromJson,
    );
    _roundTrip(
      const GitBranchesListResultDto(
        branches: <GitBranchDto>[
          GitBranchDto(name: 'main', current: true, checkedOut: true),
        ],
      ),
      (value) => value.toJson(),
      GitBranchesListResultDto.fromJson,
    );
    _roundTrip(
      WorktreeResultDto(worktree: worktree),
      (value) => value.toJson(),
      WorktreeResultDto.fromJson,
    );
    _roundTrip(
      const WorktreeArchivePreviewResultDto(
        preview: WorktreeArchivePreviewDto(
          worktreeId: 'worktree',
          dirty: false,
          unpushedCommitCount: 0,
          runningSessionCount: 0,
          removesDirectory: true,
        ),
      ),
      (value) => value.toJson(),
      WorktreeArchivePreviewResultDto.fromJson,
    );
    _roundTrip(
      SessionListResultDto(sessions: <SessionDto>[agent]),
      (value) => value.toJson(),
      SessionListResultDto.fromJson,
    );
    _roundTrip(
      SessionResultDto(session: agent),
      (value) => value.toJson(),
      SessionResultDto.fromJson,
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

  test(
    'user question contracts round-trip and expose a waiting status',
    tags: const <String>['feature_test__turn_question__contract'],
    () {
      final question = UserQuestionRequestDto(
        id: 'question',
        sessionId: agent.id,
        turnId: 'turn',
        toolCallId: 'call',
        questions: const <UserQuestionItemDto>[
          UserQuestionItemDto(
            id: 'q1',
            header: 'Storage',
            question: 'Which store should the cache use?',
            options: <UserQuestionOptionDto>[
              UserQuestionOptionDto(
                label: 'SQLite',
                description: 'Durable and already a dependency.',
              ),
              UserQuestionOptionDto(
                label: 'In memory',
                description: 'Fastest, lost on restart.',
              ),
            ],
          ),
        ],
        status: UserQuestionStatus.pending,
        createdAt: now,
      );
      _roundTrip(
        question,
        (value) => value.toJson(),
        UserQuestionRequestDto.fromJson,
      );
      _roundTrip(
        question.copyWith(
          status: UserQuestionStatus.answered,
          answers: const <UserQuestionAnswerDto>[
            UserQuestionAnswerDto(
              questionId: 'q1',
              answer: 'Postgres',
              isFreeForm: true,
            ),
          ],
        ),
        (value) => value.toJson(),
        UserQuestionRequestDto.fromJson,
      );
      _roundTrip(
        const UserQuestionAnswerParamsDto(
          requestId: 'question',
          answers: <UserQuestionAnswerDto>[
            UserQuestionAnswerDto(
              questionId: 'q1',
              answer: 'SQLite',
              isFreeForm: false,
            ),
          ],
        ),
        (value) => value.toJson(),
        UserQuestionAnswerParamsDto.fromJson,
      );
      _roundTrip(
        UserQuestionResultDto(request: question),
        (value) => value.toJson(),
        UserQuestionResultDto.fromJson,
      );

      // A blocked turn is a distinct state from one blocked on an approval.
      expect(
        SessionDto.fromJson(
          agent.copyWith(status: SessionStatus.waitingForInput).toJson(),
        ).status,
        SessionStatus.waitingForInput,
      );
      expect(TurnStatus.values, contains(TurnStatus.waitingForInput));
      expect(RpcMethod.userQuestionAnswer, 'userQuestion.answer');
      expect(RpcNotification.userQuestionRequested, 'userQuestion.requested');
    },
  );

  test(
    'the context budget rides the session contract',
    tags: const <String>['feature_test__tool_context_budget__contract'],
    () {
      final session = SessionDto(
        id: 'session',
        worktreeId: 'worktree',
        title: 'Budgeted',
        agentDefinitionId: 'coder',
        origin: SessionOrigin.manual,
        status: SessionStatus.idle,
        createdAt: now,
        updatedAt: now,
        contextTokens: 32000,
        contextWindow: 200000,
      );
      _roundTrip(session, (value) => value.toJson(), SessionDto.fromJson);

      // A provider that never advertised a window leaves the meter hidden
      // rather than reporting a made-up denominator.
      final unknown = SessionDto(
        id: 'session',
        worktreeId: 'worktree',
        title: 'Unknown',
        agentDefinitionId: 'coder',
        origin: SessionOrigin.manual,
        status: SessionStatus.idle,
        createdAt: now,
        updatedAt: now,
      );
      expect(unknown.contextWindow, isNull);
      expect(unknown.contextTokens, 0);
      expect(
        SessionDto.fromJson(
          json.decode(json.encode(unknown.toJson())) as Map<String, dynamic>,
        ).contextWindow,
        isNull,
      );
    },
  );

  test(
    'MCP resource contracts round-trip and default to empty lists',
    tags: const <String>['feature_test__mcp_resource_access__contract'],
    () {
      _roundTrip(
        const McpResourceSummaryDto(
          uri: 'file:///repo/README.md',
          name: 'README',
          title: 'Project readme',
          description: 'How to build.',
          mimeType: 'text/markdown',
          sizeBytes: 4096,
        ),
        (value) => value.toJson(),
        McpResourceSummaryDto.fromJson,
      );
      _roundTrip(
        const McpResourceSummaryDto(uri: 'db://schema'),
        (value) => value.toJson(),
        McpResourceSummaryDto.fromJson,
      );
      _roundTrip(
        const McpResourceTemplateSummaryDto(
          uriTemplate: 'file:///repo/{path}',
          name: 'Repository file',
        ),
        (value) => value.toJson(),
        McpResourceTemplateSummaryDto.fromJson,
      );

      // A daemon that has not learned about resources yet reports none, so an
      // older stored state decodes without them.
      const bare = McpServerStateDto(
        config: McpServerConfigDto(
          id: 'github',
          transport: McpTransportKind.stdio,
          command: 'npx',
        ),
        status: McpServerStatus.ready,
        scope: McpConfigScope.user,
        sourcePath: '/config/mcp.json',
      );
      expect(bare.resources, isEmpty);
      expect(bare.resourceTemplates, isEmpty);
      _roundTrip(
        bare.copyWith(
          resources: const <McpResourceSummaryDto>[
            McpResourceSummaryDto(uri: 'file:///a.txt'),
          ],
          resourceTemplates: const <McpResourceTemplateSummaryDto>[
            McpResourceTemplateSummaryDto(uriTemplate: 'file:///{p}'),
          ],
        ),
        (value) => value.toJson(),
        McpServerStateDto.fromJson,
      );
    },
  );

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
      ...SessionStatus.values,
      ...SessionMode.values,
      ...TurnStatus.values,
      ...PermissionMode.values,
      ...ApprovalStatus.values,
      ...UserQuestionStatus.values,
      ...ToolRisk.values,
      ...McpConfigScope.values,
      ...McpTransportKind.values,
      ...McpServerStatus.values,
      ...SkillSource.values,
      ...AgentCommandSource.values,
      ...WorkspaceKind.values,
      ...WorktreeKind.values,
      ...WorktreeCreateMode.values,
      ...WorktreeHookPhase.values,
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

  test('tool risk covers the MCP-provided dangerous tier', () {
    expect(ToolRisk.values, contains(ToolRisk.dangerous));
    expect(ToolRisk.dangerous.name, 'dangerous');
  });

  test('agent tool definitions carry an always-on flag', () {
    const toggleable = AgentToolDefinitionDto(
      id: 'run_command',
      name: 'run_command',
      description: 'Starts a child process.',
      risk: ToolRisk.command,
    );
    expect(toggleable.alwaysOn, isFalse);
    _roundTrip(
      const AgentToolDefinitionDto(
        id: 'read_file',
        name: 'read_file',
        description: 'Reads a workspace file.',
        risk: ToolRisk.read,
        alwaysOn: true,
      ),
      (value) => value.toJson(),
      AgentToolDefinitionDto.fromJson,
    );
    _roundTrip(
      const AgentToolDefinitionDto(
        id: 'mcp__github__create_issue',
        name: 'mcp__github__create_issue',
        description: 'Creates a GitHub issue.',
        risk: ToolRisk.dangerous,
        available: false,
      ),
      (value) => value.toJson(),
      AgentToolDefinitionDto.fromJson,
    );
  });

  test(
    'terminal lifecycle payloads preserve shell, size, and replay sequence',
    () {
      const shell = ShellSpecDto(
        executable: '/bin/zsh',
        arguments: <String>['-l'],
      );
      const terminal = TerminalDto(
        id: 'terminal-1',
        worktreeId: 'worktree-1',
        title: 'Terminal 1',
        shell: shell,
        status: TerminalStatus.running,
        columns: 120,
        rows: 40,
        lastSequence: 7,
      );
      _roundTrip(shell, (value) => value.toJson(), ShellSpecDto.fromJson);
      _roundTrip(
        const TerminalOutputDto(
          terminalId: 'terminal-1',
          sequence: 7,
          data: 'ready',
        ),
        (value) => value.toJson(),
        TerminalOutputDto.fromJson,
      );
      _roundTrip(
        const TerminalListParamsDto(worktreeId: 'worktree-1'),
        (value) => value.toJson(),
        TerminalListParamsDto.fromJson,
      );
      _roundTrip(
        const TerminalListResultDto(terminals: <TerminalDto>[terminal]),
        (value) => value.toJson(),
        TerminalListResultDto.fromJson,
      );
      _roundTrip(
        const TerminalCreateParamsDto(
          id: 'terminal-1',
          worktreeId: 'worktree-1',
          title: 'Terminal 1',
          columns: 120,
          rows: 40,
        ),
        (value) => value.toJson(),
        TerminalCreateParamsDto.fromJson,
      );
      _roundTrip(
        const TerminalIdParamsDto(terminalId: 'terminal-1'),
        (value) => value.toJson(),
        TerminalIdParamsDto.fromJson,
      );
      _roundTrip(
        const TerminalAttachParamsDto(
          terminalId: 'terminal-1',
          afterSequence: 3,
        ),
        (value) => value.toJson(),
        TerminalAttachParamsDto.fromJson,
      );
      _roundTrip(
        const TerminalResultDto(terminal: terminal),
        (value) => value.toJson(),
        TerminalResultDto.fromJson,
      );
      _roundTrip(
        const TerminalWriteParamsDto(
          terminalId: 'terminal-1',
          data: 'echo ready\r',
        ),
        (value) => value.toJson(),
        TerminalWriteParamsDto.fromJson,
      );
      _roundTrip(
        const TerminalResizeParamsDto(
          terminalId: 'terminal-1',
          columns: 100,
          rows: 30,
        ),
        (value) => value.toJson(),
        TerminalResizeParamsDto.fromJson,
      );
      _roundTrip(
        const TerminalShellDto(shell: shell),
        (value) => value.toJson(),
        TerminalShellDto.fromJson,
      );
      _roundTrip(
        const TerminalShellDto(),
        (value) => value.toJson(),
        TerminalShellDto.fromJson,
      );
      _roundTrip(terminal, (value) => value.toJson(), TerminalDto.fromJson);
      _roundTrip(
        const TerminalAttachResultDto(
          terminal: terminal,
          replay: <TerminalOutputDto>[
            TerminalOutputDto(
              terminalId: 'terminal-1',
              sequence: 7,
              data: 'ready',
            ),
          ],
        ),
        (value) => value.toJson(),
        TerminalAttachResultDto.fromJson,
      );
    },
    tags: const <String>[
      'feature_test__terminal_lifecycle__contract',
      'feature_test__terminal_settings__contract',
    ],
  );

  test(
    'default model contracts round-trip and name stable RPC methods',
    () {
      _roundTrip(
        const DefaultModelDto(
          model: SessionModelSelectionDto(
            providerConnectionId: 'connection-1',
            modelId: 'model-1',
          ),
        ),
        (value) => value.toJson(),
        DefaultModelDto.fromJson,
      );
      _roundTrip(
        const DefaultModelDto(),
        (value) => value.toJson(),
        DefaultModelDto.fromJson,
      );

      expect(
        RpcMethod.providerDefaultModelGet,
        'provider.defaultModel.get',
      );
      expect(
        RpcMethod.providerDefaultModelSet,
        'provider.defaultModel.set',
      );
    },
    tags: const <String>['feature_test__provider_default_model__contract'],
  );

  test(
    'composer file mention contracts round-trip and default to a capped search',
    () {
      const match = FileMatchDto(
        relativePath: 'lib/src/app.dart',
        absolutePath: '/worktree/lib/src/app.dart',
        name: 'app.dart',
        isDirectory: false,
        score: 720,
      );

      expect(
        const FileSearchParamsDto(worktreeId: 'w', query: 'app').limit,
        50,
      );
      expect(
        const FileSearchResultDto(matches: <FileMatchDto>[]).truncated,
        isFalse,
      );
      expect(
        const FileMatchDto(
          relativePath: 'lib',
          absolutePath: '/worktree/lib',
          name: 'lib',
          isDirectory: true,
        ).score,
        0,
      );

      _roundTrip(match, (value) => value.toJson(), FileMatchDto.fromJson);
      _roundTrip(
        const FileSearchParamsDto(
          worktreeId: 'worktree',
          query: 'app',
          limit: 20,
        ),
        (value) => value.toJson(),
        FileSearchParamsDto.fromJson,
      );
      _roundTrip(
        const FileSearchResultDto(
          matches: <FileMatchDto>[match],
          truncated: true,
        ),
        (value) => value.toJson(),
        FileSearchResultDto.fromJson,
      );

      expect(
        () => FileSearchParamsDto.fromJson(<String, dynamic>{'query': 'app'}),
        throwsA(isA<TypeError>()),
      );
    },
    tags: const <String>['feature_test__composer_file_mention__contract'],
  );

  test(
    'composer slash command contracts round-trip across every command source',
    () {
      const command = AgentCommandDto(
        id: 'review',
        name: 'review',
        description: 'Reviews the working diff.',
        source: AgentCommandSource.project,
        sourcePath: '/worktree/.agents/commands/review.md',
        body: r'Review $ARGUMENTS and report defects.',
        argumentHint: '<path>',
      );

      expect(command.argumentHint, '<path>');
      expect(const CommandListParamsDto().workspaceId, isNull);
      expect(AgentCommandSource.values, <AgentCommandSource>[
        AgentCommandSource.userHome,
        AgentCommandSource.config,
        AgentCommandSource.project,
      ]);

      for (final source in AgentCommandSource.values) {
        _roundTrip(
          AgentCommandDto(
            id: 'review',
            name: 'review',
            description: 'Reviews the working diff.',
            source: source,
            sourcePath: '/commands/review.md',
            body: 'Review the diff.',
          ),
          (value) => value.toJson(),
          AgentCommandDto.fromJson,
        );
      }

      _roundTrip(
        const CommandListParamsDto(workspaceId: 'workspace'),
        (value) => value.toJson(),
        CommandListParamsDto.fromJson,
      );
      _roundTrip(
        const CommandListResultDto(commands: <AgentCommandDto>[command]),
        (value) => value.toJson(),
        CommandListResultDto.fromJson,
      );

      expect(
        () => AgentCommandDto.fromJson(<String, dynamic>{'id': 'review'}),
        throwsA(isA<TypeError>()),
      );
    },
    tags: const <String>['feature_test__composer_slash_command__contract'],
  );
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
