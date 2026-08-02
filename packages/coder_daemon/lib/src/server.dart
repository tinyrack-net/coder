import 'dart:async';
import 'dart:convert';
import 'dart:io' show HttpConnectionInfo;

import 'package:coder_daemon/src/agent_service.dart';
import 'package:coder_daemon/src/ports.dart';
import 'package:coder_daemon/src/provider_service.dart';
import 'package:coder_daemon/src/repositories.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// DaemonRpcServer defines a public contract.
class DaemonRpcServer {
  /// Creates a [DaemonRpcServer].
  DaemonRpcServer({
    required this.workspaces,
    required this.agentRepository,
    required this.timeline,
    required this.agents,
    required this.providers,
    required this.clock,
    required this.workspaceCanonicalizer,
    required this.serverInfo,
    required this.token,
    required Stream<WireEnvelope> events,
  }) {
    _eventSubscription = events.listen(_broadcast);
  }

  /// The workspaces public API member.
  final WorkspaceRepository workspaces;

  /// The agentRepository public API member.
  final AgentRepository agentRepository;

  /// The timeline public API member.
  final TimelineRepository timeline;

  /// The agents public API member.
  final AgentService agents;

  /// The providers public API member.
  final ProviderService providers;

  /// The clock public API member.
  final Clock clock;

  /// The workspaceCanonicalizer public API member.
  final WorkspaceCanonicalizer workspaceCanonicalizer;

  /// The serverInfo public API member.
  final ServerInfoDto serverInfo;

  /// The token public API member.
  final String token;
  final Set<_ClientSession> _sessions = <_ClientSession>{};
  late final StreamSubscription<WireEnvelope> _eventSubscription;

