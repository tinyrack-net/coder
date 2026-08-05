import 'dart:async';
import 'dart:convert';

import 'package:coder_client/src/api.dart';
import 'package:coder_client/src/endpoint.dart';
import 'package:coder_client/src/web_socket_connector.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:http/http.dart' as http;
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;

/// CoderClientException defines a public contract.
class CoderClientException implements Exception {
  /// Creates a [CoderClientException].
  const CoderClientException(this.message, {this.code, this.retryable = false});

  /// The message public API member.
  final String message;

  /// The code public API member.
  final String? code;

  /// The retryable public API member.
  final bool retryable;

  @override
  String toString() =>
      'CoderClientException${code == null ? '' : '($code)'}: $message';
}

/// CoderClient defines a public contract.
class CoderClient implements CoderApi {
  CoderClient._({
    required this._endpoint,
    required this._credentials,
    required this._clientId,
    required this._clientKind,
    required this._connector,
    required this._requestTimeout,
    required this._reconnectDelay,
  });

  /// The connect public API member.
  static Future<CoderClient> connect({
    required HostEndpoint endpoint,
    required DaemonCredentials credentials,
    required String clientId,
    required String clientKind,
    WebSocketConnector? connector,
    Duration requestTimeout = const Duration(seconds: 60),
    Duration Function(int attempt)? reconnectDelay,
  }) async {
    final client = CoderClient._(
      endpoint: endpoint,
      credentials: credentials,
      clientId: clientId,
      clientKind: clientKind,
      connector: connector ?? createWebSocketConnector(),
      requestTimeout: requestTimeout,
      reconnectDelay:
          reconnectDelay ??
          (attempt) => Duration(seconds: 1 << (attempt - 1).clamp(0, 5)),
    );
    await client._open(initial: true);
    return client;
  }

  final HostEndpoint _endpoint;
  final DaemonCredentials _credentials;
  final String _clientId;
  final String _clientKind;
  final WebSocketConnector _connector;
  final Duration _requestTimeout;
  final Duration Function(int attempt) _reconnectDelay;
  final StreamController<ClientEvent> _events =
      StreamController<ClientEvent>.broadcast();
  final StreamController<ClientConnectionState> _states =
      StreamController<ClientConnectionState>.broadcast();
  final Map<String, int> _timelineSubscriptions = <String, int>{};
  final Map<String, int> _terminalSubscriptions = <String, int>{};
  json_rpc.Peer? _peer;
  ServerInfoDto? _serverInfo;
  bool _closed = false;
  bool _connecting = false;
  int _reconnectAttempt = 0;

  @override
  Stream<ClientEvent> get events => _events.stream;
  @override
  Stream<ClientConnectionState> get states => _states.stream;
  @override
  ServerInfoDto get serverInfo =>
      _serverInfo ??
      (throw StateError('The client has not completed its handshake.'));

  Future<void> _open({required bool initial}) async {
    if (_closed || _connecting) return;
    _connecting = true;
    _states.add(
      initial
          ? ClientConnectionState.connecting
          : ClientConnectionState.reconnecting,
    );
    try {
      final channel = await _connector.connect(
        _endpoint.websocketUri,
        headers: <String, String>{
          'Authorization': 'Bearer ${_credentials.bearerToken}',
        },
      );
      final peer = json_rpc.Peer(channel.cast<String>());
      _peer = peer;
      for (final type in <String>[
        RpcNotification.timelineEvent,
        RpcNotification.sessionUpdated,
        RpcNotification.agentDefinitionsChanged,
        RpcNotification.skillsChanged,
        RpcNotification.approvalRequested,
        RpcNotification.providerAuthUpdated,
        RpcNotification.mcpServersChanged,
        RpcNotification.terminalOutput,
        RpcNotification.terminalUpdated,
      ]) {
        peer.registerMethod(type, (json_rpc.Parameters parameters) {
          _handleNotification(
            type,
            Map<String, dynamic>.from(parameters.asMap),
          );
        });
      }
      unawaited(peer.listen().whenComplete(_handleSocketDone));
      final hello = await peer.sendRequest(
        RpcMethod.hello,
        HelloParamsDto(
          clientId: _clientId,
          clientKind: _clientKind,
          protocolVersion: coderProtocolVersion,
          capabilities: const <String, bool>{'timelineCatchup': true},
        ).toJson(),
      );
      _serverInfo = ServerInfoDto.fromJson(
        Map<String, dynamic>.from(hello as Map),
      );
      _reconnectAttempt = 0;
      _states.add(ClientConnectionState.connected);
      for (final entry in Map<String, int>.from(
        _timelineSubscriptions,
      ).entries) {
        unawaited(
          subscribeTimeline(entry.key, afterSequence: entry.value).then((
            events,
          ) {
            for (final event in events) {
              _events.add(TimelineClientEvent(event));
            }
          }),
        );
      }
      for (final entry in Map<String, int>.from(
        _terminalSubscriptions,
      ).entries) {
        unawaited(
          attachTerminal(entry.key, afterSequence: entry.value).then((result) {
            _events.add(TerminalUpdatedClientEvent(result.terminal));
            for (final output in result.replay) {
              _events.add(TerminalOutputClientEvent(output));
            }
          }),
        );
      }
    } catch (error) {
      await _peer?.close();
      if (initial) rethrow;
      _scheduleReconnect();
    } finally {
      _connecting = false;
    }
  }

