import 'dart:io';

import 'package:coder_app/src/desktop_startup.dart';
import 'package:coder_app/src/tray_menu_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

/// Controls the single desktop window from outside the widget tree.
abstract interface class DesktopWindow {
  /// Prepares the native window and decides whether it becomes visible.
  Future<void> prepare({required bool startHidden});

  /// Reveals and focuses the window.
  Future<void> show();

  /// Hides the window without ending the process.
  Future<void> hide();

  /// Whether the window is currently on screen.
  Future<bool> isVisible();

  /// Routes the user's close gesture to [onClose] instead of quitting.
  Future<void> interceptClose(void Function() onClose);

  /// Stops intercepting so a later close really does end the process.
  Future<void> releaseClose();

  /// Ends the process after the app has torn itself down.
  Future<void> destroy();
}

/// Owns the platform tray, menu-bar, or notification-area icon.
abstract interface class TrayIcon {
  /// Creates the icon and menu, routing selections to [onSelected] by row key.
  Future<void> install({
    required TrayMenuModel menu,
    required void Function(String itemKey) onSelected,
  });

  /// Replaces the menu and tooltip after a locale or daemon-state change.
  Future<void> update(TrayMenuModel menu);

  /// Removes the icon.
  Future<void> destroy();
}

/// Registers the app with the operating system's login-item mechanism.
abstract interface class AutostartRegistration {
  /// Rewrites the registration.
  ///
  /// [minimized] changes the recorded arguments, so turning it on or off has
  /// to re-register rather than only enable or disable.
  Future<void> apply({required bool enabled, required bool minimized});

  /// Whether the operating system currently launches the app at login.
  Future<bool> isEnabled();
}

/// Window control supplied by the desktop composition root.
///
/// Null means this platform has no window to manage, which is the honest
/// value for the mobile build rather than an error.
final desktopWindowProvider = Provider<DesktopWindow?>((ref) => null);

/// Tray icon supplied by the desktop composition root, or null on mobile.
final trayIconProvider = Provider<TrayIcon?>((ref) => null);

/// Login-item registration supplied by the desktop composition root.
final autostartProvider = Provider<AutostartRegistration?>((ref) => null);

/// Asset path of the tray icon for the current platform.
///
/// Windows renders only `.ico`, and macOS wants a monochrome template image
/// so the system can recolor it for light and dark menu bars.
String trayIconAssetPath({required TargetPlatform platform}) =>
    switch (platform) {
      TargetPlatform.windows => 'assets/tray/tray_icon.ico',
      TargetPlatform.macOS => 'assets/tray/tray_icon_template.png',
      _ => 'assets/tray/tray_icon.png',
    };

/// Production window adapter backed by `window_manager`.
final class PluginDesktopWindow implements DesktopWindow {
  /// Creates the production window adapter.
  PluginDesktopWindow({
    this.initialize = _ensureInitialized,
    this.readyToShow = _waitUntilReadyToShow,
    this.showWindow = _showWindow,
    this.hideWindow = _hideWindow,
    this.windowIsVisible = _windowIsVisible,
    this.preventClose = _setPreventClose,
    this.addWindowListener = _addWindowListener,
    this.removeWindowListener = _removeWindowListener,
    this.destroyWindow = _destroyWindow,
  });

  /// Injected `windowManager.ensureInitialized`.
  final Future<void> Function() initialize;

  /// Injected `windowManager.waitUntilReadyToShow`.
  final Future<void> Function(Future<void> Function()) readyToShow;

  /// Injected show-and-focus call.
  final Future<void> Function() showWindow;

  /// Injected hide call.
  final Future<void> Function() hideWindow;

  /// Injected visibility query.
  final Future<bool> Function() windowIsVisible;

  /// Injected close-prevention toggle.
  final Future<void> Function({required bool prevent}) preventClose;

  /// Injected listener registration.
  final void Function(WindowListener) addWindowListener;

  /// Injected listener removal.
  final void Function(WindowListener) removeWindowListener;

  /// Injected window destruction.
  final Future<void> Function() destroyWindow;

  _WindowCloseRelay? _relay;

  @override
  Future<void> prepare({required bool startHidden}) async {
    await initialize();
    await readyToShow(() async {
      if (startHidden) return;
      await showWindow();
    });
  }

  @override
  Future<void> show() => showWindow();

  @override
  Future<void> hide() => hideWindow();

  @override
  Future<bool> isVisible() => windowIsVisible();

  @override
  Future<void> interceptClose(void Function() onClose) async {
    await releaseClose();
    final relay = _WindowCloseRelay(onClose);
    _relay = relay;
    addWindowListener(relay);
    await preventClose(prevent: true);
  }

  @override
  Future<void> releaseClose() async {
    final relay = _relay;
    if (relay == null) return;
    _relay = null;
    removeWindowListener(relay);
    await preventClose(prevent: false);
  }

  @override
  Future<void> destroy() => destroyWindow();
}

final class _WindowCloseRelay with WindowListener {
  _WindowCloseRelay(this.onClose);

  final void Function() onClose;

  @override
  void onWindowClose() => onClose();
}

/// Production tray adapter backed by `tray_manager`.
final class PluginTrayIcon implements TrayIcon {
  /// Creates the production tray adapter.
  PluginTrayIcon({
    TargetPlatform? platform,
    this.setIcon = _setTrayIcon,
    this.setToolTip = _setTrayToolTip,
    this.setContextMenu = _setTrayContextMenu,
    this.addTrayListener = _addTrayListener,
    this.removeTrayListener = _removeTrayListener,
    this.destroyTray = _destroyTray,
  }) : platform = platform ?? defaultTargetPlatform;

