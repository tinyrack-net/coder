import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:termworld/termworld.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

/// Applies the Coder design system and context-menu contract to termworld.
final class CoderTerminalView extends StatefulWidget {
  /// Creates a token-backed terminal viewport for Coder.
  const CoderTerminalView({
    required this.terminal,
    required this.controller,
    this.contextMenuItems,
    this.autofocus = false,
    this.readOnly = false,
    super.key,
  });

  /// Terminal engine connected to the active PTY.
  final Terminal terminal;

  /// Selection and scroll state rendered by the viewport.
  final TerminalViewController controller;

  /// Native or Flutter context-menu description for terminal actions.
  final TRMenuElementsBuilder? contextMenuItems;

  /// Whether the terminal requests focus when mounted.
  final bool autofocus;

  /// Whether user input is disabled.
  final bool readOnly;

  @override
  State<CoderTerminalView> createState() => _CoderTerminalViewState();
}

final class _CoderTerminalViewState extends State<CoderTerminalView> {
  final TRContextMenuController _menuController = TRContextMenuController();

  @override
  void initState() {
    super.initState();
    widget.terminal.attachCustomKeyEventHandler(_handleTerminalKeyEvent);
  }

  @override
  void didUpdateWidget(CoderTerminalView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.terminal == widget.terminal) return;
    oldWidget.terminal.attachCustomKeyEventHandler((_) => true);
    widget.terminal.attachCustomKeyEventHandler(_handleTerminalKeyEvent);
  }

  void _openContextMenu(TapDownDetails details, CellOffset _) {
    if (widget.terminal.modes.mouseTrackingMode != 'none') {
      return;
    }
    _menuController.openAt(details.globalPosition);
  }

  bool _handleTerminalKeyEvent(TerminalKeyEvent event) {
    if (_menuController.isOpen &&
        event.key == LogicalKeyboardKey.escape.keyLabel) {
      _menuController.close();
      return false;
    }
    return true;
  }

  @override
  void dispose() {
    widget.terminal.attachCustomKeyEventHandler((_) => true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tinyrackTheme;
    final terminal = TerminalView(
      terminal: widget.terminal,
      controller: widget.controller,
      autofocus: widget.autofocus,
      readOnly: widget.readOnly,
      onSecondaryTapDown: widget.contextMenuItems == null
          ? null
          : _openContextMenu,
      theme: TerminalTheme(
        background: colors.surface,
        foreground: colors.text,
        cursor: colors.focus,
        selection: colors.surfaceSelected,
        black: colors.surface,
        red: colors.danger,
        green: colors.success,
        yellow: colors.warning,
        blue: colors.info,
        magenta: colors.primary,
        cyan: colors.infoBorder,
        white: colors.text,
        brightBlack: colors.textMuted,
        brightRed: colors.dangerBorder,
        brightGreen: colors.successBorder,
        brightYellow: colors.warningBorder,
        brightBlue: colors.infoBorder,
        brightMagenta: colors.primary,
        brightCyan: colors.info,
        brightWhite: colors.text,
        searchHitBackground: colors.warningSurface,
        searchHitBackgroundCurrent: colors.warning,
        searchHitForeground: colors.surface,
      ),
      style: TerminalStyle.fromTextStyle(TRTypography.code),
      padding: const EdgeInsets.all(TRSpacing.small),
    );
    final items = widget.contextMenuItems;
    return ColoredBox(
      key: const ValueKey<String>('tr-terminal-surface'),
      color: colors.surface,
      child: items == null
          ? terminal
          : TRContextMenu.itemsBuilder(
              menuController: _menuController,
              itemsBuilder: items,
              onClose: widget.controller.requestKeyboard,
              child: terminal,
            ),
    );
  }
}
