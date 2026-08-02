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
    required this._clientId,
    required this._clientKind,
    required this._connector,
    required this._requestTimeout,
    required this._reconnectDelay,
  });

  /// The connect public API member.
  static Future<CoderClient> connect({
    required HostEndpoint endpoint,
    required String clientId,
    required String clientKind,
    WebSocketConnector connector = const IoWebSocketConnector(),
    Duration requestTimeout = const Duration(seconds: 60),
    Duration Function(int attempt)? reconnectDelay,
  }) async {
    final client = CoderClient._(
      endpoint: endpoint,
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
        headers: <String, String>{'Authorization': 'Bearer ${_endpoint.token}'},
      );
      final peer = json_rpc.Peer(channel.cast<String>());
      _peer = peer;
      for (final type in <String>[
        RpcNotification.timelineEvent,
        RpcNotification.agentUpdated,
        RpcNotification.approvalRequested,
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
          final current = _timelineSubscriptions[event.agentId] ?? 0;
          if (event.sequence <= current) return;
          _timelineSubscriptions[event.agentId] = event.sequence;
          _events.add(TimelineClientEvent(event));
        case RpcNotification.agentUpdated:
          _events.add(AgentUpdatedClientEvent(AgentDto.fromJson(parameters)));
        case RpcNotification.approvalRequested:
          _events.add(
            ApprovalRequestedClientEvent(
              ApprovalRequestDto.fromJson(parameters),
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
  Future<List<WorkspaceDto>> listWorkspaces() async {
    final response = await _request(
      RpcMethod.workspaceList,
      const <String, dynamic>{},
    );
    return WorkspaceListResultDto.fromJson(response).workspaces;
  }

  @override
  Future<WorkspaceDto> registerWorkspace({
    required String id,
    required String rootPath,
    required String name,
  }) async {
    final response = await _request(
      RpcMethod.workspaceRegister,
      WorkspaceRegisterParamsDto(
        id: id,
        rootPath: rootPath,
        name: name,
      ).toJson(),
    );
    return WorkspaceResultDto.fromJson(response).workspace;
  }

  @override
  Future<List<AgentDto>> listAgents({String? workspaceId}) async {
    final response = await _request(
      RpcMethod.agentList,
      AgentListParamsDto(workspaceId: workspaceId).toJson(),
    );
    return AgentListResultDto.fromJson(response).agents;
  }

  @override
  Future<AgentDto> createAgent({
    required String id,
    required String workspaceId,
    required String title,
    required String providerId,
    required String model,
    required PermissionMode permissionMode,
    String reasoningEffort = 'medium',
  }) async {
    final response = await _request(
      RpcMethod.agentCreate,
      AgentCreateParamsDto(
        id: id,
        workspaceId: workspaceId,
        title: title,
        providerId: providerId,
        model: model,
        reasoningEffort: reasoningEffort,
        permissionMode: permissionMode,
      ).toJson(),
    );
    return AgentResultDto.fromJson(response).agent;
  }

  @override
  Future<AgentDto> updateAgentConfiguration({
    required String agentId,
    required String providerId,
    required String model,
    String reasoningEffort = 'medium',
  }) async {
    final response = await _request(
      RpcMethod.agentConfigurationUpdate,
      AgentConfigurationUpdateParamsDto(
        agentId: agentId,
        providerId: providerId,
        model: model,
        reasoningEffort: reasoningEffort,
      ).toJson(),
    );
    return AgentResultDto.fromJson(response).agent;
  }

  @override
  Future<ProviderCatalogDto> listProviderCatalog() async {
    final response = await _request(
      RpcMethod.providerList,
      const <String, dynamic>{},
    );
    return ProviderCatalogResultDto.fromJson(response).catalog;
  }

  @override
  Future<ApiProviderDto> upsertProvider(
    ApiProviderDto provider, {
    bool makeDefault = false,
  }) async {
    final response = await _request(
      RpcMethod.providerUpsert,
      ProviderUpsertParamsDto(
        provider: provider,
        makeDefault: makeDefault,
      ).toJson(),
    );
    return ProviderResultDto.fromJson(response).provider;
  }

  @override
  Future<void> deleteProvider(String providerId) async {
    await _request(
      RpcMethod.providerDelete,
      ProviderIdParamsDto(providerId: providerId).toJson(),
    );
  }

  @override
  Future<List<ProviderModelDto>> listProviderModels(String providerId) async {
    final response = await _request(
      RpcMethod.providerModelsList,
      ProviderIdParamsDto(providerId: providerId).toJson(),
    );
    return _providerModels(response);
  }

  @override
  Future<List<ProviderModelDto>> refreshProviderModels(
    String providerId,
  ) async {
    final response = await _request(
      RpcMethod.providerModelsRefresh,
      ProviderIdParamsDto(providerId: providerId).toJson(),
    );
    return _providerModels(response);
  }

  List<ProviderModelDto> _providerModels(Map<String, dynamic> response) =>
      ProviderModelsResultDto.fromJson(response).models;

  @override
  Future<ProviderModelDto> upsertProviderModel(ProviderModelDto model) async {
    final response = await _request(
      RpcMethod.providerModelUpsert,
      ProviderModelUpsertParamsDto(model: model).toJson(),
    );
    return ProviderModelResultDto.fromJson(response).model;
  }

  @override
  Future<void> deleteProviderModel(String providerId, String modelId) async {
    await _request(
      RpcMethod.providerModelDelete,
      ProviderModelParamsDto(providerId: providerId, modelId: modelId).toJson(),
    );
  }

  @override
  Future<ProviderDiagnosticDto> diagnoseProviderModel(
    String providerId,
    String modelId,
  ) async {
    final response = await _request(
      RpcMethod.providerModelDiagnose,
      ProviderModelParamsDto(providerId: providerId, modelId: modelId).toJson(),
    );
    return ProviderDiagnosticResultDto.fromJson(response).diagnostic;
  }

  @override
  Future<void> setProviderCredential(String providerId, String apiKey) async {
    await _request(
      RpcMethod.providerCredentialSet,
      ProviderCredentialSetParamsDto(
        providerId: providerId,
        apiKey: apiKey,
      ).toJson(),
    );
  }

  @override
  Future<void> clearProviderCredential(String providerId) async {
    await _request(
      RpcMethod.providerCredentialClear,
      ProviderIdParamsDto(providerId: providerId).toJson(),
    );
  }

  @override
  Future<void> startTurn({
    required String agentId,
    required String turnId,
    required String prompt,
  }) async {
    await _request(
      RpcMethod.turnStart,
      TurnStartParamsDto(
        agentId: agentId,
        turnId: turnId,
        prompt: prompt,
      ).toJson(),
    );
  }

  @override
  Future<void> cancelTurn(String agentId) async {
    await _request(
      RpcMethod.turnCancel,
      AgentIdParamsDto(agentId: agentId).toJson(),
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
    String agentId, {
    int afterSequence = 0,
  }) async {
    _timelineSubscriptions[agentId] = afterSequence;
    final response = await _request(
      RpcMethod.timelineSubscribe,
      TimelineSubscribeParamsDto(
        agentId: agentId,
        afterSequence: afterSequence,
      ).toJson(),
    );
    final events = TimelineResultDto.fromJson(response).events;
    for (final event in events) {
      final current = _timelineSubscriptions[agentId] ?? 0;
      if (event.sequence > current) {
        _timelineSubscriptions[agentId] = event.sequence;
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
