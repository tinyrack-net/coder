import 'package:daemon/src/features/plugins/runtime/host_primitives.dart';

/// JSON object passed across the public Lua host boundary.
typedef HostPrimitiveJsonObject = Map<String, Object?>;

/// Uniform catalog entry type used after native implementation type erasure.
typedef PublicHostPrimitiveContract =
    HostPrimitiveContract<HostPrimitiveJsonObject, Object?>;

/// The single source of public host operation safety and Lua type metadata.
///
/// Native bindings, SDK descriptor generation, and LuaCATS host wrappers must
/// all consume these constants. No model-facing tool metadata belongs here.
abstract final class HostPrimitiveContracts {
  /// Reads metadata for one workspace path.
  static const PublicHostPrimitiveContract workspaceStat =
      PublicHostPrimitiveContract(
        operation: 'host.workspace.stat',
        capability: 'workspace.read',
        effect: HostPrimitiveEffect.read,
        luaInputType: 'tinest.WorkspaceStatInput',
        luaOutputType: 'tinest.WorkspaceStatOutput',
      );

  /// Lists one workspace directory.
  static const PublicHostPrimitiveContract workspaceList =
      PublicHostPrimitiveContract(
        operation: 'host.workspace.list',
        capability: 'workspace.read',
        effect: HostPrimitiveEffect.read,
        luaInputType: 'tinest.WorkspaceListInput',
        luaOutputType: 'tinest.WorkspaceListOutput',
      );

  /// Reads bounded UTF-8 workspace text.
  static const PublicHostPrimitiveContract workspaceReadText =
      PublicHostPrimitiveContract(
        operation: 'host.workspace.read_text',
        capability: 'workspace.read',
        effect: HostPrimitiveEffect.read,
        luaInputType: 'tinest.WorkspaceReadTextInput',
        luaOutputType: 'tinest.WorkspaceReadTextOutput',
      );

  /// Publishes a workspace blob as an opaque host resource.
  static const PublicHostPrimitiveContract workspaceReadBlob =
      PublicHostPrimitiveContract(
        operation: 'host.workspace.read_blob',
        capability: 'workspace.read',
        effect: HostPrimitiveEffect.read,
        luaInputType: 'tinest.WorkspaceReadBlobInput',
        luaOutputType: 'tinest.WorkspaceReadBlobOutput',
      );

  /// Walks the bounded workspace tree.
  static const PublicHostPrimitiveContract workspaceWalk =
      PublicHostPrimitiveContract(
        operation: 'host.workspace.walk',
        capability: 'workspace.read',
        effect: HostPrimitiveEffect.read,
        luaInputType: 'tinest.WorkspaceWalkInput',
        luaOutputType: 'tinest.WorkspaceWalkOutput',
      );

  /// Applies one atomic workspace mutation transaction.
  static const PublicHostPrimitiveContract workspaceTransaction =
      PublicHostPrimitiveContract(
        operation: 'host.workspace.transaction',
        capability: 'workspace.patch',
        effect: HostPrimitiveEffect.write,
        luaInputType: 'tinest.WorkspaceTransactionInput',
        luaOutputType: 'tinest.WorkspaceTransactionOutput',
      );

  /// Starts one host process.
  static const PublicHostPrimitiveContract processStart =
      PublicHostPrimitiveContract(
        operation: 'host.process.start',
        capability: 'process.execute',
        effect: HostPrimitiveEffect.command,
        luaInputType: 'tinest.ProcessStartInput',
        luaOutputType: 'tinest.ProcessHandle',
      );

  /// Reads a live process handle.
  static const PublicHostPrimitiveContract processRead =
      PublicHostPrimitiveContract(
        operation: 'host.process.read',
        capability: 'process.execute',
        effect: HostPrimitiveEffect.command,
        luaInputType: 'tinest.ProcessReadInput',
        luaOutputType: 'tinest.ProcessReadOutput',
      );

  /// Writes to a live process handle.
  static const PublicHostPrimitiveContract processWrite =
      PublicHostPrimitiveContract(
        operation: 'host.process.write',
        capability: 'process.write',
        effect: HostPrimitiveEffect.command,
        luaInputType: 'tinest.ProcessWriteInput',
        luaOutputType: 'tinest.ProcessWrittenOutput',
      );

