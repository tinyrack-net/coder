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
    r'1cd01bbf7380d379c71d714129609bf780001fa9';

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

/// AgentsController defines a public contract.

@ProviderFor(AgentsController)
final agentsControllerProvider = AgentsControllerFamily._();

/// AgentsController defines a public contract.
final class AgentsControllerProvider
    extends $AsyncNotifierProvider<AgentsController, List<AgentDto>> {
  /// AgentsController defines a public contract.
  AgentsControllerProvider._({
    required AgentsControllerFamily super.from,
    required (String, String?) super.argument,
  }) : super(
         retry: null,
         name: r'agentsControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$agentsControllerHash();

  @override
  String toString() {
    return r'agentsControllerProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  AgentsController create() => AgentsController();

  @override
  bool operator ==(Object other) {
    return other is AgentsControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$agentsControllerHash() => r'07c302f3e58214d248267cd8157baeb603b13c14';

/// AgentsController defines a public contract.

final class AgentsControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          AgentsController,
          AsyncValue<List<AgentDto>>,
          List<AgentDto>,
          FutureOr<List<AgentDto>>,
          (String, String?)
        > {
  AgentsControllerFamily._()
    : super(
        retry: null,
        name: r'agentsControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// AgentsController defines a public contract.

  AgentsControllerProvider call(String hostId, String? worktreeId) =>
      AgentsControllerProvider._(argument: (hostId, worktreeId), from: this);

  @override
  String toString() => r'agentsControllerProvider';
}

/// AgentsController defines a public contract.

abstract class _$AgentsController extends $AsyncNotifier<List<AgentDto>> {
  late final _$args = ref.$arg as (String, String?);
  String get hostId => _$args.$1;
  String? get worktreeId => _$args.$2;

  FutureOr<List<AgentDto>> build(String hostId, String? worktreeId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<AgentDto>>, List<AgentDto>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<AgentDto>>, List<AgentDto>>,
              AsyncValue<List<AgentDto>>,
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
    r'11c6749b8fc3bfb3c0a415c0dfe102860f2ffc07';

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
    r'dd73111cbc37321541072256ce24f11d830a8f33';

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

  ConversationControllerProvider call(String hostId, String? agentId) =>
      ConversationControllerProvider._(argument: (hostId, agentId), from: this);

  @override
  String toString() => r'conversationControllerProvider';
}

/// ConversationController defines a public contract.

abstract class _$ConversationController
    extends $AsyncNotifier<ConversationState> {
  late final _$args = ref.$arg as (String, String?);
  String get hostId => _$args.$1;
  String? get agentId => _$args.$2;

  FutureOr<ConversationState> build(String hostId, String? agentId);
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
    r'3acb9b0d8e72bc00c45a657d5c267d1bde0fedf7';

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
