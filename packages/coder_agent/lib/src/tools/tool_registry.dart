import 'package:coder_agent/src/model.dart';
import 'package:coder_agent/src/tools/clock_tools.dart';
import 'package:coder_agent/src/tools/exec_sessions.dart';
import 'package:coder_agent/src/tools/skills.dart';
import 'package:coder_agent/src/tools/tool_support.dart';
import 'package:coder_protocol/coder_protocol.dart';

/// Everything one turn's tools are built from.
///
/// A provider reads only the fields its own tools need, so adding a port here
/// costs nothing to the providers that ignore it. Ports belonging to a
/// long-lived service rather than to a turn — an MCP client pool, a subagent
/// supervisor — are held by the provider itself instead.
final class AgentToolScope {
  /// Creates the context one turn builds its tools from.
  const AgentToolScope({
    required this.session,
    required this.definition,
    required this.selectedToolIds,
    required this.workspaceRoot,
    required this.turnId,
    required this.attachmentPublisher,
    required this.attachmentReader,
    required this.clock,
    required this.questions,
    required this.execHost,
    required this.skills,
  });

  /// The session this turn belongs to.
  final SessionDto session;

  /// The agent definition this turn runs as.
  final AgentDefinitionDto definition;

  /// Capability ids this turn runs with, always-on ones included.
  final Set<String> selectedToolIds;

  /// Worktree root every workspace path resolves against.
  final String workspaceRoot;

  /// The turn owning anything the tools publish.
  final String turnId;

  /// Publishes workspace files as turn-owned attachments.
  final AttachmentPublisher attachmentPublisher;

  /// Resolves attachment identifiers already owned by the session.
  final AttachmentReader attachmentReader;

  /// Time source that also ends a sleep early on new user input.
  final AgentClock clock;

  /// Raises multiple-choice questions and waits for the user.
  final UserQuestionCoordinator questions;

  /// The pseudo-terminals and pipes this session owns.
  final ExecSessionHost execHost;

  /// Skills resolved against this worktree.
  final SkillCatalog skills;

  /// The session this turn belongs to.
  String get sessionId => session.id;
}

/// One capability: what it advertises, and how a turn builds it.
///
/// A capability is not always one tool. `exec_command` also brings
/// `write_stdin`, because nobody may be allowed to write to a shell without
/// being able to start one, and `collaboration` brings six at once.
///
/// Deciding whether a capability applies is the provider's own job rather than
/// the registry's. Most answer it by id, but a subagent gets the collaboration
/// tools from its parentage and the skill tools only exist where the worktree
/// has skills, and neither of those is a selection a user made.
abstract interface class AgentToolProvider {
  /// Identifier agents select this capability by.
  String get id;

  /// What clients show for this capability, or null when it is not selectable.
  ///
  /// A hidden capability is always built and never offered in settings: the
  /// context-window tools are part of how a turn works rather than a choice a
  /// user makes about one.
  AgentToolDefinitionDto? get catalogEntry;

  /// Builds this capability's tools, or none when it does not apply.
  List<AgentTool> create(AgentToolScope scope);
}

/// A provider whose tools exist exactly when the turn selected its id.
abstract base class SelectableToolProvider implements AgentToolProvider {
  /// Allows subclasses to be const.
  const SelectableToolProvider();

  /// Builds the tools of a turn that selected this capability.
  List<AgentTool> build(AgentToolScope scope);

  @override
  List<AgentTool> create(AgentToolScope scope) =>
      scope.selectedToolIds.contains(id) ? build(scope) : const <AgentTool>[];
}

/// The capabilities compiled into the daemon, and their advertised order.
final class AgentToolRegistry {
  /// Creates a registry over [providers], rejecting a duplicate or mislabelled
  /// id.
  factory AgentToolRegistry(List<AgentToolProvider> providers) {
    final seen = <String>{};
    for (final provider in providers) {
      if (!seen.add(provider.id)) {
        throw StateError('Two tool providers claim the id ${provider.id}.');
      }
      if (provider.catalogEntry case final entry?
          when entry.id != provider.id) {
        throw StateError(
          'Provider ${provider.id} advertises the id ${entry.id}.',
        );
      }
    }
    return AgentToolRegistry._(List<AgentToolProvider>.unmodifiable(providers));
  }

  AgentToolRegistry._(this._providers);

  final List<AgentToolProvider> _providers;

  /// Every provider, in advertised order.
  List<AgentToolProvider> get providers => _providers;

  /// Catalog entries for the capabilities a user may turn on or off.
  List<AgentToolDefinitionDto> get catalog => <AgentToolDefinitionDto>[
    for (final provider in _providers) ?provider.catalogEntry,
  ];

  /// Capabilities every agent gets, whichever ones it lists.
  Set<String> get alwaysOnIds => <String>{
    for (final provider in _providers)
      if (provider.catalogEntry case final entry? when entry.alwaysOn)
        provider.id,
  };

  /// The capability ids a turn runs with, always-on ones first.
  List<String> resolveIds(Iterable<String> chosen) =>
      List<String>.unmodifiable(<String>{...alwaysOnIds, ...chosen});

  /// Builds every tool one turn may call.
  ///
  /// Ids this registry does not know are handed to [external], which is how
  /// MCP tools published at runtime join a turn without being compiled in.
  List<AgentTool> toolsFor(
    AgentToolScope scope, {
    AgentTool? Function(String id)? external,
  }) {
    final known = <String>{for (final provider in _providers) provider.id};
    return <AgentTool>[
      for (final provider in _providers) ...provider.create(scope),
      for (final id in scope.selectedToolIds)
        if (!known.contains(id)) ?external?.call(id),
    ];
  }
}
