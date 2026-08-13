// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_tabs_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Owns local workspace tabs and pane layout independently per worktree.

@ProviderFor(SessionTabsController)
final sessionTabsControllerProvider = SessionTabsControllerFamily._();

/// Owns local workspace tabs and pane layout independently per worktree.
final class SessionTabsControllerProvider
    extends $AsyncNotifierProvider<SessionTabsController, SessionTabsState> {
  /// Owns local workspace tabs and pane layout independently per worktree.
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
    r'819638f9bc73b72de7ba3789955d1802ce8ca885';

/// Owns local workspace tabs and pane layout independently per worktree.

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

  /// Owns local workspace tabs and pane layout independently per worktree.

  SessionTabsControllerProvider call(WorkspaceSelection selection) =>
      SessionTabsControllerProvider._(argument: selection, from: this);

  @override
  String toString() => r'sessionTabsControllerProvider';
}

/// Owns local workspace tabs and pane layout independently per worktree.

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
