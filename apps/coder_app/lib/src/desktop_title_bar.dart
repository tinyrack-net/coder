import 'dart:async';

import 'package:coder_app/l10n/gen/app_localizations.dart';
import 'package:coder_app/src/desktop_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Height of the compact Windows and Linux application frame.
const double desktopTitleBarHeight = 40;

/// Flutter-owned title bar for Windows and Linux desktop runners.
class DesktopTitleBar extends StatelessWidget {
  /// Creates a title bar connected to typed application and window commands.
  const DesktopTitleBar({
    required this.window,
    required this.sidebarCollapsed,
    required this.onNewWorkspace,
    required this.onOpenSettings,
    required this.onToggleSidebar,
    required this.onShowAbout,
    required this.onClose,
    required this.onQuit,
    super.key,
  });

  /// Typed native-window port.
  final DesktopWindow window;

  /// Whether the workspace sidebar is currently collapsed.
  final bool sidebarCollapsed;

  /// Opens the new-workspace composer.
  final VoidCallback onNewWorkspace;

  /// Opens general application settings.
  final VoidCallback onOpenSettings;

  /// Flips the persisted workspace-sidebar state.
  final VoidCallback onToggleSidebar;

  /// Opens application name and version information.
  final VoidCallback onShowAbout;

  /// Hides the window to the tray.
  final VoidCallback onClose;

  /// Fully shuts down the resident application.
  final VoidCallback onQuit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface,
      child: SizedBox(
        height: desktopTitleBarHeight,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: colors.outlineVariant)),
          ),
          child: Row(
            children: <Widget>[
              _ApplicationMenu(
                sidebarCollapsed: sidebarCollapsed,
                onNewWorkspace: onNewWorkspace,
                onOpenSettings: onOpenSettings,
                onToggleSidebar: onToggleSidebar,
                onShowAbout: onShowAbout,
                onQuit: onQuit,
              ),
              Expanded(
                child: GestureDetector(
                  key: const ValueKey<String>('desktop-title-bar-drag-area'),
                  behavior: HitTestBehavior.translucent,
                  onPanStart: (_) => unawaited(window.startDragging()),
                  onDoubleTap: () => unawaited(window.toggleMaximized()),
                  child: const SizedBox.expand(),
                ),
              ),
              _CaptionButton(
                key: const ValueKey<String>('desktop-title-bar-minimize'),
                tooltip: l10n.desktopWindowMinimize,
                icon: Icons.remove,
                onPressed: () => unawaited(window.minimize()),
              ),
              ValueListenableBuilder<bool>(
                valueListenable: window.maximized,
                builder: (context, maximized, _) => _CaptionButton(
                  key: ValueKey<String>(
                    maximized
                        ? 'desktop-title-bar-restore'
                        : 'desktop-title-bar-maximize',
                  ),
                  tooltip: maximized
                      ? l10n.desktopWindowRestore
                      : l10n.desktopWindowMaximize,
                  icon: maximized
                      ? Icons.filter_none_outlined
                      : Icons.crop_square,
                  onPressed: () => unawaited(window.toggleMaximized()),
                ),
              ),
              _CaptionButton(
                key: const ValueKey<String>('desktop-title-bar-close'),
                tooltip: l10n.desktopWindowClose,
                icon: Icons.close,
                close: true,
                onPressed: onClose,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ApplicationMenu extends StatelessWidget {
  const _ApplicationMenu({
    required this.sidebarCollapsed,
    required this.onNewWorkspace,
    required this.onOpenSettings,
    required this.onToggleSidebar,
    required this.onShowAbout,
    required this.onQuit,
  });

  final bool sidebarCollapsed;
  final VoidCallback onNewWorkspace;
  final VoidCallback onOpenSettings;
  final VoidCallback onToggleSidebar;
  final VoidCallback onShowAbout;
  final VoidCallback onQuit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return MenuBar(
      style: const MenuStyle(
        backgroundColor: WidgetStatePropertyAll<Color>(Colors.transparent),
        elevation: WidgetStatePropertyAll<double>(0),
        padding: WidgetStatePropertyAll<EdgeInsetsGeometry>(EdgeInsets.zero),
      ),
      children: <Widget>[
        SubmenuButton(
          menuChildren: <Widget>[
            MenuItemButton(
              shortcut: const SingleActivator(
                LogicalKeyboardKey.keyN,
                control: true,
              ),
              onPressed: onNewWorkspace,
              child: Text(l10n.workspaceNewWorkspace),
            ),
            MenuItemButton(
              shortcut: const SingleActivator(
                LogicalKeyboardKey.comma,
                control: true,
              ),
              onPressed: onOpenSettings,
              child: Text(l10n.settingsTitle),
            ),
            const Divider(),
            MenuItemButton(
              shortcut: const SingleActivator(
                LogicalKeyboardKey.keyQ,
                control: true,
              ),
              onPressed: onQuit,
              child: Text(l10n.trayQuit),
            ),
          ],
          child: Text(l10n.desktopMenuFile),
        ),
        SubmenuButton(
          menuChildren: <Widget>[
            MenuItemButton(
              leadingIcon: Icon(
                sidebarCollapsed ? Icons.check_box_outline_blank : Icons.check,
              ),
              shortcut: const SingleActivator(
                LogicalKeyboardKey.keyB,
                control: true,
              ),
              onPressed: onToggleSidebar,
              child: Text(
                sidebarCollapsed
                    ? l10n.workspaceSidebarExpand
                    : l10n.workspaceSidebarCollapse,
              ),
            ),
          ],
          child: Text(l10n.desktopMenuView),
        ),
        SubmenuButton(
          menuChildren: <Widget>[
            MenuItemButton(
              onPressed: onShowAbout,
              child: Text(l10n.desktopMenuAbout),
            ),
          ],
          child: Text(l10n.desktopMenuHelp),
        ),
      ],
    );
  }
}

class _CaptionButton extends StatelessWidget {
  const _CaptionButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.close = false,
    super.key,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final bool close;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: onPressed,
    style: ButtonStyle(
      minimumSize: const WidgetStatePropertyAll<Size>(
        Size(48, desktopTitleBarHeight),
      ),
      maximumSize: const WidgetStatePropertyAll<Size>(
        Size(48, desktopTitleBarHeight),
      ),
      padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
        EdgeInsets.zero,
      ),
      shape: const WidgetStatePropertyAll<OutlinedBorder>(
        RoundedRectangleBorder(),
      ),
      foregroundColor: close
          ? WidgetStateProperty.resolveWith<Color?>((states) {
              if (states.contains(WidgetState.hovered) ||
                  states.contains(WidgetState.pressed)) {
                return Colors.white;
              }
              return null;
            })
          : null,
      overlayColor: close
          ? WidgetStateProperty.resolveWith<Color?>((states) {
              if (states.contains(WidgetState.hovered) ||
                  states.contains(WidgetState.pressed)) {
                return const Color(0xffc42b1c);
              }
              return null;
            })
          : null,
    ),
    icon: Icon(icon, size: 17),
  );
}