  /// Interrupts a live process handle.
  static const PublicHostPrimitiveContract processInterrupt =
      PublicHostPrimitiveContract(
        operation: 'host.process.interrupt',
        capability: 'process.write',
        effect: HostPrimitiveEffect.command,
        luaInputType: 'tinest.ProcessHandle',
        luaOutputType: 'tinest.ProcessInterruptedOutput',
      );

  /// Terminates a live process handle.
  static const PublicHostPrimitiveContract processTerminate =
      PublicHostPrimitiveContract(
        operation: 'host.process.terminate',
        capability: 'process.write',
        effect: HostPrimitiveEffect.command,
        luaInputType: 'tinest.ProcessHandle',
        luaOutputType: 'tinest.ProcessTerminatedOutput',
      );

  /// Publishes a workspace path as an attachment.
  static const PublicHostPrimitiveContract attachmentPublish =
      PublicHostPrimitiveContract(
        operation: 'host.attachment.publish',
        capability: 'attachment.publish',
        effect: HostPrimitiveEffect.read,
        luaInputType: 'tinest.AttachmentPublishInput',
        luaOutputType: 'tinest.AttachmentEnvelope',
      );

  /// Reads an attachment as an opaque host resource.
  static const PublicHostPrimitiveContract attachmentRead =
      PublicHostPrimitiveContract(
        operation: 'host.attachment.read',
        capability: 'attachment.read',
        effect: HostPrimitiveEffect.read,
        luaInputType: 'tinest.AttachmentReadInput',
        luaOutputType: 'tinest.AttachmentEnvelope',
      );

  /// Reads the host clock.
  static const PublicHostPrimitiveContract clockCurrentTime =
      PublicHostPrimitiveContract(
        operation: 'host.clock.current_time',
        capability: 'clock.read',
        effect: HostPrimitiveEffect.read,
        luaInputType: 'tinest.ClockCurrentTimeInput',
        luaOutputType: 'tinest.ClockCurrentTimeOutput',
      );

  /// Performs one cancellable host wait.
  static const PublicHostPrimitiveContract clockSleep =
      PublicHostPrimitiveContract(
        operation: 'host.clock.sleep',
        capability: 'clock.sleep',
        effect: HostPrimitiveEffect.read,
        luaInputType: 'tinest.ClockSleepInput',
        luaOutputType: 'tinest.ClockSleepOutput',
      );

  /// Lists the host skill catalog.
  static const PublicHostPrimitiveContract skillsList =
      PublicHostPrimitiveContract(
        operation: 'host.skills.list',
        capability: 'workspace.read',
        effect: HostPrimitiveEffect.read,
        luaInputType: 'tinest.SkillListInput',
        luaOutputType: 'tinest.SkillListOutput',
      );

  /// Reads one skill document or resource.
  static const PublicHostPrimitiveContract skillsRead =
      PublicHostPrimitiveContract(
        operation: 'host.skills.read',
        capability: 'workspace.read',
        effect: HostPrimitiveEffect.read,
        luaInputType: 'tinest.SkillReadInput',
        luaOutputType: 'tinest.SkillReadOutput',
      );

  /// Asks structured questions through the host interaction surface.
  static const PublicHostPrimitiveContract interactionRequestUserInput =
      PublicHostPrimitiveContract(
        operation: 'host.interaction.request_user_input',
        capability: 'interaction.request',
        effect: HostPrimitiveEffect.read,
        luaInputType: 'tinest.InteractionRequestInput',
        luaOutputType: 'tinest.InteractionRequestOutput',
      );

  /// Spawns a child agent.
  static const PublicHostPrimitiveContract collaborationSpawnAgent =
      PublicHostPrimitiveContract(
        operation: 'host.collaboration.spawn_agent',
        capability: 'collaboration.spawn',
        effect: HostPrimitiveEffect.read,
        luaInputType: 'tinest.CollaborationSpawnInput',
        luaOutputType: 'tinest.CollaborationSpawnOutput',
      );

  /// Sends a message to an agent.
  static const PublicHostPrimitiveContract collaborationSendMessage =
      PublicHostPrimitiveContract(
        operation: 'host.collaboration.send_message',
        capability: 'collaboration.message',
        effect: HostPrimitiveEffect.read,
        luaInputType: 'tinest.CollaborationMessageInput',
        luaOutputType: 'tinest.CollaborationQueuedOutput',
      );

