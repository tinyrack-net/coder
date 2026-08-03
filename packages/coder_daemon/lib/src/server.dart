import 'dart:async';
import 'dart:convert';

import 'package:coder_daemon/src/agent_definitions.dart';
import 'package:coder_daemon/src/agent_service.dart';
import 'package:coder_daemon/src/ports.dart';
import 'package:coder_daemon/src/provider_auth.dart';
import 'package:coder_daemon/src/provider_service.dart';
import 'package:coder_daemon/src/repositories.dart';
import 'package:coder_daemon/src/workspace_service.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:shelf/shelf.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// DaemonRpcServer defines a public contract.
class DaemonRpcServer {
  /// Creates a [DaemonRpcServer].
  DaemonRpcServer({
    required this.workspaces,
    required this.sessionRepository,
    required this.timeline,
    required this.agents,
    required this.agentDefinitions,
    required this.providers,
    required this.providerAuth,
    required this.clock,
    required this.serverInfo,
    required this.token,
    required this.adminToken,
    required Stream<WireEnvelope> events,
  }) {
    _eventSubscription = events.listen(_broadcast);
    _authSubscription = providerAuth.events.listen(
      (attempt) => _broadcast(
        WireEnvelope(
          type: RpcNotification.providerAuthUpdated,
          payload: attempt.toJson(),
        ),
      ),
    );
    _agentDefinitionSubscription = agentDefinitions.changes.listen(
      (_) => _broadcast(
        const WireEnvelope(
          type: RpcNotification.agentDefinitionsChanged,
          payload: <String, dynamic>{},
        ),
      ),
    );
  }

  /// The workspaces public API member.
  final WorkspaceService workspaces;

  /// The sessionRepository public API member.
  final SessionRepository sessionRepository;

  /// The timeline public API member.
  final TimelineRepository timeline;

  /// The agents public API member.
  final SessionService agents;

  /// Markdown-backed agent definition application service.
  final AgentDefinitionService agentDefinitions;

  /// The providers public API member.
  final ProviderService providers;

  /// Transient provider authorization coordinator.
  final ProviderAuthCoordinator providerAuth;

  /// The clock public API member.
  final Clock clock;

  /// The serverInfo public API member.
  final ServerInfoDto serverInfo;

  /// The token public API member.
  final String token;

  /// Secret required for local provider-administration capabilities.
  final String adminToken;
  final Set<_ClientSession> _sessions = <_ClientSession>{};
  late final StreamSubscription<WireEnvelope> _eventSubscription;
  late final StreamSubscription<ProviderAuthAttemptDto> _authSubscription;
  late final StreamSubscription<void> _agentDefinitionSubscription;

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
    final localAdmin = _constantTimeEquals(
      request.headers['x-tinyrack-coder-admin'],
      adminToken,
    );
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
      sessionRepository: sessionRepository,
      timeline: timeline,
      agents: agents,
      agentDefinitions: agentDefinitions,
      providers: providers,
      providerAuth: providerAuth,
      clock: clock,
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
        final sessionId = event.payload['sessionId'] as String?;
        if (sessionId == null || !session.subscriptions.contains(sessionId)) {
          continue;
        }
      }
      session.send(event);
    }
  }

  /// The close public API member.
  Future<void> close() async {
    await _eventSubscription.cancel();
    await _authSubscription.cancel();
    await _agentDefinitionSubscription.cancel();
    await providerAuth.close();
    for (final session in List<_ClientSession>.of(_sessions)) {
      await session.close();
    }
  }
}

bool _constantTimeEquals(String? candidate, String expected) {
  if (candidate == null) return false;
  final candidateBytes = utf8.encode(candidate);
  final expectedBytes = utf8.encode(expected);
  var difference = candidateBytes.length ^ expectedBytes.length;
  final length = candidateBytes.length > expectedBytes.length
      ? candidateBytes.length
      : expectedBytes.length;
  for (var index = 0; index < length; index += 1) {
    final left = index < candidateBytes.length ? candidateBytes[index] : 0;
    final right = index < expectedBytes.length ? expectedBytes[index] : 0;
    difference |= left ^ right;
  }
  return difference == 0;
}

