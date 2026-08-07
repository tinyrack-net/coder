import 'package:coder_agent/coder_agent.dart';
import 'package:coder_daemon/src/features/mcp/infrastructure/mcp_resource_tools.dart';
import 'package:coder_daemon/src/features/sessions/infrastructure/multi_agent.dart';

/// The capabilities compiled into this daemon, in the order clients see them.
///
/// This list is the whole registration surface: a new tool is a provider added
/// here, and its catalog entry, its always-on status, and how a turn builds it
/// all travel with the provider rather than being restated in a switch, a DTO
/// list, and an id set that have to be kept agreeing with each other.
AgentToolRegistry builtInAgentToolRegistry({
  required GitignoreEnvironment gitignoreEnvironment,
  required McpResourceHost Function(String workspaceRoot) mcpResourceHostFor,
  required MultiAgentService? Function() multiAgent,
}) => AgentToolRegistry(<AgentToolProvider>[
  const ListDirectoryToolProvider(),
  const ReadFileToolProvider(),
  SearchTextToolProvider(gitignoreEnvironment: gitignoreEnvironment),
  GlobToolProvider(gitignoreEnvironment: gitignoreEnvironment),
  const UpdatePlanToolProvider(),
  const ApplyPatchToolProvider(),
  const AttachFileToolProvider(),
  const CurrentTimeToolProvider(),
  const SleepToolProvider(),
  McpResourceToolProvider(
    id: 'list_mcp_resources',
    description:
        'List resources MCP servers publish, such as files, schemas, '
        'or application state.',
    tool: (host) => ListMcpResourcesTool(host: host),
    hostFor: mcpResourceHostFor,
  ),
  McpResourceToolProvider(
    id: 'list_mcp_resource_templates',
    description: 'List parameterized resource templates MCP servers publish.',
    tool: (host) => ListMcpResourceTemplatesTool(host: host),
    hostFor: mcpResourceHostFor,
  ),
  McpResourceToolProvider(
    id: 'read_mcp_resource',
    description: 'Read one resource from an MCP server.',
    tool: (host) => ReadMcpResourceTool(host: host),
    hostFor: mcpResourceHostFor,
  ),
  const ExecCommandToolProvider(),
  const ViewImageToolProvider(),
  const AskUserToolProvider(),
  const ReadAttachmentToolProvider(),
  // The supervisor is wired after the session service it drives, so the
  // provider reads it at turn time rather than capturing a null at boot.
  CollaborationToolProvider(multiAgent),
  // Hidden capabilities: always built, never offered in settings.
  const ContextWindowToolProvider(),
  const SkillToolProvider(),
]);
