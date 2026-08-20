// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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
    r'828a9a812f5b2f2c28561805de20161ce2cb1808';

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
