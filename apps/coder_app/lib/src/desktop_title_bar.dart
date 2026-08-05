import 'dart:async';

import 'package:coder_app/l10n/gen/app_localizations.dart';
import 'package:coder_app/src/desktop_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

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
    final colors = context.tinyrackTheme;
    return ColoredBox(
      color: colors.surface,
      child: SizedBox(
        height: desktopTitleBarHeight,
        child: DecoratedBox(
          key: const ValueKey<String>('desktop-title-bar-border'),
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: colors.border)),
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
                action: TRWindowCaptionAction.minimize,
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
                  action: maximized
                      ? TRWindowCaptionAction.restore
                      : TRWindowCaptionAction.maximize,
                  onPressed: () => unawaited(window.toggleMaximized()),
                ),
              ),
              _CaptionButton(
                key: const ValueKey<String>('desktop-title-bar-close'),
                tooltip: l10n.desktopWindowClose,
                action: TRWindowCaptionAction.close,
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
    return TRMenubar(
      semanticLabel: l10n.desktopMenuFile,
      menus: <TRMenubarMenu>[
        TRMenubarMenu(
          menuChildren: <Widget>[
            TRMenuItem(
              shortcut: const SingleActivator(
                LogicalKeyboardKey.keyN,
                control: true,
              ),
              onPressed: onNewWorkspace,
              child: Text(l10n.workspaceNewWorkspace),
            ),
            TRMenuItem(
              shortcut: const SingleActivator(
                LogicalKeyboardKey.comma,
                control: true,
              ),
              onPressed: onOpenSettings,
              child: Text(l10n.settingsTitle),
            ),
            const TRSeparator(),
            TRMenuItem(
              shortcut: const SingleActivator(
                LogicalKeyboardKey.keyQ,
                control: true,
              ),
              onPressed: onQuit,
              child: Text(l10n.trayQuit),
            ),
          ],
          trigger: Text(l10n.desktopMenuFile),
        ),
        TRMenubarMenu(
          menuChildren: <Widget>[
            TRMenuCheckboxItem(
              value: !sidebarCollapsed,
              onChanged: (_) => onToggleSidebar(),
              child: Text(
                sidebarCollapsed
                    ? l10n.workspaceSidebarExpand
                    : l10n.workspaceSidebarCollapse,
              ),
            ),
          ],
          trigger: Text(l10n.desktopMenuView),
        ),
        TRMenubarMenu(
          menuChildren: <Widget>[
            TRMenuItem(
              onPressed: onShowAbout,
              child: Text(l10n.desktopMenuAbout),
            ),
          ],
          trigger: Text(l10n.desktopMenuHelp),
        ),
      ],
    );
  }
}

class _CaptionButton extends StatelessWidget {
  const _CaptionButton({
    required this.tooltip,
    required this.action,
    required this.onPressed,
    super.key,
  });

  final String tooltip;
  final TRWindowCaptionAction action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => TRWindowCaptionButton(
    action: action,
    glyphStyle: TRWindowCaptionGlyphStyle.expandCollapse,
    label: tooltip,
    onPressed: onPressed,
  );
}
