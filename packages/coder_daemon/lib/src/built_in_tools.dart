import 'package:coder_agent/coder_agent.dart';
import 'package:coder_daemon/src/agent_definitions.dart';
import 'package:coder_daemon/src/multi_agent.dart';
import 'package:coder_protocol/coder_protocol.dart';

/// The workspace tools the daemon compiles in and shares across every turn.
///
/// These need nothing from the session or the turn, so one instance serves the
/// whole process. Everything else is built per turn from session-scoped ports.
List<AgentTool> workspaceBuiltInTools({
  required GitignoreEnvironment gitignoreEnvironment,
}) => <AgentTool>[
  ListDirectoryTool(),
  ReadFileTool(),
  SearchTextTool(gitignoreEnvironment: gitignoreEnvironment),
  GlobTool(gitignoreEnvironment: gitignoreEnvironment),
  UpdatePlanTool(),
  ApplyPatchTool(),
];

/// Catalog entries advertised to clients for every tool compiled into the
/// daemon.
///
/// A catalog description is written for the person choosing tools in settings,
/// so it stays shorter and plainer than the tool's own description, which is
/// written for the model and carries the limits it has to respect. The two are
/// deliberately different texts rather than one duplicated.
List<AgentToolDefinitionDto> builtInAgentToolDefinitions(
  Iterable<AgentTool> workspaceTools,
) => <AgentToolDefinitionDto>[
  ...workspaceTools.map(
    (tool) => AgentToolDefinitionDto(
      id: tool.name,
      name: tool.name,
      description: tool.description,
      risk: tool.risk,
      alwaysOn: alwaysOnBuiltInToolIds.contains(tool.name),
    ),
  ),
  ...sessionScopedToolDefinitions,
];

/// Catalog entries for the tools built per turn from session-scoped ports.
const List<AgentToolDefinitionDto> sessionScopedToolDefinitions =
    <AgentToolDefinitionDto>[
      AgentToolDefinitionDto(
        id: 'attach_file',
        name: 'attach_file',
        description:
            'Attach a regular file from the workspace to the conversation.',
        risk: ToolRisk.read,
        alwaysOn: true,
      ),
      AgentToolDefinitionDto(
        id: 'current_time',
        name: 'current_time',
        description: 'Get the current time in UTC.',
        risk: ToolRisk.read,
        alwaysOn: true,
      ),
      AgentToolDefinitionDto(
        id: 'sleep',
        name: 'sleep',
        description:
            'Pause before checking something again; ends early on new '
            'user input.',
        risk: ToolRisk.read,
        alwaysOn: true,
      ),
      AgentToolDefinitionDto(
        id: 'list_mcp_resources',
        name: 'list_mcp_resources',
        description:
            'List resources MCP servers publish, such as files, schemas, '
            'or application state.',
        risk: ToolRisk.read,
      ),
      AgentToolDefinitionDto(
        id: 'list_mcp_resource_templates',
        name: 'list_mcp_resource_templates',
        description:
            'List parameterized resource templates MCP servers publish.',
        risk: ToolRisk.read,
      ),
      AgentToolDefinitionDto(
        id: 'read_mcp_resource',
        name: 'read_mcp_resource',
        description: 'Read one resource from an MCP server.',
        risk: ToolRisk.read,
      ),
      AgentToolDefinitionDto(
        id: 'exec_command',
        name: 'exec_command',
        description:
            'Run shell commands, on pipes or in a pseudo-terminal, '
            'including REPLs and servers driven across several calls.',
        risk: ToolRisk.command,
      ),
      AgentToolDefinitionDto(
        id: 'view_image',
        name: 'view_image',
        description:
            'Look at an image file in the workspace, such as a screenshot '
            'or a design mock-up.',
        risk: ToolRisk.read,
        alwaysOn: true,
      ),
      AgentToolDefinitionDto(
        id: 'ask_user',
        name: 'ask_user',
        description:
            'Ask the user multiple-choice questions and wait for the '
            'answers.',
        risk: ToolRisk.read,
        alwaysOn: true,
      ),
      AgentToolDefinitionDto(
        id: 'read_attachment',
        name: 'read_attachment',
        description:
            'Resolve an attachment ID to validated metadata and a '
            'readable path.',
        risk: ToolRisk.read,
        alwaysOn: true,
      ),
      AgentToolDefinitionDto(
        id: collaborationCapabilityId,
        name: collaborationCapabilityId,
        description:
            'Spawn, message, wait on, interrupt, and list collaborating '
            'subagents that share this workspace.',
        risk: ToolRisk.read,
      ),
    ];
