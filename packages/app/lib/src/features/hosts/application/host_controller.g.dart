// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'host_controller.dart';

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
    r'36f0e7027e18ea1f4e9fe4496ce38b100ab5cf2b';

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

/// The daemon that host-scoped screens read and write.
///
/// The saved [AppSettings.lastActiveHostId] wins so the choice survives a
/// restart and stays in step with the workspace window. It is allowed to name
/// an offline daemon, so the fallbacks only run when it names no daemon at all.

@ProviderFor(activeHostId)
final activeHostIdProvider = ActiveHostIdProvider._();

/// The daemon that host-scoped screens read and write.
///
/// The saved [AppSettings.lastActiveHostId] wins so the choice survives a
/// restart and stays in step with the workspace window. It is allowed to name
/// an offline daemon, so the fallbacks only run when it names no daemon at all.

final class ActiveHostIdProvider
    extends $FunctionalProvider<String?, String?, String?>
    with $Provider<String?> {
  /// The daemon that host-scoped screens read and write.
  ///
  /// The saved [AppSettings.lastActiveHostId] wins so the choice survives a
  /// restart and stays in step with the workspace window. It is allowed to name
  /// an offline daemon, so the fallbacks only run when it names no daemon at all.
  ActiveHostIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeHostIdProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeHostIdHash();

  @$internal
  @override
  $ProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String? create(Ref ref) {
    return activeHostId(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$activeHostIdHash() => r'bd97f7052a03788a600dc17ce51a2db1b3956cb5';
