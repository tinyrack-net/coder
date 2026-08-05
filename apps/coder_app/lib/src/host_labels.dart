import 'package:coder_app/l10n/gen/app_localizations.dart';
import 'package:coder_app/src/coder_icons.dart';
import 'package:coder_app/src/host_models.dart';
import 'package:flutter/material.dart';

/// Returns the name to show for one daemon.
///
/// The app owns the embedded daemon's name, so it is localized here rather
/// than stored on the runtime snapshot. Remote daemons keep the label the
/// user typed.
String hostLabel(AppLocalizations l10n, HostRuntimeSnapshot host) =>
    host.kind == HostKind.embedded ? l10n.embeddedDaemonName : host.label;

/// Returns the localized text for an app-authored failure.
String hostFailureText(AppLocalizations l10n, HostFailureReason reason) =>
    switch (reason) {
      HostFailureReason.missingBearerToken => l10n.hostErrorMissingToken,
      HostFailureReason.noStoredBearerToken => l10n.hostErrorNoToken,
      HostFailureReason.duplicateDaemon => l10n.hostErrorDuplicate,
      HostFailureReason.rejectedBearerToken => l10n.hostErrorUnauthorized,
      HostFailureReason.embeddedPortInUse => l10n.hostErrorEmbeddedPortInUse,
      HostFailureReason.localNetworkUnreachable =>
        l10n.hostErrorLocalNetworkUnreachable,
    };

/// Returns the failure text to show for one daemon, or null when healthy.
///
/// App-authored failures are localized; daemon-supplied text is passed
/// through, since only the daemon knows what it means.
String? hostErrorText(AppLocalizations l10n, HostRuntimeSnapshot host) {
  final reason = host.errorReason;
  return reason == null ? host.error : hostFailureText(l10n, reason);
}

/// Returns the localized status text for one daemon.
///
/// A null runtime means the daemon has not reported yet, which reads as
/// pending rather than as a failure.
String hostStatusText(AppLocalizations l10n, HostRuntimeSnapshot? runtime) {
  if (runtime == null) return l10n.hostStatusPending;
  return switch (runtime.status) {
    HostRuntimeStatus.online => l10n.hostStatusOnline,
    HostRuntimeStatus.connecting => l10n.hostStatusConnecting,
    HostRuntimeStatus.reconnecting => l10n.hostStatusReconnecting,
    HostRuntimeStatus.offline =>
      hostErrorText(l10n, runtime) ?? l10n.hostStatusOffline,
    HostRuntimeStatus.error =>
      hostErrorText(l10n, runtime) ?? l10n.hostStatusError,
    HostRuntimeStatus.conflict =>
      hostErrorText(l10n, runtime) ?? l10n.hostStatusConflict,
    HostRuntimeStatus.idle => l10n.hostStatusIdle,
  };
}

/// Returns the icon that stands for one daemon connection status.
///
/// A null status means the daemon has not reported yet, which reads as
/// paused rather than as a failure.
IconData hostStatusIcon(HostRuntimeStatus? status) => switch (status) {
  HostRuntimeStatus.online => CoderIcons.success,
  HostRuntimeStatus.connecting ||
  HostRuntimeStatus.reconnecting => CoderIcons.sync,
  HostRuntimeStatus.offline => CoderIcons.offline,
  HostRuntimeStatus.conflict => CoderIcons.branch,
  HostRuntimeStatus.error => CoderIcons.error,
  HostRuntimeStatus.idle || null => CoderIcons.paused,
};

/// Returns the localized message for a connection failure.
String hostConnectionFailureText(
  AppLocalizations l10n,
  HostConnectionFailure failure,
) {
  final reason = failure.reason;
  return reason == null ? failure.message : hostFailureText(l10n, reason);
}
