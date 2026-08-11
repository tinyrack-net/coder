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
/// still written as it arrives. The pane is therefore not what keeps this
/// alive: `TerminalSessionLeases` holds a lease for as long as the checkout
/// shows a tab for this terminal, and the session ends when that lease is
/// dropped. Auto-disposal, rather than invalidation, is what ends it — see
/// `terminal_session_leases.dart` for why the distinction matters.

@ProviderFor(TerminalSessionController)
final terminalSessionControllerProvider = TerminalSessionControllerFamily._();

/// Owns one terminal's emulator, its attachment, and its daemon wiring.
///
/// The emulator outlives the pane that renders it, so switching tabs cannot
/// reset the scrollback, and output produced while the tab is off screen is
/// still written as it arrives. The pane is therefore not what keeps this
/// alive: `TerminalSessionLeases` holds a lease for as long as the checkout
/// shows a tab for this terminal, and the session ends when that lease is
/// dropped. Auto-disposal, rather than invalidation, is what ends it — see
/// `terminal_session_leases.dart` for why the distinction matters.
final class TerminalSessionControllerProvider
    extends $NotifierProvider<TerminalSessionController, TerminalSessionState> {
  /// Owns one terminal's emulator, its attachment, and its daemon wiring.
  ///
  /// The emulator outlives the pane that renders it, so switching tabs cannot
  /// reset the scrollback, and output produced while the tab is off screen is
  /// still written as it arrives. The pane is therefore not what keeps this
  /// alive: `TerminalSessionLeases` holds a lease for as long as the checkout
  /// shows a tab for this terminal, and the session ends when that lease is
  /// dropped. Auto-disposal, rather than invalidation, is what ends it — see
  /// `terminal_session_leases.dart` for why the distinction matters.
  TerminalSessionControllerProvider._({
    required TerminalSessionControllerFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'terminalSessionControllerProvider',
         isAutoDispose: true,
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
    r'f6ad0df47211cc9349b5d046cef4eaa30dbd14e3';

/// Owns one terminal's emulator, its attachment, and its daemon wiring.
///
/// The emulator outlives the pane that renders it, so switching tabs cannot
/// reset the scrollback, and output produced while the tab is off screen is
/// still written as it arrives. The pane is therefore not what keeps this
/// alive: `TerminalSessionLeases` holds a lease for as long as the checkout
/// shows a tab for this terminal, and the session ends when that lease is
/// dropped. Auto-disposal, rather than invalidation, is what ends it — see
/// `terminal_session_leases.dart` for why the distinction matters.

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
        isAutoDispose: true,
      );

  /// Owns one terminal's emulator, its attachment, and its daemon wiring.
  ///
  /// The emulator outlives the pane that renders it, so switching tabs cannot
  /// reset the scrollback, and output produced while the tab is off screen is
  /// still written as it arrives. The pane is therefore not what keeps this
  /// alive: `TerminalSessionLeases` holds a lease for as long as the checkout
  /// shows a tab for this terminal, and the session ends when that lease is
  /// dropped. Auto-disposal, rather than invalidation, is what ends it — see
  /// `terminal_session_leases.dart` for why the distinction matters.

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
/// still written as it arrives. The pane is therefore not what keeps this
/// alive: `TerminalSessionLeases` holds a lease for as long as the checkout
/// shows a tab for this terminal, and the session ends when that lease is
/// dropped. Auto-disposal, rather than invalidation, is what ends it — see
/// `terminal_session_leases.dart` for why the distinction matters.

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
