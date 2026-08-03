import 'package:flutter/material.dart';

/// Opens a menu anchored to the widget that triggered it.
///
/// [context] must belong to the tapped control: the menu is positioned from
/// that render box, the way `PopupMenuButton` does it, so a chip's menu opens
/// against the chip instead of the enclosing pane.
Future<T?> showComposerMenu<T>(
  BuildContext context, {
  required List<PopupMenuEntry<T>> items,
}) {
  final button = context.findRenderObject()! as RenderBox;
  final overlay =
      Navigator.of(context).overlay!.context.findRenderObject()! as RenderBox;
  final position = RelativeRect.fromRect(
    Rect.fromPoints(
      button.localToGlobal(Offset.zero, ancestor: overlay),
      button.localToGlobal(
        button.size.bottomRight(Offset.zero),
        ancestor: overlay,
      ),
    ),
    Offset.zero & overlay.size,
  );
  return showMenu<T>(context: context, position: position, items: items);
}
