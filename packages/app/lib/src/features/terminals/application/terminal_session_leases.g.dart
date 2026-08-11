// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'terminal_session_leases.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Terminal identities one checkout currently shows as tabs.
///
/// Deliberately a provider rather than a getter on the tabs state: it is the
/// key the leases below are derived from, and it has to be able to hold the
/// previous answer across a reload frame.

@ProviderFor(OpenTerminalIds)
final openTerminalIdsProvider = OpenTerminalIdsFamily._();

/// Terminal identities one checkout currently shows as tabs.
///
/// Deliberately a provider rather than a getter on the tabs state: it is the
/// key the leases below are derived from, and it has to be able to hold the
/// previous answer across a reload frame.
final class OpenTerminalIdsProvider
    extends $NotifierProvider<OpenTerminalIds, Set<String>> {
  /// Terminal identities one checkout currently shows as tabs.
  ///
  /// Deliberately a provider rather than a getter on the tabs state: it is the
  /// key the leases below are derived from, and it has to be able to hold the
  /// previous answer across a reload frame.
  OpenTerminalIdsProvider._({
    required OpenTerminalIdsFamily super.from,
    required WorkspaceSelection super.argument,
  }) : super(
         retry: null,
         name: r'openTerminalIdsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$openTerminalIdsHash();

  @override
  String toString() {
    return r'openTerminalIdsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  OpenTerminalIds create() => OpenTerminalIds();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<String>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is OpenTerminalIdsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$openTerminalIdsHash() => r'2b178409a1be4b0b69930c313ea2691bcf1e6d28';

/// Terminal identities one checkout currently shows as tabs.
///
/// Deliberately a provider rather than a getter on the tabs state: it is the
/// key the leases below are derived from, and it has to be able to hold the
/// previous answer across a reload frame.

final class OpenTerminalIdsFamily extends $Family
    with
        $ClassFamilyOverride<
          OpenTerminalIds,
          Set<String>,
          Set<String>,
          Set<String>,
          WorkspaceSelection
        > {
  OpenTerminalIdsFamily._()
    : super(
        retry: null,
        name: r'openTerminalIdsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Terminal identities one checkout currently shows as tabs.
  ///
  /// Deliberately a provider rather than a getter on the tabs state: it is the
  /// key the leases below are derived from, and it has to be able to hold the
  /// previous answer across a reload frame.

  OpenTerminalIdsProvider call(WorkspaceSelection selection) =>
      OpenTerminalIdsProvider._(argument: selection, from: this);

  @override
  String toString() => r'openTerminalIdsProvider';
}

/// Terminal identities one checkout currently shows as tabs.
///
/// Deliberately a provider rather than a getter on the tabs state: it is the
/// key the leases below are derived from, and it has to be able to hold the
/// previous answer across a reload frame.

abstract class _$OpenTerminalIds extends $Notifier<Set<String>> {
  late final _$args = ref.$arg as WorkspaceSelection;
  WorkspaceSelection get selection => _$args;

  Set<String> build(WorkspaceSelection selection);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Set<String>, Set<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Set<String>, Set<String>>,
              Set<String>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// Holds one lease per open terminal tab, and does nothing else.
///
/// Terminal sessions must outlive their pane: switching tabs, splitting a
/// pane, or scrolling a tab off screen unmounts the view, and none of those
/// may reset the emulator. Something therefore has to decide when a session
/// really is over, and that decision belongs in the provider graph rather than
/// in a widget. A widget that ends a lifetime has to do it from a lifecycle
/// callback, and `Ref.invalidate` schedules its refresh through `setState`, so
/// doing it from `didUpdateWidget` — which runs inside the build phase —
/// throws "setState() or markNeedsBuild() called during build".
///
/// Leasing instead makes that unreachable. A dropped lease ends the session by
/// auto-disposal, which Riverpod drains in a microtask, after the frame.

@ProviderFor(TerminalSessionLeases)
final terminalSessionLeasesProvider = TerminalSessionLeasesFamily._();

/// Holds one lease per open terminal tab, and does nothing else.
///
/// Terminal sessions must outlive their pane: switching tabs, splitting a
/// pane, or scrolling a tab off screen unmounts the view, and none of those
/// may reset the emulator. Something therefore has to decide when a session
/// really is over, and that decision belongs in the provider graph rather than
/// in a widget. A widget that ends a lifetime has to do it from a lifecycle
/// callback, and `Ref.invalidate` schedules its refresh through `setState`, so
/// doing it from `didUpdateWidget` — which runs inside the build phase —
/// throws "setState() or markNeedsBuild() called during build".
///
/// Leasing instead makes that unreachable. A dropped lease ends the session by
/// auto-disposal, which Riverpod drains in a microtask, after the frame.
final class TerminalSessionLeasesProvider
    extends $NotifierProvider<TerminalSessionLeases, Set<String>> {
  /// Holds one lease per open terminal tab, and does nothing else.
  ///
  /// Terminal sessions must outlive their pane: switching tabs, splitting a
  /// pane, or scrolling a tab off screen unmounts the view, and none of those
  /// may reset the emulator. Something therefore has to decide when a session
  /// really is over, and that decision belongs in the provider graph rather than
  /// in a widget. A widget that ends a lifetime has to do it from a lifecycle
  /// callback, and `Ref.invalidate` schedules its refresh through `setState`, so
  /// doing it from `didUpdateWidget` — which runs inside the build phase —
  /// throws "setState() or markNeedsBuild() called during build".
  ///
  /// Leasing instead makes that unreachable. A dropped lease ends the session by
  /// auto-disposal, which Riverpod drains in a microtask, after the frame.
  TerminalSessionLeasesProvider._({
    required TerminalSessionLeasesFamily super.from,
    required WorkspaceSelection super.argument,
  }) : super(
         retry: null,
         name: r'terminalSessionLeasesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$terminalSessionLeasesHash();

  @override
  String toString() {
    return r'terminalSessionLeasesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  TerminalSessionLeases create() => TerminalSessionLeases();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<String>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TerminalSessionLeasesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$terminalSessionLeasesHash() =>
    r'5bbc6a37b2f9ac892e1aa58c014b06f7c6df33ca';

/// Holds one lease per open terminal tab, and does nothing else.
///
/// Terminal sessions must outlive their pane: switching tabs, splitting a
/// pane, or scrolling a tab off screen unmounts the view, and none of those
/// may reset the emulator. Something therefore has to decide when a session
/// really is over, and that decision belongs in the provider graph rather than
/// in a widget. A widget that ends a lifetime has to do it from a lifecycle
/// callback, and `Ref.invalidate` schedules its refresh through `setState`, so
/// doing it from `didUpdateWidget` — which runs inside the build phase —
/// throws "setState() or markNeedsBuild() called during build".
///
/// Leasing instead makes that unreachable. A dropped lease ends the session by
/// auto-disposal, which Riverpod drains in a microtask, after the frame.

final class TerminalSessionLeasesFamily extends $Family
    with
        $ClassFamilyOverride<
          TerminalSessionLeases,
          Set<String>,
          Set<String>,
          Set<String>,
          WorkspaceSelection
        > {
  TerminalSessionLeasesFamily._()
    : super(
        retry: null,
        name: r'terminalSessionLeasesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Holds one lease per open terminal tab, and does nothing else.
  ///
  /// Terminal sessions must outlive their pane: switching tabs, splitting a
  /// pane, or scrolling a tab off screen unmounts the view, and none of those
  /// may reset the emulator. Something therefore has to decide when a session
  /// really is over, and that decision belongs in the provider graph rather than
  /// in a widget. A widget that ends a lifetime has to do it from a lifecycle
  /// callback, and `Ref.invalidate` schedules its refresh through `setState`, so
  /// doing it from `didUpdateWidget` — which runs inside the build phase —
  /// throws "setState() or markNeedsBuild() called during build".
  ///
  /// Leasing instead makes that unreachable. A dropped lease ends the session by
  /// auto-disposal, which Riverpod drains in a microtask, after the frame.

  TerminalSessionLeasesProvider call(WorkspaceSelection selection) =>
      TerminalSessionLeasesProvider._(argument: selection, from: this);

  @override
  String toString() => r'terminalSessionLeasesProvider';
}

/// Holds one lease per open terminal tab, and does nothing else.
///
/// Terminal sessions must outlive their pane: switching tabs, splitting a
/// pane, or scrolling a tab off screen unmounts the view, and none of those
/// may reset the emulator. Something therefore has to decide when a session
/// really is over, and that decision belongs in the provider graph rather than
/// in a widget. A widget that ends a lifetime has to do it from a lifecycle
/// callback, and `Ref.invalidate` schedules its refresh through `setState`, so
/// doing it from `didUpdateWidget` — which runs inside the build phase —
/// throws "setState() or markNeedsBuild() called during build".
///
/// Leasing instead makes that unreachable. A dropped lease ends the session by
/// auto-disposal, which Riverpod drains in a microtask, after the frame.

abstract class _$TerminalSessionLeases extends $Notifier<Set<String>> {
  late final _$args = ref.$arg as WorkspaceSelection;
  WorkspaceSelection get selection => _$args;

  Set<String> build(WorkspaceSelection selection);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Set<String>, Set<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Set<String>, Set<String>>,
              Set<String>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
