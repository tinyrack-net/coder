import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:coder_protocol/coder_protocol.dart';
import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'agent_service.dart';
import 'database.dart';
import 'provider_service.dart';

class DaemonRpcServer {
  DaemonRpcServer({
    required this.database,
    required this.agents,
    required this.providers,
    required this.serverInfo,
    required this.token,
    required Stream<WireEnvelope> events,
  }) {
    _eventSubscription = events.listen(_broadcast);
  }

  final CoderDatabase database;
  final AgentService agents;
  final ProviderService providers;
  final ServerInfoDto serverInfo;
  final String token;
  final Set<_ClientSession> _sessions = <_ClientSession>{};
  late final StreamSubscription<WireEnvelope> _eventSubscription;

  FutureOr<Response> call(Request request) {
    if (request.url.path == 'health') {
      return Response.ok(
        jsonEncode(<String, dynamic>{
          'serverId': serverInfo.serverId,
          'version': serverInfo.version,
          'protocolVersion': serverInfo.protocolVersion,
        }),
        headers: <String, String>{'content-type': 'application/json'},
      );
    }
    if (request.url.path != 'ws') return Response.notFound('Not found');
    if (request.headers['authorization'] != 'Bearer $token') {
      return Response.unauthorized('A valid bearer token is required.');
    }
    final connectionInfo = request.context['shelf.io.connection_info'];
    final localAdmin =
        connectionInfo is HttpConnectionInfo &&
        connectionInfo.remoteAddress.isLoopback;
    return webSocketHandler(
      (channel, protocol) =>
          _openSession(channel, protocol, localAdmin: localAdmin),
    )(request);
  }

  void _openSession(
    WebSocketChannel channel,
    String? protocol, {
    required bool localAdmin,
  }) {
    final session = _ClientSession(
      channel: channel,
      database: database,
      agents: agents,
      providers: providers,
      serverInfo: serverInfo,
      localAdmin: localAdmin,
      onClosed: () {},
    );
    session.onClosed = () => _sessions.remove(session);
    _sessions.add(session);
    session.start();
  }

  void _broadcast(WireEnvelope event) {
    for (final session in List<_ClientSession>.of(_sessions)) {
      if (event.type == MessageType.timelineEvent ||
          event.type == MessageType.approvalRequest) {
        final agentId = event.payload['agentId'] as String?;
        if (agentId == null || !session.subscriptions.contains(agentId))
          continue;
      }
      session.send(event);
    }
  }

  Future<void> close() async {
    await _eventSubscription.cancel();
    for (final session in List<_ClientSession>.of(_sessions)) {
      await session.close();
    }
  }
}

class _ClientSession {
  _ClientSession({
    required this.channel,
    required this.database,
    required this.agents,
    required this.providers,
    required this.serverInfo,
    required this.localAdmin,
    required this.onClosed,
  });

  final WebSocketChannel channel;
  final CoderDatabase database;
  final AgentService agents;
  final ProviderService providers;
  final ServerInfoDto serverInfo;
  final bool localAdmin;
  void Function() onClosed;
  final Set<String> subscriptions = <String>{};
  StreamSubscription<dynamic>? _subscription;
  bool _handshakeComplete = false;

  void start() {
    _subscription = channel.stream.listen(
      _message,
      onDone: onClosed,
      onError: (_, __) => onClosed(),
    );
  }

  Future<void> _message(dynamic raw) async {
    if (raw is! String) return;
    String? requestId;
    try {
      final request = WireEnvelope.decode(raw);
      requestId = request.requestId;
      if (!_handshakeComplete) {
        await _handshake(request);
        return;
      }
      await _dispatch(request);
    } on ProtocolException catch (error) {
      _error(requestId, 'invalid_message', error.message);
    } on FormatException catch (error) {
      _error(requestId, 'invalid_payload', error.message);
    } on _RpcRequestException catch (error) {
      _error(requestId, error.code, error.message);
    } catch (error) {
      _error(requestId, 'request_failed', '$error');
    }
  }

  Future<void> _handshake(WireEnvelope request) async {
    if (request.type != MessageType.hello) {
      _error(
        request.requestId,
        'handshake_required',
        'The first message must be hello.',
      );
      await close();
      return;
    }
    if (request.payload['protocolVersion'] != coderProtocolVersion) {
      _error(
        request.requestId,
        'protocol_mismatch',
        'Unsupported protocol version.',
      );
      await close();
      return;
    }
    _handshakeComplete = true;
    send(
      WireEnvelope(
        type: MessageType.serverInfo,
        payload: serverInfo
            .copyWith(
              features: <String, bool>{
                ...serverInfo.features,
                'providerAdmin': localAdmin,
                'providerCredentialWrite': localAdmin,
                'providerDiagnostics': localAdmin,
              },
            )
            .toJson(),
      ),
    );
  }

