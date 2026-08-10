// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'terminal_attach_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Attaches to one daemon terminal and returns its replayed scrollback.
///
/// The terminal grid mounts immediately and overlays a visible connecting
/// state from this provider's loading phase, instead of presenting an empty
/// prompt that silently swallows keystrokes. Failures surface an explicit
/// retry, which re-runs this build via invalidation.

@ProviderFor(TerminalAttachController)
final terminalAttachControllerProvider = TerminalAttachControllerFamily._();

/// Attaches to one daemon terminal and returns its replayed scrollback.
///
/// The terminal grid mounts immediately and overlays a visible connecting
/// state from this provider's loading phase, instead of presenting an empty
/// prompt that silently swallows keystrokes. Failures surface an explicit
/// retry, which re-runs this build via invalidation.
final class TerminalAttachControllerProvider
    extends
        $AsyncNotifierProvider<TerminalAttachController, TerminalAttachment> {
  /// Attaches to one daemon terminal and returns its replayed scrollback.
  ///
  /// The terminal grid mounts immediately and overlays a visible connecting
  /// state from this provider's loading phase, instead of presenting an empty
  /// prompt that silently swallows keystrokes. Failures surface an explicit
  /// retry, which re-runs this build via invalidation.
  TerminalAttachControllerProvider._({
    required TerminalAttachControllerFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: noAutomaticRetry,
         name: r'terminalAttachControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$terminalAttachControllerHash();

  @override
  String toString() {
    return r'terminalAttachControllerProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  TerminalAttachController create() => TerminalAttachController();

  @override
  bool operator ==(Object other) {
    return other is TerminalAttachControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$terminalAttachControllerHash() =>
    r'3e565f071dde82a3eb446dce8f742795aa1b3188';

/// Attaches to one daemon terminal and returns its replayed scrollback.
///
/// The terminal grid mounts immediately and overlays a visible connecting
/// state from this provider's loading phase, instead of presenting an empty
/// prompt that silently swallows keystrokes. Failures surface an explicit
/// retry, which re-runs this build via invalidation.

final class TerminalAttachControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          TerminalAttachController,
          AsyncValue<TerminalAttachment>,
          TerminalAttachment,
          FutureOr<TerminalAttachment>,
          (String, String)
        > {
  TerminalAttachControllerFamily._()
    : super(
        retry: noAutomaticRetry,
        name: r'terminalAttachControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Attaches to one daemon terminal and returns its replayed scrollback.
  ///
  /// The terminal grid mounts immediately and overlays a visible connecting
  /// state from this provider's loading phase, instead of presenting an empty
  /// prompt that silently swallows keystrokes. Failures surface an explicit
  /// retry, which re-runs this build via invalidation.

  TerminalAttachControllerProvider call(String hostId, String terminalId) =>
      TerminalAttachControllerProvider._(
        argument: (hostId, terminalId),
        from: this,
      );

  @override
  String toString() => r'terminalAttachControllerProvider';
}

/// Attaches to one daemon terminal and returns its replayed scrollback.
///
/// The terminal grid mounts immediately and overlays a visible connecting
/// state from this provider's loading phase, instead of presenting an empty
/// prompt that silently swallows keystrokes. Failures surface an explicit
/// retry, which re-runs this build via invalidation.

abstract class _$TerminalAttachController
    extends $AsyncNotifier<TerminalAttachment> {
  late final _$args = ref.$arg as (String, String);
  String get hostId => _$args.$1;
  String get terminalId => _$args.$2;

  FutureOr<TerminalAttachment> build(String hostId, String terminalId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<TerminalAttachment>, TerminalAttachment>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<TerminalAttachment>, TerminalAttachment>,
              AsyncValue<TerminalAttachment>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
}
