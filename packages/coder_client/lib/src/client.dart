import 'dart:async';

import 'package:coder_protocol/coder_protocol.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'endpoint.dart';

enum ClientConnectionState { connecting, connected, reconnecting, disconnected }

class CoderClientException implements Exception {
  const CoderClientException(this.message, {this.code, this.retryable = false});

  final String message;
  final String? code;
  final bool retryable;

  @override
  String toString() =>
      'CoderClientException${code == null ? '' : '($code)'}: $message';
}

class CoderClient {
  CoderClient._({
    required HostEndpoint endpoint,
    required String clientId,
    required String clientKind,
  }) : _endpoint = endpoint,
       _clientId = clientId,
       _clientKind = clientKind;

  static Future<CoderClient> connect({
    required HostEndpoint endpoint,
    required String clientId,
    required String clientKind,
  }) async {
    final client = CoderClient._(
      endpoint: endpoint,
      clientId: clientId,
      clientKind: clientKind,
    );
    await client._open(initial: true);
    return client;
  }

  final HostEndpoint _endpoint;
  final String _clientId;
  final String _clientKind;
  final Uuid _uuid = const Uuid();
  final Map<String, Completer<WireEnvelope>> _pending =
      <String, Completer<WireEnvelope>>{};
  final StreamController<WireEnvelope> _events =
      StreamController<WireEnvelope>.broadcast();
  final StreamController<ClientConnectionState> _states =
      StreamController<ClientConnectionState>.broadcast();
  final Map<String, int> _timelineSubscriptions = <String, int>{};
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _socketSubscription;
  ServerInfoDto? _serverInfo;
  Completer<ServerInfoDto>? _serverInfoCompleter;
  bool _closed = false;
  bool _connecting = false;
  int _reconnectAttempt = 0;

