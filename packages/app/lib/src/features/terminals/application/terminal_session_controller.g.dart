// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'terminal_session_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Owns one terminal's emulator, its attachment, and its daemon wiring.
///
/// The emulator outlives the pane that renders it, so switching tabs cannot
/// reset the scrollback, and output produced while the tab is off screen is
/// still written as it arrives. The provider is deliberately `keepAlive`: the
/// pane unmounting is exactly the moment it must not be disposed. Its lifetime
/// is bound to the tab instead, which `WorkspacePage` ends by invalidating it.

@ProviderFor(TerminalSessionController)
final terminalSessionControllerProvider = TerminalSessionControllerFamily._();

/// Owns one terminal's emulator, its attachment, and its daemon wiring.
///
/// The emulator outlives the pane that renders it, so switching tabs cannot
/// reset the scrollback, and output produced while the tab is off screen is
/// still written as it arrives. The provider is deliberately `keepAlive`: the
/// pane unmounting is exactly the moment it must not be disposed. Its lifetime
/// is bound to the tab instead, which `WorkspacePage` ends by invalidating it.
final class TerminalSessionControllerProvider
    extends $NotifierProvider<TerminalSessionController, TerminalSessionState> {
  /// Owns one terminal's emulator, its attachment, and its daemon wiring.
  ///
  /// The emulator outlives the pane that renders it, so switching tabs cannot
  /// reset the scrollback, and output produced while the tab is off screen is
  /// still written as it arrives. The provider is deliberately `keepAlive`: the
  /// pane unmounting is exactly the moment it must not be disposed. Its lifetime
  /// is bound to the tab instead, which `WorkspacePage` ends by invalidating it.
  TerminalSessionControllerProvider._({
    required TerminalSessionControllerFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'terminalSessionControllerProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$terminalSessionControllerHash();

  @override
  String toString() {
    return r'terminalSessionControllerProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  TerminalSessionController create() => TerminalSessionController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TerminalSessionState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TerminalSessionState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TerminalSessionControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$terminalSessionControllerHash() =>
    r'1863ebf17d1bac54da92ba86e6e470e604bc76d5';

/// Owns one terminal's emulator, its attachment, and its daemon wiring.
///
/// The emulator outlives the pane that renders it, so switching tabs cannot
/// reset the scrollback, and output produced while the tab is off screen is
/// still written as it arrives. The provider is deliberately `keepAlive`: the
/// pane unmounting is exactly the moment it must not be disposed. Its lifetime
/// is bound to the tab instead, which `WorkspacePage` ends by invalidating it.

final class TerminalSessionControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          TerminalSessionController,
          TerminalSessionState,
          TerminalSessionState,
          TerminalSessionState,
          (String, String)
        > {
  TerminalSessionControllerFamily._()
    : super(
        retry: null,
        name: r'terminalSessionControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// Owns one terminal's emulator, its attachment, and its daemon wiring.
  ///
  /// The emulator outlives the pane that renders it, so switching tabs cannot
  /// reset the scrollback, and output produced while the tab is off screen is
  /// still written as it arrives. The provider is deliberately `keepAlive`: the
  /// pane unmounting is exactly the moment it must not be disposed. Its lifetime
  /// is bound to the tab instead, which `WorkspacePage` ends by invalidating it.

  TerminalSessionControllerProvider call(String hostId, String terminalId) =>
      TerminalSessionControllerProvider._(
        argument: (hostId, terminalId),
        from: this,
      );

  @override
  String toString() => r'terminalSessionControllerProvider';
}

/// Owns one terminal's emulator, its attachment, and its daemon wiring.
///
/// The emulator outlives the pane that renders it, so switching tabs cannot
/// reset the scrollback, and output produced while the tab is off screen is
/// still written as it arrives. The provider is deliberately `keepAlive`: the
/// pane unmounting is exactly the moment it must not be disposed. Its lifetime
/// is bound to the tab instead, which `WorkspacePage` ends by invalidating it.

abstract class _$TerminalSessionController
    extends $Notifier<TerminalSessionState> {
  late final _$args = ref.$arg as (String, String);
  String get hostId => _$args.$1;
  String get terminalId => _$args.$2;

  TerminalSessionState build(String hostId, String terminalId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<TerminalSessionState, TerminalSessionState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TerminalSessionState, TerminalSessionState>,
              TerminalSessionState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
}
