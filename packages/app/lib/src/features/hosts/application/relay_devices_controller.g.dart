// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'relay_devices_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Approved relay devices of one daemon.
///
/// Stays in its loading state until the daemon connects: an approved-device
/// list that rendered as empty before the daemon answered would misreport
/// revoked access.

@ProviderFor(relayDevices)
final relayDevicesProvider = RelayDevicesFamily._();

/// Approved relay devices of one daemon.
///
/// Stays in its loading state until the daemon connects: an approved-device
/// list that rendered as empty before the daemon answered would misreport
/// revoked access.

final class RelayDevicesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<RelayDeviceDto>>,
          List<RelayDeviceDto>,
          FutureOr<List<RelayDeviceDto>>
        >
    with
        $FutureModifier<List<RelayDeviceDto>>,
        $FutureProvider<List<RelayDeviceDto>> {
  /// Approved relay devices of one daemon.
  ///
  /// Stays in its loading state until the daemon connects: an approved-device
  /// list that rendered as empty before the daemon answered would misreport
  /// revoked access.
  RelayDevicesProvider._({
    required RelayDevicesFamily super.from,
    required String super.argument,
  }) : super(
         retry: noAutomaticRetry,
         name: r'relayDevicesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$relayDevicesHash();

  @override
  String toString() {
    return r'relayDevicesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<RelayDeviceDto>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<RelayDeviceDto>> create(Ref ref) {
    final argument = this.argument as String;
    return relayDevices(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is RelayDevicesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$relayDevicesHash() => r'9cd8a7e5d6c7b65c5c5c816818ee266dc0fff81d';

/// Approved relay devices of one daemon.
///
/// Stays in its loading state until the daemon connects: an approved-device
/// list that rendered as empty before the daemon answered would misreport
/// revoked access.

final class RelayDevicesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<RelayDeviceDto>>, String> {
  RelayDevicesFamily._()
    : super(
        retry: noAutomaticRetry,
        name: r'relayDevicesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Approved relay devices of one daemon.
  ///
  /// Stays in its loading state until the daemon connects: an approved-device
  /// list that rendered as empty before the daemon answered would misreport
  /// revoked access.

  RelayDevicesProvider call(String hostId) =>
      RelayDevicesProvider._(argument: hostId, from: this);

  @override
  String toString() => r'relayDevicesProvider';
}
