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
    r'7edaa99e7724e7c887690bfb535273ed1a30981d';

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
    r'f60475a0d3fd4917df1a10dfedf7867b9f5c42ab';

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
         retry: null,
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
    r'14470492bc6382696ec61623410e8599adbd2a40';

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
        retry: null,
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
    r'fa5778398eb8417c6f2a38812edd31fcbd28fab7';

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
    r'2292ba02b273cc1b4a5bddbc4bfe4e3fb06374cd';

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
    r'd92b6e6cd4b7c10c9f1f4c52936c2bfb6ef92253';

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
    r'5c20b1f9145555cf008db003476887083263e7b8';

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
    r'148b9e3f09318643e1268179871e538c40d3d9b7';

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
