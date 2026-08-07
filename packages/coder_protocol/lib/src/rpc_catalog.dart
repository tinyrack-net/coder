import 'package:coder_protocol/src/protocol.dart';

/// A typed JSON-RPC procedure shared by client and daemon adapters.
final class RpcProcedure<P, R> {
  /// Creates a procedure descriptor with codecs for both directions.
  const RpcProcedure({
    required this.name,
    required this.decodeParams,
    required this.encodeParams,
    required this.decodeResult,
    required this.encodeResult,
  });

  /// Stable JSON-RPC method name.
  final String name;

  /// Decodes request parameters.
  final P Function(Map<String, dynamic>) decodeParams;

  /// Encodes request parameters.
  final Map<String, dynamic> Function(P) encodeParams;

  /// Decodes a successful result.
  final R Function(Map<String, dynamic>) decodeResult;

  /// Encodes a successful result.
  final Map<String, dynamic> Function(R) encodeResult;
}

/// A typed JSON-RPC notification shared by transport adapters.
final class RpcNotificationDescriptor<E> {
  /// Creates a typed notification descriptor.
  const RpcNotificationDescriptor({
    required this.name,
    required this.decode,
    required this.encode,
  });

  /// Stable JSON-RPC notification name.
  final String name;

  /// Decodes a notification payload.
  final E Function(Map<String, dynamic>) decode;

  /// Encodes a notification payload.
  final Map<String, dynamic> Function(E) encode;
}

Map<String, dynamic> _identity(Map<String, dynamic> value) => value;

RpcProcedure<Map<String, dynamic>, Map<String, dynamic>> _procedure(
  String name,
) => RpcProcedure<Map<String, dynamic>, Map<String, dynamic>>(
  name: name,
  decodeParams: _identity,
  encodeParams: _identity,
  decodeResult: _identity,
  encodeResult: _identity,
);

RpcNotificationDescriptor<Map<String, dynamic>> _notification(String name) =>
    RpcNotificationDescriptor<Map<String, dynamic>>(
      name: name,
      decode: _identity,
      encode: _identity,
    );

/// Handshake descriptor registered before authenticated feature procedures.
final RpcProcedure<Map<String, dynamic>, Map<String, dynamic>>
systemHelloProcedure = _procedure(RpcMethod.hello);

/// Complete v3 procedure catalog in deterministic registration order.
final List<RpcProcedure<Map<String, dynamic>, Map<String, dynamic>>>
rpcProcedures = List.unmodifiable(
  <RpcProcedure<Map<String, dynamic>, Map<String, dynamic>>>[
    systemHelloProcedure,
    for (final name in <String>[
      RpcMethod.workspaceCatalog,
      RpcMethod.workspaceRegister,
      RpcMethod.workspaceRefresh,
      RpcMethod.workspaceUnregister,
      RpcMethod.directorySuggest,
      RpcMethod.fileSearch,
      RpcMethod.gitBranchesList,
      RpcMethod.worktreeCreate,
      RpcMethod.worktreeArchivePreview,
      RpcMethod.worktreeArchive,
      RpcMethod.projectSettingsGet,
      RpcMethod.projectSettingsSave,
      RpcMethod.agentDefinitionList,
      RpcMethod.agentDefinitionGet,
      RpcMethod.agentDefinitionCreate,
      RpcMethod.agentDefinitionUpdate,
      RpcMethod.agentDefinitionArchive,
      RpcMethod.agentDefinitionReset,
      RpcMethod.agentDefinitionValidate,
      RpcMethod.agentToolCatalog,
      RpcMethod.mcpServerList,
      RpcMethod.mcpServerAdd,
      RpcMethod.mcpServerUpdate,
      RpcMethod.mcpServerRemove,
      RpcMethod.mcpServerTest,
      RpcMethod.mcpSecretSet,
      RpcMethod.commandList,
      RpcMethod.skillList,
      RpcMethod.skillGet,
      RpcMethod.skillCreate,
      RpcMethod.skillUpdate,
      RpcMethod.skillDelete,
      RpcMethod.skillSetEnabled,
      RpcMethod.sessionList,
      RpcMethod.sessionSubagentList,
      RpcMethod.sessionCreate,
      RpcMethod.sessionUpdateSettings,
      RpcMethod.terminalList,
      RpcMethod.terminalCreate,
      RpcMethod.terminalAttach,
      RpcMethod.terminalWrite,
      RpcMethod.terminalResize,
      RpcMethod.terminalTerminate,
      RpcMethod.terminalShellGet,
      RpcMethod.terminalShellSet,
      RpcMethod.permissionDefaultModeGet,
      RpcMethod.permissionDefaultModeSet,
      RpcMethod.providerCatalog,
      RpcMethod.providerConnectionsList,
      RpcMethod.providerConnectApiKey,
      RpcMethod.providerConnectNone,
      RpcMethod.providerAuthStart,
      RpcMethod.providerAuthStatus,
      RpcMethod.providerAuthCancel,
      RpcMethod.providerDisconnect,
      RpcMethod.providerCatalogRefresh,
      RpcMethod.providerModelsList,
      RpcMethod.providerDefaultModelGet,
      RpcMethod.providerDefaultModelSet,
      RpcMethod.providerCustomCreate,
      RpcMethod.providerCustomUpdate,
      RpcMethod.providerCustomDelete,
      RpcMethod.turnStart,
      RpcMethod.turnCancel,
      RpcMethod.sessionCompact,
      RpcMethod.approvalResolve,
      RpcMethod.userQuestionAnswer,
      RpcMethod.sessionPendingInput,
      RpcMethod.timelineSubscribe,
    ])
      _procedure(name),
  ],
);

/// Complete v3 notification catalog.
final List<RpcNotificationDescriptor<Map<String, dynamic>>> rpcNotifications =
    List.unmodifiable(<RpcNotificationDescriptor<Map<String, dynamic>>>[
      for (final name in <String>[
        RpcNotification.timelineEvent,
        RpcNotification.sessionUpdated,
        RpcNotification.terminalOutput,
        RpcNotification.terminalUpdated,
        RpcNotification.agentDefinitionsChanged,
        RpcNotification.mcpServersChanged,
        RpcNotification.skillsChanged,
        RpcNotification.commandsChanged,
        RpcNotification.approvalRequested,
        RpcNotification.userQuestionRequested,
        RpcNotification.providerAuthUpdated,
      ])
        _notification(name),
    ]);
