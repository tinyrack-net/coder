import 'package:coder_app/src/coder_list_row.dart';
import 'package:flutter/widgets.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

/// A labeled binary setting backed by [TRSwitch].
class CoderSwitchRow extends StatelessWidget {
  /// Creates a binary setting row.
  const CoderSwitchRow({
    required this.title,
    required this.value,
    this.contentPadding,
    this.onChanged,
    this.subtitle,
    super.key,
  });

  /// Visible label.
  final Widget title;

  /// Optional supporting text.
  final Widget? subtitle;

  /// Current state.
  final bool value;

  /// Called with the next state.
  final ValueChanged<bool>? onChanged;

  /// Optional layout override.
  final EdgeInsetsGeometry? contentPadding;

  @override
  Widget build(BuildContext context) => CoderListRow(
    contentPadding: contentPadding,
    enabled: onChanged != null,
    onTap: onChanged == null ? null : () => onChanged!(!value),
    title: title,
    subtitle: subtitle,
    trailing: TRSwitch(
      checked: value,
      disabled: onChanged == null,
      onCheckedChange: onChanged,
    ),
  );
}

/// A labeled multi-selection setting backed by [TRCheckbox].
class CoderCheckboxRow extends StatelessWidget {
  /// Creates a checkbox setting row.
  const CoderCheckboxRow({
    required this.title,
    required this.value,
    this.onChanged,
    this.secondary,
    this.subtitle,
    super.key,
  });

  /// Visible label.
  final Widget title;

  /// Optional supporting text.
  final Widget? subtitle;

  /// Optional leading visual.
  final Widget? secondary;

  /// Current checked state.
  final bool value;

  /// Called with the next checked state.
  final ValueChanged<bool?>? onChanged;

  @override
  Widget build(BuildContext context) => CoderListRow(
    enabled: onChanged != null,
    onTap: onChanged == null ? null : () => onChanged!(!value),
    leading: secondary,
    title: title,
    subtitle: subtitle,
    trailing: TRCheckbox(
      checked: value,
      disabled: onChanged == null,
      onCheckedChange: (checked) => onChanged?.call(checked),
    ),
  );
}
