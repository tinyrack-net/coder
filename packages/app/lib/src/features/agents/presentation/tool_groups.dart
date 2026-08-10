import 'package:app/l10n/gen/app_localizations.dart';
import 'package:protocol/protocol.dart';

/// One tool group and the catalog entries that landed in it.
final class AgentToolGroupView {
  /// Creates a group view over [tools].
  const AgentToolGroupView({required this.group, required this.tools});

  /// The group these tools are presented and toggled under.
  final ToolGroup group;

  /// The group's tools, in catalog order.
  final List<AgentToolDefinitionDto> tools;

  /// The ids a user may actually turn on or off.
  ///
  /// An always-on tool is not one of them: the daemon supplies it whatever the
  /// agent lists, so offering it a checkbox would be a lie.
  List<String> get toggleableIds => <String>[
    for (final tool in tools)
      if (!tool.alwaysOn) tool.id,
  ];

  /// Whether nothing in this group can be changed.
  bool get locked => toggleableIds.isEmpty;

  /// How many of this group's tools a turn would receive.
  int enabledCount(Set<String> selected) =>
      tools.where((tool) => tool.alwaysOn || selected.contains(tool.id)).length;

  /// Whether every tool in this group is on.
  bool allEnabled(Set<String> selected) =>
      enabledCount(selected) == tools.length;

  /// Whether the group is neither fully on nor fully off.
  bool partiallyEnabled(Set<String> selected) {
    final enabled = enabledCount(selected);
    return enabled > 0 && enabled < tools.length;
  }
}

/// Splits [tools] into groups, in [ToolGroup] declaration order.
///
/// Group order is the enum's rather than the catalog's, because the catalog
/// order is what the daemon advertises to a model and a group's members are
/// not contiguous in it. Within a group the catalog order is kept, so a tool
/// does not move when an unrelated one is registered. A group nothing belongs
/// to is dropped instead of drawing an empty header.
List<AgentToolGroupView> groupAgentTools(List<AgentToolDefinitionDto> tools) {
  final byGroup = <ToolGroup, List<AgentToolDefinitionDto>>{};
  for (final tool in tools) {
    byGroup.putIfAbsent(tool.group, () => <AgentToolDefinitionDto>[]).add(tool);
  }
  return <AgentToolGroupView>[
    for (final group in ToolGroup.values)
      if (byGroup[group] case final grouped?)
        AgentToolGroupView(group: group, tools: List.unmodifiable(grouped)),
  ];
}

/// The localized name of [group].
String toolGroupLabel(AppLocalizations l10n, ToolGroup group) =>
    switch (group) {
      ToolGroup.filesystem => l10n.agentSettingsToolGroupFilesystem,
      ToolGroup.editing => l10n.agentSettingsToolGroupEditing,
      ToolGroup.execution => l10n.agentSettingsToolGroupExecution,
      ToolGroup.attachments => l10n.agentSettingsToolGroupAttachments,
      ToolGroup.mcp => l10n.agentSettingsToolGroupMcp,
      ToolGroup.collaboration => l10n.agentSettingsToolGroupCollaboration,
      ToolGroup.session => l10n.agentSettingsToolGroupSession,
    };
