import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:termworld/termworld.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

/// Applies the Coder design system and context-menu contract to termworld.
final class CoderTerminalView extends StatefulWidget {
  /// Creates a token-backed terminal viewport for Coder.
  const CoderTerminalView({
    required this.emulator,
    required this.controller,
    this.contextMenuItems,
    this.autofocus = false,
    this.readOnly = false,
    super.key,
  });

  /// Terminal engine connected to the active PTY.
  final TerminalEmulator emulator;

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

  void _openContextMenu(TapDownDetails details) {
    if (widget.emulator.mouseTrackingMode != TerminalMouseTrackingMode.none) {
      return;
    }
    _menuController.openAt(details.globalPosition);
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (_menuController.isOpen &&
        event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      _menuController.close();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tinyrackTheme;
    final terminal = TerminalView(
      emulator: widget.emulator,
      controller: widget.controller,
      autofocus: widget.autofocus,
      readOnly: widget.readOnly,
      onSecondaryTapDown: widget.contextMenuItems == null
          ? null
          : _openContextMenu,
      onKeyEvent: widget.contextMenuItems == null ? null : _handleKeyEvent,
      theme: TerminalTheme(
        background: colors.surface,
        foreground: colors.text,
        cursor: colors.focus,
        selection: colors.surfaceSelected,
        palette: <Color>[
          colors.surface,
          colors.danger,
          colors.success,
          colors.warning,
          colors.info,
          colors.primary,
          colors.infoBorder,
          colors.text,
          colors.textMuted,
          colors.dangerBorder,
          colors.successBorder,
          colors.warningBorder,
          colors.infoBorder,
          colors.primary,
          colors.info,
          colors.text,
        ],
      ),
      style: const TerminalStyle(
        textStyle: TRTypography.code,
        padding: EdgeInsets.all(TRSpacing.small),
      ),
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