  Future<void> _dispatch(WireEnvelope request) async {
    final requestId = request.requestId;
    if (requestId == null)
      throw const FormatException('requestId is required.');
    switch (request.type) {
      case MessageType.workspaceListRequest:
        final workspaces = await database.listWorkspaceDtos();
        _response(
          MessageType.workspaceListResponse,
          requestId,
          <String, dynamic>{
            'workspaces': workspaces.map((item) => item.toJson()).toList(),
          },
        );
      case MessageType.workspaceRegisterRequest:
        final rootPath = _requiredString(request.payload, 'rootPath');
        final directory = Directory(rootPath);
        if (!directory.existsSync())
          throw const FormatException('Workspace directory not found.');
        final canonical = directory.resolveSymbolicLinksSync();
        final workspace = await database.registerWorkspace(
          WorkspaceDto(
            id: _requiredString(request.payload, 'id'),
            name:
                (request.payload['name'] as String?)?.trim().isNotEmpty == true
                ? (request.payload['name'] as String).trim()
                : p.basename(canonical),
            rootPath: canonical,
            createdAt: DateTime.now().toUtc(),
          ),
        );
        _response(
          MessageType.workspaceRegisterResponse,
          requestId,
          <String, dynamic>{'workspace': workspace.toJson()},
        );
      case MessageType.agentListRequest:
        final items = await database.listAgentDtos(
          workspaceId: request.payload['workspaceId'] as String?,
        );
        _response(MessageType.agentListResponse, requestId, <String, dynamic>{
          'agents': items.map((item) => item.toJson()).toList(),
        });
      case MessageType.agentCreateRequest:
        final catalog = await providers.catalog();
        final providerId =
            request.payload['providerId'] as String? ??
            catalog.defaultProviderId ??
            'openai';
        final configuredProvider = await providers.get(providerId);
        final model =
            request.payload['model'] as String? ??
            configuredProvider.defaultModelId ??
            (throw const FormatException('model is required.'));
        await providers.validateAgentModel(providerId, model);
        final now = DateTime.now().toUtc();
        final agent = await database.createAgent(
          AgentDto(
            id: _requiredString(request.payload, 'id'),
            workspaceId: _requiredString(request.payload, 'workspaceId'),
            title: _requiredString(request.payload, 'title'),
            providerId: providerId,
            model: model,
            reasoningEffort:
                request.payload['reasoningEffort'] as String? ?? 'medium',
            status: AgentStatus.idle,
            permissionMode: PermissionMode.values.byName(
              (request.payload['permissionMode'] as String?) ??
                  PermissionMode.ask.name,
            ),
            createdAt: now,
            updatedAt: now,
          ),
        );
        _response(MessageType.agentCreateResponse, requestId, <String, dynamic>{
          'agent': agent.toJson(),
        });
      case MessageType.agentConfigurationUpdateRequest:
        final providerId = _requiredString(request.payload, 'providerId');
        final model = _requiredString(request.payload, 'model');
        await providers.validateAgentModel(providerId, model);
        final agent = await database.updateAgentConfiguration(
          id: _requiredString(request.payload, 'agentId'),
          providerId: providerId,
          model: model,
          reasoningEffort:
              request.payload['reasoningEffort'] as String? ?? 'medium',
        );
        _response(
          MessageType.agentConfigurationUpdateResponse,
          requestId,
          <String, dynamic>{'agent': agent.toJson()},
        );
      case MessageType.providerListRequest:
        final catalog = await providers.catalog();
        _response(
          MessageType.providerListResponse,
          requestId,
          <String, dynamic>{'catalog': catalog.toJson()},
        );
      case MessageType.providerUpsertRequest:
        _requireLocalAdmin();
        final raw = request.payload['provider'];
        if (raw is! Map) throw const FormatException('provider is required.');
        final provider = await providers.upsert(
          ApiProviderDto.fromJson(Map<String, dynamic>.from(raw)),
          makeDefault: request.payload['makeDefault'] == true,
        );
        _response(
          MessageType.providerUpsertResponse,
          requestId,
          <String, dynamic>{'provider': provider.toJson()},
        );
      case MessageType.providerDeleteRequest:
        _requireLocalAdmin();
        await providers.delete(_requiredString(request.payload, 'providerId'));
        _response(
          MessageType.providerDeleteResponse,
          requestId,
          const <String, dynamic>{},
        );
      case MessageType.providerModelsListRequest:
        final models = await providers.listModels(
          _requiredString(request.payload, 'providerId'),
        );
        _response(
          MessageType.providerModelsListResponse,
          requestId,
          <String, dynamic>{
            'models': models.map((item) => item.toJson()).toList(),
          },
        );
      case MessageType.providerModelsRefreshRequest:
        _requireLocalAdmin();
        final models = await providers.refreshModels(
          _requiredString(request.payload, 'providerId'),
        );
        _response(
          MessageType.providerModelsRefreshResponse,
          requestId,
          <String, dynamic>{
            'models': models.map((item) => item.toJson()).toList(),
          },
        );
      case MessageType.providerModelUpsertRequest:
        _requireLocalAdmin();
        final raw = request.payload['model'];
        if (raw is! Map) throw const FormatException('model is required.');
        final model = await providers.upsertManualModel(
          ProviderModelDto.fromJson(Map<String, dynamic>.from(raw)),
        );
        _response(
          MessageType.providerModelUpsertResponse,
          requestId,
          <String, dynamic>{'model': model.toJson()},
        );
      case MessageType.providerModelDeleteRequest:
        _requireLocalAdmin();
        await providers.deleteModel(
          _requiredString(request.payload, 'providerId'),
          _requiredString(request.payload, 'modelId'),
        );
        _response(
          MessageType.providerModelDeleteResponse,
          requestId,
          const <String, dynamic>{},
        );
      case MessageType.providerModelDiagnoseRequest:
        _requireLocalAdmin();
        final diagnostic = await providers.diagnose(
          _requiredString(request.payload, 'providerId'),
          _requiredString(request.payload, 'modelId'),
        );
        _response(
          MessageType.providerModelDiagnoseResponse,
          requestId,
          <String, dynamic>{'diagnostic': diagnostic.toJson()},
        );
      case MessageType.providerCredentialSetRequest:
        _requireLocalAdmin();
        await providers.setCredential(
          _requiredString(request.payload, 'providerId'),
          _requiredString(request.payload, 'apiKey'),
        );
        _response(
          MessageType.providerCredentialSetResponse,
          requestId,
          const <String, dynamic>{},
        );
      case MessageType.providerCredentialClearRequest:
        _requireLocalAdmin();
        await providers.setCredential(
          _requiredString(request.payload, 'providerId'),
          '',
        );
        _response(
          MessageType.providerCredentialClearResponse,
          requestId,
          const <String, dynamic>{},
        );
      case MessageType.turnStartRequest:
        final created = await agents.startTurn(
          agentId: _requiredString(request.payload, 'agentId'),
          turnId: _requiredString(request.payload, 'turnId'),
          prompt: _requiredString(request.payload, 'prompt'),
        );
        _response(MessageType.turnStartResponse, requestId, <String, dynamic>{
          'created': created,
        });
      case MessageType.turnCancelRequest:
        await agents.cancelTurn(_requiredString(request.payload, 'agentId'));
        _response(
          MessageType.turnCancelResponse,
          requestId,
          const <String, dynamic>{},
        );
      case MessageType.approvalResolveRequest:
        final approval = await agents.resolveApproval(
          _requiredString(request.payload, 'approvalId'),
          approved: request.payload['approved'] == true,
        );
        _response(
          MessageType.approvalResolveResponse,
          requestId,
          <String, dynamic>{'approval': approval.toJson()},
        );
      case MessageType.timelineSubscribeRequest:
        final agentId = _requiredString(request.payload, 'agentId');
        final after = request.payload['afterSequence'] as int? ?? 0;
        subscriptions.add(agentId);
        final items = await database.timelineAfter(agentId, after);
        _response(
          MessageType.timelineSubscribeResponse,
          requestId,
          <String, dynamic>{
            'events': items.map((item) => item.toJson()).toList(),
          },
        );
      default:
        _error(
          requestId,
          'unknown_method',
          'Unknown RPC method: ${request.type}',
        );
    }
  }

  String _requiredString(Map<String, dynamic> payload, String key) {
    final value = payload[key];
    if (value is! String || value.trim().isEmpty)
      throw FormatException('$key is required.');
    return value;
  }

  void _requireLocalAdmin() {
    if (!localAdmin) {
      throw const _RpcRequestException(
        'local_admin_required',
        'Provider settings can only be changed from the daemon host.',
      );
    }
  }

  void _response(String type, String requestId, Map<String, dynamic> payload) =>
      send(WireEnvelope(type: type, requestId: requestId, payload: payload));

  void _error(String? requestId, String code, String message) => send(
    WireEnvelope(
      type: MessageType.rpcError,
      requestId: requestId,
      payload: RpcErrorDto(
        code: code,
        message: message,
        retryable: false,
      ).toJson(),
    ),
  );

  void send(WireEnvelope event) => channel.sink.add(event.encode());

  Future<void> close() async {
    await _subscription?.cancel();
    await channel.sink.close();
    onClosed();
  }
}

class _RpcRequestException implements Exception {
  const _RpcRequestException(this.code, this.message);
  final String code;
  final String message;
}