  void _handleNotification(String type, Map<String, dynamic> parameters) {
    try {
      switch (type) {
        case RpcNotification.timelineEvent:
          final event = TimelineEventDto.fromJson(parameters);
          final current = _timelineSubscriptions[event.sessionId] ?? 0;
          if (event.sequence <= current) return;
          _timelineSubscriptions[event.sessionId] = event.sequence;
          _events.add(TimelineClientEvent(event));
        case RpcNotification.sessionUpdated:
          _events.add(
            SessionUpdatedClientEvent(SessionDto.fromJson(parameters)),
          );
        case RpcNotification.agentDefinitionsChanged:
          _events.add(const AgentDefinitionsChangedClientEvent());
        case RpcNotification.mcpServersChanged:
          _events.add(const McpServersChangedClientEvent());
        case RpcNotification.skillsChanged:
          _events.add(const SkillsChangedClientEvent());
        case RpcNotification.approvalRequested:
          _events.add(
            ApprovalRequestedClientEvent(
              ApprovalRequestDto.fromJson(parameters),
            ),
          );
        case RpcNotification.providerAuthUpdated:
          _events.add(
            ProviderAuthUpdatedClientEvent(
              ProviderAuthAttemptDto.fromJson(parameters),
            ),
          );
        case RpcNotification.terminalOutput:
          final output = TerminalOutputDto.fromJson(parameters);
          final current = _terminalSubscriptions[output.terminalId];
          if (current == null || output.sequence <= current) return;
          _terminalSubscriptions[output.terminalId] = output.sequence;
          _events.add(TerminalOutputClientEvent(output));
        case RpcNotification.terminalUpdated:
          _events.add(
            TerminalUpdatedClientEvent(TerminalDto.fromJson(parameters)),
          );
      }
    } on FormatException catch (error, stackTrace) {
      _events.addError(error, stackTrace);
    }
  }

