// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_definitions_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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
         retry: noAutomaticRetry,
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
    r'7153e655a2d53e789006adeace46b077c48b8577';

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
        retry: noAutomaticRetry,
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
