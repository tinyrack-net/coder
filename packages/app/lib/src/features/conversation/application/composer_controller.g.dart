// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'composer_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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
    r'da88f9e75aad4b3087a00c58b33f0a933980a9e7';

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
    required (String, String?, String) super.argument,
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
    r'10a299f76021b316ed7fd53efdeca9354f1f28ec';

/// Holds the composer selection used to create the next session.

final class SessionComposerDraftControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          SessionComposerDraftController,
          SessionComposerDraft,
          SessionComposerDraft,
          SessionComposerDraft,
          (String, String?, String)
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
    String draftId,
  ) => SessionComposerDraftControllerProvider._(
    argument: (hostId, worktreeId, draftId),
    from: this,
  );

  @override
  String toString() => r'sessionComposerDraftControllerProvider';
}

/// Holds the composer selection used to create the next session.

abstract class _$SessionComposerDraftController
    extends $Notifier<SessionComposerDraft> {
  late final _$args = ref.$arg as (String, String?, String);
  String get hostId => _$args.$1;
  String? get worktreeId => _$args.$2;
  String get draftId => _$args.$3;

  SessionComposerDraft build(String hostId, String? worktreeId, String draftId);
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
    return element.handleCreate(
      ref,
      () => build(_$args.$1, _$args.$2, _$args.$3),
    );
  }
}
