import 'package:coder_protocol/src/features/agents/procedures.dart';
import 'package:coder_protocol/src/features/mcp/procedures.dart';
import 'package:coder_protocol/src/features/prompts/procedures.dart';
import 'package:coder_protocol/src/features/providers/procedures.dart';
import 'package:coder_protocol/src/features/relay/procedures.dart';
import 'package:coder_protocol/src/features/sessions/procedures.dart';
import 'package:coder_protocol/src/features/system/procedures.dart';
import 'package:coder_protocol/src/features/terminals/procedures.dart';
import 'package:coder_protocol/src/features/workspaces/procedures.dart';
import 'package:coder_protocol/src/rpc_catalog.dart';

/// Complete v4 procedure catalog in deterministic feature order.
final List<RpcProcedureDescriptor> rpcProcedures =
    List<RpcProcedureDescriptor>.unmodifiable(<RpcProcedureDescriptor>[
      ...systemProcedures,
      ...workspacesProcedures,
      ...agentsProcedures,
      ...promptsProcedures,
      ...providersProcedures,
      ...relayProcedures,
      ...mcpProcedures,
      ...sessionsProcedures,
      ...terminalsProcedures,
    ]);

/// Complete v4 notification catalog.
final List<RpcNotificationDescriptor> rpcNotifications =
    List<RpcNotificationDescriptor>.unmodifiable(<RpcNotificationDescriptor>[
      ...agentsNotifications,
      ...promptsNotifications,
      ...providersNotifications,
      ...relayNotifications,
      ...mcpNotifications,
      ...sessionsNotifications,
      ...terminalsNotifications,
    ]);
