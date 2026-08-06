// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Riverpod bridge exposing the independently testable [HostRegistry].

@ProviderFor(HostRegistryController)
final hostRegistryControllerProvider = HostRegistryControllerProvider._();

/// Riverpod bridge exposing the independently testable [HostRegistry].
final class HostRegistryControllerProvider
    extends $AsyncNotifierProvider<HostRegistryController, HostRegistryState> {
  /// Riverpod bridge exposing the independently testable [HostRegistry].
  HostRegistryControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'hostRegistryControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$hostRegistryControllerHash();

  @$internal
  @override
  HostRegistryController create() => HostRegistryController();
}

String _$hostRegistryControllerHash() =>
    r'36f0e7027e18ea1f4e9fe4496ce38b100ab5cf2b';

/// Riverpod bridge exposing the independently testable [HostRegistry].

abstract class _$HostRegistryController
    extends $AsyncNotifier<HostRegistryState> {
  FutureOr<HostRegistryState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<HostRegistryState>, HostRegistryState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<HostRegistryState>, HostRegistryState>,
              AsyncValue<HostRegistryState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The daemon that host-scoped screens read and write.
///
/// The saved [AppSettings.lastActiveHostId] wins so the choice survives a
/// restart and stays in step with the workspace window. It is allowed to name
/// an offline daemon, so the fallbacks only run when it names no daemon at all.

@ProviderFor(activeHostId)
final activeHostIdProvider = ActiveHostIdProvider._();

/// The daemon that host-scoped screens read and write.
///
/// The saved [AppSettings.lastActiveHostId] wins so the choice survives a
/// restart and stays in step with the workspace window. It is allowed to name
/// an offline daemon, so the fallbacks only run when it names no daemon at all.

final class ActiveHostIdProvider
    extends $FunctionalProvider<String?, String?, String?>
    with $Provider<String?> {
  /// The daemon that host-scoped screens read and write.
  ///
  /// The saved [AppSettings.lastActiveHostId] wins so the choice survives a
  /// restart and stays in step with the workspace window. It is allowed to name
  /// an offline daemon, so the fallbacks only run when it names no daemon at all.
  ActiveHostIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeHostIdProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeHostIdHash();

  @$internal
  @override
  $ProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String? create(Ref ref) {
    return activeHostId(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$activeHostIdHash() => r'bd97f7052a03788a600dc17ce51a2db1b3956cb5';

/// Tracks whether the saved worktree was already restored this run.
///
/// The workspace page is rebuilt whenever the route changes, so the guard has
/// to outlive its state or leaving a session would snap straight back into it.

@ProviderFor(SelectionRestoreController)
final selectionRestoreControllerProvider =
    SelectionRestoreControllerProvider._();

/// Tracks whether the saved worktree was already restored this run.
///
/// The workspace page is rebuilt whenever the route changes, so the guard has
/// to outlive its state or leaving a session would snap straight back into it.
final class SelectionRestoreControllerProvider
    extends $NotifierProvider<SelectionRestoreController, bool> {
  /// Tracks whether the saved worktree was already restored this run.
  ///
  /// The workspace page is rebuilt whenever the route changes, so the guard has
  /// to outlive its state or leaving a session would snap straight back into it.
  SelectionRestoreControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectionRestoreControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectionRestoreControllerHash();

  @$internal
  @override
  SelectionRestoreController create() => SelectionRestoreController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$selectionRestoreControllerHash() =>
    r'392030769d1af6173d49ecf3505645831dd34e2a';

/// Tracks whether the saved worktree was already restored this run.
///
/// The workspace page is rebuilt whenever the route changes, so the guard has
/// to outlive its state or leaving a session would snap straight back into it.

abstract class _$SelectionRestoreController extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Loads every online daemon catalog without merging daemon-local IDs.

@ProviderFor(WorkspaceCatalogController)
final workspaceCatalogControllerProvider =
    WorkspaceCatalogControllerProvider._();

/// Loads every online daemon catalog without merging daemon-local IDs.
final class WorkspaceCatalogControllerProvider
    extends
        $AsyncNotifierProvider<
          WorkspaceCatalogController,
          UnifiedWorkspaceCatalogState
        > {
  /// Loads every online daemon catalog without merging daemon-local IDs.
  WorkspaceCatalogControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'workspaceCatalogControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$workspaceCatalogControllerHash();

  @$internal
  @override
  WorkspaceCatalogController create() => WorkspaceCatalogController();
}

String _$workspaceCatalogControllerHash() =>
    r'baf0d71d616d191aa43113e382375c640bc17e7f';

/// Loads every online daemon catalog without merging daemon-local IDs.

abstract class _$WorkspaceCatalogController
    extends $AsyncNotifier<UnifiedWorkspaceCatalogState> {
  FutureOr<UnifiedWorkspaceCatalogState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<UnifiedWorkspaceCatalogState>,
              UnifiedWorkspaceCatalogState
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<UnifiedWorkspaceCatalogState>,
                UnifiedWorkspaceCatalogState
              >,
              AsyncValue<UnifiedWorkspaceCatalogState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Lists local Git branches for one repository.

@ProviderFor(gitBranches)
final gitBranchesProvider = GitBranchesFamily._();

/// Lists local Git branches for one repository.

final class GitBranchesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<GitBranchDto>>,
          List<GitBranchDto>,
          FutureOr<List<GitBranchDto>>
        >
    with
        $FutureModifier<List<GitBranchDto>>,
        $FutureProvider<List<GitBranchDto>> {
  /// Lists local Git branches for one repository.
  GitBranchesProvider._({
    required GitBranchesFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'gitBranchesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$gitBranchesHash();

  @override
  String toString() {
    return r'gitBranchesProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<GitBranchDto>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<GitBranchDto>> create(Ref ref) {
    final argument = this.argument as (String, String);
    return gitBranches(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is GitBranchesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$gitBranchesHash() => r'8ed117daa9605b3730061862348d18685bf4ee8b';

/// Lists local Git branches for one repository.

final class GitBranchesFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<GitBranchDto>>,
          (String, String)
        > {
  GitBranchesFamily._()
    : super(
        retry: null,
        name: r'gitBranchesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Lists local Git branches for one repository.

  GitBranchesProvider call(String hostId, String workspaceId) =>
      GitBranchesProvider._(argument: (hostId, workspaceId), from: this);

  @override
  String toString() => r'gitBranchesProvider';
}

/// SessionsController defines a public contract.

@ProviderFor(SessionsController)
final sessionsControllerProvider = SessionsControllerFamily._();

/// SessionsController defines a public contract.
final class SessionsControllerProvider
    extends $AsyncNotifierProvider<SessionsController, List<SessionDto>> {
  /// SessionsController defines a public contract.
  SessionsControllerProvider._({
    required SessionsControllerFamily super.from,
    required (String, String?) super.argument,
  }) : super(
         retry: null,
         name: r'sessionsControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$sessionsControllerHash();

  @override
  String toString() {
    return r'sessionsControllerProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  SessionsController create() => SessionsController();

  @override
  bool operator ==(Object other) {
    return other is SessionsControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sessionsControllerHash() =>
    r'dfab8c71df5039fa3bf857815ba41a0d735c6767';

/// SessionsController defines a public contract.

final class SessionsControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          SessionsController,
          AsyncValue<List<SessionDto>>,
          List<SessionDto>,
          FutureOr<List<SessionDto>>,
          (String, String?)
        > {
  SessionsControllerFamily._()
    : super(
        retry: null,
        name: r'sessionsControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// SessionsController defines a public contract.

  SessionsControllerProvider call(String hostId, String? worktreeId) =>
      SessionsControllerProvider._(argument: (hostId, worktreeId), from: this);

  @override
  String toString() => r'sessionsControllerProvider';
}

/// SessionsController defines a public contract.

abstract class _$SessionsController extends $AsyncNotifier<List<SessionDto>> {
  late final _$args = ref.$arg as (String, String?);
  String get hostId => _$args.$1;
  String? get worktreeId => _$args.$2;

  FutureOr<List<SessionDto>> build(String hostId, String? worktreeId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<SessionDto>>, List<SessionDto>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<SessionDto>>, List<SessionDto>>,
              AsyncValue<List<SessionDto>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
}

/// Loads and edits the `coder.json` worktree hooks of one project.

@ProviderFor(ProjectSettingsController)
final projectSettingsControllerProvider = ProjectSettingsControllerFamily._();

/// Loads and edits the `coder.json` worktree hooks of one project.
final class ProjectSettingsControllerProvider
    extends
        $AsyncNotifierProvider<
          ProjectSettingsController,
          ProjectSettingsResultDto
        > {
  /// Loads and edits the `coder.json` worktree hooks of one project.
  ProjectSettingsControllerProvider._({
    required ProjectSettingsControllerFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: _noAutomaticRetry,
         name: r'projectSettingsControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$projectSettingsControllerHash();

  @override
  String toString() {
    return r'projectSettingsControllerProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  ProjectSettingsController create() => ProjectSettingsController();

  @override
  bool operator ==(Object other) {
    return other is ProjectSettingsControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$projectSettingsControllerHash() =>
    r'71d385e3d211e618a4ac9cd8b761599b0c6b2798';

/// Loads and edits the `coder.json` worktree hooks of one project.

final class ProjectSettingsControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          ProjectSettingsController,
          AsyncValue<ProjectSettingsResultDto>,
          ProjectSettingsResultDto,
          FutureOr<ProjectSettingsResultDto>,
          (String, String)
        > {
  ProjectSettingsControllerFamily._()
    : super(
        retry: _noAutomaticRetry,
        name: r'projectSettingsControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Loads and edits the `coder.json` worktree hooks of one project.

  ProjectSettingsControllerProvider call(String hostId, String workspaceId) =>
      ProjectSettingsControllerProvider._(
        argument: (hostId, workspaceId),
        from: this,
      );

  @override
  String toString() => r'projectSettingsControllerProvider';
}

/// Loads and edits the `coder.json` worktree hooks of one project.

abstract class _$ProjectSettingsController
    extends $AsyncNotifier<ProjectSettingsResultDto> {
  late final _$args = ref.$arg as (String, String);
  String get hostId => _$args.$1;
  String get workspaceId => _$args.$2;

  FutureOr<ProjectSettingsResultDto> build(String hostId, String workspaceId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<ProjectSettingsResultDto>,
              ProjectSettingsResultDto
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<ProjectSettingsResultDto>,
                ProjectSettingsResultDto
              >,
              AsyncValue<ProjectSettingsResultDto>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
}

/// Loads and edits one daemon's MCP server configuration.

@ProviderFor(McpServersController)
final mcpServersControllerProvider = McpServersControllerFamily._();

/// Loads and edits one daemon's MCP server configuration.
final class McpServersControllerProvider
    extends $AsyncNotifierProvider<McpServersController, McpServersState> {
  /// Loads and edits one daemon's MCP server configuration.
  McpServersControllerProvider._({
    required McpServersControllerFamily super.from,
    required (String, String?) super.argument,
  }) : super(
         retry: null,
         name: r'mcpServersControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$mcpServersControllerHash();

  @override
  String toString() {
    return r'mcpServersControllerProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  McpServersController create() => McpServersController();

  @override
  bool operator ==(Object other) {
    return other is McpServersControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$mcpServersControllerHash() =>
    r'3b690549082a6543aca42e1e99bb4ad8354e0704';

/// Loads and edits one daemon's MCP server configuration.

final class McpServersControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          McpServersController,
          AsyncValue<McpServersState>,
          McpServersState,
          FutureOr<McpServersState>,
          (String, String?)
        > {
  McpServersControllerFamily._()
    : super(
        retry: null,
        name: r'mcpServersControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Loads and edits one daemon's MCP server configuration.

  McpServersControllerProvider call(String hostId, String? worktreeId) =>
      McpServersControllerProvider._(
        argument: (hostId, worktreeId),
        from: this,
      );

  @override
  String toString() => r'mcpServersControllerProvider';
}

/// Loads and edits one daemon's MCP server configuration.

abstract class _$McpServersController extends $AsyncNotifier<McpServersState> {
  late final _$args = ref.$arg as (String, String?);
  String get hostId => _$args.$1;
  String? get worktreeId => _$args.$2;

  FutureOr<McpServersState> build(String hostId, String? worktreeId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<McpServersState>, McpServersState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<McpServersState>, McpServersState>,
              AsyncValue<McpServersState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
}

/// Loads and edits one daemon's Markdown agent files.

@ProviderFor(AgentDefinitionsController)
final agentDefinitionsControllerProvider = AgentDefinitionsControllerFamily._();

/// Loads and edits one daemon's Markdown agent files.
final class AgentDefinitionsControllerProvider
    extends
        $AsyncNotifierProvider<
          AgentDefinitionsController,
          AgentDefinitionsState
        > {
  /// Loads and edits one daemon's Markdown agent files.
  AgentDefinitionsControllerProvider._({
    required AgentDefinitionsControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'agentDefinitionsControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$agentDefinitionsControllerHash();

  @override
  String toString() {
    return r'agentDefinitionsControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  AgentDefinitionsController create() => AgentDefinitionsController();

  @override
  bool operator ==(Object other) {
    return other is AgentDefinitionsControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$agentDefinitionsControllerHash() =>
    r'14375fd4732aa002b984a91de1c7a17c5a2180f8';

/// Loads and edits one daemon's Markdown agent files.

final class AgentDefinitionsControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          AgentDefinitionsController,
          AsyncValue<AgentDefinitionsState>,
          AgentDefinitionsState,
          FutureOr<AgentDefinitionsState>,
          String
        > {
  AgentDefinitionsControllerFamily._()
    : super(
        retry: null,
        name: r'agentDefinitionsControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Loads and edits one daemon's Markdown agent files.

  AgentDefinitionsControllerProvider call(String hostId) =>
      AgentDefinitionsControllerProvider._(argument: hostId, from: this);

  @override
  String toString() => r'agentDefinitionsControllerProvider';
}

/// Loads and edits one daemon's Markdown agent files.

abstract class _$AgentDefinitionsController
    extends $AsyncNotifier<AgentDefinitionsState> {
  late final _$args = ref.$arg as String;
  String get hostId => _$args;

  FutureOr<AgentDefinitionsState> build(String hostId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<AgentDefinitionsState>, AgentDefinitionsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<AgentDefinitionsState>,
                AgentDefinitionsState
              >,
              AsyncValue<AgentDefinitionsState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// Loads and edits the skills one daemon offers, optionally for one project.
///
/// A null [SkillsController.workspaceId] shows only the built-in, user-home,
/// and daemon-config sources; naming a workspace layers its
/// `.agents/skills` on top.

@ProviderFor(SkillsController)
final skillsControllerProvider = SkillsControllerFamily._();

/// Loads and edits the skills one daemon offers, optionally for one project.
///
/// A null [SkillsController.workspaceId] shows only the built-in, user-home,
/// and daemon-config sources; naming a workspace layers its
/// `.agents/skills` on top.
final class SkillsControllerProvider
    extends $AsyncNotifierProvider<SkillsController, List<SkillDto>> {
  /// Loads and edits the skills one daemon offers, optionally for one project.
  ///
  /// A null [SkillsController.workspaceId] shows only the built-in, user-home,
  /// and daemon-config sources; naming a workspace layers its
  /// `.agents/skills` on top.
  SkillsControllerProvider._({
    required SkillsControllerFamily super.from,
    required (String, String?) super.argument,
  }) : super(
         retry: null,
         name: r'skillsControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$skillsControllerHash();

  @override
  String toString() {
    return r'skillsControllerProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  SkillsController create() => SkillsController();

  @override
  bool operator ==(Object other) {
    return other is SkillsControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$skillsControllerHash() => r'63c0a66af5684c17434930e2686dc4dbba2558c7';

/// Loads and edits the skills one daemon offers, optionally for one project.
///
/// A null [SkillsController.workspaceId] shows only the built-in, user-home,
/// and daemon-config sources; naming a workspace layers its
/// `.agents/skills` on top.

final class SkillsControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          SkillsController,
          AsyncValue<List<SkillDto>>,
          List<SkillDto>,
          FutureOr<List<SkillDto>>,
          (String, String?)
        > {
  SkillsControllerFamily._()
    : super(
        retry: null,
        name: r'skillsControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Loads and edits the skills one daemon offers, optionally for one project.
  ///
  /// A null [SkillsController.workspaceId] shows only the built-in, user-home,
  /// and daemon-config sources; naming a workspace layers its
  /// `.agents/skills` on top.

  SkillsControllerProvider call(String hostId, String? workspaceId) =>
      SkillsControllerProvider._(argument: (hostId, workspaceId), from: this);

  @override
  String toString() => r'skillsControllerProvider';
}

/// Loads and edits the skills one daemon offers, optionally for one project.
///
/// A null [SkillsController.workspaceId] shows only the built-in, user-home,
/// and daemon-config sources; naming a workspace layers its
/// `.agents/skills` on top.

abstract class _$SkillsController extends $AsyncNotifier<List<SkillDto>> {
  late final _$args = ref.$arg as (String, String?);
  String get hostId => _$args.$1;
  String? get workspaceId => _$args.$2;

  FutureOr<List<SkillDto>> build(String hostId, String? workspaceId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<SkillDto>>, List<SkillDto>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<SkillDto>>, List<SkillDto>>,
              AsyncValue<List<SkillDto>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
}

/// Loads the agent commands one daemon offers, optionally for one project.
///
/// A null [AgentCommandsController.workspaceId] shows only the user-home and
/// daemon-config sources; naming a workspace layers its `.agents/commands` on
/// top.

@ProviderFor(AgentCommandsController)
final agentCommandsControllerProvider = AgentCommandsControllerFamily._();

/// Loads the agent commands one daemon offers, optionally for one project.
///
/// A null [AgentCommandsController.workspaceId] shows only the user-home and
/// daemon-config sources; naming a workspace layers its `.agents/commands` on
/// top.
final class AgentCommandsControllerProvider
    extends
        $AsyncNotifierProvider<AgentCommandsController, List<AgentCommandDto>> {
  /// Loads the agent commands one daemon offers, optionally for one project.
  ///
  /// A null [AgentCommandsController.workspaceId] shows only the user-home and
  /// daemon-config sources; naming a workspace layers its `.agents/commands` on
  /// top.
  AgentCommandsControllerProvider._({
    required AgentCommandsControllerFamily super.from,
    required (String, String?) super.argument,
  }) : super(
         retry: null,
         name: r'agentCommandsControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$agentCommandsControllerHash();

  @override
  String toString() {
    return r'agentCommandsControllerProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  AgentCommandsController create() => AgentCommandsController();

  @override
  bool operator ==(Object other) {
    return other is AgentCommandsControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$agentCommandsControllerHash() =>
    r'40f6c0069a39751e3d5ee0f70bfa450154b953fc';

/// Loads the agent commands one daemon offers, optionally for one project.
///
/// A null [AgentCommandsController.workspaceId] shows only the user-home and
/// daemon-config sources; naming a workspace layers its `.agents/commands` on
/// top.

final class AgentCommandsControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          AgentCommandsController,
          AsyncValue<List<AgentCommandDto>>,
          List<AgentCommandDto>,
          FutureOr<List<AgentCommandDto>>,
          (String, String?)
        > {
  AgentCommandsControllerFamily._()
    : super(
        retry: null,
        name: r'agentCommandsControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Loads the agent commands one daemon offers, optionally for one project.
  ///
  /// A null [AgentCommandsController.workspaceId] shows only the user-home and
  /// daemon-config sources; naming a workspace layers its `.agents/commands` on
  /// top.

  AgentCommandsControllerProvider call(String hostId, String? workspaceId) =>
      AgentCommandsControllerProvider._(
        argument: (hostId, workspaceId),
        from: this,
      );

  @override
  String toString() => r'agentCommandsControllerProvider';
}

/// Loads the agent commands one daemon offers, optionally for one project.
///
/// A null [AgentCommandsController.workspaceId] shows only the user-home and
/// daemon-config sources; naming a workspace layers its `.agents/commands` on
/// top.

abstract class _$AgentCommandsController
    extends $AsyncNotifier<List<AgentCommandDto>> {
  late final _$args = ref.$arg as (String, String?);
  String get hostId => _$args.$1;
  String? get workspaceId => _$args.$2;

  FutureOr<List<AgentCommandDto>> build(String hostId, String? workspaceId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<List<AgentCommandDto>>, List<AgentCommandDto>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<AgentCommandDto>>,
                List<AgentCommandDto>
              >,
              AsyncValue<List<AgentCommandDto>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
}

/// Merges the app, agent, and skill sources into the composer's `/` catalog.

@ProviderFor(composerCommands)
final composerCommandsProvider = ComposerCommandsFamily._();

/// Merges the app, agent, and skill sources into the composer's `/` catalog.

final class ComposerCommandsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ComposerCommand>>,
          List<ComposerCommand>,
          FutureOr<List<ComposerCommand>>
        >
    with
        $FutureModifier<List<ComposerCommand>>,
        $FutureProvider<List<ComposerCommand>> {
  /// Merges the app, agent, and skill sources into the composer's `/` catalog.
  ComposerCommandsProvider._({
    required ComposerCommandsFamily super.from,
    required (String, String?) super.argument,
  }) : super(
         retry: null,
         name: r'composerCommandsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$composerCommandsHash();

  @override
  String toString() {
    return r'composerCommandsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<ComposerCommand>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ComposerCommand>> create(Ref ref) {
    final argument = this.argument as (String, String?);
    return composerCommands(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is ComposerCommandsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$composerCommandsHash() => r'eb05c67ffe9dc21f15dfeff6d1236d73f21e8632';

/// Merges the app, agent, and skill sources into the composer's `/` catalog.

final class ComposerCommandsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<ComposerCommand>>,
          (String, String?)
        > {
  ComposerCommandsFamily._()
    : super(
        retry: null,
        name: r'composerCommandsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Merges the app, agent, and skill sources into the composer's `/` catalog.

  ComposerCommandsProvider call(String hostId, String? workspaceId) =>
      ComposerCommandsProvider._(argument: (hostId, workspaceId), from: this);

  @override
  String toString() => r'composerCommandsProvider';
}

/// Searches one worktree for the files an `@` query could mention.
///
/// The query is part of the provider key, so each keystroke creates a new
/// provider and disposes the previous one. Cancelling the timer on dispose is
/// therefore the debounce itself, with no controller state to keep in sync.

@ProviderFor(composerFileSearch)
final composerFileSearchProvider = ComposerFileSearchFamily._();

/// Searches one worktree for the files an `@` query could mention.
///
/// The query is part of the provider key, so each keystroke creates a new
/// provider and disposes the previous one. Cancelling the timer on dispose is
/// therefore the debounce itself, with no controller state to keep in sync.

final class ComposerFileSearchProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<FileMatchDto>>,
          List<FileMatchDto>,
          FutureOr<List<FileMatchDto>>
        >
    with
        $FutureModifier<List<FileMatchDto>>,
        $FutureProvider<List<FileMatchDto>> {
  /// Searches one worktree for the files an `@` query could mention.
  ///
  /// The query is part of the provider key, so each keystroke creates a new
  /// provider and disposes the previous one. Cancelling the timer on dispose is
  /// therefore the debounce itself, with no controller state to keep in sync.
  ComposerFileSearchProvider._({
    required ComposerFileSearchFamily super.from,
    required (String, String, String) super.argument,
  }) : super(
         retry: null,
         name: r'composerFileSearchProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$composerFileSearchHash();

  @override
  String toString() {
    return r'composerFileSearchProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<FileMatchDto>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<FileMatchDto>> create(Ref ref) {
    final argument = this.argument as (String, String, String);
    return composerFileSearch(ref, argument.$1, argument.$2, argument.$3);
  }

  @override
  bool operator ==(Object other) {
    return other is ComposerFileSearchProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$composerFileSearchHash() =>
    r'8bd5f1afe9645cf32c7a32c0e97ae9c32bb91a90';

/// Searches one worktree for the files an `@` query could mention.
///
/// The query is part of the provider key, so each keystroke creates a new
/// provider and disposes the previous one. Cancelling the timer on dispose is
/// therefore the debounce itself, with no controller state to keep in sync.

final class ComposerFileSearchFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<FileMatchDto>>,
          (String, String, String)
        > {
  ComposerFileSearchFamily._()
    : super(
        retry: null,
        name: r'composerFileSearchProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Searches one worktree for the files an `@` query could mention.
  ///
  /// The query is part of the provider key, so each keystroke creates a new
  /// provider and disposes the previous one. Cancelling the timer on dispose is
  /// therefore the debounce itself, with no controller state to keep in sync.

  ComposerFileSearchProvider call(
    String hostId,
    String worktreeId,
    String query,
  ) => ComposerFileSearchProvider._(
    argument: (hostId, worktreeId, query),
    from: this,
  );

  @override
  String toString() => r'composerFileSearchProvider';
}

/// Owns the live terminal catalog for one connected worktree.

@ProviderFor(TerminalsController)
final terminalsControllerProvider = TerminalsControllerFamily._();

/// Owns the live terminal catalog for one connected worktree.
final class TerminalsControllerProvider
    extends $AsyncNotifierProvider<TerminalsController, List<TerminalDto>> {
  /// Owns the live terminal catalog for one connected worktree.
  TerminalsControllerProvider._({
    required TerminalsControllerFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'terminalsControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$terminalsControllerHash();

  @override
  String toString() {
    return r'terminalsControllerProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  TerminalsController create() => TerminalsController();

  @override
  bool operator ==(Object other) {
    return other is TerminalsControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$terminalsControllerHash() =>
    r'6b6c7deecfb32bc0c1ec96af62761217f9ef4e74';

/// Owns the live terminal catalog for one connected worktree.

final class TerminalsControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          TerminalsController,
          AsyncValue<List<TerminalDto>>,
          List<TerminalDto>,
          FutureOr<List<TerminalDto>>,
          (String, String)
        > {
  TerminalsControllerFamily._()
    : super(
        retry: null,
        name: r'terminalsControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Owns the live terminal catalog for one connected worktree.

  TerminalsControllerProvider call(String hostId, String worktreeId) =>
      TerminalsControllerProvider._(argument: (hostId, worktreeId), from: this);

  @override
  String toString() => r'terminalsControllerProvider';
}

/// Owns the live terminal catalog for one connected worktree.

abstract class _$TerminalsController extends $AsyncNotifier<List<TerminalDto>> {
  late final _$args = ref.$arg as (String, String);
  String get hostId => _$args.$1;
  String get worktreeId => _$args.$2;

  FutureOr<List<TerminalDto>> build(String hostId, String worktreeId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<TerminalDto>>, List<TerminalDto>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<TerminalDto>>, List<TerminalDto>>,
              AsyncValue<List<TerminalDto>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
}

/// Owns local tab visibility independently for each host worktree.

@ProviderFor(SessionTabsController)
final sessionTabsControllerProvider = SessionTabsControllerFamily._();

/// Owns local tab visibility independently for each host worktree.
final class SessionTabsControllerProvider
    extends $AsyncNotifierProvider<SessionTabsController, SessionTabsState> {
  /// Owns local tab visibility independently for each host worktree.
  SessionTabsControllerProvider._({
    required SessionTabsControllerFamily super.from,
    required WorkspaceSelection super.argument,
  }) : super(
         retry: null,
         name: r'sessionTabsControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$sessionTabsControllerHash();

  @override
  String toString() {
    return r'sessionTabsControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  SessionTabsController create() => SessionTabsController();

  @override
  bool operator ==(Object other) {
    return other is SessionTabsControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sessionTabsControllerHash() =>
    r'2986d349755320d9bd03bf811d75fa5f6efc1ed9';

/// Owns local tab visibility independently for each host worktree.

final class SessionTabsControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          SessionTabsController,
          AsyncValue<SessionTabsState>,
          SessionTabsState,
          FutureOr<SessionTabsState>,
          WorkspaceSelection
        > {
  SessionTabsControllerFamily._()
    : super(
        retry: null,
        name: r'sessionTabsControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Owns local tab visibility independently for each host worktree.

  SessionTabsControllerProvider call(WorkspaceSelection selection) =>
      SessionTabsControllerProvider._(argument: selection, from: this);

  @override
  String toString() => r'sessionTabsControllerProvider';
}

/// Owns local tab visibility independently for each host worktree.

abstract class _$SessionTabsController
    extends $AsyncNotifier<SessionTabsState> {
  late final _$args = ref.$arg as WorkspaceSelection;
  WorkspaceSelection get selection => _$args;

  FutureOr<SessionTabsState> build(WorkspaceSelection selection);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<SessionTabsState>, SessionTabsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<SessionTabsState>, SessionTabsState>,
              AsyncValue<SessionTabsState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// Holds the composer selection used to create the next session.

@ProviderFor(SessionComposerDraftController)
final sessionComposerDraftControllerProvider =
    SessionComposerDraftControllerFamily._();

/// Holds the composer selection used to create the next session.
final class SessionComposerDraftControllerProvider
    extends
        $NotifierProvider<
          SessionComposerDraftController,
          SessionComposerDraft
        > {
  /// Holds the composer selection used to create the next session.
  SessionComposerDraftControllerProvider._({
    required SessionComposerDraftControllerFamily super.from,
    required (String, String?) super.argument,
  }) : super(
         retry: null,
         name: r'sessionComposerDraftControllerProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$sessionComposerDraftControllerHash();

  @override
  String toString() {
    return r'sessionComposerDraftControllerProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  SessionComposerDraftController create() => SessionComposerDraftController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SessionComposerDraft value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SessionComposerDraft>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SessionComposerDraftControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sessionComposerDraftControllerHash() =>
    r'35c8518316989fb5a4c0ecbfeeb39d9dd779fdee';

/// Holds the composer selection used to create the next session.

final class SessionComposerDraftControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          SessionComposerDraftController,
          SessionComposerDraft,
          SessionComposerDraft,
          SessionComposerDraft,
          (String, String?)
        > {
  SessionComposerDraftControllerFamily._()
    : super(
        retry: null,
        name: r'sessionComposerDraftControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// Holds the composer selection used to create the next session.

  SessionComposerDraftControllerProvider call(
    String hostId,
    String? worktreeId,
  ) => SessionComposerDraftControllerProvider._(
    argument: (hostId, worktreeId),
    from: this,
  );

  @override
  String toString() => r'sessionComposerDraftControllerProvider';
}

/// Holds the composer selection used to create the next session.

abstract class _$SessionComposerDraftController
    extends $Notifier<SessionComposerDraft> {
  late final _$args = ref.$arg as (String, String?);
  String get hostId => _$args.$1;
  String? get worktreeId => _$args.$2;

  SessionComposerDraft build(String hostId, String? worktreeId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SessionComposerDraft, SessionComposerDraft>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SessionComposerDraft, SessionComposerDraft>,
              SessionComposerDraft,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
}

/// ConversationController defines a public contract.

@ProviderFor(ConversationController)
final conversationControllerProvider = ConversationControllerFamily._();

/// ConversationController defines a public contract.
final class ConversationControllerProvider
    extends $AsyncNotifierProvider<ConversationController, ConversationState> {
  /// ConversationController defines a public contract.
  ConversationControllerProvider._({
    required ConversationControllerFamily super.from,
    required (String, String?) super.argument,
  }) : super(
         retry: null,
         name: r'conversationControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$conversationControllerHash();

  @override
  String toString() {
    return r'conversationControllerProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  ConversationController create() => ConversationController();

  @override
  bool operator ==(Object other) {
    return other is ConversationControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$conversationControllerHash() =>
    r'7f20e9ade8a8edafeb5e88bb2f31e64f28530873';

/// ConversationController defines a public contract.

final class ConversationControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          ConversationController,
          AsyncValue<ConversationState>,
          ConversationState,
          FutureOr<ConversationState>,
          (String, String?)
        > {
  ConversationControllerFamily._()
    : super(
        retry: null,
        name: r'conversationControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// ConversationController defines a public contract.

  ConversationControllerProvider call(String hostId, String? sessionId) =>
      ConversationControllerProvider._(
        argument: (hostId, sessionId),
        from: this,
      );

  @override
  String toString() => r'conversationControllerProvider';
}

/// ConversationController defines a public contract.

abstract class _$ConversationController
    extends $AsyncNotifier<ConversationState> {
  late final _$args = ref.$arg as (String, String?);
  String get hostId => _$args.$1;
  String? get sessionId => _$args.$2;

  FutureOr<ConversationState> build(String hostId, String? sessionId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<ConversationState>, ConversationState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ConversationState>, ConversationState>,
              AsyncValue<ConversationState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
}

/// ProviderSettingsController defines a public contract.

@ProviderFor(ProviderSettingsController)
final providerSettingsControllerProvider = ProviderSettingsControllerFamily._();

/// ProviderSettingsController defines a public contract.
final class ProviderSettingsControllerProvider
    extends
        $AsyncNotifierProvider<
          ProviderSettingsController,
          ProviderSettingsState?
        > {
  /// ProviderSettingsController defines a public contract.
  ProviderSettingsControllerProvider._({
    required ProviderSettingsControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'providerSettingsControllerProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$providerSettingsControllerHash();

  @override
  String toString() {
    return r'providerSettingsControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ProviderSettingsController create() => ProviderSettingsController();

  @override
  bool operator ==(Object other) {
    return other is ProviderSettingsControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$providerSettingsControllerHash() =>
    r'8fc609ad7e2f119fc9ec66c0c909b8b34efe79aa';

/// ProviderSettingsController defines a public contract.

final class ProviderSettingsControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          ProviderSettingsController,
          AsyncValue<ProviderSettingsState?>,
          ProviderSettingsState?,
          FutureOr<ProviderSettingsState?>,
          String
        > {
  ProviderSettingsControllerFamily._()
    : super(
        retry: null,
        name: r'providerSettingsControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// ProviderSettingsController defines a public contract.

  ProviderSettingsControllerProvider call(String hostId) =>
      ProviderSettingsControllerProvider._(argument: hostId, from: this);

  @override
  String toString() => r'providerSettingsControllerProvider';
}

/// ProviderSettingsController defines a public contract.

abstract class _$ProviderSettingsController
    extends $AsyncNotifier<ProviderSettingsState?> {
  late final _$args = ref.$arg as String;
  String get hostId => _$args;

  FutureOr<ProviderSettingsState?> build(String hostId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<ProviderSettingsState?>, ProviderSettingsState?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<ProviderSettingsState?>,
                ProviderSettingsState?
              >,
              AsyncValue<ProviderSettingsState?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
