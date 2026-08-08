import 'package:coder_protocol/src/common/rpc_values.dart';
import 'package:coder_protocol/src/relay_models.dart';
import 'package:coder_protocol/src/rpc_catalog.dart';

/// Reads current relay activation and connectivity.
final relayStatusProcedure = RpcProcedure<RelayEmptyParamsDto, RelayStatusDto>(
  name: 'relay.status',
  decodeParams: RelayEmptyParamsDto.fromJson,
  encodeParams: (value) => value.toJson(),
  decodeResult: RelayStatusDto.fromJson,
  encodeResult: (value) => value.toJson(),
);

/// Enables or disables the daemon's outbound relay connection.
final relaySetEnabledProcedure =
    RpcProcedure<RelaySetEnabledParamsDto, RelayStatusDto>(
      name: 'relay.setEnabled',
      decodeParams: RelaySetEnabledParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: RelayStatusDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Creates a ten-minute one-time pairing offer.
final relayCreateOfferProcedure =
    RpcProcedure<RelayEmptyParamsDto, RelayPairingOfferDto>(
      name: 'relay.createOffer',
      decodeParams: RelayEmptyParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: RelayPairingOfferDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Lists daemon-approved relay devices.
final relayListDevicesProcedure =
    RpcProcedure<RelayEmptyParamsDto, RelayDeviceListDto>(
      name: 'relay.listDevices',
      decodeParams: RelayEmptyParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: RelayDeviceListDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Revokes one approved device and its live sessions.
final relayRevokeDeviceProcedure =
    RpcProcedure<RelayRevokeDeviceParamsDto, EmptyResultDto>(
      name: 'relay.revokeDevice',
      decodeParams: RelayRevokeDeviceParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: EmptyResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Announces relay connectivity and activation changes.
final relayStatusChangedNotification = RpcNotification<RelayStatusDto>(
  name: 'relay.statusChanged',
  decode: RelayStatusDto.fromJson,
  encode: (value) => value.toJson(),
);

/// Relay procedure catalog.
final relayProcedures = <RpcProcedureDescriptor>[
  relayStatusProcedure,
  relaySetEnabledProcedure,
  relayCreateOfferProcedure,
  relayListDevicesProcedure,
  relayRevokeDeviceProcedure,
];

/// Relay notification catalog.
final relayNotifications = <RpcNotificationDescriptor>[
  relayStatusChangedNotification,
];
