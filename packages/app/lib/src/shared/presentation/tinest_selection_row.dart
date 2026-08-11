import 'package:app/src/shared/presentation/settings_layout.dart';
import 'package:flutter/widgets.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

/// A labeled binary setting backed by [TRSwitch].
///
/// The inset comes from [SettingsRow] and cannot be overridden. A caller that
/// could set its own was how one card ended up drawing two alignment lines.
class TinestSwitchRow extends StatelessWidget {
  /// Creates a binary setting row.
  const TinestSwitchRow({
    required this.title,
    required this.value,
    this.onChanged,
    this.subtitle,
    this.wrapsSubtitle = false,
    this.flush = false,
    super.key,
  });

  /// Visible label.
  final Widget title;

  /// Optional supporting text.
  final Widget? subtitle;

  /// Whether the supporting text may occupy a second line.
  final bool wrapsSubtitle;

  /// Whether the surrounding container already supplies the inline inset.
  final bool flush;

  /// Current state.
  final bool value;

  /// Called with the next state.
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) => SettingsRow(
    enabled: onChanged != null,
    flush: flush,
    // The row's tap is the switch's tap, so the switch is the tab stop.
    controlOwnsFocus: true,
    onTap: onChanged == null ? null : () => onChanged!(!value),
    title: title,
    description: subtitle,
    wrapsDescription: wrapsSubtitle,
    control: TRSwitch(
      checked: value,
      disabled: onChanged == null,
      onCheckedChange: onChanged,
    ),
  );
}

/// A labeled multi-selection setting backed by [TRCheckbox].
class TinestCheckboxRow extends StatelessWidget {
  /// Creates a checkbox setting row.
  const TinestCheckboxRow({
    required this.title,
    required this.value,
    this.onChanged,
    this.onRowTap,
    this.indeterminate = false,
    this.secondary,
    this.subtitle,
    this.wrapsSubtitle = false,
    super.key,
  });

  /// Visible label.
  final Widget title;

  /// Optional supporting text.
  final Widget? subtitle;

  /// Whether the supporting text may occupy a second line.
  final bool wrapsSubtitle;

  /// Optional leading visual.
  final Widget? secondary;

  /// Current checked state.
  final bool value;

  /// Whether the checkbox reads as partially checked.
  ///
  /// For a row standing for several settings that disagree, such as a group
  /// header over tools where only some are on.
  final bool indeterminate;

  /// Called with the next checked state.
  final ValueChanged<bool?>? onChanged;

  /// What the row does when the checkbox is not what was tapped.
  ///
  /// Left null, the row simply repeats the checkbox, which is the usual shape
  /// and keeps one setting at one tab stop. A row that does something else —
  /// a group header that expands while its checkbox toggles the whole group —
  /// supplies this, and then the row and the checkbox are two actions and get
  /// a tab stop each.
  final VoidCallback? onRowTap;

  @override
  Widget build(BuildContext context) => SettingsRow(
    enabled: onChanged != null || onRowTap != null,
    // Without [onRowTap] the row's tap is the checkbox's tap, so the checkbox
    // is the single tab stop. With one they are two actions, and two stops.
    controlOwnsFocus: onRowTap == null,
    onTap: onRowTap ?? (onChanged == null ? null : () => onChanged!(!value)),
    leading: secondary,
    title: title,
    description: subtitle,
    wrapsDescription: wrapsSubtitle,
    control: TRCheckbox(
      checked: value,
      indeterminate: indeterminate,
      disabled: onChanged == null,
      onCheckedChange: (checked) => onChanged?.call(checked),
    ),
  );
}
