import 'package:protocol/src/features/agents/procedures.dart';
import 'package:protocol/src/features/mcp/procedures.dart';
import 'package:protocol/src/features/models/procedures.dart';
import 'package:protocol/src/features/plugins/procedures.dart';
import 'package:protocol/src/features/prompts/procedures.dart';
import 'package:protocol/src/features/providers/procedures.dart';
import 'package:protocol/src/features/relay/procedures.dart';
import 'package:protocol/src/features/sessions/procedures.dart';
import 'package:protocol/src/features/system/procedures.dart';
import 'package:protocol/src/features/terminals/procedures.dart';
import 'package:protocol/src/features/workspaces/procedures.dart';
import 'package:protocol/src/rpc_catalog.dart';

/// Complete v5 procedure catalog in deterministic feature order.
final List<RpcProcedureDescriptor> rpcProcedures =
    List<RpcProcedureDescriptor>.unmodifiable(<RpcProcedureDescriptor>[
      ...systemProcedures,
      ...workspacesProcedures,
      ...agentsProcedures,
      ...pluginsProcedures,
      ...promptsProcedures,
      ...modelsProcedures,
      ...providersProcedures,
      ...relayProcedures,
      ...mcpProcedures,
      ...sessionsProcedures,
      ...terminalsProcedures,
    ]);

/// Complete v5 notification catalog.
final List<RpcNotificationDescriptor> rpcNotifications =
    List<RpcNotificationDescriptor>.unmodifiable(<RpcNotificationDescriptor>[
      ...agentsNotifications,
      ...pluginsNotifications,
      ...promptsNotifications,
      ...providersNotifications,
      ...relayNotifications,
      ...mcpNotifications,
      ...sessionsNotifications,
      ...terminalsNotifications,
    ]);