  /// The call public API member.
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
      workspaces: workspaces,
      agentRepository: agentRepository,
      timeline: timeline,
      agents: agents,
      providers: providers,
      clock: clock,
      workspaceCanonicalizer: workspaceCanonicalizer,
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
      if (event.type == RpcNotification.timelineEvent ||
          event.type == RpcNotification.approvalRequested) {
        final agentId = event.payload['agentId'] as String?;
        if (agentId == null || !session.subscriptions.contains(agentId)) {
          continue;
        }
      }
      session.send(event);
    }
  }

  /// The close public API member.
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
    required this.workspaces,
    required this.agentRepository,
    required this.timeline,
    required this.agents,
    required this.providers,
    required this.clock,
    required this.workspaceCanonicalizer,
    required this.serverInfo,
    required this.localAdmin,
    required this.onClosed,
  });

  final WebSocketChannel channel;
  final WorkspaceRepository workspaces;
  final AgentRepository agentRepository;
  final TimelineRepository timeline;
  final AgentService agents;
  final ProviderService providers;
  final Clock clock;
  final WorkspaceCanonicalizer workspaceCanonicalizer;
  final ServerInfoDto serverInfo;
  final bool localAdmin;
  void Function() onClosed;
  final Set<String> subscriptions = <String>{};
  late final json_rpc.Peer _peer;
  bool _handshakeComplete = false;

  void start() {
    _peer = json_rpc.Peer(channel.cast<String>());
    _peer.registerMethod(RpcMethod.hello, _hello);
    for (final method in <String>[
      RpcMethod.workspaceList,
      RpcMethod.workspaceRegister,
      RpcMethod.agentList,
      RpcMethod.agentCreate,
      RpcMethod.agentConfigurationUpdate,
      RpcMethod.providerList,
      RpcMethod.providerUpsert,
      RpcMethod.providerDelete,
      RpcMethod.providerModelsList,
      RpcMethod.providerModelsRefresh,
      RpcMethod.providerModelUpsert,
      RpcMethod.providerModelDelete,
      RpcMethod.providerModelDiagnose,
      RpcMethod.providerCredentialSet,
      RpcMethod.turnStart,
      RpcMethod.turnCancel,
      RpcMethod.approvalResolve,
      RpcMethod.timelineSubscribe,
    ]) {
      _peer.registerMethod(
        method,
        (json_rpc.Parameters parameters) => _invoke(method, parameters),
      );
    }
    unawaited(_peer.listen().whenComplete(onClosed));
  }

  Future<Map<String, dynamic>> _hello(json_rpc.Parameters parameters) async {
    final payload = HelloParamsDto.fromJson(
      Map<String, dynamic>.from(parameters.asMap),
    );
    if (payload.protocolVersion != coderProtocolVersion) {
      throw json_rpc.RpcException(
        1001,
        'Unsupported protocol version.',
        data: const <String, dynamic>{'code': 'protocol_mismatch'},
      );
    }
    _handshakeComplete = true;
    return serverInfo
        .copyWith(
          features: <String, bool>{
            ...serverInfo.features,
            'providerAdmin': localAdmin,
            'providerCredentialWrite': localAdmin,
            'providerDiagnostics': localAdmin,
            'jsonRpc2': true,
          },
        )
        .toJson();
  }

  Future<Map<String, dynamic>> _invoke(
    String method,
    json_rpc.Parameters parameters,
  ) async {
    if (!_handshakeComplete) {
      throw json_rpc.RpcException(
        1000,
        'Handshake required.',
        data: const <String, dynamic>{'code': 'handshake_required'},
      );
    }
    try {
      return await _dispatch(
        method,
        Map<String, dynamic>.from(parameters.asMap),
      );
    } on _RpcRequestException catch (error) {
      throw json_rpc.RpcException(
        1002,
        error.message,
        data: <String, dynamic>{'code': error.code},
      );
    } catch (error) {
      throw json_rpc.RpcException(
        1003,
        '$error',
        data: const <String, dynamic>{'code': 'request_failed'},
      );
    }
  }

  Future<Map<String, dynamic>> _dispatch(
    String method,
    Map<String, dynamic> payload,
  ) async {
    switch (method) {
      case RpcMethod.workspaceList:
        final items = await workspaces.list();
        return WorkspaceListResultDto(workspaces: items).toJson();
      case RpcMethod.workspaceRegister:
        final request = WorkspaceRegisterParamsDto.fromJson(payload);
        final rootPath = request.rootPath;
        final canonical = workspaceCanonicalizer.canonicalizeExistingDirectory(
          rootPath,
        );
        final workspace = await workspaces.register(
          WorkspaceDto(
            id: request.id,
            name: request.name.trim().isNotEmpty
                ? request.name.trim()
                : p.basename(canonical),
            rootPath: canonical,
            createdAt: clock.nowUtc(),
          ),
        );
        return WorkspaceResultDto(workspace: workspace).toJson();
      case RpcMethod.agentList:
        final request = AgentListParamsDto.fromJson(payload);
        final items = await agentRepository.list(
          workspaceId: request.workspaceId,
        );
        return AgentListResultDto(agents: items).toJson();
      case RpcMethod.agentCreate:
        final request = AgentCreateParamsDto.fromJson(payload);
        final catalog = await providers.catalog();
        final providerId = request.providerId.isEmpty
            ? catalog.defaultProviderId ?? 'openai'
            : request.providerId;
        final configuredProvider = await providers.get(providerId);
        final model = request.model.isEmpty
            ? configuredProvider.defaultModelId ??
                  (throw const FormatException('model is required.'))
            : request.model;
        await providers.validateAgentModel(providerId, model);
        final now = clock.nowUtc();
        final agent = await agentRepository.create(
          AgentDto(
            id: request.id,
            workspaceId: request.workspaceId,
            title: request.title,
            providerId: providerId,
            model: model,
            reasoningEffort: request.reasoningEffort,
            status: AgentStatus.idle,
            permissionMode: request.permissionMode,
            createdAt: now,
            updatedAt: now,
          ),
        );
        return AgentResultDto(agent: agent).toJson();
      case RpcMethod.agentConfigurationUpdate:
        final request = AgentConfigurationUpdateParamsDto.fromJson(payload);
        final providerId = request.providerId;
        final model = request.model;
        await providers.validateAgentModel(providerId, model);
        final agent = await agentRepository.updateConfiguration(
          id: request.agentId,
          providerId: providerId,
          model: model,
          reasoningEffort: request.reasoningEffort,
        );
        return AgentResultDto(agent: agent).toJson();
      case RpcMethod.providerList:
        final catalog = await providers.catalog();
        return ProviderCatalogResultDto(catalog: catalog).toJson();
      case RpcMethod.providerUpsert:
        _requireLocalAdmin();
        final request = ProviderUpsertParamsDto.fromJson(payload);
        final provider = await providers.upsert(
          request.provider,
          makeDefault: request.makeDefault,
        );
        return ProviderResultDto(provider: provider).toJson();
      case RpcMethod.providerDelete:
        _requireLocalAdmin();
        final request = ProviderIdParamsDto.fromJson(payload);
        await providers.delete(request.providerId);
        return const <String, dynamic>{};
      case RpcMethod.providerModelsList:
        final request = ProviderIdParamsDto.fromJson(payload);
        final models = await providers.listModels(request.providerId);
        return ProviderModelsResultDto(models: models).toJson();
      case RpcMethod.providerModelsRefresh:
        _requireLocalAdmin();
        final request = ProviderIdParamsDto.fromJson(payload);
        final models = await providers.refreshModels(request.providerId);
        return ProviderModelsResultDto(models: models).toJson();
      case RpcMethod.providerModelUpsert:
        _requireLocalAdmin();
        final request = ProviderModelUpsertParamsDto.fromJson(payload);
        final model = await providers.upsertManualModel(request.model);
        return ProviderModelResultDto(model: model).toJson();
      case RpcMethod.providerModelDelete:
        _requireLocalAdmin();
        final request = ProviderModelParamsDto.fromJson(payload);
        await providers.deleteModel(request.providerId, request.modelId);
        return const <String, dynamic>{};
      case RpcMethod.providerModelDiagnose:
        _requireLocalAdmin();
        final request = ProviderModelParamsDto.fromJson(payload);
        final diagnostic = await providers.diagnose(
          request.providerId,
          request.modelId,
        );
        return ProviderDiagnosticResultDto(diagnostic: diagnostic).toJson();
      case RpcMethod.providerCredentialSet:
        _requireLocalAdmin();
        final request = ProviderCredentialSetParamsDto.fromJson(payload);
        await providers.setCredential(request.providerId, request.apiKey);
        return const <String, dynamic>{};
      case RpcMethod.providerCredentialClear:
        _requireLocalAdmin();
        final request = ProviderIdParamsDto.fromJson(payload);
        await providers.setCredential(request.providerId, '');
        return const <String, dynamic>{};
      case RpcMethod.turnStart:
        final request = TurnStartParamsDto.fromJson(payload);
        final created = await agents.startTurn(
          agentId: request.agentId,
          turnId: request.turnId,
          prompt: request.prompt,
        );
        return TurnStartResultDto(created: created).toJson();
      case RpcMethod.turnCancel:
        final request = AgentIdParamsDto.fromJson(payload);
        await agents.cancelTurn(request.agentId);
        return const <String, dynamic>{};
      case RpcMethod.approvalResolve:
        final request = ApprovalResolveParamsDto.fromJson(payload);
        final approval = await agents.resolveApproval(
          request.approvalId,
          approved: request.approved,
        );
        return ApprovalResultDto(approval: approval).toJson();
      case RpcMethod.timelineSubscribe:
        final request = TimelineSubscribeParamsDto.fromJson(payload);
        subscriptions.add(request.agentId);
        final items = await timeline.after(
          request.agentId,
          request.afterSequence,
        );
        return TimelineResultDto(events: items).toJson();
      default:
        throw _RpcRequestException(
          'unknown_method',
          'Unknown RPC method: $method',
        );
    }
  }

  void _requireLocalAdmin() {
    if (!localAdmin) {
      throw const _RpcRequestException(
        'local_admin_required',
        'Provider settings can only be changed from the daemon host.',
      );
    }
  }

  void send(WireEnvelope event) =>
      _peer.sendNotification(event.type, event.payload);

  Future<void> close() async {
    await _peer.close();
    onClosed();
  }
}

class _RpcRequestException implements Exception {
  const _RpcRequestException(this.code, this.message);
  final String code;
  final String message;
}