  /// Sends and triggers an agent follow-up task.
  static const PublicHostPrimitiveContract collaborationFollowupTask =
      PublicHostPrimitiveContract(
        operation: 'host.collaboration.followup_task',
        capability: 'collaboration.message',
        effect: HostPrimitiveEffect.read,
        luaInputType: 'tinest.CollaborationMessageInput',
        luaOutputType: 'tinest.CollaborationFollowupOutput',
      );

  /// Waits for collaboration activity.
  static const PublicHostPrimitiveContract collaborationWaitAgent =
      PublicHostPrimitiveContract(
        operation: 'host.collaboration.wait_agent',
        capability: 'collaboration.wait',
        effect: HostPrimitiveEffect.read,
        luaInputType: 'tinest.CollaborationWaitInput',
        luaOutputType: 'tinest.CollaborationWaitOutput',
      );

  /// Interrupts a child agent.
  static const PublicHostPrimitiveContract collaborationInterruptAgent =
      PublicHostPrimitiveContract(
        operation: 'host.collaboration.interrupt_agent',
        capability: 'collaboration.interrupt',
        effect: HostPrimitiveEffect.read,
        luaInputType: 'tinest.CollaborationTargetInput',
        luaOutputType: 'tinest.CollaborationInterruptOutput',
      );

  /// Lists the visible agent tree.
  static const PublicHostPrimitiveContract collaborationListAgents =
      PublicHostPrimitiveContract(
        operation: 'host.collaboration.list_agents',
        capability: 'collaboration.list',
        effect: HostPrimitiveEffect.read,
        luaInputType: 'tinest.CollaborationListInput',
        luaOutputType: 'tinest.CollaborationListOutput',
      );

  /// Lists raw MCP resources.
  static const PublicHostPrimitiveContract mcpListResources =
      PublicHostPrimitiveContract(
        operation: 'host.mcp.list_resources',
        capability: 'mcp.read',
        effect: HostPrimitiveEffect.read,
        luaInputType: 'tinest.McpPageInput',
        luaOutputType: 'tinest.McpListResourcesOutput',
      );

  /// Lists raw MCP resource templates.
  static const PublicHostPrimitiveContract mcpListResourceTemplates =
      PublicHostPrimitiveContract(
        operation: 'host.mcp.list_resource_templates',
        capability: 'mcp.read',
        effect: HostPrimitiveEffect.read,
        luaInputType: 'tinest.McpPageInput',
        luaOutputType: 'tinest.McpListResourceTemplatesOutput',
      );

  /// Reads one raw MCP resource.
  static const PublicHostPrimitiveContract mcpReadResource =
      PublicHostPrimitiveContract(
        operation: 'host.mcp.read_resource',
        capability: 'mcp.read',
        effect: HostPrimitiveEffect.read,
        luaInputType: 'tinest.McpReadResourceInput',
        luaOutputType: 'tinest.McpReadResourceOutput',
      );

  /// Catalogs raw external MCP tools.
  static const PublicHostPrimitiveContract mcpCatalogTools =
      PublicHostPrimitiveContract(
        operation: 'host.mcp.catalog_tools',
        capability: 'mcp.read',
        effect: HostPrimitiveEffect.read,
        luaInputType: 'tinest.McpCatalogToolsInput',
        luaOutputType: 'tinest.McpCatalogToolsOutput',
      );

  /// Invokes one raw external MCP tool.
  static const PublicHostPrimitiveContract mcpInvokeTool =
      PublicHostPrimitiveContract(
        operation: 'host.mcp.invoke_tool',
        capability: 'mcp.invoke',
        effect: HostPrimitiveEffect.dangerous,
        luaInputType: 'tinest.McpInvokeToolInput',
        luaOutputType: 'tinest.McpInvokeToolOutput',
      );

  /// Starts one sandboxed Lua code cell.
  static const PublicHostPrimitiveContract luaStart =
      PublicHostPrimitiveContract(
        operation: 'host.lua.start',
        capability: 'process.execute',
        effect: HostPrimitiveEffect.command,
        luaInputType: 'tinest.LuaStartInput',
        luaOutputType: 'tinest.LuaChunkOutput',
      );

  /// Reads one sandboxed Lua code cell.
  static const PublicHostPrimitiveContract luaRead =
      PublicHostPrimitiveContract(
        operation: 'host.lua.read',
        capability: 'process.execute',
        effect: HostPrimitiveEffect.command,
        luaInputType: 'tinest.LuaReadInput',
        luaOutputType: 'tinest.LuaChunkOutput',
      );

