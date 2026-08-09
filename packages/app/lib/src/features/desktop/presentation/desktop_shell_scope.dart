import 'dart:async';

import 'package:app/l10n/gen/app_localizations.dart';
import 'package:app/src/app/app_identity.dart';
import 'package:app/src/app/composition/app_providers.dart';
import 'package:app/src/app/router/app_router.dart';
import 'package:app/src/app/version.g.dart';
import 'package:app/src/features/desktop/domain/tray_menu_model.dart';
import 'package:app/src/features/desktop/infrastructure/desktop_shell.dart';
import 'package:app/src/features/desktop/presentation/desktop_title_bar.dart';
import 'package:app/src/features/desktop/presentation/tray_menu.dart';
import 'package:app/src/features/hosts/application/host_controller.dart';
import 'package:app/src/features/hosts/domain/host_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

/// How long quitting waits for the app and its daemon to tear themselves down.
///
/// The process ends when this elapses either way: a daemon that will not stop
/// must not keep a hidden, unquittable process alive.
const Duration quitBudget = Duration(seconds: 5);

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
    final window = _window;
    if (window == null || !window.supportsCustomTitleBar) return widget.child;
    // MaterialApp's builder sits above the router's Navigator, so its Overlay
    // is a descendant rather than an ancestor. Own one here for menus,
    // tooltips, and the about dialog rendered by the application frame.
    return Overlay(
      initialEntries: <OverlayEntry>[
        OverlayEntry(
          // These bindings sit above the router, so a focused terminal sees
          // every key first. A terminal turns Control with a letter into a
          // control byte and reports the key as handled, which stops the event
          // before it ever reaches here; adding Shift keeps the combination out
          // of that translation, so Control with a letter still belongs to the
          // program in the terminal. Control with a comma is not a control
          // byte, so it needs no Shift.
          builder: (context) => Consumer(
            // Overlay.initialEntries installs this builder once. Keep the
            // title bar under its own provider subscription so settings
            // changes can update menu labels and callbacks in place.
            builder: (context, ref, _) {
              final registry = ref
                  .watch(hostRegistryControllerProvider)
                  .asData
                  ?.value;
              final collapsed = registry?.settings.sidebarCollapsed ?? false;
              void newWorkspace() => widget.router.go(
                const WorkspaceHomeRoute(compose: true).location,
              );
              void openSettings() => openSettingsTask(widget.router);
              void setSidebarVisibility({required bool visible}) => unawaited(
                ref
                    .read(hostRegistryControllerProvider.notifier)
                    .setSidebarCollapsed(collapsed: !visible),
              );
              void toggleSidebar() => setSidebarVisibility(visible: collapsed);
              void showAbout() {
                final navigatorContext =
                    widget.router.routerDelegate.navigatorKey.currentContext;
                if (navigatorContext == null) return;
                unawaited(
                  showTRDialog<void>(
                    context: navigatorContext,
                    useRootNavigator: false,
                    builder: (dialogContext) {
                      final l10n = AppLocalizations.of(dialogContext);
                      return TRDialog(
                        semanticLabel: l10n.desktopMenuAbout(
                          AppIdentity.displayName,
                        ),
                        title: const TRText.inherit(AppIdentity.displayName),
                        description: const TRText.inherit(packageVersion),
                        actions: TRButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: TRText.inherit(l10n.commonClose),
                        ),
                      );
                    },
                  ),
                );
              }

              return CallbackShortcuts(
                bindings: <ShortcutActivator, VoidCallback>{
                  const SingleActivator(
                    LogicalKeyboardKey.keyN,
                    control: true,
                    shift: true,
                  ): newWorkspace,
                  const SingleActivator(
                    LogicalKeyboardKey.comma,
                    control: true,
                  ): openSettings,
                  const SingleActivator(
                    LogicalKeyboardKey.keyB,
                    control: true,
                    shift: true,
                  ): toggleSidebar,
                  const SingleActivator(
                    LogicalKeyboardKey.keyQ,
                    control: true,
                    shift: true,
                  ): () =>
                      unawaited(_quit()),
                },
                child: Column(
                  children: <Widget>[
                    DesktopTitleBar(
                      window: window,
                      sidebarCollapsed: collapsed,
                      onNewWorkspace: newWorkspace,
                      onOpenSettings: openSettings,
                      onSidebarVisibilityChanged: (visible) =>
                          setSidebarVisibility(visible: visible),
                      onShowAbout: showAbout,
                      onClose: () => unawaited(_hide()),
                      onQuit: () => unawaited(_quit()),
                    ),
                    Expanded(child: widget.child),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
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
      await tray.install(
        menu: menu,
        onSelected: _onSelected,
        onActivated: _onTrayActivated,
      );
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

  void _onTrayActivated() {
    unawaited(_reveal());
  }

  /// Brings the window back, whatever state it was in.
  ///
  /// Deliberately not a toggle: Windows reports a double click on the icon as
  /// two clicks, and a toggle would show and then hide, reading as nothing
  /// happening at all. The menu's Show/Hide row is where toggling belongs.
  Future<void> _reveal() async {
    await _window?.show();
    if (mounted) setState(() => _windowVisible = true);
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
    await _reveal();
    if (!mounted) return;
    openSettingsTask(widget.router);
  }

  Future<void> _quit() async {
    if (_quitting) return;
    _quitting = true;
    final terminator = ref.read(appTerminatorProvider);
    final teardown = _teardown(
      tray: _tray,
      window: _window,
      controller: ref.read(hostRegistryControllerProvider.notifier),
    );
    try {
      await teardown.timeout(quitBudget);
    } on Object catch (_) {
      // Deliberately broad. The window is already gone and the tray icon is
      // already destroyed by this point, so a teardown that fails or overruns
      // must still reach the terminator below; anything else leaves a process
      // the user can no longer see, reach, or quit.
    } finally {
      await terminator?.terminate();
    }
  }

  Future<void> _teardown({
    required TrayIcon? tray,
    required DesktopWindow? window,
    required HostRegistryController controller,
  }) async {
    // The window leaves the screen first so quit feels immediate, then the
    // daemon is stopped before the process goes away so no turn is killed
    // mid-write.
    await window?.hide();
    await tray?.destroy();
    await window?.releaseClose();
    await controller.shutdown();
  }
}
