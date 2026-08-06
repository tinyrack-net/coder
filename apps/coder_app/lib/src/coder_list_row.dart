import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

/// A Coder content row composed exclusively from Tinyrack tokens.
class CoderListRow extends StatefulWidget {
  /// Creates a content or navigation row.
  const CoderListRow({
    required this.title,
    this.contentPadding,
    this.dense = false,
    this.enabled = true,
    this.isThreeLine = false,
    this.leading,
    this.onTap,
    this.selected = false,
    this.subtitle,
    this.trailing,
    super.key,
  });

  /// Primary row content.
  final Widget title;

  /// Optional supporting content.
  final Widget? subtitle;

  /// Optional leading visual.
  final Widget? leading;

  /// Optional trailing visual or action.
  final Widget? trailing;

  /// Invoked when the row is activated.
  final VoidCallback? onTap;

  /// Whether the row is selected.
  final bool selected;

  /// Whether the row accepts activation.
  final bool enabled;

  /// Whether compact vertical padding is used.
  final bool dense;

  /// Whether supporting content may occupy two lines.
  final bool isThreeLine;

  /// Overrides token-based content padding when layout requires it.
  final EdgeInsetsGeometry? contentPadding;

  @override
  State<CoderListRow> createState() => _CoderListRowState();
}

class _CoderListRowState extends State<CoderListRow> {
  bool _hovered = false;
  bool _focused = false;

  bool get _interactive => widget.enabled && widget.onTap != null;

  @override
  Widget build(BuildContext context) {
    final colors = context.tinyrackTheme;
    final background = widget.selected
        ? colors.surfaceSelected
        : _hovered
        ? colors.surfaceHover
        : colors.surface;
    final verticalPadding = widget.dense
        ? TRSpacing.extraSmall
        : TRSpacing.small;
    final content = Row(
      crossAxisAlignment: widget.isThreeLine
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        if (widget.leading case final leading?) ...[
          IconTheme.merge(
            data: IconThemeData(color: colors.textMuted),
            child: leading,
          ),
          const SizedBox(width: TRSpacing.small),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              DefaultTextStyle.merge(
                style: TRTypography.body,
                child: widget.title,
              ),
              if (widget.subtitle case final subtitle?) ...[
                const SizedBox(height: TRSpacing.extraSmall),
                DefaultTextStyle.merge(
                  style: TRTypography.bodySm.copyWith(color: colors.textMuted),
                  maxLines: widget.isThreeLine ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                  child: subtitle,
                ),
              ],
            ],
          ),
        ),
        if (widget.trailing case final trailing?) ...[
          const SizedBox(width: TRSpacing.small),
          trailing,
        ],
      ],
    );

    return Semantics(
      button: _interactive,
      enabled: widget.enabled,
      selected: widget.selected,
      onTap: _interactive ? widget.onTap : null,
      child: CallbackShortcuts(
        bindings: _interactive
            ? <ShortcutActivator, VoidCallback>{
                const SingleActivator(LogicalKeyboardKey.enter): widget.onTap!,
                const SingleActivator(LogicalKeyboardKey.space): widget.onTap!,
              }
            : const <ShortcutActivator, VoidCallback>{},
        child: Focus(
          canRequestFocus: _interactive,
          onFocusChange: (focused) => setState(() => _focused = focused),
          child: MouseRegion(
            cursor: _interactive ? SystemMouseCursors.click : MouseCursor.defer,
            onEnter: _interactive
                ? (_) => setState(() => _hovered = true)
                : null,
            onExit: _interactive
                ? (_) => setState(() => _hovered = false)
                : null,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _interactive ? widget.onTap : null,
              child: AnimatedContainer(
                duration: TRMotion.fast,
                curve: TRMotion.standard,
                decoration: BoxDecoration(
                  color: background,
                  border: _focused
                      ? Border.all(
                          color: colors.focus,
                          width: TRControlMetrics.focusWidth,
                        )
                      : null,
                  borderRadius: const BorderRadius.all(TRRadii.medium),
                ),
                padding:
                    widget.contentPadding ??
                    EdgeInsets.symmetric(
                      horizontal: TRSpacing.small,
                      vertical: verticalPadding,
                    ),
                child: content,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
