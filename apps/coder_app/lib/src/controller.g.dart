// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// ConnectionController defines a public contract.

@ProviderFor(ConnectionController)
final connectionControllerProvider = ConnectionControllerProvider._();

/// ConnectionController defines a public contract.
final class ConnectionControllerProvider
    extends $AsyncNotifierProvider<ConnectionController, ConnectionSnapshot?> {
  /// ConnectionController defines a public contract.
  ConnectionControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'connectionControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$connectionControllerHash();

  @$internal
  @override
  ConnectionController create() => ConnectionController();
}

String _$connectionControllerHash() =>
    r'93b00ba6e8cd21f9fe002a68d5a543fe6a49a8bf';

/// ConnectionController defines a public contract.

abstract class _$ConnectionController
    extends $AsyncNotifier<ConnectionSnapshot?> {
  FutureOr<ConnectionSnapshot?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<ConnectionSnapshot?>, ConnectionSnapshot?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ConnectionSnapshot?>, ConnectionSnapshot?>,
              AsyncValue<ConnectionSnapshot?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// WorkspacesController defines a public contract.

@ProviderFor(WorkspacesController)
final workspacesControllerProvider = WorkspacesControllerProvider._();

/// WorkspacesController defines a public contract.
final class WorkspacesControllerProvider
    extends $AsyncNotifierProvider<WorkspacesController, List<WorkspaceDto>> {
  /// WorkspacesController defines a public contract.
  WorkspacesControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'workspacesControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$workspacesControllerHash();

  @$internal
  @override
  WorkspacesController create() => WorkspacesController();
}

String _$workspacesControllerHash() =>
    r'90cd73f2dc7e2aedfa9f2d4478976102ea05e83e';

/// WorkspacesController defines a public contract.

abstract class _$WorkspacesController
    extends $AsyncNotifier<List<WorkspaceDto>> {
  FutureOr<List<WorkspaceDto>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<WorkspaceDto>>, List<WorkspaceDto>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<WorkspaceDto>>, List<WorkspaceDto>>,
              AsyncValue<List<WorkspaceDto>>,
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
    required String? super.argument,
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
        '($argument)';
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

String _$agentsControllerHash() => r'0bde409a8933464a780ecc05ce339d457e1254e5';

/// AgentsController defines a public contract.

final class AgentsControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          AgentsController,
          AsyncValue<List<AgentDto>>,
          List<AgentDto>,
          FutureOr<List<AgentDto>>,
          String?
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

  AgentsControllerProvider call(String? workspaceId) =>
      AgentsControllerProvider._(argument: workspaceId, from: this);

  @override
  String toString() => r'agentsControllerProvider';
}

/// AgentsController defines a public contract.

abstract class _$AgentsController extends $AsyncNotifier<List<AgentDto>> {
  late final _$args = ref.$arg as String?;
  String? get workspaceId => _$args;

  FutureOr<List<AgentDto>> build(String? workspaceId);
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
    required String? super.argument,
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
        '($argument)';
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
    r'f17c25b3790e1e504e8928df9ff1dc1c4915fa23';

/// ConversationController defines a public contract.

final class ConversationControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          ConversationController,
          AsyncValue<ConversationState>,
          ConversationState,
          FutureOr<ConversationState>,
          String?
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

  ConversationControllerProvider call(String? agentId) =>
      ConversationControllerProvider._(argument: agentId, from: this);

  @override
  String toString() => r'conversationControllerProvider';
}

/// ConversationController defines a public contract.

abstract class _$ConversationController
    extends $AsyncNotifier<ConversationState> {
  late final _$args = ref.$arg as String?;
  String? get agentId => _$args;

  FutureOr<ConversationState> build(String? agentId);
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
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// ProviderSettingsController defines a public contract.

@ProviderFor(ProviderSettingsController)
final providerSettingsControllerProvider =
    ProviderSettingsControllerProvider._();

/// ProviderSettingsController defines a public contract.
final class ProviderSettingsControllerProvider
    extends
        $AsyncNotifierProvider<
          ProviderSettingsController,
          ProviderSettingsState?
        > {
  /// ProviderSettingsController defines a public contract.
  ProviderSettingsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'providerSettingsControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$providerSettingsControllerHash();

  @$internal
  @override
  ProviderSettingsController create() => ProviderSettingsController();
}

String _$providerSettingsControllerHash() =>
    r'03621d9e39f39cefe65006e2dc39074be9526428';

/// ProviderSettingsController defines a public contract.

abstract class _$ProviderSettingsController
    extends $AsyncNotifier<ProviderSettingsState?> {
  FutureOr<ProviderSettingsState?> build();
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
    return element.handleCreate(ref, build);
  }
}