  void _handleSocketDone() {
    if (_closed) return;
    _states.add(ClientConnectionState.disconnected);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_closed || _connecting) return;
    _reconnectAttempt += 1;
    Timer(
      _reconnectDelay(_reconnectAttempt),
      () => unawaited(_open(initial: false)),
    );
  }

  Future<Map<String, dynamic>> _request(
    String method,
    Map<String, dynamic> payload,
  ) async {
    try {
      final result =
          await (_peer ??
                  (throw const CoderClientException(
                    'Not connected.',
                    retryable: true,
                  )))
              .sendRequest(method, payload)
              .timeout(_requestTimeout);
      return Map<String, dynamic>.from(result as Map);
    } on json_rpc.RpcException catch (error) {
      final data = error.data is Map
          ? error.data! as Map
          : const <dynamic, dynamic>{};
      throw CoderClientException(
        error.message,
        code: data['code'] as String?,
        retryable: data['retryable'] == true,
      );
      // json_rpc_2 reports a closed peer as a StateError and offers no typed
      // alternative; converting it keeps shutdown races off the error zone.
      // ignore: avoid_catching_errors
    } on StateError catch (error) {
      throw CoderClientException(error.message, retryable: true);
    }
  }

  @override
  Future<WorkspaceCatalogDto> getWorkspaceCatalog() async {
    final response = await _request(
      RpcMethod.workspaceCatalog,
      const <String, dynamic>{},
    );
    return WorkspaceCatalogResultDto.fromJson(response).catalog;
  }

  @override
  Future<WorkspaceRegisterResultDto> registerWorkspace({
    required String workspaceId,
    required String checkoutId,
    required String rootPath,
    required String name,
  }) async {
    final response = await _request(
      RpcMethod.workspaceRegister,
      WorkspaceRegisterParamsDto(
        workspaceId: workspaceId,
        checkoutId: checkoutId,
        rootPath: rootPath,
        name: name,
      ).toJson(),
    );
    return WorkspaceRegisterResultDto.fromJson(response);
  }

  @override
  Future<WorkspaceCatalogDto> refreshWorkspace(String workspaceId) async {
    final response = await _request(
      RpcMethod.workspaceRefresh,
      WorkspaceIdParamsDto(workspaceId: workspaceId).toJson(),
    );
    return WorkspaceCatalogResultDto.fromJson(response).catalog;
  }

  @override
  Future<void> unregisterWorkspace(String workspaceId) async {
    await _request(
      RpcMethod.workspaceUnregister,
      WorkspaceIdParamsDto(workspaceId: workspaceId).toJson(),
    );
  }

  @override
  Future<List<DirectorySuggestionDto>> suggestDirectories(
    String query, {
    int limit = 30,
  }) async {
    final response = await _request(
      RpcMethod.directorySuggest,
      DirectorySuggestParamsDto(query: query, limit: limit).toJson(),
    );
    return DirectorySuggestResultDto.fromJson(response).suggestions;
  }

  @override
  Future<List<GitBranchDto>> listGitBranches(String workspaceId) async {
    final response = await _request(
      RpcMethod.gitBranchesList,
      GitBranchesListParamsDto(workspaceId: workspaceId).toJson(),
    );
    return GitBranchesListResultDto.fromJson(response).branches;
  }

  @override
  Future<ProjectSettingsResultDto> getProjectSettings(
    String workspaceId,
  ) async {
    final response = await _request(
      RpcMethod.projectSettingsGet,
      ProjectSettingsGetParamsDto(workspaceId: workspaceId).toJson(),
    );
    return ProjectSettingsResultDto.fromJson(response);
  }

  @override
  Future<ProjectSettingsResultDto> saveProjectSettings(
    String workspaceId,
    ProjectSettingsDto settings,
  ) async {
    final response = await _request(
      RpcMethod.projectSettingsSave,
      ProjectSettingsSaveParamsDto(
        workspaceId: workspaceId,
        settings: settings,
      ).toJson(),
    );
    return ProjectSettingsResultDto.fromJson(response);
  }

  @override
  Future<WorktreeResultDto> createWorktree({
    required String id,
    required String workspaceId,
    required WorktreeCreateMode mode,
    required String branchName,
    String? baseBranch,
  }) async {
    final response = await _request(
      RpcMethod.worktreeCreate,
      WorktreeCreateParamsDto(
        id: id,
        workspaceId: workspaceId,
        mode: mode,
        branchName: branchName,
        baseBranch: baseBranch,
      ).toJson(),
    );
    return WorktreeResultDto.fromJson(response);
  }

  @override
  Future<WorktreeArchivePreviewDto> previewWorktreeArchive(
    String worktreeId,
  ) async {
    final response = await _request(
      RpcMethod.worktreeArchivePreview,
      WorktreeIdParamsDto(worktreeId: worktreeId).toJson(),
    );
    return WorktreeArchivePreviewResultDto.fromJson(response).preview;
  }

  @override
  Future<WorktreeResultDto> archiveWorktree(
    String worktreeId, {
    bool force = false,
  }) async {
    final response = await _request(
      RpcMethod.worktreeArchive,
      WorktreeArchiveParamsDto(worktreeId: worktreeId, force: force).toJson(),
    );
    return WorktreeResultDto.fromJson(response);
  }

  @override
  Future<List<SessionDto>> listSessions({String? worktreeId}) async {
    final response = await _request(
      RpcMethod.sessionList,
      SessionListParamsDto(worktreeId: worktreeId).toJson(),
    );
    return SessionListResultDto.fromJson(response).sessions;
  }

  @override
  Future<SessionDto> createSession({
    required String id,
    required String worktreeId,
    required String title,
    required String agentDefinitionId,
    SessionMode mode = SessionMode.normal,
    SessionModelSelectionDto? model,
    String? reasoningEffort,
    PermissionMode? permissionMode,
    String? serviceTier,
  }) async {
    final response = await _request(
      RpcMethod.sessionCreate,
      SessionCreateParamsDto(
        id: id,
        worktreeId: worktreeId,
        title: title,
        agentDefinitionId: agentDefinitionId,
        mode: mode,
        model: model,
        reasoningEffort: reasoningEffort,
        permissionMode: permissionMode,
        serviceTier: serviceTier,
      ).toJson(),
    );
    return SessionResultDto.fromJson(response).session;
  }

  @override
  Future<SessionDto> updateSessionMode(
    String sessionId,
    SessionMode mode,
  ) async {
    final response = await _request(
      RpcMethod.sessionModeSet,
      SessionModeSetParamsDto(sessionId: sessionId, mode: mode).toJson(),
    );
    return SessionResultDto.fromJson(response).session;
  }

  @override
  Future<SessionDto> updateSessionModel(
    String sessionId,
    SessionModelSelectionDto? model,
  ) async {
    final response = await _request(
      RpcMethod.sessionModelSet,
      SessionModelSetParamsDto(sessionId: sessionId, model: model).toJson(),
    );
    return SessionResultDto.fromJson(response).session;
  }

  @override
  Future<SessionDto> updateSessionReasoningEffort(
    String sessionId,
    String? reasoningEffort,
  ) async {
    final response = await _request(
      RpcMethod.sessionReasoningEffortSet,
      SessionReasoningEffortSetParamsDto(
        sessionId: sessionId,
        reasoningEffort: reasoningEffort,
      ).toJson(),
    );
    return SessionResultDto.fromJson(response).session;
  }

  @override
  Future<SessionDto> updateSessionPermissionMode(
    String sessionId,
    PermissionMode? permissionMode,
  ) async {
    final response = await _request(
      RpcMethod.sessionPermissionModeSet,
      SessionPermissionModeSetParamsDto(
        sessionId: sessionId,
        permissionMode: permissionMode,
      ).toJson(),
    );
    return SessionResultDto.fromJson(response).session;
  }

  @override
  Future<SessionDto> updateSessionServiceTier(
    String sessionId,
    String? serviceTier,
  ) async {
    final response = await _request(
      RpcMethod.sessionServiceTierSet,
      SessionServiceTierSetParamsDto(
        sessionId: sessionId,
        serviceTier: serviceTier,
      ).toJson(),
    );
    return SessionResultDto.fromJson(response).session;
  }

  @override
  Future<List<TerminalDto>> listTerminals(String worktreeId) async {
    final response = await _request(
      RpcMethod.terminalList,
      TerminalListParamsDto(worktreeId: worktreeId).toJson(),
    );
    return TerminalListResultDto.fromJson(response).terminals;
  }

  @override
  Future<TerminalDto> createTerminal({
    required String id,
    required String worktreeId,
    required String title,
    required int columns,
    required int rows,
  }) async {
    final response = await _request(
      RpcMethod.terminalCreate,
      TerminalCreateParamsDto(
        id: id,
        worktreeId: worktreeId,
        title: title,
        columns: columns,
        rows: rows,
      ).toJson(),
    );
    return TerminalResultDto.fromJson(response).terminal;
  }

  @override
  Future<TerminalAttachResultDto> attachTerminal(
    String terminalId, {
    int afterSequence = 0,
  }) async {
    _terminalSubscriptions[terminalId] = afterSequence;
    final response = await _request(
      RpcMethod.terminalAttach,
      TerminalAttachParamsDto(
        terminalId: terminalId,
        afterSequence: afterSequence,
      ).toJson(),
    );
    final result = TerminalAttachResultDto.fromJson(response);
    for (final output in result.replay) {
      final current = _terminalSubscriptions[terminalId] ?? 0;
      if (output.sequence > current) {
        _terminalSubscriptions[terminalId] = output.sequence;
      }
    }
    return result;
  }

  @override
  Future<void> writeTerminal(String terminalId, String data) => _request(
    RpcMethod.terminalWrite,
    TerminalWriteParamsDto(terminalId: terminalId, data: data).toJson(),
  );

  @override
  Future<TerminalDto> resizeTerminal(
    String terminalId, {
    required int columns,
    required int rows,
  }) async {
    final response = await _request(
      RpcMethod.terminalResize,
      TerminalResizeParamsDto(
        terminalId: terminalId,
        columns: columns,
        rows: rows,
      ).toJson(),
    );
    return TerminalResultDto.fromJson(response).terminal;
  }

  @override
  Future<void> terminateTerminal(String terminalId) async {
    await _request(
      RpcMethod.terminalTerminate,
      TerminalIdParamsDto(terminalId: terminalId).toJson(),
    );
    _terminalSubscriptions.remove(terminalId);
  }

  @override
  Future<ShellSpecDto?> getTerminalShell() async {
    final response = await _request(
      RpcMethod.terminalShellGet,
      const <String, dynamic>{},
    );
    return TerminalShellDto.fromJson(response).shell;
  }

  @override
  Future<void> setTerminalShell(ShellSpecDto? shell) => _request(
    RpcMethod.terminalShellSet,
    TerminalShellDto(shell: shell).toJson(),
  );

  @override
  Future<List<AgentDefinitionDto>> listAgentDefinitions() async {
    final response = await _request(
      RpcMethod.agentDefinitionList,
      const <String, dynamic>{},
    );
    return AgentDefinitionListResultDto.fromJson(response).definitions;
  }

  @override
  Future<AgentDefinitionDto> getAgentDefinition(String id) async {
    final response = await _request(
      RpcMethod.agentDefinitionGet,
      AgentDefinitionIdParamsDto(id: id).toJson(),
    );
    return AgentDefinitionResultDto.fromJson(response).definition;
  }

  @override
  Future<AgentDefinitionDto> createAgentDefinition(
    String id,
    AgentDefinitionDto definition,
  ) async {
    final response = await _request(
      RpcMethod.agentDefinitionCreate,
      AgentDefinitionCreateParamsDto(id: id, definition: definition).toJson(),
    );
    return AgentDefinitionResultDto.fromJson(response).definition;
  }

  @override
  Future<AgentDefinitionDto> updateAgentDefinition(
    AgentDefinitionDto definition, {
    required String expectedContentHash,
    bool force = false,
  }) async {
    final response = await _request(
      RpcMethod.agentDefinitionUpdate,
      AgentDefinitionUpdateParamsDto(
        definition: definition,
        expectedContentHash: expectedContentHash,
        force: force,
      ).toJson(),
    );
    return AgentDefinitionResultDto.fromJson(response).definition;
  }

  @override
  Future<void> archiveAgentDefinition(String id) => _request(
    RpcMethod.agentDefinitionArchive,
    AgentDefinitionIdParamsDto(id: id).toJson(),
  );

  @override
  Future<AgentDefinitionDto> resetAgentDefinition(String id) async {
    final response = await _request(
      RpcMethod.agentDefinitionReset,
      AgentDefinitionIdParamsDto(id: id).toJson(),
    );
    return AgentDefinitionResultDto.fromJson(response).definition;
  }

  @override
  Future<AgentDefinitionDto> validateAgentDefinition(
    String id,
    String markdown,
  ) async {
    final response = await _request(
      RpcMethod.agentDefinitionValidate,
      AgentDefinitionValidateParamsDto(id: id, markdown: markdown).toJson(),
    );
    return AgentDefinitionResultDto.fromJson(response).definition;
  }

  @override
  Future<List<AgentToolDefinitionDto>> listAgentTools({
    String? worktreeId,
  }) async {
    final response = await _request(
      RpcMethod.agentToolCatalog,
      AgentToolCatalogParamsDto(worktreeId: worktreeId).toJson(),
    );
    return AgentToolCatalogResultDto.fromJson(response).tools;
  }

  @override
  Future<List<McpServerStateDto>> listMcpServers({String? worktreeId}) async {
    final response = await _request(
      RpcMethod.mcpServerList,
      McpServersParamsDto(worktreeId: worktreeId).toJson(),
    );
    return McpServersResultDto.fromJson(response).servers;
  }

  @override
  Future<McpServerStateDto> addMcpServer(McpServerConfigDto server) async {
    final response = await _request(
      RpcMethod.mcpServerAdd,
      McpServerParamsDto(server: server).toJson(),
    );
    return McpServerStateResultDto.fromJson(response).state;
  }

  @override
  Future<McpServerStateDto> updateMcpServer(McpServerConfigDto server) async {
    final response = await _request(
      RpcMethod.mcpServerUpdate,
      McpServerParamsDto(server: server).toJson(),
    );
    return McpServerStateResultDto.fromJson(response).state;
  }

  @override
  Future<void> removeMcpServer(String id) async {
    await _request(
      RpcMethod.mcpServerRemove,
      McpServerIdParamsDto(id: id).toJson(),
    );
  }

  @override
  Future<McpServerStateDto> testMcpServer(McpServerConfigDto server) async {
    final response = await _request(
      RpcMethod.mcpServerTest,
      McpServerParamsDto(server: server).toJson(),
    );
    return McpServerStateResultDto.fromJson(response).state;
  }

  @override
  Future<void> setMcpSecret(String key, String value) async {
    await _request(
      RpcMethod.mcpSecretSet,
      McpSecretParamsDto(key: key, value: value).toJson(),
    );
  }

  @override
  Future<List<SkillDto>> listSkills({String? workspaceId}) async {
    final response = await _request(
      RpcMethod.skillList,
      SkillScopeParamsDto(workspaceId: workspaceId).toJson(),
    );
    return SkillListResultDto.fromJson(response).skills;
  }

  @override
  Future<SkillDto> getSkill(String id, {String? workspaceId}) async {
    final response = await _request(
      RpcMethod.skillGet,
      SkillIdParamsDto(id: id, workspaceId: workspaceId).toJson(),
    );
    return SkillResultDto.fromJson(response).skill;
  }

  @override
  Future<SkillDto> createSkill({
    required String id,
    required SkillSource source,
    required String name,
    required String description,
    required String body,
    String? workspaceId,
  }) async {
    final response = await _request(
      RpcMethod.skillCreate,
      SkillCreateParamsDto(
        id: id,
        source: source,
        name: name,
        description: description,
        body: body,
        workspaceId: workspaceId,
      ).toJson(),
    );
    return SkillResultDto.fromJson(response).skill;
  }

  @override
  Future<SkillDto> updateSkill(
    SkillDto skill, {
    required String expectedContentHash,
    bool force = false,
    String? workspaceId,
  }) async {
    final response = await _request(
      RpcMethod.skillUpdate,
      SkillUpdateParamsDto(
        skill: skill,
        expectedContentHash: expectedContentHash,
        force: force,
        workspaceId: workspaceId,
      ).toJson(),
    );
    return SkillResultDto.fromJson(response).skill;
  }

  @override
  Future<void> deleteSkill(String id, {String? workspaceId}) => _request(
    RpcMethod.skillDelete,
    SkillIdParamsDto(id: id, workspaceId: workspaceId).toJson(),
  );

  @override
  Future<SkillDto> setSkillEnabled(
    String id, {
    required bool enabled,
    String? workspaceId,
  }) async {
    final response = await _request(
      RpcMethod.skillSetEnabled,
      SkillSetEnabledParamsDto(
        id: id,
        enabled: enabled,
        workspaceId: workspaceId,
      ).toJson(),
    );
    return SkillResultDto.fromJson(response).skill;
  }

  @override
  Future<ProviderCatalogDto> listProviderCatalog() async {
    final response = await _request(
      RpcMethod.providerCatalog,
      const <String, dynamic>{},
    );
    return ProviderCatalogResultDto.fromJson(response).catalog;
  }

  @override
  Future<List<ProviderConnectionDto>> listProviderConnections() async {
    final response = await _request(
      RpcMethod.providerConnectionsList,
      const <String, dynamic>{},
    );
    return ProviderConnectionsResultDto.fromJson(response).connections;
  }

  @override
  Future<ProviderConnectionDto> connectProviderApiKey(
    String definitionId,
    String apiKey,
  ) async {
    final response = await _request(
      RpcMethod.providerConnectApiKey,
      ProviderConnectApiKeyParamsDto(
        definitionId: definitionId,
        apiKey: apiKey,
      ).toJson(),
    );
    return ProviderConnectionResultDto.fromJson(response).connection;
  }

  @override
  Future<ProviderConnectionDto> connectProviderNone(String definitionId) async {
    final response = await _request(
      RpcMethod.providerConnectNone,
      ProviderConnectNoneParamsDto(definitionId: definitionId).toJson(),
    );
    return ProviderConnectionResultDto.fromJson(response).connection;
  }

  @override
  Future<ProviderAuthAttemptDto> startProviderAuth(
    String definitionId,
    String methodId,
  ) async {
    final response = await _request(
      RpcMethod.providerAuthStart,
      ProviderAuthStartParamsDto(
        definitionId: definitionId,
        methodId: methodId,
      ).toJson(),
    );
    return ProviderAuthAttemptResultDto.fromJson(response).attempt;
  }

  @override
  Future<ProviderAuthAttemptDto> providerAuthStatus(String attemptId) async {
    final response = await _request(
      RpcMethod.providerAuthStatus,
      ProviderAuthAttemptParamsDto(attemptId: attemptId).toJson(),
    );
    return ProviderAuthAttemptResultDto.fromJson(response).attempt;
  }

  @override
  Future<void> cancelProviderAuth(String attemptId) async {
    await _request(
      RpcMethod.providerAuthCancel,
      ProviderAuthAttemptParamsDto(attemptId: attemptId).toJson(),
    );
  }

  @override
  Future<void> disconnectProvider(String connectionId) async {
    await _request(
      RpcMethod.providerDisconnect,
      ProviderConnectionIdParamsDto(connectionId: connectionId).toJson(),
    );
  }

  @override
  Future<ProviderCatalogDto> refreshProviderCatalog() async {
    final response = await _request(
      RpcMethod.providerCatalogRefresh,
      const <String, dynamic>{},
    );
    return ProviderCatalogResultDto.fromJson(response).catalog;
  }

  @override
  Future<List<ProviderModelDto>> listProviderModels(
    String connectionId,
  ) async {
    final response = await _request(
      RpcMethod.providerModelsList,
      ProviderConnectionIdParamsDto(connectionId: connectionId).toJson(),
    );
    return ProviderModelsResultDto.fromJson(response).models;
  }

  @override
  Future<ProviderConnectionDto> createCustomProvider(
    String id,
    CustomProviderConfigDto config, {
    String? apiKey,
  }) async {
    final response = await _request(
      RpcMethod.providerCustomCreate,
      ProviderCustomCreateParamsDto(
        id: id,
        config: config,
        apiKey: apiKey,
      ).toJson(),
    );
    return ProviderConnectionResultDto.fromJson(response).connection;
  }

  @override
  Future<ProviderConnectionDto> updateCustomProvider(
    String connectionId,
    CustomProviderConfigDto config, {
    String? apiKey,
  }) async {
    final response = await _request(
      RpcMethod.providerCustomUpdate,
      ProviderCustomUpdateParamsDto(
        connectionId: connectionId,
        config: config,
        apiKey: apiKey,
      ).toJson(),
    );
    return ProviderConnectionResultDto.fromJson(response).connection;
  }

  @override
  Future<void> deleteCustomProvider(String connectionId) async {
    await _request(
      RpcMethod.providerCustomDelete,
      ProviderConnectionIdParamsDto(connectionId: connectionId).toJson(),
    );
  }

  @override
  Future<void> startTurn({
    required String sessionId,
    required String turnId,
    required String prompt,
    List<String> attachmentIds = const <String>[],
  }) async {
    await _request(
      RpcMethod.turnStart,
      TurnStartParamsDto(
        sessionId: sessionId,
        turnId: turnId,
        prompt: prompt,
        attachmentIds: attachmentIds,
      ).toJson(),
    );
  }

  @override
  Future<AttachmentDto> uploadAttachment({
    required String fileName,
    required String mimeType,
    required int byteSize,
    required Stream<List<int>> bytes,
  }) async {
    final client = http.Client();
    try {
      final request =
          http.StreamedRequest(
              'POST',
              _endpoint.httpBaseUri.resolve('attachments'),
            )
            ..headers['authorization'] = 'Bearer ${_credentials.bearerToken}'
            ..headers['content-type'] = mimeType
            ..headers['x-file-name'] = Uri.encodeComponent(fileName)
            ..contentLength = byteSize;
      unawaited(
        bytes
            .forEach(request.sink.add)
            .then<void>((_) => request.sink.close())
            .onError<Object>((error, stackTrace) {
              request.sink.addError(error, stackTrace);
              return request.sink.close();
            }),
      );
      final response = await http.Response.fromStream(
        await client.send(request),
      );
      if (response.statusCode != 200) {
        throw CoderClientException(
          response.body.isEmpty ? 'Attachment upload failed.' : response.body,
          code: 'attachment_upload_failed',
        );
      }
      return AttachmentDto.fromJson(
        Map<String, dynamic>.from(jsonDecode(response.body) as Map),
      );
    } finally {
      client.close();
    }
  }

  @override
  Future<AttachmentDownload> downloadAttachment(String id) async {
    final client = http.Client();
    final request = http.Request(
      'GET',
      _endpoint.httpBaseUri.resolve('attachments/${Uri.encodeComponent(id)}'),
    )..headers['authorization'] = 'Bearer ${_credentials.bearerToken}';
    final response = await client.send(request);
    if (response.statusCode != 200) {
      final body = await response.stream.bytesToString();
      client.close();
      throw CoderClientException(
        body.isEmpty ? 'Attachment download failed.' : body,
        code: 'attachment_download_failed',
      );
    }
    final headers = response.headers;
    final encodedName = RegExp(
      r"filename\*=UTF-8''([^;]+)",
    ).firstMatch(headers['content-disposition'] ?? '')?.group(1);
    return AttachmentDownload(
      fileName: encodedName == null ? id : Uri.decodeComponent(encodedName),
      // The parameters after `;` are not part of the media type the caller
      // matches on.
      mimeType: (headers['content-type'] ?? 'application/octet-stream')
          .split(';')
          .first
          .trim(),
      byteSize: response.contentLength ?? -1,
      bytes: _closeClientAfter(response.stream, client),
    );
  }

  Stream<List<int>> _closeClientAfter(
    Stream<List<int>> source,
    http.Client client,
  ) async* {
    try {
      yield* source;
    } finally {
      client.close();
    }
  }

  @override
  Future<void> cancelTurn(String sessionId) async {
    await _request(
      RpcMethod.turnCancel,
      SessionIdParamsDto(sessionId: sessionId).toJson(),
    );
  }

  @override
  Future<void> resolveApproval({
    required String approvalId,
    required bool approved,
  }) async {
    await _request(
      RpcMethod.approvalResolve,
      ApprovalResolveParamsDto(
        approvalId: approvalId,
        approved: approved,
      ).toJson(),
    );
  }

  @override
  Future<List<TimelineEventDto>> subscribeTimeline(
    String sessionId, {
    int afterSequence = 0,
  }) async {
    _timelineSubscriptions[sessionId] = afterSequence;
    final response = await _request(
      RpcMethod.timelineSubscribe,
      TimelineSubscribeParamsDto(
        sessionId: sessionId,
        afterSequence: afterSequence,
      ).toJson(),
    );
    final events = TimelineResultDto.fromJson(response).events;
    for (final event in events) {
      final current = _timelineSubscriptions[sessionId] ?? 0;
      if (event.sequence > current) {
        _timelineSubscriptions[sessionId] = event.sequence;
      }
    }
    return events;
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _states.add(ClientConnectionState.disconnected);
    await _peer?.close();
    await _events.close();
    await _states.close();
  }
}
