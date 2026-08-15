import 'package:protocol/protocol.dart';

/// Feature ownership for every authenticated v5 RPC procedure.
final Map<String, List<RpcProcedureDescriptor>> daemonRpcProcedureGroups =
    <String, List<RpcProcedureDescriptor>>{
      'workspaces': workspacesProcedures,
      'agents': agentsProcedures,
      'prompts': promptsProcedures,
      'models': modelsProcedures,
      'providers': providersProcedures,
      'relay': relayProcedures,
      'mcp': mcpProcedures,
      'plugins': pluginsProcedures,
      'sessions': sessionsProcedures,
      'terminals': terminalsProcedures,
    };

/// Every authenticated descriptor in deterministic feature order.
final List<RpcProcedureDescriptor> daemonRpcProcedures =
    List<RpcProcedureDescriptor>.unmodifiable(
      daemonRpcProcedureGroups.values.expand((procedures) => procedures),
    );
