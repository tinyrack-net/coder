import 'dart:async';

import 'package:daemon/src/features/relay/application/relay_pairing_service.dart';

/// Transport-neutral current relay state.
final class RelayStatus {
  /// Creates relay state.
  const RelayStatus({
    required this.enabled,
    required this.connected,
    required this.endpoint,
    required this.serverId,
  });

  /// Whether relay operation is enabled.
  final bool enabled;

  /// Whether the outbound control socket is connected.
  final bool connected;

  /// Effective relay endpoint.
  final String endpoint;

  /// Authoritative daemon identifier.
  final String serverId;
}

/// Transport-neutral short-lived pairing offer.
final class RelayPairingOfferInfo {
  /// Creates pairing offer metadata.
  const RelayPairingOfferInfo({required this.url, required this.expiresAt});

  /// Fragment-only pairing URL.
  final String url;

  /// UTC expiration instant.
  final DateTime expiresAt;
}

/// Transport-neutral approved device metadata.
final class RelayDeviceInfo {
  /// Creates approved device metadata.
  const RelayDeviceInfo({
    required this.id,
    required this.name,
    required this.registeredAt,
    required this.lastConnectedAt,
  });

  /// Daemon-scoped device identifier.
  final String id;

  /// User-visible device name.
  final String name;

  /// UTC registration instant.
  final DateTime registeredAt;

  /// Most recent authenticated connection instant.
  final DateTime? lastConnectedAt;
}

/// Starts or stops the daemon's outbound relay adapter.
typedef RelayEnabledApplier = Future<void> Function({required bool enabled});

/// Daemon relay configuration, pairing, and device-revocation service.
final class RelayControlService {
  /// Creates relay control state for one daemon.
  RelayControlService({
    required this._enabled,
    required this.endpoint,
    required this.serverId,
    required this.pairing,
    required this._applyEnabled,
  });

  /// Effective outbound relay endpoint.
  final Uri endpoint;

  /// Authoritative daemon identity.
  final String serverId;

  /// Pairing and approved-device service.
  final RelayPairingService pairing;

  final RelayEnabledApplier _applyEnabled;
  final StreamController<RelayStatus> _updates =
      StreamController<RelayStatus>.broadcast(sync: true);
  bool _enabled;
  bool _connected = false;

  /// Relay status changes.
  Stream<RelayStatus> get updates => _updates.stream;

  /// Current relay state.
  RelayStatus get status => RelayStatus(
    enabled: _enabled,
    connected: _connected,
    endpoint: endpoint.toString(),
    serverId: serverId,
  );

  /// Applies and announces relay activation.
  Future<RelayStatus> setEnabled({required bool enabled}) async {
    if (_enabled == enabled) {
      return status;
    }
    await _applyEnabled(enabled: enabled);
    _enabled = enabled;
    if (!enabled) {
      _connected = false;
    }
    _updates.add(status);
    return status;
  }

  /// Announces a control-socket connectivity transition.
  void setConnected({required bool connected}) {
    if (_connected == connected) {
      return;
    }
    _connected = connected;
    _updates.add(status);
  }

  /// Creates a fragment-only ten-minute pairing URL.
  RelayPairingOfferInfo createOffer() {
    final offer = pairing.createOffer();
    return RelayPairingOfferInfo(
      url: offer.toUrl(Uri.parse('https://coder.tinyrack.net/pair')).toString(),
      expiresAt: offer.expiresAt,
    );
  }

  /// Lists public metadata for approved devices.
  Future<List<RelayDeviceInfo>> listDevices() async =>
      (await pairing.listDevices())
          .map(
            (device) => RelayDeviceInfo(
              id: device.id,
              name: device.name,
              registeredAt: device.registeredAt,
              lastConnectedAt: device.lastConnectedAt,
            ),
          )
          .toList(growable: false);

  /// Revokes one device and its sessions.
  Future<void> revokeDevice(String deviceId) => pairing.revokeDevice(deviceId);

  /// Releases the status stream.
  Future<void> close() => _updates.close();
}
