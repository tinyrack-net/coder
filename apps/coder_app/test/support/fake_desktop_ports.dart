import 'dart:async';

import 'package:coder_app/src/desktop_shell.dart';
import 'package:coder_app/src/tray_menu_model.dart';

/// Records window control without opening a native window.
final class FakeDesktopWindow implements DesktopWindow {
  /// Creates a fake window that starts visible.
  FakeDesktopWindow({this.visible = true});

  /// Whether the window is currently on screen.
  bool visible;

  /// Whether the close gesture is being intercepted.
  bool preventingClose = false;

  /// Value recorded by the last [prepare] call, or null when never prepared.
  bool? preparedHidden;

  /// Counts of each destructive call, so ordering can be asserted.
  int shows = 0;
  int hides = 0;
  int destroys = 0;

  /// Order in which teardown steps ran, used by the quit test.
  final List<String> calls = <String>[];

  void Function()? _onClose;

  /// Drives the native close gesture from a test.
  void requestClose() => _onClose?.call();

  @override
  Future<void> prepare({required bool startHidden}) async {
    preparedHidden = startHidden;
    visible = !startHidden;
  }

  @override
  Future<void> show() async {
    shows += 1;
    visible = true;
    calls.add('show');
  }

  @override
  Future<void> hide() async {
    hides += 1;
    visible = false;
    calls.add('hide');
  }

  @override
  Future<bool> isVisible() async => visible;

  @override
  Future<void> interceptClose(void Function() onClose) async {
    _onClose = onClose;
    preventingClose = true;
  }

  @override
  Future<void> releaseClose() async {
    _onClose = null;
    preventingClose = false;
    calls.add('releaseClose');
  }

  @override
  Future<void> destroy() async {
    destroys += 1;
    calls.add('destroyWindow');
  }
}

/// Records tray installation and menu updates without a native tray.
final class FakeTrayIcon implements TrayIcon {
  /// Creates a fake tray, optionally holding [installGate] open mid-install.
  ///
  /// A held gate reproduces a real tray, where installing the icon takes long
  /// enough for another frame to ask for a menu update.
  FakeTrayIcon({this.installGate});

  /// Completed by a test to let a pending [install] finish.
  final Completer<void>? installGate;

  /// Every menu handed to the tray, in order, starting with the installed one.
  final List<TrayMenuModel> menus = <TrayMenuModel>[];

  /// Which tray calls ran, in order, as `install` and `update`.
  final List<String> operations = <String>[];

  /// Number of times the icon was installed.
  int installs = 0;

  /// Number of times the icon was destroyed.
  int destroys = 0;

  /// Shared ordering log, assigned by tests that assert teardown order.
  List<String>? calls;

  void Function(String itemKey)? _onSelected;

  /// The menu the tray is currently showing.
  TrayMenuModel get menu => menus.last;

  /// Drives a tray selection from a test.
  void select(String itemKey) => _onSelected?.call(itemKey);

  @override
  Future<void> install({
    required TrayMenuModel menu,
    required void Function(String itemKey) onSelected,
  }) async {
    installs += 1;
    operations.add('install');
    _onSelected = onSelected;
    menus.add(menu);
    await installGate?.future;
  }

  @override
  Future<void> update(TrayMenuModel menu) async {
    operations.add('update');
    menus.add(menu);
  }

  @override
  Future<void> destroy() async {
    destroys += 1;
    _onSelected = null;
    calls?.add('destroyTray');
  }
}

/// Records login-item registration without touching the real home directory.
final class FakeAutostartRegistration implements AutostartRegistration {
  /// Creates a fake registration that starts unregistered.
  FakeAutostartRegistration({this.enabled = false});

  /// Whether the operating system would launch the app at login.
  bool enabled;

  /// Whether the recorded launch arguments ask for a hidden start.
  bool minimized = false;

  /// Every [apply] call, in order.
  final List<({bool enabled, bool minimized})> applications =
      <({bool enabled, bool minimized})>[];

  @override
  Future<void> apply({required bool enabled, required bool minimized}) async {
    applications.add((enabled: enabled, minimized: minimized));
    this.enabled = enabled;
    this.minimized = minimized;
  }

  @override
  Future<bool> isEnabled() async => enabled;
}
