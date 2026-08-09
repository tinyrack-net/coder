import 'package:agent/src/contracts.dart';

import 'package:agent/src/model.dart';
import 'package:agent/src/tools/clock_tools.dart';
import 'package:agent/src/tools/exec_sessions.dart';
import 'package:agent/src/tools/lua_code_mode.dart';
import 'package:agent/src/tools/skills.dart';
import 'package:agent/src/tools/tool_support.dart';

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
    this.luaCodeModeHost,
  });

  /// The session this turn belongs to.
  final AgentSessionContext session;

  /// The agent definition this turn runs as.
  final AgentDefinitionContext definition;

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

  /// Session-scoped Lua cell host, absent on unsupported runtimes.
  final LuaCodeModeHost? luaCodeModeHost;

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
abstract base class AgentToolProvider {
  /// Allows subclasses to be const.
  const AgentToolProvider();

  /// Identifier agents select this capability by.
  String get id;

  /// What clients show for this capability, or null when it is not selectable.
  ///
  /// A hidden capability is always built and never offered in settings: the
  /// context-window tools are part of how a turn works rather than a choice a
  /// user makes about one.
  AgentToolDefinition? get catalogEntry;

  /// Builds this capability's tools, or none when it does not apply.
  List<AgentTool> create(AgentToolScope scope);

  /// Lets a capability widen approvals for the tools it owns.
  ///
  /// A rule about one tool belongs to that tool. Approving every write into a
  /// shell the user already allowed is a fact about `exec_command`, not
  /// something the shared permission code should know a tool name to express.
  ApprovalPolicy decoratePolicy(ApprovalPolicy inner, AgentToolScope scope) =>
      inner;

  /// Text this capability contributes to the system prompt, or null.
  ///
  /// A tool that needs the model told how to use it says so itself, so the
  /// prompt never names a tool that is not in the turn.
  String? promptFragment(AgentToolScope scope) => null;
}

/// A provider whose tools exist exactly when the turn selected its id.
abstract base class SelectableToolProvider extends AgentToolProvider {
  /// Allows subclasses to be const.
  const SelectableToolProvider();

  /// Builds the tools of a turn that selected this capability.
  List<AgentTool> build(AgentToolScope scope);

  @override
  List<AgentTool> create(AgentToolScope scope) =>
      scope.selectedToolIds.contains(id) ? build(scope) : const <AgentTool>[];
}

/// A capability that replaces the model-facing tools with an orchestration
/// surface while retaining the original tools for nested dispatch.
abstract base class AgentToolSurfaceProvider extends AgentToolProvider {
  /// Allows subclasses to be const.
  const AgentToolSurfaceProvider();

  /// Builds the direct surface over all tools selected for this turn.
  AgentToolSurface buildSurface(
    AgentToolScope scope,
    List<AgentTool> nestedTools,
  );

  @override
  List<AgentTool> create(AgentToolScope scope) => const <AgentTool>[];
}

/// The direct and nested halves contributed by an orchestration surface.
final class AgentToolSurface {
  /// Creates an orchestration surface.
  const AgentToolSurface({
    required this.tools,
    required this.nestedTools,
    this.promptFragment,
  });

  /// Tools advertised to the model.
  final List<AgentTool> tools;

  /// Tools callable only through the orchestration surface.
  final List<AgentTool> nestedTools;

  /// Instructions describing the nested API.
  final String? promptFragment;
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
  List<AgentToolDefinition> get catalog => <AgentToolDefinition>[
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

  /// Builds everything one turn takes from its capabilities.
  ///
  /// Each capability is asked once, and only the ones that produced a tool go
  /// on to shape the turn's approvals and system prompt: a rule or a paragraph
  /// about a tool the model was never given would describe nothing.
  ///
  /// Ids this registry does not know are handed to [external], which is how
  /// MCP tools published at runtime join a turn without being compiled in.
  AgentToolTurn build(
    AgentToolScope scope, {
    AgentTool? Function(String id)? external,
  }) {
    final known = <String>{for (final provider in _providers) provider.id};
    final tools = <AgentTool>[];
    final present = <AgentToolProvider>[];
    for (final provider in _providers) {
      if (provider is AgentToolSurfaceProvider) continue;
      final built = provider.create(scope);
      if (built.isEmpty) continue;
      present.add(provider);
      tools.addAll(built);
    }
    for (final id in scope.selectedToolIds) {
      if (known.contains(id)) continue;
      final tool = external?.call(id);
      if (tool != null) tools.add(tool);
    }
    final surfaces = _providers
        .whereType<AgentToolSurfaceProvider>()
        .where((provider) => scope.selectedToolIds.contains(provider.id))
        .toList(growable: false);
    if (surfaces.length > 1) {
      throw StateError('Only one agent tool surface may be selected.');
    }
    final surface = surfaces.isEmpty
        ? null
        : surfaces.single.buildSurface(
            scope,
            List<AgentTool>.unmodifiable(tools),
          );
    if (surfaces.isNotEmpty) present.add(surfaces.single);
    return AgentToolTurn._(
      tools: List<AgentTool>.unmodifiable(surface?.tools ?? tools),
      nestedTools: List<AgentTool>.unmodifiable(
        surface?.nestedTools ?? const <AgentTool>[],
      ),
      promptFragments: List<String>.unmodifiable(<String>[
        for (final provider in present) ?provider.promptFragment(scope),
        ?surface?.promptFragment,
      ]),
      decorate: (inner) {
        var policy = inner;
        for (final provider in present) {
          policy = provider.decoratePolicy(policy, scope);
        }
        return policy;
      },
    );
  }
}

/// What one turn's capabilities contribute to it.
final class AgentToolTurn {
  const AgentToolTurn._({
    required this.tools,
    required this.nestedTools,
    required this.promptFragments,
    required this._decorate,
  });

  /// Every tool this turn may call.
  final List<AgentTool> tools;

  /// Tools available only to a selected orchestration surface.
  final List<AgentTool> nestedTools;

  /// System-prompt paragraphs contributed by the capabilities present.
  final List<String> promptFragments;

  final ApprovalPolicy Function(ApprovalPolicy inner) _decorate;

  /// Wraps [inner] with the approval rules of the capabilities present.
  ApprovalPolicy decoratePolicy(ApprovalPolicy inner) => _decorate(inner);
}