  Stream<WireEnvelope> get events => _events.stream;
  Stream<ClientConnectionState> get states => _states.stream;
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
    final handshake = Completer<ServerInfoDto>();
    _serverInfoCompleter = handshake;
    try {
      final channel = IOWebSocketChannel.connect(
        _endpoint.websocketUri,
        headers: <String, String>{'Authorization': 'Bearer ${_endpoint.token}'},
        connectTimeout: const Duration(seconds: 10),
        pingInterval: const Duration(seconds: 10),
      );
      _channel = channel;
      await channel.ready;
      _socketSubscription = channel.stream.listen(
        _handleMessage,
        onError: _handleSocketError,
        onDone: _handleSocketDone,
        cancelOnError: false,
      );
      _send(
        WireEnvelope(
          type: MessageType.hello,
          payload: <String, dynamic>{
            'clientId': _clientId,
            'clientKind': _clientKind,
            'protocolVersion': coderProtocolVersion,
            'capabilities': <String, dynamic>{'timelineCatchup': true},
          },
        ),
      );
      _serverInfo = await handshake.future.timeout(const Duration(seconds: 10));
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
              _events.add(
                WireEnvelope(
                  type: MessageType.timelineEvent,
                  payload: event.toJson(),
                ),
              );
            }
          }),
        );
      }
    } catch (error) {
      await _socketSubscription?.cancel();
      _channel = null;
      if (initial) rethrow;
      _scheduleReconnect();
    } finally {
      _connecting = false;
    }
  }

  void _handleMessage(dynamic raw) {
    if (raw is! String) return;
    try {
      final envelope = WireEnvelope.decode(raw);
      if (envelope.type == MessageType.serverInfo) {
        final info = ServerInfoDto.fromJson(envelope.payload);
        _serverInfoCompleter?.complete(info);
        return;
      }
      if (envelope.type == MessageType.rpcError && envelope.requestId != null) {
        final error = RpcErrorDto.fromJson(envelope.payload);
        _pending
            .remove(envelope.requestId)
            ?.completeError(
              CoderClientException(
                error.message,
                code: error.code,
                retryable: error.retryable,
              ),
            );
        return;
      }
      if (envelope.requestId case final requestId?) {
        final pending = _pending.remove(requestId);
        if (pending != null) {
          pending.complete(envelope);
          return;
        }
      }
      if (envelope.type == MessageType.timelineEvent) {
        final event = TimelineEventDto.fromJson(envelope.payload);
        final current = _timelineSubscriptions[event.agentId] ?? 0;
        if (event.sequence <= current) return;
        _timelineSubscriptions[event.agentId] = event.sequence;
      }
      _events.add(envelope);
    } catch (error, stackTrace) {
      _events.addError(error, stackTrace);
    }
  }

  void _handleSocketError(Object error, StackTrace stackTrace) {
    _failPending(
      CoderClientException('Connection lost: $error', retryable: true),
    );
  }

  void _handleSocketDone() {
    if (_closed) return;
    _states.add(ClientConnectionState.disconnected);
    _failPending(
      const CoderClientException('Connection closed.', retryable: true),
    );
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_closed || _connecting) return;
    _reconnectAttempt += 1;
    final seconds = (1 << (_reconnectAttempt - 1).clamp(0, 5));
    Timer(Duration(seconds: seconds), () => unawaited(_open(initial: false)));
  }

  void _failPending(Object error) {
    for (final completer in _pending.values) {
      if (!completer.isCompleted) completer.completeError(error);
    }
    _pending.clear();
  }

  void _send(WireEnvelope envelope) {
    final channel = _channel;
    if (channel == null)
      throw const CoderClientException('Not connected.', retryable: true);
    channel.sink.add(envelope.encode());
  }

  Future<WireEnvelope> _request(
    String type,
    Map<String, dynamic> payload,
  ) async {
    final requestId = _uuid.v4();
    final completer = Completer<WireEnvelope>();
    _pending[requestId] = completer;
    try {
      _send(WireEnvelope(type: type, requestId: requestId, payload: payload));
      return await completer.future.timeout(const Duration(seconds: 60));
    } finally {
      _pending.remove(requestId);
    }
  }

  Future<List<WorkspaceDto>> listWorkspaces() async {
    final response = await _request(
      MessageType.workspaceListRequest,
      const <String, dynamic>{},
    );
    return (response.payload['workspaces'] as List? ?? const <dynamic>[])
        .whereType<Map>()
        .map((item) => WorkspaceDto.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  Future<WorkspaceDto> registerWorkspace({
    required String id,
    required String rootPath,
    required String name,
  }) async {
    final response = await _request(
      MessageType.workspaceRegisterRequest,
      <String, dynamic>{'id': id, 'rootPath': rootPath, 'name': name},
    );
    return WorkspaceDto.fromJson(
      response.payload['workspace'] as Map<String, dynamic>,
    );
  }

  Future<List<AgentDto>> listAgents({String? workspaceId}) async {
    final response = await _request(
      MessageType.agentListRequest,
      <String, dynamic>{if (workspaceId != null) 'workspaceId': workspaceId},
    );
    return (response.payload['agents'] as List? ?? const <dynamic>[])
        .whereType<Map>()
        .map((item) => AgentDto.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  Future<AgentDto> createAgent({
    required String id,
    required String workspaceId,
    required String title,
    required String providerId,
    required String model,
    String reasoningEffort = 'medium',
    required PermissionMode permissionMode,
  }) async {
    final response =
        await _request(MessageType.agentCreateRequest, <String, dynamic>{
          'id': id,
          'workspaceId': workspaceId,
          'title': title,
          'providerId': providerId,
          'model': model,
          'reasoningEffort': reasoningEffort,
          'permissionMode': permissionMode.name,
        });
    return AgentDto.fromJson(response.payload['agent'] as Map<String, dynamic>);
  }

  Future<AgentDto> updateAgentConfiguration({
    required String agentId,
    required String providerId,
    required String model,
    String reasoningEffort = 'medium',
  }) async {
    final response = await _request(
      MessageType.agentConfigurationUpdateRequest,
      <String, dynamic>{
        'agentId': agentId,
        'providerId': providerId,
        'model': model,
        'reasoningEffort': reasoningEffort,
      },
    );
    return AgentDto.fromJson(response.payload['agent'] as Map<String, dynamic>);
  }

  Future<ProviderCatalogDto> listProviderCatalog() async {
    final response = await _request(
      MessageType.providerListRequest,
      const <String, dynamic>{},
    );
    return ProviderCatalogDto.fromJson(
      Map<String, dynamic>.from(response.payload['catalog'] as Map),
    );
  }

  Future<ApiProviderDto> upsertProvider(
    ApiProviderDto provider, {
    bool makeDefault = false,
  }) async {
    final response = await _request(
      MessageType.providerUpsertRequest,
      <String, dynamic>{
        'provider': provider.toJson(),
        'makeDefault': makeDefault,
      },
    );
    return ApiProviderDto.fromJson(
      Map<String, dynamic>.from(response.payload['provider'] as Map),
    );
  }

  Future<void> deleteProvider(String providerId) async {
    await _request(MessageType.providerDeleteRequest, <String, dynamic>{
      'providerId': providerId,
    });
  }

  Future<List<ProviderModelDto>> listProviderModels(String providerId) async {
    final response = await _request(
      MessageType.providerModelsListRequest,
      <String, dynamic>{'providerId': providerId},
    );
    return _providerModels(response);
  }

  Future<List<ProviderModelDto>> refreshProviderModels(
    String providerId,
  ) async {
    final response = await _request(
      MessageType.providerModelsRefreshRequest,
      <String, dynamic>{'providerId': providerId},
    );
    return _providerModels(response);
  }

  List<ProviderModelDto> _providerModels(WireEnvelope response) =>
      (response.payload['models'] as List? ?? const <dynamic>[])
          .whereType<Map>()
          .map(
            (item) =>
                ProviderModelDto.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false);

  Future<ProviderModelDto> upsertProviderModel(ProviderModelDto model) async {
    final response = await _request(
      MessageType.providerModelUpsertRequest,
      <String, dynamic>{'model': model.toJson()},
    );
    return ProviderModelDto.fromJson(
      Map<String, dynamic>.from(response.payload['model'] as Map),
    );
  }

  Future<void> deleteProviderModel(String providerId, String modelId) async {
    await _request(MessageType.providerModelDeleteRequest, <String, dynamic>{
      'providerId': providerId,
      'modelId': modelId,
    });
  }

  Future<ProviderDiagnosticDto> diagnoseProviderModel(
    String providerId,
    String modelId,
  ) async {
    final response = await _request(
      MessageType.providerModelDiagnoseRequest,
      <String, dynamic>{'providerId': providerId, 'modelId': modelId},
    );
    return ProviderDiagnosticDto.fromJson(
      Map<String, dynamic>.from(response.payload['diagnostic'] as Map),
    );
  }

  Future<void> setProviderCredential(String providerId, String apiKey) async {
    await _request(MessageType.providerCredentialSetRequest, <String, dynamic>{
      'providerId': providerId,
      'apiKey': apiKey,
    });
  }

  Future<void> clearProviderCredential(String providerId) async {
    await _request(
      MessageType.providerCredentialClearRequest,
      <String, dynamic>{'providerId': providerId},
    );
  }

  Future<void> startTurn({
    required String agentId,
    required String turnId,
    required String prompt,
  }) async {
    await _request(MessageType.turnStartRequest, <String, dynamic>{
      'agentId': agentId,
      'turnId': turnId,
      'prompt': prompt,
    });
  }

  Future<void> cancelTurn(String agentId) async {
    await _request(MessageType.turnCancelRequest, <String, dynamic>{
      'agentId': agentId,
    });
  }

  Future<void> resolveApproval({
    required String approvalId,
    required bool approved,
  }) async {
    await _request(MessageType.approvalResolveRequest, <String, dynamic>{
      'approvalId': approvalId,
      'approved': approved,
    });
  }

  Future<List<TimelineEventDto>> subscribeTimeline(
    String agentId, {
    int afterSequence = 0,
  }) async {
    _timelineSubscriptions[agentId] = afterSequence;
    final response = await _request(
      MessageType.timelineSubscribeRequest,
      <String, dynamic>{'agentId': agentId, 'afterSequence': afterSequence},
    );
    final events = (response.payload['events'] as List? ?? const <dynamic>[])
        .whereType<Map>()
        .map(
          (item) => TimelineEventDto.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList(growable: false);
    for (final event in events) {
      final current = _timelineSubscriptions[agentId] ?? 0;
      if (event.sequence > current)
        _timelineSubscriptions[agentId] = event.sequence;
    }
    return events;
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _states.add(ClientConnectionState.disconnected);
    _failPending(const CoderClientException('Client closed.'));
    await _socketSubscription?.cancel();
    await _channel?.sink.close();
    await _events.close();
    await _states.close();
  }
}
