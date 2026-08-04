import 'dart:async';

import 'package:coder_app/l10n/gen/app_localizations.dart';
import 'package:coder_app/src/app.dart';
import 'package:coder_app/src/controller.dart';
import 'package:coder_app/src/desktop_shell.dart';
import 'package:coder_app/src/host_models.dart';
import 'package:coder_app/src/tray_menu.dart';
import 'package:coder_app/src/tray_menu_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Keeps the desktop app resident in the tray around [child].
///
/// It is mounted below `Localizations` and the router so tray labels follow
/// the selected language and selecting a row can navigate, without any of
/// that logic having to reach outside the widget tree.
class DesktopShellScope extends ConsumerStatefulWidget {
  /// Creates the desktop residency scope.
  const DesktopShellScope({
    required this.child,
    required this.router,
    this.startHidden = false,
    super.key,
  });

  /// The application below the shell.
  final Widget child;

  /// Router used by the tray, which sits above the router's own context.
  final GoRouter router;

  /// Whether this launch started without showing a window.
  final bool startHidden;

  @override
  ConsumerState<DesktopShellScope> createState() => _DesktopShellScopeState();
}

class _DesktopShellScopeState extends ConsumerState<DesktopShellScope> {
  late bool _windowVisible = !widget.startHidden;
  TrayMenuModel? _installed;
  bool _quitting = false;

  // Held in fields because `dispose` runs after `ref` is no longer safe.
  DesktopWindow? _window;
  TrayIcon? _tray;

  @override
  void initState() {
    super.initState();
    _window = ref.read(desktopWindowProvider);
    _tray = ref.read(trayIconProvider);
    unawaited(_window?.interceptClose(_onCloseGesture));
  }

  @override
  void dispose() {
    unawaited(_tray?.destroy());
    unawaited(_window?.releaseClose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final registry = ref.watch(hostRegistryControllerProvider).asData?.value;
    final menu = buildTrayMenu(
      l10n: AppLocalizations.of(context),
      windowVisible: _windowVisible,
      embeddedDaemon: registry?.runtimes[embeddedHostId],
      supportsEmbeddedDaemon: ref
          .watch(appServicesProvider)
          .supportsEmbeddedDaemon,
    );
    // A rebuild that did not change anything the user can see must not churn
    // the native menu, which is what the model's value equality is for.
    if (menu != _installed) {
      _installed = menu;
      WidgetsBinding.instance.addPostFrameCallback((_) => _publish(menu));
    }
    return widget.child;
  }

  /// Applies [menu] to the native tray, one call at a time.
  ///
  /// Two frames can each schedule a publish before the first finishes, and the
  /// native tray cannot take a menu before the icon that owns it exists, so
  /// these are chained rather than merely guarded by a flag.
  Future<void> _publish(TrayMenuModel menu) {
    final tray = _tray;
    if (tray == null) return Future<void>.value();
    final published = _pending.then((_) async {
      if (_installedTray) {
        await tray.update(menu);
        return;
      }
      _installedTray = true;
      await tray.install(menu: menu, onSelected: _onSelected);
    });
    _pending = published.then(
      (_) {},
      onError: (Object _, StackTrace _) {
        // A tray that failed to update must not stall every later update.
      },
    );
    return published;
  }

  bool _installedTray = false;
  Future<void> _pending = Future<void>.value();

  void _onCloseGesture() {
    unawaited(_hide());
  }

  Future<void> _hide() async {
    await _window?.hide();
    if (mounted) setState(() => _windowVisible = false);
  }

  void _onSelected(String itemKey) {
    switch (_installed?.actionFor(itemKey)) {
      case TrayMenuAction.toggleWindow:
        unawaited(_toggleWindow());
      case TrayMenuAction.openSettings:
        unawaited(_openSettings());
      case TrayMenuAction.quit:
        unawaited(_quit());
      case null:
        // Informational rows such as the daemon status report state only.
        break;
    }
  }

  Future<void> _toggleWindow() async {
    final window = _window;
    if (window == null) return;
    if (await window.isVisible()) {
      await _hide();
      return;
    }
    await window.show();
    if (mounted) setState(() => _windowVisible = true);
  }

  Future<void> _openSettings() async {
    await _window?.show();
    if (!mounted) return;
    setState(() => _windowVisible = true);
    widget.router.go(const GeneralSettingsRoute().location);
  }

  Future<void> _quit() async {
    if (_quitting) return;
    _quitting = true;
    final tray = _tray;
    final window = _window;
    final controller = ref.read(hostRegistryControllerProvider.notifier);
    // Stop answering the user before tearing down, then stop the daemon
    // before the process goes away so no turn is killed mid-write.
    await tray?.destroy();
    await window?.releaseClose();
    await controller.shutdown();
    await window?.destroy();
  }
}
