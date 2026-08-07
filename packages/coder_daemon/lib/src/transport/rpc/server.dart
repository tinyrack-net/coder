import 'dart:async';
import 'dart:convert';

import 'package:coder_client/coder_client.dart';
import 'package:coder_daemon/src/bootstrap/config.dart';
import 'package:coder_daemon/src/features/agents/infrastructure/agent_definitions.dart';
import 'package:coder_daemon/src/features/attachments/infrastructure/attachment_service.dart';
import 'package:coder_daemon/src/features/mcp/infrastructure/mcp_server_service.dart';
import 'package:coder_daemon/src/features/mcp/infrastructure/mcp_service.dart';
import 'package:coder_daemon/src/features/prompts/infrastructure/commands.dart';
import 'package:coder_daemon/src/features/prompts/infrastructure/skills.dart';
import 'package:coder_daemon/src/features/providers/infrastructure/provider_auth.dart';
import 'package:coder_daemon/src/features/providers/infrastructure/provider_service.dart';
import 'package:coder_daemon/src/features/sessions/infrastructure/agent_service.dart';
import 'package:coder_daemon/src/features/sessions/infrastructure/session_interactions.dart';
import 'package:coder_daemon/src/features/sessions/infrastructure/session_settings.dart';
import 'package:coder_daemon/src/features/terminals/application/terminal_service.dart';
import 'package:coder_daemon/src/features/terminals/domain/terminal.dart';
import 'package:coder_daemon/src/features/terminals/transport/terminal_mapper.dart';
import 'package:coder_daemon/src/features/workspaces/infrastructure/workspace_service.dart';
import 'package:coder_daemon/src/shared/infrastructure/persistence/repositories.dart';
import 'package:coder_daemon/src/shared/ports/daemon_ports.dart';
import 'package:coder_daemon/src/transport/rpc/rpc_dispatch.dart';
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
    required this.worktreeLifecycle,
    required this.sessionRepository,
    required this.timeline,
    required this.agents,
    required this.sessionSettings,
    required this.sessionInteractions,
    required this.attachments,
    required this.agentDefinitions,
    required this.mcp,
    required this.mcpServers,
    required this.worktrees,
    required this.skills,
    required this.commands,
    required this.providers,
    required this.models,
    required this.providerAuth,
    required this.terminals,
    required this.settings,
    required this.clock,
    required this.serverInfo,
    required this.token,
    required Stream<WireEnvelope> events,
    this.allowedOrigins = defaultAllowedOrigins,
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
    _mcpSubscription = mcp.changes.listen(
      (_) => _broadcast(
        const WireEnvelope(
          type: RpcNotification.mcpServersChanged,
          payload: <String, dynamic>{},
        ),
      ),
    );
    _skillSubscription = skills.changes.listen(
      (_) => _broadcast(
        const WireEnvelope(
          type: RpcNotification.skillsChanged,
          payload: <String, dynamic>{},
        ),
      ),
    );
    _commandSubscription = commands.changes.listen(
      (_) => _broadcast(
        const WireEnvelope(
          type: RpcNotification.commandsChanged,
          payload: <String, dynamic>{},
        ),
      ),
    );
    _terminalSubscription = terminals.events.listen((event) {
      switch (event) {
        case final TerminalOutput output:
          _broadcast(
            WireEnvelope(
              type: RpcNotification.terminalOutput,
              payload: terminalOutputToDto(output).toJson(),
            ),
          );
        case final Terminal terminal:
          _broadcast(
            WireEnvelope(
              type: RpcNotification.terminalUpdated,
              payload: terminalToDto(terminal).toJson(),
            ),
          );
      }
    });
  }

  /// The workspaces public API member.
  final WorkspaceCatalogPort workspaces;

  /// Manages Git worktree and project-settings lifecycles.
  final WorktreeLifecyclePort worktreeLifecycle;

  /// Connects and reports external MCP servers.
  final McpRuntime mcp;

  /// Administers persisted user MCP servers.
  final McpAdminPort mcpServers;

  /// Resolves a worktree id to the checkout its MCP scope belongs to.
  final WorktreeRepository worktrees;

  /// The sessionRepository public API member.
  final SessionRepository sessionRepository;

  /// The timeline public API member.
  final TimelineRepository timeline;

  /// The agents public API member.
  final SessionTurnCoordinator agents;

  /// Mutates session preferences independently of turn execution.
  final SessionSettingsPort sessionSettings;

  /// Resolves client-mediated interactions for running turns.
  final SessionInteractionPort sessionInteractions;

  /// Daemon-owned attachment payload service.
  final AttachmentService attachments;

  /// Markdown-backed agent definition application service.
  final AgentDefinitionService agentDefinitions;

  /// The skills public API member.
  final SkillCatalogService skills;

  /// Markdown-backed agent command catalog.
  final CommandService commands;

  /// The providers public API member.
  final ProviderConnectionService providers;

  /// Resolves and validates model selections for session requests.
  final ProviderModelResolver models;

  /// Transient provider authorization coordinator.
  final ProviderAuthCoordinator providerAuth;

  /// Owns daemon-lifetime interactive terminals.
  final TerminalService terminals;

  /// Persists daemon-host settings.
  final SettingsRepository settings;

  /// The clock public API member.
  final Clock clock;

  /// The serverInfo public API member.
  final ServerInfoDto serverInfo;

  /// The token public API member.
  final String token;

  /// Browser origins permitted to call this daemon.
  final Set<String> allowedOrigins;

  final Set<_ClientSession> _sessions = <_ClientSession>{};
  late final StreamSubscription<WireEnvelope> _eventSubscription;
  late final StreamSubscription<ProviderAuthAttemptDto> _authSubscription;
  late final StreamSubscription<void> _agentDefinitionSubscription;
  late final StreamSubscription<void> _mcpSubscription;
  late final StreamSubscription<void> _skillSubscription;
  late final StreamSubscription<void> _commandSubscription;
  late final StreamSubscription<Object> _terminalSubscription;

  /// The call public API member.
  FutureOr<Response> call(Request request) {
    // A browser sends an Origin; native clients and the CLI do not, so this
    // gate only ever constrains web pages.
    final origin = request.headers['origin'];
    if (origin != null && !allowedOrigins.contains(origin)) {
      return Response.forbidden('Origin $origin is not allowed.');
    }
    final cors = _corsHeaders(origin);
    if (request.method == 'OPTIONS') {
      // Only a browser preflights, and it does so before it can send the
      // credential, so this answers ahead of the authentication check.
      return origin == null
          ? Response.notFound('Not found')
          : Response.ok(null, headers: cors);
    }
    if (request.url.path == 'v3/health') {
      return Response.ok(
        jsonEncode(<String, dynamic>{
          'serverId': serverInfo.serverId,
          'version': serverInfo.version,
          'protocolVersion': serverInfo.protocolVersion,
        }),
        headers: <String, String>{'content-type': 'application/json', ...cors},
      );
    }
    final isAttachmentRequest =
        request.url.path == 'v3/attachments' ||
        (request.url.pathSegments.length >= 2 &&
            request.url.pathSegments[0] == 'v3' &&
            request.url.pathSegments[1] == 'attachments');
    if (request.url.path != 'v3/ws' && !isAttachmentRequest) {
      return Response.notFound('Not found');
    }
    if (!_constantTimeEquals(_presentedToken(request), token)) {
      return Response.unauthorized(
        'A valid bearer token is required.',
        headers: cors,
      );
    }
    if (isAttachmentRequest) return _attachmentRequest(request, cors);
    // Only the versioned protocol is offered back, so the token subprotocol a
    // browser sends is never echoed into the response.
    return webSocketHandler(
      _openSession,
      protocols: const <String>[coderWebSocketProtocol],
    )(request);
  }

  /// Reads the bearer token from the header or, for a browser, the
  /// subprotocol.
  ///
  /// The `WebSocket` API cannot set request headers, so a web client has no
  /// way to present an `Authorization` header and offers the same secret as a
  /// subprotocol instead.
  static String? _presentedToken(Request request) {
    final authorization = request.headers['authorization'];
    if (authorization != null && authorization.startsWith('Bearer ')) {
      return authorization.substring('Bearer '.length);
    }
    for (final protocol in _requestedProtocols(request)) {
      final token = decodeWebSocketTokenProtocol(protocol);
      if (token != null) return token;
    }
    return null;
  }

  static Iterable<String> _requestedProtocols(Request request) =>
      (request.headers['sec-websocket-protocol'] ?? '')
          .split(',')
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty);

  Map<String, String> _corsHeaders(String? origin) => origin == null
      ? const <String, String>{}
      : <String, String>{
          'access-control-allow-origin': origin,
          'access-control-allow-methods': 'GET, POST, OPTIONS',
          'access-control-allow-headers':
              'authorization, content-type, x-file-name',
          // Without this the browser cannot read the server-provided filename.
          'access-control-expose-headers': 'content-disposition',
          'access-control-max-age': '600',
          'vary': 'Origin',
        };

  Future<Response> _attachmentRequest(
    Request request,
    Map<String, String> cors,
  ) async {
    try {
      if (request.method == 'POST' && request.url.path == 'v3/attachments') {
        final encodedName = request.headers['x-file-name'];
        final contentLength = int.tryParse(
          request.headers['content-length'] ?? '',
        );
        if (encodedName == null || contentLength == null) {
          return Response.badRequest(
            body: 'x-file-name and content-length are required.',
          );
        }
        final attachment = await attachments.upload(
          fileName: Uri.decodeComponent(encodedName),
          mimeType:
              request.headers['content-type'] ?? 'application/octet-stream',
          declaredByteSize: contentLength,
          bytes: request.read(),
        );
        return Response.ok(
          jsonEncode(attachment.toJson()),
          headers: <String, String>{
            'content-type': 'application/json',
            'x-content-type-options': 'nosniff',
            ...cors,
          },
        );
      }
      if (request.method == 'GET' && request.url.pathSegments.length == 3) {
        final id = request.url.pathSegments[2];
        final (attachment, bytes) = await attachments.download(id);
        return Response.ok(
          bytes,
          headers: <String, String>{
            'content-type': attachment.mimeType,
            'content-length': attachment.byteSize.toString(),
            'content-disposition':
                "attachment; filename*=UTF-8''"
                '${Uri.encodeComponent(attachment.fileName)}',
            'x-content-type-options': 'nosniff',
            ...cors,
          },
        );
      }
      return Response.notFound('Not found');
    } on FormatException catch (error) {
      return Response.badRequest(body: error.message, headers: cors);
    } on AttachmentNotFoundException {
      return Response.notFound('Attachment not found.', headers: cors);
    }
  }

  void _openSession(WebSocketChannel channel, String? protocol) {
    final session = _ClientSession(
      channel: channel,
      workspaces: workspaces,
      worktreeLifecycle: worktreeLifecycle,
      sessionRepository: sessionRepository,
      timeline: timeline,
      agents: agents,
      sessionSettings: sessionSettings,
      sessionInteractions: sessionInteractions,
      agentDefinitions: agentDefinitions,
      mcp: mcp,
      mcpServers: mcpServers,
      worktrees: worktrees,
      skills: skills,
      commands: commands,
      providers: providers,
      models: models,
      providerAuth: providerAuth,
      terminals: terminals,
      settings: settings,
      clock: clock,
      serverInfo: serverInfo,
      onClosed: () {},
    );
    session.onClosed = () => _sessions.remove(session);
    _sessions.add(session);
    session.start();
  }

  void _broadcast(WireEnvelope event) {
    for (final session in List<_ClientSession>.of(_sessions)) {
      if (event.type == RpcNotification.timelineEvent ||
          event.type == RpcNotification.approvalRequested ||
          event.type == RpcNotification.userQuestionRequested) {
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
    await _mcpSubscription.cancel();
    await _skillSubscription.cancel();
    await _commandSubscription.cancel();
    await _terminalSubscription.cancel();
    await terminals.close();
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
    required this.worktreeLifecycle,
    required this.sessionRepository,
    required this.timeline,
    required this.agents,
    required this.sessionSettings,
    required this.sessionInteractions,
    required this.agentDefinitions,
    required this.mcp,
    required this.mcpServers,
    required this.worktrees,
    required this.skills,
    required this.commands,
    required this.providers,
    required this.models,
    required this.providerAuth,
    required this.terminals,
    required this.settings,
    required this.clock,
    required this.serverInfo,
    required this.onClosed,
  });

  final WebSocketChannel channel;
  final WorkspaceCatalogPort workspaces;
  final WorktreeLifecyclePort worktreeLifecycle;
  final SessionRepository sessionRepository;
  final TimelineRepository timeline;
  final SessionTurnCoordinator agents;
  final SessionSettingsPort sessionSettings;
  final SessionInteractionPort sessionInteractions;
  final AgentDefinitionService agentDefinitions;
  final McpRuntime mcp;
  final McpAdminPort mcpServers;
  final WorktreeRepository worktrees;
  final SkillCatalogService skills;
  final CommandService commands;
  final ProviderConnectionService providers;
  final ProviderModelResolver models;
  final ProviderAuthCoordinator providerAuth;
  final TerminalService terminals;
  final SettingsRepository settings;
  final Clock clock;
  final ServerInfoDto serverInfo;
  void Function() onClosed;
  final Set<String> subscriptions = <String>{};
  late final json_rpc.Peer _peer;
  bool _handshakeComplete = false;

  void start() {
    _peer = json_rpc.Peer(channel.cast<String>());
    _peer.registerMethod(RpcMethod.hello, _hello);
    for (final method in daemonRpcMethods) {
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
    if (payload.protocolMajor != coderProtocolMajor ||
        payload.protocolRevision != coderProtocolRevision) {
      throw json_rpc.RpcException(
        1001,
        'Unsupported protocol version.',
        data: const <String, dynamic>{'code': 'protocol_mismatch'},
      );
    }
    _handshakeComplete = true;
    return serverInfo
        .copyWith(
          features: <String, bool>{...serverInfo.features, 'jsonRpc2': true},
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
    } on SkillFileConflict catch (error) {
      throw json_rpc.RpcException(
        1002,
        'Skill file changed outside Coder.',
        data: <String, dynamic>{
          'code': 'skill_file_conflict',
          'currentContentHash': error.currentContentHash,
        },
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

  /// Resolves a worktree id to its checkout path, or null when absent.
  Future<String?> _worktreeRoot(String? worktreeId) async {
    if (worktreeId == null) return null;
    final worktree = await worktrees.getById(worktreeId);
    return worktree?.path;
  }

  /// Resolves a workspace ID into the project scope skills merge over.
  Future<SkillScope> _skillScope(String? workspaceId) async {
    if (workspaceId == null) return SkillScope.global;
    return SkillScope(
      workspaceId: workspaceId,
      projectRoot: await workspaces.workspaceRoot(workspaceId),
    );
  }

  /// Resolves a workspace ID into the project scope commands merge over.
  Future<CommandScope> _commandScope(String? workspaceId) async {
    if (workspaceId == null) return CommandScope.global;
    return CommandScope(
      workspaceId: workspaceId,
      projectRoot: await workspaces.workspaceRoot(workspaceId),
    );
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
        return const WorkspaceUnregisterResultDto(unregistered: true).toJson();
      case RpcMethod.directorySuggest:
        final request = DirectorySuggestParamsDto.fromJson(payload);
        return DirectorySuggestResultDto(
          suggestions: await workspaces.suggestDirectories(
            request.query,
            request.limit,
          ),
        ).toJson();
      case RpcMethod.fileSearch:
        return (await workspaces.searchFiles(
          FileSearchParamsDto.fromJson(payload),
        )).toJson();
      case RpcMethod.gitBranchesList:
        final request = GitBranchesListParamsDto.fromJson(payload);
        return GitBranchesListResultDto(
          branches: await worktreeLifecycle.listBranches(request.workspaceId),
        ).toJson();
      case RpcMethod.worktreeCreate:
        final request = WorktreeCreateParamsDto.fromJson(payload);
        return (await worktreeLifecycle.createWorktree(request)).toJson();
      case RpcMethod.projectSettingsGet:
        final request = ProjectSettingsGetParamsDto.fromJson(payload);
        return (await worktreeLifecycle.getProjectSettings(
          request.workspaceId,
        )).toJson();
      case RpcMethod.projectSettingsSave:
        final request = ProjectSettingsSaveParamsDto.fromJson(payload);
        return (await worktreeLifecycle.saveProjectSettings(request)).toJson();
      case RpcMethod.worktreeArchivePreview:
        final request = WorktreeIdParamsDto.fromJson(payload);
        return WorktreeArchivePreviewResultDto(
          preview: await worktreeLifecycle.previewArchive(request.worktreeId),
        ).toJson();
      case RpcMethod.worktreeArchive:
        final request = WorktreeArchiveParamsDto.fromJson(payload);
        return (await worktreeLifecycle.archive(
          request.worktreeId,
          force: request.force,
        )).toJson();
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
        final request = AgentDefinitionCreateParamsDto.fromJson(payload);
        return AgentDefinitionResultDto(
          definition: await agentDefinitions.create(
            request.id,
            request.definition,
          ),
        ).toJson();
      case RpcMethod.agentDefinitionUpdate:
        final request = AgentDefinitionUpdateParamsDto.fromJson(payload);
        return AgentDefinitionResultDto(
          definition: await agentDefinitions.update(
            request.definition,
            expectedContentHash: request.expectedContentHash,
            force: request.force,
          ),
        ).toJson();
      case RpcMethod.agentDefinitionArchive:
        final request = AgentDefinitionIdParamsDto.fromJson(payload);
        await agentDefinitions.archive(request.id);
        return const <String, dynamic>{};
      case RpcMethod.agentDefinitionReset:
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
        final request = AgentToolCatalogParamsDto.fromJson(payload);
        return AgentToolCatalogResultDto(
          tools: agentDefinitions.toolCatalog(
            workspaceRoot: await _worktreeRoot(request.worktreeId),
          ),
        ).toJson();
      case RpcMethod.mcpServerList:
        final request = McpServersParamsDto.fromJson(payload);
        final root = await _worktreeRoot(request.worktreeId);
        if (root != null) await mcp.ensureProject(root);
        return McpServersResultDto(
          servers: mcp.states(workspaceRoot: root),
        ).toJson();
      case RpcMethod.mcpServerAdd:
        final request = McpServerParamsDto.fromJson(payload);
        return McpServerStateResultDto(
          state: await mcpServers.add(request.server),
        ).toJson();
      case RpcMethod.mcpServerUpdate:
        final request = McpServerParamsDto.fromJson(payload);
        return McpServerStateResultDto(
          state: await mcpServers.update(request.server),
        ).toJson();
      case RpcMethod.mcpServerRemove:
        final request = McpServerIdParamsDto.fromJson(payload);
        await mcpServers.remove(request.id);
        return const <String, dynamic>{};
      case RpcMethod.mcpServerTest:
        final request = McpServerParamsDto.fromJson(payload);
        return McpServerStateResultDto(
          state: await mcpServers.test(request.server),
        ).toJson();
      case RpcMethod.mcpSecretSet:
        final request = McpSecretParamsDto.fromJson(payload);
        await mcpServers.setSecret(request.key, request.value);
        return const <String, dynamic>{};
      case RpcMethod.commandList:
        final commandRequest = CommandListParamsDto.fromJson(payload);
        return CommandListResultDto(
          commands: await commands.list(
            scope: await _commandScope(commandRequest.workspaceId),
          ),
        ).toJson();
      case RpcMethod.skillList:
        final request = SkillScopeParamsDto.fromJson(payload);
        return SkillListResultDto(
          skills: await skills.list(
            scope: await _skillScope(request.workspaceId),
          ),
        ).toJson();
      case RpcMethod.skillGet:
        final request = SkillIdParamsDto.fromJson(payload);
        return SkillResultDto(
          skill: await skills.get(
            request.id,
            scope: await _skillScope(request.workspaceId),
          ),
        ).toJson();
      case RpcMethod.skillCreate:
        final request = SkillCreateParamsDto.fromJson(payload);
        return SkillResultDto(
          skill: await skills.create(
            id: request.id,
            source: request.source,
            name: request.name,
            description: request.description,
            body: request.body,
            scope: await _skillScope(request.workspaceId),
          ),
        ).toJson();
      case RpcMethod.skillUpdate:
        final request = SkillUpdateParamsDto.fromJson(payload);
        return SkillResultDto(
          skill: await skills.update(
            request.skill,
            expectedContentHash: request.expectedContentHash,
            force: request.force,
            scope: await _skillScope(request.workspaceId),
          ),
        ).toJson();
      case RpcMethod.skillDelete:
        final request = SkillIdParamsDto.fromJson(payload);
        await skills.delete(
          request.id,
          scope: await _skillScope(request.workspaceId),
        );
        return const <String, dynamic>{};
      case RpcMethod.skillSetEnabled:
        final request = SkillSetEnabledParamsDto.fromJson(payload);
        return SkillResultDto(
          skill: await skills.setEnabled(
            request.id,
            enabled: request.enabled,
            scope: await _skillScope(request.workspaceId),
          ),
        ).toJson();
      case RpcMethod.sessionList:
        final request = SessionListParamsDto.fromJson(payload);
        final items = await sessionRepository.list(
          worktreeId: request.worktreeId,
        );
        return SessionListResultDto(sessions: items).toJson();
      case RpcMethod.sessionSubagentList:
        final request = SessionSubagentListParamsDto.fromJson(payload);
        final session = await sessionRepository.getById(request.sessionId);
        if (session == null) {
          throw const FormatException('Session not found.');
        }
        return SessionListResultDto(
          sessions: await sessionRepository.listByRoot(
            session.rootSessionId ?? session.id,
          ),
        ).toJson();
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
        final requestedModel = request.model;
        // Without an override the definition resolves through the daemon
        // fallback chain, which only fails when nothing is connected.
        if (requestedModel == null) {
          await models.resolveAgentModel(definition.model);
        } else {
          await models.validateAgentModel(
            requestedModel.providerConnectionId,
            requestedModel.modelId,
          );
        }
        final now = clock.nowUtc();
        final session = await sessionRepository.create(
          SessionDto(
            id: request.id,
            worktreeId: request.worktreeId,
            title: request.title,
            agentDefinitionId: definition.id,
            origin: SessionOrigin.manual,
            status: SessionStatus.idle,
            mode: request.mode,
            model: requestedModel,
            reasoningEffort: request.reasoningEffort,
            permissionMode: request.permissionMode,
            serviceTier: request.serviceTier,
            createdAt: now,
            updatedAt: now,
          ),
        );
        return SessionResultDto(session: session).toJson();
      case RpcMethod.sessionUpdateSettings:
        final request = SessionSettingsUpdateParamsDto.fromJson(payload);
        final session = await sessionSettings.updateSettings(
          request.sessionId,
          request.patch,
        );
        return SessionResultDto(session: session).toJson();

      case RpcMethod.terminalList:
        final request = TerminalListParamsDto.fromJson(payload);
        return TerminalListResultDto(
          terminals: terminals
              .list(request.worktreeId)
              .map(terminalToDto)
              .toList(growable: false),
        ).toJson();
      case RpcMethod.terminalCreate:
        final request = TerminalCreateParamsDto.fromJson(payload);
        return TerminalResultDto(
          terminal: terminalToDto(
            await terminals.create(
              id: request.id,
              worktreeId: request.worktreeId,
              title: request.title,
              columns: request.columns,
              rows: request.rows,
            ),
          ),
        ).toJson();
      case RpcMethod.terminalAttach:
        final request = TerminalAttachParamsDto.fromJson(payload);
        return terminalAttachmentToDto(
          terminals.attach(
            request.terminalId,
            afterSequence: request.afterSequence,
          ),
        ).toJson();
      case RpcMethod.terminalWrite:
        final request = TerminalWriteParamsDto.fromJson(payload);
        await terminals.write(request.terminalId, request.data);
        return const <String, dynamic>{};
      case RpcMethod.terminalResize:
        final request = TerminalResizeParamsDto.fromJson(payload);
        return TerminalResultDto(
          terminal: terminalToDto(
            await terminals.resize(
              request.terminalId,
              columns: request.columns,
              rows: request.rows,
            ),
          ),
        ).toJson();
      case RpcMethod.terminalTerminate:
        final request = TerminalIdParamsDto.fromJson(payload);
        await terminals.terminate(request.terminalId);
        return const <String, dynamic>{};
      case RpcMethod.terminalShellGet:
        final stored = await settings.getValue('terminal.shell');
        return TerminalShellDto(
          shell: stored == null || stored.isEmpty
              ? null
              : ShellSpecDto.fromJson(
                  Map<String, dynamic>.from(jsonDecode(stored) as Map),
                ),
        ).toJson();
      case RpcMethod.terminalShellSet:
        final request = TerminalShellDto.fromJson(payload);
        if (request.shell case final shell?
            when shell.executable.trim().isEmpty) {
          throw const FormatException('Shell executable must not be empty.');
        }
        await settings.setValue(
          'terminal.shell',
          request.shell == null ? '' : jsonEncode(request.shell!.toJson()),
        );
        return const <String, dynamic>{};
      case RpcMethod.permissionDefaultModeGet:
        final stored = await settings.getValue('permission.defaultMode');
        return PermissionSettingsDto(
          defaultMode: stored == null || stored.isEmpty
              ? PermissionMode.ask
              : PermissionMode.values.byName(stored),
        ).toJson();
      case RpcMethod.permissionDefaultModeSet:
        final request = PermissionSettingsDto.fromJson(payload);
        await settings.setValue(
          'permission.defaultMode',
          request.defaultMode.name,
        );
        return request.toJson();
      case RpcMethod.providerCatalog:
        final catalog = await providers.catalog();
        return ProviderCatalogResultDto(catalog: catalog).toJson();
      case RpcMethod.providerConnectionsList:
        final connections = await providers.connections();
        return ProviderConnectionsResultDto(connections: connections).toJson();
      case RpcMethod.providerConnectApiKey:
        final request = ProviderConnectApiKeyParamsDto.fromJson(payload);
        final connection = await providers.connectApiKey(
          request.definitionId,
          request.apiKey,
        );
        return ProviderConnectionResultDto(connection: connection).toJson();
      case RpcMethod.providerConnectNone:
        final request = ProviderConnectNoneParamsDto.fromJson(payload);
        final connection = await providers.connectNone(request.definitionId);
        return ProviderConnectionResultDto(connection: connection).toJson();
      case RpcMethod.providerAuthStart:
        final request = ProviderAuthStartParamsDto.fromJson(payload);
        final attempt = await providerAuth.start(
          definitionId: request.definitionId,
          methodId: request.methodId,
        );
        return ProviderAuthAttemptResultDto(attempt: attempt).toJson();
      case RpcMethod.providerAuthStatus:
        final request = ProviderAuthAttemptParamsDto.fromJson(payload);
        final attempt = await providerAuth.status(request.attemptId);
        return ProviderAuthAttemptResultDto(attempt: attempt).toJson();
      case RpcMethod.providerAuthCancel:
        final request = ProviderAuthAttemptParamsDto.fromJson(payload);
        await providerAuth.cancel(request.attemptId);
        return const <String, dynamic>{};
      case RpcMethod.providerDisconnect:
        final request = ProviderConnectionIdParamsDto.fromJson(payload);
        await providers.disconnect(request.connectionId);
        return const <String, dynamic>{};
      case RpcMethod.providerCatalogRefresh:
        final catalog = await providers.refreshCatalog();
        return ProviderCatalogResultDto(catalog: catalog).toJson();
      case RpcMethod.providerModelsList:
        final request = ProviderConnectionIdParamsDto.fromJson(payload);
        final models = await providers.listModels(request.connectionId);
        return ProviderModelsResultDto(models: models).toJson();
      case RpcMethod.providerDefaultModelGet:
        return DefaultModelDto(
          model: await providers.storedDefaultModel(),
        ).toJson();
      case RpcMethod.providerDefaultModelSet:
        final request = DefaultModelDto.fromJson(payload);
        await providers.setDefaultModel(request.model);
        return const <String, dynamic>{};
      case RpcMethod.providerCustomCreate:
        final request = ProviderCustomCreateParamsDto.fromJson(payload);
        final connection = await providers.createCustom(
          request.id,
          request.config,
          apiKey: request.apiKey,
        );
        return ProviderConnectionResultDto(connection: connection).toJson();
      case RpcMethod.providerCustomUpdate:
        final request = ProviderCustomUpdateParamsDto.fromJson(payload);
        final connection = await providers.updateCustom(
          request.connectionId,
          request.config,
          apiKey: request.apiKey,
        );
        return ProviderConnectionResultDto(connection: connection).toJson();
      case RpcMethod.providerCustomDelete:
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
          attachmentIds: request.attachmentIds,
        );
        return TurnStartResultDto(created: created).toJson();
      case RpcMethod.turnCancel:
        final request = SessionIdParamsDto.fromJson(payload);
        await agents.cancelTurn(request.sessionId);
        return const <String, dynamic>{};
      case RpcMethod.sessionCompact:
        final request = SessionIdParamsDto.fromJson(payload);
        await agents.compactSession(request.sessionId);
        return const <String, dynamic>{};
      case RpcMethod.approvalResolve:
        final request = ApprovalResolveParamsDto.fromJson(payload);
        final approval = await sessionInteractions.resolveApproval(
          request.approvalId,
          approved: request.approved,
        );
        return ApprovalResultDto(approval: approval).toJson();
      case RpcMethod.sessionPendingInput:
        sessionInteractions.notePendingInput(
          SessionPendingInputParamsDto.fromJson(payload).sessionId,
        );
        return const <String, dynamic>{};
      case RpcMethod.userQuestionAnswer:
        final request = UserQuestionAnswerParamsDto.fromJson(payload);
        final answered = await sessionInteractions.answerUserQuestion(
          request.requestId,
          request.answers,
        );
        return UserQuestionResultDto(request: answered).toJson();
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
