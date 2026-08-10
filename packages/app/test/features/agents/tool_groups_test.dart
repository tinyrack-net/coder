@Tags(<String>['feature_test__agent_definition_management__unit'])
library;

import 'package:app/src/features/agents/presentation/tool_groups.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/protocol.dart';

AgentToolDefinitionDto _tool(
  String id,
  ToolGroup group, {
  bool alwaysOn = false,
}) => AgentToolDefinitionDto(
  id: id,
  name: id,
  description: 'Does $id.',
  risk: ToolRisk.read,
  group: group,
  alwaysOn: alwaysOn,
);

void main() {
  test('groups follow enum order while tools keep catalog order', () {
    // The catalog is deliberately out of group order and out of alphabetical
    // order: neither is what decides where a tool is drawn.
    final grouped = groupAgentTools(<AgentToolDefinitionDto>[
      _tool('exec_command', ToolGroup.execution),
      _tool('read_file', ToolGroup.filesystem),
      _tool('apply_patch', ToolGroup.editing),
      _tool('glob', ToolGroup.filesystem),
    ]);

    expect(
      grouped.map((view) => view.group),
      <ToolGroup>[ToolGroup.filesystem, ToolGroup.editing, ToolGroup.execution],
    );
    expect(
      grouped.first.tools.map((tool) => tool.id),
      <String>['read_file', 'glob'],
    );
  });

  test('a group nothing belongs to is not drawn', () {
    final grouped = groupAgentTools(<AgentToolDefinitionDto>[
      _tool('read_file', ToolGroup.filesystem),
    ]);

    expect(grouped, hasLength(1));
    expect(grouped.single.group, ToolGroup.filesystem);
  });

  test('an always-on tool is counted but never offered a toggle', () {
    final view = groupAgentTools(<AgentToolDefinitionDto>[
      _tool('read_file', ToolGroup.filesystem, alwaysOn: true),
      _tool('glob', ToolGroup.filesystem, alwaysOn: true),
    ]).single;

    expect(view.toggleableIds, isEmpty);
    expect(view.locked, isTrue);
    expect(view.enabledCount(const <String>{}), 2);
    expect(view.allEnabled(const <String>{}), isTrue);
    expect(view.partiallyEnabled(const <String>{}), isFalse);
  });

  test('a group reports partial only between empty and full', () {
    final view = groupAgentTools(<AgentToolDefinitionDto>[
      _tool('list_mcp_resources', ToolGroup.mcp),
      _tool('read_mcp_resource', ToolGroup.mcp),
    ]).single;

    expect(view.toggleableIds, <String>[
      'list_mcp_resources',
      'read_mcp_resource',
    ]);
    expect(view.partiallyEnabled(const <String>{}), isFalse);
    expect(view.allEnabled(const <String>{}), isFalse);

    expect(view.partiallyEnabled(const <String>{'read_mcp_resource'}), isTrue);
    expect(view.allEnabled(const <String>{'read_mcp_resource'}), isFalse);

    const both = <String>{'list_mcp_resources', 'read_mcp_resource'};
    expect(view.partiallyEnabled(both), isFalse);
    expect(view.allEnabled(both), isTrue);
  });

  test('an always-on tool beside a selectable one still counts', () {
    final view = groupAgentTools(<AgentToolDefinitionDto>[
      _tool('read_file', ToolGroup.filesystem, alwaysOn: true),
      _tool('apply_patch', ToolGroup.filesystem),
    ]).single;

    expect(view.locked, isFalse);
    expect(view.toggleableIds, <String>['apply_patch']);
    // The always-on half is on whatever the agent selected, so the group reads
    // as partial rather than empty.
    expect(view.partiallyEnabled(const <String>{}), isTrue);
    expect(view.allEnabled(const <String>{'apply_patch'}), isTrue);
  });
}
