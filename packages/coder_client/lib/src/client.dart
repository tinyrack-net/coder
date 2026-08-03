import 'dart:async';

import 'package:coder_client/src/api.dart';
import 'package:coder_client/src/endpoint.dart';
import 'package:coder_client/src/web_socket_connector.dart';
import 'package:coder_protocol/coder_protocol.dart';
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
    WebSocketConnector connector = const IoWebSocketConnector(),
    Duration requestTimeout = const Duration(seconds: 60),
    Duration Function(int attempt)? reconnectDelay,
  }) async {
    final client = CoderClient._(
      endpoint: endpoint,
      credentials: credentials,
      clientId: clientId,
      clientKind: clientKind,
      connector: connector,
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
        RpcNotification.approvalRequested,
        RpcNotification.providerAuthUpdated,
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
  Future<WorktreeDto> createWorktree({
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
    return WorktreeResultDto.fromJson(response).worktree;
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
  Future<WorktreeDto> archiveWorktree(
    String worktreeId, {
    bool force = false,
  }) async {
    final response = await _request(
      RpcMethod.worktreeArchive,
      WorktreeArchiveParamsDto(worktreeId: worktreeId, force: force).toJson(),
    );
    return WorktreeResultDto.fromJson(response).worktree;
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
  }) async {
    final response = await _request(
      RpcMethod.sessionCreate,
      SessionCreateParamsDto(
        id: id,
        worktreeId: worktreeId,
        title: title,
        agentDefinitionId: agentDefinitionId,
      ).toJson(),
    );
    return SessionResultDto.fromJson(response).session;
  }

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
  Future<List<AgentToolDefinitionDto>> listAgentTools() async {
    final response = await _request(
      RpcMethod.agentToolCatalog,
      const <String, dynamic>{},
    );
    return AgentToolCatalogResultDto.fromJson(response).tools;
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
    String apiKey, {
    bool makeDefault = false,
  }) async {
    final response = await _request(
      RpcMethod.providerConnectApiKey,
      ProviderConnectApiKeyParamsDto(
        definitionId: definitionId,
        apiKey: apiKey,
        makeDefault: makeDefault,
      ).toJson(),
    );
    return ProviderConnectionResultDto.fromJson(response).connection;
  }

  @override
  Future<ProviderConnectionDto> connectProviderNone(
    String definitionId, {
    bool makeDefault = false,
  }) async {
    final response = await _request(
      RpcMethod.providerConnectNone,
      ProviderConnectNoneParamsDto(
        definitionId: definitionId,
        makeDefault: makeDefault,
      ).toJson(),
    );
    return ProviderConnectionResultDto.fromJson(response).connection;
  }

  @override
  Future<ProviderAuthAttemptDto> startProviderAuth(
    String definitionId,
    String methodId, {
    bool makeDefault = false,
  }) async {
    final response = await _request(
      RpcMethod.providerAuthStart,
      ProviderAuthStartParamsDto(
        definitionId: definitionId,
        methodId: methodId,
        makeDefault: makeDefault,
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
  Future<void> setDefaultProvider(String connectionId) async {
    await _request(
      RpcMethod.providerDefaultSet,
      ProviderDefaultSetParamsDto(connectionId: connectionId).toJson(),
    );
  }

  @override
  Future<void> setDefaultProviderModel(
    String connectionId,
    String modelId,
  ) async {
    await _request(
      RpcMethod.providerDefaultModelSet,
      ProviderDefaultModelSetParamsDto(
        connectionId: connectionId,
        modelId: modelId,
      ).toJson(),
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
    bool makeDefault = false,
  }) async {
    final response = await _request(
      RpcMethod.providerCustomCreate,
      ProviderCustomCreateParamsDto(
        id: id,
        config: config,
        makeDefault: makeDefault,
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
  }) async {
    await _request(
      RpcMethod.turnStart,
      TurnStartParamsDto(
        sessionId: sessionId,
        turnId: turnId,
        prompt: prompt,
      ).toJson(),
    );
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