class _ClientSession {
  _ClientSession({
    required this.channel,
    required this.workspaces,
    required this.sessionRepository,
    required this.timeline,
    required this.agents,
    required this.agentDefinitions,
    required this.providers,
    required this.providerAuth,
    required this.clock,
    required this.serverInfo,
    required this.localAdmin,
    required this.onClosed,
  });

  final WebSocketChannel channel;
  final WorkspaceService workspaces;
  final SessionRepository sessionRepository;
  final TimelineRepository timeline;
  final SessionService agents;
  final AgentDefinitionService agentDefinitions;
  final ProviderService providers;
  final ProviderAuthCoordinator providerAuth;
  final Clock clock;
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
      RpcMethod.workspaceCatalog,
      RpcMethod.workspaceRegister,
      RpcMethod.workspaceRefresh,
      RpcMethod.workspaceUnregister,
      RpcMethod.directorySuggest,
      RpcMethod.gitBranchesList,
      RpcMethod.worktreeCreate,
      RpcMethod.worktreeArchivePreview,
      RpcMethod.worktreeArchive,
      RpcMethod.agentDefinitionList,
      RpcMethod.agentDefinitionGet,
      RpcMethod.agentDefinitionCreate,
      RpcMethod.agentDefinitionUpdate,
      RpcMethod.agentDefinitionArchive,
      RpcMethod.agentDefinitionReset,
      RpcMethod.agentDefinitionValidate,
      RpcMethod.agentToolCatalog,
      RpcMethod.sessionList,
      RpcMethod.sessionCreate,
      RpcMethod.providerCatalog,
      RpcMethod.providerConnectionsList,
      RpcMethod.providerConnectApiKey,
      RpcMethod.providerConnectNone,
      RpcMethod.providerAuthStart,
      RpcMethod.providerAuthStatus,
      RpcMethod.providerAuthCancel,
      RpcMethod.providerDisconnect,
      RpcMethod.providerDefaultSet,
      RpcMethod.providerDefaultModelSet,
      RpcMethod.providerCatalogRefresh,
      RpcMethod.providerModelsList,
      RpcMethod.providerCustomCreate,
      RpcMethod.providerCustomUpdate,
      RpcMethod.providerCustomDelete,
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
            'agentDefinitionAdmin': localAdmin,
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
    } on ProviderConnectionFailure catch (error) {
      throw json_rpc.RpcException(
        1002,
        error.message,
        data: <String, dynamic>{'code': error.code},
      );
    } on AgentFileConflict catch (error) {
      throw json_rpc.RpcException(
        1002,
        'Agent file changed outside Coder.',
        data: <String, dynamic>{
          'code': 'agent_file_conflict',
          'currentContentHash': error.currentContentHash,
        },
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
      case RpcMethod.workspaceCatalog:
        return WorkspaceCatalogResultDto(
          catalog: await workspaces.catalog(),
        ).toJson();
      case RpcMethod.workspaceRegister:
        final request = WorkspaceRegisterParamsDto.fromJson(payload);
        return (await workspaces.register(request)).toJson();
      case RpcMethod.workspaceRefresh:
        final request = WorkspaceIdParamsDto.fromJson(payload);
        return WorkspaceCatalogResultDto(
          catalog: await workspaces.refresh(request.workspaceId),
        ).toJson();
      case RpcMethod.workspaceUnregister:
        final request = WorkspaceIdParamsDto.fromJson(payload);
        await workspaces.unregister(request.workspaceId);
        return const WorkspaceUnregisterResultDto(
          unregistered: true,
        ).toJson();
      case RpcMethod.directorySuggest:
        final request = DirectorySuggestParamsDto.fromJson(payload);
        return DirectorySuggestResultDto(
          suggestions: await workspaces.suggestDirectories(
            request.query,
            request.limit,
          ),
        ).toJson();
      case RpcMethod.gitBranchesList:
        final request = GitBranchesListParamsDto.fromJson(payload);
        return GitBranchesListResultDto(
          branches: await workspaces.listBranches(request.workspaceId),
        ).toJson();
      case RpcMethod.worktreeCreate:
        final request = WorktreeCreateParamsDto.fromJson(payload);
        return WorktreeResultDto(
          worktree: await workspaces.createWorktree(request),
        ).toJson();
      case RpcMethod.worktreeArchivePreview:
        final request = WorktreeIdParamsDto.fromJson(payload);
        return WorktreeArchivePreviewResultDto(
          preview: await workspaces.previewArchive(request.worktreeId),
        ).toJson();
      case RpcMethod.worktreeArchive:
        final request = WorktreeArchiveParamsDto.fromJson(payload);
        return WorktreeResultDto(
          worktree: await workspaces.archive(
            request.worktreeId,
            force: request.force,
          ),
        ).toJson();
      case RpcMethod.agentDefinitionList:
        return AgentDefinitionListResultDto(
          definitions: await agentDefinitions.list(),
        ).toJson();
      case RpcMethod.agentDefinitionGet:
        final request = AgentDefinitionIdParamsDto.fromJson(payload);
        return AgentDefinitionResultDto(
          definition: await agentDefinitions.get(request.id),
        ).toJson();
      case RpcMethod.agentDefinitionCreate:
        _requireLocalAdmin();
        final request = AgentDefinitionCreateParamsDto.fromJson(payload);
        return AgentDefinitionResultDto(
          definition: await agentDefinitions.create(
            request.id,
            request.definition,
          ),
        ).toJson();
      case RpcMethod.agentDefinitionUpdate:
        _requireLocalAdmin();
        final request = AgentDefinitionUpdateParamsDto.fromJson(payload);
        return AgentDefinitionResultDto(
          definition: await agentDefinitions.update(
            request.definition,
            expectedContentHash: request.expectedContentHash,
            force: request.force,
          ),
        ).toJson();
      case RpcMethod.agentDefinitionArchive:
        _requireLocalAdmin();
        final request = AgentDefinitionIdParamsDto.fromJson(payload);
        await agentDefinitions.archive(request.id);
        return const <String, dynamic>{};
      case RpcMethod.agentDefinitionReset:
        _requireLocalAdmin();
        final request = AgentDefinitionIdParamsDto.fromJson(payload);
        return AgentDefinitionResultDto(
          definition: await agentDefinitions.reset(request.id),
        ).toJson();
      case RpcMethod.agentDefinitionValidate:
        final request = AgentDefinitionValidateParamsDto.fromJson(payload);
        return AgentDefinitionResultDto(
          definition: await agentDefinitions.validate(
            request.id,
            request.markdown,
          ),
        ).toJson();
      case RpcMethod.agentToolCatalog:
        return AgentToolCatalogResultDto(
          tools: agentDefinitions.toolCatalog(),
        ).toJson();
      case RpcMethod.sessionList:
        final request = SessionListParamsDto.fromJson(payload);
        final items = await sessionRepository.list(
          worktreeId: request.worktreeId,
        );
        return SessionListResultDto(sessions: items).toJson();
      case RpcMethod.sessionCreate:
        final request = SessionCreateParamsDto.fromJson(payload);
        final definition = await agentDefinitions.get(
          request.agentDefinitionId,
        );
        if (definition.mode != AgentMode.primary ||
            definition.isArchived ||
            definition.isStale) {
          throw const FormatException(
            'New sessions require an active primary agent definition.',
          );
        }
        await providers.resolveAgentModel(definition.model);
        final now = clock.nowUtc();
        final session = await sessionRepository.create(
          SessionDto(
            id: request.id,
            worktreeId: request.worktreeId,
            title: request.title,
            agentDefinitionId: definition.id,
            origin: SessionOrigin.manual,
            status: SessionStatus.idle,
            createdAt: now,
            updatedAt: now,
          ),
        );
        return SessionResultDto(session: session).toJson();
      case RpcMethod.providerCatalog:
        final catalog = await providers.catalog();
        return ProviderCatalogResultDto(catalog: catalog).toJson();
      case RpcMethod.providerConnectionsList:
        final connections = await providers.connections();
        return ProviderConnectionsResultDto(connections: connections).toJson();
      case RpcMethod.providerConnectApiKey:
        _requireLocalAdmin();
        final request = ProviderConnectApiKeyParamsDto.fromJson(payload);
        final connection = await providers.connectApiKey(
          request.definitionId,
          request.apiKey,
          makeDefault: request.makeDefault,
        );
        return ProviderConnectionResultDto(connection: connection).toJson();
      case RpcMethod.providerConnectNone:
        _requireLocalAdmin();
        final request = ProviderConnectNoneParamsDto.fromJson(payload);
        final connection = await providers.connectNone(
          request.definitionId,
          makeDefault: request.makeDefault,
        );
        return ProviderConnectionResultDto(connection: connection).toJson();
      case RpcMethod.providerAuthStart:
        _requireLocalAdmin();
        final request = ProviderAuthStartParamsDto.fromJson(payload);
        final attempt = await providerAuth.start(
          definitionId: request.definitionId,
          methodId: request.methodId,
          makeDefault: request.makeDefault,
        );
        return ProviderAuthAttemptResultDto(attempt: attempt).toJson();
      case RpcMethod.providerAuthStatus:
        final request = ProviderAuthAttemptParamsDto.fromJson(payload);
        final attempt = await providerAuth.status(request.attemptId);
        return ProviderAuthAttemptResultDto(attempt: attempt).toJson();
      case RpcMethod.providerAuthCancel:
        _requireLocalAdmin();
        final request = ProviderAuthAttemptParamsDto.fromJson(payload);
        await providerAuth.cancel(request.attemptId);
        return const <String, dynamic>{};
      case RpcMethod.providerDisconnect:
        _requireLocalAdmin();
        final request = ProviderConnectionIdParamsDto.fromJson(payload);
        await providers.disconnect(request.connectionId);
        return const <String, dynamic>{};
      case RpcMethod.providerDefaultSet:
        _requireLocalAdmin();
        final request = ProviderDefaultSetParamsDto.fromJson(payload);
        await providers.setDefault(request.connectionId);
        return const <String, dynamic>{};
      case RpcMethod.providerDefaultModelSet:
        _requireLocalAdmin();
        final request = ProviderDefaultModelSetParamsDto.fromJson(payload);
        await providers.setDefaultModel(request.connectionId, request.modelId);
        return const <String, dynamic>{};
      case RpcMethod.providerCatalogRefresh:
        _requireLocalAdmin();
        final catalog = await providers.refreshCatalog();
        return ProviderCatalogResultDto(catalog: catalog).toJson();
      case RpcMethod.providerModelsList:
        final request = ProviderConnectionIdParamsDto.fromJson(payload);
        final models = await providers.listModels(request.connectionId);
        return ProviderModelsResultDto(models: models).toJson();
      case RpcMethod.providerCustomCreate:
        _requireLocalAdmin();
        final request = ProviderCustomCreateParamsDto.fromJson(payload);
        final connection = await providers.createCustom(
          request.id,
          request.config,
          apiKey: request.apiKey,
          makeDefault: request.makeDefault,
        );
        return ProviderConnectionResultDto(connection: connection).toJson();
      case RpcMethod.providerCustomUpdate:
        _requireLocalAdmin();
        final request = ProviderCustomUpdateParamsDto.fromJson(payload);
        final connection = await providers.updateCustom(
          request.connectionId,
          request.config,
          apiKey: request.apiKey,
        );
        return ProviderConnectionResultDto(connection: connection).toJson();
      case RpcMethod.providerCustomDelete:
        _requireLocalAdmin();
        final request = ProviderConnectionIdParamsDto.fromJson(payload);
        if (await agentDefinitions.referencesProvider(request.connectionId)) {
          throw const FormatException(
            'Provider connection is referenced by an agent definition.',
          );
        }
        await providers.deleteCustom(request.connectionId);
        return const <String, dynamic>{};
      case RpcMethod.turnStart:
        final request = TurnStartParamsDto.fromJson(payload);
        final created = await agents.startTurn(
          sessionId: request.sessionId,
          turnId: request.turnId,
          prompt: request.prompt,
        );
        return TurnStartResultDto(created: created).toJson();
      case RpcMethod.turnCancel:
        final request = SessionIdParamsDto.fromJson(payload);
        await agents.cancelTurn(request.sessionId);
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
        subscriptions.add(request.sessionId);
        final items = await timeline.after(
          request.sessionId,
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
        'This setting can only be changed by a daemon administrator.',
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
