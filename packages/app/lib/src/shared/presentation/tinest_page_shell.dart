import 'package:flutter/widgets.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

/// The standard Tinest page shell backed by [TRAppShell].
class TinestPageShell extends StatelessWidget {
  /// Creates a page with optional top chrome.
  const TinestPageShell({required this.body, this.appBar, super.key});

  /// Page content.
  final Widget body;

  /// Optional page header.
  final TinestPageHeader? appBar;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: context.tinyrackTheme.surface,
    child: SafeArea(
      child: TRAppShell(
        header: appBar == null ? null : TinestPageHeaderBar.bar(appBar!),
        main: TRAppShellMain(child: body),
      ),
    ),
  );
}

/// The top chrome of a [TinestPageShell], usable on its own.
///
/// A destination nested inside a shell's [TRAppShellMain] can render this to
/// own the page header itself. [TRAppShellHeader] resolves its scope from the
/// enclosing [TRAppShell], which spans the main region too, so the header
/// reads identically wherever it is composed.
class TinestPageHeaderBar extends StatelessWidget {
  /// Creates a standalone Tinest header bar.
  const TinestPageHeaderBar({required this.header, super.key});

  /// Declarative header content.
  final TinestPageHeader header;

  /// Builds the same bar as a raw [TRAppShellHeader].
  ///
  /// [TRAppShell.header] is typed to [TRAppShellHeader], so the shell slot
  /// cannot take this wrapper widget. Both paths share this one definition.
  static TRAppShellHeader bar(TinestPageHeader header) => TRAppShellHeader(
    borderBottom: true,
    padding: const EdgeInsets.symmetric(
      horizontal: TRSpacing.small,
      vertical: TRSpacing.extraSmall,
    ),
    children: [
      ?header.leading,
      // Identity and actions share one wrapped rail rather than a single
      // row. A destination that carries several actions would otherwise
      // overflow the bar on a phone-width window.
      Expanded(
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: TRSpacing.medium,
          runSpacing: TRSpacing.extraSmall,
          children: <Widget>[
            _TinestPageHeaderTitle(title: header.title),
            if (header.actions.isNotEmpty)
              Wrap(
                spacing: TRSpacing.small,
                runSpacing: TRSpacing.extraSmall,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: header.actions,
              ),
          ],
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => bar(header);
}

class _TinestPageHeaderTitle extends StatelessWidget {
  const _TinestPageHeaderTitle({required this.title});

  final Widget title;

  @override
  Widget build(BuildContext context) => DefaultTextStyle.merge(
    style: TRTypography.resolve(context, TRTextVariant.headingSm),
    softWrap: true,
    child: title,
  );
}

/// Declarative content for a [TinestPageShell] header.
class TinestPageHeader {
  /// Creates a page header.
  const TinestPageHeader({
    required this.title,
    this.actions = const [],
    this.leading,
  });

  /// Header title.
  final Widget title;

  /// Optional leading navigation action.
  final Widget? leading;

  /// Trailing page actions.
  final List<Widget> actions;
}