  /// Platform used to choose the icon format and the available calls.
  final TargetPlatform platform;

  /// Injected icon assignment.
  final Future<void> Function(String path, {required bool isTemplate}) setIcon;

  /// Injected tooltip assignment.
  final Future<void> Function(String) setToolTip;

  /// Injected context-menu assignment.
  final Future<void> Function(Menu) setContextMenu;

  /// Injected listener registration.
  final void Function(TrayListener) addTrayListener;

  /// Injected listener removal.
  final void Function(TrayListener) removeTrayListener;

  /// Injected tray destruction.
  final Future<void> Function() destroyTray;

  _TraySelectionRelay? _relay;

  @override
  Future<void> install({
    required TrayMenuModel menu,
    required void Function(String itemKey) onSelected,
  }) async {
    await destroy();
    final relay = _TraySelectionRelay(onSelected);
    _relay = relay;
    addTrayListener(relay);
    await setIcon(
      trayIconAssetPath(platform: platform),
      isTemplate: platform == TargetPlatform.macOS,
    );
    await update(menu);
  }

  @override
  Future<void> update(TrayMenuModel menu) async {
    // The Linux plugin answers `setToolTip` with `notImplemented`, so asking
    // for one there would throw instead of degrading.
    if (platform != TargetPlatform.linux) await setToolTip(menu.tooltip);
    await setContextMenu(_nativeMenu(menu));
  }

  @override
  Future<void> destroy() async {
    final relay = _relay;
    if (relay == null) return;
    _relay = null;
    removeTrayListener(relay);
    await destroyTray();
  }
}

/// Converts the app's tray presentation into a native menu.
Menu buildNativeTrayMenu(TrayMenuModel menu) => _nativeMenu(menu);

Menu _nativeMenu(TrayMenuModel menu) => Menu(
  items: <MenuItem>[
    for (final entry in menu.entries)
      if (entry.isSeparator)
        MenuItem.separator()
      else
        MenuItem(
          key: entry.key,
          label: entry.label,
          disabled: !entry.enabled,
        ),
  ],
);

final class _TraySelectionRelay with TrayListener {
  _TraySelectionRelay(this.onSelected);

  final void Function(String itemKey) onSelected;

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    final key = menuItem.key;
    if (key != null) onSelected(key);
  }
}

/// Production login-item adapter backed by `launch_at_startup`.
final class LaunchAtStartupRegistration implements AutostartRegistration {
  /// Creates the production login-item adapter.
  const LaunchAtStartupRegistration({
    this.configure = _configureStartup,
    this.enableStartup = _enableStartup,
    this.disableStartup = _disableStartup,
    this.startupIsEnabled = _startupIsEnabled,
  });

  /// Login-item name, also the Linux `.desktop` file name.
  ///
  /// The plugin does not quote the `Exec=` line, so this must not contain a
  /// space.
  static const String appName = 'tinyrack-coder';

  /// Injected `launchAtStartup.setup`.
  final void Function({required String appPath, required List<String> args})
  configure;

  /// Injected registration.
  final Future<void> Function() enableStartup;

  /// Injected removal.
  final Future<void> Function() disableStartup;

  /// Injected registration query.
  final Future<bool> Function() startupIsEnabled;

  @override
  Future<void> apply({required bool enabled, required bool minimized}) async {
    // The arguments are baked in when the launcher is configured, so a change
    // to `minimized` has to re-register rather than only toggle.
    configure(
      appPath: Platform.resolvedExecutable,
      args: minimized ? const <String>[startMinimizedFlag] : const <String>[],
    );
    await (enabled ? enableStartup() : disableStartup());
  }

  @override
  Future<bool> isEnabled() => startupIsEnabled();
}

// The remaining functions are one-line bridges to plugin singletons. They are
// the only part of this file a test cannot drive, which is why every adapter
// takes them as injected parameters.

Future<void> _ensureInitialized() => windowManager.ensureInitialized();

Future<void> _waitUntilReadyToShow(Future<void> Function() onReady) =>
    windowManager.waitUntilReadyToShow(null, onReady);

Future<void> _showWindow() async {
  await windowManager.show();
  await windowManager.focus();
}

Future<void> _hideWindow() => windowManager.hide();

Future<bool> _windowIsVisible() => windowManager.isVisible();

Future<void> _setPreventClose({required bool prevent}) =>
    windowManager.setPreventClose(prevent);

void _addWindowListener(WindowListener listener) =>
    windowManager.addListener(listener);

void _removeWindowListener(WindowListener listener) =>
    windowManager.removeListener(listener);

Future<void> _destroyWindow() => windowManager.destroy();

Future<void> _setTrayIcon(String path, {required bool isTemplate}) =>
    trayManager.setIcon(path, isTemplate: isTemplate);

Future<void> _setTrayToolTip(String tooltip) => trayManager.setToolTip(tooltip);

Future<void> _setTrayContextMenu(Menu menu) => trayManager.setContextMenu(menu);

void _addTrayListener(TrayListener listener) =>
    trayManager.addListener(listener);

void _removeTrayListener(TrayListener listener) =>
    trayManager.removeListener(listener);

Future<void> _destroyTray() => trayManager.destroy();

void _configureStartup({
  required String appPath,
  required List<String> args,
}) => launchAtStartup.setup(
  appName: LaunchAtStartupRegistration.appName,
  appPath: appPath,
  args: args,
);

Future<void> _enableStartup() async {
  await launchAtStartup.enable();
}

Future<void> _disableStartup() async {
  await launchAtStartup.disable();
}

Future<bool> _startupIsEnabled() => launchAtStartup.isEnabled();