  /// Terminates one sandboxed Lua code cell.
  static const PublicHostPrimitiveContract luaTerminate =
      PublicHostPrimitiveContract(
        operation: 'host.lua.terminate',
        capability: 'process.write',
        effect: HostPrimitiveEffect.command,
        luaInputType: 'tinest.LuaTerminateInput',
        luaOutputType: 'tinest.LuaChunkOutput',
      );

  /// Sends one bounded HTTP(S) request.
  static const PublicHostPrimitiveContract networkRequest =
      PublicHostPrimitiveContract(
        operation: 'host.network.request',
        capability: 'network.access',
        effect: HostPrimitiveEffect.dangerous,
        luaInputType: 'tinest.NetworkRequestInput',
        luaOutputType: 'tinest.NetworkResponse',
      );

  /// Reads one secret from the host-owned Agent/plugin scope.
  static const PublicHostPrimitiveContract secretGet =
      PublicHostPrimitiveContract(
        operation: 'host.secret.get',
        capability: 'secret.access',
        effect: HostPrimitiveEffect.dangerous,
        luaInputType: 'tinest.SecretGetInput',
        luaOutputType: 'tinest.SecretEnvelope',
      );

  /// Every public host primitive in deterministic SDK order.
  static const all = <PublicHostPrimitiveContract>[
    workspaceStat,
    workspaceList,
    workspaceReadText,
    workspaceReadBlob,
    workspaceWalk,
    workspaceTransaction,
    processStart,
    processRead,
    processWrite,
    processInterrupt,
    processTerminate,
    attachmentPublish,
    attachmentRead,
    clockCurrentTime,
    clockSleep,
    skillsList,
    skillsRead,
    interactionRequestUserInput,
    collaborationSpawnAgent,
    collaborationSendMessage,
    collaborationFollowupTask,
    collaborationWaitAgent,
    collaborationInterruptAgent,
    collaborationListAgents,
    mcpListResources,
    mcpListResourceTemplates,
    mcpReadResource,
    mcpCatalogTools,
    mcpInvokeTool,
    luaStart,
    luaRead,
    luaTerminate,
    networkRequest,
    secretGet,
  ];
}

/// Builds a validated operation index, rejecting duplicate or invalid entries.
Map<String, PublicHostPrimitiveContract> indexHostPrimitiveContracts(
  Iterable<PublicHostPrimitiveContract> contracts,
) {
  final result = <String, PublicHostPrimitiveContract>{};
  for (final contract in contracts) {
    if (!_operationPattern.hasMatch(contract.operation)) {
      throw StateError(
        'Invalid host primitive operation: ${contract.operation}.',
      );
    }
    if (contract.capability.trim().isEmpty ||
        !_luaTypePattern.hasMatch(contract.luaInputType) ||
        !_luaTypePattern.hasMatch(contract.luaOutputType)) {
      throw StateError(
        'Host primitive contract has invalid capability or Lua types: '
        '${contract.operation}.',
      );
    }
    if (result.containsKey(contract.operation)) {
      throw StateError(
        'Two host primitive contracts claim ${contract.operation}.',
      );
    }
    result[contract.operation] = contract;
  }
  return Map<String, PublicHostPrimitiveContract>.unmodifiable(result);
}

/// Fails closed when native bindings drift from the public contract catalog.
void validateHostPrimitiveRegistry(
  HostPrimitiveRegistry registry, {
  Iterable<PublicHostPrimitiveContract> contracts = HostPrimitiveContracts.all,
  Set<String> unavailableOperations = const <String>{},
}) {
  final expected = Map<String, PublicHostPrimitiveContract>.of(
    indexHostPrimitiveContracts(contracts),
  )..removeWhere((operation, _) => unavailableOperations.contains(operation));
  for (final actual in registry.descriptors) {
    final contract = expected.remove(actual.operation);
    if (contract == null || !actual.matches(contract.descriptor)) {
      throw StateError(
        'Host primitive registry differs from the public contract: '
        '${actual.operation}.',
      );
    }
  }
  if (expected.isNotEmpty) {
    throw StateError(
      'Public host primitive contracts are unavailable: '
      '${expected.keys.join(', ')}.',
    );
  }
}

final RegExp _operationPattern = RegExp(
  r'^host\.[a-z][a-z0-9_]*\.[a-z][a-z0-9_]*$',
);
final RegExp _luaTypePattern = RegExp(
  r'^(?:any|table|tinest\.[A-Za-z][A-Za-z0-9_.<>?, |\[\]]*)$',
);
