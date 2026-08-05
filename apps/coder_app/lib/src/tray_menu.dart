import 'package:coder_app/l10n/gen/app_localizations.dart';
import 'package:coder_app/src/host_models.dart';
import 'package:coder_app/src/tray_menu_model.dart';

String _trayHostStatusText(
  AppLocalizations l10n,
  HostRuntimeSnapshot? runtime,
) {
  // Native tray menus do not expose a reliable cross-platform width limit.
  // Keep daemon-provided failure details in Settings so one verbose message
  // cannot expand the Ubuntu tray menu to the width of the screen.
  if (runtime == null) return l10n.hostStatusPending;
  return switch (runtime.status) {
    HostRuntimeStatus.online => l10n.hostStatusOnline,
    HostRuntimeStatus.connecting => l10n.hostStatusConnecting,
    HostRuntimeStatus.reconnecting => l10n.hostStatusReconnecting,
    HostRuntimeStatus.offline => l10n.hostStatusOffline,
    HostRuntimeStatus.error => l10n.hostStatusError,
    HostRuntimeStatus.conflict => l10n.hostStatusConflict,
    HostRuntimeStatus.idle => l10n.hostStatusIdle,
  };
}

/// Builds the tray presentation from localized strings and live app state.
///
/// Localization is passed in rather than read from a context so the same
/// function serves the widget that owns the tray and its tests.
TrayMenuModel buildTrayMenu({
  required AppLocalizations l10n,
  required bool windowVisible,
  required HostRuntimeSnapshot? embeddedDaemon,
  required bool supportsEmbeddedDaemon,
}) => TrayMenuModel(
  tooltip: l10n.trayTooltip,
  entries: <TrayMenuEntry>[
    TrayMenuEntry(
      key: trayItemToggleWindow,
      label: windowVisible ? l10n.trayHideWindow : l10n.trayShowWindow,
      action: TrayMenuAction.toggleWindow,
    ),
    const TrayMenuEntry.separator(),
    TrayMenuEntry(
      key: trayItemOpenSettings,
      label: l10n.trayOpenSettings,
      action: TrayMenuAction.openSettings,
    ),
    if (supportsEmbeddedDaemon) ...<TrayMenuEntry>[
      const TrayMenuEntry.separator(),
      // Reporting only; selecting it must never start or stop the daemon.
      TrayMenuEntry(
        key: trayItemDaemonStatus,
        label:
            '${l10n.embeddedDaemonName}: '
            '${_trayHostStatusText(l10n, embeddedDaemon)}',
        enabled: false,
      ),
    ],
    const TrayMenuEntry.separator(),
    TrayMenuEntry(
      key: trayItemQuit,
      label: l10n.trayQuit,
      action: TrayMenuAction.quit,
    ),
  ],
);
