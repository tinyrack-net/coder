import 'dart:async';
import 'dart:convert';

import 'package:client/src/api.dart';
import 'package:client/src/endpoint.dart';
import 'package:client/src/web_socket_connector.dart';
import 'package:http/http.dart' as http;
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:protocol/protocol.dart';

SessionModelSelectionDto? _canonicalSelection(
  SessionModelSelectionDto? selection,
) => selection == null
    ? null
    : SessionModelSelectionDto(modelId: selection.qualifiedModelId);

/// CoderClientException defines a public contract.
class CoderClientException implements Exception {
  /// Creates a [CoderClientException].
  const CoderClientException(
    this.message, {
    this.code,
    this.retryable = false,
    this.details = const <String, dynamic>{},
  });

  /// The message public API member.
  final String message;

  /// The code public API member.
  final String? code;

  /// The retryable public API member.
  final bool retryable;

  /// Structured, non-sensitive failure context supplied by the daemon.
  final Map<String, dynamic> details;

  @override
  String toString() =>
      'CoderClientException${code == null ? '' : '($code)'}: $message';
}

/// CoderClient defines a public contract.
class CoderClient
    implements
        CoderApi,
        WorkspacesApi,
        SessionsApi,
        AgentsApi,
        PromptsApi,
        ProvidersApi,
        McpApi,
        TerminalsApi,
        AttachmentsApi {
  CoderClient._({
    required this._endpoint,
    required this._credentials,
    required this._clientId,
    required this._clientKind,
    required this._clientVersion,
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
    String clientVersion = 'unknown',
    WebSocketConnector? connector,
    Duration requestTimeout = const Duration(seconds: 60),
    Duration Function(int attempt)? reconnectDelay,
  }) async {
    final client = CoderClient._(
      endpoint: endpoint,
      credentials: credentials,
      clientId: clientId,
      clientKind: clientKind,
      clientVersion: clientVersion,
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
  final String _clientVersion;
  final WebSocketConnector _connector;
  final Duration _requestTimeout;
  final Duration Function(int attempt) _reconnectDelay;
  final StreamController<SessionDto> _sessionUpdates =
      StreamController<SessionDto>.broadcast();
  final StreamController<GoalDto> _goalUpdates =
      StreamController<GoalDto>.broadcast();
  final StreamController<GoalClearedDto> _goalClears =
      StreamController<GoalClearedDto>.broadcast();
  final StreamController<TimelineEventDto> _timelineEvents =
      StreamController<TimelineEventDto>.broadcast();
  final StreamController<ApprovalRequestDto> _approvalRequests =
      StreamController<ApprovalRequestDto>.broadcast();
  final StreamController<UserQuestionRequestDto> _questionRequests =
      StreamController<UserQuestionRequestDto>.broadcast();
  final StreamController<void> _agentChanges =
      StreamController<void>.broadcast();
  final StreamController<void> _skillChanges =
      StreamController<void>.broadcast();
  final StreamController<void> _commandChanges =
      StreamController<void>.broadcast();
  final StreamController<ProviderAuthAttemptDto> _providerAuthUpdates =
      StreamController<ProviderAuthAttemptDto>.broadcast();
  final StreamController<ProviderCatalogDto> _providerCatalogUpdates =
      StreamController<ProviderCatalogDto>.broadcast();
  final StreamController<void> _mcpChanges = StreamController<void>.broadcast();
  final StreamController<TerminalOutputDto> _terminalOutput =
      StreamController<TerminalOutputDto>.broadcast();
  final StreamController<TerminalDto> _terminalUpdates =
      StreamController<TerminalDto>.broadcast();
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
  Stream<ClientConnectionState> get states => _states.stream;

  @override
  WorkspacesApi get workspaces => this;

  @override
  SessionsApi get sessions => this;

  @override
  AgentsApi get agents => this;

  @override
  PromptsApi get prompts => this;

  @override
  ProvidersApi get providers => this;

  @override
  McpApi get mcp => this;

  @override
  TerminalsApi get terminals => this;

  @override
  AttachmentsApi get attachments => this;

  @override
  Stream<SessionDto> get sessionUpdates => _sessionUpdates.stream;

  @override
  Stream<GoalDto> get goalUpdates => _goalUpdates.stream;

  @override
  Stream<GoalClearedDto> get goalClears => _goalClears.stream;

  @override
  Stream<TimelineEventDto> get timelineEvents => _timelineEvents.stream;

  @override
  Stream<ApprovalRequestDto> get approvalRequests => _approvalRequests.stream;

  @override
  Stream<UserQuestionRequestDto> get questionRequests =>
      _questionRequests.stream;

  @override
  Stream<void> get definitionChanges => _agentChanges.stream;

  @override
  Stream<void> get skillChanges => _skillChanges.stream;

  @override
  Stream<void> get commandChanges => _commandChanges.stream;

  @override
  Stream<ProviderAuthAttemptDto> get authUpdates => _providerAuthUpdates.stream;

  @override
  Stream<ProviderCatalogDto> get catalogUpdates =>
      _providerCatalogUpdates.stream;

  @override
  Stream<void> get serverChanges => _mcpChanges.stream;

  @override
  Stream<TerminalOutputDto> get output => _terminalOutput.stream;

  @override
  Stream<TerminalDto> get terminalUpdates => _terminalUpdates.stream;
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
      for (final notification in rpcNotifications) {
        peer.registerMethod(notification.name, (
          json_rpc.Parameters parameters,
        ) {
          _handleNotification(
            notification.name,
            Map<String, dynamic>.from(parameters.asMap),
          );
        });
      }
      unawaited(peer.listen().whenComplete(_handleSocketDone));
      final hello = await peer.sendRequest(
        systemHelloProcedure.name,
        systemHelloProcedure.encodeParams(
          HelloParamsDto(
            clientId: _clientId,
            clientKind: _clientKind,
            protocolMajor: coderProtocolMajor,
            clientVersion: _clientVersion,
            capabilities: const <String, bool>{'timelineCatchup': true},
          ),
        ),
      );
      _serverInfo = systemHelloProcedure.decodeResult(
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
            events.forEach(_timelineEvents.add);
          }),
        );
      }
      for (final entry in Map<String, int>.from(
        _terminalSubscriptions,
      ).entries) {
        unawaited(
          attachTerminal(entry.key, afterSequence: entry.value).then((result) {
            _terminalUpdates.add(result.terminal);
            result.replay.forEach(_terminalOutput.add);
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
        case final name when name == sessionsTimelineEventNotification.name:
          final event = sessionsTimelineEventNotification.decode(parameters);
          final current = _timelineSubscriptions[event.sessionId] ?? 0;
          if (event.sequence <= current) return;
          _timelineSubscriptions[event.sessionId] = event.sequence;
          _timelineEvents.add(event);
        case final name when name == sessionsUpdatedNotification.name:
          _sessionUpdates.add(sessionsUpdatedNotification.decode(parameters));
        case final name when name == sessionsGoalUpdatedNotification.name:
          _goalUpdates.add(sessionsGoalUpdatedNotification.decode(parameters));
        case final name when name == sessionsGoalClearedNotification.name:
          _goalClears.add(sessionsGoalClearedNotification.decode(parameters));
        case final name when name == agentsChangedNotification.name:
          agentsChangedNotification.decode(parameters);
          _agentChanges.add(null);
        case final name when name == mcpChangedNotification.name:
          mcpChangedNotification.decode(parameters);
          _mcpChanges.add(null);
        case final name when name == promptsSkillsChangedNotification.name:
          promptsSkillsChangedNotification.decode(parameters);
          _skillChanges.add(null);
        case final name when name == promptsCommandsChangedNotification.name:
          promptsCommandsChangedNotification.decode(parameters);
          _commandChanges.add(null);
        case final name when name == sessionsApprovalRequestedNotification.name:
          _approvalRequests.add(
            sessionsApprovalRequestedNotification.decode(parameters),
          );
        case final name when name == sessionsQuestionRequestedNotification.name:
          _questionRequests.add(
            sessionsQuestionRequestedNotification.decode(parameters),
          );
        case final name when name == providersAuthUpdatedNotification.name:
          _providerAuthUpdates.add(
            providersAuthUpdatedNotification.decode(parameters),
          );
        case final name when name == providersCatalogUpdatedNotification.name:
          _providerCatalogUpdates.add(
            providersCatalogUpdatedNotification.decode(parameters),
          );
        case final name when name == terminalsOutputNotification.name:
          final output = terminalsOutputNotification.decode(parameters);
          final current = _terminalSubscriptions[output.terminalId];
          if (current == null || output.sequence <= current) return;
          _terminalSubscriptions[output.terminalId] = output.sequence;
          _terminalOutput.add(output);
        case final name when name == terminalsUpdatedNotification.name:
          _terminalUpdates.add(terminalsUpdatedNotification.decode(parameters));
      }
    } on FormatException catch (error, stackTrace) {
      for (final controller in <StreamController<Object?>>[
        _sessionUpdates,
        _timelineEvents,
        _approvalRequests,
        _questionRequests,
        _agentChanges,
        _skillChanges,
        _commandChanges,
        _providerAuthUpdates,
        _mcpChanges,
        _terminalOutput,
        _terminalUpdates,
      ]) {
        controller.addError(error, stackTrace);
      }
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

  Future<R> _call<P extends Object, R extends Object>(
    RpcProcedure<P, R> procedure,
    P params,
  ) async {
    try {
      final result =
          await (_peer ??
                  (throw const CoderClientException(
                    'Not connected.',
                    retryable: true,
                  )))
              .sendRequest(procedure.name, procedure.encodeParams(params))
              .timeout(_requestTimeout);
      return procedure.decodeResult(
        Map<String, dynamic>.from(result as Map),
      );
    } on json_rpc.RpcException catch (error) {
      RpcFailureDto? failure;
      if (error.data case final Map<Object?, Object?> data) {
        try {
          failure = RpcFailureDto.fromJson(Map<String, dynamic>.from(data));
        } on FormatException {
          failure = null;
        }
      }
      throw CoderClientException(
        error.message,
        code: failure?.code,
        retryable: failure?.retryable ?? false,
        details: failure?.details ?? const <String, dynamic>{},
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
    final response = await _call(
      workspacesCatalogProcedure,
      const EmptyParamsDto(),
    );
    return response.catalog;
  }

  @override
  Future<WorkspaceRegisterResultDto> registerWorkspace({
    required String workspaceId,
    required String checkoutId,
    required String rootPath,
    required String name,
  }) async {
    final response = await _call(
      workspacesRegisterProcedure,
      WorkspaceRegisterParamsDto(
        workspaceId: workspaceId,
        checkoutId: checkoutId,
        rootPath: rootPath,
        name: name,
      ),
    );
    return response;
  }

  @override
  Future<WorkspaceCatalogDto> refreshWorkspace(String workspaceId) async {
    final response = await _call(
      workspacesRefreshProcedure,
      WorkspaceIdParamsDto(workspaceId: workspaceId),
    );
    return response.catalog;
  }

  @override
  Future<void> unregisterWorkspace(String workspaceId) async {
    await _call(
      workspacesUnregisterProcedure,
      WorkspaceIdParamsDto(workspaceId: workspaceId),
    );
  }

  @override
  Future<List<DirectorySuggestionDto>> suggestDirectories(
    String query, {
    int limit = 30,
  }) async {
    final response = await _call(
      workspacesSuggestDirectoriesProcedure,
      DirectorySuggestParamsDto(query: query, limit: limit),
    );
    return response.suggestions;
  }

  @override
  Future<FileSearchResultDto> searchFiles({
    required String worktreeId,
    required String query,
    int limit = 50,
  }) async {
    final response = await _call(
      workspacesSearchFilesProcedure,
      FileSearchParamsDto(
        worktreeId: worktreeId,
        query: query,
        limit: limit,
      ),
    );
    return response;
  }

  @override
  Future<List<GitBranchDto>> listGitBranches(String workspaceId) async {
    final response = await _call(
      workspacesListBranchesProcedure,
      GitBranchesListParamsDto(workspaceId: workspaceId),
    );
    return response.branches;
  }

  @override
  Future<ProjectSettingsResultDto> getProjectSettings(
    String workspaceId,
  ) async {
    final response = await _call(
      workspacesGetProjectSettingsProcedure,
      ProjectSettingsGetParamsDto(workspaceId: workspaceId),
    );
    return response;
  }

  @override
  Future<ProjectSettingsResultDto> saveProjectSettings(
    String workspaceId,
    ProjectSettingsDto settings,
  ) async {
    final response = await _call(
      workspacesSaveProjectSettingsProcedure,
      ProjectSettingsSaveParamsDto(
        workspaceId: workspaceId,
        settings: settings,
      ),
    );
    return response;
  }

  @override
  Future<WorktreeResultDto> createWorktree({
    required String id,
    required String workspaceId,
    required WorktreeCreateMode mode,
    required String branchName,
    String? baseBranch,
  }) async {
    final response = await _call(
      workspacesCreateWorktreeProcedure,
      WorktreeCreateParamsDto(
        id: id,
        workspaceId: workspaceId,
        mode: mode,
        branchName: branchName,
        baseBranch: baseBranch,
      ),
    );
    return response;
  }

  @override
  Future<WorktreeArchivePreviewDto> previewWorktreeArchive(
    String worktreeId,
  ) async {
    final response = await _call(
      workspacesPreviewArchiveProcedure,
      WorktreeIdParamsDto(worktreeId: worktreeId),
    );
    return response.preview;
  }

  @override
  Future<WorktreeResultDto> archiveWorktree(
    String worktreeId, {
    bool force = false,
  }) async {
    final response = await _call(
      workspacesArchiveWorktreeProcedure,
      WorktreeArchiveParamsDto(worktreeId: worktreeId, force: force),
    );
    return response;
  }

  @override
  Future<List<SessionDto>> listSessions({String? worktreeId}) async {
    final response = await _call(
      sessionsListProcedure,
      SessionListParamsDto(worktreeId: worktreeId),
    );
    return response.sessions;
  }

  @override
  Future<List<SessionDto>> listSubagents(String sessionId) async {
    final response = await _call(
      sessionsListSubagentsProcedure,
      SessionSubagentListParamsDto(sessionId: sessionId),
    );
    return response.sessions;
  }

  @override
  Future<SessionDto> createSession({
    required String id,
    required String worktreeId,
    required String title,
    required String agentDefinitionId,
    SessionMode mode = SessionMode.normal,
    SessionModelSelectionDto? model,
    Map<String, ModelControlValueDto> modelControls =
        const <String, ModelControlValueDto>{},
    PermissionMode? permissionMode,
  }) async {
    final response = await _call(
      sessionsCreateProcedure,
      SessionCreateParamsDto(
        id: id,
        worktreeId: worktreeId,
        title: title,
        agentDefinitionId: agentDefinitionId,
        mode: mode,
        model: _canonicalSelection(model),
        modelControls: modelControls,
        permissionMode: permissionMode,
      ),
    );
    return response.session;
  }

  @override
  Future<SessionDto> updateSettings(
    String sessionId,
    SessionSettingsPatchDto patch,
  ) async {
    final response = await _call(
      sessionsUpdateSettingsProcedure,
      SessionSettingsUpdateParamsDto(
        sessionId: sessionId,
        patch: patch.hasModel
            ? patch.copyWith(model: _canonicalSelection(patch.model))
            : patch,
      ),
    );
    return response.session;
  }

  @override
  Future<GoalDto?> getGoal(String sessionId) async {
    final response = await _call(
      sessionsGetGoalProcedure,
      SessionIdParamsDto(sessionId: sessionId),
    );
    return response.goal;
  }

  @override
  Future<GoalDto> replaceGoal({
    required String sessionId,
    required String objective,
    int? tokenBudget,
  }) async {
    final response = await _call(
      sessionsReplaceGoalProcedure,
      GoalReplaceParamsDto(
        sessionId: sessionId,
        objective: objective,
        tokenBudget: tokenBudget,
      ),
    );
    return response.goal;
  }

  @override
  Future<GoalDto> updateGoal(String sessionId, GoalUpdateDto update) async {
    final response = await _call(
      sessionsUpdateGoalProcedure,
      GoalUpdateParamsDto(sessionId: sessionId, update: update),
    );
    return response.goal;
  }

  @override
  Future<bool> clearGoal(String sessionId) async {
    final response = await _call(
      sessionsClearGoalProcedure,
      SessionIdParamsDto(sessionId: sessionId),
    );
    return response.cleared;
  }

  @override
  Future<PermissionSettingsDto> getDefaultPermissionMode() async {
    final response = await _call(
      agentsGetDefaultPermissionModeProcedure,
      const EmptyParamsDto(),
    );
    return response;
  }

  @override
  Future<PermissionSettingsDto> setDefaultPermissionMode(
    PermissionMode permissionMode,
  ) async {
    final settings = PermissionSettingsDto(defaultMode: permissionMode);
    final response = await _call(
      agentsSetDefaultPermissionModeProcedure,
      settings,
    );
    return response;
  }

  @override
  Future<List<TerminalDto>> listTerminals(String worktreeId) async {
    final response = await _call(
      terminalsListProcedure,
      TerminalListParamsDto(worktreeId: worktreeId),
    );
    return response.terminals;
  }

  @override
  Future<TerminalDto> createTerminal({
    required String id,
    required String worktreeId,
    required String title,
    required int columns,
    required int rows,
  }) async {
    final response = await _call(
      terminalsCreateProcedure,
      TerminalCreateParamsDto(
        id: id,
        worktreeId: worktreeId,
        title: title,
        columns: columns,
        rows: rows,
      ),
    );
    return response.terminal;
  }

  @override
  Future<TerminalAttachResultDto> attachTerminal(
    String terminalId, {
    int afterSequence = 0,
  }) async {
    _terminalSubscriptions[terminalId] = afterSequence;
    final response = await _call(
      terminalsAttachProcedure,
      TerminalAttachParamsDto(
        terminalId: terminalId,
        afterSequence: afterSequence,
      ),
    );
    final result = response;
    for (final output in result.replay) {
      final current = _terminalSubscriptions[terminalId] ?? 0;
      if (output.sequence > current) {
        _terminalSubscriptions[terminalId] = output.sequence;
      }
    }
    return result;
  }

  @override
  Future<void> writeTerminal(String terminalId, String data) => _call(
    terminalsWriteProcedure,
    TerminalWriteParamsDto(terminalId: terminalId, data: data),
  );

  @override
  Future<TerminalDto> resizeTerminal(
    String terminalId, {
    required int columns,
    required int rows,
  }) async {
    final response = await _call(
      terminalsResizeProcedure,
      TerminalResizeParamsDto(
        terminalId: terminalId,
        columns: columns,
        rows: rows,
      ),
    );
    return response.terminal;
  }

  @override
  Future<void> terminateTerminal(String terminalId) async {
    await _call(
      terminalsTerminateProcedure,
      TerminalIdParamsDto(terminalId: terminalId),
    );
    _terminalSubscriptions.remove(terminalId);
  }

  @override
  Future<ShellSpecDto?> getTerminalShell() async {
    final response = await _call(
      terminalsGetDefaultShellProcedure,
      const EmptyParamsDto(),
    );
    return response.shell;
  }

  @override
  Future<void> setTerminalShell(ShellSpecDto? shell) => _call(
    terminalsSetDefaultShellProcedure,
    TerminalShellDto(shell: shell),
  );

  @override
  Future<List<AgentDefinitionDto>> listAgentDefinitions() async {
    final response = await _call(
      agentsListProcedure,
      const EmptyParamsDto(),
    );
    return response.definitions;
  }

  @override
  Future<AgentDefinitionDto> getAgentDefinition(String id) async {
    final response = await _call(
      agentsGetProcedure,
      AgentDefinitionIdParamsDto(id: id),
    );
    return response.definition;
  }

  @override
  Future<AgentDefinitionDto> createAgentDefinition(
    String id,
    AgentDefinitionDto definition,
  ) async {
    final response = await _call(
      agentsCreateProcedure,
      AgentDefinitionCreateParamsDto(id: id, definition: definition),
    );
    return response.definition;
  }

  @override
  Future<AgentDefinitionDto> updateAgentDefinition(
    AgentDefinitionDto definition, {
    required String expectedContentHash,
    bool force = false,
  }) async {
    final response = await _call(
      agentsUpdateProcedure,
      AgentDefinitionUpdateParamsDto(
        definition: definition,
        expectedContentHash: expectedContentHash,
        force: force,
      ),
    );
    return response.definition;
  }

  @override
  Future<void> archiveAgentDefinition(String id) => _call(
    agentsArchiveProcedure,
    AgentDefinitionIdParamsDto(id: id),
  );

  @override
  Future<AgentDefinitionDto> resetAgentDefinition(String id) async {
    final response = await _call(
      agentsResetProcedure,
      AgentDefinitionIdParamsDto(id: id),
    );
    return response.definition;
  }

  @override
  Future<AgentDefinitionDto> validateAgentDefinition(
    String id,
    String markdown,
  ) async {
    final response = await _call(
      agentsValidateProcedure,
      AgentDefinitionValidateParamsDto(id: id, markdown: markdown),
    );
    return response.definition;
  }

  @override
  Future<List<AgentToolDefinitionDto>> listAgentTools({
    String? worktreeId,
  }) async {
    final response = await _call(
      agentsListToolsProcedure,
      AgentToolCatalogParamsDto(worktreeId: worktreeId),
    );
    return response.tools;
  }

  @override
  Future<List<McpServerStateDto>> listMcpServers({String? worktreeId}) async {
    final response = await _call(
      mcpListServersProcedure,
      McpServersParamsDto(worktreeId: worktreeId),
    );
    return response.servers;
  }

  @override
  Future<McpServerStateDto> addMcpServer(McpServerConfigDto server) async {
    final response = await _call(
      mcpAddServerProcedure,
      McpServerParamsDto(server: server),
    );
    return response.state;
  }

  @override
  Future<McpServerStateDto> updateMcpServer(McpServerConfigDto server) async {
    final response = await _call(
      mcpUpdateServerProcedure,
      McpServerParamsDto(server: server),
    );
    return response.state;
  }

  @override
  Future<void> removeMcpServer(String id) async {
    await _call(
      mcpRemoveServerProcedure,
      McpServerIdParamsDto(id: id),
    );
  }

  @override
  Future<McpServerStateDto> testMcpServer(McpServerConfigDto server) async {
    final response = await _call(
      mcpTestServerProcedure,
      McpServerParamsDto(server: server),
    );
    return response.state;
  }

  @override
  Future<void> setMcpSecret(String key, String value) async {
    await _call(
      mcpSetSecretProcedure,
      McpSecretParamsDto(key: key, value: value),
    );
  }

  @override
  Future<List<AgentCommandDto>> listCommands({String? workspaceId}) async {
    final response = await _call(
      promptsListCommandsProcedure,
      CommandListParamsDto(workspaceId: workspaceId),
    );
    return response.commands;
  }

  @override
  Future<List<SkillDto>> listSkills({String? workspaceId}) async {
    final response = await _call(
      promptsListSkillsProcedure,
      SkillScopeParamsDto(workspaceId: workspaceId),
    );
    return response.skills;
  }

  @override
  Future<SkillDto> getSkill(String id, {String? workspaceId}) async {
    final response = await _call(
      promptsGetSkillProcedure,
      SkillIdParamsDto(id: id, workspaceId: workspaceId),
    );
    return response.skill;
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
    final response = await _call(
      promptsCreateSkillProcedure,
      SkillCreateParamsDto(
        id: id,
        source: source,
        name: name,
        description: description,
        body: body,
        workspaceId: workspaceId,
      ),
    );
    return response.skill;
  }

  @override
  Future<SkillDto> updateSkill(
    SkillDto skill, {
    required String expectedContentHash,
    bool force = false,
    String? workspaceId,
  }) async {
    final response = await _call(
      promptsUpdateSkillProcedure,
      SkillUpdateParamsDto(
        skill: skill,
        expectedContentHash: expectedContentHash,
        force: force,
        workspaceId: workspaceId,
      ),
    );
    return response.skill;
  }

  @override
  Future<void> deleteSkill(String id, {String? workspaceId}) => _call(
    promptsDeleteSkillProcedure,
    SkillIdParamsDto(id: id, workspaceId: workspaceId),
  );

  @override
  Future<SkillDto> setSkillEnabled(
    String id, {
    required bool enabled,
    String? workspaceId,
  }) async {
    final response = await _call(
      promptsSetSkillEnabledProcedure,
      SkillSetEnabledParamsDto(
        id: id,
        enabled: enabled,
        workspaceId: workspaceId,
      ),
    );
    return response.skill;
  }

  @override
  Future<ProviderCatalogDto> listProviderCatalog() async {
    final response = await _call(
      providersCatalogProcedure,
      const EmptyParamsDto(),
    );
    return response.catalog;
  }

  @override
  Future<List<ProviderConnectionDto>> listProviderConnections() async {
    final response = await _call(
      providersListConnectionsProcedure,
      const EmptyParamsDto(),
    );
    return response.connections;
  }

  @override
  Future<List<ProviderUsageDto>> listProviderUsage() async {
    final response = await _call(
      providersListUsageProcedure,
      const EmptyParamsDto(),
    );
    return response.usage;
  }

  @override
  Future<ProviderConnectionDto> connectProviderApiKey(
    String definitionId,
    String apiKey, {
    String? connectionId,
    String? modelPrefix,
  }) async {
    final response = await _call(
      providersConnectApiKeyProcedure,
      ProviderConnectApiKeyParamsDto(
        definitionId: definitionId,
        apiKey: apiKey,
        connectionId: connectionId,
        modelPrefix: modelPrefix,
      ),
    );
    return response.connection;
  }

  @override
  Future<ProviderConnectionDto> connectProviderNone(
    String definitionId, {
    String? connectionId,
    String? modelPrefix,
  }) async {
    final response = await _call(
      providersConnectNoneProcedure,
      ProviderConnectNoneParamsDto(
        definitionId: definitionId,
        connectionId: connectionId,
        modelPrefix: modelPrefix,
      ),
    );
    return response.connection;
  }

  @override
  Future<ProviderAuthAttemptDto> startProviderAuth(
    String definitionId,
    String methodId, {
    String? connectionId,
    String? modelPrefix,
  }) async {
    final response = await _call(
      providersStartAuthProcedure,
      ProviderAuthStartParamsDto(
        definitionId: definitionId,
        methodId: methodId,
        connectionId: connectionId,
        modelPrefix: modelPrefix,
      ),
    );
    return response.attempt;
  }

  @override
  Future<ProviderAuthAttemptDto> providerAuthStatus(String attemptId) async {
    final response = await _call(
      providersGetAuthProcedure,
      ProviderAuthAttemptParamsDto(attemptId: attemptId),
    );
    return response.attempt;
  }

  @override
  Future<void> cancelProviderAuth(String attemptId) async {
    await _call(
      providersCancelAuthProcedure,
      ProviderAuthAttemptParamsDto(attemptId: attemptId),
    );
  }

  @override
  Future<void> disconnectProvider(String connectionId) async {
    await _call(
      providersDisconnectProcedure,
      ProviderConnectionIdParamsDto(connectionId: connectionId),
    );
  }

  @override
  Future<ProviderConnectionDto> updateProviderModelPrefix(
    String connectionId,
    String modelPrefix,
  ) async {
    final response = await _call(
      providersUpdateModelPrefixProcedure,
      ProviderPrefixUpdateParamsDto(
        connectionId: connectionId,
        modelPrefix: modelPrefix,
      ),
    );
    return response.connection;
  }

  @override
  Future<ProviderCatalogDto> refreshProviderCatalog() async {
    final response = await _call(
      providersRefreshCatalogProcedure,
      const EmptyParamsDto(),
    );
    return response.catalog;
  }

  @override
  Future<List<ProviderModelDto>> listProviderModels(
    String connectionId,
  ) async {
    final response = await _call(
      providersListModelsProcedure,
      ProviderConnectionIdParamsDto(connectionId: connectionId),
    );
    return response.models;
  }

  @override
  Future<SessionModelSelectionDto?> getDefaultModel() async {
    final response = await _call(
      providersGetDefaultModelProcedure,
      const EmptyParamsDto(),
    );
    return response.model;
  }

  @override
  Future<void> setDefaultModel(SessionModelSelectionDto? model) => _call(
    providersSetDefaultModelProcedure,
    DefaultModelDto(model: _canonicalSelection(model)),
  );

  @override
  Future<ProviderConnectionDto> createCustomProvider(
    String id,
    CustomProviderConfigDto config, {
    String? apiKey,
    String? modelPrefix,
  }) async {
    final response = await _call(
      providersCreateCustomProcedure,
      ProviderCustomCreateParamsDto(
        id: id,
        config: config,
        apiKey: apiKey,
        modelPrefix: modelPrefix,
      ),
    );
    return response.connection;
  }

  @override
  Future<ProviderConnectionDto> updateCustomProvider(
    String connectionId,
    CustomProviderConfigDto config, {
    String? apiKey,
  }) async {
    final response = await _call(
      providersUpdateCustomProcedure,
      ProviderCustomUpdateParamsDto(
        connectionId: connectionId,
        config: config,
        apiKey: apiKey,
      ),
    );
    return response.connection;
  }

  @override
  Future<void> deleteCustomProvider(String connectionId) async {
    await _call(
      providersDeleteCustomProcedure,
      ProviderConnectionIdParamsDto(connectionId: connectionId),
    );
  }

  @override
  Future<void> startTurn({
    required String sessionId,
    required String turnId,
    required String prompt,
    List<String> attachmentIds = const <String>[],
  }) async {
    await _call(
      sessionsStartTurnProcedure,
      TurnStartParamsDto(
        sessionId: sessionId,
        turnId: turnId,
        prompt: prompt,
        attachmentIds: attachmentIds,
      ),
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
              _endpoint.httpBaseUri.resolve('v4/attachments'),
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
      _endpoint.httpBaseUri.resolve(
        'v4/attachments/${Uri.encodeComponent(id)}',
      ),
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
    await _call(
      sessionsCancelTurnProcedure,
      SessionIdParamsDto(sessionId: sessionId),
    );
  }

  @override
  Future<void> compactSession(String sessionId) async {
    await _call(
      sessionsCompactProcedure,
      SessionIdParamsDto(sessionId: sessionId),
    );
  }

  @override
  Future<void> resolveApproval({
    required String approvalId,
    required bool approved,
  }) async {
    await _call(
      sessionsResolveApprovalProcedure,
      ApprovalResolveParamsDto(
        approvalId: approvalId,
        approved: approved,
      ),
    );
  }

  @override
  Future<void> notePendingInput(String sessionId) async {
    await _call(
      sessionsNotePendingInputProcedure,
      SessionPendingInputParamsDto(sessionId: sessionId),
    );
  }

  @override
  Future<UserQuestionRequestDto> answerUserQuestion({
    required String requestId,
    required List<UserQuestionAnswerDto> answers,
  }) async => (await _call(
    sessionsAnswerQuestionProcedure,
    UserQuestionAnswerParamsDto(
      requestId: requestId,
      answers: answers,
    ),
  )).request;

  @override
  Future<List<TimelineEventDto>> subscribeTimeline(
    String sessionId, {
    int afterSequence = 0,
  }) async {
    _timelineSubscriptions[sessionId] = afterSequence;
    final response = await _call(
      sessionsSubscribeTimelineProcedure,
      TimelineSubscribeParamsDto(
        sessionId: sessionId,
        afterSequence: afterSequence,
      ),
    );
    final events = response.events;
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
    await Future.wait(<Future<void>>[
      _sessionUpdates.close(),
      _goalUpdates.close(),
      _goalClears.close(),
      _timelineEvents.close(),
      _approvalRequests.close(),
      _questionRequests.close(),
      _agentChanges.close(),
      _skillChanges.close(),
      _commandChanges.close(),
      _providerAuthUpdates.close(),
      _providerCatalogUpdates.close(),
      _mcpChanges.close(),
      _terminalOutput.close(),
      _terminalUpdates.close(),
    ]);
    await _states.close();
  }
}
