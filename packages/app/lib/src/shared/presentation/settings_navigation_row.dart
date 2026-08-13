import 'package:app/src/shared/presentation/tinest_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

enum _SettingsNavigationDestination { row }

/// One Settings destination rendered with the shared tree-navigation contract.
///
/// Navigation rows intentionally do not use `SettingsRow`: value rows suppress
/// their own hover surface so a switch or field can own interaction feedback,
/// while a destination needs selected, hover, pressed, focus, keyboard, and
/// semantics behavior on the complete row.
class SettingsNavigationRow extends StatelessWidget {
  /// Creates one Settings navigation destination.
  const SettingsNavigationRow({
    required this.title,
    required this.onPressed,
    this.description,
    this.enabled = true,
    this.leading,
    this.selected = false,
    this.trailing,
    super.key,
  });

  /// Primary destination label.
  final Widget title;

  /// Optional supporting copy below [title].
  final Widget? description;

  /// Optional leading status or destination icon.
  final Widget? leading;

  /// Optional trailing status or control, placed before the destination
  /// chevron.
  final Widget? trailing;

  /// Whether the destination accepts activation.
  final bool enabled;

  /// Whether this destination is the current selection.
  final bool selected;

  /// Invoked when the destination row is activated.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final interactive = enabled && onPressed != null;
    return TRTreeNav<_SettingsNavigationDestination>.controlled(
      value: selected ? _SettingsNavigationDestination.row : null,
      onValueChange: interactive ? (_) => onPressed!() : null,
      items: <TRTreeNavItem<_SettingsNavigationDestination>>[
        TRTreeNavLeaf<_SettingsNavigationDestination>(
          value: _SettingsNavigationDestination.row,
          disabled: !interactive,
          leading: leading,
          label: title,
          description: description,
          trailing: trailing == null && !interactive
              ? null
              : _SettingsNavigationTrailing(
                  showChevron: interactive,
                  child: trailing,
                ),
        ),
      ],
    );
  }
}

class _SettingsNavigationTrailing extends StatelessWidget {
  const _SettingsNavigationTrailing({required this.showChevron, this.child});

  final Widget? child;
  final bool showChevron;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      if (child case final child?) ...<Widget>[
        child,
        if (showChevron) const SizedBox(width: TRSpacing.small),
      ],
      if (showChevron) Icon(TinestIcons.forwardFor(context)),
    ],
  );
}
